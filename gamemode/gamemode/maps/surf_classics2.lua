-- Remove rotating parts

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_rotating")) do
		if ent:GetPos() == Vector(718, -112, -12297) or ent:GetPos() == Vector(718, -2256.38, -12447) or ent:GetPos() == Vector(718, -4560, -12608) then
			ent:Remove()
		end
	end
end)
