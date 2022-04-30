-- Define local table
local database = {}
database.Debug = GM.Config.Vars.Get("SQL_Debug", false)
database.Driver = GM.Config.Vars.Get("SQL_Driver", "sqlite")
database.Credentials = {
  Host = GM.Config.Vars.Get("SQL_Host", ""),
  User = GM.Config.Vars.Get("SQL_User", ""),
  Pass = GM.Config.Vars.Get("SQL_Pass", ""),
  Port = GM.Config.Vars.Get("SQL_Port", ""),
  Database = GM.Config.Vars.Get("SQL_Database", "")
}

-- Modules
local lang = GM.Language

-- Functions
local next, tonumber = next, tonumber

-- Add text
lang.Add({
  DatabaseInit = "Connected using %s (%s)",
  DatabaseModuleFail = "Failed to load database module '%s'",
  DatabaseModuleVersion = "Database module version is not supported. Use version %d instead",
  DatabaseConnectionFail = "Couldn't connect to the database. Error: %s",
  DatabaseDriverFail = "Unknown database driver specified: %s",
  DatabaseQueryNoConnection = "Not connected. Can't prepare query",
  DatabaseQueryError = "Error occurred while executing query.\nQuery: %s\nError: %s",
  DatabaseTransactionError = "Error occurred while executing a transaction.\n%s"
})

--[[---------------------------------------------------------
  Desc: Initializes the database
-----------------------------------------------------------]]
function database:Start()
  if self.Driver == "sqlite" then
    self.connection = self.SQLiteDriver
    self.query_options = 0
    lang.Console("DatabaseInit", self.Driver, "local file")

    database:Setup()
  elseif self.Driver == "mysql" then
    if not self.ModuleRequired then
      require("mysqloo")
      self.ModuleRequired = true
    end

    -- Check if the mysqloo version is correct
    if type(mysqloo) ~= "table" then
      lang.Console("DatabaseModuleFail", self.Driver)
    elseif tonumber(mysqloo.VERSION) ~= 9 then
      lang.Console("DatabaseModuleVersion", 9)
    end

    -- Create a database object
    local credentials = self.Credentials
    local port = tonumber(credentials.Port) or 0
    local connection = mysqloo.connect(credentials.Host, credentials.User, credentials.Pass, credentials.Database, port ~= 0 and port)

    -- Handles a succesful connection
    function connection:onConnected()
      lang.Console("DatabaseInit", database.Driver, credentials.User .. "@" .. credentials.Host)
      database:Setup()
    end

    -- Handles a failed connection
    function connection:onConnectionFailed(e)
      lang.Console("DatabaseConnectionFail", e)

      -- TODO: Retry mechanism
    end

    -- Attempt to connect
    connection:connect()

    -- Save the connection
    self.connection = connection
    self.query_options = mysqloo.OPTION_NUMERIC_FIELDS
  else
    lang.Console("DatabaseDriverFail", self.Driver)
  end
end

--[[---------------------------------------------------------
  Desc: Prepares a query
-----------------------------------------------------------]]
function database:Prepare(...)
  if not self.connection then
    return lang.Console("DatabaseQueryNoConnection")
  end

  -- Iterate over the supplied args and count queries
  local amount = 0
  local args = { ... }
  for i = 1, #args do
    if type(args[i]) == "string" then
      amount = amount + 1
    end
  end

  -- Create a transaction if we have multiple queries
  local transaction, query
  if amount > 1 then
    transaction = self.connection:createTransaction()

    -- Executed after the query is done
    function transaction:onSuccess()
      local data = {}
      local queries = self:getQueries()
      for i = 1, #queries do
        data[i] = queries[i]:getData()
      end

      if self.callback then
        self.callback(data)
      end
    end

    -- Executed if any of the queries in the transaction fail
    function transaction:onError(err)
      local text = {}
      local queries = self:getQueries()
      for i = 1, #queries do
        text[i] = "Query " .. i .. ": " .. queries[i]:error() .. " (query was: " .. queries[i].query .. ")"
      end

      lang.Console("DatabaseTransactionError", string.Implode("\n", text))

      if self.callback then
        self.callback({})
      end
    end
  end

  -- Setup the PreparedQuery objects
  for i = 1, #args do
    if type(args[i]) == "string" then
      query = self.connection:prepare(args[i])
      query.query = args[i]

      function query:onSuccess(data)
        if self.callback then
          self.callback(data)
        end
      end

      function query:onError(err)
      	print("An error occured while executing the query: ", err)

        if self.callback then
          self.callback(data)
        end
      end

      -- Check if we have any params
      local params = args[i + 1]
      if type(params) == "table" then
        for j = 1, #params do
          if type(params[j]) == "string" then
            query:setString(j, params[j])
          elseif type(params[j]) == "nil" then
            query:setNull(j)
          elseif type(params[j]) == "number" then
            query:setNumber(j, params[j])
          elseif type(params[j]) == "boolean" then
            query:setBoolean(j, params[j])
          end
        end
      end

      -- Add query to transaction
      if transaction then
        transaction:addQuery(query)
      end
    end
  end

  -- Create start point for the object
  local obj = transaction or query
  function obj:execute(callback)
    self.callback = callback
    self:start()
  end

  -- Return executable object
  return obj
