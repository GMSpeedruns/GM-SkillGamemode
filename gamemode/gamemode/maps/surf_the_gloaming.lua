-- Allow triggers to teleport any team
hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "filter_activator_team" and string.find(string.lower(key), "filterteam") then
		return "1"
	end
end)
