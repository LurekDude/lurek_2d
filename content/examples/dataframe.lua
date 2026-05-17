-- content/examples/dataframe.lua
-- lurek.dataframe API examples: tabular data for analytics, leaderboards, item databases, and stat tracking.
-- Run: cargo run -- content/examples/dataframe.lua

--@api-stub: lurek.dataframe.newDataFrame
-- Creates an empty dataframe with no columns or rows
do
  -- Use newDataFrame when you need to build a table incrementally at runtime,
  -- such as tracking player session stats as events come in.
  local stats = lurek.dataframe.newDataFrame()

  -- Define the schema: each addColumn call creates a named column with a default value.
  -- The default is used when a row is added without specifying that column.
  stats:addColumn("name", "")
  stats:addColumn("score", 0)
  stats:addColumn("deaths", 0)

  -- Add rows as the session progresses
  stats:addRow({name = "Alice", score = 1200, deaths = 3})
  stats:addRow({name = "Bob", score = 980, deaths = 5})

  -- The dataframe now has 2 rows and 3 columns
  lurek.log.info("session stats: " .. stats:nrows() .. " players tracked")
end

--@api-stub: lurek.dataframe.newDatabase
-- Creates an empty dataframe database for managing multiple named tables
do
  -- A Database groups related dataframes under string keys.
  -- Use it to organize game data: one table for players, one for items, one for quests, etc.
  local db = lurek.dataframe.newDatabase()

  local players = lurek.dataframe.fromTable({{id = 1, name = "Alice", level = 12}})
  local items = lurek.dataframe.fromTable({{id = 1, name = "Iron Sword", dmg = 15}})

  -- Register tables by name for later retrieval or SQL-style cross-table queries
  db:addTable("players", players)
  db:addTable("items", items)

  lurek.log.info("database has " .. db:tableCount() .. " tables")
end

--@api-stub: lurek.dataframe.fromTable
-- Creates a dataframe from an array of row tables (most common constructor)
do
  -- fromTable is the fastest way to create a dataframe from existing Lua data.
  -- Each element is a table mapping column names to values.
  -- All rows should share the same keys; missing keys become nil.
  local enemies = lurek.dataframe.fromTable({
    {name = "goblin",  hp = 30,  atk = 5,  xp = 10},
    {name = "orc",     hp = 60,  atk = 12, xp = 25},
    {name = "dragon",  hp = 500, atk = 80, xp = 1000},
  })

  -- Useful for loading static game data defined in Lua tables
  lurek.log.info("enemy database: " .. enemies:nrows() .. " entries")
end

--@api-stub: lurek.dataframe.fromRows
-- Creates a dataframe from column names and positional row arrays
do
  -- fromRows is useful when data comes in array form (e.g., from a binary protocol)
  -- where you know column order but rows lack named keys.
  local columns = {"rank", "player", "score", "time_ms"}
  local rows = {
    {1, "Alice",  9500, 42300},
    {2, "Bob",    8200, 51200},
    {3, "Cara",   7800, 48100},
  }

  -- Column names map 1:1 with array positions in each row
  local leaderboard = lurek.dataframe.fromRows(columns, rows)
  lurek.log.info("rank #2: " .. leaderboard:getValue(2, "player"))
end

--@api-stub: lurek.dataframe.fromCSV
-- Parses a dataframe from CSV-formatted text
do
  -- fromCSV is ideal for loading exported spreadsheet data or config tables.
  -- The first line is treated as column headers.
  local csv = "weapon,damage,cost,rarity\nsword,12,50,common\nbow,8,40,common\nstaff,15,120,rare\n"
  local shop = lurek.dataframe.fromCSV(csv)

  -- Numeric columns are auto-detected, so you can immediately compute stats
  lurek.log.info("avg weapon damage = " .. shop:mean("damage"))
end

--@api-stub: lurek.dataframe.fromJSON
-- Parses a dataframe from a JSON array of objects
do
  -- fromJSON handles data from web APIs or save files stored as JSON.
  -- Expects a JSON array where each element is an object with consistent keys.
  local json = '[{"id":1,"name":"Alice","guild":"Phoenix"},{"id":2,"name":"Bob","guild":"Shadow"}]'
  local roster = lurek.dataframe.fromJSON(json)

  lurek.log.info("guild roster: " .. roster:nrows() .. " members")
end

--@api-stub: lurek.dataframe.fromBinary
-- Deserializes a dataframe from its compact binary format
do
  -- toBinary/fromBinary is the fastest serialization for save/load cycles.
  -- Binary format preserves exact types and is smaller than CSV or JSON.
  local original = lurek.dataframe.fromTable({
    {x = 1.5, y = 2.3, entity = "player"},
    {x = 4.0, y = 7.1, entity = "npc"},
  })

  -- Serialize to binary blob (suitable for file I/O or network transfer)
  local blob = original:toBinary()

  -- Restore the exact same dataframe structure
  local restored = lurek.dataframe.fromBinary(blob)
  lurek.log.info("restored " .. restored:nrows() .. " entities from binary")
end

--@api-stub: lurek.dataframe.random
-- Generates a random dataframe from column type definitions
do
  -- random() is great for testing, procedural generation, or populating mock data.
  -- Column defs: each entry is {column_name, type_hint}.
  -- Supported hints: "id" (sequential int), "int" (random integer), "float" (random float), "name" (random name), "bool".
  local defs = {
    {"mob_id", "id"},      -- sequential 1, 2, 3...
    {"hp", "int"},         -- random integers
    {"speed", "float"},    -- random floats
    {"name", "name"},      -- random name strings
  }

  -- Generate 100 random mobs with seed 42 for reproducibility
  local mob_pool = lurek.dataframe.random(defs, 100, 42)
  lurek.log.info("generated " .. mob_pool:nrows() .. " random mobs")
end

-- DataFrame methods

--@api-stub: DataFrame:nrows
-- Returns the number of rows in this dataframe
do
  -- Use nrows to check if a dataframe has data before processing
  local df = lurek.dataframe.fromTable({{name = "Alice"}, {name = "Bob"}, {name = "Cara"}})

  -- Common pattern: guard against empty frames before accessing values
  if df:nrows() > 0 then
    lurek.log.info("first player: " .. df:getValue(1, "name"))
  end
end

--@api-stub: DataFrame:ncols
-- Returns the number of columns in this dataframe
do
  -- ncols tells you how wide the schema is.
  -- Useful for dynamic rendering (e.g., how many columns to draw in a HUD table).
  local df = lurek.dataframe.fromTable({{x = 1, y = 2, z = 3, w = 4}})

  -- Iterate columns by index to build dynamic headers
  for i = 1, df:ncols() do
    lurek.log.info("column " .. i .. " = " .. df:columns()[i])
  end
end

--@api-stub: DataFrame:columns
-- Returns an array table of column names in order
do
  -- columns() gives you the schema as a string array.
  -- Useful for rendering table headers or validating imported data.
  local df = lurek.dataframe.fromTable({{hp = 100, mp = 50, stamina = 80}})
  local headers = df:columns()

  -- headers = {"hp", "mp", "stamina"} (order matches creation)
  for _, name in ipairs(headers) do
    lurek.log.info("stat: " .. name)
  end
end

--@api-stub: DataFrame:count
-- Returns the total count of non-nil items in this dataframe
do
  -- count() returns total cells (rows * cols) that are not nil.
  -- Useful for sparsity checks on analytics data.
  local df = lurek.dataframe.fromTable({
    {event = "kill", ts = 1.0},
    {event = "death", ts = 2.5},
    {event = "kill", ts = 3.2},
  })
  local total_cells = df:count()
  lurek.log.info("tracked " .. total_cells .. " data points this session")
end

--@api-stub: DataFrame:removeColumn
-- Removes a column from this dataframe by name or index
do
  -- Use removeColumn to strip sensitive or unnecessary data before export.
  -- Example: remove internal IDs before showing a leaderboard to players.
  local df = lurek.dataframe.fromTable({
    {name = "Alice", internal_id = "a7f3", score = 9500},
    {name = "Bob", internal_id = "b2c1", score = 8200},
  })

  -- Remove the internal field before serializing for display
  df:removeColumn("internal_id")
  lurek.log.info(df:toCSV())
end

--@api-stub: DataFrame:rename
-- Renames a column (by name or index) to a new name
do
  -- rename() is useful when loading external data with unfriendly headers.
  -- CSV exports often have spaces or abbreviations that need normalizing.
  local df = lurek.dataframe.fromCSV("Player Name,Pts,W/L\nAlice,1200,15/3\n")

  -- Normalize column names for easier programmatic access
  df:rename("Player Name", "name")
  df:rename("Pts", "points")
  lurek.log.info("first column is now: " .. df:columns()[1])
end

--@api-stub: DataFrame:getColumn
-- Returns all values in a column as an array table
do
  -- getColumn extracts a full column as a plain Lua array.
  -- Useful for feeding data into chart rendering or custom calculations.
  local df = lurek.dataframe.fromTable({
    {frame = 1, ms = 16.2},
    {frame = 2, ms = 15.8},
    {frame = 3, ms = 33.1},  -- spike!
  })

  -- Get all frame times for plotting or anomaly detection
  local times = df:getColumn("ms")
  lurek.log.info("frame times: " .. times[1] .. ", " .. times[2] .. ", " .. times[3])
end

--@api-stub: DataFrame:addRow
-- Appends a row and returns its one-based index
do
  -- addRow is the primary way to insert data at runtime.
  -- Returns the new row's 1-based index, useful for immediate reference.
  local event_log = lurek.dataframe.newDataFrame()
  event_log:addColumn("event", "")
  event_log:addColumn("timestamp", 0)
  event_log:addColumn("player", "")

  -- Log a game event; the returned index lets you reference this row later
  local idx = event_log:addRow({event = "boss_kill", timestamp = 125.4, player = "Alice"})
  lurek.log.info("logged event at row " .. idx)
end

--@api-stub: DataFrame:removeRow
-- Removes a row by one-based index
do
  -- removeRow deletes a specific entry. Rows after it shift down.
  -- Example: removing a disconnected player from the active roster.
  local roster = lurek.dataframe.fromTable({
    {name = "Alice", status = "active"},
    {name = "Bob", status = "disconnected"},
    {name = "Cara", status = "active"},
  })

  -- Remove the disconnected player (row 2)
  roster:removeRow(2)
  lurek.log.info("active players: " .. roster:nrows())
end

--@api-stub: DataFrame:getRow
-- Returns a row as a table keyed by column name
do
  -- getRow returns a single row as {col_name = value, ...}.
  -- Useful for reading one entity's full record.
  local inventory = lurek.dataframe.fromTable({
    {slot = 1, item = "Health Potion", qty = 5},
    {slot = 2, item = "Iron Sword", qty = 1},
  })

  -- Read slot 1 as a full record
  local slot1 = inventory:getRow(1)
  lurek.log.info(slot1.item .. " x" .. slot1.qty)
end

