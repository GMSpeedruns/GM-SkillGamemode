-- Broken trigger removal on Voyage
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(0, -404.5, -136) then
			ent:Remove()
		end
	end
end)
