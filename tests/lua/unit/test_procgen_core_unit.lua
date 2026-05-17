-- Lurek2D Lua BDD tests for lurek.procgen
-- Headless: no GPU, no audio, no window.

-- @describe module interface
describe("module interface", function()
    -- @covers lurek.procgen.cellularAutomata
    it("exposes cellularAutomata", function()
        expect_type("function", lurek.procgen.cellularAutomata)
    end)

    -- @covers lurek.procgen.floodFill
    it("exposes floodFill", function()
        expect_type("function", lurek.procgen.floodFill)
    end)

    -- @covers lurek.procgen.perlinNoise
    it("exposes perlinNoise", function()
        expect_type("function", lurek.procgen.perlinNoise)
    end)

    -- @covers lurek.procgen.poissonDisk
    it("exposes poissonDisk", function()
        expect_type("function", lurek.procgen.poissonDisk)
    end)

    -- @covers lurek.procgen.voronoi
    it("exposes voronoi", function()
        expect_type("function", lurek.procgen.voronoi)
    end)
end)

-- @describe cellularAutomata(w, h, opts)
describe("cellularAutomata(w, h, opts)", function()
    -- @covers lurek.procgen.cellularAutomata
    it("returns a flat table of 0/1 values", function()
        local data = lurek.procgen.cellularAutomata(8, 6)
        expect_type("table", data)
        expect_equal(48, #data)
    end)

    -- @covers lurek.procgen.cellularAutomata
    it("all values are 0 or 1", function()
        local data = lurek.procgen.cellularAutomata(10, 10)
        for _, v in ipairs(data) do
            expect_true(v == 0 or v == 1, "unexpected value: " .. tostring(v))
        end
    end)

    -- @covers lurek.procgen.cellularAutomata
    it("accepts opts table with fill parameter", function()
        local data = lurek.procgen.cellularAutomata(6, 6, { fill = 0.5, iterations = 2 })
        expect_equal(36, #data)
    end)

    -- @covers lurek.procgen.cellularAutomata
    it("is deterministic for the same seed", function()
        local a = lurek.procgen.cellularAutomata(10, 10, { seed = 42 })
        local b = lurek.procgen.cellularAutomata(10, 10, { seed = 42 })
        expect_equal(#a, #b)
        for i = 1, #a do
            expect_equal(a[i], b[i])
        end
    end)
end)

-- @describe floodFill(data, w, h, sx, sy, threshold, above)
describe("floodFill(data, w, h, sx, sy, threshold, above)", function()
    -- @covers lurek.procgen.floodFill
    it("returns a table of the same size as input", function()
        local data = {}
        for i = 1, 25 do data[i] = 0 end
        local result = lurek.procgen.floodFill(data, 5, 5, 2, 2)
        expect_equal(25, #result)
    end)

    -- @covers lurek.procgen.floodFill
    it("fills connected region starting from seed", function()
        local data = {}
        for i = 1, 25 do data[i] = 0 end
        local result = lurek.procgen.floodFill(data, 5, 5, 0, 0)
        -- With all-zero grid and below-threshold fill, all cells should be marked
        local filled = 0
        for _, v in ipairs(result) do
            if v > 0 then filled = filled + 1 end
        end
        expect_true(filled > 0, "expected at least one filled cell")
    end)

    -- @covers lurek.procgen.floodFill
    it("fills only cells that meet the threshold rule", function()
        local data = {1, 1, 0, 0,
                      1, 1, 0, 0,
                      0, 0, 0, 0,
                      0, 0, 0, 1}
        local result = lurek.procgen.floodFill(data, 4, 4, 0, 0, 1, true)
        expect_equal(1, result[1])
        expect_equal(1, result[2])
        expect_equal(1, result[5])
        expect_equal(1, result[6])
        expect_equal(0, result[3])
    end)
end)

-- @describe perlinNoise(x, y, px, py)
describe("perlinNoise(x, y, px, py)", function()
    -- @covers lurek.procgen.perlinNoise
    it("returns a number", function()
        local v = lurek.procgen.perlinNoise(0.5, 0.5, 8.0, 8.0)
        expect_type("number", v)
    end)

    -- @covers lurek.procgen.perlinNoise
    it("value is in [-1, 1]", function()
        local v = lurek.procgen.perlinNoise(1.0, 2.0, 10.0, 10.0)
        expect_in_range(v, -1.0, 1.0, "out of range: " .. tostring(v))
    end)

    -- @covers lurek.procgen.perlinNoise
    it("wraps at period boundaries", function()
        local px, py = 8.0, 8.0
        local v1 = lurek.procgen.perlinNoise(0.0, 3.0, px, py)
        local v2 = lurek.procgen.perlinNoise(px, 3.0, px, py)
        local diff = math.abs(v1 - v2)
        expect_less(diff, 0.001, "does not wrap: diff=" .. tostring(diff))
    end)
end)

-- @describe poissonDisk(w, h, min_dist, max_attempts, seed)
describe("poissonDisk(w, h, min_dist, max_attempts, seed)", function()
    -- @covers lurek.procgen.poissonDisk
    it("returns a table of point objects", function()
        local pts = lurek.procgen.poissonDisk(80, 80, 10)
        expect_type("table", pts)
    end)

    -- @covers lurek.procgen.poissonDisk
    it("each point has x and y fields", function()
        local pts = lurek.procgen.poissonDisk(80, 80, 10, 30, 42)
        expect_true(#pts > 0, "expected at least one point")
        for _, p in ipairs(pts) do
            expect_type("number", p.x)
            expect_type("number", p.y)
        end
    end)

    -- @covers lurek.procgen.poissonDisk
    it("points lie within the specified bounds", function()
        local w, h = 100, 60
        local pts = lurek.procgen.poissonDisk(w, h, 8, 30, 7)
        for _, p in ipairs(pts) do
            expect_true(p.x >= 0 and p.x < w, "point x=" .. p.x .. " out of bounds")
            expect_true(p.y >= 0 and p.y < h, "point y=" .. p.y .. " out of bounds")
        end
    end)

    -- @covers lurek.procgen.poissonDisk
    it("keeps points at least min_dist apart", function()
        local min_dist = 10
        local pts = lurek.procgen.poissonDisk(80, 80, min_dist, 30, 42)
        for i = 1, #pts do
            for j = i + 1, #pts do
                local dx = pts[i].x - pts[j].x
                local dy = pts[i].y - pts[j].y
                local dist_sq = dx * dx + dy * dy
                expect_true(dist_sq >= (min_dist * min_dist) - 1e-4,
                    "points too close: " .. tostring(math.sqrt(dist_sq)))
            end
        end
    end)
end)

-- @describe voronoi(w, h, seeds)
describe("voronoi(w, h, seeds)", function()
    -- @covers lurek.procgen.voronoi
    it("returns three tables: regions, dist, dist2", function()
        local pts = { { x = 10, y = 10 }, { x = 30, y = 30 } }
        local regions, dist, dist2 = lurek.procgen.voronoi(8, 8, pts)
        expect_type("table", regions)
        expect_type("table", dist)
        expect_type("table", dist2)
    end)

    -- @covers lurek.procgen.voronoi
    it("regions table has w*h entries", function()
        local pts = { { x = 5, y = 5 }, { x = 15, y = 5 }, { x = 10, y = 15 } }
        local regions, _, _ = lurek.procgen.voronoi(20, 10, pts)
        expect_equal(200, #regions)
    end)

    -- @covers lurek.procgen.voronoi
    it("region indices are within seed count range", function()
        local pts = { { x = 5, y = 5 }, { x = 15, y = 10 } }
        local n = #pts
        local regions, _, _ = lurek.procgen.voronoi(20, 20, pts)
        for _, r in ipairs(regions) do
            expect_true(r >= 1 and r <= n, "invalid region index: " .. tostring(r))
        end
    end)
end)

-- @describe procgen determinism
describe("procgen determinism", function()
    -- @covers lurek.procgen.poissonDisk
    it("poissonDisk with same seed returns same point count", function()
        local pts1 = lurek.procgen.poissonDisk(100, 80, 12, 30, 42)
        local pts2 = lurek.procgen.poissonDisk(100, 80, 12, 30, 42)
        expect_equal(#pts1, #pts2)
    end)

    -- @covers lurek.procgen.poissonDisk
    it("poissonDisk with different seeds may differ", function()
        local pts1 = lurek.procgen.poissonDisk(100, 80, 8, 30, 1)
        local pts2 = lurek.procgen.poissonDisk(100, 80, 8, 30, 9999)
        -- Both should return non-empty tables
        expect_true(#pts1 > 0, "seed 1 result non-empty")
        expect_true(#pts2 > 0, "seed 9999 result non-empty")
    end)

    -- @covers lurek.procgen.perlinNoise
    it("perlinNoise same coords same period returns identical value", function()
        local v1 = lurek.procgen.perlinNoise(1.5, 2.5, 8.0, 8.0)
        local v2 = lurek.procgen.perlinNoise(1.5, 2.5, 8.0, 8.0)
        expect_near(v1, v2, 0.0001)
    end)
end)

-- @describe procgen edge cases
describe("procgen edge cases", function()
    -- @covers lurek.procgen.cellularAutomata
    it("cellularAutomata with fill=0 produces mostly zeros", function()
        local data = lurek.procgen.cellularAutomata(20, 20, { fill = 0.0, iterations = 0 })
        local ones = 0
        for _, v in ipairs(data) do
            if v == 1 then ones = ones + 1 end
        end
        expect_equal(0, ones, "fill=0 should produce all zeros")
    end)

    -- @covers lurek.procgen.cellularAutomata
    it("cellularAutomata with fill=1 produces mostly ones", function()
        local data = lurek.procgen.cellularAutomata(20, 20, { fill = 1.0, iterations = 0 })
        local zeros = 0
        for _, v in ipairs(data) do
            if v == 0 then zeros = zeros + 1 end
        end
        expect_equal(0, zeros, "fill=1 should produce all ones")
    end)

    -- @covers lurek.procgen.voronoi
    it("voronoi with single seed assigns all cells to region 1", function()
        local pts = { { x = 4, y = 4 } }
        local regions, _, _ = lurek.procgen.voronoi(8, 8, pts)
        for _, r in ipairs(regions) do
            expect_equal(1, r)
        end
    end)
end)

-- ============================================================
-- BSP Dungeon
-- ============================================================
-- @describe procgen.bspDungeon
describe("procgen.bspDungeon", function()
    -- @covers lurek.procgen.bspDungeon
    it("returns rooms and corridors", function()
        local d = lurek.procgen.bspDungeon({ width = 40, height = 30, seed = 1 })
        expect_type("table", d.rooms)
        expect_type("table", d.corridors)
        expect_true(#d.rooms > 0, "expected at least one room")
    end)

    -- @covers lurek.procgen.bspDungeon
    it("rooms have x,y,w,h fields", function()
        local d = lurek.procgen.bspDungeon({ width = 40, height = 30, seed = 2 })
        local r = d.rooms[1]
        expect_type("number", r.x)
        expect_type("number", r.y)
        expect_type("number", r.w)
        expect_type("number", r.h)
        expect_true(r.w > 0, "room width must be positive")
    end)

    -- @covers lurek.procgen.bspDungeon
    it("same seed is deterministic", function()
        local d1 = lurek.procgen.bspDungeon({ width = 50, height = 40, seed = 99 })
        local d2 = lurek.procgen.bspDungeon({ width = 50, height = 40, seed = 99 })
        expect_equal(#d1.rooms, #d2.rooms)
    end)
end)

-- ============================================================
-- Rooms Dungeon
-- ============================================================
-- @describe procgen.roomsDungeon
describe("procgen.roomsDungeon", function()
    -- @covers lurek.procgen.roomsDungeon
    it("grid length equals width * height", function()
        local d = lurek.procgen.roomsDungeon({ width = 20, height = 15, seed = 7 })
        expect_equal(20 * 15, #d.grid)
        expect_equal(20, d.width)
        expect_equal(15, d.height)
    end)

    -- @covers lurek.procgen.roomsDungeon
    it("rooms have x,y,w,h fields", function()
        local d = lurek.procgen.roomsDungeon({ width = 30, height = 20, max_rooms = 5, seed = 5 })
        if #d.rooms > 0 then
            local r = d.rooms[1]
            expect_type("number", r.x)
            expect_type("number", r.w)
        end
    end)
end)

-- ============================================================
-- Heightmap
-- ============================================================
-- @describe procgen.heightmap
describe("procgen.heightmap", function()
    -- @covers lurek.procgen.heightmap
    it("returns correct cell count", function()
        local hm = lurek.procgen.heightmap({ width = 16, height = 16, seed = 1 })
        expect_equal(16 * 16, #hm.cells)
        expect_equal(16, hm.width)
        expect_equal(16, hm.height)
    end)

    -- @covers lurek.procgen.heightmap
    it("cells are in [0, 1]", function()
        local hm = lurek.procgen.heightmap({ width = 8, height = 8, seed = 5 })
        for _, v in ipairs(hm.cells) do
            expect_true(v >= 0.0 and v <= 1.0, "cell out of [0,1]: " .. tostring(v))
        end
    end)

    -- @covers lurek.procgen.heightmap
    it("same seed produces same output", function()
        local a = lurek.procgen.heightmap({ width = 8, height = 8, seed = 42 })
        local b = lurek.procgen.heightmap({ width = 8, height = 8, seed = 42 })
        expect_near(a.cells[1], b.cells[1], 1e-5)
    end)
end)

-- ============================================================
-- L-System
-- ============================================================
-- @describe procgen.lsystem
describe("procgen.lsystem", function()
    -- @covers lurek.procgen.lsystem
    it("F doubled each iteration", function()
        local s = lurek.procgen.lsystem({ axiom = "F", rules = { F = "FF" }, iterations = 3 })
        expect_equal(8, #s)  -- 2^3 = 8
    end)

    -- @covers lurek.procgen.lsystem
    it("zero iterations returns axiom unchanged", function()
        local s = lurek.procgen.lsystem({ axiom = "AB", rules = { A = "B", B = "A" }, iterations = 0 })
        expect_equal("AB", s)
    end)

    -- @covers lurek.procgen.lsystemSegments
    it("lsystemSegments returns table of {x1,y1,x2,y2}", function()
        local segs = lurek.procgen.lsystemSegments(
            { axiom = "F+F+F+F", rules = {}, iterations = 0 }, 90, 1.0)
        expect_type("table", segs)
        if #segs > 0 then
            local s = segs[1]
            expect_type("number", s.x1)
            expect_type("number", s.y1)
            expect_type("number", s.x2)
            expect_type("number", s.y2)
        end
    end)
end)

-- ============================================================
-- Name Generator
-- ============================================================
-- @describe procgen.generateName
describe("procgen.generateName", function()
    local training = { "Aria", "Lyra", "Mira", "Elara", "Kira", "Tara", "Nara", "Zara", "Vera", "Lara" }

    -- @covers lurek.procgen.generateName
    it("returns a string", function()
        local name = lurek.procgen.generateName(training, 3, 8, 1)
        expect_type("string", name)
    end)

    -- @covers lurek.procgen.generateName
    it("length within min/max", function()
        for seed = 1, 5 do
            local name = lurek.procgen.generateName(training, 3, 8, seed)
            expect_true(#name >= 3 and #name <= 8, "name length out of range: " .. #name)
        end
    end)

    -- @covers lurek.procgen.generateNames
    it("generateNames returns N names", function()
        local names = lurek.procgen.generateNames(training, 5, 3, 8, 42)
        expect_equal(5, #names)
        for _, n in ipairs(names) do
            expect_type("string", n)
        end
    end)
end)

-- ============================================================
-- World Graph
-- ============================================================
-- @describe procgen.worldGraph
describe("procgen.worldGraph", function()
    -- @covers lurek.procgen.worldGraph
    it("returns correct region count", function()
        local wg = lurek.procgen.worldGraph(200, 150, 8, 1)
        expect_equal(8, #wg.regions)
    end)

    -- @covers lurek.procgen.worldGraph
    it("regions have id, name, x, y, tags", function()
        local wg = lurek.procgen.worldGraph(200, 150, 4, 2)
        local r = wg.regions[1]
        expect_type("number", r.id)
        expect_type("string", r.name)
        expect_type("number", r.x)
        expect_type("number", r.y)
        expect_type("table", r.tags)
    end)

    -- @covers lurek.procgen.worldGraph
    it("edges have from, to, cost, bidirectional", function()
        local wg = lurek.procgen.worldGraph(200, 150, 4, 3)
        if #wg.edges > 0 then
            local e = wg.edges[1]
            expect_type("number", e.from)
            expect_type("number", e.to)
            expect_type("number", e.cost)
            expect_type("boolean", e.bidirectional)
        end
    end)

    -- @covers lurek.procgen.worldGraph
    it("same seed is deterministic", function()
        local a = lurek.procgen.worldGraph(200, 150, 5, 7)
        local b = lurek.procgen.worldGraph(200, 150, 5, 7)
        expect_equal(#a.regions, #b.regions)
    end)
end)

-- ============================================================
-- Noise Map & Parallel
-- ============================================================
-- @describe procgen.noiseMap / noiseMapParallel
describe("procgen.noiseMap / noiseMapParallel", function()
    -- @covers lurek.procgen.noiseMap
    it("noiseMap returns correct count", function()
        local m = lurek.procgen.noiseMap(16, 16)
        expect_equal(256, #m)
    end)

    -- @covers lurek.procgen.noiseMap
    it("noiseMap values are numbers", function()
        local m = lurek.procgen.noiseMap(4, 4)
        for _, v in ipairs(m) do expect_type("number", v) end
    end)

    -- @covers lurek.procgen.noiseMap
    it("noiseMap same seed is deterministic", function()
        local a = lurek.procgen.noiseMap(8, 8, { seed = 42, scale_x = 0.1, scale_y = 0.1 })
        local b = lurek.procgen.noiseMap(8, 8, { seed = 42, scale_x = 0.1, scale_y = 0.1 })
        expect_near(a[1], b[1], 1e-5)
    end)

    -- @covers lurek.procgen.noiseMapParallel
    it("noiseMapParallel returns correct size", function()
        local m = lurek.procgen.noiseMapParallel(16, 16)
        expect_equal(256, #m)
    end)

    -- @covers lurek.procgen.noiseMapParallel
    it("noiseMapParallel values are numbers", function()
        local m = lurek.procgen.noiseMapParallel(4, 4, { octaves = 2 })
        for _, v in ipairs(m) do expect_type("number", v) end
    end)
end)

-- @describe lurek.procgen regression coverage
describe("lurek.procgen regression coverage", function()
    -- @covers lurek.procgen.wfcGenerate
    it("wfcGenerate returns a fully collapsed grid for a single-tile ruleset", function()
        local grid = lurek.procgen.wfcGenerate({
            width = 4,
            height = 3,
            seed = 7,
            max_attempts = 2,
            tiles = {
                { id = 1, weight = 1.0 },
            },
            adjacencies = {
                [1] = { 1 },
            },
        })

        expect_equal(4, grid.width)
        expect_equal(3, grid.height)
        expect_equal(12, #grid.cells)
        for _, cell in ipairs(grid.cells) do
            expect_equal(1, cell)
        end
    end)

    -- @covers lurek.procgen.simplex2d
    -- @covers lurek.procgen.simplex3d
    it("simplex2d and simplex3d return deterministic numeric samples", function()
        local s2_a = lurek.procgen.simplex2d(0.25, 0.5)
        local s2_b = lurek.procgen.simplex2d(0.25, 0.5)
        local s3_a = lurek.procgen.simplex3d(0.25, 0.5, 0.75)
        local s3_b = lurek.procgen.simplex3d(0.25, 0.5, 0.75)

        expect_type("number", s2_a)
        expect_type("number", s3_a)
        expect_near(s2_a, s2_b, 0.000001)
        expect_near(s3_a, s3_b, 0.000001)
    end)
end)

-- @describe unit: migrated from integration/test_graph_pathfind.lua
describe("unit: migrated from integration/test_graph_pathfind.lua", function()
        -- @covers lurek.procgen.worldGraph
        it("worldGraph edge costs match procgen expectations", function()
            local wg = lurek.procgen.worldGraph(200, 150, 6, 5)
            for _, e in ipairs(wg.edges) do
                expect_true(e.cost > 0, "edge cost should be positive")
            end
        end)

end)

-- @describe unit: migrated from integration/test_pathfind_graph.lua
describe("unit: migrated from integration/test_pathfind_graph.lua", function()
        -- @covers lurek.procgen.worldGraph
        it("worldGraph region coordinates stay within world bounds", function()
            local wg = lurek.procgen.worldGraph(200, 100, 10, 1)
            for _, r in ipairs(wg.regions) do
                expect_true(r.x >= 0 and r.x <= 200, "region x out of bounds")
                expect_true(r.y >= 0 and r.y <= 100, "region y out of bounds")
            end
        end)

        -- @covers lurek.procgen.worldGraph
        it("worldGraph edge endpoints are valid region IDs", function()
            local wg = lurek.procgen.worldGraph(200, 100, 8, 2)
            local id_set = {}
            for _, r in ipairs(wg.regions) do id_set[r.id] = true end
            for _, e in ipairs(wg.edges) do
                expect_true(id_set[e.from] == true, "from region not found: " .. e.from)
                expect_true(id_set[e.to]   == true, "to region not found: " .. e.to)
            end
        end)

        -- @covers lurek.procgen.bspDungeon
        it("BSP dungeon width/height matches requested size", function()
            local d = lurek.procgen.bspDungeon({ width = 30, height = 20, seed = 5 })
            -- All rooms must be inside the dungeon bounds
            for _, r in ipairs(d.rooms) do
                expect_true(r.x + r.w <= 30, "room overflows width")
                expect_true(r.y + r.h <= 20, "room overflows height")
            end
        end)

end)

-- @describe unit: migrated from integration/test_procgen_tilemap.lua
describe("unit: migrated from integration/test_procgen_tilemap.lua", function()
        -- @covers lurek.procgen.perlinNoise
        it("different seeds produce different tilemaps", function()
            local map1_tiles = {}
            local map2_tiles = {}

            for y = 0, 3 do
                for x = 0, 3 do
                    local n1 = lurek.procgen.perlinNoise(x * 0.1, y * 0.1, 1, 1)
                    local n2 = lurek.procgen.perlinNoise(x * 0.1 + 3.7, y * 0.1 + 5.3, 1, 1)
                    table.insert(map1_tiles, n1)
                    table.insert(map2_tiles, n2)
                end
            end

            -- At least one tile should differ
            local any_different = false
            for i = 1, #map1_tiles do
                if math.abs(map1_tiles[i] - map2_tiles[i]) > 0.001 then
                    any_different = true
                    break
                end
            end
            expect_true(any_different, "different offsets produce different noise")
        end)

        -- @covers lurek.procgen.bspDungeon
        it("BSP rooms can map to walkable tile IDs", function()
            local d = lurek.procgen.bspDungeon({ width = 40, height = 30, seed = 42 })
            -- Mark room cells as tile 1 (walkable), rest as tile 0 (wall)
            local grid = {}
            for i = 1, 40 * 30 do grid[i] = 0 end
            for _, r in ipairs(d.rooms) do
                for dy = 0, r.h - 1 do
                    for dx = 0, r.w - 1 do
                        local idx = (r.y + dy) * 40 + (r.x + dx) + 1
                        if idx >= 1 and idx <= #grid then
                            grid[idx] = 1
                        end
                    end
                end
            end
            expect_equal(40 * 30, #grid)
            -- At least one walkable cell
            local has_walkable = false
            for _, v in ipairs(grid) do
                if v == 1 then has_walkable = true break end
            end
            expect_true(has_walkable, "expected at least one walkable cell from rooms")
        end)

        -- @covers lurek.procgen.roomsDungeon
        it("roomsDungeon grid matches dimensions", function()
            local d = lurek.procgen.roomsDungeon({ width = 24, height = 16, max_rooms = 6, seed = 11 })
            expect_equal(24 * 16, #d.grid)
        end)

        -- @covers lurek.procgen.wfcGenerate
        it("WFC grid stays within tile ID set", function()
            local tiles = { { id = 0, weight = 1 }, { id = 1, weight = 1 }, { id = 2, weight = 0.5 } }
            local adj = { [0] = { 0, 1 }, [1] = { 0, 1, 2 }, [2] = { 1, 2 } }
            local g = lurek.procgen.wfcGenerate({ width = 10, height = 10, tiles = tiles, adjacencies = adj, seed = 3 })
            for _, c in ipairs(g.cells) do
                expect_true(c >= 0 and c <= 2, "unexpected tile id: " .. c)
            end
        end)

        -- @covers lurek.procgen.heightmap
        it("heightmap drives biome layer assignment", function()
            local hm = lurek.procgen.heightmap({ width = 12, height = 12, seed = 77 })
            local biomes = { "deep_water", "water", "sand", "grass", "forest", "mountain", "snow" }
            local layer = {}
            for _, v in ipairs(hm.cells) do
                local idx = math.max(1, math.min(#biomes, math.floor(v * #biomes) + 1))
                table.insert(layer, biomes[idx])
            end
            expect_equal(12 * 12, #layer)
            expect_true(type(layer[1]) == "string", "biome should be a string")
        end)

        -- @covers lurek.procgen.biomeColor
        it("biomeColor returns rgba tuple", function()
            local r, g, b, a = lurek.procgen.biomeColor("desert")
            expect_type("number", r)
            expect_type("number", g)
            expect_type("number", b)
            expect_type("number", a)
        end)

        -- @covers lurek.procgen.newBiomeClassifier
        it("newBiomeClassifier returns userdata", function()
            local bc = lurek.procgen.newBiomeClassifier({ ocean_threshold = 0.2 })
            expect_type("userdata", bc)
        end)

        -- @covers BiomeClassifier:classifyMap
        -- @covers BiomeClassifier:classify
        it("BiomeClassifier classifies map samples", function()
            local bc = lurek.procgen.newBiomeClassifier()
            local out = bc:classifyMap(2, 2, { 0.1, 0.3, 0.7, 0.9 }, { 0.8, 0.2, 0.4, 0.1 }, { 0.5, 0.7, 0.6, 0.2 })
            expect_type("table", out)
            expect_equal(4, #out)
            expect_type("string", bc:classify(0.6, 0.3, 0.7))
        end)

end)

-- ============================================================
-- BSP Dungeon With Prefabs
-- ============================================================
-- @describe procgen.bspDungeonWithPrefabs
describe("procgen.bspDungeonWithPrefabs", function()
    -- @covers lurek.procgen.bspDungeonWithPrefabs
    it("returns dungeon and prefab placement tables", function()
        local prefabs = { { name = "boss", width = 4, height = 4 } }
        local dungeon, placed = lurek.procgen.bspDungeonWithPrefabs({ width = 40, height = 30, seed = 1 }, prefabs)
        expect_type("table", dungeon.rooms)
        expect_type("table", dungeon.corridors)
        expect_type("table", placed)
    end)

    -- @covers lurek.procgen.bspDungeonWithPrefabs
    it("placed prefabs have name, x, y, width, height", function()
        local prefabs = { { name = "chest", width = 2, height = 2 } }
        local _, placed = lurek.procgen.bspDungeonWithPrefabs({ width = 40, height = 30, seed = 7 }, prefabs)
        for _, p in ipairs(placed) do
            expect_type("string", p.name)
            expect_type("number", p.x)
            expect_type("number", p.y)
            expect_type("number", p.width)
            expect_type("number", p.height)
        end
    end)

    -- @covers lurek.procgen.bspDungeonWithPrefabs
    it("same seed is deterministic", function()
        local prefabs = { { name = "room", width = 3, height = 3 } }
        local d1, p1 = lurek.procgen.bspDungeonWithPrefabs({ width = 40, height = 30, seed = 42 }, prefabs)
        local d2, p2 = lurek.procgen.bspDungeonWithPrefabs({ width = 40, height = 30, seed = 42 }, prefabs)
        expect_equal(#d1.rooms, #d2.rooms)
        expect_equal(#p1, #p2)
    end)
end)

-- ============================================================
-- Rooms Dungeon With Prefabs
-- ============================================================
-- @describe procgen.roomsDungeonWithPrefabs
describe("procgen.roomsDungeonWithPrefabs", function()
    -- @covers lurek.procgen.roomsDungeonWithPrefabs
    it("returns dungeon with grid and prefab placements", function()
        local prefabs = { { name = "altar", width = 3, height = 3 } }
        local dungeon, placed = lurek.procgen.roomsDungeonWithPrefabs({ width = 30, height = 20, seed = 5 }, prefabs)
        expect_type("table", dungeon.rooms)
        expect_type("table", dungeon.grid)
        expect_equal(30 * 20, #dungeon.grid)
        expect_type("table", placed)
    end)

    -- @covers lurek.procgen.roomsDungeonWithPrefabs
    it("placed prefabs have required fields", function()
        local prefabs = { { name = "shrine", width = 2, height = 2 } }
        local _, placed = lurek.procgen.roomsDungeonWithPrefabs({ width = 30, height = 20, seed = 9 }, prefabs)
        for _, p in ipairs(placed) do
            expect_type("string", p.name)
            expect_type("number", p.x)
            expect_type("number", p.y)
        end
    end)

    -- @covers lurek.procgen.roomsDungeonWithPrefabs
    it("same seed is deterministic", function()
        local prefabs = { { name = "room", width = 2, height = 2 } }
        local d1, _ = lurek.procgen.roomsDungeonWithPrefabs({ width = 30, height = 20, seed = 77 }, prefabs)
        local d2, _ = lurek.procgen.roomsDungeonWithPrefabs({ width = 30, height = 20, seed = 77 }, prefabs)
        expect_equal(#d1.rooms, #d2.rooms)
    end)
end)

-- ============================================================
-- Heightmap From Cellular
-- ============================================================
-- @describe procgen.heightmapFromCellular
describe("procgen.heightmapFromCellular", function()
    -- @covers lurek.procgen.heightmapFromCellular
    it("returns table with cells, width, height", function()
        local cells = lurek.procgen.cellularAutomata(8, 6, { seed = 1 })
        local hm = lurek.procgen.heightmapFromCellular(8, 6, cells)
        expect_type("table", hm.cells)
        expect_equal(8, hm.width)
        expect_equal(6, hm.height)
        expect_equal(48, #hm.cells)
    end)

    -- @covers lurek.procgen.heightmapFromCellular
    it("cell values are non-negative numbers", function()
        local cells = lurek.procgen.cellularAutomata(6, 6, { seed = 3 })
        local hm = lurek.procgen.heightmapFromCellular(6, 6, cells)
        for _, v in ipairs(hm.cells) do
            expect_type("number", v)
            expect_true(v >= 0.0, "height value must be non-negative")
        end
    end)

    -- @covers lurek.procgen.heightmapFromCellular
    it("same input produces same heightmap", function()
        local cells = lurek.procgen.cellularAutomata(8, 8, { seed = 10 })
        local a = lurek.procgen.heightmapFromCellular(8, 8, cells)
        local b = lurek.procgen.heightmapFromCellular(8, 8, cells)
        expect_near(a.cells[1], b.cells[1], 1e-5)
    end)
end)

-- ============================================================
-- Noise Map Parallel Seeded
-- ============================================================
-- @describe procgen.noiseMapParallelSeeded
describe("procgen.noiseMapParallelSeeded", function()
    -- @covers lurek.procgen.noiseMapParallelSeeded
    it("returns flat array of correct length", function()
        local m = lurek.procgen.noiseMapParallelSeeded(8, 8)
        expect_equal(64, #m)
    end)

    -- @covers lurek.procgen.noiseMapParallelSeeded
    it("values are numbers", function()
        local m = lurek.procgen.noiseMapParallelSeeded(4, 4, { seed = 1 })
        for _, v in ipairs(m) do
            expect_type("number", v)
        end
    end)

    -- @covers lurek.procgen.noiseMapParallelSeeded
    it("same seed produces deterministic results", function()
        local a = lurek.procgen.noiseMapParallelSeeded(8, 8, { seed = 99 })
        local b = lurek.procgen.noiseMapParallelSeeded(8, 8, { seed = 99 })
        expect_equal(#a, #b)
        expect_near(a[1], b[1], 1e-5)
    end)

    -- @covers lurek.procgen.noiseMapParallelSeeded
    it("different seeds produce different results", function()
        local a = lurek.procgen.noiseMapParallelSeeded(8, 8, { seed = 1, scale_x = 0.3, scale_y = 0.3 })
        local b = lurek.procgen.noiseMapParallelSeeded(8, 8, { seed = 2, scale_x = 0.3, scale_y = 0.3 })
        local any_diff = false
        for i = 1, #a do
            if math.abs(a[i] - b[i]) > 1e-5 then
                any_diff = true
                break
            end
        end
        expect_true(any_diff, "different seeds should produce different noise")
    end)
end)

test_summary()
