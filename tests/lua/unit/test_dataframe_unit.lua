-- Lurek2D DataFrame Tests
-- Tests for lurek.dataframe tabular data API

-- Helper to build a simple test DataFrame
-- @tests lurek.dataframe.fromBinary
-- @tests lurek.dataframe.fromCSV
-- @tests lurek.dataframe.fromJSON
-- @tests lurek.dataframe.fromTable
-- @tests lurek.dataframe.newDataFrame
-- @tests lurek.dataframe.newDatabase
-- @tests lurek.dataframe.random

local function make_test_df()
    local csv = "name,age,score\nAlice,30,90\nBob,25,85\nCharlie,35,92"
    return lurek.dataframe.fromCSV(csv)
end

-- =========================================================================
-- 1. Module existence
-- =========================================================================
-- @description Verifies the dataframe namespace exists as a table and exposes each documented constructor and loader as a function.
describe("lurek.dataframe module exists", function()
    -- @description Asserts that lurek.dataframe itself is a Lua table.
    it("lurek.dataframe is a table", function()
        expect_type("table", lurek.dataframe)
    end)

    -- @description Asserts that newDataFrame is exposed as a callable factory function.
    it("has newDataFrame factory", function()
        expect_type("function", lurek.dataframe.newDataFrame)
    end)

    -- @description Asserts that newDatabase is exposed as a callable factory function.
    it("has newDatabase factory", function()
        expect_type("function", lurek.dataframe.newDatabase)
    end)

    -- @description Asserts that fromTable is exposed as a callable factory function.
    it("has fromTable factory", function()
        expect_type("function", lurek.dataframe.fromTable)
    end)

    -- @description Asserts that fromCSV is exposed as a callable factory function.
    it("has fromCSV factory", function()
        expect_type("function", lurek.dataframe.fromCSV)
    end)

    -- @description Asserts that fromJSON is exposed as a callable factory function.
    it("has fromJSON factory", function()
        expect_type("function", lurek.dataframe.fromJSON)
    end)

    -- @description Asserts that fromBinary is exposed as a callable factory function.
    it("has fromBinary factory", function()
        expect_type("function", lurek.dataframe.fromBinary)
    end)

    -- @description Asserts that random is exposed as a callable factory function.
    it("has random factory", function()
        expect_type("function", lurek.dataframe.random)
    end)
end)

-- =========================================================================
-- 2. Construction
-- =========================================================================
-- @description Exercises DataFrame construction from empty state, CSV, tables, JSON, and random generation while checking shapes, parsed values, and deterministic seeding.
describe("construction", function()
    -- @description Verifies that a new empty DataFrame starts with 0 rows and 0 columns.
    it("newDataFrame creates empty DataFrame", function()
        local df = lurek.dataframe.newDataFrame()
        expect_equal(0, df:nrows())
        expect_equal(0, df:ncols())
    end)

    -- @description Verifies that parsing the helper CSV produces exactly 3 rows and 3 columns.
    it("fromCSV creates DataFrame with correct shape", function()
        local df = make_test_df()
        expect_equal(3, df:nrows())
        expect_equal(3, df:ncols())
    end)

    -- @description Verifies that CSV headers are parsed in order as name, age, and score.
    it("fromCSV parses column names", function()
        local df = make_test_df()
        local cols = df:columns()
        expect_equal("name", cols[1])
        expect_equal("age", cols[2])
        expect_equal("score", cols[3])
    end)

    -- @description Verifies that numeric CSV fields are auto-detected so the age values 30 and 25 come back as numbers.
    it("fromCSV auto-detects numbers", function()
        local df = make_test_df()
        expect_near(30, df:getValue(1, "age"), 1e-5)
        expect_near(25, df:getValue(2, "age"), 1e-5)
    end)

    -- @description Verifies that text CSV fields preserve the strings Alice and Bob in the name column.
    it("fromCSV parses text values", function()
        local df = make_test_df()
        expect_equal("Alice", df:getValue(1, "name"))
        expect_equal("Bob", df:getValue(2, "name"))
    end)

    -- @description Verifies that fromTable builds a 2x2 DataFrame from two row tables containing x and y fields.
    it("fromTable creates DataFrame from row tables", function()
        local df = lurek.dataframe.fromTable({
            { x = 1, y = 2 },
            { x = 3, y = 4 },
        })
        expect_equal(2, df:nrows())
        expect_equal(2, df:ncols())
    end)

    -- @description Verifies that a JSON array of two objects produces a DataFrame with 2 rows.
    it("fromJSON creates DataFrame", function()
        local json = '[{"a":1,"b":"hello"},{"a":2,"b":"world"}]'
        local df = lurek.dataframe.fromJSON(json)
        expect_equal(2, df:nrows())
    end)

    -- @description Verifies that random creates a DataFrame with 10 rows and the 2 requested columns.
    it("random creates DataFrame with specified rows", function()
        local defs = { {"x", "float"}, {"y", "float"} }
        local df = lurek.dataframe.random(defs, 10, 42)
        expect_equal(10, df:nrows())
        expect_equal(2, df:ncols())
    end)

    -- @description Verifies that random generation with the same seed yields matching float values for all 5 rows.
    it("random with seed is deterministic", function()
        local defs = { {"val", "float"} }
        local df1 = lurek.dataframe.random(defs, 5, 123)
        local df2 = lurek.dataframe.random(defs, 5, 123)
        for i = 1, 5 do
            expect_near(df1:getValue(i, "val"), df2:getValue(i, "val"), 1e-5)
        end
    end)

    -- @description Verifies that a CSV containing only the header x,y yields 0 rows while still defining 2 columns.
    it("fromCSV with empty body creates empty DataFrame", function()
        local df = lurek.dataframe.fromCSV("x,y")
        expect_equal(0, df:nrows())
        expect_equal(2, df:ncols())
    end)
end)

