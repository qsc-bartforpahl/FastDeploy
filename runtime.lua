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
  Locations = {""},
  LocationsLookup = {},
  Models = {},            -- List of inventory models
  ModelsLookup = {},      -- Quick lookup for models
  Names = {},             -- List of inventory names
  NamesLookup = {},       -- Quick lookup for names
  ModelToName = {},       -- Mapping: model -> name
  NameToModel = {},       -- Mapping: name -> model
  NameToLocation = {},    -- Mapping: name -> location
  ByModel = {},           -- Lookup: model -> list of names
  ByLocation = {},        -- Mapping: location -> models and names
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
local idPairingGeneration = 0
local idPairingBusy = false
local idModePreparedModel = nil
local idModeClearingModel = nil
local navigationCursorName = ""
local lastSuccessfulInventoryName = ""
local lastHandledInventoryName = ""
local deviceDiscoveryGeneration = 0
local discoveryInProgress = false
local discoveryRefreshRequested = false
local activeIDPollCycle = nil
local peripheralRequestQueue = {}
local peripheralRequestsInFlight = 0
local MAX_CONCURRENT_PERIPHERAL_REQUESTS = 4
-- Network globals
broadcastRange = ""         -- Broadcast address for the network
netMask = ""          -- Subnet mask for the network
t = 1                 -- Global index for device control updates

--Debug level settings
DebugSetting = Properties["Debug Print"].Value
-- Set design name on startup
Controls.LocalDesignName.String = Design.GetStatus().DesignName
Controls.AssignToDevice.String = ""
Controls.InventoryLocation.Color = ""
Controls.InventoryModel.Color = ""
Controls.InventoryName.Color = ""
-- Initialize device controls to a cleared state
refresh = false
for i = 1, #Controls.DeviceModel do
  Controls.DeviceModel[i].String = ""
  Controls.DeviceName[i].String = ""
  Controls.DeviceIP[i].String = ""
end
Controls.Assign.Legend = "Assign\nto\nPeripheral" 

local function sortNames(values)
  table.sort(values, function(a, b)
    local lowerA, lowerB = string.lower(a), string.lower(b)
    if lowerA == lowerB then return a < b end
    return lowerA < lowerB
  end)
end

local function appendUnique(values, lookup, value)
  if value and value ~= "" and not lookup[value] then
    lookup[value] = true
    table.insert(values, value)
  end
end

local function withEmptyChoice(values)
  local choices = {""}
  for _, value in ipairs(values) do
    table.insert(choices, value)
  end
  return choices
end

local function pumpPeripheralRequestQueue()
  while peripheralRequestsInFlight < MAX_CONCURRENT_PERIPHERAL_REQUESTS
    and #peripheralRequestQueue > 0 do
    local queued = table.remove(peripheralRequestQueue, 1)
    peripheralRequestsInFlight = peripheralRequestsInFlight + 1
    local eventHandler = queued.request.EventHandler
    queued.request.EventHandler = function(...)
      peripheralRequestsInFlight = peripheralRequestsInFlight - 1
      if eventHandler then eventHandler(...) end
      pumpPeripheralRequestQueue()
    end
    queued.send(queued.request)
  end
end

local function queuePeripheralRequest(request, method, category, onCancel)
  local send = method == "Upload" and HttpClient.Upload or HttpClient.Download
  table.insert(peripheralRequestQueue, {
    request = request,
    send = send,
    category = category,
    onCancel = onCancel
  })
  pumpPeripheralRequestQueue()
end

local function cancelQueuedPeripheralRequests(category)
  local retained = {}
  for _, queued in ipairs(peripheralRequestQueue) do
    if queued.category == category then
      if queued.onCancel then queued.onCancel() end
    else
      table.insert(retained, queued)
    end
  end
  peripheralRequestQueue = retained
end

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
local function getInventoryModels(location)
  local locationData = Inventory.ByLocation[location]
  return locationData and locationData.Models or {}
end

