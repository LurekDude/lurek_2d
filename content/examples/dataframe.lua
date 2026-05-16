-- content/examples/dataframe.lua
-- lurek.dataframe API examples.
-- Run: cargo run -- content/examples/dataframe.lua

--@api-stub: lurek.dataframe.newDataFrame
-- Creates an empty dataframe
do
  local stats = lurek.dataframe.newDataFrame()
  stats:addColumn("name", "")
  stats:addColumn("score", 0)
  stats:addRow({name = "Alice", score = 1200})
end

--@api-stub: lurek.dataframe.newDatabase
-- Creates an empty dataframe database
do
  local db = lurek.dataframe.newDatabase()
  local players = lurek.dataframe.fromTable({{id = 1, name = "Alice"}})
  db:addTable("players", players)
  lurek.log.info("tables: " .. db:tableCount())
end

--@api-stub: lurek.dataframe.fromTable
-- Creates a dataframe from an array table of row tables
do
  local rows = {
    {name = "goblin", hp = 30, level = 2},
    {name = "orc",    hp = 60, level = 5},
  }
  local enemies = lurek.dataframe.fromTable(rows)
  lurek.log.info("loaded " .. enemies:nrows() .. " enemies")
end

--@api-stub: lurek.dataframe.fromRows
-- Creates a dataframe from column names and array-style rows
do
  local columns = {"id", "name", "score"}
  local rows = {
    {1, "Alice", 1200},
    {2, "Bob", 980},
  }
  local scores = lurek.dataframe.fromRows(columns, rows)
  lurek.log.info("player #2: " .. scores:getValue(2, "name"))
end

--@api-stub: lurek.dataframe.fromCSV
-- Parses a dataframe from CSV text
do
  local csv = "weapon,damage,cost\nsword,12,50\nbow,8,40\n"
  local items = lurek.dataframe.fromCSV(csv)
  lurek.log.info("avg damage = " .. items:mean("damage"))
end

--@api-stub: lurek.dataframe.fromJSON
-- Parses a dataframe from JSON text
do
  local json = '[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]'
  local players = lurek.dataframe.fromJSON(json)
  lurek.log.info("rows: " .. players:nrows())
end

--@api-stub: lurek.dataframe.fromBinary
-- Parses a dataframe from binary data
do
  local original = lurek.dataframe.fromTable({{x = 1}, {x = 2}})
  local blob = original:toBinary()
  local restored = lurek.dataframe.fromBinary(blob)
  lurek.log.info("restored " .. restored:nrows() .. " rows")
end

--@api-stub: lurek.dataframe.random
-- Creates a random dataframe from column definitions
do
  local defs = {{"id", "id"}, {"hp", "int"}, {"name", "name"}}
  local mob_pool = lurek.dataframe.random(defs, 100, 42)
  lurek.log.info("generated " .. mob_pool:nrows() .. " mobs")
end

-- DataFrame methods

--@api-stub: DataFrame:nrows
-- Performs the nrows operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{name = "Alice"}, {name = "Bob"}})
  if df:nrows() > 0 then
    lurek.log.info("first player: " .. df:getValue(1, "name"))
  end
end

--@api-stub: DataFrame:ncols
-- Performs the ncols operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{x = 1, y = 2, z = 3}})
  for i = 1, df:ncols() do
    lurek.log.info("column " .. i .. " = " .. df:columns()[i])
  end
end

--@api-stub: DataFrame:columns
-- Performs the columns operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{hp = 100, mp = 50}})
  local headers = df:columns()
  for _, name in ipairs(headers) do
    lurek.log.info("col: " .. name)
  end
end

--@api-stub: DataFrame:count
-- Returns the total count of items held by this data frame.
do
  local df = lurek.dataframe.fromTable({{kill = 1}, {kill = 1}, {kill = 1}})
  local kills = df:count()
  lurek.log.info("session kills: " .. kills)
end

--@api-stub: DataFrame:removeColumn
-- Removes a column from this data frame.
do
  local df = lurek.dataframe.fromTable({{name = "Alice", password = "x", score = 9}})
  df:removeColumn("password")
  lurek.log.info(df:toCSV())
end

--@api-stub: DataFrame:rename
-- Performs the rename operation on this data frame.
do
  local df = lurek.dataframe.fromCSV("Player Name,Score\nAlice,1200\n")
  df:rename("Player Name", "name")
  lurek.log.info("first column is now " .. df:columns()[1])
end

