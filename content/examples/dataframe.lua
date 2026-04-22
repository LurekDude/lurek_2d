-- content/examples/dataframe.lua
-- Hand-written coverage of the lurek.dataframe API (64 items).
--
-- Every --@api-stub: block below is a real love2d-wiki-style snippet
-- showing how to call the API in actual game context. The DataFrame is
-- column-oriented; rows are accessed by 1-based index, columns by name
-- or 1-based index. Database holds named DataFrames and supports SQL
-- queries that JOIN across them.
--
-- Run: cargo run -- content/examples/dataframe.lua

-- ── lurek.dataframe.* functions ──

--@api-stub: lurek.dataframe.newDataFrame
-- Creates a new empty DataFrame.
-- Start with an empty frame when you will populate columns and rows yourself.
do  -- lurek.dataframe.newDataFrame
  local stats = lurek.dataframe.newDataFrame()
  stats:addColumn("name", "")
  stats:addColumn("score", 0)
  stats:addRow({name = "Alice", score = 1200})
end

--@api-stub: lurek.dataframe.newDatabase
-- Creates a new empty Database.
-- Use a Database to hold several related DataFrames so you can JOIN them with SQL.
do  -- lurek.dataframe.newDatabase
  local db = lurek.dataframe.newDatabase()
  local players = lurek.dataframe.fromTable({{id = 1, name = "Alice"}})
  db:addTable("players", players)
  lurek.log.info("tables: " .. db:tableCount())
end

--@api-stub: lurek.dataframe.fromTable
-- Creates a DataFrame from an array of row tables.
-- Best when your rows already exist as Lua tables (e.g. loaded save data).
do  -- lurek.dataframe.fromTable
  local rows = {
    {name = "goblin", hp = 30, level = 2},
    {name = "orc",    hp = 60, level = 5},
  }
  local enemies = lurek.dataframe.fromTable(rows)
  lurek.log.info("loaded " .. enemies:nrows() .. " enemies")
end

--@api-stub: lurek.dataframe.fromCSV
-- Parses a CSV string into a DataFrame.
-- Use for spreadsheet-authored game data — the first row is treated as the header.
do  -- lurek.dataframe.fromCSV
  local csv = "weapon,damage,cost\nsword,12,50\nbow,8,40\n"
  local items = lurek.dataframe.fromCSV(csv)
  lurek.log.info("avg damage = " .. items:mean("damage"))
end

--@api-stub: lurek.dataframe.fromJSON
-- Parses a JSON string into a DataFrame.
-- Use when reading data emitted by a web service or another tool.
do  -- lurek.dataframe.fromJSON
  local json = '[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]'
  local players = lurek.dataframe.fromJSON(json)
  lurek.log.info("rows: " .. players:nrows())
end

--@api-stub: lurek.dataframe.fromBinary
-- Deserializes a binary LVDF string into a DataFrame.
-- Round-trip a DataFrame written by toBinary — fastest format for save files.
do  -- lurek.dataframe.fromBinary
  local original = lurek.dataframe.fromTable({{x = 1}, {x = 2}})
  local blob = original:toBinary()
  local restored = lurek.dataframe.fromBinary(blob)
  lurek.log.info("restored " .. restored:nrows() .. " rows")
end

--@api-stub: lurek.dataframe.random
-- Generates a DataFrame with random data from column definitions.
-- Generate test fixtures or procedural enemy stats with reproducible seeds.
do  -- lurek.dataframe.random
  local defs = {{"id", "id"}, {"hp", "int"}, {"name", "name"}}
  local mob_pool = lurek.dataframe.random(defs, 100, 42)
  lurek.log.info("generated " .. mob_pool:nrows() .. " mobs")
end

-- ── DataFrame methods ──

--@api-stub: DataFrame:nrows
-- Returns the number of rows.
-- Branch on row count to skip empty-frame work like rendering or stat aggregation.
do  -- DataFrame:nrows
  local df = lurek.dataframe.fromTable({{name = "Alice"}, {name = "Bob"}})
  if df:nrows() > 0 then
    lurek.log.info("first player: " .. df:getValue(1, "name"))
  end
end

--@api-stub: DataFrame:ncols
-- Returns the number of columns.
-- Use when iterating columns by index or validating an imported schema.
do  -- DataFrame:ncols
  local df = lurek.dataframe.fromTable({{x = 1, y = 2, z = 3}})
  for i = 1, df:ncols() do
    lurek.log.info("column " .. i .. " = " .. df:columns()[i])
  end
