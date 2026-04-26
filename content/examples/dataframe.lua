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
  if lurek.fs then lurek.fs.write("save/scores.csv", csv) end
end

--@api-stub: DataFrame:toJSON
-- Serializes this DataFrame to a JSON string.
-- Use when posting data to a web service or saving to a human-readable file.
do  -- DataFrame:toJSON
  local df = lurek.dataframe.fromTable({{id = 1, name = "Alice"}})
  local json = df:toJSON()
  if lurek.fs then lurek.fs.write("save/players.json", json) end
end

--@api-stub: DataFrame:toBinary
-- Serializes this DataFrame to a binary LVDF string.
-- Smallest, fastest format — prefer for production save files and network packets.
do  -- DataFrame:toBinary
  local df = lurek.dataframe.fromTable({{id = 1}, {id = 2}})
  local blob = df:toBinary()
  if lurek.fs then lurek.fs.write("save/state.lvdf", blob) end
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
  if players then
    lurek.log.info("players rows: " .. players:nrows())
  end
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
  if lurek.fs then lurek.fs.write("save/world.json", db:toJSON()) end
end

--@api-stub: Database:query
-- Executes a SQL query against the database tables.
-- Run SQL across multiple tables — JOINs work because each table is named.
do  -- Database:query
  pcall(function()
    local db = lurek.dataframe.newDatabase()
    db:addTable("players", lurek.dataframe.fromTable({{id = 1, name = "Alice"}}))
    db:addTable("scores",  lurek.dataframe.fromTable({{pid = 1, pts = 9000}}))
    local joined = db:query("SELECT players.name, scores.pts FROM players, scores WHERE players.id = scores.pid")
    lurek.log.info("joined rows: " .. joined:nrows())
  end)
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

--@api-stub: GroupedFrame:aggregate
-- Apply a Lua aggregator function to a column within each group.
-- fn(values_table) -> number  -- receives all column values for the group, returns one number.
do  -- GroupedFrame:aggregate
  local df = lurek.dataframe.newDataFrame()
  df:addColumn("damage", 0) ; df:addColumn("class", "")
  df:addRow({damage=12, class="warrior"}) ; df:addRow({damage=8, class="mage"})
  df:addRow({damage=20, class="warrior"}) ; df:addRow({damage=5, class="mage"})
  local grouped = df:groupBy("class")
  if grouped and grouped.aggregate then
    local result = grouped:aggregate("damage", function(vals)
      local sum = 0
      for _, v in ipairs(vals) do sum = sum + v end
      return sum / #vals  -- mean
    end)
    lurek.log.debug("aggregate done", "dataframe")
  end
end

--@api-stub: DataFrame:groupByObj
-- Group the frame by an object-type column (uses identity comparison).
-- Returns a GroupedFrame; call :aggregate() on it to reduce per-group.
do  -- DataFrame:groupByObj
  local df = lurek.dataframe.newDataFrame()
  df:addColumn("score", 0) ; df:addColumn("key", "")
  df:addRow({score=1, key="a"}) ; df:addRow({score=2, key="b"}) ; df:addRow({score=3, key="a"})
  if df.groupByObj then
    local grouped = df:groupByObj("key")
    lurek.log.debug("groupByObj returned: " .. tostring(grouped), "dataframe")
  end
end

-- ── VecFrame: vectorized columnar operations ──────────────────────────────
--
-- VecFrame stores each column as a typed flat buffer (float64/int64/bool/text)
-- with an optional null-validity bitmap.  Operations run over the entire column
-- at once — no per-cell Lua dispatch — allowing the Rust compiler to apply
-- SIMD vectorization and rayon parallelism.
--
-- Workflow: DataFrame → toVec() → fast bulk ops → toDataFrame() (or fromVec)

--@api-stub: lurek.dataframe.toVec
-- Converts a DataFrame to a VecFrame for fast bulk column operations.
-- The conversion infers each column's type from its cell values.
do  -- lurek.dataframe.toVec
  local df = lurek.dataframe.fromCSV("hp,mp\n100,50\n200,80\n150,60\n")
  local vf = lurek.dataframe.toVec(df)
  lurek.log.info("VecFrame: " .. vf:nrows() .. " rows, " .. vf:ncols() .. " cols")
end

--@api-stub: lurek.dataframe.fromVec
-- Converts a VecFrame back to a DataFrame.
-- Round-trip after bulk column operations: toVec() → ops → fromVec().
do  -- lurek.dataframe.fromVec
  local df = lurek.dataframe.fromCSV("hp,mp\n100,50\n200,80\n")
  local vf = lurek.dataframe.toVec(df)
  vf:colMul("hp", 0.5)          -- halve all HP values at once
  local df2 = lurek.dataframe.fromVec(vf)
  lurek.log.info("first HP after halving: " .. tostring(df2:getValue(1, "hp")))
end

--@api-stub: VecFrame:colAdd
-- Add a scalar to every element of a Float64 column.
-- All rows are processed in a single vectorized Rust loop.
do  -- VecFrame:colAdd
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("score\n10\n20\n30\n"))
  vf:colAdd("score", 5)    -- score becomes 15, 25, 35
  local df = vf:toDataFrame()
  lurek.log.info("score[0] = " .. tostring(df:getValue(1, "score")))
end

--@api-stub: VecFrame:colMul
-- Multiply every element of a Float64 column by a scalar.
-- Useful for applying damage multipliers or stat scaling across all rows at once.
do  -- VecFrame:colMul
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("dmg\n10\n15\n20\n"))
  vf:colMul("dmg", 1.5)    -- apply 1.5x damage multiplier to all rows
end

