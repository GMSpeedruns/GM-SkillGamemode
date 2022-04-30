-- Remove dust stuff
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_dustcloud")) do
		ent:Remove()
	end
end)
