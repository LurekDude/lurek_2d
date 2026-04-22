-- content/examples/dataframe.lua
-- Practical usage examples for the lurek.dataframe API (64 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.dataframe.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/dataframe.lua

print("[example] lurek.dataframe — 64 API entries")

-- ── lurek.dataframe.* free functions ──

--@api-stub: lurek.dataframe.newDataFrame
-- Creates a new empty DataFrame.
-- Call when you need to create a new data frame.
local ok, obj = pcall(function() return lurek.dataframe.newDataFrame() end)
if ok and obj then print("created:", obj) end
print("lurek.dataframe.newDataFrame ok=", ok)

--@api-stub: lurek.dataframe.newDatabase
-- Creates a new empty Database.
-- Call when you need to create a new database.
local ok, obj = pcall(function() return lurek.dataframe.newDatabase() end)
if ok and obj then print("created:", obj) end
print("lurek.dataframe.newDatabase ok=", ok)

--@api-stub: lurek.dataframe.fromTable
-- Creates a DataFrame from an array of row tables.
-- Call when you need to invoke from table.
local ok, obj = pcall(function() return lurek.dataframe.fromTable(10) end)
if ok and obj then print("created:", obj) end
print("lurek.dataframe.fromTable ok=", ok)

--@api-stub: lurek.dataframe.fromCSV
-- Parses a CSV string into a DataFrame.
-- Call when you need to invoke from c s v.
local ok, obj = pcall(function() return lurek.dataframe.fromCSV(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.dataframe.fromCSV ok=", ok)

--@api-stub: lurek.dataframe.fromJSON
-- Parses a JSON string into a DataFrame.
-- Call when you need to invoke from j s o n.
local ok, obj = pcall(function() return lurek.dataframe.fromJSON(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.dataframe.fromJSON ok=", ok)

--@api-stub: lurek.dataframe.fromBinary
-- Deserializes a binary LVDF string into a DataFrame.
-- Call when you need to invoke from binary.
local ok, obj = pcall(function() return lurek.dataframe.fromBinary(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.dataframe.fromBinary ok=", ok)

--@api-stub: lurek.dataframe.random
-- Generates a DataFrame with random data from column definitions.
-- Call when you need to invoke random.
local ok, result = pcall(function() return lurek.dataframe.random(nil, 10, nil) end)
if ok then print("lurek.dataframe.random ->", result)
else print("unavailable:", result) end

-- ── DataFrame methods ──

--@api-stub: DataFrame:nrows
-- Returns the number of rows.
-- Call when you need to invoke nrows.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:nrows() end)
  print("DataFrame:nrows ->", ok, result)
end

--@api-stub: DataFrame:ncols
-- Returns the number of columns.
-- Call when you need to invoke ncols.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:ncols() end)
  print("DataFrame:ncols ->", ok, result)
end

--@api-stub: DataFrame:columns
-- Returns a table of column names.
-- Call when you need to invoke columns.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:columns() end)
  print("DataFrame:columns ->", ok, result)
end

--@api-stub: DataFrame:count
-- Returns the row count (alias for nrows).
-- Call when you need to invoke count.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:count() end)
  print("DataFrame:count ->", ok, result)
end

--@api-stub: DataFrame:removeColumn
-- Removes a column by name or index.
-- Call when you need to remove column.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:removeColumn(nil) end)
  print("DataFrame:removeColumn ->", ok, result)
end

--@api-stub: DataFrame:rename
-- Renames the column `old_name` to `new_name` in this DataFrame.
-- Call when you need to invoke rename.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:rename(nil, "new_name") end)
  print("DataFrame:rename ->", ok, result)
end

--@api-stub: DataFrame:getColumn
-- Returns all values in a column as a table.
-- Call when you need to read column.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:getColumn(nil) end)
  print("DataFrame:getColumn ->", ok, result)
end

--@api-stub: DataFrame:addRow
-- Adds a row from an optional table of name-value pairs, returns 1-based index.
-- Call when you need to add row.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:addRow(nil) end)
  print("DataFrame:addRow ->", ok, result)
end

--@api-stub: DataFrame:removeRow
-- Removes a row by 1-based index.
-- Call when you need to remove row.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:removeRow(nil) end)
  print("DataFrame:removeRow ->", ok, result)
end

--@api-stub: DataFrame:getRow
-- Returns a row as a table of name-value pairs.
-- Call when you need to read row.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:getRow(nil) end)
  print("DataFrame:getRow ->", ok, result)
end

--@api-stub: DataFrame:getValue
-- Returns a single cell value.
-- Call when you need to read value.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:getValue(nil, nil) end)
  print("DataFrame:getValue ->", ok, result)
end

