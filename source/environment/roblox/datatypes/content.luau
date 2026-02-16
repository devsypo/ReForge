local Roblox: table = require("@lune/roblox")
local Manager: table = require("@env/manager")
local Content: table = Manager.create()

Content:mount("fromObject", Roblox.Content.fromObject)
Content:mount("fromUri", Roblox.Content.fromUri)
Content:mount("fromAssetId", function() end)
Content:mount("none", Roblox.Content.none)

return Content:export()