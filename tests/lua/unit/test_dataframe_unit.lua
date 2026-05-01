-- Lurek2D DataFrame Tests
-- Tests for lurek.dataframe tabular data API

-- Helper to build a simple test DataFrame
-- @covers lurek.dataframe.fromBinary
-- @covers lurek.dataframe.fromCSV
-- @covers lurek.dataframe.fromJSON
-- @covers lurek.dataframe.fromTable
-- @covers lurek.dataframe.newDataFrame
-- @covers lurek.dataframe.newDatabase
-- @covers lurek.dataframe.random

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
describe("lurek.dataframe module exists", function()
    it("lurek.dataframe is a table", function()
        expect_type("table", lurek.dataframe)
    end)

    it("has newDataFrame factory", function()
        expect_type("function", lurek.dataframe.newDataFrame)
    end)

    it("has newDatabase factory", function()
        expect_type("function", lurek.dataframe.newDatabase)
    end)

    it("has fromTable factory", function()
        expect_type("function", lurek.dataframe.fromTable)
    end)

    it("has fromCSV factory", function()
        expect_type("function", lurek.dataframe.fromCSV)
    end)

    it("has fromJSON factory", function()
        expect_type("function", lurek.dataframe.fromJSON)
    end)

    it("has fromBinary factory", function()
        expect_type("function", lurek.dataframe.fromBinary)
    end)

    it("has random factory", function()
        expect_type("function", lurek.dataframe.random)
    end)
end)

-- =========================================================================
-- 2. Construction
-- =========================================================================
describe("construction", function()
    it("newDataFrame creates empty DataFrame", function()
        local df = lurek.dataframe.newDataFrame()
        expect_equal(0, df:nrows())
        expect_equal(0, df:ncols())
    end)

    it("fromCSV creates DataFrame with correct shape", function()
        local df = make_test_df()
        expect_equal(3, df:nrows())
        expect_equal(3, df:ncols())
    end)

    it("fromCSV parses column names", function()
        local df = make_test_df()
        local cols = df:columns()
        expect_equal("name", cols[1])
        expect_equal("age", cols[2])
        expect_equal("score", cols[3])
    end)

    it("fromCSV auto-detects numbers", function()
        local df = make_test_df()
        expect_near(30, df:getValue(1, "age"), 1e-5)
        expect_near(25, df:getValue(2, "age"), 1e-5)
    end)

    it("fromCSV parses text values", function()
        local df = make_test_df()
        expect_equal("Alice", df:getValue(1, "name"))
        expect_equal("Bob", df:getValue(2, "name"))
    end)

    it("fromTable creates DataFrame from row tables", function()
        local df = lurek.dataframe.fromTable({
            { x = 1, y = 2 },
            { x = 3, y = 4 },
        })
        expect_equal(2, df:nrows())
        expect_equal(2, df:ncols())
    end)

    it("fromJSON creates DataFrame", function()
        local json = '[{"a":1,"b":"hello"},{"a":2,"b":"world"}]'
        local df = lurek.dataframe.fromJSON(json)
        expect_equal(2, df:nrows())
    end)

    it("random creates DataFrame with specified rows", function()
        local defs = { {"x", "float"}, {"y", "float"} }
        local df = lurek.dataframe.random(defs, 10, 42)
        expect_equal(10, df:nrows())
        expect_equal(2, df:ncols())
    end)

    it("random with seed is deterministic", function()
        local defs = { {"val", "float"} }
        local df1 = lurek.dataframe.random(defs, 5, 123)
        local df2 = lurek.dataframe.random(defs, 5, 123)
        for i = 1, 5 do
            expect_near(df1:getValue(i, "val"), df2:getValue(i, "val"), 1e-5)
        end
    end)

    it("fromCSV with empty body creates empty DataFrame", function()
        local df = lurek.dataframe.fromCSV("x,y")
        expect_equal(0, df:nrows())
        expect_equal(2, df:ncols())
    end)

    it("fromCSV with empty input creates empty DataFrame", function()
        local df = lurek.dataframe.fromCSV("")
        expect_equal(0, df:nrows())
        expect_equal(0, df:ncols())
    end)
end)

