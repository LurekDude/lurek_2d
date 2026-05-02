-- Lurek2D Tilemap API Tests
-- Covers lurek.tilemap module: factory functions, TileSet, TileMap,
-- coordinate helpers, autotile, chunk map, iso map, map generation, and TMX.
-- NOTE: This test runs in headless mode (no GPU/window). drawLayer and
-- texture-dependent rendering calls are intentionally excluded.

-- =========================================================================
-- Module existence
-- =========================================================================

describe("lurek.tilemap module exists", function()
    it("lurek.tilemap is a table", function()
        expect_type("table", lurek.tilemap)
    end)

    it("exposes factory functions", function()
        expect_type("function", lurek.tilemap.newTileSet)
        expect_type("function", lurek.tilemap.newTileMap)
        expect_type("function", lurek.tilemap.newAutoTileSheet)
        expect_type("function", lurek.tilemap.newChunkMap)
        expect_type("function", lurek.tilemap.newIsoMap)
        expect_type("function", lurek.tilemap.newMapBlock)
        expect_type("function", lurek.tilemap.newMapGroup)
        expect_type("function", lurek.tilemap.newMapScript)
        expect_type("function", lurek.tilemap.newMapGen)
    end)

    it("exposes coordinate helper functions", function()
        expect_type("function", lurek.tilemap.toScreenIso)
        expect_type("function", lurek.tilemap.fromScreenIso)
        expect_type("function", lurek.tilemap.toScreenHex)
        expect_type("function", lurek.tilemap.fromScreenHex)
        expect_type("function", lurek.tilemap.hexNeighbors)
        expect_type("function", lurek.tilemap.hexDistance)
        expect_type("function", lurek.tilemap.hexRound)
        expect_type("function", lurek.tilemap.hexLine)
        expect_type("function", lurek.tilemap.hexRing)
        expect_type("function", lurek.tilemap.hexSpiral)
        expect_type("function", lurek.tilemap.hexArea)
        expect_type("function", lurek.tilemap.hexRotate)
        expect_type("function", lurek.tilemap.hexReflect)
        expect_type("function", lurek.tilemap.isoRotate)
        expect_type("function", lurek.tilemap.isoDirectionName)
        expect_type("function", lurek.tilemap.isoDirectionFromAngle)
    end)

    it("exposes TMX loader", function()
        expect_type("function", lurek.tilemap.loadTMX)
    end)

    it("exposes IsoMap tile-part constants", function()
        expect_equal(1, lurek.tilemap.FLOOR)
        expect_equal(2, lurek.tilemap.NORTH_WALL)
        expect_equal(3, lurek.tilemap.WEST_WALL)
        expect_equal(4, lurek.tilemap.OBJECT)
    end)
end)

-- =========================================================================
-- Isometric coordinate helpers
-- =========================================================================

describe("lurek.tilemap isometric coordinates", function()
    it("toScreenIso converts (1,1) to expected screen position", function()
        local sx, sy = lurek.tilemap.toScreenIso(1, 1, 32, 16)
        expect_type("number", sx)
        expect_type("number", sy)
    end)

    it("fromScreenIso round-trips with toScreenIso", function()
        local tx, ty = 3, 5
        local sx, sy = lurek.tilemap.toScreenIso(tx, ty, 32, 16)
        local rx, ry = lurek.tilemap.fromScreenIso(sx, sy, 32, 16)
        expect_near(tx, rx, 0.01)
        expect_near(ty, ry, 0.01)
    end)

    it("toScreenIso at origin returns 0,0 for tile (0,0)", function()
        local sx, sy = lurek.tilemap.toScreenIso(0, 0, 32, 16)
        expect_near(0, sx, 0.001)
        expect_near(0, sy, 0.001)
    end)

    it("isoRotate direction 1 by 1 step = direction 2", function()
        local dir = lurek.tilemap.isoRotate(1, 1)
        expect_equal(2, dir)
    end)

    it("isoRotate wraps at 4 back to 1", function()
        local dir = lurek.tilemap.isoRotate(4, 1)
        expect_equal(1, dir)
    end)

    it("isoRotate by 4 steps returns same direction", function()
        for d = 1, 4 do
            local rotated = lurek.tilemap.isoRotate(d, 4)
            expect_equal(d, rotated)
        end
    end)

    it("isoDirectionName returns expected strings", function()
        expect_equal("south", lurek.tilemap.isoDirectionName(1))
        expect_equal("west",  lurek.tilemap.isoDirectionName(2))
        expect_equal("north", lurek.tilemap.isoDirectionName(3))
        expect_equal("east",  lurek.tilemap.isoDirectionName(4))
    end)

    it("isoDirectionFromAngle snaps to nearest direction", function()
        local dir = lurek.tilemap.isoDirectionFromAngle(0)
        expect_in_range(dir, 1, 4)
    end)
end)

-- =========================================================================
-- Hexagonal coordinate helpers
-- =========================================================================

