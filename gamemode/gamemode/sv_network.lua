local network = {}
network.Messages = {}

-- Add network identifiers
util.AddNetworkString("Language")
util.AddNetworkString("GUI")

-- Metatables
local ENTITY_META = FindMetaTable("Entity")
local PLAYER_META = FindMetaTable("Player")

-- Modules
local lang = GM.Language

-- Variables
local net = net

-- Add text
lang.Add({
  MissingTextID = "Couldn't find text for key: %s"
})

--[[---------------------------------------------------------
  Desc: Gets a networked variable
-----------------------------------------------------------]]
function ENTITY_META:Var(action, ...)
  -- return f[ action ]( self, ... )
  -- TODO: Research NetworkVar
end

--[[---------------------------------------------------------
  Desc: Prints something on the client
-----------------------------------------------------------]]
function PLAYER_META:Print(key, ...)
  local id = lang.GetIDByKey(key)
  if id then
    net.Start("Language")
    net.WriteUInt(id, 32)

    local args = { ... }
    net.WriteBit(#args > 0)

    if #args > 0 then
      net.WriteTable(args)
    end

    net.Send(self)
  else
    lang.Console("MissingTextID", key)
  end
end

--[[---------------------------------------------------------
  Desc: Opens a GUI on the client
-----------------------------------------------------------]]
function PLAYER_META:OpenGUI(identifier, ...)
  net.Start("GUI")
  net.WriteString(identifier)

  local args = { ... }
  net.WriteTable(args)
  net.Send(self)
end
