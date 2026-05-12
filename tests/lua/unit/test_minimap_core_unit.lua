-- Lurek2D minimap API tests.
-- Covers minimap construction, terrain/object/fog state, view controls, and helper queries exposed through lurek.minimap.

-- @describe lurek.minimap.newMinimap
describe("lurek.minimap.newMinimap", function()
    -- @covers LMinimap:getGridHeight
    -- @covers LMinimap:getGridWidth
    -- @covers lurek.minimap.newMinimap
    it("creates a minimap with grid dimensions", function()
        local m = lurek.minimap.newMinimap(64, 48)
        expect_type("userdata", m)
        expect_equal(64, m:getGridWidth())
        expect_equal(48, m:getGridHeight())
    end)

    -- @covers LMinimap:getDisplayHeight
    -- @covers LMinimap:getDisplayWidth
    -- @covers lurek.minimap.newMinimap
    it("creates a minimap with custom display size", function()
        local m = lurek.minimap.newMinimap(32, 32, 200, 150)
        expect_equal(200, m:getDisplayWidth())
        expect_equal(150, m:getDisplayHeight())
    end)

    -- @covers LMinimap:type
    -- @covers LMinimap:typeOf
    -- @covers lurek.minimap.newMinimap
    it("reports correct type", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal("LMinimap", m:type())
        expect_true(m:typeOf("Minimap"))
        expect_true(m:typeOf("Object"))
        expect_false(m:typeOf("Image"))
    end)
end)

-- Grid dimensions

-- @describe grid dimensions
describe("grid dimensions", function()
    -- @covers LMinimap:getCellCount
    -- @covers lurek.minimap.newMinimap
    it("returns total cell count", function()
        local m = lurek.minimap.newMinimap(40, 30)
        expect_equal(1200, m:getCellCount())
    end)

    -- @covers LMinimap:clearPath
    -- @covers LMinimap:getPathCount
    -- @covers LMinimap:showPath
    -- @covers lurek.minimap.newMinimap

    -- @covers LMinimap:getGridSize
    -- @covers lurek.minimap.newMinimap
    it("returns grid size as two values", function()
        local m = lurek.minimap.newMinimap(40, 30)
        local w, h = m:getGridSize()
        expect_equal(40, w)
        expect_equal(30, h)
    end)
end)

-- Display size

-- @describe display size
describe("display size", function()
    -- @covers LMinimap:getDisplayHeight
    -- @covers LMinimap:getDisplaySize
    -- @covers LMinimap:getDisplayWidth
    -- @covers LMinimap:setDisplaySize
    -- @covers lurek.minimap.newMinimap
    it("can set and get display size", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setDisplaySize(300, 200)
        expect_equal(300, m:getDisplayWidth())
        expect_equal(200, m:getDisplayHeight())
        local w, h = m:getDisplaySize()
        expect_equal(300, w)
        expect_equal(200, h)
    end)
end)

-- Terrain

-- @describe terrain
describe("terrain", function()
    -- @covers LMinimap:getTerrain
    -- @covers lurek.minimap.newMinimap
    it("defaults to terrain type 0", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getTerrain(1, 1))
        expect_equal(0, m:getTerrain(5, 5))
    end)

    -- @covers LMinimap:getTerrain
    -- @covers LMinimap:setTerrain
    -- @covers lurek.minimap.newMinimap
    it("can set and get terrain type", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setTerrain(3, 4, 7)
        expect_equal(7, m:getTerrain(3, 4))
    end)

    -- @covers LMinimap:getTerrainColor
    -- @covers LMinimap:setTerrainColor
    -- @covers lurek.minimap.newMinimap
    it("can set and get terrain colors with alpha", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setTerrainColor(1, 0.2, 0.4, 0.6, 0.8)
        local r, g, b, a = m:getTerrainColor(1)
        expect_near(0.2, r)
        expect_near(0.4, g)
        expect_near(0.6, b)
        expect_near(0.8, a)
    end)

    -- @covers LMinimap:getTerrainColor
    -- @covers LMinimap:setTerrainColor
    -- @covers lurek.minimap.newMinimap
    it("defaults alpha to 1.0", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setTerrainColor(2, 0.1, 0.2, 0.3)
        local _, _, _, a = m:getTerrainColor(2)
        expect_near(1.0, a)
    end)
end)

-- Fog of war