--@api-stub: VecFrame:colClamp
-- Clamp every element of a Float64 column to [min, max].
-- Useful for enforcing stat caps (e.g. HP cannot exceed 100).
do  -- VecFrame:colClamp
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n-5\n50\n150\n"))
  vf:colClamp("hp", 0, 100)   -- HP in [0, 100]
  local df = vf:toDataFrame()
  lurek.log.info("hp[2] clamped to " .. tostring(df:getValue(2, "hp")))  -- 100
end

--@api-stub: VecFrame:colAbs
-- Replace every element with its absolute value.
-- Useful for converting signed deltas (e.g. position offsets) to distances.
do  -- VecFrame:colAbs
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("delta\n-3\n4\n-1\n"))
  vf:colAbs("delta")
  local df = vf:toDataFrame()
  lurek.log.info("abs delta[0] = " .. tostring(df:getValue(1, "delta")))
end

--@api-stub: VecFrame:colSqrt
-- Apply square root to every element of a Float64 column.
-- Convert squared distances to Euclidean distances without a Lua loop.
do  -- VecFrame:colSqrt
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("dist_sq\n9\n16\n25\n"))
  vf:colSqrt("dist_sq")   -- dist_sq becomes 3, 4, 5
  local df = vf:toDataFrame()
  lurek.log.info("dist[0] = " .. tostring(df:getValue(1, "dist_sq")))
end

--@api-stub: VecFrame:colOp
-- Element-wise binary operation between two Float64 columns.
-- op: "add" | "sub" | "mul" | "div" | "min" | "max"
do  -- VecFrame:colOp
  local df = lurek.dataframe.fromCSV("atk,def\n30,10\n40,15\n20,5\n")
  local vf = lurek.dataframe.toVec(df)
  vf:colOp("net_dmg", "atk", "sub", "def")   -- net_dmg = atk - def per row
  local df2 = vf:toDataFrame()
  lurek.log.info("net_dmg[0] = " .. tostring(df2:getValue(1, "net_dmg")))  -- 20
end

--@api-stub: VecFrame:reduce
-- Reduce an entire numeric column to a single scalar.
-- op: "sum" | "mean" | "min" | "max" | "std" | "var" | "count"
do  -- VecFrame:reduce
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("score\n10\n20\n30\n"))
  local total = vf:reduce("score", "sum")
  local avg   = vf:reduce("score", "mean")
  lurek.log.info("sum=" .. total .. " mean=" .. avg)
end

--@api-stub: VecFrame:filterMask
-- Build a boolean row mask: mask[i] = (col[i] op val).
-- op: "<" | "<=" | ">" | ">=" | "==" | "!="
do  -- VecFrame:filterMask
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n10\n50\n90\n"))
  local mask = vf:filterMask("hp", ">=", 50)  -- {false, true, true}
  lurek.log.info("rows with hp >= 50: " .. tostring(mask[2]) .. ", " .. tostring(mask[3]))
end

--@api-stub: VecFrame:applyMask
-- Return a new VecFrame with only the rows where mask[i] is true.
-- Combine with filterMask for fast predicate-based row selection.
do  -- VecFrame:applyMask
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n10\n50\n90\n"))
  local mask = vf:filterMask("hp", ">=", 50)
  local alive = vf:applyMask(mask)   -- 2 rows
  lurek.log.info("alive rows: " .. alive:nrows())  -- 2
end

--@api-stub: VecFrame:colType
-- Return the dtype name of a column: "float64" | "int64" | "bool" | "text".
-- Inspect the column type before choosing a scalar op or cast target.
do  -- VecFrame:colType
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n10\n20\n"))
  local dtype = vf:colType("hp")
  lurek.log.info("hp dtype: " .. dtype)  -- "float64"
end

--@api-stub: VecFrame:parReduce
-- Reduce multiple columns in parallel using rayon, returning {col → value}.
-- Useful for computing per-stat totals across large enemy tables in one call.
do  -- VecFrame:parReduce
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp,mp,atk\n10,5,8\n20,10,12\n"))
  local sums = vf:parReduce({"hp", "mp", "atk"}, "sum")
  for col, s in pairs(sums) do
    lurek.log.info(col .. " sum = " .. tostring(s))
  end
end

--@api-stub: VecFrame:parScalarOp
-- Apply a scalar op in parallel to multiple Float64 columns.
do  -- VecFrame:parScalarOp
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp,mp\n100,50\n200,80\n"))
  vf:parScalarOp({"hp", "mp"}, "mul", 0.5)   -- halve all stats at once
  local df2 = vf:toDataFrame()
  lurek.log.info("hp[0]=" .. df2:getValue(1,"hp") .. " mp[0]=" .. df2:getValue(1,"mp"))
end

--@api-stub: VecFrame:toDataFrame
-- Convert a VecFrame back to a DataFrame (same as lurek.dataframe.fromVec).
-- Use as the last step after bulk VecFrame ops before displaying or saving data.
do  -- VecFrame:toDataFrame
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("v\n1\n2\n3\n"))
  vf:colAdd("v", 10)
  local df2 = vf:toDataFrame()
  lurek.log.info("v[0] = " .. tostring(df2:getValue(1, "v")))  -- 11
end

--@api-stub: VecFrame:colSub
-- Subtract a scalar from every element of a Float64 column.
-- Useful for reducing stats by a fixed amount (e.g. applying stamina drain).
do  -- VecFrame:colSub
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("stamina\n100\n80\n60\n"))
  vf:colSub("stamina", 10)
  local df2 = vf:toDataFrame()
  lurek.log.info("stamina[0] after drain = " .. tostring(df2:getValue(1, "stamina")))  -- 90
end