--@api-stub: DataFrame:getColumn
-- Returns the column of this data frame.
do
  local df = lurek.dataframe.fromTable({{x = 1}, {x = 2}, {x = 3}})
  local xs = df:getColumn("x")
  lurek.log.info("first x = " .. xs[1] .. ", last x = " .. xs[#xs])
end

--@api-stub: DataFrame:addRow
-- Adds a row to this data frame.
do
  local log_df = lurek.dataframe.newDataFrame()
  log_df:addColumn("event", "")
  log_df:addColumn("t", 0)
  local row = log_df:addRow({event = "spawn", t = 1.25})
  lurek.log.info("logged at row " .. row)
end

--@api-stub: DataFrame:removeRow
-- Removes a row from this data frame.
do
  local df = lurek.dataframe.fromTable({{name = "Alice"}, {name = "Bob"}, {name = "Cara"}})
  df:removeRow(2)
  lurek.log.info("rows left: " .. df:nrows())
end

--@api-stub: DataFrame:getRow
-- Returns the row of this data frame.
do
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80}})
  local row = df:getRow(1)
  lurek.log.info(row.name .. " has " .. row.hp .. " hp")
end

--@api-stub: DataFrame:getValue
-- Returns the value of this data frame.
do
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80}})
  local hp = df:getValue(1, "hp")
  if hp < 30 then lurek.log.warn("low hp: " .. hp) end
end

--@api-stub: DataFrame:head
-- Performs the head operation on this data frame.
do
  local df = lurek.dataframe.random({{"id", "id"}, {"score", "int"}}, 100, 1)
  local top = df:head(3)
  lurek.log.info("preview:\n" .. top:toString())
end

--@api-stub: DataFrame:tail
-- Performs the tail operation on this data frame.
do
  local df = lurek.dataframe.random({{"t", "int"}, {"event", "name"}}, 50, 7)
  local recent = df:tail(5)
  lurek.log.info("last 5:\n" .. recent:toString())
end

--@api-stub: DataFrame:slice
-- Performs the slice operation on this data frame.
do
  local df = lurek.dataframe.random({{"id", "id"}, {"score", "int"}}, 100, 2)
  local page = df:slice(11, 20)
  lurek.log.info("page rows: " .. page:nrows())
end

--@api-stub: DataFrame:select
-- Performs the select operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80, mp = 30, x = 0, y = 0}})
  local hud_view = df:select("name", "hp", "mp")
  lurek.log.info(hud_view:toString())
end

--@api-stub: DataFrame:unique
-- Performs the unique operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{type = "goblin"}, {type = "orc"}, {type = "goblin"}})
  local kinds = df:unique("type")
  lurek.log.info("distinct types: " .. #kinds)
end

--@api-stub: DataFrame:groupBy
-- Performs the group by operation on this data frame.
do
  local df = lurek.dataframe.fromTable({
    {team = "red", score = 10}, {team = "blue", score = 7}, {team = "red", score = 5},
  })
  local groups = df:groupBy("team")
  lurek.log.info("red rows: " .. groups["red"]:nrows())
end

--@api-stub: DataFrame:merge
-- Performs the merge operation on this data frame.
do
  local a = lurek.dataframe.fromTable({{id = 1}, {id = 2}})
  local b = lurek.dataframe.fromTable({{id = 3}, {id = 4}})
  a:merge(b)
  lurek.log.info("merged rows: " .. a:nrows())
end

--@api-stub: DataFrame:countBy
-- Performs the count by operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{weapon = "sword"}, {weapon = "bow"}, {weapon = "sword"}})
  local counts = df:countBy("weapon")
  lurek.log.info(counts:toString())
end

--@api-stub: DataFrame:dropNil
-- Performs the drop nil operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{x = 1}, {x = nil}, {x = 3}})
  local clean = df:dropNil("x")
  lurek.log.info("clean rows: " .. clean:nrows())
end

--@api-stub: DataFrame:sample
-- Performs the sample operation on this data frame.
do
  local df = lurek.dataframe.random({{"id", "id"}, {"score", "int"}}, 1000, 9)
  local subset = df:sample(50, 123)
  lurek.log.info("sampled " .. subset:nrows() .. " rows")
end

--@api-stub: DataFrame:describe
-- Performs the describe operation on this data frame.
do
  local df = lurek.dataframe.random({{"hp", "int"}, {"mp", "int"}}, 200, 11)
  local summary = df:describe()
  lurek.log.info(summary:toString())
end

--@api-stub: DataFrame:sum
-- Performs the sum operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{dmg = 12}, {dmg = 20}, {dmg = 8}})
  local total = df:sum("dmg")
  lurek.log.info("total damage: " .. total)
end

--@api-stub: DataFrame:mean
-- Performs the mean operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{dps = 50}, {dps = 70}, {dps = 60}})
  local avg = df:mean("dps")
  lurek.log.info("avg dps: " .. avg)
end

--@api-stub: DataFrame:min
-- Performs the min operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{ms = 16}, {ms = 33}, {ms = 14}})
  local fastest = df:min("ms")
  lurek.log.info("best frame ms: " .. fastest)
