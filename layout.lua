local CurrentPage = PageNames[props["page_index"].Value]
local deviceCount = props["Device Count"].Value

layout["code"]={
    PrettyName="code",
    Style="None",
    Position={0,0},
    Size={0,0},
    IsReadOnly=true,
    Color={0,0,0}
}

table.insert(graphics, {
  Type = "GroupBox",
  Text = "Network Warning",
  Fill = {255, 200, 0},
  StrokeWidth = 1,
  StrokeColor = {180, 80, 0},
  CornerRadius = 6,
  Position = {25, 4},
  Size = {737, 32},
  FontSize = 10,
  HTextAlign = "Left"
})

table.insert(graphics, {
  Type = "Text",
  Text = "WARNING: Running Fast Deploy in multiple places on the same network at the same time can cause havoc. Only one user at a time per network.",
  Position = {32, 9},
  Size = {723, 22},
  FontSize = 9,
  Color = {0, 0, 0},
  HTextAlign = "Left",
  VTextAlign = "Center"
})


if CurrentPage == "Main UI" then
   

    -- Description section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Fast Deploy Description of Function",
      Fill = {48, 73, 96},
      StrokeWidth = 1,
      StrokeColor = {255, 255, 255},
      CornerRadius = 8,
      Position = {25, 55},
      Size = {737,139},
      FontSize = 14,
      Color = {0, 0, 0}
    })

    -- Description text
    table.insert(graphics, {
      Type = "Text",
      Text = "Streamlined Pairing: Enables quick pairing of inventory items to peripheral on the network via the core, simplifying device integration. \n\nRemote Management: Designed to work seamlessly with Q-SYS Reflect Enterprise Manager, enhancing remote management capabilities. \n\nUCI Support: Allows pairing of devices to a User Control Interface (UCI) without requiring a laptop in the room, improving efficiency. \n\nFlexible Deployment: Ideal for assigning cold storage devices to specific rooms or rapidly deploying devices across a system.",
      Position = {25, 78},
      Size = {737,116},
      FontSize = 12,
      Color = {255, 255, 255},
      HTextAlign = "Left"
    })



    -- Refresh section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Refresh Devices",
      Fill = {213,233, 215},
      StrokeWidth = 1,
      StrokeColor = {0,0,0},
      CornerRadius = 8,
      Position = {25, 204},
      Size = {737, 63},
      FontSize = 12
    })

    layout["Get"] = {
      PrettyName = "Action~Refresh",
      Style = "Button",
      Position = {288, 228},
      Size = {204, 32},
      Color = {236, 236, 236},
      Legend = "Refresh"
    }

    layout["SessionStatus"] = {
      PrettyName = "Session~Status",
      Style = "Text",
      Position = {500, 228},
      Size = {170, 32},
      IsReadOnly = true,
      FontSize = 10,
      Color = {220, 220, 220},
      HTextAlign = "Left"
    }

    layout["ReleaseSession"] = {
      PrettyName = "Session~Release",
      Style = "Button",
      Position = {675, 228},
      Size = {72, 32},
      Color = {255, 200, 150},
      Legend = "Release"
    }

    -- Main pairing section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Pairing Inventory to Peripheral",
      Fill = {},
      StrokeWidth = 1,
      StrokeColor = {0,0,0},
      CornerRadius = 8,
      Position = {25, 286},
      Size = {737,473},
      FontSize = 12
    })

    -- Inventory section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Inventory",
      Fill = {153,204,255},
      StrokeWidth = 1,
      StrokeColor = {120, 120, 120},
      CornerRadius = 6,
      Position = {38, 410},
      Size = {309,89},
      FontSize = 12,
      HTextAlign = "Left"
    })

    table.insert(graphics, {
      Type = "Text",
      Text = "Model",
      Position = {46, 439},
      Size = {136,16},
      FontSize = 12,
      Color = {0, 0, 0},
      HTextAlign = "Left"
    })

    layout["InventoryModel"] = {
      PrettyName = "Inventory~Model",
      Style = "ComboBox",
      Position = {46, 460},
      Size = {136,26},
      FontSize = 12
    }
    
    table.insert(graphics, {
      Type = "Text",
      Text = "Name",
      Position = {196, 439},
      Size = {136,16},
      FontSize = 12,
      Color = {0, 0, 0},
      HTextAlign = "Left"
    })

    layout["InventoryName"] = {
      PrettyName = "Inventory~Name",
      Style = "ComboBox",
      Position = {196, 460},
      Size = {136,26},
      FontSize = 11
    }

    -- Peripheral section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Peripheral",
      Fill = {89,218,136},
      StrokeWidth = 1,
      StrokeColor = {0,0,0},
      CornerRadius = 8,
      Position = {362, 410},
      Size = {225,89},
      FontSize = 12,
      HTextAlign = "Left"
    })

    table.insert(graphics, {
      Type = "Text",
      Text = "Select Network Device to Pair",
      Position = {389, 439},
      Size = {170,16},
      FontSize = 12,
      Color = {0, 0, 0},
      HTextAlign = "Left"
    })

    layout["AssignToDevice"] = {
      PrettyName = "Assign~To Device",
      Style = "ComboBox",
      Position = {389, 460},
      Size = {170,26},
      FontSize = 12
    }

    layout["Assign"] = {
      PrettyName = "Action~Assign",
      Style = "Button",
      Position = {596, 410},
      Size = {91,90},
      Color = {0, 255, 128},
      Legend = "Select\nPeripheral"
    }

    -- IP Mode section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Peripheral Ip Mode",
      Fill = {255,175,96},
      StrokeWidth = 1,
      StrokeColor = {0,0,0},
      CornerRadius = 8,
      Position = {38, 512},
      Size = {549,78},
      FontSize = 12,
      HTextAlign = "Left"
    })

    layout["IPMode"] = {
      PrettyName = "Network~IP Mode",
      Style = "Button",
      Position = {46, 538},
      Size = {110,35},
      Color = {105,105,105},
      Legend = "DHCP"
    }

    -- IP Address section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "IP Address of Peripheral to be paired",
      StrokeWidth = 1,
      StrokeColor = {0,0,0},
      CornerRadius = 8,
      Position = {227, 530},
      Size = {270,48},
      FontSize = 12,
      HTextAlign = "Left"
    })



    layout["ThirdOctet"] = {
      PrettyName = "IP~Third Octet",
      Style = "ComboBox",
      Position = {362, 557},
      Size = {61,16},
      FontSize = 12
    }

    layout["LastOctet"] = {
      PrettyName = "IP~Last Octet",
      Style = "ComboBox",
      Position = {431, 557},
      Size = {61,16},
      FontSize = 12
    }

    layout["BaseOctets 1"] = {
      PrettyName = "IP~First Octet",
      Style = "Text",
      Position = {230, 557},
      Size = {61,16},
      FontSize = 12,
      Fill = {255,255,255},
    }

    layout["BaseOctets 2"] = {
      PrettyName = "IP~Second Octet",
      Style = "Text",
      Position = {296, 557},
      Size = {61,16},
      FontSize = 12,     
    }

    table.insert(graphics, {
      Type = "Text",
      Text = ".",
      Position = {291, 562},
      Size = {6,11},
      FontSize = 12,
      Color = {0,0,0},
      HTextAlign = "Left"
    })

    table.insert(graphics, {
      Type = "Text",
      Text = ".",
      Position = {357, 562},
      Size = {6,11},
      FontSize = 12,
      Color = {0,0,0},
      HTextAlign = "Left"
    })
    table.insert(graphics, {
      Type = "Text",
      Text = ".",
      Position = {426, 562},
      Size = {6,11},
      FontSize = 12,
      Color = {0,0,0},
      HTextAlign = "Left"
    })
    -- Information section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Information",
      Fill = {255,132,132},
      StrokeWidth = 1,
      StrokeColor = {0,0,0},
      CornerRadius = 8,
      Position = {38, 600},
      Size = {549,149},
      FontSize = 12,
      HTextAlign = "Left"
    })

    layout["PairingByNameDebug"] = {
      PrettyName = "Debug~Status",
      Style = "Text",
      Position = {145, 612},
      Size = {347,131},
      IsReadOnly = true,
      Color = {239, 205, 205},
      StrokeColor = {0,0,0},
      FontSize = 9,
      HTextAlign = "Left"
    }

    -- Default Naming section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Default Naming",
      Fill = {255,255,174},
      StrokeWidth = 1,
      StrokeColor = {0,0,0},
      CornerRadius = 8,
      Position = {602, 600},
      Size = {152,149},
      FontSize = 12,
      Color = {0,0,0}
    })

    table.insert(graphics, {
      Type = "Text",
      Text = "Press\nReset Name\nto revert name to\nFactory Default",
      Position = {613, 622},
      Size = {129,77},
      FontSize = 10,
      Color = {0,0,0},
      HTextAlign = "Center"
    })

    layout["ResetName"] = {
      PrettyName = "Action~Reset Name",
      Style = "Button",
      Position = {635, 711},
      Size = {95,32},
      Color = {255, 255, 0},
      Legend = "Reset Name"
    }

