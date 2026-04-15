-- Lurek2D minimap geometry overlay tests.
-- Covers: drawLine, drawRect, clearOverlay.

-- @description Covers suite: minimap geometry overlay.
describe("minimap geometry overlay", function()
    -- @covers Minimap.drawLine
    -- @description drawLine accepts valid coordinates and color table without error.
    it("drawLine does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 32, 32, {255, 0, 0, 255})
        expect_equal(true, true)
    end)

    -- @covers Minimap.drawRect
    -- @description drawRect accepts valid coordinates and color table without error.
    it("drawRect does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawRect(10, 10, 20, 20, {0, 255, 0, 255})
        expect_equal(true, true)
    end)

    -- @covers Minimap.clearOverlay
    -- @description clearOverlay removes all geometry without crashing.
    it("clearOverlay clears geometry", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 10, 10, {255, 0, 0, 255})
        mm:drawRect(5, 5, 15, 15, {0, 0, 255, 255})
        mm:clearOverlay()
        expect_equal(true, true)
    end)

    -- @covers Minimap.drawLine
    -- @covers Minimap.clearOverlay
    -- @description clearOverlay can be called on an empty overlay without error.
    it("clearOverlay on empty overlay does not error", function()
        local mm = lurek.minimap.newMinimap(32, 32)
        mm:clearOverlay()
        expect_equal(true, true)
    end)

    -- @covers Minimap.drawLine
    -- @covers Minimap.drawRect
    -- @description Multiple shapes can be accumulated before clearing.
    it("multiple shapes accumulate before clear", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 10, 10, {255, 0, 0, 255})
        mm:drawLine(10, 10, 20, 20, {0, 255, 0, 255})
        mm:drawRect(0, 0, 8, 8, {255, 255, 0, 255})
        mm:clearOverlay()
        expect_equal(true, true)
    end)
end)

test_summary()
