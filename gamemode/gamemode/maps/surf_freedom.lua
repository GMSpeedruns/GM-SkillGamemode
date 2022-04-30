-- Pause rotating end
if CLIENT then
	local main = hook.GetTable()["OnEntityCreated"]["SpawnPlayerCheck"]
	hook.Remove("OnEntityCreated", "SpawnPlayerCheck")
	hook.Add("OnEntityCreated", "SpawnPlayerCheck", function(ent)
		if ent:GetClass() != "beam" or IsValid(ent:GetParent()) then
			main(ent)
		end
	end)

	return
elseif SERVER then
	AddCSLuaFile()
end

hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "func_rotating" then
		if string.find(string.lower(key), "maxspeed") then
			return "0"
		elseif string.find(string.lower(key), "fanfriction") then
			return "0"
		elseif string.find(string.lower(key), "spawnflags") then
			return "1024"
		end
	elseif ent:GetClass() == "func_lod" then
		if key == "DisappearDist" then
			return "10000"
		end
	end
end)

local base = GM.Config.Server.Type
hook.Add("PlayerInitialSpawn", "MapPlayerInitialSpawn", function(ply)
	ply:SendLua("include(\"" .. base .. "/gamemode/maps/surf_freedom.lua\")")
end)
