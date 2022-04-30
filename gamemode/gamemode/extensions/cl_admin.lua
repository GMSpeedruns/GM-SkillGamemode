local admin = {}

-- Get shared data
local shared = include("sh_admin.lua")
for name, data in pairs(shared) do
  admin[name] = data
end

-- Modules
local gui = GM.GUI
local helpers = GM.Helpers

-- Variables
local actions = {}
local context = {}

local net = net
local IN_DUCK = IN_DUCK
local Angle, Vector, Color, LocalPlayer = Angle, Vector, Color, LocalPlayer
local DrawWireframeBox, SetMaterial = render.DrawWireframeBox, render.SetMaterial
local SnapVector, MinMaxVector = helpers.SnapVector, helpers.MinMaxVector
local DrawMaterial = Material("sprites/tp_beam001")

--[[---------------------------------------------------------
	Desc: Acknowledges validity for hooks
-----------------------------------------------------------]]
function admin:IsValid()
  return true
end

--[[---------------------------------------------------------
	Desc: Shorthand function for sending data to server
-----------------------------------------------------------]]
function admin.Send(action, step, rest)
  net.Start("Admin")
  net.WriteString(action)
  net.WriteUInt(step, 4)
  if rest then rest() end
  net.SendToServer()
end

--[[---------------------------------------------------------
	Desc: Handles zone adding
-----------------------------------------------------------]]
function actions.ZonesAdd(action, step)
  local window = gui:Get("admin")
  local sheet = window.frame.Sheet

  if step == 0 then
    local zones = net.ReadTable()
    if not sheet.Step then
      local w, h = sheet.Admin:GetSize()
      sheet.Step = vgui.Create("DPanel", sheet.Admin)
      sheet.Step:SetPos(w / 2, 0)
      sheet.Step:SetSize(w / 2, h)
    end

    local panel = sheet.Step
    table.sort(zones)

    local lbl = window:CreateLabel{ parent = panel, x = 10, y = 10, text = "Choose zone type, then start moving" }
    local types = window:CreateCombo{ parent = panel, x = 10, y = 30, text = "Select a zone type..." }

    for i = 1, #zones do
      types:AddChoice(string.gsub(zones[i], "_", " "))
    end

    function types:OnSelect(index, value)
      admin.Send(action, 1, function()
        net.WriteString(value)
      end)
    end
  elseif step == 1 then
    if context.Label then context.Label:Remove() end
    if context.Button then context.Button:Remove() end

    context = net.ReadTable()
    context.Label = window:CreateLabel{ parent = sheet.Step, x = 10, y = 60, text = "" }
    function context.Label:UpdateText()
      self:SetText("Type: " .. context.Type .. "\n" .. "Min: " .. string.gsub(tostring(context.Min), ".000000", "") .. "\nMax: " .. string.gsub(tostring(context.Max), ".000000", ""))
    end

    context.Button = window:CreateButton{ parent = sheet.Step, x = 10, y = 120, text = "Finish", click = function()
      hook.Remove("PostDrawTranslucentRenderables", admin)
      admin.Send(action, 2)
    end }

    window:CreateButton{ parent = sheet.Step, x = 10 + context.Button:GetWide() + 10, y = 120, text = "Cancel", click = function()
      context = {}
      sheet.Step:Remove()
      sheet.Step = nil
    end }

    hook.Add("PostDrawTranslucentRenderables", admin, admin.PreviewZone)
    window:Close()
  elseif step == 2 then
    local result = net.ReadBool()
    sheet.Step:Remove()
    sheet.Step = nil

    -- TODO: Print a fail message here
  end
end

--[[---------------------------------------------------------
	Desc: Receive data on the Admin message
-----------------------------------------------------------]]
function admin.Receive(len)
  local action = net.ReadString()
  if actions[action] then
    actions[action](action, net.ReadUInt(4))
  end
end
net.Receive("Admin", admin.Receive)

--[[---------------------------------------------------------
	Desc: Builds the admin menu
-----------------------------------------------------------]]
function admin:Build()
  self.args = table.Merge(self.args, {
    Keep = true
  })

  local sheet = self.frame.Sheet
  local tab = vgui.Create("DPanel", sheet)
  tab.Paint = gui.EmptyPaint
  sheet:AddSheet("Admin", tab, "icon16/report_user.png")
  sheet.Admin = tab

  local prev = sheet.Items[#sheet.Items - 1]
  sheet.Items[#sheet.Items].Tab:SetColor(prev.Tab:GetTextColor())
  sheet.Items[#sheet.Items].Tab.Paint = gui.EmptyPaint

  local explanation = self:CreateLabel{ parent = tab, x = 10, y = 10, text = "Select a player below" }
  local players = self:CreateCombo{ parent = tab, x = 10, y = 30, text = "Select player..." }

  for _, ply in pairs(player.GetHumans()) do
    players:AddChoice(ply:Name() .. " (" .. ply:SteamID() .. ")", ply:SteamID())
  end

  function players:OnSelect(index, value)
    print("Steam ID for", value, "is", self:GetOptionData(index))
  end

  local x, y = 10, 70
  local roles = self.args[1]
  for role, items in pairs(admin.Actions) do
    if bit.band(roles, admin.Roles[role]) > 0 then
      local role_label = self:CreateLabel{ parent = tab, x = x, y = y, text = role }
      local actions = self:CreateCombo{ parent = tab, x = x, y = y + 20, text = "Select action..." }
      actions:SetSortItems(false)

      for i = 1, #items do
        actions:AddChoice(items[i], role)
      end

      function actions:OnSelect(index, value)
        admin.Send(self:GetOptionData(index) .. value, 0)
      end

      y = x ~= 10 and y + 50 or y
      x = x == 10 and 150 or 10
    end
  end
end
gui:Extend("menu", "admin", admin.Build)

--[[---------------------------------------------------------
	Desc: Draws a preview zone
-----------------------------------------------------------]]
function admin:PreviewZone()
	if context.Start then
    local size = LocalPlayer():KeyDown(IN_DUCK) and 16 or 32
    local start = SnapVector(context.Start, size)
    local stop = SnapVector(LocalPlayer():GetPos(), size)
    context.Min, context.Max = MinMaxVector(start, stop)
    context.Max.z = context.Max.z + context.Height
    context.Label:UpdateText()

    SetMaterial(DrawMaterial)
    DrawWireframeBox(context.Min, Angle(0, 0, 0), Vector(0, 0, 0), context.Max - context.Min, Color(255, 255, 255))
  else
    hook.Remove("PostDrawTranslucentRenderables", admin)
	end
end
