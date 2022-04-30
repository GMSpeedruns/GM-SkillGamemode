local commands = {}
commands.Separator = " "

-- Container for all command functions
local cmd = {}

-- Functions
local sub, lower, find, explode = string.sub, string.lower, string.find, string.Explode
local next = next


--[[---------------------------------------------------------
  Desc: Checks if the message contains a command
  Notes: Overrides the base gamemode hook
         so we can easily cancel out the message
-----------------------------------------------------------]]
function GM:PlayerSay(ply, text)
  local prefix = sub(text, 1, 1)
  local command = "invalid"

  if prefix ~= "!" and prefix ~= "/" then
    -- TODO: Filter text here
    return text
  else
    command = lower(sub(text, 2))

    if command == "" then
      return ""
    end
  end

  local result = commands.Run(ply, command, text)
  if not result or type(result) ~= "string" then
    return ""
  else
    return result
  end
end

--[[---------------------------------------------------------
  Desc: Called when the player presses F1
-----------------------------------------------------------]]
function GM:ShowHelp(ply)
  ply:OpenGUI("menu")
end

--[[---------------------------------------------------------
  Desc: Called when the player presses F2
-----------------------------------------------------------]]
function GM:ShowTeam(ply)
end

--[[---------------------------------------------------------
  Desc: Called when the player presses F3
-----------------------------------------------------------]]
function GM:ShowSpare1(ply)
end

--[[---------------------------------------------------------
  Desc: Called when the player presses F4
-----------------------------------------------------------]]
function GM:ShowSpare2(ply)
end



--[[---------------------------------------------------------
  Desc: Register a command
-----------------------------------------------------------]]
function commands.Add(func, ...)
  -- TODO: Actually add a function to cmd
end

--[[---------------------------------------------------------
  Desc: Aliases a registered command
-----------------------------------------------------------]]
function commands.Alias(identifier, ...)
  local aliases = { ... }
  for command in next, cmd do
    if command == identifier then
      for i = 1, #aliases do
        cmd[aliases[i]] = cmd[command]
      end

      break
    end
  end
end

--[[---------------------------------------------------------
  Desc: Runs a player command
-----------------------------------------------------------]]
function commands.Run(ply, command, text)
  local args_lower, args_upper = {}, {}

  -- Parse the arguments
  if find(command, commands.Separator, 1, true) then
    local split_lower = explode(commands.Separator, command)
    local split_upper = explode(commands.Separator, text)
    command = split_lower[1]

    for i = 2, #splitLower do
      args_lower[#args_lower + 1] = split_lower[i]
      args_upper[#args_upper + 1] = split_upper[i]
    end
  end

  -- Default to the invalid command
  local base_command = command
  if not cmd[command] then
    command = "invalid"
  end

  -- Take lowercased args as the default
  local args = args_lower
  args.Command = base_command
  args.FullArgs = args_upper
  args.FullText = text

  return cmd[command](ply, args)
end

--[[---------------------------------------------------------
  Desc: The default command, lets the player know their attempt failed
-----------------------------------------------------------]]
function cmd.invalid(ply, args)
  ply:Print("CommandInvalid", args.Command)
end

--[[---------------------------------------------------------
  Desc: Resets the player to the start
-----------------------------------------------------------]]
function cmd.restart(ply)
  if ply:IsSpectator() then
    ply:Print("SpectatingRestart")
  else
    -- TODO: Expand
    ply:Spawn()
  end
end
commands.Alias("restart", "r", "respawn", "kill", "start")

--[[---------------------------------------------------------
  Desc: Toggles spectator mode on the player
-----------------------------------------------------------]]
function cmd.spectate(ply)
  if ply:IsSpectator() then
    -- TODO: Move out of spectator
  else
    -- Change to spectator here
  end
end
commands.Alias("spectate", "spec", "watch")

--[[---------------------------------------------------------
  Desc: Removes weapons from a player
-----------------------------------------------------------]]
function cmd.stripweapons(ply)
  if ply:IsSpectator() then
    ply:Print("SpectatingWeapon")
  else
    ply:StripWeapons()
  end
end
commands.Alias("stripweapons", "strip", "remove")

--[[---------------------------------------------------------
  Desc: Changes the active map safely
-----------------------------------------------------------]]
local function OnChangeMap(ply, cmd, args)
  if IsValid(ply) or ply:IsPlayer() then return end
  if #args ~= 1 then return end

  for _, ply in pairs(player.GetHumans()) do
    GAMEMODE:PlayerDisconnected(ply)
  end

  RunConsoleCommand("changelevel", args[1])
end
concommand.Add("changemap", OnChangeMap)

--[[---------------------------------------------------------
  Desc: Reloads the server
-----------------------------------------------------------]]
local function OnReloadServer(ply, cmd, args)
  if IsValid(ply) or ply:IsPlayer() then return end
  local map = #args > 0 and args[1] or game.GetMap()
  RunConsoleCommand("changemap", map)
end
concommand.Add("rs", OnReloadServer)
