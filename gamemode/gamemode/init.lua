-- For benchmarking gamemode load time
local start = SysTime()

-- Add clientside files for download
AddCSLuaFile("sh_helpers.lua")
AddCSLuaFile("sh_storage.lua")
AddCSLuaFile("sh_config.lua")
AddCSLuaFile("sh_language.lua")
AddCSLuaFile("sh_core.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_gui.lua")
AddCSLuaFile("cl_network.lua")
AddCSLuaFile("cl_timer.lua")

-- Config variables
GM.PresetVars = {
  { "Player_WalkSpeed", 260, "The walk speed of a player without weapons", true },
  { "Player_SpawnWeapons", true, "Whether or not to spawn players with weapons", true },
  { "Player_CSSJumps", true, "Whether or not to use CS:S jump height", true },
  { "Player_CSSDuck", true, "Whether or not to use CS:S ducking", true },
  { "Player_CSSGain", true, "Whether or not to use CS:S gain", true }
}

-- Ensure certain ConVars
RunConsoleCommand("fps_max", "0")
RunConsoleCommand("mp_falldamage", "0")
RunConsoleCommand("sv_gravity", "800")
RunConsoleCommand("sv_sticktoground", "0")
RunConsoleCommand("sv_stopspeed", "75")
RunConsoleCommand("sv_friction", "4")
RunConsoleCommand("sv_accelerate", "5")
RunConsoleCommand("sv_airaccelerate", "0")
RunConsoleCommand("sv_maxvelocity", "3500")
RunConsoleCommand("sv_turbophysics", "1")

-- Attempt to load the gamemode core
local error_code = include("sh_core.lua")
if error_code ~= 0 then
  return print("Could not load gamemode core. Stopped loading serverside", "Error: " .. error_code)
end

-- Load serverside files
include("sv_database.lua")
include("sv_network.lua")
include("sv_commands.lua")
include("sv_records.lua")
include("sv_timer.lua")
include("sv_zones.lua")
include("sv_player.lua")

-- Include extensions and maps
include("extensions/init.lua")
include("maps/init.lua")

-- Add resources
local content_dir = "gamemodes/" .. GM.Config.Server.Type .. "/content"
local resources = GM.Helpers.RecursiveFind(content_dir, "*", "GAME")
for i = 1, #resources do
  resource.AddFile(string.sub(resources[i], string.len(content_dir) + 2))
end

-- Remove useless hooks
local function SetupPostEntity()
  hook.Remove("PlayerTick", "TickWidgets")
  hook.Remove("PreDrawHalos", "PropertiesHover")
end
hook.Add("InitPostEntity", "SetupPostEntity", SetupPostEntity)

--[[---------------------------------------------------------
  Desc: Collection of functions that we want to
        return a fixed value
  Notes: These override the base gamemode defaults
-----------------------------------------------------------]]
function GM:CanPlayerSuicide() return false end
function GM:PlayerShouldTakeDamage() return false end
function GM:GetFallDamage() return false end
function GM:PlayerCanHearPlayersVoice() return true end
function GM:IsSpawnpointSuitable() return true end
function GM:PlayerDeathThink() end
function GM:PlayerSetModel() end

--[[---------------------------------------------------------
  Desc: Makes sure stripped players can't do anything
        as well as to avoid weapon pickup lag
  Notes: Override base gamemode
-----------------------------------------------------------]]
local config = GM.Config.Server
function GM:PlayerCanPickupWeapon(ply, weapon)
  -- TODO: Limit weapons for surf

  if ply.WeaponStripped or ply.WeaponPickupProhibit then return false end
  if ply:HasWeapon(weapon:GetClass()) then return false end
  if ply:IsBot() then return false end

  -- For Bunny Hop we'll want to stock up their ammo to the max
  if config.Bhop then
    timer.Simple(0.1, function()
      if IsValid(ply) and IsValid(weapon) then
        ply:SetAmmo(999, weapon:GetPrimaryAmmoType())
      end
    end)
  end

  return true
end

--[[---------------------------------------------------------
  Desc: Ensures players can't take damage
  Notes: Override base gamemode
-----------------------------------------------------------]]
function GM:EntityTakeDamage(ent, dmg)
  if ent:IsPlayer() then return false end
  return BaseClass:EntityTakeDamage(ent, dmg)
end

-- Start the database
GM.Database:Start()

-- Notify console
GM.Language.Console("GamemodeLoaded", (SysTime() - start) * 1000)

-- Clear out global references
local modules = { "Helpers", "Storage", "Config", "Language", "Database", "Zones", "Timer", "Player" }
for i = 1, #modules do
  GM[modules[i]] = nil
end
