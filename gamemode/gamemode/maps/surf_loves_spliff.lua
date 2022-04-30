-- Remove jail teleports teleport
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetName() == "level_teleport" then
			ent:Remove()
		elseif ent:GetPos() == Vector(672, 1248, -184) then
			ent:Remove()
		end
	end
end)
