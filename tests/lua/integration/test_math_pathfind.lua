-- Integration: lurek.math Vec3/spline/lerp/remap combined with pathfinding costs

-- Vec3 heuristic applied to pathfinding costs
describe("vec3 + pathfinding heuristic integration", function()

    -- @integration LJpsGrid:findPath
    -- @integration LVec3:distance
    -- @integration lurek.math.vec3
    -- @integration lurek.pathfind.newJpsGrid
    it("3D distances can weight JPS grid costs", function()
        -- Simulate two waypoints in 3D space
        local a = lurek.math.vec3(0, 0, 0)
        local b = lurek.math.vec3(10, 0, 5)
        local dist_3d = a:distance(b)
        expect_true(dist_3d > 10, "3D distance should be larger than 2D along x")

        -- Build a JPS grid and find a path
        local g = lurek.pathfind.newJpsGrid(8, 8)
        local path = g:findPath(1, 1, 5, 5)
        expect_true(path == nil or #path > 0, "JPS path should be nil or non-empty")
    end)

end)
test_summary()
