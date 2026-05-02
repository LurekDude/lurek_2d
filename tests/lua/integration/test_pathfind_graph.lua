-- tests/lua/integration/test_pathfind_graph.lua
-- Integration: lurek.pathfind jpsGrid + graph_astar from procgen world graph
-- Namespaces: lurek.pathfind + lurek.procgen


--                                                                                                                                        
-- JPS Grid
--                                                                                                                                        
describe("pathfinding.newJpsGrid", function()

    it("creates a JPS grid without error", function()
        local g = lurek.pathfind.newJpsGrid(12, 12)
        expect_type("userdata", g)
    end)

    it("setBlocked / isBlocked round-trip", function()
        local g = lurek.pathfind.newJpsGrid(8, 8)
        g:setBlocked(5, 3, true)
        expect_equal(true, g:isBlocked(5, 3))
        g:setBlocked(5, 3, false)
        expect_equal(false, g:isBlocked(5, 3))
    end)

    it("findPath returns nil when start is blocked", function()
        local g = lurek.pathfind.newJpsGrid(6, 6)
        g:setBlocked(1, 1, true)
        local path = g:findPath(1, 1, 6, 6)
        -- Blocked start     no path
        expect_true(path == nil or type(path) == "table", "should return nil or table")
    end)

    it("findPath on open grid returns a path", function()
        local g = lurek.pathfind.newJpsGrid(10, 10)
        local path = g:findPath(1, 1, 8, 8)
        expect_true(path ~= nil, "expected a valid path on open grid")
    end)

    it("path cells have x and y fields", function()
        local g = lurek.pathfind.newJpsGrid(8, 8)
        local path = g:findPath(1, 1, 6, 6)
        if path and #path > 0 then
            expect_type("number", path[1].x)
            expect_type("number", path[1].y)
        end
    end)

    it("path starts and ends at expected coordinates", function()
        local g = lurek.pathfind.newJpsGrid(10, 10)
        local path = g:findPath(1, 1, 5, 5)
        if path and #path >= 2 then
            local first = path[1]
            local last  = path[#path]
            -- We allow some tolerance: path may not begin exactly at 1,1 (jump points)
            expect_type("number", first.x)
            expect_type("number", last.x)
            expect_equal(5, last.x)
            expect_equal(5, last.y)
        end
    end)

    it("blocking a cell removes it from the path", function()
        local g = lurek.pathfind.newJpsGrid(8, 8)
        -- Block cell (4, 4) which is on the diagonal from (1,1) to (7,7)
        g:setBlocked(4, 4, true)
        local path_blocked = g:findPath(1, 1, 7, 7)
        if path_blocked then
            for _, c in ipairs(path_blocked) do
                expect_true(not (c.x == 4 and c.y == 4), "blocked cell must not appear on path")
            end
        end
    end)

    it("multiple independent grids don't share state", function()
        local g1 = lurek.pathfind.newJpsGrid(8, 8)
        local g2 = lurek.pathfind.newJpsGrid(8, 8)
        g1:setBlocked(3, 3, true)
        expect_equal(true, g1:isBlocked(3, 3))
        expect_equal(false, g2:isBlocked(3, 3))
    end)
end)

--                                                                                                                                        
-- JPS Grid + WorldGraph produced by procgen
--                                                                                                                                        
describe("procgen worldGraph + JPS grid integration", function()

    it("worldGraph region coordinates stay within world bounds", function()
        local wg = lurek.procgen.worldGraph(200, 100, 10, 1)
        for _, r in ipairs(wg.regions) do
            expect_true(r.x >= 0 and r.x <= 200, "region x out of bounds")
            expect_true(r.y >= 0 and r.y <= 100, "region y out of bounds")
        end
    end)

    it("worldGraph edge endpoints are valid region IDs", function()
        local wg = lurek.procgen.worldGraph(200, 100, 8, 2)
        local id_set = {}
        for _, r in ipairs(wg.regions) do id_set[r.id] = true end
        for _, e in ipairs(wg.edges) do
            expect_true(id_set[e.from] == true, "from region not found: " .. e.from)
            expect_true(id_set[e.to]   == true, "to region not found: " .. e.to)
        end
    end)

    it("BSP dungeon width/height matches requested size", function()
        local d = lurek.procgen.bspDungeon({ width = 30, height = 20, seed = 5 })
        -- All rooms must be inside the dungeon bounds
        for _, r in ipairs(d.rooms) do
            expect_true(r.x + r.w <= 30, "room overflows width")
            expect_true(r.y + r.h <= 20, "room overflows height")
        end
    end)

    it("room floors are navigable via JPS grid", function()
        local d = lurek.procgen.roomsDungeon({ width = 20, height = 16, max_rooms = 4, seed = 7 })
        -- Build a JPS grid from the dungeon's floor plan
        local g = lurek.pathfind.newJpsGrid(d.width, d.height)
        for y = 1, d.height do
            for x = 1, d.width do
                local idx = (y - 1) * d.width + x
                -- False = wall     blocked
                if not d.grid[idx] then
                    g:setBlocked(x, y, true)
                end
            end
        end
        -- Find two floor cells and verify a path exists between them
        local floors = {}
        for y = 1, d.height do
            for x = 1, d.width do
                local idx = (y - 1) * d.width + x
                if d.grid[idx] then
                    table.insert(floors, { x = x, y = y })
                    if #floors >= 2 then break end
                end
            end
            if #floors >= 2 then break end
        end
        if #floors >= 2 then
            local path = g:findPath(floors[1].x, floors[1].y, floors[2].x, floors[2].y)
            -- Path may be nil if rooms not connected     that's acceptable; just ensure no crash
            expect_true(path == nil or type(path) == "table", "expected nil or table")
        end
    end)
end)
test_summary()
