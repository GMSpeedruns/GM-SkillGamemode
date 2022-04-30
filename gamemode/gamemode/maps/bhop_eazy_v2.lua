-- Remove breakables
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_breakable")) do
		if ent:GetPos() == Vector(4912, 832, 120) or ent:GetPos() == Vector(5200, 1312, 120) or ent:GetPos() == Vector(4912, 1184, 120) then
			ent:Remove()
		end
	end
end)
