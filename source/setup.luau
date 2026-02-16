local FS: table = require("@lune/fs")
local Network: table = require("@lune/net")
local Process: table = require("@lune/process")
local Serde: table = require("@lune/serde")
local Arguments: table = Process.args

local function Serialize(Value): string
  local Type: string = type(Value)

  if Type == "number" or Type == "boolean" then
    return tostring(Value)
  end

  if Type == "string" then
    return string.format("%q", Value)
  end

  if Type == "table" then
    local Out = table.create(#Value * 5 + 2)
    local i = 1
    
    Out[i] = "{"
    i += 1
    
    for _, v in ipairs(Value) do
      Out[i] = Serialize(v)
      Out[i + 1] = ","
      i += 2
    end
    
    for k, v in pairs(Value) do
      if type(k) ~= "number" then
        Out[i] = "["
        Out[i + 1] = Serialize(k)
        Out[i + 2] = "] = "
        Out[i + 3] = Serialize(v)
        Out[i + 4] = ","
        i += 5
      end
    end
    
    Out[i] = "}"
    return table.concat(Out)
  end

  return "nil"
end

-- Fetch version from repo
local VersionData: string = Network.request({
  url = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/version.txt",
  method = "GET"
}).body

local RepoVersion: string = VersionData:gsub("%s+", "")

-- Save version to cache file
local VersionFile: string = "source/.cache/studioversion.luau"
FS.writeFile(VersionFile, ("return %q"):format(RepoVersion))

local HashFile: string = "source/.cache/studioversionhash.luau"
local VersionHash: string = Serde.hash("sha256", RepoVersion)
FS.writeFile(HashFile, ("return %q"):format(VersionHash))

print("[SETUP]: Repo Version:", RepoVersion)

local Data: string = Network.request({
  url = "https://api.github.com/repos/MaximumADHD/Roblox-Client-Tracker/contents/Full-API-Dump.json?ref=roblox",
  method = "GET"
}).body

local CurrentHash: string = Serde.decode("json", Data).sha
local CachedHash: string?

if FS.isFile("source/.cache/rblxapidumphash.luau") then
  CachedHash = require("@cache/rblxapidumphash")
else
  local Hash: string = "return '%s' -- This file is used for hash checking!"
  FS.writeFile("source/.cache/rblxapidumphash.luau", string.format(Hash, CurrentHash))
end

if CachedHash ~= CurrentHash or Arguments[1] == "--force" or not FS.isFile("source/.cache/rblxapidump.luau") then
  local Start: string = os.time()
  
  print("[SETUP]: Redownloading RBLX API Dump..")
  local Data: string = Network.request({
    url = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Full-API-Dump.json",
    method = "GET"
  }).body

  print("[SETUP]: Finished downloading! serializing the dump..")

  local API: table = Serde.decode("json", Data)
  
  FS.writeFile("source/.cache/rblxapidump.luau", "return " .. Serialize(API))
  
  local IsValid: boolean = pcall(require, "@cache/rblxapidump")
  
  if IsValid then
    return print(string.format("[SETUP]: Finished serializing! took %d seconds", os.time() - Start))
  else
    return print("[SETUP]: Output of serializer is invalid syntax!!")
  end
end

print("[INTERNAL]: Setup is already done! skipping..")