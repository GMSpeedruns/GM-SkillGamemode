-- Include helper functions
GM.Helpers = include("sh_helpers.lua")

-- Load storage module first
GM.Storage = include("sh_storage.lua")

-- Check if we can load
local loaded = GM.Storage:Init()
if loaded ~= true then
  return "Storage missing"
end

-- Configure the gamemode
GM.Config = include("sh_config.lua")

-- Check if the config is ready
if type(GM.Config) ~= "table" then
  return "Invalid config"
end

-- Load language
GM.Language = include("sh_language.lua")

-- Copy config values
local config = GM.Config
GM.Name = config.Server.Name
GM.Author = config.Server.Host
GM.Email = config.Server.Email
GM.Website = config.Server.Website
GM.Version = "10.0.0"

-- Define the player settings
local PLAYER_META = FindMetaTable("Player")
local PLAYER = {}
PLAYER.DisplayName = "Player"
PLAYER.DefaultSpeed = 250
PLAYER.WalkSpeed = config.Vars.Get("Player_WalkSpeed") or PLAYER.DefaultSpeed
PLAYER.RunSpeed = PLAYER.WalkSpeed
PLAYER.CrouchedWalkSpeed = 0.34
PLAYER.DuckSpeed = 0.4
PLAYER.UnDuckSpeed = 0.2
PLAYER.AvoidPlayers = false
PLAYER.SpawnWeapons = config.Vars.Get("Player_SpawnWeapons")
PLAYER.Model = "models/player/group01/male_01.mdl"
PLAYER.BotModel = "models/player/kleiner.mdl"
PLAYER.PlayerTeam = 1
PLAYER.SpectatorTeam = TEAM_SPECTATOR
player_manager.RegisterClass(config.Movement.Class, PLAYER, "player_default")

--[[---------------------------------------------------------
  Desc: Grants the player equipment
  Notes: Called from the base gamemode, serverside
-----------------------------------------------------------]]
function PLAYER:Loadout()
  local ply = self.Player
  if #ply:GetWeapons() > 0 then
    ply:StripWeapons()
  end

  if PLAYER.SpawnWeapons then
    ply:Give("weapon_glock")
    ply:Give("weapon_usp")
    ply:Give("weapon_knife")

    ply:SetAmmo(999, "pistol")
    ply:SetAmmo(999, "smg1")
    ply:SetAmmo(999, "buckshot")
  end
end

--[[---------------------------------------------------------
  Desc: Sets a player model
  Notes: Called from the base gamemode
-----------------------------------------------------------]]
function PLAYER:SetModel()
  self.Player:SetModel(self.Player:IsBot() and PLAYER.BotModel or PLAYER.Model)
end

--[[---------------------------------------------------------
  Desc: Convenience function to check for spectator
-----------------------------------------------------------]]
function PLAYER_META:IsSpectator()
  return self:Team() == PLAYER.SpectatorTeam
end

--[[---------------------------------------------------------
  Desc: Also changes walk speed when stripping weapons
  Notes: Overrides the Player function
-----------------------------------------------------------]]
PLAYER_META.DefaultStripWeapons = PLAYER_META.StripWeapons
function PLAYER_META:StripWeapons()
  self:SetWalkSpeed(PLAYER.WalkSpeed)
  self:DefaultStripWeapons()
end

--[[---------------------------------------------------------
  Desc: Changes walkspeed according to held weapon
-----------------------------------------------------------]]
local function ChangeWalkSpeed(ply, old, new)
  if IsValid(new) then
    ply:SetWalkSpeed(new:GetClass() == "weapon_scout" and PLAYER.WalkSpeed or PLAYER.DefaultSpeed)
  else
    ply:SetWalkSpeed(PLAYER.WalkSpeed)
  end
end
hook.Add("PlayerSwitchWeapon", "ChangeWalkSpeed", ChangeWalkSpeed)

