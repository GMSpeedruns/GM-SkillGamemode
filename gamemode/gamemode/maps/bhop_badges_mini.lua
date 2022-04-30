-- Remove colorful glocks
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("weapon_glock")) do
		ent:Remove()
	end
end)