end

--@api-stub: DataFrame:max
-- Performs the max operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{score = 1200}, {score = 4500}, {score = 800}})
  local best = df:max("score")
  lurek.log.info("high score: " .. best)
end

--@api-stub: DataFrame:median
-- Performs the median operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{ms = 16}, {ms = 17}, {ms = 18}, {ms = 200}})
  local typical = df:median("ms")
  lurek.log.info("typical ms: " .. typical)
end

--@api-stub: DataFrame:stddev
-- Performs the stddev operation on this data frame.
do
  local df = lurek.dataframe.random({{"ms", "int"}}, 60, 3)
  local s = df:stddev("ms")
  lurek.log.info("ms stddev: " .. s)
end

--@api-stub: DataFrame:variance
-- Performs the variance operation on this data frame.
do
  local df = lurek.dataframe.random({{"dmg", "int"}}, 100, 4)
  local v = df:variance("dmg")
  lurek.log.info("dmg variance: " .. v)
end

--@api-stub: DataFrame:fillNil
-- Performs the fill nil operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{score = 10}, {score = nil}, {score = 5}})
  df:fillNil("score", 0)
  lurek.log.info("sum after fill: " .. df:sum("score"))
end

--@api-stub: DataFrame:toCSV
-- Performs the to csv operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{name = "Alice", score = 1200}})
  local csv = df:toCSV()
  if lurek.fs then lurek.fs.write("save/scores.csv", csv) end
end

--@api-stub: DataFrame:toJSON
-- Performs the to json operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{id = 1, name = "Alice"}})
  local json = df:toJSON()
  if lurek.fs then lurek.fs.write("save/players.json", json) end
end

--@api-stub: DataFrame:toBinary
-- Performs the to binary operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{id = 1}, {id = 2}})
  local blob = df:toBinary()
  if lurek.fs then lurek.fs.write("save/state.lvdf", blob) end
end

--@api-stub: DataFrame:toTable
-- Performs the to table operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80}})
  local rows = df:toTable()
  for _, row in ipairs(rows) do
    lurek.log.info(row.name .. ": " .. row.hp)
  end
end

--@api-stub: DataFrame:rows
-- Performs the rows operation on this data frame.
do
  local df = lurek.dataframe.fromTable({
    {name = "Alice", hp = 80},
    {name = "Bob", hp = 50},
  })
  for i, row in df:rows() do
    lurek.log.info("#" .. i .. " " .. row.name .. " hp=" .. row.hp)
  end
end

--@api-stub: DataFrame:toString
-- Performs the to string operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80}, {name = "Bob", hp = 50}})
  lurek.log.info("party:\n" .. df:toString())
end

--@api-stub: DataFrame:query
-- Performs the query operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{name = "Alice", hp = 80}, {name = "Bob", hp = 20}})
  local hurt = df:query("SELECT name FROM t WHERE hp < 50")
  lurek.log.info("hurt rows: " .. hurt:nrows())
end

--@api-stub: DataFrame:clone
-- Performs the clone operation on this data frame.
do
  local original = lurek.dataframe.fromTable({{x = 1}, {x = 2}})
  local working = original:clone()
  working:addRow({x = 3})
  lurek.log.info("orig=" .. original:nrows() .. " copy=" .. working:nrows())
end

--@api-stub: DataFrame:correlationMatrix
-- Performs the correlation matrix operation on this data frame.
do
  local df = lurek.dataframe.random({{"dmg", "int"}, {"cost", "int"}}, 50, 5)
  local matrix = df:correlationMatrix()
  lurek.log.info("correlation:\n" .. matrix:toString())
end

--@api-stub: DataFrame:modeVal
-- Performs the mode val operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{w = "sword"}, {w = "bow"}, {w = "sword"}})
  local favourite = df:modeVal("w")
  lurek.log.info("most-picked: " .. tostring(favourite))
end

--@api-stub: DataFrame:entropy
-- Performs the entropy operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{class = "warrior"}, {class = "mage"}, {class = "warrior"}})
  local h = df:entropy("class")
  lurek.log.info("class entropy bits: " .. h)
end

--@api-stub: DataFrame:addRowBatch
-- Adds a row batch to this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addColumn("x", 0)
  df:addColumn("y", 0)
  df:addRowBatch({{1, 2}, {3, 4}, {5, 6}})
  lurek.log.info("rows now: " .. df:nrows())
end

--@api-stub: DataFrame:getColumnAsF64
-- Returns the column as f64 of this data frame.
do
  local df = lurek.dataframe.random({{"hp", "int"}}, 16, 6)
  local nums = df:getColumnAsF64("hp")
  lurek.log.info("first hp = " .. nums[1])
end

