-- Booster Fix
hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "trigger_multiple" and key == "OnTrigger" and value == "!activator,AddOutput,basevelocity 0 0 350,0,-1" then
		return "!activator,AddOutput,basevelocity 0 0 440,0,-1"
	end
end)