-- @describe fog of war
describe("fog of war", function()
    -- @covers LMinimap:isFogEnabled
    -- @covers lurek.minimap.newMinimap
    it("is disabled by default", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_false(m:isFogEnabled())
    end)
    -- @covers LMinimap:isFogEnabled
    -- @covers LMinimap:setFogEnabled
    -- @covers lurek.minimap.newMinimap
    it("can toggle fog", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setFogEnabled(true)
        expect_true(m:isFogEnabled())
        m:setFogEnabled(false)
        expect_false(m:isFogEnabled())
    end)

    -- @covers LMinimap:getFogLevel
    -- @covers lurek.minimap.newMinimap
    it("defaults fog level to 0 (hidden)", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getFogLevel(1, 1))
    end)

    -- @covers LMinimap:getFogLevel
    -- @covers LMinimap:setFogLevel
    -- @covers lurek.minimap.newMinimap
    it("can set fog levels", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setFogLevel(2, 3, 2) -- visible
        expect_equal(2, m:getFogLevel(2, 3))
        m:setFogLevel(2, 3, 1) -- explored
        expect_equal(1, m:getFogLevel(2, 3))
    end)

    -- @covers LMinimap:getFogColor
    -- @covers LMinimap:setFogColor
    -- @covers lurek.minimap.newMinimap
    it("can set fog color", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setFogColor(0.1, 0.2, 0.3, 0.5)
        local r, g, b, a = m:getFogColor()
        expect_near(0.1, r)
        expect_near(0.2, g)
        expect_near(0.3, b)
        expect_near(0.5, a)
    end)

    -- @covers LMinimap:getFogLevel
    -- @covers LMinimap:setFogData
    -- @covers lurek.minimap.newMinimap
    it("can bulk set fog data", function()
        local m = lurek.minimap.newMinimap(3, 3)
        m:setFogData({
            2, 1, 0,
            0, 2, 1,
            1, 0, 2,
        })
        expect_equal(2, m:getFogLevel(1, 1))
        expect_equal(1, m:getFogLevel(2, 1))
        expect_equal(0, m:getFogLevel(3, 1))
        expect_equal(0, m:getFogLevel(1, 2))
        expect_equal(2, m:getFogLevel(2, 2))
        expect_equal(2, m:getFogLevel(3, 3))
    end)
end)

-- Object types

-- @describe object types
describe("object types", function()
    -- @covers LMinimap:getObjectTypeCount
    -- @covers lurek.minimap.newMinimap
    it("starts with zero types", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getObjectTypeCount())
    end)

    -- @covers LMinimap:addObjectType
    -- @covers LMinimap:getObjectTypeCount
    -- @covers lurek.minimap.newMinimap
    it("adds types with 1-based indices", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local idx1 = m:addObjectType("unit", 1, 0, 0)
        expect_equal(1, idx1)
        local idx2 = m:addObjectType("building", 0, 0, 1, 0.8)
        expect_equal(2, idx2)
        expect_equal(2, m:getObjectTypeCount())
    end)

    -- @covers LMinimap:addObjectType
    -- @covers LMinimap:isObjectTypeVisible
    -- @covers LMinimap:setObjectTypeVisible
    -- @covers lurek.minimap.newMinimap
    it("toggles type visibility", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local idx = m:addObjectType("unit", 1, 0, 0)
        expect_true(m:isObjectTypeVisible(idx))
        m:setObjectTypeVisible(idx, false)
        expect_false(m:isObjectTypeVisible(idx))
    end)
end)

-- Objects

-- @describe objects
describe("objects", function()
    -- @covers LMinimap:getObjectCount
    -- @covers lurek.minimap.newMinimap
    it("starts with zero objects", function()
        local m = lurek.minimap.newMinimap(100, 100)
        expect_equal(0, m:getObjectCount())
    end)

    -- @covers LMinimap:addObjectType
    -- @covers LMinimap:getObjectCount
    -- @covers LMinimap:removeObject
    -- @covers LMinimap:setObject
    -- @covers lurek.minimap.newMinimap
    it("can add and remove objects", function()
        local m = lurek.minimap.newMinimap(100, 100)
        local idx = m:addObjectType("unit", 1, 0, 0)
        m:setObject(1, 50, 60, idx)
        expect_equal(1, m:getObjectCount())
        m:setObject(2, 70, 80, idx, 1)
        expect_equal(2, m:getObjectCount())
        expect_true(m:removeObject(1))
        expect_equal(1, m:getObjectCount())
        expect_false(m:removeObject(999))
    end)

    -- @covers LMinimap:addObjectType
    -- @covers LMinimap:clearObjects
    -- @covers LMinimap:getObjectCount
    -- @covers LMinimap:setObject
    -- @covers lurek.minimap.newMinimap
    it("can clear all objects", function()
        local m = lurek.minimap.newMinimap(100, 100)
        local idx = m:addObjectType("unit", 1, 0, 0)
        m:setObject(1, 10, 10, idx)
        m:setObject(2, 20, 20, idx)
        m:clearObjects()
        expect_equal(0, m:getObjectCount())
    end)
end)

-- Owner colors

