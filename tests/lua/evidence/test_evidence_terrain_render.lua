-- Evidence test: terrain render
-- Produces: terrain_render.png showing the terrain grid as a pixel image.
-- This test proves the TerrainMap API works by creating a terrain, filling
-- a pattern, and calling toImageData to produce a verifiable PNG.

-- @description Covers suite: evidence: terrain render.
describe("evidence: terrain render", function()
    -- @covers lurek.physics.newTerrain
    -- @covers LuaTerrain:fillAll
    -- @covers LuaTerrain:fillCircle
    -- @covers LuaTerrain:toImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Creates a 64x64 terrain, fills it solid, digs a circle,
    --              renders to RGBA bytes, and saves as a PNG evidence file.
    it("terrain toImageData produces a pixel image", function()
        ensure_evidence_dir("physics")
        local path = evidence_output_dir("physics") .. "terrain_render.png"

        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(64, 64, 4, world)

        -- Fill solid ground.
        terrain:fillAll(true)
        -- Dig a large crater in the centre.
        terrain:fillCircle(128, 128, 64, false)

        -- Render to RGBA bytes (solid = brown, empty = dark sky).
        local raw = terrain:toImageData(139, 90, 43, 30, 30, 60)
        expect_equal(64 * 64 * 4, #raw)

        -- Build an image from raw bytes and save.
        local img = lurek.image.newImageData(64, 64)
        img:setRawData(raw)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)

test_summary()
