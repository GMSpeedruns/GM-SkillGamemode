local rtv = nil
if not rtv then return end -- TODO: Prevent loading of this file

--[[
  Description: Player disconnection hook to clean up the trash they made
--]]
local function PlayerDisconnect( ply )
  -- Bots don't need any other logic
  if ply:IsBot() then return end

  -- When we're all empty, unload the gamemode (save bots)
  if #player.GetHumans() - 1 < 1 then
    GAMEMODE:UnloadGamemode( "Disconnect" )
  end

  -- Notify spectated players that their spectator is gone
  if ply.Spectating then
    ply:Spectator( "End", { ply:GetObserverTarget() } )
    ply.Spectating = nil
  end

  -- When they're racing, close the match
  if ply.Race then
    ply.Race:Abandon( ply )
  end

  -- Clean bot data
  Core.Ext( "Bot", "CleanPlayer" )( ply )

  -- Collect garbage if required
  if bit.band( Config.Var.GetInt( "ServerCollect" ), 2 ) > 0 then
    collectgarbage( "collect" )
  end

  -- Check if a vote is going on
  if RTV.VotePossible then return end

  -- If not, remove their vote
  if ply.Rocked then
    RTV.Votes = RTV.Votes - 1
  end

  -- And check if the vote passes now
  local Count = RTV.GetVotable( ply )
  if Count > 0 then
    RTV.Required = math.ceil( Count * RTV.Fraction )

    if RTV.Votes >= RTV.Required then
      RTV.StartVote()
    end
  end
end
hook.Add( "PlayerDisconnected", "PlayerDisconnect", PlayerDisconnect )



-- RTV System
RTV.MapRepeat = Config.Var.GetInt( "MapRepeat" )
RTV.UseLimitations = Config.Var.GetBool( "VoteLimit" )
RTV.MinLimitations = Config.Var.GetInt( "VoteLimitCount" )
RTV.Fraction = Config.Var.GetFloat( "VoteFraction" )
RTV.RandomizeTie = Config.Var.GetBool( "VoteRandomize" )
RTV.VoteTime = Config.Var.GetInt( "VoteDuration" )
RTV.Length = Config.Var.GetInt( "MapLength" ) * 60
RTV.DefaultExtend = Config.Var.GetInt( "MapExtend" ) * 60
RTV.WaitPeriod = Config.Var.GetInt( "VoteWait" ) * 60

RTV.Identifier = "MapCountdown"
RTV.Version = 1
RTV.ListMax = 5
RTV.VoteCount = 7
RTV.Votes = 0
RTV.VotePossible = false
RTV.VoteList = {}
RTV.VoteTimeEnd = 0
RTV.Extends = 0
RTV.CheckInterval = 0.5 * 60
RTV.BroadcastInterval = RTV.VoteTime / 10

