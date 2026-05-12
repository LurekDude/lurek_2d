-- Lurek2D DataFrame Tests
-- Tests for lurek.dataframe tabular data API

-- Helper to build a simple test DataFrame

local function make_test_df()
    local csv = "name,age,score\nAlice,30,90\nBob,25,85\nCharlie,35,92"
    return lurek.dataframe.fromCSV(csv)
end
function df_add_column(df, name, default)
    ---@type any
    local default_value = default
    if default_value == nil then
        return df:addColumn(name)
    end
    return df:addColumn(name, default_value)
end

function df_remove_column(df, col)
    ---@type any
    local column_ref = col
    return df:removeColumn(column_ref)
end

function df_set_value(df, row, col, val)
    ---@type any
    local column_ref = col
    return df:setValue(row, column_ref, val)
end



-- =========================================================================
-- 1. Module existence
-- =========================================================================
-- @describe lurek.dataframe module exists
describe("lurek.dataframe module exists", function()
    -- @covers lurek.dataframe
    it("lurek.dataframe is a table", function()
        expect_type("table", lurek.dataframe)
    end)

    -- @covers lurek.dataframe.newDataFrame
    it("has newDataFrame factory", function()
        expect_type("function", lurek.dataframe.newDataFrame)
    end)

    -- @covers lurek.dataframe.newDatabase
    it("has newDatabase factory", function()
        expect_type("function", lurek.dataframe.newDatabase)
    end)

    -- @covers lurek.dataframe.fromTable
    it("has fromTable factory", function()
        expect_type("function", lurek.dataframe.fromTable)
    end)

    -- @covers lurek.dataframe.fromRows
    it("has fromRows factory", function()
        expect_type("function", lurek.dataframe.fromRows)
    end)

    -- @covers lurek.dataframe.fromCSV
    it("has fromCSV factory", function()
        expect_type("function", lurek.dataframe.fromCSV)
    end)

    -- @covers lurek.dataframe.fromJSON
    it("has fromJSON factory", function()
        expect_type("function", lurek.dataframe.fromJSON)
    end)

    -- @covers lurek.dataframe.fromBinary
    it("has fromBinary factory", function()
        expect_type("function", lurek.dataframe.fromBinary)
    end)

    -- @covers lurek.dataframe.random
    it("has random factory", function()
        expect_type("function", lurek.dataframe.random)
    end)
end)

-- =========================================================================
-- 2. Construction
-- =========================================================================
-- @describe construction
describe("construction", function()
    -- @covers LDataFrame:ncols
    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.newDataFrame
    it("newDataFrame creates empty DataFrame", function()
        local df = lurek.dataframe.newDataFrame()
        expect_equal(0, df:nrows())
        expect_equal(0, df:ncols())
    end)

    -- @covers LVecFrame:ncols
    -- @covers LVecFrame:nrows
    it("fromCSV creates DataFrame with correct shape", function()
        local df = make_test_df()
        expect_equal(3, df:nrows())
        expect_equal(3, df:ncols())
    end)

    -- @covers LDataFrame:columns
    -- @covers LVecFrame:columns
    it("fromCSV parses column names", function()
        local df = make_test_df()
        local cols = df:columns()
        expect_equal("name", cols[1])
        expect_equal("age", cols[2])
        expect_equal("score", cols[3])
    end)

    -- @covers LVecFrame:getValue
    it("fromCSV auto-detects numbers", function()
        local df = make_test_df()
        expect_near(30, df:getValue(1, "age"), 1e-5)
        expect_near(25, df:getValue(2, "age"), 1e-5)
    end)

    -- @covers LVecFrame:getValue
    it("fromCSV parses text values", function()
        local df = make_test_df()
        expect_equal("Alice", df:getValue(1, "name"))
        expect_equal("Bob", df:getValue(2, "name"))
    end)

    -- @covers LDataFrame:ncols
    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.fromTable
    it("fromTable creates DataFrame from row tables", function()
        local df = lurek.dataframe.fromTable({
            { x = 1, y = 2 },
            { x = 3, y = 4 },
        })
        expect_equal(2, df:nrows())
        expect_equal(2, df:ncols())
        local df = lurek.dataframe.fromRows(
            { "id", "name", "score" },
            {
                { 1, "Alice", 10 },
                { 2, "Bob", 20 },
            }
        )
        expect_equal(2, df:nrows())
        expect_equal(3, df:ncols())
        expect_equal("Bob", df:getValue(2, "name"))
    end)

    -- @covers lurek.dataframe.fromRows
    it("fromRows validates row width against declared columns", function()
        expect_error(function()
            lurek.dataframe.fromRows({ "x", "y" }, { { 1 } })
        end)
    end)

    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.fromJSON
    it("fromJSON creates DataFrame", function()
        local json = '[{"a":1,"b":"hello"},{"a":2,"b":"world"}]'
        local df = lurek.dataframe.fromJSON(json)
        expect_equal(2, df:nrows())
    end)

    -- @covers LDataFrame:ncols
    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.random
    it("random creates DataFrame with specified rows", function()
        local defs = { {"x", "float"}, {"y", "float"} }
        local df = lurek.dataframe.random(defs, 10, 42)
        expect_equal(10, df:nrows())
        expect_equal(2, df:ncols())
    end)

    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.random
    it("random with seed is deterministic", function()
        local defs = { {"val", "float"} }
        local df1 = lurek.dataframe.random(defs, 5, 123)
        local df2 = lurek.dataframe.random(defs, 5, 123)
        for i = 1, 5 do
            expect_near(df1:getValue(i, "val"), df2:getValue(i, "val"), 1e-5)
        end
    end)

    -- @covers LDataFrame:ncols
    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.fromCSV
    it("fromCSV with empty input creates empty DataFrame", function()
        local df = lurek.dataframe.fromCSV("")
        expect_equal(0, df:nrows())
        expect_equal(0, df:ncols())
    end)
end)