-- =========================================================================
-- 3. Schema
-- =========================================================================
describe("schema", function()
    it("nrows returns row count", function()
        local df = make_test_df()
        expect_equal(3, df:nrows())
    end)

    it("ncols returns column count", function()
        local df = make_test_df()
        expect_equal(3, df:ncols())
    end)

    it("columns returns ordered column names", function()
        local df = make_test_df()
        local cols = df:columns()
        expect_equal(3, #cols)
    end)

    it("count is alias for nrows", function()
        local df = make_test_df()
        expect_equal(df:nrows(), df:count())
    end)
end)

-- =========================================================================
-- 4. Column operations
-- =========================================================================
describe("column operations", function()
    it("addColumn increases ncols", function()
        local df = make_test_df()
        df_add_column(df, "grade")
        expect_equal(4, df:ncols())
    end)

    it("addColumn with default fills all rows", function()
        local df = make_test_df()
        df_add_column(df, "pass", true)
        for i = 1, df:nrows() do
            expect_equal(true, df:getValue(i, "pass"))
        end
    end)

    it("removeColumn by name decreases ncols", function()
        local df = make_test_df()
        df_remove_column(df, "age")
        expect_equal(2, df:ncols())
    end)

    it("removeColumn by index decreases ncols", function()
        local df = make_test_df()
        df_remove_column(df, 2)
        expect_equal(2, df:ncols())
    end)

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

    it("getColumn returns column values", function()
        local df = make_test_df()
        local ages = df:getColumn("age")
        expect_equal(3, #ages)
        expect_near(30, ages[1], 1e-5)
        expect_near(25, ages[2], 1e-5)
        expect_near(35, ages[3], 1e-5)
    end)

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
describe("row operations", function()
    it("addRow increases nrows", function()
        local df = make_test_df()
        df:addRow({ name = "Dave", age = 28, score = 88 })
        expect_equal(4, df:nrows())
    end)

    it("addRow returns 1-based index", function()
        local df = make_test_df()
        local idx = df:addRow({ name = "Dave", age = 28, score = 88 })
        expect_equal(4, idx)
    end)

    it("addRow with no args adds empty row", function()
        local df = make_test_df()
        local before = df:nrows()
        df:addRow()
        expect_equal(before + 1, df:nrows())
    end)

    it("removeRow decreases nrows", function()
        local df = make_test_df()
        df:removeRow(2)
        expect_equal(2, df:nrows())
    end)

    it("removeRow removes correct row", function()
        local df = make_test_df()
        df:removeRow(1) -- Remove Alice
        expect_equal("Bob", df:getValue(1, "name"))
    end)

    it("getRow returns row as table", function()
        local df = make_test_df()
        local row = df:getRow(1)
        expect_equal("Alice", row.name)
        expect_near(30, row.age, 1e-5)
        expect_near(90, row.score, 1e-5)
    end)

    it("getRow with last row index works", function()
        local df = make_test_df()
        local row = df:getRow(3)
        expect_equal("Charlie", row.name)
    end)
end)

-- =========================================================================
-- 6. Cell access
-- =========================================================================
describe("cell access", function()
    it("getValue by column name", function()
        local df = make_test_df()
        expect_equal("Alice", df:getValue(1, "name"))
    end)

    it("getValue by column index", function()
        local df = make_test_df()
        expect_equal("Alice", df:getValue(1, 1))
    end)

    it("setValue changes cell value", function()
        local df = make_test_df()
        df_set_value(df, 1, "name", "Alicia")
        expect_equal("Alicia", df:getValue(1, "name"))
    end)

    it("setValue by column index", function()
        local df = make_test_df()
        df_set_value(df, 2, 2, 99)
        expect_near(99, df:getValue(2, "age"), 1e-5)
    end)

    it("setValue to nil clears cell", function()
        local df = make_test_df()
        df_set_value(df, 1, "name", nil)
        expect_nil(df:getValue(1, "name"))
    end)
end)

-- =========================================================================
-- 7. Filter
-- =========================================================================
describe("filter", function()
    it("filter == returns matching rows", function()
        local df = make_test_df()
        local result = df:filter("name", "==", "Alice")
        expect_equal(1, result:nrows())
        expect_equal("Alice", result:getValue(1, "name"))
    end)

    it("filter != excludes matching rows", function()
        local df = make_test_df()
        local result = df:filter("name", "!=", "Alice")
        expect_equal(2, result:nrows())
    end)

    it("filter < on numeric column", function()
        local df = make_test_df()
        local result = df:filter("age", "<", 30)
        expect_equal(1, result:nrows())
        expect_equal("Bob", result:getValue(1, "name"))
    end)

    it("filter > on numeric column", function()
        local df = make_test_df()
        local result = df:filter("age", ">", 30)
        expect_equal(1, result:nrows())
        expect_equal("Charlie", result:getValue(1, "name"))
    end)

    it("filter <= includes boundary", function()
        local df = make_test_df()
        local result = df:filter("age", "<=", 30)
        expect_equal(2, result:nrows())
    end)

    it("filter >= includes boundary", function()
        local df = make_test_df()
        local result = df:filter("age", ">=", 30)
        expect_equal(2, result:nrows())
    end)

    it("filter with no matches returns empty DataFrame", function()
        local df = make_test_df()
        local result = df:filter("age", ">", 100)
        expect_equal(0, result:nrows())
    end)

    it("filter contains matches substrings", function()
        local df = make_test_df()
        local result = df:filter("name", "contains", "li")
        expect_equal(2, result:nrows())
        expect_equal("Alice", result:getValue(1, "name"))
        expect_equal("Charlie", result:getValue(2, "name"))
    end)

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
describe("sort", function()
    it("sort ascending by numeric column", function()
        local df = make_test_df()
        local sorted = df:sort("age", true)
        expect_near(25, sorted:getValue(1, "age"), 1e-5)
        expect_near(30, sorted:getValue(2, "age"), 1e-5)
        expect_near(35, sorted:getValue(3, "age"), 1e-5)
    end)

    it("sort descending by numeric column", function()
        local df = make_test_df()
        local sorted = df:sort("age", false)
        expect_near(35, sorted:getValue(1, "age"), 1e-5)
        expect_near(30, sorted:getValue(2, "age"), 1e-5)
        expect_near(25, sorted:getValue(3, "age"), 1e-5)
    end)

    it("sort defaults to ascending", function()
        local df = make_test_df()
        local sorted = df:sort("age")
        expect_near(25, sorted:getValue(1, "age"), 1e-5)
    end)

    it("sort preserves row data", function()
        local df = make_test_df()
        local sorted = df:sort("age", true)
        expect_equal("Bob", sorted:getValue(1, "name"))
    end)

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
describe("head/tail/slice", function()
    it("head defaults to 5 (returns all if fewer)", function()
        local df = make_test_df()
        local h = df:head()
        expect_equal(3, h:nrows()) -- only 3 rows total
    end)

    it("head with n returns first n rows", function()
        local df = make_test_df()
        local h = df:head(2)
        expect_equal(2, h:nrows())
        expect_equal("Alice", h:getValue(1, "name"))
        expect_equal("Bob", h:getValue(2, "name"))
    end)

    it("head larger than row count returns all rows", function()
        local df = make_test_df()
        local h = df:head(100)
        expect_equal(3, h:nrows())
    end)

    it("tail defaults to 5 (returns all if fewer)", function()
        local df = make_test_df()
        local t = df:tail()
        expect_equal(3, t:nrows())
    end)

    it("tail with n returns last n rows", function()
        local df = make_test_df()
        local t = df:tail(2)
        expect_equal(2, t:nrows())
        expect_equal("Bob", t:getValue(1, "name"))
        expect_equal("Charlie", t:getValue(2, "name"))
    end)

    it("slice with 1-based inclusive range", function()
        local df = make_test_df()
        local s = df:slice(1, 2)
        expect_equal(2, s:nrows())
        expect_equal("Alice", s:getValue(1, "name"))
        expect_equal("Bob", s:getValue(2, "name"))
    end)

    it("slice single row", function()
        local df = make_test_df()
        local s = df:slice(2, 2)
        expect_equal(1, s:nrows())
        expect_equal("Bob", s:getValue(1, "name"))
    end)

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
describe("select", function()
    it("select by column name", function()
        local df = make_test_df()
        local s = df:select("name", "score")
        expect_equal(2, s:ncols())
        expect_equal(3, s:nrows())
        expect_equal("Alice", s:getValue(1, "name"))
    end)

    it("select by column index", function()
        local df = make_test_df()
        local s = df:select(1, 3)
        expect_equal(2, s:ncols())
    end)

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
describe("unique", function()
    it("unique returns distinct values", function()
        local csv = "color\nred\nblue\nred\ngreen\nblue"
        local df = lurek.dataframe.fromCSV(csv)
        local u = df:unique("color")
        expect_equal(3, #u)
    end)

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
describe("groupBy", function()
    it("groupBy returns table of DataFrames", function()
        local csv = "dept,name\nHR,Alice\nIT,Bob\nHR,Charlie\nIT,Dave"
        local df = lurek.dataframe.fromCSV(csv)
        local groups = df:groupBy("dept")
        expect_type("table", groups)
    end)

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
describe("join", function()
    it("inner join matches on shared column values", function()
        local csv1 = "id,name\n1,Alice\n2,Bob\n3,Charlie"
        local csv2 = "id,dept\n1,HR\n2,IT\n4,Finance"
        local df1 = lurek.dataframe.fromCSV(csv1)
        local df2 = lurek.dataframe.fromCSV(csv2)
        local result = df1:join(df2, "id", "id", "inner")
        expect_equal(2, result:nrows()) -- only ids 1 and 2 match
    end)

    it("left join keeps all left rows", function()
        local csv1 = "id,name\n1,Alice\n2,Bob\n3,Charlie"
        local csv2 = "id,dept\n1,HR\n2,IT\n4,Finance"
        local df1 = lurek.dataframe.fromCSV(csv1)
        local df2 = lurek.dataframe.fromCSV(csv2)
        local result = df1:join(df2, "id", "id", "left")
        expect_equal(3, result:nrows()) -- all 3 left rows
    end)

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
describe("merge", function()
    it("merge appends rows in-place", function()
        local df1 = lurek.dataframe.fromCSV("x\n1\n2")
        local df2 = lurek.dataframe.fromCSV("x\n3\n4")
        df1:merge(df2)
        expect_equal(4, df1:nrows())
    end)

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
describe("countBy", function()
    it("countBy returns DataFrame with value and count", function()
        local csv = "color\nred\nblue\nred\ngreen\nblue"
        local df = lurek.dataframe.fromCSV(csv)
        local result = df:countBy("color")
        expect_equal(3, result:nrows()) -- 3 unique colors
        expect_equal(2, result:ncols()) -- value + count
    end)

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
describe("dropNil", function()
    it("dropNil removes rows with nil in column", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x")
        df:addRow({ x = 1 })
        df:addRow() -- nil
        df:addRow({ x = 3 })
        local result = df:dropNil("x")
        expect_equal(2, result:nrows())
    end)

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
describe("sample", function()
    it("sample returns correct number of rows", function()
        local df = make_test_df()
        local s = df:sample(2, 42)
        expect_equal(2, s:nrows())
    end)

    it("sample with seed is deterministic", function()
        local df = make_test_df()
        local s1 = df:sample(2, 99)
        local s2 = df:sample(2, 99)
        expect_equal(s1:getValue(1, "name"), s2:getValue(1, "name"))
        expect_equal(s1:getValue(2, "name"), s2:getValue(2, "name"))
    end)

    it("sample preserves schema", function()
        local df = make_test_df()
        local s = df:sample(1, 42)
        expect_equal(3, s:ncols())
    end)
end)

-- =========================================================================
-- 18. Describe
-- =========================================================================
describe("describe", function()
    it("describe returns a DataFrame", function()
        local df = make_test_df()
        local stats = df:describe()
        expect_true(stats:nrows() > 0)
        expect_true(stats:ncols() > 0)
    end)

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
describe("analytics", function()
    it("sum computes correct total", function()
        local df = make_test_df()
        -- ages: 30 + 25 + 35 = 90
        expect_near(90, df:sum("age"), 1e-5)
    end)

    it("mean computes correct average", function()
        local df = make_test_df()
        -- ages: (30 + 25 + 35) / 3 = 30
        expect_near(30, df:mean("age"), 1e-5)
    end)

    it("min returns smallest value", function()
        local df = make_test_df()
        expect_near(25, df:min("age"), 1e-5)
    end)

    it("max returns largest value", function()
        local df = make_test_df()
        expect_near(35, df:max("age"), 1e-5)
    end)

    it("median returns middle value", function()
        local df = make_test_df()
        expect_near(30, df:median("age"), 1e-5)
    end)

    it("stddev returns standard deviation", function()
        local df = make_test_df()
        local sd = df:stddev("age")
-- stddev of mean var sd
        expect_true(sd > 0)
    end)

    it("variance returns non-negative value", function()
        local df = make_test_df()
        local v = df:variance("age")
        expect_true(v >= 0)
    end)

    it("sum on scores", function()
        local df = make_test_df()
        -- scores: 90 + 85 + 92 = 267
        expect_near(267, df:sum("score"), 1e-5)
    end)

    it("analytics by column index", function()
        local df = make_test_df()
        -- column 2 = age, sum = 90
        expect_near(90, df:sum(2), 1e-5)
    end)
end)

-- =========================================================================
-- 20. FillNil
-- =========================================================================
describe("fillNil", function()
    it("fillNil replaces nil values", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x")
        df:addRow({ x = 1 })
        df:addRow() -- nil
        df:addRow({ x = 3 })
        df:fillNil("x", 0)
        expect_near(0, df:getValue(2, "x"), 1e-5)
    end)

    it("fillNil does not change non-nil values", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x")
        df:addRow({ x = 5 })
        df:addRow() -- nil
        df:fillNil("x", 0)
        expect_near(5, df:getValue(1, "x"), 1e-5)
    end)

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
describe("apply", function()
    it("apply transforms column values", function()
        local df = lurek.dataframe.fromCSV("x\n1\n2\n3")
        df:apply("x", function(v) return v * 2 end)
        expect_near(2, df:getValue(1, "x"), 1e-5)
        expect_near(4, df:getValue(2, "x"), 1e-5)
        expect_near(6, df:getValue(3, "x"), 1e-5)
    end)

    it("apply can change type", function()
        local df = lurek.dataframe.fromCSV("x\n1\n2\n3")
        df:apply("x", function(v) return "val_" .. tostring(v) end)
        -- tostring of a number may vary; just check it's now a string
        expect_type("string", df:getValue(1, "x"))
    end)

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
describe("serialization", function()
    it("toCSV produces string", function()
        local df = make_test_df()
        local csv = df:toCSV()
        expect_type("string", csv)
        expect_true(#csv > 0)
    end)

    it("toCSV roundtrip preserves data", function()
        local df = make_test_df()
        local csv = df:toCSV()
        local df2 = lurek.dataframe.fromCSV(csv)
        expect_equal(df:nrows(), df2:nrows())
        expect_equal(df:ncols(), df2:ncols())
    end)

    it("toJSON produces string", function()
        local df = make_test_df()
        local json = df:toJSON()
        expect_type("string", json)
        expect_true(#json > 0)
    end)

    it("toJSON roundtrip preserves row count", function()
        local df = make_test_df()
        local json = df:toJSON()
        local df2 = lurek.dataframe.fromJSON(json)
        expect_equal(df:nrows(), df2:nrows())
    end)

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

    it("toTable returns array of row-tables", function()
        local df = make_test_df()
        local t = df:toTable()
        expect_equal(3, #t)
        expect_equal("Alice", t[1].name)
    end)

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
describe("SQL on DataFrame", function()
    it("SELECT * FROM self returns all rows", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self")
        expect_equal(3, result:nrows())
    end)

    it("SELECT with WHERE filters rows", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self WHERE age > 28")
        expect_true(result:nrows() > 0)
        -- All returned ages should be > 28
        for i = 1, result:nrows() do
            expect_true(result:getValue(i, "age") > 28)
        end
    end)

    it("SELECT with ORDER BY sorts", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self ORDER BY age")
        expect_near(25, result:getValue(1, "age"), 1e-5)
    end)

    it("SELECT with LIMIT restricts rows", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self LIMIT 2")
        expect_equal(2, result:nrows())
    end)

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
describe("clone", function()
    it("clone returns independent copy", function()
        local df = make_test_df()
        local c = df:clone()
        df_set_value(c, 1, "name", "Modified")
        expect_equal("Alice", df:getValue(1, "name"))
        expect_equal("Modified", c:getValue(1, "name"))
    end)

    it("clone has same dimensions", function()
        local df = make_test_df()
        local c = df:clone()
        expect_equal(df:nrows(), c:nrows())
        expect_equal(df:ncols(), c:ncols())
    end)

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
describe("type", function()
    it("DataFrame type() returns LDataFrame", function()
        local df = make_test_df()
        expect_equal("LDataFrame", df:type())
    end)

    it("DataFrame typeOf DataFrame is true", function()
        local df = make_test_df()
        expect_true(df:typeOf("DataFrame"))
    end)

    it("DataFrame typeOf wrong type is false", function()
        local df = make_test_df()
        expect_false(df:typeOf("Database"))
    end)
end)

-- =========================================================================
-- 26. Database
-- =========================================================================
describe("Database", function()
    it("newDatabase creates empty database", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal(0, db:tableCount())
    end)

    it("addTable and getTable work", function()
        local db = lurek.dataframe.newDatabase()
        local df = make_test_df()
        db:addTable("users", df)
        local retrieved = db:getTable("users")
        expect_not_nil(retrieved)
        expect_equal(3, retrieved:nrows())
    end)

    it("getTable returns nil for missing table", function()
        local db = lurek.dataframe.newDatabase()
        expect_nil(db:getTable("nonexistent"))
    end)

    it("hasTable returns true for existing table", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("data", make_test_df())
        expect_true(db:hasTable("data"))
    end)

    it("hasTable returns false for missing table", function()
        local db = lurek.dataframe.newDatabase()
        expect_false(db:hasTable("nope"))
    end)

    it("removeTable removes the table", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("data", make_test_df())
        db:removeTable("data")
        expect_false(db:hasTable("data"))
    end)

    it("listTables returns table names", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("alpha", make_test_df())
        db:addTable("beta", make_test_df())
        local names = db:listTables()
        expect_equal(2, #names)
    end)

    it("tableCount reflects additions", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal(0, db:tableCount())
        db:addTable("t1", make_test_df())
        expect_equal(1, db:tableCount())
        db:addTable("t2", make_test_df())
        expect_equal(2, db:tableCount())
    end)

    it("clear removes all tables", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("t1", make_test_df())
        db:addTable("t2", make_test_df())
        db:clear()
        expect_equal(0, db:tableCount())
    end)

    it("merge combines databases", function()
        local db1 = lurek.dataframe.newDatabase()
        db1:addTable("a", make_test_df())
        local db2 = lurek.dataframe.newDatabase()
        db2:addTable("b", make_test_df())
        db1:merge(db2)
        expect_true(db1:hasTable("a"))
        expect_true(db1:hasTable("b"))
    end)

    it("toJSON returns non-empty string", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("t1", make_test_df())
        local json = db:toJSON()
        expect_type("string", json)
        expect_true(#json > 0)
    end)

    it("Database type() returns LDatabase", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal("LDatabase", db:type())
    end)

    it("Database typeOf Database is true", function()
        local db = lurek.dataframe.newDatabase()
        expect_true(db:typeOf("Database"))
    end)

    it("Database typeOf wrong type is false", function()
        local db = lurek.dataframe.newDatabase()
        expect_false(db:typeOf("DataFrame"))
    end)
end)

-- =========================================================================
-- 27. Database SQL
-- =========================================================================
describe("Database SQL", function()
    it("query on single table", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT * FROM users")
        expect_equal(3, result:nrows())
    end)

    it("query with WHERE clause", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT * FROM users WHERE age > 28")
        expect_true(result:nrows() > 0)
    end)

    it("query selecting specific columns", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT name FROM users")
        expect_equal(1, result:ncols())
        expect_equal(3, result:nrows())
    end)
end)

describe("CellValue nil and display (RS parity)", function()
    it("nil cell displays as empty or 'nil' string", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", "number")
        df:addRow({ x = nil })
        local v = df:getValue(1, "x")
        expect_true(v == nil or v == "nil" or v == "")
    end)

    it("number cell round-trips through get", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "n", "number")
        df:addRow({ n = 42 })
        expect_near(42, df:getValue(1, "n"), 0.001)
    end)

    it("text cell round-trips through get", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "s", "text")
        df:addRow({ s = "hello" })
        expect_equal("hello", df:getValue(1, "s"))
    end)

    it("bool cell round-trips through get", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "b", "bool")
        df:addRow({ b = true })
        expect_true(df:getValue(1, "b"))
    end)

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

describe("Database (RS parity)", function()
    it("newDatabase returns userdata", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal("userdata", type(db))
    end)

    it("addTable and getTable round-trip", function()
        local db = lurek.dataframe.newDatabase()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "id", "number")
        db:addTable("users", df)
        local t = db:getTable("users")
        expect_equal("userdata", type(t))
    end)

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
describe("lurek.dataframe.DataFrame analytics", function()

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

    it("withCumsum accumulates correctly", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 1}) df:addRow({v = 2}) df:addRow({v = 3})
        df:withCumsum("v", "cs")
        local row3 = df:getRow(3)
        expect_near(6.0, row3.cs, 0.001)
    end)

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

    it("groupAgg errors on unknown aggregate name", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "cat", "")
        df_add_column(df, "val", 0)
        df:addRow({cat = "A", val = 10})
        expect_error(function()
            df:groupAgg("cat", "val", "nope")
        end)
    end)

    it("corr of column with itself is 1", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", 0)
        df:addRow({x = 1}) df:addRow({x = 2}) df:addRow({x = 3})
        expect_near(1.0, df:corr("x", "x"), 0.001)
    end)

    xit("correlationMatrix includes column header", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "a", 0)
        df_add_column(df, "b", 0)
        df:addRow({a = 1, b = 2})
        df:addRow({a = 2, b = 4})
        local mat = df:correlationMatrix()
        expect_equal("DataFrame", mat:type())
        local cols = mat:columns()
        expect_equal("column", cols[1])
    end)

    it("zscoreCol produces zero-mean column", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        for i = 1, 8 do df:addRow({v = i * 2}) end
        df:zscoreCol("v", "z")
        local total = 0
        for i = 1, 8 do total = total + df:getRow(i).z end
        expect_near(0.0, total / 8, 0.001)
    end)

    it("normalizeCol scales values to output range", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 0}) df:addRow({v = 50}) df:addRow({v = 100})
        df:normalizeCol("v", 0, 1, "n")
        expect_near(0.0, df:getRow(1).n, 0.001)
        expect_near(0.5, df:getRow(2).n, 0.001)
        expect_near(1.0, df:getRow(3).n, 0.001)
    end)

    xit("outliers filters to extreme rows", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        -- Most values near 0, one outlier
        for i = 1, 9 do df:addRow({v = 0}) end
        df:addRow({v = 1000})
        local out = df:outliers("v", 2.0)
        expect_equal(1, out:nrows())
    end)

    it("modeVal returns most frequent value", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "a"}) df:addRow({x = "c"})
        expect_equal("a", df:modeVal("x"))
    end)

    it("entropy of uniform 4-value column is 2 bits", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "c"}) df:addRow({x = "d"})
        expect_near(2.0, df:entropy("x"), 0.001)
    end)

    xit("addRowBatch adds all rows", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRowBatch({{1}, {2}, {3}})
        expect_equal(3, df:nrows())
    end)

    it("getColumnAsF64 returns numeric array", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 10}) df:addRow({v = 20})
        local arr = df:getColumnAsF64("v")
        expect_equal(2, #arr)
        expect_near(10.0, arr[1], 0.001)
        expect_near(20.0, arr[2], 0.001)
    end)

    it("setColumnFromF64 overwrites column with new values", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 0}) df:addRow({v = 0})
        df:setColumnFromF64("v", {7, 14})
        expect_near(7.0, df:getRow(1).v, 0.001)
        expect_near(14.0, df:getRow(2).v, 0.001)
    end)

    xit("pivot creates wide-format DataFrame", function()
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
describe("lurek.dataframe.DataFrame analytics", function()

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

    it("withCumsum accumulates correctly", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 1}) df:addRow({v = 2}) df:addRow({v = 3})
        df:withCumsum("v", "cs")
        local row3 = df:getRow(3)
        expect_near(6.0, row3.cs, 0.001)
    end)

    xit("groupAgg with sum aggregates correctly", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "cat", "")
        df_add_column(df, "val", 0)
        df:addRow({cat = "A", val = 10})
        df:addRow({cat = "B", val = 5})
        df:addRow({cat = "A", val = 20})
        local agg = df:groupAgg("cat", "val", "sum")
        expect_equal(2, agg:nrows())
    end)

    it("corr of column with itself is 1", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", 0)
        df:addRow({x = 1}) df:addRow({x = 2}) df:addRow({x = 3})
        expect_near(1.0, df:corr("x", "x"), 0.001)
    end)

    xit("correlationMatrix includes column header", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "a", 0)
        df_add_column(df, "b", 0)
        df:addRow({a = 1, b = 2})
        df:addRow({a = 2, b = 4})
        local mat = df:correlationMatrix()
        expect_equal("DataFrame", mat:type())
        local cols = mat:columns()
        expect_equal("column", cols[1])
    end)

    it("zscoreCol produces zero-mean column", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        for i = 1, 8 do df:addRow({v = i * 2}) end
        df:zscoreCol("v", "z")
        local total = 0
        for i = 1, 8 do total = total + df:getRow(i).z end
        expect_near(0.0, total / 8, 0.001)
    end)

    it("normalizeCol scales values to output range", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 0}) df:addRow({v = 50}) df:addRow({v = 100})
        df:normalizeCol("v", 0, 1, "n")
        expect_near(0.0, df:getRow(1).n, 0.001)
        expect_near(0.5, df:getRow(2).n, 0.001)
        expect_near(1.0, df:getRow(3).n, 0.001)
    end)

    xit("outliers filters to extreme rows", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        -- Most values near 0, one outlier
        for i = 1, 9 do df:addRow({v = 0}) end
        df:addRow({v = 1000})
        local out = df:outliers("v", 2.0)
        expect_equal(1, out:nrows())
    end)

    it("modeVal returns most frequent value", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "a"}) df:addRow({x = "c"})
        expect_equal("a", df:modeVal("x"))
    end)

    it("entropy of uniform 4-value column is 2 bits", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "c"}) df:addRow({x = "d"})
        expect_near(2.0, df:entropy("x"), 0.001)
    end)

    xit("addRowBatch adds all rows", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRowBatch({{1}, {2}, {3}})
        expect_equal(3, df:nrows())
    end)

    it("getColumnAsF64 returns numeric array", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 10}) df:addRow({v = 20})
        local arr = df:getColumnAsF64("v")
        expect_equal(2, #arr)
        expect_near(10.0, arr[1], 0.001)
        expect_near(20.0, arr[2], 0.001)
    end)

    it("setColumnFromF64 overwrites column with new values", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRow({v = 0}) df:addRow({v = 0})
        df:setColumnFromF64("v", {7, 14})
        expect_near(7.0, df:getRow(1).v, 0.001)
        expect_near(14.0, df:getRow(2).v, 0.001)
    end)

    xit("pivot creates wide-format DataFrame", function()
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

describe("DataFrame: pivotTable", function()

    -- @covers lurek.dataframe.DataFrame.pivotTable
    xit("pivotTable reshapes long to wide with default mean aggregation", function()
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

    -- @covers lurek.dataframe.DataFrame.pivotTable
    xit("pivotTable with sum aggregation", function()
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

    -- @covers lurek.dataframe.DataFrame.pivotTable
    xit("pivotTable with count aggregation", function()
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

describe("DataFrame: rollingMean", function()

    -- @covers lurek.dataframe.DataFrame.rollingMean
    xit("rollingMean appends result column and preserves original", function()
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
-- Row 1: window only 1 predecessor nil
        expect_nil(rm[1], "first row should be nil with window=2")
        -- Row 2: mean(2,4)=3
        expect_near(3.0, rm[2], 0.001)
        -- Row 3: mean(4,6)=5
        expect_near(5.0, rm[3], 0.001)
        -- Row 4: mean(6,8)=7
        expect_near(7.0, rm[4], 0.001)
    end)

    -- @covers lurek.dataframe.DataFrame.rollingMean
    xit("rollingMean uses default result column name", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "score")
        df:addRow({ score = 10 })
        df:addRow({ score = 20 })

        local df2 = df:rollingMean("score", 2)
        local cols = df2:columns()
        expect_equal(2, #cols)
        expect_equal("score", cols[1])
        expect_equal("score_rolling_mean", cols[2])
    end)

end)

describe("DataFrame: rollingSum", function()

    -- @covers lurek.dataframe.DataFrame.rollingSum
    xit("rollingSum produces correct sums", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v")
        df:addRow({ v = 1 })
        df:addRow({ v = 2 })
        df:addRow({ v = 3 })

        local df2 = df:rollingSum("v", 2, "v_rs")
        expect_equal(2, df2:ncols())
        local rs = df2:getColumn("v_rs")
        expect_nil(rs[1])
        expect_near(3.0, rs[2], 0.001)  -- 1+2
        expect_near(5.0, rs[3], 0.001)  -- 2+3
    end)

end)

describe("DataFrame: rank", function()

    -- @covers lurek.dataframe.DataFrame.rank
    xit("rank desc assigns rank 1 to highest score", function()
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

    -- @covers lurek.dataframe.DataFrame.rank
    xit("rank asc assigns rank 1 to lowest score", function()
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

    -- @covers lurek.dataframe.DataFrame.rank
    xit("rank uses default result column name", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "pts")
        df:addRow({ pts = 5 })
        df:addRow({ pts = 3 })

        local df2 = df:rank("pts")
        local cols = df2:columns()
        expect_equal(2, #cols)
        expect_equal("pts_rank", cols[2])
    end)

end)

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @covers DataFrame:min
    it("covers DataFrame:min", function()
        local df = lurek.dataframe.fromCSV("v\n10\n2\n7")
        expect_equal(2, df:min("v"))
    end)

    -- @covers DataFrame:max
    it("covers DataFrame:max", function()
        local df = lurek.dataframe.fromCSV("v\n10\n2\n7")
        expect_equal(10, df:max("v"))
    end)

    -- @covers DataFrame:withEval
    it("withEval adds a computed column with a string expression", function()
        local df = lurek.dataframe.fromCSV("x,y\n1,2\n3,4")
        local out = df:withEval("z", "x + y")
        expect_not_nil(out)
        expect_equal(3, out:ncols())
        expect_equal(3, out:getValue(1, "z"))   -- 1 + 2
        expect_equal(7, out:getValue(2, "z"))   -- 3 + 4
    end)

end)

describe("DataFrame shape accessors", function()
    local function csv3x3()
        return lurek.dataframe.fromCSV("name,age,score\nAlice,30,90\nBob,25,85\nCharlie,35,92")
    end

    -- @covers DataFrame:nrows
    it("nrows returns row count", function()
        expect_equal(3, csv3x3():nrows())
    end)

    -- @covers DataFrame:ncols
    it("ncols returns column count", function()
        expect_equal(3, csv3x3():ncols())
    end)

    -- @covers DataFrame:columns
    it("columns returns an array of column name strings", function()
        local cols = csv3x3():columns()
        expect_type("table", cols)
        expect_equal(3, #cols)
    end)

    -- @covers DataFrame:count
    it("count returns the number of non-nil values in a column", function()
        local df = csv3x3()
        expect_equal(3, df:count("name"))
    end)
end)

describe("DataFrame column/row mutation", function()
    local function make_df()
        return lurek.dataframe.fromCSV("a,b\n1,4\n2,5\n3,6")
    end

    -- @covers DataFrame:removeColumn
    it("removeColumn removes a column", function()
        local df = make_df()
        df_remove_column(df, "b")
        expect_equal(1, df:ncols())
    end)

    -- @covers DataFrame:rename
    it("rename renames a column", function()
        local df = make_df()
        df:rename("a", "aa")
        local cols = df:columns()
        local found = false
        for _, c in ipairs(cols) do if c == "aa" then found = true end end
        expect_equal(true, found)
    end)

    -- @covers DataFrame:getColumn
    it("getColumn returns an array of values", function()
        local df = make_df()
        local col = df:getColumn("a")
        expect_type("table", col)
        expect_equal(3, #col)
    end)

    -- @covers DataFrame:addRow
    it("addRow increases nrows by 1", function()
        local df = make_df()
        df:addRow({ a = 99, b = 88 })
        expect_equal(4, df:nrows())
    end)

    -- @covers DataFrame:removeRow
    it("removeRow decreases nrows by 1", function()
        local df = make_df()
        df:removeRow(1)
        expect_equal(2, df:nrows())
    end)

    -- @covers DataFrame:getRow
    it("getRow returns a table with column keys", function()
        local df = make_df()
        local row = df:getRow(1)
        expect_type("table", row)
        expect_equal(1, row.a)
    end)

    -- @covers DataFrame:getValue
    it("getValue returns the cell value at (row, col)", function()
        local df = make_df()
        expect_equal(2, df:getValue(2, "a"))
    end)
end)

describe("DataFrame slicing and filtering", function()
    local function nums_df()
        -- 5 rows, col 'v'
        return lurek.dataframe.fromCSV("v\n10\n20\n30\n40\n50")
    end

    -- @covers DataFrame:head
    it("head(2) returns first 2 rows", function()
        local h = nums_df():head(2)
        expect_equal(2, h:nrows())
        expect_equal(10, h:getValue(1, "v"))
    end)

    -- @covers DataFrame:tail
    it("tail(2) returns last 2 rows", function()
        local t = nums_df():tail(2)
        expect_equal(2, t:nrows())
        expect_equal(50, t:getValue(2, "v"))
    end)

    -- @covers DataFrame:slice
    it("slice(2,4) returns rows 2 to 4", function()
        local s = nums_df():slice(2, 4)
        expect_equal(3, s:nrows())
        expect_equal(20, s:getValue(1, "v"))
    end)

    -- @covers DataFrame:select
    it("select with vararg column names keeps only those columns", function()
        local df = lurek.dataframe.fromCSV("a,b,c\n1,2,3\n4,5,6")
        local out = df:select("a", "c")
        expect_equal(2, out:ncols())
    end)

    -- @covers DataFrame:unique
    it("unique returns an array of distinct values", function()
        local df = lurek.dataframe.fromCSV("x\n1\n1\n2\n3\n2")
        local vals = df:unique("x")
        expect_type("table", vals)
        expect_equal(3, #vals)
    end)

    -- @covers DataFrame:groupBy
    it("groupBy returns a table of DataFrames keyed by group value", function()
        local df = lurek.dataframe.fromCSV("cat,v\nA,1\nB,2\nA,3")
        local groups = df:groupBy("cat")
        expect_type("table", groups)
    end)

    -- @covers DataFrame:merge
    it("merge appends rows from another DataFrame in-place", function()
        local left  = lurek.dataframe.fromCSV("id,x\n1,10\n2,20")
        local right = lurek.dataframe.fromCSV("id,x\n3,30\n4,40")
        left:merge(right)
        expect_equal(4, left:nrows())
    end)

    -- @covers DataFrame:countBy
    it("countBy returns a DataFrame with count column", function()
        local df = lurek.dataframe.fromCSV("cat\nA\nB\nA\nA")
        local counts = df:countBy("cat")
        expect_not_nil(counts)
        -- countBy returns a DataFrame userdata (value, count columns)
        expect_equal(2, counts:nrows())   -- 2 distinct values: A, B
    end)

    -- @covers DataFrame:dropNil
    it("dropNil removes rows with nil in a column", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "x", 0)
        df:addRow({ x = 1 })
        df:addRow({ x = nil })
        df:addRow({ x = 3 })
        local out = df:dropNil("x")
        expect_equal(2, out:nrows())
    end)

    -- @covers DataFrame:sample
    it("sample(2) returns exactly 2 rows", function()
        local out = nums_df():sample(2)
        expect_equal(2, out:nrows())
    end)
end)

-- =========================================================================
-- Vectorized VecFrame API (lurek.dataframe.toVec / fromVec)
-- =========================================================================

-- @covers lurek.dataframe.toVec
-- @covers lurek.dataframe.fromVec
describe("lurek.dataframe vectorized factory functions", function()
    it("toVec is a function", function()
        -- @covers lurek.dataframe.toVec
        expect_type("function", lurek.dataframe.toVec)
    end)

    it("fromVec is a function", function()
        -- @covers lurek.dataframe.fromVec
        expect_type("function", lurek.dataframe.fromVec)
    end)

    it("toVec returns a VecFrame userdata", function()
        -- @covers lurek.dataframe.toVec
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n")
        local vf = lurek.dataframe.toVec(df)
        assert(vf ~= nil, "toVec returned nil")
        assert(type(vf) == "userdata", "expected userdata")
    end)

    it("fromVec converts VecFrame back to DataFrame", function()
        -- @covers lurek.dataframe.fromVec
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n")
        local vf = lurek.dataframe.toVec(df)
        local df2 = lurek.dataframe.fromVec(vf)
        assert(df2 ~= nil, "fromVec returned nil")
    end)
end)

-- @covers VecFrame:nrows
-- @covers VecFrame:ncols
-- @covers VecFrame:columns
describe("VecFrame shape queries", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    it("nrows returns correct row count", function()
        -- @covers VecFrame:nrows
        local vf = make_vf()
        assert(vf:nrows() == 3, "expected nrows=3, got " .. tostring(vf:nrows()))
    end)

    it("ncols returns correct column count", function()
        -- @covers VecFrame:ncols
        local vf = make_vf()
        assert(vf:ncols() == 2, "expected ncols=2, got " .. tostring(vf:ncols()))
    end)

    it("columns returns table of column names", function()
        -- @covers VecFrame:columns
        local vf = make_vf()
        local cols = vf:columns()
        assert(type(cols) == "table", "expected table")
        assert(cols[1] == "hp", "expected cols[1]='hp', got " .. tostring(cols[1]))
        assert(cols[2] == "mp", "expected cols[2]='mp', got " .. tostring(cols[2]))
    end)
end)

-- @covers VecFrame:colType
-- @covers VecFrame:colCast
describe("VecFrame type inspection and casting", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n")
        return lurek.dataframe.toVec(df)
    end

    it("colType returns float64 for numeric column", function()
        -- @covers VecFrame:colType
        local vf = make_vf()
        assert(vf:colType("hp") == "float64", "expected float64, got " .. tostring(vf:colType("hp")))
    end)

    it("colType returns nil for nonexistent column", function()
        -- @covers VecFrame:colType
        local vf = make_vf()
        assert(vf:colType("NOPE") == nil, "expected nil for missing column")
    end)

    it("colCast float64 to int64 changes type", function()
        -- @covers VecFrame:colCast
        local vf = make_vf()
        vf:colCast("hp", "int64")
        assert(vf:colType("hp") == "int64", "expected int64 after cast")
    end)

    it("colCast int64 back to float64 changes type", function()
        -- @covers VecFrame:colCast
        local vf = make_vf()
        vf:colCast("hp", "int64")
        vf:colCast("hp", "float64")
        assert(vf:colType("hp") == "float64", "expected float64 after cast back")
    end)
end)

-- @covers VecFrame:colAdd
-- @covers VecFrame:colSub
-- @covers VecFrame:colMul
-- @covers VecFrame:colDiv
-- @covers VecFrame:colAbs
-- @covers VecFrame:colSqrt
-- @covers VecFrame:colFloor
-- @covers VecFrame:colCeil
-- @covers VecFrame:colNeg
-- @covers VecFrame:colClamp
describe("VecFrame scalar column operations", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    local function first(vf, col)
        local df2 = vf:toDataFrame()
        return df2:getValue(0, col)
    end

    it("colAdd adds scalar to every row", function()
        -- @covers VecFrame:colAdd
        local vf = make_vf()
        vf:colAdd("hp", 5)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "hp")
        assert(v ~= nil, "colAdd: got nil")
        assert(math.abs(v - 15) < 0.0001, "expected 15, got " .. tostring(v))
    end)

    xit("colSub subtracts scalar from every row", function()
        -- @covers VecFrame:colSub
        local vf = make_vf()
        vf:colSub("hp", 5)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(0, "hp")
        assert(math.abs(v - 5) < 0.0001, "expected 5, got " .. tostring(v))
    end)

    it("colMul multiplies every row by scalar", function()
        -- @covers VecFrame:colMul
        local vf = make_vf()
        vf:colMul("hp", 3)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "hp")
        assert(math.abs(v - 30) < 0.0001, "expected 30, got " .. tostring(v))
    end)

    it("colDiv divides every row by scalar", function()
        -- @covers VecFrame:colDiv
        local vf = make_vf()
        vf:colDiv("hp", 2)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "hp")
        assert(math.abs(v - 5) < 0.0001, "expected 5, got " .. tostring(v))
    end)

    it("colAbs makes all values non-negative", function()
        -- @covers VecFrame:colAbs
        local df = lurek.dataframe.fromCSV("v\n-3\n4\n-1.5\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colAbs("v")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "v")
        assert(v ~= nil and v >= 0, "expected non-negative, got " .. tostring(v))
    end)

    it("colSqrt takes sqrt of every row", function()
        -- @covers VecFrame:colSqrt
        local df = lurek.dataframe.fromCSV("v\n9\n4\n1\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colSqrt("v")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "v")
        assert(math.abs(v - 3) < 0.0001, "expected 3, got " .. tostring(v))
    end)

    xit("colFloor floors every element", function()
        -- @covers VecFrame:colFloor
        local df = lurek.dataframe.fromCSV("v\n1.9\n2.5\n3.1\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colFloor("v")
        local df2 = lurek.dataframe.fromVec(vf)
        assert(math.abs(df2:getValue(0, "v") - 1) < 0.0001, "expected 1")
    end)

    xit("colCeil ceils every element", function()
        -- @covers VecFrame:colCeil
        local df = lurek.dataframe.fromCSV("v\n1.1\n2.5\n3.9\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colCeil("v")
        local df2 = lurek.dataframe.fromVec(vf)
        assert(math.abs(df2:getValue(0, "v") - 2) < 0.0001, "expected 2")
    end)

    xit("colNeg negates every element", function()
        -- @covers VecFrame:colNeg
        local df = lurek.dataframe.fromCSV("v\n5\n10\n15\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colNeg("v")
        local df2 = lurek.dataframe.fromVec(vf)
        assert(math.abs(df2:getValue(0, "v") - (-5)) < 0.0001, "expected -5")
    end)

    it("colClamp clamps values to [min, max]", function()
        -- @covers VecFrame:colClamp
        local vf = make_vf()
        vf:colClamp("hp", 15, 25)
        local df2 = lurek.dataframe.fromVec(vf)
        local v0 = df2:getValue(1, "hp")
        assert(math.abs(v0 - 15) < 0.0001, "expected 15 (clamped), got " .. tostring(v0))
        local v1 = df2:getValue(2, "hp")
        assert(math.abs(v1 - 20) < 0.0001, "expected 20, got " .. tostring(v1))
        local v2 = df2:getValue(3, "hp")
        assert(math.abs(v2 - 25) < 0.0001, "expected 25 (clamped), got " .. tostring(v2))
    end)

    it("colDiv by zero errors", function()
        -- @covers VecFrame:colDiv
        local vf = make_vf()
        expect_error(function()
            vf:colDiv("hp", 0)
        end)
    end)

    it("scalar ops on text columns error", function()
        -- @covers VecFrame:colAdd
        local df = lurek.dataframe.fromCSV("name\nAlice\nBob\n")
        local vf = lurek.dataframe.toVec(df)
        expect_error(function()
            vf:colAdd("name", 1)
        end)
    end)
end)

-- @covers VecFrame:colOp
describe("VecFrame binary column operations", function()
    it("colOp add computes element-wise sum", function()
        -- @covers VecFrame:colOp
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colOp("total", "hp", "add", "mp")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "total")
        assert(v ~= nil and math.abs(v - 15) < 0.0001, "expected 15, got " .. tostring(v))
    end)

    it("colOp mul computes element-wise product", function()
        -- @covers VecFrame:colOp
        local df = lurek.dataframe.fromCSV("a,b\n3,4\n5,6\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colOp("product", "a", "mul", "b")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:getValue(1, "product")
        assert(v ~= nil and math.abs(v - 12) < 0.0001, "expected 12, got " .. tostring(v))
    end)

    xit("colOp min picks element-wise minimum", function()
        -- @covers VecFrame:colOp
        local df = lurek.dataframe.fromCSV("a,b\n3,7\n8,2\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colOp("m", "a", "min", "b")
        local df2 = lurek.dataframe.fromVec(vf)
        assert(math.abs(df2:getValue(0, "m") - 3) < 0.0001, "expected 3")
        assert(math.abs(df2:getValue(1, "m") - 2) < 0.0001, "expected 2")
    end)
end)

-- @covers VecFrame:reduce
describe("VecFrame reductions", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    it("reduce sum returns correct total", function()
        -- @covers VecFrame:reduce
        local vf = make_vf()
        local s = vf:reduce("hp", "sum")
        assert(s ~= nil and math.abs(s - 60) < 0.0001, "expected 60, got " .. tostring(s))
    end)

    it("reduce mean returns correct average", function()
        -- @covers VecFrame:reduce
        local vf = make_vf()
        local m = vf:reduce("hp", "mean")
        assert(m ~= nil and math.abs(m - 20) < 0.0001, "expected 20, got " .. tostring(m))
    end)

    it("reduce min returns minimum value", function()
        -- @covers VecFrame:reduce
        local vf = make_vf()
        assert(vf:reduce("hp", "min") == 10, "expected 10")
    end)

    it("reduce max returns maximum value", function()
        -- @covers VecFrame:reduce
        local vf = make_vf()
        assert(vf:reduce("hp", "max") == 30, "expected 30")
    end)

    it("reduce count returns row count", function()
        -- @covers VecFrame:reduce
        local vf = make_vf()
        assert(vf:reduce("hp", "count") == 3, "expected 3")
    end)

    it("reduce std is near 0 for constant column", function()
        -- @covers VecFrame:reduce
        local df = lurek.dataframe.fromCSV("v\n5\n5\n5\n")
        local vf = lurek.dataframe.toVec(df)
        local s = vf:reduce("v", "std")
        assert(s ~= nil and math.abs(s) < 0.0001, "expected near 0, got " .. tostring(s))
    end)

    it("reduce count skips nil rows after toVec conversion", function()
        -- @covers VecFrame:reduce
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v")
        df:addRow({ v = 1 })
        df:addRow()
        df:addRow({ v = 3 })
        local vf = lurek.dataframe.toVec(df)
        assert(vf:reduce("v", "count") == 2, "expected count=2")
    end)

    it("reduce on missing column errors", function()
        -- @covers VecFrame:reduce
        local vf = make_vf()
        expect_error(function()
            vf:reduce("NOPE", "sum")
        end)
    end)
end)

-- @covers VecFrame:filterMask
-- @covers VecFrame:applyMask
describe("VecFrame filter and mask", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    it("filterMask > returns correct boolean array", function()
        -- @covers VecFrame:filterMask
        local vf = make_vf()
        local mask = vf:filterMask("hp", ">", 15)
        assert(type(mask) == "table", "expected table")
        assert(mask[1] == false, "row 0 (hp=10) should be false")
        assert(mask[2] == true,  "row 1 (hp=20) should be true")
        assert(mask[3] == true,  "row 2 (hp=30) should be true")
    end)

    it("filterMask <= returns correct boolean array", function()
        -- @covers VecFrame:filterMask
        local vf = make_vf()
        local mask = vf:filterMask("hp", "<=", 20)
        assert(mask[1] == true, "row 0 (hp=10) should be true")
        assert(mask[2] == true, "row 1 (hp=20) should be true")
        assert(mask[3] == false, "row 2 (hp=30) should be false")
    end)

    it("applyMask returns filtered VecFrame with correct row count", function()
        -- @covers VecFrame:applyMask
        local vf = make_vf()
        local mask = vf:filterMask("hp", ">", 15)
        local filtered = vf:applyMask(mask)
        assert(filtered:nrows() == 2, "expected 2 rows, got " .. tostring(filtered:nrows()))
    end)

    it("applyMask combined reduce gives correct sum", function()
        -- @covers VecFrame:applyMask
        local vf = make_vf()
        local mask = vf:filterMask("hp", ">=", 20)
        local filtered = vf:applyMask(mask)
        local s = filtered:reduce("hp", "sum")
        assert(math.abs(s - 50) < 0.0001, "expected 50, got " .. tostring(s))
    end)

    it("applyMask with wrong mask length errors", function()
        -- @covers VecFrame:applyMask
        local vf = make_vf()
        expect_error(function()
            vf:applyMask({ true, false })
        end)
    end)
end)

-- @covers VecFrame:parReduce
-- @covers VecFrame:parScalarOp
describe("VecFrame parallel operations", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    it("parReduce sum across multiple columns", function()
        -- @covers VecFrame:parReduce
        local vf = make_vf()
        local result = vf:parReduce({"hp", "mp"}, "sum")
        assert(type(result) == "table", "expected table")
        assert(math.abs(result["hp"] - 60) < 0.0001, "expected hp sum=60, got " .. tostring(result["hp"]))
        assert(math.abs(result["mp"] - 30) < 0.0001, "expected mp sum=30, got " .. tostring(result["mp"]))
    end)

    it("parScalarOp mul across multiple columns", function()
        -- @covers VecFrame:parScalarOp
        local vf = make_vf()
        vf:parScalarOp({"hp", "mp"}, "mul", 2)
        local df2 = lurek.dataframe.fromVec(vf)
        local hp0 = df2:getValue(1, "hp")
        local mp0 = df2:getValue(1, "mp")
        assert(math.abs(hp0 - 20) < 0.0001, "expected hp=20, got " .. tostring(hp0))
        assert(math.abs(mp0 - 10) < 0.0001, "expected mp=10, got " .. tostring(mp0))
    end)
end)

-- @covers VecFrame:toDataFrame
describe("VecFrame conversion roundtrip", function()
    it("toDataFrame preserves modified values after vector ops", function()
        -- @covers VecFrame:toDataFrame
        local df = lurek.dataframe.fromCSV("hp,mp\n100,50\n200,100\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colMul("hp", 0.5)
        vf:colAdd("mp", 10)
        local df2 = vf:toDataFrame()
        local hp0 = df2:getValue(1, "hp")
        local mp0 = df2:getValue(1, "mp")
        assert(math.abs(hp0 - 50) < 0.0001, "expected hp=50, got " .. tostring(hp0))
        assert(math.abs(mp0 - 60) < 0.0001, "expected mp=60, got " .. tostring(mp0))
    end)
end)

describe("DataFrame statistics", function()
    local function num_df()
        return lurek.dataframe.fromCSV("v\n10\n20\n30\n40")
    end

    -- @covers DataFrame:describe
    it("describe returns a DataFrame with descriptive statistics", function()
        local d = num_df():describe()
        expect_not_nil(d)
        -- describe returns a DataFrame (userdata) with stat rows
        expect_true(d:nrows() > 0, "describe must return at least one row")
    end)

    -- @covers DataFrame:sum
    it("sum of {10,20,30,40} = 100", function()
        expect_equal(100, num_df():sum("v"))
    end)

    -- @covers DataFrame:mean
    it("mean of {10,20,30,40} = 25", function()
        expect_equal(25, num_df():mean("v"))
    end)

    -- @covers DataFrame:median
    it("median returns a number", function()
        expect_type("number", num_df():median("v"))
    end)

    -- @covers DataFrame:stddev
    it("stddev returns a non-negative number", function()
        local s = num_df():stddev("v")
        expect_type("number", s)
        expect_true(s >= 0, "stddev must be non-negative")
    end)

    -- @covers DataFrame:variance
    it("variance returns a non-negative number", function()
        local v = num_df():variance("v")
        expect_type("number", v)
        expect_true(v >= 0, "variance must be non-negative")
    end)

    -- @covers DataFrame:modeVal
    it("modeVal returns the most frequent value", function()
        local df = lurek.dataframe.fromCSV("v\n1\n2\n2\n3")
        local m = df:modeVal("v")
        expect_equal(2, m)
    end)

    -- @covers DataFrame:entropy
    it("entropy returns a non-negative number", function()
        local df = lurek.dataframe.fromCSV("v\n1\n2\n2\n3")
        local e = df:entropy("v")
        expect_type("number", e)
        expect_true(e >= 0, "entropy must be non-negative")
    end)

    -- @covers DataFrame:correlationMatrix
    it("correlationMatrix returns a DataFrame or table", function()
        local df = lurek.dataframe.fromCSV("a,b\n1,4\n2,5\n3,6")
        local cm = df:correlationMatrix()
        expect_not_nil(cm)
    end)
end)

describe("DataFrame nil handling", function()
    -- @covers DataFrame:fillNil
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

describe("DataFrame serialization", function()
    local function alpha_df()
        return lurek.dataframe.fromCSV("name,val\nAlice,1\nBob,2")
    end

    -- @covers DataFrame:toCSV
    it("toCSV returns a non-empty string", function()
        local csv = alpha_df():toCSV()
        expect_type("string", csv)
        expect_true(#csv > 5, "CSV output must not be empty")
    end)

    -- @covers DataFrame:toJSON
    it("toJSON returns a non-empty string", function()
        local json = alpha_df():toJSON()
        expect_type("string", json)
        expect_true(#json > 2, "JSON output must not be empty")
    end)

    -- @covers DataFrame:toBinary
    it("toBinary returns a non-empty string", function()
        local bin = alpha_df():toBinary()
        expect_type("string", bin)
        expect_true(#bin > 0, "binary output must not be empty")
    end)

    -- @covers DataFrame:toTable
    it("toTable returns a Lua array of row tables", function()
        local rows = alpha_df():toTable()
        expect_type("table", rows)
        expect_equal(2, #rows)
        expect_equal("Alice", rows[1].name)
    end)

    -- @covers DataFrame:toString
    it("toString returns a non-empty string", function()
        local s = alpha_df():toString()
        expect_type("string", s)
        expect_true(#s > 0, "string representation must not be empty")
    end)
end)

describe("DataFrame query and clone", function()
    -- @covers DataFrame:query
    it("query returns a filtered DataFrame via SQL", function()
        local df = lurek.dataframe.fromCSV("v\n10\n20\n30")
        local out = df:query("SELECT * FROM df WHERE v > 15")
        expect_not_nil(out)
        expect_equal(2, out:nrows())
    end)

    -- @covers DataFrame:clone
    it("clone produces an independent copy", function()
        local df = lurek.dataframe.fromCSV("v\n1\n2\n3")
        local copy = df:clone()
        expect_equal(3, copy:nrows())
        copy:removeRow(1)
        expect_equal(3, df:nrows())  -- original unchanged
    end)
end)

describe("DataFrame bulk row ops and typed columns", function()
    -- @covers DataFrame:addRowBatch
    it("addRowBatch adds multiple rows at once", function()
        local df = lurek.dataframe.newDataFrame()
        df_add_column(df, "v", 0)
        df:addRowBatch({{ v = 1 }, { v = 2 }, { v = 3 }})
        expect_equal(3, df:nrows())
    end)

    -- @covers DataFrame:getColumnAsF64
    it("getColumnAsF64 returns a number array", function()
        local df = lurek.dataframe.fromCSV("v\n1\n2\n3")
        local nums = df:getColumnAsF64("v")
        expect_type("table", nums)
        expect_equal(3, #nums)
        expect_equal(1, nums[1])
    end)

    -- @covers DataFrame:setColumnFromF64
    it("setColumnFromF64 writes values back into a column", function()
        local df = lurek.dataframe.fromCSV("v\n1\n2\n3")
        df:setColumnFromF64("v", {10, 20, 30})
        expect_equal(10, df:getValue(1, "v"))
        expect_equal(30, df:getValue(3, "v"))
    end)

    -- @covers DataFrame:type
    it("type returns 'LDataFrame'", function()
        local df = lurek.dataframe.newDataFrame()
        expect_equal("LDataFrame", df:type())
    end)

    -- @covers DataFrame:typeOf
    it("typeOf('LDataFrame') returns true", function()
        local df = lurek.dataframe.newDataFrame()
        expect_equal(true, df:typeOf("LDataFrame"))
    end)
end)

describe("Database operations", function()
    local function make_db()
        local db = lurek.dataframe.newDatabase()
        local df = lurek.dataframe.fromCSV("x\n1\n2")
        db:addTable("test", df)
        return db
    end

    -- @covers Database:getTable
    it("getTable returns the stored DataFrame", function()
        local db = make_db()
        local t = db:getTable("test")
        expect_not_nil(t)
        expect_equal(2, t:nrows())
    end)

    -- @covers Database:hasTable
    it("hasTable returns true after addTable", function()
        local db = make_db()
        expect_equal(true, db:hasTable("test"))
        expect_equal(false, db:hasTable("__missing__"))
    end)

    -- @covers Database:removeTable
    it("removeTable decreases tableCount by 1", function()
        local db = make_db()
        db:removeTable("test")
        expect_equal(false, db:hasTable("test"))
    end)

    -- @covers Database:listTables
    it("listTables returns an array of table name strings", function()
        local db = make_db()
        local names = db:listTables()
        expect_type("table", names)
        expect_equal(1, #names)
        expect_equal("test", names[1])
    end)

    -- @covers Database:tableCount
    it("tableCount returns 1 after addTable", function()
        expect_equal(1, make_db():tableCount())
    end)

    -- @covers Database:clear
    it("clear removes all tables", function()
        local db = make_db()
        db:clear()
        expect_equal(0, db:tableCount())
    end)

    -- @covers Database:merge
    it("merge adds all tables from another database", function()
        local db1 = make_db()
        local db2 = lurek.dataframe.newDatabase()
        db2:addTable("other", lurek.dataframe.fromCSV("y\n9"))
        db1:merge(db2)
        expect_equal(2, db1:tableCount())
    end)

    -- @covers Database:toJSON
    it("toJSON returns a non-empty string", function()
        local json = make_db():toJSON()
        expect_type("string", json)
        expect_true(#json > 2, "JSON must not be empty")
    end)

    -- @covers Database:query
    it("query returns a DataFrame from a SQL-like expression", function()
        local db = make_db()
        local result = db:query("SELECT * FROM test WHERE x > 1")
        expect_not_nil(result)
    end)

    -- @covers Database:type
    it("type returns 'LDatabase'", function()
        expect_equal("LDatabase", lurek.dataframe.newDatabase():type())
    end)

    -- @covers Database:typeOf
    it("typeOf('LDatabase') returns true", function()
        expect_equal(true, lurek.dataframe.newDatabase():typeOf("LDatabase"))
    end)
end)

-- =========================================================================
-- Phase 06: grouped:aggregate with Lua callback
-- =========================================================================
describe("grouped:aggregate with Lua callback", function()
    it("groupByObj method exists on DataFrame", function()
        local df = lurek.dataframe.newDataFrame()
        expect_equal(type(df.groupByObj), "function")
    end)

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

test_summary()
