-- Remove rotating parts
local rots = {
	Vector(1504, 12544, 9040),
	Vector(11648, 12563.9, 3050.12),
	Vector(4672, 12547.9, 2442.1)
}

local linear = {
	Vector(-6306.09, 8080, -5536.4),
	Vector(5600, -11392, 9552),
	Vector(8672, -9088, 9552),
	Vector(12768, -11072, 8976)
}

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_rotating")) do
		if table.HasValue(rots, ent:GetPos()) then
			ent:Remove()
		elseif ent:GetPos() == Vector(-14784, 8080, -12528) then
			ent:SetPos(Vector(-14795, 7920, -12435))
		end
	end

	for _, ent in pairs(ents.FindByClass("func_movelinear")) do
		if table.HasValue(linear, ent:GetPos()) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(12768, -11840, 9008) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("func_illusionary")) do
		if ent:GetPos() != Vector(-11872, -3296, 12784) then
			ent:Remove()
		end
	end
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
