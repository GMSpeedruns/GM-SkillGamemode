-- Define a storage table
local storage = {}
storage.Data = {}
storage.Separator = "_"

-- Specify storage file path
if SERVER then
  storage.File = "settings.txt"
elseif CLIENT then
  local ip = string.Split(game.GetIPAddress(), ":")[1]
  local dir = "gmskill/" .. ip .. "/"
  file.CreateDir(dir)
  storage.File = dir .. "storage.dat"
end

--[[---------------------------------------------------------
  Desc: Initializes the storage system
-----------------------------------------------------------]]
function storage:Init()
  if file.Exists(self.File, "DATA") then
    local data = file.Read(self.File, "DATA")
    if CLIENT then
      storage.Hash = util.CRC(data or "")
      data = util.Decompress(data)
    end
    if data and data ~= "" then
      self.Data = util.JSONToTable(data)
      self.Loaded = true
    end
  elseif SERVER then
    file.Write(self.File, "{}")
    return self:Init()
  end

  return self.Loaded, storage.File
end

--[[---------------------------------------------------------
  Desc: Saves changes to file
-----------------------------------------------------------]]
function storage:Save()
  file.Write(self.File, util.TableToJSON(self.Data, true))
end

--[[---------------------------------------------------------
  Desc: Sets a config value by key
-----------------------------------------------------------]]
function storage:Set(key, value)
  if not SERVER then return end

  local pieces = string.Explode(self.Separator, key)
  if #pieces > 1 then
    if not self.Data[pieces[1]] then
      self.Data[pieces[1]] = {}
    end

    self.Data[pieces[1]][pieces[2]] = value
  else
    self.Data[key] = value
  end

  self:Save()

  return true
end

--[[---------------------------------------------------------
  Desc: Gets a config value by key
-----------------------------------------------------------]]
function storage:Get(key, default, set_if_missing)
  if set_if_missing then
    local value = self:Get(key)
    if not value then
      self:Set(key, default)
      return default
    else
      return value
    end
  end

  local pieces = string.Explode(self.Separator, key)
  if #pieces > 1 then
    return self.Data[pieces[1]] and self.Data[pieces[1]][pieces[2]] or default
  else
    return self.Data[key] or default
  end
end

--[[---------------------------------------------------------
  Desc: Gets or instantly sets a config value
-----------------------------------------------------------]]
function storage:Config(key, default)
  return self:Get(key, default, true)
end

--[[---------------------------------------------------------
  Desc: Adds shared config data to given table
-----------------------------------------------------------]]
function storage:AddSharedToTable(tab, key)
  local pieces = string.Explode(self.Separator, key)
  if #pieces > 1 then
    if not tab[pieces[1]] then
      tab[pieces[1]] = {}
    end

    tab[pieces[1]][pieces[2]] = self:Get(key)
  else
    tab[key] = self:Get(key)
  end
end

return storage
