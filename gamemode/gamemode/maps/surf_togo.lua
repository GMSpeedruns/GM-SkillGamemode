-- Remove jail teleports
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(-10280, 9888, -1184) or ent:GetPos() == Vector(128, 2752, -7568) then
			ent:Remove()
		end
	end
end)
