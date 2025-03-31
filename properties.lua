table.insert(props, {
  Name = "Debug Print",
  Type = "enum",
  Choices = {"None", "Tx/Rx", "Tx", "Rx", "Function Calls", "All"},
  Value = "None"
})

table.insert(props, {
  Name = "Device Count",
  Type = "integer",
  Min = 1,
  Max = 100,
  Value = 50
})

