-- content/examples/dataframe.lua
-- Lurek2D lurek.dataframe API Reference
-- Run with: cargo run -- content/examples/dataframe
--
-- Scenario: An RPG analytics dashboard — tracking player stats, item inventories,
-- monster spawn data, and leaderboard scores. Uses DataFrames for in-game data
-- analysis, CSV/JSON import/export, and a Database for multi-table persistence.

print("=== lurek.dataframe — Game Data Analytics ===\n")

-- =============================================================================
-- DataFrame Creation (module-level functions)
-- =============================================================================

-- ---- Stub: lurek.dataframe.newDataFrame -----------------------------------
--@api-stub: lurek.dataframe.newDataFrame
-- Create an empty DataFrame with named columns.
local monsters = lurek.dataframe.newDataFrame({
    columns = {"name", "type", "hp", "attack", "xp_reward"}
})
print("monsters table created: 5 columns")

-- ---- Stub: lurek.dataframe.fromTable --------------------------------------
--@api-stub: lurek.dataframe.fromTable
-- Create a DataFrame from a Lua table (most common way to seed data).
local items = lurek.dataframe.fromTable({
    name = {"Iron Sword", "Health Potion", "Fire Staff", "Steel Shield", "Mana Ring"},
    type = {"weapon", "consumable", "weapon", "armor", "accessory"},
    price = {150, 50, 300, 200, 250},
    weight = {3.5, 0.5, 2.0, 6.0, 0.2},
    rarity = {"common", "common", "rare", "uncommon", "rare"}
})
print("items table: " .. items:nrows() .. " rows, " .. items:ncols() .. " columns")

-- ---- Stub: lurek.dataframe.fromCSV ----------------------------------------
--@api-stub: lurek.dataframe.fromCSV
-- Load from CSV file (e.g. game balance spreadsheet exported from Excel).
local balance = lurek.dataframe.fromCSV("assets/data/monster_balance.csv")
print("balance data loaded from CSV")

-- ---- Stub: lurek.dataframe.fromJSON ---------------------------------------
--@api-stub: lurek.dataframe.fromJSON
-- Load from JSON (e.g. server leaderboard response).
local scores = lurek.dataframe.fromJSON("assets/data/leaderboard.json")
print("leaderboard loaded from JSON")

-- ---- Stub: lurek.dataframe.fromBinary -------------------------------------
--@api-stub: lurek.dataframe.fromBinary
-- Load from a compact binary format (fast saves).
local save_data = lurek.dataframe.fromBinary("saves/player_stats.bin")
print("save data loaded from binary")

-- ---- Stub: lurek.dataframe.random -----------------------------------------
--@api-stub: lurek.dataframe.random
-- Generate random test data for debugging or procedural generation.
local test_data = lurek.dataframe.random(100, {
    columns = {"x", "y", "damage"},
    min = {0, 0, 1},
    max = {800, 600, 100}
})
print("random test data: " .. test_data:nrows() .. " rows")

-- =============================================================================
-- DataFrame Object Methods — Row & Column Access
-- =============================================================================

-- ---- Stub: DataFrame:nrows ------------------------------------------------
--@api-stub: DataFrame:nrows
print("items rows: " .. items:nrows())

-- ---- Stub: DataFrame:ncols ------------------------------------------------
--@api-stub: DataFrame:ncols
print("items columns: " .. items:ncols())

-- ---- Stub: DataFrame:columns ----------------------------------------------
--@api-stub: DataFrame:columns
local cols = items:columns()
print("item columns: " .. table.concat(cols, ", "))

-- ---- Stub: DataFrame:count ------------------------------------------------
--@api-stub: DataFrame:count
-- Count non-nil values in a column.
print("non-nil prices: " .. items:count("price"))

-- ---- Stub: DataFrame:getColumn --------------------------------------------
--@api-stub: DataFrame:getColumn
local prices = items:getColumn("price")
print("prices: " .. table.concat(prices, ", "))

