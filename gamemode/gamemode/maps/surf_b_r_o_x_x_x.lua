-- Removing rotating stuff and trails

if CLIENT then
	local main = hook.GetTable()["OnEntityCreated"]["SpawnPlayerCheck"]
	hook.Remove("OnEntityCreated", "SpawnPlayerCheck")
	hook.Add("OnEntityCreated", "SpawnPlayerCheck", function(ent)
		if ent:GetClass() != "env_spritetrail" then
			main(ent)
		end
	end)

	return
elseif SERVER then
	AddCSLuaFile()
end

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_breakable")) do
		if ent:GetPos() == Vector(-3634.52, -1026, -990) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("func_rotating")) do
		if ent:GetPos() == Vector(-3634.69, -1024, -987.5) or ent:GetPos() == Vector(-3634.6, -1024, -987.5) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(-3641.41, -1026, -990) then
			ent:Remove()
		end
	end
end)

-- And allow trails
local base = GM.Config.Server.Type
hook.Add("PlayerInitialSpawn", "MapPlayerInitialSpawn", function(ply)
	ply:SendLua("include(\"" .. base .. "/gamemode/maps/surf_b_r_o_x_x_x.lua\")")
end)
