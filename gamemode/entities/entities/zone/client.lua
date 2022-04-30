-- Functions
local SetMaterial, DrawBeam = render.SetMaterial, render.DrawBeam

-- Variables
local material = Material("sprites/tp_beam001")
local width = 10
local colors = {
	["Map Start"] = Color(0, 255, 0),
	["Map Finish"] = Color(255, 0, 0)
}

--[[---------------------------------------------------------
  Desc: Initializes the entity
-----------------------------------------------------------]]
function ENT:Initialize()
	self.initialized = false
end

--[[---------------------------------------------------------
  Desc: Draws the lines of the zone
-----------------------------------------------------------]]
function ENT:Draw()
	SetMaterial(material)
	DrawBeam(self.bl, self.tl, width, 0, 1, self.color)
	DrawBeam(self.tl, self.tr, width, 0, 1, self.color)
	DrawBeam(self.tr, self.br, width, 0, 1, self.color)
	DrawBeam(self.br, self.bl, width, 0, 1, self.color)
end

--[[---------------------------------------------------------
  Desc: Think hook handles first initialization when ready
-----------------------------------------------------------]]
function ENT:Think()
	if not self.initialized then
		self.type = self:GetType()

		local min, max = self:GetCollisionBounds()
		self:SetRenderBounds(min, max)
		min = self:GetPos() + min
		max = self:GetPos() + max

		if self:GetOnEdge() then
			min = min - Vector(16, 16, 0)
			max = max + Vector(16, 16, 0)
		end

		self.bl = Vector(min.x, min.y, min.z)
		self.tl = Vector(min.x, max.y, min.z)
		self.tr = Vector(max.x, max.y, min.z)
		self.br = Vector(max.x, min.y, min.z)
		self.color = colors[self.type]
		self.initialized = true
	end
end