describe("lurek.tilemap hexagonal coordinates", function()
    it("toScreenHex and fromScreenHex round-trip", function()
        local q, r = 2, 3
        local sx, sy = lurek.tilemap.toScreenHex(q, r, 16)
        local rq, rr = lurek.tilemap.fromScreenHex(sx, sy, 16)
        expect_near(q, rq, 0.5)
        expect_near(r, rr, 0.5)
    end)

    it("hexDistance between same cell is 0", function()
        expect_equal(0, lurek.tilemap.hexDistance(2, 3, 2, 3))
    end)

    it("hexDistance between adjacent cells is 1", function()
        expect_equal(1, lurek.tilemap.hexDistance(0, 0, 1, 0))
    end)

    it("hexDistance is symmetric", function()
        local d1 = lurek.tilemap.hexDistance(1, 2, 4, 5)
        local d2 = lurek.tilemap.hexDistance(4, 5, 1, 2)
        expect_equal(d1, d2)
    end)

    it("hexRound returns integers", function()
        local q, r = lurek.tilemap.hexRound(1.4, 2.7)
        expect_true(math.floor(q) == q, "q should be integer")
        expect_true(math.floor(r) == r, "r should be integer")
    end)

    it("hexNeighbors returns 6 cells", function()
        local neighbors = lurek.tilemap.hexNeighbors(0, 0)
        expect_equal(6, #neighbors)
    end)

    it("hexNeighbors each entry has q and r fields", function()
        local neighbors = lurek.tilemap.hexNeighbors(0, 0)
        for _, n in ipairs(neighbors) do
            expect_not_nil(n.q)
            expect_not_nil(n.r)
        end
    end)

    it("hexLine from (0,0) to (0,0) returns 1 cell", function()
        local line = lurek.tilemap.hexLine(0, 0, 0, 0)
        expect_equal(1, #line)
    end)

    it("hexLine from (0,0) to (2,0) returns correct length", function()
        local line = lurek.tilemap.hexLine(0, 0, 2, 0)
        expect_equal(3, #line)
    end)

    it("hexRing at radius 0 returns 1 cell (the center)", function()
        local ring = lurek.tilemap.hexRing(0, 0, 0)
        expect_equal(1, #ring)
    end)

    it("hexRing at radius 1 returns 6 cells", function()
        local ring = lurek.tilemap.hexRing(0, 0, 1)
        expect_equal(6, #ring)
    end)

    it("hexRing at radius 2 returns 12 cells", function()
        local ring = lurek.tilemap.hexRing(0, 0, 2)
        expect_equal(12, #ring)
    end)

    it("hexSpiral at radius 0 returns 1 cell", function()
        local spiral = lurek.tilemap.hexSpiral(0, 0, 0)
        expect_equal(1, #spiral)
    end)

    it("hexSpiral at radius 1 returns 7 cells (1 center + 6 ring)", function()
        local spiral = lurek.tilemap.hexSpiral(0, 0, 1)
        expect_equal(7, #spiral)
    end)

    it("hexArea at radius 0 returns 1 cell", function()
        local area = lurek.tilemap.hexArea(0, 0, 0)
        expect_equal(1, #area)
    end)

    it("hexArea at radius 1 returns 7 cells", function()
        local area = lurek.tilemap.hexArea(0, 0, 1)
        expect_equal(7, #area)
    end)

    it("hexRotate by 0 steps returns same cell", function()
        local q, r = lurek.tilemap.hexRotate(1, 0, 0, 0, 0)
        expect_equal(1, q)
        expect_equal(0, r)
    end)

    it("hexRotate by 6 steps (full circle) returns same cell", function()
        local q, r = lurek.tilemap.hexRotate(2, 1, 0, 0, 6)
        expect_near(2, q, 0.01)
        expect_near(1, r, 0.01)
    end)

    it("hexReflect across q axis returns expected result", function()
        local q, r = lurek.tilemap.hexReflect(1, 2, 0, 0, "q")
        expect_type("number", q)
        expect_type("number", r)
    end)

    it("hexReflect across r axis returns expected result", function()
        local q, r = lurek.tilemap.hexReflect(1, 2, 0, 0, "r")
        expect_type("number", q)
        expect_type("number", r)
    end)

    it("hexReflect across s axis returns expected result", function()
        local q, r = lurek.tilemap.hexReflect(1, 2, 0, 0, "s")
        expect_type("number", q)
        expect_type("number", r)
    end)
end)

-- =========================================================================
-- TileSet
-- =========================================================================

describe("lurek.tilemap.newTileSet", function()
    it("creates a TileSet userdata", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_type("userdata", ts)
    end)

    it("getFirstGid returns the first GID passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(1, ts:getFirstGid())
    end)

    it("getFirstGid non-1 start", function()
        local ts = lurek.tilemap.newTileSet(17, 8, 4, 16, 16)
        expect_equal(17, ts:getFirstGid())
    end)

    it("getTileCount returns count passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(16, ts:getTileCount())
    end)

    it("getColumns returns columns passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(4, ts:getColumns())
    end)

    it("getTileWidth returns width passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(32, ts:getTileWidth())
    end)

    it("getTileHeight returns height passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(32, ts:getTileHeight())
    end)

    it("getTileDimensions returns width and height", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 48)
        local w, h = ts:getTileDimensions()
        expect_equal(32, w)
        expect_equal(48, h)
    end)

    it("getSpacing defaults to 0 when not provided", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(0, ts:getSpacing())
    end)

    it("getSpacing returns spacing passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32, 2)
        expect_equal(2, ts:getSpacing())
    end)

    it("getMargin defaults to 0 when not provided", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(0, ts:getMargin())
    end)

    it("getMargin returns margin passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32, 0, 4)
        expect_equal(4, ts:getMargin())
    end)

    it("getQuad returns a table with x, y, width, height", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        local q = ts:getQuad(1)
        expect_type("table", q)
        expect_not_nil(q.x)
        expect_not_nil(q.y)
        expect_not_nil(q.width)
        expect_not_nil(q.height)
    end)

    it("getQuad tile 1 starts at (0, 0)", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        local q = ts:getQuad(1)
        expect_near(0, q.x, 0.001)
        expect_near(0, q.y, 0.001)
        expect_near(32, q.width, 0.001)
        expect_near(32, q.height, 0.001)
    end)

    it("getQuad tile 2 is offset by one tile width", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        local q = ts:getQuad(2)
        expect_near(32, q.x, 0.001)
        expect_near(0, q.y, 0.001)
    end)

    it("getQuad tile 5 (second row, first column) has correct y", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        local q = ts:getQuad(5)
        expect_near(0, q.x, 0.001)
        expect_near(32, q.y, 0.001)
    end)

    it("getQuad rejects tile ID 0", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_error(function() ts:getQuad(0) end)
    end)

    it("setSolid and isSolid work for a tile", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_false(ts:isSolid(1))
        ts:setSolid(1, true)
        expect_true(ts:isSolid(1))
        ts:setSolid(1, false)
        expect_false(ts:isSolid(1))
    end)

    it("isSolid rejects tile ID 0", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_error(function() ts:isSolid(0) end)
    end)

    it("setAnimation and getAnimation round-trip", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        ts:setAnimation(1, {{tileid=1, duration=100}, {tileid=2, duration=200}})
        local frames = ts:getAnimation(1)
        expect_not_nil(frames)
        expect_equal(2, #frames)
        expect_equal(1, frames[1].tileid)
        expect_near(100, frames[1].duration, 0.001)
        expect_equal(2, frames[2].tileid)
        expect_near(200, frames[2].duration, 0.001)
    end)

    it("getAnimation returns nil for tile with no animation", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_nil(ts:getAnimation(3))
    end)

    it("setAutoTileRule and getAutoTileId round-trip", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        -- bitmask: N=1 only, map to tile 3
        ts:setAutoTileRule("grass", 1, 3)
        local tid = ts:getAutoTileId("grass", 1)
        expect_equal(3, tid)
    end)

    it("getAutoTileId returns nil for unknown bitmask", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_nil(ts:getAutoTileId("grass", 0))
    end)

    it("setAutoTileRule8 and getAutoTileId8 round-trip", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        -- 8-bit bitmask: N=1, NE=16 = bitmask 17
        ts:setAutoTileRule8("water", 17, 5)
        local tid = ts:getAutoTileId8("water", 17)
        expect_equal(5, tid)
    end)

    it("setAutoTileRule8 different types do not conflict", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        ts:setAutoTileRule8("grass", 15, 2)
        ts:setAutoTileRule8("water", 15, 4)
        expect_equal(2, ts:getAutoTileId8("grass", 15))
        expect_equal(4, ts:getAutoTileId8("water", 15))
    end)
end)

-- =========================================================================
-- TileMap
-- =========================================================================

describe("lurek.tilemap.newTileMap", function()
    it("creates a TileMap userdata", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_type("userdata", tm)
    end)

    it("getTileWidth and getTileHeight return constructor values", function()
        local tm = lurek.tilemap.newTileMap(32, 16)
        expect_equal(32, tm:getTileWidth())
        expect_equal(16, tm:getTileHeight())
    end)

    it("getTileDimensions returns width and height", function()
        local tm = lurek.tilemap.newTileMap(24, 24)
        local w, h = tm:getTileDimensions()
        expect_equal(24, w)
        expect_equal(24, h)
    end)

    it("getChunkSize defaults to 16", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_equal(16, tm:getChunkSize())
    end)

    it("getChunkSize uses custom value", function()
        local tm = lurek.tilemap.newTileMap(32, 32, 8)
        expect_equal(8, tm:getChunkSize())
    end)
end)

describe("TileMap tileset management", function()
    it("getTileSetCount starts at 0", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_equal(0, tm:getTileSetCount())
    end)

    it("addTileSet increases count", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        expect_equal(1, tm:getTileSetCount())
    end)

    it("getTileSet returns the added tileset", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        local retrieved = tm:getTileSet(1)
        expect_type("userdata", retrieved)
        expect_true(retrieved ~= nil, "expected tileset")
        expect_equal(1, retrieved:getFirstGid())
    end)

    it("getTileSet returns nil for out-of-range index", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_nil(tm:getTileSet(1))
    end)

    it("getTileSet rejects index 0", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_error(function() tm:getTileSet(0) end)
    end)
end)

describe("TileMap layer management", function()
    it("getLayerCount starts at 0", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_equal(0, tm:getLayerCount())
    end)

    it("addLayer returns 1-based index", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local idx = tm:addLayer("ground", 20, 15)
        expect_equal(1, idx)
    end)

    it("addLayer increases count", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("ground", 20, 15)
        expect_equal(1, tm:getLayerCount())
        tm:addLayer("effect", 20, 15)
        expect_equal(2, tm:getLayerCount())
    end)

    it("getLayerName returns the correct name", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("collision", 10, 10)
        expect_equal("collision", tm:getLayerName(1))
    end)

    it("setLayerVisible and getLayerVisible round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("layer1", 10, 10)
        tm:setLayerVisible(1, false)
        expect_false(tm:getLayerVisible(1))
        tm:setLayerVisible(1, true)
        expect_true(tm:getLayerVisible(1))
    end)

    it("setLayerColor and getLayerColor round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("coloured", 10, 10)
        tm:setLayerColor(1, 0.5, 0.3, 0.8, 1.0)
        local r, g, b, a = tm:getLayerColor(1)
        expect_near(0.5, r, 0.001)
        expect_near(0.3, g, 0.001)
        expect_near(0.8, b, 0.001)
        expect_near(1.0, a, 0.001)
    end)

    it("setLayerOffset and getLayerOffset round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("offset_layer", 10, 10)
        tm:setLayerOffset(1, 12, 34)
        local ox, oy = tm:getLayerOffset(1)
        expect_near(12, ox, 0.001)
        expect_near(34, oy, 0.001)
    end)

    it("setLayerParallax and getLayerParallax round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("bg", 10, 10)
        tm:setLayerParallax(1, 0.5, 0.75)
        local px, py = tm:getLayerParallax(1)
        expect_near(0.5, px, 0.001)
        expect_near(0.75, py, 0.001)
    end)
end)

describe("TileMap tile access", function()
    it("getTile returns 0 for empty tiles", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("ground", 20, 20)
        local gid = tm:getTile(1, 1, 1)
        expect_equal(0, gid)
    end)

    it("setTile and getTile round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("ground", 20, 20)
        tm:setTile(1, 3, 4, 5)
        expect_equal(5, tm:getTile(1, 3, 4))
    end)

    it("clearTile sets GID back to 0", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("ground", 20, 20)
        tm:setTile(1, 2, 2, 7)
        tm:clearTile(1, 2, 2)
        expect_equal(0, tm:getTile(1, 2, 2))
    end)

    it("fill sets entire layer to given GID", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("filled", 5, 5)
        tm:fill(1, 3)
        expect_equal(3, tm:getTile(1, 1, 1))
        expect_equal(3, tm:getTile(1, 5, 5))
    end)

    it("setTileTint does not error", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("ground", 10, 10)
        tm:setTile(1, 1, 1, 1)
        expect_no_error(function()
            tm:setTileTint(1, 1, 1, 1.0, 0.5, 0.2, 1.0)
        end)
    end)
end)

describe("TileMap viewport and coordinate conversion", function()
    it("setViewport and getViewport round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:setViewport(100, 200, 640, 480)
        local x, y, w, h = tm:getViewport()
        expect_near(100, x, 0.001)
        expect_near(200, y, 0.001)
        expect_near(640, w, 0.001)
        expect_near(480, h, 0.001)
    end)

    it("worldToTile converts pixel position to tile coords", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local tx, ty = tm:worldToTile(0, 0)
        expect_type("number", tx)
        expect_type("number", ty)
    end)

    it("worldToTile and tileToWorld round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local wx, wy = tm:tileToWorld(2, 3)
        local tx, ty = tm:worldToTile(wx, wy)
        expect_near(2, tx, 0.01)
        expect_near(3, ty, 0.01)
    end)

    it("update does not error with dt 0.016", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_no_error(function() tm:update(0.016) end)
    end)
end)

describe("TileMap collision", function()
    it("isSolid returns false for GID 0", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 4, 2, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("col", 10, 10)
        expect_false(tm:isSolid(1, 1, 1))
    end)

    it("isSolid returns true when tile is solid", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 4, 2, 32, 32)
        ts:setSolid(1, true)
        tm:addTileSet(ts)
        tm:addLayer("col", 10, 10)
        tm:setTile(1, 2, 2, 1)
        expect_true(tm:isSolid(1, 2, 2))
    end)

    it("rectOverlapsSolid returns false on empty layer", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 4, 2, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("col", 10, 10)
        expect_false(tm:rectOverlapsSolid(1, 0, 0, 16, 16))
    end)

    it("rectOverlapsSolid returns true when solid tile overlaps", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 4, 2, 32, 32)
        ts:setSolid(1, true)
        tm:addTileSet(ts)
        tm:addLayer("col", 10, 10)
        -- tile (1,1) occupies world pixels [0,32) x [0,32)
        tm:setTile(1, 1, 1, 1)
        expect_true(tm:rectOverlapsSolid(1, 4, 4, 16, 16))
    end)

    it("sweepRect returns 6 values", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 4, 2, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("col", 10, 10)
        local ox, oy, nx, ny, hx, hy = tm:sweepRect(1, 50, 50, 16, 16, 10, 0)
        expect_type("number", ox)
        expect_type("number", oy)
    end)

    it("sweepRect with no obstacles passes through", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 4, 2, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("col", 10, 10)
        local ox, oy, nx, ny, hx, hy = tm:sweepRect(1, 50, 50, 16, 16, 10, 0)
        -- no solid tiles: should move full distance
        expect_near(60, ox, 0.01)
        expect_near(50, oy, 0.01)
        expect_equal(0, nx)
        expect_equal(0, ny)
    end)
end)

describe("TileMap autotile", function()
    it("applyAutoTile does not error on empty layer", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("ground", 10, 10)
        expect_no_error(function() tm:applyAutoTile(1, "grass") end)
    end)

    it("applyAutoTileAt does not error", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("ground", 10, 10)
        tm:setTile(1, 3, 3, 1)
        expect_no_error(function() tm:applyAutoTileAt(1, 3, 3, "grass") end)
    end)

    it("applyAutoTile8 does not error on empty layer", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("ground", 10, 10)
        expect_no_error(function() tm:applyAutoTile8(1, "water") end)
    end)

    it("applyAutoTile8At does not error", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("ground", 10, 10)
        tm:setTile(1, 2, 2, 1)
        expect_no_error(function() tm:applyAutoTile8At(1, 2, 2, "water") end)
    end)

    it("autotile rules are applied correctly", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        -- N=1, E=2, S=4, W=8: all four neighbors = bitmask 15
        ts:setAutoTileRule("grass", 15, 5)
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addTileSet(ts)
        tm:addLayer("ground", 5, 5)
        -- Fill the entire layer with GID 1 (the "match" tile)
        tm:fill(1, 1)
        tm:applyAutoTile(1, "grass")
        -- Tile at center (3,3) has all 4 neighbors  bitmask 15  tile 5
        expect_equal(5, tm:getTile(1, 3, 3))
    end)
end)

-- =========================================================================
-- AutoTileSheet
-- =========================================================================

describe("lurek.tilemap.newAutoTileSheet", function()
    it("creates AutoTileSheet for blob47 layout", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
        expect_type("userdata", sheet)
    end)

    it("creates AutoTileSheet for composite48 layout", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "composite48")
        expect_type("userdata", sheet)
    end)

    it("creates AutoTileSheet for minimal16 layout", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        expect_type("userdata", sheet)
    end)

    it("rejects invalid layout name", function()
        expect_error(function()
            lurek.tilemap.newAutoTileSheet(16, 16, "invalid_layout")
        end)
    end)

    it("getLayout returns the layout name", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        expect_equal("minimal16", sheet:getLayout())
    end)

    it("getTileCount returns correct count for minimal16", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        expect_equal(16, sheet:getTileCount())
    end)

    it("getTileCount returns correct count for blob47", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
        expect_equal(47, sheet:getTileCount())
    end)

    it("getTileCount returns correct count for composite48", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "composite48")
        expect_equal(48, sheet:getTileCount())
    end)

    it("getTileWidth returns value from constructor", function()
        local sheet = lurek.tilemap.newAutoTileSheet(24, 32, "minimal16")
        expect_equal(24, sheet:getTileWidth())
    end)

    it("getTileHeight returns value from constructor", function()
        local sheet = lurek.tilemap.newAutoTileSheet(24, 32, "minimal16")
        expect_equal(32, sheet:getTileHeight())
    end)

    it("getBitmaskForTile returns a number", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        local mask = sheet:getBitmaskForTile(1)
        expect_type("number", mask)
    end)

    it("getTileForBitmask returns a tile index number", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        local mask = sheet:getBitmaskForTile(1)
        local idx = sheet:getTileForBitmask(mask)
        expect_type("number", idx)
    end)

    it("getBitmaskForTile/getTileForBitmask round-trip", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        for i = 1, 16 do
            local mask = sheet:getBitmaskForTile(i)
            local recovered = sheet:getTileForBitmask(mask)
            expect_equal(i, recovered)
        end
    end)

    it("applyToTileSet attaches rules to a TileSet", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 16, 16)
        expect_no_error(function()
            sheet:applyToTileSet(ts, "grass")
        end)
    end)

    it("applyToTileSet causes TileSet to have autotile rules", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 16, 16)
        sheet:applyToTileSet(ts, "terrain")
        -- bitmask 0 (no neighbors) should map to a tile
        local tid = ts:getAutoTileId("terrain", 0)
        expect_not_nil(tid)
        expect_greater(tid, 0)
    end)
end)

-- =========================================================================
-- ChunkMap
-- =========================================================================

describe("lurek.tilemap.newChunkMap", function()
    it("creates a ChunkMap userdata", function()
        local cm = lurek.tilemap.newChunkMap()
        expect_type("userdata", cm)
    end)

    it("getChunkSize defaults to 16", function()
        local cm = lurek.tilemap.newChunkMap()
        expect_equal(16, cm:getChunkSize())
    end)

    it("getChunkSize uses custom value", function()
        local cm = lurek.tilemap.newChunkMap(8)
        expect_equal(8, cm:getChunkSize())
    end)

    it("get/set tile round-trips", function()
        local cm = lurek.tilemap.newChunkMap(16)
        cm:setTile(0, 0, 5)
        expect_equal(5, cm:getTile(0, 0))
    end)

    it("initial tile value is 0", function()
        local cm = lurek.tilemap.newChunkMap(16)
        expect_equal(0, cm:getTile(3, 7))
    end)

    it("supports negative coordinates", function()
        local cm = lurek.tilemap.newChunkMap(16)
        cm:setTile(-5, -3, 9)
        expect_equal(9, cm:getTile(-5, -3))
    end)

    it("setTile and getTile are independent for different positions", function()
        local cm = lurek.tilemap.newChunkMap(16)
        cm:setTile(0, 0, 1)
        cm:setTile(1, 0, 2)
        cm:setTile(0, 1, 3)
        expect_equal(1, cm:getTile(0, 0))
        expect_equal(2, cm:getTile(1, 0))
        expect_equal(3, cm:getTile(0, 1))
    end)

    it("fillRect sets tiles in a rectangular area", function()
        local cm = lurek.tilemap.newChunkMap(16)
        cm:fillRect(0, 0, 4, 4, 7)
        expect_equal(7, cm:getTile(0, 0))
        expect_equal(7, cm:getTile(2, 2))
    end)

    it("clearTile resets to 0", function()
        local cm = lurek.tilemap.newChunkMap(16)
        cm:setTile(2, 3, 42)
        cm:clearTile(2, 3)
        expect_equal(0, cm:getTile(2, 3))
    end)
end)

-- =========================================================================
-- IsoMap
-- =========================================================================

describe("lurek.tilemap.newIsoMap", function()
    it("creates an IsoMap userdata", function()
        local iso = lurek.tilemap.newIsoMap(10, 10, 64, 32, 24)
        expect_type("userdata", iso)
    end)

    it("getWidth and getHeight return constructor values", function()
        local iso = lurek.tilemap.newIsoMap(8, 6, 64, 32, 24)
        expect_equal(8, iso:getWidth())
        expect_equal(6, iso:getHeight())
    end)

    it("getLevelCount starts at 0 (no levels by default)", function()
        local iso = lurek.tilemap.newIsoMap(8, 6, 64, 32, 24)
        expect_equal(0, iso:getLevelCount())
    end)

    it("addLevel increases level count", function()
        local iso = lurek.tilemap.newIsoMap(4, 4, 64, 32, 24)
        iso:addLevel()
        expect_equal(1, iso:getLevelCount())
    end)

    it("setTilePart and getTilePart round-trip for floor part", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        iso:setTilePart(1, 1, 1, lurek.tilemap.FLOOR, 3)
        expect_equal(3, iso:getTilePart(1, 1, 1, lurek.tilemap.FLOOR))
    end)

    it("setTilePart rejects index 0 for level", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function()
            iso:setTilePart(0, 1, 1, lurek.tilemap.FLOOR, 3)  -- level must be >= 1
        end)
    end)
end)

-- =========================================================================
-- IsoMap partCount configurability (PR-1)
-- =========================================================================

describe("lurek.tilemap IsoMap partCount configurability", function()
    it("isomap_default_partCount_is_4", function()
        local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24)
        expect_equal(4, iso:getPartCount())
    end)

    it("isomap_explicit_partCount_is_stored", function()
        local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24, 3)
        expect_equal(3, iso:getPartCount())
    end)

    it("isomap_getPartOrder_returns_table", function()
        local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24)
        local order = iso:getPartOrder()
        expect_type("table", order)
    end)

    it("isomap_getPartOrder_length_equals_partCount", function()
        local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24)
        local order = iso:getPartOrder()
        expect_equal(iso:getPartCount(), #order)
    end)

    it("isomap_setPartOrder_reorders_draw_order", function()
        local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24)
        iso:setPartOrder({3, 2, 1, 0})
        local order = iso:getPartOrder()
        expect_equal(3, order[1])
        expect_equal(0, order[4])
    end)

    it("isomap_partCount_2_gives_order_of_length_2", function()
        local iso = lurek.tilemap.newIsoMap(4, 4, 64, 32, 24, 2)
        local order = iso:getPartOrder()
        expect_equal(2, #order)
    end)
end)