--@api-stub: VecFrame:colDiv
-- Divide every element of a Float64 column by a scalar.
-- Normalise a column to a [0, 1] range by dividing by its maximum value.
do  -- VecFrame:colDiv
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("score\n100\n200\n150\n"))
  vf:colDiv("score", 200)
  local df2 = vf:toDataFrame()
  lurek.log.info("normalised score[1] = " .. tostring(df2:getValue(1, "score")))  -- 1.0
end

--@api-stub: VecFrame:colFloor
-- Round every element of a Float64 column down to the nearest integer.
-- Snap fractional coordinates to tile positions without a Lua loop.
do  -- VecFrame:colFloor
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x\n1.9\n2.1\n3.7\n"))
  vf:colFloor("x")
  local df2 = vf:toDataFrame()
  lurek.log.info("floored x[2] = " .. tostring(df2:getValue(2, "x")))  -- 3
end

--@api-stub: VecFrame:colCeil
-- Round every element of a Float64 column up to the nearest integer.
-- Compute minimum tile coverage for fractional world coordinates.
do  -- VecFrame:colCeil
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("y\n1.1\n2.5\n3.0\n"))
  vf:colCeil("y")
  local df2 = vf:toDataFrame()
  lurek.log.info("ceiled y[0] = " .. tostring(df2:getValue(1, "y")))  -- 2
end

--@api-stub: VecFrame:colNeg
-- Negate every element of a Float64 column (multiply by -1).
-- Flip velocity or force columns to reverse direction without a loop.
do  -- VecFrame:colNeg
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("vy\n3\n-2\n0\n"))
  vf:colNeg("vy")
  local df2 = vf:toDataFrame()
  lurek.log.info("negated vy[0] = " .. tostring(df2:getValue(1, "vy")))  -- -3
end

--@api-stub: VecFrame:colCast
-- Cast a column to a new dtype: "float64" | "int64" | "bool" | "text".
-- Convert an integer column to float before arithmetic, or text for display.
do  -- VecFrame:colCast
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("level\n1\n2\n3\n"))
  vf:colCast("level", "float64")
  lurek.log.info("level dtype after cast: " .. vf:colType("level"))  -- "float64"
  local df2 = vf:toDataFrame()
  lurek.log.info("level[0] as float = " .. tostring(df2:getValue(1, "level")))
end

--@api-stub: VecFrame:nrows
-- Return the number of rows in this VecFrame.
-- Use to guard slice/applyMask calls or to log frame dimensions.
do  -- VecFrame:nrows
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("v\n10\n20\n30\n"))
  lurek.log.info("VecFrame rows: " .. vf:nrows())  -- 3
  local df2 = vf:toDataFrame()
  assert(vf:nrows() == df2:nrows())
end

--@api-stub: VecFrame:ncols
-- Return the number of columns in this VecFrame.
-- Check column count after toVec to confirm all DataFrame columns were kept.
do  -- VecFrame:ncols
  local df = lurek.dataframe.fromCSV("hp,mp,atk\n10,5,8\n")
  local vf = lurek.dataframe.toVec(df)
  lurek.log.info("VecFrame cols: " .. vf:ncols())  -- 3
  assert(vf:ncols() == df:ncols())
end

--@api-stub: VecFrame:columns
-- Return a table of column name strings in this VecFrame.
-- Iterate column names to build dynamic UI headers or log schemas.
do  -- VecFrame:columns
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("a,b,c\n1,2,3\n"))
  local cols = vf:columns()
  for i, name in ipairs(cols) do
    lurek.log.info("col " .. i .. ": " .. name)
  end
end

--@api-stub: VecFrame:type
-- Return the type name of this object ("VecFrame").
-- Use in generic dispatch code that handles both VecFrame and DataFrame userdata.
do  -- VecFrame:type
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x\n1\n"))
  if vf:type() == "VecFrame" then
    lurek.log.info("got a VecFrame, rows=" .. vf:nrows())
  end
end

--@api-stub: VecFrame:typeOf
-- Return true if this object is of the given type.
-- Inheritance-style check — also returns true for the generic "Object" supertype.
do  -- VecFrame:typeOf
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x\n1\n"))
  if vf:typeOf("Object") then
    lurek.log.info("VecFrame is an Object")
  end
end

--@api-stub: DataFrame:addColumn
-- Adds a new column to the DataFrame from a Lua table of values.
-- Column length must match nrows(); use nil to append an empty column.
do  -- DataFrame:addColumn
  local df = lurek.dataframe.newDataFrame()
  df:addRow({name="Alice", score=85})
  df:addColumn("grade", {"A"})
  lurek.log.info("cols: " .. df:ncols(), "dataframe")
end

--@api-stub: Database:addTable
-- Adds a named DataFrame to the Database for SQL-style querying.
-- Table name must be unique; adding a duplicate name replaces the previous table.
do  -- Database:addTable
  local db = lurek.dataframe.newDatabase()
  local df = lurek.dataframe.newDataFrame()
  df:addRow({id=1, name="Alice"})
  db:addTable("users", df)
  lurek.log.info("tables: " .. db:tableCount(), "dataframe")
end

--@api-stub: DataFrame:apply
-- Applies a Lua function to every element of a column and stores results in a new column.
-- Signature: fn(value) -> new_value; nil return keeps the original value.
do  -- DataFrame:apply
  local df = lurek.dataframe.newDataFrame()
  df:addRow({score=60})
  df:addRow({score=80})
  df:apply("score", function(v) return v >= 70 and "pass" or "fail" end)
  lurek.log.info("grade col added", "dataframe")
end

