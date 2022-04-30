-- Remove trap images
hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "infodecal" and key == "texture" and string.find(value, "trap") then
		return "real_dev/dev_gray4"
	end
end)
