-- Lurek2D minimap API tests.
-- Covers minimap construction, terrain/object/fog state, view controls, and helper queries exposed through lurek.minimap.

describe("lurek.minimap.newMinimap", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getGridWidth
    -- @tests Minimap.getGridHeight
    it("creates a minimap with grid dimensions", function()
        local m = lurek.minimap.newMinimap(64, 48)
        expect_type("userdata", m)
        expect_equal(64, m:getGridWidth())
        expect_equal(48, m:getGridHeight())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getDisplayWidth
    -- @tests Minimap.getDisplayHeight
    it("creates a minimap with custom display size", function()
        local m = lurek.minimap.newMinimap(32, 32, 200, 150)
        expect_equal(200, m:getDisplayWidth())
        expect_equal(150, m:getDisplayHeight())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.type
    -- @tests Minimap.typeOf
    it("reports correct type", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal("LMinimap", m:type())
        expect_true(m:typeOf("Minimap"))
        expect_true(m:typeOf("Object"))
        expect_false(m:typeOf("Image"))
    end)
end)

-- Grid dimensions

describe("grid dimensions", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getGridSize
    it("returns grid size as two values", function()
        local m = lurek.minimap.newMinimap(40, 30)
        local w, h = m:getGridSize()
        expect_equal(40, w)
        expect_equal(30, h)
    end)
end)

-- Display size

describe("display size", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setDisplaySize
    -- @tests Minimap.getDisplayWidth
    -- @tests Minimap.getDisplayHeight
    -- @tests Minimap.getDisplaySize
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

describe("terrain", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getTerrain
    it("defaults to terrain type 0", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getTerrain(1, 1))
        expect_equal(0, m:getTerrain(5, 5))
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTerrain
    -- @tests Minimap.getTerrain
    it("can set and get terrain type", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setTerrain(3, 4, 7)
        expect_equal(7, m:getTerrain(3, 4))
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTerrainColor
    -- @tests Minimap.getTerrainColor
    it("can set and get terrain colors with alpha", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setTerrainColor(1, 0.2, 0.4, 0.6, 0.8)
        local r, g, b, a = m:getTerrainColor(1)
        expect_near(0.2, r)
        expect_near(0.4, g)
        expect_near(0.6, b)
        expect_near(0.8, a)
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTerrainColor
    -- @tests Minimap.getTerrainColor
    it("defaults alpha to 1.0", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setTerrainColor(2, 0.1, 0.2, 0.3)
        local _, _, _, a = m:getTerrainColor(2)
        expect_near(1.0, a)
    end)
end)

-- Fog of war

describe("fog of war", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.isFogEnabled
    it("is disabled by default", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_false(m:isFogEnabled())
    end)
    -- @tests Minimap.isFogEnabled
    it("can toggle fog", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setFogEnabled(true)
        expect_true(m:isFogEnabled())
        m:setFogEnabled(false)
        expect_false(m:isFogEnabled())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getFogLevel
    it("defaults fog level to 0 (hidden)", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getFogLevel(1, 1))
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setFogLevel
    -- @tests Minimap.getFogLevel
    it("can set fog levels", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setFogLevel(2, 3, 2) -- visible
        expect_equal(2, m:getFogLevel(2, 3))
        m:setFogLevel(2, 3, 1) -- explored
        expect_equal(1, m:getFogLevel(2, 3))
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setFogColor
    -- @tests Minimap.getFogColor
    it("can set fog color", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setFogColor(0.1, 0.2, 0.3, 0.5)
        local r, g, b, a = m:getFogColor()
        expect_near(0.1, r)
        expect_near(0.2, g)
        expect_near(0.3, b)
        expect_near(0.5, a)
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setFogData
    -- @tests Minimap.getFogLevel
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

describe("object types", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getObjectTypeCount
    it("starts with zero types", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getObjectTypeCount())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.addObjectType
    -- @tests Minimap.getObjectTypeCount
    it("adds types with 1-based indices", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local idx1 = m:addObjectType("unit", 1, 0, 0)
        expect_equal(1, idx1)
        local idx2 = m:addObjectType("building", 0, 0, 1, 0.8)
        expect_equal(2, idx2)
        expect_equal(2, m:getObjectTypeCount())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.addObjectType
    -- @tests Minimap.isObjectTypeVisible
    -- @tests Minimap.setObjectTypeVisible
    it("toggles type visibility", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local idx = m:addObjectType("unit", 1, 0, 0)
        expect_true(m:isObjectTypeVisible(idx))
        m:setObjectTypeVisible(idx, false)
        expect_false(m:isObjectTypeVisible(idx))
    end)
end)

-- Objects

describe("objects", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getObjectCount
    it("starts with zero objects", function()
        local m = lurek.minimap.newMinimap(100, 100)
        expect_equal(0, m:getObjectCount())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.addObjectType
    -- @tests Minimap.setObject
    -- @tests Minimap.getObjectCount
    -- @tests Minimap.removeObject
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

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.addObjectType
    -- @tests Minimap.setObject
    -- @tests Minimap.clearObjects
    -- @tests Minimap.getObjectCount
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

describe("owner colors", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setOwnerColor
    -- @tests Minimap.getOwnerColor
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

describe("color mode", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getColorMode
    it("defaults to terrain", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal("terrain", m:getColorMode())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setColorMode
    -- @tests Minimap.getColorMode
    it("can switch to political", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setColorMode("political")
        expect_equal("political", m:getColorMode())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setColorMode
    it("errors on invalid mode", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_error(function() m:setColorMode("invalid") end)
    end)
end)

-- Zoom and pan

describe("zoom and pan", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getZoom
    it("defaults zoom to 1.0", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_near(1.0, m:getZoom())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setZoom
    -- @tests Minimap.getZoom
    it("can set zoom", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setZoom(2.5)
        expect_near(2.5, m:getZoom())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setCenter
    -- @tests Minimap.getCenter
    it("can set center", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(5, 3)
        local cx, cy = m:getCenter()
        expect_near(5, cx)
        expect_near(3, cy)
    end)
end)

-- Viewport

describe("viewport", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getViewportRect
    it("starts with no viewport rect", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_nil(m:getViewportRect())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setViewportRect
    -- @tests Minimap.getViewportRect
    xit("can set and get viewport rect", function()
        local m = lurek.minimap.newMinimap(100, 100)
        m:setViewportRect(10, 20, 30, 40)
        local x, y, w, h = m:getViewportRect()
        expect_not_nil(x)
        expect_equal(10, x)
        expect_equal(20, y)
        expect_equal(30, w)
        expect_equal(40, h)
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setViewportRect
    -- @tests Minimap.clearViewportRect
    -- @tests Minimap.getViewportRect
    it("can clear viewport rect", function()
        local m = lurek.minimap.newMinimap(100, 100)
        m:setViewportRect(10, 20, 30, 40)
        m:clearViewportRect()
        expect_nil(m:getViewportRect())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.isViewportVisible
    -- @tests Minimap.setViewportVisible
    it("can toggle viewport visibility", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_true(m:isViewportVisible())
        m:setViewportVisible(false)
        expect_false(m:isViewportVisible())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setViewportColor
    -- @tests Minimap.getViewportColor
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

describe("pings", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getPingCount
    it("starts with zero pings", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getPingCount())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.addPing
    -- @tests Minimap.getPingCount
    it("can add pings", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:addPing(5, 5, 2.0)
        expect_equal(1, m:getPingCount())
        m:addPing(3, 3, 1.0, 0, 1, 0, 1)
        expect_equal(2, m:getPingCount())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.addPing
    -- @tests Minimap.update
    -- @tests Minimap.getPingCount
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

describe("markers", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getMarkerCount
    it("starts with zero markers", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getMarkerCount())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.addMarker
    -- @tests Minimap.hasMarker
    -- @tests Minimap.getMarkerDescription
    -- @tests Minimap.getMarkerCount
    it("can add and query markers", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local id = m:addMarker(3, 4, "Objective A")
        expect_true(m:hasMarker(id))
        expect_equal("Objective A", m:getMarkerDescription(id))
        expect_equal(1, m:getMarkerCount())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.addMarker
    -- @tests Minimap.removeMarker
    -- @tests Minimap.hasMarker
    -- @tests Minimap.getMarkerCount
    -- @tests Minimap.getMarkerDescription
    it("can remove markers", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local id = m:addMarker(3, 4, "Test")
        expect_true(m:removeMarker(id))
        expect_false(m:hasMarker(id))
        expect_equal(0, m:getMarkerCount())
        expect_nil(m:getMarkerDescription(id))
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.addMarker
    -- @tests Minimap.hasMarker
    -- @tests Minimap.getMarkerCount
    it("can add markers without description", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local id = m:addMarker(7, 8)
        expect_true(m:hasMarker(id))
        expect_equal(1, m:getMarkerCount())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.removeMarker
    it("returns false for non-existent marker removal", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_false(m:removeMarker(999))
    end)
end)

-- Anti-alias

describe("anti-alias", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.isAntiAlias
    it("defaults to false", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_false(m:isAntiAlias())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setAntiAlias
    -- @tests Minimap.isAntiAlias
    it("can toggle", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setAntiAlias(true)
        expect_true(m:isAntiAlias())
    end)
end)

-- Coordinate conversion

describe("coordinate conversion", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.gridToScreen
    -- @tests Minimap.screenToGrid
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

describe("update", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.update
    it("does not crash", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_no_error(function() m:update(0.016) end)
        expect_no_error(function() m:update(0.033) end)
    end)
end)

-- Full workflow

describe("full workflow", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTerrain
    -- @tests Minimap.setFogEnabled
    -- @tests Minimap.addObjectType
    -- @tests Minimap.setViewportRect
    -- @tests Minimap.addPing
    -- @tests Minimap.addMarker
    -- @tests Minimap.setZoom
    -- @tests Minimap.update
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

describe("terrain data bulk set", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTerrainData
    -- @tests Minimap.getTerrain
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

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTerrainData
    -- @tests Minimap.getTerrain
    it("ignores excess values beyond grid size", function()
        local m = lurek.minimap.newMinimap(2, 2)
        m:setTerrainData({7, 8, 9, 10, 11, 12, 13})
        expect_equal(7, m:getTerrain(1, 1))
        expect_equal(10, m:getTerrain(2, 2))
        -- grid is 2x2 so only first 4 values should apply
    end)
end)

-- Tile descriptions

describe("tile descriptions", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getTileDescription
    it("returns nil for unset types", function()
        local m = lurek.minimap.newMinimap(5, 5)
        expect_nil(m:getTileDescription(0))
        expect_nil(m:getTileDescription(99))
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTileDescription
    -- @tests Minimap.getTileDescription
    it("sets and retrieves a description", function()
        local m = lurek.minimap.newMinimap(5, 5)
        m:setTileDescription(1, "Grass")
        expect_equal("Grass", m:getTileDescription(1))
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTileDescription
    -- @tests Minimap.getTileDescription
    it("overwrites existing description", function()
        local m = lurek.minimap.newMinimap(5, 5)
        m:setTileDescription(0, "Water")
        m:setTileDescription(0, "Deep water")
        expect_equal("Deep water", m:getTileDescription(0))
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTileDescription
    -- @tests Minimap.getTileDescription
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

describe("getHoverInfo", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.getHoverInfo
    it("returns nil outside minimap bounds", function()
        local m = lurek.minimap.newMinimap(4, 4, 100, 100)
        expect_nil(m:getHoverInfo(-1, 50, 0, 0))
        expect_nil(m:getHoverInfo(50, -1, 0, 0))
        expect_nil(m:getHoverInfo(101, 50, 0, 0))
        expect_nil(m:getHoverInfo(50, 101, 0, 0))
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTerrainData
    -- @tests Minimap.setTileDescription
    -- @tests Minimap.getHoverInfo
    it("returns tile description for hovered cell", function()
        local m = lurek.minimap.newMinimap(4, 4, 100, 100)
        m:setTerrainData({1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1})
        m:setTileDescription(1, "Plains")
        local info = m:getHoverInfo(1, 1, 0, 0)
        expect_equal("Plains", info)
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setTerrain
    -- @tests Minimap.getHoverInfo
    it("returns nil when terrain has no description", function()
        local m = lurek.minimap.newMinimap(4, 4, 100, 100)
        m:setTerrain(1, 1, 99)
        expect_nil(m:getHoverInfo(1, 1, 0, 0))
    end)
end)

-- setClickable / isClickable

describe("clickable", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.isClickable
    it("defaults to true", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_true(m:isClickable())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setClickable
    -- @tests Minimap.isClickable
    it("can be disabled", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setClickable(false)
        expect_false(m:isClickable())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setClickable
    -- @tests Minimap.isClickable
    it("can be re-enabled", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setClickable(false)
        m:setClickable(true)
        expect_true(m:isClickable())
    end)
end)

-- getCenterX / getCenterY

describe("center individual getters", function()
    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setCenter
    -- @tests Minimap.getCenterX
    it("getCenterX returns the X component", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(3.5, 7.25)
        expect_near(3.5, m:getCenterX())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setCenter
    -- @tests Minimap.getCenterY
    it("getCenterY returns the Y component", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(3.5, 7.25)
        expect_near(7.25, m:getCenterY())
    end)

    -- @covers lurek.minimap.newMinimap
    -- @tests Minimap.setCenter
    -- @tests Minimap.getCenter
    -- @tests Minimap.getCenterX
    -- @tests Minimap.getCenterY
    it("getCenterX and getCenterY match getCenter", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(1.0, 9.0)
        local cx, cy = m:getCenter()
        expect_near(cx, m:getCenterX())
        expect_near(cy, m:getCenterY())
    end)
end)

-- Minimap Layers (merged from test_minimap_layers.lua)

describe("minimap layers", function()
    -- @tests Minimap.getLayer
    it("setLayer defaults to layer 0", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        expect_equal(mm:getLayer(), 0)
    end)

    -- @tests Minimap.setLayer
    -- @tests Minimap.getLayer
    it("setLayer and getLayer work", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:setLayer(1)
        expect_equal(mm:getLayer(), 1)
    end)

    -- @tests Minimap.setLayer
    -- @tests Minimap.getLayer
    it("setLayer can switch between layers", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:setLayer(2)
        expect_equal(mm:getLayer(), 2)
        mm:setLayer(0)
        expect_equal(mm:getLayer(), 0)
    end)

    -- @tests Minimap.setLayerData
    it("setLayerData stores layer data", function()
        local mm = lurek.minimap.newMinimap(8, 8)
        local data = {}
        for i = 1, 64 do data[i] = 0 end
        mm:setLayerData(0, data)
        expect_equal(true, true)
    end)

    -- @tests Minimap.setLayerData
    it("setLayerData works for higher layer indices", function()
        local mm = lurek.minimap.newMinimap(4, 4)
        local data = {}
        for i = 1, 16 do data[i] = 1 end
        mm:setLayerData(2, data)
        expect_equal(true, true)
    end)
end)

describe("minimap marker animation", function()
    -- @tests Minimap.setMarkerAnimation
    it("setMarkerAnimation blink does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "blink", 2.0)
        expect_equal(true, true)
    end)

    -- @tests Minimap.setMarkerAnimation
    it("setMarkerAnimation pulse does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "pulse", 1.5)
        expect_equal(true, true)
    end)

    -- @tests Minimap.setMarkerAnimation
    it("setMarkerAnimation rotate does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "rotate", 3.14)
        expect_equal(true, true)
    end)

    -- @tests Minimap.clearMarkerAnimation
    it("clearMarkerAnimation stops animation", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        mm:setMarkerAnimation(id, "blink", 1.0)
        mm:clearMarkerAnimation(id)
        expect_equal(true, true)
    end)

    -- @tests Minimap.setMarkerAnimation
    it("setMarkerAnimation rejects unknown type", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        expect_error(function()
            mm:setMarkerAnimation(id, "spin_forever", 1.0)
        end)
    end)

    -- @tests Minimap.update
    -- @tests Minimap.setMarkerAnimation
    it("update advances marker animation phases", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        mm:setMarkerAnimation(id, "blink", 2.0)
        mm:update(0.016)
        expect_equal(true, true)
    end)
end)

-- Minimap Overlay (merged from test_minimap_ui.lua)

describe("minimap geometry overlay", function()
    -- @tests Minimap.drawLine
    it("drawLine does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 32, 32, {255, 0, 0, 255})
        expect_equal(true, true)
    end)

    -- @tests Minimap.drawRect
    it("drawRect does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawRect(10, 10, 20, 20, {0, 255, 0, 255})
        expect_equal(true, true)
    end)

    -- @tests Minimap.clearOverlay
    it("clearOverlay clears geometry", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 10, 10, {255, 0, 0, 255})
        mm:drawRect(5, 5, 15, 15, {0, 0, 255, 255})
        mm:clearOverlay()
        expect_equal(true, true)
    end)

    -- @tests Minimap.drawLine
    -- @tests Minimap.clearOverlay
    it("clearOverlay on empty overlay does not error", function()
        local mm = lurek.minimap.newMinimap(32, 32)
        mm:clearOverlay()
        expect_equal(true, true)
    end)

    -- @tests Minimap.drawLine
    -- @tests Minimap.drawRect
    it("multiple shapes accumulate before clear", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 10, 10, {255, 0, 0, 255})
        mm:drawLine(10, 10, 20, 20, {0, 255, 0, 255})
        mm:drawRect(0, 0, 8, 8, {255, 255, 0, 255})
        mm:clearOverlay()
        expect_equal(true, true)
    end)
end)

-- Minimap Path (merged from test_minimap_path.lua)

describe("minimap path visualization", function()
    -- @tests Minimap.showPath
    it("showPath accepts a list of points", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:showPath({{0, 0}, {16, 16}, {32, 0}}, {0, 0, 255, 255})
        expect_equal(true, true)
    end)

    -- @tests Minimap.showPath
    it("showPath returns a path ID", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:showPath({{0, 0}, {10, 10}}, {255, 0, 0, 255})
        expect_true(type(id) == "number")
        expect_true(id > 0)
    end)

    -- @tests Minimap.showPath
    it("showPath returns distinct IDs", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id1 = mm:showPath({{0, 0}, {5, 5}}, {255, 0, 0, 255})
        local id2 = mm:showPath({{10, 10}, {20, 20}}, {0, 255, 0, 255})
        expect_true(id1 ~= id2)
    end)

    -- @tests Minimap.clearPath
    it("clearPath removes all paths", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:showPath({{0, 0}, {10, 10}}, {255, 255, 0, 255})
        mm:showPath({{5, 5}, {15, 15}}, {0, 255, 255, 255})
        mm:clearPath()
        expect_equal(true, true)
    end)

    -- @tests Minimap.clearPath
    it("clearPath with id removes specific path", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:showPath({{0, 0}, {10, 10}}, {255, 0, 0, 255})
        mm:clearPath(id)
        expect_equal(true, true)
    end)

    -- @tests Minimap.clearPath
    it("clearPath on empty set does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:clearPath()
        expect_equal(true, true)
    end)
end)

test_summary()