local function getInventoryNames(location, model)
  local locationData = Inventory.ByLocation[location]
  if not locationData then return {} end
  return locationData.ByModel[string.upper(model or "")] or {}
end

local function listContains(values, value)
  for _, candidate in ipairs(values) do
    if candidate == value then return true end
  end
  return false
end

local function getDeviceNamesForModel(model)
  local names = {}
  local modelKey = string.upper(model or "")
  for name, deviceModel in pairs(DeviceTypeLookup) do
    if string.upper(deviceModel or "") == modelKey and DevicesAndIPs[name] then
      table.insert(names, name)
    end
  end
  sortNames(names)
  return withEmptyChoice(names)
end

local function updateNavigationButtons()
  local names = getInventoryNames(Controls.InventoryLocation.String, Controls.InventoryModel.String)
  local cursor = Controls.InventoryName.String
  if cursor == "" or not listContains(names, cursor) then
    cursor = navigationCursorName
  end
  if cursor == "" or not listContains(names, cursor) then
    cursor = lastSuccessfulInventoryName
  end

  local index
  for i, name in ipairs(names) do
    if name == cursor then
      index = i
      break
    end
  end

  local hasNames = #names > 0
  Controls.PrevDevice.IsDisabled = not hasNames or (index ~= nil and index <= 1)
  Controls.NextDevice.IsDisabled = not hasNames or (index ~= nil and index >= #names)
end

local function refreshInventorySelectors()
  Controls.InventoryLocation.Choices = withEmptyChoice(Inventory.Locations)
  local location = Controls.InventoryLocation.String
  if location ~= "" and not Inventory.ByLocation[location] then
    location = ""
    Controls.InventoryLocation.String = ""
  end

  local models = getInventoryModels(location)
  Controls.InventoryModel.Choices = withEmptyChoice(models)
  local model = Controls.InventoryModel.String
  if model ~= "" and not listContains(models, model) then
    model = ""
    Controls.InventoryModel.String = ""
  end

  local names = getInventoryNames(location, model)
  Controls.InventoryName.Choices = withEmptyChoice(names)
  if Controls.InventoryName.String ~= "" and not listContains(names, Controls.InventoryName.String) then
    Controls.InventoryName.String = ""
  end

  Controls.AssignToDevice.Choices = model == "" and {""} or getDeviceNamesForModel(model)
  if Controls.AssignToDevice.String ~= ""
    and not listContains(Controls.AssignToDevice.Choices, Controls.AssignToDevice.String) then
    Controls.AssignToDevice.String = ""
  end
  updateNavigationButtons()
end

function updateInventory()
  local statusChanged = false
  local currentStatuses = {}
  local nextInventory = {
    Locations = {},
    LocationsLookup = {},
    Models = {},
    ModelsLookup = {},
    Names = {},
    NamesLookup = {},
    ModelToName = {},
    NameToModel = {},
    NameToLocation = {},
    ByModel = {},
    ByLocation = {},
    ByModelLookup = {},
    Types = Inventory.Types
  }

  for _, item in pairs(Design.GetInventory()) do
    local model = item.Model
    local name = item.Name
    local code = item.Status and item.Status.Code
    if name and code ~= nil then
      currentStatuses[name] = code
      if LastStatusCodes[name] ~= nil and LastStatusCodes[name] ~= code then
        statusChanged = true
      end
    end

    if name and model and (Inventory.Types[item.Type] or item.Type == "") then
      local location = item.Location
      if type(location) == "string" then
        location = location:match("^%s*(.-)%s*$")
      end
      if type(location) ~= "string" or location == "" then
        location = "Unassigned"
      end
      local modelKey = string.upper(model)
      appendUnique(nextInventory.Locations, nextInventory.LocationsLookup, location)
      appendUnique(nextInventory.Models, nextInventory.ModelsLookup, model)
      appendUnique(nextInventory.Names, nextInventory.NamesLookup, name)
      nextInventory.ModelToName[model] = nextInventory.ModelToName[model] or name
      nextInventory.NameToModel[name] = model
      nextInventory.NameToLocation[name] = location
      nextInventory.ByModel[modelKey] = nextInventory.ByModel[modelKey] or {}
      table.insert(nextInventory.ByModel[modelKey], name)
      nextInventory.ByLocation[location] = nextInventory.ByLocation[location] or {
        Models = {},
        ModelLookup = {},
        ByModel = {}
      }
      local locationData = nextInventory.ByLocation[location]
      appendUnique(locationData.Models, locationData.ModelLookup, model)
      locationData.ByModel[modelKey] = locationData.ByModel[modelKey] or {}
      table.insert(locationData.ByModel[modelKey], name)
    end
  end

  for _, locationData in pairs(nextInventory.ByLocation) do
    sortNames(locationData.Models)
    for _, names in pairs(locationData.ByModel) do sortNames(names) end
  end
  for _, names in pairs(nextInventory.ByModel) do sortNames(names) end
  sortNames(nextInventory.Locations)
  sortNames(nextInventory.Models)
  sortNames(nextInventory.Names)
  nextInventory.Types = Inventory.Types
  Inventory = nextInventory
  LastStatusCodes = currentStatuses
  refreshInventorySelectors()

  if refresh == true or statusChanged then
    getDevices()
  end
end
-- Start inventory update timer (runs every 5 seconds)
inventoryTimer.EventHandler = updateInventory
inventoryTimer:Start(5)
updateInventory()


-- **Download configuration from a peripheral device**
function downloadFromPeripherals(ip, name, t, generation)
  DebugFunctionEntry("downloadFromPeripherals", ip, name, t)
  DebugPrint("Downloading configuration from " .. name .. " at " .. ip, "tx")
  
  queuePeripheralRequest({
    Url = "https://" .. ip .. "/cgi-bin/status_xml",
    Timeout = 30,
    Headers = {},
    EventHandler = function(_, code, data)
      if generation and generation ~= deviceDiscoveryGeneration then return end
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
  }, "Download", "device-detail")
  DebugFunctionExit("downloadFromPeripherals")
end

-- **Map models to device names for assignment choices**
function modelHandling(model, name)
  if not model or model == "" or not name or name == "" then
    return
  end
  model = string.upper(model)
  if not tabModeltoName[model] then
    tabModeltoName[model] = {}
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
      if not elem.name or not elem.lan_a_ip then
        DisplayPrint("Skipping discovered peripheral without name or LAN A IP")
      else
        if refreshname and elem.name == string.lower(refreshname) then
          refresh = false
          DebugPrint("Refresh stopped for " .. elem.name, "function")
        end
        DebugPrint("Found device: " .. elem.name .. " with IP: " .. elem.lan_a_ip, "rx")
        table.insert(Devices, elem.name)
        table.insert(IPs, elem.lan_a_ip)
        table.insert(DeviceTypes, elem.part_number)
        DevicesAndIPs[elem.name] = elem.lan_a_ip
        DeviceTypeLookup[elem.name] = elem.part_number or ""
        Peripherals[elem.name] = {ip = elem.lan_a_ip}
        modelHandling(elem.part_number, elem.name)
        DevicesLookup[elem.name] = t
        if t <= #Controls.DeviceModel then
          downloadFromPeripherals(elem.lan_a_ip, elem.name, t, deviceDiscoveryGeneration)
          Controls.DeviceModel[t].String = elem.part_number or ""
          Controls.DeviceName[t].String = elem.name
          Controls.DeviceIP[t].String = elem.lan_a_ip
          Controls.DeviceModel[t].IsInvisible = false
          Controls.DeviceName[t].IsInvisible = false
          Controls.DeviceIP[t].IsInvisible = false
          Controls.DesignOnDevice[t].IsInvisible = false
          Controls.ID[t].IsInvisible = false
          Controls.IDPairing[t].IsInvisible = false
          Controls.PeripheralInfo[t].IsInvisible = false
        end
        t = t + 1
      end
    else
      DebugPrint("Found core device: " .. elem.name, "rx")
      Cores[elem.name] = elem
    end
  end
  local deviceChoices = {}
  for _, name in ipairs(Devices) do table.insert(deviceChoices, name) end
  sortNames(deviceChoices)
  Controls.Device.Choices = deviceChoices
  for _, names in pairs(tabModeltoName) do sortNames(names) end
  refreshInventorySelectors()
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
  if discoveryInProgress then
    discoveryRefreshRequested = true
    return
  end
  discoveryInProgress = true
  discoveryRefreshRequested = false
  deviceDiscoveryGeneration = deviceDiscoveryGeneration + 1
  cancelQueuedPeripheralRequests("device-detail")
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
  DevicesLookup, Peripherals, Cores = {}, {}, {}

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
    EventHandler = function(headers, code, data)
      parseDevices(headers, code, data)
      discoveryInProgress = false
      if discoveryRefreshRequested then
        discoveryRefreshRequested = false
        Timer.CallAfter(getDevices, 1)
      end
    end
  })
  populateNetworkInterfaceControls()