--@api-stub: DataFrame:setColumnFromF64
-- Sets the column from f64 of this data frame.
do
  local df = lurek.dataframe.fromTable({{x = 0}, {x = 0}, {x = 0}})
  df:setColumnFromF64("x", {1.5, 2.5, 3.5})
  lurek.log.info("sum x = " .. df:sum("x"))
end

--@api-stub: DataFrame:type
-- Returns the Lua-visible type name string for this data frame handle.
do
  local df = lurek.dataframe.newDataFrame()
  if df:type() == "DataFrame" then
    lurek.log.info("got a frame, columns=" .. df:ncols())
  end
end

--@api-stub: DataFrame:typeOf
-- Returns true if this data frame handle matches the given type name string.
do
  local df = lurek.dataframe.newDataFrame()
  if df:typeOf("Object") then
    lurek.log.info("DataFrame is an Object")
  end
end

--@api-stub: DataFrame:withEval
-- Performs the with eval operation on this data frame.
do
  local df = lurek.dataframe.fromTable({{atk = 10, bonus = 4}, {atk = 8, bonus = 2}})
  local boosted = df:withEval("total", "atk + bonus * 1.5")
  lurek.log.info("max total: " .. boosted:max("total"))
end

-- Database methods

--@api-stub: Database:getTable
-- Returns the table of this database.
do
  local db = lurek.dataframe.newDatabase()
  db:addTable("players", lurek.dataframe.fromTable({{name = "Alice"}}))
  local players = db:getTable("players")
  if players then
    lurek.log.info("players rows: " .. players:nrows())
  end
end

--@api-stub: Database:removeTable
-- Removes a table from this database.
do
  local db = lurek.dataframe.newDatabase()
  db:addTable("temp", lurek.dataframe.newDataFrame())
  db:removeTable("temp")
  lurek.log.info("table count: " .. db:tableCount())
end

--@api-stub: Database:hasTable
-- Returns true if this database has a table.
do
  local db = lurek.dataframe.newDatabase()
  if not db:hasTable("scores") then
    db:addTable("scores", lurek.dataframe.newDataFrame())
  end
end

--@api-stub: Database:listTables
-- Performs the list tables operation on this database.
do
  local db = lurek.dataframe.newDatabase()
  db:addTable("a", lurek.dataframe.newDataFrame())
  db:addTable("b", lurek.dataframe.newDataFrame())
  for _, name in ipairs(db:listTables()) do
    lurek.log.info("table: " .. name)
  end
end

--@api-stub: Database:tableCount
-- Performs the table count operation on this database.
do
  local db = lurek.dataframe.newDatabase()
  db:addTable("scores", lurek.dataframe.newDataFrame())
  if db:tableCount() > 0 then
    lurek.log.info("database populated")
  end
end

--@api-stub: Database:clear
-- Clears all items from this database.
do
  local db = lurek.dataframe.newDatabase()
  db:addTable("round", lurek.dataframe.newDataFrame())
  db:clear()
  lurek.log.info("cleared, count=" .. db:tableCount())
end

--@api-stub: Database:merge
-- Performs the merge operation on this database.
do
  local base = lurek.dataframe.newDatabase()
  local mod = lurek.dataframe.newDatabase()
  mod:addTable("extra_items", lurek.dataframe.fromTable({{id = "amulet"}}))
  base:merge(mod)
  lurek.log.info("after merge: " .. base:tableCount() .. " tables")
end

--@api-stub: Database:toJSON
-- Performs the to json operation on this database.
do
  local db = lurek.dataframe.newDatabase()
  db:addTable("players", lurek.dataframe.fromTable({{name = "Alice"}}))
  if lurek.fs then lurek.fs.write("save/world.json", db:toJSON()) end
end

--@api-stub: Database:query
-- Performs the query operation on this database.
do
  pcall(function()
    local db = lurek.dataframe.newDatabase()
    db:addTable("players", lurek.dataframe.fromTable({{id = 1, name = "Alice"}}))
    db:addTable("scores",  lurek.dataframe.fromTable({{pid = 1, pts = 9000}}))
    local joined = db:query("SELECT players.name, scores.pts FROM players, scores WHERE players.id = scores.pid")
    lurek.log.info("joined rows: " .. joined:nrows())
  end)
end

--@api-stub: Database:type
-- Returns the Lua-visible type name string for this database handle.
do
  local db = lurek.dataframe.newDatabase()
  if db:type() == "Database" then
    lurek.log.info("got a database, tables=" .. db:tableCount())
  end
end

--@api-stub: Database:typeOf
-- Returns true if this database handle matches the given type name string.
do
  local db = lurek.dataframe.newDatabase()
  if db:typeOf("Object") then
    lurek.log.info("Database is an Object")
  end
end