--[[---------------------------------------------------------
  Desc: Adds teams to the gamemode
-----------------------------------------------------------]]
function GM:CreateTeams()
  team.SetUp(PLAYER.PlayerTeam, "Players", Color(255, 50, 50, 255), false)
  team.SetUp(PLAYER.SpectatorTeam, "Spectators", Color(50, 255, 50, 255), true)
  team.SetSpawnPoint(PLAYER.PlayerTeam, { "info_player_terrorist", "info_player_counterterrorist" })
end

--[[---------------------------------------------------------
  Desc: Controls noclip access
-----------------------------------------------------------]]
function GM:PlayerNoClip(ply)
  return ply:Alive() and not ply:IsSpectator()
end

--[[---------------------------------------------------------
  Desc: Disables the use key outside of play
-----------------------------------------------------------]]
function GM:PlayerUse(ply)
  return ply:Alive() and not ply:IsSpectator() and ply:GetMoveType() == MOVETYPE_WALK
end

--[[---------------------------------------------------------
  Desc: Enables autohop
-----------------------------------------------------------]]
local band = bit.band
local no_jump = bit.bnot(IN_JUMP)
local no_autohop = {}
local function AutoHop(ply, data)
  if ply:IsBot() or no_autohop[ply] then return end
  if band(data:GetButtons(), 2) > 0 and not ply:IsOnGround() and ply:WaterLevel() < 2 and ply:GetMoveType() ~= 9 then
    data:SetButtons(band(data:GetButtons(), no_jump))
  end
end
hook.Add("SetupMove", "DoAutoHop", AutoHop)

--[[---------------------------------------------------------
  Desc: Ensures the basic skill movement
-----------------------------------------------------------]]
local Movement = config.Movement
local Clamp, FrameTime = math.Clamp, FrameTime
local aa, mv = Movement.Acceleration, Movement.Strafe
local css_gain = config.Vars.Get("Player_CSSGain")
function GM:Move(ply, data)
  if ply:IsOnGround() or not ply:Alive() or ply:IsBot() then return end

  local aim = data:GetMoveAngles()
  local forward, right = aim:Forward(), aim:Right()
  local fmove = data:GetForwardSpeed()
  local smove = data:GetSideSpeed()

  if data:KeyDown(1024) then smove = smove + 500 end
  if data:KeyDown(512) then smove = smove - 500 end

  forward.z, right.z = 0,0
  forward:Normalize()
  right:Normalize()

  local vel = data:GetVelocity()
  local wishvel = forward * fmove + right * smove
  wishvel.z = 0

  local wishspeed = wishvel:Length()
  if wishspeed > data:GetMaxSpeed() then
    wishvel = wishvel * (data:GetMaxSpeed() / wishspeed)
    wishspeed = data:GetMaxSpeed()
  end

  local wishspd = wishspeed
  if css_gain then
    wishspd = Clamp(wishspd, 0, mv + (Clamp(vel:Length2D() - 500, 0, 500) / 1000) * 1.4)
  else
    wishspd = Clamp(wishspd, 0, mv)
  end

  local wishdir = wishvel:GetNormal()
  local current = vel:Dot(wishdir)

  local addspeed = wishspd - current
  if addspeed <= 0 then return end

  local accelspeed = aa * FrameTime() * wishspeed
  if accelspeed > addspeed then
    accelspeed = addspeed
  end

  vel = vel + (wishdir * accelspeed)
  data:SetVelocity(vel)

  return false
end

