local Process: table = require("@lune/process")
local Manager: table = require("@env/manager")
local Internal: table = require("@env/internal")
local Instrument: table = Manager.create()

local CallStack: table = Internal.CallStack
local CallHooks: table = Internal.CallHooks
local Script: table = Internal.Script

Instrument:define("CALL", function(FuncName: string, Object: any, ...: any?): any
  local Arguments: table = {...}
  local ArgCount: number = select("#", ...)
  
  if not Object then
    error("attempt to call a nil value", 2)
  end
  
  local Hooked: any = CallHooks[Object]
  local Line, Name, Count, Variadic = debug.info(Hooked or Object, "lna")

  local FuncID = nil
  if Script.Functions[Object] then
    FuncID = Script.Functions[Object].Id
  end
  
  CallStack.Level += 1
  table.insert(CallStack.Stack, {
    Name = FuncName,
    Object = Hooked or Object,
    Level = CallStack.Level,
    Orginal = Object,
    Type = "Call",
    ReturnValues = nil,
    Metadata = {
      Hooked = Hooked and Object,
      Id = FuncID,
      Arguments = Arguments,
      Line = Line,
      Name = Name,
      Count = Count,
      Variadic = Variadic
    }
  })
  
  local Status: bool, Result: table = pcall(function()
    return { (Hooked or Object)(unpack(Arguments, 1, ArgCount)) }
  end)

  table.remove(CallStack.Stack)
  CallStack.Level -= 1

  if not Status then
    error(Result, 2)
  end
  
  return unpack(Result, 1, #Result)
end)

Instrument:define("NAMECALL", function(Table: table, Index: table, ...: any): any
  local Arguments: table = {...}
  local ArgCount: number = select("#", ...)
  local Object: any = Table[Index]
  
  if not Object then
    error("attempt to call a nil value", 2)
  end
  
  local Hooked: any = CallHooks[Object]
  local Line, Name, Count, Variadic = debug.info(Hooked or Object, "lna")
  
  local FuncID = nil
  if Script.Functions[Object] then
    FuncID = Script.Functions[Object].Id
  end
  
  CallStack.Level += 1
  table.insert(CallStack.Stack, {
    Name = Index,
    Object = Hooked or Object,
    Level = CallStack.Level,
    Orginal = Object,
    Table = Table,
    Type = "NameCall",
    ReturnValues = nil,
    Metadata = {
      Hooked = Hooked and Object,
      Id = FuncID,
      Arguments = Arguments,
      Line = Line,
      Name = Name,
      Count = Count,
      Variadic = Variadic
    }
  })

  local Status: bool, Result: table = pcall(function()
    return { (Hooked or Object)(Table, unpack(Arguments, 1, ArgCount)) }
  end)

  table.remove(CallStack.Stack)
  CallStack.Level -= 1

  if not Status then
    error(Result, 2)
  end
  
  return unpack(Result, 1, #Result)
end)

Instrument:define("DEFINE", function(FuncName: string, FuncID: number, Object: any, Upvalues): any
  Script.Functions[Object] = {
    Name = FuncName,
    Id = FuncID,
    Object = Object,
    Upvalues = Upvalues
  }
  
  return Object
end)

Instrument:define("RET", function(FuncID: number, ...: any)
  local Frame = CallStack.Stack[#CallStack.Stack]
  if Frame then
    Frame.ReturnValues = {...}
  end
  
  return ...
end)

return Instrument:export() :: table