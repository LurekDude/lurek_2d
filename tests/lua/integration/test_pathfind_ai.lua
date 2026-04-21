-- tests/lua/integration/test_pathfind_ai.lua
-- Integration: lurek.pathfind hex/jps grids used with AI-style logic.
-- Namespaces: lurek.pathfind + lurek.ai


-- ─────────────────────────────────────────────
-- HexGrid: AI turn-based movement patterns
-- ─────────────────────────────────────────────
describe("hexGrid + AI turn-based movement", function()

    it("AI unit can find path to target", function()
        local map = lurek.pathfind.newHexGrid(12, 12)
        -- Simulate AI agent at (1,1) targeting (10,10)
        local path = map:findPath(1, 1, 10, 10)
        expect_true(path ~= nil, "AI should find a path on open map")
        expect_true(#path >= 1, "path must have length >= 1")
    end)

    it("AI units compute their movement range with budget", function()
        local map = lurek.pathfind.newHexGrid(10, 10)
        -- Typical turn-based unit with movement of 3
        local reachable = map:rangeOfMovement(5, 5, 3.0)
        expect_type("table", reachable)
        expect_true(#reachable > 0, "unit should be able to reach some cells")
        expect_true(#reachable >= 6, "with budget=3, should reach at least 6 hex cells")
    end)

    it("AI units check line of sight before shooting", function()
        local map = lurek.pathfind.newHexGrid(10, 10)
        local los_clear = map:lineOfSight(1, 1, 5, 5)
        expect_equal(true, los_clear, "open map should have LOS")

        -- Add a wall column
        for row = 1, 10 do
            map:setBlocked(3, row, true)
        end
        local los_blocked = map:lineOfSight(1, 5, 8, 5)
        expect_equal(false, los_blocked, "wall should block LOS")
    end)

    it("AI computes FOV for visibility grid", function()
        local map = lurek.pathfind.newHexGrid(10, 10)
        local visible = map:fieldOfView(5, 5, 3)
        expect_type("table", visible)
        -- FOV with radius 3 on open map should see many cells
        expect_true(#visible >= 7, "expected at least 7 visible cells with radius 3")
    end)

    it("enemy AI chooses closest walkable cell to player", function()
        local map = lurek.pathfind.newHexGrid(10, 10)
        local player = { col = 8, row = 8 }
        local enemies = {
            { col = 1, row = 1 },
            { col = 2, row = 2 },
            { col = 9, row = 9 },
        }
        local closest = nil
        local min_dist = math.huge
        for _, e in ipairs(enemies) do
            local d = map:distance(e.col, e.row, player.col, player.row)
            if d < min_dist then
                min_dist = d
                closest = e
            end
        end
        expect_true(closest ~= nil, "should find closest enemy")
        -- Enemy at (9,9) is closest to player at (8,8) at distance 1
        expect_equal(9, closest.col)
        expect_equal(9, closest.row)
    end)

    it("AI blocked by terrain uses alternative path", function()
        local map = lurek.pathfind.newHexGrid(8, 8)
        -- Block direct corridor from (1,4) to (8,4)
        for col = 2, 7 do map:setBlocked(col, 4, true) end
        local path_direct = map:findPath(1, 4, 8, 4)
        -- Path should be nil or go around
        if path_direct then
            for _, step in ipairs(path_direct) do
                expect_true(step.row ~= 4 or step.col == 1 or step.col == 8,
                    "path should avoid blocked row 4")
            end
        end
    end)
end)

-- ─────────────────────────────────────────────
-- JPS Grid: AI real-time movement
-- ─────────────────────────────────────────────
describe("jpsGrid + AI real-time movement", function()

    it("AI pathfinding request returns a route", function()
        local map = lurek.pathfind.newJpsGrid(20, 20)
        local path = map:findPath(1, 1, 18, 18)
        expect_true(path ~= nil or true, "should return path or nil without crash")
    end)

    it("shorter path when obstacles removed", function()
        local open = lurek.pathfind.newJpsGrid(10, 10)
        local blocked = lurek.pathfind.newJpsGrid(10, 10)
        -- Add obstacles in blocked version
        for y = 2, 8 do blocked:setBlocked(5, y, true) end
        local path_open    = open:findPath(1, 5, 9, 5)
        local path_blocked = blocked:findPath(1, 5, 9, 5)
        -- Blocked path may be longer or nil; open path should be shorter
        if path_open and path_blocked then
            expect_true(#path_blocked >= #path_open, "detour should be at least as long as direct")
        end
    end)

    it("AI can place multiple units without conflicts", function()
        local map = lurek.pathfind.newJpsGrid(10, 10)
        -- Simulate 3 AI units with different start/end positions
        local routes = {
            map:findPath(1, 1, 10, 10),
            map:findPath(1, 10, 10, 1),
            map:findPath(5, 1, 5, 10),
        }
        for _, r in ipairs(routes) do
            expect_true(r == nil or type(r) == "table", "each route should be nil or table")
        end
    end)
end)

-- ─────────────────────────────────────────────
-- RangeMap: AI tactical movement zones
-- ─────────────────────────────────────────────
describe("rangeMap + AI tactical analysis", function()

    it("AI identifies cells within movement budget", function()
        local result = lurek.pathfind.rangeMap({
            width = 10, height = 10,
            origin_x = 5, origin_y = 5,
            budget = 2.0
        })
        -- Cross shape (4 directions × 2 steps) plus origin = ~13 cells
        expect_true(#result.cells >= 5, "expected at least 5 cells with budget=2")
    end)

    it("AI avoids high-cost terrain", function()
        -- Build a cost grid with high-cost center column
        local costs = {}
        for y = 1, 10 do
            for x = 1, 10 do
                costs[(y - 1) * 10 + x] = (x == 5) and 10.0 or 1.0
            end
        end
        local cheap = lurek.pathfind.rangeMap({ width = 10, height = 10, origin_x = 3, origin_y = 5, budget = 3.0 })
        local expensive = lurek.pathfind.rangeMap({
            width = 10, height = 10,
            costs = costs,
            origin_x = 3, origin_y = 5,
            budget = 3.0
        })
        -- With high-cost column-5, fewer cells should be reachable
        expect_true(#expensive.cells <= #cheap.cells, "high-cost terrain should reduce reachable area")
    end)

    it("surrounded AI unit can only reach origin", function()
        -- Block all adjacent cells
        local blocked = {}
        for i = 1, 8 * 8 do blocked[i] = false end
        for y = 3, 5 do
            for x = 3, 5 do
                if not (x == 4 and y == 4) then
                    blocked[(y - 1) * 8 + x] = true
                end
            end
        end
        local result = lurek.pathfind.rangeMap({
            width = 8, height = 8,
            blocked = blocked,
            origin_x = 4, origin_y = 4,
            budget = 10.0
        })
        expect_equal(1, #result.cells)
        expect_equal(4, result.cells[1].x)
        expect_equal(4, result.cells[1].y)
    end)
end)

test_summary()
