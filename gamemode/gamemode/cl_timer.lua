local global_timer = timer
global_timer.__index = global_timer

local timer = {}
setmetatable(timer, global_timer)

timer.Record = 0

-- Functions
local SysTime = SysTime
local format, floor = string.format, math.floor
local net = net

--[[---------------------------------------------------------
  Desc: Gets timer delay by using ping
-----------------------------------------------------------]]
function timer.GetDelayFromPing()
  local ping = LocalPlayer():Ping()
  if ping > 500 then
    return 0.5
  else
    return ping / 1000.0
  end
end

--[[---------------------------------------------------------
  Desc: Gets the player's current time
-----------------------------------------------------------]]
function timer:GetTime()
  if not timer.End and timer.Begin then
    return SysTime() - timer.Begin
  elseif timer.End and timer.Begin then
    return timer.End - timer.Begin
  else
    return 0
  end
end

--[[---------------------------------------------------------
  Desc: 'Pretty' prints a player's time
-----------------------------------------------------------]]
function timer:GetPrettyTime()
  return self.Convert(self:GetTime())
end

--[[---------------------------------------------------------
  Desc: Formats given time
  TODO: Allow changing of decimals
-----------------------------------------------------------]]
local HourFormat, MinuteFormat = "%d:%.2d:%.2d.%.3d", "%.2d:%.2d.%.3d"
function timer.Convert(t)
  if t >= 3600 then
    return format(HourFormat, floor(t / 3600), floor(t / 60 % 60), floor(t % 60), floor(t * 1000 % 1000))
  else
    return format(MinuteFormat, floor(t / 60 % 60), floor(t % 60), floor(t * 1000 % 1000))
  end
end

--[[---------------------------------------------------------
  Desc: Network receiver for timer data
-----------------------------------------------------------]]
function timer.Receive()
  local id = net.ReadUInt(2)
  if id == 0 then
    timer.Begin = nil
    timer.End = nil
  elseif id == 1 then
    timer.Begin = SysTime() - timer.GetDelayFromPing()
    timer.End = nil
  elseif id == 2 then
    timer.Begin = SysTime() - net.ReadDouble()
    timer.End = SysTime()
  end
end
net.Receive("Timer", timer.Receive)

-- TODO: This whole thing is a mess, rewrite it.
local Vel = { Get = function( p ) return fl( Is3DVel and p:GetVelocity():Length() or p:GetVelocity():Length2D() ) end, Color = function( s, c, a ) return FColor( c.r, c.g, c.b, a or s.Opacity or 0 ) end, Timeout = function( s ) if IsValid( lp() ) and s.Get( lp() ) == 0 then s.Location = 0 s.Opacity = 255 s.Direction = false s.Moving = true s.Active = true else s.Counting = false end end }


-- Store reference
GM.Timer = timer
