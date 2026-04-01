-- Luna2D Integration Test: Compute + DataFrame
-- Tests using compute arrays for bulk data that feeds into DataFrames

describe("integration: compute analysis to dataframe", function()
    it("generates data with compute, stores in dataframe", function()
        -- Generate numeric data with compute
        local values = luna.compute.range(1, 101, 1, "float32")
        local squared = values:mul(values)

        -- Store results in a DataFrame
        local df = luna.dataframe.newDataFrame()
        df:addColumn("value", 0)
        df:addColumn("squared", 0)

        for i = 1, 100 do
            df:addRow({
                value = i,
                squared = i * i
            })
        end

        expect_equal(100, df:nrows(), "100 rows stored")
        expect_near(1, df:getValue(1, "value"), 0.01, "first value")
        expect_near(10000, df:getValue(100, "squared"), 0.01, "last squared")
    end)
end)

describe("integration: compute stats match dataframe", function()
    it("compute sum matches dataframe column sum", function()
        local arr = luna.compute.range(1, 51, 1, "float32")
        local compute_sum = arr:sum()

        local df = luna.dataframe.newDataFrame()
        df:addColumn("val", 0)
        for i = 1, 50 do
            df:addRow({val = i})
        end

        -- Both should agree on sum 1+2+...+50 = 1275
        expect_near(1275, compute_sum, 0.1, "compute sum")
    end)
end)
