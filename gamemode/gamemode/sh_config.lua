-- Setup a table for our configuration
local Config = {}

-- Modules
local storage = GM.Storage

-- Server-specific settings
Config.Server = {}
Config.Server.Type = storage:Config("Server_Type", "set this to bhop or surf")
Config.Server.Host = storage:Config("Server_Host", "Gamemode Host Name")
Config.Server.Website = storage:Config("Server_Website", "http://www.gamemode.host/")

-- Resolve gamemode category name
Config.Server.Name = ({ bhop = "Bunny Hop", surf = "Skill Surf" })[Config.Server.Type]
Config.Server.Title = storage:Config("Server_Title", Config.Server.Name)

-- Validate the given type
if not Config.Server.Name then
  return error("Invalid gamemode type specified")
else
  local id = string.upper(Config.Server.Type[1]) .. string.sub(Config.Server.Type, 2)
  Config.Server[id] = true
end

-- Wrapper for vars
local Vars = {}
Vars.Data = {}
Vars.Descriptions = {}
Vars.Shared = { "Server_Type", "Server_Host", "Server_Website" }

--[[---------------------------------------------------------
  Desc: Handles var command
-----------------------------------------------------------]]
function Vars.Command(ply, cmd, args)
  if IsValid(ply) then return end

  -- TODO: Change this
  if #args > 0 then
    if tonumber(args[1]) then
      args[1] = tonumber(args[1])
    end

    if storage:Set(cmd, args[1]) then
      print("Variable set")
    else
      print("Failed to set variable")
    end
  else
    print("Var", cmd)
    print("Description", Vars.Descriptions[cmd])
    print("Value", storage:Config(cmd))
  end
end

--[[---------------------------------------------------------
  Desc: Sets a config variable
-----------------------------------------------------------]]
function Vars.Set(name, default, description, shared)
  Vars.Data[name] = storage:Config(name, default)
  Vars.Descriptions[name] = description

  if shared then
    Vars.Shared[#Vars.Shared + 1] = name
  end

  concommand.Add(name, Vars.Command, nil, description)
end

--[[---------------------------------------------------------
  Desc: Gets a config variable
-----------------------------------------------------------]]
function Vars.Get(name, default)
  if default then
    return storage:Config(name, default)
  else
    return storage:Get(name)
  end
end

--[[---------------------------------------------------------
  Desc: Serializes vars table
-----------------------------------------------------------]]
function Vars.Serialize()
  local tab = {}
  for i = 1, #Vars.Shared do
    storage:AddSharedToTable(tab, Vars.Shared[i])
  end
  return util.TableToJSON(tab)
end

-- Register presets
if GM.PresetVars then
  for i = 1, #GM.PresetVars do
    Vars.Set(unpack(GM.PresetVars[i]))
  end
end

-- Add to Vars to the Config table
Config.Vars = Vars

-- Movement settings
Config.Movement = {
  Class = "player_move",
  StepSize = 18,
  JumpPower = Vars.Get("Player_CSSJumps") and math.sqrt(2 * 800 * 57.81) or 290,
  Acceleration = Config.Server.Bhop and (Vars.Get("Player_CSSGain") and 1200 or 500) or 120,
  Strafe = Vars.Get("Player_CSSGain") and 30 or 32.4,

  HullMin = Vector(-16, -16, 0),
  HullDuck = Vector(16, 16, 45),
  HullStand = Vector(16, 16, Vars.Get("Player_CSSDuck") and 54 or 62),
  HullMax = Vector(16, 16, 62),
  ViewDuck = Vector(0, 0, 47),
  ViewStand = Vector(0, 0, Vars.Get("Player_CSSDuck") and 56 or 64),
  ViewDiff = Vector(0, 0, Vars.Get("Player_CSSDuck") and 8 or 0),
  ViewBase = Vector(0, 0, 0)
}

-- Return to the including file
return Config