end

--@api-stub: DataFrame:columns
-- Returns a table of column names.
-- Fetch the header list once when building UI tables or driving column selectors.
do  -- DataFrame:columns
  local df = lurek.dataframe.fromTable({{hp = 100, mp = 50}})
  local headers = df:columns()
  for _, name in ipairs(headers) do
    lurek.log.info("col: " .. name)
  end
end

--@api-stub: DataFrame:count
-- Returns the row count (alias for nrows).
-- Same as nrows — handy when reading code that pretends DataFrames are SQL tables.
do  -- DataFrame:count
  local df = lurek.dataframe.fromTable({{kill = 1}, {kill = 1}, {kill = 1}})
  local kills = df:count()
  lurek.log.info("session kills: " .. kills)
end

--@api-stub: DataFrame:removeColumn
-- Removes a column by name or index.
-- Drop sensitive or oversized columns before serialising for the network or save.
do  -- DataFrame:removeColumn
  local df = lurek.dataframe.fromTable({{name = "Alice", password = "x", score = 9}})
  df:removeColumn("password")
  lurek.log.info(df:toCSV())
end

--@api-stub: DataFrame:rename
-- Renames the column `old_name` to `new_name` in this DataFrame.
-- Rename imported columns to engine-internal names so downstream code stays stable.
do  -- DataFrame:rename
  local df = lurek.dataframe.fromCSV("Player Name,Score\nAlice,1200\n")
  df:rename("Player Name", "name")
  lurek.log.info("first column is now " .. df:columns()[1])
end

--@api-stub: DataFrame:getColumn
-- Returns all values in a column as a table.
-- Pull one column out as a plain array for use with lurek.math or table iteration.
do  -- DataFrame:getColumn
  local df = lurek.dataframe.fromTable({{x = 1}, {x = 2}, {x = 3}})
  local xs = df:getColumn("x")
  lurek.log.info("first x = " .. xs[1] .. ", last x = " .. xs[#xs])
end

--@api-stub: DataFrame:addRow
-- Adds a row from an optional table of name-value pairs, returns 1-based index.
-- Use for incremental logging — return value is the 1-based index of the new row.
do  -- DataFrame:addRow
  local log_df = lurek.dataframe.newDataFrame()
  log_df:addColumn("event", "")
  log_df:addColumn("t", 0)
  local row = log_df:addRow({event = "spawn", t = 1.25})
  lurek.log.info("logged at row " .. row)
end

--@api-stub: DataFrame:removeRow
-- Removes a row by 1-based index.
-- Drop a single row by 1-based index — useful when an entity dies in a stats frame.
do  -- DataFrame:removeRow
  local df = lurek.dataframe.fromTable({{name = "Alice"}, {name = "Bob"}, {name = "Cara"}})
  df:removeRow(2)
  lurek.log.info("rows left: " .. df:nrows())
end

--@api-stub: DataFrame:getRow
-- Returns a row as a table of name-value pairs.
-- Fetch a row as a name-keyed table to feed UI panels or per-entity logic.
do  -- DataFrame:getRow
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80}})
  local row = df:getRow(1)
  lurek.log.info(row.name .. " has " .. row.hp .. " hp")
end

--@api-stub: DataFrame:getValue
-- Returns a single cell value.
-- Cell-level read for tooltips, HUD numbers, or single-stat lookups.
do  -- DataFrame:getValue
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80}})
  local hp = df:getValue(1, "hp")
  if hp < 30 then lurek.log.warn("low hp: " .. hp) end
end

--@api-stub: DataFrame:head
-- Returns the first n rows (default 5).
-- Preview the top of a frame in logs or a debug HUD without dumping everything.
do  -- DataFrame:head
  local df = lurek.dataframe.random({{"id", "id"}, {"score", "int"}}, 100, 1)
  local top = df:head(3)
  lurek.log.info("preview:\n" .. top:toString())
end

--@api-stub: DataFrame:tail
-- Returns the last n rows (default 5).
-- Inspect the most recent rows — e.g. last few entries in a rolling event log.
do  -- DataFrame:tail
  local df = lurek.dataframe.random({{"t", "int"}, {"event", "name"}}, 50, 7)
  local recent = df:tail(5)
  lurek.log.info("last 5:\n" .. recent:toString())
end