--@api-stub: GroupedFrame:aggregate
-- Performs the aggregate operation on this grouped frame.
do
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
-- Performs the group by obj operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addColumn("score", 0) ; df:addColumn("key", "")
  df:addRow({score=1, key="a"}) ; df:addRow({score=2, key="b"}) ; df:addRow({score=3, key="a"})
  if df.groupByObj then
    local grouped = df:groupByObj("key")
    lurek.log.debug("groupByObj returned: " .. tostring(grouped), "dataframe")
  end
end

-- VecFrame: vectorized columnar operations
--
-- VecFrame stores each column as a typed flat buffer (float64/int64/bool/text)
-- with an optional null-validity bitmap.  Operations run over the entire column
-- at once â€” no per-cell Lua dispatch â€” allowing the Rust compiler to apply
-- SIMD vectorization and rayon parallelism.
--
-- Workflow: DataFrame â†’ toVec() â†’ fast bulk ops â†’ toDataFrame() (or fromVec)

--@api-stub: lurek.dataframe.toVec
-- Converts a dataframe to a vectorized frame
do
  local df = lurek.dataframe.fromCSV("hp,mp\n100,50\n200,80\n150,60\n")
  local vf = lurek.dataframe.toVec(df)
  lurek.log.info("VecFrame: " .. vf:nrows() .. " rows, " .. vf:ncols() .. " cols")
end

--@api-stub: lurek.dataframe.fromVec
-- Converts a vectorized frame to a dataframe
do
  local df = lurek.dataframe.fromCSV("hp,mp\n100,50\n200,80\n")
  local vf = lurek.dataframe.toVec(df)
  vf:colMul("hp", 0.5)          -- halve all HP values at once
  local df2 = lurek.dataframe.fromVec(vf)
  lurek.log.info("first HP after halving: " .. tostring(df2:getValue(1, "hp")))
end

--@api-stub: VecFrame:colAdd
-- Performs the col add operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("score\n10\n20\n30\n"))
  vf:colAdd("score", 5)    -- score becomes 15, 25, 35
  local df = vf:toDataFrame()
  lurek.log.info("score[0] = " .. tostring(df:getValue(1, "score")))
end

--@api-stub: VecFrame:colMul
-- Performs the col mul operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("dmg\n10\n15\n20\n"))
  vf:colMul("dmg", 1.5)    -- apply 1.5x damage multiplier to all rows
end

--@api-stub: VecFrame:colClamp
-- Performs the col clamp operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n-5\n50\n150\n"))
  vf:colClamp("hp", 0, 100)   -- HP in [0, 100]
  local df = vf:toDataFrame()
  lurek.log.info("hp[2] clamped to " .. tostring(df:getValue(2, "hp")))  -- 100
end

--@api-stub: VecFrame:colAbs
-- Performs the col abs operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("delta\n-3\n4\n-1\n"))
  vf:colAbs("delta")
  local df = vf:toDataFrame()
  lurek.log.info("abs delta[0] = " .. tostring(df:getValue(1, "delta")))
end

--@api-stub: VecFrame:colSqrt
-- Performs the col sqrt operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("dist_sq\n9\n16\n25\n"))
  vf:colSqrt("dist_sq")   -- dist_sq becomes 3, 4, 5
  local df = vf:toDataFrame()
  lurek.log.info("dist[0] = " .. tostring(df:getValue(1, "dist_sq")))
end

--@api-stub: VecFrame:colOp
-- Performs the col op operation on this vec frame.
do
  local df = lurek.dataframe.fromCSV("atk,def\n30,10\n40,15\n20,5\n")
  local vf = lurek.dataframe.toVec(df)
  vf:colOp("net_dmg", "atk", "sub", "def")   -- net_dmg = atk - def per row
  local df2 = vf:toDataFrame()
  lurek.log.info("net_dmg[0] = " .. tostring(df2:getValue(1, "net_dmg")))  -- 20
end

--@api-stub: VecFrame:reduce
-- Performs the reduce operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("score\n10\n20\n30\n"))
  local total = vf:reduce("score", "sum")
  local avg   = vf:reduce("score", "mean")
  lurek.log.info("sum=" .. total .. " mean=" .. avg)
end

--@api-stub: VecFrame:filterMask
-- Performs the filter mask operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n10\n50\n90\n"))
  local mask = vf:filterMask("hp", ">=", 50)  -- {false, true, true}
  lurek.log.info("rows with hp >= 50: " .. tostring(mask[2]) .. ", " .. tostring(mask[3]))
end

--@api-stub: VecFrame:applyMask
-- Applies mask to this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n10\n50\n90\n"))
  local mask = vf:filterMask("hp", ">=", 50)
  local alive = vf:applyMask(mask)   -- 2 rows
  lurek.log.info("alive rows: " .. alive:nrows())  -- 2
end

