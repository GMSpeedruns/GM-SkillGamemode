-- Stop rotating things from rotating
hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "func_rotating" then
		if string.find(string.lower(key), "maxspeed") then
			return "0"
		elseif string.find(string.lower(key), "fanfriction") then
			return "0"
		elseif string.find(string.lower(key), "spawnflags") then
			return "1024"
		end
	end
end)
