local Task: table = require("@lune/task")
local Version: string = require("@cache/studioversion")

local Internal: table = require("@env/internal")
local Content: table = require("@datatype/content")
local Instance: table = require("@datatype/instance")
local SharedTable: table = require("@datatype/sharedtable")
local Random: table = require("@datatype/random")
local TweenInfo: table = require("@datatype/tweeninfo")

local Bindings: table = require("@roblox/binder")
local Default: table = require("@roblox/default")
local Manager: table = require("@env/manager")
local Roblox: table = Manager.create()
local API: table = Bindings.Roblox

local DataModel: userdata = API.Instance.new("DataModel")
Internal.DataModel = DataModel
Internal.Roblox = API

local Protected: Instance = API.Instance.new("Folder")
Protected.Parent = DataModel:GetService("CoreGui")
Protected.Name = "Hidden"

--for ClassName, Defaults in Default do
  for MemberName, Value in Default.DataModel do --ClassTable
    DataModel[MemberName] = Value
  end
--end

Roblox:mount("Axes", API.Axes)
Roblox:mount("BrickColor", API.BrickColor)
Roblox:mount("CFrame", API.CFrame)
Roblox:mount("Color3", API.Color3)
Roblox:mount("ColorSequence", API.ColorSequence)
Roblox:mount("ColorSequenceKeypoint", API.ColorSequenceKeypoint)
Roblox:mount("Enum", API.Enum)
Roblox:mount("Faces", API.Faces)
Roblox:mount("Font", API.Font)
Roblox:mount("Instance", Instance)
Roblox:mount("NumberRange", API.NumberRange)
Roblox:mount("NumberSequence", API.NumberSequence)
Roblox:mount("NumberSequenceKeypoint", API.NumberSequenceKeypoint)
Roblox:mount("PhysicalProperties", API.PhysicalProperties)
Roblox:mount("Ray", API.Ray)
Roblox:mount("Rect", API.Rect)
Roblox:mount("Region3", API.Region3)
Roblox:mount("Region3int16", API.Region3int16)
Roblox:mount("UDim", API.UDim)
Roblox:mount("UDim2", API.UDim2)
Roblox:mount("Vector2", API.Vector2)
Roblox:mount("Vector2int16", API.Vector2int16)
Roblox:mount("Vector3", API.Vector3)
Roblox:mount("Vector3int16", API.Vector3int16)

Roblox:mount("TweenInfo", TweenInfo)
Roblox:mount("DateTime", {})
Roblox:mount("Path2D", {})
Roblox:mount("Path2DControlPoint", {})
Roblox:mount("PathWaypoint", {})
Roblox:mount("RotationCurveKey", {})
Roblox:mount("FloatCurveKey", {})
Roblox:mount("RaycastParams", {})
Roblox:mount("OverlapParams", {})
Roblox:mount("CatalogSearchParams", {})
Roblox:mount("Random", Random)
Roblox:mount("Actor", {})
Roblox:mount("SharedTable", SharedTable)

Roblox:mount("Content", Content) 

Roblox:mount("RBXScriptSignal", {})
Roblox:mount("RBXScriptConnection", {})
Roblox:mount("RaycastResult", {})
Roblox:mount("DockWidgetPluginGuiInfo", {})
Roblox:mount("ValueCurveKey", {})
Roblox:mount("Secret", {})

Roblox:mount("game", DataModel)
Roblox:mount("shared", setmetatable({}, { __metatable = "The metatable is locked", }))
Roblox:mount("script", {})
Roblox:mount("workspace", DataModel:GetService("Workspace"))

Roblox:define("delay", function(Delay: number, Callback: any): nil
  Roblox:checktype(1, Delay, "number")
  Roblox:checktype(2, Callback, "function")
  
  return Task.delay(Delay, Callback)
end)

Roblox:define("DebuggerManager", function(): userdata
  return newproxy() :: userdata
end)

Roblox:define("elapsedTime", function(): userdata
  local DayStart = os.time(os.date("*t"))
  
  return os.time() - DayStart
end)

Roblox:define("PluginManager", function(): userdata
  return newproxy() :: userdata
end)

Roblox:define("printidentity", function(): nil
  
end)

Roblox:define("settings", function(): userdata
  return newproxy() :: userdata
end)

Roblox:define("spawn", function(Callback: any): nil
  Roblox:checktype(1, Callback, "function")
  
  return Task.spawn(Callback)
end)

Roblox:define("stats", function(): userdata
  return newproxy() :: userdata
end)

Roblox:define("tick", function(): number
  return os.clock() :: number
end)

Roblox:define("time", function(): number
  return os.time() :: number
end)

Roblox:define("typeof", function(Value: any): string
  Roblox:checktype(1, Value, "any")

  return typeof(Value) :: string
end)

Roblox:define("UserSettings", function(): userdata
  return newproxy() :: userdata
end)

Roblox:define("version", function(): string
  return Version :: string
end)

Roblox:define("wait", function(Delay: number)
  Roblox:checktype(1, Delay, "number")
  
  return Task.wait(Delay)
end)

Roblox:define("warn", function(...: any?): nil
  print("[WARN]:", ...)
end)

Roblox:define("ypcall", function(Func: (...any) -> any, ...: any): (boolean, ...any)
  Roblox:checktype(1, Func, "function")

  return pcall(Func, ...)
end)

return Roblox:export() :: table