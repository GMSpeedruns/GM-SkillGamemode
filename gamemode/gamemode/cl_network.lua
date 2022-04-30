-- Metatables
local ENTITY_META = FindMetaTable("Entity")

-- Modules
local lang = GM.Language
local gui = GM.GUI

-- Variables
local net = net

--[[---------------------------------------------------------
  Desc: Gets a networked variable
-----------------------------------------------------------]]
function ENTITY_META:Var(action, ...)
  --return f[ action ]( self, ... )
end

--[[---------------------------------------------------------
  Desc: Receives print data
-----------------------------------------------------------]]
local function OnPrint()
  local id = net.ReadUInt(32)
  local args = net.ReadBit() == 1 and net.ReadTable()
  local key = lang.GetKeyByID(id)

  if key then
    lang.Print(key, unpack(args))
  end
end
net.Receive("Language", OnPrint)

--[[---------------------------------------------------------
  Desc: Receives GUI data
-----------------------------------------------------------]]
local function OnOpenGUI()
  gui:Create(net.ReadString(), net.ReadTable())
end
net.Receive("GUI", OnOpenGUI)
