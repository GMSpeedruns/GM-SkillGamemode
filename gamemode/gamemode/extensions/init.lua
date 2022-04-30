-- Find all extensions
local dir = GM.Config.Server.Type .. "/gamemode/extensions/"
local files = file.Find(dir .. "*.lua", "LUA")
table.sort(files)

-- Include all files
for i = 1, #files do
	local filename = files[i]
	local prefix = string.sub(filename, 1, 2)
	if prefix == "cl" or prefix == "sh" then
		AddCSLuaFile(dir .. filename)
	end

	if prefix == "sv" or prefix == "sh" then
		include(dir .. filename)
	end
end
