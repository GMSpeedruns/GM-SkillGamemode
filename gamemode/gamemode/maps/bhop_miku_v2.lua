-- Lag fix
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("prop_dynamic")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("logic_timer")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("logic_case")) do
		ent:Remove()
	end
end)