end

-- SQL Table Mappings
local field = { INT = 0, DEC = 1, STR = 2, TXT = 3, DATE = 4 }
local mod = { NONE = 0, PRIMARY = 1, INCREMENT = 2, NOTNULL = 4 }
local keywords = {
  [field.INT] = { "INTEGER", "int(11)" },
  [field.DEC] = { "INTEGER", "double" },
  [field.STR] = { "TEXT", "varchar(255)" },
  [field.DATE] = { "INTEGER", "int(11)"	},
  [field.TXT] = { "TEXT", "text" }
}

local structure = {
  ["players"] = {
    { "steamid", field.STR, bit.bor(mod.PRIMARY, mod.NOTNULL) },
    { "connections", field.INT, mod.NOTNULL },
    { "playtime", field.DEC, mod.NOTNULL },
    { "last_seen", field.DATE, mod.NOTNULL }
  },

  ["maps"] = {
    { "name", field.STR, bit.bor(mod.PRIMARY, mod.NOTNULL) },
    { "plays", field.INT, mod.NOTNULL },
    { "hours", field.DEC, mod.NOTNULL },
    { "added", field.DATE, mod.NOTNULL },
    { "options", field.INT, mod.NONE }
  },

  ["times"] = {
    { "player", field.STR, mod.NOTNULL },
    { "map", field.STR, mod.NOTNULL },
    { "style", field.INT, mod.NOTNULL },
    { "bonus", field.INT, mod.NOTNULL },
    { "time", field.DEC, mod.NOTNULL },
    { "points", field.DEC, mod.NOTNULL },
    { "date", field.DATE, mod.NOTNULL },
    { "info", field.TXT, mod.NONE } -- TODO: Change this into multiple columns
  },

  ["zones"] = {
    { "map", field.STR, mod.NOTNULL },
    { "type", field.STR, mod.NOTNULL },
    { "min", field.STR, mod.NOTNULL },
    { "max", field.STR, mod.NOTNULL },
    { "data", field.STR, mod.NONE }
  }
}

