-- Fix jail and moving parts
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("logic_relay")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("func_door")) do
		if string.find(ent:GetName(), "falldoor") then
			ent:Fire("Open")
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if string.find(ent:GetName(), "timeupteles") then
			ent:Remove()
		end
	end
end)

hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "func_rotating" then
		if string.find(string.lower(key), "maxspeed") then
			return "0"
		elseif string.find(string.lower(key), "fanfriction") then
			return "0"
		elseif string.find(string.lower(key), "spawnflags") then
			return "1024"
		end
	elseif ent:GetClass() == "func_door" then
		if string.find(string.lower(key), "wait") and tonumber(value) == 3 then
			return "-1"
		end
	end
end)