elseif CurrentPage == "Pair by ID" then

    layout["PairWithIdDirections 1"] = {
      PrettyName = "Help~Directions",
      Style = "Text",
      Position = {38, 58},
      Size = {334, 88},
      IsReadOnly = true,
      Color = {255, 255, 255},
      FontSize = 8
    }

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Directions",
      Fill = {255, 255, 255},
      StrokeWidth = 1,
      StrokeColor = {0, 0, 0},
      CornerRadius = 6,
      Position = {25, 40},
      Size = {360, 108},
      FontSize = 11,
      HTextAlign = "Left"
    })

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Pair by ID",
      Fill = {194, 194, 194},
      StrokeWidth = 1,
      StrokeColor = {0, 0, 0},
      CornerRadius = 8,
      Position = {25, 158},
      Size = {360, 90},
      FontSize = 12,
      HTextAlign = "Left"
    })

    layout["PairWithID"] = {
      PrettyName = "Action~Pair With ID",
      Style = "Button",
      Position = {45, 188},
      Size = {120, 50},
      Color = {0, 128, 255},
      Legend = "Pair\nWith ID"
    }

    layout["SessionStatus"] = {
      PrettyName = "Session~Status",
      Style = "Text",
      Position = {180, 195},
      Size = {130, 36},
      IsReadOnly = true,
      FontSize = 9,
      Color = {220, 220, 220},
      HTextAlign = "Left"
    }

    layout["ReleaseSession"] = {
      PrettyName = "Session~Release",
      Style = "Button",
      Position = {315, 195},
      Size = {60, 36},
      Color = {255, 200, 150},
      Legend = "Release"
    }

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Inventory",
      Fill = {153, 204, 255},
      StrokeWidth = 1,
      StrokeColor = {120, 120, 120},
      CornerRadius = 6,
      Position = {25, 258},
      Size = {360, 95},
      FontSize = 12,
      HTextAlign = "Left"
    })

    table.insert(graphics, {
      Type = "Text",
      Text = "Location",
      Position = {38, 281},
      Size = {100, 16},
      FontSize = 11,
      Color = {0, 0, 0},
      HTextAlign = "Left"
    })

    layout["InventoryLocation"] = {
      PrettyName = "Inventory~Location",
      Style = "ComboBox",
      Position = {38, 301},
      Size = {100, 26},
      FontSize = 11
    }

    table.insert(graphics, {
      Type = "Text",
      Text = "Model",
      Position = {148, 281},
      Size = {100, 16},
      FontSize = 11,
      Color = {0, 0, 0},
      HTextAlign = "Left"
    })

    layout["InventoryModel"] = {
      PrettyName = "Inventory~Model",
      Style = "ComboBox",
      Position = {148, 301},
      Size = {100, 26},
      FontSize = 11
    }

    table.insert(graphics, {
      Type = "Text",
      Text = "Name",
      Position = {258, 281},
      Size = {100, 16},
      FontSize = 11,
      Color = {0, 0, 0},
      HTextAlign = "Left"
    })

    layout["InventoryName"] = {
      PrettyName = "Inventory~Name",
      Style = "ComboBox",
      Position = {258, 301},
      Size = {100, 26},
      FontSize = 11
    }

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Next Up",
      Fill = {220, 220, 220},
      StrokeWidth = 1,
      StrokeColor = {0, 0, 0},
      CornerRadius = 6,
      Position = {25, 363},
      Size = {360, 55},
      FontSize = 12,
      HTextAlign = "Left"
    })

    layout["OneShotNextUp"] = {
      PrettyName = "One Shot~Next Up",
      Style = "Text",
      Position = {38, 386},
      Size = {334, 24},
      IsReadOnly = true,
      FontSize = 14
    }

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "To Be Paired",
      StrokeWidth = 1,
      StrokeColor = {0, 0, 0},
      CornerRadius = 6,
      Position = {400, 40},
      Size = {180, 478},
      FontSize = 12,
      HTextAlign = "Left"
    })

    layout["OneShotToBePaired"] = {
      PrettyName = "One Shot~To Be Paired",
      Style = "ListBox",
      Position = {408, 62},
      Size = {164, 448},
      FontSize = 11,
      IsReadOnly = true
    }

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Paired",
      StrokeWidth = 1,
      StrokeColor = {0, 0, 0},
      CornerRadius = 6,
      Position = {590, 40},
      Size = {180, 478},
      FontSize = 12,
      HTextAlign = "Left"
    })

    layout["OneShotPaired"] = {
      PrettyName = "One Shot~Paired",
      Style = "ListBox",
      Position = {598, 62},
      Size = {164, 448},
      FontSize = 11,
      IsReadOnly = true
    }

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Information",
      Fill = {255, 132, 132},
      StrokeWidth = 1,
      StrokeColor = {0, 0, 0},
      CornerRadius = 8,
      Position = {25, 425},
      Size = {360, 93},
      FontSize = 12,
      HTextAlign = "Left"
    })

    layout["PairingByNameDebug"] = {
      PrettyName = "Debug~Status",
      Style = "Text",
      Position = {38, 442},
      Size = {334, 68},
      IsReadOnly = true,
      Color = {239, 205, 205},
      FontSize = 9,
      HTextAlign = "Left"
    }

    layout["PairWithIdDirections 2"] = {
      PrettyName = "Help~ID Warnings",
      Style = "Text",
      Position = {0, 0},
      Size = {0, 0},
      IsReadOnly = true,
      IsInvisible = true,
      Color = {255, 255, 255},
      FontSize = 12
    }