--@api-stub: DataFrame:getValue
-- Returns one cell value by row index and column reference
do
  -- getValue is the fastest way to read a single cell.
  -- Use it in tight loops or conditional checks.
  local df = lurek.dataframe.fromTable({
    {name = "Alice", hp = 80, max_hp = 100},
    {name = "Bob", hp = 15, max_hp = 100},
  })

  -- Check if any player is critically low
  for i = 1, df:nrows() do
    local hp = df:getValue(i, "hp")
    if hp < 30 then
      lurek.log.warn(df:getValue(i, "name") .. " is critically low: " .. hp .. " HP")
    end
  end
end

--@api-stub: DataFrame:head
-- Returns a new dataframe with the first N rows (default 5)
do
  -- head() is useful for previewing large datasets or showing "top N" results.
  local scores = lurek.dataframe.random({{"rank", "id"}, {"score", "int"}}, 100, 1)

  -- Preview the first 3 entries
  local top3 = scores:head(3)
  lurek.log.info("top 3 preview:\n" .. top3:toString())
end

--@api-stub: DataFrame:tail
-- Returns a new dataframe with the last N rows (default 5)
do
  -- tail() shows the most recent entries. Ideal for event logs or chat history.
  local events = lurek.dataframe.random({{"timestamp", "int"}, {"event", "name"}}, 50, 7)

  -- Show the 5 most recent events
  local recent = events:tail(5)
  lurek.log.info("recent events:\n" .. recent:toString())
end

--@api-stub: DataFrame:slice
-- Returns a one-based inclusive row slice as a new dataframe
do
  -- slice(start, end) extracts a range of rows. Both indices are inclusive.
  -- Great for pagination in a UI list.
  local all_items = lurek.dataframe.random({{"id", "id"}, {"name", "name"}, {"price", "int"}}, 100, 2)

  -- Page 2 of a 10-items-per-page list: rows 11 through 20
  local page2 = all_items:slice(11, 20)
  lurek.log.info("page 2 has " .. page2:nrows() .. " items")
end

--@api-stub: DataFrame:select
-- Returns a new dataframe with only the specified columns
do
  -- select() projects specific columns, discarding the rest.
  -- Useful for creating a "view" that only shows relevant fields.
  local full_data = lurek.dataframe.fromTable({
    {name = "Alice", hp = 80, mp = 30, x = 12.5, y = -3.2, internal_state = 7},
  })

  -- HUD only needs name, hp, mp -- hide position and internal data
  local hud_view = full_data:select("name", "hp", "mp")
  lurek.log.info(hud_view:toString())
end

