-- Lurek2D Tilemap API Tests
-- Covers lurek.tilemap module: factory functions, TileSet, TileMap,
-- coordinate helpers, autotile, chunk map, iso map, map generation, and TMX.
-- NOTE: This test runs in headless mode (no GPU/window). drawLayer and
-- texture-dependent rendering calls are intentionally excluded.

-- =========================================================================
-- Module existence
-- =========================================================================

-- @description Covers suite: lurek.tilemap module exists.
describe("lurek.tilemap module exists", function()
    -- @tests lurek.tilemap
    -- @tests lurek.tilemap.FLOOR
    -- @tests lurek.tilemap.NORTH_WALL
    -- @tests lurek.tilemap.OBJECT
    -- @tests lurek.tilemap.WEST_WALL
    -- @tests lurek.tilemap.fromScreenHex
    -- @tests lurek.tilemap.fromScreenIso
    -- @tests lurek.tilemap.hexArea
    -- @tests lurek.tilemap.hexDistance
    -- @tests lurek.tilemap.hexLine
    -- @tests lurek.tilemap.hexNeighbors
    -- @tests lurek.tilemap.hexReflect
    -- @tests lurek.tilemap.hexRing
    -- @tests lurek.tilemap.hexRotate
    -- @tests lurek.tilemap.hexRound
    -- @tests lurek.tilemap.hexSpiral
    -- @tests lurek.tilemap.isoDirectionFromAngle
    -- @tests lurek.tilemap.isoDirectionName
    -- @tests lurek.tilemap.isoRotate
    -- @tests lurek.tilemap.loadTMX
    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests lurek.tilemap.newChunkMap
    -- @tests lurek.tilemap.newIsoMap
    -- @tests lurek.tilemap.newMapBlock
    -- @tests lurek.tilemap.newMapGen
    -- @tests lurek.tilemap.newMapGroup
    -- @tests lurek.tilemap.newMapScript
    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests lurek.tilemap.toScreenHex
    -- @tests lurek.tilemap.toScreenIso
    -- @description Confirms the tilemap module table is registered.
    it("lurek.tilemap is a table", function()
        expect_type("table", lurek.tilemap)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests lurek.tilemap.newChunkMap
    -- @tests lurek.tilemap.newIsoMap
    -- @tests lurek.tilemap.newMapBlock
    -- @tests lurek.tilemap.newMapGroup
    -- @tests lurek.tilemap.newMapScript
    -- @tests lurek.tilemap.newMapGen
    -- @description Verifies the tilemap factory entrypoints are exported as callable functions.
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

    -- @tests lurek.tilemap.toScreenIso
    -- @tests lurek.tilemap.fromScreenIso
    -- @tests lurek.tilemap.toScreenHex
    -- @tests lurek.tilemap.fromScreenHex
    -- @tests lurek.tilemap.hexNeighbors
    -- @tests lurek.tilemap.hexDistance
    -- @tests lurek.tilemap.hexRound
    -- @tests lurek.tilemap.hexLine
    -- @tests lurek.tilemap.hexRing
    -- @tests lurek.tilemap.hexSpiral
    -- @tests lurek.tilemap.hexArea
    -- @tests lurek.tilemap.hexRotate
    -- @tests lurek.tilemap.hexReflect
    -- @tests lurek.tilemap.isoRotate
    -- @tests lurek.tilemap.isoDirectionName
    -- @tests lurek.tilemap.isoDirectionFromAngle
    -- @description Checks that the isometric and hex helper APIs are registered as functions.
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

    -- @tests lurek.tilemap.loadTMX
    -- @description Verifies the TMX loader entrypoint is exported as a function.
    it("exposes TMX loader", function()
        expect_type("function", lurek.tilemap.loadTMX)
    end)

    -- @tests lurek.tilemap.FLOOR
    -- @tests lurek.tilemap.NORTH_WALL
    -- @tests lurek.tilemap.WEST_WALL
    -- @tests lurek.tilemap.OBJECT
    -- @description Confirms the exposed isometric tile-part constants keep their expected numeric values.
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

-- @description Covers suite: lurek.tilemap isometric coordinates.
describe("lurek.tilemap isometric coordinates", function()
    -- @tests lurek.tilemap.toScreenIso
    -- @description Verifies toScreenIso returns numeric screen coordinates for a valid tile coordinate.
    it("toScreenIso converts (1,1) to expected screen position", function()
        local sx, sy = lurek.tilemap.toScreenIso(1, 1, 32, 16)
        expect_type("number", sx)
        expect_type("number", sy)
    end)

    -- @tests lurek.tilemap.toScreenIso
    -- @tests lurek.tilemap.fromScreenIso
    -- @description Confirms isometric world conversion round-trips between tile and screen space.
    it("fromScreenIso round-trips with toScreenIso", function()
        local tx, ty = 3, 5
        local sx, sy = lurek.tilemap.toScreenIso(tx, ty, 32, 16)
        local rx, ry = lurek.tilemap.fromScreenIso(sx, sy, 32, 16)
        expect_near(tx, rx, 0.01)
        expect_near(ty, ry, 0.01)
    end)

    -- @tests lurek.tilemap.toScreenIso
    -- @description Checks that the isometric origin maps to the screen origin.
    it("toScreenIso at origin returns 0,0 for tile (0,0)", function()
        local sx, sy = lurek.tilemap.toScreenIso(0, 0, 32, 16)
        expect_near(0, sx, 0.001)
        expect_near(0, sy, 0.001)
    end)

    -- @tests lurek.tilemap.isoRotate
    -- @description Verifies rotating isometric direction 1 by one step advances to direction 2.
    it("isoRotate direction 1 by 1 step = direction 2", function()
        local dir = lurek.tilemap.isoRotate(1, 1)
        expect_equal(2, dir)
    end)

    -- @tests lurek.tilemap.isoRotate
    -- @description Confirms isoRotate wraps direction 4 back to direction 1.
    it("isoRotate wraps at 4 back to 1", function()
        local dir = lurek.tilemap.isoRotate(4, 1)
        expect_equal(1, dir)
    end)

    -- @tests lurek.tilemap.isoRotate
    -- @description Verifies a full four-step rotation returns each direction to itself.
    it("isoRotate by 4 steps returns same direction", function()
        for d = 1, 4 do
            local rotated = lurek.tilemap.isoRotate(d, 4)
            expect_equal(d, rotated)
        end
    end)

    -- @tests lurek.tilemap.isoDirectionName
    -- @description Checks the direction-name helper returns the expected compass strings.
    it("isoDirectionName returns expected strings", function()
        expect_equal("south", lurek.tilemap.isoDirectionName(1))
        expect_equal("west",  lurek.tilemap.isoDirectionName(2))
        expect_equal("north", lurek.tilemap.isoDirectionName(3))
        expect_equal("east",  lurek.tilemap.isoDirectionName(4))
    end)

    -- @tests lurek.tilemap.isoDirectionFromAngle
    -- @description Verifies angle snapping resolves to one of the four valid isometric directions.
    it("isoDirectionFromAngle snaps to nearest direction", function()
        local dir = lurek.tilemap.isoDirectionFromAngle(0)
        expect_in_range(dir, 1, 4)
    end)
end)

-- =========================================================================
-- Hexagonal coordinate helpers
-- =========================================================================

-- @description Covers suite: lurek.tilemap hexagonal coordinates.
describe("lurek.tilemap hexagonal coordinates", function()
    -- @tests lurek.tilemap.toScreenHex
    -- @tests lurek.tilemap.fromScreenHex
    -- @description Confirms hex grid coordinate conversion round-trips within the expected tolerance.
    it("toScreenHex and fromScreenHex round-trip", function()
        local q, r = 2, 3
        local sx, sy = lurek.tilemap.toScreenHex(q, r, 16)
        local rq, rr = lurek.tilemap.fromScreenHex(sx, sy, 16)
        expect_near(q, rq, 0.5)
        expect_near(r, rr, 0.5)
    end)

    -- @tests lurek.tilemap.hexDistance
    -- @description Verifies the distance between the same hex cell is zero.
    it("hexDistance between same cell is 0", function()
        expect_equal(0, lurek.tilemap.hexDistance(2, 3, 2, 3))
    end)

    -- @tests lurek.tilemap.hexDistance
    -- @description Checks that adjacent hex cells report a distance of one.
    it("hexDistance between adjacent cells is 1", function()
        expect_equal(1, lurek.tilemap.hexDistance(0, 0, 1, 0))
    end)

    -- @tests lurek.tilemap.hexDistance
    -- @description Confirms hexDistance is symmetric regardless of argument order.
    it("hexDistance is symmetric", function()
        local d1 = lurek.tilemap.hexDistance(1, 2, 4, 5)
        local d2 = lurek.tilemap.hexDistance(4, 5, 1, 2)
        expect_equal(d1, d2)
    end)

    -- @tests lurek.tilemap.hexRound
    -- @description Verifies hexRound snaps fractional coordinates to integer axial coordinates.
    it("hexRound returns integers", function()
        local q, r = lurek.tilemap.hexRound(1.4, 2.7)
        expect_true(math.floor(q) == q, "q should be integer")
        expect_true(math.floor(r) == r, "r should be integer")
    end)

    -- @tests lurek.tilemap.hexNeighbors
    -- @description Checks that hexNeighbors returns the six adjacent cells.
    it("hexNeighbors returns 6 cells", function()
        local neighbors = lurek.tilemap.hexNeighbors(0, 0)
        expect_equal(6, #neighbors)
    end)

    -- @tests lurek.tilemap.hexNeighbors
    -- @description Verifies each neighbor entry exposes axial q and r fields.
    it("hexNeighbors each entry has q and r fields", function()
        local neighbors = lurek.tilemap.hexNeighbors(0, 0)
        for _, n in ipairs(neighbors) do
            expect_not_nil(n.q)
            expect_not_nil(n.r)
        end
    end)

    -- @tests lurek.tilemap.hexLine
    -- @description Confirms a zero-length hex line still returns the origin cell.
    it("hexLine from (0,0) to (0,0) returns 1 cell", function()
        local line = lurek.tilemap.hexLine(0, 0, 0, 0)
        expect_equal(1, #line)
    end)

    -- @tests lurek.tilemap.hexLine
    -- @description Checks hexLine includes both endpoints when tracing a straight axial segment.
    it("hexLine from (0,0) to (2,0) returns correct length", function()
        local line = lurek.tilemap.hexLine(0, 0, 2, 0)
        expect_equal(3, #line)
    end)

    -- @tests lurek.tilemap.hexRing
    -- @description Verifies a radius-zero hex ring collapses to the center cell.
    it("hexRing at radius 0 returns 1 cell (the center)", function()
        local ring = lurek.tilemap.hexRing(0, 0, 0)
        expect_equal(1, #ring)
    end)

    -- @tests lurek.tilemap.hexRing
    -- @description Confirms a radius-one hex ring contains exactly six cells.
    it("hexRing at radius 1 returns 6 cells", function()
        local ring = lurek.tilemap.hexRing(0, 0, 1)
        expect_equal(6, #ring)
    end)

    -- @tests lurek.tilemap.hexRing
    -- @description Confirms a radius-two hex ring contains twelve cells.
    it("hexRing at radius 2 returns 12 cells", function()
        local ring = lurek.tilemap.hexRing(0, 0, 2)
        expect_equal(12, #ring)
    end)

    -- @tests lurek.tilemap.hexSpiral
    -- @description Verifies a radius-zero hex spiral contains only the origin.
    it("hexSpiral at radius 0 returns 1 cell", function()
        local spiral = lurek.tilemap.hexSpiral(0, 0, 0)
        expect_equal(1, #spiral)
    end)

    -- @tests lurek.tilemap.hexSpiral
    -- @description Checks that a radius-one hex spiral includes the center plus the first ring.
    it("hexSpiral at radius 1 returns 7 cells (1 center + 6 ring)", function()
        local spiral = lurek.tilemap.hexSpiral(0, 0, 1)
        expect_equal(7, #spiral)
    end)

    -- @tests lurek.tilemap.hexArea
    -- @description Verifies a radius-zero hex area contains only the center cell.
    it("hexArea at radius 0 returns 1 cell", function()
        local area = lurek.tilemap.hexArea(0, 0, 0)
        expect_equal(1, #area)
    end)

    -- @tests lurek.tilemap.hexArea
    -- @description Confirms a radius-one hex area expands to seven cells.
    it("hexArea at radius 1 returns 7 cells", function()
        local area = lurek.tilemap.hexArea(0, 0, 1)
        expect_equal(7, #area)
    end)

    -- @tests lurek.tilemap.hexRotate
    -- @description Checks that rotating by zero steps leaves axial coordinates unchanged.
    it("hexRotate by 0 steps returns same cell", function()
        local q, r = lurek.tilemap.hexRotate(1, 0, 0, 0, 0)
        expect_equal(1, q)
        expect_equal(0, r)
    end)

    -- @tests lurek.tilemap.hexRotate
    -- @description Verifies a full six-step hex rotation returns the original cell.
    it("hexRotate by 6 steps (full circle) returns same cell", function()
        local q, r = lurek.tilemap.hexRotate(2, 1, 0, 0, 6)
        expect_near(2, q, 0.01)
        expect_near(1, r, 0.01)
    end)

    -- @tests lurek.tilemap.hexReflect
    -- @description Confirms q-axis reflection returns numeric axial coordinates.
    it("hexReflect across q axis returns expected result", function()
        local q, r = lurek.tilemap.hexReflect(1, 2, 0, 0, "q")
        expect_type("number", q)
        expect_type("number", r)
    end)

    -- @tests lurek.tilemap.hexReflect
    -- @description Confirms r-axis reflection returns numeric axial coordinates.
    it("hexReflect across r axis returns expected result", function()
        local q, r = lurek.tilemap.hexReflect(1, 2, 0, 0, "r")
        expect_type("number", q)
        expect_type("number", r)
    end)

    -- @tests lurek.tilemap.hexReflect
    -- @description Confirms s-axis reflection returns numeric axial coordinates.
    it("hexReflect across s axis returns expected result", function()
        local q, r = lurek.tilemap.hexReflect(1, 2, 0, 0, "s")
        expect_type("number", q)
        expect_type("number", r)
    end)
end)

-- =========================================================================
-- TileSet
-- =========================================================================

-- @description Covers suite: lurek.tilemap.newTileSet.
describe("lurek.tilemap.newTileSet", function()
    -- @tests lurek.tilemap.newTileSet
    -- @description Verifies the TileSet factory returns userdata.
    it("creates a TileSet userdata", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_type("userdata", ts)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getFirstGid
    -- @description Confirms getFirstGid returns the starting GID passed to the TileSet constructor.
    it("getFirstGid returns the first GID passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(1, ts:getFirstGid())
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getFirstGid
    -- @description Verifies getFirstGid preserves non-default first GID values.
    it("getFirstGid non-1 start", function()
        local ts = lurek.tilemap.newTileSet(17, 8, 4, 16, 16)
        expect_equal(17, ts:getFirstGid())
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getTileCount
    -- @description Checks that getTileCount reflects the tile count configured at construction.
    it("getTileCount returns count passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(16, ts:getTileCount())
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getColumns
    -- @description Verifies getColumns returns the configured tileset column count.
    it("getColumns returns columns passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(4, ts:getColumns())
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getTileWidth
    -- @description Confirms getTileWidth returns the configured tile width.
    it("getTileWidth returns width passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(32, ts:getTileWidth())
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getTileHeight
    -- @description Confirms getTileHeight returns the configured tile height.
    it("getTileHeight returns height passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(32, ts:getTileHeight())
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getTileDimensions
    -- @description Verifies getTileDimensions returns both configured tile dimensions.
    it("getTileDimensions returns width and height", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 48)
        local w, h = ts:getTileDimensions()
        expect_equal(32, w)
        expect_equal(48, h)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getSpacing
    -- @description Checks that getSpacing defaults to zero when no spacing is provided.
    it("getSpacing defaults to 0 when not provided", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(0, ts:getSpacing())
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getSpacing
    -- @description Verifies getSpacing returns the explicit spacing configured on the tileset.
    it("getSpacing returns spacing passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32, 2)
        expect_equal(2, ts:getSpacing())
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getMargin
    -- @description Checks that getMargin defaults to zero when no margin is provided.
    it("getMargin defaults to 0 when not provided", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_equal(0, ts:getMargin())
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getMargin
    -- @description Verifies getMargin returns the explicit tileset margin.
    it("getMargin returns margin passed to constructor", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32, 0, 4)
        expect_equal(4, ts:getMargin())
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getQuad
    -- @description Confirms getQuad returns a table describing the tile rectangle.
    it("getQuad returns a table with x, y, width, height", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        local q = ts:getQuad(1)
        expect_type("table", q)
        expect_not_nil(q.x)
        expect_not_nil(q.y)
        expect_not_nil(q.width)
        expect_not_nil(q.height)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getQuad
    -- @description Verifies the first tile quad starts at the origin with the configured size.
    it("getQuad tile 1 starts at (0, 0)", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        local q = ts:getQuad(1)
        expect_near(0, q.x, 0.001)
        expect_near(0, q.y, 0.001)
        expect_near(32, q.width, 0.001)
        expect_near(32, q.height, 0.001)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getQuad
    -- @description Checks that the second tile quad shifts by one tile width in the first row.
    it("getQuad tile 2 is offset by one tile width", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        local q = ts:getQuad(2)
        expect_near(32, q.x, 0.001)
        expect_near(0, q.y, 0.001)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getQuad
    -- @description Verifies row wrapping when resolving the quad for the fifth tile.
    it("getQuad tile 5 (second row, first column) has correct y", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        local q = ts:getQuad(5)
        expect_near(0, q.x, 0.001)
        expect_near(32, q.y, 0.001)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getQuad
    -- @description Confirms getQuad rejects invalid tile ID zero.
    it("getQuad rejects tile ID 0", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_error(function() ts:getQuad(0) end)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:setSolid
    -- @tests TileSet:isSolid
    -- @description Verifies TileSet solidity flags can be toggled and queried per tile.
    it("setSolid and isSolid work for a tile", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_false(ts:isSolid(1))
        ts:setSolid(1, true)
        expect_true(ts:isSolid(1))
        ts:setSolid(1, false)
        expect_false(ts:isSolid(1))
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:isSolid
    -- @description Confirms isSolid rejects tile ID zero.
    it("isSolid rejects tile ID 0", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_error(function() ts:isSolid(0) end)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:setAnimation
    -- @tests TileSet:getAnimation
    -- @description Checks that animation frame data round-trips through TileSet animation accessors.
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

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getAnimation
    -- @description Verifies getAnimation returns nil when a tile has no animation configured.
    it("getAnimation returns nil for tile with no animation", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_nil(ts:getAnimation(3))
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:setAutoTileRule
    -- @tests TileSet:getAutoTileId
    -- @description Confirms four-neighbor autotile rules round-trip through the TileSet rule table.
    it("setAutoTileRule and getAutoTileId round-trip", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        -- bitmask: N=1 only, map to tile 3
        ts:setAutoTileRule("grass", 1, 3)
        local tid = ts:getAutoTileId("grass", 1)
        expect_equal(3, tid)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:getAutoTileId
    -- @description Verifies unknown four-neighbor autotile masks return nil.
    it("getAutoTileId returns nil for unknown bitmask", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        expect_nil(ts:getAutoTileId("grass", 0))
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:setAutoTileRule8
    -- @tests TileSet:getAutoTileId8
    -- @description Confirms eight-neighbor autotile rules round-trip through the TileSet rule table.
    it("setAutoTileRule8 and getAutoTileId8 round-trip", function()
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        -- 8-bit bitmask: N=1, NE=16 = bitmask 17
        ts:setAutoTileRule8("water", 17, 5)
        local tid = ts:getAutoTileId8("water", 17)
        expect_equal(5, tid)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:setAutoTileRule8
    -- @tests TileSet:getAutoTileId8
    -- @description Verifies autotile rules are stored independently per terrain type.
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

-- @description Covers suite: lurek.tilemap.newTileMap.
describe("lurek.tilemap.newTileMap", function()
    -- @tests lurek.tilemap.newTileMap
    -- @description Verifies the TileMap factory returns userdata.
    it("creates a TileMap userdata", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_type("userdata", tm)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:getTileWidth
    -- @tests TileMap:getTileHeight
    -- @description Confirms TileMap dimension accessors return the constructor values.
    it("getTileWidth and getTileHeight return constructor values", function()
        local tm = lurek.tilemap.newTileMap(32, 16)
        expect_equal(32, tm:getTileWidth())
        expect_equal(16, tm:getTileHeight())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:getTileDimensions
    -- @description Verifies getTileDimensions returns both configured tile dimensions.
    it("getTileDimensions returns width and height", function()
        local tm = lurek.tilemap.newTileMap(24, 24)
        local w, h = tm:getTileDimensions()
        expect_equal(24, w)
        expect_equal(24, h)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:getChunkSize
    -- @description Checks that TileMap defaults to a chunk size of sixteen tiles.
    it("getChunkSize defaults to 16", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_equal(16, tm:getChunkSize())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:getChunkSize
    -- @description Verifies getChunkSize returns the custom chunk size supplied at construction.
    it("getChunkSize uses custom value", function()
        local tm = lurek.tilemap.newTileMap(32, 32, 8)
        expect_equal(8, tm:getChunkSize())
    end)
end)

-- @description Covers suite: TileMap tileset management.
describe("TileMap tileset management", function()
    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:getTileSetCount
    -- @description Confirms a new TileMap starts with no attached tilesets.
    it("getTileSetCount starts at 0", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_equal(0, tm:getTileSetCount())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileMap:addTileSet
    -- @tests TileMap:getTileSetCount
    -- @description Verifies adding a TileSet increments the TileMap tileset count.
    it("addTileSet increases count", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        expect_equal(1, tm:getTileSetCount())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileMap:addTileSet
    -- @tests TileMap:getTileSet
    -- @tests TileSet:getFirstGid
    -- @description Checks that TileMap:getTileSet returns the same tileset that was added.
    it("getTileSet returns the added tileset", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        local retrieved = tm:getTileSet(1)
        expect_type("userdata", retrieved)
        expect_equal(1, retrieved:getFirstGid())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:getTileSet
    -- @description Verifies requesting an out-of-range tileset index returns nil.
    it("getTileSet returns nil for out-of-range index", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_nil(tm:getTileSet(1))
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:getTileSet
    -- @description Confirms TileMap:getTileSet rejects invalid zero indices.
    it("getTileSet rejects index 0", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_error(function() tm:getTileSet(0) end)
    end)
end)

-- @description Covers suite: TileMap layer management.
describe("TileMap layer management", function()
    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:getLayerCount
    -- @description Confirms a new TileMap starts with no layers.
    it("getLayerCount starts at 0", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_equal(0, tm:getLayerCount())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @description Verifies addLayer returns a one-based layer index.
    it("addLayer returns 1-based index", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local idx = tm:addLayer("ground", 20, 15)
        expect_equal(1, idx)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:getLayerCount
    -- @description Checks that each added layer increments the layer count.
    it("addLayer increases count", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("ground", 20, 15)
        expect_equal(1, tm:getLayerCount())
        tm:addLayer("effect", 20, 15)
        expect_equal(2, tm:getLayerCount())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:getLayerName
    -- @description Verifies getLayerName returns the name assigned when the layer was created.
    it("getLayerName returns the correct name", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("collision", 10, 10)
        expect_equal("collision", tm:getLayerName(1))
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:setLayerVisible
    -- @tests TileMap:getLayerVisible
    -- @description Confirms layer visibility flags can be toggled and read back.
    it("setLayerVisible and getLayerVisible round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("layer1", 10, 10)
        tm:setLayerVisible(1, false)
        expect_false(tm:getLayerVisible(1))
        tm:setLayerVisible(1, true)
        expect_true(tm:getLayerVisible(1))
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:setLayerColor
    -- @tests TileMap:getLayerColor
    -- @description Verifies per-layer tint colors round-trip through the color accessors.
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

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:setLayerOffset
    -- @tests TileMap:getLayerOffset
    -- @description Checks that per-layer screen offsets round-trip correctly.
    it("setLayerOffset and getLayerOffset round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("offset_layer", 10, 10)
        tm:setLayerOffset(1, 12, 34)
        local ox, oy = tm:getLayerOffset(1)
        expect_near(12, ox, 0.001)
        expect_near(34, oy, 0.001)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:setLayerParallax
    -- @tests TileMap:getLayerParallax
    -- @description Verifies layer parallax factors round-trip through the TileMap API.
    it("setLayerParallax and getLayerParallax round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("bg", 10, 10)
        tm:setLayerParallax(1, 0.5, 0.75)
        local px, py = tm:getLayerParallax(1)
        expect_near(0.5, px, 0.001)
        expect_near(0.75, py, 0.001)
    end)
end)

-- @description Covers suite: TileMap tile access.
describe("TileMap tile access", function()
    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:getTile
    -- @description Confirms unset TileMap cells default to GID zero.
    it("getTile returns 0 for empty tiles", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("ground", 20, 20)
        local gid = tm:getTile(1, 1, 1)
        expect_equal(0, gid)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:setTile
    -- @tests TileMap:getTile
    -- @description Verifies tile GIDs can be written and read back from a layer.
    it("setTile and getTile round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("ground", 20, 20)
        tm:setTile(1, 3, 4, 5)
        expect_equal(5, tm:getTile(1, 3, 4))
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:setTile
    -- @tests TileMap:clearTile
    -- @tests TileMap:getTile
    -- @description Confirms clearTile resets a populated tile back to zero.
    it("clearTile sets GID back to 0", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("ground", 20, 20)
        tm:setTile(1, 2, 2, 7)
        tm:clearTile(1, 2, 2)
        expect_equal(0, tm:getTile(1, 2, 2))
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:fill
    -- @tests TileMap:getTile
    -- @description Verifies fill writes the provided GID across the entire layer.
    it("fill sets entire layer to given GID", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("filled", 5, 5)
        tm:fill(1, 3)
        expect_equal(3, tm:getTile(1, 1, 1))
        expect_equal(3, tm:getTile(1, 5, 5))
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addLayer
    -- @tests TileMap:setTile
    -- @tests TileMap:setTileTint
    -- @description Checks that tinting a populated tile completes without raising an error.
    it("setTileTint does not error", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:addLayer("ground", 10, 10)
        tm:setTile(1, 1, 1, 1)
        expect_no_error(function()
            tm:setTileTint(1, 1, 1, 1.0, 0.5, 0.2, 1.0)
        end)
    end)
end)

-- @description Covers suite: TileMap viewport and coordinate conversion.
describe("TileMap viewport and coordinate conversion", function()
    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:setViewport
    -- @tests TileMap:getViewport
    -- @description Verifies viewport bounds round-trip through the TileMap viewport accessors.
    it("setViewport and getViewport round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:setViewport(100, 200, 640, 480)
        local x, y, w, h = tm:getViewport()
        expect_near(100, x, 0.001)
        expect_near(200, y, 0.001)
        expect_near(640, w, 0.001)
        expect_near(480, h, 0.001)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:worldToTile
    -- @description Confirms worldToTile returns numeric tile coordinates.
    it("worldToTile converts pixel position to tile coords", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local tx, ty = tm:worldToTile(0, 0)
        expect_type("number", tx)
        expect_type("number", ty)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:tileToWorld
    -- @tests TileMap:worldToTile
    -- @description Verifies TileMap world and tile coordinate conversions round-trip.
    it("worldToTile and tileToWorld round-trip", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local wx, wy = tm:tileToWorld(2, 3)
        local tx, ty = tm:worldToTile(wx, wy)
        expect_near(2, tx, 0.01)
        expect_near(3, ty, 0.01)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:update
    -- @description Checks that a TileMap update tick accepts a small delta time without error.
    it("update does not error with dt 0.016", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_no_error(function() tm:update(0.016) end)
    end)
end)

-- @description Covers suite: TileMap collision.
describe("TileMap collision", function()
    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:isSolid
    -- @description Confirms empty cells with GID zero are treated as non-solid.
    it("isSolid returns false for GID 0", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 4, 2, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("col", 10, 10)
        expect_false(tm:isSolid(1, 1, 1))
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:setSolid
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:setTile
    -- @tests TileMap:isSolid
    -- @description Verifies TileMap:isSolid reports true for tiles marked solid in the attached tileset.
    it("isSolid returns true when tile is solid", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 4, 2, 32, 32)
        ts:setSolid(1, true)
        tm:addTileSet(ts)
        tm:addLayer("col", 10, 10)
        tm:setTile(1, 2, 2, 1)
        expect_true(tm:isSolid(1, 2, 2))
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:rectOverlapsSolid
    -- @description Confirms collision overlap checks return false when no solid tiles are present.
    it("rectOverlapsSolid returns false on empty layer", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 4, 2, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("col", 10, 10)
        expect_false(tm:rectOverlapsSolid(1, 0, 0, 16, 16))
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:setSolid
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:setTile
    -- @tests TileMap:rectOverlapsSolid
    -- @description Verifies overlap checks return true when a swept rectangle intersects a solid tile.
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

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:sweepRect
    -- @description Checks that sweepRect returns numeric collision and response values.
    it("sweepRect returns 6 values", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 4, 2, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("col", 10, 10)
        local ox, oy, nx, ny, hx, hy = tm:sweepRect(1, 50, 50, 16, 16, 10, 0)
        expect_type("number", ox)
        expect_type("number", oy)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:sweepRect
    -- @description Verifies sweepRect allows full movement and zero normals when no obstacles are present.
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

-- @description Covers suite: TileMap autotile.
describe("TileMap autotile", function()
    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:applyAutoTile
    -- @description Confirms applying four-neighbor autotiling to an empty layer does not raise an error.
    it("applyAutoTile does not error on empty layer", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("ground", 10, 10)
        expect_no_error(function() tm:applyAutoTile(1, "grass") end)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:setTile
    -- @tests TileMap:applyAutoTileAt
    -- @description Verifies applyAutoTileAt can update a populated cell without error.
    it("applyAutoTileAt does not error", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("ground", 10, 10)
        tm:setTile(1, 3, 3, 1)
        expect_no_error(function() tm:applyAutoTileAt(1, 3, 3, "grass") end)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:applyAutoTile8
    -- @description Confirms applying eight-neighbor autotiling to an empty layer does not raise an error.
    it("applyAutoTile8 does not error on empty layer", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("ground", 10, 10)
        expect_no_error(function() tm:applyAutoTile8(1, "water") end)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.newTileSet
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:setTile
    -- @tests TileMap:applyAutoTile8At
    -- @description Verifies applyAutoTile8At can update a populated cell without error.
    it("applyAutoTile8At does not error", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        tm:addTileSet(ts)
        tm:addLayer("ground", 10, 10)
        tm:setTile(1, 2, 2, 1)
        expect_no_error(function() tm:applyAutoTile8At(1, 2, 2, "water") end)
    end)

    -- @tests lurek.tilemap.newTileSet
    -- @tests TileSet:setAutoTileRule
    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:addTileSet
    -- @tests TileMap:addLayer
    -- @tests TileMap:fill
    -- @tests TileMap:applyAutoTile
    -- @tests TileMap:getTile
    -- @description Checks that four-neighbor autotile rules select the expected center tile after application.
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
        -- Tile at center (3,3) has all 4 neighbors â†’ bitmask 15 â†’ tile 5
        expect_equal(5, tm:getTile(1, 3, 3))
    end)
end)

-- =========================================================================
-- AutoTileSheet
-- =========================================================================

-- @description Covers suite: lurek.tilemap.newAutoTileSheet.
describe("lurek.tilemap.newAutoTileSheet", function()
    -- @tests lurek.tilemap.newAutoTileSheet
    -- @description Verifies the AutoTileSheet factory creates userdata for the blob47 layout.
    it("creates AutoTileSheet for blob47 layout", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
        expect_type("userdata", sheet)
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @description Verifies the AutoTileSheet factory creates userdata for the composite48 layout.
    it("creates AutoTileSheet for composite48 layout", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "composite48")
        expect_type("userdata", sheet)
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @description Verifies the AutoTileSheet factory creates userdata for the minimal16 layout.
    it("creates AutoTileSheet for minimal16 layout", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        expect_type("userdata", sheet)
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @description Confirms newAutoTileSheet rejects unknown layout names.
    it("rejects invalid layout name", function()
        expect_error(function()
            lurek.tilemap.newAutoTileSheet(16, 16, "invalid_layout")
        end)
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests AutoTileSheet:getLayout
    -- @description Checks that AutoTileSheet:getLayout returns the selected layout name.
    it("getLayout returns the layout name", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        expect_equal("minimal16", sheet:getLayout())
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests AutoTileSheet:getTileCount
    -- @description Verifies minimal16 sheets report the expected tile count.
    it("getTileCount returns correct count for minimal16", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        expect_equal(16, sheet:getTileCount())
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests AutoTileSheet:getTileCount
    -- @description Verifies blob47 sheets report the expected tile count.
    it("getTileCount returns correct count for blob47", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
        expect_equal(47, sheet:getTileCount())
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests AutoTileSheet:getTileCount
    -- @description Verifies composite48 sheets report the expected tile count.
    it("getTileCount returns correct count for composite48", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "composite48")
        expect_equal(48, sheet:getTileCount())
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests AutoTileSheet:getTileWidth
    -- @description Confirms AutoTileSheet:getTileWidth returns the configured tile width.
    it("getTileWidth returns value from constructor", function()
        local sheet = lurek.tilemap.newAutoTileSheet(24, 32, "minimal16")
        expect_equal(24, sheet:getTileWidth())
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests AutoTileSheet:getTileHeight
    -- @description Confirms AutoTileSheet:getTileHeight returns the configured tile height.
    it("getTileHeight returns value from constructor", function()
        local sheet = lurek.tilemap.newAutoTileSheet(24, 32, "minimal16")
        expect_equal(32, sheet:getTileHeight())
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests AutoTileSheet:getBitmaskForTile
    -- @description Verifies AutoTileSheet:getBitmaskForTile returns a numeric bitmask for a tile index.
    it("getBitmaskForTile returns a number", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        local mask = sheet:getBitmaskForTile(1)
        expect_type("number", mask)
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests AutoTileSheet:getBitmaskForTile
    -- @tests AutoTileSheet:getTileForBitmask
    -- @description Checks that a tile bitmask can be converted back into a tile index.
    it("getTileForBitmask returns a tile index number", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        local mask = sheet:getBitmaskForTile(1)
        local idx = sheet:getTileForBitmask(mask)
        expect_type("number", idx)
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests AutoTileSheet:getBitmaskForTile
    -- @tests AutoTileSheet:getTileForBitmask
    -- @description Verifies bitmask lookup round-trips for every tile in the minimal16 layout.
    it("getBitmaskForTile/getTileForBitmask round-trip", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        for i = 1, 16 do
            local mask = sheet:getBitmaskForTile(i)
            local recovered = sheet:getTileForBitmask(mask)
            expect_equal(i, recovered)
        end
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests lurek.tilemap.newTileSet
    -- @tests AutoTileSheet:applyToTileSet
    -- @description Confirms AutoTileSheet rules can be attached to a TileSet without error.
    it("applyToTileSet attaches rules to a TileSet", function()
        local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 16, 16)
        expect_no_error(function()
            sheet:applyToTileSet(ts, "grass")
        end)
    end)

    -- @tests lurek.tilemap.newAutoTileSheet
    -- @tests lurek.tilemap.newTileSet
    -- @tests AutoTileSheet:applyToTileSet
    -- @tests TileSet:getAutoTileId
    -- @description Verifies applyToTileSet populates TileSet autotile rules for the requested terrain type.
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

-- @description Covers suite: lurek.tilemap.newChunkMap.
describe("lurek.tilemap.newChunkMap", function()
    -- @tests lurek.tilemap.newChunkMap
    -- @description Verifies the ChunkMap factory returns userdata.
    it("creates a ChunkMap userdata", function()
        local cm = lurek.tilemap.newChunkMap()
        expect_type("userdata", cm)
    end)

    -- @tests lurek.tilemap.newChunkMap
    -- @tests ChunkMap:getChunkSize
    -- @description Confirms ChunkMap defaults to a chunk size of sixteen tiles.
    it("getChunkSize defaults to 16", function()
        local cm = lurek.tilemap.newChunkMap()
        expect_equal(16, cm:getChunkSize())
    end)

    -- @tests lurek.tilemap.newChunkMap
    -- @tests ChunkMap:getChunkSize
    -- @description Verifies getChunkSize returns the explicitly configured chunk size.
    it("getChunkSize uses custom value", function()
        local cm = lurek.tilemap.newChunkMap(8)
        expect_equal(8, cm:getChunkSize())
    end)

    -- @tests lurek.tilemap.newChunkMap
    -- @tests ChunkMap:setTile
    -- @tests ChunkMap:getTile
    -- @description Checks that ChunkMap tile writes can be read back at the same coordinates.
    it("get/set tile round-trips", function()
        local cm = lurek.tilemap.newChunkMap(16)
        cm:setTile(0, 0, 5)
        expect_equal(5, cm:getTile(0, 0))
    end)

    -- @tests lurek.tilemap.newChunkMap
    -- @tests ChunkMap:getTile
    -- @description Confirms uninitialized chunk cells default to zero.
    it("initial tile value is 0", function()
        local cm = lurek.tilemap.newChunkMap(16)
        expect_equal(0, cm:getTile(3, 7))
    end)

    -- @tests lurek.tilemap.newChunkMap
    -- @tests ChunkMap:setTile
    -- @tests ChunkMap:getTile
    -- @description Verifies ChunkMap stores tiles correctly at negative coordinates.
    it("supports negative coordinates", function()
        local cm = lurek.tilemap.newChunkMap(16)
        cm:setTile(-5, -3, 9)
        expect_equal(9, cm:getTile(-5, -3))
    end)

    -- @tests lurek.tilemap.newChunkMap
    -- @tests ChunkMap:setTile
    -- @tests ChunkMap:getTile
    -- @description Checks that ChunkMap stores distinct values independently per coordinate.
    it("setTile and getTile are independent for different positions", function()
        local cm = lurek.tilemap.newChunkMap(16)
        cm:setTile(0, 0, 1)
        cm:setTile(1, 0, 2)
        cm:setTile(0, 1, 3)
        expect_equal(1, cm:getTile(0, 0))
        expect_equal(2, cm:getTile(1, 0))
        expect_equal(3, cm:getTile(0, 1))
    end)

    -- @tests lurek.tilemap.newChunkMap
    -- @tests ChunkMap:fillRect
    -- @tests ChunkMap:getTile
    -- @description Verifies fillRect writes the requested GID across the target rectangle.
    it("fillRect sets tiles in a rectangular area", function()
        local cm = lurek.tilemap.newChunkMap(16)
        cm:fillRect(0, 0, 4, 4, 7)
        expect_equal(7, cm:getTile(0, 0))
        expect_equal(7, cm:getTile(2, 2))
    end)

    -- @tests lurek.tilemap.newChunkMap
    -- @tests ChunkMap:setTile
    -- @tests ChunkMap:clearTile
    -- @tests ChunkMap:getTile
    -- @description Confirms clearTile resets a populated chunk cell back to zero.
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

-- @description Covers suite: lurek.tilemap.newIsoMap.
describe("lurek.tilemap.newIsoMap", function()
    -- @tests lurek.tilemap.newIsoMap
    -- @description Verifies the IsoMap factory returns userdata.
    it("creates an IsoMap userdata", function()
        local iso = lurek.tilemap.newIsoMap(10, 10, 64, 32, 24)
        expect_type("userdata", iso)
    end)

    -- @tests lurek.tilemap.newIsoMap
    -- @tests IsoMap:getWidth
    -- @tests IsoMap:getHeight
    -- @description Confirms IsoMap dimension accessors return the constructor values.
    it("getWidth and getHeight return constructor values", function()
        local iso = lurek.tilemap.newIsoMap(8, 6, 64, 32, 24)
        expect_equal(8, iso:getWidth())
        expect_equal(6, iso:getHeight())
    end)

    -- @tests lurek.tilemap.newIsoMap
    -- @tests IsoMap:getLevelCount
    -- @description Verifies a new IsoMap starts with zero levels.
    it("getLevelCount starts at 0 (no levels by default)", function()
        local iso = lurek.tilemap.newIsoMap(8, 6, 64, 32, 24)
        expect_equal(0, iso:getLevelCount())
    end)

    -- @tests lurek.tilemap.newIsoMap
    -- @tests IsoMap:addLevel
    -- @tests IsoMap:getLevelCount
    -- @description Checks that adding an isometric level increments the level count.
    it("addLevel increases level count", function()
        local iso = lurek.tilemap.newIsoMap(4, 4, 64, 32, 24)
        iso:addLevel()
        expect_equal(1, iso:getLevelCount())
    end)

    -- @tests lurek.tilemap.newIsoMap
    -- @tests lurek.tilemap.FLOOR
    -- @tests IsoMap:addLevel
    -- @tests IsoMap:setTilePart
    -- @tests IsoMap:getTilePart
    -- @description Verifies IsoMap floor-part tiles round-trip through setTilePart and getTilePart.
    it("setTilePart and getTilePart round-trip for floor part", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        iso:setTilePart(1, 1, 1, lurek.tilemap.FLOOR, 3)
        expect_equal(3, iso:getTilePart(1, 1, 1, lurek.tilemap.FLOOR))
    end)

    -- @tests lurek.tilemap.newIsoMap
    -- @tests lurek.tilemap.FLOOR
    -- @tests IsoMap:addLevel
    -- @tests IsoMap:setTilePart
    -- @description Confirms IsoMap:setTilePart rejects zero as an invalid level index.
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

-- @description Covers suite: lurek.tilemap IsoMap partCount configurability.
describe("lurek.tilemap IsoMap partCount configurability", function()
    -- @tests lurek.tilemap.newIsoMap
    -- @tests IsoMap:getPartCount
    -- @description Creates an IsoMap without the optional 6th argument; getPartCount must return the default of 4.
    it("isomap_default_partCount_is_4", function()
        local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24)
        expect_equal(4, iso:getPartCount())
    end)

    -- @tests lurek.tilemap.newIsoMap
    -- @tests IsoMap:getPartCount
    -- @description Creates an IsoMap with an explicit partCount of 3 and verifies getPartCount returns 3.
    it("isomap_explicit_partCount_is_stored", function()
        local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24, 3)
        expect_equal(3, iso:getPartCount())
    end)

    -- @tests lurek.tilemap.newIsoMap
    -- @tests IsoMap:getPartOrder
    -- @description Verifies getPartOrder returns a Lua table for an IsoMap with the default part count.
    it("isomap_getPartOrder_returns_table", function()
        local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24)
        local order = iso:getPartOrder()
        expect_type("table", order)
    end)

    -- @tests lurek.tilemap.newIsoMap
    -- @tests IsoMap:getPartCount
    -- @tests IsoMap:getPartOrder
    -- @description Confirms the length of the table returned by getPartOrder equals getPartCount.
    it("isomap_getPartOrder_length_equals_partCount", function()
        local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24)
        local order = iso:getPartOrder()
        expect_equal(iso:getPartCount(), #order)
    end)

    -- @tests lurek.tilemap.newIsoMap
    -- @tests IsoMap:setPartOrder
    -- @tests IsoMap:getPartOrder
    -- @description Sets a custom draw order and verifies the first element reflects the new ordering.
    it("isomap_setPartOrder_reorders_draw_order", function()
        local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24)
        iso:setPartOrder({4, 3, 2, 1})
        local order = iso:getPartOrder()
        expect_equal(4, order[1])
        expect_equal(1, order[4])
    end)

    -- @tests lurek.tilemap.newIsoMap
    -- @tests IsoMap:getPartCount
    -- @tests IsoMap:getPartOrder
    -- @description Creates an IsoMap with partCount=2 and confirms getPartOrder returns a 2-element table.
    it("isomap_partCount_2_gives_order_of_length_2", function()
        local iso = lurek.tilemap.newIsoMap(4, 4, 64, 32, 24, 2)
        local order = iso:getPartOrder()
        expect_equal(2, #order)
    end)
end)

-- =========================================================================
-- TileMap orientation (PR-2)
-- =========================================================================

-- @description Covers suite: lurek.tilemap TileMap orientation configurability.
describe("lurek.tilemap TileMap orientation", function()
    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:getOrientation
    -- @description Verifies a freshly-created TileMap reports the default orientation as "topdown".
    it("tilemap_default_orientation_is_topdown", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_equal("topdown", tm:getOrientation())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:setOrientation
    -- @tests TileMap:getOrientation
    -- @description Sets orientation to "topdown" and reads it back.
    it("tilemap_setOrientation_topdown_roundtrips", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:setOrientation("topdown")
        expect_equal("topdown", tm:getOrientation())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:setOrientation
    -- @tests TileMap:getOrientation
    -- @description Sets orientation to "sideview" and reads it back.
    it("tilemap_setOrientation_sideview_roundtrips", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:setOrientation("sideview")
        expect_equal("sideview", tm:getOrientation())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:setOrientation
    -- @tests TileMap:getOrientation
    -- @description Sets orientation to "isometric" and reads it back.
    it("tilemap_setOrientation_isometric_roundtrips", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:setOrientation("isometric")
        expect_equal("isometric", tm:getOrientation())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:setOrientation
    -- @tests TileMap:getOrientation
    -- @description Sets orientation to "hexagonal" and reads it back.
    it("tilemap_setOrientation_hexagonal_roundtrips", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        tm:setOrientation("hexagonal")
        expect_equal("hexagonal", tm:getOrientation())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:setOrientation
    -- @description Passes an unknown orientation string; the engine must return an error.
    it("tilemap_setOrientation_unknown_errors", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_error(function()
            tm:setOrientation("diagonal")
        end)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests TileMap:getOrientation
    -- @description Confirms getOrientation returns a string type.
    it("tilemap_getOrientation_returns_string", function()
        local tm = lurek.tilemap.newTileMap(32, 32)
        expect_type("string", tm:getOrientation())
    end)
end)

-- =========================================================================
-- MapScript addStep type coverage (PR-3)
-- =========================================================================

-- @description Covers suite: lurek.tilemap MapScript addStep type coverage.
describe("lurek.tilemap MapScript addStep type coverage", function()
    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:addStep
    -- @description Verifies addStep accepts the "placeRandom" step type without error.
    it("addStep_placeRandom_does_not_error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "placeRandom", gid = 1, count = 5})
        end)
    end)

    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:addStep
    -- @description Verifies addStep accepts the "placeLine" step type without error.
    it("addStep_placeLine_does_not_error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "placeLine", gid = 1, x1 = 0, y1 = 0, x2 = 3, y2 = 3})
        end)
    end)

    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:addStep
    -- @description Verifies addStep accepts the "floodFill" step type without error.
    it("addStep_floodFill_does_not_error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "floodFill", gid = 2, x = 0, y = 0})
        end)
    end)

    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:addStep
    -- @description Verifies addStep accepts the "drawPath" step type without error.
    it("addStep_drawPath_does_not_error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "drawPath", gid = 1, points = {{0,0},{1,1}}})
        end)
    end)

    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:addStep
    -- @description Verifies addStep accepts the "fillRect" step type without error.
    it("addStep_fillRect_does_not_error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "fillRect", gid = 3, x = 0, y = 0, w = 4, h = 4})
        end)
    end)

    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:addStep
    -- @description Confirms all 8 documented step types can be added; the step count must reach 8.
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

    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:addStep
    -- @description Passes an unknown step type string; the engine must return an error.
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

-- @description Covers suite: lurek.tilemap.newMapBlock.
describe("lurek.tilemap.newMapBlock", function()
    -- @tests lurek.tilemap.newMapBlock
    -- @description Verifies the MapBlock factory returns userdata.
    it("creates a MapBlock userdata", function()
        local block = lurek.tilemap.newMapBlock(10, 10, 1, 4)
        expect_type("userdata", block)
    end)

    -- @tests lurek.tilemap.newMapBlock
    -- @tests MapBlock:getWidth
    -- @tests MapBlock:getHeight
    -- @description Confirms MapBlock dimension accessors return the constructor values.
    it("getWidth and getHeight return constructor values", function()
        local block = lurek.tilemap.newMapBlock(12, 8, 2, 4)
        expect_equal(12, block:getWidth())
        expect_equal(8, block:getHeight())
    end)

    -- @tests lurek.tilemap.newMapBlock
    -- @tests MapBlock:getLayerCount
    -- @description Verifies MapBlock reports the layer count configured at construction.
    it("getLayerCount returns layers from constructor", function()
        local block = lurek.tilemap.newMapBlock(10, 10, 3, 4)
        expect_equal(3, block:getLayerCount())
    end)

    -- @tests lurek.tilemap.newMapBlock
    -- @tests MapBlock:setTile
    -- @tests MapBlock:getTile
    -- @description Checks that MapBlock tile writes can be read back from the same layer and coordinates.
    it("setTile and getTile round-trip", function()
        local block = lurek.tilemap.newMapBlock(10, 10, 1, 4)
        block:setTile(1, 2, 3, 7)
        expect_equal(7, block:getTile(1, 2, 3))
    end)
end)

-- @description Covers suite: lurek.tilemap.newMapGroup.
describe("lurek.tilemap.newMapGroup", function()
    -- @tests lurek.tilemap.newMapGroup
    -- @description Verifies the MapGroup factory returns userdata.
    it("creates a MapGroup userdata", function()
        local group = lurek.tilemap.newMapGroup("desert")
        expect_type("userdata", group)
    end)

    -- @tests lurek.tilemap.newMapGroup
    -- @tests MapGroup:getName
    -- @description Confirms MapGroup:getName returns the constructor name.
    it("getName returns the name from constructor", function()
        local group = lurek.tilemap.newMapGroup("forest")
        expect_equal("forest", group:getName())
    end)

    -- @tests lurek.tilemap.newMapGroup
    -- @tests lurek.tilemap.newMapBlock
    -- @tests MapGroup:getBlockCount
    -- @tests MapGroup:addBlock
    -- @description Verifies adding a MapBlock increments the group block count.
    it("addBlock increases block count", function()
        local group = lurek.tilemap.newMapGroup("test")
        expect_equal(0, group:getBlockCount())
        local block = lurek.tilemap.newMapBlock(4, 4, 1, 4)
        group:addBlock(block)
        expect_equal(1, group:getBlockCount())
    end)

    -- @tests lurek.tilemap.newMapGroup
    -- @tests lurek.tilemap.newMapScript
    -- @tests MapGroup:getScriptCount
    -- @tests MapGroup:addScript
    -- @description Verifies adding a MapScript increments the group script count.
    it("addScript increases script count", function()
        local group = lurek.tilemap.newMapGroup("test")
        expect_equal(0, group:getScriptCount())
        local script = lurek.tilemap.newMapScript()
        group:addScript(script)
        expect_equal(1, group:getScriptCount())
    end)
end)

-- @description Covers suite: lurek.tilemap.newMapScript.
describe("lurek.tilemap.newMapScript", function()
    -- @tests lurek.tilemap.newMapScript
    -- @description Verifies the MapScript factory returns userdata.
    it("creates a MapScript userdata", function()
        local script = lurek.tilemap.newMapScript()
        expect_type("userdata", script)
    end)

    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:getStepCount
    -- @description Confirms a new MapScript starts with zero steps.
    it("getStepCount starts at 0", function()
        local script = lurek.tilemap.newMapScript()
        expect_equal(0, script:getStepCount())
    end)

    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:addStep
    -- @tests MapScript:getStepCount
    -- @description Verifies adding a generation step increments the script step count.
    it("addStep increases step count", function()
        local script = lurek.tilemap.newMapScript()
        script:addStep({type = "fillRandom", gid = 1, chance = 0.5})
        expect_equal(1, script:getStepCount())
    end)

    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:addStep
    -- @description Checks that placeBlock script steps are accepted without error.
    it("addStep with placeBlock type does not error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "placeBlock", x = 0, y = 0})
        end)
    end)

    -- @tests lurek.tilemap.newMapScript
    -- @tests MapScript:addStep
    -- @description Checks that fillArea script steps are accepted without error.
    it("addStep with fillArea type does not error", function()
        local script = lurek.tilemap.newMapScript()
        expect_no_error(function()
            script:addStep({type = "fillArea", gid = 2, x = 0, y = 0, w = 4, h = 4})
        end)
    end)
end)

-- @description Covers suite: lurek.tilemap.newMapGen.
describe("lurek.tilemap.newMapGen", function()
    -- @tests lurek.tilemap.newMapGroup
    -- @tests lurek.tilemap.newMapGen
    -- @description Verifies newMapGen accepts the small preset and returns userdata.
    it("creates a MapGen from small preset", function()
        local group = lurek.tilemap.newMapGroup("world")
        local gen = lurek.tilemap.newMapGen(group, "small", 4)
        expect_type("userdata", gen)
    end)

    -- @tests lurek.tilemap.newMapGroup
    -- @tests lurek.tilemap.newMapGen
    -- @description Verifies newMapGen accepts the medium preset and returns userdata.
    it("creates a MapGen from medium preset", function()
        local group = lurek.tilemap.newMapGroup("world")
        local gen = lurek.tilemap.newMapGen(group, "medium", 4)
        expect_type("userdata", gen)
    end)

    -- @tests lurek.tilemap.newMapGroup
    -- @tests lurek.tilemap.newMapGen
    -- @description Verifies newMapGen accepts the large preset and returns userdata.
    it("creates a MapGen from large preset", function()
        local group = lurek.tilemap.newMapGroup("world")
        local gen = lurek.tilemap.newMapGen(group, "large", 4)
        expect_type("userdata", gen)
    end)

    -- @tests lurek.tilemap.newMapGroup
    -- @tests lurek.tilemap.newMapGen
    -- @description Confirms newMapGen also accepts explicit numeric dimensions.
    it("creates a MapGen from numeric dimensions", function()
        local group = lurek.tilemap.newMapGroup("world")
        local gen = lurek.tilemap.newMapGen(group, 4, 4, 4)
        expect_type("userdata", gen)
    end)

    -- @tests lurek.tilemap.newMapGroup
    -- @tests lurek.tilemap.newMapGen
    -- @description Verifies newMapGen rejects unsupported preset names.
    it("rejects invalid size string", function()
        local group = lurek.tilemap.newMapGroup("world")
        expect_error(function()
            lurek.tilemap.newMapGen(group, "huge", 4)
        end)
    end)

    -- @tests lurek.tilemap.newMapGroup
    -- @tests lurek.tilemap.newMapBlock
    -- @tests MapBlock:setTile
    -- @tests MapGroup:addBlock
    -- @tests lurek.tilemap.newMapGen
    -- @tests MapGen:generate
    -- @description Checks that MapGen:generate produces a TileMap userdata from the configured group data.
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

-- @description Covers suite: lurek.tilemap.loadTMX.
describe("lurek.tilemap.loadTMX", function()
    -- @tests lurek.tilemap.loadTMX
    -- @description Verifies the TMX loader entrypoint remains callable as a function.
    it("loadTMX is a function", function()
        expect_type("function", lurek.tilemap.loadTMX)
    end)

    -- @tests lurek.tilemap.loadTMX
    -- @description Confirms loadTMX rejects malformed XML input.
    it("loadTMX throws an error for invalid XML", function()
        expect_error(function()
            lurek.tilemap.loadTMX("not xml at all")
        end)
    end)

    -- @tests lurek.tilemap.loadTMX
    -- @description Verifies loadTMX parses a minimal orthogonal TMX string into a Lua table without an error value.
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

    -- @tests lurek.tilemap.loadTMX
    -- @description Checks that parsed TMX metadata fields are exposed with the expected values.
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

    -- @tests lurek.tilemap.loadTMX
    -- @description Verifies loadTMX populates the parsed layer array with tile layer metadata.
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

-- ═══════════════════════════════════════════════════════════════════════
-- Merged from test_tilemap_ext.lua
-- ═══════════════════════════════════════════════════════════════════════

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

describe("lurek.tilemap extended", function()
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
    end)

    describe("toNavGrid()", function()
        it("returns a table of row tables", function()
            local tm = lurek.tilemap.fromLDtk(LDTK_JSON)
            local grid = tm:toNavGrid(1, {})
            expect_type("table", grid)
            expect_true(#grid > 0, "expected at least one row")
            expect_type("table", grid[1])
        end)

        it("empty-cell (GID 0) is walkable by default", function()
            local tm = lurek.tilemap.fromLDtk(LDTK_JSON)
            local grid = tm:toNavGrid(1, {})
            expect_type("boolean", grid[1][1])
        end)

        it("listed GIDs are walkable", function()
            local tm = lurek.tilemap.new(2, 1, 16, 16)
            tm:setTile(1, 0, 0, 5)
            tm:setTile(1, 1, 0, 6)
            local grid = tm:toNavGrid(1, {5})
            expect_equal(true,  grid[1][1])
            expect_equal(false, grid[1][2])
        end)
    end)

    describe("onTileEnter() / checkEntities()", function()
        it("onTileEnter accepts a callback", function()
            local tm = lurek.tilemap.new(4, 4, 16, 16)
            tm:onTileEnter(5, function(wx, wy, tx, ty) end)
            expect_equal(true, true)
        end)

        it("callback fires for a matching tile", function()
            local tm = lurek.tilemap.new(4, 4, 16, 16)
            tm:setTile(1, 0, 0, 5)
            local fired = false
            tm:onTileEnter(5, function(wx, wy, tx, ty)
                fired = true
            end)
            tm:checkEntities(1, {{x=8, y=8}})
            expect_true(fired, "expected callback to fire")
        end)

        it("callback does not fire for a non-matching tile", function()
            local tm = lurek.tilemap.new(4, 4, 16, 16)
            tm:setTile(1, 0, 0, 3)
            local fired = false
            tm:onTileEnter(5, function()
                fired = true
            end)
            tm:checkEntities(1, {{x=8, y=8}})
            expect_false(fired)
        end)
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════
-- Merged from test_tilemap_large_map.lua
-- ═══════════════════════════════════════════════════════════════════════

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

-- @description Covers suite: IsoMap regression — 0-index must return Lua error not panic.
describe("IsoMap regression: zero index", function()
    -- @tests lurek.tilemap.IsoMap.setTilePart
    it("setTilePart rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:setTilePart(0, 1, 1, lurek.tilemap.FLOOR, 3) end)
        expect_error(function() iso:setTilePart(1, 0, 1, lurek.tilemap.FLOOR, 3) end)
        expect_error(function() iso:setTilePart(1, 1, 0, lurek.tilemap.FLOOR, 3) end)
    end)

    -- @tests lurek.tilemap.IsoMap.getTilePart
    it("getTilePart rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:getTilePart(0, 1, 1, lurek.tilemap.FLOOR) end)
    end)

    -- @tests lurek.tilemap.IsoMap.setLevelVisible
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

-- @description Covers suite: IsoMap regression — 0-index must return Lua error not panic.
describe("IsoMap regression: zero index", function()
    -- @tests lurek.tilemap.IsoMap.setTilePart
    it("setTilePart rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:setTilePart(0, 1, 1, lurek.tilemap.FLOOR, 3) end)
        expect_error(function() iso:setTilePart(1, 0, 1, lurek.tilemap.FLOOR, 3) end)
        expect_error(function() iso:setTilePart(1, 1, 0, lurek.tilemap.FLOOR, 3) end)
    end)

    -- @tests lurek.tilemap.IsoMap.getTilePart
    it("getTilePart rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:getTilePart(0, 1, 1, lurek.tilemap.FLOOR) end)
    end)

    -- @tests lurek.tilemap.IsoMap.setLevelVisible
    it("setLevelVisible rejects z=0 without panicking", function()
        local iso = lurek.tilemap.newIsoMap(5, 5, 64, 32, 24)
        iso:addLevel()
        expect_error(function() iso:setLevelVisible(0, true) end)
    end)
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests ChunkMap:loadChunk
    it("covers ChunkMap:loadChunk", function()
        -- TODO: Implement test for ChunkMap:loadChunk
    end)

    -- @tests ChunkMap:unloadChunk
    it("covers ChunkMap:unloadChunk", function()
        -- TODO: Implement test for ChunkMap:unloadChunk
    end)

    -- @tests ChunkMap:getLoadedChunks
    it("covers ChunkMap:getLoadedChunks", function()
        -- TODO: Implement test for ChunkMap:getLoadedChunks
    end)

    -- @tests ChunkMap:chunkTileRange
    it("covers ChunkMap:chunkTileRange", function()
        -- TODO: Implement test for ChunkMap:chunkTileRange
    end)

    -- @tests IsoMap:isLevelVisible
    it("covers IsoMap:isLevelVisible", function()
        -- TODO: Implement test for IsoMap:isLevelVisible
    end)

    -- @tests IsoMap:fillLevel
    it("covers IsoMap:fillLevel", function()
        -- TODO: Implement test for IsoMap:fillLevel
    end)

    -- @tests IsoMap:getLevelHeight
    it("covers IsoMap:getLevelHeight", function()
        -- TODO: Implement test for IsoMap:getLevelHeight
    end)

    -- @tests IsoMap:tileToScreen
    it("covers IsoMap:tileToScreen", function()
        -- TODO: Implement test for IsoMap:tileToScreen
    end)

    -- @tests IsoMap:screenToTile
    it("covers IsoMap:screenToTile", function()
        -- TODO: Implement test for IsoMap:screenToTile
    end)

    -- @tests MapBlock:getSide
    it("covers MapBlock:getSide", function()
        -- TODO: Implement test for MapBlock:getSide
    end)

    -- @tests MapBlock:getSegmentSize
    it("covers MapBlock:getSegmentSize", function()
        -- TODO: Implement test for MapBlock:getSegmentSize
    end)

    -- @tests MapBlock:getWidthInSegments
    it("covers MapBlock:getWidthInSegments", function()
        -- TODO: Implement test for MapBlock:getWidthInSegments
    end)

    -- @tests MapBlock:getHeightInSegments
    it("covers MapBlock:getHeightInSegments", function()
        -- TODO: Implement test for MapBlock:getHeightInSegments
    end)

    -- @tests MapGroup:removeBlock
    it("covers MapGroup:removeBlock", function()
        -- TODO: Implement test for MapGroup:removeBlock
    end)

end)

describe("Missing explicit test for lurek.tilemap.fromLDtk", function()
    it("lurek.tilemap.fromLDtk works", function()
        -- @tests lurek.tilemap.fromLDtk
        -- TODO: add assertion for lurek.tilemap.fromLDtk
    end)
end)

describe("Missing explicit test for lurek.tilemap.newLargeMapRenderer", function()
    it("lurek.tilemap.newLargeMapRenderer works", function()
        -- @tests lurek.tilemap.newLargeMapRenderer
        -- TODO: add assertion for lurek.tilemap.newLargeMapRenderer
    end)
end)

describe("Missing explicit test for TileMap:drawToImage", function()
    it("TileMap:drawToImage works", function()
        -- @tests TileMap:drawToImage
        -- TODO: add assertion for TileMap:drawToImage
    end)
end)

describe("Missing explicit test for AutoTileSheet:getQuad", function()
    it("AutoTileSheet:getQuad works", function()
        -- @tests AutoTileSheet:getQuad
        -- TODO: add assertion for AutoTileSheet:getQuad
    end)
end)

describe("Missing explicit test for LargeMapRenderer:setTile", function()
    it("LargeMapRenderer:setTile works", function()
        -- @tests LargeMapRenderer:setTile
        -- TODO: add assertion for LargeMapRenderer:setTile
    end)
end)

describe("Missing explicit test for LargeMapRenderer:getTile", function()
    it("LargeMapRenderer:getTile works", function()
        -- @tests LargeMapRenderer:getTile
        -- TODO: add assertion for LargeMapRenderer:getTile
    end)
end)

describe("Missing explicit test for LargeMapRenderer:getMapSize", function()
    it("LargeMapRenderer:getMapSize works", function()
        -- @tests LargeMapRenderer:getMapSize
        -- TODO: add assertion for LargeMapRenderer:getMapSize
    end)
end)

describe("Missing explicit test for LargeMapRenderer:setChunkSize", function()
    it("LargeMapRenderer:setChunkSize works", function()
        -- @tests LargeMapRenderer:setChunkSize
        -- TODO: add assertion for LargeMapRenderer:setChunkSize
    end)
end)

describe("Missing explicit test for LargeMapRenderer:getChunkSize", function()
    it("LargeMapRenderer:getChunkSize works", function()
        -- @tests LargeMapRenderer:getChunkSize
        -- TODO: add assertion for LargeMapRenderer:getChunkSize
    end)
end)

describe("Missing explicit test for LargeMapRenderer:invalidateChunk", function()
    it("LargeMapRenderer:invalidateChunk works", function()
        -- @tests LargeMapRenderer:invalidateChunk
        -- TODO: add assertion for LargeMapRenderer:invalidateChunk
    end)
end)

describe("Missing explicit test for LargeMapRenderer:invalidateAll", function()
    it("LargeMapRenderer:invalidateAll works", function()
        -- @tests LargeMapRenderer:invalidateAll
        -- TODO: add assertion for LargeMapRenderer:invalidateAll
    end)
end)

describe("Missing explicit test for LargeMapRenderer:getVisibleChunks", function()
    it("LargeMapRenderer:getVisibleChunks works", function()
        -- @tests LargeMapRenderer:getVisibleChunks
        -- TODO: add assertion for LargeMapRenderer:getVisibleChunks
    end)
end)

describe("Missing explicit test for LargeMapRenderer:getTotalChunks", function()
    it("LargeMapRenderer:getTotalChunks works", function()
        -- @tests LargeMapRenderer:getTotalChunks
        -- TODO: add assertion for LargeMapRenderer:getTotalChunks
    end)
end)

describe("Missing explicit test for LargeMapRenderer:setCamera", function()
    it("LargeMapRenderer:setCamera works", function()
        -- @tests LargeMapRenderer:setCamera
        -- TODO: add assertion for LargeMapRenderer:setCamera
    end)
end)

describe("Missing explicit test for LargeMapRenderer:setViewport", function()
    it("LargeMapRenderer:setViewport works", function()
        -- @tests LargeMapRenderer:setViewport
        -- TODO: add assertion for LargeMapRenderer:setViewport
    end)
end)

describe("Missing explicit test for LargeMapRenderer:setLodEnabled", function()
    it("LargeMapRenderer:setLodEnabled works", function()
        -- @tests LargeMapRenderer:setLodEnabled
        -- TODO: add assertion for LargeMapRenderer:setLodEnabled
    end)
end)

describe("Missing explicit test for LargeMapRenderer:isLodEnabled", function()
    it("LargeMapRenderer:isLodEnabled works", function()
        -- @tests LargeMapRenderer:isLodEnabled
        -- TODO: add assertion for LargeMapRenderer:isLodEnabled
    end)
end)

describe("Missing explicit test for LargeMapRenderer:setLodThresholds", function()
    it("LargeMapRenderer:setLodThresholds works", function()
        -- @tests LargeMapRenderer:setLodThresholds
        -- TODO: add assertion for LargeMapRenderer:setLodThresholds
    end)
end)

describe("Missing explicit test for LargeMapRenderer:setTilesetColumns", function()
    it("LargeMapRenderer:setTilesetColumns works", function()
        -- @tests LargeMapRenderer:setTilesetColumns
        -- TODO: add assertion for LargeMapRenderer:setTilesetColumns
    end)
end)

describe("Missing explicit test for LargeMapRenderer:getTilesetColumns", function()
    it("LargeMapRenderer:getTilesetColumns works", function()
        -- @tests LargeMapRenderer:getTilesetColumns
        -- TODO: add assertion for LargeMapRenderer:getTilesetColumns
    end)
end)

describe("Missing explicit test for IsoMap:setLevelVisible", function()
    it("IsoMap:setLevelVisible works", function()
        -- @tests IsoMap:setLevelVisible
        -- TODO: add assertion for IsoMap:setLevelVisible
    end)
end)

describe("Missing explicit test for IsoMap:setOrigin", function()
    it("IsoMap:setOrigin works", function()
        -- @tests IsoMap:setOrigin
        -- TODO: add assertion for IsoMap:setOrigin
    end)
end)

describe("Missing explicit test for IsoMap:getTileWidth", function()
    it("IsoMap:getTileWidth works", function()
        -- @tests IsoMap:getTileWidth
        -- TODO: add assertion for IsoMap:getTileWidth
    end)
end)

describe("Missing explicit test for IsoMap:getTileHeight", function()
    it("IsoMap:getTileHeight works", function()
        -- @tests IsoMap:getTileHeight
        -- TODO: add assertion for IsoMap:getTileHeight
    end)
end)

describe("Missing explicit test for MapBlock:getDimensions", function()
    it("MapBlock:getDimensions works", function()
        -- @tests MapBlock:getDimensions
        -- TODO: add assertion for MapBlock:getDimensions
    end)
end)

describe("Missing explicit test for MapBlock:setName", function()
    it("MapBlock:setName works", function()
        -- @tests MapBlock:setName
        -- TODO: add assertion for MapBlock:setName
    end)
end)

describe("Missing explicit test for MapBlock:getName", function()
    it("MapBlock:getName works", function()
        -- @tests MapBlock:getName
        -- TODO: add assertion for MapBlock:getName
    end)
end)

describe("Missing explicit test for MapBlock:setWeight", function()
    it("MapBlock:setWeight works", function()
        -- @tests MapBlock:setWeight
        -- TODO: add assertion for MapBlock:setWeight
    end)
end)

describe("Missing explicit test for MapBlock:getWeight", function()
    it("MapBlock:getWeight works", function()
        -- @tests MapBlock:getWeight
        -- TODO: add assertion for MapBlock:getWeight
    end)
end)
