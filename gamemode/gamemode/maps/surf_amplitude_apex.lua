-- Fix jail and edit teleporters
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("logic_relay")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("trigger_push")) do
		if ent:GetPos() == Vector(-14896, 12042, 1864) then
			ent:Remove()
		end
	end
end)

hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "trigger_teleport" then
		if string.find(string.lower(key), "origin") then
			if value == "3537 951 -8240" then
				tr = ent
			end
		elseif string.find(string.lower(key), "target") then
			if value == "jail_dest_ct2" or value == "jail_dest_t2" then
				return "stage2_start"
			elseif value == "jail_dest_ct3" or value == "jail_dest_t3" then
				return "stage3_start"
			end
		elseif tr == ent then
			if key == "OnStartTouch" then
				return ""
			end
		end
	elseif ent:GetClass() == "filter_activator_team" then
		if string.find(string.lower(key), "filterteam") then
			return "1"
		end
	end
end)