--@api-stub: DataFrame:unique
-- Returns unique values from a column as an array table
do
  -- unique() extracts distinct values. Useful for building filter dropdowns
  -- or counting how many different enemy types exist.
  local spawns = lurek.dataframe.fromTable({
    {type = "goblin", zone = "forest"},
    {type = "orc", zone = "mountain"},
    {type = "goblin", zone = "cave"},
    {type = "dragon", zone = "mountain"},
  })

  local enemy_types = spawns:unique("type")
  lurek.log.info("distinct enemy types: " .. #enemy_types)
end

--@api-stub: DataFrame:groupBy
-- Groups rows by column value; returns a table of {key = sub-dataframe}
do
  -- groupBy splits a dataframe into sub-frames keyed by column value.
  -- Perfect for per-team stats, per-zone analysis, etc.
  local match_data = lurek.dataframe.fromTable({
    {team = "red",  player = "Alice", kills = 10},
    {team = "blue", player = "Bob",   kills = 7},
    {team = "red",  player = "Cara",  kills = 5},
    {team = "blue", player = "Dave",  kills = 12},
  })

  -- Split into per-team dataframes
  local by_team = match_data:groupBy("team")
  lurek.log.info("red team players: " .. by_team["red"]:nrows())
  lurek.log.info("blue team players: " .. by_team["blue"]:nrows())
end

--@api-stub: DataFrame:merge
-- Appends all rows from another dataframe into this one (in-place)
do
  -- merge() concatenates two frames vertically.
  -- Use it to combine data from multiple sources (e.g., round results).
  local round1 = lurek.dataframe.fromTable({{player = "Alice", score = 500}})
  local round2 = lurek.dataframe.fromTable({{player = "Alice", score = 700}})

  -- Combine both rounds into a single history
  round1:merge(round2)
  lurek.log.info("total records after merge: " .. round1:nrows())
end

--@api-stub: DataFrame:countBy
-- Counts occurrences of each value in a column; returns a new dataframe
do
  -- countBy creates a frequency table. Useful for finding the most common item,
  -- most-picked weapon, or most-visited zone.
  local loot_drops = lurek.dataframe.fromTable({
    {item = "potion"}, {item = "gold"}, {item = "potion"},
    {item = "gem"}, {item = "gold"}, {item = "potion"},
  })

  -- Result has columns: the grouped column and "count"
  local freq = loot_drops:countBy("item")
  lurek.log.info("loot frequency:\n" .. freq:toString())
end

--@api-stub: DataFrame:dropNil
-- Returns a new dataframe with rows where a column is nil removed
do
  -- dropNil filters out incomplete records.
  -- Common when optional fields are missing for some entries.
  local survey = lurek.dataframe.fromTable({
    {player = "Alice", rating = 5},
    {player = "Bob", rating = nil},   -- Bob didn't answer
    {player = "Cara", rating = 4},
  })

  -- Only process rows where rating is present
  local valid = survey:dropNil("rating")
  lurek.log.info("valid responses: " .. valid:nrows())
end

--@api-stub: DataFrame:sample
-- Returns a random subset of N rows (optional seed for reproducibility)
do
  -- sample() picks random rows without replacement.
  -- Useful for random encounters, test subsets, or A/B testing.
  local all_mobs = lurek.dataframe.random({{"id", "id"}, {"hp", "int"}, {"name", "name"}}, 1000, 9)

  -- Pick 50 random mobs for this dungeon floor (seed 123 for consistent generation)
  local floor_mobs = all_mobs:sample(50, 123)
  lurek.log.info("spawning " .. floor_mobs:nrows() .. " mobs on this floor")
end

--@api-stub: DataFrame:describe
-- Returns summary statistics (count, mean, std, min, max) for numeric columns
do
  -- describe() gives you a quick statistical overview of your data.
  -- Returns a dataframe where rows are statistics and columns are your numeric fields.
  local combat_log = lurek.dataframe.random({{"damage", "int"}, {"heal", "int"}}, 200, 11)

  -- Get min, max, mean, std for damage and heal at a glance
  local summary = combat_log:describe()
  lurek.log.info("combat stats:\n" .. summary:toString())
end

--@api-stub: DataFrame:sum
-- Returns the numeric sum of a column
do
  -- sum() totals all values in a numeric column.
  -- Use for total damage dealt, total gold earned, total distance traveled, etc.
  local hits = lurek.dataframe.fromTable({
    {source = "sword", dmg = 12},
    {source = "fireball", dmg = 45},
    {source = "arrow", dmg = 8},
  })

  local total_damage = hits:sum("dmg")
  lurek.log.info("total damage this combo: " .. total_damage)
end

--@api-stub: DataFrame:mean
-- Returns the arithmetic mean of a numeric column
do
  -- mean() computes the average. Useful for performance monitoring or balance analysis.
  local frame_stats = lurek.dataframe.fromTable({
    {frame = 1, dt_ms = 16.1},
    {frame = 2, dt_ms = 16.4},
    {frame = 3, dt_ms = 32.0},  -- dropped frame
    {frame = 4, dt_ms = 15.9},
  })

  local avg_dt = frame_stats:mean("dt_ms")
  lurek.log.info("average frame time: " .. string.format("%.1f", avg_dt) .. " ms")
end

--@api-stub: DataFrame:min
-- Returns the minimum value of a column
do
  -- min() finds the smallest value. Useful for best scores, fastest times, lowest prices.
  local speedrun = lurek.dataframe.fromTable({
    {attempt = 1, time_s = 142.5},
    {attempt = 2, time_s = 138.2},
    {attempt = 3, time_s = 145.0},
  })

  local best = speedrun:min("time_s")
  lurek.log.info("personal best: " .. best .. "s")
end

--@api-stub: DataFrame:max
-- Returns the maximum value of a column
do
  -- max() finds the largest value. Use for high scores, max damage, peak values.
  local season_scores = lurek.dataframe.fromTable({
    {week = 1, score = 1200},
    {week = 2, score = 4500},
    {week = 3, score = 3800},
  })

  local high_score = season_scores:max("score")
  lurek.log.info("season high score: " .. high_score)
end

--@api-stub: DataFrame:median
-- Returns the median (middle value) of a numeric column
do
  -- median() is robust against outliers unlike mean().
  -- Use it for "typical" frame time or "typical" damage output.
  local frame_times = lurek.dataframe.fromTable({
    {ms = 16}, {ms = 16}, {ms = 17}, {ms = 200},  -- one huge spike
  })

  -- median (16.5) is much more representative than mean (~62)
  local typical = frame_times:median("ms")
  lurek.log.info("typical frame time: " .. typical .. " ms")
end

--@api-stub: DataFrame:stddev
-- Returns the standard deviation of a numeric column
do
  -- stddev() measures spread. Low stddev = consistent performance; high = erratic.
  local perf = lurek.dataframe.random({{"frame_ms", "int"}}, 60, 3)

  local spread = perf:stddev("frame_ms")
  lurek.log.info("frame time stddev: " .. string.format("%.2f", spread) .. " ms")
end

--@api-stub: DataFrame:variance
-- Returns the variance of a numeric column
do
  -- variance() is stddev squared. Useful in statistical formulas.
  -- High variance in damage output = inconsistent weapon balance.
  local hits = lurek.dataframe.random({{"dmg", "int"}}, 100, 4)

  local v = hits:variance("dmg")
  lurek.log.info("damage variance: " .. string.format("%.1f", v))
end

--@api-stub: DataFrame:fillNil
-- Replaces nil cells in a column with a specified value
do
  -- fillNil patches missing data with a default.
  -- Use before computations that would fail on nil values.
  local scores = lurek.dataframe.fromTable({
    {player = "Alice", score = 10},
    {player = "Bob", score = nil},   -- Bob crashed mid-game
    {player = "Cara", score = 5},
  })

  -- Replace nil with 0 so sum/mean work correctly
  scores:fillNil("score", 0)
  lurek.log.info("total score after fill: " .. scores:sum("score"))
end

--@api-stub: DataFrame:toCSV
-- Serializes this dataframe to CSV text
do
  -- toCSV creates a string suitable for file export or clipboard copy.
  -- First row is column headers, subsequent rows are values.
  local leaderboard = lurek.dataframe.fromTable({
    {rank = 1, name = "Alice", score = 9500},
    {rank = 2, name = "Bob", score = 8200},
  })

  local csv = leaderboard:toCSV()
  -- Write to disk if filesystem is available
  if lurek.fs then lurek.fs.write("save/leaderboard.csv", csv) end
  lurek.log.info("exported CSV: " .. #csv .. " bytes")
end

--@api-stub: DataFrame:toJSON
-- Serializes this dataframe to a JSON array of objects
do
  -- toJSON produces a JSON string for web API output or inter-process communication.
  local save_data = lurek.dataframe.fromTable({
    {slot = 1, name = "World 1", playtime = 3600},
    {slot = 2, name = "World 2", playtime = 1200},
  })

  local json = save_data:toJSON()
  if lurek.fs then lurek.fs.write("save/slots.json", json) end
  lurek.log.info("exported JSON: " .. #json .. " bytes")
end

--@api-stub: DataFrame:toBinary
-- Serializes this dataframe to a compact binary format
do
  -- toBinary is the most space-efficient and fastest serialization.
  -- Use it for autosave, network sync, or large dataset caching.
  local world_state = lurek.dataframe.fromTable({
    {entity_id = 1, x = 10.5, y = 20.3, hp = 100},
    {entity_id = 2, x = -5.0, y = 12.7, hp = 45},
  })

  local blob = world_state:toBinary()
  if lurek.fs then lurek.fs.write("save/world.lvdf", blob) end
  lurek.log.info("binary size: " .. #blob .. " bytes")
end

--@api-stub: DataFrame:toTable
-- Converts this dataframe to a plain Lua array of row tables
do
  -- toTable() gives you back raw Lua tables for custom processing.
  -- Use when you need to iterate with Lua-native patterns.
  local df = lurek.dataframe.fromTable({
    {name = "Alice", hp = 80},
    {name = "Bob", hp = 50},
  })

  local rows = df:toTable()
  -- rows is now a plain Lua array: {{name="Alice", hp=80}, {name="Bob", hp=50}}
  for _, row in ipairs(rows) do
    lurek.log.info(row.name .. " has " .. row.hp .. " HP")
  end
end

--@api-stub: DataFrame:rows
-- Returns an iterator for use in for-loops (index, row_table)
do
  -- rows() provides a generic-for iterator that yields (index, row_table).
  -- More idiomatic than manual index loops for sequential processing.
  local party = lurek.dataframe.fromTable({
    {name = "Alice", role = "tank", hp = 120},
    {name = "Bob", role = "healer", hp = 60},
    {name = "Cara", role = "dps", hp = 80},
  })

  -- Iterate all party members with their position index
  for i, member in party:rows() do
    lurek.log.info("#" .. i .. " " .. member.name .. " (" .. member.role .. ")")
  end
end

--@api-stub: DataFrame:toString
-- Formats this dataframe as a human-readable aligned text table
do
  -- toString() produces a pretty-printed table for debug output or console display.
  local party = lurek.dataframe.fromTable({
    {name = "Alice", hp = 80, class = "warrior"},
    {name = "Bob", hp = 50, class = "mage"},
  })

  -- Great for lurek.log.info during development
  lurek.log.info("party:\n" .. party:toString())
end

--@api-stub: DataFrame:query
-- Runs a SQL SELECT query against this dataframe (table alias is "t")
do
  -- query() lets you use SQL syntax for complex filtering and projection.
  -- The dataframe is exposed as table "t" in the SQL context.
  local players = lurek.dataframe.fromTable({
    {name = "Alice", hp = 80, level = 12},
    {name = "Bob", hp = 20, level = 5},
    {name = "Cara", hp = 45, level = 8},
  })

  -- Find players with low HP who might need healing
  local wounded = players:query("SELECT name, hp FROM t WHERE hp < 50")
  lurek.log.info("wounded players: " .. wounded:nrows())
end

--@api-stub: DataFrame:clone
-- Returns a deep copy of this dataframe (modifications don't affect the original)
do
  -- clone() creates an independent copy. Essential when you want to modify
  -- data without corrupting the original (e.g., "what-if" simulations).
  local base_stats = lurek.dataframe.fromTable({
    {stat = "atk", value = 10},
    {stat = "def", value = 8},
  })

  -- Create a buffed copy for simulation without touching base_stats
  local buffed = base_stats:clone()
  buffed:setValue(1, "value", 15)  -- boost attack in the copy only
  lurek.log.info("base atk=" .. base_stats:getValue(1, "value") ..
                 " buffed atk=" .. buffed:getValue(1, "value"))
end

--@api-stub: DataFrame:correlationMatrix
-- Returns a correlation matrix dataframe for all numeric columns
do
  -- correlationMatrix shows how numeric columns relate to each other.
  -- Values near 1 or -1 indicate strong correlation (useful for game balance).
  local balance = lurek.dataframe.random({{"damage", "int"}, {"cost", "int"}, {"weight", "int"}}, 50, 5)

  -- Check if high-damage weapons are also the most expensive (should they be?)
  local matrix = balance:correlationMatrix()
  lurek.log.info("correlation:\n" .. matrix:toString())
end

--@api-stub: DataFrame:modeVal
-- Returns the most frequently occurring value in a column
do
  -- modeVal finds the most common value (the "mode" in statistics).
  -- Useful for finding the most popular weapon, most common drop, etc.
  local weapon_picks = lurek.dataframe.fromTable({
    {match = 1, weapon = "sword"},
    {match = 2, weapon = "bow"},
    {match = 3, weapon = "sword"},
    {match = 4, weapon = "staff"},
    {match = 5, weapon = "sword"},
  })

  local most_popular = weapon_picks:modeVal("weapon")
  lurek.log.info("most picked weapon: " .. tostring(most_popular))
end

--@api-stub: DataFrame:entropy
-- Returns the Shannon entropy of a column (measures diversity)
do
  -- entropy() quantifies how "spread out" values are.
  -- High entropy = diverse picks; low entropy = dominated by one value.
  -- Useful for measuring class balance in multiplayer games.
  local class_picks = lurek.dataframe.fromTable({
    {class = "warrior"}, {class = "mage"}, {class = "warrior"},
    {class = "rogue"}, {class = "mage"}, {class = "healer"},
  })

  local h = class_picks:entropy("class")
  lurek.log.info("class diversity (entropy): " .. string.format("%.2f", h) .. " bits")
end

--@api-stub: DataFrame:addRowBatch
-- Appends multiple rows at once from positional arrays (faster than repeated addRow)
do
  -- addRowBatch is significantly faster than calling addRow in a loop.
  -- Rows are arrays matching column order (not keyed tables).
  local positions = lurek.dataframe.newDataFrame()
  positions:addColumn("x", 0)
  positions:addColumn("y", 0)
  positions:addColumn("entity_id", 0)

  -- Batch-insert 3 positions at once (order matches columns: x, y, entity_id)
  positions:addRowBatch({
    {10.5, 20.0, 1},
    {-3.0,  5.5, 2},
    { 0.0, -1.0, 3},
  })
  lurek.log.info("entities tracked: " .. positions:nrows())
end

--@api-stub: DataFrame:getColumnAsF64
-- Returns a numeric column as an array of Lua numbers (float64)
do
  -- getColumnAsF64 extracts numeric data as a flat number array.
  -- Useful for feeding into math functions or VecFrame operations.
  local df = lurek.dataframe.random({{"hp", "int"}}, 16, 6)

  -- Returns a plain array of numbers
  local hp_values = df:getColumnAsF64("hp")
  lurek.log.info("first entity HP = " .. hp_values[1])
end

--@api-stub: DataFrame:setColumnFromF64
-- Replaces a numeric column's values from an array of numbers
do
  -- setColumnFromF64 bulk-writes computed values back into a column.
  -- Use after external math processing.
  local df = lurek.dataframe.fromTable({{x = 0}, {x = 0}, {x = 0}})

  -- Overwrite the "x" column with computed values
  df:setColumnFromF64("x", {1.5, 2.5, 3.5})
  lurek.log.info("sum of x after set: " .. df:sum("x"))  -- 7.5
end

--@api-stub: DataFrame:type
-- Returns the type name string "DataFrame" for this handle
do
  -- type() and typeOf() let you do runtime type checking on dataframe handles.
  local df = lurek.dataframe.newDataFrame()
  if df:type() == "DataFrame" then
    lurek.log.info("confirmed: this is a DataFrame handle")
  end
end

--@api-stub: DataFrame:typeOf
-- Returns true if this handle matches the given type name
do
  -- typeOf checks against "LDataFrame", "DataFrame", or "Object".
  -- Useful for generic functions that accept multiple handle types.
  local df = lurek.dataframe.newDataFrame()
  if df:typeOf("Object") then
    lurek.log.info("DataFrame is an Object (all handles are)")
  end
end

--@api-stub: DataFrame:withEval
-- Returns a new dataframe with an added column computed from an expression
do
  -- withEval creates a derived column using a math expression referencing other columns.
  -- The expression is evaluated row-by-row in the Rust engine (fast).
  local weapons = lurek.dataframe.fromTable({
    {name = "sword", atk = 10, bonus = 4},
    {name = "axe", atk = 15, bonus = 2},
    {name = "dagger", atk = 6, bonus = 8},
  })

  -- Compute effective damage: atk + bonus * 1.5 (applied per row)
  local with_eff = weapons:withEval("effective_dmg", "atk + bonus * 1.5")
  lurek.log.info("best effective damage: " .. with_eff:max("effective_dmg"))
end

-- Database methods

--@api-stub: Database:getTable
-- Returns a copy of a named table from the database (or nil if not found)
do
  -- getTable retrieves a dataframe by its registered name.
  -- Returns nil if the name doesn't exist, so always check.
  local db = lurek.dataframe.newDatabase()
  db:addTable("players", lurek.dataframe.fromTable({{name = "Alice", level = 10}}))

  local players = db:getTable("players")
  if players then
    lurek.log.info("players table has " .. players:nrows() .. " rows")
  end
end

--@api-stub: Database:removeTable
-- Removes a named table from the database
do
  -- removeTable deletes a table by name. Use for cleanup or session resets.
  local db = lurek.dataframe.newDatabase()
  db:addTable("temp_cache", lurek.dataframe.newDataFrame())

  -- Clean up temporary data
  db:removeTable("temp_cache")
  lurek.log.info("tables remaining: " .. db:tableCount())
end

--@api-stub: Database:hasTable
-- Returns true if the database contains a table with the given name
do
  -- hasTable lets you check before inserting to avoid overwriting.
  local db = lurek.dataframe.newDatabase()

  -- Only create the scores table if it doesn't already exist
  if not db:hasTable("scores") then
    db:addTable("scores", lurek.dataframe.newDataFrame())
    lurek.log.info("created scores table")
  end
end

--@api-stub: Database:listTables
-- Returns an array of all table names in the database
do
  -- listTables gives you the full schema of the database.
  -- Useful for debug UIs or save-game inspection tools.
  local db = lurek.dataframe.newDatabase()
  db:addTable("players", lurek.dataframe.newDataFrame())
  db:addTable("items", lurek.dataframe.newDataFrame())
  db:addTable("quests", lurek.dataframe.newDataFrame())

  for _, name in ipairs(db:listTables()) do
    lurek.log.info("table: " .. name)
  end
end

--@api-stub: Database:tableCount
-- Returns the number of tables in this database
do
  -- tableCount is a quick way to check if the database is populated.
  local db = lurek.dataframe.newDatabase()
  db:addTable("scores", lurek.dataframe.newDataFrame())
  db:addTable("config", lurek.dataframe.newDataFrame())

  if db:tableCount() > 0 then
    lurek.log.info("database has " .. db:tableCount() .. " tables")
  end
end

--@api-stub: Database:clear
-- Removes all tables from this database
do
  -- clear() wipes the database for a fresh start (e.g., new game session).
  local db = lurek.dataframe.newDatabase()
  db:addTable("round1", lurek.dataframe.newDataFrame())
  db:addTable("round2", lurek.dataframe.newDataFrame())

  -- Reset for a new session
  db:clear()
  lurek.log.info("database cleared, tables=" .. db:tableCount())
end

--@api-stub: Database:merge
-- Merges all tables from another database into this one
do
  -- merge() combines two databases. Tables with same name get overwritten.
  -- Useful for loading mod data on top of base data.
  local base = lurek.dataframe.newDatabase()
  base:addTable("weapons", lurek.dataframe.fromTable({{name = "sword", dmg = 10}}))

  local mod_data = lurek.dataframe.newDatabase()
  mod_data:addTable("extra_weapons", lurek.dataframe.fromTable({{name = "laser", dmg = 99}}))

  -- Mod's tables are added into the base database
  base:merge(mod_data)
  lurek.log.info("after mod merge: " .. base:tableCount() .. " tables")
end

--@api-stub: Database:toJSON
-- Serializes the entire database (all tables) to JSON text
do
  -- toJSON serializes every table in the database as a JSON object of arrays.
  -- Use for full save-game export or debug snapshots.
  local db = lurek.dataframe.newDatabase()
  db:addTable("players", lurek.dataframe.fromTable({{name = "Alice", level = 5}}))
  db:addTable("inventory", lurek.dataframe.fromTable({{item = "potion", qty = 3}}))

  local json = db:toJSON()
  if lurek.fs then lurek.fs.write("save/full_save.json", json) end
  lurek.log.info("database JSON: " .. #json .. " bytes")
end

--@api-stub: Database:query
-- Runs a SQL query across multiple database tables (supports JOINs)
do
  -- Database:query() lets you write SQL that references multiple tables by name.
  -- This is the most powerful way to combine related data.
  pcall(function()
    local db = lurek.dataframe.newDatabase()
    db:addTable("players", lurek.dataframe.fromTable({
      {id = 1, name = "Alice"},
      {id = 2, name = "Bob"},
    }))
    db:addTable("scores", lurek.dataframe.fromTable({
      {player_id = 1, points = 9000},
      {player_id = 2, points = 7500},
    }))

    -- Cross-table JOIN: match players to their scores
    local result = db:query(
      "SELECT players.name, scores.points FROM players, scores WHERE players.id = scores.player_id"
    )
    lurek.log.info("joined result: " .. result:nrows() .. " rows")
  end)
end

--@api-stub: Database:type
-- Returns the type name string "Database" for this handle
do
  local db = lurek.dataframe.newDatabase()
  if db:type() == "Database" then
    lurek.log.info("confirmed: this is a Database handle")
  end
end

--@api-stub: Database:typeOf
-- Returns true if this handle matches the given type name
do
  -- typeOf checks against "LDatabase", "Database", or "Object".
  local db = lurek.dataframe.newDatabase()
  if db:typeOf("Object") then
    lurek.log.info("Database is an Object")
  end
end

--@api-stub: GroupedFrame:aggregate
-- Aggregates a column in each group using a custom Lua function
do
  -- GroupedFrame is returned by groupByObj(). It lets you run custom aggregation
  -- functions per group (more flexible than groupAgg's built-in functions).
  local df = lurek.dataframe.newDataFrame()
  df:addColumn("damage", 0)
  df:addColumn("class", "")
  df:addRow({damage = 12, class = "warrior"})
  df:addRow({damage = 8, class = "mage"})
  df:addRow({damage = 20, class = "warrior"})
  df:addRow({damage = 5, class = "mage"})

  local grouped = df:groupByObj("class")
  if grouped and grouped.aggregate then
    -- Custom aggregation: compute mean damage per class
    local result = grouped:aggregate("damage", function(vals)
      local sum = 0
      for _, v in ipairs(vals) do sum = sum + v end
      return sum / #vals
    end)
    lurek.log.debug("aggregate done", "dataframe")
  end
end

--@api-stub: DataFrame:groupByObj
-- Groups rows by a column and returns a GroupedFrame object
do
  -- groupByObj returns a LGroupedFrame handle (unlike groupBy which returns a plain table).
  -- The handle supports aggregate() for custom per-group calculations.
  local df = lurek.dataframe.newDataFrame()
  df:addColumn("score", 0)
  df:addColumn("region", "")
  df:addRow({score = 100, region = "EU"})
  df:addRow({score = 200, region = "NA"})
  df:addRow({score = 150, region = "EU"})

  if df.groupByObj then
    local grouped = df:groupByObj("region")
    lurek.log.debug("groupByObj returned: " .. tostring(grouped), "dataframe")
  end
end

-- VecFrame: vectorized columnar operations
--
-- VecFrame stores each column as a typed flat buffer (float64/int64/bool/text)
-- with an optional null-validity bitmap.  Operations run over the entire column
-- at once — no per-cell Lua dispatch — allowing the Rust compiler to apply
-- SIMD vectorization and rayon parallelism.
--
-- Workflow: DataFrame → toVec() → fast bulk ops → toDataFrame() (or fromVec)

--@api-stub: lurek.dataframe.toVec
-- Converts a dataframe to a vectorized VecFrame for bulk numeric operations
do
  -- toVec() converts a DataFrame into a VecFrame optimized for batch math.
  -- All numeric operations on VecFrame run in Rust without per-cell Lua overhead.
  local df = lurek.dataframe.fromCSV("hp,mp,stamina\n100,50,80\n200,80,60\n150,60,90\n")

  -- Convert to VecFrame for fast bulk processing
  local vf = lurek.dataframe.toVec(df)
  lurek.log.info("VecFrame: " .. vf:nrows() .. " rows, " .. vf:ncols() .. " cols")
end

--@api-stub: lurek.dataframe.fromVec
-- Converts a VecFrame back to a regular DataFrame
do
  -- fromVec() is the inverse of toVec().
  -- After performing fast bulk operations, convert back to DataFrame for display/query.
  local df = lurek.dataframe.fromCSV("hp,mp\n100,50\n200,80\n")
  local vf = lurek.dataframe.toVec(df)

  -- Apply a damage reduction to all HP values at once
  vf:colMul("hp", 0.5)

  -- Convert back to DataFrame for normal operations
  local result = lurek.dataframe.fromVec(vf)
  lurek.log.info("HP after 50% reduction: " .. tostring(result:getValue(1, "hp")))
end

--@api-stub: VecFrame:colAdd
-- Adds a scalar value to every cell in a numeric column (in-place)
do
  -- colAdd shifts all values up by a constant. Use for buffs, offsets, or adjustments.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("score\n10\n20\n30\n"))

  -- Give everyone a +5 bonus (runs in Rust, no Lua loop)
  vf:colAdd("score", 5)

  local df = vf:toDataFrame()
  lurek.log.info("score after +5 bonus: " .. tostring(df:getValue(1, "score")))  -- 15
end

--@api-stub: VecFrame:colMul
-- Multiplies every cell in a numeric column by a scalar (in-place)
do
  -- colMul scales all values. Use for damage multipliers, difficulty scaling, etc.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("dmg\n10\n15\n20\n"))

  -- Apply a 1.5x critical hit multiplier to all damage values
  vf:colMul("dmg", 1.5)

  local df = vf:toDataFrame()
  lurek.log.info("crit damage: " .. tostring(df:getValue(1, "dmg")))  -- 15
end

--@api-stub: VecFrame:colClamp
-- Clamps every cell in a numeric column to [min, max] range (in-place)
do
  -- colClamp enforces bounds. Essential for HP (0 to max), percentages (0 to 100), etc.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n-5\n50\n150\n"))

  -- Ensure HP stays in valid range [0, 100]
  vf:colClamp("hp", 0, 100)

  local df = vf:toDataFrame()
  lurek.log.info("clamped: " .. tostring(df:getValue(1, "hp")) .. ", "
    .. tostring(df:getValue(3, "hp")))  -- 0, 100
end

--@api-stub: VecFrame:colAbs
-- Applies absolute value to every cell in a numeric column (in-place)
do
  -- colAbs converts negatives to positives. Useful for distances or magnitudes.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("velocity\n-3\n4\n-1\n"))

  -- Get speed (magnitude) from velocity (which can be negative)
  vf:colAbs("velocity")

  local df = vf:toDataFrame()
  lurek.log.info("speed values: " .. tostring(df:getValue(1, "velocity")))  -- 3
end

--@api-stub: VecFrame:colSqrt
-- Applies square root to every cell in a numeric column (in-place)
do
  -- colSqrt computes sqrt per cell. Useful for converting squared distances to actual distances.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("dist_sq\n9\n16\n25\n"))

  -- Convert squared distances to actual distances
  vf:colSqrt("dist_sq")

  local df = vf:toDataFrame()
  lurek.log.info("distances: " .. tostring(df:getValue(1, "dist_sq")) .. ", "
    .. tostring(df:getValue(2, "dist_sq")))  -- 3, 4
end

--@api-stub: VecFrame:colOp
-- Applies a binary operation between two columns, storing result in a new column
do
  -- colOp computes (left_col <op> right_col) per row into a new output column.
  -- Supported ops: "add", "sub", "mul", "div".
  local df = lurek.dataframe.fromCSV("atk,def\n30,10\n40,15\n20,5\n")
  local vf = lurek.dataframe.toVec(df)

  -- Compute net damage = atk - def for each entity
  vf:colOp("net_dmg", "atk", "sub", "def")

  local result = vf:toDataFrame()
  lurek.log.info("net damage row 1: " .. tostring(result:getValue(1, "net_dmg")))  -- 20
end

--@api-stub: VecFrame:reduce
-- Reduces a numeric column to a single value using a named operation
do
  -- reduce() computes an aggregate over a VecFrame column without converting back.
  -- Supported ops: "sum", "mean", "min", "max", "count".
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("score\n10\n20\n30\n"))

  local total = vf:reduce("score", "sum")    -- 60
  local avg = vf:reduce("score", "mean")     -- 20
  lurek.log.info("total=" .. total .. " avg=" .. avg)
end

--@api-stub: VecFrame:filterMask
-- Builds a boolean mask array from a column comparison
do
  -- filterMask creates a {true, false, ...} array based on a condition.
  -- Use with applyMask to filter the VecFrame efficiently.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n10\n50\n90\n"))

  -- Build a mask: which rows have hp >= 50?
  local mask = vf:filterMask("hp", ">=", 50)
  -- mask = {false, true, true}
  lurek.log.info("row 2 passes filter: " .. tostring(mask[2]))
end

--@api-stub: VecFrame:applyMask
-- Returns a new VecFrame containing only rows where mask is true
do
  -- applyMask filters rows using a boolean array (from filterMask or custom logic).
  -- This is the vectorized equivalent of DataFrame:filter().
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n10\n50\n90\n"))

  -- Filter to only rows with hp >= 50
  local mask = vf:filterMask("hp", ">=", 50)
  local alive = vf:applyMask(mask)

  lurek.log.info("alive entities: " .. alive:nrows())  -- 2
end

--@api-stub: VecFrame:colType
-- Returns the data type name of a vectorized column ("float64", "int64", "text", "bool")
do
  -- colType tells you how a column is stored internally.
  -- Useful for debugging type mismatches in operations.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n10\n20\n"))

  local dtype = vf:colType("hp")
  lurek.log.info("hp stored as: " .. dtype)  -- "float64"
end

--@api-stub: VecFrame:parReduce
-- Reduces multiple columns in parallel using a named operation
do
  -- parReduce runs the same reduction on multiple columns simultaneously.
  -- Exploits multi-core CPUs for large datasets.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp,mp,atk\n10,5,8\n20,10,12\n30,15,6\n"))

  -- Sum all three stat columns in parallel
  local sums = vf:parReduce({"hp", "mp", "atk"}, "sum")
  for col, s in pairs(sums) do
    lurek.log.info(col .. " total = " .. tostring(s))
  end
end

--@api-stub: VecFrame:toDataFrame
-- Converts this VecFrame back to a regular DataFrame
do
  -- toDataFrame() is the same as lurek.dataframe.fromVec(vf) but called as a method.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("v\n1\n2\n3\n"))
  vf:colAdd("v", 10)

  -- Method-style conversion back to DataFrame
  local df = vf:toDataFrame()
  lurek.log.info("v[1] after +10: " .. tostring(df:getValue(1, "v")))  -- 11
end

--@api-stub: VecFrame:colSub
-- Subtracts a scalar from every cell in a numeric column (in-place)
do
  -- colSub decreases all values. Use for drain effects, decay, or cost deduction.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("stamina\n100\n80\n60\n"))

  -- All entities lose 10 stamina per turn
  vf:colSub("stamina", 10)

  local df = vf:toDataFrame()
  lurek.log.info("stamina after drain: " .. tostring(df:getValue(1, "stamina")))  -- 90
