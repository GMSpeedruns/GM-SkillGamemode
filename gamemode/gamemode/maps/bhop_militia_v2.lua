-- Remove breakable borders
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_breakable")) do
		ent:Remove()
	end
end)