-- ---- Stub: DataFrame:getRow -----------------------------------------------
--@api-stub: DataFrame:getRow
local row = items:getRow(0)
print("first item: " .. row.name .. " (" .. row.type .. ") - " .. row.price .. "g")

-- ---- Stub: DataFrame:getValue ---------------------------------------------
--@api-stub: DataFrame:getValue
local first_name = items:getValue(0, "name")
print("item[0].name = " .. first_name)

-- ---- Stub: DataFrame:addRow -----------------------------------------------
--@api-stub: DataFrame:addRow
items:addRow({name = "Dragon Scale", type = "material", price = 500, weight = 1.0, rarity = "legendary"})
print("added Dragon Scale: " .. items:nrows() .. " items total")

-- ---- Stub: DataFrame:addRowBatch ------------------------------------------
--@api-stub: DataFrame:addRowBatch
-- Add multiple rows at once (faster than one-by-one).
items:addRowBatch({
    {name = "Bronze Axe", type = "weapon", price = 120, weight = 4.0, rarity = "common"},
    {name = "Elixir", type = "consumable", price = 200, weight = 0.3, rarity = "uncommon"},
})
print("batch added 2 items: " .. items:nrows() .. " total")

-- ---- Stub: DataFrame:removeRow --------------------------------------------
--@api-stub: DataFrame:removeRow
items:removeRow(items:nrows() - 1)
print("last row removed: " .. items:nrows() .. " remaining")

-- ---- Stub: DataFrame:removeColumn -----------------------------------------
--@api-stub: DataFrame:removeColumn
-- Remove a column no longer needed (e.g. internal debug data).
local items_copy = items:clone()
items_copy:removeColumn("weight")
print("weight column removed from copy: " .. items_copy:ncols() .. " columns")

-- ---- Stub: DataFrame:rename -----------------------------------------------
--@api-stub: DataFrame:rename
items_copy:rename("price", "gold_cost")
print("price renamed to gold_cost")

-- =============================================================================
-- Filtering, Slicing & Sampling
-- =============================================================================

-- ---- Stub: DataFrame:head -------------------------------------------------
--@api-stub: DataFrame:head
local top3 = items:head(3)
print("top 3 items: " .. top3:nrows() .. " rows")

-- ---- Stub: DataFrame:tail -------------------------------------------------
--@api-stub: DataFrame:tail
local last2 = items:tail(2)
print("last 2 items: " .. last2:nrows() .. " rows")

-- ---- Stub: DataFrame:slice ------------------------------------------------
--@api-stub: DataFrame:slice
local mid = items:slice(1, 3)
print("items [1..3]: " .. mid:nrows() .. " rows")

-- ---- Stub: DataFrame:select -----------------------------------------------
--@api-stub: DataFrame:select
-- Select specific columns (like SQL SELECT).
local name_price = items:select({"name", "price"})
print("selected name+price: " .. name_price:ncols() .. " columns")

