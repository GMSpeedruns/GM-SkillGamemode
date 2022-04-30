-- Remove bonus teleport

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(8716, -5888, -11516) then
			ent:Remove()
		end
	end
end)