elseif CurrentPage == "Network Device List" then
    -- Dark background
    -- table.insert(graphics, {
    --   Type = "GroupBox",
    --   Text = "",
    --   StrokeWidth = 0,
    --   Position = {0, 0},
    --   Size = {795,780}
    -- })

    -- Top network info boxes
    -- table.insert(graphics, {
    --   Type = "GroupBox",
    --   Text = "",
    --   Fill = {54, 56, 62},
    --   StrokeWidth = 1,
    --   StrokeColor = {80, 80, 80},
    --   Position = {100, 100},
    --   Size = {169,89}
    -- })
    
    -- table.insert(graphics, {
    --   Type = "GroupBox",
    --   Text = "",
    --   Fill = {54, 56, 62},
    --   StrokeWidth = 1,
    --   StrokeColor = {80, 80, 80},
    --   Position = {544, 100},
    --   Size = {192, 136}
    -- })
    
    -- Network info text
    layout["CurrentLanAConfig"] = {
      PrettyName = "LanAConfig",
      Style = "Text",
      Position = {108, 50},
      Size = {161,81},
      Fill = {194,194,194},
      
      FontSize = 9
    }

    -- Refresh section
    -- table.insert(graphics, {
    --   Type = "GroupBox",
    --   Text = "Refresh Devices",
    --   Fill = {213,233, 215},
    --   StrokeWidth = 1,
    --   StrokeColor = {0,0,0},
    --   CornerRadius = 8,
    --   Position = {288, 50},
    --   Size = {204, 63},
    --   FontSize = 12
    -- })

    layout["Get"] = {
      PrettyName = "Action~Refresh",
      Style = "Button",
      Position = {288, 68},
      Size = {204, 32},
      Color = {236, 236, 236},
      Legend = "Refresh"
    }

    layout["CurrentLanBConfig"] = {
      PrettyName = "LanBConfig",
      Style = "Text",
      Position = {545, 50},
      Size = {161,81},
      Fill = {194,194,194},
      
      FontSize = 9
    }
    
    -- Network Settings section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Network Settings",
      Fill = {194,194,194},
      StrokeWidth = 1,
      StrokeColor = {80, 80, 80},
      Position = {12, 151},
      Size = {790,66},
      FontSize = 12,
      Color = {0,0,0},
      HTextAlign = "Left"
    })
    
    -- Network settings fields
    table.insert(graphics, {
      Type = "Text",
      Text = "Netmask",
      Position = {30, 175},
      Size = {128,16},
      FontSize = 11,
      HTextAlign = "Left"
    })
    
    layout["NewNetmask"] = {
      PrettyName = "Network~Netmask",
      Style = "Text",
      Position = {30, 191},
      Size = {128,16},
      FontSize = 11,
      IsReadOnly = true
    }
    
    table.insert(graphics, {
      Type = "Text",
      Text = "Gateway",
      Position = {173, 175},
      Size = {128,16},
      FontSize = 11,
      HTextAlign = "Left"
    })
    
    layout["NewGateway"] = {
      PrettyName = "Network~Gateway",
      Style = "Text",
      Position = {173, 191},
      Size = {128,16},
      FontSize = 11,
      IsReadOnly = true
    }
    
    table.insert(graphics, {
      Type = "Text",
      Text = "NetworkPrefix",
      Position = {312, 175},
      Size = {128,16},
      FontSize = 11,
      HTextAlign = "Left"
    })
    
    layout["NewNetworkPrefix"] = {
      PrettyName = "Network~Prefix",
      Style = "Text",
      Position = {312, 191},
      Size = {128,16},
      FontSize = 11,
      IsReadOnly = true
      
    }
    
    table.insert(graphics, {
      Type = "Text",
      Text = "IPRange",
      Position = {459, 175},
      Size = {128,16},
      FontSize = 11,
      HTextAlign = "Left"
    })
    
    layout["NewIPRange"] = {
      PrettyName = "Network~IP Range",
      Style = "Text",
      Position = {458, 191},
      Size = {128,16},
      FontSize = 11,
      IsReadOnly = true
    }
    
    table.insert(graphics, {
      Type = "Text",
      Text = "IPMode",
      Position = {667, 175},
      Size = {64,16},
      FontSize = 10,
      HTextAlign = "Left"
    })
    
    layout["IPMode"] = {
      PrettyName = "Network~IP Mode",
      Style = "Button",
      Position = {667, 191},
      Size = {64,16},
      Legend = "DHCP"
    }
    
    -- Device List Headers
    local headerY = 246
    local idX = 9
    local modelX = 53
    local nameX = 190
    local ipX = 324
    local designX = 463
    table.insert(graphics, {
      Type = "Text",
      Text = "ID",
      Position = {idX, headerY},
      Size = {36, 16},
      FontSize = 11,
      HTextAlign = "Left"
    })
    
    table.insert(graphics, {
      Type = "Text",
      Text = "DeviceModel",
      Position = {modelX, headerY},
      Size = {128, 16},
      FontSize = 11,
      HTextAlign = "Left"
    })
    
    table.insert(graphics, {
      Type = "Text",
      Text = "DeviceName",
      Position = {nameX, headerY},
      Size = {120, 16},
      FontSize = 11,
      HTextAlign = "Left"
    })
    
    table.insert(graphics, {
      Type = "Text",
      Text = "DeviceIP",
      Position = {ipX, headerY},
      Size = {100, 16},
      FontSize = 11,
      HTextAlign = "Left"
    })
    
    table.insert(graphics, {
      Type = "Text",
      Text = "DesignOnDevice",
      Position = {designX, headerY},
      Size = {150, 16},
      FontSize = 11,
      HTextAlign = "Left"
    })
    
    -- Device List Items
    for i = 1, deviceCount do
      local yPos = headerY + 16 + ((i-1) * 20)
      
      layout["ID " .. i  ] = {
        PrettyName = "Device " .. i .. "~ID",
        Style = "Button",
        Position = {idX, yPos},
        Size = {36, 16},
        Legend = "ID_OFF"
      }
      
      layout["DeviceModel " .. i ] = {
        PrettyName = "Device " .. i .. "~Model",
        Style = "Text",
        Position = {modelX, yPos},
        Size = {128, 16},
        Color = i % 2 == 0 and {50, 50, 50} or {40, 40, 40},
        IsReadOnly = true
      }
      
      layout["DeviceName " .. i ] = {
        PrettyName = "Device " .. i .. "~Name",
        Style = "Text",
        Position = {nameX, yPos},
        Size = {128, 16},
        Color = i % 2 == 0 and {50, 50, 50} or {40, 40, 40},
        IsReadOnly = true
      }
      
      layout["DeviceIP " .. i ] = {
        PrettyName = "Device " .. i .. "~IP",
        Style = "Text",
        Position = {ipX, yPos},
        Size = {128, 16},
        Color = i % 2 == 0 and {50, 50, 50} or {40, 40, 40},
        IsReadOnly = true
      }
      
      layout["DesignOnDevice " .. i ] = {
        PrettyName = "Device " .. i .. "~Design",
        Style = "Text",
        Position = {designX, yPos},
        Size = {341, 16},
        Color = i % 2 == 0 and {50, 50, 50} or {40, 40, 40},
        IsReadOnly = true
      }
      
      -- Hidden elements that are used elsewhere
    --   layout["IDPairing[" .. i .. "]"] = {
    --     PrettyName = "Device " .. i .. "~ID Pairing",
    --     Style = "Button",
    --     Position = {15, yPos},
    --     Size = {45, 16},
    --     IsInvisible = true
    --   }
      
    --   layout["PeripheralInfo[" .. i .. "]"] = {
    --     PrettyName = "Device " .. i .. "~Info",
    --     Style = "Text",
    --     Position = {15, yPos},
    --     Size = {45, 16},
    --     IsInvisible = true
    --   }
    end
    
    -- Slider background (visible on right side in screenshot)
    -- table.insert(graphics, {
    --   Type = "GroupBox",
    --   Text = "",
    --   Fill = {70, 130, 70},
    --   StrokeWidth = 0,
    --   Position = {756, 746},
    --   Size = {16, 8},
    --   FontSize = 1
    -- })

