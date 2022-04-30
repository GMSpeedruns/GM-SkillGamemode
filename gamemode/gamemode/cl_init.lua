-- For benchmarking gamemode load time
local start = SysTime()

-- Define upvalues
local error_code
local storage, updated
local max_fails, fails = 20, 0

--[[---------------------------------------------------------
  Desc: Handles validation info from the server
-----------------------------------------------------------]]
local function ReceiveValidation()
  local crc = net.ReadString()
  if error_code == 0 then
    if crc ~= storage.Hash then
      print("Old client version detected")

      local len = net.ReadUInt(32)
      local data = net.ReadData(len)
      file.Write(storage.File, data)
      updated = true
    else
      storage.Validated = true
    end
  else
    print("Received update from server")
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    file.Write(storage.File, data)
    updated = true
  end
end
net.Receive("Validation", ReceiveValidation)

--[[---------------------------------------------------------
  Desc: Validates storage
-----------------------------------------------------------]]
local function Validator()
  if storage.Validated then return end
  if updated then
    print("Applying updates")
    LocalPlayer():ConCommand("retry")
  elseif fails > max_fails then
    print("Failed to validate client")
    LocalPlayer():ConCommand("disconnect")
  else
    fails = fails + 1
  end

  timer.Simple(0.1, Validator)
end

--[[---------------------------------------------------------
  Desc: Called when the client is ready
-----------------------------------------------------------]]
local function ValidationReady()
  timer.Simple(0.1, Validator)
end
hook.Add("InitPostEntity", "ValidationReady", ValidationReady)

-- Attempt to load the gamemode core
error_code = include("sh_core.lua")
storage = GM.Storage

-- Check if there were any errors
if error_code ~= 0 then
  return print("Could not load gamemode core. Stopped loading clientside", "Error: " .. error_code)
end

-- Load clientside files
include("cl_timer.lua")
include("cl_gui.lua")
include("cl_network.lua")

-- Load extensions
local dir = GM.Config.Server.Type .. "/gamemode/extensions/"
local extensions = file.Find(dir .. "*.lua", "LUA")
for i = 1, #extensions do
  include(dir .. extensions[i])
end

-- Functions
local LocalPlayer, IsValid = LocalPlayer, IsValid

-- Variables
local Movement = GM.Config.Movement

--[[---------------------------------------------------------
  Desc: Initializes clientside entities
-----------------------------------------------------------]]
local function InitializeEntities()
  local ply = LocalPlayer()
  hook.Run("PlayerInitialSpawn", ply)

  ply.Style = 0 -- TODO: Remove?
  ply:SetViewOffset(Movement.ViewStand)
  ply:SetViewOffsetDucked(Movement.ViewDuck)

  hook.Remove("PlayerTick", "TickWidgets")
  hook.Remove("PreDrawHalos", "PropertiesHover")
  hook.Remove("PostDrawEffects", "RenderHalos")
end
hook.Add("InitPostEntity", "InitializeEntities", InitializeEntities)

--[[---------------------------------------------------------
  Desc: Runs checks that need to occur every 5 seconds
-----------------------------------------------------------]]
local function ClientTick()
  local ply = LocalPlayer()
  if not IsValid(ply) then return timer.Simple(1, ClientTick) end
  timer.Simple(5, ClientTick)

  ply:SetHull(Movement.HullMin, Movement.HullStand)
  ply:SetHullDuck(Movement.HullMin, Movement.HullDuck)
end
timer.Simple(1, ClientTick)

-- Destroy resource hogs
function GM:UpdateAnimation() end
function GM:GrabEarAnimation() end
function GM:MouthMoveAnimation() end
function GM:DoAnimationEvent() end
function GM:AdjustMouseSensitivity() end
function GM:CalcViewModelView() end
function GM:PreDrawViewModel() end
function GM:PostDrawViewModel() end

-- Notify console
GM.Language.Console("GamemodeLoaded", (SysTime() - start) * 1000)

-- Clear out global references
local modules = { "Helpers", "Storage", "Config", "Language", "GUI", "Timer" }
for i = 1, #modules do
  GM[modules[i]] = nil
end
