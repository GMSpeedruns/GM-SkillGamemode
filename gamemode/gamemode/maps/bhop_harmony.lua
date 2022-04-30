-- Harmony trash fix

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("logic_*")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("func_wall_toggle")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("func_illusionary")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("point_clientcommand")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("shadow_control")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("func_brush")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("env_smokestack")) do
		ent:Remove()
	end
end)