elseif CurrentPage == "Leaderboards" then

    local arcadeBg = {12, 8, 32}
    local arcadeCyan = {0, 255, 255}
    local arcadeYellow = {255, 255, 0}
    local arcadeMagenta = {255, 0, 255}
    local arcadeGreen = {0, 255, 128}

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "",
      Fill = arcadeBg,
      StrokeWidth = 0,
      Position = {0, 40},
      Size = {795, 740}
    })

    table.insert(graphics, {
      Type = "Text",
      Text = "* * *  F A S T   D E P L O Y   —   H I G H   S C O R E S  * * *",
      Position = {80, 48},
      Size = {635, 22},
      FontSize = 14,
      Color = arcadeYellow,
      HTextAlign = "Center"
    })

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "HIGH SCORES",
      Fill = {20, 16, 48},
      StrokeWidth = 2,
      StrokeColor = arcadeCyan,
      CornerRadius = 4,
      Position = {25, 78},
      Size = {745, 72},
      FontSize = 12,
      Color = arcadeCyan,
      HTextAlign = "Left"
    })

    layout["LeaderboardSummary"] = {
      PrettyName = "Leaderboards~Summary",
      Style = "Text",
      Position = {40, 100},
      Size = {715, 40},
      IsReadOnly = true,
      FontSize = 11,
      Color = arcadeGreen,
      HTextAlign = "Left"
    }

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "TOP 10 FASTEST",
      Fill = {20, 16, 48},
      StrokeWidth = 2,
      StrokeColor = arcadeCyan,
      CornerRadius = 4,
      Position = {25, 162},
      Size = {360, 220},
      FontSize = 11,
      Color = arcadeCyan,
      HTextAlign = "Left"
    })

    layout["LeaderboardFastest"] = {
      PrettyName = "Leaderboards~Fastest",
      Style = "Text",
      Position = {35, 182},
      Size = {340, 190},
      IsReadOnly = true,
      FontSize = 10,
      Color = arcadeCyan,
      HTextAlign = "Left"
    }

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "TOP 10 SLOWEST",
      Fill = {20, 16, 48},
      StrokeWidth = 2,
      StrokeColor = arcadeMagenta,
      CornerRadius = 4,
      Position = {410, 162},
      Size = {360, 220},
      FontSize = 11,
      Color = arcadeMagenta,
      HTextAlign = "Left"
    })

    layout["LeaderboardSlowest"] = {
      PrettyName = "Leaderboards~Slowest",
      Style = "Text",
      Position = {420, 182},
      Size = {340, 190},
      IsReadOnly = true,
      FontSize = 10,
      Color = arcadeMagenta,
      HTextAlign = "Left"
    }

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "BY DEVICE TYPE",
      Fill = {20, 16, 48},
      StrokeWidth = 2,
      StrokeColor = arcadeYellow,
      CornerRadius = 4,
      Position = {25, 394},
      Size = {745, 200},
      FontSize = 11,
      Color = arcadeYellow,
      HTextAlign = "Left"
    })

    layout["LeaderboardByType"] = {
      PrettyName = "Leaderboards~By Type",
      Style = "Text",
      Position = {35, 414},
      Size = {725, 170},
      IsReadOnly = true,
      FontSize = 10,
      Color = arcadeYellow,
      HTextAlign = "Left"
    }

    table.insert(graphics, {
      Type = "GroupBox",
      Text = "TIME SAVED",
      Fill = {20, 16, 48},
      StrokeWidth = 2,
      StrokeColor = arcadeGreen,
      CornerRadius = 4,
      Position = {25, 606},
      Size = {520, 56},
      FontSize = 11,
      Color = arcadeGreen,
      HTextAlign = "Left"
    })

    layout["LeaderboardTimeSaved"] = {
      PrettyName = "Leaderboards~Time Saved",
      Style = "Text",
      Position = {40, 626},
      Size = {490, 28},
      IsReadOnly = true,
      FontSize = 12,
      Color = arcadeGreen,
      HTextAlign = "Left"
    }

    layout["LeaderboardResetStats"] = {
      PrettyName = "Leaderboards~Reset Stats",
      Style = "Button",
      Position = {565, 616},
      Size = {120, 36},
      Color = {180, 40, 80},
      Legend = "RESET\nSTATS"
    }