--@api-stub: DataFrame:corr
-- Returns the Pearson correlation coefficient between two numeric columns.
-- Values near 1 indicate strong positive correlation, near -1 strong negative.
do  -- DataFrame:corr
  local df = lurek.dataframe.newDataFrame()
  df:addRow({x=1, y=2})
  df:addRow({x=3, y=4})
  df:addRow({x=5, y=6})
  local r = df:corr("x", "y")
  lurek.log.info("correlation: " .. r, "dataframe")
end

--@api-stub: DataFrame:filter
-- Returns a new DataFrame containing only rows where the predicate function returns true.
-- Predicate receives the row table; does not modify the original frame.
do  -- DataFrame:filter
  local df = lurek.dataframe.newDataFrame()
  df:addRow({age=20, name="Alice"})
  df:addRow({age=35, name="Bob"})
  local adults = df:filter("age", ">=", 21)
  lurek.log.info("adults: " .. adults:nrows(), "dataframe")
end

--@api-stub: DataFrame:groupAgg
-- Groups rows by a column and aggregates another column using a named function.
-- Supported aggregators: "sum", "mean", "count", "min", "max".
do  -- DataFrame:groupAgg
  local df = lurek.dataframe.newDataFrame()
  df:addRow({team="A", score=10})
  df:addRow({team="A", score=20})
  df:addRow({team="B", score=30})
  local out = df:groupAgg("team", "score", "sum")
  lurek.log.info("group agg rows: " .. out:nrows(), "dataframe")
end

--@api-stub: DataFrame:join
-- Joins two DataFrames on a shared key column, returning a new merged frame.
-- join_type: "inner" (default), "left", "right", or "outer".
do  -- DataFrame:join
  local left  = lurek.dataframe.newDataFrame()
  local right = lurek.dataframe.newDataFrame()
  left:addRow({id=1, name="Alice"})
  right:addRow({id=1, dept="Eng"})
  local merged = left:join(right, "id", "inner")
  lurek.log.info("joined rows: " .. merged:nrows(), "dataframe")
end

--@api-stub: DataFrame:normalizeCol
-- Normalises a numeric column to the [0, 1] range in-place.
-- Uses min-max scaling; column min and max are computed from the data.
do  -- DataFrame:normalizeCol
  local df = lurek.dataframe.newDataFrame()
  df:addRow({val=10}) ; df:addRow({val=50}) ; df:addRow({val=90})
  df:normalizeCol("val", 0.0, 1.0, "val_norm")
  lurek.log.info("normalized col", "dataframe")
end

--@api-stub: DataFrame:outliers
-- Returns a new DataFrame containing rows whose column value is an outlier.
-- Outliers are defined as more than threshold standard deviations from the mean.
do  -- DataFrame:outliers
  local df = lurek.dataframe.newDataFrame()
  for i=1,10 do df:addRow({v=i}) end
  df:addRow({v=1000})
  local out = df:outliers("v", 2.0)
  lurek.log.info("outliers: " .. out:nrows(), "dataframe")
end

--@api-stub: VecFrame:parScalarOp
-- Applies a scalar operation to all cells of a VecFrame in parallel.
-- op is one of "+", "-", "*", "/"; faster than loop-based column iteration.
do  -- VecFrame:parScalarOp
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromTable({
    x = {1.0, 2.0, 3.0}, y = {4.0, 5.0, 6.0}
  }))
  local scaled = vf:parScalarOp({"x", "y"}, "*", 2.0)
  lurek.log.info("par scalar done", "dataframe")
end

--@api-stub: DataFrame:pivot
-- Pivots the DataFrame: unique values of pivot_col become new columns.
-- values_col provides the cell values; aggregation is "first" by default.
do  -- DataFrame:pivot
  local df = lurek.dataframe.newDataFrame()
  df:addRow({name="Alice", month="Jan", val=100})
  df:addRow({name="Alice", month="Feb", val=120})
  local p = df:pivot("name", "month", "val")
  lurek.log.info("pivot cols: " .. p:ncols(), "dataframe")
end

--@api-stub: DataFrame:pivotTable
-- Creates a pivot table with row/column grouping and an aggregation function.
-- More powerful than pivot(); supports multi-index and custom aggregators.
do  -- DataFrame:pivotTable
  local df = lurek.dataframe.newDataFrame()
  df:addRow({region="N", product="A", sales=50})
  df:addRow({region="N", product="B", sales=70})
  local pt = df:pivotTable("region", "product", "sales", "sum")
  lurek.log.info("pivot table rows: " .. pt:nrows(), "dataframe")
end

--@api-stub: DataFrame:rank
-- Returns a new DataFrame with a rank column added, ranked by the given column.
-- Ties use the "average" method by default; method can be "min", "max", "first".
do  -- DataFrame:rank
  local df = lurek.dataframe.newDataFrame()
  df:addRow({score=80}) ; df:addRow({score=95}) ; df:addRow({score=72})
  local ranked = df:rank("score")
  lurek.log.info("rank col added", "dataframe")
end

--@api-stub: DataFrame:rollingMean
-- Returns a new DataFrame with rolling mean applied to a numeric column.
-- window is the number of preceding rows (inclusive); edge rows get nil/NaN.
do  -- DataFrame:rollingMean
  local df = lurek.dataframe.newDataFrame()
  for i=1,5 do df:addRow({v=i*2}) end
  local out = df:rollingMean("v", 3)
  lurek.log.info("rolling mean rows: " .. out:nrows(), "dataframe")
end

--@api-stub: DataFrame:rollingSum
-- Returns a new DataFrame with rolling sum applied to a numeric column.
-- Useful for computing moving-window totals such as rolling revenue sums.
do  -- DataFrame:rollingSum
  local df = lurek.dataframe.newDataFrame()
  for i=1,5 do df:addRow({v=i}) end
  local out = df:rollingSum("v", 3)
  lurek.log.info("rolling sum rows: " .. out:nrows(), "dataframe")
