-- Fix jail
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("math_counter")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if string.find(ent:GetName(), "end_round_teles") then
			ent:Remove()
		elseif ent:GetPos() == Vector(-6405.98, -5980.71, -8242.5) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_multiple")) do
		if ent:GetPos() == Vector(-6405.99, -5980.71, -8279.5) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_push")) do
		if ent:GetPos() == Vector(-6405.98, -5980.71, -8484) then
			ent:Remove()
		end
	end
end)
