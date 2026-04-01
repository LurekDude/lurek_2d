-- tests/lua/test_minimap.lua
-- Integration tests for luna.minimap.*

local total, passed, failed = 0, 0, 0
local current_describe = ""

local function describe(name, fn)
    current_describe = name
    fn()
end

local function it(name, fn)
    total = total + 1
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        print("FAIL: " .. current_describe .. " > " .. name .. ": " .. tostring(err))
    end
end

local function expect_eq(a, b)
    assert(a == b, "expected " .. tostring(b) .. " got " .. tostring(a))
end

local function expect_type(v, t)
    assert(type(v) == t, "expected type " .. t .. " got " .. type(v))
end

local function expect_near(a, b, e)
    assert(math.abs(a - b) < (e or 0.001), "expected ~" .. tostring(b) .. " got " .. tostring(a))
end

local function expect_no_error(fn) fn() end

local function expect_error(fn)
    local ok = pcall(fn)
    assert(not ok, "expected error but succeeded")
end

-- ── Factory ──

describe("luna.minimap.newMinimap", function()
    it("creates a minimap with grid dimensions", function()
        local m = luna.minimap.newMinimap(64, 48)
        expect_type(m, "userdata")
        expect_eq(m:getGridWidth(), 64)
        expect_eq(m:getGridHeight(), 48)
    end)

    it("creates a minimap with custom display size", function()
        local m = luna.minimap.newMinimap(32, 32, 200, 150)
        expect_eq(m:getDisplayWidth(), 200)
        expect_eq(m:getDisplayHeight(), 150)
    end)

    it("reports correct type", function()
        local m = luna.minimap.newMinimap(10, 10)
        expect_eq(m:type(), "Minimap")
        assert(m:typeOf("Minimap"))
        assert(m:typeOf("Object"))
        assert(not m:typeOf("Image"))
    end)
end)

-- ── Grid dimensions ──

describe("grid dimensions", function()
    it("returns grid size as two values", function()
        local m = luna.minimap.newMinimap(40, 30)
        local w, h = m:getGridSize()
        expect_eq(w, 40)
        expect_eq(h, 30)
    end)
end)

-- ── Display size ──

describe("display size", function()
    it("can set and get display size", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setDisplaySize(300, 200)
        expect_eq(m:getDisplayWidth(), 300)
        expect_eq(m:getDisplayHeight(), 200)
        local w, h = m:getDisplaySize()
        expect_eq(w, 300)
        expect_eq(h, 200)
    end)
end)

-- ── Terrain ──

describe("terrain", function()
    it("defaults to terrain type 0", function()
        local m = luna.minimap.newMinimap(10, 10)
        expect_eq(m:getTerrain(1, 1), 0)
        expect_eq(m:getTerrain(5, 5), 0)
    end)

    it("can set and get terrain type", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setTerrain(3, 4, 7)
        expect_eq(m:getTerrain(3, 4), 7)
    end)

    it("can set and get terrain colors with alpha", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setTerrainColor(1, 0.2, 0.4, 0.6, 0.8)
        local r, g, b, a = m:getTerrainColor(1)
        expect_near(r, 0.2)
        expect_near(g, 0.4)
        expect_near(b, 0.6)
        expect_near(a, 0.8)
    end)

    it("defaults alpha to 1.0", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setTerrainColor(2, 0.1, 0.2, 0.3)
        local _, _, _, a = m:getTerrainColor(2)
        expect_near(a, 1.0)
    end)
end)

-- ── Fog of war ──

describe("fog of war", function()
    it("is disabled by default", function()
        local m = luna.minimap.newMinimap(10, 10)
        assert(not m:isFogEnabled())
    end)

    it("can toggle fog", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setFogEnabled(true)
        assert(m:isFogEnabled())
        m:setFogEnabled(false)
        assert(not m:isFogEnabled())
    end)

    it("defaults fog level to 0 (hidden)", function()
        local m = luna.minimap.newMinimap(10, 10)
        expect_eq(m:getFogLevel(1, 1), 0)
    end)

    it("can set fog levels", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setFogLevel(2, 3, 2) -- visible
        expect_eq(m:getFogLevel(2, 3), 2)
        m:setFogLevel(2, 3, 1) -- explored
        expect_eq(m:getFogLevel(2, 3), 1)
    end)

    it("can set fog color", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setFogColor(0.1, 0.2, 0.3, 0.5)
        local r, g, b, a = m:getFogColor()
        expect_near(r, 0.1)
        expect_near(g, 0.2)
        expect_near(b, 0.3)
        expect_near(a, 0.5)
    end)

    it("can bulk set fog data", function()
        local m = luna.minimap.newMinimap(3, 3)
        m:setFogData({
            2, 1, 0,
            0, 2, 1,
            1, 0, 2,
        })
        expect_eq(m:getFogLevel(1, 1), 2)
        expect_eq(m:getFogLevel(2, 1), 1)
        expect_eq(m:getFogLevel(3, 1), 0)
        expect_eq(m:getFogLevel(1, 2), 0)
        expect_eq(m:getFogLevel(2, 2), 2)
        expect_eq(m:getFogLevel(3, 3), 2)
    end)
end)