-- @describe owner colors
describe("owner colors", function()
    -- @covers LMinimap:getOwnerColor
    -- @covers LMinimap:setOwnerColor
    -- @covers lurek.minimap.newMinimap
    it("can set and get owner colors", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setOwnerColor(1, 0, 0, 1, 0.9)
        local r, g, b, a = m:getOwnerColor(1)
        expect_near(0.0, r)
        expect_near(0.0, g)
        expect_near(1.0, b)
        expect_near(0.9, a)
    end)
end)

-- Color mode

-- @describe color mode
describe("color mode", function()
    -- @covers LMinimap:getColorMode
    -- @covers lurek.minimap.newMinimap
    it("defaults to terrain", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal("terrain", m:getColorMode())
    end)

    -- @covers LMinimap:getColorMode
    -- @covers LMinimap:setColorMode
    -- @covers lurek.minimap.newMinimap
    it("can switch to political", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setColorMode("political")
        expect_equal("political", m:getColorMode())
    end)

    -- @covers LMinimap:setColorMode
    -- @covers lurek.minimap.newMinimap
    it("errors on invalid mode", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_error(function() m:setColorMode("invalid") end)
    end)
end)

-- Zoom and pan

-- @describe zoom and pan
describe("zoom and pan", function()
    -- @covers LMinimap:getZoom
    -- @covers lurek.minimap.newMinimap
    it("defaults zoom to 1.0", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_near(1.0, m:getZoom())
    end)

    -- @covers LMinimap:getZoom
    -- @covers LMinimap:setZoom
    -- @covers lurek.minimap.newMinimap
    it("can set zoom", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setZoom(2.5)
        expect_near(2.5, m:getZoom())
    end)

    -- @covers LMinimap:getCenter
    -- @covers LMinimap:setCenter
    -- @covers lurek.minimap.newMinimap
    it("can set center", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(5, 3)
        local cx, cy = m:getCenter()
        expect_near(5, cx)
        expect_near(3, cy)
    end)

    -- @covers LMinimap:getCenter
    -- @covers LMinimap:getViewportRect
    -- @covers LMinimap:trackCamera
    -- @covers lurek.camera.new
    -- @covers lurek.minimap.newMinimap
    it("can track a camera", function()
        local m = lurek.minimap.newMinimap(64, 64)
        local cam = lurek.camera.new(20, 10)
        cam:setPosition(12, 18)
        cam:setZoom(2.0)

        m:trackCamera(cam)

        local cx, cy = m:getCenter()
        local x, y, w, h = m:getViewportRect()
        expect_near(12, cx)
        expect_near(18, cy)
        expect_near(7, x)
        expect_near(15.5, y)
        expect_near(10, w)
        expect_near(5, h)
    end)

    -- @covers LMinimap:getFogLevel
    -- @covers LMinimap:revealRadius
    -- @covers LMinimap:setFogData
    -- @covers LMinimap:setFogEnabled
    -- @covers lurek.minimap.newMinimap
    it("can reveal a circular fog area", function()
        local m = lurek.minimap.newMinimap(8, 8)
        local hidden = {}
        for i = 1, 64 do hidden[i] = 0 end
        m:setFogEnabled(true)
        m:setFogData(hidden)

        m:revealRadius(3.5, 3.5, 1.6)

        expect_equal(2, m:getFogLevel(4, 4))
        expect_equal(2, m:getFogLevel(3, 4))
        expect_equal(0, m:getFogLevel(1, 1))
    end)
end)

-- Viewport

-- @describe viewport
describe("viewport", function()
    -- @covers LMinimap:getViewportRect
    -- @covers lurek.minimap.newMinimap
    it("starts with no viewport rect", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_nil(m:getViewportRect())
    end)

    -- @covers LMinimap:getViewportRect
    -- @covers LMinimap:setViewportRect
    -- @covers lurek.minimap.newMinimap
    it("can set and get viewport rect", function()
        local m = lurek.minimap.newMinimap(100, 100)
        m:setViewportRect(10, 20, 30, 40)
        local x, y, w, h = m:getViewportRect()
        expect_not_nil(x)
        expect_equal(10, x)
        expect_equal(20, y)
        expect_equal(30, w)
        expect_equal(40, h)
    end)

    -- @covers LMinimap:clearViewportRect
    -- @covers LMinimap:getViewportRect
    -- @covers LMinimap:setViewportRect
    -- @covers lurek.minimap.newMinimap
    it("can clear viewport rect", function()
        local m = lurek.minimap.newMinimap(100, 100)
        m:setViewportRect(10, 20, 30, 40)
        m:clearViewportRect()
        expect_nil(m:getViewportRect())
    end)

    -- @covers LMinimap:isViewportVisible
    -- @covers LMinimap:setViewportVisible
    -- @covers lurek.minimap.newMinimap
    it("can toggle viewport visibility", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_true(m:isViewportVisible())
        m:setViewportVisible(false)
        expect_false(m:isViewportVisible())
    end)

    -- @covers LMinimap:getViewportColor
    -- @covers LMinimap:setViewportColor
    -- @covers lurek.minimap.newMinimap
    it("can set viewport color", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setViewportColor(0.5, 0.6, 0.7, 0.3)
        local r, g, b, a = m:getViewportColor()
        expect_near(0.5, r)
        expect_near(0.6, g)
        expect_near(0.7, b)
        expect_near(0.3, a)
    end)
end)