end

--@api-stub: DataFrame:setValue
-- Sets the value at (row_index, column_name) in place.
-- row_index is 1-based; raises an error for out-of-bounds or unknown column.
do  -- DataFrame:setValue
  local df = lurek.dataframe.newDataFrame()
  df:addRow({score=50, name="Alice"})
  df:setValue(1, "score", 90)
  lurek.log.info("updated score: " .. df:getValue(1, "score"), "dataframe")
end

--@api-stub: DataFrame:sort
-- Sorts the DataFrame in-place by one or more columns.
-- Pass asc=true for ascending (default); multi-key sort via a table of column names.
do  -- DataFrame:sort
  local df = lurek.dataframe.newDataFrame()
  df:addRow({score=80}) ; df:addRow({score=60}) ; df:addRow({score=95})
  df:sort("score", true)
  lurek.log.info("sorted first: " .. df:getValue(1, "score"), "dataframe")
end

--@api-stub: DataFrame:withCumsum
-- Returns a new DataFrame with a cumulative-sum column derived from a source column.
-- The resulting column is appended with the suffix "_cumsum" by default.
do  -- DataFrame:withCumsum
  local df = lurek.dataframe.newDataFrame()
  for i=1,4 do df:addRow({v=i}) end
  local out = df:withCumsum("v", "v_cumsum")
  lurek.log.info("cumsum col added", "dataframe")
end

--@api-stub: DataFrame:withPctChange
-- Returns a new DataFrame with a percentage-change column derived from a source column.
-- First row is nil/NaN; subsequent rows show (current-prev)/prev*100.
do  -- DataFrame:withPctChange
  local df = lurek.dataframe.newDataFrame()
  for _, v in ipairs({100,110,121,133}) do df:addRow({price=v}) end
  local out = df:withPctChange("price", "price_pct")
  lurek.log.info("pct change col added", "dataframe")
end

--@api-stub: DataFrame:withRank
-- Returns a new DataFrame with a rank column added for a numeric source column.
-- Ties default to average ranking; the new column is named source.."_rank".
do  -- DataFrame:withRank
  local df = lurek.dataframe.newDataFrame()
  df:addRow({pts=10}) ; df:addRow({pts=30}) ; df:addRow({pts=20})
  local out = df:withRank("pts", true, "pts_rank")
  lurek.log.info("rank col added", "dataframe")
end

--@api-stub: DataFrame:withRollingMax
-- Returns a new DataFrame with a rolling-maximum column derived from a source column.
-- Useful for computing peak values within a sliding time window.
do  -- DataFrame:withRollingMax
  local df = lurek.dataframe.newDataFrame()
  for _, v in ipairs({3,1,4,1,5,9,2,6}) do df:addRow({v=v}) end
  local out = df:withRollingMax("v", 3, "v_rollmax")
  lurek.log.info("rolling max col added", "dataframe")
end

--@api-stub: DataFrame:withRollingMean
-- Returns a new DataFrame with a rolling-mean column appended for a source column.
-- Equivalent to rolling mean but returns a new frame instead of mutating in place.
do  -- DataFrame:withRollingMean
  local df = lurek.dataframe.newDataFrame()
  for i=1,5 do df:addRow({temp=20+i}) end
  local out = df:withRollingMean("temp", 3, "temp_rollmean")
  lurek.log.info("rolling mean col added", "dataframe")
end

--@api-stub: DataFrame:withRollingMin
-- Returns a new DataFrame with a rolling-minimum column derived from a source column.
-- Useful for tracking the recent low value of a time series.
do  -- DataFrame:withRollingMin
  local df = lurek.dataframe.newDataFrame()
  for _, v in ipairs({5,3,8,2,7,1}) do df:addRow({v=v}) end
  local out = df:withRollingMin("v", 3, "v_rollmin")
  lurek.log.info("rolling min col added", "dataframe")
end

--@api-stub: DataFrame:withRollingSum
-- Returns a new DataFrame with a rolling-sum column derived from a source column.
-- Useful for sliding-window revenue totals or event-count aggregations.
do  -- DataFrame:withRollingSum
  local df = lurek.dataframe.newDataFrame()
  for i=1,5 do df:addRow({sales=i*10}) end
  local out = df:withRollingSum("sales", 3, "sales_rollsum")
  lurek.log.info("rolling sum col added", "dataframe")
end

--@api-stub: DataFrame:zscoreCol
-- Z-score normalises a numeric column in-place: (x-mean)/stddev.
-- After normalisation the column has mean≈0 and stddev≈1.
do  -- DataFrame:zscoreCol
  local df = lurek.dataframe.newDataFrame()
  for i=1,6 do df:addRow({v=i*5}) end
  df:zscoreCol("v", "v_zscore")
  lurek.log.info("zscore normalised", "dataframe")
end

