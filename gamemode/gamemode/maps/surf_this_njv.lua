-- Remove annoying parts
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_illusionary")) do
		if ent:GetPos() == Vector(1824, -576, -312) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("func_door")) do
		ent:Remove()
	end
end)
