local CurrentPage = PageNames[props["page_index"].Value]
local deviceCount = props["Device Count"].Value

local theme = {
  background = {24, 31, 42},
  panel = {35, 44, 57},
  panelRaised = {43, 54, 69},
  border = {63, 78, 96},
  text = {232, 238, 245},
  muted = {157, 172, 190},
  accent = {0, 122, 204},
  accentDark = {0, 91, 156},
  green = {39, 143, 99},
  warning = {192, 139, 55},
  rowA = {38, 48, 62},
  rowB = {44, 55, 70}
}

local function addBackground()
  table.insert(graphics, {
    Type = "GroupBox",
    Text = "",
    Fill = theme.background,
    StrokeWidth = 0,
    Position = {0, 0},
    Size = {795, 780}
  })
end

local function addPanel(text, x, y, width, height)
  table.insert(graphics, {
    Type = "GroupBox",
    Text = text,
    Fill = theme.panel,
    StrokeWidth = 1,
    StrokeColor = theme.border,
    CornerRadius = 8,
    Position = {x, y},
    Size = {width, height},
    FontSize = 11,
    Color = theme.text,
    HTextAlign = "Left"
  })
end

local function addLabel(text, x, y, width, height, fontSize, color, align)
  table.insert(graphics, {
    Type = "Text",
    Text = text,
    Position = {x, y},
    Size = {width, height},
    FontSize = fontSize or 11,
    Color = color or theme.muted,
    HTextAlign = align or "Left"
  })
end

local function addControl(name, prettyName, style, x, y, width, height, options)
  local control = {
    PrettyName = prettyName,
    Style = style,
    Position = {x, y},
    Size = {width, height}
  }
  for key, value in pairs(options or {}) do
    control[key] = value
  end
  layout[name] = control
end

layout["code"] = {
  PrettyName = "code",
  Style = "None",
  Position = {0, 0},
  Size = {0, 0},
  IsReadOnly = true,
  Color = {0, 0, 0}
}