-- =============================================================================
-- STUBS: 109 uncovered lurek.dataframe API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LDataFrame methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDataFrame:nrows ----------------------------------------------
--@api-stub: LDataFrame:nrows
-- Returns the number of rows.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:nrows()  -- -> integer
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:ncols ----------------------------------------------
--@api-stub: LDataFrame:ncols
-- Returns the number of columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:ncols()  -- -> integer
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:columns --------------------------------------------
--@api-stub: LDataFrame:columns
-- Returns a table of column names.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:columns()  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:count ----------------------------------------------
--@api-stub: LDataFrame:count
-- Returns the row count (alias for nrows).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:count()  -- -> integer
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:addColumn ------------------------------------------
--@api-stub: LDataFrame:addColumn
-- Adds a new column with an optional default value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:addColumn("hero", [default])
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:removeColumn ---------------------------------------
--@api-stub: LDataFrame:removeColumn
-- Removes a column by name or index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:removeColumn(col)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:rename ---------------------------------------------
--@api-stub: LDataFrame:rename
-- Renames the column `old_name` to `new_name` in this DataFrame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:rename(col, new_name)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:getColumn ------------------------------------------
--@api-stub: LDataFrame:getColumn
-- Returns all values in a column as a table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:getColumn(col)  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:addRow ---------------------------------------------
--@api-stub: LDataFrame:addRow
-- Adds a row from an optional table of name-value pairs, returns 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:addRow([row_tbl])  -- -> integer
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:removeRow ------------------------------------------
--@api-stub: LDataFrame:removeRow
-- Removes a row by 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:removeRow(row)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:getRow ---------------------------------------------
--@api-stub: LDataFrame:getRow
-- Returns a row as a table of name-value pairs.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:getRow(row)  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:getValue -------------------------------------------
--@api-stub: LDataFrame:getValue
-- Returns a single cell value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:getValue(row, col)  -- -> LuaValue
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:setValue -------------------------------------------
--@api-stub: LDataFrame:setValue
-- Sets a single cell value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:setValue(row, col, val)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:filter ---------------------------------------------
--@api-stub: LDataFrame:filter
-- Filters rows where column matches a condition, returns a new DataFrame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:filter(col, op, val)  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:sort -----------------------------------------------
--@api-stub: LDataFrame:sort
-- Sorts by column, returns a new DataFrame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:sort(col, [ascending])  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:head -----------------------------------------------
--@api-stub: LDataFrame:head
-- Returns the first n rows (default 5).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:head([n])  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:tail -----------------------------------------------
--@api-stub: LDataFrame:tail
-- Returns the last n rows (default 5).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:tail([n])  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:slice ----------------------------------------------
--@api-stub: LDataFrame:slice
-- Returns rows from start to end (1-based, inclusive).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:slice(start, end)  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:select ---------------------------------------------
--@api-stub: LDataFrame:select
-- Selects a subset of columns, returns a new DataFrame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:select(...)  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:unique ---------------------------------------------
--@api-stub: LDataFrame:unique
-- Returns unique values in a column as a table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:unique(col)  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:groupBy --------------------------------------------
--@api-stub: LDataFrame:groupBy
-- Groups rows by column value, returns a table of DataFrames keyed by value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:groupBy(col)  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:groupByObj -----------------------------------------
--@api-stub: LDataFrame:groupByObj
-- Groups rows by column value, returns a GroupedFrame object supporting aggregate().
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:groupByObj(col)  -- -> GroupedFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:join -----------------------------------------------
--@api-stub: LDataFrame:join
-- Joins with another DataFrame on matching columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:join()  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:merge ----------------------------------------------
--@api-stub: LDataFrame:merge
-- Appends rows from another DataFrame in-place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:merge(other)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:countBy --------------------------------------------
--@api-stub: LDataFrame:countBy
-- Counts distinct values in a column, returns a DataFrame with value and count columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:countBy(col)  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:dropNil --------------------------------------------
--@api-stub: LDataFrame:dropNil
-- Removes rows where the given column is nil, returns a new DataFrame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:dropNil(col)  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:sample ---------------------------------------------
--@api-stub: LDataFrame:sample
-- Returns a random sample of n rows.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:sample(5, [seed])  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:describe -------------------------------------------
--@api-stub: LDataFrame:describe
-- Returns descriptive statistics for all numeric columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:describe()  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:sum ------------------------------------------------
--@api-stub: LDataFrame:sum
-- Returns the sum of numeric values in a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:sum(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:mean -----------------------------------------------
--@api-stub: LDataFrame:mean
-- Returns the mean of numeric values in a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:mean(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:min ------------------------------------------------
--@api-stub: LDataFrame:min
-- Returns the minimum numeric value in a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:min(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:max ------------------------------------------------
--@api-stub: LDataFrame:max
-- Returns the maximum numeric value in a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:max(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:median ---------------------------------------------
--@api-stub: LDataFrame:median
-- Returns the median of numeric values in a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:median(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:stddev ---------------------------------------------
--@api-stub: LDataFrame:stddev
-- Returns the population standard deviation of numeric values in a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:stddev(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:variance -------------------------------------------
--@api-stub: LDataFrame:variance
-- Returns the population variance of numeric values in a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:variance(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:fillNil --------------------------------------------
--@api-stub: LDataFrame:fillNil
-- Replaces nil values in a column with the given value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:fillNil(col, val)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:apply ----------------------------------------------
--@api-stub: LDataFrame:apply
-- Applies a function to each value in a column, replacing cells with results.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:apply(col_val, func)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:toCSV ----------------------------------------------
--@api-stub: LDataFrame:toCSV
-- Serializes this DataFrame to a CSV string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:toCSV()  -- -> string
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:toJSON ---------------------------------------------
--@api-stub: LDataFrame:toJSON
-- Serializes this DataFrame to a JSON string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:toJSON()  -- -> string
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:toBinary -------------------------------------------
--@api-stub: LDataFrame:toBinary
-- Serializes this DataFrame to a binary LVDF string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:toBinary()  -- -> string
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:toTable --------------------------------------------
--@api-stub: LDataFrame:toTable
-- Converts this DataFrame to a Lua table of row tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:toTable()  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:toString -------------------------------------------
--@api-stub: LDataFrame:toString
-- Returns a formatted string table representation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:toString()  -- -> string
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:query ----------------------------------------------
--@api-stub: LDataFrame:query
-- Executes a SQL query against this DataFrame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:query(sql_str)  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:clone ----------------------------------------------
--@api-stub: LDataFrame:clone
-- Returns a deep copy of this DataFrame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:clone()  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withRollingMean ------------------------------------
--@api-stub: LDataFrame:withRollingMean
-- Add a rolling mean column. Rows with insufficient history get nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withRollingMean(col, window, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withRollingSum -------------------------------------
--@api-stub: LDataFrame:withRollingSum
-- Add a rolling sum column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withRollingSum(col, window, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withRollingMin -------------------------------------
--@api-stub: LDataFrame:withRollingMin
-- Add a rolling minimum column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withRollingMin(col, window, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withRollingMax -------------------------------------
--@api-stub: LDataFrame:withRollingMax
-- Add a rolling maximum column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withRollingMax(col, window, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withRank -------------------------------------------
--@api-stub: LDataFrame:withRank
-- Add a rank column (1-based, ties averaged).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withRank(col, [asc], "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withPctChange --------------------------------------
--@api-stub: LDataFrame:withPctChange
-- Add a percent-change-from-previous-row column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withPctChange(col, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withCumsum -----------------------------------------
--@api-stub: LDataFrame:withCumsum
-- Add a cumulative-sum column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withCumsum(col, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:groupAgg -------------------------------------------
--@api-stub: LDataFrame:groupAgg
-- Aggregate agg_col grouped by group_col using the named function.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:groupAgg(group_col, agg_col, fn_name)  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:pivot ----------------------------------------------
--@api-stub: LDataFrame:pivot
-- Creates a wide pivot table by reshaping rows into columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:pivot(row_col, col_col, val_col)  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:corr -----------------------------------------------
--@api-stub: LDataFrame:corr
-- Pearson correlation coefficient between two numeric columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:corr(col_a, col_b)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:correlationMatrix ----------------------------------
--@api-stub: LDataFrame:correlationMatrix
-- Compute a correlation matrix for all numeric columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:correlationMatrix()  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:zscoreCol ------------------------------------------
--@api-stub: LDataFrame:zscoreCol
-- Add a z-score column for the given numeric column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:zscoreCol(col, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:normalizeCol ---------------------------------------
--@api-stub: LDataFrame:normalizeCol
-- Add a min-max normalized column scaled to [out_min, out_max].
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:normalizeCol(col, out_min, out_max, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:outliers -------------------------------------------
--@api-stub: LDataFrame:outliers
-- Return a new DataFrame with only outlier rows (|z-score| > threshold).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:outliers(col, [threshold])  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:modeVal --------------------------------------------
--@api-stub: LDataFrame:modeVal
-- Return the most frequent value in a column (nil if empty).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:modeVal(col)  -- -> table|nil
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:entropy --------------------------------------------
--@api-stub: LDataFrame:entropy
-- Shannon entropy (bits) of the value distribution in a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:entropy(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:addRowBatch ----------------------------------------
--@api-stub: LDataFrame:addRowBatch
-- Add multiple rows at once from a table of row tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:addRowBatch(rows)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:getColumnAsF64 -------------------------------------
--@api-stub: LDataFrame:getColumnAsF64
-- Return a numeric column as a Lua array of numbers (nils → 0/nan).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:getColumnAsF64(col)  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:setColumnFromF64 -----------------------------------
--@api-stub: LDataFrame:setColumnFromF64
-- Set a numeric column from a Lua array of numbers.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:setColumnFromF64(col, values)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:type -----------------------------------------------
--@api-stub: LDataFrame:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:type()  -- -> string
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:typeOf ---------------------------------------------
--@api-stub: LDataFrame:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:typeOf("hero")  -- -> boolean
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withEval -------------------------------------------
--@api-stub: LDataFrame:withEval
-- Returns a new DataFrame with an additional computed column named `col_name`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withEval(col_name, expr)  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:pivotTable -----------------------------------------
--@api-stub: LDataFrame:pivotTable
-- Reshapes a long-format DataFrame into wide format.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:pivotTable()  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:rollingMean ----------------------------------------
--@api-stub: LDataFrame:rollingMean
-- Returns a new DataFrame with a rolling mean column appended.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:rollingMean(col, window, [result_col])  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:rollingSum -----------------------------------------
--@api-stub: LDataFrame:rollingSum
-- Returns a new DataFrame with a rolling sum column appended.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:rollingSum(col, window, [result_col])  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:rank -----------------------------------------------
--@api-stub: LDataFrame:rank
-- Returns a new DataFrame with a dense-rank column appended.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:rank(col, [order], [result_col])  -- -> DataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- -----------------------------------------------------------------------------
-- LDatabase methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDatabase:addTable --------------------------------------------
--@api-stub: LDatabase:addTable
-- Adds or replaces a table by cloning the given DataFrame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:addTable("hero", df_ud)
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:getTable --------------------------------------------
--@api-stub: LDatabase:getTable
-- Returns a copy of a table by name, or nil if not found.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:getTable("hero")  -- -> DataFrame?
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:removeTable -----------------------------------------
--@api-stub: LDatabase:removeTable
-- Drops the named table from this in-memory database if it exists.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:removeTable("hero")
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:hasTable --------------------------------------------
--@api-stub: LDatabase:hasTable
-- Returns true if a table with the given name exists.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:hasTable("hero")  -- -> boolean
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:listTables ------------------------------------------
--@api-stub: LDatabase:listTables
-- Returns a table of all table names.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:listTables()  -- -> table
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:tableCount ------------------------------------------
--@api-stub: LDatabase:tableCount
-- Returns the number of tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:tableCount()  -- -> integer
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:clear -----------------------------------------------
--@api-stub: LDatabase:clear
-- Drops every table from this in-memory database, leaving it empty.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:clear()
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:merge -----------------------------------------------
--@api-stub: LDatabase:merge
-- Merges all tables from another Database into this one.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:merge(other)
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:toJSON ----------------------------------------------
--@api-stub: LDatabase:toJSON
-- Serializes all tables to a JSON object string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:toJSON()  -- -> string
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:query -----------------------------------------------
--@api-stub: LDatabase:query
-- Executes a SQL query against the database tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:query(sql_str)  -- -> DataFrame
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:type ------------------------------------------------
--@api-stub: LDatabase:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:type()  -- -> string
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:typeOf ----------------------------------------------
--@api-stub: LDatabase:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:typeOf("hero")  -- -> boolean
-- (replace lDatabase_stub with your real LDatabase instance above)

-- -----------------------------------------------------------------------------
-- LGroupedFrame methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGroupedFrame:aggregate ---------------------------------------
--@api-stub: LGroupedFrame:aggregate
-- Apply a Lua function to aggregate a column's values per group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGroupedFrame_stub:aggregate(col_name, func)  -- -> DataFrame — new dataframe with group keys and aggregated values
-- (replace lGroupedFrame_stub with your real LGroupedFrame instance above)

-- ---- Stub: LGroupedFrame:type --------------------------------------------
--@api-stub: LGroupedFrame:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGroupedFrame_stub:type()  -- -> string
-- (replace lGroupedFrame_stub with your real LGroupedFrame instance above)

-- ---- Stub: LGroupedFrame:typeOf ------------------------------------------
--@api-stub: LGroupedFrame:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGroupedFrame_stub:typeOf("hero")  -- -> boolean
-- (replace lGroupedFrame_stub with your real LGroupedFrame instance above)

-- -----------------------------------------------------------------------------
-- LVecFrame methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LVecFrame:colAdd ----------------------------------------------
--@api-stub: LVecFrame:colAdd
-- Add a scalar to every element of a Float64 column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colAdd(col, val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colSub ----------------------------------------------
--@api-stub: LVecFrame:colSub
-- Subtract a scalar from every element of a Float64 column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colSub(col, val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colMul ----------------------------------------------
--@api-stub: LVecFrame:colMul
-- Multiply every element of a Float64 column by a scalar.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colMul(col, val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colDiv ----------------------------------------------
--@api-stub: LVecFrame:colDiv
-- Divide every element of a Float64 column by a scalar.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colDiv(col, val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colAbs ----------------------------------------------
--@api-stub: LVecFrame:colAbs
-- Apply absolute value to every element of a Float64 column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colAbs(col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colSqrt ---------------------------------------------
--@api-stub: LVecFrame:colSqrt
-- Apply square root to every element of a Float64 column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colSqrt(col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colFloor --------------------------------------------
--@api-stub: LVecFrame:colFloor
-- Apply floor to every element of a Float64 column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colFloor(col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colCeil ---------------------------------------------
--@api-stub: LVecFrame:colCeil
-- Apply ceiling to every element of a Float64 column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colCeil(col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colNeg ----------------------------------------------
--@api-stub: LVecFrame:colNeg
-- Negate every element of a Float64 column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colNeg(col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colClamp --------------------------------------------
--@api-stub: LVecFrame:colClamp
-- Clamp every element of a Float64 column to [min, max].
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colClamp(col, min_val, max_val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colOp -----------------------------------------------
--@api-stub: LVecFrame:colOp
-- Compute out[i] = left[i] op right[i] for every row.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colOp(out_col, left_col, op, right_col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:reduce ----------------------------------------------
--@api-stub: LVecFrame:reduce
-- Reduce an entire numeric column to a single value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:reduce(col, op)  -- -> number|nil
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:filterMask ------------------------------------------
--@api-stub: LVecFrame:filterMask
-- Build a boolean row mask: mask[i] = col[i] cmp_op val.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:filterMask(col, cmp_op, val)  -- -> table
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:applyMask -------------------------------------------
--@api-stub: LVecFrame:applyMask
-- Return a new VecFrame containing only the rows where mask[i] is true.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:applyMask(mask_tbl)  -- -> VecFrame
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colType ---------------------------------------------
--@api-stub: LVecFrame:colType
-- Return the dtype name of a column: "float64", "int64", "bool", or "text".
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colType(col)  -- -> string|nil
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colCast ---------------------------------------------
--@api-stub: LVecFrame:colCast
-- Cast a column to a new dtype: "float64", "int64", or "text".
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colCast(col, dtype)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:nrows -----------------------------------------------
--@api-stub: LVecFrame:nrows
-- Return the number of rows.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:nrows()  -- -> integer
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:ncols -----------------------------------------------
--@api-stub: LVecFrame:ncols
-- Return the number of columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:ncols()  -- -> integer
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:columns ---------------------------------------------
--@api-stub: LVecFrame:columns
-- Return a table of column names.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:columns()  -- -> table
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:parReduce -------------------------------------------
--@api-stub: LVecFrame:parReduce
-- Reduce multiple columns in parallel, returning {col → value} table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:parReduce(cols_tbl, op)  -- -> table
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:parScalarOp -----------------------------------------
--@api-stub: LVecFrame:parScalarOp
-- Apply a scalar op in parallel to multiple Float64 columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:parScalarOp(cols_tbl, op, val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:toDataFrame -----------------------------------------
--@api-stub: LVecFrame:toDataFrame
-- Convert this VecFrame back to a DataFrame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:toDataFrame()  -- -> DataFrame
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:type ------------------------------------------------
--@api-stub: LVecFrame:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:type()  -- -> string
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:typeOf ----------------------------------------------
--@api-stub: LVecFrame:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:typeOf("hero")  -- -> boolean
-- (replace lVecFrame_stub with your real LVecFrame instance above)