--@api-stub: DataFrame:slice
-- Returns rows from start to end (1-based, inclusive).
-- Extract a fixed window for paging UI or chart segments (1-based inclusive).
do  -- DataFrame:slice
  local df = lurek.dataframe.random({{"id", "id"}, {"score", "int"}}, 100, 2)
  local page = df:slice(11, 20)
  lurek.log.info("page rows: " .. page:nrows())
end

--@api-stub: DataFrame:select
-- Selects a subset of columns, returns a new DataFrame.
-- Project to just the columns you need before sending to a chart or save file.
do  -- DataFrame:select
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80, mp = 30, x = 0, y = 0}})
  local hud_view = df:select("name", "hp", "mp")
  lurek.log.info(hud_view:toString())
end

--@api-stub: DataFrame:unique
-- Returns unique values in a column as a table.
-- List distinct values to populate a filter dropdown or dedupe spawn pools.
do  -- DataFrame:unique
  local df = lurek.dataframe.fromTable({{type = "goblin"}, {type = "orc"}, {type = "goblin"}})
  local kinds = df:unique("type")
  lurek.log.info("distinct types: " .. #kinds)
end

--@api-stub: DataFrame:groupBy
-- Groups rows by column value, returns a table of DataFrames keyed by value.
-- Bucket rows by category to feed per-team scoreboards or per-region tallies.
do  -- DataFrame:groupBy
  local df = lurek.dataframe.fromTable({
    {team = "red", score = 10}, {team = "blue", score = 7}, {team = "red", score = 5},
  })
  local groups = df:groupBy("team")
  lurek.log.info("red rows: " .. groups["red"]:nrows())
end

--@api-stub: DataFrame:merge
-- Appends rows from another DataFrame in-place.
-- Append rows from a compatible frame in-place — handy when concatenating logs.
do  -- DataFrame:merge
  local a = lurek.dataframe.fromTable({{id = 1}, {id = 2}})
  local b = lurek.dataframe.fromTable({{id = 3}, {id = 4}})
  a:merge(b)
  lurek.log.info("merged rows: " .. a:nrows())
end

--@api-stub: DataFrame:countBy
-- Counts distinct values in a column, returns a DataFrame with value and count columns.
-- Build a quick frequency table — perfect for kill-by-weapon or item-by-rarity charts.
do  -- DataFrame:countBy
  local df = lurek.dataframe.fromTable({{weapon = "sword"}, {weapon = "bow"}, {weapon = "sword"}})
  local counts = df:countBy("weapon")
  lurek.log.info(counts:toString())
end

--@api-stub: DataFrame:dropNil
-- Removes rows where the given column is nil, returns a new DataFrame.
-- Strip incomplete rows before computing statistics that cannot tolerate gaps.
do  -- DataFrame:dropNil
  local df = lurek.dataframe.fromTable({{x = 1}, {x = nil}, {x = 3}})
  local clean = df:dropNil("x")
  lurek.log.info("clean rows: " .. clean:nrows())
end

--@api-stub: DataFrame:sample
-- Returns a random sample of n rows.
-- Pull a deterministic random subset for A/B tests or telemetry sampling.
do  -- DataFrame:sample
  local df = lurek.dataframe.random({{"id", "id"}, {"score", "int"}}, 1000, 9)
  local subset = df:sample(50, 123)
  lurek.log.info("sampled " .. subset:nrows() .. " rows")
end

--@api-stub: DataFrame:describe
-- Returns descriptive statistics for all numeric columns.
-- Summary stats per numeric column — drop into a debug overlay for live tuning.
do  -- DataFrame:describe
  local df = lurek.dataframe.random({{"hp", "int"}, {"mp", "int"}}, 200, 11)
  local summary = df:describe()
  lurek.log.info(summary:toString())
end

--@api-stub: DataFrame:sum
-- Returns the sum of numeric values in a column.
-- Total a numeric column — total damage, total gold earned, etc.
do  -- DataFrame:sum
  local df = lurek.dataframe.fromTable({{dmg = 12}, {dmg = 20}, {dmg = 8}})
  local total = df:sum("dmg")
  lurek.log.info("total damage: " .. total)
end

--@api-stub: DataFrame:mean
-- Returns the mean of numeric values in a column.
-- Average a numeric column — average DPS, average session length, etc.
do  -- DataFrame:mean
  local df = lurek.dataframe.fromTable({{dps = 50}, {dps = 70}, {dps = 60}})
  local avg = df:mean("dps")
  lurek.log.info("avg dps: " .. avg)
end

--@api-stub: DataFrame:min
-- Returns the minimum numeric value in a column.
-- Find the lowest value to spotlight worst-performing weapons or slowest frames.
do  -- DataFrame:min
  local df = lurek.dataframe.fromTable({{ms = 16}, {ms = 33}, {ms = 14}})
  local fastest = df:min("ms")
  lurek.log.info("best frame ms: " .. fastest)
end

--@api-stub: DataFrame:max
-- Returns the maximum numeric value in a column.
-- Find the highest value — top score, slowest frame, peak memory.
do  -- DataFrame:max
  local df = lurek.dataframe.fromTable({{score = 1200}, {score = 4500}, {score = 800}})
  local best = df:max("score")
  lurek.log.info("high score: " .. best)
end

--@api-stub: DataFrame:median
-- Returns the median of numeric values in a column.
-- More robust than mean when outliers (lag spikes, super-rare drops) skew the data.
do  -- DataFrame:median
  local df = lurek.dataframe.fromTable({{ms = 16}, {ms = 17}, {ms = 18}, {ms = 200}})
  local typical = df:median("ms")
  lurek.log.info("typical ms: " .. typical)
end

--@api-stub: DataFrame:stddev
-- Returns the population standard deviation of numeric values in a column.
-- Measure dispersion — high stddev on frame time means inconsistent performance.
do  -- DataFrame:stddev
  local df = lurek.dataframe.random({{"ms", "int"}}, 60, 3)
  local s = df:stddev("ms")
  lurek.log.info("ms stddev: " .. s)
end

--@api-stub: DataFrame:variance
-- Returns the population variance of numeric values in a column.
-- Squared dispersion — useful when feeding statistics into z-score or risk maths.
do  -- DataFrame:variance
  local df = lurek.dataframe.random({{"dmg", "int"}}, 100, 4)
  local v = df:variance("dmg")
  lurek.log.info("dmg variance: " .. v)
end

--@api-stub: DataFrame:fillNil
-- Replaces nil values in a column with the given value.
-- Substitute a sentinel before stats — e.g. replace nil scores with 0.
do  -- DataFrame:fillNil
  local df = lurek.dataframe.fromTable({{score = 10}, {score = nil}, {score = 5}})
  df:fillNil("score", 0)
  lurek.log.info("sum after fill: " .. df:sum("score"))
end

--@api-stub: DataFrame:toCSV
-- Serializes this DataFrame to a CSV string.
-- Export to a clipboard-friendly text format for spreadsheets and bug reports.
do  -- DataFrame:toCSV
  local df = lurek.dataframe.fromTable({{name = "Alice", score = 1200}})
  local csv = df:toCSV()
  lurek.fs.write("save/scores.csv", csv)
end

--@api-stub: DataFrame:toJSON
-- Serializes this DataFrame to a JSON string.
-- Use when posting data to a web service or saving to a human-readable file.
do  -- DataFrame:toJSON
  local df = lurek.dataframe.fromTable({{id = 1, name = "Alice"}})
  local json = df:toJSON()
  lurek.fs.write("save/players.json", json)
end

--@api-stub: DataFrame:toBinary
-- Serializes this DataFrame to a binary LVDF string.
-- Smallest, fastest format — prefer for production save files and network packets.
do  -- DataFrame:toBinary
  local df = lurek.dataframe.fromTable({{id = 1}, {id = 2}})
  local blob = df:toBinary()
  lurek.fs.write("save/state.lvdf", blob)
end

--@api-stub: DataFrame:toTable
-- Converts this DataFrame to a Lua table of row tables.
-- Round-trip back to plain Lua tables for code that does not speak DataFrame.
do  -- DataFrame:toTable
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80}})
  local rows = df:toTable()
  for _, row in ipairs(rows) do
    lurek.log.info(row.name .. ": " .. row.hp)
  end
