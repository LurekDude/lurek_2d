-- Lurek2D Lua BDD tests for lurek.procgen
-- Headless: no GPU, no audio, no window.

describe("lurek.procgen", function()
    describe("module interface", function()
        it("exposes cellularAutomata", function()
            expect_type("function", lurek.procgen.cellularAutomata)
        end)

        it("exposes floodFill", function()
            expect_type("function", lurek.procgen.floodFill)
        end)

        it("exposes perlinNoise", function()
            expect_type("function", lurek.procgen.perlinNoise)
        end)

        it("exposes poissonDisk", function()
            expect_type("function", lurek.procgen.poissonDisk)
        end)

        it("exposes voronoi", function()
            expect_type("function", lurek.procgen.voronoi)
        end)
    end)

    describe("cellularAutomata(w, h, opts)", function()
        it("returns a flat table of 0/1 values", function()
            local data = lurek.procgen.cellularAutomata(8, 6)
            expect_type("table", data)
            expect_equal(48, #data)
        end)

        it("all values are 0 or 1", function()
            local data = lurek.procgen.cellularAutomata(10, 10)
            for _, v in ipairs(data) do
                assert(v == 0 or v == 1, "unexpected value: " .. tostring(v))
            end
        end)

        it("accepts opts table with fill parameter", function()
            local data = lurek.procgen.cellularAutomata(6, 6, { fill = 0.5, iterations = 2 })
            expect_equal(36, #data)
        end)
    end)

    describe("floodFill(data, w, h, sx, sy, threshold, above)", function()
        it("returns a table of the same size as input", function()
            local data = {}
            for i = 1, 25 do data[i] = 0 end
            local result = lurek.procgen.floodFill(data, 5, 5, 2, 2)
            expect_equal(25, #result)
        end)

        it("fills connected region starting from seed", function()
            local data = {}
            for i = 1, 25 do data[i] = 0 end
            local result = lurek.procgen.floodFill(data, 5, 5, 0, 0)
            -- With all-zero grid and below-threshold fill, all cells should be marked
            local filled = 0
            for _, v in ipairs(result) do
                if v > 0 then filled = filled + 1 end
            end
            assert(filled > 0, "expected at least one filled cell")
        end)
    end)

    describe("perlinNoise(x, y, px, py)", function()
        it("returns a number", function()
            local v = lurek.procgen.perlinNoise(0.5, 0.5, 8.0, 8.0)
            expect_type("number", v)
        end)

        it("value is in [-1, 1]", function()
            local v = lurek.procgen.perlinNoise(1.0, 2.0, 10.0, 10.0)
            assert(v >= -1.0 and v <= 1.0, "out of range: " .. tostring(v))
        end)

        it("wraps at period boundaries", function()
            local px, py = 8.0, 8.0
            local v1 = lurek.procgen.perlinNoise(0.0, 3.0, px, py)
            local v2 = lurek.procgen.perlinNoise(px, 3.0, px, py)
            local diff = math.abs(v1 - v2)
            assert(diff < 0.001, "does not wrap: diff=" .. tostring(diff))
        end)
    end)

    describe("poissonDisk(w, h, min_dist, max_attempts, seed)", function()
        it("returns a table of point objects", function()
            local pts = lurek.procgen.poissonDisk(80, 80, 10)
            expect_type("table", pts)
        end)

        it("each point has x and y fields", function()
            local pts = lurek.procgen.poissonDisk(80, 80, 10, 30, 42)
            assert(#pts > 0, "expected at least one point")
            for _, p in ipairs(pts) do
                expect_type("number", p.x)
                expect_type("number", p.y)
            end
        end)

        it("points lie within the specified bounds", function()
            local w, h = 100, 60
            local pts = lurek.procgen.poissonDisk(w, h, 8, 30, 7)
            for _, p in ipairs(pts) do
                assert(p.x >= 0 and p.x < w, "point x=" .. p.x .. " out of bounds")
                assert(p.y >= 0 and p.y < h, "point y=" .. p.y .. " out of bounds")
            end
        end)
    end)

    describe("voronoi(w, h, seeds)", function()
        it("returns three tables: regions, dist, dist2", function()
            local pts = { { x = 10, y = 10 }, { x = 30, y = 30 } }
            local regions, dist, dist2 = lurek.procgen.voronoi(8, 8, pts)
            expect_type("table", regions)
            expect_type("table", dist)
            expect_type("table", dist2)
        end)

        it("regions table has w*h entries", function()
            local pts = { { x = 5, y = 5 }, { x = 15, y = 5 }, { x = 10, y = 15 } }
            local regions, _, _ = lurek.procgen.voronoi(20, 10, pts)
            expect_equal(200, #regions)
        end)

        it("region indices are within seed count range", function()
            local pts = { { x = 5, y = 5 }, { x = 15, y = 10 } }
            local n = #pts
            local regions, _, _ = lurek.procgen.voronoi(20, 20, pts)
            for _, r in ipairs(regions) do
                assert(r >= 1 and r <= n, "invalid region index: " .. tostring(r))
            end
        end)
    end)
end)

test_summary()