--@api-stub: DataFrame:head
-- Returns the first n rows (default 5).
-- Call when you need to invoke head.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:head(10) end)
  print("DataFrame:head ->", ok, result)
end

--@api-stub: DataFrame:tail
-- Returns the last n rows (default 5).
-- Call when you need to invoke tail.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:tail(10) end)
  print("DataFrame:tail ->", ok, result)
end

--@api-stub: DataFrame:slice
-- Returns rows from start to end (1-based, inclusive).
-- Call when you need to invoke slice.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:slice(nil, nil) end)
  print("DataFrame:slice ->", ok, result)
end

--@api-stub: DataFrame:select
-- Selects a subset of columns, returns a new DataFrame.
-- Call when you need to invoke select.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:select(10) end)
  print("DataFrame:select ->", ok, result)
end

--@api-stub: DataFrame:unique
-- Returns unique values in a column as a table.
-- Call when you need to invoke unique.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:unique(nil) end)
  print("DataFrame:unique ->", ok, result)
end

--@api-stub: DataFrame:groupBy
-- Groups rows by column value, returns a table of DataFrames keyed by value.
-- Call when you need to invoke group by.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:groupBy(nil) end)
  print("DataFrame:groupBy ->", ok, result)
end

--@api-stub: DataFrame:merge
-- Appends rows from another DataFrame in-place.
-- Call when you need to invoke merge.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:merge(nil) end)
  print("DataFrame:merge ->", ok, result)
end

--@api-stub: DataFrame:countBy
-- Counts distinct values in a column, returns a DataFrame with value and count columns.
-- Call when you need to invoke count by.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:countBy(nil) end)
  print("DataFrame:countBy ->", ok, result)
end

--@api-stub: DataFrame:dropNil
-- Removes rows where the given column is nil, returns a new DataFrame.
-- Call when you need to invoke drop nil.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:dropNil(nil) end)
  print("DataFrame:dropNil ->", ok, result)
end

--@api-stub: DataFrame:sample
-- Returns a random sample of n rows.
-- Call when you need to invoke sample.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:sample(10, nil) end)
  print("DataFrame:sample ->", ok, result)
end

--@api-stub: DataFrame:describe
-- Returns descriptive statistics for all numeric columns.
-- Call when you need to invoke describe.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:describe() end)
  print("DataFrame:describe ->", ok, result)
end

--@api-stub: DataFrame:sum
-- Returns the sum of numeric values in a column.
-- Call when you need to invoke sum.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:sum(nil) end)
  print("DataFrame:sum ->", ok, result)
end

--@api-stub: DataFrame:mean
-- Returns the mean of numeric values in a column.
-- Call when you need to invoke mean.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:mean(nil) end)
  print("DataFrame:mean ->", ok, result)
end

--@api-stub: DataFrame:min
-- Returns the minimum numeric value in a column.
-- Call when you need to invoke min.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:min(nil) end)
  print("DataFrame:min ->", ok, result)
end

--@api-stub: DataFrame:max
-- Returns the maximum numeric value in a column.
-- Call when you need to invoke max.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:max(nil) end)
  print("DataFrame:max ->", ok, result)
end

--@api-stub: DataFrame:median
-- Returns the median of numeric values in a column.
-- Call when you need to invoke median.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:median(nil) end)
  print("DataFrame:median ->", ok, result)
end

--@api-stub: DataFrame:stddev
-- Returns the population standard deviation of numeric values in a column.
-- Call when you need to invoke stddev.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:stddev(nil) end)
  print("DataFrame:stddev ->", ok, result)
end

--@api-stub: DataFrame:variance
-- Returns the population variance of numeric values in a column.
-- Call when you need to invoke variance.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:variance(nil) end)
  print("DataFrame:variance ->", ok, result)
end

--@api-stub: DataFrame:fillNil
-- Replaces nil values in a column with the given value.
-- Call when you need to invoke fill nil.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:fillNil(nil, nil) end)
  print("DataFrame:fillNil ->", ok, result)
end

--@api-stub: DataFrame:toCSV
-- Serializes this DataFrame to a CSV string.
-- Call when you need to invoke to c s v.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:toCSV() end)
  print("DataFrame:toCSV ->", ok, result)
end

--@api-stub: DataFrame:toJSON
-- Serializes this DataFrame to a JSON string.
-- Call when you need to invoke to j s o n.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:toJSON() end)
  print("DataFrame:toJSON ->", ok, result)
end

--@api-stub: DataFrame:toBinary
-- Serializes this DataFrame to a binary LVDF string.
-- Call when you need to invoke to binary.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:toBinary() end)
  print("DataFrame:toBinary ->", ok, result)
end

