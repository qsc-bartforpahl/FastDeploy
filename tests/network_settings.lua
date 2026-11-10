local download, upload, encodedSettings
local uploads = {}
HttpClient = {
  Download = function(request) download = request end,
  Upload = function(request)
    upload = request
    uploads[#uploads + 1] = request
  end
}
DebugNetworkRequest = function() end
rapidjson = {
  decode = function(data)
    if data == "invalid" then error("invalid JSON") end
    return data
  end,
  encode = function(settings)
    encodedSettings = settings
    return "encoded JSON"
  end
}

local function beginRequest(mode, ip, netmask, gateway)
  download, upload, encodedSettings, uploads = nil, nil, nil, {}
  local result = {}
  uploadPeripheralNetworkSettings("10.0.0.2", "new-name", mode, ip, netmask, gateway,
    function(_, code, data) result.code, result.data = code, data end)
  assert(download.Url == "https://10.0.0.2/api/v1/network/settings")
  return result
end

local result = beginRequest("static", "10.0.0.3", "255.255.255.0", "10.0.0.1")
local settings = {
  hostname = "old-name",
  primary_dns = "10.0.0.4",
  interfaces = {
    {name = "LAN A", mode = "auto", operate_with_any_poe_pse = true},
    {name = "LAN B", mode = "static", address = "192.168.1.2"}
  }
}
download.EventHandler(nil, 200, settings)
assert(upload.Url == "https://10.0.0.2/api/v1/network/settings")
assert(upload.Method == "POST" and upload.Headers["Content-Type"] == "application/json")
assert(encodedSettings.hostname == "new-name" and encodedSettings.primary_dns == "10.0.0.4")
assert(encodedSettings.interfaces[1].mode == "static" and encodedSettings.interfaces[1].address == "10.0.0.3")
assert(encodedSettings.interfaces[1].netmask == "255.255.255.0" and encodedSettings.interfaces[1].gateway == "10.0.0.1")
assert(encodedSettings.interfaces[1].operate_with_any_poe_pse == true)
assert(encodedSettings.interfaces[2].address == "192.168.1.2")
upload.EventHandler(nil, 200, "ok")
assert(result.code == 200)

beginRequest("auto", "", "", "")
download.EventHandler(nil, 404, "not found")
assert(upload.Url == "https://10.0.0.2/cgi-bin/network_configuration_xml")
assert(upload.Headers["Content-Type"] == "text/xml")
assert(upload.Data:find("<hostname>new%-name</hostname>") and upload.Data:find("<mode>auto</mode>"))

result = beginRequest("auto", "", "", "")
download.EventHandler(nil, 200, {hostname = "old-name", interfaces = {{name = "LAN A"}}})
assert(upload.Url == "https://10.0.0.2/api/v1/network/settings")
upload.EventHandler(nil, 400, "{}")
assert(upload.Url == "https://10.0.0.2/cgi-bin/network_configuration_xml")
assert(#uploads == 2)
assert(uploads[2].Headers["Content-Type"] == "text/xml")
uploads[2].EventHandler(nil, 200, "ok")
assert(result.code == 200)

result = beginRequest("auto", "", "", "")
download.EventHandler(nil, 400, '{"message":"invalid settings"}')
assert(not upload and result.code == 400)

result = beginRequest("auto", "", "", "")
download.EventHandler(nil, 401, "Unauthorized")
assert(not upload and result.code == 401)

result = beginRequest("auto", "", "", "")
download.EventHandler(nil, 200, "invalid")
assert(not upload and result.code == 0)

result = beginRequest("auto", "", "", "")
download.EventHandler(nil, 200, {interfaces = {{name = "LAN B"}}})
assert(not upload and result.code == 0)

print("network settings tests passed")