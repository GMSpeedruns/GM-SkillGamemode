-- Define entity type
ENT.Type = "anim"
ENT.Base = "base_anim"

--[[---------------------------------------------------------
  Desc: Set up network variables for the entity
-----------------------------------------------------------]]
function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "Type")
	self:NetworkVar("Bool", 0, "OnEdge")
end

-- Include necessary files
if SERVER then
	AddCSLuaFile("shared.lua")
	AddCSLuaFile("client.lua")
	include("server.lua")
elseif CLIENT then
	include("client.lua")
end
