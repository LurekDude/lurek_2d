-- Integration: compute statistics fed into dataframe reports
describe("integration: compute statistics to dataframe", function()
    -- @integration LDataFrame:addColumn
    -- @integration LDataFrame:addRow
    -- @integration LDataFrame:getValue
    -- @integration LDataFrame:ncols
    -- @integration LDataFrame:nrows
    -- @integration lurek.compute.ones
    -- @integration lurek.compute.range
    -- @integration lurek.dataframe.newDataFrame
    it("compute array stats populate dataframe", function()
        -- Create arrays with known distributions
        local datasets = {
            lurek.compute.range(1, 101, 1, "float32"),    -- 1-100
            lurek.compute.ones({100}, "float32"),          -- all ones
            lurek.compute.range(50, 150, 1, "float32"),    -- 50-149
        }
        local names = {"linear", "uniform", "offset"}

        -- Create a DataFrame to hold statistics
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("dataset", "")
        df:addColumn("count", 0)
        df:addColumn("sum", 0)
        df:addColumn("mean", 0)
        df:addColumn("min", 0)
        df:addColumn("max", 0)

        for i, arr in ipairs(datasets) do
            df:addRow({
                dataset = names[i],
                count = arr:getSize(),
                sum = arr:sum(),
                mean = arr:mean(),
                min = arr:min(),
                max = arr:max(),
            })
        end

        expect_equal(3, df:nrows(), "3 dataset rows")
        expect_equal(6, df:ncols(), "6 stat columns")

        -- Verify linear dataset stats (row 1 = "linear": 1..100, sum=5050)
        expect_near(100, df:getValue(1, "count"), 0.01, "linear count")
        expect_near(5050, df:getValue(1, "sum"), 1.0, "linear sum")
        expect_near(50.5, df:getValue(1, "mean"), 0.1, "linear mean")
        expect_near(1, df:getValue(1, "min"), 0.01, "linear min")
        expect_near(100, df:getValue(1, "max"), 0.01, "linear max")

        -- Verify uniform dataset (row 2 = "uniform": all ones, sum=100)
        expect_near(100, df:getValue(2, "sum"), 0.01, "uniform sum")
        expect_near(1.0, df:getValue(2, "mean"), 0.001, "uniform mean")
    end)
end)

describe("integration: image data to compute array", function()
    -- @integration LArray:getSize
    -- @integration LArray:max
    -- @integration LArray:min
    -- @integration LImageData:getPixel
    -- @integration LImageData:setPixel
    -- @integration lurek.compute.fromTable
    -- @integration lurek.image.newImageData
    it("image pixel data can be analyzed with compute", function()
        -- Create a gradient image
        local width, height = 16, 16
        local img = lurek.image.newImageData(width, height)

        -- Set pixels with gradient
        for y = 0, height - 1 do
            for x = 0, width - 1 do
                img:setPixel(x, y, x * 16, y * 16, 128, 255)
            end
        end

        -- Extract red channel values into a table
        local red_values = {}
        for y = 0, height - 1 do
            for x = 0, width - 1 do
                local r, g, b, a = img:getPixel(x, y)
                table.insert(red_values, r)
            end
        end

        -- Create compute array from red channel
        local arr = lurek.compute.fromTable(red_values, nil, "float32")
        expect_equal(256, arr:getSize(), "256 pixels")

        -- Analyze
        expect_near(0, arr:min(), 0.01, "min red is 0")
        expect_near(240, arr:max(), 0.01, "max red is 240")
    end)
end)

test_summary()
