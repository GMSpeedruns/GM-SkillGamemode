local admin = {}
admin.Auth = {}

-- Get shared data
local shared = include("sh_admin.lua")
for name, data in pairs(shared) do
  admin[name] = data
end

-- Add network string
util.AddNetworkString("Admin")

-- Modules
local database = GM.Database
local lang = GM.Language
local zones = GM.Zones
local helpers = GM.Helpers

-- Variables
local actions = {}
local net = net

-- Add text
lang.Add({
  AdminInvalidParameters = "Expected %d parameters, got %d (Expected format: %s)",
  AdminInvalidSteamID = "Invalid Steam ID entered",
  AdminInvalidRoleLevel = "Invalid role entered",
  AdminUpdatedRole = "Changed roles of admin '%s' from %d to %d",
  AdminAddedWithRole = "Added new admin '%s' with roles: %d"
})

--[[---------------------------------------------------------
	Desc: Acknowledges validity for hooks
-----------------------------------------------------------]]
function admin:IsValid()
  return true
end

--[[---------------------------------------------------------
	Desc: Load zones from database and setup them up
-----------------------------------------------------------]]
function admin:Initialize()
  local field, mod = database.GetTableDescriptors()
  local custom = {
    ["admins"] = {
    	{ "steamid", field.STR, bit.bor(mod.PRIMARY, mod.NOTNULL) },
    	{ "roles", field.INT, mod.NOTNULL }
    },

    ["admin_logs"] = {
  		{ "id", field.INT, bit.bor(mod.PRIMARY, mod.INCREMENT, mod.NOTNULL) },
      { "steamid", field.STR, mod.NOTNULL },
  		{ "name", field.STR, mod.NONE },
  		{ "data", field.TXT, mod.NONE },
  		{ "date", field.DATE, mod.NONE }
  	},

    ["admin_reports"] = {
  		{ "id", field.INT, bit.bor(mod.PRIMARY, mod.INCREMENT, mod.NOTNULL) },
  		{ "type", field.INT, mod.NOTNULL },
  		{ "suspect", field.STR, mod.NONE },
  		{ "comment", field.TXT, mod.NONE },
  		{ "date", field.DATE, mod.NOTNULL },
  		{ "reporter", field.STR, mod.NOTNULL },
  		{ "handler", field.STR, mod.NONE },
  		{ "evidence", field.STR, mod.NONE }
  	}
  }

  database:Setup(custom)
end
hook.Add("OnDatabaseConnected", admin, admin.Initialize)

--[[---------------------------------------------------------
	Desc: Checks admin status of the player
-----------------------------------------------------------]]
function admin:LoadAuth(ply)
  local query = database:Prepare("SELECT * FROM admins WHERE steamid = ?", { ply:SteamID() })
  query:execute(function(data)
    if #data > 0 then
      ply.AdminRoles = data[1].roles
    end
  end)
end
hook.Add("PlayerInitialSpawn", admin, admin.LoadAuth)

--[[---------------------------------------------------------
	Desc: Sets admin status in the database and reloads
-----------------------------------------------------------]]
function admin:SetRole(steamid, roles)
  local query = database:Prepare("SELECT * FROM admins WHERE steamid = ?", { steamid })
  query:execute(function(data)
    if #data > 0 then
      database:Prepare("UPDATE admins SET roles = ? WHERE steamid = ?", { roles, steamid }):execute(function()
        lang.Console("AdminUpdatedRole", steamid, data[1].roles, roles)
      end)
    else
      database:Prepare("INSERT INTO admins (steamid, roles) VALUES (?, ?)", { steamid, roles }):execute(function()
        lang.Console("AdminAddedWithRole", steamid, roles)
      end)
    end
  end)
end

--[[---------------------------------------------------------
	Desc: Checks if user possesses a role
-----------------------------------------------------------]]
function admin:HasRole(ply, role)
  return bit.band(ply.AdminRoles or 0, self.Roles[role]) > 0
end

--[[---------------------------------------------------------
	Desc: Shorthand function for sending data to client
-----------------------------------------------------------]]
function admin.Send(ply, action, step, rest)
  net.Start("Admin")
  net.WriteString(action)
  net.WriteUInt(step, 4)
  if rest then rest() end
  net.Send(ply)
end

--[[---------------------------------------------------------
	Desc: Handles the zone add action
-----------------------------------------------------------]]
function actions.ZonesAdd(ply, action, step)
  if step == 0 then
    admin.Send(ply, action, step, function()
      net.WriteTable(zones.Types)
    end)
  elseif step == 1 then
    local zone = net.ReadString()
    local setup = zones:StartCreate(ply, zone)
    if setup then
      admin.Send(ply, action, step, function()
        net.WriteTable(setup)
      end)
    end
  elseif step == 2 then
    admin.Send(ply, action, step, function()
      net.WriteBool(zones:StopCreate(ply))
    end)
  end
end

--[[---------------------------------------------------------
  Desc: Handles a player admin message
-----------------------------------------------------------]]
function admin.Receive(len, ply)
  local action = net.ReadString()
  local pos = string.find(string.sub(action, 2), "%u")
  if pos then
    local role = string.sub(action, 1, pos)
    if admin:HasRole(ply, role) then
      if actions[action] then
        actions[action](ply, action, net.ReadUInt(4))
      end
    end
  end
end
net.Receive("Admin", admin.Receive)

--[[---------------------------------------------------------
  Desc: Console command to change admin role
-----------------------------------------------------------]]
local function OnSetAdmin(ply, cmd, args)
  if IsValid(ply) or ply:IsPlayer() then return end
  if #args ~= 2 then return lang.Console("AdminInvalidParameters", 2, #args, "setadmin [steamid: quoted string] [role: integer]") end
  if not helpers.IsValidSteamID(args[1]) then return lang.Console("AdminInvalidSteamID") end
  if not tonumber(args[2]) then return lang.Console("AdminInvalidRoleLevel") end

  admin:SetRole(args[1], tonumber(args[2]))
end
concommand.Add("setadmin", OnSetAdmin)

--[[---------------------------------------------------------
	Desc: Called when the player presses F1
  Overrides: Commands ShowHelp function
-----------------------------------------------------------]]
function GM:ShowHelp(ply)
  if ply.AdminRoles and ply.AdminRoles > 0 then
    ply:OpenGUI("admin", ply.AdminRoles)
  else
    ply:OpenGUI("menu")
  end
end