end

--@api-stub: DataFrame:toString
-- Returns a formatted string table representation.
-- Pretty-printed table — drop straight into the log or an in-game console.
do  -- DataFrame:toString
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80}, {name = "Bob", hp = 50}})
  lurek.log.info("party:\n" .. df:toString())
end

--@api-stub: DataFrame:query
-- Executes a SQL query against this DataFrame.
-- Run a SQL query against a single frame — alias `t` is implicit in the FROM clause.
do  -- DataFrame:query
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80}, {name = "Bob", hp = 20}})
  local hurt = df:query("SELECT name FROM t WHERE hp < 50")
  lurek.log.info("hurt rows: " .. hurt:nrows())
end

--@api-stub: DataFrame:clone
-- Returns a deep copy of this DataFrame.
-- Make an independent copy before destructive ops like fillNil or merge.
do  -- DataFrame:clone
  local original = lurek.dataframe.fromTable({{x = 1}, {x = 2}})
  local working = original:clone()
  working:addRow({x = 3})
  lurek.log.info("orig=" .. original:nrows() .. " copy=" .. working:nrows())
end

--@api-stub: DataFrame:correlationMatrix
-- Compute a correlation matrix for all numeric columns.
-- Spot relationships between numeric stats (does damage correlate with cost?).
do  -- DataFrame:correlationMatrix
  local df = lurek.dataframe.random({{"dmg", "int"}, {"cost", "int"}}, 50, 5)
  local matrix = df:correlationMatrix()
  lurek.log.info("correlation:\n" .. matrix:toString())