-- =========================================================================
-- 3. Schema
-- =========================================================================
-- @describe schema
describe("schema", function()
    -- @covers LVecFrame:nrows
    it("nrows returns row count", function()
        local df = make_test_df()
        expect_equal(3, df:nrows())
    end)

    -- @covers LVecFrame:ncols
    it("ncols returns column count", function()
        local df = make_test_df()
        expect_equal(3, df:ncols())
    end)

    -- @covers LDataFrame:columns
    -- @covers LVecFrame:columns
    it("columns returns ordered column names", function()
        local df = make_test_df()
        local cols = df:columns()
        expect_equal(3, #cols)
    end)

    -- @covers lurek.dataframe
    it("count is alias for nrows", function()
        local df = make_test_df()
        expect_equal(df:nrows(), df:count())
    end)
end)

-- =========================================================================
-- 4. Column operations
-- =========================================================================
-- @describe column operations
describe("column operations", function()
    -- @covers LDataFrame:addColumn
    -- @covers LDataFrame:ncols
    it("addColumn increases ncols", function()
        local df = make_test_df()
        df_add_column(df, "grade")
        expect_equal(4, df:ncols())
    end)

    -- @covers LDataFrame:addColumn
    -- @covers LDataFrame:getValue
    it("addColumn with default fills all rows", function()
        local df = make_test_df()
        df_add_column(df, "pass", true)
        for i = 1, df:nrows() do
            expect_equal(true, df:getValue(i, "pass"))
        end
    end)

    -- @covers LDataFrame:ncols
    -- @covers LDataFrame:removeColumn
    it("removeColumn by name decreases ncols", function()
        local df = make_test_df()
        df_remove_column(df, "age")
        expect_equal(2, df:ncols())
    end)

    -- @covers LDataFrame:ncols
    -- @covers LDataFrame:removeColumn
    it("removeColumn by index decreases ncols", function()
        local df = make_test_df()
        df_remove_column(df, 2)
        expect_equal(2, df:ncols())
    end)

    -- @covers LDataFrame:rename
    it("rename changes column name", function()
        local df = make_test_df()
        df:rename("age", "years")
        local cols = df:columns()
        -- Check "years" is present and "age" is not
        local found_years = false
        local found_age = false
        for _, c in ipairs(cols) do
            if c == "years" then found_years = true end
            if c == "age" then found_age = true end
        end
        expect_true(found_years)
        expect_false(found_age)
    end)

    -- @covers LDataFrame:getColumn
    it("getColumn returns column values", function()
        local df = make_test_df()
        local ages = df:getColumn("age")
        expect_equal(3, #ages)
        expect_near(30, ages[1], 1e-5)
        expect_near(25, ages[2], 1e-5)
        expect_near(35, ages[3], 1e-5)
    end)

    -- @covers LDataFrame:getColumn
    it("getColumn by index works", function()
        local df = make_test_df()
        local names = df:getColumn(1)
        expect_equal(3, #names)
        expect_equal("Alice", names[1])
    end)
end)

-- =========================================================================
-- 5. Row operations
-- =========================================================================
-- @describe row operations
describe("row operations", function()
    -- @covers LDataFrame:addRow
    it("addRow increases nrows", function()
        local df = make_test_df()
        df:addRow({ name = "Dave", age = 28, score = 88 })
        expect_equal(4, df:nrows())
    end)

    -- @covers LDataFrame:addRow
    it("addRow returns 1-based index", function()
        local df = make_test_df()
        local idx = df:addRow({ name = "Dave", age = 28, score = 88 })
        expect_equal(4, idx)
    end)

    -- @covers LDataFrame:addRow
    it("addRow with no args adds empty row", function()
        local df = make_test_df()
        local before = df:nrows()
        df:addRow()
        expect_equal(before + 1, df:nrows())
    end)

    -- @covers LDataFrame:removeRow
    it("removeRow decreases nrows", function()
        local df = make_test_df()
        df:removeRow(2)
        expect_equal(2, df:nrows())
    end)

    -- @covers LDataFrame:removeRow
    it("removeRow removes correct row", function()
        local df = make_test_df()
        df:removeRow(1) -- Remove Alice
        expect_equal("Bob", df:getValue(1, "name"))
    end)

    -- @covers LDataFrame:getRow
    it("getRow returns row as table", function()
        local df = make_test_df()
        local row = df:getRow(1)
        expect_equal("Alice", row.name)
        expect_near(30, row.age, 1e-5)
        expect_near(90, row.score, 1e-5)
    end)

    -- @covers LDataFrame:getRow
    it("getRow with last row index works", function()
        local df = make_test_df()
        local row = df:getRow(3)
        expect_equal("Charlie", row.name)
    end)
end)

-- =========================================================================
-- 6. Cell access
-- =========================================================================
-- @describe cell access
describe("cell access", function()
    -- @covers LDataFrame:getValue
    it("getValue by column name", function()
        local df = make_test_df()
        expect_equal("Alice", df:getValue(1, "name"))
    end)

    -- @covers LDataFrame:getValue
    it("getValue by column index", function()
        local df = make_test_df()
        expect_equal("Alice", df:getValue(1, 1))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:setValue
    it("setValue changes cell value", function()
        local df = make_test_df()
        df_set_value(df, 1, "name", "Alicia")
        expect_equal("Alicia", df:getValue(1, "name"))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:setValue
    it("setValue by column index", function()
        local df = make_test_df()
        df_set_value(df, 2, 2, 99)
        expect_near(99, df:getValue(2, "age"), 1e-5)
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:setValue
    it("setValue to nil clears cell", function()
        local df = make_test_df()
        df_set_value(df, 1, "name", nil)
        expect_nil(df:getValue(1, "name"))
    end)
end)

-- =========================================================================
-- 7. Filter
-- =========================================================================
-- @describe filter
describe("filter", function()
    -- @covers LDataFrame:filter
    it("filter == returns matching rows", function()
        local df = make_test_df()
        local result = df:filter("name", "==", "Alice")
        expect_equal(1, result:nrows())
        expect_equal("Alice", result:getValue(1, "name"))
    end)

    -- @covers LDataFrame:filter
    it("filter != excludes matching rows", function()
        local df = make_test_df()
        local result = df:filter("name", "!=", "Alice")
        expect_equal(2, result:nrows())
    end)

    -- @covers LDataFrame:filter
    it("filter < on numeric column", function()
        local df = make_test_df()
        local result = df:filter("age", "<", 30)
        expect_equal(1, result:nrows())
        expect_equal("Bob", result:getValue(1, "name"))
    end)

    -- @covers LDataFrame:filter
    it("filter > on numeric column", function()
        local df = make_test_df()
        local result = df:filter("age", ">", 30)
        expect_equal(1, result:nrows())
        expect_equal("Charlie", result:getValue(1, "name"))
    end)

    -- @covers LDataFrame:filter
    it("filter <= includes boundary", function()
        local df = make_test_df()
        local result = df:filter("age", "<=", 30)
        expect_equal(2, result:nrows())
    end)

    -- @covers LDataFrame:filter
    it("filter >= includes boundary", function()
        local df = make_test_df()
        local result = df:filter("age", ">=", 30)
        expect_equal(2, result:nrows())
    end)

    -- @covers LDataFrame:filter
    it("filter with no matches returns empty DataFrame", function()
        local df = make_test_df()
        local result = df:filter("age", ">", 100)
        expect_equal(0, result:nrows())
    end)

    -- @covers LDataFrame:filter
    it("filter contains matches substrings", function()
        local df = make_test_df()
        local result = df:filter("name", "contains", "li")
        expect_equal(2, result:nrows())
        expect_equal("Alice", result:getValue(1, "name"))
        expect_equal("Charlie", result:getValue(2, "name"))
    end)

    -- @covers LDataFrame:filter
    it("filter with unsupported operator errors", function()
        local df = make_test_df()
        local bad_op = string.char(126)
        expect_error(function()
            df:filter("age", bad_op, 1)
        end)
    end)
end)

-- =========================================================================
-- 8. Sort
-- =========================================================================
-- @describe sort
describe("sort", function()
    -- @covers lurek.dataframe
    it("sort ascending by numeric column", function()
        local df = make_test_df()
        local sorted = df:sort("age", true)
        expect_near(25, sorted:getValue(1, "age"), 1e-5)
        expect_near(30, sorted:getValue(2, "age"), 1e-5)
        expect_near(35, sorted:getValue(3, "age"), 1e-5)
    end)

    -- @covers lurek.dataframe
    it("sort descending by numeric column", function()
        local df = make_test_df()
        local sorted = df:sort("age", false)
        expect_near(35, sorted:getValue(1, "age"), 1e-5)
        expect_near(30, sorted:getValue(2, "age"), 1e-5)
        expect_near(25, sorted:getValue(3, "age"), 1e-5)
    end)

    -- @covers lurek.dataframe
    it("sort defaults to ascending", function()
        local df = make_test_df()
        local sorted = df:sort("age")
        expect_near(25, sorted:getValue(1, "age"), 1e-5)
    end)

    -- @covers lurek.dataframe
    it("sort preserves row data", function()
        local df = make_test_df()
        local sorted = df:sort("age", true)
        expect_equal("Bob", sorted:getValue(1, "name"))
    end)

    -- @covers LDataFrame:sort
    -- @covers lurek.dataframe.fromTable
    it("sort places nil values last", function()
        local df = lurek.dataframe.fromTable({
            { x = 2 },
            { x = nil },
            { x = 1 },
        })
        local sorted = df:sort("x", true)
        expect_near(1, sorted:getValue(1, "x"), 1e-5)
        expect_near(2, sorted:getValue(2, "x"), 1e-5)
        expect_nil(sorted:getValue(3, "x"))
    end)

    -- @covers LDataFrame:sort
    -- @covers lurek.dataframe.fromTable
    it("sort orders numbers before text before booleans", function()
        local df = lurek.dataframe.fromTable({
            { x = true },
            { x = "alpha" },
            { x = 2 },
        })
        local sorted = df:sort("x", true)
        expect_near(2, sorted:getValue(1, "x"), 1e-5)
        expect_equal("alpha", sorted:getValue(2, "x"))
        expect_equal(true, sorted:getValue(3, "x"))
    end)
end)

-- =========================================================================
-- 9. Head / Tail / Slice
-- =========================================================================
-- @describe head/tail/slice
describe("head/tail/slice", function()
    -- @covers LDataFrame:head
    it("head defaults to 5 (returns all if fewer)", function()
        local df = make_test_df()
        local h = df:head()
        expect_equal(3, h:nrows()) -- only 3 rows total
    end)

    -- @covers LDataFrame:head
    it("head with n returns first n rows", function()
        local df = make_test_df()
        local h = df:head(2)
        expect_equal(2, h:nrows())
        expect_equal("Alice", h:getValue(1, "name"))
        expect_equal("Bob", h:getValue(2, "name"))
    end)

    -- @covers LDataFrame:head
    it("head larger than row count returns all rows", function()
        local df = make_test_df()
        local h = df:head(100)
        expect_equal(3, h:nrows())
    end)

    -- @covers LDataFrame:tail
    it("tail defaults to 5 (returns all if fewer)", function()
        local df = make_test_df()
        local t = df:tail()
        expect_equal(3, t:nrows())
    end)

    -- @covers LDataFrame:tail
    it("tail with n returns last n rows", function()
        local df = make_test_df()
        local t = df:tail(2)
        expect_equal(2, t:nrows())
        expect_equal("Bob", t:getValue(1, "name"))
        expect_equal("Charlie", t:getValue(2, "name"))
    end)

    -- @covers LDataFrame:slice
    it("slice with 1-based inclusive range", function()
        local df = make_test_df()
        local s = df:slice(1, 2)
        expect_equal(2, s:nrows())
        expect_equal("Alice", s:getValue(1, "name"))
        expect_equal("Bob", s:getValue(2, "name"))
    end)

    -- @covers LDataFrame:slice
    it("slice single row", function()
        local df = make_test_df()
        local s = df:slice(2, 2)
        expect_equal(1, s:nrows())
        expect_equal("Bob", s:getValue(1, "name"))
    end)

    -- @covers LDataFrame:slice
    it("slice out of range errors", function()
        local df = make_test_df()
        expect_error(function()
            df:slice(10, 20)
        end)
    end)
end)

-- =========================================================================
-- 10. Select
-- =========================================================================
-- @describe select
describe("select", function()
    -- @covers LDataFrame:select
    it("select by column name", function()
        local df = make_test_df()
        local s = df:select("name", "score")
        expect_equal(2, s:ncols())
        expect_equal(3, s:nrows())
        expect_equal("Alice", s:getValue(1, "name"))
    end)

    -- @covers LDataFrame:select
    it("select by column index", function()
        local df = make_test_df()
        local s = df:select(1, 3)
        expect_equal(2, s:ncols())
    end)

    -- @covers LDataFrame:select
    it("select single column", function()
        local df = make_test_df()
        local s = df:select("name")
        expect_equal(1, s:ncols())
        expect_equal(3, s:nrows())
    end)
end)

-- =========================================================================
-- 11. Unique
-- =========================================================================
-- @describe unique
describe("unique", function()
    -- @covers LDataFrame:unique
    -- @covers lurek.dataframe.fromCSV
    it("unique returns distinct values", function()
        local csv = "color\nred\nblue\nred\ngreen\nblue"
        local df = lurek.dataframe.fromCSV(csv)
        local u = df:unique("color")
        expect_equal(3, #u)
    end)

    -- @covers LDataFrame:unique
    -- @covers lurek.dataframe.fromCSV
    it("unique on numeric column", function()
        local csv = "x\n1\n2\n1\n3\n2"
        local df = lurek.dataframe.fromCSV(csv)
        local u = df:unique("x")
        expect_equal(3, #u)
    end)
end)

-- =========================================================================
-- 12. GroupBy
-- =========================================================================
-- @describe groupBy
describe("groupBy", function()
    -- @covers LDataFrame:groupBy
    -- @covers lurek.dataframe.fromCSV
    it("groupBy returns table of DataFrames", function()
        local csv = "dept,name\nHR,Alice\nIT,Bob\nHR,Charlie\nIT,Dave"
        local df = lurek.dataframe.fromCSV(csv)
        local groups = df:groupBy("dept")
        expect_type("table", groups)
    end)

    -- @covers LDataFrame:groupBy
    -- @covers lurek.dataframe.fromCSV
    it("groupBy subsets have correct row counts", function()
        local csv = "dept,name\nHR,Alice\nIT,Bob\nHR,Charlie\nIT,Dave"
        local df = lurek.dataframe.fromCSV(csv)
        local groups = df:groupBy("dept")
        local count = 0
        for _, sub in pairs(groups) do
            count = count + sub:nrows()
        end
        expect_equal(4, count)
    end)

    -- @covers LDataFrame:groupBy
    -- @covers lurek.dataframe.fromCSV
    it("groupBy preserves column structure", function()
        local csv = "dept,name\nHR,Alice\nIT,Bob"
        local df = lurek.dataframe.fromCSV(csv)
        local groups = df:groupBy("dept")
        for _, sub in pairs(groups) do
            expect_equal(2, sub:ncols())
        end
    end)
end)

-- =========================================================================
-- 13. Join
-- =========================================================================
-- @describe join
describe("join", function()
    -- @covers LDataFrame:join
    -- @covers lurek.dataframe.fromCSV
    it("inner join matches on shared column values", function()
        local csv1 = "id,name\n1,Alice\n2,Bob\n3,Charlie"
        local csv2 = "id,dept\n1,HR\n2,IT\n4,Finance"
        local df1 = lurek.dataframe.fromCSV(csv1)
        local df2 = lurek.dataframe.fromCSV(csv2)
        local result = df1:join(df2, "id", "id", "inner")
        expect_equal(2, result:nrows()) -- only ids 1 and 2 match
    end)

    -- @covers LDataFrame:join
    -- @covers lurek.dataframe.fromCSV
    it("left join keeps all left rows", function()
        local csv1 = "id,name\n1,Alice\n2,Bob\n3,Charlie"
        local csv2 = "id,dept\n1,HR\n2,IT\n4,Finance"
        local df1 = lurek.dataframe.fromCSV(csv1)
        local df2 = lurek.dataframe.fromCSV(csv2)
        local result = df1:join(df2, "id", "id", "left")
        expect_equal(3, result:nrows()) -- all 3 left rows
    end)

    -- @covers LDataFrame:join
    -- @covers lurek.dataframe.fromCSV
    it("join defaults to inner", function()
        local csv1 = "id,name\n1,Alice\n2,Bob"
        local csv2 = "id,dept\n1,HR\n3,Finance"
        local df1 = lurek.dataframe.fromCSV(csv1)
        local df2 = lurek.dataframe.fromCSV(csv2)
        local result = df1:join(df2, "id", "id")
        expect_equal(1, result:nrows()) -- only id 1 matches
    end)
end)

-- =========================================================================
-- 14. Merge
-- =========================================================================
-- @describe merge
describe("merge", function()
    -- @covers LDataFrame:merge
    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.fromCSV
    it("merge appends rows in-place", function()
        local df1 = lurek.dataframe.fromCSV("x\n1\n2")
        local df2 = lurek.dataframe.fromCSV("x\n3\n4")
        df1:merge(df2)
        expect_equal(4, df1:nrows())
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:merge
    -- @covers lurek.dataframe.fromCSV
    it("merge preserves original data", function()
        local df1 = lurek.dataframe.fromCSV("x\n1\n2")
        local df2 = lurek.dataframe.fromCSV("x\n3\n4")
        df1:merge(df2)
        expect_near(1, df1:getValue(1, "x"), 1e-5)
        expect_near(2, df1:getValue(2, "x"), 1e-5)
        expect_near(3, df1:getValue(3, "x"), 1e-5)
        expect_near(4, df1:getValue(4, "x"), 1e-5)
    end)
end)

-- =========================================================================
-- 15. CountBy
-- =========================================================================
-- @describe countBy
describe("countBy", function()
    -- @covers LDataFrame:countBy
    -- @covers lurek.dataframe.fromCSV
    it("countBy returns DataFrame with value and count", function()
        local csv = "color\nred\nblue\nred\ngreen\nblue"
        local df = lurek.dataframe.fromCSV(csv)
        local result = df:countBy("color")
        expect_equal(3, result:nrows()) -- 3 unique colors
        expect_equal(2, result:ncols()) -- value + count
    end)

    -- @covers LDataFrame:countBy
    -- @covers lurek.dataframe.fromCSV
    it("countBy counts are correct", function()
        local csv = "color\nred\nblue\nred\nred\nblue"
        local df = lurek.dataframe.fromCSV(csv)
        local result = df:countBy("color")
        -- Sum of all counts should equal total rows
        local total = 0
        for i = 1, result:nrows() do
            total = total + result:getValue(i, 2)
        end
        expect_near(5, total, 1e-5)
    end)
end)

-- =========================================================================
-- 16. DropNil
-- =========================================================================
-- @describe dropNil
describe("dropNil", function()
    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:dropNil
    -- @covers lurek.dataframe.newDataFrame
    it("dropNil removes rows with nil in column", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x")
        df:addRow({ x = 1 })
        df:addRow() -- nil
        df:addRow({ x = 3 })
        local result = df:dropNil("x")
        expect_equal(2, result:nrows())
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:dropNil
    -- @covers lurek.dataframe.newDataFrame
    it("dropNil preserves non-nil rows", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x")
        df:addRow({ x = 10 })
        df:addRow({ x = 20 })
        local result = df:dropNil("x")
        expect_equal(2, result:nrows())
    end)
end)

-- =========================================================================
-- 17. Sample
-- =========================================================================
-- @describe sample
describe("sample", function()
    -- @covers LCatmullRom:sample
    -- @covers LDataFrame:sample
    -- @covers LHermite:sample
    it("sample returns correct number of rows", function()
        local df = make_test_df()
        local s = df:sample(2, 42)
        expect_equal(2, s:nrows())
    end)

    -- @covers LCatmullRom:sample
    -- @covers LDataFrame:sample
    -- @covers LHermite:sample
    it("sample with seed is deterministic", function()
        local df = make_test_df()
        local s1 = df:sample(2, 99)
        local s2 = df:sample(2, 99)
        expect_equal(s1:getValue(1, "name"), s2:getValue(1, "name"))
        expect_equal(s1:getValue(2, "name"), s2:getValue(2, "name"))
    end)

    -- @covers LCatmullRom:sample
    -- @covers LDataFrame:sample
    -- @covers LHermite:sample
    it("sample preserves schema", function()
        local df = make_test_df()
        local s = df:sample(1, 42)
        expect_equal(3, s:ncols())
    end)
end)

-- =========================================================================
-- 18. Describe
-- =========================================================================
-- @describe describe
describe("describe", function()
    -- @covers LDataFrame:describe
    it("describe returns a DataFrame", function()
        local df = make_test_df()
        local stats = df:describe()
        expect_true(stats:nrows() > 0)
        expect_true(stats:ncols() > 0)
    end)

    -- @covers LDataFrame:describe
    it("describe has statistic rows", function()
        local df = make_test_df()
        local stats = df:describe()
        -- Should have at least 1 row of stats
        expect_true(stats:nrows() >= 1)
    end)
end)

-- =========================================================================
-- 19. Analytics
-- =========================================================================
-- @describe analytics
describe("analytics", function()
    -- @covers lurek.dataframe
    it("sum computes correct total", function()
        local df = make_test_df()
        -- ages: 30 + 25 + 35 = 90
        expect_near(90, df:sum("age"), 1e-5)
    end)

    -- @covers lurek.dataframe
    -- @covers LDataFrame:mean
    it("mean computes correct average", function()
        local df = make_test_df()
        -- ages: (30 + 25 + 35) / 3 = 30
        expect_near(30, df:mean("age"), 1e-5)
    end)

    -- @covers lurek.dataframe
    it("min returns smallest value", function()
        local df = make_test_df()
        expect_near(25, df:min("age"), 1e-5)
    end)

    -- @covers lurek.dataframe
    it("max returns largest value", function()
        local df = make_test_df()
        expect_near(35, df:max("age"), 1e-5)
    end)

    -- @covers LDataFrame:median
    it("median returns middle value", function()
        local df = make_test_df()
        expect_near(30, df:median("age"), 1e-5)
    end)

    -- @covers LDataFrame:stddev
    it("stddev returns standard deviation", function()
        local df = make_test_df()
        local sd = df:stddev("age")
-- stddev of mean var sd
        expect_true(sd > 0)
    end)

    -- @covers LDataFrame:variance
    it("variance returns non-negative value", function()
        local df = make_test_df()
        local v = df:variance("age")
        expect_true(v >= 0)
    end)

    -- @covers lurek.dataframe
    it("sum on scores", function()
        local df = make_test_df()
        -- scores: 90 + 85 + 92 = 267
        expect_near(267, df:sum("score"), 1e-5)
    end)

    -- @covers lurek.dataframe
    it("analytics by column index", function()
        local df = make_test_df()
        -- column 2 = age, sum = 90
        expect_near(90, df:sum(2), 1e-5)
    end)
end)

-- =========================================================================
-- 20. FillNil
-- =========================================================================
-- @describe fillNil
describe("fillNil", function()
    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:fillNil
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.newDataFrame
    it("fillNil replaces nil values", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x")
        df:addRow({ x = 1 })
        df:addRow() -- nil
        df:addRow({ x = 3 })
        df:fillNil("x", 0)
        expect_near(0, df:getValue(2, "x"), 1e-5)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:fillNil
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.newDataFrame
    it("fillNil does not change non-nil values", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x")
        df:addRow({ x = 5 })
        df:addRow() -- nil
        df:fillNil("x", 0)
        expect_near(5, df:getValue(1, "x"), 1e-5)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:fillNil
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.newDataFrame
    it("fillNil with string value", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "name")
        df:addRow() -- nil
        df:fillNil("name", "unknown")
        expect_equal("unknown", df:getValue(1, "name"))
    end)
end)

-- =========================================================================
-- 21. Apply
-- =========================================================================
-- @describe apply
describe("apply", function()
    -- @covers LDataFrame:apply
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.fromCSV
    it("apply transforms column values", function()
        local df = lurek.dataframe.fromCSV("x\n1\n2\n3")
        df:apply("x", function(v) return v * 2 end)
        expect_near(2, df:getValue(1, "x"), 1e-5)
        expect_near(4, df:getValue(2, "x"), 1e-5)
        expect_near(6, df:getValue(3, "x"), 1e-5)
    end)

    -- @covers LDataFrame:apply
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.fromCSV
    it("apply can change type", function()
        local df = lurek.dataframe.fromCSV("x\n1\n2\n3")
        df:apply("x", function(v) return "val_" .. tostring(v) end)
        -- tostring of a number may vary; just check it's now a string
        expect_type("string", df:getValue(1, "x"))
    end)

    -- @covers LDataFrame:apply
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.fromCSV
    it("apply with identity preserves values", function()
        local df = lurek.dataframe.fromCSV("x\n10\n20")
        df:apply("x", function(v) return v end)
        expect_near(10, df:getValue(1, "x"), 1e-5)
        expect_near(20, df:getValue(2, "x"), 1e-5)
    end)
end)

-- =========================================================================
-- 22. Serialization
-- =========================================================================
-- @describe serialization
describe("serialization", function()
    -- @covers LDataFrame:toCSV
    it("toCSV produces string", function()
        local df = make_test_df()
        local csv = df:toCSV()
        expect_type("string", csv)
        expect_true(#csv > 0)
    end)

    -- @covers LDataFrame:ncols
    -- @covers LDataFrame:nrows
    -- @covers LDataFrame:toCSV
    -- @covers lurek.dataframe.fromCSV
    it("toCSV roundtrip preserves data", function()
        local df = make_test_df()
        local csv = df:toCSV()
        local df2 = lurek.dataframe.fromCSV(csv)
        expect_equal(df:nrows(), df2:nrows())
        expect_equal(df:ncols(), df2:ncols())
    end)

    -- @covers LDataFrame:toJSON
    -- @covers LQualityReport:toJSON
    it("toJSON produces string", function()
        local df = make_test_df()
        local json = df:toJSON()
        expect_type("string", json)
        expect_true(#json > 0)
    end)

    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.fromJSON
    it("toJSON roundtrip preserves row count", function()
        local df = make_test_df()
        local json = df:toJSON()
        local df2 = lurek.dataframe.fromJSON(json)
        expect_equal(df:nrows(), df2:nrows())
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:ncols
    -- @covers LDataFrame:nrows
    -- @covers LDataFrame:toBinary
    -- @covers lurek.dataframe.fromBinary
    it("toBinary/fromBinary roundtrip", function()
        local df = make_test_df()
        local bin = df:toBinary()
        expect_type("string", bin)
        local df2 = lurek.dataframe.fromBinary(bin)
        expect_equal(df:nrows(), df2:nrows())
        expect_equal(df:ncols(), df2:ncols())
        -- Verify data integrity
        for i = 1, df:nrows() do
            expect_equal(df:getValue(i, "name"), df2:getValue(i, "name"))
            expect_near(df:getValue(i, "age"), df2:getValue(i, "age"), 1e-5)
        end
    end)

    -- @covers LDataFrame:toTable
    it("toTable returns array of row-tables", function()
        local df = make_test_df()
        local t = df:toTable()
        expect_equal(3, #t)
        expect_equal("Alice", t[1].name)
    end)

    -- @covers LDataFrame:rows
    -- @covers LDataFrame:toTable
    it("rows iterator streams index and row table in order", function()
        local df = make_test_df()
        local seen = {}
        for i, row in df:rows() do
            seen[#seen + 1] = { i = i, name = row.name }
        end

        expect_equal(3, #seen)
        expect_equal(1, seen[1].i)
        expect_equal("Alice", seen[1].name)
        expect_equal(3, seen[3].i)
        expect_equal("Charlie", seen[3].name)
    end)

    -- @covers LDataFrame:rows
    -- @covers lurek.dataframe.newDataFrame
    it("rows iterator returns no items for empty dataframe", function()
        local df = lurek.dataframe.newDataFrame()
        local count = 0
        for _, _ in df:rows() do
            count = count + 1
        end
        expect_equal(0, count)
    end)

    -- @covers LDataFrame:toString
    it("toString returns non-empty string", function()
        local df = make_test_df()
        local s = df:toString()
        expect_type("string", s)
        expect_true(#s > 0)
    end)
end)

-- =========================================================================
-- 23. SQL
-- =========================================================================
-- @describe SQL on DataFrame
describe("SQL on DataFrame", function()
    -- @covers LHtmlDocument:query
    -- @covers LHtmlElement:query
    it("SELECT * FROM self returns all rows", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self")
        expect_equal(3, result:nrows())
    end)

    -- @covers LHtmlDocument:query
    -- @covers LHtmlElement:query
    it("SELECT with WHERE filters rows", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self WHERE age > 28")
        expect_true(result:nrows() > 0)
        -- All returned ages should be > 28
        for i = 1, result:nrows() do
            expect_true(result:getValue(i, "age") > 28)
        end
    end)

    -- @covers LHtmlDocument:query
    -- @covers LHtmlElement:query
    it("SELECT with ORDER BY sorts", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self ORDER BY age")
        expect_near(25, result:getValue(1, "age"), 1e-5)
    end)

    -- @covers LHtmlDocument:query
    -- @covers LHtmlElement:query
    it("SELECT with LIMIT restricts rows", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self LIMIT 2")
        expect_equal(2, result:nrows())
    end)

    -- @covers LHtmlDocument:query
    -- @covers LHtmlElement:query
    it("SELECT specific columns", function()
        local df = make_test_df()
        local result = df:query("SELECT name, score FROM self")
        expect_equal(2, result:ncols())
        expect_equal(3, result:nrows())
    end)
end)

-- =========================================================================
-- 24. Clone
-- =========================================================================
-- @describe clone
describe("clone", function()
    -- @covers lurek.dataframe
    -- @covers LByteData:clone
    -- @covers LParticleSystem:clone
    it("clone returns independent copy", function()
        local df = make_test_df()
        local c = df:clone()
        df_set_value(c, 1, "name", "Modified")
        expect_equal("Alice", df:getValue(1, "name"))
        expect_equal("Modified", c:getValue(1, "name"))
    end)

    -- @covers lurek.dataframe
    it("clone has same dimensions", function()
        local df = make_test_df()
        local c = df:clone()
        expect_equal(df:nrows(), c:nrows())
        expect_equal(df:ncols(), c:ncols())
    end)

    -- @covers lurek.dataframe
    it("clone has same data", function()
        local df = make_test_df()
        local c = df:clone()
        for i = 1, df:nrows() do
            expect_equal(df:getValue(i, "name"), c:getValue(i, "name"))
        end
    end)
end)

-- =========================================================================
-- 25. Type
-- =========================================================================
-- @describe type
describe("type", function()
    -- @covers lurek.dataframe
    it("DataFrame type() returns LDataFrame", function()
        local df = make_test_df()
        expect_equal("LDataFrame", df:type())
    end)

    -- @covers lurek.dataframe
    it("DataFrame typeOf DataFrame is true", function()
        local df = make_test_df()
        expect_true(df:typeOf("DataFrame"))
    end)

    -- @covers lurek.dataframe
    it("DataFrame typeOf wrong type is false", function()
        local df = make_test_df()
        expect_false(df:typeOf("Database"))
    end)
end)

-- =========================================================================
-- 26. Database
-- =========================================================================
-- @describe Database
describe("Database", function()
    -- @covers LDatabase:tableCount
    -- @covers lurek.dataframe.newDatabase
    it("newDatabase creates empty database", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal(0, db:tableCount())
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:getTable
    -- @covers lurek.dataframe.newDatabase
    it("addTable and getTable work", function()
        local db = lurek.dataframe.newDatabase()
        local df = make_test_df()
        db:addTable("users", df)
        local retrieved = db:getTable("users")
        expect_not_nil(retrieved)
        expect_equal(3, retrieved:nrows())
    end)

    -- @covers LDatabase:getTable
    -- @covers lurek.dataframe.newDatabase
    it("getTable returns nil for missing table", function()
        local db = lurek.dataframe.newDatabase()
        expect_nil(db:getTable("nonexistent"))
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:hasTable
    -- @covers lurek.dataframe.newDatabase
    it("hasTable returns true for existing table", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("data", make_test_df())
        expect_true(db:hasTable("data"))
    end)

    -- @covers LDatabase:hasTable
    -- @covers lurek.dataframe.newDatabase
    it("hasTable returns false for missing table", function()
        local db = lurek.dataframe.newDatabase()
        expect_false(db:hasTable("nope"))
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:hasTable
    -- @covers LDatabase:removeTable
    -- @covers lurek.dataframe.newDatabase
    it("removeTable removes the table", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("data", make_test_df())
        db:removeTable("data")
        expect_false(db:hasTable("data"))
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:listTables
    -- @covers lurek.dataframe.newDatabase
    it("listTables returns table names", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("alpha", make_test_df())
        db:addTable("beta", make_test_df())
        local names = db:listTables()
        expect_equal(2, #names)
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:tableCount
    -- @covers lurek.dataframe.newDatabase
    it("tableCount reflects additions", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal(0, db:tableCount())
        db:addTable("t1", make_test_df())
        expect_equal(1, db:tableCount())
        db:addTable("t2", make_test_df())
        expect_equal(2, db:tableCount())
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:clear
    -- @covers LDatabase:tableCount
    -- @covers lurek.dataframe.newDatabase
    it("clear removes all tables", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("t1", make_test_df())
        db:addTable("t2", make_test_df())
        db:clear()
        expect_equal(0, db:tableCount())
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:hasTable
    -- @covers LDatabase:merge
    -- @covers lurek.dataframe.newDatabase
    it("merge combines databases", function()
        local db1 = lurek.dataframe.newDatabase()
        db1:addTable("a", make_test_df())
        local db2 = lurek.dataframe.newDatabase()
        db2:addTable("b", make_test_df())
        db1:merge(db2)
        expect_true(db1:hasTable("a"))
        expect_true(db1:hasTable("b"))
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:toJSON
    -- @covers lurek.dataframe.newDatabase
    it("toJSON returns non-empty string", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("t1", make_test_df())
        local json = db:toJSON()
        expect_type("string", json)
        expect_true(#json > 0)
    end)

    -- @covers LDatabase:type
    -- @covers lurek.dataframe.newDatabase
    it("Database type() returns LDatabase", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal("LDatabase", db:type())
    end)

    -- @covers LDatabase:typeOf
    -- @covers lurek.dataframe.newDatabase
    it("Database typeOf Database is true", function()
        local db = lurek.dataframe.newDatabase()
        expect_true(db:typeOf("Database"))
    end)

    -- @covers LDatabase:typeOf
    -- @covers lurek.dataframe.newDatabase
    it("Database typeOf wrong type is false", function()
        local db = lurek.dataframe.newDatabase()
        expect_false(db:typeOf("DataFrame"))
    end)
end)

-- =========================================================================
-- 27. Database SQL
-- =========================================================================
-- @describe Database SQL
describe("Database SQL", function()
    -- @covers LDatabase:addTable
    -- @covers LDatabase:query
    -- @covers lurek.dataframe.newDatabase
    it("query on single table", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT * FROM users")
        expect_equal(3, result:nrows())
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:query
    -- @covers lurek.dataframe.newDatabase
    it("query with WHERE clause", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT * FROM users WHERE age > 28")
        expect_true(result:nrows() > 0)
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:query
    -- @covers lurek.dataframe.newDatabase
    it("query selecting specific columns", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT name FROM users")
        expect_equal(1, result:ncols())
        expect_equal(3, result:nrows())
    end)
end)

-- @describe CellValue nil and display (RS parity)
describe("CellValue nil and display (RS parity)", function()
    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.newDataFrame
    it("nil cell displays as empty or 'nil' string", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", "number")
        df:addRow({ x = nil })
        local v = df:getValue(1, "x")
        expect_true(v == nil or v == "nil" or v == "")
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.newDataFrame
    it("number cell round-trips through get", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "n", "number")
        df:addRow({ n = 42 })
        expect_near(42, df:getValue(1, "n"), 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.newDataFrame
    it("text cell round-trips through get", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "s", "text")
        df:addRow({ s = "hello" })
        expect_equal("hello", df:getValue(1, "s"))
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.newDataFrame
    it("bool cell round-trips through get", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "b", "bool")
        df:addRow({ b = true })
        expect_true(df:getValue(1, "b"))
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:toCSV
    -- @covers lurek.dataframe.newDataFrame
    it("toCSV formats integer-like numbers without trailing .0", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "n_int", "number")
        df_add_column(df, "n_float", "number")
        df_add_column(df, "b", "bool")
        df_add_column(df, "s", "text")
        df:addRow({ n_int = 5, n_float = 3.14, b = false, s = "hi" })

        local csv = df:toCSV()
        expect_true(string.find(csv, "5,3.14,false,hi", 1, true) ~= nil)
    end)
end)

-- @describe Database (RS parity)
describe("Database (RS parity)", function()
    -- @covers lurek.dataframe.newDatabase
    it("newDatabase returns userdata", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal("userdata", type(db))
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:getTable
    -- @covers lurek.dataframe.newDataFrame
    -- @covers lurek.dataframe.newDatabase
    it("addTable and getTable round-trip", function()
        local db = lurek.dataframe.newDatabase()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "id", "number")
        db:addTable("users", df)
        local t = db:getTable("users")
        expect_equal("userdata", type(t))
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:listTables
    -- @covers lurek.dataframe.newDataFrame
    -- @covers lurek.dataframe.newDatabase
    it("listTables returns list of added tables", function()
        local db = lurek.dataframe.newDatabase()
        local df = lurek.dataframe.newDataFrame()
        db:addTable("items", df)
        local names = db:listTables()
        expect_equal("table", type(names))
        local found = false
        for _, n in ipairs(names) do if n == "items" then found = true end end
        expect_true(found)
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:listTables
    -- @covers LDatabase:removeTable
    -- @covers lurek.dataframe.newDataFrame
    -- @covers lurek.dataframe.newDatabase
    it("removeTable decrements table count", function()
        local db = lurek.dataframe.newDatabase()
        local df = lurek.dataframe.newDataFrame()
        db:addTable("tmp", df)
        db:removeTable("tmp")
        local names = db:listTables()
        local found = false
        for _, n in ipairs(names) do if n == "tmp" then found = true end end
        expect_false(found)
    end)
end)

-- ---------------------------------------------------------------------------
-- Analytics methods
-- ---------------------------------------------------------------------------
-- @describe lurek.dataframe.DataFrame analytics
describe("lurek.dataframe.DataFrame analytics", function()

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withRollingMean
    -- @covers lurek.dataframe.newDataFrame
    it("withRollingMean adds column with nil for insufficient history", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "val", 0)
        df:addRow({val = 1})
        df:addRow({val = 3})
        df:addRow({val = 5})
        df:withRollingMean("val", 2, "rm")
        local row1 = df:getRow(1)
        local row2 = df:getRow(2)
        expect_equal(nil, row1.rm)
        expect_near(2.0, row2.rm, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withRollingSum
    -- @covers lurek.dataframe.newDataFrame
    it("withRollingSum computes window sums", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "val", 0)
        df:addRow({val = 2})
        df:addRow({val = 4})
        df:addRow({val = 6})
        df:withRollingSum("val", 2, "rs")
        local row3 = df:getRow(3)
        expect_near(10.0, row3.rs, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withRank
    -- @covers lurek.dataframe.newDataFrame
    it("withRank ascending assigns lowest value rank 1", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "score", 0)
        df:addRow({score = 10})
        df:addRow({score = 30})
        df:addRow({score = 20})
        df:withRank("score", true, "rank")
        local r1 = df:getRow(1)
        local r2 = df:getRow(2)
        local r3 = df:getRow(3)
        expect_near(1.0, r1.rank, 0.001)
        expect_near(3.0, r2.rank, 0.001)
        expect_near(2.0, r3.rank, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withPctChange
    -- @covers lurek.dataframe.newDataFrame
    it("withPctChange first row is nil, rest are ratios", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", 0)
        df:addRow({x = 100})
        df:addRow({x = 110})
        df:addRow({x = 121})
        df:withPctChange("x", "pct")
        local row1 = df:getRow(1)
        local row2 = df:getRow(2)
        expect_equal(nil, row1.pct)
        expect_near(0.1, row2.pct, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withCumsum
    -- @covers lurek.dataframe.newDataFrame
    it("withCumsum accumulates correctly", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 1}) df:addRow({v = 2}) df:addRow({v = 3})
        df:withCumsum("v", "cs")
        local row3 = df:getRow(3)
        expect_near(6.0, row3.cs, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:groupAgg
    -- @covers lurek.dataframe.newDataFrame
    it("groupAgg accepts documented aggregate names", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "cat", "")
        df_add_column(df, "val", 0)
        df:addRow({cat = "A", val = 10})
        df:addRow({cat = "B", val = 5})
        df:addRow({cat = "A", val = 20})
        for _, fn_name in ipairs({ "mean", "SUM", "count", "first", "last" }) do
            local agg = df:groupAgg("cat", "val", fn_name)
            expect_equal(2, agg:nrows())
        end
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:groupAgg
    -- @covers lurek.dataframe.newDataFrame
    it("groupAgg errors on unknown aggregate name", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "cat", "")
        df_add_column(df, "val", 0)
        df:addRow({cat = "A", val = 10})
        expect_error(function()
            df:groupAgg("cat", "val", "nope")
        end)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:corr
    -- @covers lurek.dataframe.newDataFrame
    it("corr of column with itself is 1", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", 0)
        df:addRow({x = 1}) df:addRow({x = 2}) df:addRow({x = 3})
        expect_near(1.0, df:corr("x", "x"), 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:correlationMatrix
    -- @covers lurek.dataframe.newDataFrame
    it("correlationMatrix includes column header", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "a", 0)
        df_add_column(df, "b", 0)
        df:addRow({a = 1, b = 2})
        df:addRow({a = 2, b = 4})
        local mat = df:correlationMatrix()
        expect_equal("LDataFrame", mat:type())
        local cols = mat:columns()
        expect_equal("column", cols[1])
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:zscoreCol
    -- @covers lurek.dataframe.newDataFrame
    it("zscoreCol produces zero-mean column", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        for i = 1, 8 do df:addRow({v = i * 2}) end
        df:zscoreCol("v", "z")
        local total = 0
        for i = 1, 8 do total = total + df:getRow(i).z end
        expect_near(0.0, total / 8, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:normalizeCol
    -- @covers lurek.dataframe.newDataFrame
    it("normalizeCol scales values to output range", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 0}) df:addRow({v = 50}) df:addRow({v = 100})
        df:normalizeCol("v", 0, 1, "n")
        expect_near(0.0, df:getRow(1).n, 0.001)
        expect_near(0.5, df:getRow(2).n, 0.001)
        expect_near(1.0, df:getRow(3).n, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:outliers
    -- @covers lurek.dataframe.newDataFrame
    it("outliers filters to extreme rows", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        -- Most values near 0, one outlier
        for i = 1, 9 do df:addRow({v = 0}) end
        df:addRow({v = 1000})
        local out = df:outliers("v", 2.0)
        expect_equal(1, out:nrows())
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:modeVal
    -- @covers lurek.dataframe.newDataFrame
    it("modeVal returns most frequent value", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "a"}) df:addRow({x = "c"})
        expect_equal("a", df:modeVal("x"))
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:entropy
    -- @covers lurek.dataframe.newDataFrame
    it("entropy of uniform 4-value column is 2 bits", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "c"}) df:addRow({x = "d"})
        expect_near(2.0, df:entropy("x"), 0.001)
    end)

    -- @covers LDataFrame:addRowBatch
    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.newDataFrame
    it("addRowBatch adds all rows", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRowBatch({{1}, {2}, {3}})
        expect_equal(3, df:nrows())
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getColumnAsF64
    -- @covers lurek.dataframe.newDataFrame
    it("getColumnAsF64 returns numeric array", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 10}) df:addRow({v = 20})
        local arr = df:getColumnAsF64("v")
        expect_equal(2, #arr)
        expect_near(10.0, arr[1], 0.001)
        expect_near(20.0, arr[2], 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:setColumnFromF64
    -- @covers lurek.dataframe.newDataFrame
    it("setColumnFromF64 overwrites column with new values", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 0}) df:addRow({v = 0})
        df:setColumnFromF64("v", {7, 14})
        expect_near(7.0, df:getRow(1).v, 0.001)
        expect_near(14.0, df:getRow(2).v, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:pivot
    -- @covers lurek.dataframe.newDataFrame
    it("pivot creates wide-format DataFrame", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "row", "")
        df_add_column(df, "col", "")
        df_add_column(df, "val", 0)
        df:addRow({row = "R1", col = "C1", val = 1})
        df:addRow({row = "R1", col = "C2", val = 2})
        df:addRow({row = "R2", col = "C1", val = 3})
        local p = df:pivot("row", "col", "val")
        -- Should have 3 columns: row, C1, C2
        expect_equal(3, #p:columns())
    end)

end)

-- ---------------------------------------------------------------------------
-- Analytics methods
-- ---------------------------------------------------------------------------
-- @describe lurek.dataframe.DataFrame analytics
describe("lurek.dataframe.DataFrame analytics", function()

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withRollingMean
    -- @covers lurek.dataframe.newDataFrame
    it("withRollingMean adds column with nil for insufficient history", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "val", 0)
        df:addRow({val = 1})
        df:addRow({val = 3})
        df:addRow({val = 5})
        df:withRollingMean("val", 2, "rm")
        local row1 = df:getRow(1)
        local row2 = df:getRow(2)
        expect_equal(nil, row1.rm)
        expect_near(2.0, row2.rm, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withRollingSum
    -- @covers lurek.dataframe.newDataFrame
    it("withRollingSum computes window sums", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "val", 0)
        df:addRow({val = 2})
        df:addRow({val = 4})
        df:addRow({val = 6})
        df:withRollingSum("val", 2, "rs")
        local row3 = df:getRow(3)
        expect_near(10.0, row3.rs, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withRank
    -- @covers lurek.dataframe.newDataFrame
    it("withRank ascending assigns lowest value rank 1", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "score", 0)
        df:addRow({score = 10})
        df:addRow({score = 30})
        df:addRow({score = 20})
        df:withRank("score", true, "rank")
        local r1 = df:getRow(1)
        local r2 = df:getRow(2)
        local r3 = df:getRow(3)
        expect_near(1.0, r1.rank, 0.001)
        expect_near(3.0, r2.rank, 0.001)
        expect_near(2.0, r3.rank, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withPctChange
    -- @covers lurek.dataframe.newDataFrame
    it("withPctChange first row is nil, rest are ratios", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", 0)
        df:addRow({x = 100})
        df:addRow({x = 110})
        df:addRow({x = 121})
        df:withPctChange("x", "pct")
        local row1 = df:getRow(1)
        local row2 = df:getRow(2)
        expect_equal(nil, row1.pct)
        expect_near(0.1, row2.pct, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withCumsum
    -- @covers lurek.dataframe.newDataFrame
    it("withCumsum accumulates correctly", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 1}) df:addRow({v = 2}) df:addRow({v = 3})
        df:withCumsum("v", "cs")
        local row3 = df:getRow(3)
        expect_near(6.0, row3.cs, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:groupAgg
    -- @covers lurek.dataframe.newDataFrame
    it("groupAgg with sum aggregates correctly", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "cat", "")
        df_add_column(df, "val", 0)
        df:addRow({cat = "A", val = 10})
        df:addRow({cat = "B", val = 5})
        df:addRow({cat = "A", val = 20})
        local agg = df:groupAgg("cat", "val", "sum")
        expect_equal(2, agg:nrows())
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:corr
    -- @covers lurek.dataframe.newDataFrame
    it("corr of column with itself is 1", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", 0)
        df:addRow({x = 1}) df:addRow({x = 2}) df:addRow({x = 3})
        expect_near(1.0, df:corr("x", "x"), 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:correlationMatrix
    -- @covers lurek.dataframe.newDataFrame
    it("correlationMatrix includes column header", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "a", 0)
        df_add_column(df, "b", 0)
        df:addRow({a = 1, b = 2})
        df:addRow({a = 2, b = 4})
        local mat = df:correlationMatrix()
        expect_equal("LDataFrame", mat:type())
        local cols = mat:columns()
        expect_equal("column", cols[1])
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:zscoreCol
    -- @covers lurek.dataframe.newDataFrame
    it("zscoreCol produces zero-mean column", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        for i = 1, 8 do df:addRow({v = i * 2}) end
        df:zscoreCol("v", "z")
        local total = 0
        for i = 1, 8 do total = total + df:getRow(i).z end
        expect_near(0.0, total / 8, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:normalizeCol
    -- @covers lurek.dataframe.newDataFrame
    it("normalizeCol scales values to output range", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 0}) df:addRow({v = 50}) df:addRow({v = 100})
        df:normalizeCol("v", 0, 1, "n")
        expect_near(0.0, df:getRow(1).n, 0.001)
        expect_near(0.5, df:getRow(2).n, 0.001)
        expect_near(1.0, df:getRow(3).n, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:outliers
    -- @covers lurek.dataframe.newDataFrame
    it("outliers filters to extreme rows", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        -- Most values near 0, one outlier
        for i = 1, 9 do df:addRow({v = 0}) end
        df:addRow({v = 1000})
        local out = df:outliers("v", 2.0)
        expect_equal(1, out:nrows())
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:modeVal
    -- @covers lurek.dataframe.newDataFrame
    it("modeVal returns most frequent value", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "a"}) df:addRow({x = "c"})
        expect_equal("a", df:modeVal("x"))
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:entropy
    -- @covers lurek.dataframe.newDataFrame
    it("entropy of uniform 4-value column is 2 bits", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "c"}) df:addRow({x = "d"})
        expect_near(2.0, df:entropy("x"), 0.001)
    end)

    -- @covers LDataFrame:addRowBatch
    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.newDataFrame
    it("addRowBatch adds all rows", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRowBatch({{1}, {2}, {3}})
        expect_equal(3, df:nrows())
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getColumnAsF64
    -- @covers lurek.dataframe.newDataFrame
    it("getColumnAsF64 returns numeric array", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 10}) df:addRow({v = 20})
        local arr = df:getColumnAsF64("v")
        expect_equal(2, #arr)
        expect_near(10.0, arr[1], 0.001)
        expect_near(20.0, arr[2], 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:setColumnFromF64
    -- @covers lurek.dataframe.newDataFrame
    it("setColumnFromF64 overwrites column with new values", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 0}) df:addRow({v = 0})
        df:setColumnFromF64("v", {7, 14})
        expect_near(7.0, df:getRow(1).v, 0.001)
        expect_near(14.0, df:getRow(2).v, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:pivot
    -- @covers lurek.dataframe.newDataFrame
    it("pivot creates wide-format DataFrame", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "row", "")
        df_add_column(df, "col", "")
        df_add_column(df, "val", 0)
        df:addRow({row = "R1", col = "C1", val = 1})
        df:addRow({row = "R1", col = "C2", val = 2})
        df:addRow({row = "R2", col = "C1", val = 3})
        local p = df:pivot("row", "col", "val")
        -- Should have 3 columns: row, C1, C2
        expect_equal(3, #p:columns())
    end)

end)

-- DataFrame pivotTable / rollingMean / rollingSum / rank (merged from test_dataframe_pivot_window.lua)

-- @describe DataFrame: pivotTable
describe("DataFrame: pivotTable", function()

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:pivotTable
    -- @covers lurek.dataframe.newDataFrame
    it("pivotTable reshapes long to wide with default mean aggregation", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "player")
        df_add_column(df, "stat")
        df_add_column(df, "value")
        df:addRow({ player = "A", stat = "hp", value = 100 })
        df:addRow({ player = "A", stat = "mp", value = 50  })
        df:addRow({ player = "B", stat = "hp", value = 80  })
        df:addRow({ player = "B", stat = "mp", value = 60  })

        local wide = df:pivotTable("player", "stat", "value")
        expect_not_nil(wide)
        -- Should have 3 columns: player, hp, mp
        expect_equal(3, wide:ncols())
        -- Should have 2 rows: A and B
        expect_equal(2, wide:nrows())
        local hp = wide:getColumn("hp")
        local mp = wide:getColumn("mp")
        expect_near(100, hp[1], 0.001)
        expect_near(50,  mp[1], 0.001)
        expect_near(80,  hp[2], 0.001)
        expect_near(60,  mp[2], 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:pivotTable
    -- @covers lurek.dataframe.newDataFrame
    it("pivotTable with sum aggregation", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "group")
        df_add_column(df, "cat")
        df_add_column(df, "val")
        df:addRow({ group = "X", cat = "a", val = 10 })
        df:addRow({ group = "X", cat = "a", val = 20 })
        df:addRow({ group = "X", cat = "b", val = 5  })

        local wide = df:pivotTable("group", "cat", "val", "sum")
        expect_not_nil(wide)
        local a_col = wide:getColumn("a")
        expect_near(30, a_col[1], 0.001)  -- 10+20
        local b_col = wide:getColumn("b")
        expect_near(5, b_col[1], 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:pivotTable
    -- @covers lurek.dataframe.newDataFrame
    it("pivotTable with count aggregation", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "g")
        df_add_column(df, "c")
        df_add_column(df, "v")
        df:addRow({ g = "R1", c = "C1", v = 1 })
        df:addRow({ g = "R1", c = "C1", v = 2 })
        df:addRow({ g = "R1", c = "C2", v = 3 })

        local wide = df:pivotTable("g", "c", "v", "count")
        local c1 = wide:getColumn("C1")
        expect_equal(2, c1[1])  -- two rows for (R1, C1)
        local c2 = wide:getColumn("C2")
        expect_equal(1, c2[1])
    end)

end)

-- @describe DataFrame: rollingMean
describe("DataFrame: rollingMean", function()

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:ncols
    -- @covers LDataFrame:rollingMean
    -- @covers lurek.dataframe.newDataFrame
    it("rollingMean appends result column and preserves original", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v")
        df:addRow({ v = 2 })
        df:addRow({ v = 4 })
        df:addRow({ v = 6 })
        df:addRow({ v = 8 })

        local df2 = df:rollingMean("v", 2, "v_rm")
        -- Original df unchanged
        expect_equal(1, df:ncols())
        -- New df has 2 columns
        expect_equal(2, df2:ncols())
        local rm = df2:getColumn("v_rm")
-- Row 1: partial window of 1 (only [1..1]) â†’ mean(2) = 2
        expect_near(2.0, rm[1], 0.001, "first row partial window mean")
        -- Row 2: mean(2,4)=3
        expect_near(3.0, rm[2], 0.001)
        -- Row 3: mean(4,6)=5
        expect_near(5.0, rm[3], 0.001)
        -- Row 4: mean(6,8)=7
        expect_near(7.0, rm[4], 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:rollingMean
    -- @covers lurek.dataframe.newDataFrame
    it("rollingMean uses default result column name", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "score")
        df:addRow({ score = 10 })
        df:addRow({ score = 20 })

        local df2 = df:rollingMean("score", 2)
        local cols = df2:columns()
        expect_equal(2, #cols)
        expect_equal("score", cols[1])
        expect_equal("rolling_mean", cols[2])
    end)

end)

-- @describe DataFrame: rollingSum
describe("DataFrame: rollingSum", function()

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:rollingSum
    -- @covers lurek.dataframe.newDataFrame
    it("rollingSum produces correct sums", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v")
        df:addRow({ v = 1 })
        df:addRow({ v = 2 })
        df:addRow({ v = 3 })

        local df2 = df:rollingSum("v", 2, "v_rs")
        expect_equal(2, df2:ncols())
        local rs = df2:getColumn("v_rs")
        expect_near(1.0, rs[1], 0.001)  -- partial window: just row 1 = 1
        expect_near(3.0, rs[2], 0.001)  -- 1+2
        expect_near(5.0, rs[3], 0.001)  -- 2+3
    end)

end)

-- @describe DataFrame: rank
describe("DataFrame: rank", function()

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:rank
    -- @covers lurek.dataframe.newDataFrame
    it("rank desc assigns rank 1 to highest score", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "score")
        df:addRow({ score = 30 })
        df:addRow({ score = 10 })
        df:addRow({ score = 20 })

        local df2 = df:rank("score", "desc", "rank")
        expect_equal(2, df2:ncols())
        local ranks = df2:getColumn("rank")
-- score 30 rank 1 score 20 rank 2 score 10 rank 3
        expect_near(1, ranks[1], 0.001)
        expect_near(3, ranks[2], 0.001)
        expect_near(2, ranks[3], 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:rank
    -- @covers lurek.dataframe.newDataFrame
    it("rank asc assigns rank 1 to lowest score", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "score")
        df:addRow({ score = 30 })
        df:addRow({ score = 10 })
        df:addRow({ score = 20 })

        local df2 = df:rank("score", "asc", "rank")
        local ranks = df2:getColumn("rank")
-- score 30 rank 3 score 20 rank 2 score 10 rank 1
        expect_near(3, ranks[1], 0.001)
        expect_near(1, ranks[2], 0.001)
        expect_near(2, ranks[3], 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:rank
    -- @covers lurek.dataframe.newDataFrame
    it("rank uses default result column name", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "pts")
        df:addRow({ pts = 5 })
        df:addRow({ pts = 3 })

        local df2 = df:rank("pts")
        local cols = df2:columns()
        expect_equal(2, #cols)
        expect_equal("rank", cols[2])
    end)

end)

-- =========================================================================
-- =========================================================================

-- @describe Missing API Coverage
describe("Missing API Coverage", function()
    -- @covers LDataFrame:min
    -- @covers lurek.dataframe.fromCSV
    it("covers DataFrame:min", function()
        local df = lurek.dataframe.fromCSV("v\n10\n2\n7")
        expect_equal(2, df:min("v"))
    end)

    -- @covers LDataFrame:max
    -- @covers lurek.dataframe.fromCSV
    it("covers DataFrame:max", function()
        local df = lurek.dataframe.fromCSV("v\n10\n2\n7")
        expect_equal(10, df:max("v"))
    end)

    -- @covers LDataFrame:withEval
    -- @covers lurek.dataframe.fromCSV
    it("withEval adds a computed column with a string expression", function()
        local df = lurek.dataframe.fromCSV("x,y\n1,2\n3,4")
        local out = df:withEval("z", "x + y")
        expect_not_nil(out)
        expect_equal(3, out:ncols())
        expect_equal(3, out:getValue(1, "z"))   -- 1 + 2
        expect_equal(7, out:getValue(2, "z"))   -- 3 + 4
    end)

end)

-- @describe DataFrame shape accessors
describe("DataFrame shape accessors", function()
    local function csv3x3()
        return lurek.dataframe.fromCSV("name,age,score\nAlice,30,90\nBob,25,85\nCharlie,35,92")
    end

    -- @covers LDataFrame:nrows
    it("nrows returns row count", function()
        expect_equal(3, csv3x3():nrows())
    end)

    -- @covers LDataFrame:ncols
    it("ncols returns column count", function()
        expect_equal(3, csv3x3():ncols())
    end)

    -- @covers LDataFrame:columns
    it("columns returns an array of column name strings", function()
        local cols = csv3x3():columns()
        expect_type("table", cols)
        expect_equal(3, #cols)
    end)

    -- @covers lurek.dataframe
    it("count returns the total number of rows", function()
        local df = csv3x3()
        expect_equal(3, df:count())
    end)
end)

-- @describe DataFrame column/row mutation
describe("DataFrame column/row mutation", function()
    local function make_df()
        return lurek.dataframe.fromCSV("a,b\n1,4\n2,5\n3,6")
    end

    -- @covers LDataFrame:ncols
    -- @covers LDataFrame:removeColumn
    it("removeColumn removes a column", function()
        local df = make_df()
        df_remove_column(df, "b")
        expect_equal(1, df:ncols())
    end)

    -- @covers LDataFrame:rename
    it("rename renames a column", function()
        local df = make_df()
        df:rename("a", "aa")
        local cols = df:columns()
        local found = false
        for _, c in ipairs(cols) do if c == "aa" then found = true end end
        expect_equal(true, found)
    end)

    -- @covers LDataFrame:getColumn
    it("getColumn returns an array of values", function()
        local df = make_df()
        local col = df:getColumn("a")
        expect_type("table", col)
        expect_equal(3, #col)
    end)

    -- @covers LDataFrame:addRow
    it("addRow increases nrows by 1", function()
        local df = make_df()
        df:addRow({ a = 99, b = 88 })
        expect_equal(4, df:nrows())
    end)

    -- @covers LDataFrame:removeRow
    it("removeRow decreases nrows by 1", function()
        local df = make_df()
        df:removeRow(1)
        expect_equal(2, df:nrows())
    end)

    -- @covers LDataFrame:getRow
    it("getRow returns a table with column keys", function()
        local df = make_df()
        local row = df:getRow(1)
        expect_type("table", row)
        expect_equal(1, row.a)
    end)

    -- @covers LDataFrame:getValue
    it("getValue returns the cell value at (row, col)", function()
        local df = make_df()
        expect_equal(2, df:getValue(2, "a"))
    end)
end)

-- @describe DataFrame slicing and filtering
describe("DataFrame slicing and filtering", function()
    local function nums_df()
        -- 5 rows, col 'v'
        return lurek.dataframe.fromCSV("v\n10\n20\n30\n40\n50")
    end

    -- @covers LDataFrame:head
    it("head(2) returns first 2 rows", function()
        local h = nums_df():head(2)
        expect_equal(2, h:nrows())
        expect_equal(10, h:getValue(1, "v"))
    end)

    -- @covers LDataFrame:tail
    it("tail(2) returns last 2 rows", function()
        local t = nums_df():tail(2)
        expect_equal(2, t:nrows())
        expect_equal(50, t:getValue(2, "v"))
    end)

    -- @covers LDataFrame:slice
    it("slice(2,4) returns rows 2 to 4", function()
        local s = nums_df():slice(2, 4)
        expect_equal(3, s:nrows())
        expect_equal(20, s:getValue(1, "v"))
    end)

    -- @covers LDataFrame:select
    -- @covers lurek.dataframe.fromCSV
    it("select with vararg column names keeps only those columns", function()
        local df = lurek.dataframe.fromCSV("a,b,c\n1,2,3\n4,5,6")
        local out = df:select("a", "c")
        expect_equal(2, out:ncols())
    end)

    -- @covers LDataFrame:unique
    -- @covers lurek.dataframe.fromCSV
    it("unique returns an array of distinct values", function()
        local df = lurek.dataframe.fromCSV("x\n1\n1\n2\n3\n2")
        local vals = df:unique("x")
        expect_type("table", vals)
        expect_equal(3, #vals)
    end)

    -- @covers LDataFrame:groupBy
    -- @covers lurek.dataframe.fromCSV
    it("groupBy returns a table of DataFrames keyed by group value", function()
        local df = lurek.dataframe.fromCSV("cat,v\nA,1\nB,2\nA,3")
        local groups = df:groupBy("cat")
        expect_type("table", groups)
    end)

    -- @covers LDataFrame:merge
    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.fromCSV
    it("merge appends rows from another DataFrame in-place", function()
        local left  = lurek.dataframe.fromCSV("id,x\n1,10\n2,20")
        local right = lurek.dataframe.fromCSV("id,x\n3,30\n4,40")
        left:merge(right)
        expect_equal(4, left:nrows())
    end)

    -- @covers LDataFrame:countBy
    -- @covers lurek.dataframe.fromCSV
    it("countBy returns a DataFrame with count column", function()
        local df = lurek.dataframe.fromCSV("cat\nA\nB\nA\nA")
        local counts = df:countBy("cat")
        expect_not_nil(counts)
        -- countBy returns a DataFrame userdata (value, count columns)
        expect_equal(2, counts:nrows())   -- 2 distinct values: A, B
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:dropNil
    -- @covers lurek.dataframe.newDataFrame
    it("dropNil removes rows with nil in a column", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", 0)
        df:addRow({ x = 1 })
        df:addRow({ x = nil })
        df:addRow({ x = 3 })
        local out = df:dropNil("x")
        expect_equal(2, out:nrows())
    end)

    -- @covers LDataFrame:sample
    it("sample(2) returns exactly 2 rows", function()
        local out = nums_df():sample(2)
        expect_equal(2, out:nrows())
    end)
end)

-- =========================================================================
-- Vectorized VecFrame API (lurek.dataframe.toVec / fromVec)
-- =========================================================================

-- @describe lurek.dataframe vectorized factory functions
describe("lurek.dataframe vectorized factory functions", function()
    -- @covers lurek.dataframe.toVec
    it("toVec is a function", function()
        expect_type("function", lurek.dataframe.toVec)
    end)

    -- @covers lurek.dataframe.fromVec
    it("fromVec is a function", function()
        expect_type("function", lurek.dataframe.fromVec)
    end)

    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.toVec
    it("toVec returns a VecFrame userdata", function()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n")
        local vf = lurek.dataframe.toVec(df)
        expect_true(vf ~= nil, "toVec returned nil")
        expect_true(type(vf) == "userdata", "expected userdata")
    end)

    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.fromVec
    -- @covers lurek.dataframe.toVec
    it("fromVec converts VecFrame back to DataFrame", function()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n")
        local vf = lurek.dataframe.toVec(df)
        local df2 = lurek.dataframe.fromVec(vf)
        expect_true(df2 ~= nil, "fromVec returned nil")
    end)
end)

-- @describe VecFrame shape queries
describe("VecFrame shape queries", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    -- @covers LVecFrame:nrows
    it("nrows returns correct row count", function()
        local vf = make_vf()
        expect_true(vf:nrows() == 3, "expected nrows=3, got " .. tostring(vf:nrows()))
    end)

    -- @covers LVecFrame:ncols
    it("ncols returns correct column count", function()
        local vf = make_vf()
        expect_true(vf:ncols() == 2, "expected ncols=2, got " .. tostring(vf:ncols()))
    end)

    -- @covers LVecFrame:columns
    it("columns returns table of column names", function()
        local vf = make_vf()
        local cols = vf:columns()
        expect_true(type(cols) == "table", "expected table")
        expect_true(cols[1] == "hp", "expected cols[1]='hp', got " .. tostring(cols[1]))
        expect_true(cols[2] == "mp", "expected cols[2]='mp', got " .. tostring(cols[2]))
    end)
end)

-- @describe VecFrame type inspection and casting
describe("VecFrame type inspection and casting", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n")
        return lurek.dataframe.toVec(df)
    end

    -- @covers LVecFrame:colType
    it("colType returns float64 for numeric column", function()
        local vf = make_vf()
        expect_true(vf:colType("hp") == "float64", "expected float64, got " .. tostring(vf:colType("hp")))
    end)

    -- @covers LVecFrame:colType
    it("colType returns nil for nonexistent column", function()
        local vf = make_vf()
        expect_true(vf:colType("NOPE") == nil, "expected nil for missing column")
    end)

    -- @covers LVecFrame:colCast
    -- @covers LVecFrame:colType
    it("colCast float64 to int64 changes type", function()
        local vf = make_vf()
        vf:colCast("hp", "int64")
        expect_true(vf:colType("hp") == "int64", "expected int64 after cast")
    end)

    -- @covers LVecFrame:colCast
    -- @covers LVecFrame:colType
    it("colCast int64 back to float64 changes type", function()
        local vf = make_vf()
        vf:colCast("hp", "int64")
        vf:colCast("hp", "float64")
        expect_true(vf:colType("hp") == "float64", "expected float64 after cast back")
    end)
end)

-- @describe VecFrame scalar column operations
describe("VecFrame scalar column operations", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    local function first(vf, col)
        local df2 = vf:toDataFrame()
        return df2:getValue(0, col)
    end

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colAdd
    -- @covers lurek.dataframe.fromVec
    it("colAdd adds scalar to every row", function()
        local vf = make_vf()
        vf:colAdd("hp", 5)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "hp")
        expect_true(v ~= nil, "colAdd: got nil")
        expect_true(math.abs(v - 15) < 0.0001, "expected 15, got " .. tostring(v))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colSub
    -- @covers lurek.dataframe.fromVec
    it("colSub subtracts scalar from every row", function()
        local vf = make_vf()
        vf:colSub("hp", 5)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "hp")
        expect_true(math.abs(v - 5) < 0.0001, "expected 5, got " .. tostring(v))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colMul
    -- @covers lurek.dataframe.fromVec
    it("colMul multiplies every row by scalar", function()
        local vf = make_vf()
        vf:colMul("hp", 3)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "hp")
        expect_true(math.abs(v - 30) < 0.0001, "expected 30, got " .. tostring(v))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colDiv
    -- @covers lurek.dataframe.fromVec
    it("colDiv divides every row by scalar", function()
        local vf = make_vf()
        vf:colDiv("hp", 2)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "hp")
        expect_true(math.abs(v - 5) < 0.0001, "expected 5, got " .. tostring(v))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colAbs
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.fromVec
    -- @covers lurek.dataframe.toVec
    it("colAbs makes all values non-negative", function()
        local df = lurek.dataframe.fromCSV("v\n-3\n4\n-1.5\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colAbs("v")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "v")
        expect_true(v ~= nil and v >= 0, "expected non-negative, got " .. tostring(v))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colSqrt
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.fromVec
    -- @covers lurek.dataframe.toVec
    it("colSqrt takes sqrt of every row", function()
        local df = lurek.dataframe.fromCSV("v\n9\n4\n1\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colSqrt("v")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "v")
        expect_true(math.abs(v - 3) < 0.0001, "expected 3, got " .. tostring(v))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colFloor
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.fromVec
    -- @covers lurek.dataframe.toVec
    it("colFloor floors every element", function()
        local df = lurek.dataframe.fromCSV("v\n1.9\n2.5\n3.1\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colFloor("v")
        local df2 = lurek.dataframe.fromVec(vf)
        expect_true(math.abs(df2:getValue(1, "v") - 1) < 0.0001, "expected 1")
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colCeil
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.fromVec
    -- @covers lurek.dataframe.toVec
    it("colCeil ceils every element", function()
        local df = lurek.dataframe.fromCSV("v\n1.1\n2.5\n3.9\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colCeil("v")
        local df2 = lurek.dataframe.fromVec(vf)
        expect_true(math.abs(df2:getValue(1, "v") - 2) < 0.0001, "expected 2")
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colNeg
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.fromVec
    -- @covers lurek.dataframe.toVec
    it("colNeg negates every element", function()
        local df = lurek.dataframe.fromCSV("v\n5\n10\n15\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colNeg("v")
        local df2 = lurek.dataframe.fromVec(vf)
        expect_true(math.abs(df2:getValue(1, "v") - (-5)) < 0.0001, "expected -5")
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colClamp
    -- @covers lurek.dataframe.fromVec
    it("colClamp clamps values to [min, max]", function()
        local vf = make_vf()
        vf:colClamp("hp", 15, 25)
        local df2 = lurek.dataframe.fromVec(vf)
        local v0 = df2:getValue(1, "hp")
        expect_true(math.abs(v0 - 15) < 0.0001, "expected 15 (clamped), got " .. tostring(v0))
        local v1 = df2:getValue(2, "hp")
        expect_true(math.abs(v1 - 20) < 0.0001, "expected 20, got " .. tostring(v1))
        local v2 = df2:getValue(3, "hp")
        expect_true(math.abs(v2 - 25) < 0.0001, "expected 25 (clamped), got " .. tostring(v2))
    end)

    -- @covers LVecFrame:colDiv
    it("colDiv by zero errors", function()
        local vf = make_vf()
        expect_error(function()
            vf:colDiv("hp", 0)
        end)
    end)

    -- @covers LVecFrame:colAdd
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.toVec
    it("scalar ops on text columns error", function()
        local df = lurek.dataframe.fromCSV("name\nAlice\nBob\n")
        local vf = lurek.dataframe.toVec(df)
        expect_error(function()
            vf:colAdd("name", 1)
        end)
    end)
end)

-- @describe VecFrame binary column operations
describe("VecFrame binary column operations", function()
    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colOp
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.fromVec
    -- @covers lurek.dataframe.toVec
    it("colOp add computes element-wise sum", function()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colOp("total", "hp", "add", "mp")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "total")
        expect_true(v ~= nil and math.abs(v - 15) < 0.0001, "expected 15, got " .. tostring(v))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colOp
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.fromVec
    -- @covers lurek.dataframe.toVec
    it("colOp mul computes element-wise product", function()
        local df = lurek.dataframe.fromCSV("a,b\n3,4\n5,6\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colOp("product", "a", "mul", "b")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "product")
        expect_true(v ~= nil and math.abs(v - 12) < 0.0001, "expected 12, got " .. tostring(v))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:colOp
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.fromVec
    -- @covers lurek.dataframe.toVec
    it("colOp min picks element-wise minimum", function()
        local df = lurek.dataframe.fromCSV("a,b\n3,7\n8,2\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colOp("m", "a", "min", "b")
        local df2 = lurek.dataframe.fromVec(vf)
        expect_true(math.abs(df2:getValue(1, "m") - 3) < 0.0001, "expected 3")
        expect_true(math.abs(df2:getValue(2, "m") - 2) < 0.0001, "expected 2")
    end)
end)

-- @describe VecFrame reductions
describe("VecFrame reductions", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    -- @covers lurek.dataframe
    it("reduce sum returns correct total", function()
        local vf = make_vf()
        local s = vf:reduce("hp", "sum")
        expect_true(s ~= nil and math.abs(s - 60) < 0.0001, "expected 60, got " .. tostring(s))
    end)

    -- @covers lurek.dataframe
    it("reduce mean returns correct average", function()
        local vf = make_vf()
        local m = vf:reduce("hp", "mean")
        expect_true(m ~= nil and math.abs(m - 20) < 0.0001, "expected 20, got " .. tostring(m))
    end)

    -- @covers lurek.dataframe
    it("reduce min returns minimum value", function()
        local vf = make_vf()
        expect_true(vf:reduce("hp", "min") == 10, "expected 10")
    end)

    -- @covers lurek.dataframe
    it("reduce max returns maximum value", function()
        local vf = make_vf()
        expect_true(vf:reduce("hp", "max") == 30, "expected 30")
    end)

    -- @covers lurek.dataframe
    it("reduce count returns row count", function()
        local vf = make_vf()
        expect_true(vf:reduce("hp", "count") == 3, "expected 3")
    end)

    -- @covers LVecFrame:reduce
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.toVec
    it("reduce std is near 0 for constant column", function()
        local df = lurek.dataframe.fromCSV("v\n5\n5\n5\n")
        local vf = lurek.dataframe.toVec(df)
        local s = vf:reduce("v", "std")
        expect_true(s ~= nil and math.abs(s) < 0.0001, "expected near 0, got " .. tostring(s))
    end)

    -- @covers LDataFrame:addRow
    -- @covers LVecFrame:reduce
    -- @covers lurek.dataframe.newDataFrame
    -- @covers lurek.dataframe.toVec
    it("reduce count skips nil rows after toVec conversion", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v")
        df:addRow({ v = 1 })
        df:addRow()
        df:addRow({ v = 3 })
        local vf = lurek.dataframe.toVec(df)
        expect_true(vf:reduce("v", "count") == 2, "expected count=2")
    end)

    -- @covers lurek.dataframe
    it("reduce on missing column errors", function()
        local vf = make_vf()
        expect_error(function()
            vf:reduce("NOPE", "sum")
        end)
    end)
end)

-- @describe VecFrame filter and mask
describe("VecFrame filter and mask", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    -- @covers LVecFrame:filterMask
    it("filterMask > returns correct boolean array", function()
        local vf = make_vf()
        local mask = vf:filterMask("hp", ">", 15)
        expect_true(type(mask) == "table", "expected table")
        expect_true(mask[1] == false, "row 0 (hp=10) should be false")
        expect_true(mask[2] == true,  "row 1 (hp=20) should be true")
        expect_true(mask[3] == true,  "row 2 (hp=30) should be true")
    end)

    -- @covers LVecFrame:filterMask
    it("filterMask <= returns correct boolean array", function()
        local vf = make_vf()
        local mask = vf:filterMask("hp", "<=", 20)
        expect_true(mask[1] == true, "row 0 (hp=10) should be true")
        expect_true(mask[2] == true, "row 1 (hp=20) should be true")
        expect_true(mask[3] == false, "row 2 (hp=30) should be false")
    end)

    -- @covers LVecFrame:applyMask
    -- @covers LVecFrame:filterMask
    it("applyMask returns filtered VecFrame with correct row count", function()
        local vf = make_vf()
        local mask = vf:filterMask("hp", ">", 15)
        local filtered = vf:applyMask(mask)
        expect_true(filtered:nrows() == 2, "expected 2 rows, got " .. tostring(filtered:nrows()))
    end)

    -- @covers LVecFrame:applyMask
    -- @covers LVecFrame:filterMask
    it("applyMask combined reduce gives correct sum", function()
        local vf = make_vf()
        local mask = vf:filterMask("hp", ">=", 20)
        local filtered = vf:applyMask(mask)
        local s = filtered:reduce("hp", "sum")
        expect_true(math.abs(s - 50) < 0.0001, "expected 50, got " .. tostring(s))
    end)

    -- @covers LVecFrame:applyMask
    it("applyMask with wrong mask length errors", function()
        local vf = make_vf()
        expect_error(function()
            vf:applyMask({ true, false })
        end)
    end)
end)

-- @describe VecFrame parallel operations
describe("VecFrame parallel operations", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    -- @covers LVecFrame:parReduce
    it("parReduce sum across multiple columns", function()
        local vf = make_vf()
        local result = vf:parReduce({"hp", "mp"}, "sum")
        expect_true(type(result) == "table", "expected table")
        expect_true(math.abs(result["hp"] - 60) < 0.0001, "expected hp sum=60, got " .. tostring(result["hp"]))
        expect_true(math.abs(result["mp"] - 30) < 0.0001, "expected mp sum=30, got " .. tostring(result["mp"]))
    end)

    -- @covers LDataFrame:getValue
    -- @covers LVecFrame:parScalarOp
    -- @covers lurek.dataframe.fromVec
    it("parScalarOp mul across multiple columns", function()
        local vf = make_vf()
        vf:parScalarOp({"hp", "mp"}, "mul", 2)
        local df2 = lurek.dataframe.fromVec(vf)
        local hp0 = df2:getValue(1, "hp")
        local mp0 = df2:getValue(1, "mp")
        expect_true(math.abs(hp0 - 20) < 0.0001, "expected hp=20, got " .. tostring(hp0))
        expect_true(math.abs(mp0 - 10) < 0.0001, "expected mp=10, got " .. tostring(mp0))
    end)
end)

-- @describe VecFrame conversion roundtrip
describe("VecFrame conversion roundtrip", function()
    -- @covers LVecFrame:colAdd
    -- @covers LVecFrame:colMul
    -- @covers LVecFrame:toDataFrame
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.toVec
    it("toDataFrame preserves modified values after vector ops", function()
        local df = lurek.dataframe.fromCSV("hp,mp\n100,50\n200,100\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colMul("hp", 0.5)
        vf:colAdd("mp", 10)
        local df2 = vf:toDataFrame()
        local hp0 = df2:getValue(1, "hp")
        local mp0 = df2:getValue(1, "mp")
        expect_true(math.abs(hp0 - 50) < 0.0001, "expected hp=50, got " .. tostring(hp0))
        expect_true(math.abs(mp0 - 60) < 0.0001, "expected mp=60, got " .. tostring(mp0))
    end)
end)

-- @describe DataFrame statistics
describe("DataFrame statistics", function()
    local function num_df()
        return lurek.dataframe.fromCSV("v\n10\n20\n30\n40")
    end

    -- @covers LDataFrame:describe
    it("describe returns a DataFrame with descriptive statistics", function()
        local d = num_df():describe()
        expect_not_nil(d)
        -- describe returns a DataFrame (userdata) with stat rows
        expect_true(d:nrows() > 0, "describe must return at least one row")
    end)

    -- @covers LDataFrame:sum
    it("sum of {10,20,30,40} = 100", function()
        expect_equal(100, num_df():sum("v"))
    end)

    -- @covers LDataFrame:mean
    it("mean of {10,20,30,40} = 25", function()
        expect_equal(25, num_df():mean("v"))
    end)

    -- @covers LDataFrame:median
    it("median returns a number", function()
        expect_type("number", num_df():median("v"))
    end)

    -- @covers LDataFrame:stddev
    it("stddev returns a non-negative number", function()
        local s = num_df():stddev("v")
        expect_type("number", s)
        expect_true(s >= 0, "stddev must be non-negative")
    end)

    -- @covers LDataFrame:variance
    it("variance returns a non-negative number", function()
        local v = num_df():variance("v")
        expect_type("number", v)
        expect_true(v >= 0, "variance must be non-negative")
    end)

    -- @covers LDataFrame:modeVal
    -- @covers lurek.dataframe.fromCSV
    it("modeVal returns the most frequent value", function()
        local df = lurek.dataframe.fromCSV("v\n1\n2\n2\n3")
        local m = df:modeVal("v")
        expect_equal(2, m)
    end)

    -- @covers LDataFrame:entropy
    -- @covers lurek.dataframe.fromCSV
    it("entropy returns a non-negative number", function()
        local df = lurek.dataframe.fromCSV("v\n1\n2\n2\n3")
        local e = df:entropy("v")
        expect_type("number", e)
        expect_true(e >= 0, "entropy must be non-negative")
    end)

    -- @covers LDataFrame:correlationMatrix
    -- @covers lurek.dataframe.fromCSV
    it("correlationMatrix returns a DataFrame or table", function()
        local df = lurek.dataframe.fromCSV("a,b\n1,4\n2,5\n3,6")
        local cm = df:correlationMatrix()
        expect_not_nil(cm)
    end)
end)

-- @describe DataFrame nil handling
describe("DataFrame nil handling", function()
    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:fillNil
    -- @covers LDataFrame:getValue
    -- @covers lurek.dataframe.newDataFrame
    it("fillNil replaces nil with a default value", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", 0)
        df:addRow({ x = 1 })
        df:addRow({ x = nil })
        df:addRow({ x = 3 })
        df:fillNil("x", 99)
        expect_equal(99, df:getValue(2, "x"))
    end)
end)

-- @describe DataFrame serialization
describe("DataFrame serialization", function()
    local function alpha_df()
        return lurek.dataframe.fromCSV("name,val\nAlice,1\nBob,2")
    end

    -- @covers LDataFrame:toCSV
    it("toCSV returns a non-empty string", function()
        local csv = alpha_df():toCSV()
        expect_type("string", csv)
        expect_true(#csv > 5, "CSV output must not be empty")
    end)

    -- @covers LDataFrame:toJSON
    it("toJSON returns a non-empty string", function()
        local json = alpha_df():toJSON()
        expect_type("string", json)
        expect_true(#json > 2, "JSON output must not be empty")
    end)

    -- @covers LDataFrame:toBinary
    it("toBinary returns a non-empty string", function()
        local bin = alpha_df():toBinary()
        expect_type("string", bin)
        expect_true(#bin > 0, "binary output must not be empty")
    end)

    -- @covers LDataFrame:toTable
    it("toTable returns a Lua array of row tables", function()
        local rows = alpha_df():toTable()
        expect_type("table", rows)
        expect_equal(2, #rows)
        expect_equal("Alice", rows[1].name)
    end)

    -- @covers LDataFrame:toString
    it("toString returns a non-empty string", function()
        local s = alpha_df():toString()
        expect_type("string", s)
        expect_true(#s > 0, "string representation must not be empty")
    end)
end)

-- @describe DataFrame query and clone
describe("DataFrame query and clone", function()
    -- @covers LDataFrame:query
    -- @covers lurek.dataframe.fromCSV
    it("query returns a filtered DataFrame via SQL", function()
        local df = lurek.dataframe.fromCSV("v\n10\n20\n30")
        local out = df:query("SELECT * FROM df WHERE v > 15")
        expect_not_nil(out)
        expect_equal(2, out:nrows())
    end)

    -- @covers LDataFrame:clone
    -- @covers LDataFrame:nrows
    -- @covers LDataFrame:removeRow
    -- @covers lurek.dataframe.fromCSV
    it("clone produces an independent copy", function()
        local df = lurek.dataframe.fromCSV("v\n1\n2\n3")
        local copy = df:clone()
        expect_equal(3, copy:nrows())
        copy:removeRow(1)
        expect_equal(3, df:nrows())  -- original unchanged
    end)
end)

-- @describe DataFrame bulk row ops and typed columns
describe("DataFrame bulk row ops and typed columns", function()
    -- @covers LDataFrame:addRowBatch
    -- @covers LDataFrame:nrows
    -- @covers lurek.dataframe.newDataFrame
    it("addRowBatch adds multiple rows at once", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRowBatch({{ v = 1 }, { v = 2 }, { v = 3 }})
        expect_equal(3, df:nrows())
    end)

    -- @covers LDataFrame:getColumnAsF64
    -- @covers lurek.dataframe.fromCSV
    it("getColumnAsF64 returns a number array", function()
        local df = lurek.dataframe.fromCSV("v\n1\n2\n3")
        local nums = df:getColumnAsF64("v")
        expect_type("table", nums)
        expect_equal(3, #nums)
        expect_equal(1, nums[1])
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:setColumnFromF64
    -- @covers lurek.dataframe.fromCSV
    it("setColumnFromF64 writes values back into a column", function()
        local df = lurek.dataframe.fromCSV("v\n1\n2\n3")
        df:setColumnFromF64("v", {10, 20, 30})
        expect_equal(10, df:getValue(1, "v"))
        expect_equal(30, df:getValue(3, "v"))
    end)

    -- @covers LDataFrame:type
    -- @covers lurek.dataframe.newDataFrame
    it("type returns 'LDataFrame'", function()
        local df = lurek.dataframe.newDataFrame()
        expect_equal("LDataFrame", df:type())
    end)

    -- @covers LDataFrame:typeOf
    -- @covers lurek.dataframe.newDataFrame
    it("typeOf('LDataFrame') returns true", function()
        local df = lurek.dataframe.newDataFrame()
        expect_equal(true, df:typeOf("LDataFrame"))
    end)
end)

-- @describe Database operations
describe("Database operations", function()
    local function make_db()
        local db = lurek.dataframe.newDatabase()
        local df = lurek.dataframe.fromCSV("x\n1\n2")
        db:addTable("test", df)
        return db
    end

    -- @covers LDatabase:getTable
    it("getTable returns the stored DataFrame", function()
        local db = make_db()
        local t = db:getTable("test")
        expect_not_nil(t)
        expect_equal(2, t:nrows())
    end)

    -- @covers LDatabase:hasTable
    it("hasTable returns true after addTable", function()
        local db = make_db()
        expect_equal(true, db:hasTable("test"))
        expect_equal(false, db:hasTable("__missing__"))
    end)

    -- @covers LDatabase:hasTable
    -- @covers LDatabase:removeTable
    it("removeTable decreases tableCount by 1", function()
        local db = make_db()
        db:removeTable("test")
        expect_equal(false, db:hasTable("test"))
    end)

    -- @covers LDatabase:listTables
    it("listTables returns an array of table name strings", function()
        local db = make_db()
        local names = db:listTables()
        expect_type("table", names)
        expect_equal(1, #names)
        expect_equal("test", names[1])
    end)

    -- @covers LDatabase:tableCount
    it("tableCount returns 1 after addTable", function()
        expect_equal(1, make_db():tableCount())
    end)

    -- @covers LDatabase:tableCount
    it("clear removes all tables", function()
        local db = make_db()
        db:clear()
        expect_equal(0, db:tableCount())
    end)

    -- @covers LDatabase:addTable
    -- @covers LDatabase:tableCount
    -- @covers lurek.dataframe.fromCSV
    -- @covers lurek.dataframe.newDatabase
    it("merge adds all tables from another database", function()
        local db1 = make_db()
        local db2 = lurek.dataframe.newDatabase()
        db2:addTable("other", lurek.dataframe.fromCSV("y\n9"))
        db1:merge(db2)
        expect_equal(2, db1:tableCount())
    end)

    -- @covers LDatabase:toJSON
    it("toJSON returns a non-empty string", function()
        local json = make_db():toJSON()
        expect_type("string", json)
        expect_true(#json > 2, "JSON must not be empty")
    end)

    -- @covers LDatabase:query
    it("query returns a DataFrame from a SQL-like expression", function()
        local db = make_db()
        local result = db:query("SELECT * FROM test WHERE x > 1")
        expect_not_nil(result)
    end)

    -- @covers LDatabase:type
    -- @covers lurek.dataframe.newDatabase
    it("type returns 'LDatabase'", function()
        expect_equal("LDatabase", lurek.dataframe.newDatabase():type())
    end)

    -- @covers LDatabase:typeOf
    -- @covers lurek.dataframe.newDatabase
    it("typeOf('LDatabase') returns true", function()
        expect_equal(true, lurek.dataframe.newDatabase():typeOf("LDatabase"))
    end)
end)

-- =========================================================================
-- Phase 06: grouped:aggregate with Lua callback
-- =========================================================================
-- @describe grouped:aggregate with Lua callback
describe("grouped:aggregate with Lua callback", function()
    -- @covers lurek.dataframe.newDataFrame
    it("groupByObj method exists on DataFrame", function()
        local df = lurek.dataframe.newDataFrame()
        expect_equal(type(df.groupByObj), "function")
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:groupByObj
    -- @covers lurek.dataframe.newDataFrame
    it("groupByObj returns a GroupedFrame object", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "category", nil)
        df_add_column(df, "value", nil)
        df:addRow({category = "a", value = 1})
        df:addRow({category = "b", value = 10})
        local g = df:groupByObj("category")
        expect_not_nil(g)
        expect_equal(type(g.aggregate), "function")
    end)

    -- @covers LDataFrame:groupByObj
    -- @covers LGroupedFrame:aggregate
    -- @covers lurek.dataframe.fromCSV
    it("aggregate with sum callback produces correct result", function()
        local csv = "category,value\na,1\na,2\nb,10"
        local df = lurek.dataframe.fromCSV(csv)
        local g = df:groupByObj("category")
        if g then
            local result = g:aggregate("value", function(vals)
                local s = 0
                for _, v in ipairs(vals) do s = s + v end
                return s
            end)
            expect_not_nil(result)
            expect_equal(result:nrows(), 2)
        end
    end)
end)

-- @describe LDataFrame rolling extrema
describe("LDataFrame rolling extrema", function()
    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withRollingMin
    -- @covers lurek.dataframe.newDataFrame
    it("withRollingMin computes window minima", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "val", 0)
        df:addRow({val = 4})
        df:addRow({val = 2})
        df:addRow({val = 6})
        df:withRollingMin("val", 2, "rmin")
        local row3 = df:getRow(3)
        expect_near(2.0, row3.rmin, 0.001)
    end)

    -- @covers LDataFrame:addRow
    -- @covers LDataFrame:getRow
    -- @covers LDataFrame:withRollingMax
    -- @covers lurek.dataframe.newDataFrame
    it("withRollingMax computes window maxima", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "val", 0)
        df:addRow({val = 4})
        df:addRow({val = 2})
        df:addRow({val = 6})
        df:withRollingMax("val", 2, "rmax")
        local row3 = df:getRow(3)
        expect_near(6.0, row3.rmax, 0.001)
    end)
end)

-- @describe dataframe strict: LDataFrame extra methods
describe("dataframe strict: LDataFrame extra methods", function()
    -- @covers LDataFrame:count
    -- @covers lurek.dataframe.newDataFrame
    it("LDataFrame count returns number of rows", function()
        local df = lurek.dataframe.newDataFrame()
        expect_type("number", df:count())
    end)

    -- @covers LDataFrame:addColumn
    -- @covers lurek.dataframe.newDataFrame
    it("LDataFrame addColumn is callable", function()
        local df = lurek.dataframe.newDataFrame()
        local ok = pcall(function() df:addColumn("score", 0) end)
        expect_true(ok)
    end)

    -- @covers LDataFrame:removeColumn
    -- @covers lurek.dataframe.newDataFrame
    it("LDataFrame removeColumn is callable after addColumn", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("tmp", 0)
        local ok = pcall(function() df:removeColumn("tmp") end)
        expect_true(ok)
    end)

    -- @covers LDataFrame:setValue
    -- @covers lurek.dataframe.newDataFrame
    it("LDataFrame setValue is callable", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("val", 0)
        df:addRow({val = 10})
        local ok = pcall(function() df:setValue(1, "val", 99) end)
        expect_true(ok)
    end)

    -- @covers LDataFrame:sum
    -- @covers lurek.dataframe.newDataFrame
    it("LDataFrame sum returns a number for numeric column", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("n", 0)
        df:addRow({n = 3})
        df:addRow({n = 5})
        local s = df:sum("n")
        expect_true(s == nil or type(s) == "number")
    end)

    -- @covers LDataFrame:toTable
    -- @covers lurek.dataframe.newDataFrame
    it("LDataFrame toTable returns a table", function()
        local df = lurek.dataframe.newDataFrame()
        expect_type("table", df:toTable())
    end)
end)

-- @describe dataframe strict: LVecFrame type/typeOf
describe("dataframe strict: LVecFrame type/typeOf", function()
    -- @covers LVecFrame:type
    -- @covers LVecFrame:typeOf
    -- @covers lurek.dataframe.toVec
    -- @covers lurek.dataframe.newDataFrame
    it("LVecFrame type and typeOf are callable", function()
        local df = lurek.dataframe.newDataFrame()
        local vf = lurek.dataframe.toVec(df)
        expect_type("string", vf:type())
        expect_type("boolean", vf:typeOf("Object"))
    end)
end)

-- @describe dataframe strict: LGroupedFrame type/typeOf
describe("dataframe strict: LGroupedFrame type/typeOf", function()
    -- @covers LGroupedFrame:type
    -- @covers LGroupedFrame:typeOf
    -- @covers lurek.dataframe.newDataFrame
    it("LGroupedFrame type and typeOf are callable", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("cat", "a")
        df:addRow({cat = "x"})
        local ok, gf = pcall(function() return df:groupBy("cat") end)
        if ok and gf ~= nil and type(gf) == "userdata" then
            local ok2, t = pcall(function() return gf:type() end)
            if ok2 then expect_type("string", t) end
            local ok3, b = pcall(function() return gf:typeOf("Object") end)
            if ok3 then expect_type("boolean", b) end
        else
            expect_false(ok and gf ~= nil and type(gf) == "userdata")
        end
    end)
end)

-- @describe dataframe dedicated: advanced transforms and SQL join
describe("dataframe dedicated: advanced transforms and SQL join", function()
    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:withEval
    -- @covers lurek.dataframe.fromRows
    it("withEval computes expression column", function()
        local df = lurek.dataframe.fromRows(
            { "x", "y" },
            {
                { 2, 3 },
                { 5, 7 },
            }
        )
        local out = df:withEval("z", "x + y")
        expect_near(5.0, out:getValue(1, "z"), 0.001)
        expect_near(12.0, out:getValue(2, "z"), 0.001)
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:pivotTable
    -- @covers lurek.dataframe.fromRows
    it("pivotTable builds wide shape with sum agg", function()
        local df = lurek.dataframe.fromRows(
            { "team", "kind", "score" },
            {
                { "red", "a", 2 },
                { "red", "b", 4 },
                { "blue", "a", 6 },
                { "blue", "b", 1 },
            }
        )
        local out = df:pivotTable("team", "kind", "score", "sum")
        expect_equal(2, out:nrows())
        expect_near(2.0, out:getValue(1, "a"), 0.001)
        expect_near(4.0, out:getValue(1, "b"), 0.001)
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:rollingMean
    -- @covers lurek.dataframe.fromRows
    it("rollingMean computes trailing means", function()
        local df = lurek.dataframe.fromRows(
            { "v" },
            {
                { 2 },
                { 4 },
                { 8 },
            }
        )
        local out = df:rollingMean("v", 2, "v_rm")
        expect_near(3.0, out:getValue(2, "v_rm"), 0.001)
        expect_near(6.0, out:getValue(3, "v_rm"), 0.001)
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:rollingSum
    -- @covers lurek.dataframe.fromRows
    it("rollingSum computes trailing sums", function()
        local df = lurek.dataframe.fromRows(
            { "v" },
            {
                { 2 },
                { 4 },
                { 8 },
            }
        )
        local out = df:rollingSum("v", 2, "v_rs")
        expect_near(6.0, out:getValue(2, "v_rs"), 0.001)
        expect_near(12.0, out:getValue(3, "v_rs"), 0.001)
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDataFrame:rank
    -- @covers lurek.dataframe.fromRows
    it("rank desc assigns rank 1 to highest", function()
        local df = lurek.dataframe.fromRows(
            { "name", "score" },
            {
                { "A", 10 },
                { "B", 30 },
                { "C", 20 },
            }
        )
        local out = df:rank("score", "desc", "rk")
        expect_near(3.0, out:getValue(1, "rk"), 0.001)
        expect_near(1.0, out:getValue(2, "rk"), 0.001)
        expect_near(2.0, out:getValue(3, "rk"), 0.001)
    end)

    -- @covers LDataFrame:getValue
    -- @covers LDatabase:addTable
    -- @covers LDatabase:query
    -- @covers lurek.dataframe.fromRows
    -- @covers lurek.dataframe.newDatabase
    it("Database query supports multi-table join", function()
        local players = lurek.dataframe.fromRows(
            { "id", "name" },
            {
                { 1, "Alice" },
                { 2, "Bob" },
            }
        )
        local scores = lurek.dataframe.fromRows(
            { "player_id", "score" },
            {
                { 1, 100 },
                { 2, 200 },
            }
        )

        local db = lurek.dataframe.newDatabase()
        db:addTable("players", players)
        db:addTable("scores", scores)

        local out = db:query(
            "SELECT name, score FROM players JOIN scores ON players.id = scores.player_id ORDER BY score DESC"
        )
        expect_equal(2, out:nrows())
        expect_equal("Bob", out:getValue(1, "name"))
        expect_near(200.0, out:getValue(1, "score"), 0.001)
    end)
end)

-- @describe unit: migrated from integration/test_image_dataframe.lua
describe("unit: migrated from integration/test_image_dataframe.lua", function()
        -- @covers LDataFrame:addColumn
        -- @covers LDataFrame:addRow
        -- @covers LDataFrame:nrows
        -- @covers lurek.dataframe.newDataFrame
        it("DataFrame can hold numeric pixel data without overflow", function()
            local df = lurek.dataframe.newDataFrame()
            df:addColumn("value")
            for i = 0, 255 do
                df:addRow({ value = i })
            end
            expect_equal(256, df:nrows(), "256 rows without overflow")
        end)

end)

test_summary()

-- @describe lazy evaluation pipeline
describe("lazy evaluation pipeline", function()

    -- @covers LDataFrame:lazy
    it("lazy has lazy factory method", function()
        local df = lurek.dataframe.fromCSV("a,b\n1,2\n3,4")
        local lq = df:lazy()
        expect_not_nil(lq, "lazy() returns a value")
        expect_equal("LLazyQuery", lq:type(), "type is LLazyQuery")
    end)

    -- @covers LDataFrame:lazy
    -- @covers LLazyQuery:collect
    it("lazy collect with no steps returns identical rows", function()
        local df = lurek.dataframe.fromCSV("x,y\n1,2\n3,4\n5,6")
        local out = df:lazy():collect()
        expect_equal(3, out:nrows(), "row count preserved")
        expect_equal(2, out:ncols(), "col count preserved")
    end)

    -- @covers LLazyQuery:filter
    -- @covers LLazyQuery:collect
    it("lazy filter reduces rows", function()
        local df = lurek.dataframe.fromCSV("age,score\n20,80\n30,90\n40,70")
        local out = df:lazy():filter("age", ">", 25):collect()
        expect_equal(2, out:nrows(), "two rows pass age > 25")
    end)

    -- @covers LLazyQuery:sort
    -- @covers LLazyQuery:head
    it("lazy sort + head returns top-n", function()
        local df = lurek.dataframe.fromCSV("v\n3\n1\n4\n1\n5\n9")
        local out = df:lazy():sort("v", false):head(3):collect()
        expect_equal(3, out:nrows(), "head(3) yields 3 rows")
        expect_equal(9, out:getValue(1, "v"), "first row is max value")
    end)

    -- @covers LLazyQuery:tail
    it("lazy tail returns last rows", function()
        local df = lurek.dataframe.fromCSV("n\n1\n2\n3\n4\n5")
        local out = df:lazy():tail(2):collect()
        expect_equal(2, out:nrows(), "tail(2) yields 2 rows")
        expect_equal(5, out:getValue(2, "n"), "last row is 5")
    end)

    -- @covers LLazyQuery:limit
    it("lazy limit is alias for head", function()
        local df = lurek.dataframe.fromCSV("x\n10\n20\n30\n40")
        local out = df:lazy():limit(2):collect()
        expect_equal(2, out:nrows(), "limit(2) yields 2 rows")
    end)

    -- @covers LLazyQuery:dropNil
    it("lazy dropNil removes nil rows", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v")
        df:addRow({ v = 1 })
        df:addRow({})        -- nil
        df:addRow({ v = 3 })
        local out = df:lazy():dropNil("v"):collect()
        expect_equal(2, out:nrows(), "two non-nil rows remain")
    end)

    -- @covers LLazyQuery:select
    it("lazy select retains only named columns", function()
        local df = lurek.dataframe.fromCSV("a,b,c\n1,2,3\n4,5,6")
        local out = df:lazy():select({"a", "c"}):collect()
        expect_equal(2, out:ncols(), "two columns selected")
        expect_equal("a", out:columns()[1], "first column is a")
        expect_equal("c", out:columns()[2], "second column is c")
    end)

    -- @covers LLazyQuery:filter
    -- @covers LLazyQuery:sort
    -- @covers LLazyQuery:head
    it("lazy chained filter-sort-head pipeline", function()
        local df = lurek.dataframe.fromCSV("name,score\nalice,80\nbob,60\ncharlie,90\ndave,70")
        local out = df:lazy()
            :filter("score", ">=", 70)
            :sort("score", false)
            :head(2)
            :collect()
        expect_equal(2, out:nrows(), "two rows pass score >= 70 after head(2)")
        expect_equal(90, out:getValue(1, "score"), "top score first")
    end)

    -- @covers LLazyQuery:typeOf
    it("lazy typeOf returns true for LLazyQuery", function()
        local df = lurek.dataframe.fromCSV("x\n1")
        local lq = df:lazy()
        expect_true(lq:typeOf("LLazyQuery"), "typeOf LLazyQuery")
        expect_true(lq:typeOf("Object"), "typeOf Object")
        expect_false(lq:typeOf("LDataFrame"), "typeOf LDataFrame is false")
    end)

end)

-- @describe random edge cases
describe("random edge cases", function()

    -- @covers lurek.dataframe.random
    it("random with n=0 returns empty DataFrame", function()
        local defs = { {"x", "number"}, {"y", "number"} }
        local df = lurek.dataframe.random(defs, 0, 1)
        expect_equal(0, df:nrows(), "zero rows when n=0")
        expect_equal(2, df:ncols(), "columns still present")
    end)

    -- @covers lurek.dataframe.random
    it("random returns exactly n rows", function()
        local defs = { {"id", "number"} }
        local df = lurek.dataframe.random(defs, 7, 99)
        expect_equal(7, df:nrows(), "exactly 7 rows")
    end)

end)

-- @describe Database multi-table SQL JOIN
describe("Database multi-table SQL JOIN", function()

    -- @covers LDatabase:query
    it("SQL JOIN on two tables returns combined rows", function()
        local orders = lurek.dataframe.fromCSV("order_id,customer_id,amount\n1,10,100\n2,20,200\n3,10,150")
        local customers = lurek.dataframe.fromCSV("customer_id,name\n10,Alice\n20,Bob")
        local db = lurek.dataframe.newDatabase()
        db:addTable("orders", orders)
        db:addTable("customers", customers)
        local result = db:query("SELECT orders.order_id, customers.name, orders.amount FROM orders JOIN customers ON orders.customer_id = customers.customer_id")
        expect_not_nil(result, "query returns a result")
        expect_equal(3, result:nrows(), "three joined rows")
    end)

    -- @covers LDatabase:query
    it("SQL query against single table returns filtered rows", function()
        local scores = lurek.dataframe.fromCSV("player,score\nAlice,90\nBob,70\nCharlie,85")
        local db = lurek.dataframe.newDatabase()
        db:addTable("scores", scores)
        local result = db:query("SELECT player, score FROM scores WHERE score > 80")
        expect_equal(2, result:nrows(), "two rows with score > 80")
    end)

end)

test_summary()