-- ---- Stub: DataFrame:unique -----------------------------------------------
--@api-stub: DataFrame:unique
local unique_types = items:unique("type")
print("unique item types: " .. #unique_types)

-- ---- Stub: DataFrame:query ------------------------------------------------
--@api-stub: DataFrame:query
-- SQL-like query string for filtering.
local rare = items:query("rarity == 'rare'")
print("rare items: " .. rare:nrows())

-- ---- Stub: DataFrame:sample -----------------------------------------------
--@api-stub: DataFrame:sample
local sample = items:sample(2)
print("random sample of 2 items: " .. sample:nrows())

-- ---- Stub: DataFrame:dropNil ----------------------------------------------
--@api-stub: DataFrame:dropNil
local clean = items:dropNil()
print("after dropNil: " .. clean:nrows() .. " rows (no nils)")

-- ---- Stub: DataFrame:fillNil ----------------------------------------------
--@api-stub: DataFrame:fillNil
-- Replace nil values with a default (e.g. 0 for missing stats).
items:fillNil("price", 0)
print("nil prices filled with 0")

-- =============================================================================
-- Grouping & Aggregation — game balance analytics
-- =============================================================================

-- ---- Stub: DataFrame:groupBy ----------------------------------------------
--@api-stub: DataFrame:groupBy
-- Group items by type to analyze balance across categories.
local by_type = items:groupBy("type")
print("grouped by type: " .. tostring(by_type))

-- ---- Stub: DataFrame:countBy ----------------------------------------------
--@api-stub: DataFrame:countBy
-- Count items per category.
local counts = items:countBy("type")
print("items per type: " .. tostring(counts))

-- ---- Stub: DataFrame:merge ------------------------------------------------
--@api-stub: DataFrame:merge
-- Merge two DataFrames (like SQL JOIN). Combine items with their drop sources.
local drop_sources = lurek.dataframe.fromTable({
    name = {"Iron Sword", "Fire Staff"},
    drop_from = {"Skeleton Knight", "Fire Dragon"}
})
local merged = items:merge(drop_sources, "name")
print("merged items+drops: " .. merged:nrows() .. " rows, " .. merged:ncols() .. " cols")

-- =============================================================================
-- Statistics — balance analysis
-- =============================================================================

-- ---- Stub: DataFrame:sum --------------------------------------------------
--@api-stub: DataFrame:sum
print("total item value: " .. items:sum("price") .. " gold")

-- ---- Stub: DataFrame:mean -------------------------------------------------
--@api-stub: DataFrame:mean
print("average price: " .. string.format("%.1f", items:mean("price")) .. " gold")

-- ---- Stub: DataFrame:min --------------------------------------------------
--@api-stub: DataFrame:min
print("cheapest: " .. items:min("price") .. " gold")

-- ---- Stub: DataFrame:max --------------------------------------------------
--@api-stub: DataFrame:max
print("most expensive: " .. items:max("price") .. " gold")

-- ---- Stub: DataFrame:median -----------------------------------------------
--@api-stub: DataFrame:median
print("median price: " .. tostring(items:median("price")))

-- ---- Stub: DataFrame:stddev -----------------------------------------------
--@api-stub: DataFrame:stddev
print("price std dev: " .. string.format("%.1f", items:stddev("price")))

-- ---- Stub: DataFrame:variance ---------------------------------------------
--@api-stub: DataFrame:variance
print("price variance: " .. string.format("%.1f", items:variance("price")))

-- ---- Stub: DataFrame:describe ---------------------------------------------
--@api-stub: DataFrame:describe
-- Full descriptive statistics for balance review.
local stats = items:describe()
print("describe:\n" .. tostring(stats))

-- ---- Stub: DataFrame:correlationMatrix ------------------------------------
--@api-stub: DataFrame:correlationMatrix
-- Correlation between numeric columns (e.g. does price correlate with weight?).
local corr = items:correlationMatrix()
print("correlation matrix:\n" .. tostring(corr))

-- ---- Stub: DataFrame:modeVal ----------------------------------------------
--@api-stub: DataFrame:modeVal
print("most common rarity: " .. tostring(items:modeVal("rarity")))

-- ---- Stub: DataFrame:entropy ----------------------------------------------
--@api-stub: DataFrame:entropy
-- Shannon entropy — measures category diversity.
print("type entropy: " .. string.format("%.3f", items:entropy("type")))

-- ---- Stub: DataFrame:withEval ---------------------------------------------
--@api-stub: DataFrame:withEval
-- Add a computed column based on an expression.
local enriched = items:withEval("value_per_kg", "price / weight")
print("value_per_kg computed: " .. enriched:ncols() .. " columns")

-- ---- Stub: DataFrame:getColumnAsF64 ---------------------------------------
--@api-stub: DataFrame:getColumnAsF64
-- Get a column as a flat array of floats (for math operations).
local price_arr = items:getColumnAsF64("price")
print("prices as f64: " .. #price_arr .. " values")

-- ---- Stub: DataFrame:setColumnFromF64 -------------------------------------
--@api-stub: DataFrame:setColumnFromF64
-- Set a column from a flat float array (after external processing).
items:setColumnFromF64("price", price_arr)
print("prices restored from f64 array")

-- =============================================================================
-- Clone & Type
-- =============================================================================

-- ---- Stub: DataFrame:clone ------------------------------------------------
--@api-stub: DataFrame:clone
local items_backup = items:clone()
print("items cloned: " .. items_backup:nrows() .. " rows")

-- ---- Stub: DataFrame:type -------------------------------------------------
--@api-stub: DataFrame:type
-- ---- Stub: DataFrame:typeOf -----------------------------------------------
--@api-stub: DataFrame:typeOf
print("type: " .. tostring(items:type()))
print("typeOf: " .. tostring(items:typeOf("DataFrame")))

-- =============================================================================
-- Serialization — Save/Load game data
-- =============================================================================

-- ---- Stub: DataFrame:toString ---------------------------------------------
--@api-stub: DataFrame:toString
print(items:toString())

-- ---- Stub: DataFrame:toTable ----------------------------------------------
--@api-stub: DataFrame:toTable
local tbl = items:toTable()
print("toTable: " .. #tbl.name .. " names")

-- ---- Stub: DataFrame:toCSV ------------------------------------------------
--@api-stub: DataFrame:toCSV
items:toCSV("output/items_export.csv")
print("exported to CSV: output/items_export.csv")

-- ---- Stub: DataFrame:toJSON -----------------------------------------------
--@api-stub: DataFrame:toJSON
items:toJSON("output/items_export.json")
print("exported to JSON: output/items_export.json")

-- ---- Stub: DataFrame:toBinary ---------------------------------------------
--@api-stub: DataFrame:toBinary
items:toBinary("output/items_export.bin")
print("exported to binary: output/items_export.bin")

-- =============================================================================
-- Database — multi-table game data persistence
-- =============================================================================

-- ---- Stub: lurek.dataframe.newDatabase ------------------------------------
--@api-stub: lurek.dataframe.newDatabase
local db = lurek.dataframe.newDatabase()
print("database created")

-- ---- Stub: Database:getTable ----------------------------------------------
--@api-stub: Database:getTable
-- Store DataFrames in the database by name.
db:getTable("items")  -- returns nil if not yet stored
print("items table from DB: " .. tostring(db:getTable("items")))

-- ---- Stub: Database:hasTable ----------------------------------------------
--@api-stub: Database:hasTable
print("has 'items': " .. tostring(db:hasTable("items")))

-- ---- Stub: Database:listTables --------------------------------------------
--@api-stub: Database:listTables
local tables = db:listTables()
print("DB tables: " .. #tables)

-- ---- Stub: Database:tableCount --------------------------------------------
--@api-stub: Database:tableCount
print("table count: " .. db:tableCount())

-- ---- Stub: Database:removeTable -------------------------------------------
--@api-stub: Database:removeTable
db:removeTable("items")
print("items table removed from DB")

-- ---- Stub: Database:clear -------------------------------------------------
--@api-stub: Database:clear
db:clear()
print("database cleared")

-- ---- Stub: Database:merge -------------------------------------------------
--@api-stub: Database:merge
-- Merge another database into this one (combine save files).
local db2 = lurek.dataframe.newDatabase()
db:merge(db2)
print("databases merged")

-- ---- Stub: Database:toJSON ------------------------------------------------
--@api-stub: Database:toJSON
db:toJSON("output/game_db.json")
print("database exported to JSON")

-- ---- Stub: Database:query -------------------------------------------------
--@api-stub: Database:query
-- SQL-like query across database tables.
local result = db:query("SELECT * FROM items WHERE price > 100")
print("query result: " .. tostring(result))

-- ---- Stub: Database:type --------------------------------------------------
--@api-stub: Database:type
-- ---- Stub: Database:typeOf ------------------------------------------------
--@api-stub: Database:typeOf
print("DB type: " .. tostring(db:type()))
print("DB typeOf: " .. tostring(db:typeOf("Database")))

print("\n-- dataframe.lua example complete --")