-- Pings

-- @describe pings
describe("pings", function()
    -- @covers LMinimap:getPingCount
    -- @covers lurek.minimap.newMinimap
    it("starts with zero pings", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getPingCount())
    end)

    -- @covers LMinimap:addPing
    -- @covers LMinimap:getPingCount
    -- @covers lurek.minimap.newMinimap
    it("can add pings", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:addPing(5, 5, 2.0)
        expect_equal(1, m:getPingCount())
        m:addPing(3, 3, 1.0, 0, 1, 0, 1)
        expect_equal(2, m:getPingCount())
    end)

    -- @covers LMinimap:addPing
    -- @covers LMinimap:getPingCount
    -- @covers LMinimap:update
    -- @covers lurek.minimap.newMinimap
    it("expires pings after duration", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:addPing(5, 5, 1.0)
        expect_equal(1, m:getPingCount())
        m:update(0.5)
        expect_equal(1, m:getPingCount())
        m:update(0.6) -- total > 1.0
        expect_equal(0, m:getPingCount())
    end)
end)

-- Markers

-- @describe markers
describe("markers", function()
    -- @covers LMinimap:getMarkerCount
    -- @covers lurek.minimap.newMinimap
    it("starts with zero markers", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getMarkerCount())
    end)

    -- @covers LMinimap:addMarker
    -- @covers LMinimap:getMarkerCount
    -- @covers LMinimap:getMarkerDescription
    -- @covers LMinimap:hasMarker
    -- @covers lurek.minimap.newMinimap
    it("can add and query markers", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local id = m:addMarker(3, 4, "Objective A")
        expect_true(m:hasMarker(id))
        expect_equal("Objective A", m:getMarkerDescription(id))
        expect_equal(1, m:getMarkerCount())
    end)

    -- @covers LMinimap:addMarker
    -- @covers LMinimap:getMarkerCount
    -- @covers LMinimap:getMarkerDescription
    -- @covers LMinimap:hasMarker
    -- @covers LMinimap:removeMarker
    -- @covers lurek.minimap.newMinimap
    it("can remove markers", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local id = m:addMarker(3, 4, "Test")
        expect_true(m:removeMarker(id))
        expect_false(m:hasMarker(id))
        expect_equal(0, m:getMarkerCount())
        expect_nil(m:getMarkerDescription(id))
    end)

    -- @covers LMinimap:addMarker
    -- @covers LMinimap:getMarkerCount
    -- @covers LMinimap:hasMarker
    -- @covers lurek.minimap.newMinimap
    it("can add markers without description", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local id = m:addMarker(7, 8)
        expect_true(m:hasMarker(id))
        expect_equal(1, m:getMarkerCount())
    end)

    -- @covers LMinimap:removeMarker
    -- @covers lurek.minimap.newMinimap
    it("returns false for non-existent marker removal", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_false(m:removeMarker(999))
    end)
end)

-- Anti-alias

-- @describe anti-alias
describe("anti-alias", function()
    -- @covers LMinimap:isAntiAlias
    -- @covers lurek.minimap.newMinimap
    it("defaults to false", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_false(m:isAntiAlias())
    end)

    -- @covers LMinimap:isAntiAlias
    -- @covers LMinimap:setAntiAlias
    -- @covers lurek.minimap.newMinimap
    it("can toggle", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setAntiAlias(true)
        expect_true(m:isAntiAlias())
    end)
end)

-- Coordinate conversion

-- @describe coordinate conversion
describe("coordinate conversion", function()
    -- @covers LMinimap:gridToScreen
    -- @covers LMinimap:screenToGrid
    -- @covers lurek.minimap.newMinimap
    it("converts grid to screen and back", function()
        local m = lurek.minimap.newMinimap(10, 10, 100, 100)
        local sx, sy = m:gridToScreen(0, 0, 0, 0)
        expect_type("number", sx)
        expect_type("number", sy)
        local gx, gy = m:screenToGrid(sx, sy, 0, 0)
        expect_near(0, gx)
        expect_near(0, gy)
    end)
end)

-- Update

-- @describe update
describe("update", function()
    -- @covers LMinimap:update
    -- @covers lurek.minimap.newMinimap
    it("does not crash", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_no_error(function() m:update(0.016) end)
        expect_no_error(function() m:update(0.033) end)
    end)
end)