end

--@api-stub: VecFrame:colDiv
-- Divides every cell in a numeric column by a scalar (in-place)
do
  -- colDiv normalizes values or applies fractional scaling.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("score\n100\n200\n150\n"))

  -- Normalize scores to 0-1 range by dividing by max (200)
  vf:colDiv("score", 200)

  local df = vf:toDataFrame()
  lurek.log.info("normalized score[1]: " .. tostring(df:getValue(1, "score")))  -- 0.5
end

--@api-stub: VecFrame:colFloor
-- Applies floor (round down) to every cell in a numeric column (in-place)
do
  -- colFloor rounds down to the nearest integer. Use for tile snapping or integer coercion.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x\n1.9\n2.1\n3.7\n"))

  -- Snap to grid (floor to integer)
  vf:colFloor("x")

  local df = vf:toDataFrame()
  lurek.log.info("floored: " .. tostring(df:getValue(1, "x")) .. ", "
    .. tostring(df:getValue(3, "x")))  -- 1, 3
end

--@api-stub: VecFrame:colCeil
-- Applies ceil (round up) to every cell in a numeric column (in-place)
do
  -- colCeil rounds up. Use for "minimum 1 damage" type calculations.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("y\n1.1\n2.5\n3.0\n"))

  vf:colCeil("y")

  local df = vf:toDataFrame()
  lurek.log.info("ceiled y[1]: " .. tostring(df:getValue(1, "y")))  -- 2
