local Regex: table = require("@lune/regex")
local Library: table = {}

local GeneralUrl: userdata = Regex.new([=[^[A-Za-z0-9._~:/?#\[\]@!$&'()*+,;=%-]+$]=])
local WebsocketUrl: userdata = Regex.new([=[^wss?://[A-Za-z0-9._~:/?#\[\]@!$&'()*+,;=%-]+$]=])

local BLOCKED_EXTENSIONS: { [string]: boolean } = {
	["exe"] = true,
	["scr"] = true,
	["bat"] = true,
	["com"] = true,
	["csh"] = true,
	["msi"] = true,
	["vb"] = true,
	["vbs"] = true,
	["vbe"] = true,
	["ws"] = true,
	["wsf"] = true,
	["wsh"] = true,
	["ps1"] = true,
	["psy"] = true,
}

local function isSafeSegment(Segment: string): boolean
	if Segment == "" then
		return false
	end

	if Segment == "." or Segment == ".." then
		return false
	end

	return not not Segment:match("^%.?[A-Za-z0-9_-][A-Za-z0-9_.-]*$")
end

local function getExtension(filename: string): string?
	local dot = filename:match("^.*()%.") -- get last dot position
	if not dot then
		return false
	end
	local ext = filename:sub(dot + 1)
	return ext:lower()
end

function Library.SanitizePath(Path: string, checkexc): string?
	local sanitized: string = Path:gsub("%s+", "")

	if sanitized:sub(1, 1) == "/" then
		return false
	end

	if sanitized:sub(-1) == "/" then
		return false
	end

	if sanitized:find("..", 1, true) then
		return false
	end

	local lastSegment: string?
	for segment in sanitized:gmatch("[^/]+") do
		if not isSafeSegment(segment) then
			return false
		end
		lastSegment = segment
	end

	if lastSegment then
		local ext = getExtension(lastSegment)
		if checkexc == false and ext and BLOCKED_EXTENSIONS[ext] then
			return false
		end
	end

	return sanitized
end

function Library.SanitizeUrl(Url: string): string?
	local Sanitized: string = Url:gsub("%s+", "")

	if not GeneralUrl:isMatch(Sanitized) then
		return false
	end

	return Sanitized :: string
end

function Library.isWebsocketUrl(Url: string): boolean
	local Sanitized: string? = Library.SanitizeUrl(Url)
	if not Sanitized then
		return false
	end

	return WebsocketUrl:isMatch(Sanitized)
end

return Library