end

-- **Configure a peripheral to use DHCP**
function uploadPeripheralNetworkSettings(originalIP, hostname, mode, ip, netmask, defaultRoute, handler)
  local apiUrl = "https://" .. originalIP .. "/api/v1/network/settings"
  local legacyUrl = "https://" .. originalIP .. "/cgi-bin/network_configuration_xml"
  local function isEmptyBadRequest(code, data)
    return code == 400 and (
      data == nil
      or data == ""
      or (type(data) == "string" and data:match("^%s*{}%s*$") ~= nil)
      or (type(data) == "table" and next(data) == nil)
    )
  end
  local function uploadLegacyNetworkSettings()
    local payload = string.format([[<network_configuration>
    <hostname>%s</hostname>
    <enable_dns/>
    <primary_dns/>
    <secondary_dns/>
    <interface><name>LAN A</name><mode>%s</mode><address>%s</address><netmask>%s</netmask><default_route>%s</default_route></interface>
  </network_configuration>]], hostname, mode, ip, netmask, defaultRoute)
    DebugNetworkRequest(legacyUrl, "POST", payload)
    queuePeripheralRequest({
      Url = legacyUrl,
      Data = payload,
      Method = "POST",
      Timeout = 30,
      Headers = { ["Content-Type"] = "text/xml" },
      EventHandler = handler
    }, "Upload", "network-settings")
  end
  queuePeripheralRequest({
    Url = apiUrl,
    Timeout = 30,
    Headers = {},
    EventHandler = function(_, code, data)
      local url, payload, contentType
      if code == 404 or code == 405 or isEmptyBadRequest(code, data) then
        uploadLegacyNetworkSettings()
        return
      elseif code == 200 then
        local decoded, settings = pcall(rapidjson.decode, data)
        if not decoded or type(settings) ~= "table" or type(settings.interfaces) ~= "table" then
          handler(nil, 0, "Invalid peripheral network settings response")
          return
        end
        local lanA
        for _, interface in ipairs(settings.interfaces) do
          if interface.name == "LAN A" then
            lanA = interface
            break
          end
        end
        if not lanA then
          handler(nil, 0, "Peripheral network settings do not include LAN A")
          return
        end
        settings.hostname = hostname
        lanA.mode, lanA.address, lanA.netmask, lanA.gateway = mode, ip, netmask, defaultRoute
        local encoded, result = pcall(rapidjson.encode, settings)
        if not encoded then
          handler(nil, 0, "Could not encode peripheral network settings")
          return
        end
        url, payload, contentType = apiUrl, result, "application/json"
      else
        handler(nil, code, "Could not read peripheral network settings: " .. tostring(data or code))
        return
      end
      DebugNetworkRequest(url, "POST", payload)
      queuePeripheralRequest({
        Url = url,
        Data = payload,
        Method = "POST",
        Timeout = 30,
        Headers = { ["Content-Type"] = contentType },
        EventHandler = function(headers, uploadCode, uploadData)
          if url == apiUrl and isEmptyBadRequest(uploadCode, uploadData) then
            uploadLegacyNetworkSettings()
          else
            handler(headers, uploadCode, uploadData)
          end
        end
      }, "Upload", "network-settings")
    end
  }, "Download", "network-settings")