end

--@api-stub: DataFrame:modeVal
-- Return the most frequent value in a column (nil if empty).
-- Find the most common value — favourite weapon, most-used skill, etc.
do  -- DataFrame:modeVal
  local df = lurek.dataframe.fromTable({{w = "sword"}, {w = "bow"}, {w = "sword"}})
  local favourite = df:modeVal("w")
  lurek.log.info("most-picked: " .. tostring(favourite))
end

--@api-stub: DataFrame:entropy
-- Shannon entropy (bits) of the value distribution in a column.
-- Measure variety — low entropy means everyone picks the same thing (balance issue).
do  -- DataFrame:entropy
  local df = lurek.dataframe.fromTable({{class = "warrior"}, {class = "mage"}, {class = "warrior"}})
  local h = df:entropy("class")
  lurek.log.info("class entropy bits: " .. h)
end

--@api-stub: DataFrame:addRowBatch
-- Add multiple rows at once from a table of row tables.
-- Bulk-insert positional rows — much faster than calling addRow in a loop.
do  -- DataFrame:addRowBatch
  local df = lurek.dataframe.newDataFrame()
  df:addColumn("x", 0)
  df:addColumn("y", 0)
  df:addRowBatch({{1, 2}, {3, 4}, {5, 6}})
  lurek.log.info("rows now: " .. df:nrows())
end

--@api-stub: DataFrame:getColumnAsF64
-- Return a numeric column as a Lua array of numbers (nils → 0/nan).
-- Optimised numeric extract — feed straight into FFT, signal smoothing, or graphs.
do  -- DataFrame:getColumnAsF64
  local df = lurek.dataframe.random({{"hp", "int"}}, 16, 6)
  local nums = df:getColumnAsF64("hp")
  lurek.log.info("first hp = " .. nums[1])
end

--@api-stub: DataFrame:setColumnFromF64
-- Set a numeric column from a Lua array of numbers.
-- Bulk-replace a numeric column — useful after running smoothing or filtering off-frame.
do  -- DataFrame:setColumnFromF64
  local df = lurek.dataframe.fromTable({{x = 0}, {x = 0}, {x = 0}})
  df:setColumnFromF64("x", {1.5, 2.5, 3.5})
  lurek.log.info("sum x = " .. df:sum("x"))
end

--@api-stub: DataFrame:type
-- Returns the type name of this object.
-- Use in generic dispatch code that handles both DataFrame and Database userdata.
do  -- DataFrame:type
  local df = lurek.dataframe.newDataFrame()
  if df:type() == "DataFrame" then
    lurek.log.info("got a frame, columns=" .. df:ncols())
  end
end

--@api-stub: DataFrame:typeOf
-- Returns true if this object is of the given type.
-- Inheritance-style check — also returns true for the generic "Object" supertype.
do  -- DataFrame:typeOf
  local df = lurek.dataframe.newDataFrame()
  if df:typeOf("Object") then
    lurek.log.info("DataFrame is an Object")
  end
end

--@api-stub: DataFrame:withEval
-- Returns a new DataFrame with an additional computed column named `col_name`.
-- Add derived columns with a simple `+ - * /` expression over existing columns.
do  -- DataFrame:withEval
  local df = lurek.dataframe.fromTable({{atk = 10, bonus = 4}, {atk = 8, bonus = 2}})
  local boosted = df:withEval("total", "atk + bonus * 1.5")
  lurek.log.info("max total: " .. boosted:max("total"))
end

-- ── Database methods ──

