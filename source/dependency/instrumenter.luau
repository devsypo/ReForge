local FileSystem: table = require("@lune/fs")
local Process: table = require("@lune/process")
local Random: table = require("@dependency/random")
local Library: table = {}

local Result = Process.exec("lute", { "--version" })
assert(Result.ok, "Error occured whilst checking Lute. Did you install lute? (== 2025.1115)")
  
local Version = Result.stdout:gsub("%s+$", ""):sub(-4)

if Process.os == "linux" or Process.os == "macos" then
  assert(Version == "1115", "Version mismatched expected Lute version 2025.1115 but got 2025." .. Version)
else
  warn("[Lute]: disabling version check due to operating issue! make sure lute is at 2025.1115")
end

function Library.go(Source: string): string
  local InputPath = Random:filename(16, ".luau", "./source/temporary/")
  local OutputPath = Random:filename(16, ".luau", "./source/temporary/")
  
  FileSystem.writeFile(InputPath, Source)
  
  local Result = Process.exec("lute", { "run", "./source/dependency/hookop", "--with-luaurc" }, { 
    env = { InputPath = InputPath, OutputPath = OutputPath },
    cwd = "./"
  })

  FileSystem.removeFile(InputPath)
  
  local Out; if Result.ok then
    assert(FileSystem.isFile(OutputPath), "[HOOKOP]: Designated output path is not found!")
    
    Out = FileSystem.readFile(OutputPath)
    FileSystem.removeFile(OutputPath)
  end
  
  print(Result.stdout, Result.stderr)
  assert(Result.ok, "[HOOKOP]: Error occured whilst patching script!")
  
  return Out
end

return table.freeze(Library)