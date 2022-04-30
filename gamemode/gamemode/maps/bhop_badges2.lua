-- Crouch bug remove
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	-- GAMEMODE:SetDefaultStyle(Core.Config.Style.Legit, 16) -- TODO: Make this possible again (show GUI on the player)

	for _, ent in pairs(ents.FindByClass("trigger_multiple")) do
		if ent:GetPos() == Vector(-12543.9, -8448, 4319.96) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(-3840, -4832, -468) or ent:GetPos() == Vector(-9216, -2168, -1732) then
			ent:Remove()
		end
	end
end)

-- Enable the stamina system
include("kz_wildcard.lua")
