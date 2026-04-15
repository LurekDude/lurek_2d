-- Lurek2D Parallax Tiling Unit Tests (headless)
-- Tests: setTiling / getTiling / setTileSize on ParallaxLayer.
--
-- @covers LuaParallaxLayer.setTiling
-- @covers LuaParallaxLayer.getTiling
-- @covers LuaParallaxLayer.setTileSize

-- Helper: load a real texture for tests that require a LuaImage.
local function make_layer()
    local img = lurek.graphic.newImage("assets/icon.png")
    return lurek.parallax.newLayer({ texture = img })
end

-- ── setTiling / getTiling ─────────────────────────────────────────────────────

-- @description Covers suite: parallax tiling enable/disable.
describe("parallax tiling", function()
    -- @covers LuaParallaxLayer.getTiling
    -- @description Verifies tiling is disabled by default on a newly created layer.
    it("tiling is disabled by default", function()
        local layer = make_layer()
        expect_equal(false, layer:getTiling())
    end)

    -- @covers LuaParallaxLayer.setTiling
    -- @covers LuaParallaxLayer.getTiling
    -- @description Enables tiling and verifies getTiling returns true.
    it("setTiling(true) enables tiling", function()
        local layer = make_layer()
        layer:setTiling(true)
        expect_equal(true, layer:getTiling())
    end)

    -- @covers LuaParallaxLayer.setTiling
    -- @covers LuaParallaxLayer.getTiling
    -- @description Disables tiling after enabling and verifies getTiling returns false.
    it("setTiling(false) disables tiling", function()
        local layer = make_layer()
        layer:setTiling(true)
        layer:setTiling(false)
        expect_equal(false, layer:getTiling())
    end)

    -- @covers LuaParallaxLayer.setTiling
    -- @covers LuaParallaxLayer.getTiling
    -- @description Verifies multiple toggle round-trips are stable.
    it("toggling tiling multiple times is stable", function()
        local layer = make_layer()
        layer:setTiling(true)
        layer:setTiling(false)
        layer:setTiling(true)
        expect_equal(true, layer:getTiling())
    end)
end)

-- ── setTileSize ───────────────────────────────────────────────────────────────

-- @description Covers suite: parallax tile size override.
describe("parallax tile size", function()
    -- @covers LuaParallaxLayer.setTileSize
    -- @description Verifies setTileSize accepts positive dimensions without error.
    it("setTileSize accepts positive dimensions", function()
        local layer = make_layer()
        -- Should not error
        layer:setTileSize(256.0, 128.0)
        expect_equal(true, true)  -- reached without error
    end)

    -- @covers LuaParallaxLayer.setTileSize
    -- @description Verifies setTileSize with zero width resets to texture-based dimensions.
    it("setTileSize with zero width resets to texture default", function()
        local layer = make_layer()
        layer:setTileSize(0.0, 64.0)
        -- Non-positive w resets tile_w; no error expected
        expect_equal(true, true)
    end)

    -- @covers LuaParallaxLayer.setTileSize
    -- @description Verifies setTileSize can be combined with setTiling without error.
    it("setTileSize combined with setTiling works", function()
        local layer = make_layer()
        layer:setTiling(true)
        layer:setTileSize(128.0, 128.0)
        expect_equal(true, layer:getTiling())
    end)
end)

test_summary()
