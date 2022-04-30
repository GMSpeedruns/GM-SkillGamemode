-- Remove jail teleporters
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(3224, 1896, 4432) then
			ent:SetKeyValue("target", "start_1")
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_multiple")) do
		if ent:GetPos() == Vector(3224, 1896, 4472) then
			ent:Remove()
		end
	end
end)
