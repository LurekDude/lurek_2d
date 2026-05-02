-- tests/lua/integration/test_image_dataframe.lua
-- Integration: lurek.image pixel data and lurek.dataframe tabular analysis combined.

describe("image + dataframe integration", function()
    it("creates ImageData and records pixel stats in a DataFrame", function()
        local img = lurek.image.newImageData(4, 4)
        -- fill with known pixels
        for y = 0, 3 do
            for x = 0, 3 do
                img:setPixel(x, y, x * 60, y * 60, 128, 255)
            end
        end

        local df = lurek.dataframe.newDataFrame()
        df:addColumn("r")
        df:addColumn("g")
        df:addColumn("b")

        for y = 0, 3 do
            for x = 0, 3 do
                local r, g, b, _ = img:getPixel(x, y)
                df:addRow({ r = r, g = g, b = b })
            end
        end

        expect_equal(16, df:nrows(), "16 pixels become 16 DataFrame rows")
        expect_equal(3, df:ncols(), "r/g/b columns present")
    end)

    it("ImageData width/height round-trips", function()
        local img = lurek.image.newImageData(32, 16)
        expect_equal(img:getWidth(), 32, "width is 32")
        expect_equal(img:getHeight(), 16, "height is 16")
    end)

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
