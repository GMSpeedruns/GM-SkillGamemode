-- Remove trains and keep hiding platforms open
local tmr = {
	Vector(-6080, -1296, -1413.93),
	Vector(-6408, -1296, -1413.93),
	Vector(-6808, -1296, -1413.93),
	Vector(-6896, -1472, -1413.93),
	Vector(-6896, -1728, -1413.93),
	Vector(-6896, -2048, -1413.93),
	Vector(-6896, -2320, -1413.93),
}

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(10240.1, -14144, -4816) or ent:GetPos() == Vector(10240.1, -14336, -4816) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("func_tanktrain")) do
		if ent:GetPos() == Vector(10240.1, -14144, -4824) or ent:GetPos() == Vector(10240.1, -14336, -4824) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("path_track")) do
		if string.find(ent:GetName(), "train", 1, true) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_multiple")) do
		if table.HasValue(tmr, ent:GetPos()) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("func_door")) do
		ent:Fire("Open")
	end
end)

hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "func_door" and string.find(string.lower(key), "wait") and tonumber(value) == 4 then
		return "-1"
	end
end)
