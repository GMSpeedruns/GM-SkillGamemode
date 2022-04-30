-- Remove auto jail

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(11712, -6528, -1360) then
			ent:Remove()
		end
	end
end)