if not RTV.Initialized then
  RTV.TimeNotify = {}
  RTV.Initialized = ST()
  RTV.Begin = RTV.Initialized
  RTV.End = RTV.Begin + RTV.Length

  local tab = string.Explode( ",", Config.Var.Get( "MapNotifications" ) )
  for i = 1, #tab do
    RTV.TimeNotify[ #RTV.TimeNotify + 1 ] = { tonumber( tab[ i ] ) }
  end
end

RTV.Func = {}
RTV.AutoExtend = {}
RTV.Nominations = {}
RTV.LatestList = {}

--[[
Description: Starts the RTV system
--]]
function RTV:Start()
  -- Make sure there's only one RTV timer running
  if timer.Exists( self.Identifier ) then
    timer.Remove( self.Identifier )
  end

  -- Set initialization fields for lifetime calculation
  self.Begin = ST()
  self.End = self.Begin + self.Length

  -- Populate the vote list with 0 votes
  for i = 1, self.VoteCount do
    self.VoteList[ i ] = 0
  end

  -- Load all necessary data
  self:Load()

  -- Crack up the random generator to throw in a little less than pseudo-randoms
  math.random( 1, 5 )

  -- Skip timers if length is 0
  if RTV.Length == 0 then return end

  -- Create a timer
  timer.Create( self.Identifier, self.Length, 1, self.StartVote )
  timer.Create( self.Identifier .. "Hourglass", self.CheckInterval, 0, self.TimeCheck )
end

--[[
Description: Loads data required for the RTV system
--]]
function RTV:Load()
  file.CreateDir( Config.BaseType .. "/" )

  -- Load in or write the map version
  if not file.Exists( Config.BaseType .. "/maplistversion.txt", "DATA" ) then
    file.Write( Config.BaseType .. "/maplistversion.txt", tostring( self.Version ) )
  else
    self.Version = tonumber( file.Read( Config.BaseType .. "/maplistversion.txt", "DATA" ) )
  end

  -- Create a dummy file if it's blank
  local dummy = {}
  for i = 1, RTV.MapRepeat do dummy[ i ] = "Dummy" end

  if not file.Exists( Config.BaseType .. "/maptracker.txt", "DATA" ) then
    file.Write( Config.BaseType .. "/maptracker.txt", util.TableToJSON( dummy ) )
  end

  -- Check file content
  local content = file.Read( Config.BaseType .. "/maptracker.txt", "DATA" )
  if not content or content == "" then return end

  -- Try to deserialize
  local tab = util.JSONToTable( content )
  if not tab or #tab != RTV.MapRepeat then
    return file.Write( Config.BaseType .. "/maptracker.txt", util.TableToJSON( dummy ) )
  end

  -- If we're going back to the same map, don't keep adding to the list
  if tab[ 1 ] == game.GetMap() then return end

  -- Insert at front and remove at the back
  table.insert( tab, 1, game.GetMap() )
  table.remove( tab, RTV.MapRepeat + 1 )

  -- Update the table
  self.LatestList = tab

  -- Finally write to file
  file.Write( Config.BaseType .. "/maptracker.txt", util.TableToJSON( self.LatestList ) )
end

--[[
Description: Starts the vote
--]]
function RTV.StartVote()
  if RTV.VotePossible then return end

  -- Let everyone know we just started a vote
  RTV.VotePossible = true
  RTV.Selections = {}
  Core.Print( nil, "Notification", Core.Text( "VoteStart" ) )

  -- Iterate over the nomination table and categorize it by vote count
  local MapList, MaxCount = {}, 1
  for map,voters in pairs( RTV.Nominations ) do
    local amount = 0
    for _,v in pairs( voters ) do
      if IsValid( v ) then
        amount = amount + 1
      end
    end

    -- If we've got an entry already, expand, otherwise create it
    local count = MapList[ amount ] and #MapList[ amount ]
    if not count then
      MapList[ amount ] = { map }
    else
      MapList[ amount ][ count + 1 ] = map
    end

    -- Increase max count if necessary
    if amount > MaxCount then
      MaxCount = amount
    end
  end

  -- Loop over the most important nominations
  for i = MaxCount, 1, -1 do
    if MapList[ i ] then
      for j = 1, #MapList[ i ] do
        if #RTV.Selections >= RTV.ListMax then break end

        -- Add the nomination to the list
        RTV.Selections[ #RTV.Selections + 1 ] = MapList[ i ][ j ]
      end
    end
  end

  -- If we haven't had sufficient nominations, gather some random maps
  if #RTV.Selections < 5 and Timer.Maps > 0 then
    -- Copy the base table and remove already nominated entries
    local copy = table.Copy( Maps )
    for i = 1, #RTV.Selections do
      copy[ RTV.Selections[ i ] ] = nil
    end

    -- Randomize all items but still keep plays into account
    local temp = {}
    for map,data in pairs( copy ) do
      temp[ #temp + 1 ] = { Map = map, Seed = math.random() * (data.nPlays or 0) }
    end

    -- Sort it by the quasi-random seed
    table.sort( temp, function( a, b ) return a.Seed < b.Seed end )

    -- Get the 25% least played maps in a separate table
    local limit = {}
    for i = 1, math.ceil( #temp * 0.25 ) do
      limit[ i ] = temp[ i ]
    end

    -- Finally add random entries
    for _,data in RandomPairs( limit ) do
      local map = data.Map
      if #RTV.Selections >= RTV.ListMax then break end
      if table.HasValue( RTV.Selections, map ) or map == game.GetMap() then continue end
      if table.HasValue( RTV.LatestList, map ) then continue end

      -- Add the random map to the list
      RTV.Selections[ #RTV.Selections + 1 ] = { map, RTV.GetMapData( map ) }
    end
  end

  -- Create a sortable table
  local sorted = {}
  for i = 1, #RTV.Selections do
    local item = RTV.Selections[ i ]
    if type( item ) == "table" then
      sorted[ #sorted + 1 ] = { Map = item[ 1 ], Plays = item[ 2 ][ 3 ], ListID = i }
    end
  end

  -- Check if we have maps to sort
  if #sorted > 0 then
    -- Sort the table with ascending plays
    table.SortByMember( sorted, "Plays", true )

    -- Reset the current table
    local offset
    for i = 1, #RTV.Selections do
      if type( RTV.Selections[ i ] ) == "table" then
        if not offset then offset = i end
        RTV.Selections[ i ] = nil
      end
    end

    -- Overwrite table entries with re-sorted entries
    for i = 1, #sorted do
      if not offset then break end
      RTV.Selections[ offset + i - 1 ] = sorted[ i ].Map
    end
  end

  -- Double check if we have maps at all
  if #RTV.Selections == 0 then
    local add = {}
    local maps = file.Find( "maps/*.bsp", "GAME" )
    for _,m in RandomPairs( maps ) do
      if #add < 5 then
        add[ #add + 1 ] = string.sub( m, 1, #m - 4 )
      end
    end

    -- Add dummy values if we don't have anything
    if #add < 5 then
      for i = 1, 5 do
        add[ i ] = "no_maps_" .. i
      end
    end

    -- Set our fake table to the selections
    for i = 1, #add do
      RTV.Selections[ i ] = add[ i ]
    end
  end

  -- Create a new table with only map data to be sent
  local RTVSend = {}
  for i = 1, #RTV.Selections do
    RTVSend[ #RTVSend + 1 ] = RTV.GetMapData( RTV.Selections[ i ] )
  end

  -- Make the list accessible from the RTV object and set the ending time
  RTV.VoteTimeEnd = ST() + RTV.VoteTime
  RTV.Sent = RTVSend
  RTV.Sent.Countdown = math.Clamp( RTV.VoteTimeEnd - ST(), 0, RTV.VoteTime )

  -- Broadcast the compiled list and start a timer
  timer.Simple( RTV.VoteTime + 1, RTV.EndVote )
  Core.Broadcast( "RTV/List", RTV.Sent )

  -- Distribute the instant votes
  timer.Simple( 0.5, function()
    local extend = {}
    for p,v in pairs( RTV.AutoExtend ) do
      if v then
        extend[ #extend + 1 ] = p
      end
    end

    if #extend > 0 then
      Core.Send( extend, "RTV/InstantVote", 6 )
    end

    for map,voters in pairs( RTV.Nominations ) do
      for id,data in pairs( RTV.Sent ) do
        if id == "Countdown" then continue end
        if data[ 1 ] == map then
          local out = {}
          for _,p in pairs( voters ) do
            if not RTV.AutoExtend[ p ] then
              out[ #out + 1 ] = p
            end
          end

          Core.Send( out, "RTV/InstantVote", id )
        end
      end
    end
  end )

  -- Get all vote participants
  local tabPlayers = player.GetHumans()
  local szUIDs, szMaps, tabPlys, nIDs = {}, {}, {}, {}
  for i = 1, #tabPlayers do szUIDs[ #szUIDs + 1 ] = tabPlayers[ i ].UID tabPlys[ szUIDs[ #szUIDs ] ] = tabPlayers[ i ] end
  for i = 1, #RTVSend do szMaps[ #szMaps + 1 ] = RTVSend[ i ][ 1 ] nIDs[ szMaps[ #szMaps ] ] = i end

  -- Get query pieces
  local queryMap = "szMap = '" .. string.Implode( "' OR szMap = '", szMaps ) .. "'"
  local queryPlayers = "szUID = '" .. string.Implode( "' OR szUID = '", szUIDs ) .. "'"

  -- Get the beaten maps and send them to the players
  Prepare(
  "SELECT szMap, szUID, nPoints FROM `game_times` WHERE nStyle = {0} AND (" .. queryMap .. ") AND (" .. queryPlayers .. ")",
  { Styles.Normal }
)( function( data, varArg )
  if Core.Assert( data, "szMap" ) then
    local tabData = {}
    for i = 1, #data do
      local t, m = tabData[ data[ i ].szUID ], { nIDs[ data[ i ].szMap ], data[ i ].nPoints }
      if not t then
        tabData[ data[ i ].szUID ] = { m }
      else
        t[ #t + 1 ] = m
      end
    end

    for steam,list in pairs( tabData ) do
      local out = {}
      for i = 1, #list do
        out[ list[ i ][ 1 ] ] = list[ i ][ 2 ] / RTVSend[ list[ i ][ 1 ] ][ 2 ]
      end

      if IsValid( tabPlys[ steam ] ) then
        Core.Send( tabPlys[ steam ], "RTV/SetBeaten", out )
      end
    end
  end
end )

-- Check broadcast timer
if timer.Exists( RTV.Identifier .. "Broadcast" ) then
  timer.Remove( RTV.Identifier .. "Broadcast" )
end

-- Create one with iterations that stop before the timer runs out
timer.Create( RTV.Identifier .. "Broadcast", RTV.BroadcastInterval, RTV.VoteTime / RTV.BroadcastInterval - 1, function()
  NetPrepare( "RTV/VoteList", RTV.VoteList ):Broadcast()
end )
end

--[[
Description: Ends the vote and decides what won (a map or extend or even random)
--]]
function RTV.EndVote()
  if RTV.CancelVote then
    local result = RTV.CompleteVote( true )
    return RTV:ResetVote( "Yes", 2, false, "VoteCancelled", result == "Extend" and "Extend won the vote. " or "" )
  end

  -- Trigger finalization (bots)
  GAMEMODE:UnloadGamemode( "VoteEnd", RTV.CompleteVote )
end

--[[
Description: Callback for gamemode unloading
--]]
function RTV.CompleteVote( bGet )
  local nMax, nTotal, nWin = 0, 0, -1
  for i = 1, 7 do
    if RTV.VoteList[ i ] and RTV.VoteList[ i ] > nMax then
      nMax = RTV.VoteList[ i ]
      nWin = i
    end

    nTotal = nTotal + RTV.VoteList[ i ]
  end

  -- If enabled, pick a random one if there's duplicates
  if RTV.RandomizeTie then
    local votes = {}
    for i = 1, 7 do
      if RTV.VoteList[ i ] == nMax then
        votes[ #votes + 1 ] = i
      end
    end

    if #votes > 1 then
      nWin = votes[ math.random( 1, #votes ) ]
      Core.Print( nil, "Notification", Core.Text( "VoteSameVotes", "#" .. string.Implode( ", #", votes ), nWin ) )
    end
  end

  -- Execute winner function
  if nWin <= 0 then
    nWin = math.random( 1, 5 )
  elseif nWin == 6 then
    if bGet then return "Extend" end
    Core.Print( nil, "Notification", Core.Text( "VoteExtend", RTV.DefaultExtend / 60 ) )
    return RTV:ResetVote( nil, 1, true, nil )
  elseif nWin == 7 then
    RTV.VotePossible = false

    if Timer.Maps > 0 then
      local ListMap, ListPlays = {}, {}
      for map,data in pairs( Maps ) do
        ListMap[ #ListMap + 1 ] = map
        ListPlays[ #ListPlays + 1 ] = data["nPlays"]
      end

      local minId, minValue, thisMap = ListMap[ 1 ], ListPlays[ 1 ], game.GetMap()
      for i = 2, #ListPlays do
        if ListPlays[ i ] < minValue and ListMap[ i ] != thisMap then
          minId = ListMap[ i ]
          minValue = ListPlays[ i ]
        end
      end

      if minId and minValue and Maps[ minId ] then
        nWin = 1
        RTV.Selections[ nWin ] = minId
      else
        nWin = math.random( 1, 5 )
      end
    else
      nWin = math.random( 1, 5 )
    end
  end

  -- Get the map from the selection table
  local szMap = RTV.Selections[ nWin ]
  if not szMap or not type( szMap ) == "string" then
    return Core.Print( nil, "Notification", Core.Text( "VoteMissing", szMap ) )
  end

  -- Check if the map we're changing to is actually available
  if not RTV.IsAvailable( szMap ) then
    Core.Print( nil, "Notification", Core.Text( "VoteMissing", szMap ) )
  else
    Core.Print( nil, "Notification", Core.Text( "VoteChange", szMap ) )
  end

  -- Check if we just want the result
  if bGet then
    return szMap
  end

  -- Backup reset for if we don't change
  timer.Simple( 10, function()
    RTV:ResetVote( "Yes", 1, false, "VoteFailure" )
  end )

  -- Finally change level
  timer.Simple( 5, function()
    Core.PrintC( "[Event] RTV -> Map changed to: ", szMap )

    GAMEMODE:UnloadGamemode( "Vote Change", function()
      RunConsoleCommand( "changelevel", szMap )
    end )
  end )
end

--[[
Description: Resets the vote data according to the vote type
--]]
function RTV:ResetVote( szCancel, nMult, bExtend, szMsg, varArg )
  nMult = nMult or 1

  if szCancel and szCancel == "Yes" then
    self.CancelVote = nil
  end

  self.VotePossible = false
  self.Selections = {}

  self.Begin = ST()
  self.End = self.Begin + (nMult * self.DefaultExtend)

  self.Votes = 0
  for i = 1, self.VoteCount do
    self.VoteList[ i ] = 0
  end

  for _,d in pairs( self.TimeNotify ) do
    d[ 2 ] = nil
  end

  if bExtend then
    self.Extends = self.Extends + 1
    RTV.SendTimeLeft()
  end

  for _,p in pairs( player.GetHumans() ) do
    p.Rocked = nil
    p.LastVotedID = nil
    p.ResentVote = nil
  end

  if timer.Exists( self.Identifier ) then
    timer.Remove( self.Identifier )
  end

  timer.Create( self.Identifier, nMult * self.DefaultExtend, 1, self.StartVote )

  if szMsg then
    Core.Print( nil, "Notification", Core.Text( szMsg, varArg ) )
  end
end

--[[
Description: Changes the time left on the vote
--]]
function RTV.ChangeTime( nMins )
  -- Make sure there's only one RTV timer running
  if timer.Exists( RTV.Identifier ) then
    timer.Remove( RTV.Identifier )
  end

  timer.Create( RTV.Identifier, nMins * 60, 1, RTV.StartVote )

  RTV.End = ST() + nMins * 60
  RTV.SendTimeLeft()

  for _,d in pairs( RTV.TimeNotify ) do
    d[ 2 ] = nil
  end

  for i = 1, #RTV.TimeNotify do
    local item = RTV.TimeNotify[ i ]
    if nMins * 60 < item[ 1 ] * 60 then
      item[ 2 ] = true
    end
  end
end
Core.RTVChangeTime = RTV.ChangeTime

--[[
Description: Broadcasts a timeleft notification to every connected player
Notes: Runs on a timer
--]]
function RTV.TimeCheck()
  local remaining = RTV.End - ST()
  for i = 1, #RTV.TimeNotify do
    local item = RTV.TimeNotify[ i ]
    if remaining < item[ 1 ] * 60 and not item[ 2 ] then
      local text = remaining < 60 and "Less than 1 minute remaining" or ((remaining >= 60 and remaining < 120) and "1 minute remaining" or math.floor( remaining / 60 ) .. " minutes remaining")
      NetPrepare( "Global/Notify", { "Notification", text, "hourglass", 10, text } ):Broadcast()

      item[ 2 ] = true
      break
    end
  end
end

--[[
Description: Get the amount of people that can actually vote in the server
--]]
function RTV.GetVotable( exclude, plys )
  local n, ps = 0, {}

  for _,p in pairs( player.GetHumans() ) do
    if p == exclude then
      continue
    elseif (Core.Ext( "AFK", "GetPoints" )( p ) or 10) < 2 then
      continue
    elseif RTV.UseLimitations and StylePoints[ Styles.Normal ] and (not StylePoints[ Styles.Normal ][ p.UID ] or StylePoints[ Styles.Normal ][ p.UID ] == 0) then
      if p.Style != Styles.Normal then
        continue
      elseif p.Record == 0 and #player.GetHumans() > RTV.MinLimitations then
        continue
      end
    end

    n = n + 1
    ps[ #ps + 1 ] = p
  end

  return plys and ps or n
end


--[[
Description: Triggers a vote on the player if possible
--]]
function RTV.Func.Vote( ply )
  if ply.RTVLimit and ST() - ply.RTVLimit < 60 then
    return Core.Print( ply, "Notification", Core.Text( "VoteLimit", math.ceil( 60 - (ST() - ply.RTVLimit) ) ) )
  elseif ply.Rocked then
    return Core.Print( ply, "Notification", Core.Text( "VoteAlready" ) )
  elseif RTV.VotePossible then
    return Core.Print( ply, "Notification", Core.Text( "VotePeriod" ) )
  elseif ST() - RTV.Begin < RTV.WaitPeriod then
    return Core.Print( ply, "Notification", Core.Text( "VoteLimited", string.format( "%.1f", (RTV.WaitPeriod - (ST() - RTV.Begin)) / 60 ) ) )
  elseif RTV.UseLimitations and #player.GetHumans() > RTV.MinLimitations then
    if StylePoints[ Styles.Normal ] and (not StylePoints[ Styles.Normal ][ ply.UID ] or StylePoints[ Styles.Normal ][ ply.UID ] == 0) then
      if ply.Style != Styles.Normal then
        return Core.Print( ply, "Notification", Core.Text( "VoteLimitPlay" ) )
      elseif ply.Record == 0 then
        return Core.Print( ply, "Notification", Core.Text( "VoteLimitPlay" ) )
      end
    end
  end

  ply.RTVLimit = ST()
  ply.Rocked = true

  RTV.Votes = RTV.Votes + 1
  RTV.Required = math.ceil( RTV.GetVotable() * RTV.Fraction )

  local nVotes = RTV.Required - RTV.Votes
  Core.Print( nil, "Notification", Core.Text( "VotePlayer", ply:Name(), nVotes, nVotes == 1 and "vote" or "votes", math.ceil( (RTV.Votes / RTV.Required) * 100 ) ) )

  if RTV.Votes >= RTV.Required then
    RTV.StartVote()
  end
end

--[[
Description: Revokes a vote on the player if there is any
--]]
function RTV.Func.Revoke( ply )
  if RTV.VotePossible then
    return Core.Print( ply, "Notification", Core.Text( "VotePeriod" ) )
  end

  if ply.Rocked then
    ply.Rocked = false

    RTV.Votes = RTV.Votes - 1
    RTV.Required = math.ceil( RTV.GetVotable() * RTV.Fraction )

    local nVotes = RTV.Required - RTV.Votes
    Core.Print( nil, "Notification", Core.Text( "VoteRevoke", ply:Name(), nVotes, nVotes == 1 and "vote" or "votes" ) )
  else
    Core.Print( ply, "Notification", Core.Text( "VoteRevokeFail" ) )
  end
end

--[[
Description: Nominates a map
Notes: Whole lot of extra logic for sorting the maps
--]]
function RTV.Func.Nominate( ply, szMap )
  local szIdentifier = "Nomination"
  local varArgs = { ply:Name(), szMap }

  if RTV.UseLimitations and #player.GetHumans() > RTV.MinLimitations and table.HasValue( RTV.LatestList, szMap ) then
    local at = 1
    for id,map in pairs( RTV.LatestList ) do
      if map == szMap then
        at = id
        break
      end
    end

    return Core.Print( ply, "Notification", Core.Text( "NominateRecent", at - 1 ) )
  end

  if ply.NominatedMap and ply.NominatedMap != szMap then
    if RTV.Nominations[ ply.NominatedMap ] then
      for id,p in pairs( RTV.Nominations[ ply.NominatedMap ] ) do
        if p == ply then
          table.remove( RTV.Nominations[ ply.NominatedMap ], id )

          if #RTV.Nominations[ ply.NominatedMap ] == 0 then
            RTV.Nominations[ ply.NominatedMap ] = nil
          end

          szIdentifier = "NominationChange"
          varArgs = { ply:Name(), ply.NominatedMap, szMap }

          break
        end
      end
    end
  elseif ply.NominatedMap and ply.NominatedMap == szMap then
    return Core.Print( ply, "Notification", Core.Text( "NominationAlready" ) )
  end

  if not RTV.Nominations[ szMap ] then
    RTV.Nominations[ szMap ] = { ply }
    ply.NominatedMap = szMap
    Core.Print( nil, "Notification", Core.Text( szIdentifier, varArgs ) )
  elseif type( RTV.Nominations ) == "table" then
    local Included = false
    for _,p in pairs( RTV.Nominations[ szMap ] ) do
      if p == ply then Included = true break end
    end

    if not Included then
      table.insert( RTV.Nominations[ szMap ], ply )
      ply.NominatedMap = szMap
      Core.Print( nil, "Notification", Core.Text( szIdentifier, varArgs ) )
    else
      return Core.Print( ply, "Notification", Core.Text( "NominationAlready" ) )
    end
  end
end

--[[
Description: Returns a list of who has voted and who hasn't voted
--]]
function RTV.Func.Who( ply )
  local Voted = {}
  local NotVoted = {}

  for _,p in pairs( RTV.GetVotable( nil, true ) ) do
    if p.Rocked then
      Voted[ #Voted + 1 ] = p:Name()
    else
      NotVoted[ #NotVoted + 1 ] = p:Name()
    end
  end

  RTV.Required = math.ceil( RTV.GetVotable() * RTV.Fraction )
  Core.Print( ply, "Notification", Core.Text( "VoteList", RTV.Required, #Voted, string.Implode( ", ", Voted ), #NotVoted, string.Implode( ", ", NotVoted ) ) )
end

--[[
Description: Checks how many votes are left before the map changes
--]]
function RTV.Func.Check( ply )
  RTV.Required = math.ceil( RTV.GetVotable() * RTV.Fraction )

  local nVotes = RTV.Required - RTV.Votes
  Core.Print( ply, "Notification", Core.Text( "VoteCheck", nVotes, nVotes == 1 and "vote" or "votes" ) )
end

--[[
Description: Returns the time remaining before a change of maps
--]]
function RTV.Func.Left( ply )
  Core.Print( ply, "Notification", Core.Text( "MapTimeLeft", Timer.Convert( RTV.End - ST() ) ) )
end

--[[
Description: Resends the voting screen to the player
--]]
function RTV.Func.Revote( ply, bGet )
  if bGet then return RTV.VotePossible end
  if not RTV.VotePossible then return Core.Print( ply, "Notification", Core.Text( "VotePeriodActive" ) ) end
  ply.ResentVote = true

  RTV.Sent.Countdown = math.Clamp( RTV.VoteTimeEnd - ST(), 0, RTV.VoteTime )
  Core.Send( ply, "RTV/List", RTV.Sent )
end

--[[
Description: Gets a type of map requested by the player
--]]
function RTV.Func.MapFunc( ply, key )
  if Timer.Maps == 0 then return end

  if key == "playinfo" then
    Core.Print( ply, "General", Core.Text( "TimerMapsInfo" ) )
  elseif key == "leastplayed" then
    local temp = {}
    for map,data in pairs( Maps ) do
      temp[ #temp + 1 ] = { Map = map, Plays = data.nPlays or 0 }
    end

    table.SortByMember( temp, "Plays", true )

    local str = {}
    for i = 1, 5 do
      str[ i ] = temp[ i ].Map .. " (" .. temp[ i ].Plays .. " plays)"
    end

    Core.Print( ply, "General", Core.Text( "TimerMapsDisplay", "Least", string.Implode( ", ", str ) ) )
  elseif key == "mostplayed" or key == "overplayed" then
    local temp = {}
    for map,data in pairs( Maps ) do
      temp[ #temp + 1 ] = { Map = map, Plays = data.nPlays or 0 }
    end

    table.SortByMember( temp, "Plays", false )

    local str = {}
    for i = 1, 5 do
      str[ i ] = temp[ i ].Map .. " (" .. temp[ i ].Plays .. " plays)"
    end

    Core.Print( ply, "General", Core.Text( "TimerMapsDisplay", "Most", string.Implode( ", ", str ) ) )
  elseif key == "lastplayed" or key == "lastmaps" then
    local temp = {}
    for map,data in pairs( Maps ) do
      temp[ #temp + 1 ] = { Map = map, Date = data.szDate }
    end

    table.SortByMember( temp, "Date", false )

    local str = {}
    for i = 1, 5 do
      str[ i ] = temp[ i ].Map .. " (" .. temp[ i ].Date .. ")"
    end

    Core.Print( ply, "General", Core.Text( "TimerMapsDisplay", "Last", string.Implode( ", ", str ) ) )
  elseif key == "randommap" then
    for map,data in RandomPairs( Maps ) do
      Core.Print( ply, "General", Core.Text( "TimerMapsRandom", map ) )
      break
    end
  end
end

--[[
Description: Shows which map you have nominated
--]]
function RTV.Func.Which( ply )
  Core.Print( ply, "Notification", ply.NominatedMap and Core.Text( "MapNominated", "", ply.NominatedMap ) or Core.Text( "MapNominated", "n't", "a map" ) )
end

--[[
Description: Shows all nominated maps
--]]
function RTV.Func.Nominations( ply )
  local MapList, MaxCount = {}, 1
  for map,voters in pairs( RTV.Nominations ) do
    local plys = { map }
    for _,v in pairs( voters ) do
      if IsValid( v ) then
        plys[ #plys + 1 ] = v:Name()
      end
    end

    -- If we've got an entry already, expand, otherwise create it
    local amount = #plys - 1
    local count = MapList[ amount ] and #MapList[ amount ]
    if not count then
      MapList[ amount ] = { plys }
    else
      MapList[ amount ][ count + 1 ] = plys
    end

    -- Increase max count if necessary
    if amount > MaxCount then
      MaxCount = amount
    end
  end

  -- Loop over the most important nominations
  local str, add = Core.Text( "MapNominations" )
  for i = MaxCount, 1, -1 do
    if MapList[ i ] then
      for j = 1, #MapList[ i ] do
        str = str .. "- " .. table.remove( MapList[ i ][ j ], 1 ) .. " (By " .. i .. " player(s): " .. string.Implode( ", ", MapList[ i ][ j ] ) .. ")\n"
        add = true
      end
    end
  end

  -- Print the message out
  Core.Print( ply, "Notification", add and (str .. Core.Text( "MapNominationChance" )) or Core.Text( "MapNominationsNone" ) )
end

--[[
Description: Revokes a player map nomination
--]]
function RTV.Func.Denominate( ply )
  if not ply.NominatedMap then
    return Core.Print( ply, "Notification", Core.Text( "MapNominationNone" ) )
  end

  if RTV.Nominations[ ply.NominatedMap ] then
    for id,p in pairs( RTV.Nominations[ ply.NominatedMap ] ) do
      if p == ply then
        table.remove( RTV.Nominations[ ply.NominatedMap ], id )

        if #RTV.Nominations[ ply.NominatedMap ] == 0 then
          RTV.Nominations[ ply.NominatedMap ] = nil
        end

        break
      end
    end
  end

  ply.NominatedMap = nil

  Core.Print( ply, "Notification", Core.Text( "MapNominationRevoke" ) )
end

--[[
Description: Sets the player to automatically vote extend
--]]
function RTV.Func.Extend( ply )
  RTV.AutoExtend[ ply ] = not RTV.AutoExtend[ ply ]

  Core.Print( ply, "Notification", Core.Text( "MapAutoExtend", not RTV.AutoExtend[ ply ] and "no longer " or "" ) )
end

--[[
Description: The function that triggers the RTV.Func's
--]]
function PLAYER:RTV( szType, args )
  if RTV.Func[ szType ] then
    return RTV.Func[ szType ]( self, args )
  end
end


--[[
Description: Process a received vote
--]]
function RTV.ReceiveVote( ply, varArgs )
  local nVote, nOld = varArgs[ 1 ], varArgs[ 2 ]
  if not RTV.VotePossible or not nVote then return end
  if ply.LastVotedID == nVote then return end

  if not nOld and ply.ResentVote and ply.LastVotedID then
    nOld = ply.LastVotedID
    ply.ResentVote = nil
  end

  ply.LastVotedID = nVote

  local nAdd = 1
  if not nOld then
    if nVote < 1 or nVote > 7 then return end
    if not RTV.VoteList[ nVote ] then RTV.VoteList[ nVote ] = 0 end
    RTV.VoteList[ nVote ] = RTV.VoteList[ nVote ] + nAdd
  else
    if nVote < 1 or nVote > 7 or nOld < 1 or nOld > 7 then return end
    if not RTV.VoteList[ nVote ] then RTV.VoteList[ nVote ] = 0 end
    if not RTV.VoteList[ nOld ] then RTV.VoteList[ nOld ] = 0 end
    RTV.VoteList[ nVote ] = RTV.VoteList[ nVote ] + nAdd
    RTV.VoteList[ nOld ] = RTV.VoteList[ nOld ] - nAdd
    if RTV.VoteList[ nOld ] < 0 then RTV.VoteList[ nOld ] = 0 end
  end

  NetPrepare( "RTV/VoteList", RTV.VoteList ):Broadcast()
end
Core.Register( "Global/Vote", RTV.ReceiveVote )

--[[
Description: Sends the map list to a player
Notes: Encodes it here since it might take a while before anyone needs a new map list
--]]
local EncodedData, EncodedLength
function RTV.GetMapList( ply, varArgs )
  if varArgs[ 1 ] != RTV.Version then
    if not EncodedData or not EncodedLength then
      EncodedData = util.Compress( util.TableToJSON( { Maps, RTV.Version, Timer.Maps } ) )
      EncodedLength = #EncodedData
    end

    if not EncodedData or not EncodedLength then
      Core.Print( ply, "Notification", Core.Text( "MiscMissingMapList" ) )
    else
      net.Start( "BinaryTransfer" )
      net.WriteString( "List" )
      net.WriteString( varArgs[ 2 ] or "" )
      net.WriteUInt( EncodedLength, 32 )
      net.WriteData( EncodedData, EncodedLength )
      net.Send( ply )
    end
  end
end
Core.Register( "Global/MapList", RTV.GetMapList )

--[[
Description: Called when the player tries to open another map list and it automatically updates
--]]
function RTV.MapListUpdated( ply, varArgs )
  Core.RemoveCommandLimit( ply )
  GAMEMODE:PlayerSay( ply, varArgs[ 1 ] )
end
Core.Register( "Global/MapUpdateCmd", RTV.MapListUpdated )

--[[
Description: Informs the client about how much time is left on the map
--]]
function RTV.SendTimeLeft( ply )
  local ar = NetPrepare( "Timer/TimeLeft" )
  ar:Double( RTV.End - ST() )

  if ply then
    ar:Send( ply )
  else
    ar:Broadcast()
  end
end

--[[
Description: Update the version number and increment it
--]]
function RTV:UpdateVersion( nAmount )
  EncodedData, EncodedLength = nil, nil

  self.Version = self.Version + (nAmount or 1)
  file.Write( Config.BaseType .. "/maplistversion.txt", tostring( self.Version ) )
end

--[[
Description: Checks if the map exists on the disk
--]]
function RTV.IsAvailable( szMap )
  return file.Exists( "maps/" .. szMap .. ".bsp", "GAME" )
end

--[[
Description: Checks if the map exists in the loaded database table
--]]
function RTV.MapExists( szMap )
  return not not Maps[ szMap ]
end

--[[
Description: Returns the loaded data about a map
Notes: Could add more but this is only necessary to be on the client itself
--]]
function RTV.GetMapData( szMap )
  local tab = Maps[ szMap ]

  if tab then
    if Config.IsSurf then
      return { szMap, tab["nMultiplier"], tab["nPlays"], tab["nTier"] or 1, tab["nType"] or 0 }
    else
      return { szMap, tab["nMultiplier"], tab["nPlays"] }
    end
  else
    if Config.IsSurf then
      return { szMap, 0, 0, 1, 0 }
    else
      return { szMap, 0, 0 }
    end
  end
end
