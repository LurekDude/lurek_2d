-- Luna2D Stress Test: DataFrame Bulk Operations
-- Tests large DataFrames with many rows and columns

describe("dataframe stress: bulk row insertion", function()
    it("inserts 5000 rows", function()
        local df = luna.dataframe.newDataFrame()
        df:addColumn("id", 0)
        df:addColumn("name", "")
        df:addColumn("score", 0.0)

        for i = 1, 5000 do
            df:addRow({id = i, name = "player_" .. i, score = i * 1.5})
        end

        expect_equal(5000, df:nrows(), "5000 rows added")
        expect_equal(3, df:ncols(), "3 columns")
    end)

    it("reads back all 5000 rows correctly", function()
        local df = luna.dataframe.newDataFrame()
        df:addColumn("value", 0)

        for i = 1, 5000 do
            df:addRow({value = i})
        end

        -- Spot check
        local val_1 = df:getValue(1, "value")
        local val_2500 = df:getValue(2500, "value")
        local val_5000 = df:getValue(5000, "value")

        expect_near(1, val_1, 0.01, "first row")
        expect_near(2500, val_2500, 0.01, "middle row")
        expect_near(5000, val_5000, 0.01, "last row")
    end)
end)

describe("dataframe stress: many columns", function()
    it("creates DataFrame with 50 columns", function()
        local df = luna.dataframe.newDataFrame()

        for c = 1, 50 do
            df:addColumn("col_" .. c, 0)
        end

        -- Add 100 rows
        for r = 1, 100 do
            local row = {}
            for c = 1, 50 do
                row["col_" .. c] = r * c
            end
            df:addRow(row)
        end

        expect_equal(100, df:nrows(), "100 rows")
        expect_equal(50, df:ncols(), "50 columns")

        -- Spot check
        local val = df:getValue(50, "col_25")
        expect_near(50 * 25, val, 0.01, "row 50 col 25")
    end)
end)

describe("dataframe stress: column operations", function()
    it("adds and removes columns repeatedly", function()
        local df = luna.dataframe.newDataFrame()

        -- Add 20 rows first
        df:addColumn("base", 0)
        for i = 1, 20 do
            df:addRow({base = i})
        end

        -- Add and remove 100 columns
        for cycle = 1, 100 do
            local name = "temp_" .. cycle
            df:addColumn(name, cycle)
            df:removeColumn(name)
        end

        -- DataFrame should still be functional
        expect_equal(20, df:nrows(), "rows preserved after column churn")
        expect_equal(1, df:ncols(), "only base column remains")
    end)
end)
