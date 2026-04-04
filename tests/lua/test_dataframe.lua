-- Luna2D DataFrame Tests
-- Tests for luna.dataframe tabular data API

-- Helper to build a simple test DataFrame
local function make_test_df()
    local csv = "name,age,score\nAlice,30,90\nBob,25,85\nCharlie,35,92"
    return luna.dataframe.fromCSV(csv)
end

-- =========================================================================
-- 1. Module existence
-- =========================================================================
describe("luna.dataframe module exists", function()
    it("luna.dataframe is a table", function()
        expect_type("table", luna.dataframe)
    end)

    it("has newDataFrame factory", function()
        expect_type("function", luna.dataframe.newDataFrame)
    end)

    it("has newDatabase factory", function()
        expect_type("function", luna.dataframe.newDatabase)
    end)

    it("has fromTable factory", function()
        expect_type("function", luna.dataframe.fromTable)
    end)

    it("has fromCSV factory", function()
        expect_type("function", luna.dataframe.fromCSV)
    end)

    it("has fromJSON factory", function()
        expect_type("function", luna.dataframe.fromJSON)
    end)

    it("has fromBinary factory", function()
        expect_type("function", luna.dataframe.fromBinary)
    end)

    it("has random factory", function()
        expect_type("function", luna.dataframe.random)
    end)
end)