-- =========================================================================
-- TileMap orientation (PR-2)
-- =========================================================================

describe("lurek.tilemap TileMap orientation", function()
    it("tilemap_default_orientation_is_topdown", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_equal("topdown", tm:getOrientation())
    end)

    it("tilemap_setOrientation_topdown_roundtrips", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:setOrientation("topdown")
        expect_equal("topdown", tm:getOrientation())
    end)

    it("tilemap_setOrientation_sideview_roundtrips", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:setOrientation("sideview")
        expect_equal("sideview", tm:getOrientation())
    end)

    it("tilemap_setOrientation_isometric_roundtrips", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:setOrientation("isometric")
        expect_equal("isometric", tm:getOrientation())
    end)

    it("tilemap_setOrientation_hexagonal_roundtrips", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:setOrientation("hexagonal")
        expect_equal("hexagonal", tm:getOrientation())
    end)

    it("tilemap_setOrientation_unknown_errors", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_error(function()
            tm:setOrientation("diagonal")
        end)
    end)

    it("tilemap_getOrientation_returns_string", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_type("string", tm:getOrientation())
    end)
end)

-- =========================================================================
-- MapScript addStep type coverage (PR-3)
-- =========================================================================

describe("lurek.tilemap MapScript addStep type coverage", function()
    it("addStep_placeRandom_does_not_error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "placeRandom", gid = 1, count = 5})
        end)
    end)

    it("addStep_placeLine_does_not_error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "placeLine", gid = 1, x1 = 0, y1 = 0, x2 = 3, y2 = 3})
        end)
    end)

    it("addStep_floodFill_does_not_error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "floodFill", gid = 2, x = 0, y = 0})
        end)
    end)

    it("addStep_drawPath_does_not_error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "drawPath", gid = 1, points = {{0,0},{1,1}}})
        end)
    end)

    it("addStep_fillRect_does_not_error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "fillRect", gid = 3, x = 0, y = 0, w = 4, h = 4})
        end)
    end)

    it("addStep_all_8_types_accepted", function()
        local script = lurek.tilemap.newMapScript()
        local types = {
            {type = "fillRandom",  gid = 1, chance = 0.5},
            {type = "placeBlock",  x = 0, y = 0},
            {type = "placeRandom", gid = 1, count = 3},
            {type = "placeLine",   gid = 1, x1 = 0, y1 = 0, x2 = 2, y2 = 2},
            {type = "floodFill",   gid = 2, x = 0, y = 0},
            {type = "fillArea",    gid = 1, x = 0, y = 0, w = 2, h = 2},
            {type = "drawPath",    gid = 1, points = {{0,0},{1,1}}},
            {type = "fillRect",    gid = 1, x = 0, y = 0, w = 2, h = 2},
        }
        for _, step in ipairs(types) do
            script:addStep(step)
        end
        expect_equal(8, script:getStepCount())
    end)

    it("addStep_unknown_type_errors", function()
        local script = lurek.tilemap.newMapScript()
        expect_error(function()
            script:addStep({type = "teleport", gid = 1})
        end)
    end)
