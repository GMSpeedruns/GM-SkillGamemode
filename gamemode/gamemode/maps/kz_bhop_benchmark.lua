-- Highen WJ triggers
local fakes = {
	{ Vector(2597.83, 3049.45, 2298.33), Vector(3352.07, 3867.13, 2300.33) },
	{ Vector(2274.19, 3245.97, 2298.33), Vector(2593.69, 3663.97, 2300.33) }
}

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	-- GAMEMODE:SetDefaultStyle(Core.Config.Style.Legit, 16)
	-- TODO: StepSize?

	local target
	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(5592, 11296, 7120) or ent:GetPos() == Vector(5536, 11172, 7120) or ent:GetPos() == Vector(-832.02, 1039.94, 3128) then
			ent:SetPos(ent:GetPos() + Vector(0, 0, 8))
			ent:Spawn()
		elseif ent:GetPos() == Vector(3204, 3416, 2432) then
			target = ents.FindByName(ent:GetSaveTable().target)[1]
		end
	end

	if not IsValid(target) then return end
	for _, ent in pairs(fakes) do
		local f = ents.Create("TeleporterEnt")
		f:SetPos((v[1] + v[2]) / 2)
		f.min = v[1]
		f.max = v[2]
		f.targetpos = target:GetPos()
		f.targetang = target:GetAngles()
		f:Spawn()
	end
end)
