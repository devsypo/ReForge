local Roblox: table = require("@lune/roblox")
local Manager: table = require("@env/manager")
local Random: table = Manager.create()
local Methods: table = {}
local RNGStates: table = {}

local MIN_SEED = -9007199254740991
local MAX_SEED =  9007199254740991

local function ClampSeed(Seed: number): number
  local Seed = math.floor(Seed)
  
  if Seed < MIN_SEED then return MIN_SEED end
  if Seed > MAX_SEED then return MAX_SEED end
  
  return Seed
end

local function CreateRNG(Seed: number)
  local co = coroutine.wrap(function()
    math.randomseed(Seed)
    while true do
      coroutine.yield(math.random())
    end
  end)
  
  return co
end

Random:define("new", function(Seed: number?): userdata
  Seed = (Seed and ClampSeed(Seed)) or 0
  Random:checktype(1, Seed, "number")

  local Proxy: userdata = newproxy(true)
  local Properties: table = getmetatable(Proxy)

  RNGStates[Proxy] = {
    Seed = Seed,
    RNG = CreateRNG(Seed)
  }

  Properties.__index = function(_, Key)
    return Methods[Key]
  end

  Properties.__newindex = function()
    error("Table is frozen", 2)
  end

  Properties.__type = function()
    return "Random"
  end

  return Proxy :: userdata
end)

Methods.NextInteger = function(Self: userdata, Min: number, Max: number): number
  Random:checktype(1, Self, "userdata")
  Random:checktype(2, Min, "number")
  Random:checktype(3, Max, "number")
  
  if Min > Max then 
    error("Min must be <= Max", 2) 
  end

  local State: table = RNGStates[Self]
  local Rad: number = State.RNG()
  
  return math.floor(Rad * (Max - Min + 1) + Min) :: number
end

Methods.NextNumber = function(Self: userdata, Min: number?, Max: number?): number
  Random:checktype(1, Self, "userdata")

  local State: table = RNGStates[Self]
  local Rad: number = State.RNG()

  if Min == nil and Max == nil then
    return Rad :: number
  end

  Random:checktype(2, Min, "number")
  Random:checktype(3, Max, "number")
  
  if Min > Max then 
    error("Min must be <= Max", 2) 
  end

  return Rad * (Max - Min) + Min :: number
end

Methods.NextUnitVector = function(Self: userdata)
  Random:checktype(1, Self, "userdata")
  local State: number = RNGStates[Self]

  local Theta: number = 2 * math.pi * State.RNG()
  
  local Phi = math.acos(2 * State.RNG() - 1)
  
  local X: number = math.sin(Phi) * math.cos(Theta)
  local Y: number = math.sin(Phi) * math.sin(Theta)
  local Z: number = math.cos(Phi)
  
  return Roblox.Vector3.new(X, Y, Z) :: Vector3
end

Methods.Shuffle = function(Self: userdata, Table: table)
  Random:checktype(1, Self, "userdata")
  Random:checktype(2, Table, "table")

  local State: table = RNGStates[Self]
  local Size: number = #Table
  
  for i = Size, 2, -1 do
    local Integer: table = Random.NextInteger(Self, 1, i)
    Table[i], Table[Integer] = Table[Integer], Table[i]
  end
end

Methods.Clone = function(Self: userdata): userdata
  Random:checktype(1, Self, "userdata")

  local OldState: userdata = RNGStates[Self]
  if not OldState then
    error("Invalid Random object", 2)
  end

  local Proxy: userdata = newproxy(true)
  local Properties: table = getmetatable(Proxy)
  
  local newCo: coroutine = coroutine.wrap(function()
    math.randomseed(OldState.Seed)
    while true do
      coroutine.yield(math.random())
    end
  end)
  
  local Count: number = OldState.Count or 0
  
  for _ = 1, Count do
    newCo()
  end

  RNGStates[Proxy] = {
    Seed = OldState.Seed,
    RNG = newCo,
    Count = Count
  }

  Properties.__index = function(_, Key)
    return Methods[Key]
  end

  Properties.__newindex = function()
    error("Table is frozen", 2)
  end

  Properties.__type = function()
    return "Random"
  end

  return Proxy :: Random
end

return Random:export() :: table