end

function setPeripheralToDHCP(name)
  uploadPeripheralNetworkSettings(Peripherals[name].ip, Peripherals[name].hostname or name, "auto", "", "", "", function(_, code, data)
    DisplayPrint("Set DHCP for " .. name .. ": " .. (code == 200 and "Success" or "Failed: " .. tostring(data)))
  end)
end

-- **Configure a peripheral witha new or old name and static IP or DHCP**
function setPeripheral(oldName, newName, ip, netmask, defaultRoute, mode, onSuccess)
  DebugFunctionEntry("setPeripheral", oldName, newName, ip, netmask, defaultRoute, mode)
  DebugPrint("Setting peripheral " .. oldName .. " to " .. newName .. " with mode " .. mode, "function")
  
  if mode == "auto" then
    ip, netmask, defaultRoute = "", "", ""
  end
  local originalIP = DevicesAndIPs[oldName]
  local model = DeviceTypeLookup[oldName]
  local pairingByID = Controls.PairWithID.Boolean
  local pairingGeneration = idPairingGeneration
  local inventoryModel = Controls.InventoryModel.String
  local inventoryName = Controls.InventoryName.String
  DebugPrint("Sending configuration to " .. oldName .. " at " .. originalIP, "tx")
  uploadPeripheralNetworkSettings(originalIP, newName, mode, ip, netmask, defaultRoute, function(_, code, data)
      DebugNetworkResponse("https://" .. originalIP, code, data)
      if code == 200 then
        DebugPrint("Successfully configured " .. newName, "rx")
        if inventoryName ~= "" and Inventory.NameToModel[inventoryName] then
          navigationCursorName = inventoryName
          lastSuccessfulInventoryName = inventoryName
        end
        if inventoryModel ~= "" and inventoryName == newName
          and Controls.InventoryModel.String == inventoryModel
          and Controls.InventoryName.String == inventoryName
          and pairingGeneration == idPairingGeneration then
          Controls.InventoryName.Color = "green"
        end
        if mode == "static" then
          DisplayPrint("✓ Success \t\t Inventory Name:    " .. newName .. " \n\t\t\t Model: " .. model .. " \t Static IP: " .. ip)
          Controls.Assign.Legend = newName .. " \n✓ Success \n"..ip
          Timer.CallAfter(function()buildDirectionsString() Controls.Assign.IsDisabled = true  end,5) 
        else 
          DisplayPrint("✓ Success \t\t inventory Name:    " .. newName .. " \n\t\t\t Model: " .. model .. " \t IP mode: DHCP")
          Controls.Assign.Legend = newName .. " \n✓ Success \n DHCP"
          Timer.CallAfter(function()buildDirectionsString() Controls.Assign.IsDisabled = true end,5) 
        end 
        local peripheral = Peripherals[oldName] or {}
        peripheral.ip = mode == "auto" and originalIP or ip
        peripheral.hostname = newName
        Peripherals[newName] = peripheral
        DevicesAndIPs[newName] = peripheral.ip
        DeviceTypeLookup[newName] = model
        local index = DevicesLookup[oldName]
        if index then
          Devices[index] = newName
          DevicesLookup[newName] = index
          Controls.DeviceName[index].String = newName
          Controls.DeviceIP[index].String = peripheral.ip
        end
        for _, names in pairs(tabModeltoName) do
          for i, name in ipairs(names) do
            if name == oldName then names[i] = newName end
          end
          sortNames(names)
        end
        if oldName ~= newName then
          Peripherals[oldName], DevicesAndIPs[oldName], DeviceTypeLookup[oldName], DevicesLookup[oldName] = nil, nil, nil, nil
        end
        if Controls.InventoryName.String == newName and not (pairingByID and Controls.KeepPairWithID.Boolean) then
          Controls.InventoryName.String = ""
        end
        DebugPrint("Setting assign to device choices to empty", "function")
        Controls.AssignToDevice.Choices = {}
        updateNavigationButtons()
        if onSuccess then onSuccess() end
      else
        DebugPrint("Failed to configure " .. newName .. ": " .. tostring(data), "rx")
        DisplayPrint("\nFailed to configure " .. newName .. ": " .. tostring(data))
      end
      if pairingByID and pairingGeneration == idPairingGeneration then
        idPairingBusy = false
        if Controls.PairWithID.Boolean then
          if Controls.KeepPairWithID.Boolean then
            if code == 200 then clearIDModeForModel(model) end
          else
            PairingMode(false)
          end
        end
      end
      Controls.AssignToDevice.String = ""
    end)
  DebugFunctionExit("setPeripheral")
