-- Lurek2D Integration Test: Compute + DataFrame
-- Tests NdArray statistical operations feeding into DataFrame reports

describe("integration: compute statistics to dataframe", function()
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
    it("image pixel data can be analyzed with compute", function()
        -- Create a gradient image
        local width, height = 16, 16
        local img = lurek.img.newImageData(width, height)

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

describe("integration: data encoding pipeline", function()
    it("compress -> encode -> decode -> decompress roundtrip", function()
        local original = "Lurek2D integration test: compress then encode then decode then decompress."

        -- Step 1: Compress
        local compressed = lurek.data.compress("deflate", original, 6)

        -- Step 2: Base64 encode (for safe text transport)
        local encoded = lurek.data.encode("base64", compressed)
        expect_type("string", encoded, "encoded is string")

        -- Step 3: Base64 decode
        local decoded_compressed = lurek.data.decode("base64", encoded)

        -- Step 4: Decompress
        local result = lurek.data.decompress("deflate", decoded_compressed)

        expect_equal(original, result, "full pipeline preserves data")
    end)

    it("hash of compressed data is stable", function()
        local data = "Hash stability test vector"
        local compressed = lurek.data.compress("zlib", data, 6)

        local hash1 = lurek.data.hash("sha256", compressed)
        local hash2 = lurek.data.hash("sha256", compressed)

        expect_equal(hash1, hash2, "hash is deterministic")
        expect_equal(64, #hash1, "SHA-256 produces 64 hex chars")
    end)
end)
