-- Remove the weapon button
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_button")) do
		-- Find an entity named 'weapon_button'
		if ent:GetPos() == Vector(-189, -262, 68) then
			ent:Remove()
		end
	end
end)