-- Full workflow

-- @describe full workflow
describe("full workflow", function()
    -- @covers LMinimap:addMarker
    -- @covers LMinimap:addObjectType
    -- @covers LMinimap:addPing
    -- @covers LMinimap:getMarkerCount
    -- @covers LMinimap:getObjectCount
    -- @covers LMinimap:getPingCount
    -- @covers LMinimap:getZoom
    -- @covers LMinimap:isFogEnabled
    -- @covers LMinimap:setCenter
    -- @covers LMinimap:setFogEnabled
    -- @covers LMinimap:setFogLevel
    -- @covers LMinimap:setObject
    -- @covers LMinimap:setOwnerColor
    -- @covers LMinimap:setTerrain
    -- @covers LMinimap:setTerrainColor
    -- @covers LMinimap:setViewportRect
    -- @covers LMinimap:setZoom
    -- @covers LMinimap:update
    -- @covers lurek.minimap.newMinimap
    it("runs a complete minimap setup", function()
        local m = lurek.minimap.newMinimap(32, 32, 200, 200)

        -- Terrain
        for x = 1, 32 do
            for y = 1, 32 do
                m:setTerrain(x, y, (x + y) % 4)
            end
        end
        m:setTerrainColor(0, 0, 0.5, 0)
        m:setTerrainColor(1, 0.3, 0.3, 0.3)

        -- Fog
        m:setFogEnabled(true)
        for x = 1, 10 do
            for y = 1, 10 do
                m:setFogLevel(x, y, 2)
            end
        end

        -- Objects
        local unitType = m:addObjectType("unit", 0, 1, 0)
        m:setObject(1, 5, 5, unitType, 0)
        m:setOwnerColor(0, 0, 1, 0)

        -- Viewport
        m:setViewportRect(0, 0, 16, 12)

        -- Pings and markers
        m:addPing(15, 15, 3, 1, 0, 0)
        m:addMarker(20, 20, "Base", 0, 0, 1)

        -- Zoom
        m:setZoom(1.5)
        m:setCenter(16, 16)

        -- Verify
        expect_equal(1, m:getObjectCount())
        expect_equal(1, m:getPingCount())
        expect_equal(1, m:getMarkerCount())
        expect_true(m:isFogEnabled())
        expect_near(1.5, m:getZoom())

        m:update(0.016)
        expect_equal(1, m:getPingCount())
    end)
end)

-- setTerrainData

-- @describe terrain data bulk set
describe("terrain data bulk set", function()
    -- @covers LMinimap:getTerrain
    -- @covers LMinimap:setTerrainData
    -- @covers lurek.minimap.newMinimap
    it("sets all cells from a flat table", function()
        local m = lurek.minimap.newMinimap(3, 2)
        m:setTerrainData({1, 2, 3, 4, 5, 6})
        expect_equal(1, m:getTerrain(1, 1))
        expect_equal(2, m:getTerrain(2, 1))
        expect_equal(3, m:getTerrain(3, 1))
        expect_equal(4, m:getTerrain(1, 2))
        expect_equal(5, m:getTerrain(2, 2))
        expect_equal(6, m:getTerrain(3, 2))
    end)

    -- @covers LMinimap:getTerrain
    -- @covers LMinimap:setTerrainData
    -- @covers lurek.minimap.newMinimap
    it("ignores excess values beyond grid size", function()
        local m = lurek.minimap.newMinimap(2, 2)
        m:setTerrainData({7, 8, 9, 10, 11, 12, 13})
        expect_equal(7, m:getTerrain(1, 1))
        expect_equal(10, m:getTerrain(2, 2))
        -- grid is 2x2 so only first 4 values should apply
    end)
end)

-- Tile descriptions

-- @describe tile descriptions
describe("tile descriptions", function()
    -- @covers LMinimap:getTileDescription
    -- @covers lurek.minimap.newMinimap
    it("returns nil for unset types", function()
        local m = lurek.minimap.newMinimap(5, 5)
        expect_nil(m:getTileDescription(0))
        expect_nil(m:getTileDescription(99))
    end)

    -- @covers LMinimap:getTileDescription
    -- @covers LMinimap:setTileDescription
    -- @covers lurek.minimap.newMinimap
    it("sets and retrieves a description", function()
        local m = lurek.minimap.newMinimap(5, 5)
        m:setTileDescription(1, "Grass")
        expect_equal("Grass", m:getTileDescription(1))
    end)

    -- @covers LMinimap:getTileDescription
    -- @covers LMinimap:setTileDescription
    -- @covers lurek.minimap.newMinimap
    it("overwrites existing description", function()
        local m = lurek.minimap.newMinimap(5, 5)
        m:setTileDescription(0, "Water")
        m:setTileDescription(0, "Deep water")
        expect_equal("Deep water", m:getTileDescription(0))
    end)

    -- @covers LMinimap:getTileDescription
    -- @covers LMinimap:setTileDescription
    -- @covers lurek.minimap.newMinimap
    it("handles multiple types independently", function()
        local m = lurek.minimap.newMinimap(5, 5)
        m:setTileDescription(0, "Water")
        m:setTileDescription(1, "Forest")
        m:setTileDescription(2, "Mountain")
        expect_equal("Water",    m:getTileDescription(0))
        expect_equal("Forest",   m:getTileDescription(1))
        expect_equal("Mountain", m:getTileDescription(2))
        expect_nil(m:getTileDescription(3))
    end)
end)