if CurrentPage == "Main UI" then
  addBackground()
  addPanel("", 20, 16, 755, 70)
  addLabel("FAST DEPLOY", 38, 27, 360, 28, 22, theme.text)
  addLabel("PERIPHERAL PAIRING  /  DEVICE MANAGEMENT", 40, 56, 440, 16, 9, theme.muted)
  addControl("Get", "Action~Refresh", "Button", 660, 32, 96, 36, {
    Legend = "REFRESH",
    Color = theme.accent
  })

  addPanel("PAIR BY DEVICE ID", 20, 98, 755, 104)
  addControl("PairWithID", "Action~Pair With ID", "Button", 40, 128, 112, 42, {
    Color = theme.accent,
    Legend = "Pair by ID"
  })
  addControl("KeepPairWithID", "Action~Keep Pair With ID", "Button", 165, 128, 118, 42, {
    Color = theme.accentDark,
    Legend = "Keep Pairing"
  })
  addControl("PairWithIdDirections 1", "Help~Directions", "Text", 302, 108, 448, 88, {
    IsReadOnly = true,
    Color = theme.text,
    Fill = theme.panel,
    FontSize = 11,
    HTextAlign = "Left"
  })
  addControl("PairWithIdDirections 2", "Help~ID Warnings", "Text", 302, 109, 448, 77, {
    IsReadOnly = true,
    IsInvisible = true,
    Color = theme.text,
    Fill = theme.panel,
    FontSize = 10,
    HTextAlign = "Left"
  })

  addPanel("INVENTORY", 20, 204, 430, 252)
  addLabel("Choose the Designer target", 38, 226, 390, 16, 10, theme.muted)
  addLabel("LOCATION", 38, 247, 386, 15, 9, theme.muted)
  addControl("InventoryLocation", "Inventory~Location", "ComboBox", 38, 264, 394, 30, {
    FontSize = 11
  })
  addLabel("MODEL", 38, 302, 172, 15, 9, theme.muted)
  addControl("InventoryModel", "Inventory~Model", "ComboBox", 38, 319, 172, 30, {
    FontSize = 11
  })
  addLabel("INVENTORY NAME", 232, 302, 200, 15, 9, theme.muted)
  addControl("InventoryName", "Inventory~Name", "ComboBox", 232, 319, 200, 30, {
    FontSize = 10
  })
  addControl("PrevDevice", "Inventory~Prev Device", "Button", 38, 365, 172, 36, {
    Legend = "<  PREVIOUS"
  })
  addControl("NextDevice", "Inventory~Next Device", "Button", 232, 365, 200, 36, {
    Legend = "NEXT DEVICE  >",
    Color = theme.accent
  })
  addLabel("Use Next Device to step through sorted names.", 38, 416, 394, 18, 9, theme.muted)

  addPanel("NETWORK PERIPHERAL", 465, 204, 310, 252)
  addLabel("Select the online device to pair", 483, 226, 274, 16, 10, theme.muted)
  addLabel("DISCOVERED DEVICE", 483, 252, 274, 15, 9, theme.muted)
  addControl("AssignToDevice", "Assign~To Device", "ComboBox", 483, 269, 274, 32, {
    FontSize = 11
  })
  addLabel("The selected model filters this list.", 483, 315, 274, 16, 9, theme.muted)
  addControl("Assign", "Action~Assign", "Button", 483, 347, 274, 54, {
    Color = theme.green,
    Legend = "ASSIGN PERIPHERAL"
  })

  addPanel("IP ADDRESS", 20, 470, 755, 100)
  addLabel("Address mode", 38, 494, 120, 16, 9, theme.muted)
  addControl("IPMode", "Network~IP Mode", "Button", 38, 513, 112, 38, {
    Color = theme.panelRaised,
    Legend = "DHCP"
  })
  addLabel("PERIPHERAL ADDRESS", 178, 494, 300, 15, 9, theme.muted)
  addControl("BaseOctets 1", "IP~First Octet", "Text", 178, 514, 48, 30, {
    IsReadOnly = true,
    Color = theme.panelRaised,
    FontSize = 11
  })
  addLabel(".", 228, 518, 8, 20, 12, theme.muted)
  addControl("BaseOctets 2", "IP~Second Octet", "Text", 239, 514, 48, 30, {
    IsReadOnly = true,
    Color = theme.panelRaised,
    FontSize = 11
  })
  addLabel(".", 289, 518, 8, 20, 12, theme.muted)
  addControl("ThirdOctet", "IP~Third Octet", "ComboBox", 300, 514, 62, 30, {
    FontSize = 10
  })
  addLabel(".", 364, 518, 8, 20, 12, theme.muted)
  addControl("LastOctet", "IP~Last Octet", "ComboBox", 375, 514, 66, 30, {
    FontSize = 10
  })
  addLabel("IP settings can be changed before assignment.", 478, 519, 278, 18, 9, theme.muted)

  addPanel("PAIRING STATUS", 20, 584, 500, 176)
  addControl("PairingByNameDebug", "Debug~Status", "Text", 38, 610, 464, 128, {
    IsReadOnly = true,
    Color = theme.text,
    Fill = theme.panelRaised,
    StrokeColor = theme.border,
    FontSize = 10
  })
  addPanel("DEFAULT NAMING", 535, 584, 240, 176)
  addLabel("Restore the peripheral's factory name.", 553, 614, 204, 36, 10, theme.muted)
  addControl("ResetName", "Action~Reset Name", "Button", 553, 678, 204, 42, {
    Color = theme.panelRaised,
    Legend = "RESET NAME"
  })

