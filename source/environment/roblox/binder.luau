local FS: table = require("@lune/fs")
local Luau: table = require("@lune/luau")
local Roblox: table = require("@lune/roblox")
local Rbxscriptsignal: table = require("@datatype/rbxscriptsignal")
local API: table = require("@cache/rblxapidump")
local Internal: table = require("@env/internal")
local UserBindings: table = require("@roblox/userbindings")
local Securities: table = {}
local Bindings: table = {}

local IDAC: table = {
	[0] = {"None"},
	[1] = {"PluginSecurity", "None", "LocalUserSecurity"},
	[2] = {"None"},
	[3] = {"PluginSecurity", "None", "LocalUserSecurity", "RobloxScriptSecurity"},
	[4] = {"PluginSecurity", "None", "LocalUserSecurity"},
	[5] = {"PluginSecurity", "None"},
	[6] = {"PluginSecurity", "None", "LocalUserSecurity", "RobloxScriptSecurity"},
	[7] = {"PluginSecurity", "None", "LocalUserSecurity", "WritePlayerSecurity", "RobloxScriptSecurity", "RobloxSecurity", "NotAccessable"},
	[8] = {"PluginSecurity", "None", "LocalUserSecurity", "WritePlayerSecurity", "RobloxScriptSecurity", "RobloxSecurity", "NotAccessable"},
	[9] = {"WritePlayerSecurity", "None", "RobloxScriptSecurity"},
}

local function Warn(...)
  if Internal.DebugMode then
    warn(...)
  end
end

local function canAccess(Security: string, Identity: number): boolean
	local Capabilities: table = IDAC[Identity or Internal.ThreadIdentities.Default]

	for _, Capability in ipairs(Capabilities) do
		if Capability == Security then
			return true
		end
	end

	return false :: boolean
end

--[[
local BindingsPath: string = "source/environment/roblox/bindings/"
local ERR_BINDINGS_NOT_DIRECTORY: string = "Binder.luau: expected bindings folder to contain only directories, but found file: '%s'"
local ERR_BINDING_MISSING_INIT: string = "Binder.luau: failed to bind '%s' (missing init.luau)"
local ERR_BINDING_NOT_TABLE: string = "Binder.luau: binding '%s' must return a table"
local ERR_BINDING_REQUIRE_ERROR: string = "Binder.luau: failed to load binding '%s', syntax issue?"
local ERR_MEMBER_NOT_TABLE: string = "Binder.luau: binding '%s.%s' must be a table"
local ERR_MISSING_KIND: string = "Binder.luau: binding '%s.%s' missing Kind"
local ERR_FUNCTION_HANDLER: string = "Binder.luau: function '%s.%s' missing Handler"
local ERR_PROPERTY_GET: string = "Binder.luau: property '%s.%s'.Get must be a function"
local ERR_PROPERTY_SET: string = "Binder.luau: property '%s.%s'.Set must be a function"
local ERR_UNKNOWN_KIND: string = "Binder.luau: unknown Kind '%s' in '%s.%s'"
local ERR_SECURITY_FUNCTION: string = "Binder.luau: function '%s.%s' Security must be a string"
local ERR_SECURITY_PROPERTY: string = "Binder.luau: property '%s.%s' Security must be a table"
local ERR_SECURITY_PROPERTY_GET: string = "Binder.luau: property '%s.%s' Security.Get must be a string"
local ERR_SECURITY_PROPERTY_SET: string = "Binder.luau: property '%s.%s' Security.Set must be a string"
local ERR_SECURITY_NIL: string = "[BINDER]: Security field is nil in '%s' for '%s', defaulting to 'None'"
local ERR_SECURITY_PROPERTY_NIL: string = "[BINDER]: Security field is nil in '%s' for '%s' on '%s', defaulting to 'None'"
local ERR_EVENT_HANDLER: string = "Binder.luau: event '%s.%s' missing Handler"
local ERR_EVENT_HANDLER_TABLE: string = "Binder.luau: event '%s.%s'.Handler must be a table"
local ERR_EVENT_CONNECT: string = "Binder.luau: event '%s.%s'.Handler.Connect must be a function"
local ERR_SECURITY_EVENT: string = "Binder.luau: event '%s.%s' Security must be a string"
local ERR_INSUFFICIENT_IDENTITY: string = "The current thread cannot call '%s' (lacking capability %s)"
]]

local ERR_SECURITY_FUNCTION: string = "Binder.luau: function '%s.%s' Security must be a string"
local ERR_SECURITY_PROPERTY_GET: string = "Binder.luau: property '%s.%s' Security.Get must be a string"
local ERR_SECURITY_PROPERTY_SET: string = "Binder.luau: property '%s.%s' Security.Set must be a string"
local ERR_SECURITY_NIL: string = "[BINDER]: Security field is nil in '%s' for '%s', defaulting to 'None'"
local ERR_SECURITY_PROPERTY_NIL: string = "[BINDER]: Security field is nil in '%s' for '%s' on '%s', defaulting to 'None'"
local ERR_INSUFFICIENT_IDENTITY: string = "The current thread cannot call '%s' (lacking capability %s)"

for _, Class: string in API.Classes do
  Securities[Class.Name] = {}
  for _, Member in Class.Members do
    Securities[Class.Name][Member.Name] = Member.Security
  end