-- =========================================================================
-- 2. Construction
-- =========================================================================
describe("construction", function()
    it("newDataFrame creates empty DataFrame", function()
        local df = luna.dataframe.newDataFrame()
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
        local df = luna.dataframe.fromTable({
            { x = 1, y = 2 },
            { x = 3, y = 4 },
        })
        expect_equal(2, df:nrows())
        expect_equal(2, df:ncols())
    end)

    it("fromJSON creates DataFrame", function()
        local json = '[{"a":1,"b":"hello"},{"a":2,"b":"world"}]'
        local df = luna.dataframe.fromJSON(json)
        expect_equal(2, df:nrows())
    end)

    it("random creates DataFrame with specified rows", function()
        local defs = { {"x", "float"}, {"y", "float"} }
        local df = luna.dataframe.random(defs, 10, 42)
        expect_equal(10, df:nrows())
        expect_equal(2, df:ncols())
    end)

    it("random with seed is deterministic", function()
        local defs = { {"val", "float"} }
        local df1 = luna.dataframe.random(defs, 5, 123)
        local df2 = luna.dataframe.random(defs, 5, 123)
        for i = 1, 5 do
            expect_near(df1:getValue(i, "val"), df2:getValue(i, "val"), 1e-5)
        end
    end)

    it("fromCSV with empty body creates empty DataFrame", function()
        local df = luna.dataframe.fromCSV("x,y")
        expect_equal(0, df:nrows())
        expect_equal(2, df:ncols())
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
        df:addColumn("grade")
        expect_equal(4, df:ncols())
    end)

    it("addColumn with default fills all rows", function()
        local df = make_test_df()
        df:addColumn("pass", true)
        for i = 1, df:nrows() do
            expect_equal(true, df:getValue(i, "pass"))
        end
    end)

    it("removeColumn by name decreases ncols", function()
        local df = make_test_df()
        df:removeColumn("age")
        expect_equal(2, df:ncols())
    end)

    it("removeColumn by index decreases ncols", function()
        local df = make_test_df()
        df:removeColumn(2)
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
        df:setValue(1, "name", "Alicia")
        expect_equal("Alicia", df:getValue(1, "name"))
    end)

    it("setValue by column index", function()
        local df = make_test_df()
        df:setValue(2, 2, 99)
        expect_near(99, df:getValue(2, "age"), 1e-5)
    end)

    it("setValue to nil clears cell", function()
        local df = make_test_df()
        df:setValue(1, "name", nil)
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
        local df = luna.dataframe.fromCSV(csv)
        local u = df:unique("color")
        expect_equal(3, #u)
    end)

    it("unique on numeric column", function()
        local csv = "x\n1\n2\n1\n3\n2"
        local df = luna.dataframe.fromCSV(csv)
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
        local df = luna.dataframe.fromCSV(csv)
        local groups = df:groupBy("dept")
        expect_type("table", groups)
    end)

    it("groupBy subsets have correct row counts", function()
        local csv = "dept,name\nHR,Alice\nIT,Bob\nHR,Charlie\nIT,Dave"
        local df = luna.dataframe.fromCSV(csv)
        local groups = df:groupBy("dept")
        local count = 0
        for _, sub in pairs(groups) do
            count = count + sub:nrows()
        end
        expect_equal(4, count)
    end)

    it("groupBy preserves column structure", function()
        local csv = "dept,name\nHR,Alice\nIT,Bob"
        local df = luna.dataframe.fromCSV(csv)
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
        local df1 = luna.dataframe.fromCSV(csv1)
        local df2 = luna.dataframe.fromCSV(csv2)
        local result = df1:join(df2, "id", "id", "inner")
        expect_equal(2, result:nrows()) -- only ids 1 and 2 match
    end)

    it("left join keeps all left rows", function()
        local csv1 = "id,name\n1,Alice\n2,Bob\n3,Charlie"
        local csv2 = "id,dept\n1,HR\n2,IT\n4,Finance"
        local df1 = luna.dataframe.fromCSV(csv1)
        local df2 = luna.dataframe.fromCSV(csv2)
        local result = df1:join(df2, "id", "id", "left")
        expect_equal(3, result:nrows()) -- all 3 left rows
    end)

    it("join defaults to inner", function()
        local csv1 = "id,name\n1,Alice\n2,Bob"
        local csv2 = "id,dept\n1,HR\n3,Finance"
        local df1 = luna.dataframe.fromCSV(csv1)
        local df2 = luna.dataframe.fromCSV(csv2)
        local result = df1:join(df2, "id", "id")
        expect_equal(1, result:nrows()) -- only id 1 matches
    end)
end)

-- =========================================================================
-- 14. Merge
-- =========================================================================
describe("merge", function()
    it("merge appends rows in-place", function()
        local df1 = luna.dataframe.fromCSV("x\n1\n2")
        local df2 = luna.dataframe.fromCSV("x\n3\n4")
        df1:merge(df2)
        expect_equal(4, df1:nrows())
    end)

    it("merge preserves original data", function()
        local df1 = luna.dataframe.fromCSV("x\n1\n2")
        local df2 = luna.dataframe.fromCSV("x\n3\n4")
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
        local df = luna.dataframe.fromCSV(csv)
        local result = df:countBy("color")
        expect_equal(3, result:nrows()) -- 3 unique colors
        expect_equal(2, result:ncols()) -- value + count
    end)

    it("countBy counts are correct", function()
        local csv = "color\nred\nblue\nred\nred\nblue"
        local df = luna.dataframe.fromCSV(csv)
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
        local df = luna.dataframe.newDataFrame()
        df:addColumn("x")
        df:addRow({ x = 1 })
        df:addRow() -- nil
        df:addRow({ x = 3 })
        local result = df:dropNil("x")
        expect_equal(2, result:nrows())
    end)

    it("dropNil preserves non-nil rows", function()
        local df = luna.dataframe.newDataFrame()
        df:addColumn("x")
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
        -- stddev of [25,30,35]: mean=30, var=(25+0+25)/3=50/3, sd≈4.082
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
        local df = luna.dataframe.newDataFrame()
        df:addColumn("x")
        df:addRow({ x = 1 })
        df:addRow() -- nil
        df:addRow({ x = 3 })
        df:fillNil("x", 0)
        expect_near(0, df:getValue(2, "x"), 1e-5)
    end)

    it("fillNil does not change non-nil values", function()
        local df = luna.dataframe.newDataFrame()
        df:addColumn("x")
        df:addRow({ x = 5 })
        df:addRow() -- nil
        df:fillNil("x", 0)
        expect_near(5, df:getValue(1, "x"), 1e-5)
    end)

    it("fillNil with string value", function()
        local df = luna.dataframe.newDataFrame()
        df:addColumn("name")
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
        local df = luna.dataframe.fromCSV("x\n1\n2\n3")
        df:apply("x", function(v) return v * 2 end)
        expect_near(2, df:getValue(1, "x"), 1e-5)
        expect_near(4, df:getValue(2, "x"), 1e-5)
        expect_near(6, df:getValue(3, "x"), 1e-5)
    end)

    it("apply can change type", function()
        local df = luna.dataframe.fromCSV("x\n1\n2\n3")
        df:apply("x", function(v) return "val_" .. tostring(v) end)
        -- tostring of a number may vary; just check it's now a string
        expect_type("string", df:getValue(1, "x"))
    end)

    it("apply with identity preserves values", function()
        local df = luna.dataframe.fromCSV("x\n10\n20")
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
        local df2 = luna.dataframe.fromCSV(csv)
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
        local df2 = luna.dataframe.fromJSON(json)
        expect_equal(df:nrows(), df2:nrows())
    end)

    it("toBinary/fromBinary roundtrip", function()
        local df = make_test_df()
        local bin = df:toBinary()
        expect_type("string", bin)
        local df2 = luna.dataframe.fromBinary(bin)
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
        c:setValue(1, "name", "Modified")
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
    it("DataFrame type() returns DataFrame", function()
        local df = make_test_df()
        expect_equal("DataFrame", df:type())
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
        local db = luna.dataframe.newDatabase()
        expect_equal(0, db:tableCount())
    end)

    it("addTable and getTable work", function()
        local db = luna.dataframe.newDatabase()
        local df = make_test_df()
        db:addTable("users", df)
        local retrieved = db:getTable("users")
        expect_not_nil(retrieved)
        expect_equal(3, retrieved:nrows())
    end)

    it("getTable returns nil for missing table", function()
        local db = luna.dataframe.newDatabase()
        expect_nil(db:getTable("nonexistent"))
    end)

    it("hasTable returns true for existing table", function()
        local db = luna.dataframe.newDatabase()
        db:addTable("data", make_test_df())
        expect_true(db:hasTable("data"))
    end)

    it("hasTable returns false for missing table", function()
        local db = luna.dataframe.newDatabase()
        expect_false(db:hasTable("nope"))
    end)

    it("removeTable removes the table", function()
        local db = luna.dataframe.newDatabase()
        db:addTable("data", make_test_df())
        db:removeTable("data")
        expect_false(db:hasTable("data"))
    end)

    it("listTables returns table names", function()
        local db = luna.dataframe.newDatabase()
        db:addTable("alpha", make_test_df())
        db:addTable("beta", make_test_df())
        local names = db:listTables()
        expect_equal(2, #names)
    end)

    it("tableCount reflects additions", function()
        local db = luna.dataframe.newDatabase()
        expect_equal(0, db:tableCount())
        db:addTable("t1", make_test_df())
        expect_equal(1, db:tableCount())
        db:addTable("t2", make_test_df())
        expect_equal(2, db:tableCount())
    end)

    it("clear removes all tables", function()
        local db = luna.dataframe.newDatabase()
        db:addTable("t1", make_test_df())
        db:addTable("t2", make_test_df())
        db:clear()
        expect_equal(0, db:tableCount())
    end)

    it("merge combines databases", function()
        local db1 = luna.dataframe.newDatabase()
        db1:addTable("a", make_test_df())
        local db2 = luna.dataframe.newDatabase()
        db2:addTable("b", make_test_df())
        db1:merge(db2)
        expect_true(db1:hasTable("a"))
        expect_true(db1:hasTable("b"))
    end)

    it("toJSON returns non-empty string", function()
        local db = luna.dataframe.newDatabase()
        db:addTable("t1", make_test_df())
        local json = db:toJSON()
        expect_type("string", json)
        expect_true(#json > 0)
    end)

    it("Database type() returns Database", function()
        local db = luna.dataframe.newDatabase()
        expect_equal("Database", db:type())
    end)

    it("Database typeOf Database is true", function()
        local db = luna.dataframe.newDatabase()
        expect_true(db:typeOf("Database"))
    end)

    it("Database typeOf wrong type is false", function()
        local db = luna.dataframe.newDatabase()
        expect_false(db:typeOf("DataFrame"))
    end)
end)

-- =========================================================================
-- 27. Database SQL
-- =========================================================================
describe("Database SQL", function()
    it("query on single table", function()
        local db = luna.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT * FROM users")
        expect_equal(3, result:nrows())
    end)

    it("query with WHERE clause", function()
        local db = luna.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT * FROM users WHERE age > 28")
        expect_true(result:nrows() > 0)
    end)

    it("query selecting specific columns", function()
        local db = luna.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT name FROM users")
        expect_equal(1, result:ncols())
        expect_equal(3, result:nrows())
    end)
end)
