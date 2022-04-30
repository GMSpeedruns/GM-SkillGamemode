-- Increase booster power at the start
hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "trigger_push" and string.find(string.lower(key), "speed") and tonumber(value) == 800 then
		return "2500"
	end
end)