--[[---------------------------------------------------------
  Desc: Change player movement or restrict it
-----------------------------------------------------------]]
local css_duck = config.Vars.Get("Player_CSSDuck")
local ducked, ground, duck_set = {}, {}, {}
local top_velocity, average_total, average_count, jumps = {}, {}, {}, {}
local HullMin, HullMax, HullStand = Movement.HullMin, Movement.HullMax, Movement.HullStand
local CLIENT, LocalPlayer, MASK_PLAYERSOLID = CLIENT, LocalPlayer, MASK_PLAYERSOLID
local function ChangeMove(ply, data)
  if ply:IsBot() then return end
  if not ply:IsOnGround() then
    if not ducked[ply] then
      ground[ply] = 0
      duck_set[ply] = nil
      ducked[ply] = true

      ply:SetDuckSpeed(0)
      ply:SetUnDuckSpeed(0)

      if css_duck then
        ply:SetHull(HullMin, HullStand)
      end
    end

    -- TODO: Do this differently
    local st = 0 --ply.Style
    if st > 1 and st < 8 and not ply.Freestyle and ply:GetMoveType() ~= 8 then
      if st == 2 or st == 4 or st == 7 then
        data:SetSideSpeed(0)

        if st == 4 and data:GetForwardSpeed() < 0 then
          data:SetForwardSpeed(0)
        elseif st == 7 and data:GetForwardSpeed() > 0 then
          data:SetForwardSpeed(0)
        end
      elseif st == 5 then
        data:SetForwardSpeed(0)

        if data:GetSideSpeed() > 0 then
          data:SetSideSpeed(0)
        end
      elseif st == 6 then
        data:SetForwardSpeed(0)

        if data:GetSideSpeed() < 0 then
          data:SetSideSpeed(0)
        end
      elseif st == 3 then
        -- TODO: ooo
        -- if ib and ba( data:GetButtons(), 16 ) > 0 then
        -- 	local bd = data:GetButtons()
        -- 	if ba( bd, 512 ) > 0 or ba( bd, 1024 ) > 0 then
        -- 		data:SetForwardSpeed( 0 )
        -- 		data:SetSideSpeed( 0 )
        -- 	end
        -- end
        --
        -- if data:GetForwardSpeed() == 0 or data:GetSideSpeed() == 0 then
        -- 	data:SetForwardSpeed( 0 )
        -- 	data:SetSideSpeed( 0 )
        -- end
      end
    end

    -- TODO: Low gravity
    -- if CLIENT and ply.Gravity != nil then
    -- 	if ply.Gravity or ply.Freestyle then
    -- 		ply:SetGravity( 0 )
    -- 	else
    -- 		ply:SetGravity( plg )
    -- 	end
    -- end

    local v = data:GetVelocity():Length2D()
    if v > top_velocity[ply] then
      top_velocity[ply] = v
    end

    average_total[ply] = average_total[ply] + v
    average_count[ply] = average_count[ply] + 1
  else
    local st = 0 -- ply.Style
    if ground[ply] > 12 then
      if not duck_set[ply] then
        if st == 9 then
          -- TODO: scrollll
          ply:SetJumpPower( _C.Player.JumpPower )
        end

        ply:SetDuckSpeed(PLAYER.DuckSpeed)
        ply:SetUnDuckSpeed(PLAYER.UnDuckSpeed)

        if css_duck and not util.TraceLine({ filter = ply, mask = MASK_PLAYERSOLID, start = ply:EyePos(), endpos = ply:EyePos() + Vector(0, 0, 24) }).Hit then
          ply:SetHull(HullMin, HullMax)
        end

        duck_set[ply] = true
      end
    else
      ground[ply] = ground[ply] + 1

      if ground[ply] == 1 then
        ducked[ply] = nil

        if st == 9 then
          ply:SetJumpPower( _C.Player.ScrollPower )
        end

        if jumps[ply] then
          jumps[ply] = jumps[ply] + 1
        end
      elseif ground[ply] > 1 and data:KeyDown(2) and not no_autohop[ply] then
        if CLIENT and ground[ply] < 4 then return end

        local vel = data:GetVelocity()
        vel.z = ply:GetJumpPower()

        ply:SetDuckSpeed(0)
        ply:SetUnDuckSpeed(0)
        ground[ply] = 0

        data:SetVelocity(vel)
      end
    end
  end
end
hook.Add("SetupMove", "ChangeMove", ChangeMove)

-- Override non-important movement functions
local MainStand, IdleActivity = ACT_MP_STAND_IDLE, ACT_HL2MP_IDLE
function GM:CalcMainActivity() return MainStand, -1 end
function GM:TranslateActivity() return IdleActivity end
function GM:CreateMove() end
function GM:SetupMove() end
function GM:FinishMove() end

