-- Force to easy mode
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.GetAll()) do
		local name = ent:GetName()
		if name == "but_e" or name == "but_m" or name == "but_h" or name == "win_med" or name == "win_hard" or name == "movelinear" then
			ent:Remove()
		elseif name == "lvl1_ha_me_e" or name == "lvl1_ha_e" or name == "lvl1_me_e" or name == "lvl5_ha_e" or name == "lvl5_ha_me_e" then
			ent:Fire("Disable")
		elseif name == "01activ_EASY" or name == "01activ_MEDIUM" or name == "01activ_HARD" then
			ent:Remove()
		elseif name == "win_knife" then
			ent:Fire("Disable")
		elseif name == "break_4lvl_med" or name == "break_1lvl_ha_me" then
			ent:Fire("Break")
		elseif name == "door_start" then
			ent:Fire("Close")
		end
	end
end)
