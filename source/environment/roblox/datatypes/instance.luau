local Internal: table = require("@env/internal")
local Manager: table = require("@env/manager")
local Instance: table = Manager.create()

local API: table = Internal.Roblox
local CachedInstances: table = Internal.CachedInstances

Instance:define("new", function(ClassName: string, Parent: any)
  Instance:checktype(1, ClassName, "string")
  if Parent then
    Instance:checktype(2, Parent, "Instance")
  end
  
  local Object: any = Internal.Roblox.Instance.new(ClassName)
  if Parent then
    Object.Parent = Parent
  end
  
  CachedInstances[Object] = true
  
  return Object
end)

return Instance:export()