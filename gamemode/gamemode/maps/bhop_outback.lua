-- Remove the slowly opening doors
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_door")) do
		if ent:GetName() == "door_level2" then
			ent:Remove()
		end
	end
end)
