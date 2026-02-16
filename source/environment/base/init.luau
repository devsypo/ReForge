local Internal: table = require("@env/internal")
local Task: table = require("@base/task")
local Bit: table = require("@base/bit")
local Manager: table = require("@env/manager")
local Base: table = Manager.create()

local CallStack: table = Internal.CallStack
local Script: table = Internal.Script
local FunctionEnv: table = Internal.FunctionEnv
local Private: table = Internal.Private

Base:mount("bit", Bit)
Base:mount("bit32", bit32)
Base:mount("buffer", buffer)
Base:mount("coroutine", coroutine)
Base:mount("debug", debug)
Base:mount("math", math)
Base:mount("os", os)
Base:mount("string", string)
Base:mount("table", table)
Base:mount("task", Task)
Base:mount("utf8", utf8)
Base:mount("vector", vector)

Base:define("print", function(...: any?): nil
  print("[PRINT]:", ...)
end)

Base:define("error", function(Message: any, Level: number?): nil
  Base:checktype(1, Message, "any")

  if Level ~= nil then
    Base:checktype(2, Level, "number")
  end

  return error(Message, Level)
end)

Base:define("loadstring", function(Content: string, ChunkName: string): ()
  Base:checktype(1, Content, "string")
  if ChunkName then
    Base:checktype(2, ChunkName, "string")
  end
  
end)

Base:define("require", function(Module: ModuleScript | string | number): any?
  Base:checktype(1, Module, "Instance")
  
end)

Base:define("ipairs", function(Table: table): ( (table, number) -> (number, any), table, number )
  Base:checktype(1, Table, "table")

  return ipairs(Table)
end)

Base:define("pairs", function(Table: table): ((table) -> (any, any), table, any)
  Base:checktype(1, Table, "table")

  return pairs(Table)
end)

Base:define("next", function(Table: table, Index: any?): (any, any)
  Base:checktype(1, Table, "table")

  if Index ~= nil then
    Base:checktype(2, Index, "any")
  end

  return next(Table, Index)
end)

Base:define("select", function(Index: number | string, ...: any): any
  Base:checktype(1, Index, "number", "string")

  return select(Index, ...)
end)

Base:define("type", function(Value: any): string
  Base:checktype(1, Value, "any")

  return type(Value)
end)

Base:define("tostring", function(Value: any): string
  Base:checktype(1, Value, "any")

  return tostring(Value)
end)

Base:define("tonumber", function(Value: any, BaseNum: number?): number?
  Base:checktype(1, Value, "any")

  if BaseNum ~= nil then
    Base:checktype(2, BaseNum, "number")
  end

  return tonumber(Value, BaseNum)
end)

Base:define("assert", function(Value: any, Message: string?): any
  Base:checktype(1, Value, "any")

  if Message ~= nil then
    Base:checktype(2, Message, "string")
  end

  return assert(Value, Message)
end)

