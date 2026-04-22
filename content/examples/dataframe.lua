-- content/examples/dataframe.lua
-- Scaffolded coverage of the lurek.dataframe API (64 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/dataframe_api.rs   (Lua binding, arg types, return shape)
--   * src/dataframe/                 (semantics, side effects)
--   * docs/specs/dataframe.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/dataframe.lua

-- ── lurek.dataframe.* functions ──

--@api-stub: lurek.dataframe.newDataFrame
-- Creates a new empty DataFrame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: lurek.dataframe.newDataFrame
  local _todo = "TODO: write a real lurek.dataframe.newDataFrame usage example"
  print(_todo)
end

--@api-stub: lurek.dataframe.newDatabase
-- Creates a new empty Database.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: lurek.dataframe.newDatabase
  local _todo = "TODO: write a real lurek.dataframe.newDatabase usage example"
  print(_todo)
end

--@api-stub: lurek.dataframe.fromTable
-- Creates a DataFrame from an array of row tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: lurek.dataframe.fromTable
  local _todo = "TODO: write a real lurek.dataframe.fromTable usage example"
  print(_todo)
end

--@api-stub: lurek.dataframe.fromCSV
-- Parses a CSV string into a DataFrame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: lurek.dataframe.fromCSV
  local _todo = "TODO: write a real lurek.dataframe.fromCSV usage example"
  print(_todo)
end

--@api-stub: lurek.dataframe.fromJSON
-- Parses a JSON string into a DataFrame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: lurek.dataframe.fromJSON
  local _todo = "TODO: write a real lurek.dataframe.fromJSON usage example"
  print(_todo)
end

--@api-stub: lurek.dataframe.fromBinary
-- Deserializes a binary LVDF string into a DataFrame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: lurek.dataframe.fromBinary
  local _todo = "TODO: write a real lurek.dataframe.fromBinary usage example"
  print(_todo)
end

--@api-stub: lurek.dataframe.random
-- Generates a DataFrame with random data from column definitions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: lurek.dataframe.random
  local _todo = "TODO: write a real lurek.dataframe.random usage example"
  print(_todo)
end

-- ── DataFrame methods ──

--@api-stub: DataFrame:nrows
-- Returns the number of rows.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:nrows
  local _todo = "TODO: write a real DataFrame:nrows usage example"
  print(_todo)
end

--@api-stub: DataFrame:ncols
-- Returns the number of columns.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:ncols
  local _todo = "TODO: write a real DataFrame:ncols usage example"
  print(_todo)
end

--@api-stub: DataFrame:columns
-- Returns a table of column names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:columns
  local _todo = "TODO: write a real DataFrame:columns usage example"
  print(_todo)
end

--@api-stub: DataFrame:count
-- Returns the row count (alias for nrows).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:count
  local _todo = "TODO: write a real DataFrame:count usage example"
  print(_todo)
end

--@api-stub: DataFrame:removeColumn
-- Removes a column by name or index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:removeColumn
  local _todo = "TODO: write a real DataFrame:removeColumn usage example"
  print(_todo)
end

--@api-stub: DataFrame:rename
-- Renames the column `old_name` to `new_name` in this DataFrame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:rename
  local _todo = "TODO: write a real DataFrame:rename usage example"
  print(_todo)
end

--@api-stub: DataFrame:getColumn
-- Returns all values in a column as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:getColumn
  local _todo = "TODO: write a real DataFrame:getColumn usage example"
  print(_todo)
end

--@api-stub: DataFrame:addRow
-- Adds a row from an optional table of name-value pairs, returns 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:addRow
  local _todo = "TODO: write a real DataFrame:addRow usage example"
  print(_todo)
end

--@api-stub: DataFrame:removeRow
-- Removes a row by 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:removeRow
  local _todo = "TODO: write a real DataFrame:removeRow usage example"
  print(_todo)
end

--@api-stub: DataFrame:getRow
-- Returns a row as a table of name-value pairs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:getRow
  local _todo = "TODO: write a real DataFrame:getRow usage example"
  print(_todo)
end

--@api-stub: DataFrame:getValue
-- Returns a single cell value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:getValue
  local _todo = "TODO: write a real DataFrame:getValue usage example"
  print(_todo)
end

--@api-stub: DataFrame:head
-- Returns the first n rows (default 5).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:head
  local _todo = "TODO: write a real DataFrame:head usage example"
  print(_todo)
end

--@api-stub: DataFrame:tail
-- Returns the last n rows (default 5).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:tail
  local _todo = "TODO: write a real DataFrame:tail usage example"
  print(_todo)
end

--@api-stub: DataFrame:slice
-- Returns rows from start to end (1-based, inclusive).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:slice
  local _todo = "TODO: write a real DataFrame:slice usage example"
  print(_todo)
end

--@api-stub: DataFrame:select
-- Selects a subset of columns, returns a new DataFrame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:select
  local _todo = "TODO: write a real DataFrame:select usage example"
  print(_todo)
end

--@api-stub: DataFrame:unique
-- Returns unique values in a column as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:unique
  local _todo = "TODO: write a real DataFrame:unique usage example"
  print(_todo)
end

--@api-stub: DataFrame:groupBy
-- Groups rows by column value, returns a table of DataFrames keyed by value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:groupBy
  local _todo = "TODO: write a real DataFrame:groupBy usage example"
  print(_todo)
end

--@api-stub: DataFrame:merge
-- Appends rows from another DataFrame in-place.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:merge
  local _todo = "TODO: write a real DataFrame:merge usage example"
  print(_todo)
end

--@api-stub: DataFrame:countBy
-- Counts distinct values in a column, returns a DataFrame with value and count columns.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:countBy
  local _todo = "TODO: write a real DataFrame:countBy usage example"
  print(_todo)
end

--@api-stub: DataFrame:dropNil
-- Removes rows where the given column is nil, returns a new DataFrame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:dropNil
  local _todo = "TODO: write a real DataFrame:dropNil usage example"
  print(_todo)
end

--@api-stub: DataFrame:sample
-- Returns a random sample of n rows.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:sample
  local _todo = "TODO: write a real DataFrame:sample usage example"
  print(_todo)
end

--@api-stub: DataFrame:describe
-- Returns descriptive statistics for all numeric columns.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:describe
  local _todo = "TODO: write a real DataFrame:describe usage example"
  print(_todo)
end

--@api-stub: DataFrame:sum
-- Returns the sum of numeric values in a column.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:sum
  local _todo = "TODO: write a real DataFrame:sum usage example"
  print(_todo)
end

--@api-stub: DataFrame:mean
-- Returns the mean of numeric values in a column.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:mean
  local _todo = "TODO: write a real DataFrame:mean usage example"
  print(_todo)
end

--@api-stub: DataFrame:min
-- Returns the minimum numeric value in a column.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:min
  local _todo = "TODO: write a real DataFrame:min usage example"
  print(_todo)
end

--@api-stub: DataFrame:max
-- Returns the maximum numeric value in a column.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:max
  local _todo = "TODO: write a real DataFrame:max usage example"
  print(_todo)
end

--@api-stub: DataFrame:median
-- Returns the median of numeric values in a column.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:median
  local _todo = "TODO: write a real DataFrame:median usage example"
  print(_todo)
end

--@api-stub: DataFrame:stddev
-- Returns the population standard deviation of numeric values in a column.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:stddev
  local _todo = "TODO: write a real DataFrame:stddev usage example"
  print(_todo)
end

--@api-stub: DataFrame:variance
-- Returns the population variance of numeric values in a column.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:variance
  local _todo = "TODO: write a real DataFrame:variance usage example"
  print(_todo)
end

--@api-stub: DataFrame:fillNil
-- Replaces nil values in a column with the given value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:fillNil
  local _todo = "TODO: write a real DataFrame:fillNil usage example"
  print(_todo)
end

--@api-stub: DataFrame:toCSV
-- Serializes this DataFrame to a CSV string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:toCSV
  local _todo = "TODO: write a real DataFrame:toCSV usage example"
  print(_todo)
end

--@api-stub: DataFrame:toJSON
-- Serializes this DataFrame to a JSON string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:toJSON
  local _todo = "TODO: write a real DataFrame:toJSON usage example"
  print(_todo)
end

--@api-stub: DataFrame:toBinary
-- Serializes this DataFrame to a binary LVDF string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:toBinary
  local _todo = "TODO: write a real DataFrame:toBinary usage example"
  print(_todo)
end

--@api-stub: DataFrame:toTable
-- Converts this DataFrame to a Lua table of row tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:toTable
  local _todo = "TODO: write a real DataFrame:toTable usage example"
  print(_todo)
end

--@api-stub: DataFrame:toString
-- Returns a formatted string table representation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:toString
  local _todo = "TODO: write a real DataFrame:toString usage example"
  print(_todo)
end

--@api-stub: DataFrame:query
-- Executes a SQL query against this DataFrame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:query
  local _todo = "TODO: write a real DataFrame:query usage example"
  print(_todo)
end

--@api-stub: DataFrame:clone
-- Returns a deep copy of this DataFrame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:clone
  local _todo = "TODO: write a real DataFrame:clone usage example"
  print(_todo)
end

--@api-stub: DataFrame:correlationMatrix
-- Compute a correlation matrix for all numeric columns.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:correlationMatrix
  local _todo = "TODO: write a real DataFrame:correlationMatrix usage example"
  print(_todo)
end

--@api-stub: DataFrame:modeVal
-- Return the most frequent value in a column (nil if empty).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:modeVal
  local _todo = "TODO: write a real DataFrame:modeVal usage example"
  print(_todo)
end

--@api-stub: DataFrame:entropy
-- Shannon entropy (bits) of the value distribution in a column.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:entropy
  local _todo = "TODO: write a real DataFrame:entropy usage example"
  print(_todo)
end

--@api-stub: DataFrame:addRowBatch
-- Add multiple rows at once from a table of row tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:addRowBatch
  local _todo = "TODO: write a real DataFrame:addRowBatch usage example"
  print(_todo)
end

--@api-stub: DataFrame:getColumnAsF64
-- Return a numeric column as a Lua array of numbers (nils → 0/nan).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:getColumnAsF64
  local _todo = "TODO: write a real DataFrame:getColumnAsF64 usage example"
  print(_todo)
end

--@api-stub: DataFrame:setColumnFromF64
-- Set a numeric column from a Lua array of numbers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:setColumnFromF64
  local _todo = "TODO: write a real DataFrame:setColumnFromF64 usage example"
  print(_todo)
end

--@api-stub: DataFrame:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:type
  local _todo = "TODO: write a real DataFrame:type usage example"
  print(_todo)
end

--@api-stub: DataFrame:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:typeOf
  local _todo = "TODO: write a real DataFrame:typeOf usage example"
  print(_todo)
end

--@api-stub: DataFrame:withEval
-- Returns a new DataFrame with an additional computed column named `col_name`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: DataFrame:withEval
  local _todo = "TODO: write a real DataFrame:withEval usage example"
  print(_todo)
end

-- ── Database methods ──

--@api-stub: Database:getTable
-- Returns a copy of a table by name, or nil if not found.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:getTable
  local _todo = "TODO: write a real Database:getTable usage example"
  print(_todo)
end

--@api-stub: Database:removeTable
-- Drops the named table from this in-memory database if it exists.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:removeTable
  local _todo = "TODO: write a real Database:removeTable usage example"
  print(_todo)
end

--@api-stub: Database:hasTable
-- Returns true if a table with the given name exists.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:hasTable
  local _todo = "TODO: write a real Database:hasTable usage example"
  print(_todo)
end

--@api-stub: Database:listTables
-- Returns a table of all table names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:listTables
  local _todo = "TODO: write a real Database:listTables usage example"
  print(_todo)
end

--@api-stub: Database:tableCount
-- Returns the number of tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:tableCount
  local _todo = "TODO: write a real Database:tableCount usage example"
  print(_todo)
end

--@api-stub: Database:clear
-- Drops every table from this in-memory database, leaving it empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:clear
  local _todo = "TODO: write a real Database:clear usage example"
  print(_todo)
end

--@api-stub: Database:merge
-- Merges all tables from another Database into this one.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:merge
  local _todo = "TODO: write a real Database:merge usage example"
  print(_todo)
end

--@api-stub: Database:toJSON
-- Serializes all tables to a JSON object string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:toJSON
  local _todo = "TODO: write a real Database:toJSON usage example"
  print(_todo)
end

--@api-stub: Database:query
-- Executes a SQL query against the database tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:query
  local _todo = "TODO: write a real Database:query usage example"
  print(_todo)
end

--@api-stub: Database:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:type
  local _todo = "TODO: write a real Database:type usage example"
  print(_todo)
end

--@api-stub: Database:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/dataframe_api.rs and docs/specs/dataframe.md).
do  -- TODO: Database:typeOf
  local _todo = "TODO: write a real Database:typeOf usage example"
  print(_todo)
end

