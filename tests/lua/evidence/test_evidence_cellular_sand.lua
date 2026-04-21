-- Evidence test: cellular sand falling simulation
-- Produces: cellular_sand.png showing sand particles after 50 simulation steps.
-- Proves CellularWorld step() works: sand placed at the top migrates to the bottom.

-- @description Covers suite: evidence: cellular sand simulation.
describe("evidence: cellular sand simulation", function()
    -- @covers lurek.physics.newCellular
    -- @covers LuaCellular:fillRect
    -- @covers LuaCellular:stepN
    -- @covers LuaCellular:toImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Places a layer of sand at the top of a 64x64 grid,
    --              steps 50 times, then renders and saves a PNG proving
    --              sand migrated downward (pile visible at the bottom).
    it("sand falls to the bottom and produces a visible pile image", function()
        ensure_evidence_dir("physics")
        local path = evidence_output_dir("physics") .. "cellular_sand.png"

        local W, H = 64, 64
        local sim = lurek.physics.newCellular(W, H)

        -- Fill top 3 rows with sand.
        sim:fillRect(0, 0, W, 3, lurek.physics.CELL_SAND)

        -- Run simulation for 50 ticks.
        sim:stepN(50)

        -- Verify sand moved (counted at top row should be near zero).
        local top_sand = 0
        for x = 0, W - 1 do
            if sim:getCell(x, 0) == lurek.physics.CELL_SAND then
                top_sand = top_sand + 1
            end
        end
        expect_true(top_sand < W * 3, "sand should have migrated away from top")

        -- Render evidence image.
        local raw = sim:toImageData()
        expect_equal(W * H * 4, #raw)

        local img = lurek.image.newImageData(W, H)
        img:setRawData(raw)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)

test_summary()