elseif CurrentPage == "Network Device List" then
  deviceCount = math.max(1, math.min(150, deviceCount))
  addBackground()
  addPanel("", 20, 16, 755, 70)
  addLabel("NETWORK OVERVIEW", 38, 27, 430, 28, 20, theme.text)
  addLabel("DISCOVERED PERIPHERALS  /  NETWORK STATUS", 40, 56, 470, 16, 9, theme.muted)
  addControl("Get", "Action~Refresh", "Button", 660, 32, 96, 36, {
    Legend = "REFRESH",
    Color = theme.accent
  })

  addPanel("LAN A", 20, 101, 365, 90)
  addControl("CurrentLanAConfig", "LanAConfig", "Text", 38, 126, 329, 52, {
    IsReadOnly = true,
    Color = theme.text,
    Fill = theme.panelRaised,
    FontSize = 9
  })
  addPanel("LAN B", 410, 101, 365, 90)
  addControl("CurrentLanBConfig", "LanBConfig", "Text", 428, 126, 329, 52, {
    IsReadOnly = true,
    Color = theme.text,
    Fill = theme.panelRaised,
    FontSize = 9
  })

  addPanel("NETWORK SETTINGS", 20, 205, 755, 116)
  local networkFields = {
    {"NewNetmask", "Netmask", "Network~Netmask", 38, 132},
    {"NewGateway", "Gateway", "Network~Gateway", 185, 132},
    {"NewNetworkPrefix", "NetworkPrefix", "Network~Prefix", 332, 132},
    {"NewIPRange", "IPRange", "Network~IP Range", 479, 132}
  }
  for _, field in ipairs(networkFields) do
    local controlName, labelText, prettyName, x, width = field[1], field[2], field[3], field[4], field[5]
    addLabel(string.upper(labelText), x, 239, width, 15, 9, theme.muted)
    addControl(controlName, prettyName, "Text", x, 258, width, 32, {
      IsReadOnly = true,
      Color = theme.text,
      Fill = theme.panelRaised,
      FontSize = 10
    })
  end
  addLabel("IP MODE", 648, 239, 110, 15, 9, theme.muted)
  addControl("IPMode", "Network~IP Mode", "Button", 648, 258, 110, 32, {
    Legend = "DHCP",
    Color = theme.panelRaised
  })

  addPanel("DISCOVERED PERIPHERALS", 20, 335, 755, math.max(420, 100 + deviceCount * 22))
  addLabel("MODEL FILTER", 34, 355, 136, 15, 9, theme.muted)
  addControl("DeviceModelFilter", "Devices~Model Filter", "ComboBox", 34, 373, 220, 30, {
    FontSize = 10
  })
  addControl("DeviceListSummary", "Devices~Filter Summary", "Text", 270, 373, 488, 30, {
    IsReadOnly = true,
    Color = theme.text,
    Fill = theme.panelRaised,
    FontSize = 9
  })
  local headerY = 414
  local columns = {
    {"ID", 34, 48},
    {"MODEL", 92, 126},
    {"DEVICE NAME", 226, 136},
    {"IP ADDRESS", 370, 128},
    {"DESIGN ON DEVICE", 508, 250}
  }
  for _, column in ipairs(columns) do
    addLabel(column[1], column[2], headerY, column[3], 16, 9, theme.accent)
  end

  local rowY = headerY + 20
  for i = 1, deviceCount do
    local y = rowY + ((i - 1) * 22)
    local rowColor = i % 2 == 0 and theme.rowB or theme.rowA
    addControl("ID " .. i, "Device " .. i .. "~ID", "Button", 34, y, 48, 20, {
      Legend = "ID_OFF",
      Color = theme.panelRaised,
      FontSize = 8
    })
    addControl("DeviceModel " .. i, "Device " .. i .. "~Model", "Text", 92, y, 126, 20, {
      IsReadOnly = true,
      Color = rowColor,
      FontSize = 9
    })
    addControl("DeviceName " .. i, "Device " .. i .. "~Name", "Text", 226, y, 136, 20, {
      IsReadOnly = true,
      Color = rowColor,
      FontSize = 9
    })
    addControl("DeviceIP " .. i, "Device " .. i .. "~IP", "Text", 370, y, 128, 20, {
      IsReadOnly = true,
      Color = rowColor,
      FontSize = 9
    })
    addControl("DesignOnDevice " .. i, "Device " .. i .. "~Design", "Text", 508, y, 250, 20, {
      IsReadOnly = true,
      Color = rowColor,
      FontSize = 9
    })
  end

elseif CurrentPage == "Extra Stuff" then
  addBackground()
  addPanel("", 20, 16, 755, 70)
  addLabel("DEVICE UTILITIES", 38, 27, 430, 28, 20, theme.text)
  addLabel("MAINTENANCE  /  DIAGNOSTICS", 40, 56, 470, 16, 9, theme.muted)

  addPanel("PERIPHERAL TOOLS", 20, 110, 755, 280)
  addLabel("Choose a discovered peripheral to inspect or manage.", 42, 140, 690, 18, 10, theme.muted)
  addLabel("DEVICE", 42, 178, 280, 15, 9, theme.muted)
  addControl("Device", "Utilities~Device", "ComboBox", 42, 197, 330, 32, {
    FontSize = 11
  })
  addLabel("IP ADDRESS", 398, 178, 300, 15, 9, theme.muted)
  addControl("IP", "Utilities~IP", "Text", 398, 197, 330, 32, {
    IsReadOnly = true,
    Color = theme.text,
    Fill = theme.panelRaised,
    FontSize = 11
  })
  addLabel("Actions", 42, 255, 300, 18, 10, theme.text)
  addControl("Reboot", "Utilities~Reboot", "Button", 42, 286, 180, 42, {
    Legend = "REBOOT DEVICE",
    Color = theme.panelRaised
  })
  addControl("DownloadLogfile", "Utilities~Download Log", "Button", 240, 286, 220, 42, {
    Legend = "DOWNLOAD LOG FILE",
    Color = theme.accent
  })
end
