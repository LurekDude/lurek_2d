-- Integration: JPS grid pathfinding with procgen world graphs

-- JPS Grid + WorldGraph produced by procgen
describe("procgen worldGraph + JPS grid integration", function()

    -- @integration LJpsGrid:findPath
    -- @integration LJpsGrid:setBlocked
    -- @integration lurek.pathfind.newJpsGrid
    -- @integration lurek.procgen.roomsDungeon
    it("room floors are navigable via JPS grid", function()
        local d = lurek.procgen.roomsDungeon({ width = 20, height = 16, max_rooms = 4, seed = 7 })
        -- Build a JPS grid from the dungeon's floor plan
        local g = lurek.pathfind.newJpsGrid(d.width, d.height)
        for y = 1, d.height do
            for x = 1, d.width do
                local idx = (y - 1) * d.width + x
                -- False = wall -> blocked
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
            expect_not_nil(path, "adjacent floor cells should produce a path")
            expect_true(#path > 0, "path between floor cells should not be empty")
        end
    end)
end)
test_summary()
