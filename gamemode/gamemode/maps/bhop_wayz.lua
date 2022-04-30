-- Stop rotating objects
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_rotating")) do
		ent:SetName("StoppedNow")
	end
end)
