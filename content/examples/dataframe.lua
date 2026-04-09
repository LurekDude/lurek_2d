-- examples/dataframe.lua
-- Columnar data tables with SQL-style operations
-- API: lurek.dataframe

--------------------------------------------------------------------------------
-- Constructors
--------------------------------------------------------------------------------

-- Empty dataframe
local df = lurek.dataframe.newDataFrame()

-- From an array of row tables
local df2 = lurek.dataframe.fromTable({
    { name = "Alice", age = 30, score = 95.5 },
    { name = "Bob",   age = 25, score = 78.0 },
    { name = "Carol", age = 35, score = 88.5 },
    { name = "Dave",  age = 28, score = 91.0 },
})

-- From CSV text
local csv = "name,age,score\nAlice,30,95.5\nBob,25,78.0\n"
local df3 = lurek.dataframe.fromCSV(csv)

-- From JSON text
local json = '[{"name":"Alice","age":30},{"name":"Bob","age":25}]'
local df4 = lurek.dataframe.fromJSON(json)

-- From binary (toBinary round-trip)
local bin = df2:toBinary()
local df5 = lurek.dataframe.fromBinary(bin)

-- Random data from column definitions
-- Each def: {name, hint} where hint is "string"|"integer"|"float"|"bool"
local dfRand = lurek.dataframe.random(
    { { "id", "integer" }, { "label", "string" }, { "value", "float" } },
    50,     -- row count
    42      -- optional seed
)

-- Empty database
local db = lurek.dataframe.newDatabase()

--------------------------------------------------------------------------------
-- DataFrame — dimensions and schema
--------------------------------------------------------------------------------

local rows  = df2:nrows()     -- number of rows
local cols  = df2:ncols()     -- number of columns
local names = df2:columns()   -- table of column name strings
local cnt   = df2:count()     -- same as nrows

--------------------------------------------------------------------------------
-- Schema modification
--------------------------------------------------------------------------------

df2:addColumn("status", "active")  -- add column with default value
df2:removeColumn("status")          -- remove by name
df2:rename("score", "points")       -- rename a column

-- Column values as a flat table
local ages = df2:getColumn("age")       -- {30, 25, 35, 28}
local agesByIdx = df2:getColumn(2)      -- columns are also 1-based indexable

--------------------------------------------------------------------------------
-- Row operations
--------------------------------------------------------------------------------

local newIdx = df2:addRow({ name = "Eve", age = 22, points = 99.0 })  -- returns 1-based index
df2:removeRow(newIdx)

-- Access a full row as a table
local row1 = df2:getRow(1)   -- { name="Alice", age=30, points=95.5 }

-- Get / set individual cell
local val = df2:getValue(1, "name")      -- "Alice"
local val2 = df2:getValue(2, 2)          -- 25 (row 2, col 2)
df2:setValue(1, "points", 97.0)

--------------------------------------------------------------------------------
-- Filtering
--------------------------------------------------------------------------------

-- Supported operators: "==", "!=", "<", ">", "<=", ">="
local adults    = df2:filter("age", ">=", 30)
local highScore = df2:filter("points", ">", 90)
local named     = df2:filter("name", "==", "Alice")

--------------------------------------------------------------------------------
-- Sorting and slicing
--------------------------------------------------------------------------------

local sorted  = df2:sort("age", true)   -- ascending
local desc    = df2:sort("points")      -- default ascending; pass false for desc
local firstN  = df2:head(2)             -- first 2 rows (default 5)
local lastN   = df2:tail(2)             -- last 2 rows
local sliced  = df2:slice(2, 4)         -- rows 2 through 4 inclusive (1-based)

--------------------------------------------------------------------------------
-- Column selection
--------------------------------------------------------------------------------

local projected = df2:select("name", "points")   -- keep only these columns
local uniqueAges = df2:unique("age")              -- {22, 25, 28, 30, 35}

--------------------------------------------------------------------------------
-- Grouping and aggregation
--------------------------------------------------------------------------------

-- groupBy returns a table keyed by unique values in the column
local groups = df2:groupBy("status")
for key, group_df in pairs(groups) do
    print(key, group_df:nrows())
end

-- Statistical aggregations
local total  = df2:sum("points")
local avg    = df2:mean("points")
local minVal = df2:min("age")
local maxVal = df2:max("age")
local med    = df2:median("points")
local std    = df2:stddev("points")
local vari   = df2:variance("points")

-- describe returns a summary DataFrame (count, mean, std, min, max per column)
local summary = df2:describe()
print(summary:toCSV())

-- Value frequency count
local counts = df2:countBy("name")  -- returns DataFrame {value, count}

--------------------------------------------------------------------------------
-- Joining and merging
--------------------------------------------------------------------------------

local extra = lurek.dataframe.fromTable({
    { name = "Alice", rank = "A" },
    { name = "Bob",   rank = "B" },
})

-- Join: thisCol, otherCol, type ("inner" | "left" | "right" | "outer")
local joined = df2:join(extra, "name", "name", "inner")

-- Merge: append rows from another DataFrame in-place
local moreRows = lurek.dataframe.fromTable({
    { name = "Frank", age = 40, points = 70.0 },
})
df2:merge(moreRows)

--------------------------------------------------------------------------------
-- Cleaning
--------------------------------------------------------------------------------

-- Drop rows with nil in a column
local clean = df2:dropNil("points")

-- Fill nil values
df2:fillNil("points", 0.0)

--------------------------------------------------------------------------------
-- Sampling
--------------------------------------------------------------------------------

local sample = df2:sample(3, 99)  -- 3 random rows with seed 99

--------------------------------------------------------------------------------
-- Apply (in-place transform)
--------------------------------------------------------------------------------

df2:apply("points", function(v)
    return v * 1.1  -- 10% bonus
end)

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

local csv_out  = df2:toCSV()
local json_out = df2:toJSON()
local bin_out  = df2:toBinary()
local tbl_out  = df2:toTable()   -- array of row tables

for i, row in ipairs(tbl_out) do
    print(i, row.name, row.points)
end

--------------------------------------------------------------------------------
-- Database — named collection of DataFrames
--------------------------------------------------------------------------------

db:addTable("players", df2)
db:addTable("extras", extra)

local hasPlayers = db:hasTable("players")   -- true
local players2   = db:getTable("players")   -- DataFrame copy
local tableNames = db:listTables()          -- {"players", "extras"}
local numTables  = db:tableCount()          -- 2

-- SQL query against all tables in the database
local result = db:query("SELECT name, points FROM players WHERE points > 80")
print(result:toCSV())

-- Merge another database in
local db2 = lurek.dataframe.newDatabase()
db2:addTable("extra_data", lurek.dataframe.newDataFrame())
db:merge(db2)

-- Export the whole database to JSON
local db_json = db:toJSON()

-- Remove a table
db:removeTable("extras")

-- Clear all tables
db:clear()

-- ─── DataFrame ─────────────────────────────────────────────────────────────────

local clone = dataframe:clone()  -- Returns a deep copy of this DataFrame
local to_string = dataframe:toString()  -- Returns a formatted string table representation
local dataframe_type = dataframe:type()  -- "DataFrame"
local dataframe_is_type = dataframe:typeOf("DataFrame")  -- Returns true if this object is of the given type

-- ─── Database ──────────────────────────────────────────────────────────────────

local database_type = database:type()  -- "Database"
local database_is_type = database:typeOf("Database")  -- Returns true if this object is of the given type