--@api-stub: VecFrame:colType
-- Performs the col type operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp\n10\n20\n"))
  local dtype = vf:colType("hp")
  lurek.log.info("hp dtype: " .. dtype)  -- "float64"
end

--@api-stub: VecFrame:parReduce
-- Performs the par reduce operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp,mp,atk\n10,5,8\n20,10,12\n"))
  local sums = vf:parReduce({"hp", "mp", "atk"}, "sum")
  for col, s in pairs(sums) do
    lurek.log.info(col .. " sum = " .. tostring(s))
  end
end
-- do  -- VecFrame:parScalarOp
--   local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("hp,mp\n100,50\n200,80\n"))
--   vf:parScalarOp({"hp", "mp"}, "mul", 0.5)   -- halve all stats at once
--   local df2 = vf:toDataFrame()
--   lurek.log.info("hp[0]=" .. df2:getValue(1,"hp") .. " mp[0]=" .. df2:getValue(1,"mp"))
-- end

--@api-stub: VecFrame:toDataFrame
-- Performs the to data frame operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("v\n1\n2\n3\n"))
  vf:colAdd("v", 10)
  local df2 = vf:toDataFrame()
  lurek.log.info("v[0] = " .. tostring(df2:getValue(1, "v")))  -- 11
end

--@api-stub: VecFrame:colSub
-- Performs the col sub operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("stamina\n100\n80\n60\n"))
  vf:colSub("stamina", 10)
  local df2 = vf:toDataFrame()
  lurek.log.info("stamina[0] after drain = " .. tostring(df2:getValue(1, "stamina")))  -- 90
end

--@api-stub: VecFrame:colDiv
-- Performs the col div operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("score\n100\n200\n150\n"))
  vf:colDiv("score", 200)
  local df2 = vf:toDataFrame()
  lurek.log.info("normalised score[1] = " .. tostring(df2:getValue(1, "score")))  -- 1.0
end

--@api-stub: VecFrame:colFloor
-- Performs the col floor operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x\n1.9\n2.1\n3.7\n"))
  vf:colFloor("x")
  local df2 = vf:toDataFrame()
  lurek.log.info("floored x[2] = " .. tostring(df2:getValue(2, "x")))  -- 3
end

--@api-stub: VecFrame:colCeil
-- Performs the col ceil operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("y\n1.1\n2.5\n3.0\n"))
  vf:colCeil("y")
  local df2 = vf:toDataFrame()
  lurek.log.info("ceiled y[0] = " .. tostring(df2:getValue(1, "y")))  -- 2
end

--@api-stub: VecFrame:colNeg
-- Performs the col neg operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("vy\n3\n-2\n0\n"))
  vf:colNeg("vy")
  local df2 = vf:toDataFrame()
  lurek.log.info("negated vy[0] = " .. tostring(df2:getValue(1, "vy")))  -- -3
end

--@api-stub: VecFrame:colCast
-- Performs the col cast operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("level\n1\n2\n3\n"))
  vf:colCast("level", "float64")
  lurek.log.info("level dtype after cast: " .. vf:colType("level"))  -- "float64"
  local df2 = vf:toDataFrame()
  lurek.log.info("level[0] as float = " .. tostring(df2:getValue(1, "level")))
end

--@api-stub: VecFrame:nrows
-- Performs the nrows operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("v\n10\n20\n30\n"))
  lurek.log.info("VecFrame rows: " .. vf:nrows())  -- 3
  local df2 = vf:toDataFrame()
  assert(vf:nrows() == df2:nrows())
end

--@api-stub: VecFrame:ncols
-- Performs the ncols operation on this vec frame.
do
  local df = lurek.dataframe.fromCSV("hp,mp,atk\n10,5,8\n")
  local vf = lurek.dataframe.toVec(df)
  lurek.log.info("VecFrame cols: " .. vf:ncols())  -- 3
  assert(vf:ncols() == df:ncols())
end

--@api-stub: VecFrame:columns
-- Performs the columns operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("a,b,c\n1,2,3\n"))
  local cols = vf:columns()
  for i, name in ipairs(cols) do
    lurek.log.info("col " .. i .. ": " .. name)
  end
end

--@api-stub: VecFrame:type
-- Returns the Lua-visible type name string for this vec frame handle.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x\n1\n"))
  if vf:type() == "VecFrame" then
    lurek.log.info("got a VecFrame, rows=" .. vf:nrows())
  end
end

--@api-stub: VecFrame:typeOf
-- Returns true if this vec frame handle matches the given type name string.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x\n1\n"))
  if vf:typeOf("Object") then
    lurek.log.info("VecFrame is an Object")
  end
end

--@api-stub: DataFrame:addColumn
-- Adds a column to this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({name="Alice", score=85})
  df:addColumn("grade", {"A"})
  lurek.log.info("cols: " .. df:ncols(), "dataframe")
