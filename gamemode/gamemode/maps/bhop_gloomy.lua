local poles = {
	Vector(65, 1842, -3),
	Vector(180, 1778, -3),
	Vector(292, 1737, -3),
	Vector(413, 1710.01, -3),
	Vector(551, 1712, -3),
	Vector(659.44, 1757.48, -3),
	Vector(750, 1823, -3),
	Vector(846, 1905, -3),
	Vector(977, 1905, -3)
}

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	-- Remove all breakable entities
	for _, ent in pairs(ents.FindByClass("func_breakable")) do
		ent:Remove()
	end

	-- Remove trigger once
	for _, ent in pairs(ents.FindByClass("trigger_once")) do
		ent:Remove()
	end

	-- Remove all scout trails
	for _, ent in pairs(ents.FindByClass("weapon_scout")) do
		ent:Remove()
	end

	-- TODO: Figure out what the goal was here
	-- -- Since this might get called a lot, localize
	-- local index = IndexPlatform
	-- local plats = Core.GetMapVariable("Platforms")
	-- plats.NoWipe = true
  --
	-- -- Loop over all door platforms
	-- for _, ent in pairs(ents.FindByClass("func_door")) do
	-- 	if string.find(ent:GetName(), "move1") then
	-- 		ent:Remove()
	-- 	end
  --
	-- 	if not table.HasValue(poles, ent:GetPos()) then continue end
  --
	-- 	ent:Fire("Lock")
	-- 	ent:SetKeyValue("spawnflags", "1024")
	-- 	ent:SetKeyValue("speed", "0")
	-- 	ent:SetRenderMode(RENDERMODE_TRANSALPHA)
  --
	-- 	if ent.BHS then
	-- 		ent:SetKeyValue("locked_sound", ent.BHS)
	-- 	else
	-- 		ent:SetKeyValue("locked_sound", "DoorSound.DefaultMove")
	-- 	end
  --
	-- 	local nid = ent:EntIndex()
	-- 	index(nid)
	-- 	plats[#plats + 1] = nid
	-- end
end)

hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "func_rotating" then
		if string.find(string.lower(key), "maxspeed") then
			return "0"
		elseif string.find(string.lower(key), "fanfriction") then
			return "0"
		elseif string.find(string.lower(key), "spawnflags") then
			return "1024"
		end
	end
end)