end

--@api-stub: VecFrame:colNeg
-- Negates every cell in a numeric column (in-place)
do
  -- colNeg flips the sign. Use for reversing velocity, inverting offsets, etc.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("vy\n3\n-2\n0\n"))

  -- Reverse vertical velocity (bounce)
  vf:colNeg("vy")

  local df = vf:toDataFrame()
  lurek.log.info("bounced vy[1]: " .. tostring(df:getValue(1, "vy")))  -- -3
end

--@api-stub: VecFrame:colCast
-- Casts a column to a different data type (e.g., "float64", "int64")
do
  -- colCast changes the internal storage type of a column.
  -- Use when you need float precision for integer data or vice versa.
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("level\n1\n2\n3\n"))

  -- Cast int column to float for fractional math
  vf:colCast("level", "float64")
  lurek.log.info("level dtype after cast: " .. vf:colType("level"))

  local df = vf:toDataFrame()
  lurek.log.info("level[1] as float: " .. tostring(df:getValue(1, "level")))
end

--@api-stub: VecFrame:nrows
-- Returns the number of rows in this VecFrame
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("v\n10\n20\n30\n"))

  -- Row count is consistent between VecFrame and its source DataFrame
  lurek.log.info("VecFrame rows: " .. vf:nrows())
  assert(vf:nrows() == 3)
end

--@api-stub: VecFrame:ncols
-- Returns the number of columns in this VecFrame
do
  local df = lurek.dataframe.fromCSV("hp,mp,atk\n10,5,8\n")
  local vf = lurek.dataframe.toVec(df)

  -- Column count matches the source DataFrame
  lurek.log.info("VecFrame cols: " .. vf:ncols())
  assert(vf:ncols() == df:ncols())
end

--@api-stub: VecFrame:columns
-- Returns an array of column names in this VecFrame
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp,mp,stamina\n1,2,3\n"))

  -- Column names are preserved from the source DataFrame
  local cols = vf:columns()
  for i, name in ipairs(cols) do
    lurek.log.info("VecFrame col " .. i .. ": " .. name)
  end
end

--@api-stub: VecFrame:type
-- Returns the type name string "VecFrame" for this handle
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x\n1\n"))
  if vf:type() == "VecFrame" then
    lurek.log.info("confirmed: this is a VecFrame handle")
  end
end

--@api-stub: VecFrame:typeOf
-- Returns true if this handle matches the given type name
do
  -- typeOf checks against "VecFrame" or "Object".
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x\n1\n"))
  if vf:typeOf("Object") then
    lurek.log.info("VecFrame is an Object")
  end
end

--@api-stub: DataFrame:addColumn
-- Adds a new column with an optional default value for existing rows
do
  -- addColumn extends the schema. Existing rows get the default value.
  -- The default can be a single value (applied to all rows) or an array of per-row values.
  local df = lurek.dataframe.newDataFrame()
  df:addRow({name = "Alice", score = 85})
  df:addRow({name = "Bob", score = 72})

  -- Add a "grade" column after the fact; existing rows get the provided default
  df:addColumn("grade", "ungraded")
  lurek.log.info("columns now: " .. df:ncols())
end

--@api-stub: Database:addTable
-- Adds or replaces a named table in the database
do
  -- addTable registers a dataframe under a string key.
  -- If a table with that name exists, it gets replaced.
  local db = lurek.dataframe.newDatabase()
  local users = lurek.dataframe.newDataFrame()
  users:addRow({id = 1, name = "Alice", role = "admin"})

  db:addTable("users", users)
  lurek.log.info("database now has " .. db:tableCount() .. " table(s)")
end

--@api-stub: DataFrame:apply
-- Transforms every cell in a column using a Lua function (in-place)
do
  -- apply() runs your function on each cell and replaces it with the return value.
  -- Use for custom transformations that simple math can't express.
  local df = lurek.dataframe.newDataFrame()
  df:addRow({score = 60, name = "Alice"})
  df:addRow({score = 80, name = "Bob"})
  df:addRow({score = 45, name = "Cara"})

  -- Convert numeric scores to letter grades
  df:apply("score", function(v)
    if v >= 70 then return "pass" else return "fail" end
  end)
  lurek.log.info("applied grade transform")
end

--@api-stub: DataFrame:corr
-- Returns the Pearson correlation between two numeric columns
do
  -- corr() measures linear relationship between two variables.
  -- +1 = perfectly correlated, -1 = inversely correlated, 0 = no relationship.
  local df = lurek.dataframe.newDataFrame()
  df:addRow({playtime = 10, skill = 20})
  df:addRow({playtime = 30, skill = 55})
  df:addRow({playtime = 50, skill = 85})

  -- Check if playtime correlates with skill level
  local r = df:corr("playtime", "skill")
  lurek.log.info("playtime-skill correlation: " .. string.format("%.3f", r))
end

--@api-stub: DataFrame:filter
-- Returns a new dataframe with rows matching a condition (col op val)
do
  -- filter() creates a subset based on a comparison.
  -- Supported ops: "==", "!=", ">", ">=", "<", "<=".
  local players = lurek.dataframe.newDataFrame()
  players:addRow({name = "Alice", level = 20})
  players:addRow({name = "Bob", level = 5})
  players:addRow({name = "Cara", level = 35})

  -- Find high-level players for the raid
  local raiders = players:filter("level", ">=", 15)
  lurek.log.info("raid-eligible: " .. raiders:nrows() .. " players")
end

--@api-stub: DataFrame:groupAgg
-- Groups by one column and aggregates another with a built-in function
do
  -- groupAgg is a shorthand: group by one column, aggregate another.
  -- Built-in aggregates: "sum", "mean", "min", "max", "count".
  local sales = lurek.dataframe.newDataFrame()
  sales:addRow({region = "North", revenue = 500})
  sales:addRow({region = "North", revenue = 300})
  sales:addRow({region = "South", revenue = 700})

  -- Total revenue per region
  local totals = sales:groupAgg("region", "revenue", "sum")
  lurek.log.info("revenue by region:\n" .. totals:toString())
end

--@api-stub: DataFrame:join
-- Joins two dataframes by column (inner, left, right, or outer)
do
  -- join() combines rows from two dataframes where a key matches.
  -- Supports: "inner" (default), "left", "right", "outer".
  local players = lurek.dataframe.newDataFrame()
  players:addRow({id = 1, name = "Alice"})
  players:addRow({id = 2, name = "Bob"})

  local guilds = lurek.dataframe.newDataFrame()
  guilds:addRow({player_id = 1, guild = "Phoenix"})
  guilds:addRow({player_id = 2, guild = "Shadow"})

  -- Inner join: match players.id to guilds.player_id
  local merged = players:join(guilds, "id", "player_id", "inner")
  lurek.log.info("joined rows: " .. merged:nrows())
end

