-- Remove moving door
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_door")) do
		if ent:GetName() == "ture" then
			ent:Remove()
		end
	end
end)
