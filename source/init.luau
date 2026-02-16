local Instrumenter: table = require("@dependency/instrumenter")
local FS: table = require("@lune/fs")
local Luau: table = require("@lune/luau")
local Process: table = require("@lune/process")
local Stdio: table = require("@lune/stdio")
local Internal: table = require("@env/internal")
local CreateEnvironment: any = require("@env")
local Arguments: table = Process.args

local HookOp: boolean = true
local Base: boolean = true
local Exploit: boolean = true
local Roblox: boolean = true
local Missingprint: boolean = true

for _, Arg in Arguments do
  if Arg == "--no-hookop" or Arg == "--no-h"  then
    HookOp = false
    print("[REFORGED]: HookOp is crucial for ReForge. Some functions will straight up error!")
  elseif Arg == "--no-exploit" or Arg == "--no-e" then
    Exploit = false
  elseif Arg == "--no-luau" or Arg == "--no-l" then
    Base = false
  elseif Arg == "--no-roblox" or Arg == "--no-r" then
    Roblox = false
  elseif Arg == "--no-missingprint" or Arg == "--no-m" then
    Missingprint = false
  end
end

local function Main(): any
  local Source: string = FS.readFile("input.luau")
  local Configuration: table = {
    HookOp = HookOp,
    Base = Base,
    Exploit = Exploit,
    Roblox = Roblox,
    Missingprint = Missingprint
  }
  
  local Environment: table = CreateEnvironment(Configuration)
  if HookOp then Source = Instrumenter.go(Source) end
  
  local BC: string = Luau.compile(Source, {
    optimizationLevel = 2,
    debugLevel = 0,
    debugName = "__USER_CODE"
  })
  
  local FN: any = Luau.load(Source)
  
  Internal.Environment = Environment
  
  Environment.getgenv = function()
    return Environment
  end

  Environment.getfenv = function()
    return Environment
  end
  
  _ENV = Environment
  
  setfenv(FN, Environment)()
end

return Main()