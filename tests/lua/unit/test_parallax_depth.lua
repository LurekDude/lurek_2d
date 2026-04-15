-- Lurek2D Parallax Depth Unit Tests (headless)
-- Tests: setDepth / getDepth on ParallaxLayer.
--
-- @covers LuaParallaxLayer.setDepth
-- @covers LuaParallaxLayer.getDepth

-- Helper: create a layer backed by a real texture.
local function make_layer()
    local img = lurek.graphic.newImage("assets/icon.png")
    return lurek.parallax.newLayer({ texture = img })
end

-- ── setDepth / getDepth ───────────────────────────────────────────────────────

-- @description Covers suite: parallax layer floating-point depth.
describe("parallax layer depth", function()
    -- @covers LuaParallaxLayer.getDepth
    -- @description Verifies depth defaults to 0.0 on a newly created layer.
    it("depth defaults to 0.0", function()
        local layer = make_layer()
        expect_near(0.0, layer:getDepth(), 0.001)
    end)

    -- @covers LuaParallaxLayer.setDepth
    -- @covers LuaParallaxLayer.getDepth
    -- @description Sets a positive depth and verifies it round-trips.
    it("setDepth to positive value", function()
        local layer = make_layer()
        layer:setDepth(10.0)
        expect_near(10.0, layer:getDepth(), 0.001)
    end)

    -- @covers LuaParallaxLayer.setDepth
    -- @covers LuaParallaxLayer.getDepth
    -- @description Sets a negative depth and verifies it round-trips.
    it("setDepth to negative value", function()
        local layer = make_layer()
        layer:setDepth(-10.0)
        expect_near(-10.0, layer:getDepth(), 0.001)
    end)

    -- @covers LuaParallaxLayer.setDepth
    -- @covers LuaParallaxLayer.getDepth
    -- @description Sets a fractional depth and verifies it round-trips with
    -- floating-point tolerance.
    it("setDepth to fractional value", function()
        local layer = make_layer()
        layer:setDepth(0.5)
        expect_near(0.5, layer:getDepth(), 0.001)
    end)

    -- @covers LuaParallaxLayer.setDepth
    -- @covers LuaParallaxLayer.getDepth
    -- @description Verifies depth can be updated multiple times.
    it("setDepth can be updated multiple times", function()
        local layer = make_layer()
        layer:setDepth(1.0)
        layer:setDepth(-5.5)
        layer:setDepth(100.0)
        expect_near(100.0, layer:getDepth(), 0.001)
    end)

    -- @covers LuaParallaxLayer.setDepth
    -- @covers LuaParallaxLayer.getDepth
    -- @description Verifies depth is independent of the integer z value.
    it("setDepth is independent of setZ", function()
        local layer = make_layer()
        layer:setZ(5)
        layer:setDepth(2.5)
        expect_equal(5, layer:getZ())
        expect_near(2.5, layer:getDepth(), 0.001)
    end)
end)

test_summary()
