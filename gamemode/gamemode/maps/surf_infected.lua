-- Force to easy mode
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.GetAll()) do
		local name = ent:GetName()
		if name == "red" then
			ent:Fire("TurnOff")
		elseif name == "h" then
			ent:Fire("Disable")
		elseif name == "right" then
			ent:Fire("Open")
		elseif name == "left" then
			ent:Fire("Open")
		elseif name == "movwe" then
			ent:Fire("Close")
		elseif name == "HARDMODE" then
			ent:Fire("Break")
		elseif name == "cc" then
			ent:Fire("Disable")
		elseif name == "spawnlrgreen" then
			ent:Fire("LightOn")
		end
	end

	for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
		if ent:GetPos() == Vector(-11612, 2128, 10180) or ent:GetPos() == Vector(-11612, 1968, 10180) then
			ent:Remove()
		end
	end
end)
