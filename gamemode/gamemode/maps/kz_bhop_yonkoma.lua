-- Set WJ and legit force

-- hook.Add("InitPostEntity", "MapInitPostEntity", function()
-- 	GAMEMODE:SetDefaultStyle(Core.Config.Style.Legit, 16)
-- end)

hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "trigger_teleport" and key == "OnStartTouch" and value == "knife,Use,,0.1,-1" or value == "strip,Strip,,0,-1" then
		return ""
	end
end)
