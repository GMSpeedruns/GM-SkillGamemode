-- Remove stupid unreliable doors
local doors = {
	Vector(2736, -2895, 2688),
	Vector(2896, -2895, 2688),
	Vector(2846, -8856.5, 2712),
	Vector(2778, -8856.5, 2712),
	Vector(10350, -9424.5, 10256),
	Vector(10282, -9424.5, 10256)
}

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_door")) do
		if table.HasValue(doors, ent:GetPos()) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_multiple")) do
		if ent:GetPos() == Vector(2896, -2878.5, 2672) or ent:GetPos() == Vector(2736, -2878.5, 2672) then
			ent:Remove()
		end
	end
end)
