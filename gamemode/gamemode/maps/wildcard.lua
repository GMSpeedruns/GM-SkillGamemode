-- Set custom map spawning angles
-- TODO: This is ridiculous

local MapTable = {
	["bhop_aztec_fixed"] = { 90, 180, -90 },
	["bhop_jouluuu"] = 270,
	["bhop_orgrimmar"] = 180,
	["bhop_jierdas"] = 180,
	["bhop_wob_yk"] = 180,
	["bhop_western"] = 180
}

-- TODO: Make this work, but VERY DIFFERENTLY (settable in gamemode control panel)
-- __MAP["CustomEntitySetup"] = function(Timer)
-- 	local map = MapTable[game.GetMap()]
-- 	if map then
-- 		local bonuses, base = {}
-- 		if type(map) == "table" then
-- 			base = table.remove(map, 1)
-- 			bonuses = map
-- 		else
-- 			base = map
-- 		end
--
-- 		if base then
-- 			Timer.BaseAngles = Angle(0, base, 0)
-- 		end
--
-- 		if #bonuses > 0 then
-- 			for _, i in pairs(Core.GetBonusIDs()) do
-- 				if bonuses[i + 1] then
-- 					Timer.BonusAngles[i] = Angle(0, bonuses[i + 1], 0)
-- 				end
-- 			end
-- 		end
-- 	end
-- end

-- Enable fading platforms
for _, ent in pairs(ents.FindByClass("func_lod")) do
	ent:SetRenderMode(RENDERMODE_TRANSALPHA)
end

-- Enable fading non-platforms
for _, ent in pairs(ents.GetAll()) do
	if ent:GetRenderFX() != 0 and ent:GetRenderMode() == 0 then
		ent:SetRenderMode(RENDERMODE_TRANSALPHA)
	end
end

-- Gets rid of the "Couldn't dispatch user message (21)" errors in console
for _, ent in pairs(ents.FindByClass("env_hudhint")) do
	ent:Remove()
end