-- View calculation references
local IsValid, Vector, TraceLine, min = IsValid, Vector, util.TraceLine, math.min
local HullDuck = Movement.HullDuck
local ViewDuck, ViewStand, ViewBase, ViewDiff = Movement.ViewDuck, Movement.ViewStand, Movement.ViewBase, Movement.ViewDiff
local TraceData, ActiveTrace, ViewOffset, ViewOffsetDuck, ViewTwitch = {}, {}, {}, {}, {}

--[[---------------------------------------------------------
  Desc: Executes a trace on the player to see
        what their roof status is
-----------------------------------------------------------]]
local function ExecuteTrace(ply)
  local crouched = ply:Crouching()
  local maxs = crouched and HullDuck or HullStand
  local view = crouched and ViewDuck or ViewStand

  local s = ply:GetPos()
  s.z = s.z + maxs.z

  TraceData[ply].start = s

  local e = Vector(s.x, s.y, s.z)
  e.z = e.z + (12 - maxs.z)
  e.z = e.z + view.z
  TraceData[ply].endpos = e

  local fraction = TraceLine(TraceData[ply]).Fraction
  if fraction < 1 then
    local est = s.z + fraction * (e.z - s.z) - ply:GetPos().z - 12
    if not crouched then
      local offset = ply:GetViewOffset()
      offset.z = est
      return offset, nil
    else
      local offset = ply:GetViewOffsetDucked()
      offset.z = min(offset.z, est)
      return nil, offset
    end
  else
    return nil, nil
  end
end

--[[---------------------------------------------------------
  Desc: Updates view offset on players for
        smooth play when crouching
-----------------------------------------------------------]]
local function InstallView(ply)
  if not IsValid(ply) then return end

  if ActiveTrace[ply] then
    local normal, duck = ExecuteTrace(ply)
    if normal ~= nil or duck ~= nil then
      ViewOffset[ply] = normal
      ViewOffsetDuck[ply] = duck
    else
      ActiveTrace[ply] = nil
      ViewOffset[ply] = nil
      ViewOffsetDuck[ply] = nil
    end
  end

  ply:SetViewOffset((ViewOffset[ply] or ViewStand) + ViewDiff)

  -- TODO: Actually implement ViewTwitch
  if ViewTwitch[ply] then
    ply:SetViewOffsetDucked(ViewOffsetDuck[ply] or ViewDuck)
  else
    if duck_set[ply] then
      ply:SetViewOffsetDucked(ViewOffsetDuck[ply] or ViewDuck)
    else
      ply:SetViewOffsetDucked((ViewOffsetDuck[ply] or ViewDuck) + ViewDiff)
    end
  end
end
hook.Add("Move", "InstallView", InstallView)

--[[---------------------------------------------------------
  Desc: Trace players and cache their view settings
-----------------------------------------------------------]]
local players
local function ExecuteTraces()
  players = players or player.GetAll()

  for i = 1, #players do
    local ply = players[i]
    if IsValid(ply) then
      if not TraceData[ply] then TraceData[ply] = { filter = ply, mask = MASK_PLAYERSOLID } end
      if not ActiveTrace[ply] then
        local normal, ducked = ExecuteTrace(ply)
        if normal ~= nil or ducked ~= nil then
          ActiveTrace[ply] = true
          ViewOffset[ply] = normal
          ViewOffsetDuck[ply] = ducked
        else
          ViewOffset[ply] = nil
          ViewOffsetDuck[ply] = nil
        end
      end
    end
  end
end
timer.Create("TracePlayerViews", 0.5, 0, ExecuteTraces)

--[[---------------------------------------------------------
  Desc: Sets a few player indexed tables initial values
-----------------------------------------------------------]]
local function SetInitialValues(ply)
  players = CLIENT and { ply }
  ground[ply] = 0
  top_velocity[ply] = 0
  average_total[ply] = 0
  average_count[ply] = 0
end
hook.Add("PlayerInitialSpawn", "SetInitialValues", SetInitialValues)

-- Acknowledge complete load
return 0
