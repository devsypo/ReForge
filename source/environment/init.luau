local Base: table = require("@base")
local Exploit: table = require("@exploit")
local Roblox: table = require("@roblox")
local Instrument: table = require("@instr")
local Manager: table = require("@env/manager")

local function Main(Configuration: table)
  local Public: table = Manager.create()
  
  if Configuration.HookOp then
    Public:extend(Instrument)
  end
  
  if Configuration.Base then
    Public:extend(Base)
  end
  
  if Configuration.Exploit then
    Public:extend(Exploit)
  end
  
  if Configuration.Roblox then
    Public:extend(Roblox)
  end
  
  local Missing: table = {}
  local Properties: table = {
    __index = function(_, Key)
      if not Missing[Key] and Configuration.Missingprint then
        print("[INTERNAL]: Missing variable '" .. Key .. "'")
        Missing[Key] = true
      end
    end
  }

  return setmetatable(Public:export(), Properties) :: table
end

return Main :: any