Base:define("pcall", function(Func: (...any) -> any, ...: any): (boolean, ...any)
  Base:checktype(1, Func, "function")
  
  local Results: table = { pcall(Func, ...) }
  local Error: string = Results[2]
  
  if not Results[1] and type(Error) == "string" then
    local Message = Error:match("^.*:%d+:%s*(.*)$") or Error
    Message = Message:match("^%s*(.-)%s*$")
    
    --print("[VM - System ]: Bypassing (Prometheus / Forks) line check")
    
    return false, Message
  end

  return table.unpack(Results, 1, #Results)
end)

Base:define("xpcall", function(Func: (...any) -> any, ErrHandler: (any) -> any, ...: any): (boolean, ...any)
  Base:checktype(1, Func, "function")
  Base:checktype(2, ErrHandler, "function")

  local function InternalHandler(Error: any)
    if type(Error) == "string" then
      local Message = Error:match("^.*:%d+:%s*(.*)$") or Error
      Message = Message:match("^%s*(.-)%s*$")
      
      return ErrHandler(Message)
    end
    
    return ErrHandler(Error)
  end

  return xpcall(Func, InternalHandler, ...)
end)

Base:define("rawget", function(Table: table, Key: any): any
  Base:checktype(1, Table, "table")
  Base:checktype(2, Key, "any")

  return rawget(Table, Key)
end)

Base:define("rawset", function(Table: table, Key: any, Value: any): table
  Base:checktype(1, Table, "table")
  Base:checktype(2, Key, "any")
  Base:checktype(3, Value, "any")

  return rawset(Table, Key, Value)
end)

Base:define("rawequal", function(A: any, B: any): boolean
  Base:checktype(1, A, "any")
  Base:checktype(2, B, "any")

  return rawequal(A, B)
end)

Base:define("rawlen", function(Value: table | string): number
  Base:checktype(1, Value, "table", "string")

  return rawlen(Value)
end)

Base:define("newproxy", function(Metatable: boolean?): userdata
  if IsTrueProxy ~= nil then
    Base:checktype(1, Metatable, "boolean")
  end
  
  local Proxy: table = newproxy(Metatable)
  if Metatable then
    Internal.Metatables[Proxy] = getmetatable(Proxy)
  end
  
  return Proxy
end)

Base:define("getmetatable", function(Table: table): table?
  Base:checktype(1, Table, "table", "userdata", "string")

  return getmetatable(Table)
end)

Base:define("setmetatable", function(Table: table, Metatable: table?): table
  Base:checktype(1, Table, "table")

  if Metatable ~= nil then
    Base:checktype(2, Metatable, "table")
  end
  
  Internal.Metatables[Table] = Metatable

  return setmetatable(Table, Metatable)
end)

Base:define("getfenv", function(Target: any?): table
  Base:checktype(1, Target, "function", "number", "nil")
  local IsA: table = typeof(Target)
  
  local Out: table = { script = "Script" }
  local Properties: table = { __index = {} }
  
  if Target == 0 then
    
  elseif IsA == "number" then
    if Target <= 0 or Target > #CallStack.Stack then 
      error("Invalid stack level", 2) 
    end
    
  elseif IsA == "function" then
    
  elseif IsA == "nil" then
    
  end
  
  local Environment: table = setmetatable(Out, Properties)
  Internal.Metatables[Environment] = Properties
  
  return Environment :: table
end)

Base:define("setfenv", function(Target: any, Env: table): table
  Base:checktype(1, Target, "function", "number")
  Base:checktype(2, Env, "table")
  local IsA: table = typeof(Target)
  
  if Target == 0 then
    local Frame: table = CallStack.Stack[#CallStack.Stack]
    local Object: any? = Frame and Frame.Object
    
    if Object and Private.Isclosure(Object) then
      return setfenv(Object, Env)
    end
  elseif IsA == "number" then
    if Target <= 0 or Target > #CallStack.Stack then 
      error("Invalid stack level", 2) 
    end
    
    local Frame: table = CallStack.Stack[Target]
    local Object: any? = Frame and Frame.Object
    
    if Object and Private.Islclosure(Object) then
      return setfenv(Object, Env)
    end
  elseif IsA == "function" then
    if Private.Islclosure(Target) then
      return setfenv(Target, Env)
    end
  end
  
  error("cannot change environment of given object", 2)
end)

Base:define("gcinfo", function(): number
  return gcinfo()
end)

Base:define("collectgarbage", function(Mode: string): number
  Base:checktype(1, Mode, "string")
  assert(Mode == "count", "Invalid mode to 'collectgarbage'")
  
  return gcinfo()
end)

Base:define("unpack", function(Table: table, Start: number?, End: number?): ...any
  Base:checktype(1, Table, "table")

  if Start ~= nil then
    Base:checktype(2, Start, "number")
  end

  if End ~= nil then
    Base:checktype(3, End, "number")
  end

  return unpack(Table, Start, End)
end)

Base:define("_G", {})

Base:define("_VERSION", "Luau")

return Base:export() :: table