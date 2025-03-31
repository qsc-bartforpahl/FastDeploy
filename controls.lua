table.insert(ctrls,{
  Name = "code",
  ControlType = "Text",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})
-- Base controls
table.insert(ctrls, {
  Name = "SendButton",
  ControlType = "Button",
  ButtonType = "Momentary",
  Count = 1,
  UserPin = true,
  PinStyle = "Input",
  Icon = "Power"
})

-- Network Configuration
table.insert(ctrls, { 
  Name = "LocalDesignName", 
  ControlType = "Text", 
  UserPin = true, 
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "NewNetworkPrefix", 
  ControlType = "Text", 
  UserPin = true, 
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "NewNetmask", 
  ControlType = "Text", 
  UserPin = true, 
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "NewGateway", 
  ControlType = "Text", 
  UserPin = true, 
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "NewIPRange", 
  ControlType = "Text", 
  UserPin = true, 
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "CurrentLanAConfig", 
  ControlType = "Text",
  Count = 1
})

table.insert(ctrls, { 
  Name = "CurrentLanBConfig", 
  ControlType = "Text",
  Count = 1
})

table.insert(ctrls, { 
  Name = "IPMode", 
  ControlType = "Button", 
  ButtonType = "Toggle", 
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "BaseOctets", 
  ControlType = "Text", 
  Constraint = "List",
  Count = 2
})

table.insert(ctrls, { 
  Name = "ThirdOctet", 
  ControlType = "Text", 
  Constraint = "List",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "LastOctet", 
  ControlType = "Text", 
  Constraint = "List",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

-- Inventory Selection
table.insert(ctrls, { 
  Name = "InventoryModel", 
  ControlType = "Text", 
  Constraint = "List", 
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "InventoryName", 
  ControlType = "Text", 
  Constraint = "List", 
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "AssignToDevice", 
  ControlType = "Text", 
  Constraint = "List", 
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})



-- Device List (dynamic count based on properties)
local deviceCount = props["Device Count"].Value
print("deviceCount: "..deviceCount)
table.insert(ctrls, { 
  Name = "DeviceModel", 
  ControlType = "Text", 
  Count = deviceCount,
  UserPin = true,
  PinStyle = "Input"
})

table.insert(ctrls, { 
  Name = "DeviceName", 
  ControlType = "Text", 
  Count = deviceCount,
  UserPin = true,
  PinStyle = "Input"
})

table.insert(ctrls, { 
  Name = "DeviceIP", 
  ControlType = "Text", 
  Count = deviceCount,
  UserPin = true,
  PinStyle = "Input"
})

table.insert(ctrls, { 
  Name = "DesignOnDevice", 
  ControlType = "Text", 
  Count = deviceCount,
  UserPin = true,
  PinStyle = "Input"
})

table.insert(ctrls, { 
  Name = "ID", 
  ControlType = "Button", 
  ButtonType = "Toggle", 
  Count = deviceCount,
  UserPin = true,
  PinStyle = "Input"
})

table.insert(ctrls, { 
  Name = "IDPairing", 
  ControlType = "Button", 
  ButtonType = "Toggle", 
  Count = deviceCount,
  UserPin = true,
  PinStyle = "Input"
})

table.insert(ctrls, { 
  Name = "PeripheralInfo", 
  ControlType = "Text", 
  Count = deviceCount,
  UserPin = true,
  PinStyle = "Input"
})

-- Actions
table.insert(ctrls, { 
  Name = "Get", 
  ControlType = "Button", 
  ButtonType = "Trigger",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "Assign", 
  ControlType = "Button", 
  ButtonType = "Trigger",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "ResetName", 
  ControlType = "Button", 
  ButtonType = "Trigger",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "PairWithID", 
  ControlType = "Button", 
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "PairWithIdDontShowAdgain", 
  ControlType = "Button", 
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "PairWithIdDirections", 
  ControlType = "Text", 
  Count = 2,
  UserPin = true,
  PinStyle = "Input"
})

table.insert(ctrls, { 
  Name = "Control_2", 
  ControlType = "Button", 
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "PairingByNameDebug", 
  ControlType = "Text", 
  Count = 1,
  UserPin = true,
  PinStyle = "Input"
})

-- Utilities
table.insert(ctrls, { 
  Name = "Device", 
  ControlType = "Text", 
  Constraint = "Combo Box",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "IP", 
  ControlType = "Text",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "Reboot", 
  ControlType = "Button",
  ButtonType = "Trigger",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "SetStatic", 
  ControlType = "Button",
  ButtonType = "Trigger",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "SetDHCP", 
  ControlType = "Button",
  ButtonType = "Trigger",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "DownloadLogfile", 
  ControlType = "Button",
  ButtonType = "Trigger",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "ScanIPs", 
  ControlType = "Button",
  ButtonType = "Trigger",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "StaticOrAuto", 
  ControlType = "Text",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})

table.insert(ctrls, { 
  Name = "Dtype", 
  ControlType = "Text",
  UserPin = true,
  PinStyle = "Input",
  Count = 1
})  



