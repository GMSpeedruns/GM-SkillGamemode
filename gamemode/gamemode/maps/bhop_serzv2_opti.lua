-- Remove stupid rotating things
hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "func_rotating" then
		if string.find(string.lower(key), "maxspeed") and tonumber(value) == 25 then
			return "0"
		elseif string.find(string.lower(key), "fanfriction") and tonumber(value) == 20 then
			return "0"
		elseif string.find(string.lower(key), "spawnflags") then
			return "1024"
		end
	end
end)
