-- tests/lua/integration/test_pathfind_hexmap.lua
-- Unit: lurek.pathfind hexGrid + rangeMap
-- Namespaces: lurek.pathfind


--
-- Hex Grid
--
-- @describe pathfinding.newHexGrid
describe("pathfinding.newHexGrid", function()

    -- @covers lurek.pathfind.newHexGrid
    it("creates a hex grid without error", function()
        local g = lurek.pathfind.newHexGrid(10, 10, "flat")
        expect_type("userdata", g)
    end)

    -- @covers lurek.pathfind.newHexGrid
    it("pointy layout also works", function()
        local g = lurek.pathfind.newHexGrid(8, 8, "pointy")
        expect_type("userdata", g)
    end)

    -- @covers lurek.pathfind.newHexGrid
    it("default layout works with no third argument", function()
        local g = lurek.pathfind.newHexGrid(6, 6)
        expect_type("userdata", g)
    end)

    -- @covers LHexGrid:isBlocked
    -- @covers LHexGrid:setBlocked
    it("setBlocked and isBlocked round-trip", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        g:setBlocked(3, 3, true)
        expect_equal(true, g:isBlocked(3, 3))
        g:setBlocked(3, 3, false)
        expect_equal(false, g:isBlocked(3, 3))
    end)

    -- @covers LHexGrid:findPath
    -- @covers LHexGrid:setBlocked
    it("findPath returns nil when blocked", function()
        local g = lurek.pathfind.newHexGrid(6, 6)
        -- Block every path from (1,1) to (6,6)
        for row = 1, 6 do
            for col = 2, 5 do
                g:setBlocked(col, row, true)
            end
        end
        local path = g:findPath(1, 1, 6, 6)
        expect_nil(path, "separating wall should make target unreachable")
    end)

    -- @covers LHexGrid:findPath
    it("findPath returns a path on an open grid", function()
        local g = lurek.pathfind.newHexGrid(10, 10)
        local path = g:findPath(1, 1, 5, 5)
        expect_true(path ~= nil, "expected path on open grid")
        expect_true(#path >= 1, "path must have at least one step")
    end)

    -- @covers LHexGrid:findPath
    it("path cells have col and row fields", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        local path = g:findPath(1, 1, 4, 4)
        expect_not_nil(path, "open grid should produce a path")
        expect_true(#path > 0, "path should contain at least one cell")
        local cell = path[1]
        expect_type("number", cell.col)
        expect_type("number", cell.row)
    end)

    -- @covers LHexGrid:lineOfSight
    -- @covers LHexGrid:setBlocked
    it("lineOfSight returns false through a blocked wall", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        for row = 1, 8 do
            g:setBlocked(4, row, true)
        end
        local los = g:lineOfSight(1, 4, 8, 4)
        expect_equal(false, los)
    end)

    -- @covers LHexGrid:lineOfSight
    it("lineOfSight returns true in open space", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        local los = g:lineOfSight(1, 1, 2, 2)
        expect_equal(true, los)
    end)

    -- @covers LHexGrid:fieldOfView
    it("fieldOfView returns cells within radius", function()
        local g = lurek.pathfind.newHexGrid(10, 10)
        local fov = g:fieldOfView(5, 5, 2)
        expect_type("table", fov)
        expect_true(#fov > 0, "expected at least one cell in FOV")
        for _, c in ipairs(fov) do
            expect_type("number", c.col)
            expect_type("number", c.row)
        end
    end)

    -- @covers LHexGrid:rangeOfMovement
    it("rangeOfMovement returns cells within budget", function()
        local g = lurek.pathfind.newHexGrid(10, 10)
        local cells = g:rangeOfMovement(5, 5, 3.0)
        expect_type("table", cells)
        expect_true(#cells > 0, "expected at least one reachable cell")
    end)

    -- @covers LHexGrid:rangeOfMovement
    -- @covers LHexGrid:setBlocked
    it("rangeOfMovement limited by walls", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        -- Completely surround origin
        for col = 3, 5 do
            for row = 3, 5 do
                if not (col == 4 and row == 4) then
                    g:setBlocked(col, row, true)
                end
            end
        end
        local cells_open = lurek.pathfind.newHexGrid(8, 8):rangeOfMovement(4, 4, 5)
        local cells_blocked = g:rangeOfMovement(4, 4, 5)
        expect_true(#cells_blocked <= #cells_open, "blocked grid should have fewer reachable cells")
    end)

    -- @covers LHexGrid:distance
    it("distance between adjacent cells is 1", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        local d = g:distance(3, 3, 4, 3)
        expect_equal(1, d)
    end)
end)

--
-- Range Map
--
-- @describe pathfinding.rangeMap
describe("pathfinding.rangeMap", function()

    -- @covers lurek.pathfind.rangeMap
    it("returns cells, width, height", function()
        local result = lurek.pathfind.rangeMap({
            width = 10, height = 10,
            origin_x = 5, origin_y = 5,
            budget = 3.0
        })
        expect_type("table", result.cells)
        expect_equal(10, result.width)
        expect_equal(10, result.height)
    end)

    -- @covers lurek.pathfind.rangeMap
    it("cells have x, y, cost fields", function()
        local result = lurek.pathfind.rangeMap({
            width = 8, height = 8,
            origin_x = 4, origin_y = 4,
            budget = 2.0
        })
        expect_true(#result.cells > 0, "rangeMap should return at least one cell")
        local c = result.cells[1]
        expect_type("number", c.x)
        expect_type("number", c.y)
        expect_type("number", c.cost)
    end)

    -- @covers lurek.pathfind.rangeMap
    it("origin cell has cost 0", function()
        local result = lurek.pathfind.rangeMap({
            width = 8, height = 8,
            origin_x = 4, origin_y = 4,
            budget = 2.0
        })
        local found_origin = false
        for _, c in ipairs(result.cells) do
            if c.x == 4 and c.y == 4 then
                expect_near(0.0, c.cost, 1e-5)
                found_origin = true
            end
        end
        expect_true(found_origin, "origin cell should be in reachable list")
    end)

    -- @covers lurek.pathfind.rangeMap
    it("blocked cells are excluded", function()
        local blocked = {}
        for i = 1, 8 * 8 do blocked[i] = false end
        -- Block everything around origin
        for x = 3, 5 do
            for y = 3, 5 do
                if not (x == 4 and y == 4) then
                    blocked[(y - 1) * 8 + x] = true
                end
            end
        end
        local result = lurek.pathfind.rangeMap({
            width = 8, height = 8,
            blocked = blocked,
            origin_x = 4, origin_y = 4,
            budget = 5.0
        })
        -- Should only reach origin in a completely enclosed space
        local outside_origin = false
        for _, c in ipairs(result.cells) do
            if c.x ~= 4 or c.y ~= 4 then outside_origin = true end
        end
        expect_equal(false, outside_origin)
    end)

    -- @covers lurek.pathfind.rangeMap
    it("budget constrains reachable distance", function()
        local r3 = lurek.pathfind.rangeMap({ width = 12, height = 12, origin_x = 6, origin_y = 6, budget = 3.0 })
        local r6 = lurek.pathfind.rangeMap({ width = 12, height = 12, origin_x = 6, origin_y = 6, budget = 6.0 })
        expect_true(#r6.cells >= #r3.cells, "larger budget should reach at least as many cells")
    end)
end)
test_summary()