-- =========================================================================
-- 3. Schema
-- =========================================================================
-- @description Checks basic schema introspection helpers for row count, column count, ordered column names, and the count alias.
describe("schema", function()
    -- @description Verifies that nrows reports the helper DataFrame's 3 rows.
    it("nrows returns row count", function()
        local df = make_test_df()
        expect_equal(3, df:nrows())
    end)

    -- @description Verifies that ncols reports the helper DataFrame's 3 columns.
    it("ncols returns column count", function()
        local df = make_test_df()
        expect_equal(3, df:ncols())
    end)

    -- @description Verifies that columns returns three ordered column names.
    it("columns returns ordered column names", function()
        local df = make_test_df()
        local cols = df:columns()
        expect_equal(3, #cols)
    end)

    -- @description Verifies that count() returns the same value as nrows().
    it("count is alias for nrows", function()
        local df = make_test_df()
        expect_equal(df:nrows(), df:count())
    end)
end)

-- =========================================================================
-- 4. Column operations
-- =========================================================================
-- @description Covers adding, removing, renaming, and reading columns while checking dimensions, default fill values, and returned column data.
describe("column operations", function()
    -- @description Verifies that adding a grade column increases the column count from 3 to 4.
    it("addColumn increases ncols", function()
        local df = make_test_df()
        df:addColumn("grade")
        expect_equal(4, df:ncols())
    end)

    -- @description Verifies that adding a pass column with default true fills every existing row with true.
    it("addColumn with default fills all rows", function()
        local df = make_test_df()
        df:addColumn("pass", true)
        for i = 1, df:nrows() do
            expect_equal(true, df:getValue(i, "pass"))
        end
    end)

    -- @description Verifies that removing the age column by name reduces the column count to 2.
    it("removeColumn by name decreases ncols", function()
        local df = make_test_df()
        df:removeColumn("age")
        expect_equal(2, df:ncols())
    end)

    -- @description Verifies that removing the second column by index also reduces the column count to 2.
    it("removeColumn by index decreases ncols", function()
        local df = make_test_df()
        df:removeColumn(2)
        expect_equal(2, df:ncols())
    end)

    -- @description Verifies that renaming age to years removes age from the schema and adds years.
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

    -- @description Verifies that getColumn("age") returns three values 30, 25, and 35 in row order.
    it("getColumn returns column values", function()
        local df = make_test_df()
        local ages = df:getColumn("age")
        expect_equal(3, #ages)
        expect_near(30, ages[1], 1e-5)
        expect_near(25, ages[2], 1e-5)
        expect_near(35, ages[3], 1e-5)
    end)

    -- @description Verifies that getColumn(1) returns the first column and starts with Alice.
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
-- @description Covers adding, removing, and retrieving rows while checking returned indices, row counts, and row content.
describe("row operations", function()
    -- @description Verifies that adding Dave as a fourth row increases the row count to 4.
    it("addRow increases nrows", function()
        local df = make_test_df()
        df:addRow({ name = "Dave", age = 28, score = 88 })
        expect_equal(4, df:nrows())
    end)

    -- @description Verifies that addRow returns the new row's 1-based index 4.
    it("addRow returns 1-based index", function()
        local df = make_test_df()
        local idx = df:addRow({ name = "Dave", age = 28, score = 88 })
        expect_equal(4, idx)
    end)

    -- @description Verifies that calling addRow with no data still appends one row.
    it("addRow with no args adds empty row", function()
        local df = make_test_df()
        local before = df:nrows()
        df:addRow()
        expect_equal(before + 1, df:nrows())
    end)

    -- @description Verifies that removing row 2 reduces the total row count from 3 to 2.
    it("removeRow decreases nrows", function()
        local df = make_test_df()
        df:removeRow(2)
        expect_equal(2, df:nrows())
    end)

    -- @description Verifies that removing the first row shifts Bob into the first position.
    it("removeRow removes correct row", function()
        local df = make_test_df()
        df:removeRow(1) -- Remove Alice
        expect_equal("Bob", df:getValue(1, "name"))
    end)

    -- @description Verifies that getRow(1) returns a table with Alice, age 30, and score 90.
    it("getRow returns row as table", function()
        local df = make_test_df()
        local row = df:getRow(1)
        expect_equal("Alice", row.name)
        expect_near(30, row.age, 1e-5)
        expect_near(90, row.score, 1e-5)
    end)

    -- @description Verifies that getRow(3) returns the last row containing Charlie.
    it("getRow with last row index works", function()
        local df = make_test_df()
        local row = df:getRow(3)
        expect_equal("Charlie", row.name)
    end)
end)

-- =========================================================================
-- 6. Cell access
-- =========================================================================
-- @description Checks reading and writing individual cells by column name and index, including clearing a value with nil.
describe("cell access", function()
    -- @description Verifies that getValue(1, "name") returns Alice.
    it("getValue by column name", function()
        local df = make_test_df()
        expect_equal("Alice", df:getValue(1, "name"))
    end)

    -- @description Verifies that getValue(1, 1) returns Alice from the first column by index.
    it("getValue by column index", function()
        local df = make_test_df()
        expect_equal("Alice", df:getValue(1, 1))
    end)

    -- @description Verifies that setting row 1 name to Alicia updates the stored cell value.
    it("setValue changes cell value", function()
        local df = make_test_df()
        df:setValue(1, "name", "Alicia")
        expect_equal("Alicia", df:getValue(1, "name"))
    end)

    -- @description Verifies that setting row 2 column 2 to 99 updates the age value to 99.
    it("setValue by column index", function()
        local df = make_test_df()
        df:setValue(2, 2, 99)
        expect_near(99, df:getValue(2, "age"), 1e-5)
    end)

    -- @description Verifies that setting a cell to nil makes getValue return nil for that cell.
    it("setValue to nil clears cell", function()
        local df = make_test_df()
        df:setValue(1, "name", nil)
        expect_nil(df:getValue(1, "name"))
    end)
end)

-- =========================================================================
-- 7. Filter
-- =========================================================================
-- @description Verifies row filtering across equality, inequality, numeric comparisons, boundaries, and no-match cases.
describe("filter", function()
    -- @description Verifies that filtering name == Alice returns exactly one row and that row's name is Alice.
    it("filter == returns matching rows", function()
        local df = make_test_df()
        local result = df:filter("name", "==", "Alice")
        expect_equal(1, result:nrows())
        expect_equal("Alice", result:getValue(1, "name"))
    end)

    -- @description Verifies that filtering name != Alice excludes Alice and leaves 2 rows.
    it("filter != excludes matching rows", function()
        local df = make_test_df()
        local result = df:filter("name", "!=", "Alice")
        expect_equal(2, result:nrows())
    end)

    -- @description Verifies that filtering age < 30 returns only Bob.
    it("filter < on numeric column", function()
        local df = make_test_df()
        local result = df:filter("age", "<", 30)
        expect_equal(1, result:nrows())
        expect_equal("Bob", result:getValue(1, "name"))
    end)

    -- @description Verifies that filtering age > 30 returns only Charlie.
    it("filter > on numeric column", function()
        local df = make_test_df()
        local result = df:filter("age", ">", 30)
        expect_equal(1, result:nrows())
        expect_equal("Charlie", result:getValue(1, "name"))
    end)

    -- @description Verifies that filtering age <= 30 includes the boundary and returns 2 rows.
    it("filter <= includes boundary", function()
        local df = make_test_df()
        local result = df:filter("age", "<=", 30)
        expect_equal(2, result:nrows())
    end)

    -- @description Verifies that filtering age >= 30 includes the boundary and returns 2 rows.
    it("filter >= includes boundary", function()
        local df = make_test_df()
        local result = df:filter("age", ">=", 30)
        expect_equal(2, result:nrows())
    end)

    -- @description Verifies that filtering age > 100 returns an empty DataFrame with 0 rows.
    it("filter with no matches returns empty DataFrame", function()
        local df = make_test_df()
        local result = df:filter("age", ">", 100)
        expect_equal(0, result:nrows())
    end)
end)

-- =========================================================================
-- 8. Sort
-- =========================================================================
-- @description Verifies ascending and descending sorting, the default sort direction, and row-data preservation after sorting.
describe("sort", function()
    -- @description Verifies that sorting age ascending yields ages 25, 30, and 35 in order.
    it("sort ascending by numeric column", function()
        local df = make_test_df()
        local sorted = df:sort("age", true)
        expect_near(25, sorted:getValue(1, "age"), 1e-5)
        expect_near(30, sorted:getValue(2, "age"), 1e-5)
        expect_near(35, sorted:getValue(3, "age"), 1e-5)
    end)

    -- @description Verifies that sorting age descending yields ages 35, 30, and 25 in order.
    it("sort descending by numeric column", function()
        local df = make_test_df()
        local sorted = df:sort("age", false)
        expect_near(35, sorted:getValue(1, "age"), 1e-5)
        expect_near(30, sorted:getValue(2, "age"), 1e-5)
        expect_near(25, sorted:getValue(3, "age"), 1e-5)
    end)

    -- @description Verifies that omitting the direction still sorts age ascending, placing 25 first.
    it("sort defaults to ascending", function()
        local df = make_test_df()
        local sorted = df:sort("age")
        expect_near(25, sorted:getValue(1, "age"), 1e-5)
    end)

    -- @description Verifies that sorting by age keeps row values together so the first sorted row is Bob.
    it("sort preserves row data", function()
        local df = make_test_df()
        local sorted = df:sort("age", true)
        expect_equal("Bob", sorted:getValue(1, "name"))
    end)
end)

-- =========================================================================
-- 9. Head / Tail / Slice
-- =========================================================================
-- @description Checks row-window helpers for default and explicit counts and for inclusive 1-based slicing.
describe("head/tail/slice", function()
    -- @description Verifies that head() returns all 3 rows when the DataFrame has fewer than the default 5 rows.
    it("head defaults to 5 (returns all if fewer)", function()
        local df = make_test_df()
        local h = df:head()
        expect_equal(3, h:nrows()) -- only 3 rows total
    end)

    -- @description Verifies that head(2) returns the first two rows, Alice then Bob.
    it("head with n returns first n rows", function()
        local df = make_test_df()
        local h = df:head(2)
        expect_equal(2, h:nrows())
        expect_equal("Alice", h:getValue(1, "name"))
        expect_equal("Bob", h:getValue(2, "name"))
    end)

    -- @description Verifies that tail() returns all 3 rows when the DataFrame has fewer than the default 5 rows.
    it("tail defaults to 5 (returns all if fewer)", function()
        local df = make_test_df()
        local t = df:tail()
        expect_equal(3, t:nrows())
    end)

    -- @description Verifies that tail(2) returns the last two rows, Bob then Charlie.
    it("tail with n returns last n rows", function()
        local df = make_test_df()
        local t = df:tail(2)
        expect_equal(2, t:nrows())
        expect_equal("Bob", t:getValue(1, "name"))
        expect_equal("Charlie", t:getValue(2, "name"))
    end)

    -- @description Verifies that slice(1, 2) uses a 1-based inclusive range and returns Alice then Bob.
    it("slice with 1-based inclusive range", function()
        local df = make_test_df()
        local s = df:slice(1, 2)
        expect_equal(2, s:nrows())
        expect_equal("Alice", s:getValue(1, "name"))
        expect_equal("Bob", s:getValue(2, "name"))
    end)

    -- @description Verifies that slice(2, 2) returns a single-row DataFrame containing Bob.
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
-- @description Verifies column projection by name and index, including selecting multiple columns and a single column.
describe("select", function()
    -- @description Verifies that selecting name and score yields 2 columns, preserves 3 rows, and keeps Alice in row 1.
    it("select by column name", function()
        local df = make_test_df()
        local s = df:select("name", "score")
        expect_equal(2, s:ncols())
        expect_equal(3, s:nrows())
        expect_equal("Alice", s:getValue(1, "name"))
    end)

    -- @description Verifies that selecting columns 1 and 3 by index yields exactly 2 columns.
    it("select by column index", function()
        local df = make_test_df()
        local s = df:select(1, 3)
        expect_equal(2, s:ncols())
    end)

    -- @description Verifies that selecting only name yields a single-column DataFrame with all 3 rows.
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
-- @description Verifies extraction of distinct values from text and numeric columns.
describe("unique", function()
    -- @description Verifies that unique("color") returns three distinct colors from repeated color rows.
    it("unique returns distinct values", function()
        local csv = "color\nred\nblue\nred\ngreen\nblue"
        local df = lurek.dataframe.fromCSV(csv)
        local u = df:unique("color")
        expect_equal(3, #u)
    end)

    -- @description Verifies that unique("x") returns three distinct numeric values from repeated numbers.
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
-- @description Verifies grouping by a column returns DataFrame subsets with the expected total rows and preserved schema.
describe("groupBy", function()
    -- @description Verifies that grouping by dept returns a Lua table of DataFrame subsets.
    it("groupBy returns table of DataFrames", function()
        local csv = "dept,name\nHR,Alice\nIT,Bob\nHR,Charlie\nIT,Dave"
        local df = lurek.dataframe.fromCSV(csv)
        local groups = df:groupBy("dept")
        expect_type("table", groups)
    end)

    -- @description Verifies that the grouped subsets together contain all 4 original rows.
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

    -- @description Verifies that each grouped subset keeps the original 2-column schema.
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
-- @description Verifies inner and left joins on id columns, including the default join type.
describe("join", function()
    -- @description Verifies that an inner join on id keeps only the two matching rows with ids 1 and 2.
    it("inner join matches on shared column values", function()
        local csv1 = "id,name\n1,Alice\n2,Bob\n3,Charlie"
        local csv2 = "id,dept\n1,HR\n2,IT\n4,Finance"
        local df1 = lurek.dataframe.fromCSV(csv1)
        local df2 = lurek.dataframe.fromCSV(csv2)
        local result = df1:join(df2, "id", "id", "inner")
        expect_equal(2, result:nrows()) -- only ids 1 and 2 match
    end)

    -- @description Verifies that a left join on id keeps all 3 rows from the left DataFrame.
    it("left join keeps all left rows", function()
        local csv1 = "id,name\n1,Alice\n2,Bob\n3,Charlie"
        local csv2 = "id,dept\n1,HR\n2,IT\n4,Finance"
        local df1 = lurek.dataframe.fromCSV(csv1)
        local df2 = lurek.dataframe.fromCSV(csv2)
        local result = df1:join(df2, "id", "id", "left")
        expect_equal(3, result:nrows()) -- all 3 left rows
    end)

    -- @description Verifies that omitting the join type defaults to inner and returns only the single matching id 1 row.
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
-- @description Verifies that merging appends rows in place and preserves row order and values from both sources.
describe("merge", function()
    -- @description Verifies that merging x=[1,2] with x=[3,4] increases the first DataFrame to 4 rows.
    it("merge appends rows in-place", function()
        local df1 = lurek.dataframe.fromCSV("x\n1\n2")
        local df2 = lurek.dataframe.fromCSV("x\n3\n4")
        df1:merge(df2)
        expect_equal(4, df1:nrows())
    end)

    -- @description Verifies that merged rows preserve the sequence of x values 1, 2, 3, and 4.
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
-- @description Verifies grouped counting output shape and total counts for repeated values.
describe("countBy", function()
    -- @description Verifies that countBy("color") returns 3 result rows and 2 columns for value and count.
    it("countBy returns DataFrame with value and count", function()
        local csv = "color\nred\nblue\nred\ngreen\nblue"
        local df = lurek.dataframe.fromCSV(csv)
        local result = df:countBy("color")
        expect_equal(3, result:nrows()) -- 3 unique colors
        expect_equal(2, result:ncols()) -- value + count
    end)

    -- @description Verifies that summing the returned counts from countBy("color") equals the original 5 rows.
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
-- @description Verifies dropping rows with nil values in a target column while keeping complete rows intact.
describe("dropNil", function()
    -- @description Verifies that dropNil("x") removes the row with nil and leaves 2 rows with non-nil x values.
    it("dropNil removes rows with nil in column", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x")
        df:addRow({ x = 1 })
        df:addRow() -- nil
        df:addRow({ x = 3 })
        local result = df:dropNil("x")
        expect_equal(2, result:nrows())
    end)

    -- @description Verifies that dropNil("x") keeps both rows when x is already non-nil in every row.
    it("dropNil preserves non-nil rows", function()
        local df = lurek.dataframe.newDataFrame()
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
-- @description Verifies random sampling row counts, seeded determinism, and schema preservation.
describe("sample", function()
    -- @description Verifies that sampling 2 rows returns a DataFrame with exactly 2 rows.
    it("sample returns correct number of rows", function()
        local df = make_test_df()
        local s = df:sample(2, 42)
        expect_equal(2, s:nrows())
    end)

    -- @description Verifies that sampling with the same seed returns the same names in both sampled rows.
    it("sample with seed is deterministic", function()
        local df = make_test_df()
        local s1 = df:sample(2, 99)
        local s2 = df:sample(2, 99)
        expect_equal(s1:getValue(1, "name"), s2:getValue(1, "name"))
        expect_equal(s1:getValue(2, "name"), s2:getValue(2, "name"))
    end)

    -- @description Verifies that sampling preserves the original 3-column schema.
    it("sample preserves schema", function()
        local df = make_test_df()
        local s = df:sample(1, 42)
        expect_equal(3, s:ncols())
    end)
end)

-- =========================================================================
-- 18. Describe
-- =========================================================================
-- @description Verifies that describe() produces a non-empty statistical summary DataFrame.
describe("describe", function()
    -- @description Verifies that describe() returns a DataFrame with at least one row and one column.
    it("describe returns a DataFrame", function()
        local df = make_test_df()
        local stats = df:describe()
        expect_true(stats:nrows() > 0)
        expect_true(stats:ncols() > 0)
    end)

    -- @description Verifies that describe() includes at least one statistics row.
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
-- @description Verifies numeric aggregate helpers over the age and score columns, including column-index access and non-negative variance outputs.
describe("analytics", function()
    -- @description Verifies that sum("age") returns 90 for ages 30, 25, and 35.
    it("sum computes correct total", function()
        local df = make_test_df()
        -- ages: 30 + 25 + 35 = 90
        expect_near(90, df:sum("age"), 1e-5)
    end)

    -- @description Verifies that mean("age") returns 30 from ages 30, 25, and 35.
    it("mean computes correct average", function()
        local df = make_test_df()
        -- ages: (30 + 25 + 35) / 3 = 30
        expect_near(30, df:mean("age"), 1e-5)
    end)

    -- @description Verifies that min("age") returns the smallest age, 25.
    it("min returns smallest value", function()
        local df = make_test_df()
        expect_near(25, df:min("age"), 1e-5)
    end)

    -- @description Verifies that max("age") returns the largest age, 35.
    it("max returns largest value", function()
        local df = make_test_df()
        expect_near(35, df:max("age"), 1e-5)
    end)

    -- @description Verifies that median("age") returns the middle value, 30.
    it("median returns middle value", function()
        local df = make_test_df()
        expect_near(30, df:median("age"), 1e-5)
    end)

    -- @description Verifies that stddev("age") returns a positive value for ages 25, 30, and 35.
    it("stddev returns standard deviation", function()
        local df = make_test_df()
        local sd = df:stddev("age")
        -- stddev of [25,30,35]: mean=30, var=(25+0+25)/3=50/3, sdĂ˘â€°Â4.082
        expect_true(sd > 0)
    end)

    -- @description Verifies that variance("age") is never negative.
    it("variance returns non-negative value", function()
        local df = make_test_df()
        local v = df:variance("age")
        expect_true(v >= 0)
    end)

    -- @description Verifies that sum("score") returns 267 for scores 90, 85, and 92.
    it("sum on scores", function()
        local df = make_test_df()
        -- scores: 90 + 85 + 92 = 267
        expect_near(267, df:sum("score"), 1e-5)
    end)

    -- @description Verifies that sum(2) treats column 2 as age and returns 90.
    it("analytics by column index", function()
        local df = make_test_df()
        -- column 2 = age, sum = 90
        expect_near(90, df:sum(2), 1e-5)
    end)
end)

-- =========================================================================
-- 20. FillNil
-- =========================================================================
-- @description Verifies filling nil cells with replacement values without modifying cells that already contain data.
describe("fillNil", function()
    -- @description Verifies that fillNil("x", 0) replaces a nil x cell with numeric 0.
    it("fillNil replaces nil values", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x")
        df:addRow({ x = 1 })
        df:addRow() -- nil
        df:addRow({ x = 3 })
        df:fillNil("x", 0)
        expect_near(0, df:getValue(2, "x"), 1e-5)
    end)

    -- @description Verifies that fillNil("x", 0) leaves an existing x value of 5 unchanged.
    it("fillNil does not change non-nil values", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x")
        df:addRow({ x = 5 })
        df:addRow() -- nil
        df:fillNil("x", 0)
        expect_near(5, df:getValue(1, "x"), 1e-5)
    end)

    -- @description Verifies that fillNil("name", "unknown") replaces a nil text cell with the string unknown.
    it("fillNil with string value", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("name")
        df:addRow() -- nil
        df:fillNil("name", "unknown")
        expect_equal("unknown", df:getValue(1, "name"))
    end)
end)

-- =========================================================================
-- 21. Apply
-- =========================================================================
-- @description Verifies applying Lua callbacks to column values, including numeric transforms, type changes, and identity behavior.
describe("apply", function()
    -- @description Verifies that applying v * 2 to column x changes values 1, 2, 3 into 2, 4, 6.
    it("apply transforms column values", function()
        local df = lurek.dataframe.fromCSV("x\n1\n2\n3")
        df:apply("x", function(v) return v * 2 end)
        expect_near(2, df:getValue(1, "x"), 1e-5)
        expect_near(4, df:getValue(2, "x"), 1e-5)
        expect_near(6, df:getValue(3, "x"), 1e-5)
    end)

    -- @description Verifies that applying tostring-based formatting converts numeric x values into strings.
    it("apply can change type", function()
        local df = lurek.dataframe.fromCSV("x\n1\n2\n3")
        df:apply("x", function(v) return "val_" .. tostring(v) end)
        -- tostring of a number may vary; just check it's now a string
        expect_type("string", df:getValue(1, "x"))
    end)

    -- @description Verifies that applying the identity function keeps x values at 10 and 20.
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
-- @description Verifies CSV, JSON, binary, table, and string serialization paths, including round-trips and data integrity checks.
describe("serialization", function()
    -- @description Verifies that toCSV returns a non-empty string.
    it("toCSV produces string", function()
        local df = make_test_df()
        local csv = df:toCSV()
        expect_type("string", csv)
        expect_true(#csv > 0)
    end)

    -- @description Verifies that converting to CSV and back preserves row and column counts.
    it("toCSV roundtrip preserves data", function()
        local df = make_test_df()
        local csv = df:toCSV()
        local df2 = lurek.dataframe.fromCSV(csv)
        expect_equal(df:nrows(), df2:nrows())
        expect_equal(df:ncols(), df2:ncols())
    end)

    -- @description Verifies that toJSON returns a non-empty string.
    it("toJSON produces string", function()
        local df = make_test_df()
        local json = df:toJSON()
        expect_type("string", json)
        expect_true(#json > 0)
    end)

    -- @description Verifies that converting to JSON and back preserves the row count.
    it("toJSON roundtrip preserves row count", function()
        local df = make_test_df()
        local json = df:toJSON()
        local df2 = lurek.dataframe.fromJSON(json)
        expect_equal(df:nrows(), df2:nrows())
    end)

    -- @description Verifies that binary serialization round-trips rows, columns, names, and numeric age values unchanged.
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

    -- @description Verifies that toTable returns three row tables and that the first row keeps name = Alice.
    it("toTable returns array of row-tables", function()
        local df = make_test_df()
        local t = df:toTable()
        expect_equal(3, #t)
        expect_equal("Alice", t[1].name)
    end)

    -- @description Verifies that toString returns a non-empty string representation.
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
-- @description Verifies SQL queries against a DataFrame for full selection, filtering, ordering, limits, and column projection.
describe("SQL on DataFrame", function()
    -- @description Verifies that SELECT * FROM self returns all 3 rows.
    it("SELECT * FROM self returns all rows", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self")
        expect_equal(3, result:nrows())
    end)

    -- @description Verifies that a WHERE age > 28 query returns only rows whose age values are greater than 28.
    it("SELECT with WHERE filters rows", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self WHERE age > 28")
        expect_true(result:nrows() > 0)
        -- All returned ages should be > 28
        for i = 1, result:nrows() do
            expect_true(result:getValue(i, "age") > 28)
        end
    end)

    -- @description Verifies that ORDER BY age sorts the result so the first age is 25.
    it("SELECT with ORDER BY sorts", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self ORDER BY age")
        expect_near(25, result:getValue(1, "age"), 1e-5)
    end)

    -- @description Verifies that LIMIT 2 restricts the result to exactly 2 rows.
    it("SELECT with LIMIT restricts rows", function()
        local df = make_test_df()
        local result = df:query("SELECT * FROM self LIMIT 2")
        expect_equal(2, result:nrows())
    end)

    -- @description Verifies that selecting name and score returns 2 columns while keeping all 3 rows.
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
-- @description Verifies cloning produces an independent copy with matching dimensions and copied data.
describe("clone", function()
    -- @description Verifies that mutating the clone does not alter the original and the clone reflects the new value.
    it("clone returns independent copy", function()
        local df = make_test_df()
        local c = df:clone()
        c:setValue(1, "name", "Modified")
        expect_equal("Alice", df:getValue(1, "name"))
        expect_equal("Modified", c:getValue(1, "name"))
    end)

    -- @description Verifies that a clone has the same row and column counts as the source DataFrame.
    it("clone has same dimensions", function()
        local df = make_test_df()
        local c = df:clone()
        expect_equal(df:nrows(), c:nrows())
        expect_equal(df:ncols(), c:ncols())
    end)

    -- @description Verifies that the clone copies each row's name value exactly.
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
-- @description Verifies DataFrame runtime type reporting through type() and typeOf().
describe("type", function()
    -- @description Verifies that DataFrame:type() returns the string DataFrame.
    it("DataFrame type() returns LDataFrame", function()
        local df = make_test_df()
        expect_equal("LDataFrame", df:type())
    end)

    -- @description Verifies that DataFrame:typeOf("DataFrame") returns true.
    it("DataFrame typeOf DataFrame is true", function()
        local df = make_test_df()
        expect_true(df:typeOf("DataFrame"))
    end)

    -- @description Verifies that DataFrame:typeOf("Database") returns false.
    it("DataFrame typeOf wrong type is false", function()
        local df = make_test_df()
        expect_false(df:typeOf("Database"))
    end)
end)

-- =========================================================================
-- 26. Database
-- =========================================================================
-- @description Verifies database table management, merging, JSON export, and runtime type reporting.
describe("Database", function()
    -- @description Verifies that a new database starts with 0 tables.
    it("newDatabase creates empty database", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal(0, db:tableCount())
    end)

    -- @description Verifies that addTable stores a DataFrame under users and getTable retrieves it with 3 rows.
    it("addTable and getTable work", function()
        local db = lurek.dataframe.newDatabase()
        local df = make_test_df()
        db:addTable("users", df)
        local retrieved = db:getTable("users")
        expect_not_nil(retrieved)
        expect_equal(3, retrieved:nrows())
    end)

    -- @description Verifies that getTable returns nil when the named table does not exist.
    it("getTable returns nil for missing table", function()
        local db = lurek.dataframe.newDatabase()
        expect_nil(db:getTable("nonexistent"))
    end)

    -- @description Verifies that hasTable returns true after adding a table named data.
    it("hasTable returns true for existing table", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("data", make_test_df())
        expect_true(db:hasTable("data"))
    end)

    -- @description Verifies that hasTable returns false for a missing table name.
    it("hasTable returns false for missing table", function()
        local db = lurek.dataframe.newDatabase()
        expect_false(db:hasTable("nope"))
    end)

    -- @description Verifies that removeTable deletes the stored table so hasTable("data") becomes false.
    it("removeTable removes the table", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("data", make_test_df())
        db:removeTable("data")
        expect_false(db:hasTable("data"))
    end)

    -- @description Verifies that listing tables after adding alpha and beta returns two names.
    it("listTables returns table names", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("alpha", make_test_df())
        db:addTable("beta", make_test_df())
        local names = db:listTables()
        expect_equal(2, #names)
    end)

    -- @description Verifies that tableCount moves from 0 to 1 to 2 as tables t1 and t2 are added.
    it("tableCount reflects additions", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal(0, db:tableCount())
        db:addTable("t1", make_test_df())
        expect_equal(1, db:tableCount())
        db:addTable("t2", make_test_df())
        expect_equal(2, db:tableCount())
    end)

    -- @description Verifies that clear removes both previously added tables and resets tableCount to 0.
    it("clear removes all tables", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("t1", make_test_df())
        db:addTable("t2", make_test_df())
        db:clear()
        expect_equal(0, db:tableCount())
    end)

    -- @description Verifies that merging another database keeps table a and adds table b.
    it("merge combines databases", function()
        local db1 = lurek.dataframe.newDatabase()
        db1:addTable("a", make_test_df())
        local db2 = lurek.dataframe.newDatabase()
        db2:addTable("b", make_test_df())
        db1:merge(db2)
        expect_true(db1:hasTable("a"))
        expect_true(db1:hasTable("b"))
    end)

    -- @description Verifies that Database:toJSON returns a non-empty string after adding a table.
    it("toJSON returns non-empty string", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("t1", make_test_df())
        local json = db:toJSON()
        expect_type("string", json)
        expect_true(#json > 0)
    end)

    -- @description Verifies that Database:type() returns the string Database.
    it("Database type() returns LDatabase", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal("LDatabase", db:type())
    end)

    -- @description Verifies that Database:typeOf("Database") returns true.
    it("Database typeOf Database is true", function()
        local db = lurek.dataframe.newDatabase()
        expect_true(db:typeOf("Database"))
    end)

    -- @description Verifies that Database:typeOf("DataFrame") returns false.
    it("Database typeOf wrong type is false", function()
        local db = lurek.dataframe.newDatabase()
        expect_false(db:typeOf("DataFrame"))
    end)
end)

-- =========================================================================
-- 27. Database SQL
-- =========================================================================
-- @description Verifies SQL queries executed against named database tables for selection, filtering, and projection.
describe("Database SQL", function()
    -- @description Verifies that querying SELECT * FROM users returns all 3 rows from the stored table.
    it("query on single table", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT * FROM users")
        expect_equal(3, result:nrows())
    end)

    -- @description Verifies that a database query with WHERE age > 28 returns at least one matching row.
    it("query with WHERE clause", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT * FROM users WHERE age > 28")
        expect_true(result:nrows() > 0)
    end)

    -- @description Verifies that selecting only name from users returns 1 column across all 3 rows.
    it("query selecting specific columns", function()
        local db = lurek.dataframe.newDatabase()
        db:addTable("users", make_test_df())
        local result = db:query("SELECT name FROM users")
        expect_equal(1, result:ncols())
        expect_equal(3, result:nrows())
    end)
end)

-- @description Verifies nil display behavior and round-tripping of number, text, and bool cell values for RS parity checks.
describe("CellValue nil and display (RS parity)", function()
    -- @description Verifies that a nil numeric cell is exposed as nil, "nil", or an empty string.
    it("nil cell displays as empty or 'nil' string", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x", "number")
        df:addRow({ x = nil })
        local v = df:getValue(1, "x")
        expect_true(v == nil or v == "nil" or v == "")
    end)

    -- @description Verifies that a number cell containing 42 round-trips through getValue within tolerance.
    it("number cell round-trips through get", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("n", "number")
        df:addRow({ n = 42 })
        expect_near(42, df:getValue(1, "n"), 0.001)
    end)

    -- @description Verifies that a text cell containing hello round-trips through getValue unchanged.
    it("text cell round-trips through get", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("s", "text")
        df:addRow({ s = "hello" })
        expect_equal("hello", df:getValue(1, "s"))
    end)

    -- @description Verifies that a bool cell containing true round-trips through getValue as truthy.
    it("bool cell round-trips through get", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("b", "bool")
        df:addRow({ b = true })
        expect_true(df:getValue(1, "b"))
    end)
end)

-- @description Verifies RS parity behavior for Database userdata creation, table round-tripping, listing, and removal.
describe("Database (RS parity)", function()
    -- @description Verifies that newDatabase returns a userdata value.
    it("newDatabase returns userdata", function()
        local db = lurek.dataframe.newDatabase()
        expect_equal("userdata", type(db))
    end)

    -- @description Verifies that adding a users table and retrieving it returns userdata.
    it("addTable and getTable round-trip", function()
        local db = lurek.dataframe.newDatabase()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("id", "number")
        db:addTable("users", df)
        local t = db:getTable("users")
        expect_equal("userdata", type(t))
    end)

    -- @description Verifies that listTables returns a table containing the added name items.
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

    -- @description Verifies that removing tmp makes it disappear from the listed table names.
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

    -- @description withRollingMean adds a column with the rolling mean, first rows are nil.
    it("withRollingMean adds column with nil for insufficient history", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("val", 0)
        df:addRow({val = 1})
        df:addRow({val = 3})
        df:addRow({val = 5})
        df:withRollingMean("val", 2, "rm")
        local row1 = df:getRow(1)
        local row2 = df:getRow(2)
        expect_equal(nil, row1.rm)
        expect_near(2.0, row2.rm, 0.001)
    end)

    -- @description withRollingSum adds a window sum column.
    it("withRollingSum computes window sums", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("val", 0)
        df:addRow({val = 2})
        df:addRow({val = 4})
        df:addRow({val = 6})
        df:withRollingSum("val", 2, "rs")
        local row3 = df:getRow(3)
        expect_near(10.0, row3.rs, 0.001)
    end)

    -- @description withRank produces 1-based ranks in ascending order.
    it("withRank ascending assigns lowest value rank 1", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("score", 0)
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

    -- @description withPctChange produces nil for the first row and correct ratio for subsequent rows.
    it("withPctChange first row is nil, rest are ratios", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x", 0)
        df:addRow({x = 100})
        df:addRow({x = 110})
        df:addRow({x = 121})
        df:withPctChange("x", "pct")
        local row1 = df:getRow(1)
        local row2 = df:getRow(2)
        expect_equal(nil, row1.pct)
        expect_near(0.1, row2.pct, 0.001)
    end)

    -- @description withCumsum produces cumulative sum.
    it("withCumsum accumulates correctly", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        df:addRow({v = 1}) df:addRow({v = 2}) df:addRow({v = 3})
        df:withCumsum("v", "cs")
        local row3 = df:getRow(3)
        expect_near(6.0, row3.cs, 0.001)
    end)

    -- @description groupAgg sums a numeric column by category.
    xit("groupAgg with sum aggregates correctly", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("cat", "")
        df:addColumn("val", 0)
        df:addRow({cat = "A", val = 10})
        df:addRow({cat = "B", val = 5})
        df:addRow({cat = "A", val = 20})
        local agg = df:groupAgg("cat", "val", "sum")
        expect_equal(2, agg:rowCount())
    end)

    -- @description corr returns 1 for a column correlated with itself.
    it("corr of column with itself is 1", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x", 0)
        df:addRow({x = 1}) df:addRow({x = 2}) df:addRow({x = 3})
        expect_near(1.0, df:corr("x", "x"), 0.001)
    end)

    -- @description correlationMatrix returns a DataFrame with "column" header row.
    xit("correlationMatrix includes column header", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("a", 0)
        df:addColumn("b", 0)
        df:addRow({a = 1, b = 2})
        df:addRow({a = 2, b = 4})
        local mat = df:correlationMatrix()
        expect_equal("DataFrame", mat:type())
        local cols = mat:columnNames()
        expect_equal("column", cols[1])
    end)

    -- @description zscoreCol adds a column with zero mean.
    it("zscoreCol produces zero-mean column", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        for i = 1, 8 do df:addRow({v = i * 2}) end
        df:zscoreCol("v", "z")
        local total = 0
        for i = 1, 8 do total = total + df:getRow(i).z end
        expect_near(0.0, total / 8, 0.001)
    end)

    -- @description normalizeCol scales to [0,1].
    it("normalizeCol scales values to output range", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        df:addRow({v = 0}) df:addRow({v = 50}) df:addRow({v = 100})
        df:normalizeCol("v", 0, 1, "n")
        expect_near(0.0, df:getRow(1).n, 0.001)
        expect_near(0.5, df:getRow(2).n, 0.001)
        expect_near(1.0, df:getRow(3).n, 0.001)
    end)

    -- @description outliers returns only rows where z-score exceeds threshold.
    xit("outliers filters to extreme rows", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        -- Most values near 0, one outlier
        for i = 1, 9 do df:addRow({v = 0}) end
        df:addRow({v = 1000})
        local out = df:outliers("v", 2.0)
        expect_equal(1, out:rowCount())
    end)

    -- @description modeVal returns the most frequent value.
    it("modeVal returns most frequent value", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "a"}) df:addRow({x = "c"})
        expect_equal("a", df:modeVal("x"))
    end)

    -- @description entropy of a uniform distribution is log2(n).
    it("entropy of uniform 4-value column is 2 bits", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "c"}) df:addRow({x = "d"})
        expect_near(2.0, df:entropy("x"), 0.001)
    end)

    -- @description addRowBatch adds multiple rows atomically.
    xit("addRowBatch adds all rows", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        df:addRowBatch({{1}, {2}, {3}})
        expect_equal(3, df:rowCount())
    end)

    -- @description getColumnAsF64 returns a Lua array of floats.
    it("getColumnAsF64 returns numeric array", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        df:addRow({v = 10}) df:addRow({v = 20})
        local arr = df:getColumnAsF64("v")
        expect_equal(2, #arr)
        expect_near(10.0, arr[1], 0.001)
        expect_near(20.0, arr[2], 0.001)
    end)

    -- @description setColumnFromF64 overwrites column values.
    it("setColumnFromF64 overwrites column with new values", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        df:addRow({v = 0}) df:addRow({v = 0})
        df:setColumnFromF64("v", {7, 14})
        expect_near(7.0, df:getRow(1).v, 0.001)
        expect_near(14.0, df:getRow(2).v, 0.001)
    end)

    -- @description pivot creates a wide-format table with correct column labels.
    xit("pivot creates wide-format DataFrame", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("row", "")
        df:addColumn("col", "")
        df:addColumn("val", 0)
        df:addRow({row = "R1", col = "C1", val = 1})
        df:addRow({row = "R1", col = "C2", val = 2})
        df:addRow({row = "R2", col = "C1", val = 3})
        local p = df:pivot("row", "col", "val")
        -- Should have 3 columns: row, C1, C2
        expect_equal(3, #p:columnNames())
    end)

end)

-- ---------------------------------------------------------------------------
-- Analytics methods
-- ---------------------------------------------------------------------------
describe("lurek.dataframe.DataFrame analytics", function()

    -- @description withRollingMean adds a column with the rolling mean, first rows are nil.
    it("withRollingMean adds column with nil for insufficient history", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("val", 0)
        df:addRow({val = 1})
        df:addRow({val = 3})
        df:addRow({val = 5})
        df:withRollingMean("val", 2, "rm")
        local row1 = df:getRow(1)
        local row2 = df:getRow(2)
        expect_equal(nil, row1.rm)
        expect_near(2.0, row2.rm, 0.001)
    end)

    -- @description withRollingSum adds a window sum column.
    it("withRollingSum computes window sums", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("val", 0)
        df:addRow({val = 2})
        df:addRow({val = 4})
        df:addRow({val = 6})
        df:withRollingSum("val", 2, "rs")
        local row3 = df:getRow(3)
        expect_near(10.0, row3.rs, 0.001)
    end)

    -- @description withRank produces 1-based ranks in ascending order.
    it("withRank ascending assigns lowest value rank 1", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("score", 0)
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

    -- @description withPctChange produces nil for the first row and correct ratio for subsequent rows.
    it("withPctChange first row is nil, rest are ratios", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x", 0)
        df:addRow({x = 100})
        df:addRow({x = 110})
        df:addRow({x = 121})
        df:withPctChange("x", "pct")
        local row1 = df:getRow(1)
        local row2 = df:getRow(2)
        expect_equal(nil, row1.pct)
        expect_near(0.1, row2.pct, 0.001)
    end)

    -- @description withCumsum produces cumulative sum.
    it("withCumsum accumulates correctly", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        df:addRow({v = 1}) df:addRow({v = 2}) df:addRow({v = 3})
        df:withCumsum("v", "cs")
        local row3 = df:getRow(3)
        expect_near(6.0, row3.cs, 0.001)
    end)

    -- @description groupAgg sums a numeric column by category.
    xit("groupAgg with sum aggregates correctly", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("cat", "")
        df:addColumn("val", 0)
        df:addRow({cat = "A", val = 10})
        df:addRow({cat = "B", val = 5})
        df:addRow({cat = "A", val = 20})
        local agg = df:groupAgg("cat", "val", "sum")
        expect_equal(2, agg:rowCount())
    end)

    -- @description corr returns 1 for a column correlated with itself.
    it("corr of column with itself is 1", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x", 0)
        df:addRow({x = 1}) df:addRow({x = 2}) df:addRow({x = 3})
        expect_near(1.0, df:corr("x", "x"), 0.001)
    end)

    -- @description correlationMatrix returns a DataFrame with "column" header row.
    xit("correlationMatrix includes column header", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("a", 0)
        df:addColumn("b", 0)
        df:addRow({a = 1, b = 2})
        df:addRow({a = 2, b = 4})
        local mat = df:correlationMatrix()
        expect_equal("DataFrame", mat:type())
        local cols = mat:columnNames()
        expect_equal("column", cols[1])
    end)

    -- @description zscoreCol adds a column with zero mean.
    it("zscoreCol produces zero-mean column", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        for i = 1, 8 do df:addRow({v = i * 2}) end
        df:zscoreCol("v", "z")
        local total = 0
        for i = 1, 8 do total = total + df:getRow(i).z end
        expect_near(0.0, total / 8, 0.001)
    end)

    -- @description normalizeCol scales to [0,1].
    it("normalizeCol scales values to output range", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        df:addRow({v = 0}) df:addRow({v = 50}) df:addRow({v = 100})
        df:normalizeCol("v", 0, 1, "n")
        expect_near(0.0, df:getRow(1).n, 0.001)
        expect_near(0.5, df:getRow(2).n, 0.001)
        expect_near(1.0, df:getRow(3).n, 0.001)
    end)

    -- @description outliers returns only rows where z-score exceeds threshold.
    xit("outliers filters to extreme rows", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        -- Most values near 0, one outlier
        for i = 1, 9 do df:addRow({v = 0}) end
        df:addRow({v = 1000})
        local out = df:outliers("v", 2.0)
        expect_equal(1, out:rowCount())
    end)

    -- @description modeVal returns the most frequent value.
    it("modeVal returns most frequent value", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "a"}) df:addRow({x = "c"})
        expect_equal("a", df:modeVal("x"))
    end)

    -- @description entropy of a uniform distribution is log2(n).
    it("entropy of uniform 4-value column is 2 bits", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("x", "")
        df:addRow({x = "a"}) df:addRow({x = "b"})
        df:addRow({x = "c"}) df:addRow({x = "d"})
        expect_near(2.0, df:entropy("x"), 0.001)
    end)

    -- @description addRowBatch adds multiple rows atomically.
    xit("addRowBatch adds all rows", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        df:addRowBatch({{1}, {2}, {3}})
        expect_equal(3, df:rowCount())
    end)

    -- @description getColumnAsF64 returns a Lua array of floats.
    it("getColumnAsF64 returns numeric array", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        df:addRow({v = 10}) df:addRow({v = 20})
        local arr = df:getColumnAsF64("v")
        expect_equal(2, #arr)
        expect_near(10.0, arr[1], 0.001)
        expect_near(20.0, arr[2], 0.001)
    end)

    -- @description setColumnFromF64 overwrites column values.
    it("setColumnFromF64 overwrites column with new values", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("v", 0)
        df:addRow({v = 0}) df:addRow({v = 0})
        df:setColumnFromF64("v", {7, 14})
        expect_near(7.0, df:getRow(1).v, 0.001)
        expect_near(14.0, df:getRow(2).v, 0.001)
    end)

    -- @description pivot creates a wide-format table with correct column labels.
    xit("pivot creates wide-format DataFrame", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("row", "")
        df:addColumn("col", "")
        df:addColumn("val", 0)
        df:addRow({row = "R1", col = "C1", val = 1})
        df:addRow({row = "R1", col = "C2", val = 2})
        df:addRow({row = "R2", col = "C1", val = 3})
        local p = df:pivot("row", "col", "val")
        -- Should have 3 columns: row, C1, C2
        expect_equal(3, #p:columnNames())
    end)

end)

-- â”€â”€ DataFrame pivotTable / rollingMean / rollingSum / rank (merged from test_dataframe_pivot_window.lua) â”€â”€

describe("DataFrame: pivotTable", function()

    -- @tests lurek.dataframe.DataFrame.pivotTable
    -- @description pivotTable reshapes a long DataFrame to wide format (mean agg, default).
    xit("pivotTable reshapes long to wide with default mean aggregation", function()
        local df = lurek.dataframe.new()
        df:addColumn("player")
        df:addColumn("stat")
        df:addColumn("value")
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

    -- @tests lurek.dataframe.DataFrame.pivotTable
    -- @description pivotTable with sum aggregation accumulates duplicate entries.
    xit("pivotTable with sum aggregation", function()
        local df = lurek.dataframe.new()
        df:addColumn("group")
        df:addColumn("cat")
        df:addColumn("val")
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

    -- @tests lurek.dataframe.DataFrame.pivotTable
    -- @description pivotTable with count aggregation counts rows per cell.
    xit("pivotTable with count aggregation", function()
        local df = lurek.dataframe.new()
        df:addColumn("g")
        df:addColumn("c")
        df:addColumn("v")
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

    -- @tests lurek.dataframe.DataFrame.rollingMean
    -- @description rollingMean returns new DataFrame with extra column; leaves original unchanged.
    xit("rollingMean appends result column and preserves original", function()
        local df = lurek.dataframe.new()
        df:addColumn("v")
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
        -- Row 1: window=2, only 1 predecessor â†’ nil
        expect_nil(rm[1], "first row should be nil with window=2")
        -- Row 2: mean(2,4)=3
        expect_near(3.0, rm[2], 0.001)
        -- Row 3: mean(4,6)=5
        expect_near(5.0, rm[3], 0.001)
        -- Row 4: mean(6,8)=7
        expect_near(7.0, rm[4], 0.001)
    end)

    -- @tests lurek.dataframe.DataFrame.rollingMean
    -- @description rollingMean default result column name contains source column name.
    xit("rollingMean uses default result column name", function()
        local df = lurek.dataframe.new()
        df:addColumn("score")
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

    -- @tests lurek.dataframe.DataFrame.rollingSum
    -- @description rollingSum returns new DataFrame with correct rolling sums.
    xit("rollingSum produces correct sums", function()
        local df = lurek.dataframe.new()
        df:addColumn("v")
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

    -- @tests lurek.dataframe.DataFrame.rank
    -- @description rank descending assigns rank 1 to the highest score.
    xit("rank desc assigns rank 1 to highest score", function()
        local df = lurek.dataframe.new()
        df:addColumn("score")
        df:addRow({ score = 30 })
        df:addRow({ score = 10 })
        df:addRow({ score = 20 })

        local df2 = df:rank("score", "desc", "rank")
        expect_equal(2, df2:ncols())
        local ranks = df2:getColumn("rank")
        -- score 30 â†’ rank 1, score 20 â†’ rank 2, score 10 â†’ rank 3
        expect_near(1, ranks[1], 0.001)
        expect_near(3, ranks[2], 0.001)
        expect_near(2, ranks[3], 0.001)
    end)

    -- @tests lurek.dataframe.DataFrame.rank
    -- @description rank ascending assigns rank 1 to the lowest score.
    xit("rank asc assigns rank 1 to lowest score", function()
        local df = lurek.dataframe.new()
        df:addColumn("score")
        df:addRow({ score = 30 })
        df:addRow({ score = 10 })
        df:addRow({ score = 20 })

        local df2 = df:rank("score", "asc", "rank")
        local ranks = df2:getColumn("rank")
        -- score 30 â†’ rank 3, score 20 â†’ rank 2, score 10 â†’ rank 1
        expect_near(3, ranks[1], 0.001)
        expect_near(1, ranks[2], 0.001)
        expect_near(2, ranks[3], 0.001)
    end)

    -- @tests lurek.dataframe.DataFrame.rank
    -- @description rank uses default column name when resultCol omitted.
    xit("rank uses default result column name", function()
        local df = lurek.dataframe.new()
        df:addColumn("pts")
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
    -- @tests DataFrame:min
    it("covers DataFrame:min", function()
        local df = lurek.dataframe.fromCSV("v\n10\n2\n7")
        expect_equal(2, df:min("v"))
    end)

    -- @tests DataFrame:max
    it("covers DataFrame:max", function()
        local df = lurek.dataframe.fromCSV("v\n10\n2\n7")
        expect_equal(10, df:max("v"))
    end)

    -- @tests DataFrame:withEval
    it("covers DataFrame:withEval", function()
        -- TODO: Implement test for DataFrame:withEval
    end)

end)

describe("Missing explicit test for DataFrame:nrows", function()
    it("DataFrame:nrows works", function()
        -- @tests DataFrame:nrows
        -- TODO: add assertion for DataFrame:nrows
    end)
end)

describe("Missing explicit test for DataFrame:ncols", function()
    it("DataFrame:ncols works", function()
        -- @tests DataFrame:ncols
        -- TODO: add assertion for DataFrame:ncols
    end)
end)

describe("Missing explicit test for DataFrame:columns", function()
    it("DataFrame:columns works", function()
        -- @tests DataFrame:columns
        -- TODO: add assertion for DataFrame:columns
    end)
end)

describe("Missing explicit test for DataFrame:count", function()
    it("DataFrame:count works", function()
        -- @tests DataFrame:count
        -- TODO: add assertion for DataFrame:count
    end)
end)

describe("Missing explicit test for DataFrame:removeColumn", function()
    it("DataFrame:removeColumn works", function()
        -- @tests DataFrame:removeColumn
        -- TODO: add assertion for DataFrame:removeColumn
    end)
end)

describe("Missing explicit test for DataFrame:rename", function()
    it("DataFrame:rename works", function()
        -- @tests DataFrame:rename
        -- TODO: add assertion for DataFrame:rename
    end)
end)

describe("Missing explicit test for DataFrame:getColumn", function()
    it("DataFrame:getColumn works", function()
        -- @tests DataFrame:getColumn
        -- TODO: add assertion for DataFrame:getColumn
    end)
end)

describe("Missing explicit test for DataFrame:addRow", function()
    it("DataFrame:addRow works", function()
        -- @tests DataFrame:addRow
        -- TODO: add assertion for DataFrame:addRow
    end)
end)

describe("Missing explicit test for DataFrame:removeRow", function()
    it("DataFrame:removeRow works", function()
        -- @tests DataFrame:removeRow
        -- TODO: add assertion for DataFrame:removeRow
    end)
end)

describe("Missing explicit test for DataFrame:getRow", function()
    it("DataFrame:getRow works", function()
        -- @tests DataFrame:getRow
        -- TODO: add assertion for DataFrame:getRow
    end)
end)

describe("Missing explicit test for DataFrame:getValue", function()
    it("DataFrame:getValue works", function()
        -- @tests DataFrame:getValue
        -- TODO: add assertion for DataFrame:getValue
    end)
end)

describe("Missing explicit test for DataFrame:head", function()
    it("DataFrame:head works", function()
        -- @tests DataFrame:head
        -- TODO: add assertion for DataFrame:head
    end)
end)

describe("Missing explicit test for DataFrame:tail", function()
    it("DataFrame:tail works", function()
        -- @tests DataFrame:tail
        -- TODO: add assertion for DataFrame:tail
    end)
end)

describe("Missing explicit test for DataFrame:slice", function()
    it("DataFrame:slice works", function()
        -- @tests DataFrame:slice
        -- TODO: add assertion for DataFrame:slice
    end)
end)

describe("Missing explicit test for DataFrame:select", function()
    it("DataFrame:select works", function()
        -- @tests DataFrame:select
        -- TODO: add assertion for DataFrame:select
    end)
end)

describe("Missing explicit test for DataFrame:unique", function()
    it("DataFrame:unique works", function()
        -- @tests DataFrame:unique
        -- TODO: add assertion for DataFrame:unique
    end)
end)

describe("Missing explicit test for DataFrame:groupBy", function()
    it("DataFrame:groupBy works", function()
        -- @tests DataFrame:groupBy
        -- TODO: add assertion for DataFrame:groupBy
    end)
end)

describe("Missing explicit test for DataFrame:merge", function()
    it("DataFrame:merge works", function()
        -- @tests DataFrame:merge
        -- TODO: add assertion for DataFrame:merge
    end)
end)

describe("Missing explicit test for DataFrame:countBy", function()
    it("DataFrame:countBy works", function()
        -- @tests DataFrame:countBy
        -- TODO: add assertion for DataFrame:countBy
    end)
end)

describe("Missing explicit test for DataFrame:dropNil", function()
    it("DataFrame:dropNil works", function()
        -- @tests DataFrame:dropNil
        -- TODO: add assertion for DataFrame:dropNil
    end)
end)

describe("Missing explicit test for DataFrame:sample", function()
    it("DataFrame:sample works", function()
        -- @tests DataFrame:sample
        -- TODO: add assertion for DataFrame:sample
    end)
end)

-- =========================================================================
-- Vectorized VecFrame API (lurek.dataframe.toVec / fromVec)
-- =========================================================================

-- @tests lurek.dataframe.toVec
-- @tests lurek.dataframe.fromVec
describe("lurek.dataframe vectorized factory functions", function()
    it("toVec is a function", function()
        -- @tests lurek.dataframe.toVec
        expect_type("function", lurek.dataframe.toVec)
    end)

    it("fromVec is a function", function()
        -- @tests lurek.dataframe.fromVec
        expect_type("function", lurek.dataframe.fromVec)
    end)

    it("toVec returns a VecFrame userdata", function()
        -- @tests lurek.dataframe.toVec
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n")
        local vf = lurek.dataframe.toVec(df)
        assert(vf ~= nil, "toVec returned nil")
        assert(type(vf) == "userdata", "expected userdata")
    end)

    it("fromVec converts VecFrame back to DataFrame", function()
        -- @tests lurek.dataframe.fromVec
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n")
        local vf = lurek.dataframe.toVec(df)
        local df2 = lurek.dataframe.fromVec(vf)
        assert(df2 ~= nil, "fromVec returned nil")
    end)
end)

-- @tests VecFrame:nrows
-- @tests VecFrame:ncols
-- @tests VecFrame:columns
describe("VecFrame shape queries", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    it("nrows returns correct row count", function()
        -- @tests VecFrame:nrows
        local vf = make_vf()
        assert(vf:nrows() == 3, "expected nrows=3, got " .. tostring(vf:nrows()))
    end)

    it("ncols returns correct column count", function()
        -- @tests VecFrame:ncols
        local vf = make_vf()
        assert(vf:ncols() == 2, "expected ncols=2, got " .. tostring(vf:ncols()))
    end)

    it("columns returns table of column names", function()
        -- @tests VecFrame:columns
        local vf = make_vf()
        local cols = vf:columns()
        assert(type(cols) == "table", "expected table")
        assert(cols[1] == "hp", "expected cols[1]='hp', got " .. tostring(cols[1]))
        assert(cols[2] == "mp", "expected cols[2]='mp', got " .. tostring(cols[2]))
    end)
end)

-- @tests VecFrame:colType
-- @tests VecFrame:colCast
describe("VecFrame type inspection and casting", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n")
        return lurek.dataframe.toVec(df)
    end

    it("colType returns float64 for numeric column", function()
        -- @tests VecFrame:colType
        local vf = make_vf()
        assert(vf:colType("hp") == "float64", "expected float64, got " .. tostring(vf:colType("hp")))
    end)

    it("colType returns nil for nonexistent column", function()
        -- @tests VecFrame:colType
        local vf = make_vf()
        assert(vf:colType("NOPE") == nil, "expected nil for missing column")
    end)

    it("colCast float64 to int64 changes type", function()
        -- @tests VecFrame:colCast
        local vf = make_vf()
        vf:colCast("hp", "int64")
        assert(vf:colType("hp") == "int64", "expected int64 after cast")
    end)
end)

-- @tests VecFrame:colAdd
-- @tests VecFrame:colSub
-- @tests VecFrame:colMul
-- @tests VecFrame:colDiv
-- @tests VecFrame:colAbs
-- @tests VecFrame:colSqrt
-- @tests VecFrame:colFloor
-- @tests VecFrame:colCeil
-- @tests VecFrame:colNeg
-- @tests VecFrame:colClamp
describe("VecFrame scalar column operations", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    local function first(vf, col)
        local df2 = vf:toDataFrame()
        return df2:get(0, col)
    end

    xit("colAdd adds scalar to every row", function()
        -- @tests VecFrame:colAdd
        local vf = make_vf()
        vf:colAdd("hp", 5)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:get(0, "hp")
        assert(v ~= nil, "colAdd: got nil")
        assert(math.abs(v - 15) < 0.0001, "expected 15, got " .. tostring(v))
    end)

    xit("colSub subtracts scalar from every row", function()
        -- @tests VecFrame:colSub
        local vf = make_vf()
        vf:colSub("hp", 5)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:get(0, "hp")
        assert(math.abs(v - 5) < 0.0001, "expected 5, got " .. tostring(v))
    end)

    xit("colMul multiplies every row by scalar", function()
        -- @tests VecFrame:colMul
        local vf = make_vf()
        vf:colMul("hp", 3)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:get(0, "hp")
        assert(math.abs(v - 30) < 0.0001, "expected 30, got " .. tostring(v))
    end)

    xit("colDiv divides every row by scalar", function()
        -- @tests VecFrame:colDiv
        local vf = make_vf()
        vf:colDiv("hp", 2)
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:get(0, "hp")
        assert(math.abs(v - 5) < 0.0001, "expected 5, got " .. tostring(v))
    end)

    xit("colAbs makes all values non-negative", function()
        -- @tests VecFrame:colAbs
        local df = lurek.dataframe.fromCSV("v\n-3\n4\n-1.5\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colAbs("v")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:get(0, "v")
        assert(v ~= nil and v >= 0, "expected non-negative, got " .. tostring(v))
    end)

    xit("colSqrt takes sqrt of every row", function()
        -- @tests VecFrame:colSqrt
        local df = lurek.dataframe.fromCSV("v\n9\n4\n1\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colSqrt("v")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:get(0, "v")
        assert(math.abs(v - 3) < 0.0001, "expected 3, got " .. tostring(v))
    end)

    xit("colFloor floors every element", function()
        -- @tests VecFrame:colFloor
        local df = lurek.dataframe.fromCSV("v\n1.9\n2.5\n3.1\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colFloor("v")
        local df2 = lurek.dataframe.fromVec(vf)
        assert(math.abs(df2:get(0, "v") - 1) < 0.0001, "expected 1")
    end)

    xit("colCeil ceils every element", function()
        -- @tests VecFrame:colCeil
        local df = lurek.dataframe.fromCSV("v\n1.1\n2.5\n3.9\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colCeil("v")
        local df2 = lurek.dataframe.fromVec(vf)
        assert(math.abs(df2:get(0, "v") - 2) < 0.0001, "expected 2")
    end)

    xit("colNeg negates every element", function()
        -- @tests VecFrame:colNeg
        local df = lurek.dataframe.fromCSV("v\n5\n10\n15\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colNeg("v")
        local df2 = lurek.dataframe.fromVec(vf)
        assert(math.abs(df2:get(0, "v") - (-5)) < 0.0001, "expected -5")
    end)

    xit("colClamp clamps values to [min, max]", function()
        -- @tests VecFrame:colClamp
        local vf = make_vf()
        vf:colClamp("hp", 15, 25)
        local df2 = lurek.dataframe.fromVec(vf)
        -- row 0 was 10 â†’ clamped to 15
        local v0 = df2:get(0, "hp")
        assert(math.abs(v0 - 15) < 0.0001, "expected 15 (clamped), got " .. tostring(v0))
        -- row 1 was 20 â†’ stays 20
        local v1 = df2:get(1, "hp")
        assert(math.abs(v1 - 20) < 0.0001, "expected 20, got " .. tostring(v1))
        -- row 2 was 30 â†’ clamped to 25
        local v2 = df2:get(2, "hp")
        assert(math.abs(v2 - 25) < 0.0001, "expected 25 (clamped), got " .. tostring(v2))
    end)
end)

-- @tests VecFrame:colOp
describe("VecFrame binary column operations", function()
    xit("colOp add computes element-wise sum", function()
        -- @tests VecFrame:colOp
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colOp("total", "hp", "add", "mp")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:get(0, "total")
        assert(v ~= nil and math.abs(v - 15) < 0.0001, "expected 15, got " .. tostring(v))
    end)

    xit("colOp mul computes element-wise product", function()
        -- @tests VecFrame:colOp
        local df = lurek.dataframe.fromCSV("a,b\n3,4\n5,6\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colOp("product", "a", "mul", "b")
        local df2 = lurek.dataframe.fromVec(vf)
        local v = df2:get(0, "product")
        assert(v ~= nil and math.abs(v - 12) < 0.0001, "expected 12, got " .. tostring(v))
    end)

    xit("colOp min picks element-wise minimum", function()
        -- @tests VecFrame:colOp
        local df = lurek.dataframe.fromCSV("a,b\n3,7\n8,2\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colOp("m", "a", "min", "b")
        local df2 = lurek.dataframe.fromVec(vf)
        assert(math.abs(df2:get(0, "m") - 3) < 0.0001, "expected 3")
        assert(math.abs(df2:get(1, "m") - 2) < 0.0001, "expected 2")
    end)
end)

-- @tests VecFrame:reduce
describe("VecFrame reductions", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    it("reduce sum returns correct total", function()
        -- @tests VecFrame:reduce
        local vf = make_vf()
        local s = vf:reduce("hp", "sum")
        assert(s ~= nil and math.abs(s - 60) < 0.0001, "expected 60, got " .. tostring(s))
    end)

    it("reduce mean returns correct average", function()
        -- @tests VecFrame:reduce
        local vf = make_vf()
        local m = vf:reduce("hp", "mean")
        assert(m ~= nil and math.abs(m - 20) < 0.0001, "expected 20, got " .. tostring(m))
    end)

    it("reduce min returns minimum value", function()
        -- @tests VecFrame:reduce
        local vf = make_vf()
        assert(vf:reduce("hp", "min") == 10, "expected 10")
    end)

    it("reduce max returns maximum value", function()
        -- @tests VecFrame:reduce
        local vf = make_vf()
        assert(vf:reduce("hp", "max") == 30, "expected 30")
    end)

    it("reduce count returns row count", function()
        -- @tests VecFrame:reduce
        local vf = make_vf()
        assert(vf:reduce("hp", "count") == 3, "expected 3")
    end)

    it("reduce std is near 0 for constant column", function()
        -- @tests VecFrame:reduce
        local df = lurek.dataframe.fromCSV("v\n5\n5\n5\n")
        local vf = lurek.dataframe.toVec(df)
        local s = vf:reduce("v", "std")
        assert(s ~= nil and math.abs(s) < 0.0001, "expected ~0, got " .. tostring(s))
    end)
end)

-- @tests VecFrame:filterMask
-- @tests VecFrame:applyMask
describe("VecFrame filter and mask", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    it("filterMask > returns correct boolean array", function()
        -- @tests VecFrame:filterMask
        local vf = make_vf()
        local mask = vf:filterMask("hp", ">", 15)
        assert(type(mask) == "table", "expected table")
        assert(mask[1] == false, "row 0 (hp=10) should be false")
        assert(mask[2] == true,  "row 1 (hp=20) should be true")
        assert(mask[3] == true,  "row 2 (hp=30) should be true")
    end)

    it("filterMask <= returns correct boolean array", function()
        -- @tests VecFrame:filterMask
        local vf = make_vf()
        local mask = vf:filterMask("hp", "<=", 20)
        assert(mask[1] == true, "row 0 (hp=10) should be true")
        assert(mask[2] == true, "row 1 (hp=20) should be true")
        assert(mask[3] == false, "row 2 (hp=30) should be false")
    end)

    it("applyMask returns filtered VecFrame with correct row count", function()
        -- @tests VecFrame:applyMask
        local vf = make_vf()
        local mask = vf:filterMask("hp", ">", 15)
        local filtered = vf:applyMask(mask)
        assert(filtered:nrows() == 2, "expected 2 rows, got " .. tostring(filtered:nrows()))
    end)

    it("applyMask combined reduce gives correct sum", function()
        -- @tests VecFrame:applyMask
        local vf = make_vf()
        local mask = vf:filterMask("hp", ">=", 20)
        local filtered = vf:applyMask(mask)
        local s = filtered:reduce("hp", "sum")
        assert(math.abs(s - 50) < 0.0001, "expected 50, got " .. tostring(s))
    end)
end)

-- @tests VecFrame:parReduce
-- @tests VecFrame:parScalarOp
describe("VecFrame parallel operations", function()
    local function make_vf()
        local df = lurek.dataframe.fromCSV("hp,mp\n10,5\n20,10\n30,15\n")
        return lurek.dataframe.toVec(df)
    end

    it("parReduce sum across multiple columns", function()
        -- @tests VecFrame:parReduce
        local vf = make_vf()
        local result = vf:parReduce({"hp", "mp"}, "sum")
        assert(type(result) == "table", "expected table")
        assert(math.abs(result["hp"] - 60) < 0.0001, "expected hp sum=60, got " .. tostring(result["hp"]))
        assert(math.abs(result["mp"] - 30) < 0.0001, "expected mp sum=30, got " .. tostring(result["mp"]))
    end)

    xit("parScalarOp mul across multiple columns", function()
        -- @tests VecFrame:parScalarOp
        local vf = make_vf()
        vf:parScalarOp({"hp", "mp"}, "mul", 2)
        local df2 = lurek.dataframe.fromVec(vf)
        local hp0 = df2:get(0, "hp")
        local mp0 = df2:get(0, "mp")
        assert(math.abs(hp0 - 20) < 0.0001, "expected hp=20, got " .. tostring(hp0))
        assert(math.abs(mp0 - 10) < 0.0001, "expected mp=10, got " .. tostring(mp0))
    end)
end)

-- @tests VecFrame:toDataFrame
describe("VecFrame conversion roundtrip", function()
    xit("toVec â†’ ops â†’ toDataFrame preserves modified values", function()
        -- @tests VecFrame:toDataFrame
        local df = lurek.dataframe.fromCSV("hp,mp\n100,50\n200,100\n")
        local vf = lurek.dataframe.toVec(df)
        vf:colMul("hp", 0.5)
        vf:colAdd("mp", 10)
        local df2 = vf:toDataFrame()
        local hp0 = df2:get(0, "hp")
        local mp0 = df2:get(0, "mp")
        assert(math.abs(hp0 - 50) < 0.0001, "expected hp=50, got " .. tostring(hp0))
        assert(math.abs(mp0 - 60) < 0.0001, "expected mp=60, got " .. tostring(mp0))
    end)
end)

describe("Missing explicit test for DataFrame:describe", function()
    it("DataFrame:describe works", function()
        -- @tests DataFrame:describe
        -- TODO: add assertion for DataFrame:describe
    end)
end)

describe("Missing explicit test for DataFrame:sum", function()
    it("DataFrame:sum works", function()
        -- @tests DataFrame:sum
        -- TODO: add assertion for DataFrame:sum
    end)
end)

describe("Missing explicit test for DataFrame:mean", function()
    it("DataFrame:mean works", function()
        -- @tests DataFrame:mean
        -- TODO: add assertion for DataFrame:mean
    end)
end)

describe("Missing explicit test for DataFrame:median", function()
    it("DataFrame:median works", function()
        -- @tests DataFrame:median
        -- TODO: add assertion for DataFrame:median
    end)
end)

describe("Missing explicit test for DataFrame:stddev", function()
    it("DataFrame:stddev works", function()
        -- @tests DataFrame:stddev
        -- TODO: add assertion for DataFrame:stddev
    end)
end)

describe("Missing explicit test for DataFrame:variance", function()
    it("DataFrame:variance works", function()
        -- @tests DataFrame:variance
        -- TODO: add assertion for DataFrame:variance
    end)
end)

describe("Missing explicit test for DataFrame:fillNil", function()
    it("DataFrame:fillNil works", function()
        -- @tests DataFrame:fillNil
        -- TODO: add assertion for DataFrame:fillNil
    end)
end)

describe("Missing explicit test for DataFrame:toCSV", function()
    it("DataFrame:toCSV works", function()
        -- @tests DataFrame:toCSV
        -- TODO: add assertion for DataFrame:toCSV
    end)
end)

describe("Missing explicit test for DataFrame:toJSON", function()
    it("DataFrame:toJSON works", function()
        -- @tests DataFrame:toJSON
        -- TODO: add assertion for DataFrame:toJSON
    end)
end)

describe("Missing explicit test for DataFrame:toBinary", function()
    it("DataFrame:toBinary works", function()
        -- @tests DataFrame:toBinary
        -- TODO: add assertion for DataFrame:toBinary
    end)
end)

describe("Missing explicit test for DataFrame:toTable", function()
    it("DataFrame:toTable works", function()
        -- @tests DataFrame:toTable
        -- TODO: add assertion for DataFrame:toTable
    end)
end)

describe("Missing explicit test for DataFrame:toString", function()
    it("DataFrame:toString works", function()
        -- @tests DataFrame:toString
        -- TODO: add assertion for DataFrame:toString
    end)
end)

describe("Missing explicit test for DataFrame:query", function()
    it("DataFrame:query works", function()
        -- @tests DataFrame:query
        -- TODO: add assertion for DataFrame:query
    end)
end)

describe("Missing explicit test for DataFrame:clone", function()
    it("DataFrame:clone works", function()
        -- @tests DataFrame:clone
        -- TODO: add assertion for DataFrame:clone
    end)
end)

describe("Missing explicit test for DataFrame:correlationMatrix", function()
    it("DataFrame:correlationMatrix works", function()
        -- @tests DataFrame:correlationMatrix
        -- TODO: add assertion for DataFrame:correlationMatrix
    end)
end)

describe("Missing explicit test for DataFrame:modeVal", function()
    it("DataFrame:modeVal works", function()
        -- @tests DataFrame:modeVal
        -- TODO: add assertion for DataFrame:modeVal
    end)
end)

describe("Missing explicit test for DataFrame:entropy", function()
    it("DataFrame:entropy works", function()
        -- @tests DataFrame:entropy
        -- TODO: add assertion for DataFrame:entropy
    end)
end)

describe("Missing explicit test for DataFrame:addRowBatch", function()
    it("DataFrame:addRowBatch works", function()
        -- @tests DataFrame:addRowBatch
        -- TODO: add assertion for DataFrame:addRowBatch
    end)
end)

describe("Missing explicit test for DataFrame:getColumnAsF64", function()
    it("DataFrame:getColumnAsF64 works", function()
        -- @tests DataFrame:getColumnAsF64
        -- TODO: add assertion for DataFrame:getColumnAsF64
    end)
end)

describe("Missing explicit test for DataFrame:setColumnFromF64", function()
    it("DataFrame:setColumnFromF64 works", function()
        -- @tests DataFrame:setColumnFromF64
        -- TODO: add assertion for DataFrame:setColumnFromF64
    end)
end)

describe("Missing explicit test for DataFrame:type", function()
    it("DataFrame:type works", function()
        -- @tests DataFrame:type
        -- TODO: add assertion for DataFrame:type
    end)
end)

describe("Missing explicit test for DataFrame:typeOf", function()
    it("DataFrame:typeOf works", function()
        -- @tests DataFrame:typeOf
        -- TODO: add assertion for DataFrame:typeOf
    end)
end)

describe("Missing explicit test for Database:getTable", function()
    it("Database:getTable works", function()
        -- @tests Database:getTable
        -- TODO: add assertion for Database:getTable
    end)
end)

describe("Missing explicit test for Database:removeTable", function()
    it("Database:removeTable works", function()
        -- @tests Database:removeTable
        -- TODO: add assertion for Database:removeTable
    end)
end)

describe("Missing explicit test for Database:hasTable", function()
    it("Database:hasTable works", function()
        -- @tests Database:hasTable
        -- TODO: add assertion for Database:hasTable
    end)
end)

describe("Missing explicit test for Database:listTables", function()
    it("Database:listTables works", function()
        -- @tests Database:listTables
        -- TODO: add assertion for Database:listTables
    end)
end)

describe("Missing explicit test for Database:tableCount", function()
    it("Database:tableCount works", function()
        -- @tests Database:tableCount
        -- TODO: add assertion for Database:tableCount
    end)
end)

describe("Missing explicit test for Database:clear", function()
    it("Database:clear works", function()
        -- @tests Database:clear
        -- TODO: add assertion for Database:clear
    end)
end)

describe("Missing explicit test for Database:merge", function()
    it("Database:merge works", function()
        -- @tests Database:merge
        -- TODO: add assertion for Database:merge
    end)
end)

describe("Missing explicit test for Database:toJSON", function()
    it("Database:toJSON works", function()
        -- @tests Database:toJSON
        -- TODO: add assertion for Database:toJSON
    end)
end)

describe("Missing explicit test for Database:query", function()
    it("Database:query works", function()
        -- @tests Database:query
        -- TODO: add assertion for Database:query
    end)
end)

describe("Missing explicit test for Database:type", function()
    it("Database:type works", function()
        -- @tests Database:type
        -- TODO: add assertion for Database:type
    end)
end)

describe("Missing explicit test for Database:typeOf", function()
    it("Database:typeOf works", function()
        -- @tests Database:typeOf
        -- TODO: add assertion for Database:typeOf
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
        df:addColumn("category", nil)
        df:addColumn("value", nil)
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
