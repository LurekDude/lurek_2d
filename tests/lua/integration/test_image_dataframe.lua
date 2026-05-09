-- Integration: image pixel data analyzed via dataframe columns
describe("image + dataframe integration", function()
    -- @integration LDataFrame:addColumn
    -- @integration LDataFrame:addRow
    -- @integration LDataFrame:ncols
    -- @integration LDataFrame:nrows
    -- @integration LImageData:getPixel
    -- @integration LImageData:setPixel
    -- @integration lurek.dataframe.newDataFrame
    -- @integration lurek.image.newImageData
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

end)
test_summary()
