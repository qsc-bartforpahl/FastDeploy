local report = print
local requests, delayed

local function control()
  return {String = "", Boolean = false, Choices = {}, IsDisabled = false}
end

local function setup(keepPairing)
  requests, delayed = {}, {}
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
        {Model = "NL-SB42", Name = "speaker-01", Type = "Network Loudspeaker", Status = {Code = 0}},
        {Model = "NL-SB42", Name = "speaker-02", Type = "Network Loudspeaker", Status = {Code = 0}},
        {Model = "NVM-302D", Name = "video-01", Type = "Video I/O", Status = {Code = 0}}
      }
    end
  }
  HttpClient = {
    Download = function(request) requests[#requests + 1] = request end,
    Upload = function(request) requests[#requests + 1] = request end
  }
  dofile(arg and arg[1] or "runtime.lua")
  parseDevices(nil, 200, {
    {name = "Soundbar-A", lan_a_ip = "10.0.0.31", part_number = "NL-SB42", type = "peripheral"},
    {name = "Soundbar-B", lan_a_ip = "10.0.0.32", part_number = "NL-SB42", type = "peripheral"},
    {name = "Video-A", lan_a_ip = "10.0.0.77", part_number = "NVM-302D", type = "peripheral"}
  })
  Controls.ThirdOctet.String, Controls.LastOctet.String = "0", "31"
  Controls.KeepPairWithID.Boolean = keepPairing
  PairingMode(true)
  Controls.InventoryModel.String = "NL-SB42"
  Controls.InventoryModel.EventHandler()
  Controls.InventoryName.String = "speaker-01"
  Controls.InventoryName.EventHandler()
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
  assert(not RefreshTimer.running, "Polling must stop before assignment")
  return polls
end

local function finishConfiguration(code)
  local reads = matchingRequests("/api/v1/network/settings")
  assert(#reads == 1, "Exactly one assignment should be in flight")
  reads[1].EventHandler(nil, 200, {interfaces = {{name = "LAN A", mode = "auto"}}})
  local posts = matchingRequests("/api/v1/network/settings")
  assert(#posts == 2 and posts[2].Method == "POST")
  requests = {}
  posts[2].EventHandler(nil, code or 200, "response")
end

setup(true)
assert(Controls.InventoryName.Color == "")
local polls = detectDevice()
assert(Controls.InventoryName.Color == "", "Do not mark pairing complete before the response")
polls[2].EventHandler(nil, 200, "<status><id_mode>on</id_mode></status>")
finishConfiguration()
assert(Controls.PairWithID.Boolean)
assert(Controls.InventoryModel.String == "NL-SB42")
assert(Controls.InventoryName.Color == "green")
assert(Controls.InventoryModel.Color == "", "The model must not be colored on completion")
assert(Controls.InventoryName.String == "speaker-01")
assert(not Controls.InventoryName.IsDisabled)
assert(#Controls.InventoryName.Choices == 2)
assert(Peripherals["speaker-01"].ip == "10.0.0.31")
assert(DevicesAndIPs["Soundbar-A"] == nil and DevicesAndIPs["speaker-01"] == "10.0.0.31")
local off = matchingRequests("/cgi-bin/id_mode?mode=off")
assert(#off == 2, "All devices of the paired model must receive ID-off")
for _, request in ipairs(off) do
  assert(not request.Url:find("10.0.0.77", 1, true), "Do not reset other models")
end
assert(not RefreshTimer.running, "Wait for ID-off responses before polling")
off[1].EventHandler(nil, 200, "")
assert(not RefreshTimer.running)
off[2].EventHandler(nil, 200, "")
assert(RefreshTimer.running)

Controls.InventoryName.String = "speaker-02"
Controls.InventoryName.EventHandler()
assert(Controls.InventoryName.Color == "", "Changing the name must clear the success color")
requests = {}
detectDevice(2)
finishConfiguration()
assert(Controls.PairWithID.Boolean and Controls.InventoryName.String == "speaker-02")
assert(DevicesAndIPs["speaker-02"] == "10.0.0.32", "Second device should use the next inventory name")
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
off[1].EventHandler(nil, 200, "")
off[2].EventHandler(nil, 200, "")
requests = {}
detectDevice(2)
finishConfiguration()
assert(Controls.InventoryName.String == "speaker-02")

setup(true)
detectDevice()
finishConfiguration()
off = matchingRequests("/cgi-bin/id_mode?mode=off")
PairingMode(false)
off[1].EventHandler(nil, 200, "")
off[2].EventHandler(nil, 200, "")
assert(not RefreshTimer.running, "Late ID-off responses must not restart disabled pairing")

setup(true)
detectDevice()
PairingMode(false)
PairingMode(true)
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

print = report
report("pair by ID tests passed")
