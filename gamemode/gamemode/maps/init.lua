-- Find all matching maps
local dir = GM.Config.Server.Type .. "/gamemode/maps/"
local files = file.Find(dir .. "*.lua", "LUA")
for _, f in pairs(files) do
	-- Replace for global types
	local ef = f:gsub("wildcard", "*"):gsub(".lua", "")

	-- Check if the map matches
	if (string.find(ef, "*", 1, true) and string.match(game.GetMap(), ef)) or f:gsub(".lua", "") == game.GetMap() or ef == "*" then
		-- Check overrides
		-- TODO: Remove continue construction
		--if Zones["NoWildcard"] and Zones["NoWildcard"][game.GetMap()] and string.find(f, "wildcard", 1, true) then continue end

		-- Load the individual map file
		local result = include(f)

		-- Handle custom options
		if type(result) == "table" then
			-- TODO: Custom map options (Search for return { for all options)
		end

		-- -- Allow custom entities
		-- for identifier, bool in pairs(__MAP) do
		-- 	if not Zones[identifier] then
		-- 		Zones[identifier] = {}
    --
		-- 		if identifier == "CustomEntitySetup" then
		-- 			Zones[identifier] = bool
		-- 			break
		-- 		end
		-- 	end
    --
		-- 	Zones[identifier][game.GetMap()] = bool
		-- end
	end
end