end

for ClassName: string, Members: table in UserBindings do
  for MemberName: string, Property: table in Members do
    local Kind: string = Property.Kind
    
    if Kind == "Method" then
      local Security: string = "None"
      if Property.Security ~= nil then
        assert(type(Property.Security) == "string", string.format(ERR_SECURITY_FUNCTION, ClassName, MemberName))
        Security = Property.Security
      elseif Securities[ClassName][MemberName] then
        Security = Securities[ClassName][MemberName]
      else
        Warn(ERR_SECURITY_NIL:format(ClassName, MemberName))
      end
      
      Warn("User-defined binding", ClassName, MemberName, Security)
      
      Roblox.implementMethod(ClassName, MemberName, function(...)
        local ExecutingThread: thread = coroutine.running()
        assert(canAccess(Security, Internal.ThreadIdentities[ExecutingThread]), string.format(ERR_INSUFFICIENT_IDENTITY, MemberName, Security))
        
        return Property.Handler(...)
      end)
      
      continue
    end
    
    if Kind == "Property" then
      local Read: string = "None"
      local Write: string = "None"
      
      local ClassSecurity = Securities[ClassName]
      local MemberSecurity = ClassSecurity and ClassSecurity[MemberName]
      
      if Property.Security.Get ~= nil then
        assert(type(Property.Security.Get) == "string", ERR_SECURITY_PROPERTY_GET:format(ClassName, MemberName))
        Read = Property.Security.Get
      elseif MemberSecurity and MemberSecurity.Read then
        Read = MemberSecurity.Read
      else
        Warn(ERR_SECURITY_PROPERTY_NIL:format(ClassName, MemberName, "Get"))
      end
      
      if Property.Security.Set ~= nil then
        assert(type(Property.Security.Set) == "string", ERR_SECURITY_PROPERTY_SET:format(ClassName, MemberName))
        Write = Property.Security.Set
      elseif MemberSecurity and MemberSecurity.Write then
        Write = MemberSecurity.Write
      else
        Warn(ERR_SECURITY_PROPERTY_NIL:format(ClassName, MemberName, "Set"))
      end
      
      Warn("User-defined binding", ClassName, MemberName, Write, Read)
      
      local Get: any = function(...): any
        local ExecutingThread: thread = coroutine.running()
        assert(canAccess(Read, Internal.ThreadIdentities[ExecutingThread]), string.format(ERR_INSUFFICIENT_IDENTITY, MemberName, Read))
        
        return Property.Get(...)
      end
      
      local Set: any = function(...): any
        local ExecutingThread: thread = coroutine.running()
        assert(canAccess(Write, Internal.ThreadIdentities[ExecutingThread]), string.format(ERR_INSUFFICIENT_IDENTITY, MemberName, Write))
        
        return Property.Set(...)
      end
      
      Roblox.implementProperty(ClassName, MemberName, Get, Set)
      
      continue
    end
    
    if Kind == "Event" then
      --Roblox.implementProperty(ClassName, MemberName)
      
      continue
    end
  end
end

for _, Class: string in API.Classes do
  local ClassName: string = Class.Name
  local Binding = UserBindings[ClassName]
  
  for _, Member in Class.Members do
    local Type: string = Member.MemberType
    local Security: string = Member.Security
    if Binding and Binding[Member.Name] then
      continue
    end
    
    if Type == "Function" then
      Roblox.implementMethod(ClassName, Member.Name, function(...)
        local ExecutingThread: thread = coroutine.running()
        assert(canAccess(Security, Internal.ThreadIdentities[ExecutingThread]), string.format(ERR_INSUFFICIENT_IDENTITY, Member.Name, Security))
        
      end)
    elseif Type == "Property" then
      local Read: string = Security.Read or Security.Get
      local Write: string = Security.Write or Security.Set
      
      local Get: any = function(...)
        local ExecutingThread: thread = coroutine.running()
        assert(canAccess(Read, Internal.ThreadIdentities[ExecutingThread]), string.format(ERR_INSUFFICIENT_IDENTITY, Member.Name, Security))
        
      end
      
      local Set: any = function(...)
        local ExecutingThread: thread = coroutine.running()
        assert(canAccess(Write, Internal.ThreadIdentities[ExecutingThread]), string.format(ERR_INSUFFICIENT_IDENTITY, Member.Name, Security))
        
      end
      
      Roblox.implementProperty(ClassName, Member.Name, Get, Set)
    elseif Type == "Event" then
      local Signal: userdata = Rbxscriptsignal.Signal()
      
      local Get: any = function()
        local ExecutingThread: thread = coroutine.running()
        assert(canAccess(Security, Internal.ThreadIdentities[ExecutingThread]), string.format(ERR_INSUFFICIENT_IDENTITY, Member.Name, Security))
        
        return Signal
      end
      
      Roblox.implementProperty(ClassName, Member.Name, Get, function() end)
    end
  end
end

for _, Class: string in API.Classes do
  local Tags: table = Class.Tags or {}
  for _, Tag in Tags do
    if Tag == "Service" then
      pcall(Roblox.implementProperty, "DataModel", Class.Name, function(self)
        return self:GetService(Class.Name)
      end)
    end
  end
end

return { Roblox = Roblox }