-- ── Object types ──

describe("object types", function()
    it("starts with zero types", function()
        local m = luna.minimap.newMinimap(10, 10)
        expect_eq(m:getObjectTypeCount(), 0)
    end)

    it("adds types with 1-based indices", function()
        local m = luna.minimap.newMinimap(10, 10)
        local idx1 = m:addObjectType("unit", 1, 0, 0)
        expect_eq(idx1, 1)
        local idx2 = m:addObjectType("building", 0, 0, 1, 0.8)
        expect_eq(idx2, 2)
        expect_eq(m:getObjectTypeCount(), 2)
    end)

    it("toggles type visibility", function()
        local m = luna.minimap.newMinimap(10, 10)
        local idx = m:addObjectType("unit", 1, 0, 0)
        assert(m:isObjectTypeVisible(idx))
        m:setObjectTypeVisible(idx, false)
        assert(not m:isObjectTypeVisible(idx))
    end)
end)

-- ── Objects ──

describe("objects", function()
    it("starts with zero objects", function()
        local m = luna.minimap.newMinimap(100, 100)
        expect_eq(m:getObjectCount(), 0)
    end)

    it("can add and remove objects", function()
        local m = luna.minimap.newMinimap(100, 100)
        local idx = m:addObjectType("unit", 1, 0, 0)
        m:setObject(1, 50, 60, idx)
        expect_eq(m:getObjectCount(), 1)
        m:setObject(2, 70, 80, idx, 1)
        expect_eq(m:getObjectCount(), 2)
        assert(m:removeObject(1))
        expect_eq(m:getObjectCount(), 1)
        assert(not m:removeObject(999))
    end)

    it("can clear all objects", function()
        local m = luna.minimap.newMinimap(100, 100)
        local idx = m:addObjectType("unit", 1, 0, 0)
        m:setObject(1, 10, 10, idx)
        m:setObject(2, 20, 20, idx)
        m:clearObjects()
        expect_eq(m:getObjectCount(), 0)
    end)
end)

-- ── Owner colors ──

describe("owner colors", function()
    it("can set and get owner colors", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setOwnerColor(1, 0, 0, 1, 0.9)
        local r, g, b, a = m:getOwnerColor(1)
        expect_near(r, 0.0)
        expect_near(g, 0.0)
        expect_near(b, 1.0)
        expect_near(a, 0.9)
    end)
end)

-- ── Color mode ──

describe("color mode", function()
    it("defaults to terrain", function()
        local m = luna.minimap.newMinimap(10, 10)
        expect_eq(m:getColorMode(), "terrain")
    end)

    it("can switch to political", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setColorMode("political")
        expect_eq(m:getColorMode(), "political")
    end)

    it("errors on invalid mode", function()
        local m = luna.minimap.newMinimap(10, 10)
        expect_error(function() m:setColorMode("invalid") end)
    end)
end)

-- ── Zoom and pan ──

describe("zoom and pan", function()
    it("defaults zoom to 1.0", function()
        local m = luna.minimap.newMinimap(10, 10)
        expect_near(m:getZoom(), 1.0)
    end)

    it("can set zoom", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setZoom(2.5)
        expect_near(m:getZoom(), 2.5)
    end)

    it("can set center", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setCenter(5, 3)
        local cx, cy = m:getCenter()
        expect_near(cx, 5)
        expect_near(cy, 3)
    end)
end)

-- ── Viewport ──

