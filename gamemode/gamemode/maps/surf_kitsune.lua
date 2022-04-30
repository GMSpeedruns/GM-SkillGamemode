-- Remove rainbow button
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_button")) do
		if ent:GetPos() == Vector(12288, 3584, -2444) then
			ent:Remove()
		end
	end
end)
