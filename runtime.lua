rapidjson = require("rapidjson")

-- Global tables for device and inventory management
Devices = {}                -- List of device names
DevicesLookup = {}          -- Maps device names to indices
IPs = {}                    -- List of device IPs
DeviceTypes = {}            -- List of device models
DevicesAndIPs = {}          -- Lookup: device name -> IP
DeviceTypeLookup = {}       -- Lookup: device name -> model
tabModeltoName = {}         -- Lookup: model -> list of device names for choices
tabModelNameLookup = {}     -- Lookup: device name -> index in tabModeltoName
Peripherals = {}            -- Stores detailed peripheral configurations
Cores = {}  
tabDebugString = {}                -- Stores core device details
Inventory = {
  Models = {""},          -- List of inventory models
  ModelsLookup = {},      -- Quick lookup for models
  Names = {""},           -- List of inventory names
  NamesLookup = {},       -- Quick lookup for names
  ModelToName = {},       -- Mapping: model -> name
  NameToModel = {},       -- Mapping: name -> model
  ByModel = {},           -- Lookup: model -> list of names
  ByModelLookup = {},     -- Tracks models in ByModel
  Types = {               -- Supported device types
    ["Network Microphone"] = true, ["Camera"] = true, ["Network Loudspeaker"] = true,
    ["Control I/O"] = true, ["Amplifier"] = true, ["Audio I/O"] = true,
    ["Audio Video I/O"] = true, ["Peripheral"] = true, ["Video I/O"] = true,
    ["Control Interface"] = true, ["Page Station"] = true
  }
}

LastStatusCodes = {}        -- Tracks last known status codes for inventory items
inventoryTimer = Timer.New() -- Timer for periodic inventory updates
RefreshTimer = Timer.New()
-- Network globals
broadcastRange = ""         -- Broadcast address for the network
netMask = ""          -- Subnet mask for the network
t = 1                 -- Global index for device control updates

--Debug level settings
DebugSetting = Properties["Debug Print"].Value
-- Set design name on startup
Controls.LocalDesignName.String = Design.GetStatus().DesignName
Controls.AssignToDevice.String = ""
-- Initialize device controls to a cleared state
refresh = false
for i = 1, #Controls.DeviceModel do
  Controls.DeviceModel[i].String = ""
  Controls.DeviceName[i].String = ""
  Controls.DeviceIP[i].String = ""
end
Controls.Assign.Legend = "Assign\nto\nPeripheral" 

-- Debug Print function to display in UCI 
function DisplayPrint(str)
  -- Add the new string to the debug table
  table.insert(tabDebugString, str)
  
  -- If we have more than 5 lines, remove the oldest one
  if #tabDebugString > 5 then
    table.remove(tabDebugString, 1)
  end
  -- Combine all strings with line breaks
  local displayText = table.concat(tabDebugString, "\n")
  -- Update the debug display control if it exists
  Controls.PairingByNameDebug.String = displayText
  print(str)
end

-- Debug print function that respects the debug level setting
function DebugPrint(str, type) 
  -- If debug is set to "None", don't print anything
  if DebugSetting == "None" then
      return
  end
  -- Only print to console based on debug setting
  if DebugSetting == "All" then
      print(str)
  elseif DebugSetting == type then
      print(str)
  end
end

-- Function to add debug prints for function entry
function DebugFunctionEntry(funcName, ...)
  local args = {...}
  local argStr = ""
  for i, arg in ipairs(args) do
      if type(arg) == "string" then
          argStr = argStr .. (i > 1 and ", " or "") .. '"' .. arg .. '"'
      else
          argStr = argStr .. (i > 1 and ", " or "") .. tostring(arg)
      end
  end
  DebugPrint("Function Enter: " .. funcName .. "(" .. argStr .. ")", "Function Calls")
end

-- Function to add debug prints for function exit
function DebugFunctionExit(funcName, result)
  if result then
      DebugPrint("Function Exit: " .. funcName .. " -> " .. tostring(result), "Function Calls")
  else
      DebugPrint("Function Exit: " .. funcName, "Function Calls")
  end
end

-- Function to add debug prints for network requests
function DebugNetworkRequest(url, method, data)
  DebugPrint("Network Request: " .. method .. " " .. url, "Tx")
  if data then
      DebugPrint("Request Data: " .. tostring(data), "Tx")
  end
end

-- Function to add debug prints for network responses
function DebugNetworkResponse(url, code, data)
  DebugPrint("Network Response: " .. url .. " -> " .. code, "Rx")
  if data then
      DebugPrint("Response Data: " .. tostring(data), "Rx")
  end
end

function prettyPrintTable(tab)
  print("Table:\n" .. rapidjson.encode(tab, { pretty = true }))
end

