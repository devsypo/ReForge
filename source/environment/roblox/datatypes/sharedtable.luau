local Manager: table = require("@env/manager")
local SharedTable: table = Manager.create()
local Internal: table = {}

local function DeepClone(Value: any): table
  if type(Value) ~= "table" then
    return Value
  end

  local Copy: table = {}
  
  for k, v in pairs(Value) do
    Copy[DeepClone(k)] = DeepClone(v)
  end

  return Copy :: table
end

SharedTable:define("new", function(Predefined): table
  Predefined = Predefined or {}

  Internal[Predefined] = {
    __IsFrozen = false,
    Data = table.clone(Predefined)
  }

  return Predefined
end)

SharedTable:define("clear", function(Table: SharedTable)
  local Info: table = Internal[Table]
  SharedTable:checktype(1, Info, "table")

  if Info.__IsFrozen then
    error("SharedTable is frozen", 2)
  end

  for Key in pairs(Info.Data) do
    Info.Data[Key] = nil
  end
end)

SharedTable:define("cloneAndFreeze", function(Table: SharedTable, Deep: bool): SharedTable
  local Info: table = Internal[Table]
  SharedTable:checktype(1, Info, "table")

  local Cloned: table
  if Deep then
    Cloned = DeepClone(Info.Data)
  else
    Cloned = table.clone(Info.Data)
  end

  Internal[Cloned] = {
    __IsFrozen = true,
    Data = Cloned
  }

  return Cloned
end)

SharedTable:define("clone", function(Table: SharedTable, Deep: bool): SharedTable
  local Info: table = Internal[Table]
  SharedTable:checktype(1, Info, "table")

  local Cloned: table
  if Deep then
    Cloned = DeepClone(Info.Data)
  else
    Cloned = table.clone(Info.Data)
  end

  Internal[Cloned] = {
    __IsFrozen = Info.__IsFrozen,
    Data = Cloned
  }

  return Cloned :: table
end)

SharedTable:define("freeze", function(Table: SharedTable)
  local Info: table = Internal[Table]
  SharedTable:checktype(1, Info, "table")
  
  Info.__IsFrozen = true
end)

SharedTable:define("increment", function(Table: SharedTable, Key: string | number, Delta: number)
  local Info: table = Internal[Table]
  SharedTable:checktype(1, Info, "table")

  if Info.__IsFrozen then
    error("SharedTable is frozen", 2)
  end

  local Value: number = Info.Data[Key]
  checktype(2, Value, "number")

  Info.Data[Key] = Value + Delta
  
  return Value
end)

SharedTable:define("isFrozen", function(Table: SharedTable): boolean
  local Info: table = Internal[Table]
  if type(Info) ~= "table" then
    return false
  end

  return Info.__IsFrozen == true
end)

SharedTable:define("size", function(Table: SharedTable): number
  local Info: table = Internal[Table]
  if not Info then
    return 0
  end

  local Count: number = 0
  for _ in pairs(Info.Data) do
    Count += 1
  end

  return Count :: number
end)  

SharedTable:define("update", function(Table: SharedTable, Key: string | number, Function: Func)
  local Info: table = Internal[Table]
  SharedTable:checktype(1, Info, "table")

  if Info.__IsFrozen then
    error("SharedTable is frozen", 2)
  end

  local CurrentValue = Info.Data[Key]
  SharedTable:checktype(3, Function, "function")

  local NewValue = Function(CurrentValue)
  Info.Data[Key] = NewValue
end)

return SharedTable:export()