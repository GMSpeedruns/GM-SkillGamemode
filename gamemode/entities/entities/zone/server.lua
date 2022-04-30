local IsValid = IsValid

--[[---------------------------------------------------------
  Desc: Initialize the zone entity
-----------------------------------------------------------]]
function ENT:Initialize()
	local min, max = self.min, self.max
	local difference = max - min
	local box = (max - min) / 2

	if difference.x > 32 and difference.y > 32 then
		min = min + Vector(16, 16, 0)
		max = max - Vector(16, 16, 0)

		self:SetOnEdge(true)
	else
		self:SetOnEdge(false)
	end

	self:SetType(self.type)
	self:SetSolid(SOLID_BBOX)
	self:PhysicsInitBox(-box, box)
	self:SetCollisionBoundsWS(min, max)
	self:SetTrigger(true)
	self:DrawShadow(false)
	self:SetNotSolid(true)
	self:SetNoDraw(false)
	self.Phys = self:GetPhysicsObject()

	if IsValid(self.Phys) then
		self.Phys:Sleep()
		self.Phys:EnableCollisions(false)
	end
end

--[[---------------------------------------------------------
  Desc: Handles any triggered StartTouch event on zone
-----------------------------------------------------------]]
function ENT:StartTouch(ent)
	if IsValid(self) and IsValid(ent) and ent:IsPlayer() then
		self.zone:OnEnter(ent)
	end
end

--[[---------------------------------------------------------
  Desc: Handles any triggered EndTouch event on zone
-----------------------------------------------------------]]
function ENT:EndTouch(ent)
	if IsValid(self) and IsValid(ent) and ent:IsPlayer() then
		self.zone:OnLeave(ent)
	end
end
