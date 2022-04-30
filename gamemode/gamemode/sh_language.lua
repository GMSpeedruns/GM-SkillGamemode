-- Define local tables
local lang = {}
local l = {}
local ids = {}

-- Functions
local next = next
local find, sub, format = string.find, string.sub, string.format

-- Colors and prefixes
local colors = {
  ["$w"] = Color(255, 255, 255), -- White
  ["$l"] = Color(0, 255, 255), -- Light blue
  ["$m"] = Color(200, 0, 0) -- Maroon
}

local prefixes = {
  Database = "$l",
  Gamemode = "$m"
}

-- TODO: KSF scheme
local schemes = {
  ksf = {
    Color(168, 230, 161),
    Color(161, 203, 230),
    Color(230, 188, 161),
    Color(223, 161, 230)
  }
}

--[[---------------------------------------------------------
  Desc: Adds identifiers to the language table
-----------------------------------------------------------]]
function lang.Add(t)
  l = table.Merge(l, t)
end

--[[---------------------------------------------------------
  Desc: Gets raw language entry
-----------------------------------------------------------]]
function lang.Get(key)
  return l[key]
end

--[[---------------------------------------------------------
  Desc: Gets the id for a key
-----------------------------------------------------------]]
function lang.GetIDByKey(key)
  for id, k in next, ids do
    if k == key then
      return id
    end
  end
end

--[[---------------------------------------------------------
  Desc: Gets the id by looking for key
-----------------------------------------------------------]]
function lang.GetKeyByID(id)
  for i, key in next, ids do
    if i == id then
      return key
    end
  end
end

--[[---------------------------------------------------------
  Desc: Parses dollar colors and them into Color structures
-----------------------------------------------------------]]
function lang.ParseColors(text, white)
  local t = {}
  if white then
    t[#t + 1] = colors["$w"]
  end

  local i = string.find(text, "$", 1, true)
  if not i then
    t[#t + 1] = text
    return t
  end

  local last = i > 1 and 0
  while i do
    if last then
      t[#t + 1] = string.sub(text, last + 1, i - 1)
    end

    t[#t + 1] = colors[string.sub(text, i, i + 1)]

    last = i + 1
    i = string.find(text, "$", i + 1, true)
  end

  t[#t + 1] = string.sub(text, last + 1)

  return t
end

--[[---------------------------------------------------------
  Desc: Prints a message in the console
-----------------------------------------------------------]]
function lang.Console(key, ...)
  local text = l[key] or key .. " not found"
  local prefixed = find(sub(key, 2), "%u")
  if prefixed then
    local prefix = sub(key, 1, prefixed)
    local col = prefixes[prefix] or ""
    text = "$w[" .. col .. prefix .. "$w] " .. text
  end

  local t = lang.ParseColors(format(text, ...))
  t[#t + 1] = "\n"

  MsgC(unpack(t))
end

--[[---------------------------------------------------------
  Desc: Prints text in the chatbox
-----------------------------------------------------------]]
function lang.Print(key, ...)
  chat.AddText(unpack(lang.ParseColors(format(l[key], ...), true)))
end

-- General
l["GamemodeLoaded"] = "Loaded in %.3f ms"

-- Commands
l["CommandInvalid"] = "The command '%s' is invalid"
l["SpectatingLimited"] = "This is not possible while spectating"
l["SpectatingWeapon"] = "You can't obtain a weapon whilst spectating"
l["SpectatingRestart"] = "You have to be alive in order to reset yourself to the start"

-- Generate unique ids
for txt_id in next, l do
  local id = tonumber(util.CRC(l[txt_id]))
  ids[id] = txt_id
end

return lang
