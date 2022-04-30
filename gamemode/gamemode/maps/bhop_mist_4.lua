-- Removes crash and ugly shit
hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if string.sub(key, 1, 2) == "On" and string.find(value, "ShowHudHint") then
		ent.hudhint = true
	end

	if key == "OnMapSpawn" and value == "command,Command,exec bhopmist4.cfg,0,-1" then
		return ""
	end
end)

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	ents.FindByName("timer2")[1]:Remove()

	for _, ent in pairs(ents.FindByName("d1")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByName("d2")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByName("d3")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("trigger_multiple")) do
		if ent.hudhint then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("point_servercommand")) do
		ent:Remove()
	end
end)
