-- Fix jail and weird spawn position
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_rot_button")) do
		ent:Remove()
	end
end)

hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "trigger_teleport" and string.find(string.lower(key), "target") and value == "tp_nakaz" then
		return "tp"
	end
end)
