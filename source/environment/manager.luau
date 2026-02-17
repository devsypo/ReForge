local Process: table = require("@lune/process")
local Internal: table = require("@env/internal")

export type ExploitFunction = (...any) -> any

export type PublicNamespace = {
  define: (self: PublicNamespace, ...any) -> any,
  rawdefine: (self: PublicNamespace, Name: string, Object: any) -> any,
  namespace: (
    self: PublicNamespace,
    Name: string,
    Predef: { [string]: any } | nil
  ) -> PublicNamespace,
  extend: (self: PublicNamespace, Other: any) -> any,
  export: (self: PublicNamespace) -> { [string]: any },
  checktype: (self: PublicNamespace, Index: number, Value: any, Expected: string) -> nil,
  getfunc: (self: PublicNamespace) -> string
}

export type ManagerModule = {
  create: (Path: string?) -> PublicNamespace
}

local assert = assert
local type = type
local unpack = unpack
local ipairs = ipairs
local next = next
local string_format = string.format
local table_concat = table.concat

local function createManager(Path: string?): PublicNamespace
  local CurrentFunc: string? = nil
  local Objects: { [string]: any } = {}
  local Public = {} :: any
  Path = Path or ""

  function Public:define(...: any): any
    local Args = { ... }
    local Object = Args[#Args]
    
    local Names = {}
    for i = 1, #Args - 1 do
      assert(type(Args[i]) == "string")
      Names[#Names + 1] = Args[i]
    end
    
    for _, Name in ipairs(Names) do
      Objects[Name] = Object
    end
    
    return Object
  end

  function Public:namespace(Name: string, Predef: { [string]: any }?): PublicNamespace
    assert(type(Name) == "string")
    
    local ChildPath = Path ~= "" and (Path .. "." .. Name) or Name
    local Child = createManager(ChildPath)
    
    if Predef then
      for K, V in Predef do
        Child:define(K, V)
      end
    end
    
    Objects[Name] = Child
    return Child
  end
  
  function Public:extend(Other: any): table
    assert(type(Other) == "table")
    
    if type(Other.export) == "function" then
      Other = Other:export()
    end
    
    for Key, Value in Other do
      Objects[Key] = Value
    end
    
    return Other
  end

  function Public:export(): { [string]: any }
    local Out = {}
    
    for Key, Value in Objects do
      if type(Value) == "table" and Value.export then
        Out[Key] = Value:export()
        
      elseif type(Value) == "function" then
        local FullPath: string = Path ~= "" and (Path .. "." .. Key) or Key
        
        local Call: any = setfenv(function(...)
          local Prev = CurrentFunc
          CurrentFunc = FullPath
          
          local Result = { Value(...) }
          
          CurrentFunc = Prev
          return unpack(Result)
        end, {})
        
        Internal.FuncNames[Call] = Key
        Out[Key] = Call
      else
        Out[Key] = Value
      end
    end
    
    return Out
  end

  function Public:mount(Name: string, Value: any)
    assert(type(Name) == "string")
    Objects[Name] = Value
    return Value
  end

  function Public:getfunc(): string
    return CurrentFunc or Path or "<anonymous>"
  end

  function Public:checktype(Index: number, Value: any, Expected: string, ...: string): nil
    local FuncPath: string = CurrentFunc or "<anonymous>"
    local IsA: string = typeof(Value)
    
    if Expected == "any" then
      return nil
    end
    
    local ExpectedTypes: table = { Expected, ... }
    
    for _, TypeName in ipairs(ExpectedTypes) do
      if IsA == TypeName then
        return nil
      end
    end
    
    local TypeMessage: string = "invalid argument #%d to '%s' (%s expected, got %s)"
    local MismatchType: string = TypeMessage:format(Index, FuncPath, table_concat(ExpectedTypes, " or "), IsA)
    
    error(MismatchType)
  end

  return Public
end

return { create = createManager } :: ManagerModule