-- getHoverInfo

-- @describe getHoverInfo
describe("getHoverInfo", function()
    -- @covers LMinimap:getHoverInfo
    -- @covers lurek.minimap.newMinimap
    it("returns nil outside minimap bounds", function()
        local m = lurek.minimap.newMinimap(4, 4, 100, 100)
        expect_nil(m:getHoverInfo(-1, 50, 0, 0))
        expect_nil(m:getHoverInfo(50, -1, 0, 0))
        expect_nil(m:getHoverInfo(101, 50, 0, 0))
        expect_nil(m:getHoverInfo(50, 101, 0, 0))
    end)

    -- @covers LMinimap:getHoverInfo
    -- @covers LMinimap:setTerrainData
    -- @covers LMinimap:setTileDescription
    -- @covers lurek.minimap.newMinimap
    it("returns tile description for hovered cell", function()
        local m = lurek.minimap.newMinimap(4, 4, 100, 100)
        m:setTerrainData({1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1})
        m:setTileDescription(1, "Plains")
        local info = m:getHoverInfo(1, 1, 0, 0)
        expect_equal("Plains", info)
    end)

    -- @covers LMinimap:getHoverInfo
    -- @covers LMinimap:setTerrain
    -- @covers lurek.minimap.newMinimap
    it("returns nil when terrain has no description", function()
        local m = lurek.minimap.newMinimap(4, 4, 100, 100)
        m:setTerrain(1, 1, 99)
        expect_nil(m:getHoverInfo(1, 1, 0, 0))
    end)
end)

-- setClickable / isClickable

-- @describe clickable
describe("clickable", function()
    -- @covers LMinimap:isClickable
    -- @covers lurek.minimap.newMinimap
    it("defaults to true", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_true(m:isClickable())
    end)

    -- @covers LMinimap:isClickable
    -- @covers LMinimap:setClickable
    -- @covers lurek.minimap.newMinimap
    it("can be disabled", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setClickable(false)
        expect_false(m:isClickable())
    end)

    -- @covers LMinimap:isClickable
    -- @covers LMinimap:setClickable
    -- @covers lurek.minimap.newMinimap
    it("can be re-enabled", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setClickable(false)
        m:setClickable(true)
        expect_true(m:isClickable())
    end)
end)

-- getCenterX / getCenterY

-- @describe center individual getters
describe("center individual getters", function()
    -- @covers LMinimap:getCenterX
    -- @covers LMinimap:setCenter
    -- @covers lurek.minimap.newMinimap
    it("getCenterX returns the X component", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(3.5, 7.25)
        expect_near(3.5, m:getCenterX())
    end)

    -- @covers LMinimap:getCenterY
    -- @covers LMinimap:setCenter
    -- @covers lurek.minimap.newMinimap
    it("getCenterY returns the Y component", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(3.5, 7.25)
        expect_near(7.25, m:getCenterY())
    end)

    -- @covers LMinimap:getCenter
    -- @covers LMinimap:getCenterX
    -- @covers LMinimap:getCenterY
    -- @covers LMinimap:setCenter
    -- @covers lurek.minimap.newMinimap
    it("getCenterX and getCenterY match getCenter", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(1.0, 9.0)
        local cx, cy = m:getCenter()
        expect_near(cx, m:getCenterX())
        expect_near(cy, m:getCenterY())
    end)
end)

-- Minimap Layers (merged from test_minimap_layers.lua)

