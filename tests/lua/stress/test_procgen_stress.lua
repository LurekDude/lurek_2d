-- tests/lua/stress/test_procgen_stress.lua
-- Stress tests for lurek.procgen — throughput and allocation under load.
-- Validates that generators don't crash, memory-leak, or hang under large inputs.

local init = require("tests/lua/init")
describe, it, expect_equal, expect_near, expect_error, expect_true, expect_type, test_summary =
    init.describe, init.it, init.expect_equal, init.expect_near,
    init.expect_error, init.expect_true, init.expect_type, init.test_summary

-- ─────────────────────────────────────────────
-- Repeated dungeon generation
-- ─────────────────────────────────────────────
describe("procgen stress: repeated dungeon generation", function()

    it("bspDungeon 100 iterations with different seeds", function()
        for seed = 1, 100 do
            local d = lurek.procgen.bspDungeon({ width = 60, height = 40, seed = seed })
            expect_type("table", d.rooms)
        end
    end)

    it("roomsDungeon 50 iterations", function()
        for seed = 1, 50 do
            local d = lurek.procgen.roomsDungeon({ width = 40, height = 30, max_rooms = 10, seed = seed })
            expect_true(#d.grid == 40 * 30, "grid size mismatch at seed " .. seed)
        end
    end)

    it("bspDungeon large map (200×150) completes without crash", function()
        local d = lurek.procgen.bspDungeon({ width = 200, height = 150, seed = 777 })
        expect_type("table", d.rooms)
        expect_true(#d.rooms > 0, "large map should generate rooms")
    end)
end)

-- ─────────────────────────────────────────────
-- Heightmap throughput
-- ─────────────────────────────────────────────
describe("procgen stress: heightmap large and repeated", function()

    it("heightmap 128×128 completes", function()
        local hm = lurek.procgen.heightmap({ width = 128, height = 128, seed = 1, octaves = 4 })
        expect_equal(128 * 128, #hm.cells)
    end)

    it("heightmap 256×256 completes", function()
        local hm = lurek.procgen.heightmap({ width = 256, height = 256, seed = 2, octaves = 6 })
        expect_equal(256 * 256, #hm.cells)
    end)

    it("20 heightmaps in sequence without error", function()
        for i = 1, 20 do
            local hm = lurek.procgen.heightmap({ width = 32, height = 32, seed = i })
            expect_equal(32 * 32, #hm.cells)
        end
    end)
end)

-- ─────────────────────────────────────────────
-- Noise map throughput
-- ─────────────────────────────────────────────
describe("procgen stress: noise maps", function()

    it("noiseMap 512×512 completes", function()
        local m = lurek.procgen.noiseMap(512, 512, { seed = 1 })
        expect_equal(512 * 512, #m)
    end)

    it("noiseMapParallel 512×512 completes", function()
        local m = lurek.procgen.noiseMapParallel(512, 512, { octaves = 4 })
        expect_equal(512 * 512, #m)
    end)

    it("noiseMapParallel 1024×1024 completes", function()
        local m = lurek.procgen.noiseMapParallel(1024, 1024)
        expect_equal(1024 * 1024, #m)
    end)

    it("10 parallel noise maps in sequence", function()
        for i = 1, 10 do
            local m = lurek.procgen.noiseMapParallel(64, 64, { octaves = 3 })
            expect_equal(64 * 64, #m)
        end
    end)
end)

-- ─────────────────────────────────────────────
-- L-System expansion
-- ─────────────────────────────────────────────
describe("procgen stress: L-system deep expansion", function()

    it("L-system 8 iterations completes fast", function()
        local s = lurek.procgen.lsystem({ axiom = "F", rules = { F = "FF" }, iterations = 8 })
        expect_equal(256, #s)  -- 2^8
    end)

    it("Koch curve 5 iterations produces many segments", function()
        local segs = lurek.procgen.lsystemSegments(
            { axiom = "F--F--F", rules = { F = "F+F--F+F" }, iterations = 5 },
            60, 1.0
        )
        expect_type("table", segs)
        expect_true(#segs > 100, "5-iteration Koch should produce >100 segments")
    end)
end)

-- ─────────────────────────────────────────────
-- Name generation throughput
-- ─────────────────────────────────────────────
describe("procgen stress: name generation", function()

    it("1000 names generated without error", function()
        local training = { "Aria", "Lyra", "Mira", "Elara", "Kira", "Tara", "Nara", "Zara",
                           "Vera", "Lara", "Sera", "Fira", "Bora", "Cora", "Diana" }
        local names = lurek.procgen.generateNames(training, 1000, 3, 10, 42)
        expect_equal(1000, #names)
        for _, n in ipairs(names) do
            expect_type("string", n)
            expect_true(#n >= 3 and #n <= 10, "name out of range: " .. n)
        end
    end)
end)

-- ─────────────────────────────────────────────
-- World graph large
-- ─────────────────────────────────────────────
describe("procgen stress: world graph", function()

    it("worldGraph 100 regions completes without error", function()
        local wg = lurek.procgen.worldGraph(2000, 1500, 100, 1)
        expect_equal(100, #wg.regions)
        expect_true(#wg.edges > 0, "expected edges in large world graph")
    end)

    it("worldGraph 50 different seeds complete", function()
        for seed = 1, 50 do
            local wg = lurek.procgen.worldGraph(400, 300, 15, seed)
            expect_equal(15, #wg.regions)
        end
    end)
end)

-- ─────────────────────────────────────────────
-- WFC stress
-- ─────────────────────────────────────────────
describe("procgen stress: wfc generation", function()

    it("wfc 32×32 grid completes", function()
        local tiles = { { id = 0, weight = 1.0 }, { id = 1, weight = 0.5 } }
        local adj = { [0] = { 0, 1 }, [1] = { 0, 1 } }
        local g = lurek.procgen.wfcGenerate({ width = 32, height = 32, tiles = tiles, adjacencies = adj, seed = 5 })
        expect_equal(32 * 32, #g.cells)
    end)

    it("wfc 20 iterations with different seeds", function()
        local tiles = { { id = 0, weight = 1.0 }, { id = 1, weight = 1.0 } }
        local adj = { [0] = { 0, 1 }, [1] = { 0, 1 } }
        for seed = 1, 20 do
            local g = lurek.procgen.wfcGenerate({ width = 16, height = 16, tiles = tiles, adjacencies = adj, seed = seed })
            expect_equal(256, #g.cells)
        end
    end)
end)

-- ─────────────────────────────────────────────
-- HexGrid range-of-movement large map
-- ─────────────────────────────────────────────
describe("pathfinding stress: hexGrid large map", function()

    it("hexGrid 100×100 findPath completes", function()
        local g = lurek.pathfind.newHexGrid(100, 100)
        local path = g:findPath(1, 1, 100, 100)
        expect_true(path == nil or #path > 0, "should find path or return nil")
    end)

    it("hexGrid 50×50 fieldOfView radius=20 completes", function()
        local g = lurek.pathfind.newHexGrid(50, 50)
        local fov = g:fieldOfView(25, 25, 20)
        expect_type("table", fov)
        expect_true(#fov > 0, "FOV should cover some cells")
    end)

    it("rangeMap 50×50 with budget 15 completes", function()
        local r = lurek.pathfind.rangeMap({
            width = 50, height = 50,
            origin_x = 25, origin_y = 25,
            budget = 15.0
        })
        expect_true(#r.cells > 0, "expected reachable cells")
    end)
end)

test_summary()