-- **Calculate network prefix from netmask and broadcast address**
-- Returns a CIDR notation prefix (e.g., "192.168.1.0/24") and sets control choices
function calculateNetworkPrefix(netmask, broadcast)
  local cidrMap = {
    ["255.255.255.0"] = 24, ["255.255.254.0"] = 23, ["255.255.252.0"] = 22,
    ["255.255.248.0"] = 21, ["255.255.240.0"] = 20, ["255.255.224.0"] = 19,
    ["255.255.192.0"] = 18, ["255.255.128.0"] = 17, ["255.255.0.0"] = 16
  }
  local cidr = cidrMap[netmask] or 24

  local octets = {}
  for octet in broadcast:gmatch("%d+") do
    octets[#octets + 1] = tonumber(octet)
  end

  local hostBits = 32 - cidr
  local hostRange = 2 ^ hostBits - 1
  local networkFourth = octets[4] - (octets[4] % (hostRange + 1))
  local networkThird = octets[3]
  Controls.BaseOctets[1].String = octets[1]
  Controls.BaseOctets[2].String = octets[2]
  local thirdOctetChoices = {}
  if cidr >= 24 then
    thirdOctetChoices = { tostring(networkThird) }
  else
    local subnetBits = 24 - cidr
    local subnetRange = 2 ^ subnetBits
    local baseThird = networkThird - (networkThird % subnetRange)
    for i = 0, subnetRange - 1 do
      table.insert(thirdOctetChoices, tostring(math.floor(baseThird + i)))
    end
  end

  local lastOctetChoices = {}
  for i = 1, 254 do
      table.insert(lastOctetChoices, tostring(i))
  end

  Controls.ThirdOctet.Choices = thirdOctetChoices
  Controls.LastOctet.Choices = lastOctetChoices
  Controls.ThirdOctet.String = thirdOctetChoices[1] or "1"
  Controls.LastOctet.String = "1"

  return string.format("%d.%d.%d.%d/%d", octets[1], octets[2], networkThird, networkFourth, cidr)
end

-- **Populate network interface controls with current LAN settings**
function populateNetworkInterfaceControls()
  local ni = Network.Interfaces()
  local lanAConfig, lanBConfig = {}, {}

  for _, item in ipairs(ni) do
    if item.Interface == "LAN A" then
      broadcastRange = item.BroadcastAddress
      netMask = item.Netmask
      Controls.NewNetworkPrefix.String = calculateNetworkPrefix(item.Netmask, item.BroadcastAddress)
      Controls.NewNetmask.String = Controls.NewNetmask.String == "" and item.Netmask or Controls.NewNetmask.String
      Controls.NewGateway.String = Controls.NewGateway.String == "" and item.Gateway or Controls.NewGateway.String
      Controls.NewIPRange.String = Controls.NewIPRange.String == "" and calculateIPRangeFromGateway(Controls.NewNetworkPrefix.String) or Controls.NewIPRange.String
      lanAConfig = { Interface = "LAN A", Address = item.Address, Netmask = item.Netmask, Gateway = item.Gateway, BroadcastAddress = item.BroadcastAddress }
    elseif item.Interface == "LAN B" then
      lanBConfig = { Interface = "LAN B", Address = item.Address, Netmask = item.Netmask, Gateway = item.Gateway, BroadcastAddress = item.BroadcastAddress }
    end
  end

  Controls.CurrentLanAConfig.String = rapidjson.encode(lanAConfig, {pretty = true})
  Controls.CurrentLanBConfig.String = rapidjson.encode(lanBConfig, {pretty = true})
end




-- **Update inventory from design data and detect status changes**
function updateInventory()
  if refresh == true then
    getDevices()
  end
  local statusChanged = false
  
  for _, v in pairs(Design.GetInventory()) do
    local model, name, code = v.Model, v.Name, v.Status.Code
    
    if LastStatusCodes[name] and LastStatusCodes[name] ~= code then
        statusChanged = true
    end
    LastStatusCodes[name] = code
    
    if Inventory.Types[v.Type] or v.Type == "" then
      if not Inventory.ModelsLookup[model] then
        table.insert(Inventory.Models, model)
        Inventory.ModelsLookup[model] = true
      end
      if not Inventory.NamesLookup[name] then
        table.insert(Inventory.Names, name)
        Inventory.NamesLookup[name] = true
        Inventory.NameToModel[name] = model
        if not Inventory.ByModel[model] then
          Inventory.ByModel[model] = {}
        end   
        if not Inventory.ByModelLookup[model] then
          table.insert(Inventory.ByModel[model], name)
          Inventory.ByModelLookup[model] = true
        else 
          table.insert(Inventory.ByModel[model], name)
        end
      end
      Controls.InventoryModel.Choices = Inventory.Models
    end
  end
  
  if statusChanged then
      getDevices()
  end
end
-- Start inventory update timer (runs every 5 seconds)
inventoryTimer.EventHandler = updateInventory
inventoryTimer:Start(5)
updateInventory()


-- **Download configuration from a peripheral device**
function downloadFromPeripherals(ip, name, t)
  DebugFunctionEntry("downloadFromPeripherals", ip, name, t)
  DebugPrint("Downloading configuration from " .. name .. " at " .. ip, "tx")
  
  HttpClient.Download({
    Url = "https://" .. ip .. "/cgi-bin/status_xml",
    Timeout = 30,
    Headers = {},
    EventHandler = function(_, code, data)
      DebugNetworkResponse("https://" .. ip .. "/cgi-bin/status_xml", code, data)
      if code == 200 then
        DebugPrint("Received configuration from " .. name, "rx")
        Peripherals[name] = {
          ip = ip,
          mac = data:match("<mac_address>(.-)</mac_address>") or "N/A",
          design = data:match("<pretty_name>(.-)</pretty_name>") or "N/A",
          firmware = data:match("<firmware_version>(.-)</firmware_version>") or "N/A",
          hostname = data:match("<device_name%s*>(.-)</device_name>") or "N/A",
          id = data:match("<id_mode>(.-)</id_mode>") or "N/A",
          model = data:match("<device_model_pretty>(.-)</device_model_pretty>") or "N/A",
          interface = {
            mode = data:match("<mode%s*>(.-)</mode>") or "N/A",
            address = data:match("<address%s*>(.-)</address>") or "N/A",
            netmask = data:match("<mask%s*>(.-)</mask>") or "N/A",
            default_route = data:match("<gateway%s*>(.-)</gateway>") or "N/A",
          }
        }
        Controls.DesignOnDevice[t].String = Peripherals[name].design
        local colorMap = { [""] = "", [Controls.LocalDesignName.String] = "green" }
        Controls.DesignOnDevice[t].Color = colorMap[Controls.DesignOnDevice[t].String] or "yellow"
        Controls.ID[t].Legend = "ID: " .. string.upper(Peripherals[name].id)
        Controls.ID[t].Boolean = (Peripherals[name].id == "on")
      else
        DebugPrint("Failed to download configuration from " .. name .. ": " .. code, "rx")
      end
    end
  })
  DebugFunctionExit("downloadFromPeripherals")
end

-- **Map models to device names for assignment choices**
function modelHandling(model, name)
  if not model then
    return
  end
  model = string.upper(model)
  if not tabModeltoName[model] then
    tabModeltoName[model] = {""}
  end
  if not tabModelNameLookup[name] then
    table.insert(tabModeltoName[model], name)
    for i = 1, #tabModeltoName[model] do
      if tabModeltoName[model][i] == name then
        tabModelNameLookup[name] = i
        break
      end
    end
  end
end

-- **Parse discovered devices from core HTTP response**
function parseDevices(headers, code, data)
  DebugPrint("Starting device discovery", "function")
  if code ~= 200 then
    DisplayPrint("Failed to fetch devices: " .. code)
    DebugPrint("Failed to fetch devices: " .. code, "rx")
    return
  end
  local decoded = rapidjson.decode(data)
  t = 1

  for _, elem in pairs(decoded) do
    if elem.type ~= "core" then
      if refreshname and  elem.name == string.lower(refreshname) then
        refresh = false
        DebugPrint("Refresh stopped for "..elem.name, "function")
      end
      DebugPrint("Found device: " .. elem.name .. " with IP: " .. elem.lan_a_ip, "rx")
      table.insert(Devices, elem.name)
      table.insert(IPs, elem.lan_a_ip)
      table.insert(DeviceTypes, elem.part_number)
      DevicesAndIPs[elem.name] = elem.lan_a_ip
      DeviceTypeLookup[elem.name] = elem.part_number
      Peripherals[elem.name] = { ip = elem.lan_a_ip }
      modelHandling(elem.part_number, elem.name)
      DevicesLookup[Devices[t]] = t
      downloadFromPeripherals(elem.lan_a_ip, elem.name, t)
      Controls.DeviceModel[t].String = elem.part_number or ""
      Controls.DeviceName[t].String = elem.name or ""
      Controls.DeviceIP[t].String = elem.lan_a_ip or ""
      Controls.DeviceModel[t].IsInvisible = false
      Controls.DeviceName[t].IsInvisible = false
      Controls.DeviceIP[t].IsInvisible = false
      Controls.DesignOnDevice[t].IsInvisible = false
      Controls.ID[t].IsInvisible = false
      Controls.IDPairing[t].IsInvisible = false
      Controls.PeripheralInfo[t].IsInvisible = false
      t = t + 1
    else
      DebugPrint("Found core device: " .. elem.name, "rx")
      Cores[elem.name] = elem
    end
  end
  Controls.Device.Choices = Devices
end

-- **Get IP mode (Static or DHCP) and update control states**
function getIPMode()
    local ipMode = Controls.IPMode.Boolean and "Static" or "DHCP"
    Controls.LastOctet.Color = ""
    -- Controls.NewNetmask.IsDisabled = not Controls.IPMode.Boolean
    -- Controls.NewGateway.IsDisabled = not Controls.IPMode.Boolean
    Controls.ThirdOctet.IsDisabled = not Controls.IPMode.Boolean
    Controls.LastOctet.IsDisabled = not Controls.IPMode.Boolean
    -- Controls.NewIPRange.IsDisabled = not Controls.IPMode.Boolean
    -- Controls.NewNetworkPrefix.IsDisabled = not Controls.IPMode.Boolean
    return ipMode
end

function checkForReset ()
  if Controls.AssignToDevice.String ~= "" and Controls.InventoryName.String ~= "" then 
    Controls.ResetName.IsDisabled = false
    Controls.Assign.IsDisabled = false
  else
    Controls.ResetName.IsDisabled = true 
    Controls.Assign.IsDisabled = true
  end 
end


-- **Fetch and display all devices on the network**
function getDevices()
  checkForReset ()
  Controls.AssignToDevice.String = ""
  t = 1
  for i = 1, #Controls.DeviceModel do
    Controls.DeviceModel[i].IsInvisible = true
    Controls.DeviceName[i].IsInvisible = true
    Controls.DeviceIP[i].IsInvisible = true
    Controls.DesignOnDevice[i].IsInvisible = true
    Controls.ID[i].IsInvisible = true
    Controls.IDPairing[i].IsInvisible = true
    Controls.PeripheralInfo[i].IsInvisible = true
    Controls.DeviceModel[i].String = ""
    Controls.DeviceName[i].String = ""
    Controls.DeviceIP[i].String = ""
    Controls.DesignOnDevice[i].String = ""
    Controls.ID[i].String = ""
    Controls.IDPairing[i].String = ""
    Controls.PeripheralInfo[i].String = ""
  end
  Controls.IPMode.Legend = getIPMode()
  Devices, IPs, DeviceTypes, DevicesAndIPs, DeviceTypeLookup, tabModeltoName, tabModelNameLookup = {}, {}, {}, {}, {}, {}, {}

  local coreIP = ""
  for _, item in ipairs(Network.Interfaces()) do
    if item.Interface == "LAN A" then
      coreIP = item.Address
      broadcastRange = item.BroadcastAddress
      netMask = item.Netmask
      break
    end
  end
  HttpClient.Download({
    Url = "https://" .. coreIP .. "/debug/remote_support/network_debug/discovered_devices",
    Timeout = 30,
    Headers = {},
    EventHandler = parseDevices
  })
  populateNetworkInterfaceControls()
end

-- **Configure a peripheral to use DHCP**
function setPeripheralToDHCP(name)
  local payload = string.format([[<network_configuration>
    <hostname>%s</hostname>
    <enable_dns/>
    <primary_dns/>
    <secondary_dns/>
    <interface><name>LAN A</name><mode>auto</mode><address/><netmask/><default_route/></interface>
    </network_configuration>]], Peripherals[name].hostname or name)
  HttpClient.Upload({
    Url = "https://" .. Peripherals[name].ip .. "/cgi-bin/network_configuration_xml",
    Data = payload,
    Method = "POST",
    Timeout = 30,
    Headers = { ["Content-Type"] = "text/xml" },
    EventHandler = function(_, code, data)
      DisplayPrint("Set DHCP for " .. name .. ": " .. (code == 200 and "Success" or "Failed: " .. data))
    end
  })
end

-- **Configure a peripheral witha new or old name and static IP or DHCP**
function setPeripheral(oldName, newName, ip, netmask, defaultRoute, mode)
  DebugFunctionEntry("setPeripheral", oldName, newName, ip, netmask, defaultRoute, mode)
  DebugPrint("Setting peripheral " .. oldName .. " to " .. newName .. " with mode " .. mode, "function")
  
  if mode == "auto" then
    ip, netmask, defaultRoute = "", "", ""
  end
  local originalIP = DevicesAndIPs[oldName]
  local model = DeviceTypeLookup[oldName]
  local payload = string.format([[<network_configuration>
    <hostname>%s</hostname>
    <enable_dns/>
    <primary_dns/>
    <secondary_dns/>
    <interface><name>LAN A</name><mode>%s</mode><address>%s</address><netmask>%s</netmask><default_route>%s</default_route></interface>
  </network_configuration>]], newName, mode, ip, netmask, defaultRoute)
  
  DebugPrint("Sending configuration to " .. oldName .. " at " .. originalIP, "tx")
  DebugNetworkRequest("https://" .. originalIP .. "/cgi-bin/network_configuration_xml", "POST", payload)
  
  HttpClient.Upload({
    Url = "https://" .. originalIP .. "/cgi-bin/network_configuration_xml",
    Data = payload,
    Method = "POST",
    Timeout = 30,
    Headers = { ["Content-Type"] = "text/xml" },
    EventHandler = function(_, code, data)
      DebugNetworkResponse("https://" .. originalIP .. "/cgi-bin/network_configuration_xml", code, data)
      if code == 200 then
        DebugPrint("Successfully configured " .. newName, "rx")
        if mode == "static" then
          DisplayPrint("✓ Success \t\t Inventory Name:    " .. newName .. " \n\t\t\t Model: " .. model .. " \t Static IP: " .. ip)
          Controls.Assign.Legend = newName .. " \n✓ Success \n"..ip
          Timer.CallAfter(function()buildDirectionsString() Controls.Assign.IsDisabled = true  end,5) 
        else 
          DisplayPrint("✓ Success \t\t inventory Name:    " .. newName .. " \n\t\t\t Model: " .. model .. " \t IP mode: DHCP")
          Controls.Assign.Legend = newName .. " \n✓ Success \n DHCP"
          Timer.CallAfter(function()buildDirectionsString() Controls.Assign.IsDisabled = true end,5) 
        end 
        Peripherals[newName] = { ip = ip }
        
        if oldName ~= newName then Peripherals[oldName] = nil end
        Controls.InventoryName.String = ""
        DebugPrint("Setting assign to device choices to empty", "function")
        Controls.AssignToDevice.Choices = {}
      else
        DebugPrint("Failed to configure " .. newName .. ": " .. data, "rx")
        DisplayPrint("\nFailed to set static for " .. newName .. ": " .. data)
      end
      if Controls.PairWithID.Boolean then
        PairingMode()
        Controls.PairWithID.Boolean = false
        PairingMode()
      end
      Controls.AssignToDevice.String = ""
    end
  })
  DebugFunctionExit("setPeripheral")
end




-- **Reset a device's name to a default format (model-MAC last 4)**
function resetName(model, name, ip)

  name = string.lower(name)
  local i = DevicesLookup[name] or 1
  model = model or Controls.DeviceModel[i].String
  if model == "I/O-USB-Bridge" then
    model = "iousb"
  end
  ip = ip or Controls.DeviceIP[i].String
  local mode = "auto"
  local mac = ""
  if not Peripherals[name].mac then 
    mac = tostring(math.random(100000000000000, 999999999999999)) 
  else 
    mac = string.gsub(Peripherals[name].mac or "", ":", "") 
  end
  local lastFour = mac:sub(-4)
  local newName = model .. "-" .. lastFour
  setPeripheral(name, newName, ip, netMask, Controls.NewGateway.String, mode)
  DisplayPrint("✓ Success\t\t Reset name for " .. name .. " to: " .. newName)
  refresh = true 
  refreshname = newName
  Timer.CallAfter(getDevices, 30)
  Controls.AssignToDevice.Choices = {}
end

-- **Calculate IP range from gateway and netmask**
function calculateIPRangeFromGateway(prefix)
  -- Parse IP and CIDR parts (e.g., "192.168.1.0/24")
  local ip, cidr = prefix:match("(%d+%.%d+%.%d+%.%d+)/(%d+)")
  
  -- Convert to octets array
  local octets = {}
  for part in ip:gmatch("%d+") do
    octets[#octets + 1] = tonumber(part)
  end
  cidr = tonumber(cidr)
  -- Calculate the base network address based on CIDR prefix
  local base = octets[3] - (octets[3] % (2 ^ (24 - cidr)))
  -- Return IP range
  return string.format("%d.%d.%d.1-%d.%d.%d.254", octets[1], octets[2], base, octets[1], octets[2], base + (2 ^ (24 - cidr)) - 1)
end
-- **Convert netmask to CIDR notation**
function getSubnetMaskCIDR(netmask)
  local cidrMap = {
    ["255.255.255.0"] = 24, ["255.255.254.0"] = 23, ["255.255.252.0"] = 22,
    ["255.255.248.0"] = 21, ["255.255.240.0"] = 20, ["255.255.224.0"] = 19,
    ["255.255.192.0"] = 18, ["255.255.128.0"] = 17, ["255.255.0.0"] = 16
  }
  return cidrMap[netmask] or 24
end
-- **Check if inventory name matches a device name and reset if needed**
function checkAndResetNameIfNeeded(device)
  local inventoryName = string.lower(Controls.InventoryName.String)
  local assignToDevice = string.lower(device or Controls.AssignToDevice.String)
  -- Only proceed if inventory name is set and doesn't match the assign to device
  if inventoryName == assignToDevice then
      return false
  end
  if inventoryName ~= "" and inventoryName ~= assignToDevice then
    for i = 1, #Controls.DeviceName do
        -- Check if inventory name matches this device name
      if inventoryName == string.lower(Controls.DeviceName[i].String) then
        -- Found a match, reset the name
        DisplayPrint("⚠️Warning⚠️\t\t Found matching device name: " .. Controls.InventoryName.String)
        resetName(Controls.DeviceModel[i].String, Controls.DeviceName[i].String, Controls.DeviceIP[i].String)
        return false
      end
    end
  end
  
  return false
end

-- **Assign a device to an inventory item with IP configuration**
function applyAssign(device)
  DebugPrint("Starting device assignment process", "function")
  
  if checkAndResetNameIfNeeded(device) then
      DebugPrint("Name reset needed, returning early", "function")
      return
  end

  if Controls.InventoryName.String == "" then
      DebugPrint("Error: Inventory Name cannot be empty", "function")
      DisplayPrint("\nError: Inventory Name cannot be empty")
      return
  end
  if Controls.AssignToDevice.String == "" and not Controls.PairWithID.Boolean then
      DebugPrint("Error: Assign To Device cannot be empty", "function")
      DisplayPrint("\nError: Assign To Device cannot be empty")
      return
  end

  if not Controls.PairWithID.Boolean then
    device = Controls.AssignToDevice.String
  end

  local mode = Controls.IPMode.Boolean and "static" or "auto"
  DebugPrint("Using IP mode: " .. mode, "function")

  local oldName = device
  local peripheralName = Controls.InventoryName.String
  local originalIP = DevicesAndIPs[device]
  if not originalIP then
      DebugPrint("Error: Could not find IP for device " .. oldName, "function")
      DisplayPrint("\nError: Could not find IP for device " .. oldName)
      return
  end

  local octets = {}
  for octet in originalIP:gmatch("%d+") do
    table.insert(octets, octet)
  end
  local newIP = string.format("%d.%d.%s.%s", tonumber(octets[1]), tonumber(octets[2]), Controls.ThirdOctet.String, Controls.LastOctet.String)
  local netmask = Controls.NewNetmask.String or "255.255.254.0"
  local defaultRoute = Controls.NewGateway.String or "0.0.0.0"
  
  DebugPrint("New IP configuration - IP: " .. newIP .. ", Netmask: " .. netmask .. ", Gateway: " .. defaultRoute, "function")
  
  if mode == "auto" then
    DebugPrint("Using DHCP mode, proceeding with configuration", "function")
    setPeripheral(oldName, peripheralName, newIP, netmask, defaultRoute, mode)
    return
  end
  if newIP == originalIP then
    DebugPrint("IP unchanged, proceeding with configuration", "function")
    setPeripheral(oldName, peripheralName, newIP, netmask, defaultRoute, mode)
    return
  end

  DebugPrint("Checking IP availability with ping", "function")
  local ping = Ping.New(newIP)
  ping:setTimeoutInterval(2.0)
  ping:setPingInterval(1.0)
  local pingComplete = false
  local timeoutTimer = Timer.New()

  timeoutTimer.EventHandler = function()
    if not pingComplete then
      DebugPrint("Ping timeout - assuming IP is available", "function")
      DisplayPrint("✓ Ping timeout\t\tassuming IP is available")
      pingComplete = true
      ping:stop()
      setPeripheral(oldName, peripheralName, newIP, netmask, defaultRoute, mode)
    end
    timeoutTimer:Stop()
  end
  ping.EventHandler = function(response)
    if not pingComplete then
      DebugPrint("Warning: IP " .. response.HostName .. " is in use", "function")
      DisplayPrint("⚠️Warning⚠️ \t\tIP " .. response.HostName .. " in use\n\t\t\t Please check the IP address and try again")
      Controls.LastOctet.Color = "red"
      pingComplete = true
      ping:stop()
      timeoutTimer:Stop()
    end
  end
  ping.ErrorHandler = function(response)
    if not pingComplete then
      DebugPrint("IP " .. response.HostName .. " is available", "function")
      DisplayPrint("\n Ping failed - IP " .. response.HostName .. " available\n\t\t\t Proceeding with assignment")
      pingComplete = true
      ping:stop()
      timeoutTimer:Stop()
      setPeripheral(oldName, peripheralName, newIP, netmask, defaultRoute, mode)
    end
  end
  timeoutTimer:Start(3)
  ping:start(true)
end

-- **Convert boolean to ID mode string ("on" or "off")**
function idMode(bool)
    return bool and "on" or "off"
end

-- **Listen for ID mode on devices of a specific model**
-- Used in pairing mode to detect when a device's ID is activated
function listenForIDMode(model)
  DebugPrint("Starting ID mode listener for model: " .. model, "function")
  RefreshTimer.EventHandler = function()
    for _, name in pairs(tabModeltoName[model] or {}) do
      if name ~= "" then
        local ip = DevicesAndIPs[name]
        DebugPrint("Checking ID mode for device: " .. name, "tx")
        HttpClient.Download({
          Url = "https://" .. ip .. "/cgi-bin/status_xml",
          Timeout = 30,
          Headers = {},
          EventHandler = function(_, code, data)
            if code == 200 then
              local device = string.lower(data:match("<device_name%s*>(.-)</device_name>") or "N/A")
              local id = data:match("<id_mode>(.-)</id_mode>") or "N/A"
              if id == "on" then
                DebugPrint("ID mode detected on device: " .. device, "rx")
                applyAssign(device)
                RefreshTimer:Stop()
                DebugPrint("Turning off ID mode for device: " .. device, "tx")
                HttpClient.Download({
                  Url = "https://" .. ip .. "/cgi-bin/id_mode?mode=off",
                  Timeout = 30,
                  Headers = {},
                  EventHandler = function(_, code, data)
                    if code == 200 then
                      DebugPrint("Successfully turned off ID mode", "rx")
                    else
                      DebugPrint("Failed to turn off ID mode: " .. code, "rx")
                    end
                  end
                })
              end
            end
          end
        })
      end
    end
  end
  RefreshTimer:Start(5)
end

-- **Toggle pairing mode for ID-based assignment**

function hidePairIdWarning ()
  local hide = not Controls.PairWithID.Boolean
   Controls.PairWithIdDirections[2].IsInvisible  = hide 

  return hide
end
Controls.Control_2.EventHandler = function ()
  Controls.PairWithIdDontShowAdgain.Boolean = Controls.Control_2.Boolean
end 
-- When enabled, listens for ID activation on devices matching the selected model
function PairingMode(b)

  Controls.PairWithID.Boolean = b
  if b then
    hidePairIdWarning ()
    
    Controls.InventoryName.String = ""
    Controls.InventoryModel.String = ""
    Controls.AssignToDevice.String = ""
    Controls.AssignToDevice.IsDisabled = true
    Controls.Assign.IsInvisible = true
    Controls.ResetName.IsInvisible = true
    Controls.Assign.IsDisabled = true
    Controls.IPMode.IsInvisible = true
    Controls.LastOctet.IsDisabled = true 
    Controls.ThirdOctet.IsDisabled = true
    Controls.IPMode.Boolean = false 
    Controls.IPMode.Legend = getIPMode()
    for i = 1, #Controls.ID do
      Controls.ID[i].IsDisabled = true
      if Controls.DeviceName[i].String ~= "" then
        local ip = Controls.DeviceIP[i].String
        local name = Controls.DeviceName[i].String
        local t = i
        print("setting id mode to off for " .. name)
        HttpClient.Download({
          Url = "https://" .. ip .. "/cgi-bin/id_mode?mode=off",
          Timeout = 30,
          Headers = {},
          EventHandler = function(_, code, data)
            Timer.CallAfter(function() downloadFromPeripherals(ip, name, t) end, 1)
          end
        })
      end
    end
    modelcheckID = false
    namecheckID = false
    peripheralcheckID = false
    buildDirectionsString()
  else
    for i = 1, #Controls.ID do
      Controls.ID[i].IsDisabled = false
    end
    Controls.AssignToDevice.IsDisabled = false
    -- Controls.Assign.IsDisabled = false
    Controls.Assign.IsInvisible = false
    Controls.IPMode.IsInvisible = false
    Controls.ResetName.IsInvisible = false
    Controls.PairWithIdDirections[2].IsInvisible , Controls.PairWithIdDontShowAdgain.IsInvisible = true, true 
    buildDirectionsString()
  end
end

-- **Send ID mode command to a device**
function sendId(ip, name, t, mode)
  HttpClient.Download({
    Url = "https://" .. ip .. "/cgi-bin/id_mode?mode=" .. mode,
    Timeout = 30,
    Headers = {},
    EventHandler = function(_, code, data)
      if code == 200 then
        Timer.CallAfter(function() downloadFromPeripherals(ip, name, t) end, 1)
      end
    end
  })
end

-- **Handle inventory model selection**
function handleInventoryModel()
  local model = Controls.InventoryModel.String
  if model == "" then
    Controls.InventoryModel.Choices = Inventory.Models
    Controls.InventoryName.Choices = Inventory.Names
    Controls.AssignToDevice.Choices = { "" }
    Controls.AssignToDevice.String = ""
  else
    Controls.InventoryName.Choices = Inventory.ByModel[model] or { "" }
    Controls.InventoryName.String = Inventory.ByModel[model] and Inventory.ByModel[model][1] or ""
  end
  Controls.InventoryName.String = ""
  Controls.AssignToDevice.Choices = {}
  Controls.AssignToDevice.String = ""
end

-- **Event Handlers**

Controls.InventoryName.EventHandler = function()
  if Controls.InventoryName.String ~= "" then 
    namecheckID = true 
  else namecheckID = false 
  end 
  checkForReset ()
  local name = Controls.InventoryName.String
  if name == "" then
    Controls.InventoryModel.Choices = Inventory.Models
    Controls.InventoryName.Choices = Inventory.Names
    Controls.AssignToDevice.Choices = { "" }
  else
    local model = string.upper(Inventory.NameToModel[name])
    Controls.AssignToDevice.Choices = tabModeltoName[model] or { "" }
  end
  if Controls.PairWithID.Boolean then
    Controls.AssignToDevice.Choices = { "" }
    local model = string.upper(Inventory.NameToModel[name])
    listenForIDMode(model)
    print("listenForIDMode called from inventoryname")
  end
  buildDirectionsString()
end

Controls.InventoryModel.EventHandler = function()
  if Controls.InventoryModel.String ~= "" then 
    modelcheckID = true 
  else modelcheckID = false 
  end 
  checkForReset ()
  if Controls.PairWithID.Boolean then
    Controls.InventoryName.String = ""
    Controls.AssignToDevice.String = ""
    Controls.AssignToDevice.Choices = { "" }
    -- local model = Controls.InventoryModel.String
    -- if model ~= "" then
    --   listenForIDMode(string.upper(model))
    --   print("listenForIDMode called from inventorymodel")
    -- end
  end
  handleInventoryModel()
  buildDirectionsString()
end

Controls.Device.EventHandler = function()
  local device = Controls.Device.String
  Controls.IP.String = DevicesAndIPs[device] or ""
  if Peripherals[device] then
    Controls.StaticOrAuto.String = Peripherals[device].interface.mode
    Controls.Dtype.String = DeviceTypeLookup[device] or ""
  elseif Cores[device] then
    Controls.StaticOrAuto.String = Cores[device].Network and Cores[device].Network[1].mode or "N/A"
  end
end

Controls.Get.EventHandler = getDevices

Controls.Reboot.EventHandler = function()
  HttpClient.Download({
    Url = "https://" .. Controls.IP.String .. "/cgi-bin/device-reboot",
    Timeout = 30,
    Headers = {},
    EventHandler = function(_, code, data) DisplayPrint("Reboot response: " .. code) end
  })
end

Controls.DownloadLogfile.EventHandler = function()
  local ip = Controls.IP.String
  if ip ~= "" then
    HttpClient.Download({
      Url = "https://" .. ip .. "/cgi-bin/system_state",
      Timeout = 30,
      Headers = {},
      EventHandler = function(_, code, data)
        if code == 200 then
          local file = io.open("media/log_" .. Controls.Device.String .. "_" .. os.date() .. ".qsyslog", "wb")
          file:write(data)
          file:close()
          DisplayPrint("Log saved!")
        else
          DisplayPrint("Log download failed: " .. code)
        end
      end
    })
  end
end

Controls.SetStatic.EventHandler = function()
  setPeripheral(Controls.Device.String, Controls.Device.String, Controls.IP.String, netMask, Controls.NewGateway.String, "static")
end

Controls.LastOctet.EventHandler = function()
  Controls.LastOctet.Color = ""
end


Controls.SetDHCP.EventHandler = function()
  setPeripheralToDHCP(Controls.Device.String)
end

Controls.ScanIPs.EventHandler = function()
  local base = broadcastRange:match("(%d+%.%d+%.%d+%.).+")
  local cidr = getSubnetMaskCIDR(netMask)
  local found = {}
  for i = 1, 254 do
    local ip = base .. i
    local ping = Ping.New(ip)
    ping:start(false)
    ping:setPingInterval(5.0)
    ping.EventHandler = function(resp)
      if not found[resp.HostName] then
        found[resp.HostName] = true
        DisplayPrint("Found: " .. resp.HostName)
      end
    end
  end
end

Controls.AssignToDevice.EventHandler = function()
  if Controls.AssignToDevice.String ~= "" then
    peripheralcheckID = true
  else 
    peripheralcheckID = false
  end
  checkForReset()
  buildDirectionsString()
  local selectedDevice = Controls.AssignToDevice.String
  if selectedDevice and DevicesAndIPs[selectedDevice] then
    local deviceIP = DevicesAndIPs[selectedDevice]
    local octets = {}
    for octet in deviceIP:gmatch("%d+") do
        table.insert(octets, octet)
    end
    if #octets >= 4 then
        Controls.ThirdOctet.String = octets[3]
        Controls.LastOctet.String = octets[4]
    end
  end
end

Controls.IPMode.EventHandler = function()
  Controls.IPMode.Legend = getIPMode()
end

for i = 1, #Controls.ID do
  Controls.ID[i].EventHandler = function()
    local bool = Controls.ID[i].Boolean
    local ip = Controls.DeviceIP[i].String
    local name = Controls.DeviceName[i].String
    local t = i
    sendId(ip, name, t, idMode(bool))
  end
end

Controls.Assign.EventHandler = function()
  applyAssign(Controls.AssignToDevice.String)
  print("Assign button pressed by assign eventhandler")
  buildDirectionsString()
end

Controls.ResetName.EventHandler = function ()
  local name = Controls.AssignToDevice.String
  local ip = DevicesAndIPs[Controls.AssignToDevice.String]
  local model = DeviceTypeLookup[name] or DeviceTypeLookup[Controls.InventoryName.String]
  resetName(model, name, ip)
  buildDirectionsString()
end 

Controls.PairWithID.EventHandler = function ()
  PairingMode(Controls.PairWithID.Boolean)
end 

Controls.PairWithIdDontShowAdgain.EventHandler = hidePairIdWarning

function buildDirectionsString()
    -- Check if inventory name, model, and device are selected
    if Controls.InventoryName.String == "" then
        namecheckID = false
    end
    
    if Controls.InventoryModel.String == "" then
        modelcheckID = false
    end
    
    if Controls.AssignToDevice.String == "" then
        peripheralcheckID = false
    end

    -- First directions string (for PairWithIdDirections[1])
    local header1 = "Follow these steps to pair a device to the system:"
    local step1 = "1. Select a model from the inventory" .. (modelcheckID and " ✓" or "")
  local step2 = "2. Select a name from the inventory" .. (namecheckID and " ✓" or "")
  local step3 = "3. Select the Peripheral to pair" .. (peripheralcheckID and " ✓" or "")
  local step4 = "4. Press the green button"
  
  local directions1 = header1 .. "\n" .. step1
  Controls.Assign.Legend = "Select Model\nand\nName"
  if modelcheckID then
    directions1 = directions1 .. "\n" .. step2
    Controls.Assign.Legend = "Select Model\nand\nName"
  end
  
  if modelcheckID and namecheckID then
    directions1 = directions1 .. "\n" .. step3
    Controls.Assign.Legend = "Select\nPeripheral"
  end
  if modelcheckID and namecheckID and peripheralcheckID then
    directions1 = directions1 .. "\n" .. step4
    Controls.Assign.Legend = "Assign\nPeripheral"
  end
  Controls.PairWithIdDirections[1].String = directions1

  -- Second directions string (for PairWithIdDirections[2])
  local header2 = "--Caution! Pairing with ID is not supported on all devices.   \n--Make sure that only you perform this operation. \n--Be careful not to pair with a device outside \n of the devices meant for this system. \n\n"
  local step1_id = "1. Select a model from the inventory" .. (modelcheckID and " ✓" or "")
  local step2_id = "2. Select a name from the inventory" .. (namecheckID and " ✓" or "")
  local step3_id = "3. Press the ID button on the device"
  
  local directions2 = header2 .. "\n" .. step1_id
  
  if modelcheckID then
    directions2 = directions2 .. "\n" .. step2_id
  end
  
  if modelcheckID and namecheckID then
    directions2 = directions2 .. "\n" .. step3_id
  end
  
  Controls.PairWithIdDirections[2].String = directions2
end

-- Initial device discovery
getDevices()
PairingMode(false)
buildDirectionsString()
