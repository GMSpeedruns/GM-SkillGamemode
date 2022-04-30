-- Define a table for helper functions
local helpers = {}

--[[---------------------------------------------------------
  Desc: Performs a recursive search for files
-----------------------------------------------------------]]
function helpers.RecursiveFind(base_dir, file_type, path_type)
  local results = {}
  local files, directories = file.Find(base_dir .. "/" .. file_type, path_type)

  -- Add files to results
  for i = 1, #files do
    results[#results + 1] = base_dir .. "/" .. files[i]
  end

  -- Search folders
  for i = 1, #directories do
    table.Add(results, helpers.RecursiveFind(base_dir .. "/" .. directories[i], file_type, path_type))
  end

  return results
end

--[[---------------------------------------------------------
  Desc: Checks if the Steam ID is valid
-----------------------------------------------------------]]
function helpers.IsValidSteamID(steamid)
  return util.SteamIDTo64(steamid) ~= "0"
end

--[[---------------------------------------------------------
  Desc: Gets a player name from steamworks
-----------------------------------------------------------]]
local names = {}
function helpers.GetPlayerName(steamid, callback, arg)
  if names[steamid] then
    callback(steamid, names[steamid], arg)
  else
    steamworks.RequestPlayerInfo(steamid)

    timer.Simple(1, function()
      local name = steamworks.GetPlayerName(steamid)
      if not name or name == "[unknown]" then
        name = "Failed to load player name"
      else
        names[steamid] = name
      end

      callback(steamid, name, arg)
    end)
  end
end

--[[---------------------------------------------------------
  Desc: Rounds a vector to a specific multiple
-----------------------------------------------------------]]
local Vector, Round = Vector, math.Round
function helpers.SnapVector(v, n)
  return Vector(Round(v.x / n) * n, Round(v.y / n) * n, v.z)
end

--[[---------------------------------------------------------
  Desc: Rounds a vector to a specific multiple
-----------------------------------------------------------]]
local min, max = math.min, math.max
function helpers.MinMaxVector(a, b)
  return Vector(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z)), Vector(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z))
end

--[[---------------------------------------------------------
  Desc: Finds a valid position within a square
-----------------------------------------------------------]]
function helpers.RandomizeCoordinate(min, max)
	local spread_x, spread_y, spread_z = 8, 8, 0
  local diff_x, diff_y = max.x - min.x, max.y - min.y
  local center = (min + max) / 2
  local center_vector = Vector(center.x, center.y, min.z)

  -- Check if we can expand the spread
	if diff_x > 96 then spread_x = diff_x - 32 - diff_x / 2 end
	if diff_y > 96 then spread_y = diff_y - 32 - diff_y / 2 end
  if max.z - min.z > 32 then spread_z = 16 end

	return center_vector + Vector(math.random(-spread_x, spread_x), math.random(-spread_y, spread_y), spread_z)
end

return helpers