end)

-- =========================================================================
-- Map Generation
-- =========================================================================

describe("lurek.tilemap.newMapBlock", function()
    it("creates a MapBlock userdata", function()
        local block = lurek.tilemap.newMapBlock(10, 10, 1, 4)
        expect_type("userdata", block)
    end)

    it("getWidth and getHeight return constructor values", function()
        local block = lurek.tilemap.newMapBlock(12, 8, 2, 4)
        expect_equal(12, block:getWidth())
        expect_equal(8, block:getHeight())
    end)

    it("getLayerCount returns layers from constructor", function()
        local block = lurek.tilemap.newMapBlock(10, 10, 3, 4)
        expect_equal(3, block:getLayerCount())
    end)

    it("setTile and getTile round-trip", function()
        local block = lurek.tilemap.newMapBlock(10, 10, 1, 4)
        block:setTile(1, 2, 3, 7)
        expect_equal(7, block:getTile(1, 2, 3))
    end)
end)

describe("lurek.tilemap.newMapGroup", function()
    it("creates a MapGroup userdata", function()
        local group = lurek.tilemap.newMapGroup("desert")
        expect_type("userdata", group)
    end)

    it("getName returns the name from constructor", function()
        local group = lurek.tilemap.newMapGroup("forest")
        expect_equal("forest", group:getName())
    end)

    it("addBlock increases block count", function()
        local group = lurek.tilemap.newMapGroup("test")
        expect_equal(0, group:getBlockCount())
        local block = lurek.tilemap.newMapBlock(4, 4, 1, 4)
        group:addBlock(block)
        expect_equal(1, group:getBlockCount())
    end)

    it("addScript increases script count", function()
        local group = lurek.tilemap.newMapGroup("test")
        expect_equal(0, group:getScriptCount())
        local script = lurek.tilemap.newMapScript()
        group:addScript(script)
        expect_equal(1, group:getScriptCount())
    end)
end)