--@api-stub: DataFrame:normalizeCol
-- Adds a range-normalized column (maps values to [out_min, out_max])
do
  -- normalizeCol scales a numeric column to a target range.
  -- Use for normalizing stats to 0-1 for ML inputs or UI bar widths.
  local df = lurek.dataframe.newDataFrame()
  df:addRow({val = 10})
  df:addRow({val = 50})
  df:addRow({val = 90})

  -- Normalize "val" to [0.0, 1.0] and store in "val_norm"
  df:normalizeCol("val", 0.0, 1.0, "val_norm")
  lurek.log.info("normalized column added")
end

--@api-stub: DataFrame:outliers
-- Returns rows where a column value is a statistical outlier (z-score based)
do
  -- outliers() finds rows with values far from the mean.
  -- Default threshold is 2.0 standard deviations.
  local df = lurek.dataframe.newDataFrame()
  for i = 1, 10 do df:addRow({response_ms = 15 + i}) end
  df:addRow({response_ms = 1000})  -- obvious outlier (lag spike)

  local spikes = df:outliers("response_ms", 2.0)
  lurek.log.info("lag spikes detected: " .. spikes:nrows())
end

--@api-stub: VecFrame:parScalarOp
-- Applies a scalar operation to multiple columns in parallel
do
  -- parScalarOp runs the same scalar op on multiple columns at once, using threads.
  -- Supported ops: "add", "sub", "mul", "div".
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x,y,z\n1.0,4.0,2.0\n2.0,5.0,3.0\n3.0,6.0,4.0\n"))

  -- Double all coordinate values simultaneously (multi-threaded)
  vf:parScalarOp({"x", "y", "z"}, "mul", 2.0)
  lurek.log.info("parallel scalar op done")
end

--@api-stub: DataFrame:pivot
-- Pivots rows into columns using row key, column key, and value fields
do
  -- pivot() reshapes data from long format to wide format.
  -- Each unique value in col_col becomes a new column.
  local df = lurek.dataframe.newDataFrame()
  df:addRow({player = "Alice", stat = "hp", value = 100})
  df:addRow({player = "Alice", stat = "mp", value = 50})
  df:addRow({player = "Bob", stat = "hp", value = 80})
  df:addRow({player = "Bob", stat = "mp", value = 70})

  -- Pivot: players as rows, stats as columns
  local wide = df:pivot("player", "stat", "value")
  lurek.log.info("pivot columns: " .. wide:ncols())
end

--@api-stub: DataFrame:pivotTable
-- Builds a pivot table with aggregation (like a spreadsheet pivot)
do
  -- pivotTable groups by two dimensions and aggregates.
  -- Like a cross-tab or spreadsheet pivot table.
  local df = lurek.dataframe.newDataFrame()
  df:addRow({region = "North", product = "Sword", sales = 50})
  df:addRow({region = "North", product = "Shield", sales = 30})
  df:addRow({region = "South", product = "Sword", sales = 70})
  df:addRow({region = "South", product = "Shield", sales = 40})

  -- Pivot: region as rows, product as columns, sum of sales
  local pt = df:pivotTable("region", "product", "sales", "sum")
  lurek.log.info("pivot table:\n" .. pt:toString())
end

--@api-stub: DataFrame:rank
-- Returns a new dataframe with a rank column added
do
  -- rank() assigns a position (1st, 2nd, 3rd...) based on a column's value.
  -- Use for leaderboard position calculation.
  local df = lurek.dataframe.newDataFrame()
  df:addRow({player = "Alice", score = 80})
  df:addRow({player = "Bob", score = 95})
  df:addRow({player = "Cara", score = 72})

  -- Rank by score descending (highest = rank 1)
  local ranked = df:rank("score", "desc", "position")
  lurek.log.info("ranked:\n" .. ranked:toString())
end

--@api-stub: DataFrame:rollingMean
-- Returns a new dataframe with a rolling average column added
do
  -- rollingMean smooths noisy data over a window of N rows.
  -- Common for frame time smoothing or trend detection.
  local df = lurek.dataframe.newDataFrame()
  for _, v in ipairs({16, 17, 33, 16, 15, 16, 32, 16}) do
    df:addRow({frame_ms = v})
  end

  -- 3-frame rolling average to smooth spikes
  local smoothed = df:rollingMean("frame_ms", 3)
  lurek.log.info("smoothed frame data:\n" .. smoothed:head(5):toString())
end

--@api-stub: DataFrame:rollingSum
-- Returns a new dataframe with a rolling sum column added
do
  -- rollingSum totals over a sliding window. Useful for "damage in last N hits".
  local df = lurek.dataframe.newDataFrame()
  for _, v in ipairs({10, 20, 15, 30, 5}) do
    df:addRow({dmg = v})
  end

  -- Sum of damage over last 3 hits
  local windowed = df:rollingSum("dmg", 3)
  lurek.log.info("rolling sum data:\n" .. windowed:toString())
end

--@api-stub: DataFrame:setValue
-- Sets one cell value by row index and column reference
do
  -- setValue modifies a single cell in-place. Use for targeted updates.
  local df = lurek.dataframe.newDataFrame()
  df:addRow({player = "Alice", score = 50})

  -- Player earned points — update their score
  df:setValue(1, "score", 150)
  lurek.log.info("updated score: " .. df:getValue(1, "score"))
end

--@api-stub: DataFrame:sort
-- Returns a new sorted dataframe by column (ascending or descending)
do
  -- sort() orders rows by a column. Use for leaderboards, priority queues, etc.
  local df = lurek.dataframe.newDataFrame()
  df:addRow({name = "Cara", score = 80})
  df:addRow({name = "Alice", score = 95})
  df:addRow({name = "Bob", score = 60})

  -- Sort descending for a high-score list
  local leaderboard = df:sort("score", false)
  lurek.log.info("1st place: " .. leaderboard:getValue(1, "name"))
end

--@api-stub: DataFrame:withCumsum
-- Adds a cumulative sum column (running total) in-place
do
  -- withCumsum creates a running total column. Use for total gold over time,
  -- cumulative XP, or progressive score tracking.
  local df = lurek.dataframe.newDataFrame()
  for _, xp in ipairs({100, 50, 200, 75}) do
    df:addRow({xp_gained = xp})
  end

  -- Column "total_xp" will be: 100, 150, 350, 425
  df:withCumsum("xp_gained", "total_xp")
  lurek.log.info("cumulative XP column added")
end

--@api-stub: DataFrame:withPctChange
-- Adds a percent-change column (row-over-row change rate) in-place
do
  -- withPctChange shows the rate of change between consecutive rows.
  -- Useful for detecting sudden spikes or drops in metrics.
  local df = lurek.dataframe.newDataFrame()
  for _, price in ipairs({100, 110, 121, 133}) do
    df:addRow({gold_price = price})
  end

  -- Shows ~10% growth each step
  df:withPctChange("gold_price", "gold_change_pct")
  lurek.log.info("percent change column added")
end

--@api-stub: DataFrame:withRank
-- Adds a rank column in-place based on a source column
do
  -- withRank assigns ordinal positions without creating a new dataframe.
  local df = lurek.dataframe.newDataFrame()
  df:addRow({player = "Alice", pts = 10})
  df:addRow({player = "Bob", pts = 30})
  df:addRow({player = "Cara", pts = 20})

  -- Rank ascending: lowest pts = rank 1
  df:withRank("pts", true, "pts_rank")
  lurek.log.info("rank column added in-place")
end

--@api-stub: DataFrame:withRollingMax
-- Adds a rolling maximum column in-place
do
  -- withRollingMax tracks the peak value over a sliding window.
  -- Use for "max damage in last N hits" or "peak FPS in last N frames".
  local df = lurek.dataframe.newDataFrame()
  for _, v in ipairs({3, 1, 4, 1, 5, 9, 2, 6}) do
    df:addRow({value = v})
  end

  -- Track the maximum over a 3-row window
  df:withRollingMax("value", 3, "peak_3")
  lurek.log.info("rolling max column added")
end

--@api-stub: DataFrame:withRollingMean
-- Adds a rolling mean column in-place
do
  -- withRollingMean smooths data inline (same as rollingMean but modifies in-place).
  local df = lurek.dataframe.newDataFrame()
  for i = 1, 5 do df:addRow({temp = 20 + i}) end

  df:withRollingMean("temp", 3, "temp_smooth")
  lurek.log.info("rolling mean column added in-place")
end

--@api-stub: DataFrame:withRollingMin
-- Adds a rolling minimum column in-place
do
  -- withRollingMin tracks the lowest value in a sliding window.
  -- Use for "minimum HP in last N ticks" monitoring.
  local df = lurek.dataframe.newDataFrame()
  for _, v in ipairs({5, 3, 8, 2, 7, 1}) do
    df:addRow({hp = v})
  end

  -- Track the minimum over a 3-row window
  df:withRollingMin("hp", 3, "hp_floor")
  lurek.log.info("rolling min column added")
end

--@api-stub: DataFrame:withRollingSum
-- Adds a rolling sum column in-place
do
  -- withRollingSum tracks a windowed total inline.
  local df = lurek.dataframe.newDataFrame()
  for i = 1, 5 do df:addRow({sales = i * 10}) end

  -- Sum of last 3 periods
  df:withRollingSum("sales", 3, "sales_3period")
  lurek.log.info("rolling sum column added in-place")
end

--@api-stub: DataFrame:zscoreCol
-- Adds a z-score normalized column in-place
do
  -- zscoreCol standardizes values: (value - mean) / stddev.
  -- Result has mean=0, stddev=1. Use for comparing across different scales.
  local df = lurek.dataframe.newDataFrame()
  for i = 1, 6 do df:addRow({stat = i * 5}) end

  -- Normalize "stat" to z-scores in column "stat_z"
  df:zscoreCol("stat", "stat_z")
  lurek.log.info("z-score normalized column added")
end

-- -----------------------------------------------------------------------------
-- LGroupedFrame methods
-- -----------------------------------------------------------------------------

--@api-stub: LDataFrame:lazy
-- Starts a lazy query pipeline from this dataframe
do
  -- lazy() creates a deferred query builder. Steps are chained but not executed
  -- until you call :collect(). This allows the engine to optimize the query plan.
  local df = lurek.dataframe.fromTable({
    {name = "alice", hp = 12, team = "red"},
    {name = "bob", hp = 7, team = "blue"},
    {name = "cara", hp = 20, team = "red"},
  })

  -- Create a lazy query handle (no work done yet)
  local q = df:lazy()
  lurek.log.info("lazy query type: " .. tostring(q:type()))
end

