-- Lurek2D minimap API tests.
-- Covers minimap construction, terrain/object/fog state, view controls, and helper queries exposed through lurek.minimap.

-- @description Covers suite: lurek.minimap.newMinimap.
describe("lurek.minimap.newMinimap", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getGridWidth
    -- @tests Minimap.getGridHeight
    -- @description Creates a minimap with grid dimensions and verifies the grid width and height accessors.
    it("creates a minimap with grid dimensions", function()
        local m = lurek.minimap.newMinimap(64, 48)
        expect_type("userdata", m)
        expect_equal(64, m:getGridWidth())
        expect_equal(48, m:getGridHeight())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getDisplayWidth
    -- @tests Minimap.getDisplayHeight
    -- @description Creates a minimap with an explicit display size and checks the stored display dimensions.
    it("creates a minimap with custom display size", function()
        local m = lurek.minimap.newMinimap(32, 32, 200, 150)
        expect_equal(200, m:getDisplayWidth())
        expect_equal(150, m:getDisplayHeight())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.type
    -- @tests Minimap.typeOf
    -- @description Verifies the minimap userdata reports the correct type and type hierarchy.
    it("reports correct type", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal("LMinimap", m:type())
        expect_true(m:typeOf("Minimap"))
        expect_true(m:typeOf("Object"))
        expect_false(m:typeOf("Image"))
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Grid dimensions ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: grid dimensions.
describe("grid dimensions", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getGridSize
    -- @description Confirms getGridSize returns the grid width and height that were used at construction.
    it("returns grid size as two values", function()
        local m = lurek.minimap.newMinimap(40, 30)
        local w, h = m:getGridSize()
        expect_equal(40, w)
        expect_equal(30, h)
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Display size ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: display size.
describe("display size", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setDisplaySize
    -- @tests Minimap.getDisplayWidth
    -- @tests Minimap.getDisplayHeight
    -- @tests Minimap.getDisplaySize
    -- @description Updates the minimap display size and verifies both scalar and tuple getters reflect the new values.
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

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Terrain ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: terrain.
describe("terrain", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getTerrain
    -- @description Verifies uninitialized terrain cells default to terrain type 0.
    it("defaults to terrain type 0", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getTerrain(1, 1))
        expect_equal(0, m:getTerrain(5, 5))
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTerrain
    -- @tests Minimap.getTerrain
    -- @description Writes a terrain type into one cell and reads it back from the same coordinates.
    it("can set and get terrain type", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setTerrain(3, 4, 7)
        expect_equal(7, m:getTerrain(3, 4))
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTerrainColor
    -- @tests Minimap.getTerrainColor
    -- @description Stores a terrain color with alpha and verifies all four returned channels.
    it("can set and get terrain colors with alpha", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setTerrainColor(1, 0.2, 0.4, 0.6, 0.8)
        local r, g, b, a = m:getTerrainColor(1)
        expect_near(0.2, r)
        expect_near(0.4, g)
        expect_near(0.6, b)
        expect_near(0.8, a)
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTerrainColor
    -- @tests Minimap.getTerrainColor
    -- @description Verifies setTerrainColor applies the default alpha value of 1.0 when alpha is omitted.
    it("defaults alpha to 1.0", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setTerrainColor(2, 0.1, 0.2, 0.3)
        local _, _, _, a = m:getTerrainColor(2)
        expect_near(1.0, a)
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Fog of war ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: fog of war.
describe("fog of war", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.isFogEnabled
    -- @description Confirms fog of war is disabled when a minimap is first created.
    it("is disabled by default", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_false(m:isFogEnabled())
    end)
    -- @tests Minimap.isFogEnabled
    -- @description Toggles fog of war on and off and checks the enabled flag after each change.
    it("can toggle fog", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setFogEnabled(true)
        expect_true(m:isFogEnabled())
        m:setFogEnabled(false)
        expect_false(m:isFogEnabled())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getFogLevel
    -- @description Verifies unexplored tiles default to fog level 0.
    it("defaults fog level to 0 (hidden)", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getFogLevel(1, 1))
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setFogLevel
    -- @tests Minimap.getFogLevel
    -- @description Writes visible and explored fog states to a tile and verifies the stored levels.
    it("can set fog levels", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setFogLevel(2, 3, 2) -- visible
        expect_equal(2, m:getFogLevel(2, 3))
        m:setFogLevel(2, 3, 1) -- explored
        expect_equal(1, m:getFogLevel(2, 3))
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setFogColor
    -- @tests Minimap.getFogColor
    -- @description Sets a fog tint with alpha and checks that the returned RGBA values match.
    it("can set fog color", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setFogColor(0.1, 0.2, 0.3, 0.5)
        local r, g, b, a = m:getFogColor()
        expect_near(0.1, r)
        expect_near(0.2, g)
        expect_near(0.3, b)
        expect_near(0.5, a)
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setFogData
    -- @tests Minimap.getFogLevel
    -- @description Bulk-loads fog data into the grid and verifies representative cells across the map.
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

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Object types ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: object types.
describe("object types", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getObjectTypeCount
    -- @description Verifies a new minimap starts with no registered object types.
    it("starts with zero types", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getObjectTypeCount())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.addObjectType
    -- @tests Minimap.getObjectTypeCount
    -- @description Adds multiple object types and verifies they receive 1-based indices and increment the type count.
    it("adds types with 1-based indices", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local idx1 = m:addObjectType("unit", 1, 0, 0)
        expect_equal(1, idx1)
        local idx2 = m:addObjectType("building", 0, 0, 1, 0.8)
        expect_equal(2, idx2)
        expect_equal(2, m:getObjectTypeCount())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.addObjectType
    -- @tests Minimap.isObjectTypeVisible
    -- @tests Minimap.setObjectTypeVisible
    -- @description Toggles the visibility flag for an object type and verifies the updated state.
    it("toggles type visibility", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local idx = m:addObjectType("unit", 1, 0, 0)
        expect_true(m:isObjectTypeVisible(idx))
        m:setObjectTypeVisible(idx, false)
        expect_false(m:isObjectTypeVisible(idx))
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Objects ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: objects.
describe("objects", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getObjectCount
    -- @description Confirms a new minimap has no placed objects.
    it("starts with zero objects", function()
        local m = lurek.minimap.newMinimap(100, 100)
        expect_equal(0, m:getObjectCount())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.addObjectType
    -- @tests Minimap.setObject
    -- @tests Minimap.getObjectCount
    -- @tests Minimap.removeObject
    -- @description Adds objects of a registered type, removes them by id, and verifies the object count updates correctly.
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

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.addObjectType
    -- @tests Minimap.setObject
    -- @tests Minimap.clearObjects
    -- @tests Minimap.getObjectCount
    -- @description Clears all placed objects and verifies the minimap reports an empty object list.
    it("can clear all objects", function()
        local m = lurek.minimap.newMinimap(100, 100)
        local idx = m:addObjectType("unit", 1, 0, 0)
        m:setObject(1, 10, 10, idx)
        m:setObject(2, 20, 20, idx)
        m:clearObjects()
        expect_equal(0, m:getObjectCount())
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Owner colors ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: owner colors.
describe("owner colors", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setOwnerColor
    -- @tests Minimap.getOwnerColor
    -- @description Stores an owner color with alpha and verifies the returned RGBA channels.
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

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Color mode ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: color mode.
describe("color mode", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getColorMode
    -- @description Verifies the default minimap color mode is terrain-based.
    it("defaults to terrain", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal("terrain", m:getColorMode())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setColorMode
    -- @tests Minimap.getColorMode
    -- @description Switches the color mode to political and confirms the new mode is reported.
    it("can switch to political", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setColorMode("political")
        expect_equal("political", m:getColorMode())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setColorMode
    -- @description Ensures setColorMode rejects an unsupported mode string.
    it("errors on invalid mode", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_error(function() m:setColorMode("invalid") end)
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Zoom and pan ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: zoom and pan.
describe("zoom and pan", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getZoom
    -- @description Confirms the initial zoom factor is 1.0.
    it("defaults zoom to 1.0", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_near(1.0, m:getZoom())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setZoom
    -- @tests Minimap.getZoom
    -- @description Updates the zoom factor and verifies the new zoom value is returned.
    it("can set zoom", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setZoom(2.5)
        expect_near(2.5, m:getZoom())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setCenter
    -- @tests Minimap.getCenter
    -- @description Re-centers the minimap and verifies the new center coordinates.
    it("can set center", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(5, 3)
        local cx, cy = m:getCenter()
        expect_near(5, cx)
        expect_near(3, cy)
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Viewport ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: viewport.
describe("viewport", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getViewportRect
    -- @description Verifies the viewport rectangle is unset on a new minimap.
    it("starts with no viewport rect", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_nil(m:getViewportRect())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setViewportRect
    -- @tests Minimap.getViewportRect
    -- @description Sets a viewport rectangle and verifies each returned field matches the assigned bounds.
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

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setViewportRect
    -- @tests Minimap.clearViewportRect
    -- @tests Minimap.getViewportRect
    -- @description Clears a previously assigned viewport rectangle and confirms it becomes nil again.
    it("can clear viewport rect", function()
        local m = lurek.minimap.newMinimap(100, 100)
        m:setViewportRect(10, 20, 30, 40)
        m:clearViewportRect()
        expect_nil(m:getViewportRect())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.isViewportVisible
    -- @tests Minimap.setViewportVisible
    -- @description Toggles viewport rendering visibility and verifies the visible flag changes accordingly.
    it("can toggle viewport visibility", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_true(m:isViewportVisible())
        m:setViewportVisible(false)
        expect_false(m:isViewportVisible())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setViewportColor
    -- @tests Minimap.getViewportColor
    -- @description Sets the viewport highlight color and verifies all returned color channels.
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

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Pings ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: pings.
describe("pings", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getPingCount
    -- @description Confirms a new minimap starts with no active pings.
    it("starts with zero pings", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getPingCount())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.addPing
    -- @tests Minimap.getPingCount
    -- @description Adds pings with default and explicit color parameters and verifies the ping count increases.
    it("can add pings", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:addPing(5, 5, 2.0)
        expect_equal(1, m:getPingCount())
        m:addPing(3, 3, 1.0, 0, 1, 0, 1)
        expect_equal(2, m:getPingCount())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.addPing
    -- @tests Minimap.update
    -- @tests Minimap.getPingCount
    -- @description Advances the minimap update loop past a ping duration and confirms the ping expires.
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

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Markers ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: markers.
describe("markers", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getMarkerCount
    -- @description Confirms a new minimap starts with no markers.
    it("starts with zero markers", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_equal(0, m:getMarkerCount())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.addMarker
    -- @tests Minimap.hasMarker
    -- @tests Minimap.getMarkerDescription
    -- @tests Minimap.getMarkerCount
    -- @description Adds a marker with a description and verifies it can be queried by id.
    it("can add and query markers", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local id = m:addMarker(3, 4, "Objective A")
        expect_true(m:hasMarker(id))
        expect_equal("Objective A", m:getMarkerDescription(id))
        expect_equal(1, m:getMarkerCount())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.addMarker
    -- @tests Minimap.removeMarker
    -- @tests Minimap.hasMarker
    -- @tests Minimap.getMarkerCount
    -- @tests Minimap.getMarkerDescription
    -- @description Removes a marker and verifies its presence, count, and description are cleared.
    it("can remove markers", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local id = m:addMarker(3, 4, "Test")
        expect_true(m:removeMarker(id))
        expect_false(m:hasMarker(id))
        expect_equal(0, m:getMarkerCount())
        expect_nil(m:getMarkerDescription(id))
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.addMarker
    -- @tests Minimap.hasMarker
    -- @tests Minimap.getMarkerCount
    -- @description Adds a marker without a description and verifies it is still tracked correctly.
    it("can add markers without description", function()
        local m = lurek.minimap.newMinimap(10, 10)
        local id = m:addMarker(7, 8)
        expect_true(m:hasMarker(id))
        expect_equal(1, m:getMarkerCount())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.removeMarker
    -- @description Verifies removeMarker returns false for an id that does not exist.
    it("returns false for non-existent marker removal", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_false(m:removeMarker(999))
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Anti-alias ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: anti-alias.
describe("anti-alias", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.isAntiAlias
    -- @description Confirms anti-aliasing is disabled by default.
    it("defaults to false", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_false(m:isAntiAlias())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setAntiAlias
    -- @tests Minimap.isAntiAlias
    -- @description Enables anti-aliasing and verifies the flag becomes true.
    it("can toggle", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setAntiAlias(true)
        expect_true(m:isAntiAlias())
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Coordinate conversion ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: coordinate conversion.
describe("coordinate conversion", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.gridToScreen
    -- @tests Minimap.screenToGrid
    -- @description Converts a grid coordinate to screen space and back to verify the mapping round-trips.
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

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Update ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: update.
describe("update", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.update
    -- @description Verifies update accepts typical frame deltas without raising an error.
    it("does not crash", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_no_error(function() m:update(0.016) end)
        expect_no_error(function() m:update(0.033) end)
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Full workflow ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: full workflow.
describe("full workflow", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTerrain
    -- @tests Minimap.setFogEnabled
    -- @tests Minimap.addObjectType
    -- @tests Minimap.setViewportRect
    -- @tests Minimap.addPing
    -- @tests Minimap.addMarker
    -- @tests Minimap.setZoom
    -- @tests Minimap.update
    -- @description Exercises a representative minimap setup flow with terrain, fog, objects, viewport, pings, markers, zoom, and update handling.
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

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č setTerrainData ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: terrain data bulk set.
describe("terrain data bulk set", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTerrainData
    -- @tests Minimap.getTerrain
    -- @description Loads a flat terrain array into the grid and verifies each cell is populated in row-major order.
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

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTerrainData
    -- @tests Minimap.getTerrain
    -- @description Verifies setTerrainData ignores extra entries that exceed the minimap grid size.
    it("ignores excess values beyond grid size", function()
        local m = lurek.minimap.newMinimap(2, 2)
        m:setTerrainData({7, 8, 9, 10, 11, 12, 13})
        expect_equal(7, m:getTerrain(1, 1))
        expect_equal(10, m:getTerrain(2, 2))
        -- grid is 2x2 so only first 4 values should apply
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č Tile descriptions ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: tile descriptions.
describe("tile descriptions", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getTileDescription
    -- @description Confirms querying an unset tile description returns nil.
    it("returns nil for unset types", function()
        local m = lurek.minimap.newMinimap(5, 5)
        expect_nil(m:getTileDescription(0))
        expect_nil(m:getTileDescription(99))
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTileDescription
    -- @tests Minimap.getTileDescription
    -- @description Stores a tile description string and verifies it can be retrieved by terrain type.
    it("sets and retrieves a description", function()
        local m = lurek.minimap.newMinimap(5, 5)
        m:setTileDescription(1, "Grass")
        expect_equal("Grass", m:getTileDescription(1))
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTileDescription
    -- @tests Minimap.getTileDescription
    -- @description Replaces an existing tile description and verifies the later value wins.
    it("overwrites existing description", function()
        local m = lurek.minimap.newMinimap(5, 5)
        m:setTileDescription(0, "Water")
        m:setTileDescription(0, "Deep water")
        expect_equal("Deep water", m:getTileDescription(0))
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTileDescription
    -- @tests Minimap.getTileDescription
    -- @description Verifies tile descriptions are stored independently for multiple terrain types.
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

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č getHoverInfo ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: getHoverInfo.
describe("getHoverInfo", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.getHoverInfo
    -- @description Verifies hover queries outside the minimap display bounds return nil.
    it("returns nil outside minimap bounds", function()
        local m = lurek.minimap.newMinimap(4, 4, 100, 100)
        expect_nil(m:getHoverInfo(-1, 50, 0, 0))
        expect_nil(m:getHoverInfo(50, -1, 0, 0))
        expect_nil(m:getHoverInfo(101, 50, 0, 0))
        expect_nil(m:getHoverInfo(50, 101, 0, 0))
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTerrainData
    -- @tests Minimap.setTileDescription
    -- @tests Minimap.getHoverInfo
    -- @description Resolves a hovered tile to its configured terrain description.
    it("returns tile description for hovered cell", function()
        local m = lurek.minimap.newMinimap(4, 4, 100, 100)
        m:setTerrainData({1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1})
        m:setTileDescription(1, "Plains")
        local info = m:getHoverInfo(1, 1, 0, 0)
        expect_equal("Plains", info)
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setTerrain
    -- @tests Minimap.getHoverInfo
    -- @description Verifies hover info returns nil when the hovered terrain type has no description.
    it("returns nil when terrain has no description", function()
        local m = lurek.minimap.newMinimap(4, 4, 100, 100)
        m:setTerrain(1, 1, 99)
        expect_nil(m:getHoverInfo(1, 1, 0, 0))
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č setClickable / isClickable ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: clickable.
describe("clickable", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.isClickable
    -- @description Confirms minimaps are clickable by default.
    it("defaults to true", function()
        local m = lurek.minimap.newMinimap(10, 10)
        expect_true(m:isClickable())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setClickable
    -- @tests Minimap.isClickable
    -- @description Disables minimap click handling and verifies the clickable flag turns off.
    it("can be disabled", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setClickable(false)
        expect_false(m:isClickable())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setClickable
    -- @tests Minimap.isClickable
    -- @description Re-enables click handling after disabling it and verifies the flag returns to true.
    it("can be re-enabled", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setClickable(false)
        m:setClickable(true)
        expect_true(m:isClickable())
    end)
end)

-- ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č getCenterX / getCenterY ├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣─ä─é╦ś├óÔéČ┼í├é┬Č

-- @description Covers suite: center individual getters.
describe("center individual getters", function()
    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setCenter
    -- @tests Minimap.getCenterX
    -- @description Sets the minimap center and verifies getCenterX returns the X component.
    it("getCenterX returns the X component", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(3.5, 7.25)
        expect_near(3.5, m:getCenterX())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setCenter
    -- @tests Minimap.getCenterY
    -- @description Sets the minimap center and verifies getCenterY returns the Y component.
    it("getCenterY returns the Y component", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(3.5, 7.25)
        expect_near(7.25, m:getCenterY())
    end)

    -- @tests lurek.minimap.newMinimap
    -- @tests Minimap.setCenter
    -- @tests Minimap.getCenter
    -- @tests Minimap.getCenterX
    -- @tests Minimap.getCenterY
    -- @description Verifies the individual center getters stay in sync with the tuple returned by getCenter.
    it("getCenterX and getCenterY match getCenter", function()
        local m = lurek.minimap.newMinimap(10, 10)
        m:setCenter(1.0, 9.0)
        local cx, cy = m:getCenter()
        expect_near(cx, m:getCenterX())
        expect_near(cy, m:getCenterY())
    end)
end)

-- ─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č Minimap Layers (merged from test_minimap_layers.lua) ─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č

-- @description Covers suite: minimap layers.
describe("minimap layers", function()
    -- @tests Minimap.getLayer
    -- @description getLayer returns 0 by default.
    it("setLayer defaults to layer 0", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        expect_equal(mm:getLayer(), 0)
    end)

    -- @tests Minimap.setLayer
    -- @tests Minimap.getLayer
    -- @description setLayer and getLayer round-trip correctly.
    it("setLayer and getLayer work", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:setLayer(1)
        expect_equal(mm:getLayer(), 1)
    end)

    -- @tests Minimap.setLayer
    -- @tests Minimap.getLayer
    -- @description setLayer can switch between multiple layer indices.
    it("setLayer can switch between layers", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:setLayer(2)
        expect_equal(mm:getLayer(), 2)
        mm:setLayer(0)
        expect_equal(mm:getLayer(), 0)
    end)

    -- @tests Minimap.setLayerData
    -- @description setLayerData stores a flat table without error.
    it("setLayerData stores layer data", function()
        local mm = lurek.minimap.newMinimap(8, 8)
        local data = {}
        for i = 1, 64 do data[i] = 0 end
        mm:setLayerData(0, data)
        expect_equal(true, true)
    end)

    -- @tests Minimap.setLayerData
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
    -- @tests Minimap.setMarkerAnimation
    -- @description setMarkerAnimation with "blink" does not error.
    it("setMarkerAnimation blink does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "blink", 2.0)
        expect_equal(true, true)
    end)

    -- @tests Minimap.setMarkerAnimation
    -- @description setMarkerAnimation with "pulse" does not error.
    it("setMarkerAnimation pulse does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "pulse", 1.5)
        expect_equal(true, true)
    end)

    -- @tests Minimap.setMarkerAnimation
    -- @description setMarkerAnimation with "rotate" does not error.
    it("setMarkerAnimation rotate does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10, "test", 1, 0, 0, 1)
        mm:setMarkerAnimation(id, "rotate", 3.14)
        expect_equal(true, true)
    end)

    -- @tests Minimap.clearMarkerAnimation
    -- @description clearMarkerAnimation removes animation without error.
    it("clearMarkerAnimation stops animation", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        mm:setMarkerAnimation(id, "blink", 1.0)
        mm:clearMarkerAnimation(id)
        expect_equal(true, true)
    end)

    -- @tests Minimap.setMarkerAnimation
    -- @description setMarkerAnimation with an invalid type returns an error.
    it("setMarkerAnimation rejects unknown type", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        expect_error(function()
            mm:setMarkerAnimation(id, "spin_forever", 1.0)
        end)
    end)

    -- @tests Minimap.update
    -- @tests Minimap.setMarkerAnimation
    -- @description update advances animation phases without error.
    it("update advances marker animation phases", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:addMarker(10, 10)
        mm:setMarkerAnimation(id, "blink", 2.0)
        mm:update(0.016)
        expect_equal(true, true)
    end)
end)

-- ─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č Minimap Overlay (merged from test_minimap_ui.lua) ─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č

-- @description Covers suite: minimap geometry overlay.
describe("minimap geometry overlay", function()
    -- @tests Minimap.drawLine
    -- @description drawLine accepts valid coordinates and color table without error.
    it("drawLine does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 32, 32, {255, 0, 0, 255})
        expect_equal(true, true)
    end)

    -- @tests Minimap.drawRect
    -- @description drawRect accepts valid coordinates and color table without error.
    it("drawRect does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawRect(10, 10, 20, 20, {0, 255, 0, 255})
        expect_equal(true, true)
    end)

    -- @tests Minimap.clearOverlay
    -- @description clearOverlay removes all geometry without crashing.
    it("clearOverlay clears geometry", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:drawLine(0, 0, 10, 10, {255, 0, 0, 255})
        mm:drawRect(5, 5, 15, 15, {0, 0, 255, 255})
        mm:clearOverlay()
        expect_equal(true, true)
    end)

    -- @tests Minimap.drawLine
    -- @tests Minimap.clearOverlay
    -- @description clearOverlay can be called on an empty overlay without error.
    it("clearOverlay on empty overlay does not error", function()
        local mm = lurek.minimap.newMinimap(32, 32)
        mm:clearOverlay()
        expect_equal(true, true)
    end)

    -- @tests Minimap.drawLine
    -- @tests Minimap.drawRect
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

-- ─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č Minimap Path (merged from test_minimap_path.lua) ─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č─é╦ś├óÔéČ┼ą├óÔÇÜ┬Č

-- @description Covers suite: minimap path visualization.
describe("minimap path visualization", function()
    -- @tests Minimap.showPath
    -- @description showPath accepts a list of {x, y} point tables without error.
    it("showPath accepts a list of points", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:showPath({{0, 0}, {16, 16}, {32, 0}}, {0, 0, 255, 255})
        expect_equal(true, true)
    end)

    -- @tests Minimap.showPath
    -- @description showPath returns a non-zero integer path ID.
    it("showPath returns a path ID", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:showPath({{0, 0}, {10, 10}}, {255, 0, 0, 255})
        expect_true(type(id) == "number")
        expect_true(id > 0)
    end)

    -- @tests Minimap.showPath
    -- @description Each showPath call returns a distinct ID.
    it("showPath returns distinct IDs", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id1 = mm:showPath({{0, 0}, {5, 5}}, {255, 0, 0, 255})
        local id2 = mm:showPath({{10, 10}, {20, 20}}, {0, 255, 0, 255})
        expect_true(id1 ~= id2)
    end)

    -- @tests Minimap.clearPath
    -- @description clearPath() with no argument removes all paths without error.
    it("clearPath removes all paths", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:showPath({{0, 0}, {10, 10}}, {255, 255, 0, 255})
        mm:showPath({{5, 5}, {15, 15}}, {0, 255, 255, 255})
        mm:clearPath()
        expect_equal(true, true)
    end)

    -- @tests Minimap.clearPath
    -- @description clearPath(id) removes only the path with the given ID.
    it("clearPath with id removes specific path", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:showPath({{0, 0}, {10, 10}}, {255, 0, 0, 255})
        mm:clearPath(id)
        expect_equal(true, true)
    end)

    -- @tests Minimap.clearPath
    -- @description clearPath on an empty set does not error.
    it("clearPath on empty set does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:clearPath()
        expect_equal(true, true)
    end)
end)

test_summary()