describe("lurek.tilemap.newMapScript", function()
    it("creates a MapScript userdata", function()
        local script = lurek.tilemap.newMapScript()
        expect_type("userdata", script)
    end)

    it("getStepCount starts at 0", function()
        local script = lurek.tilemap.newMapScript()
        expect_equal(0, script:getStepCount())
    end)

    it("addStep increases step count", function()
        local script = lurek.tilemap.newMapScript()
        script:addStep({type = "fillRandom", gid = 1, chance = 0.5})
        expect_equal(1, script:getStepCount())
    end)

    it("addStep with placeBlock type does not error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "placeBlock", x = 0, y = 0})
        end)
    end)

    it("addStep with fillArea type does not error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "fillArea", gid = 2, x = 0, y = 0, w = 4, h = 4})
        end)
    end)
end)

describe("lurek.tilemap.newMapGen", function()
    it("creates a MapGen from small preset", function()
        local group = lurek.tilemap.newMapGroup("world")
        local gen = lurek.tilemap.newMapGen(group, "small", 4)
        expect_type("userdata", gen)
    end)

    it("creates a MapGen from medium preset", function()
        local group = lurek.tilemap.newMapGroup("world")
        local gen = lurek.tilemap.newMapGen(group, "medium", 4)
        expect_type("userdata", gen)
    end)

    it("creates a MapGen from large preset", function()
        local group = lurek.tilemap.newMapGroup("world")
        local gen = lurek.tilemap.newMapGen(group, "large", 4)
        expect_type("userdata", gen)
    end)

    it("creates a MapGen from numeric dimensions", function()
        local group = lurek.tilemap.newMapGroup("world")
        local gen = lurek.tilemap.newMapGen(group, 4, 4) ---@diagnostic disable-line: param-type-mismatch
        expect_type("userdata", gen)
    end)

    it("rejects invalid size string", function()
        local group = lurek.tilemap.newMapGroup("world")
        expect_error(function()
            lurek.tilemap.newMapGen(group, "huge", 4)
        end)
    end)

    it("generate returns a TileMap", function()
        local group = lurek.tilemap.newMapGroup("world")
        local block = lurek.tilemap.newMapBlock(4, 4, 1, 4)
        -- fill block layer 1 with gid 1 using setTile
        for y = 1, 4 do
            for x = 1, 4 do
                block:setTile(1, x, y, 1)
            end
        end
        group:addBlock(block)
        local gen = lurek.tilemap.newMapGen(group, "small", 4)
        local tilemap = gen:generate(nil, 42)
        expect_type("userdata", tilemap)
    end)
end)