--@api-stub: LLazyQuery
-- Lazy query pipeline: chain filter, sort, head, tail, limit, slice, select, dropNil, then collect
do
  -- LazyQuery chains multiple operations before executing them all at once.
  -- This can be more efficient than applying each operation individually.
  local df = lurek.dataframe.fromTable({
    {name = "alice", hp = 12, mana = 5, team = "red"},
    {name = "bob", hp = 7, mana = nil, team = "blue"},
    {name = "cara", hp = 20, mana = 9, team = "red"},
    {name = "dave", hp = 15, mana = 3, team = "blue"},
  })

  -- Verify type
  local q = df:lazy()
  local is_lazy = q:typeOf("LLazyQuery")
  lurek.log.info("is lazy query: " .. tostring(is_lazy))

  -- Chain: filter hp > 10, then collect results
  local filtered = df:lazy():filter("hp", ">", 10):collect()

  -- Chain: sort by hp descending, take top 2
  local sorted = df:lazy():sort("hp", false):head(2):collect()

  -- Chain: get last 2 rows
  local tailed = df:lazy():tail(2):collect()

  -- Chain: limit to 3 rows maximum
  local limited = df:lazy():limit(3):collect()

  -- Chain: slice rows 2 through 4 (inclusive)
  local sliced = df:lazy():slice(2, 4):collect()

  -- Chain: drop rows where mana is nil
  local non_nil = df:lazy():dropNil("mana"):collect()

  -- Chain: keep only name and hp columns
  local selected = df:lazy():select({"name", "hp"}):collect()

  lurek.log.info("filtered: " .. filtered:nrows() .. " rows")
  lurek.log.info("top 2 by hp: " .. sorted:nrows() .. " rows")
  lurek.log.info("tailed: " .. tailed:nrows() .. " rows")
  lurek.log.info("limited: " .. limited:nrows() .. " rows")
  lurek.log.info("sliced: " .. sliced:nrows() .. " rows")
  lurek.log.info("non-nil mana: " .. non_nil:nrows() .. " rows")
  lurek.log.info("selected cols: " .. selected:ncols() .. " cols")
end

print("content/examples/dataframe.lua")