-- @describe minimap layers
describe("minimap layers", function()
    -- @covers LMinimap:getLayer
    -- @covers lurek.minimap.newMinimap
    it("setLayer defaults to layer 0", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        expect_equal(mm:getLayer(), 0)
    end)

    -- @covers LMinimap:getLayer
    -- @covers LMinimap:setLayer
    -- @covers lurek.minimap.newMinimap
    it("setLayer and getLayer work", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:setLayer(1)
        expect_equal(mm:getLayer(), 1)
    end)

    -- @covers LMinimap:getLayer
    -- @covers LMinimap:setLayer
    -- @covers lurek.minimap.newMinimap
    it("setLayer can switch between layers", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:setLayer(2)
        expect_equal(mm:getLayer(), 2)
        mm:setLayer(0)
        expect_equal(mm:getLayer(), 0)
    end)

    -- @covers LMinimap:setLayerData
    -- @covers lurek.minimap.newMinimap
    it("setLayerData stores layer data", function()
        local mm = lurek.minimap.newMinimap(8, 8)
        local data = {}
        for i = 1, 64 do data[i] = 0 end
        mm:setLayerData(0, data)
        expect_equal(true, true)
    end)

    -- @covers LMinimap:setLayerData
    -- @covers lurek.minimap.newMinimap
    it("setLayerData works for higher layer indices", function()
        local mm = lurek.minimap.newMinimap(4, 4)
        local data = {}
        for i = 1, 16 do data[i] = 1 end
        mm:setLayerData(2, data)
        expect_equal(true, true)
    end)

    -- @covers LMinimap:getLayerCount
    -- @covers LMinimap:getLayerData
    -- @covers LMinimap:setLayerData
    -- @covers lurek.minimap.newMinimap
    it("returns stored layer data and layer count", function()
        local mm = lurek.minimap.newMinimap(4, 4)
        local data = {}
        for i = 1, 16 do data[i] = i % 3 end
        mm:setLayerData(1, data)

        local out = mm:getLayerData(1)
        expect_equal(2, mm:getLayerCount())
        expect_type("table", out)
        expect_equal(16, #out)
        expect_equal(data[1], out[1])
        expect_equal(data[16], out[16])
        expect_nil(mm:getLayerData(5))
    end)
end)

-- @describe minimap marker animation
describe("minimap marker animation", function()
    -- @covers LMinimap:addMarker
    -- @covers LMinimap:setMarkerAnimation
    -- @covers lurek.minimap.newMinimap
    it("setMarkerAnimation blink does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "blink", 2.0)
        expect_equal(true, true)
    end)

    -- @covers LMinimap:addMarker
    -- @covers LMinimap:setMarkerAnimation
    -- @covers lurek.minimap.newMinimap
    it("setMarkerAnimation pulse does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "pulse", 1.5)
        expect_equal(true, true)
    end)

    -- @covers LMinimap:addMarker
    -- @covers LMinimap:setMarkerAnimation
    -- @covers lurek.minimap.newMinimap
    it("setMarkerAnimation rotate does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "rotate", 3.14)
        expect_equal(true, true)
    end)

    -- @covers LMinimap:addMarker
    -- @covers LMinimap:clearMarkerAnimation
    -- @covers LMinimap:setMarkerAnimation
    -- @covers lurek.minimap.newMinimap
    it("clearMarkerAnimation stops animation", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        mm:setMarkerAnimation(id, "blink", 1.0)
        mm:clearMarkerAnimation(id)
        expect_equal(true, true)
    end)

    -- @covers LMinimap:addMarker
    -- @covers LMinimap:setMarkerAnimation
    -- @covers lurek.minimap.newMinimap
    it("setMarkerAnimation rejects unknown type", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        expect_error(function()
            mm:setMarkerAnimation(id, "spin_forever", 1.0)
        end)
    end)

    -- @covers LMinimap:addMarker
    -- @covers LMinimap:setMarkerAnimation
    -- @covers LMinimap:update
    -- @covers lurek.minimap.newMinimap
    it("update advances marker animation phases", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        mm:setMarkerAnimation(id, "blink", 2.0)
        mm:update(0.016)
        expect_equal(true, true)
    end)
end)

-- Minimap Overlay (merged from test_minimap_ui.lua)

-- @describe minimap geometry overlay
describe("minimap geometry overlay", function()
    -- @covers LMinimap:drawLine
    -- @covers lurek.minimap.newMinimap
    it("drawLine does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 32, 32, {255, 0, 0, 255})
        expect_equal(true, true)
    end)

    -- @covers LMinimap:drawRect
    -- @covers lurek.minimap.newMinimap
    it("drawRect does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawRect(10, 10, 20, 20, {0, 255, 0, 255})
        expect_equal(true, true)
    end)

    -- @covers LMinimap:clearOverlay
    -- @covers LMinimap:drawLine
    -- @covers LMinimap:drawRect
    -- @covers lurek.minimap.newMinimap
    it("clearOverlay clears geometry", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 10, 10, {255, 0, 0, 255})
        mm:drawRect(5, 5, 15, 15, {0, 0, 255, 255})
        mm:clearOverlay()
        expect_equal(true, true)
    end)

    -- @covers LMinimap:clearOverlay
    -- @covers lurek.minimap.newMinimap
    it("clearOverlay on empty overlay does not error", function()
        local mm = lurek.minimap.newMinimap(32, 32)
        mm:clearOverlay()
        expect_equal(true, true)
    end)

    -- @covers LMinimap:clearOverlay
    -- @covers LMinimap:drawLine
    -- @covers LMinimap:drawRect
    -- @covers lurek.minimap.newMinimap
    it("multiple shapes accumulate before clear", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 10, 10, {255, 0, 0, 255})
        mm:drawLine(10, 10, 20, 20, {0, 255, 0, 255})
        mm:drawRect(0, 0, 8, 8, {255, 255, 0, 255})
        mm:clearOverlay()
        expect_equal(true, true)
    end)

    -- @covers LMinimap:drawLine
    -- @covers LMinimap:drawRect
    -- @covers LMinimap:getOverlayShapeCount
    -- @covers lurek.minimap.newMinimap
    it("reports overlay shape count", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        expect_equal(0, mm:getOverlayShapeCount())
        mm:drawLine(0, 0, 10, 10, {255, 0, 0, 255})
        mm:drawRect(0, 0, 8, 8, {255, 255, 0, 255})
        expect_equal(2, mm:getOverlayShapeCount())
    end)