elseif CurrentPage == "Extra Stuff" then
    -- Dark background
    -- table.insert(graphics, {
    --   Type = "GroupBox",
    --   Text = "",
    --   StrokeWidth = 0,
    --   Position = {0, 0},
    --   Size = {795,780}
   
    -- })

    -- Utilities section
    table.insert(graphics, {
      Type = "GroupBox",
      Text = "Utilities",
      Fill = lightgrey,
      StrokeWidth = 1,

      Position = {53, 125},
      Size = {359, 171},
      CornerRadius = 8,
      HTextAlign = "Left",
      FontSize = 12
    })

    table.insert(graphics, {
      Type = "Text",
      Text = "Device",
      Position = {77, 178},
      Size = {50, 16},
      FontSize = 11,
      HTextAlign = "Left"
    })

    layout["Device"] = {
      PrettyName = "Utilities~Device",
      Style = "ComboBox",
      Position = {135, 178},
      Size = {200, 25},
      FontSize = 11
    }

    table.insert(graphics, {
      Type = "Text",
      Text = "IP",
      Position = {77, 218},
      Size = {50, 16},
      FontSize = 11,

      HTextAlign = "Left"
    })

    layout["IP"] = {
      PrettyName = "Utilities~IP",
      Style = "Text",
      Position = {135, 218},
      Size = {200, 25},

      IsReadOnly = true
    }

    -- Action buttons
    layout["Reboot"] = {
      PrettyName = "Utilities~Reboot",
      Style = "Button",
      Position = {135, 263},
      Size = {90, 25},
      Legend = "Reboot"
    }

    layout["DownloadLogfile"] = {
      PrettyName = "Utilities~Download Log",
      Style = "Button",
      Position = {245, 263},
      Size = {125, 25},
      Legend = "Download Log File"
    }

    -- -- Hidden elements that we need to keep but don't show on this page
    -- layout["Dtype"] = {
    --   PrettyName = "Utilities~Device Type",
    --   Style = "Text",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["StaticOrAuto"] = {
    --   PrettyName = "Utilities~IP Mode",
    --   Style = "Text",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["SetDHCP"] = {
    --   PrettyName = "Utilities~Set DHCP",
    --   Style = "Button",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["SetStatic"] = {
    --   PrettyName = "Utilities~Set Static",
    --   Style = "Button",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["ScanIPs"] = {
    --   PrettyName = "Utilities~Scan IPs",
    --   Style = "Button", 
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["NewNetworkPrefix"] = {
    --   PrettyName = "Network~Prefix",
    --   Style = "Text",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["NewNetmask"] = {
    --   PrettyName = "Network~Netmask", 
    --   Style = "Text",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["NewGateway"] = {
    --   PrettyName = "Network~Gateway",
    --   Style = "Text",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["NewIPRange"] = {
    --   PrettyName = "Network~IP Range",
    --   Style = "Text",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["LocalDesignName"] = {
    --   PrettyName = "Network~Current Design",
    --   Style = "Text",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["CurrentLanAConfig"] = {
    --   PrettyName = "Network~LAN A Config",
    --   Style = "Text",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }

    -- layout["CurrentLanBConfig"] = {
    --   PrettyName = "Network~LAN B Config",
    --   Style = "Text",
    --   Position = {0, 0},
    --   Size = {0, 0},
    --   IsInvisible = true
    -- }
end
