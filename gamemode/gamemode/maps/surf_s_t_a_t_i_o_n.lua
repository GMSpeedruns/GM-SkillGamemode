-- Remove jail teleports teleport
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetName() == "start_zusammen" then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_multiple")) do
		if ent:GetName() == "ban" then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("func_button")) do
		ent:Remove()
	end
end)

hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetName() == "tele3" and string.find(string.lower(key), "startdisabled") then
		return "0"
	end
end)
