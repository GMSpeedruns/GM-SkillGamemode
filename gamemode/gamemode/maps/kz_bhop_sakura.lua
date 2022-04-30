-- Remove some fucky triggers for crouch

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	--GAMEMODE:SetDefaultStyle(Core.Config.Style.Legit, 16)
	-- TODO: Move to kz_file

	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(84, 1769.5, 657.5) then
			ent:Remove()
		end
	end
end)
