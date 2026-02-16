local Roblox: table = require("@lune/roblox")
local Manager: table = require("@env/manager")
local TweenInfo: table = Manager.create()

local Enum: table = Roblox.Enum

TweenInfo:define("new", function(Time: number?, EasingStyle: enum?, EasingDirection: enum?, RepeatCount: number?, Reverse: boolean?, DelayTime: number?)
  Time = Time or 1
  TweenInfo:checktype(1, Time, "number")
  
  EasingStyle = EasingStyle or Enum.EasingStyle.Quad
  TweenInfo:checktype(2, EasingStyle, "EnumItem")
  
  EasingDirection = EasingDirection or Enum.EasingDirection.Out
  TweenInfo:checktype(3, EasingDirection, "EnumItem")
  
  RepeatCount = RepeatCount or 0
  TweenInfo:checktype(4, RepeatCount, "number")
  
  Reverse = Reverse or false
  TweenInfo:checktype(5, Reverse, "boolean")
  
  DelayTime = DelayTime or 0
  TweenInfo:checktype(6, DelayTime, "number")
  
  local Proxy: table = newproxy(true)
  local Properties: table = getmetatable(Proxy)
  
  Properties.__index = {
    Time = Time,
    EasingStyle = EasingStyle,
    EasingDirection = EasingDirection,
    RepeatCount = RepeatCount,
    Reverse = Reverse,
    DelayTime = DelayTime
  }
  
  return Proxy :: userdata
end)

return TweenInfo:export()