end




-- **Reset a device's name to a default format (model-MAC last 4)**
function resetName(model, name, ip)

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
  setPeripheral(name, newName, ip, netMask, Controls.NewGateway.String, mode, function()
    DisplayPrint("✓ Success\t\t Reset name for " .. name .. " to: " .. newName)
    refresh = true
    refreshname = newName
    Timer.CallAfter(getDevices, 30)
  end)
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

function stopIDModeListener()
  idPairingGeneration = idPairingGeneration + 1
  RefreshTimer:Stop()
  activeIDPollCycle = nil
  cancelQueuedPeripheralRequests("id-poll")
end

function clearIDModeForModel(model)
  local modelKey = string.upper(model or "")
  if idPairingBusy and idModeClearingModel == modelKey then return end
  stopIDModeListener()
  local generation = idPairingGeneration
  idModePreparedModel = nil
  idModeClearingModel = modelKey
  local targets = {}
  for name, deviceModel in pairs(DeviceTypeLookup) do
    if string.upper(deviceModel or "") == modelKey and DevicesAndIPs[name] then
      targets[#targets + 1] = { name = name, ip = DevicesAndIPs[name] }
    end
  end
  table.sort(targets, function(a, b)
    local lowerA, lowerB = string.lower(a.name), string.lower(b.name)
    if lowerA == lowerB then return a.name < b.name end
    return lowerA < lowerB
  end)
  local pending, failed = #targets, false
  idPairingBusy = pending > 0
  local function finish()
    if generation == idPairingGeneration then
      idPairingBusy = false
      idModeClearingModel = nil
      if not failed and Controls.PairWithID.Boolean
        and string.upper(Controls.InventoryModel.String or "") == modelKey then
        idModePreparedModel = modelKey
        if Controls.InventoryName.String ~= "" then listenForIDMode(modelKey) end
      elseif failed then
        idModePreparedModel = nil
      end
    end
  end
  if pending == 0 then
    finish()
    return
  end
  for _, target in ipairs(targets) do
    queuePeripheralRequest({
      Url = "https://" .. target.ip .. "/cgi-bin/id_mode?mode=off",
      Timeout = 30,
      Headers = {},
      EventHandler = function(_, code, data)
        if code ~= 200 then
          failed = true
          DisplayPrint("Failed to turn off ID mode for " .. target.name .. ": HTTP " .. tostring(code) .. " " .. tostring(data))
        end
        pending = pending - 1
        if pending == 0 then finish() end
      end
    }, "Download", "id-off")
  end
end

-- **Listen for ID mode on devices of a specific model**
-- Used in pairing mode to detect when a device's ID is activated
function listenForIDMode(model)
  if idPairingBusy then return end
  stopIDModeListener()
  local modelKey = string.upper(model or "")
  if not Controls.PairWithID.Boolean or Controls.InventoryName.String == ""
    or string.upper(Controls.InventoryModel.String or "") ~= modelKey then return end
  local generation = idPairingGeneration
  local inventoryName = Controls.InventoryName.String
  DebugPrint("Starting ID mode listener for model: " .. modelKey, "function")
  local function finishPollRequest(cycle)
    if cycle.remaining <= 0 then return end
    cycle.remaining = cycle.remaining - 1
    if cycle.remaining == 0 and activeIDPollCycle == cycle then
      activeIDPollCycle = nil
    end
  end
  RefreshTimer.EventHandler = function()
    if generation ~= idPairingGeneration or idPairingBusy or not Controls.PairWithID.Boolean then return end
    if activeIDPollCycle then return end
    local candidates = tabModeltoName[modelKey] or {}
    local cycle = {remaining = 0}
    for _, name in ipairs(candidates) do
      if DevicesAndIPs[name] then cycle.remaining = cycle.remaining + 1 end
    end
    if cycle.remaining == 0 then return end
    activeIDPollCycle = cycle
    for _, name in ipairs(candidates) do
      if DevicesAndIPs[name] then
        local ip = DevicesAndIPs[name]
        DebugPrint("Checking ID mode for device: " .. name, "tx")
        queuePeripheralRequest({
          Url = "https://" .. ip .. "/cgi-bin/status_xml",
          Timeout = 30,
          Headers = {},
          EventHandler = function(_, code, data)
            local selectionIsCurrent = generation == idPairingGeneration
              and not idPairingBusy and Controls.PairWithID.Boolean
              and Controls.InventoryName.String == inventoryName
              and string.upper(Controls.InventoryModel.String or "") == modelKey
            if selectionIsCurrent and code == 200 then
              local device = name
              local id = data:match("<id_mode>(.-)</id_mode>") or "N/A"
              if id == "on" then
                DebugPrint("ID mode detected on device: " .. device, "rx")
                stopIDModeListener()
                idPairingBusy = true
                applyAssign(device)
                DebugPrint("Turning off ID mode for device: " .. device, "tx")
                queuePeripheralRequest({
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
                }, "Download", "id-off")
              end
            end
            finishPollRequest(cycle)
          end
        }, "Download", "id-poll", function() finishPollRequest(cycle) end)
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

  stopIDModeListener()
  idPairingBusy = false
  idModePreparedModel = nil
  idModeClearingModel = nil
  Controls.PairWithID.Boolean = b
  if b then
    hidePairIdWarning ()
    
    Controls.InventoryName.String = ""
    Controls.InventoryModel.String = ""
    Controls.InventoryName.Color = ""
    navigationCursorName = ""
    lastSuccessfulInventoryName = ""
    Controls.InventoryModel.Choices = withEmptyChoice(getInventoryModels(Controls.InventoryLocation.String))
    Controls.InventoryName.Choices = {""}
    lastHandledInventoryName = ""
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
    end
    Controls.NextDevice.IsDisabled = true
    Controls.PrevDevice.IsDisabled = true
    modelcheckID = false
    namecheckID = false
    peripheralcheckID = false
    buildDirectionsString()
  else
    cancelQueuedPeripheralRequests("id-poll")
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
  queuePeripheralRequest({
    Url = "https://" .. ip .. "/cgi-bin/id_mode?mode=" .. mode,
    Timeout = 30,
    Headers = {},
    EventHandler = function(_, code, data)
      if code == 200 then
        Timer.CallAfter(function() downloadFromPeripherals(ip, name, t, deviceDiscoveryGeneration) end, 1)
      end
    end
  }, "Download", "id-off")
end

-- **Handle inventory model selection**
function handleInventoryModel()
  local location = Controls.InventoryLocation.String
  local model = Controls.InventoryModel.String
  Controls.InventoryName.Choices = withEmptyChoice(getInventoryNames(location, model))
  Controls.InventoryName.String = ""
  Controls.AssignToDevice.Choices = model == "" and {""} or getDeviceNamesForModel(model)
  Controls.AssignToDevice.String = ""
  navigationCursorName = ""
  lastSuccessfulInventoryName = ""
  lastHandledInventoryName = ""
  updateNavigationButtons()
end

-- **Event Handlers**

local function handleInventoryNameChanged()
  local name = Controls.InventoryName.String
  if name == lastHandledInventoryName then
    updateNavigationButtons()
    return
  end
  lastHandledInventoryName = name
  Controls.InventoryName.Color = ""
  if name ~= "" then
    navigationCursorName = name
    namecheckID = true 
  else namecheckID = false 
  end 
  checkForReset ()
  local model = string.upper(Controls.InventoryModel.String or "")
  Controls.AssignToDevice.Choices = model == "" and {""} or getDeviceNamesForModel(model)
  Controls.AssignToDevice.String = ""
  if Controls.PairWithID.Boolean and name ~= "" then
    Controls.AssignToDevice.Choices = { "" }
    model = string.upper(Inventory.NameToModel[name] or "")
    if model ~= "" then
      if idModePreparedModel == model then
        listenForIDMode(model)
      elseif idModeClearingModel ~= model then
        clearIDModeForModel(model)
      end
    end
  elseif Controls.PairWithID.Boolean then
    idPairingBusy = false
    stopIDModeListener()
  end
  updateNavigationButtons()
  buildDirectionsString()
end

Controls.InventoryName.EventHandler = handleInventoryNameChanged

Controls.InventoryLocation.EventHandler = function()
  stopIDModeListener()
  idPairingBusy = false
  idModePreparedModel = nil
  idModeClearingModel = nil
  navigationCursorName = ""
  lastSuccessfulInventoryName = ""
  lastHandledInventoryName = ""
  Controls.InventoryModel.String = ""
  Controls.InventoryName.String = ""
  Controls.InventoryName.Color = ""
  Controls.AssignToDevice.String = ""
  handleInventoryModel()
  Controls.InventoryModel.Choices = withEmptyChoice(getInventoryModels(Controls.InventoryLocation.String))
  modelcheckID = false
  namecheckID = false
  checkForReset()
  buildDirectionsString()
end

Controls.InventoryModel.EventHandler = function()
  Controls.InventoryName.Color = ""
  stopIDModeListener()
  idPairingBusy = false
  idModeClearingModel = nil
  idModePreparedModel = nil
  navigationCursorName = ""
  lastSuccessfulInventoryName = ""
  lastHandledInventoryName = ""
  Controls.InventoryName.String = ""
  Controls.AssignToDevice.String = ""
  if Controls.InventoryModel.String ~= "" then 
    modelcheckID = true 
  else modelcheckID = false 
  end 
  checkForReset ()
  handleInventoryModel()
  if Controls.PairWithID.Boolean and Controls.InventoryModel.String ~= "" then
    clearIDModeForModel(string.upper(Controls.InventoryModel.String))
  end
  buildDirectionsString()
end

local function moveInventoryName(direction)
  local names = getInventoryNames(Controls.InventoryLocation.String, Controls.InventoryModel.String)
  if #names == 0 then return end
  local current = Controls.InventoryName.String
  if current == "" or not listContains(names, current) then
    current = navigationCursorName
  end
  if current == "" or not listContains(names, current) then
    current = lastSuccessfulInventoryName
  end

  local index
  for i, name in ipairs(names) do
    if name == current then
      index = i
      break
    end
  end
  local nextIndex
  if index then
    nextIndex = index + direction
  else
    nextIndex = direction > 0 and 1 or #names
  end
  if nextIndex < 1 or nextIndex > #names then return end

  Controls.InventoryName.String = names[nextIndex]
  handleInventoryNameChanged()
end

Controls.PrevDevice.EventHandler = function()
  moveInventoryName(-1)
end

Controls.NextDevice.EventHandler = function()
  moveInventoryName(1)
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