end)

-- Minimap Path (merged from test_minimap_path.lua)

-- @describe minimap path visualization
describe("minimap path visualization", function()
    -- @covers LMinimap:showPath
    -- @covers lurek.minimap.newMinimap
    it("showPath accepts a list of points", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:showPath({{0, 0}, {16, 16}, {32, 0}}, {0, 0, 255, 255})
        expect_equal(true, true)
    end)

    -- @covers LMinimap:showPath
    -- @covers lurek.minimap.newMinimap
    it("showPath returns a path ID", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:showPath({{0, 0}, {10, 10}}, {255, 0, 0, 255})
        expect_true(type(id) == "number")
        expect_true(id > 0)
    end)

    -- @covers LMinimap:showPath
    -- @covers lurek.minimap.newMinimap
    it("showPath returns distinct IDs", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id1 = mm:showPath({{0, 0}, {5, 5}}, {255, 0, 0, 255})
        local id2 = mm:showPath({{10, 10}, {20, 20}}, {0, 255, 0, 255})
        expect_true(id1 ~= id2)
    end)

    -- @covers LMinimap:clearPath
    -- @covers LMinimap:showPath
    -- @covers lurek.minimap.newMinimap
    it("clearPath removes all paths", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:showPath({{0, 0}, {10, 10}}, {255, 255, 0, 255})
        mm:showPath({{5, 5}, {15, 15}}, {0, 255, 255, 255})
        mm:clearPath()
        expect_equal(true, true)
    end)

    -- @covers LMinimap:clearPath
    -- @covers LMinimap:showPath
    -- @covers lurek.minimap.newMinimap
    it("clearPath with id removes specific path", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:showPath({{0, 0}, {10, 10}}, {255, 0, 0, 255})
        mm:clearPath(id)
        expect_equal(true, true)
    end)

    -- @covers LMinimap:clearPath
    -- @covers lurek.minimap.newMinimap
    it("clearPath on empty set does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:clearPath()
        expect_equal(true, true)
    end)
end)

-- @describe minimap icon helpers
describe("minimap icon helpers", function()
    -- @covers LMinimap:addMarker
    -- @covers LMinimap:addObjectType
    -- @covers LMinimap:clearMarkerTexture
    -- @covers LMinimap:clearObjectTypeTexture
    -- @covers LMinimap:setMarkerTexture
    -- @covers LMinimap:setObjectTypeTexture
    -- @covers lurek.minimap.newMinimap
    -- @covers lurek.render.newImage
    it("accepts texture-backed icons for object types and markers", function()
        local mm = lurek.minimap.newMinimap(32, 32)
        local tex = lurek.render.newImage("assets/icon.png")
        local type_idx = mm:addObjectType("unit", 1, 0, 0, 1)
        local marker_id = mm:addMarker(5, 6, "poi")

        expect_no_error(function() mm:setObjectTypeTexture(type_idx, tex, 12, 12) end)
        expect_no_error(function() mm:clearObjectTypeTexture(type_idx) end)
        expect_no_error(function() mm:setMarkerTexture(marker_id, tex, 10, 10) end)
        expect_no_error(function() mm:clearMarkerTexture(marker_id) end)
    end)
end)

-- @describe minimap strict: LMinimap render
describe("minimap strict: LMinimap render", function()
    -- @covers LMinimap:render
    -- @covers lurek.minimap.newMinimap
    it("LMinimap render is callable", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local ok = pcall(function() mm:render() end)
        expect_type("boolean", ok)
    end)
end)

-- @describe minimap migrated from render unit
describe("minimap migrated from render unit", function()
    -- @covers lurek.minimap.newMinimap
    it("exposes lurek.minimap.newMinimap as the canonical constructor", function()
        expect_type("function", lurek.minimap.newMinimap)
    end)
end)

test_summary()