--@api-stub: Database:getTable
-- Returns a copy of a table by name, or nil if not found.
-- Returns a deep copy — modify it freely without touching the database state.
do  -- Database:getTable
  local db = lurek.dataframe.newDatabase()
  db:addTable("players", lurek.dataframe.fromTable({{name = "Alice"}}))
  local players = db:getTable("players")
  lurek.log.info("players rows: " .. players:nrows())
end

--@api-stub: Database:removeTable
-- Drops the named table from this in-memory database if it exists.
-- Drop a table when the corresponding game system shuts down (e.g. lobby closes).
do  -- Database:removeTable
  local db = lurek.dataframe.newDatabase()
  db:addTable("temp", lurek.dataframe.newDataFrame())
  db:removeTable("temp")
  lurek.log.info("table count: " .. db:tableCount())
end

--@api-stub: Database:hasTable
-- Returns true if a table with the given name exists.
-- Guard against missing tables before querying — avoids a runtime SQL error.
do  -- Database:hasTable
  local db = lurek.dataframe.newDatabase()
  if not db:hasTable("scores") then
    db:addTable("scores", lurek.dataframe.newDataFrame())
  end
end

--@api-stub: Database:listTables
-- Returns a table of all table names.
-- Iterate every table for a debug overlay or to drive an export-all command.
do  -- Database:listTables
  local db = lurek.dataframe.newDatabase()
  db:addTable("a", lurek.dataframe.newDataFrame())
  db:addTable("b", lurek.dataframe.newDataFrame())
  for _, name in ipairs(db:listTables()) do
    lurek.log.info("table: " .. name)
  end
end

--@api-stub: Database:tableCount
-- Returns the number of tables.
-- Quick sanity check — branch on this to skip empty-database UI rendering.
do  -- Database:tableCount
  local db = lurek.dataframe.newDatabase()
  db:addTable("scores", lurek.dataframe.newDataFrame())
  if db:tableCount() > 0 then
    lurek.log.info("database populated")
  end
end

--@api-stub: Database:clear
-- Drops every table from this in-memory database, leaving it empty.
-- Wipe everything between matches or when loading a fresh save file.
do  -- Database:clear
  local db = lurek.dataframe.newDatabase()
  db:addTable("round", lurek.dataframe.newDataFrame())
  db:clear()
  lurek.log.info("cleared, count=" .. db:tableCount())
end

--@api-stub: Database:merge
-- Merges all tables from another Database into this one.
-- Pull every table from another Database — useful when stitching together mod data.
do  -- Database:merge
  local base = lurek.dataframe.newDatabase()
  local mod = lurek.dataframe.newDatabase()
  mod:addTable("extra_items", lurek.dataframe.fromTable({{id = "amulet"}}))
  base:merge(mod)
  lurek.log.info("after merge: " .. base:tableCount() .. " tables")
end

--@api-stub: Database:toJSON
-- Serializes all tables to a JSON object string.
-- Serialise the whole database — handy for full-game save files or debug dumps.
do  -- Database:toJSON
  local db = lurek.dataframe.newDatabase()
  db:addTable("players", lurek.dataframe.fromTable({{name = "Alice"}}))
  lurek.fs.write("save/world.json", db:toJSON())
end

--@api-stub: Database:query
-- Executes a SQL query against the database tables.
-- Run SQL across multiple tables — JOINs work because each table is named.
do  -- Database:query
  local db = lurek.dataframe.newDatabase()
  db:addTable("players", lurek.dataframe.fromTable({{id = 1, name = "Alice"}}))
  db:addTable("scores",  lurek.dataframe.fromTable({{pid = 1, pts = 9000}}))
  local joined = db:query("SELECT players.name, scores.pts FROM players, scores WHERE players.id = scores.pid")
  lurek.log.info("joined rows: " .. joined:nrows())
end

--@api-stub: Database:type
-- Returns the type name of this object.
-- Use in generic code that introspects either DataFrame or Database userdata.
do  -- Database:type
  local db = lurek.dataframe.newDatabase()
  if db:type() == "Database" then
    lurek.log.info("got a database, tables=" .. db:tableCount())
  end
end

--@api-stub: Database:typeOf
-- Returns true if this object is of the given type.
-- Inheritance-style check — also returns true for the generic "Object" supertype.
do  -- Database:typeOf
  local db = lurek.dataframe.newDatabase()
  if db:typeOf("Object") then
    lurek.log.info("Database is an Object")
  end
end
