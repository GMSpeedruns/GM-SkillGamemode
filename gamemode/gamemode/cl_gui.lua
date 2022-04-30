local global_gui = gui
global_gui.__index = global_gui

local gui = {}
setmetatable(gui, global_gui)

gui.active = {}
gui.windows = {}
gui.EmptyPaint = function() end

-- Define window object
gui.window = {}
gui.window.__index = gui.window

-- Create fonts
surface.CreateFont("WindowTitle", { font = "Trebuchet24", size = 19 })
surface.CreateFont("WindowText", { font = "Trebuchet24", size = 15 })
surface.CreateFont("WindowLabel", { font = "Lato", size = 16 })
surface.CreateFont("WindowSubtitle", { font = "Trebuchet24", size = 11 })
surface.CreateFont("WindowCloseButton", { font = "Coolvetica", size = 13, weight = 800 })
surface.CreateFont("WindowButton", { font = "Tahoma", size = 19, weight = 800 })
surface.CreateFont("WindowButtonLight", { font = "Tahoma", size = 19 })
surface.CreateFont("HUDSmall", { font = "Lato", size = 20 })
surface.CreateFont("HUDLarge", { font = "Lato", size = 34 })
surface.CreateFont("ScoreboardTitle", { font = "Coolvetica", size = 52 })
surface.CreateFont("ScoreboardPlayer", { font = "Coolvetica", size = 24 })
surface.CreateFont("ScoreboardAuthor", { font = "Tahoma", size = 14, weight = 800 })

-- Modules
local timer = GM.Timer
local config = GM.Config

-- Functions
local SysTime, Color, IsValid, LocalPlayer = SysTime, Color, IsValid, LocalPlayer
local ScrW, ScrH = ScrW, ScrH
local RoundedBox, SimpleText = draw.RoundedBox, draw.SimpleText
local SetDrawColor, DrawRect, DrawLine, DrawOutlinedRect = surface.SetDrawColor, surface.DrawRect, surface.DrawLine, surface.DrawOutlinedRect
local SetFont, GetTextSize = surface.SetFont, surface.GetTextSize
local SetMaterial, DrawTexturedRect = surface.SetMaterial, surface.DrawTexturedRect
local Derma_DrawBackgroundBlur = Derma_DrawBackgroundBlur
local format, sub = string.format, string.sub

-- Constants
local ALIGN_LEFT, ALIGN_RIGHT, ALIGN_TOP, ALIGN_BOTTOM, ALIGN_CENTER = TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, TEXT_ALIGN_BOTTOM, TEXT_ALIGN_CENTER

-- Colors
local COLOR_TEXT_BLACK = Color(0, 0, 0)
local COLOR_TEXT_DARK1 = Color(25, 25, 25)
local COLOR_TEXT_GRAY1 = Color(68, 68, 68)
local COLOR_TEXT_GRAY2 = Color(85, 85, 85)
local COLOR_TEXT_GRAY3 = Color(130, 130, 130)
local COLOR_TEXT_GRAY4 = Color(150, 150, 150)
local COLOR_TEXT_WHITE = Color(255, 255, 255)
local COLOR_HUD_BACKGROUND = Color(0, 0, 0, 160)
local COLOR_HUD_WHITE_TRANSPARENT = Color(255, 255, 255, 2)
local COLOR_SCOREBOARD_BACKGROUND = Color(35, 35, 35, 150)
local COLOR_SCOREBOARD_PLAYER1 = Color(42, 42, 42, 150)
local COLOR_SCOREBOARD_PLAYER2 = Color(64, 64, 64, 150)

-- Materials
local MATERIAL_COG = Material("icon16/cog.png")

--[[---------------------------------------------------------
  Desc: Acknowledges validity for hooks
-----------------------------------------------------------]]
function gui:IsValid()
  return true
end