end

--@api-stub: Database:addTable
-- Adds a table to this database.
do
  local db = lurek.dataframe.newDatabase()
  local df = lurek.dataframe.newDataFrame()
  df:addRow({id=1, name="Alice"})
  db:addTable("users", df)
  lurek.log.info("tables: " .. db:tableCount(), "dataframe")
end

--@api-stub: DataFrame:apply
-- Applies  to this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({score=60})
  df:addRow({score=80})
  df:apply("score", function(v) return v >= 70 and "pass" or "fail" end)
  lurek.log.info("grade col added", "dataframe")
end

--@api-stub: DataFrame:corr
-- Performs the corr operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({x=1, y=2})
  df:addRow({x=3, y=4})
  df:addRow({x=5, y=6})
  local r = df:corr("x", "y")
  lurek.log.info("correlation: " .. r, "dataframe")
end

--@api-stub: DataFrame:filter
-- Performs the filter operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({age=20, name="Alice"})
  df:addRow({age=35, name="Bob"})
  local adults = df:filter("age", ">=", 21)
  lurek.log.info("adults: " .. adults:nrows(), "dataframe")
end

--@api-stub: DataFrame:groupAgg
-- Performs the group agg operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({team="A", score=10})
  df:addRow({team="A", score=20})
  df:addRow({team="B", score=30})
  local out = df:groupAgg("team", "score", "sum")
  lurek.log.info("group agg rows: " .. out:nrows(), "dataframe")
end

--@api-stub: DataFrame:join
-- Blocks until this data frame finishes its current operation.
do
  local left  = lurek.dataframe.newDataFrame()
  local right = lurek.dataframe.newDataFrame()
  left:addRow({id=1, name="Alice"})
  right:addRow({id=1, dept="Eng"})
  local merged = left:join(right, "id", "id", "inner")
  lurek.log.info("joined rows: " .. merged:nrows(), "dataframe")
end

--@api-stub: DataFrame:normalizeCol
-- Performs the normalize col operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({val=10}) ; df:addRow({val=50}) ; df:addRow({val=90})
  df:normalizeCol("val", 0.0, 1.0, "val_norm")
  lurek.log.info("normalized col", "dataframe")
end

--@api-stub: DataFrame:outliers
-- Performs the outliers operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  for i=1,10 do df:addRow({v=i}) end
  df:addRow({v=1000})
  local out = df:outliers("v", 2.0)
  lurek.log.info("outliers: " .. out:nrows(), "dataframe")
end

--@api-stub: VecFrame:parScalarOp
-- Performs the par scalar op operation on this vec frame.
do
  local vf = lurek.dataframe.toVec(lurek.dataframe.fromCSV("x,y\n1.0,4.0\n2.0,5.0\n3.0,6.0\n"))
  local scaled = vf:parScalarOp({"x", "y"}, "mul", 2.0)
  lurek.log.info("par scalar done", "dataframe")
end

--@api-stub: DataFrame:pivot
-- Performs the pivot operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({name="Alice", month="Jan", val=100})
  df:addRow({name="Alice", month="Feb", val=120})
  local p = df:pivot("name", "month", "val")
  lurek.log.info("pivot cols: " .. p:ncols(), "dataframe")
end

--@api-stub: DataFrame:pivotTable
-- Performs the pivot table operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({region="N", product="A", sales=50})
  df:addRow({region="N", product="B", sales=70})
  local pt = df:pivotTable("region", "product", "sales", "sum")
  lurek.log.info("pivot table rows: " .. pt:nrows(), "dataframe")
end

--@api-stub: DataFrame:rank
-- Performs the rank operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({score=80}) ; df:addRow({score=95}) ; df:addRow({score=72})
  local ranked = df:rank("score")
  lurek.log.info("rank col added", "dataframe")
end

--@api-stub: DataFrame:rollingMean
-- Performs the rolling mean operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  for i=1,5 do df:addRow({v=i*2}) end
  local out = df:rollingMean("v", 3)
  lurek.log.info("rolling mean rows: " .. out:nrows(), "dataframe")
end

--@api-stub: DataFrame:rollingSum
-- Performs the rolling sum operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  for i=1,5 do df:addRow({v=i}) end
  local out = df:rollingSum("v", 3)
  lurek.log.info("rolling sum rows: " .. out:nrows(), "dataframe")
end

--@api-stub: DataFrame:setValue
-- Sets the value of this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({score=50, name="Alice"})
  df:setValue(1, "score", 90)
  lurek.log.info("updated score: " .. df:getValue(1, "score"), "dataframe")
end

