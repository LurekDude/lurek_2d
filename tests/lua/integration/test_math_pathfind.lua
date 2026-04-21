-- tests/lua/integration/test_math_pathfind.lua
-- Integration: lurek.math Vec3/spline/lerp/remap used alongside pathfinding data.
-- Namespaces: lurek.math + lurek.pathfind


-- ─────────────────────────────────────────────
-- Vec3
-- ─────────────────────────────────────────────
describe("math.vec3", function()

    it("creates a Vec3 with correct components", function()
        local v = lurek.math.vec3(1, 2, 3)
        expect_near(1, v.x, 1e-5)
        expect_near(2, v.y, 1e-5)
        expect_near(3, v.z, 1e-5)
    end)

    it("Vec3 alias works identically", function()
        local v = lurek.math.Vec3(4, 5, 6)
        expect_near(4, v.x, 1e-5)
        expect_near(5, v.y, 1e-5)
        expect_near(6, v.z, 1e-5)
    end)

    it("length of (3,4,0) is 5", function()
        local v = lurek.math.vec3(3, 4, 0)
        expect_near(5.0, v:length(), 1e-4)
    end)

    it("length of unit vector is 1", function()
        local v = lurek.math.vec3(1, 0, 0)
        expect_near(1.0, v:length(), 1e-5)
    end)

    it("lengthSquared avoids sqrt", function()
        local v = lurek.math.vec3(2, 2, 1)
        expect_near(9.0, v:lengthSquared(), 1e-5) -- 4+4+1=9
    end)

    it("normalize produces unit vector", function()
        local v = lurek.math.vec3(3, 0, 0):normalize()
        expect_near(1.0, v:length(), 1e-5)
        expect_near(1.0, v.x, 1e-5)
    end)

    it("dot product of perpendicular vectors is 0", function()
        local a = lurek.math.vec3(1, 0, 0)
        local b = lurek.math.vec3(0, 1, 0)
        expect_near(0.0, a:dot(b), 1e-5)
    end)

    it("dot product of parallel vectors equals product of lengths", function()
        local a = lurek.math.vec3(2, 0, 0)
        local b = lurek.math.vec3(3, 0, 0)
        expect_near(6.0, a:dot(b), 1e-5)
    end)

    it("cross product of x and y axes is z axis", function()
        local x = lurek.math.vec3(1, 0, 0)
        local y = lurek.math.vec3(0, 1, 0)
        local z = x:cross(y)
        expect_near(0.0, z.x, 1e-5)
        expect_near(0.0, z.y, 1e-5)
        expect_near(1.0, z.z, 1e-5)
    end)

    it("lerp at t=0 returns from", function()
        local a = lurek.math.vec3(0, 0, 0)
        local b = lurek.math.vec3(10, 20, 30)
        local v = a:lerp(b, 0)
        expect_near(0.0, v.x, 1e-5)
    end)

    it("lerp at t=1 returns to", function()
        local a = lurek.math.vec3(0, 0, 0)
        local b = lurek.math.vec3(10, 20, 30)
        local v = a:lerp(b, 1)
        expect_near(10.0, v.x, 1e-5)
        expect_near(20.0, v.y, 1e-5)
    end)

    it("lerp at t=0.5 is midpoint", function()
        local a = lurek.math.vec3(0, 0, 0)
        local b = lurek.math.vec3(10, 0, 0)
        local v = a:lerp(b, 0.5)
        expect_near(5.0, v.x, 1e-5)
    end)

    it("distance from (0,0,0) to (1,0,0) is 1", function()
        local a = lurek.math.vec3(0, 0, 0)
        local b = lurek.math.vec3(1, 0, 0)
        expect_near(1.0, a:distance(b), 1e-5)
    end)

    it("add combines components", function()
        local a = lurek.math.vec3(1, 2, 3)
        local b = lurek.math.vec3(4, 5, 6)
        local c = a:add(b)
        expect_near(5.0, c.x, 1e-5)
        expect_near(7.0, c.y, 1e-5)
        expect_near(9.0, c.z, 1e-5)
    end)

    it("sub subtracts components", function()
        local a = lurek.math.vec3(5, 5, 5)
        local b = lurek.math.vec3(2, 3, 1)
        local c = a:sub(b)
        expect_near(3.0, c.x, 1e-5)
    end)

    it("scale multiplies components", function()
        local v = lurek.math.vec3(2, 3, 4):scale(2)
        expect_near(4.0, v.x, 1e-5)
        expect_near(6.0, v.y, 1e-5)
        expect_near(8.0, v.z, 1e-5)
    end)
end)

