local FS: table = require("@lune/fs")
local Luau: table = require("@lune/luau")
local Internal: table = require("@env/internal")
local Bindings: table = {}
local BindingQueue: table = {}

local Environment: table = table.clone(getfenv(0))
Environment.Shared = require("@env/shared")

local BindingsPath: string = "source/environment/roblox/bindings/"
local ERR_BINDINGS_NOT_DIRECTORY: string = "Binder.luau: expected bindings folder to contain only directories, but found file: '%s'"
local ERR_BINDING_MISSING_INIT: string = "Binder.luau: failed to bind '%s' (missing init.luau)"
local ERR_BINDING_NOT_TABLE: string = "Binder.luau: binding '%s' must return a table"
local ERR_BINDING_REQUIRE_ERROR: string = "Binder.luau: failed to load binding '%s', syntax issue?"

local ERR_MEMBER_NOT_TABLE: string = "Binder.luau: binding '%s.%s' must be a table"
local ERR_MISSING_KIND: string = "Binder.luau: binding '%s.%s' missing Kind"
local ERR_UNKNOWN_KIND: string = "Binder.luau: unknown Kind '%s' in '%s.%s'"

local ERR_FUNCTION_HANDLER: string = "Binder.luau: function '%s.%s' missing Handler"
local ERR_SECURITY_FUNCTION: string = "Binder.luau: function '%s.%s' Security must be a string"

local ERR_PROPERTY_GET: string = "Binder.luau: property '%s.%s'.Get must be a function"
local ERR_PROPERTY_SET: string = "Binder.luau: property '%s.%s'.Set must be a function"
local ERR_SECURITY_PROPERTY: string = "Binder.luau: property '%s.%s' Security must be a table"
local ERR_SECURITY_PROPERTY_GET: string = "Binder.luau: property '%s.%s' Security.Get must be a string"
local ERR_SECURITY_PROPERTY_SET: string = "Binder.luau: property '%s.%s' Security.Set must be a string"

local ERR_EVENT_HANDLER: string = "Binder.luau: event '%s.%s' missing Handler"
local ERR_EVENT_HANDLER_TABLE: string = "Binder.luau: event '%s.%s'.Handler must be a table"
local ERR_EVENT_CONNECT: string = "Binder.luau: event '%s.%s'.Handler.Connect must be a function"
local ERR_SECURITY_EVENT: string = "Binder.luau: event '%s.%s' Security must be a string"

local ERR_SECURITY_NIL: string = "[BINDER]: Security field is nil in '%s' for '%s', defaulting to 'None'"
local ERR_SECURITY_PROPERTY_NIL: string = "[BINDER]: Security field is nil in '%s' for '%s' on '%s', defaulting to 'None'"
local ERR_INSUFFICIENT_IDENTITY: string = "The current thread cannot call '%s' (lacking capability %s)"

local function Warn(...)
  if Internal.DebugMode then
    warn(...)
  end
end

local function Pull(Path): table
  local Source: string = FS.readFile(Path)
  local Bytecode: string = Luau.compile(Source, {
    optimizationLevel = 2
  })
  
  local FN: any = Luau.load(Bytecode)
  setfenv(FN, Environment)
  
  return FN()
end

local function ValidateBinding(Name: string, Binding: any)
  assert(type(Binding) == "table", string.format(ERR_BINDING_NOT_TABLE, Name))

  for MemberName, Member in Binding do
    assert(type(Member) == "table", string.format(ERR_MEMBER_NOT_TABLE, Name, MemberName))
    local Kind: string = Member.Kind
    
    assert(type(Kind) == "string", string.format(ERR_MISSING_KIND, Name, MemberName))
    
    if Kind == "Method" then
      assert(type(Member.Handler) == "function", string.format(ERR_FUNCTION_HANDLER, Name, MemberName))
    elseif Kind == "Property" then
      if Member.Security then
        assert(type(Member.Security) == "table", string.format(ERR_SECURITY_PROPERTY, Name, MemberName))
      else
        Member.Security = {}
      end
      
      if Member.Get == nil then
        Member.Get = function() end
      else
        assert(type(Member.Get) == "function", string.format(ERR_PROPERTY_GET, Name, MemberName))
      end
      
      if Member.Set == nil then
        Member.Set = function() end
      else
        assert(type(Member.Set) == "function", string.format(ERR_PROPERTY_SET, Name, MemberName))
      end
    elseif Kind == "Event" then
      Warn("No support for events yet!")
    else
      error(string.format(ERR_UNKNOWN_KIND, Kind, Name, MemberName))
    end
  end
  
  return Binding :: table
end

for _, DirectoryName in FS.readDir(BindingsPath) do
  assert(FS.isDir(BindingsPath .. DirectoryName), string.format(ERR_BINDINGS_NOT_DIRECTORY, DirectoryName))

  local InitPath: string = BindingsPath .. DirectoryName .. "/init.luau"
  assert(FS.isFile(InitPath), string.format(ERR_BINDING_MISSING_INIT, DirectoryName))

  table.insert(BindingQueue, { InitPath, DirectoryName })
end

for _, Binding in BindingQueue do
  local Path: string, Name: string = Binding[1], Binding[2]

  local Status: boolean, Module: table? = pcall(Pull, Path)
  if not Status then
    Warn(tostring(Module))
  end
  
  assert(Status, string.format(ERR_BINDING_REQUIRE_ERROR, Name))
  Bindings[Name] = ValidateBinding(Name, Module)
end

return Bindings :: table