--[[---------------------------------------------------------
  Desc: Sets up the database structure
-----------------------------------------------------------]]
function database:Setup(custom)
  local driver_id
  if self.Driver == "sqlite" then
    driver_id = 1
  elseif self.Driver == "mysql" then
    driver_id = 2
  end

  local queries = {}
  for name, data in pairs(custom or structure) do
    local query = "CREATE TABLE IF NOT EXISTS `" .. name .. "` ("
    local fields, primary = {}

    for i = 1, #data do
      local partial = ""
      local column_name = data[i][1]
      local column_type = data[i][2]
      local column_options = data[i][3]

      partial = partial .. "`" .. column_name .. "` " .. keywords[column_type][driver_id]

      if driver_id == 1 then
        if column_options > 0 then
          local opts = {}
          if bit.band(column_options, mod.PRIMARY) > 0 then opts[#opts + 1] = "PRIMARY KEY" end
          if bit.band(column_options, mod.INCREMENT) > 0 then opts[#opts + 1] = "AUTOINCREMENT" end
          if bit.band(column_options, mod.NOTNULL) > 0 then opts[#opts + 1] = "NOT NULL" end

          partial = partial .. " " .. string.Implode(" ", opts)
        end

        fields[#fields + 1] = partial
      elseif driver_id == 2 then
        if column_options > 0 then
          local opts = {}
          if bit.band(column_options, mod.NOTNULL) > 0 then opts[#opts + 1] = "NOT NULL" end
          if bit.band(column_options, mod.INCREMENT) > 0 then opts[#opts + 1] = "AUTO_INCREMENT" end
          if bit.band(column_options, mod.PRIMARY) > 0 then primary = "PRIMARY KEY (`" .. column_name .. "`)" end

          partial = partial .. " " .. string.Implode(" ", opts)
        end

        fields[#fields + 1] = partial
      end
    end

    -- Append the primary key bit if it was set
    if primary then
      fields[#fields + 1] = primary
    end

    queries[#queries + 1] = query .. string.Implode(", ", fields) .. ");"
  end

  local query = self:Prepare(unpack(queries))
  query:execute(function()
    -- If it wasn't a custom setup, we want to let the game know our database is ready
    if not custom then
      hook.Run("OnDatabaseConnected")
    end
  end)
end

--[[---------------------------------------------------------
  Desc: Returns the table creation field types and modifiers
-----------------------------------------------------------]]
function database.GetTableDescriptors()
  return field, mod
end

-- Create the SQLite driver wrapper
local sqlite = {}
local sql = sql

-- Define sqlite objects
sqlite.query = {}
sqlite.query.__index = sqlite.query
sqlite.transaction = {}
sqlite.transaction.__index = sqlite.transaction

-- Query constructor
function sqlite:prepare(query)
  local tab = { query = query }
  setmetatable(tab, self.query)
  return tab
end

-- Starts a query
function sqlite.query:start()
  self.data = sql.Query(self.query)

  if self.data == false then
    self.error_msg = sql.LastError()
    self:onError(self.error_msg)
  else
    if self.data == nil then
      self.data = {}
    else
      self:parseData(self.data)
    end

    self:onSuccess(self.data)
  end

  return self.data
end

-- Get the query error
function sqlite.query:error()
  return self.error_msg or ""
end

-- Get the query data
function sqlite.query:getData()
  return self.data
end

-- Parse the data types
function sqlite.query:parseData(data)
  for i = 1, #data do
    for j, v in next, data[i] do
      if tonumber(v) then
        data[i][j] = tonumber(v)
      end
    end
  end
end

-- Replace ? with string
function sqlite.query:setString(i, str)
  self.query = string.gsub(self.query, "?", sql.SQLStr(str), 1)
end

-- Replace ? with NULL
function sqlite.query:setNull(i)
  self.query = string.gsub(self.query, "?", "NULL", 1)
end

-- Replace ? with number
function sqlite.query:setNumber(i, num)
  self.query = string.gsub(self.query, "?", num, 1)
end

-- Replace ? with number for bool
function sqlite.query:setBoolean(i, bool)
  self:setNumber(i, bool and 1 or 0)
end

-- Transaction constructor
function sqlite:createTransaction()
  local transaction = { queries = {} }
  setmetatable(transaction, self.transaction)
  return transaction
end

-- Start a chain execution of queries in the transaction
function sqlite.transaction:start()
  local failed
  for i = 1, #self.queries do
    if self.queries[i]:start() == false then
      failed = self.queries[i]:error()
      break
    end
  end

  if failed then
    self:onError(failed)
  else
    self:onSuccess()
  end
end

-- Add a query to the transaction
function sqlite.transaction:addQuery(query)
  query.transaction = self
  query.onSuccess = self.callbackVoid
  query.onError = self.callbackVoid
  self.queries[#self.queries + 1] = query
end

-- Get all queries in a transaction
function sqlite.transaction:getQueries()
  return self.queries
end

-- Void function for individual query callbacks
function sqlite.transaction:callbackVoid()
end

-- Store the driver
database.SQLiteDriver = sqlite

-- Store the database
GM.Database = database