describe("viewport", function()
    it("starts with no viewport rect", function()
        local m = luna.minimap.newMinimap(10, 10)
        assert(m:getViewportRect() == nil)
    end)

    it("can set and get viewport rect", function()
        local m = luna.minimap.newMinimap(100, 100)
        m:setViewportRect(10, 20, 30, 40)
        local vp = m:getViewportRect()
        assert(vp ~= nil)
        expect_eq(vp.x, 10)
        expect_eq(vp.y, 20)
        expect_eq(vp.w, 30)
        expect_eq(vp.h, 40)
    end)

    it("can clear viewport rect", function()
        local m = luna.minimap.newMinimap(100, 100)
        m:setViewportRect(10, 20, 30, 40)
        m:clearViewportRect()
        assert(m:getViewportRect() == nil)
    end)

    it("can toggle viewport visibility", function()
        local m = luna.minimap.newMinimap(10, 10)
        assert(m:isViewportVisible())
        m:setViewportVisible(false)
        assert(not m:isViewportVisible())
    end)

    it("can set viewport color", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setViewportColor(0.5, 0.6, 0.7, 0.3)
        local r, g, b, a = m:getViewportColor()
        expect_near(r, 0.5)
        expect_near(g, 0.6)
        expect_near(b, 0.7)
        expect_near(a, 0.3)
    end)
end)

-- ── Pings ──

describe("pings", function()
    it("starts with zero pings", function()
        local m = luna.minimap.newMinimap(10, 10)
        expect_eq(m:getPingCount(), 0)
    end)

    it("can add pings", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:addPing(5, 5, 2.0)
        expect_eq(m:getPingCount(), 1)
        m:addPing(3, 3, 1.0, 0, 1, 0, 1)
        expect_eq(m:getPingCount(), 2)
    end)

    it("expires pings after duration", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:addPing(5, 5, 1.0)
        expect_eq(m:getPingCount(), 1)
        m:update(0.5)
        expect_eq(m:getPingCount(), 1)
        m:update(0.6) -- total > 1.0
        expect_eq(m:getPingCount(), 0)
    end)
end)

-- ── Markers ──

describe("markers", function()
    it("starts with zero markers", function()
        local m = luna.minimap.newMinimap(10, 10)
        expect_eq(m:getMarkerCount(), 0)
    end)

    it("can add and query markers", function()
        local m = luna.minimap.newMinimap(10, 10)
        local id = m:addMarker(3, 4, "Objective A")
        assert(m:hasMarker(id))
        expect_eq(m:getMarkerDescription(id), "Objective A")
        expect_eq(m:getMarkerCount(), 1)
    end)

    it("can remove markers", function()
        local m = luna.minimap.newMinimap(10, 10)
        local id = m:addMarker(3, 4, "Test")
        assert(m:removeMarker(id))
        assert(not m:hasMarker(id))
        expect_eq(m:getMarkerCount(), 0)
        assert(m:getMarkerDescription(id) == nil)
    end)

    it("can add markers without description", function()
        local m = luna.minimap.newMinimap(10, 10)
        local id = m:addMarker(7, 8)
        assert(m:hasMarker(id))
        expect_eq(m:getMarkerCount(), 1)
    end)

    it("returns false for non-existent marker removal", function()
        local m = luna.minimap.newMinimap(10, 10)
        assert(not m:removeMarker(999))
    end)
end)

-- ── Anti-alias ──

describe("anti-alias", function()
    it("defaults to false", function()
        local m = luna.minimap.newMinimap(10, 10)
        assert(not m:isAntiAlias())
    end)

    it("can toggle", function()
        local m = luna.minimap.newMinimap(10, 10)
        m:setAntiAlias(true)
        assert(m:isAntiAlias())
    end)
end)

-- ── Coordinate conversion ──

describe("coordinate conversion", function()
    it("converts grid to screen and back", function()
        local m = luna.minimap.newMinimap(10, 10, 100, 100)
        local sx, sy = m:gridToScreen(0, 0, 0, 0)
        expect_type(sx, "number")
        expect_type(sy, "number")
        local gx, gy = m:screenToGrid(sx, sy, 0, 0)
        expect_near(gx, 0)
        expect_near(gy, 0)
    end)
end)

-- ── Update ──

describe("update", function()
    it("does not crash", function()
        local m = luna.minimap.newMinimap(10, 10)
        expect_no_error(function() m:update(0.016) end)
        expect_no_error(function() m:update(0.033) end)
    end)
end)

-- ── Full workflow ──

describe("full workflow", function()
    it("runs a complete minimap setup", function()
        local m = luna.minimap.newMinimap(32, 32, 200, 200)

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
        expect_eq(m:getObjectCount(), 1)
        expect_eq(m:getPingCount(), 1)
        expect_eq(m:getMarkerCount(), 1)
        assert(m:isFogEnabled())
        expect_near(m:getZoom(), 1.5)

        m:update(0.016)
        expect_eq(m:getPingCount(), 1)
    end)
end)

_test_results = { total = total, passed = passed, failed = failed }
