-- Integration: pathfinding results reflected on minimap overlays

local function path_to_points(path)
    local points = {}
    for index, node in ipairs(path) do
        points[index] = { node.x, node.y }
    end
    return points
end

local function path_signature(path)
    local out = {}
    for i, node in ipairs(path) do
        out[i] = tostring(node.x) .. ":" .. tostring(node.y)
    end
    return table.concat(out, "|")
end

local function assert_path_valid(path, sx, sy, ex, ey)
    expect_true(path ~= nil, "path should exist")
    expect_true(#path > 0, "path should not be empty")
    for i, node in ipairs(path) do
        expect_type("table", node)
        expect_type("number", node.x)
        expect_type("number", node.y)
        if i > 1 then
            local prev = path[i - 1]
            local dx = math.abs(node.x - prev.x)
            local dy = math.abs(node.y - prev.y)
            expect_true(dx <= 1 and dy <= 1 and (dx + dy) > 0, "adjacent path nodes should be neighboring cells")
        end
    end
    expect_equal(sx, path[1].x)
    expect_equal(sy, path[1].y)
    expect_equal(ex, path[#path].x)
    expect_equal(ey, path[#path].y)
end


describe("minimap + pathfind integration", function()
    -- @integration LUnitPathfinder:findPath
    -- @integration LMinimap:showPath
    -- @integration lurek.minimap.newMinimap
    -- @integration lurek.pathfind.newNavGrid
    -- @integration lurek.pathfind.newPathfinder
    it("computed path nodes can be pushed to the minimap as a route overlay", function()
        local grid = lurek.pathfind.newNavGrid(8, 8)
        local pf = lurek.pathfind.newPathfinder(grid)
        local minimap = lurek.minimap.newMinimap(8, 8, 80, 80)
        local path = pf:findPath(1, 1, 8, 8)

        assert_path_valid(path, 1, 1, 8, 8)

        local overlay_id = minimap:showPath(path_to_points(path), {255, 0, 0, 255})

        expect_type("number", overlay_id)
        expect_true(overlay_id > 0)
    end)

    -- @integration LUnitPathfinder:findPath
    -- @integration LMinimap:clearPath
    -- @integration LMinimap:showPath
    -- @integration lurek.minimap.newMinimap
    -- @integration lurek.pathfind.newNavGrid
    -- @integration lurek.pathfind.newPathfinder
    it("minimap accepts a replacement overlay when path target changes", function()
        local grid = lurek.pathfind.newNavGrid(8, 8)
        local pf = lurek.pathfind.newPathfinder(grid)
        local minimap = lurek.minimap.newMinimap(8, 8, 80, 80)
        local first_path = pf:findPath(1, 1, 8, 1)
        assert_path_valid(first_path, 1, 1, 8, 1)
        local first_sig = path_signature(first_path)
        local first_id = minimap:showPath(path_to_points(first_path), {255, 0, 0, 255})

        local second_path = pf:findPath(1, 1, 8, 8)
        assert_path_valid(second_path, 1, 1, 8, 8)
        local second_sig = path_signature(second_path)

        minimap:clearPath(first_id)
        local second_id = minimap:showPath(path_to_points(second_path), {0, 255, 0, 255})

        expect_type("number", first_id)
        expect_true(first_id > 0)
        expect_type("number", second_id)
        expect_true(second_id > 0)
        expect_not_equal(first_sig, second_sig)
    end)

    -- @integration LNavGrid:isBlocked
    -- @integration LNavGrid:setBlocked
    -- @integration LUnitPathfinder:findPath
    -- @integration LMinimap:getTerrain
    -- @integration LMinimap:setTerrain
    -- @integration lurek.minimap.newMinimap
    -- @integration lurek.pathfind.newNavGrid
    -- @integration lurek.pathfind.newPathfinder
    it("blocked cells on the minimap stay aligned with pathfind impassable nodes", function()
        local grid = lurek.pathfind.newNavGrid(6, 6)
        local pf = lurek.pathfind.newPathfinder(grid)
        local minimap = lurek.minimap.newMinimap(6, 6, 60, 60)

        for y = 1, 6 do
            grid:setBlocked(4, y, true)
            minimap:setTerrain(4, y, 9)
        end
        grid:setBlocked(4, 3, false)
        minimap:setTerrain(4, 3, 0)

        local path = pf:findPath(1, 1, 6, 6)
        assert_path_valid(path, 1, 1, 6, 6)
        local used_gap = false

        expect_true(grid:isBlocked(4, 2))
        expect_equal(9, minimap:getTerrain(4, 2))
        expect_false(grid:isBlocked(4, 3))
        expect_equal(0, minimap:getTerrain(4, 3))

        for _, node in ipairs(path) do
            expect_true(minimap:getTerrain(node.x, node.y) ~= 9, "path should not cross minimap-blocked terrain")
            if node.x == 4 and node.y == 3 then
                used_gap = true
            end
        end

        expect_true(used_gap, "path should pass through the shared open gap")
    end)
end)
test_summary()