-- =============================================================================
-- STUBS: 121 uncovered lurek.dataframe API item(s)
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
-- Returns the number of rows in this dataframe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:nrows()  -- -> integer
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:ncols ----------------------------------------------
--@api-stub: LDataFrame:ncols
-- Returns the number of columns in this dataframe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:ncols()  -- -> integer
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:columns --------------------------------------------
--@api-stub: LDataFrame:columns
-- Returns all column names in order. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:columns()  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:count ----------------------------------------------
--@api-stub: LDataFrame:count
-- Returns the row count for this dataframe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:count()  -- -> integer
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:addColumn ------------------------------------------
--@api-stub: LDataFrame:addColumn
-- Adds a column with an optional default value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:addColumn("hero", [default])
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:removeColumn ---------------------------------------
--@api-stub: LDataFrame:removeColumn
-- Removes a column by name or one-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:removeColumn(col)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:rename ---------------------------------------------
--@api-stub: LDataFrame:rename
-- Renames a column by name or one-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:rename(col, new_name)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:getColumn ------------------------------------------
--@api-stub: LDataFrame:getColumn
-- Returns a column as an array table. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:getColumn(col)  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:addRow ---------------------------------------------
--@api-stub: LDataFrame:addRow
-- Adds a row from an optional map table and returns its one-based row index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:addRow([row_tbl])  -- -> integer
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:removeRow ------------------------------------------
--@api-stub: LDataFrame:removeRow
-- Removes a row by one-based index. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:removeRow(row)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:getRow ---------------------------------------------
--@api-stub: LDataFrame:getRow
-- Returns a row as a table keyed by column name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:getRow(row)  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:getValue -------------------------------------------
--@api-stub: LDataFrame:getValue
-- Returns one cell value by one-based row and column reference.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:getValue(row, col)  -- -> LuaValue
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:setValue -------------------------------------------
--@api-stub: LDataFrame:setValue
-- Sets one cell value by one-based row and column reference.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:setValue(row, col, val)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:filter ---------------------------------------------
--@api-stub: LDataFrame:filter
-- Returns rows whose column value matches a comparison.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:filter(col, op, val)  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:sort -----------------------------------------------
--@api-stub: LDataFrame:sort
-- Returns rows sorted by a column. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:sort(col, [ascending])  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:head -----------------------------------------------
--@api-stub: LDataFrame:head
-- Returns the first rows of this dataframe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:head([n])  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:tail -----------------------------------------------
--@api-stub: LDataFrame:tail
-- Returns the last rows of this dataframe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:tail([n])  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:slice ----------------------------------------------
--@api-stub: LDataFrame:slice
-- Returns a one-based inclusive row slice.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:slice(start, end)  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:select ---------------------------------------------
--@api-stub: LDataFrame:select
-- Returns a dataframe with selected columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:select(...)  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:unique ---------------------------------------------
--@api-stub: LDataFrame:unique
-- Returns unique values from a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:unique(col)  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:groupBy --------------------------------------------
--@api-stub: LDataFrame:groupBy
-- Groups rows by a column and returns a table from group key to dataframe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:groupBy(col)  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:groupByObj -----------------------------------------
--@api-stub: LDataFrame:groupByObj
-- Groups rows by a column and returns a grouped-frame object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:groupByObj(col)  -- -> LGroupedFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:join -----------------------------------------------
--@api-stub: LDataFrame:join
-- Joins this dataframe with another dataframe by column references.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:join()  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:merge ----------------------------------------------
--@api-stub: LDataFrame:merge
-- Appends another dataframe into this dataframe in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:merge(other)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:countBy --------------------------------------------
--@api-stub: LDataFrame:countBy
-- Counts occurrences of each value in a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:countBy(col)  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:dropNil --------------------------------------------
--@api-stub: LDataFrame:dropNil
-- Returns rows where the chosen column is not nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:dropNil(col)  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:sample ---------------------------------------------
--@api-stub: LDataFrame:sample
-- Returns a sampled dataframe. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:sample(5, [seed])  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:describe -------------------------------------------
--@api-stub: LDataFrame:describe
-- Returns summary statistics for numeric columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:describe()  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:sum ------------------------------------------------
--@api-stub: LDataFrame:sum
-- Returns the numeric sum of a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:sum(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:mean -----------------------------------------------
--@api-stub: LDataFrame:mean
-- Returns the numeric mean of a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:mean(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:min ------------------------------------------------
--@api-stub: LDataFrame:min
-- Returns the minimum value of a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:min(col)  -- -> LuaValue
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:max ------------------------------------------------
--@api-stub: LDataFrame:max
-- Returns the maximum value of a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:max(col)  -- -> LuaValue
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:median ---------------------------------------------
--@api-stub: LDataFrame:median
-- Returns the numeric median of a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:median(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:stddev ---------------------------------------------
--@api-stub: LDataFrame:stddev
-- Returns the numeric standard deviation of a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:stddev(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:variance -------------------------------------------
--@api-stub: LDataFrame:variance
-- Returns the numeric variance of a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:variance(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:fillNil --------------------------------------------
--@api-stub: LDataFrame:fillNil
-- Replaces nil cells in a column with a value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:fillNil(col, val)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:apply ----------------------------------------------
--@api-stub: LDataFrame:apply
-- Applies a Lua function to each value in a column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:apply(col_val, func)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:toCSV ----------------------------------------------
--@api-stub: LDataFrame:toCSV
-- Serializes this dataframe to CSV text.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:toCSV()  -- -> string
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:toJSON ---------------------------------------------
--@api-stub: LDataFrame:toJSON
-- Serializes this dataframe to JSON text.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:toJSON()  -- -> string
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:toBinary -------------------------------------------
--@api-stub: LDataFrame:toBinary
-- Serializes this dataframe to binary data.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:toBinary()  -- -> string
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:toTable --------------------------------------------
--@api-stub: LDataFrame:toTable
-- Converts this dataframe to an array table of row tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:toTable()  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:rows -----------------------------------------------
--@api-stub: LDataFrame:rows
-- Returns an iterator function over one-based row index and row table pairs.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:rows()  -- -> function
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:toString -------------------------------------------
--@api-stub: LDataFrame:toString
-- Formats this dataframe as a human-readable text table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:toString()  -- -> string
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:query ----------------------------------------------
--@api-stub: LDataFrame:query
-- Runs a SQL-style query against this dataframe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:query(sql_str)  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:clone ----------------------------------------------
--@api-stub: LDataFrame:clone
-- Returns a deep copy of this dataframe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:clone()  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withRollingMean ------------------------------------
--@api-stub: LDataFrame:withRollingMean
-- Adds a rolling mean column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withRollingMean(col, window, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withRollingSum -------------------------------------
--@api-stub: LDataFrame:withRollingSum
-- Adds a rolling sum column in place. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withRollingSum(col, window, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withRollingMin -------------------------------------
--@api-stub: LDataFrame:withRollingMin
-- Adds a rolling minimum column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withRollingMin(col, window, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withRollingMax -------------------------------------
--@api-stub: LDataFrame:withRollingMax
-- Adds a rolling maximum column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withRollingMax(col, window, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withRank -------------------------------------------
--@api-stub: LDataFrame:withRank
-- Adds a rank column in place. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withRank(col, [asc], "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withPctChange --------------------------------------
--@api-stub: LDataFrame:withPctChange
-- Adds a percent-change column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withPctChange(col, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withCumsum -----------------------------------------
--@api-stub: LDataFrame:withCumsum
-- Adds a cumulative-sum column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withCumsum(col, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:groupAgg -------------------------------------------
--@api-stub: LDataFrame:groupAgg
-- Groups by one column and aggregates another column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:groupAgg(group_col, agg_col, fn_name)  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:pivot ----------------------------------------------
--@api-stub: LDataFrame:pivot
-- Pivots rows into columns using row, column, and value fields.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:pivot(row_col, col_col, val_col)  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:corr -----------------------------------------------
--@api-stub: LDataFrame:corr
-- Returns correlation between two numeric columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:corr(col_a, col_b)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:correlationMatrix ----------------------------------
--@api-stub: LDataFrame:correlationMatrix
-- Returns a correlation matrix for numeric columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:correlationMatrix()  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:zscoreCol ------------------------------------------
--@api-stub: LDataFrame:zscoreCol
-- Adds a z-score normalized column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:zscoreCol(col, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:normalizeCol ---------------------------------------
--@api-stub: LDataFrame:normalizeCol
-- Adds a range-normalized column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:normalizeCol(col, out_min, out_max, "hero")
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:outliers -------------------------------------------
--@api-stub: LDataFrame:outliers
-- Returns rows considered outliers for a numeric column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:outliers(col, [threshold])  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:modeVal --------------------------------------------
--@api-stub: LDataFrame:modeVal
-- Returns the mode value of a column. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:modeVal(col)  -- -> LuaValue
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:entropy --------------------------------------------
--@api-stub: LDataFrame:entropy
-- Returns entropy for a column. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:entropy(col)  -- -> number
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:addRowBatch ----------------------------------------
--@api-stub: LDataFrame:addRowBatch
-- Appends multiple rows from array-style row tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:addRowBatch(rows)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:getColumnAsF64 -------------------------------------
--@api-stub: LDataFrame:getColumnAsF64
-- Returns a numeric column as an array of numbers.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:getColumnAsF64(col)  -- -> table
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:setColumnFromF64 -----------------------------------
--@api-stub: LDataFrame:setColumnFromF64
-- Replaces a numeric column from an array table of numbers.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:setColumnFromF64(col, values)
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:type -----------------------------------------------
--@api-stub: LDataFrame:type
-- Returns the Lua-visible type name for this dataframe handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:type()  -- -> string
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:typeOf ---------------------------------------------
--@api-stub: LDataFrame:typeOf
-- Returns whether this dataframe handle matches a supported type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:typeOf("hero")  -- -> boolean
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:withEval -------------------------------------------
--@api-stub: LDataFrame:withEval
-- Returns a dataframe with a column computed from an expression.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:withEval(col_name, expr)  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:pivotTable -----------------------------------------
--@api-stub: LDataFrame:pivotTable
-- Builds a pivot table using row key, column key, value column, and aggregate function.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:pivotTable()  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:rollingMean ----------------------------------------
--@api-stub: LDataFrame:rollingMean
-- Returns a dataframe with a rolling mean column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:rollingMean(col, window, [result_col])  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:rollingSum -----------------------------------------
--@api-stub: LDataFrame:rollingSum
-- Returns a dataframe with a rolling sum column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:rollingSum(col, window, [result_col])  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- ---- Stub: LDataFrame:rank -----------------------------------------------
--@api-stub: LDataFrame:rank
-- Returns a dataframe with a rank column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataFrame_stub:rank(col, [order], [result_col])  -- -> LDataFrame
-- (replace lDataFrame_stub with your real LDataFrame instance above)

-- -----------------------------------------------------------------------------
-- LDatabase methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDatabase:addTable --------------------------------------------
--@api-stub: LDatabase:addTable
-- Adds or replaces a named dataframe table in the database.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:addTable("hero", df_ud)
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:getTable --------------------------------------------
--@api-stub: LDatabase:getTable
-- Returns a copy of a named table when it exists.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:getTable("hero")  -- -> LuaValue
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:removeTable -----------------------------------------
--@api-stub: LDatabase:removeTable
-- Removes a named table from the database.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:removeTable("hero")
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:hasTable --------------------------------------------
--@api-stub: LDatabase:hasTable
-- Returns whether a named table exists.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:hasTable("hero")  -- -> boolean
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:listTables ------------------------------------------
--@api-stub: LDatabase:listTables
-- Returns all table names in the database.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:listTables()  -- -> table
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:tableCount ------------------------------------------
--@api-stub: LDatabase:tableCount
-- Returns the number of tables in the database.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:tableCount()  -- -> integer
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:clear -----------------------------------------------
--@api-stub: LDatabase:clear
-- Removes every table from the database.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:clear()
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:merge -----------------------------------------------
--@api-stub: LDatabase:merge
-- Merges another database into this database.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:merge(other)
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:toJSON ----------------------------------------------
--@api-stub: LDatabase:toJSON
-- Serializes the database to JSON text.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:toJSON()  -- -> string
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:query -----------------------------------------------
--@api-stub: LDatabase:query
-- Runs a SQL-style query against the database tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:query(sql_str)  -- -> LDataFrame
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:type ------------------------------------------------
--@api-stub: LDatabase:type
-- Returns the Lua-visible type name for this database handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:type()  -- -> string
-- (replace lDatabase_stub with your real LDatabase instance above)

-- ---- Stub: LDatabase:typeOf ----------------------------------------------
--@api-stub: LDatabase:typeOf
-- Returns whether this database handle matches a supported type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDatabase_stub:typeOf("hero")  -- -> boolean
-- (replace lDatabase_stub with your real LDatabase instance above)

-- -----------------------------------------------------------------------------
-- LGroupedFrame methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGroupedFrame:aggregate ---------------------------------------
--@api-stub: LGroupedFrame:aggregate
-- Aggregates one numeric column in every group by calling a Lua function with that group's numeric values.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGroupedFrame_stub:aggregate(col_name, func)  -- -> LDataFrame
-- (replace lGroupedFrame_stub with your real LGroupedFrame instance above)

-- ---- Stub: LGroupedFrame:type --------------------------------------------
--@api-stub: LGroupedFrame:type
-- Returns the Lua-visible type name for this grouped frame handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGroupedFrame_stub:type()  -- -> string
-- (replace lGroupedFrame_stub with your real LGroupedFrame instance above)

-- ---- Stub: LGroupedFrame:typeOf ------------------------------------------
--@api-stub: LGroupedFrame:typeOf
-- Returns whether this grouped frame handle matches a supported type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGroupedFrame_stub:typeOf("hero")  -- -> boolean
-- (replace lGroupedFrame_stub with your real LGroupedFrame instance above)

-- -----------------------------------------------------------------------------
-- LLazyQuery methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LLazyQuery:filter ---------------------------------------------
--@api-stub: LLazyQuery:filter
-- Adds a filter step to the lazy query.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:filter(col, op, val)  -- -> LLazyQuery
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- ---- Stub: LLazyQuery:sort -----------------------------------------------
--@api-stub: LLazyQuery:sort
-- Adds a sort step to the lazy query. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:sort(col, [ascending])  -- -> LLazyQuery
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- ---- Stub: LLazyQuery:head -----------------------------------------------
--@api-stub: LLazyQuery:head
-- Adds a head limit step to the lazy query.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:head(5)  -- -> LLazyQuery
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- ---- Stub: LLazyQuery:tail -----------------------------------------------
--@api-stub: LLazyQuery:tail
-- Adds a tail limit step to the lazy query.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:tail(5)  -- -> LLazyQuery
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- ---- Stub: LLazyQuery:limit ----------------------------------------------
--@api-stub: LLazyQuery:limit
-- Adds a row limit step to the lazy query.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:limit(5)  -- -> LLazyQuery
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- ---- Stub: LLazyQuery:slice ----------------------------------------------
--@api-stub: LLazyQuery:slice
-- Adds a one-based row slice step to the lazy query.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:slice(start, end)  -- -> LLazyQuery
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- ---- Stub: LLazyQuery:dropNil --------------------------------------------
--@api-stub: LLazyQuery:dropNil
-- Adds a step that drops rows with nil values in a column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:dropNil(col)  -- -> LLazyQuery
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- ---- Stub: LLazyQuery:select ---------------------------------------------
--@api-stub: LLazyQuery:select
-- Adds a column selection step to the lazy query.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:select(cols)  -- -> LLazyQuery
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- ---- Stub: LLazyQuery:collect --------------------------------------------
--@api-stub: LLazyQuery:collect
-- Executes the lazy query and returns a dataframe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:collect()  -- -> LDataFrame
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- ---- Stub: LLazyQuery:type -----------------------------------------------
--@api-stub: LLazyQuery:type
-- Returns the Lua-visible type name for this lazy query handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:type()  -- -> string
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- ---- Stub: LLazyQuery:typeOf ---------------------------------------------
--@api-stub: LLazyQuery:typeOf
-- Returns whether this lazy query handle matches a supported type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLazyQuery_stub:typeOf("hero")  -- -> boolean
-- (replace lLazyQuery_stub with your real LLazyQuery instance above)

-- -----------------------------------------------------------------------------
-- LVecFrame methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LVecFrame:colAdd ----------------------------------------------
--@api-stub: LVecFrame:colAdd
-- Adds a scalar to a numeric column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colAdd(col, val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colSub ----------------------------------------------
--@api-stub: LVecFrame:colSub
-- Subtracts a scalar from a numeric column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colSub(col, val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colMul ----------------------------------------------
--@api-stub: LVecFrame:colMul
-- Multiplies a numeric column by a scalar in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colMul(col, val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colDiv ----------------------------------------------
--@api-stub: LVecFrame:colDiv
-- Divides a numeric column by a scalar in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colDiv(col, val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colAbs ----------------------------------------------
--@api-stub: LVecFrame:colAbs
-- Applies absolute value to a numeric column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colAbs(col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colSqrt ---------------------------------------------
--@api-stub: LVecFrame:colSqrt
-- Applies square root to a numeric column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colSqrt(col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colFloor --------------------------------------------
--@api-stub: LVecFrame:colFloor
-- Applies floor to a numeric column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colFloor(col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colCeil ---------------------------------------------
--@api-stub: LVecFrame:colCeil
-- Applies ceil to a numeric column in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colCeil(col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colNeg ----------------------------------------------
--@api-stub: LVecFrame:colNeg
-- Negates a numeric column in place. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colNeg(col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colClamp --------------------------------------------
--@api-stub: LVecFrame:colClamp
-- Clamps a numeric column in place. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colClamp(col, min_val, max_val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colOp -----------------------------------------------
--@api-stub: LVecFrame:colOp
-- Applies a binary column operation into an output column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colOp(out_col, left_col, op, right_col)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:reduce ----------------------------------------------
--@api-stub: LVecFrame:reduce
-- Reduces a numeric column with a named operation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:reduce(col, op)  -- -> number
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:filterMask ------------------------------------------
--@api-stub: LVecFrame:filterMask
-- Builds a boolean mask for a numeric column comparison.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:filterMask(col, cmp_op, val)  -- -> table
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:applyMask -------------------------------------------
--@api-stub: LVecFrame:applyMask
-- Returns a vectorized frame filtered by a boolean mask table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:applyMask(mask_tbl)  -- -> LVecFrame
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colType ---------------------------------------------
--@api-stub: LVecFrame:colType
-- Returns the data type name for a vectorized column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colType(col)  -- -> LuaValue
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:colCast ---------------------------------------------
--@api-stub: LVecFrame:colCast
-- Casts a vectorized column to another data type in place.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:colCast(col, dtype)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:nrows -----------------------------------------------
--@api-stub: LVecFrame:nrows
-- Returns the number of rows in this vectorized frame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:nrows()  -- -> integer
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:ncols -----------------------------------------------
--@api-stub: LVecFrame:ncols
-- Returns the number of columns in this vectorized frame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:ncols()  -- -> integer
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:columns ---------------------------------------------
--@api-stub: LVecFrame:columns
-- Returns all vectorized column names in order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:columns()  -- -> table
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:parReduce -------------------------------------------
--@api-stub: LVecFrame:parReduce
-- Reduces multiple numeric columns in parallel.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:parReduce(cols_tbl, op)  -- -> table
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:parScalarOp -----------------------------------------
--@api-stub: LVecFrame:parScalarOp
-- Applies a scalar operation to multiple numeric columns in parallel.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:parScalarOp(cols_tbl, op, val)
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:toDataFrame -----------------------------------------
--@api-stub: LVecFrame:toDataFrame
-- Converts this vectorized frame to a dataframe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:toDataFrame()  -- -> LDataFrame
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:type ------------------------------------------------
--@api-stub: LVecFrame:type
-- Returns the Lua-visible type name for this vectorized frame handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:type()  -- -> string
-- (replace lVecFrame_stub with your real LVecFrame instance above)

-- ---- Stub: LVecFrame:typeOf ----------------------------------------------
--@api-stub: LVecFrame:typeOf
-- Returns whether this vectorized frame handle matches a supported type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lVecFrame_stub:typeOf("hero")  -- -> boolean
-- (replace lVecFrame_stub with your real LVecFrame instance above)
