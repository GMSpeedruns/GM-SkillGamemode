local zones = {}
zones.Height = 70
zones.Creating = {}
zones.Entities = {}
zones.Types = {
  -- Map timer
  "Map Start",
  "Map Finish",

  -- Bonus timer
  "Bonus Start",
  "Bonus Finish",

  -- Stage timer
  "Stage Start",
  "Stage Finish",

  -- Timer stopper
  "Stop All",
  "Stop Map",
  "Stop Bonus",
  "Stop Stage",

  -- Special zones
  "Restart",
  "Freestyle",
  "Booster",
  "Gravity",
  "Block"
}

-- Define zone object
zones.zone = {}
zones.zone.__index = zones.zone

-- Modules
local database = GM.Database
local helpers = GM.Helpers
local timer = GM.Timer

-- Functions
local HookRun = hook.Run

--[[---------------------------------------------------------
  Desc: Acknowledges validity for hooks
-----------------------------------------------------------]]
function zones:IsValid()
  return true
end

--[[---------------------------------------------------------
  Desc: Load zones from database and setup them up
-----------------------------------------------------------]]
function zones:Initialize()
  local query = database:Prepare(
    "SELECT * FROM zones WHERE map = ?",
    { game.GetMap() }
  )

  query:execute(function(data)
    zones:Setup(data)
  end)
end
hook.Add("OnDatabaseConnected", zones, zones.Initialize)

--[[---------------------------------------------------------
  Desc: Create a zone
-----------------------------------------------------------]]
function zones:Create(type, min, max)
  local zone = { type = type, min = min, max = max }
  setmetatable(zone, self.zone)

  return zone:Spawn()
end

--[[---------------------------------------------------------
  Desc: Creates zone using fetched data
-----------------------------------------------------------]]
function zones:Setup(data)
  self.List = data or self.List

  -- Remove existing zones
  for i = 1, #self.Entities do
    self.Entities[i]:Remove()
    self.Entities[i] = nil
  end

  self.Entities = {}

  for i = 1, #self.List do
    local item = self.List[i]
    self.Entities[#self.Entities + 1] = self:Create(item.type, Vector(item.min), Vector(item.max))
  end
end

--[[---------------------------------------------------------
  Desc: Gets all zones with a given type
-----------------------------------------------------------]]
function zones:GetZonesByType(type)
  local list = {}
  for i = 1, #self.Entities do
    if self.Entities[i].type == type then
      list[#list + 1] = self.Entities[i]
    end
  end

  return list
end

--[[---------------------------------------------------------
  Desc: Start creating a zone
-----------------------------------------------------------]]
function zones:StartCreate(ply, type)
  if not table.HasValue(self.Types, type) then return end
  if self.Creating[ply] and self.Creating[ply].Type == type then
    self.Creating[ply].Start = ply:GetPos()
  else
    self.Creating[ply] = {
      Start = ply:GetPos(),
      Type = type,
      Height = self.Height
    }
  end

  return self.Creating[ply]
end

--[[---------------------------------------------------------
  Desc: Start creating a zone
-----------------------------------------------------------]]
function zones:StopCreate(ply)
  local tab = self.Creating[ply]
  if not tab then return end

  -- Check if we need a pair of zones
  local size = ply:KeyDown(IN_DUCK) and 16 or 32
  tab.min = helpers.SnapVector(tab.Start, size)
  tab.max = helpers.SnapVector(ply:GetPos(), size)
  tab.min, tab.max = helpers.MinMaxVector(tab.min, tab.max)
  tab.max.z = tab.max.z + self.Height

  -- Save data into the database
  local query = database:Prepare(
    "INSERT INTO zones (map, type, min, max) VALUES (?, ?, ?, ?)",
    { game.GetMap(), tab.Type, tostring(tab.min), tostring(tab.max) }
  )

  query:execute(function(data)
    zones:Initialize()
  end)

  return true
end

--[[---------------------------------------------------------
  Desc: TODO
-----------------------------------------------------------]]
function zones:GetSpawnPoint(type, preferred)
  local list = self:GetZonesByType(type)
  if #list > 0 then
    local zone = list[1]
    if preferred and preferred.type == zone.type then
      -- TODO: Finish this (for multiple start zones)
    end

    return helpers.RandomizeCoordinate(zone.min, zone.max, zone.center)
  end
end

--[[---------------------------------------------------------
  Desc: Handles moving the player to the spawn
-----------------------------------------------------------]]
function zones:MovePlayerToSpawn(ply)
  if ply:IsBonus() then
    -- TODO: Finish this for bonus
  elseif ply:IsStage() then

  else
    local spawn = self:GetSpawnPoint("Timer", ply:GetStartingZone())
    if spawn then
      ply:SetPos(spawn)
    end
    -- TODO: If nil do a print, maybe one level higher?
  end
end

--[[---------------------------------------------------------
  Desc: Create the zone entity
-----------------------------------------------------------]]
function zones.zone:Spawn()
  -- Set variables and spawn the entity
  self.entity = ents.Create("zone")
  self.entity.zone = self
  self.entity.min = self.min
  self.entity.max = self.max
  self.entity.type = self.type
  self.entity.OnEnter = self.OnEnter
  self.entity.OnLeave = self.OnLeave
  self.entity:SetPos((self.min + self.max) / 2)
  self.entity:Spawn()

  return self
end

--[[---------------------------------------------------------
  Desc: Remove the zone entity
-----------------------------------------------------------]]
function zones.zone:Remove()
  if IsValid(self.entity) then
    self.entity:Remove()
    self.entity = nil
  end
end

--[[---------------------------------------------------------
  Desc: Callback for players entering a zone
-----------------------------------------------------------]]
function zones.zone:OnEnter(ply)
  if not ply:IsSpectator() then
    timer:OnEnterZone(self, ply)
  end
end

--[[---------------------------------------------------------
  Desc: Callback for players leaving a zone
-----------------------------------------------------------]]
function zones.zone:OnLeave(ply)
  if not ply:IsSpectator() then
    timer:OnLeaveZone(self, ply)
  end
end

--[[---------------------------------------------------------
  Desc: Returns if a zone uses timing
-----------------------------------------------------------]]
function zones.zone:IsTimeable()
  local first_space = string.find(self.type, " ")
  local prefix = first_space and string.sub(self.type, 1, first_space - 1)
  return prefix == "Timer" or prefix == "Bonus" or prefix == "Stage"
end

-- Store reference
GM.Zones = zones
