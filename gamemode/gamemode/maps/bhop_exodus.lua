-- Exodus trigger fix and broken spikes
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	--[[
	This should be fixed by using sv_turbophysics on the server

	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(6560, 5112, 7412) then
			ent:SetKeyValue("target","13")
		end
	end
	--]]

	for _, ent in pairs(ents.FindByClass("func_brush")) do
		if ent:GetName() == "aokilv6" then
			ent:SetName("disabled")
		end
	end

	local p = ents.Create("game_block")
	p:SetPos(Vector(-328, 11992, 4703))
	p.min = Vector(-2, -2, -1.5)
	p.max = Vector(2, 2, 1)
	p:Spawn()

	p = ents.Create("game_block")
	p:SetPos(Vector(-296, 12095, 4703))
	p.min = Vector(-2, -2, -1.5)
	p.max = Vector(2, 2, 1)
	p:Spawn()

	p = ents.Create("game_block")
	p:SetPos(Vector(-655, 12151, 4703))
	p.min = Vector(-2, -2, -1.5)
	p.max = Vector(2, 2, 1)
	p:Spawn()

	p = ents.Create("game_block")
	p:SetPos(Vector(-815, 11920, 4703))
	p.min = Vector(-2, -2, -1.5)
	p.max = Vector(2, 2, 1)
	p:Spawn()

	p = ents.Create("game_block")
	p:SetPos(Vector(-815, 11808, 4703))
	p.min = Vector(-2, -2, -1.5)
	p.max = Vector(2, 2, 1)
	p:Spawn()

	p = ents.Create("game_block")
	p:SetPos(Vector(-911, 11840, 4703))
	p.min = Vector(-2, -2, -1.5)
	p.max = Vector(2, 2, 1)
	p:Spawn()

	p = ents.Create("game_block")
	p:SetPos(Vector(-1071, 11840, 4703))
	p.min = Vector(-2, -2, -1.5)
	p.max = Vector(2, 2, 1)
	p:Spawn()
end)
