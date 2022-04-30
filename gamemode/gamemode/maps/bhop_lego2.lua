-- Booster power increasing
hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "trigger_push" and string.find(string.lower(key), "speed") then
		return tostring(tonumber(value) + 80)
	end
end)
