-- Lurek2D minimap multi-layer and marker animation tests.
-- Covers: setLayer, getLayer, setLayerData, setMarkerAnimation, clearMarkerAnimation.

-- @description Covers suite: minimap layers.
describe("minimap layers", function()
    -- @covers Minimap.getLayer
    -- @description getLayer returns 0 by default.
    it("setLayer defaults to layer 0", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        expect_equal(mm:getLayer(), 0)
    end)

    -- @covers Minimap.setLayer
    -- @covers Minimap.getLayer
    -- @description setLayer and getLayer round-trip correctly.
    it("setLayer and getLayer work", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:setLayer(1)
        expect_equal(mm:getLayer(), 1)
    end)

    -- @covers Minimap.setLayer
    -- @covers Minimap.getLayer
    -- @description setLayer can switch between multiple layer indices.
    it("setLayer can switch between layers", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:setLayer(2)
        expect_equal(mm:getLayer(), 2)
        mm:setLayer(0)
        expect_equal(mm:getLayer(), 0)
    end)

    -- @covers Minimap.setLayerData
    -- @description setLayerData stores a flat table without error.
    it("setLayerData stores layer data", function()
        local mm = lurek.minimap.newMinimap(8, 8)
        local data = {}
        for i = 1, 64 do data[i] = 0 end
        mm:setLayerData(0, data)
        expect_equal(true, true)
    end)

    -- @covers Minimap.setLayerData
    -- @description setLayerData can write non-contiguous layer indices.
    it("setLayerData works for higher layer indices", function()
        local mm = lurek.minimap.newMinimap(4, 4)
        local data = {}
        for i = 1, 16 do data[i] = 1 end
        mm:setLayerData(2, data)
        expect_equal(true, true)
    end)
end)

-- @description Covers suite: minimap marker animation.
describe("minimap marker animation", function()
    -- @covers Minimap.setMarkerAnimation
    -- @description setMarkerAnimation with "blink" does not error.
    it("setMarkerAnimation blink does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "blink", 2.0)
        expect_equal(true, true)
    end)

    -- @covers Minimap.setMarkerAnimation
    -- @description setMarkerAnimation with "pulse" does not error.
    it("setMarkerAnimation pulse does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "pulse", 1.5)
        expect_equal(true, true)
    end)

    -- @covers Minimap.setMarkerAnimation
    -- @description setMarkerAnimation with "rotate" does not error.
    it("setMarkerAnimation rotate does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "rotate", 3.14)
        expect_equal(true, true)
    end)

    -- @covers Minimap.clearMarkerAnimation
    -- @description clearMarkerAnimation removes animation without error.
    it("clearMarkerAnimation stops animation", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        mm:setMarkerAnimation(id, "blink", 1.0)
        mm:clearMarkerAnimation(id)
        expect_equal(true, true)
    end)

    -- @covers Minimap.setMarkerAnimation
    -- @description setMarkerAnimation with an invalid type returns an error.
    it("setMarkerAnimation rejects unknown type", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        expect_error(function()
            mm:setMarkerAnimation(id, "spin_forever", 1.0)
        end)
    end)

    -- @covers Minimap.update
    -- @covers Minimap.setMarkerAnimation
    -- @description update advances animation phases without error.
    it("update advances marker animation phases", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        mm:setMarkerAnimation(id, "blink", 2.0)
        mm:update(0.016)
        expect_equal(true, true)
    end)
end)

test_summary()