--@api-stub: DataFrame:sort
-- Sorts the items in this data frame according to their sort key.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({score=80}) ; df:addRow({score=60}) ; df:addRow({score=95})
  df:sort("score", true)
  lurek.log.info("sorted first: " .. df:getValue(1, "score"), "dataframe")
end

--@api-stub: DataFrame:withCumsum
-- Performs the with cumsum operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  for i=1,4 do df:addRow({v=i}) end
  local out = df:withCumsum("v", "v_cumsum")
  lurek.log.info("cumsum col added", "dataframe")
end

--@api-stub: DataFrame:withPctChange
-- Performs the with pct change operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  for _, v in ipairs({100,110,121,133}) do df:addRow({price=v}) end
  local out = df:withPctChange("price", "price_pct")
  lurek.log.info("pct change col added", "dataframe")
end

--@api-stub: DataFrame:withRank
-- Performs the with rank operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  df:addRow({pts=10}) ; df:addRow({pts=30}) ; df:addRow({pts=20})
  local out = df:withRank("pts", true, "pts_rank")
  lurek.log.info("rank col added", "dataframe")
end

--@api-stub: DataFrame:withRollingMax
-- Performs the with rolling max operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  for _, v in ipairs({3,1,4,1,5,9,2,6}) do df:addRow({v=v}) end
  local out = df:withRollingMax("v", 3, "v_rollmax")
  lurek.log.info("rolling max col added", "dataframe")
end

--@api-stub: DataFrame:withRollingMean
-- Performs the with rolling mean operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  for i=1,5 do df:addRow({temp=20+i}) end
  local out = df:withRollingMean("temp", 3, "temp_rollmean")
  lurek.log.info("rolling mean col added", "dataframe")
end

--@api-stub: DataFrame:withRollingMin
-- Performs the with rolling min operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  for _, v in ipairs({5,3,8,2,7,1}) do df:addRow({v=v}) end
  local out = df:withRollingMin("v", 3, "v_rollmin")
  lurek.log.info("rolling min col added", "dataframe")
end

--@api-stub: DataFrame:withRollingSum
-- Performs the with rolling sum operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  for i=1,5 do df:addRow({sales=i*10}) end
  local out = df:withRollingSum("sales", 3, "sales_rollsum")
  lurek.log.info("rolling sum col added", "dataframe")
end

--@api-stub: DataFrame:zscoreCol
-- Performs the zscore col operation on this data frame.
do
  local df = lurek.dataframe.newDataFrame()
  for i=1,6 do df:addRow({v=i*5}) end
  df:zscoreCol("v", "v_zscore")
  lurek.log.info("zscore normalised", "dataframe")
end

-- -----------------------------------------------------------------------------
-- LGroupedFrame methods
-- -----------------------------------------------------------------------------

--@api-stub: LDataFrame:lazy
-- Starts a lazy query pipeline from this dataframe
do
  local df = lurek.dataframe.fromTable({
    {name = "alice", hp = 12, team = "red"},
    {name = "bob", hp = 7, team = "blue"},
    {name = "cara", hp = 20, team = "red"},
  })
  local q = df:lazy()
  local t = q:type()
  lurek.log.info("lazy type: " .. tostring(t), "dataframe")
end

--@api-stub: LLazyQuery
-- Performs the l lazy query operation on this .
do
  local df = lurek.dataframe.fromTable({
    {name = "alice", hp = 12, mana = 5, team = "red"},
    {name = "bob", hp = 7, mana = nil, team = "blue"},
    {name = "cara", hp = 20, mana = 9, team = "red"},
    {name = "dave", hp = 15, mana = 3, team = "blue"},
  })

  local q = df:lazy()
  local is_lazy = q:typeOf("LLazyQuery")
  lurek.log.info("is lazy query: " .. tostring(is_lazy), "dataframe")

  local filtered = df:lazy():filter("hp", ">", 10):collect()
  local sorted = df:lazy():sort("hp", false):head(2):collect()
  local tailed = df:lazy():tail(2):collect()
  local limited = df:lazy():limit(3):collect()
  local sliced = df:lazy():slice(2, 4):collect()
  local non_nil = df:lazy():dropNil("mana"):collect()
  local selected = df:lazy():select({"name", "hp"}):collect()

  lurek.log.info("filtered rows: " .. filtered:nrows(), "dataframe")
  lurek.log.info("sorted rows: " .. sorted:nrows(), "dataframe")
  lurek.log.info("tailed rows: " .. tailed:nrows(), "dataframe")
  lurek.log.info("limited rows: " .. limited:nrows(), "dataframe")
  lurek.log.info("sliced rows: " .. sliced:nrows(), "dataframe")
  lurek.log.info("non-nil rows: " .. non_nil:nrows(), "dataframe")
  lurek.log.info("selected cols: " .. selected:ncols(), "dataframe")
end
