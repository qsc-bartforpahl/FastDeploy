local report = print
local requests, delayed
local activePeripheralRequests, maxPeripheralRequests

local function control()
  return {String = "", Boolean = false, Choices = {}, IsDisabled = false}
end

local function trackPeripheralRequest(request, method)
  requests[#requests + 1] = request
  local isPeripheral = request.Url:find("/cgi-bin/", 1, true)
    or request.Url:find("/api/v1/", 1, true)
    or request.Url:find("/network_configuration_xml", 1, true)
  if isPeripheral then
    activePeripheralRequests = activePeripheralRequests + 1
    maxPeripheralRequests = math.max(maxPeripheralRequests, activePeripheralRequests)
    local eventHandler = request.EventHandler
    request.EventHandler = function(...)
      if not request.testCompleted then
        request.testCompleted = true
        activePeripheralRequests = activePeripheralRequests - 1
      end
      if eventHandler then eventHandler(...) end
    end
  end
end

local function setup(keepPairing)
  requests, delayed = {}, {}
  activePeripheralRequests, maxPeripheralRequests = 0, 0
  print = function() end
  props = {["Device Count"] = {Value = 3}}
  ctrls = {}
  dofile("controls.lua")
  Controls = {}
  for _, definition in ipairs(ctrls) do
    if (definition.Count or 1) > 1 then
      Controls[definition.Name] = {}
      for i = 1, definition.Count do
        Controls[definition.Name][i] = control()
      end
    else
      Controls[definition.Name] = control()
    end
  end
  Properties = {["Debug Print"] = {Value = "None"}}
  package.loaded.rapidjson = {
    decode = function(data) return data end,
    encode = function() return "{}" end
  }
  Timer = {
    New = function()
      return {
        Start = function(self) self.running = true end,
        Stop = function(self) self.running = false end
      }
    end,
    CallAfter = function(callback) delayed[#delayed + 1] = callback end
  }
  Network = {Interfaces = function() return {} end}
  Design = {
    GetStatus = function() return {DesignName = "test-design"} end,
    GetInventory = function()
      return {
        {Model = "NL-SB42", Name = "speaker-01", Location = "Room A", Type = "Network Loudspeaker", Status = {Code = 0}},
        {Model = "NL-SB42", Name = "speaker-02", Location = "Room A", Type = "Network Loudspeaker", Status = {Code = 0}},
        {Model = "NL-SB42", Name = "speaker-03", Location = "Room B", Type = "Network Loudspeaker", Status = {Code = 0}},
        {Model = "NVM-302D", Name = "video-01", Location = "Room B", Type = "Video I/O", Status = {Code = 0}},
        {Model = "CX-Q", Name = "unassigned-device", Type = "Peripheral", Status = {Code = 0}}
      }
    end
  }
  HttpClient = {
    Download = function(request) trackPeripheralRequest(request, "Download") end,
    Upload = function(request) trackPeripheralRequest(request, "Upload") end
  }
  dofile(arg and arg[1] or "runtime.lua")
  local discoveryRequest
  for _, request in ipairs(requests) do
    if request.Url:find("/discovered_devices", 1, true) then
      discoveryRequest = request
      break
    end
  end
  discoveryRequest.EventHandler(nil, 200, {
    {name = "Soundbar-A", lan_a_ip = "10.0.0.31", part_number = "NL-SB42", type = "peripheral"},
    {name = "Soundbar-B", lan_a_ip = "10.0.0.32", part_number = "NL-SB42", type = "peripheral"},
    {name = "Video-A", lan_a_ip = "10.0.0.77", part_number = "NVM-302D", type = "peripheral"}
  })
  for _, request in ipairs(requests) do
    if request.Url:find("/cgi-bin/status_xml", 1, true) then
      request.EventHandler(nil, 200, "<status><id_mode>off</id_mode></status>")
    end
  end
  Controls.InventoryLocation.String = "Room A"
  Controls.InventoryLocation.EventHandler()
  Controls.ThirdOctet.String, Controls.LastOctet.String = "0", "31"
  Controls.KeepPairWithID.Boolean = keepPairing
  PairingMode(true)
  Controls.InventoryModel.String = "NL-SB42"
  Controls.InventoryModel.EventHandler()
  Controls.InventoryName.String = "speaker-01"
  Controls.InventoryName.EventHandler()
  for _, request in ipairs(requests) do
    if request.Url:find("/cgi-bin/id_mode?mode=off", 1, true) then
      request.EventHandler(nil, 200, "")
    end
  end
  requests = {}
end

local function matchingRequests(suffix)
  local matches = {}
  for _, request in ipairs(requests) do
    if request.Url:sub(-#suffix) == suffix then matches[#matches + 1] = request end
  end
  return matches
end

local function detectDevice(index)
  assert(RefreshTimer.running)
  RefreshTimer.EventHandler()
  local polls = matchingRequests("/cgi-bin/status_xml")
  assert(#polls == 2, "Only devices of the selected model should be polled")
  polls[index or 1].EventHandler(nil, 200, "<status><id_mode>on</id_mode></status>")
  for i, request in ipairs(polls) do
    if i ~= (index or 1) then
      request.EventHandler(nil, 200, "<status><id_mode>off</id_mode></status>")
    end
  end
  assert(not RefreshTimer.running, "Polling must stop before assignment")
  return polls
end

local function finishConfiguration(code)
  local reads = matchingRequests("/api/v1/network/settings")
  assert(#reads == 1, "Exactly one assignment should be in flight")
  reads[1].EventHandler(nil, 200, {interfaces = {{name = "LAN A", mode = "auto"}}})
  local posts = matchingRequests("/api/v1/network/settings")
  assert(#posts == 2 and posts[2].Method == "POST")
  for _, request in ipairs(requests) do
    if request.Url:find("/cgi-bin/id_mode?mode=off", 1, true) then
      request.EventHandler(nil, 200, "")
    end
  end
  requests = {}
  posts[2].EventHandler(nil, code or 200, "response")
end

setup(true)
assert(Controls.InventoryName.Color == "")
local polls = detectDevice()
local firstDeviceIP = polls[1].Url:match("https://([^/]+)/")
assert(Controls.InventoryName.Color == "", "Do not mark pairing complete before the response")
finishConfiguration()
assert(Controls.PairWithID.Boolean)
assert(Controls.InventoryModel.String == "NL-SB42")
assert(Controls.InventoryName.Color == "green")
assert(Controls.InventoryModel.Color == "", "The model must not be colored on completion")
assert(Controls.InventoryName.String == "speaker-01")
assert(not Controls.InventoryName.IsDisabled)
assert(#Controls.InventoryName.Choices == 3)
assert(Peripherals["speaker-01"].ip == firstDeviceIP)
assert(DevicesAndIPs["Soundbar-A"] == nil and DevicesAndIPs["speaker-01"] == firstDeviceIP)
local off = matchingRequests("/cgi-bin/id_mode?mode=off")
assert(#off == 2, "All devices of the paired model must receive ID-off")
for _, request in ipairs(off) do
  assert(not request.Url:find("10.0.0.77", 1, true), "Do not reset other models")
end
assert(not RefreshTimer.running, "Wait for ID-off responses before polling")
for _, request in ipairs(off) do request.EventHandler(nil, 200, "") end
assert(RefreshTimer.running)

Controls.InventoryName.String = "speaker-02"
Controls.InventoryName.EventHandler()
assert(Controls.InventoryName.Color == "", "Changing the name must clear the success color")
requests = {}
local secondDevicePolls = detectDevice(2)
local secondDeviceIP = secondDevicePolls[2].Url:match("https://([^/]+)/")
finishConfiguration()
assert(Controls.PairWithID.Boolean and Controls.InventoryName.String == "speaker-02")
assert(DevicesAndIPs["speaker-02"] == secondDeviceIP, "Second device should use the next inventory name")
assert(Controls.InventoryModel.String == "NL-SB42")
assert(Controls.InventoryName.Color == "green", "The next successful pairing must restore green")
Controls.InventoryModel.EventHandler()
assert(Controls.InventoryName.Color == "", "Changing the model must also clear the name color")

setup(false)
detectDevice()
finishConfiguration()
assert(not Controls.PairWithID.Boolean, "Default mode should still exit after one pairing")
assert(Controls.InventoryName.Color == "green")
assert(Controls.InventoryName.String == "")
assert(not RefreshTimer.running)
local requestCountBeforeNavigation = #requests
Controls.NextDevice.EventHandler()
assert(Controls.InventoryName.String == "speaker-02", "Next should advance from the last successful name")
assert(#requests == requestCountBeforeNavigation, "Name navigation must not send peripheral requests")
assert(Controls.NextDevice.IsDisabled and not Controls.PrevDevice.IsDisabled)
Controls.NextDevice.EventHandler()
assert(Controls.InventoryName.String == "speaker-02", "Next must stop at the end of the list")
Controls.PrevDevice.EventHandler()
assert(Controls.InventoryName.String == "speaker-01", "Prev should return to the prior name")
assert(Controls.PrevDevice.IsDisabled and not Controls.NextDevice.IsDisabled)

setup(true)
detectDevice()
Controls.KeepPairWithID.Boolean = false
finishConfiguration()
assert(not Controls.PairWithID.Boolean, "Turning the option off should restore single-pair behavior")
assert(Controls.InventoryName.String == "")

setup(true)
PairingMode(false)
requests = {}
setPeripheral("Soundbar-A", "speaker-01", "", "", "", "auto")
finishConfiguration()
assert(not Controls.PairWithID.Boolean)
assert(Controls.InventoryName.String == "", "Manual assignment should not retain the name")
assert(#matchingRequests("/cgi-bin/id_mode?mode=off") == 0)

setup(true)
detectDevice()
finishConfiguration(500)
assert(Controls.InventoryName.Color == "", "A failed pairing must not turn the name green")
assert(Controls.PairWithID.Boolean and Controls.InventoryName.String == "speaker-01")
assert(not RefreshTimer.running)
assert(#matchingRequests("/cgi-bin/id_mode?mode=off") == 0)
assert(Controls.PairingByNameDebug.String:find("Failed to configure", 1, true))

setup(true)
detectDevice()
finishConfiguration()
off = matchingRequests("/cgi-bin/id_mode?mode=off")
off[1].EventHandler(nil, 500, "failed")
off[2].EventHandler(nil, 200, "")
assert(not RefreshTimer.running, "ID-off failure must leave polling paused")
assert(Controls.PairingByNameDebug.String:find("Failed to turn off ID mode", 1, true))

setup(true)
RefreshTimer.EventHandler()
polls = matchingRequests("/cgi-bin/status_xml")
PairingMode(false)
requests = {}
polls[1].EventHandler(nil, 200, "<status><id_mode>on</id_mode></status>")
assert(#requests == 0, "Late status responses must not pair after exiting ID mode")

setup(true)
RefreshTimer.EventHandler()
polls = matchingRequests("/cgi-bin/status_xml")
Controls.InventoryName.String = "speaker-02"
Controls.InventoryName.EventHandler()
requests = {}
polls[1].EventHandler(nil, 200, "<status><id_mode>on</id_mode></status>")
assert(#requests == 0, "Late status responses must not use a previous inventory selection")

setup(true)
Controls.InventoryName.String = ""
Controls.InventoryName.EventHandler()
assert(not RefreshTimer.running, "Clearing the inventory name must stop polling")

setup(true)
detectDevice()
finishConfiguration()
off = matchingRequests("/cgi-bin/id_mode?mode=off")
Controls.InventoryName.String = "speaker-02"
Controls.InventoryName.EventHandler()
assert(not RefreshTimer.running, "Selecting the next name must not skip the ID-off barrier")
for _, request in ipairs(off) do request.EventHandler(nil, 200, "") end
requests = {}
detectDevice(2)
finishConfiguration()
assert(Controls.InventoryName.String == "speaker-02")

setup(true)
detectDevice()
finishConfiguration()
off = matchingRequests("/cgi-bin/id_mode?mode=off")
PairingMode(false)
for _, request in ipairs(off) do request.EventHandler(nil, 200, "") end
assert(not RefreshTimer.running, "Late ID-off responses must not restart disabled pairing")

setup(true)
detectDevice()
PairingMode(false)
PairingMode(true)
Controls.InventoryModel.String = "NVM-302D"
Controls.InventoryLocation.String = "Room B"
Controls.InventoryLocation.EventHandler()
Controls.InventoryModel.String = "NVM-302D"
Controls.InventoryModel.EventHandler()
Controls.InventoryName.String = "video-01"
Controls.InventoryName.EventHandler()
finishConfiguration()
assert(Controls.InventoryName.String == "video-01")
assert(Controls.InventoryModel.String == "NVM-302D")
assert(Controls.InventoryName.Color == "", "An old assignment must not color the new name")
assert(RefreshTimer.running, "A previous assignment must not stop a new pairing session")
assert(#matchingRequests("/cgi-bin/id_mode?mode=off") == 0)

setup(true)
PairingMode(false)
assert(#Controls.InventoryLocation.Choices == 4)
assert(Controls.InventoryLocation.Choices[2] == "Room A")
assert(Controls.InventoryLocation.Choices[3] == "Room B")
assert(Controls.InventoryLocation.Choices[4] == "Unassigned")
Controls.InventoryLocation.String = "Room A"
Controls.InventoryLocation.EventHandler()
assert(#Controls.InventoryModel.Choices == 2 and Controls.InventoryModel.Choices[2] == "NL-SB42")
Controls.InventoryModel.String = "NL-SB42"
Controls.InventoryModel.EventHandler()
assert(Controls.InventoryName.Choices[2] == "speaker-01")
assert(Controls.InventoryName.Choices[3] == "speaker-02")
Controls.InventoryName.String = "speaker-01"
Controls.InventoryName.EventHandler()
assert(Controls.PrevDevice.IsDisabled and not Controls.NextDevice.IsDisabled)
requestCountBeforeNavigation = #requests
Controls.NextDevice.EventHandler()
assert(Controls.InventoryName.String == "speaker-02")
assert(#requests == requestCountBeforeNavigation, "Prev/Next must not assign or make HTTP calls")
assert(Controls.NextDevice.IsDisabled and not Controls.PrevDevice.IsDisabled)
Controls.PrevDevice.EventHandler()
assert(Controls.InventoryName.String == "speaker-01")
Controls.InventoryLocation.String = ""
Controls.InventoryLocation.EventHandler()
assert(#Controls.InventoryModel.Choices == 1 and #Controls.InventoryName.Choices == 1)
assert(Controls.PrevDevice.IsDisabled and Controls.NextDevice.IsDisabled,
  "Navigation must be disabled when the selected location has no inventory items")
Controls.InventoryLocation.String = "Room B"
Controls.InventoryLocation.EventHandler()
assert(#Controls.InventoryModel.Choices == 3)
Controls.InventoryModel.String = "NL-SB42"
Controls.InventoryModel.EventHandler()
assert(#Controls.AssignToDevice.Choices == 3,
  "Unadopted peripherals are filtered by model, not the selected inventory location")
Controls.InventoryLocation.String = "Unassigned"
Controls.InventoryLocation.EventHandler()
assert(#Controls.InventoryModel.Choices == 2 and Controls.InventoryModel.Choices[2] == "CX-Q")
Controls.InventoryModel.String = "CX-Q"
Controls.InventoryModel.EventHandler()
assert(Controls.InventoryName.Choices[2] == "unassigned-device")
Controls.InventoryLocation.String = "Room B"
Controls.InventoryLocation.EventHandler()

local discovered = {}
for i = 1, 750 do
  local model = i <= 10 and "NL-SB42" or "AMP-OTHER"
  discovered[i] = {
    name = string.format("network-device-%03d", i),
    lan_a_ip = string.format("10.1.0.%d", i),
    part_number = model,
    type = "peripheral"
  }
end
requests = {}
activePeripheralRequests, maxPeripheralRequests = 0, 0
getDevices()
local coreDiscovery
for _, request in ipairs(requests) do
  if request.Url:find("/discovered_devices", 1, true) then coreDiscovery = request end
end
assert(coreDiscovery, "Refresh must issue a Core discovery request")
coreDiscovery.EventHandler(nil, 200, discovered)
assert(#Devices == 750, "The complete discovery data must be retained")
assert(#matchingRequests("/cgi-bin/status_xml") == 3,
  "Discovery should enrich only the three visible device rows, not all 750")
assert(maxPeripheralRequests <= 4, "Discovery enrichment must respect the request limit")
local requestIndex = 1
while requestIndex <= #requests do
  local request = requests[requestIndex]
  if request.Url:find("/cgi-bin/status_xml", 1, true) and not request.testCompleted then
    request.EventHandler(nil, 200, "<status><id_mode>off</id_mode></status>")
  end
  requestIndex = requestIndex + 1
end
assert(activePeripheralRequests == 0)

Controls.PairWithID.Boolean = true
PairingMode(true)
Controls.InventoryModel.String = "NL-SB42"
Controls.InventoryModel.EventHandler()
assert(#matchingRequests("/cgi-bin/id_mode?mode=off") == 4,
  "ID-off commands must be started in bounded batches")
requestIndex = 1
while requestIndex <= #requests do
  local request = requests[requestIndex]
  if request.Url:find("/cgi-bin/id_mode?mode=off", 1, true) and not request.testCompleted then
    assert(request.Url:find("10.1.0.", 1, true), "ID-off must target only the selected model")
    request.EventHandler(nil, 200, "")
  end
  requestIndex = requestIndex + 1
end
assert(not RefreshTimer.running, "ID polling waits for an inventory name")
Controls.InventoryName.String = "speaker-03"
Controls.InventoryName.EventHandler()
assert(RefreshTimer.running, "ID polling starts after bounded model-specific ID-off work")
requests = {}
activePeripheralRequests, maxPeripheralRequests = 0, 0
RefreshTimer.EventHandler()
assert(#matchingRequests("/cgi-bin/status_xml") == 4,
  "Only four model-specific status requests may start at once")
requestIndex = 1
while requestIndex <= #requests do
  local request = requests[requestIndex]
  if request.Url:find("/cgi-bin/status_xml", 1, true) and not request.testCompleted then
    assert(request.Url:find("10.1.0.", 1, true), "ID status polling must exclude other models")
    request.EventHandler(nil, 200, "<status><id_mode>off</id_mode></status>")
  end
  requestIndex = requestIndex + 1
end
assert(#matchingRequests("/cgi-bin/status_xml") == 10,
  "The full selected-model scan should include all ten matching peripherals")
assert(maxPeripheralRequests <= 4, "Peripheral HTTP concurrency must never exceed four")
assert(activePeripheralRequests == 0)

print = report
report("pair by ID tests passed")
