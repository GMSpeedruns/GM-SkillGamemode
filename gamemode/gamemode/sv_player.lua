local player = {}
player.ValidationDelay = 5
player.Validations = {}

local styles = {}
local modes = {}

-- Add network identifiers
util.AddNetworkString("Validation")

-- Metatables
local PLAYER_META = FindMetaTable("Player")

-- Modules
local lang = GM.Language
local config = GM.Config
local database = GM.Database
local zones = GM.Zones

-- Functions
local SetPlayerClass = player_manager.SetPlayerClass
local HookRun = hook.Run

-- Variables
local MovementData = config.Movement
local PlayerBase = baseclass.Get(MovementData.Class)
local GamemodeBase = baseclass.Get("gamemode_base")

-- Constants
local MOVETYPE_WALK = MOVETYPE_WALK

-- Add text
lang.Add({
  ServerError = "Server encountered an error",
  PlayerConfigError = "Couldn't send player the server config"
})

--[[---------------------------------------------------------
  Desc: Loads and compresses data for the player
-----------------------------------------------------------]]
function player.Initialize()
  if not player.ConfigPayload then
    local data = config.Vars.Serialize()
    player.ConfigPayload = util.Compress(data)
    player.ConfigPayloadCRC = util.CRC(player.ConfigPayload)
    player.ConfigPayloadLength = #player.ConfigPayload
  end
end
hook.Add("Initialize", "InitializePlayer", player.Initialize)

--[[---------------------------------------------------------
  Desc: Saves player connection
-----------------------------------------------------------]]
function player.RegisterJoin(ply)
  -- Store a connection time variable
  ply.JoinTime = os.time()

  -- Update their data right away
  local query = database:Prepare("SELECT * FROM players WHERE steamid = ?", { ply:SteamID() })
  query:execute(function(data)
    if #data > 0 then
      database:Prepare("UPDATE players SET connections = connections + 1, last_seen = ? WHERE steamid = ?", { ply.JoinTime, ply:SteamID() }):execute()
    else
      database:Prepare("INSERT INTO players (steamid, connections, playtime, last_seen) VALUES (?, ?, ?, ?)", { ply:SteamID(), 1, 0, ply.JoinTime }):execute()
    end
  end)
end

--[[---------------------------------------------------------
  Desc: Saves player playtime
-----------------------------------------------------------]]
function player.RegisterLeave(ply)
  local time = os.time()
  local gained = time - ply.JoinTime
  database:Prepare("UPDATE players SET playtime = playtime + ?, last_seen = ? WHERE steamid = ?", { gained, time, ply:SteamID() }):execute()
end

--[[---------------------------------------------------------
  Desc: Changes the player's style
-----------------------------------------------------------]]
function PLAYER_META:SetStyle(style)
  styles[self] = style
end

--[[---------------------------------------------------------
  Desc: Changes the player's mode
-----------------------------------------------------------]]
function PLAYER_META:SetMode(mode)
  modes[self] = mode
end

--[[---------------------------------------------------------
  Desc: Resets the player to the spawn
-----------------------------------------------------------]]
function PLAYER_META:ResetToSpawn()
  -- Stop the player from moving
  self:SetLocalVelocity(Vector(0, 0, 0))
  self:SetJumpPower(MovementData.JumpPower)

	if self:GetMoveType() ~= MOVETYPE_WALK then
		self:SetMoveType(MOVETYPE_WALK)
  end
  
  zones:MovePlayerToSpawn(self)
end

--[[---------------------------------------------------------
  Desc: Fully resets the player
  Notes: This function overrides the base gamemode spawn
-----------------------------------------------------------]]
function GM:PlayerSpawn(ply)
  -- Inherit data from the player class
  SetPlayerClass(ply, MovementData.Class)
  GamemodeBase:PlayerSpawn(ply)

  -- Spawn the player on the first spot and set variables
  if not ply:IsBot() then
    -- Set normal movement settings for the player
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetJumpPower(MovementData.JumpPower)
    ply:SetStepSize(MovementData.StepSize)

    -- Move the player to the spawn
    ply:ResetToSpawn()

    -- TODO: Further player spawning
  end

  -- Preferably do this in Bot extension
  -- Handle bot spawning
  -- TODO: Bot spawn
end

--[[---------------------------------------------------------
  Desc: Makes the player ready for play
-----------------------------------------------------------]]
function GM:PlayerInitialSpawn(ply)
  -- Set default settings
  ply:DrawShadow(false)
  ply:SetAvoidPlayers(false)
  ply:SetNoCollideWithTeammates(true)
  ply:SetTeam(PlayerBase.PlayerTeam)
  ply:SetHull(MovementData.HullMin, MovementData.HullStand)
  ply:SetHullDuck(MovementData.HullMin, MovementData.HullDuck)

  -- Setup normal player
  if not ply:IsBot() then
    -- Send config to the player
    if player.ConfigPayload then
      net.Start("Validation")
      net.WriteString(player.ConfigPayloadCRC)
      net.WriteUInt(player.ConfigPayloadLength, 32)
      net.WriteData(player.ConfigPayload, player.ConfigPayloadLength)
      net.Send(ply)
    else
      error(lang.Get("PlayerConfigError"))
      return ply:Kick(lang.Get("ServerError"))
    end

    -- Update player statistics
    player.RegisterJoin(ply)
  end
end

--[[---------------------------------------------------------
  Desc: Handles a disconnected player
-----------------------------------------------------------]]
function GM:PlayerDisconnected(ply)
  player.RegisterLeave(ply)
end

-- Store reference
GM.Player = player