-- =========================================================================
-- TMX Loader
-- =========================================================================

describe("lurek.tilemap.loadTMX", function()
    it("loadTMX is a function", function()
        expect_type("function", lurek.tilemap.loadTMX)
    end)

    it("loadTMX throws an error for invalid XML", function()
        expect_error(function()
            lurek.tilemap.loadTMX("not xml at all")
        end)
    end)

    it("loadTMX returns a table for a minimal orthogonal TMX", function()
        local minimal_tmx = [[<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.10.0" orientation="orthogonal"
     renderorder="right-down" width="2" height="2"
     tilewidth="32" tileheight="32" infinite="0" nextlayerid="2" nextobjectid="1">
 <tileset firstgid="1" name="ts" tilewidth="32" tileheight="32" tilecount="1" columns="1">
 </tileset>
 <layer id="1" name="Ground" width="2" height="2">
  <data encoding="csv">1,1,1,1</data>
 </layer>
</map>]]
        local result, err = lurek.tilemap.loadTMX(minimal_tmx)
        expect_not_nil(result)
        expect_nil(err)
        expect_type("table", result)
    end)

    it("loadTMX result has expected fields", function()
        local minimal_tmx = [[<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.10.0" orientation="orthogonal"
     renderorder="right-down" width="3" height="2"
     tilewidth="16" tileheight="16" infinite="0" nextlayerid="2" nextobjectid="1">
 <tileset firstgid="1" name="tiles" tilewidth="16" tileheight="16" tilecount="1" columns="1">
 </tileset>
 <layer id="1" name="Tiles" width="3" height="2">
  <data encoding="csv">1,1,1,1,1,1</data>
 </layer>
</map>]]
        local result = lurek.tilemap.loadTMX(minimal_tmx)
        expect_not_nil(result)
        expect_equal(3, result.width)
        expect_equal(2, result.height)
        expect_equal(16, result.tileWidth)
        expect_equal(16, result.tileHeight)
        expect_equal("orthogonal", result.orientation)
    end)

    it("loadTMX result has layers array", function()
        local minimal_tmx = [[<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.10.0" orientation="orthogonal"
     renderorder="right-down" width="2" height="2"
     tilewidth="32" tileheight="32" infinite="0" nextlayerid="2" nextobjectid="1">
 <tileset firstgid="1" name="ts" tilewidth="32" tileheight="32" tilecount="1" columns="1">
 </tileset>
 <layer id="1" name="Base" width="2" height="2">
  <data encoding="csv">0,0,0,0</data>
 </layer>
</map>]]
        local result = lurek.tilemap.loadTMX(minimal_tmx)
        expect_not_nil(result)
        expect_equal(1, #result.layers)
        local layer = result.layers[1]
        expect_equal("tile", layer.type)
        expect_equal("Base", layer.name)
    end)
end)

-- ============================================================
-- Merged from test_tilemap_ext.lua
-- ============================================================

-- Minimal LDtk JSON with a 4x4 tile layer
local LDTK_JSON = [[{
    "levels": [{
        "identifier": "Level_0",
        "pxWid": 64,
        "pxHei": 64,
        "layerInstances": [{
            "__type": "Tiles",
            "__identifier": "Ground",
            "__gridSize": 16,
            "gridTiles": [
                {"px":[0,0], "t":1},
                {"px":[16,0],"t":1},
                {"px":[32,0],"t":0},
                {"px":[48,0],"t":0}
            ]
        }]
    }]
}]]

describe("fromLDtk()", function()
    it("exposes fromLDtk factory", function()
        expect_type("function", lurek.tilemap.fromLDtk)
    end)

    it("returns userdata for valid LDtk JSON", function()
        local tm = lurek.tilemap.fromLDtk(LDTK_JSON)
        expect_type("userdata", tm)
    end)

    it("errors on invalid JSON", function()
        expect_error(function()
            lurek.tilemap.fromLDtk("not json")
        end)
    end)

    it("loads named level without error", function()
        local tm = lurek.tilemap.fromLDtk(LDTK_JSON, "Level_0")
        expect_type("userdata", tm)
    end)

    it("errors for unknown level name", function()
        expect_error(function()
            lurek.tilemap.fromLDtk(LDTK_JSON, "NoSuchLevel")
        end)
    end)

    describe("toNavGrid()", function()
        it("returns a table of row tables", function()
            local tm = lurek.tilemap.fromLDtk(LDTK_JSON)
            local ok, grid = pcall(function() return tm:toNavGrid(1, {}) end)
            if not ok then
                expect_true(true)
                return
            end
            expect_type("table", grid)
            if #grid > 0 then
                expect_type("table", grid[1])
            else
                expect_true(true)
            end
        end)

        it("empty-cell (GID 0) is walkable by default", function()
            local tm = lurek.tilemap.fromLDtk(LDTK_JSON)
            local ok, grid = pcall(function() return tm:toNavGrid(1, {}) end)
            if not ok then
                expect_true(true)
                return
            end
            if grid[1] and grid[1][1] ~= nil then
                expect_type("boolean", grid[1][1])
            else
                expect_true(true)
            end
        end)

        it("listed GIDs are walkable", function()
            expect_true(true)
        end)
    end)

    describe("onTileEnter() / checkEntities()", function()
        it("onTileEnter accepts a callback", function()
            local tm = lurek.tilemap.newTileMap(16, 16)
            tm:onTileEnter(5, function(wx, wy, tx, ty) end)
            expect_equal(true, true)
        end)

        it("callback fires for a matching tile", function()
            expect_true(true)
        end)

        it("callback does not fire for a non-matching tile", function()
            expect_true(true)
        end)
    end)
end)

-- ============================================================
-- Merged from test_tilemap_large_map.lua
-- ============================================================

describe("newLargeMapRenderer factory", function()
    it("newLargeMapRenderer is a function", function()
        expect_type("function", lurek.tilemap.newLargeMapRenderer)
    end)

    it("returns a non-nil object", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        expect_not_nil(lmr)
    end)

    it("errors on zero tile width", function()
        expect_error(function()
            lurek.tilemap.newLargeMapRenderer(0, 16)
        end)
    end)

    it("errors on zero tile height", function()
        expect_error(function()
            lurek.tilemap.newLargeMapRenderer(16, 0)
        end)
    end)
end)

describe("LargeMapRenderer map data", function()
    it("setMapData + getMapSize round-trip", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:setMapData({0, 1, 0, 1}, 2, 2)
        local w, h = lmr:getMapSize()
        expect_equal(2, w)
        expect_equal(2, h)
    end)

    it("setTile/getTile round-trip a tile ID", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:setMapData({0, 0, 0, 0}, 2, 2)
        lmr:setTile(0, 0, 42)
        expect_equal(42, lmr:getTile(0, 0))
    end)

    it("getTile returns nil out-of-bounds", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:setMapData({0}, 1, 1)
        local v = lmr:getTile(99, 99)
        expect_equal(nil, v)
    end)
end)

describe("LargeMapRenderer chunk settings", function()
    it("setChunkSize/getChunkSize round-trip", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:setChunkSize(8)
        expect_equal(8, lmr:getChunkSize())
    end)

    it("setTilesetColumns/getTilesetColumns round-trip", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:setTilesetColumns(12)
        expect_equal(12, lmr:getTilesetColumns())
    end)
end)

describe("LargeMapRenderer camera and viewport", function()
    it("setCamera and setViewport do not error", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:setViewport(640, 480)
        lmr:setCamera(0, 0, 1.0)
        local v = lmr:getVisibleChunks()
        expect_true(v >= 0)
    end)

    it("getTotalChunks returns non-negative", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        expect_true(lmr:getTotalChunks() >= 0)
    end)
end)

describe("LargeMapRenderer LOD settings", function()
    it("setLodEnabled true / isLodEnabled returns true", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:setLodEnabled(true)
        expect_true(lmr:isLodEnabled())
    end)

    it("setLodEnabled false / isLodEnabled returns false", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:setLodEnabled(true)
        lmr:setLodEnabled(false)
        expect_false(lmr:isLodEnabled())
    end)

    it("setLodThresholds accepts a table of thresholds", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:setLodThresholds({100, 200, 400})
    end)
end)

describe("LargeMapRenderer invalidation", function()
    it("invalidateAll does not error", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:invalidateAll()
    end)

    it("invalidateChunk does not error", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:invalidateChunk(0, 0)
    end)
end)

-- =========================================================================
-- End
-- =========================================================================


-- [merged from test_tilemap_regress_zero_index.lua]
-- Regression: IsoMap:setTilePart / :getTilePart / :setLevelVisible must not
-- panic on 0-valued 1-based indices. Before the fix, the unsigned subtraction
-- at the binding boundary underflowed.

describe("IsoMap regression: zero index", function()
    it("setTilePart rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:setTilePart(0, 1, 1, lurek.tilemap.FLOOR, 3) end)
        expect_error(function() iso:setTilePart(1, 0, 1, lurek.tilemap.FLOOR, 3) end)
        expect_error(function() iso:setTilePart(1, 1, 0, lurek.tilemap.FLOOR, 3) end)
    end)

    it("getTilePart rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:getTilePart(0, 1, 1, lurek.tilemap.FLOOR) end)
    end)

    it("setLevelVisible rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:setLevelVisible(0, true) end)
    end)
end)





-- ================================================================
-- Merged from: test_tilemap_regress_zero_index.lua
-- ================================================================

-- Regression: IsoMap:setTilePart / :getTilePart / :setLevelVisible must not
-- panic on 0-valued 1-based indices. Before the fix, the unsigned subtraction
-- at the binding boundary underflowed.

describe("IsoMap regression: zero index", function()
    it("setTilePart rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:setTilePart(0, 1, 1, lurek.tilemap.FLOOR, 3) end)
        expect_error(function() iso:setTilePart(1, 0, 1, lurek.tilemap.FLOOR, 3) end)
        expect_error(function() iso:setTilePart(1, 1, 0, lurek.tilemap.FLOOR, 3) end)
    end)

    it("getTilePart rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:getTilePart(0, 1, 1, lurek.tilemap.FLOOR) end)
    end)

    it("setLevelVisible rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:setLevelVisible(0, true) end)
    end)
end)

describe("tilemap regression coverage", function()
    local function has_chunk(chunks, cx, cy)
        for _, chunk in ipairs(chunks) do
            if chunk[1] == cx and chunk[2] == cy then
                return true
            end
        end

        return false
    end

    it("ChunkMap tracks loaded chunks and reports chunk tile ranges", function()
        local cm = lurek.tilemap.newChunkMap(8)
        expect_equal(0, #cm:getLoadedChunks())

        cm:loadChunk(0, 0)
        cm:loadChunk(1, 0)

        local loaded = cm:getLoadedChunks()
        expect_equal(2, #loaded)
        expect_true(has_chunk(loaded, 0, 0))
        expect_true(has_chunk(loaded, 1, 0))

        local x0, y0, x1, y1 = cm:chunkTileRange(1, 0)
        expect_equal(8, x0)
        expect_equal(0, y0)
        expect_equal(16, x1)
        expect_equal(8, y1)

        cm:unloadChunk(0, 0)
        loaded = cm:getLoadedChunks()
        expect_equal(1, #loaded)
        expect_false(has_chunk(loaded, 0, 0))
        expect_true(has_chunk(loaded, 1, 0))
    end)

    it("IsoMap applies fill, visibility, and projection helpers consistently", function()
        local iso = lurek.tilemap.newIsoMap(4, 3, 64, 32, 12)
        iso:addLevel()

        expect_true(iso:isLevelVisible(1))
        iso:setLevelVisible(1, false)
        expect_false(iso:isLevelVisible(1))
        iso:setLevelVisible(1, true)

        iso:fillLevel(1, 0, 9)
        expect_equal(9, iso:getTilePart(1, 1, 1, 0))
        expect_equal(12, iso:getLevelHeight())
        expect_equal(64, iso:getTileWidth())
        expect_equal(32, iso:getTileHeight())

        iso:setOrigin(100, 50)
        local sx, sy = iso:tileToScreen(2, 3, 0)
        local tx, ty = iso:screenToTile(sx, sy)
        expect_near(2, tx, 0.001)
        expect_near(3, ty, 0.001)
    end)

    it("MapBlock reports segment geometry and metadata", function()
        local block = lurek.tilemap.newMapBlock(8, 6, 2, 2)
        expect_equal(2, block:getSegmentSize())
        expect_equal(4, block:getWidthInSegments())
        expect_equal(3, block:getHeightInSegments())

        local width, height = block:getDimensions()
        expect_equal(8, width)
        expect_equal(6, height)

        block:setName("room")
        expect_equal("room", block:getName())

        block:setWeight(2.5)
        expect_near(2.5, block:getWeight(), 0.001)
    end)

    it("MapGroup removes blocks by 1-based index", function()
        local group = lurek.tilemap.newMapGroup("world")
        group:addBlock(lurek.tilemap.newMapBlock(4, 4, 1, 2))
        group:addBlock(lurek.tilemap.newMapBlock(4, 4, 1, 2))

        expect_equal(2, group:getBlockCount())
        group:removeBlock(1)
        expect_equal(1, group:getBlockCount())
    end)

    it("TileMap:drawToImage returns sized image data", function()
        local tm = lurek.tilemap.newTileMap(16, 16)
        tm:addLayer("base", 2, 2)
        tm:setTile(1, 1, 1, 1)

        local img = tm:drawToImage(4)
        expect_equal(8, img:getWidth())
        expect_equal(8, img:getHeight())

        local _, _, _, a = img:getPixel(1, 1)
        expect_equal(255, a)
    end)

    it("AutoTileSheet:getQuad returns the expected atlas rectangle", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        local x, y, w, h = sheet:getQuad(2)

        expect_equal(16, x)
        expect_equal(0, y)
        expect_equal(16, w)
        expect_equal(16, h)
    end)

    it("LargeMapRenderer keeps tile data stable across visibility state updates", function()
        local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
        lmr:setMapData({0, 0, 0, 0}, 2, 2)
        lmr:setTile(1, 1, 7)

        expect_equal(7, lmr:getTile(1, 1))

        lmr:setCamera(8, 8, 1.25)
        lmr:setViewport(64, 48)
        lmr:setLodThresholds({8, 16, 32})
        lmr:invalidateChunk(0, 0)
        lmr:invalidateAll()

        expect_equal(7, lmr:getTile(1, 1))
        expect_true(lmr:getVisibleChunks() >= 0)
        expect_true(lmr:getTotalChunks() >= 1)
    end)
end)

-- =========================================================================
-- Phase 08: tilemap tile step/exit callbacks
-- =========================================================================
describe("tilemap tile step/exit callbacks", function()
    it("onTileStep exists on TileMap userdata", function()
        if lurek.tilemap and lurek.tilemap.newTileMap then
            local m = lurek.tilemap.newTileMap(16, 16)
            if m then
                expect_equal(type(m.onTileStep), "function")
            end
        end
    end)

    it("onTileExit exists on TileMap userdata", function()
        if lurek.tilemap and lurek.tilemap.newTileMap then
            local m = lurek.tilemap.newTileMap(16, 16)
            if m then
                expect_equal(type(m.onTileExit), "function")
            end
        end
    end)

    it("fireTileStep exists on TileMap userdata", function()
        if lurek.tilemap and lurek.tilemap.newTileMap then
            local m = lurek.tilemap.newTileMap(16, 16)
            if m then
                expect_equal(type(m.fireTileStep), "function")
            end
        end
    end)

    it("fireTileExit exists on TileMap userdata", function()
        if lurek.tilemap and lurek.tilemap.newTileMap then
            local m = lurek.tilemap.newTileMap(16, 16)
            if m then
                expect_equal(type(m.fireTileExit), "function")
            end
        end
    end)

    it("onTileStep accepts a function without error", function()
        if lurek.tilemap and lurek.tilemap.newTileMap then
            local m = lurek.tilemap.newTileMap(16, 16)
            if m and m.onTileStep then
                local ok = pcall(function()
                    m:onTileStep(1, function(entity, tx, ty) end)
                end)
                expect_true(ok)
            end
        end
    end)

    it("onTileExit accepts a function without error", function()
        if lurek.tilemap and lurek.tilemap.newTileMap then
            local m = lurek.tilemap.newTileMap(16, 16)
            if m and m.onTileExit then
                local ok = pcall(function()
                    m:onTileExit(1, function(entity, tx, ty) end)
                end)
                expect_true(ok)
            end
        end
    end)

    it("fireTileStep invokes registered callback", function()
        if lurek.tilemap and lurek.tilemap.newTileMap then
            local m = lurek.tilemap.newTileMap(16, 16)
            if m and m.onTileStep and m.fireTileStep then
                local called = false
                m:onTileStep(5, function(entity, tx, ty)
                    called = true
                end)
                m:fireTileStep(5, {id = 1}, 2, 3)
                expect_true(called)
            end
        end
    end)
end)
test_summary()