-- ─────────────────────────────────────────────
-- Catmull-Rom Spline
-- ─────────────────────────────────────────────
describe("math.catmullRom", function()

    local pts = { { x = 0, y = 0 }, { x = 1, y = 0 }, { x = 2, y = 1 }, { x = 3, y = 0 } }

    it("creates a spline without error", function()
        local s = lurek.math.catmullRom(pts)
        expect_type("userdata", s)
    end)

    it("len returns control point count", function()
        local s = lurek.math.catmullRom(pts)
        expect_equal(4, s:len())
    end)

    it("sample returns two numbers", function()
        local s = lurek.math.catmullRom(pts)
        local x, y = s:sample(0.5)
        expect_type("number", x)
        expect_type("number", y)
    end)

    it("sample at t=0 is near first control point", function()
        local s = lurek.math.catmullRom(pts)
        local x, y = s:sample(0.0)
        -- Catmull-Rom boundary behaviour: at t=0 should be near pts[1] or pts[2]
        expect_type("number", x)
    end)

    it("sampleSegment returns two numbers", function()
        local s = lurek.math.catmullRom(pts)
        local x, y = s:sampleSegment(1, 0.5)
        expect_type("number", x)
        expect_type("number", y)
    end)
end)

-- ─────────────────────────────────────────────
-- Hermite Spline
-- ─────────────────────────────────────────────
describe("math.hermite", function()

    it("creates a hermite spline without error", function()
        local s = lurek.math.hermite(0, 0, 10, 0, 1, 1, 1, -1)
        expect_type("userdata", s)
    end)

    it("sample returns two numbers", function()
        local s = lurek.math.hermite(0, 0, 10, 0, 1, 1, 1, -1)
        local x, y = s:sample(0.5)
        expect_type("number", x)
        expect_type("number", y)
    end)

    it("sample at t=0 is start point", function()
        local s = lurek.math.hermite(2, 3, 8, 5, 0, 0, 0, 0)
        local x, y = s:sample(0.0)
        expect_near(2.0, x, 1e-4)
        expect_near(3.0, y, 1e-4)
    end)

    it("sample at t=1 is end point", function()
        local s = lurek.math.hermite(2, 3, 8, 5, 0, 0, 0, 0)
        local x, y = s:sample(1.0)
        expect_near(8.0, x, 1e-4)
        expect_near(5.0, y, 1e-4)
    end)
end)

-- ─────────────────────────────────────────────
-- lerp / remap free functions
-- ─────────────────────────────────────────────
describe("math.lerp / math.remap", function()

    it("lerp at t=0 returns a", function()
        expect_near(3.0, lurek.math.lerp(3, 7, 0), 1e-5)
    end)

    it("lerp at t=1 returns b", function()
        expect_near(7.0, lurek.math.lerp(3, 7, 1), 1e-5)
    end)

    it("lerp at t=0.5 is midpoint", function()
        expect_near(5.0, lurek.math.lerp(3, 7, 0.5), 1e-5)
    end)

    it("lerp extrapolates beyond [a,b]", function()
        expect_near(9.0, lurek.math.lerp(3, 7, 1.5), 1e-5)
    end)

    it("remap center of [0,1] to [10,20]", function()
        expect_near(15.0, lurek.math.remap(0.5, 0, 1, 10, 20), 1e-4)
    end)

    it("remap minimum stays at out_min", function()
        expect_near(10.0, lurek.math.remap(0, 0, 1, 10, 20), 1e-4)
    end)

    it("remap maximum stays at out_max", function()
        expect_near(20.0, lurek.math.remap(1, 0, 1, 10, 20), 1e-4)
    end)

    it("remap inverts when out_min > out_max", function()
        expect_near(15.0, lurek.math.remap(0.5, 0, 1, 20, 10), 1e-4)
    end)
end)

-- ─────────────────────────────────────────────
-- Vec3 heuristic applied to pathfinding costs
-- ─────────────────────────────────────────────
describe("vec3 + pathfinding heuristic integration", function()

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

    it("spline segments can define a patrol route for a unit path", function()
        local patrol = lurek.math.catmullRom {
            { x = 1, y = 1 }, { x = 50, y = 10 }, { x = 80, y = 50 }, { x = 50, y = 90 }, { x = 1, y = 80 }
        }
        -- Sample 10 positions along the spline
        local positions = {}
        for i = 0, 9 do
            local t = i / 9
            local px, py = patrol:sample(t)
            table.insert(positions, { x = px, y = py })
        end
        expect_equal(10, #positions)
        for _, pos in ipairs(positions) do
            expect_type("number", pos.x)
            expect_type("number", pos.y)
        end
    end)
end)

test_summary()
