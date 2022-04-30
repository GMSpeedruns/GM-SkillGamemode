-- Remove doors that open too slow
local openers = {
	Vector(-5852, -4336, 84),
	Vector(-3872, -2488, 384),
	Vector(-2184, -1776, 384),
	Vector(-724, 1704, 64),
	Vector(3732, 6456, 352)
}

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_door")) do
		if string.find(ent:GetName(), "door") then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_multiple")) do
		if table.HasValue(openers, ent:GetPos()) then
			ent:Remove()
		end
	end
end)
