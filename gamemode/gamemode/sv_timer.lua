local timer = {}
local runs = {}
local starts = {}

-- Add network identifiers
util.AddNetworkString("Timer")

-- Metatables
local PLAYER_META = FindMetaTable("Player")

-- Modules
local records = GM.Records

-- Functions
local SysTime = SysTime

-- Variables
local net = net

--[[---------------------------------------------------------
  Desc: Acknowledges validity for hooks
-----------------------------------------------------------]]
function timer:IsValid()
  return true
end

--[[---------------------------------------------------------
  Desc: Handles timer upon entering zone
-----------------------------------------------------------]]
function timer:OnEnterZone(zone, ply)
  print("Timer EnterZone", self, zone, ply)
  local type = zone.type
  if type == "Map Start" then
    runs[ply] = nil

    net.Start("Timer")
    net.WriteUInt(0, 2)
    net.Send(ply)
  elseif type == "Map Finish" then
    if runs[ply] then
      local time = SysTime() - runs[ply].Start
      self:ProcessRun(ply)
      print("Finished in", time)

      net.Start("Timer")
      net.WriteUInt(2, 2)
      net.WriteDouble(time)
      net.Send(ply)
    end
  end
end
hook.Add("OnEnterZone", timer, timer.OnEnterZone)

--[[---------------------------------------------------------
  Desc: Handles timer upon leaving zone
-----------------------------------------------------------]]
function timer:OnLeaveZone(zone, ply)
  print("Timer LeaveZone", self, zone, zone.type, ply)

  -- Store starting location for timeable zones
  if zone:IsTimeable() then
    starts[ply] = zone
  end

  local type = zone.type
  if type == "Map Start" then
    print("Ground", ply:IsOnGround())
    -- TODO: Send a notification if not on ground
    runs[ply] = {
      Start = SysTime(),
      Jumps = 0,
      StartSpeed = ply:GetVelocity():Length2D()
    }

    net.Start("Timer")
    net.WriteUInt(1, 2)
    net.Send(ply)
  end
end
hook.Add("OnLeaveZone", timer, timer.OnLeaveZone)

--[[---------------------------------------------------------
  Desc: Handles player reset
-----------------------------------------------------------]]
function timer:PlayerResetToSpawn(ply)
  -- TODO: Store current player position for /undo ing this
  -- TODO: Reset bonus and normal timer
end
hook.Add("PlayerResetToSpawn", timer, timer.PlayerResetToSpawn)

--[[---------------------------------------------------------
  Desc: Returns whether or not the player is in bonus
-----------------------------------------------------------]]
function timer:ProcessRun(ply)
  -- TODO: Make this work
  return false
end

--[[---------------------------------------------------------
  Desc: Returns whether or not the player is in bonus
-----------------------------------------------------------]]
function PLAYER_META:IsBonus()
  -- TODO: Make this work
  return false
end

--[[---------------------------------------------------------
  Desc: Returns whether or not the player is in a stage
-----------------------------------------------------------]]
function PLAYER_META:IsStage()
  -- TODO: Make this work
  return false
end

--[[---------------------------------------------------------
  Desc: Returns the last start zone of the player
-----------------------------------------------------------]]
function PLAYER_META:GetStartingZone()
  return starts[self]
end

-- Store reference
GM.Timer = timer