--@api-stub: DataFrame:toTable
-- Converts this DataFrame to a Lua table of row tables.
-- Call when you need to invoke to table.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:toTable() end)
  print("DataFrame:toTable ->", ok, result)
end

--@api-stub: DataFrame:toString
-- Returns a formatted string table representation.
-- Call when you need to invoke to string.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:toString() end)
  print("DataFrame:toString ->", ok, result)
end

--@api-stub: DataFrame:query
-- Executes a SQL query against this DataFrame.
-- Call when you need to invoke query.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:query("sql_str value") end)
  print("DataFrame:query ->", ok, result)
end

--@api-stub: DataFrame:clone
-- Returns a deep copy of this DataFrame.
-- Call when you need to invoke clone.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:clone() end)
  print("DataFrame:clone ->", ok, result)
end

--@api-stub: DataFrame:correlationMatrix
-- Compute a correlation matrix for all numeric columns.
-- Call when you need to invoke correlation matrix.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:correlationMatrix() end)
  print("DataFrame:correlationMatrix ->", ok, result)
end

--@api-stub: DataFrame:modeVal
-- Return the most frequent value in a column (nil if empty).
-- Call when you need to invoke mode val.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:modeVal(nil) end)
  print("DataFrame:modeVal ->", ok, result)
end

--@api-stub: DataFrame:entropy
-- Shannon entropy (bits) of the value distribution in a column.
-- Call when you need to invoke entropy.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:entropy(nil) end)
  print("DataFrame:entropy ->", ok, result)
end

--@api-stub: DataFrame:addRowBatch
-- Add multiple rows at once from a table of row tables.
-- Call when you need to add row batch.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:addRowBatch(10) end)
  print("DataFrame:addRowBatch ->", ok, result)
end

--@api-stub: DataFrame:getColumnAsF64
-- Return a numeric column as a Lua array of numbers (nils → 0/nan).
-- Call when you need to read column as f64.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:getColumnAsF64(nil) end)
  print("DataFrame:getColumnAsF64 ->", ok, result)
end

--@api-stub: DataFrame:setColumnFromF64
-- Set a numeric column from a Lua array of numbers.
-- Call when you need to assign column from f64.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:setColumnFromF64(nil, nil) end)
  print("DataFrame:setColumnFromF64 ->", ok, result)
end

--@api-stub: DataFrame:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("DataFrame:type ->", ok, result)
end

--@api-stub: DataFrame:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("DataFrame:typeOf ->", ok, result)
end

--@api-stub: DataFrame:withEval
-- Returns a new DataFrame with an additional computed column named `col_name`.
-- Call when you need to invoke with eval.
-- Build a DataFrame via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDataFrame(...)
if instance then
  local ok, result = pcall(function() return instance:withEval("col_name", nil) end)
  print("DataFrame:withEval ->", ok, result)
end

-- ── Database methods ──

--@api-stub: Database:getTable
-- Returns a copy of a table by name, or nil if not found.
-- Call when you need to read table.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:getTable("name") end)
  print("Database:getTable ->", ok, result)
end

--@api-stub: Database:removeTable
-- Drops the named table from this in-memory database if it exists.
-- Call when you need to remove table.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:removeTable("name") end)
  print("Database:removeTable ->", ok, result)
end

--@api-stub: Database:hasTable
-- Returns true if a table with the given name exists.
-- Call when you need to check has table.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:hasTable("name") end)
  print("Database:hasTable ->", ok, result)
end

--@api-stub: Database:listTables
-- Returns a table of all table names.
-- Call when you need to invoke list tables.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:listTables() end)
  print("Database:listTables ->", ok, result)
end

--@api-stub: Database:tableCount
-- Returns the number of tables.
-- Call when you need to invoke table count.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:tableCount() end)
  print("Database:tableCount ->", ok, result)
end

--@api-stub: Database:clear
-- Drops every table from this in-memory database, leaving it empty.
-- Call when you need to invoke clear.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Database:clear ->", ok, result)
end

--@api-stub: Database:merge
-- Merges all tables from another Database into this one.
-- Call when you need to invoke merge.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:merge(nil) end)
  print("Database:merge ->", ok, result)
end

--@api-stub: Database:toJSON
-- Serializes all tables to a JSON object string.
-- Call when you need to invoke to j s o n.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:toJSON() end)
  print("Database:toJSON ->", ok, result)
end

--@api-stub: Database:query
-- Executes a SQL query against the database tables.
-- Call when you need to invoke query.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:query("sql_str value") end)
  print("Database:query ->", ok, result)
end

--@api-stub: Database:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Database:type ->", ok, result)
end

--@api-stub: Database:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a Database via the appropriate lurek.dataframe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.dataframe.newDatabase(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Database:typeOf ->", ok, result)
end