--[[---------------------------------------------------------
  Desc: Trims text to a maximum width
-----------------------------------------------------------]]
function gui.TrimToSize(font, text, max)
  if max <= 0 then return "" end

  SetFont(font)

  local long, first = true, true
  while long do
    local w = GetTextSize(text)
    if w > max then
      if first then
        text = sub(text, 1, #text - 4)
        first = false
      else
        text = sub(text, 1, #text - 1)
      end
    else
      break
    end
  end

  if not first then
    text = text .. "..."
  end

  return text
end

--[[---------------------------------------------------------
  Desc: Creates a new window
-----------------------------------------------------------]]
function gui:Create(id, args)
  if not self.windows[id] then return end

  -- Check if an instance already exists
  for i = 1, #self.active do
    if self.active[i].id == id then
      return self.active[i].args.Keep and self.active[i]:Show()
    end
  end

  -- Create the new window
  local window = { id = id, args = args }
  setmetatable(window, self.window)
  window.Build = self.windows[id]
  self.active[#self.active + 1] = window

  -- And display
  window:Show()
end

--[[---------------------------------------------------------
  Desc: Register a window setup
-----------------------------------------------------------]]
function gui:Register(id, setup)
  self.windows[id] = setup
end

--[[---------------------------------------------------------
  Desc: Extend a window setup
-----------------------------------------------------------]]
function gui:Extend(clone, id, setup)
  local old = self.windows[clone]
  if not old then return end

  self.windows[id] = function(self)
    old(self)
    setup(self)
  end
end

--[[---------------------------------------------------------
  Desc: Gets an opened window instance
-----------------------------------------------------------]]
function gui:Get(id)
  for _, window in pairs(self.active) do
    if window.id == id then
      return window
    end
  end
end

--[[---------------------------------------------------------
  Desc: Closes this window instance
-----------------------------------------------------------]]
function gui.window:Close()
  local window = self.Target or self
  if not window.frame then return end
  window.frame:Close()

  if window.args.Keep then return end
  for i = 1, #gui.active do
    if gui.active[i].id == window.id then
      table.remove(gui.active, i)
      break
    end
  end
end

--[[---------------------------------------------------------
  Desc: Shows this window instance
-----------------------------------------------------------]]
function gui.window:Show()
  if self.frame then
    return self.frame:SetVisible(true)
  end

  self.frame = vgui.Create("DFrame")
  self.frame.Paint = self.Paint
  self.frame:SetTitle("")
  self.frame:SetDraggable(true)
  self.frame:ShowCloseButton(false)

  -- Build the form itself
  self:Build()
  self.frame.args = self.args
  self.frame:SetSize(self.args.Width, self.args.Height)

  -- Add blur if we need to (TODO: See if this needs implementing)
  if self.args.Blur then
    self.frame.BlurTime = SysTime()
    self.frame:SetBackgroundBlur(true)
  end

  -- Don't delete window if specified
  if self.args.Keep then
    self.frame:SetDeleteOnClose(false)
  end

  -- Add the close button and show the window
  self:AddCloseButton()
  self.frame:Center()
  self.frame:MakePopup()
end

--[[---------------------------------------------------------
  Desc: Adds the close button
-----------------------------------------------------------]]
function gui.window:AddCloseButton()
  if self.close then return end

  local close = vgui.Create("DButton", self.frame)
  close:SetPos(self.frame:GetWide() - 24, 8)
  close:SetSize(16, 16)
  close:SetText("")
  close:SetDrawBackground(false)
  close.Target = self
  close.Paint = self.PaintCloseButton
  close.DoClick = self.Close

  self.close = close
end

--[[---------------------------------------------------------
  Desc: Adds a standard label
-----------------------------------------------------------]]
function gui.window:CreateLabel(t)
  local lbl = vgui.Create("DLabel", t.parent)
  lbl:SetPos(t.x, t.y)
  lbl:SetFont(t.font or "WindowLabel")
  lbl:SetTextColor(t.color or COLOR_TEXT_GRAY2)

  lbl.OldSetText = lbl.SetText
  function lbl:SetText(txt)
    self:OldSetText(txt)
    self:SizeToContents()
  end

  lbl:SetText(t.text)

  return lbl
end

--[[---------------------------------------------------------
  Desc: Adds a standard combobox
-----------------------------------------------------------]]
function gui.window:CreateCombo(t)
  SetFont("DermaDefault")
  local w = GetTextSize(t.text)

  local combo = vgui.Create("DComboBox", t.parent)
  combo:SetPos(t.x, t.y)
  combo:SetSize(w + 40, 20)
  combo:SetValue(t.text)

  return combo
end

--[[---------------------------------------------------------
  Desc: Adds a styled button
-----------------------------------------------------------]]
function gui.window:CreateButton(t)
  local btn = vgui.Create("DButton", t.parent)
  btn.Text = t.text
  btn.Font = t.bold and "WindowButton" or "WindowButtonLight"
  btn.Paint = self.PaintButton
  btn.DoClick = t.click

  SetFont(btn.Font)
  local w, h = GetTextSize(btn.Text)
  t.w = t.w or w + 20
  t.h = t.h or h + 10

  btn:SetPos(t.x, t.y)
  btn:SetSize(t.w, t.h)
  btn:SetText("")
  btn:SetDrawBackground(false)

  return btn
end

--[[---------------------------------------------------------
  Desc: Paints styled button
-----------------------------------------------------------]]
function gui.window:PaintButton(w, h)
  local color, y = Color(221, 221, 221), 0
  if self:IsDown() then
    color, y = Color(206, 206, 206), 1
  elseif self:IsHovered() then
    color = Color(238, 238, 238)
  end

  RoundedBox(4, 0, y, w, h - 1, Color(0, 0, 0, 240))
  RoundedBox(4, 0, y, w, h - 2, Color(119, 119, 119))
  RoundedBox(4, 1, y + 1, w - 2, h - 4, color)

  SimpleText(self.Text, self.Font, w / 2, h / 2 - 1 + y, Color(255, 255, 255, 204), ALIGN_CENTER, ALIGN_CENTER)
  SimpleText(self.Text, self.Font, w / 2, h / 2 - 2 + y, Color(51, 51, 51), ALIGN_CENTER, ALIGN_CENTER)
end

--[[---------------------------------------------------------
  Desc: Paints the frame
-----------------------------------------------------------]]
function gui.window:Paint(w, h)
  RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 76))
  RoundedBox(8, 8, 44, w - 16, h - 52, Color(252, 252, 252))
  RoundedBox(8, 8, 8, w - 16, 44, Color(236, 236, 236))

  SetDrawColor(Color(236, 236, 236))
  DrawRect(8, 52 - 16, w - 16, 16)

  local args = self.args
  SetDrawColor(Color(196, 196, 196))
  DrawLine(8, 52, w - 8, 52)

  SimpleText(args.Title, "WindowTitle", w / 2, 8 + 44 / 2 + 1, Color(255, 255, 255, 204), ALIGN_CENTER, ALIGN_CENTER)
  local w2, h2 = SimpleText(args.Title, "WindowTitle", w / 2, 8 + 44 / 2, COLOR_TEXT_GRAY1, ALIGN_CENTER, ALIGN_CENTER)

  if args.Subtitle then
    SimpleText(args.Subtitle, "WindowSubtitle", w / 2, 8 + 44 / 2 + h2, COLOR_TEXT_GRAY3, ALIGN_CENTER, ALIGN_TOP)
  end
end

--[[---------------------------------------------------------
  Desc: Paints the close button
-----------------------------------------------------------]]
function gui.window:PaintCloseButton(w, h)
  SimpleText("X", "WindowCloseButton", w - 4, h / 2, COLOR_TEXT_GRAY1, ALIGN_RIGHT, ALIGN_CENTER)
end



-- Necessary screens:
-- Modal (Spectate) or text query
-- List selection (Style)
-- Nominate
-- Vote (RTV extension)
-- Records
-- Top List
-- Rank display
-- Long Jump Stats (Extension)
-- Maps left/beaten/wrs
-- Checkpoints
-- Realtime stats
-- Spectator keys
-- TAS (extension)
-- Player profile
-- Settings
-- Radio (extension?)
-- Admin panel
-- Bot control

--[[---------------------------------------------------------
  Desc: Builds the settings window
-----------------------------------------------------------]]
function gui.windows:menu()
  self.args = table.Merge(self.args, {
    Title = "Main Menu",
    Width = 600,
    Height = 500
  })

  self.frame.OldPaint = self.frame.Paint
  function self.frame:Paint(w, h)
    self:OldPaint(w, h)

    SetDrawColor(Color(236, 236, 236))
    DrawRect(8, 52, w - 16, 24)

    SetDrawColor(Color(196, 196, 196))
    DrawLine(8, 52, w - 8, 52)
    DrawLine(8, 52 + 24, w - 8, 52 + 24)
  end

  local sheet = vgui.Create("DPropertySheet", self.frame)
  sheet:Dock(FILL)
  sheet:DockMargin(0, 24, 0, 0)
  function sheet:Paint(w, h)
    RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
  end

  local timer = vgui.Create("DPanel", sheet)
  timer.Paint = gui.EmptyPaint
  sheet:AddSheet("Timer", timer, "icon16/time.png")

  local client = vgui.Create("DPanel", sheet)
  client.Paint = gui.EmptyPaint
  sheet:AddSheet("Client", client, "icon16/monitor_edit.png")

  local communication = vgui.Create("DPanel", sheet)
  communication.Paint = gui.EmptyPaint
  sheet:AddSheet("Communication", communication, "icon16/sound.png")

  for i = 1, #sheet.Items do
    sheet.Items[i].Tab:SetColor(COLOR_TEXT_GRAY1)
    sheet.Items[i].Tab.Paint = gui.EmptyPaint
  end

  self.frame.Sheet = sheet
end


-- TODO: Make something that automatically enables the mouse whenever a screen is open (not with vote though)
-- Show a hint on how to use the mouse maybe? (Hold mouse instead of context key)

gui.hud_meta = {}

--[[---------------------------------------------------------
  Desc: Draws the heads up display
-----------------------------------------------------------]]
function gui.hud_meta:Paint(w, h)
  SetDrawColor(COLOR_HUD_BACKGROUND)
  DrawRect(0, 0, w, h)

  local ply = LocalPlayer()
  if not IsValid(ply) then return end

  if ply:IsSpectator() then
    -- TODO: Spectator HUD
    local ob = ply:GetObserverTarget()
  else
    -- TODO: Add time comparison
    if timer.Record > 0 then
      local time = timer:GetPrettyTime()
      SimpleText("Time:", "HUDSmall", 20, 21, COLOR_TEXT_DARK1, ALIGN_LEFT, ALIGN_CENTER)
      SimpleText("Time:", "HUDSmall", 20, 19, COLOR_TEXT_WHITE, ALIGN_LEFT, ALIGN_CENTER)
      SimpleText(time, "HUDSmall", 140, 21, COLOR_TEXT_DARK1, ALIGN_LEFT, ALIGN_CENTER)
      SimpleText(time, "HUDSmall", 140, 19, COLOR_TEXT_WHITE, ALIGN_LEFT, ALIGN_CENTER)

      local best = timer.Convert(timer.Record)
      SimpleText("Best:", "HUDSmall", 20, 41, COLOR_TEXT_DARK1, ALIGN_LEFT, ALIGN_CENTER)
      SimpleText("Best:", "HUDSmall", 20, 39, COLOR_TEXT_WHITE, ALIGN_LEFT, ALIGN_CENTER)
      SimpleText(best, "HUDSmall", 140, 41, COLOR_TEXT_DARK1, ALIGN_LEFT, ALIGN_CENTER)
      SimpleText(best, "HUDSmall", 140, 39, COLOR_TEXT_WHITE, ALIGN_LEFT, ALIGN_CENTER)
    else
      local time = "Time: " .. timer:GetPrettyTime()
      SimpleText(time, "HUDLarge", 20, 32, COLOR_TEXT_DARK1, ALIGN_LEFT, ALIGN_CENTER)
      SimpleText(time, "HUDLarge", 20, 30, COLOR_TEXT_WHITE, ALIGN_LEFT, ALIGN_CENTER)
    end

    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon.Clip1 then
      local ammo = ply:GetAmmoCount(weapon:GetPrimaryAmmoType())
      if ammo > 0 then
        local magazine = weapon:Clip1() .. " / " .. ammo
        SimpleText(magazine, "HUDLarge", w - 20, 30, COLOR_TEXT_DARK1, ALIGN_RIGHT, ALIGN_CENTER)
        SimpleText(magazine, "HUDLarge", w - 20, 28, COLOR_TEXT_WHITE, ALIGN_RIGHT, ALIGN_CENTER)
      end
    end

    local speed = ply:GetVelocity():Length2D()
    local velocity = format("Velocity: %.0f u/s", speed)
    SimpleText(velocity, "HUDLarge", w / 2, 32, COLOR_TEXT_DARK1, ALIGN_CENTER, ALIGN_CENTER)
    SimpleText(velocity, "HUDLarge", w / 2, 30, COLOR_TEXT_WHITE, ALIGN_CENTER, ALIGN_CENTER)
  end
end

--[[---------------------------------------------------------
  Desc: Creates the heads-up display
-----------------------------------------------------------]]
function gui:CreateHUD()
  self.hud = vgui.Create("DFrame")
  self.hud:SetTitle("")
  self.hud:SetDraggable(false)
  self.hud:ShowCloseButton(false)
  self.hud:SetSize(ScrW(), 60)
  self.hud:SetPos(0, ScrH() - self.hud:GetTall())

  self.hud.Think = function() end
  self.hud.Paint = gui.hud_meta.Paint
end
hook.Add("Initialize", gui, gui.CreateHUD)

-- Store in a fast hash table
local hide_applet = {
  ["CHudDeathNotice"] = true,
  ["CHudHealth"] = true,
  ["CHudSecondaryAmmo"] = true,
  ["CHudAmmo"] = true,
  ["CHudBattery"] = true,
  ["CHudTrain"] = true,
  ["CHudCrosshair"] = true
}

--[[---------------------------------------------------------
  Desc: Override the default HUDs
-----------------------------------------------------------]]
function GM:HUDPaint() end
function GM:HUDDrawScoreBoard() end
function GM:HUDShouldDraw(applet)
  return not hide_applet[applet]
end



-- Scoreboard table
local scoreboard = {}
scoreboard.BottomHeight = 40
scoreboard.PlayerRatio = 0.7
scoreboard.DefaultPlayer = "Retrieving..."

--[[---------------------------------------------------------
  Desc: Draws a player item
-----------------------------------------------------------]]
function scoreboard:DrawPlayer(w, h)
  SetDrawColor(self.Background)
  DrawRect(0, 0, w, h)

  SetDrawColor(COLOR_TEXT_GRAY4)
  DrawLine(0, 0, w, 0)
  DrawLine(0, 0, 0, h)
  DrawLine(w, 0, w, h)
  DrawLine(w - 1, 0, w - 1, h)

  if self.Last then
    DrawLine(0, h - 1, w, h - 1)
  end

  local ply = self.Player
  local inner = self.Parent
  local x = 0

  if IsValid(ply) then
    if ply:IsBot() then

    else
      SimpleText("Rank", "ScoreboardPlayer", x + 11, 9, COLOR_TEXT_BLACK, ALIGN_LEFT)
      SimpleText("Rank", "ScoreboardPlayer", x + 10, 8, COLOR_TEXT_WHITE, ALIGN_LEFT)
      x = x + inner.PlayerWidth + 56

      SimpleText(self.Name, "ScoreboardPlayer", x + 11, 9, COLOR_TEXT_BLACK, ALIGN_LEFT)
      SimpleText(self.Name, "ScoreboardPlayer", x + 10, 8, COLOR_TEXT_WHITE, ALIGN_LEFT)

      local scroll = self.ScrollBar.Enabled and self.ScrollBar:GetWide() or 0
      local o = w - self.RecordWidth - ((105 - self.RecordWidth) * 2) - scoreboard.RecordOffset + scroll
      SimpleText("00:00.000", "ScoreboardPlayer", o + 1, 9, COLOR_TEXT_BLACK, ALIGN_RIGHT)
      SimpleText("00:00.000", "ScoreboardPlayer", o, 8, COLOR_TEXT_WHITE, ALIGN_RIGHT)
      o = o + 20 + (self.TimerWidth - self.RecordWidth)

      SimpleText("Style", "ScoreboardPlayer", o + 1, 9, COLOR_TEXT_BLACK, ALIGN_LEFT)
      SimpleText("Style", "ScoreboardPlayer", o, 8, COLOR_TEXT_WHITE, ALIGN_LEFT)

      local ping = ply:Ping()
      SimpleText(ping, "ScoreboardPlayer", w - 9, 9, COLOR_TEXT_BLACK, ALIGN_RIGHT)
      SimpleText(ping, "ScoreboardPlayer", w - 10, 8, COLOR_TEXT_WHITE, ALIGN_RIGHT)
    end
  else
    local text = inner.Count > 1 and "Player has disconnected" or "No players to display!"
    SimpleText(text, "ScoreboardPlayer", w / 2 + 1, 9, COLOR_TEXT_BLACK, ALIGN_CENTER)
    SimpleText(text, "ScoreboardPlayer", w / 2, 8, COLOR_TEXT_WHITE, ALIGN_CENTER)
  end
end

--[[---------------------------------------------------------
  Desc: Adds a player item to the list
-----------------------------------------------------------]]
function scoreboard:AddPlayer(ply, id, last)
  local inner = self:GetParent()
  local player = vgui.Create("DButton", inner)
  player:SetTall(36)
  player:SetText("")

  player.Parent = inner
  player.Background = id % 2 == 0 and COLOR_SCOREBOARD_PLAYER1 or COLOR_SCOREBOARD_PLAYER2
  player.Last = last
  player.Player = ply
  player.ScrollBar = self:GetVBar()
  player.Paint = scoreboard.DrawPlayer

  if not ply.Blank then
    player.Name = ply:Name()
    player.Record = timer.Convert(0)

    if ply:IsBot() then

    else
      SetFont("ScoreboardPlayer")
      player.TimerWidth = GetTextSize(timer.Convert(0))
      player.RecordWidth = GetTextSize(player.Record)

      local w = inner:GetTextWidth()
      w = w - 8

      player.Name = gui.TrimToSize("ScoreboardPlayer", player.Name, w)
    end
  end

  function player:DoClick()
    print("Clicked a player!", self.Player)
  end

  self:AddItem(player)
end

--[[---------------------------------------------------------
  Desc: Refreshes players or bots in a list
-----------------------------------------------------------]]
function scoreboard:RefreshList()
  local players
  if self.Bots then
    players = player.GetBots()

    -- TODO: Sort bots accordingly
    -- table.sort(players, function(a, b)
    --
    -- end)
  else
    local spectators = {}
    players = {}

    for _, ply in pairs(player.GetHumans()) do
      if ply:Alive() then
        players[#players + 1] = ply
      else
        spectators[#spectators + 1] = ply:Name()
      end
    end

    -- TODO: Sort players accordingly
    -- table.sort(players, function(a, b)
    --
    -- end)

    if #players == 0 then
      players[1] = { Blank = true }
    end

    local frame = self:GetParent()
    frame.spectators.List = #spectators > 0 and string.Implode(", ", spectators) or "None"
  end

  local scroll = self.ScrollPanel
  local canvas = scroll:GetCanvas()
  self.Count = #players

  for _, child in pairs(canvas:GetChildren()) do
    if IsValid(child) then
      child:Remove()
    end
  end

  for id, ply in pairs(players) do
    scroll:AddPlayer(ply, id, id == #players)
  end

  canvas:InvalidateLayout()
end

--[[---------------------------------------------------------
  Desc: Generate the player section
-----------------------------------------------------------]]
function scoreboard:GenerateSection(type, frame, h, pw)
  local bots = type == "bots"
  local inner = vgui.Create("DPanel", frame)
  inner.Count = 0
  inner.Bots = bots
  inner.RectOffset = bots and 4 or 2
  inner.PlayerWidth = pw
  inner.Refresh = self.RefreshList

  function inner:Paint(w, h)
    SetDrawColor(COLOR_HUD_WHITE_TRANSPARENT)
    DrawOutlinedRect(0, 0, w, h - self.RectOffset)
  end

  local head = vgui.Create("DPanel", inner)
  head:DockMargin(0, 0, 0, 4)
  head:Dock(TOP)
  head.Paint = gui.EmptyPaint

  local rank = vgui.Create("DLabel", head)
  rank:SetText(bots and "Type" or "Rank")
  rank:SetFont("Trebuchet24")
  rank:SetTextColor(COLOR_TEXT_WHITE)
  rank:SetWidth(bots and 80 or 50)
  rank:Dock(LEFT)

  local player = vgui.Create("DLabel", head)
  player:SetText(bots and "Replay" or "Player")
  player:SetFont("Trebuchet24")
  player:SetTextColor(COLOR_TEXT_WHITE)
  player:SetWidth(60)
  player:DockMargin(pw + 14 - (bots and 30 or 0), 0, 0, 0)
  player:Dock(LEFT)
  inner.LeftMost = player

  local ping = vgui.Create("DLabel", head)
  ping:SetText(bots and "Date" or "Ping")
  ping:SetFont("Trebuchet24")
  ping:SetTextColor(COLOR_TEXT_WHITE)
  ping:SetWidth(50)
  ping:DockMargin(0, 0, 0, 0)
  ping:Dock(RIGHT)

  if not bots then
    local style = vgui.Create("DLabel", head)
    style:SetText("Style")
    style:SetFont("Trebuchet24")
    style:SetTextColor(COLOR_TEXT_WHITE)
    style:SetWidth(80)
    style:DockMargin(0, 0, scoreboard.RecordOffset - 18, 0)
    style:Dock(RIGHT)
  end

  local timer = vgui.Create("DLabel", head)
  timer:SetText("Record")
  timer:SetFont("Trebuchet24")
  timer:SetTextColor(COLOR_TEXT_WHITE)
  timer:SetWidth(80)
  timer:DockMargin(0, 0, bots and 80 or 18, 0)
  timer:Dock(RIGHT)
  inner.RightMost = timer

  -- Save maximum achievable width
  function inner:GetTextWidth()
    return self.RightMost:GetPos() - self.LeftMost:GetPos()
  end

  inner:SetTall(h)
  inner:DockPadding(8, 8, 8, bots and 12 or 8)
  inner:Dock(TOP)

  -- Wrap new items into a scrollable panel
  local list = vgui.Create("DScrollPanel", inner)
  list:Dock(FILL)
  list.AddPlayer = self.AddPlayer
  inner.ScrollPanel = list

  local canvas = list:GetCanvas()
  function canvas:OnChildAdded(child)
    child:Dock(TOP)
  end

  return inner
end

--[[---------------------------------------------------------
  Desc: Shows the scoreboard
-----------------------------------------------------------]]
function GM:ScoreboardShow()
  if IsValid(scoreboard.frame) then
    scoreboard.frame.BlurStart = SysTime()
    scoreboard.frame:SetVisible(true)
    scoreboard.frame:Update()
  else
    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW() * 0.5, ScrH() * 0.8)
    frame:SetTitle("")
    frame:DockPadding(4, 4, 4, 4)
    frame:Center()
    frame:MakePopup()
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:SetKeyboardInputEnabled(false)
    frame:SetDeleteOnClose(false)
    frame.BlurStart = SysTime()
    scoreboard.RecordOffset = ((ScrW() - 1280) / 64) * 8
    scoreboard.frame = frame

    function frame:Paint(w, h)
      Derma_DrawBackgroundBlur(self, self.BlurStart)
      RoundedBox(8, 0, 0, w, h, COLOR_SCOREBOARD_BACKGROUND)
    end

    local credits = vgui.Create("DPanel", frame)
    credits:Dock(TOP)
    credits:DockPadding(8, 2, 8, 0)
    credits.Paint = gui.EmptyPaint

    local title = vgui.Create("DLabel", credits)
    title:Dock(LEFT)
    title:SetFont("ScoreboardTitle")
    title:SetText(config.Server.Title)
    title:SetTextColor(COLOR_TEXT_WHITE)
    frame.title = title

    function credits:PerformLayout()
      local frame = self:GetParent()
      SetFont(frame.title:GetFont())
      local w, h = GetTextSize(frame.title:GetText())
      self:SetTall(h)
    end

    function title:PerformLayout()
      SetFont(self:GetFont())
      self:SetSize(GetTextSize(self:GetText()))
    end

    local author = vgui.Create("DButton", credits)
    author:Dock(RIGHT)
    author:SetFont("ScoreboardAuthor")
    author:SetText(format("%s\nBy Gravious\nVersion %s", config.Server.Name, GAMEMODE.Version))
    author:SetTextColor(COLOR_TEXT_WHITE)
    author:SetDrawBackground(false)
    author:SetDrawBorder(false)
    author.PerformLayout = title.PerformLayout

    function author:DoClick()
      gui.OpenURL("http://steamcommunity.com/id/GraviousDev/")
    end

    local h = frame:GetTall()
    SetFont("ScoreboardPlayer")
    local pw, ph = GetTextSize(scoreboard.DefaultPlayer)
    ph = scoreboard.PlayerRatio * h

    frame.players = scoreboard:GenerateSection("players", frame, ph, pw)
    frame.bots = scoreboard:GenerateSection("bots", frame, h - ph - (scoreboard.BottomHeight * 2 - 8), pw)

    local bottom = vgui.Create("DPanel", frame)
    bottom:SetTall(scoreboard.BottomHeight)
    bottom:Dock(TOP)
    bottom:DockPadding(0, 0, 0, 0)
    bottom.Paint = gui.EmptyPaint

    local spectators = vgui.Create("DButton", bottom)
    spectators:SetText("Spectators:") -- TODO: Also add a tooltip for a full list?
    spectators:SetFont("WindowText")
    spectators:SetTextColor(COLOR_TEXT_GRAY4)
    spectators:SetWide(frame:GetWide() - 100)
    spectators:SetDrawBackground(false)
    spectators:SetDrawBorder(false)
    spectators:Dock(LEFT)
    spectators:DockMargin(4, 0, 0, 24)
    spectators.List = "None"
    spectators.PerformLayout = title.PerformLayout
    spectators.DoClick = function() end -- TODO: Make this
    spectators.DoRightClick = function() end
    spectators:SetTooltip(spectators.List)
    frame.spectators = spectators

    local settings = vgui.Create("DButton", bottom)
    settings:Dock(RIGHT)
    settings:DockMargin(0, 0, 4, 0)
    settings:SetText("")
    settings:SetWide(64)

    function settings:Paint(w, h)
      SimpleText("Settings", "WindowText", 0, 8, COLOR_TEXT_GRAY4, ALIGN_LEFT, ALIGN_CENTER)
      SetMaterial(MATERIAL_COG)
      SetDrawColor(COLOR_TEXT_WHITE)
      DrawTexturedRect(w - 16, 0, 16, 16)
    end

    function settings:DoClick()
      print("TODO: Open settings here")
    end

    function frame:Update()
      self.players:Refresh()
      self.bots:Refresh()
      self.spectators:SetText("Spectators: " .. self.spectators.List)
      self.spectators:SetTooltip(self.spectators.List)
    end

    timer.Simple(0, function()
      frame:Update()
    end)
  end
end

--[[---------------------------------------------------------
  Desc: Hides the scoreboard
-----------------------------------------------------------]]
function GM:ScoreboardHide()
  if IsValid(scoreboard.frame) then
    scoreboard.frame:Close()
  end
end

-- Save reference
GM.GUI = gui
