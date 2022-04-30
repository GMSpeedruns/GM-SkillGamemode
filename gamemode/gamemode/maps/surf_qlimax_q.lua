-- Fix jail and moving parts
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_button")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("func_movelinear")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("func_tracktrain")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("path_track")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if string.find(ent:GetName(), "failerteleport") or string.find(ent:GetName(), "winnerteleport") then
			ent:Remove()
		end
	end
end)

-- -- Get player table
-- local PLAYER = FindMetaTable("Player")
-- function PLAYER:IsStageResettable(id)
-- 	return id != 6
-- end
-- TODO: Apply this for new stuff
