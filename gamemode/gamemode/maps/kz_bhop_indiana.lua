-- Crouch parts removal

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	-- GAMEMODE:SetDefaultStyle(Core.Config.Style.Legit, 16)
	-- TODO: Yup

	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(4312, 3600, -3780) then
			ent:Remove()
		end
	end
end)
