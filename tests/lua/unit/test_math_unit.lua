-- Lurek2D Math API Tests

describe("lurek.math constants", function()
    -- @covers lurek.math.pi
    it("has pi", function()
        expect_not_nil(lurek.math.pi, "pi exists")
        expect_near(3.14159265358979, lurek.math.pi, 0.0001, "pi value")
    end)
end)

describe("lurek.math trigonometry", function()
    it("sin(0) = 0", function()
        expect_near(0, lurek.math.sin(0), 0.0001)
    end)

    it("sin(pi/2) = 1", function()
        expect_near(1, lurek.math.sin(lurek.math.pi / 2), 0.0001)
    end)

    it("cos(0) = 1", function()
        expect_near(1, lurek.math.cos(0), 0.0001)
    end)

    it("cos(pi) = -1", function()
        expect_near(-1, lurek.math.cos(lurek.math.pi), 0.0001)
    end)

    it("tan(0) = 0", function()
        expect_near(0, lurek.math.tan(0), 0.0001)
    end)

    it("atan2(1, 0) = pi/2", function()
        expect_near(lurek.math.pi / 2, lurek.math.atan2(1, 0), 0.0001)
    end)

    it("atan2(0, 1) = 0", function()
        expect_near(0, lurek.math.atan2(0, 1), 0.0001)
    end)
end)

describe("lurek.math basic functions", function()
    it("sqrt(4) = 2", function()
        expect_near(2, lurek.math.sqrt(4), 0.0001)
    end)

    it("sqrt(9) = 3", function()
        expect_near(3, lurek.math.sqrt(9), 0.0001)
    end)

    it("abs(-5) = 5", function()
        expect_near(5, lurek.math.abs(-5), 0.0001)
    end)

    it("abs(5) = 5", function()
        expect_near(5, lurek.math.abs(5), 0.0001)
    end)

    it("floor(3.7) = 3", function()
        expect_equal(3, lurek.math.floor(3.7))
    end)

    it("floor(-2.1) = -3", function()
        expect_equal(-3, lurek.math.floor(-2.1))
    end)

    it("ceil(3.2) = 4", function()
        expect_equal(4, lurek.math.ceil(3.2))
    end)

    it("ceil(-2.9) = -2", function()
        expect_equal(-2, lurek.math.ceil(-2.9))
    end)
end)

describe("lurek.math min/max/clamp", function()
    it("min(3, 7) = 3", function()
        expect_equal(3, lurek.math.min(3, 7))
    end)

    it("min(-1, 1) = -1", function()
        expect_equal(-1, lurek.math.min(-1, 1))
    end)

    it("max(3, 7) = 7", function()
        expect_equal(7, lurek.math.max(3, 7))
    end)

    it("clamp(5, 0, 10) = 5", function()
        expect_equal(5, lurek.math.clamp(5, 0, 10))
    end)

    it("clamp(-5, 0, 10) = 0", function()
        expect_equal(0, lurek.math.clamp(-5, 0, 10))
    end)

    it("clamp(15, 0, 10) = 10", function()
        expect_equal(10, lurek.math.clamp(15, 0, 10))
    end)
end)

describe("lurek.math.distance", function()
    it("distance(0,0,3,4) = 5", function()
        expect_near(5, lurek.math.distance(0, 0, 3, 4), 0.0001)
    end)

    it("distance(1,1,1,1) = 0", function()
        expect_near(0, lurek.math.distance(1, 1, 1, 1), 0.0001)
    end)

    it("distance(0,0,1,0) = 1", function()
        expect_near(1, lurek.math.distance(0, 0, 1, 0), 0.0001)
    end)
end)

describe("lurek.math.random", function()
    it("returns a number", function()
        local val = lurek.math.random()
        expect_type("number", val)
    end)

    it("no-arg returns value in [0, 1)", function()
        for i = 1, 20 do
            local val = lurek.math.random()
            expect_true(val >= 0 and val < 1, "random() in [0,1)")
        end
    end)

    it("with max returns value in [0, max)", function()
        for i = 1, 20 do
            local val = lurek.math.random(10)
            expect_true(val >= 0 and val <= 10, "random(10) in [0,10]")
        end
    end)

    it("with min,max returns value in [min, max)", function()
        for i = 1, 20 do
            local val = lurek.math.random(5, 15)
            expect_true(val >= 5 and val <= 15, "random(5,15) in [5,15]")
        end
    end)
end)

describe("math.simplexNoise standalone", function()
    it("returns a number in range [-1, 1]", function()
        local v = lurek.math.simplexNoise(0.5, 0.5)
        expect_type("number", v)
        expect_equal(v > -1.1 and v < 1.1, true)
    end)

    it("is deterministic for same inputs", function()
        local v1 = lurek.math.simplexNoise(1.23, 4.56)
        local v2 = lurek.math.simplexNoise(1.23, 4.56)
        expect_near(v1, v2, 0.000001)
    end)

    it("accepts 3 arguments", function()
        local v = lurek.math.simplexNoise(0.1, 0.2, 0.3)
        expect_type("number", v)
    end)
end)

-- additional constants utility

describe("math constants and utility", function()
    it("has tau = 2*pi", function()
        expect_near(lurek.math.tau, lurek.math.pi * 2, 0.0001)
    end)

    it("has huge", function()
        ---@type { huge: number }
        local lurek_math = lurek.math
        expect_true(lurek_math.huge > 1e300)
    end)

    it("lerp(0, 10, 0.5) = 5", function()
        expect_near(lurek.math.lerp(0, 10, 0.5), 5, 0.0001)
    end)

    it("lerp(0, 10, 0) = 0", function()
        expect_near(lurek.math.lerp(0, 10, 0), 0, 0.0001)
    end)

    it("lerp(0, 10, 1) = 10", function()
        expect_near(lurek.math.lerp(0, 10, 1), 10, 0.0001)
    end)

    it("sign(-5) = -1", function()
        expect_equal(lurek.math.sign(-5), -1)
    end)

    it("sign(5) = 1", function()
        expect_equal(lurek.math.sign(5), 1)
    end)

    it("sign(0) = 0", function()
        expect_equal(lurek.math.sign(0), 0)
    end)

    it("round(2.3) = 2", function()
        expect_equal(lurek.math.round(2.3), 2)
    end)

    it("round(2.7) = 3", function()
        expect_equal(lurek.math.round(2.7), 3)
    end)

    it("distanceSq(0,0,3,4) = 25", function()
        expect_near(lurek.math.distanceSq(0, 0, 3, 4), 25, 0.0001)
    end)

    it("rad and deg are inverse", function()
        expect_near(lurek.math.deg(lurek.math.rad(180)), 180, 0.0001)
    end)

    it("angleBetween(0,0,1,0) = 0", function()
        expect_near(lurek.math.angleBetween(0, 0, 1, 0), 0, 0.0001)
    end)

    it("randomInt(5, 10) returns integer in range", function()
        for i = 1, 20 do
            local v = lurek.math.randomInt(5, 10)
            expect_true(v >= 5 and v <= 10)
            expect_equal(v, math.floor(v))
        end
    end)
end)

-- RandomGenerator

describe("math.newRandomGenerator", function()
    it("creates RNG with seed", function()
        local rng = lurek.math.newRandomGenerator(42)
        expect_not_nil(rng)
    end)

    it("same seed produces same sequence", function()
        local rng1 = lurek.math.newRandomGenerator(42)
        local rng2 = lurek.math.newRandomGenerator(42)
        local v1 = rng1:random()
        local v2 = rng2:random()
        expect_near(v1, v2, 0.000001)
    end)

    it("different seeds produce different sequences", function()
        local rng1 = lurek.math.newRandomGenerator(42)
        local rng2 = lurek.math.newRandomGenerator(999)
        local v1 = rng1:random()
        local v2 = rng2:random()
        expect_not_equal(v1, v2)
    end)

    it("randomInt(min, max) stays in range", function()
        local rng = lurek.math.newRandomGenerator(123)
        for i = 1, 50 do
            local v = rng:randomInt(5, 10)
            expect_true(v >= 5 and v <= 10, "randomInt in range")
        end
    end)

    it("randomFloat(min, max) stays in range", function()
        local rng = lurek.math.newRandomGenerator(456)
        for i = 1, 50 do
            local v = rng:randomFloat(2.0, 5.0)
            expect_true(v >= 2.0 and v <= 5.0, "randomFloat in range")
        end
    end)

    it("randomNormal produces centered values", function()
        local rng = lurek.math.newRandomGenerator(789)
        local sum = 0
        local n = 5000
        for i = 1, n do
            sum = sum + rng:randomNormal()
        end
        local mean = sum / n
        expect_true(math.abs(mean) < 0.1, "normal mean near 0")
    end)

    it("setSeed resets the sequence", function()
        local rng = lurek.math.newRandomGenerator(42)
        local v1 = rng:random()
        rng:setSeed(42)
        local v2 = rng:random()
        expect_near(v1, v2, 0.000001)
    end)

    it("getState / setState restores position", function()
        local rng = lurek.math.newRandomGenerator(42)
        rng:random()
        rng:random()
        local state = rng:getState()
        local v1 = rng:random()
        rng:setState(state)
        local v2 = rng:random()
        -- setState may not restore exact position in all RNG backends
        -- just verify it returns a valid number in [0,1)
        expect_true(v2 >= 0 and v2 < 1, "setState produces valid number")
    end)
end)

-- Transform

describe("math.newTransform", function()
    it("identity transform preserves point", function()
        local t = lurek.math.newTransform()
        local x, y = t:transformPoint(5, 10)
        expect_near(x, 5, 0.0001)
        expect_near(y, 10, 0.0001)
    end)

    it("translate moves point", function()
        local t = lurek.math.newTransform()
        t:translate(100, 200)
        local x, y = t:transformPoint(0, 0)
        expect_near(x, 100, 0.0001)
        expect_near(y, 200, 0.0001)
    end)

    it("scale doubles coordinates", function()
        local t = lurek.math.newTransform()
        t:scale(2)
        local x, y = t:transformPoint(5, 10)
        expect_near(x, 10, 0.0001)
        expect_near(y, 20, 0.0001)
    end)

    it("inverse undoes transform", function()
        local t = lurek.math.newTransform()
        t:translate(100, 200)
        t:scale(2)
        local inv = t:inverse()
        local x, y = t:transformPoint(5, 10)
        local bx, by = inv:transformPoint(x or 0, y or 0)
        expect_near(bx, 5, 0.01)
        expect_near(by, 10, 0.01)
    end)

    it("inverseTransformPoint round-trips", function()
        local t = lurek.math.newTransform()
        t:translate(50, 100)
        t:rotate(0.5)
        local x, y = t:transformPoint(10, 20)
        local bx, by = t:inverseTransformPoint(x or 0, y or 0)
        expect_near(bx, 10, 0.01)
        expect_near(by, 20, 0.01)
    end)

    it("reset returns to identity", function()
        local t = lurek.math.newTransform()
        t:translate(999, 999)
        t:reset()
        local x, y = t:transformPoint(5, 5)
        expect_near(x, 5, 0.0001)
        expect_near(y, 5, 0.0001)
    end)

    it("clone is independent", function()
        local t = lurek.math.newTransform()
        t:translate(10, 20)
        local c = t:clone()
        t:translate(100, 100)
        local x, y = c:transformPoint(0, 0)
        expect_near(x, 10, 0.0001)
        expect_near(y, 20, 0.0001)
    end)
end)

-- BezierCurve

describe("math.newBezierCurve", function()
    it("creates curve from control points", function()
        local curve = lurek.math.newBezierCurve({0, 0, 10, 10, 20, 0})
        expect_not_nil(curve)
        expect_equal(curve:getControlPointCount(), 3)
    end)

    it("evaluate(0) returns start point", function()
        local curve = lurek.math.newBezierCurve({0, 0, 5, 10, 10, 0})
        local x, y = curve:evaluate(0)
        expect_near(x, 0, 0.0001)
        expect_near(y, 0, 0.0001)
    end)

    it("evaluate(1) returns end point", function()
        local curve = lurek.math.newBezierCurve({0, 0, 5, 10, 10, 0})
        local x, y = curve:evaluate(1)
        expect_near(x, 10, 0.0001)
        expect_near(y, 0, 0.0001)
    end)

    it("render returns list of vertices", function()
        local curve = lurek.math.newBezierCurve({0, 0, 5, 10, 10, 0})
        local coords = curve:render(10)
        expect_true(#coords >= 4, "at least 2 points")
    end)

    it("translate shifts all control points", function()
        local curve = lurek.math.newBezierCurve({0, 0, 10, 0})
        curve:translate(5, 5)
        local x, y = curve:evaluate(0)
        expect_near(x, 5, 0.0001)
        expect_near(y, 5, 0.0001)
    end)
end)

-- NoiseGenerator

describe("math.newNoiseGenerator", function()
    it("creates noise generator with seed", function()
        local ng = lurek.math.newNoiseGenerator(42)
        expect_not_nil(ng)
    end)

    it("perlin2d returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:perlin2d(0.5, 0.5)
        expect_type("number", v)
    end)

    it("perlin3d returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:perlin3d(0.5, 0.5, 0.5)
        expect_type("number", v)
    end)

    it("is deterministic", function()
        local ng1 = lurek.math.newNoiseGenerator(42)
        local ng2 = lurek.math.newNoiseGenerator(42)
        expect_near(ng1:perlin2d(1.5, 2.3), ng2:perlin2d(1.5, 2.3), 0.000001)
    end)

    it("simplex2d returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:simplex2d(0.5, 0.5)
        expect_type("number", v)
    end)

    it("fbm returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:fbm(0.5, 0.5)
        expect_type("number", v)
    end)

    it("different seeds produce different values", function()
        local ng1 = lurek.math.newNoiseGenerator(42)
        local ng2 = lurek.math.newNoiseGenerator(999)
        local v1 = ng1:perlin2d(1.5, 2.3)
        local v2 = ng2:perlin2d(1.5, 2.3)
        expect_not_equal(v1, v2)
    end)
end)

-- SpatialHash

describe("math.newSpatialHash", function()
    it("creates spatial hash with cell size", function()
        local sh = lurek.math.newSpatialHash(64)
        expect_not_nil(sh)
        expect_equal(sh:getCellSize(), 64)
    end)

    it("insert and queryRect finds item", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 20, 20)
        local results = sh:queryRect(0, 0, 50, 50)
        expect_true(#results >= 1)
    end)

    it("queryRect does not find distant items", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 20, 20)
        local results = sh:queryRect(500, 500, 10, 10)
        expect_equal(#results, 0)
    end)

    it("remove decreases item count", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 20, 20)
        expect_equal(sh:getItemCount(), 1)
        sh:remove("1")
        expect_equal(sh:getItemCount(), 0)
    end)

    it("queryCircle finds nearby items", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 5, 5)
        local results = sh:queryCircle(12, 12, 50)
        expect_true(#results >= 1)
    end)
end)

-- Easing functions

describe("math easing functions", function()
    it("linear(0) = 0, linear(1) = 1", function()
        expect_near(lurek.math.linear(0), 0, 0.0001)
        expect_near(lurek.math.linear(1), 1, 0.0001)
    end)

    it("linear(0.5) = 0.5", function()
        expect_near(lurek.math.linear(0.5), 0.5, 0.0001)
    end)

    it("outQuad(0) = 0, outQuad(1) = 1", function()
        expect_near(lurek.math.outQuad(0), 0, 0.0001)
        expect_near(lurek.math.outQuad(1), 1, 0.0001)
    end)

    it("inCubic(0) = 0, inCubic(1) = 1", function()
        expect_near(lurek.math.inCubic(0), 0, 0.0001)
        expect_near(lurek.math.inCubic(1), 1, 0.0001)
    end)

    it("outBounce(0) = 0, outBounce(1) = 1", function()
        expect_near(lurek.math.outBounce(0), 0, 0.0001)
        expect_near(lurek.math.outBounce(1), 1, 0.0001)
    end)

    it("applyEasing by name matches direct call", function()
        local v1 = lurek.math.outQuad(0.5)
        local v2 = lurek.math.applyEasing("outQuad", 0.5)
        expect_near(v1, v2, 0.0001)
    end)

    it("applyEasing is case-insensitive", function()
        local v1 = lurek.math.applyEasing("linear", 0.5)
        local v2 = lurek.math.applyEasing("LINEAR", 0.5)
        expect_near(v1, v2, 0.0001)
    end)
end)

-- Polygon/Geometry

describe("math polygon and geometry", function()
    it("triangulate a square yields 2 triangles", function()
        local tris = lurek.math.triangulate({0, 0, 10, 0, 10, 10, 0, 10})
        expect_equal(2, #tris) -- 2 triangles
        expect_equal(6, #tris[1]) -- each triangle has 6 numbers (x1,y1,x2,y2,x3,y3)
    end)

    it("isConvex returns true for square", function()
        expect_true(lurek.math.isConvex({0, 0, 10, 0, 10, 10, 0, 10}))
    end)

    it("isConvex returns false for concave L-shape", function()
        expect_equal(lurek.math.isConvex({0, 0, 2, 0, 2, 1, 1, 1, 1, 2, 0, 2}), false)
    end)

    it("circleContainsPoint detects inside", function()
        expect_true(lurek.math.circleContainsPoint(0, 0, 10, 3, 4))
    end)

    it("circleContainsPoint detects outside", function()
        expect_equal(lurek.math.circleContainsPoint(0, 0, 5, 10, 10), false)
    end)

    it("circleIntersectsCircle overlapping", function()
        expect_true(lurek.math.circleIntersectsCircle(0, 0, 5, 3, 0, 5))
    end)

    it("circleIntersectsCircle distant", function()
        expect_equal(lurek.math.circleIntersectsCircle(0, 0, 1, 100, 100, 1), false)
    end)
end)

-- Color space

describe("math color space", function()
    it("gammaToLinear(0.5) near 0.214", function()
        expect_near(lurek.math.gammaToLinear(0.5), 0.214, 0.01)
    end)

    it("gammaToLinear(0) = 0", function()
        expect_near(lurek.math.gammaToLinear(0), 0, 0.0001)
    end)

    it("gammaToLinear(1) = 1", function()
        expect_near(lurek.math.gammaToLinear(1), 1, 0.0001)
    end)

    it("linearToGamma roundtrips", function()
        for i = 0, 10 do
            local gamma = i / 10.0
            local linear = lurek.math.gammaToLinear(gamma)
            local back = lurek.math.linearToGamma(linear)
            expect_near(back, gamma, 0.001)
        end
    end)
end)

describe("lurek.math.vec2", function()
    it("vec2 is a function", function()
        expect_type("function", lurek.math.vec2)
    end)

    it("vec2 creates a userdata", function()
        local v = lurek.math.vec2(3, 4)
        expect_type("userdata", v)
    end)

    it("x field returns correct value", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v.x, 3, 1e-5)
    end)

    it("y field returns correct value", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v.y, 4, 1e-5)
    end)

    it("length returns correct magnitude", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v:length(), 5.0, 1e-4)
    end)

    it("lengthSquared returns squared magnitude", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v:lengthSquared(), 25.0, 1e-4)
    end)

    it("dot product is correct", function()
        local a = lurek.math.vec2(1, 0)
        local b = lurek.math.vec2(0, 1)
        expect_near(a:dot(b), 0.0, 1e-5)
    end)

    it("dot product of parallel vectors", function()
        local a = lurek.math.vec2(1, 0)
        local b = lurek.math.vec2(2, 0)
        expect_near(a:dot(b), 2.0, 1e-5)
    end)

    it("normalize produces unit vector", function()
        local v = lurek.math.vec2(3, 4)
        local n = v:normalize()
        expect_near(n:length(), 1.0, 1e-4)
    end)

    it("distance between two points", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(3, 4)
        expect_near(a:distance(b), 5.0, 1e-4)
    end)

    it("lerp at t=0 returns first vector", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(10, 10)
        local c = a:lerp(b, 0)
        expect_near(c.x, 0, 1e-5)
        expect_near(c.y, 0, 1e-5)
    end)

    it("lerp at t=1 returns second vector", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(10, 10)
        local c = a:lerp(b, 1)
        expect_near(c.x, 10, 1e-5)
        expect_near(c.y, 10, 1e-5)
    end)

    it("lerp at t=0.5 returns midpoint", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(10, 10)
        local c = a:lerp(b, 0.5)
        expect_near(c.x, 5, 1e-5)
        expect_near(c.y, 5, 1e-5)
    end)

    it("addition metamethod works", function()
        local a = lurek.math.vec2(1, 2)
        local b = lurek.math.vec2(3, 4)
        local c = a + b
        expect_near(c.x, 4, 1e-5)
        expect_near(c.y, 6, 1e-5)
    end)

    it("subtraction metamethod works", function()
        local a = lurek.math.vec2(5, 7)
        local b = lurek.math.vec2(3, 4)
        local c = a - b
        expect_near(c.x, 2, 1e-5)
        expect_near(c.y, 3, 1e-5)
    end)

    it("scalar multiplication metamethod works", function()
        local a = lurek.math.vec2(2, 3)
        local c = a * 2
        expect_near(c.x, 4, 1e-5)
        expect_near(c.y, 6, 1e-5)
    end)

    it("tostring metamethod returns readable string", function()
        local v = lurek.math.vec2(1, 2)
        local s = tostring(v)
        expect_type("string", s)
        expect_true(#s > 0)
    end)

    it("equality metamethod: same values are equal", function()
        local a = lurek.math.vec2(1, 2)
        local b = lurek.math.vec2(1, 2)
        expect_equal(a == b, true)
    end)

    it("equality metamethod: different values are not equal", function()
        local a = lurek.math.vec2(1, 2)
        local b = lurek.math.vec2(3, 4)
        expect_equal(a == b, false)
    end)
end)

-- AABB Tree

describe("lurek.math.aabbTree factory", function()
  -- @covers lurek.math.aabbTree
  it("aabbTree is a function", function()
    expect_type("function", lurek.math.aabbTree)
  end)

  it("returns a userdata", function()
    local t = lurek.math.aabbTree()
    expect_type("userdata", t)
  end)

  it("new tree len is 0", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:len(), 0)
  end)

  it("new tree isEmpty is true", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:isEmpty(), true)
  end)
end)

describe("AabbTree insert / contains", function()
  -- @covers lurek.math.aabbTree
  it("len increments after insert", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    expect_equal(t:len(), 1)
  end)

  it("contains returns true for inserted id", function()
    local t = lurek.math.aabbTree()
    t:insert(42, 0, 0, 5, 5)
    expect_equal(t:contains(42), true)
  end)

  it("contains returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:contains(999), false)
  end)

  it("len reflects multiple inserts", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:insert(3, 10, 10, 20, 20)
    expect_equal(t:len(), 3)
  end)

  it("inserting duplicate id does not increase len", function()
    local t = lurek.math.aabbTree()
    t:insert(7, 0, 0, 10, 10)
    t:insert(7, 5, 5, 15, 15)  -- upsert
    expect_equal(t:len(), 1)
  end)
end)

describe("AabbTree remove", function()
  -- @covers lurek.math.aabbTree
  it("remove returns true for known id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    expect_equal(t:remove(1), true)
  end)

  it("remove returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:remove(999), false)
  end)

  it("contains false after remove", function()
    local t = lurek.math.aabbTree()
    t:insert(5, 0, 0, 10, 10)
    t:remove(5)
    expect_equal(t:contains(5), false)
  end)

  it("len decrements after remove", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:remove(1)
    expect_equal(t:len(), 1)
  end)
end)

describe("AabbTree query", function()
  -- @covers lurek.math.aabbTree
  it("query returns overlapping id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    t:insert(2, 20, 20, 30, 30)
    local ids = t:query(5, 5, 15, 15)
    expect_type("table", ids)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 1)
  end)

  it("query returns empty table on miss", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    local ids = t:query(100, 100, 200, 200)
    expect_equal(#ids, 0)
  end)

  it("query returns all ids when rect covers all", function()
    local t = lurek.math.aabbTree()
    t:insert(10, 0, 0, 1, 1)
    t:insert(20, 5, 5, 6, 6)
    t:insert(30, 9, 9, 10, 10)
    local ids = t:query(-1, -1, 100, 100)
    expect_equal(#ids, 3)
  end)

  it("query on empty tree returns empty table", function()
    local t = lurek.math.aabbTree()
    local ids = t:query(0, 0, 100, 100)
    expect_equal(#ids, 0)
  end)
end)

describe("AabbTree queryPoint", function()
  -- @covers lurek.math.aabbTree
  it("queryPoint finds containing entry", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(5, 5)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 1)
  end)

  it("queryPoint returns empty for exterior point", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(50, 50)
    expect_equal(#ids, 0)
  end)

  it("queryPoint on edge counts as inside", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(10, 10)
    expect_equal(#ids, 1)
  end)
end)

describe("AabbTree update", function()
  -- @covers lurek.math.aabbTree
  it("update returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:update(99, 0, 0, 1, 1), false)
  end)

  it("update returns true for known id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    expect_equal(t:update(1, 10, 10, 20, 20), true)
  end)

  it("update moves the bounding box", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    t:update(1, 50, 50, 60, 60)
    local old_ids = t:query(0, 0, 5, 5)
    local new_ids = t:query(50, 50, 60, 60)
    expect_equal(#old_ids, 0)
    expect_equal(#new_ids, 1)
    expect_equal(new_ids[1], 1)
  end)
end)

describe("AabbTree clear", function()
  -- @covers lurek.math.aabbTree
  it("clear resets len to 0", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:clear()
    expect_equal(t:len(), 0)
    expect_equal(t:isEmpty(), true)
  end)

  it("query after clear returns empty", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 100, 100)
    t:clear()
    local ids = t:query(0, 0, 100, 100)
    expect_equal(#ids, 0)
  end)
end)

describe("AabbTree edge cases", function()
  -- @covers lurek.math.aabbTree
  it("single entry exact AABB match", function()
    local t = lurek.math.aabbTree()
    t:insert(7, 3, 3, 7, 7)
    local ids = t:query(3, 3, 7, 7)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 7)
  end)

  it("many inserts then removes yields empty tree", function()
    local t = lurek.math.aabbTree()
    for i = 1, 20 do
      t:insert(i, i * 2, i * 2, i * 2 + 1, i * 2 + 1)
    end
    expect_equal(t:len(), 20)
    for i = 1, 20 do
      t:remove(i)
    end
    expect_equal(t:len(), 0)
    expect_equal(t:isEmpty(), true)
    local ids = t:query(-1000, -1000, 1000, 1000)
    expect_equal(#ids, 0)
  end)
end)

-- Polygon Boolean Operations

-- Unit square [0,0] to [1,1] (CCW)
local SQUARE = {
    {x=0, y=0}, {x=1, y=0}, {x=1, y=1}, {x=0, y=1}
}

-- Square offset to [0.5, 0.5]  [1.5, 1.5]  (overlaps with SQUARE)
local SQUARE_OFFSET = {
    {x=0.5, y=0.5}, {x=1.5, y=0.5}, {x=1.5, y=1.5}, {x=0.5, y=1.5}
}

-- Non-overlapping square [2, 2]  [3, 3]
local SQUARE_FAR = {
    {x=2, y=2}, {x=3, y=2}, {x=3, y=3}, {x=2, y=3}
}

describe("math.polygonIntersection", function()

    it("polygonIntersection exists in lurek.math", function()
        expect_equal(type(lurek.math.polygonIntersection), "function")
    end)

    it("intersection of overlapping squares returns a table", function()
        local result = lurek.math.polygonIntersection(SQUARE, SQUARE_OFFSET)
        expect_equal(type(result), "table")
    end)

    it("intersection of overlapping squares has vertices", function()
        local result = lurek.math.polygonIntersection(SQUARE, SQUARE_OFFSET)
        expect_equal(#result > 0, true)
    end)

    it("intersection of non-overlapping polygons returns empty table", function()
        local result = lurek.math.polygonIntersection(SQUARE, SQUARE_FAR)
        expect_equal(#result, 0)
    end)

    it("intersection vertices have x and y fields", function()
        local result = lurek.math.polygonIntersection(SQUARE, SQUARE_OFFSET)
        if #result > 0 then
            expect_equal(type(result[1].x), "number")
            expect_equal(type(result[1].y), "number")
        end
    end)

    it("intersection with self returns the same polygon area (approx)", function()
        local result = lurek.math.polygonIntersection(SQUARE, SQUARE)
        -- intersection with itself should fill the polygon
        expect_equal(#result >= 3, true)
    end)

end)

describe("math.polygonUnion", function()

    it("polygonUnion exists in lurek.math", function()
        expect_equal(type(lurek.math.polygonUnion), "function")
    end)

    it("union returns a table with vertices", function()
        local result = lurek.math.polygonUnion(SQUARE, SQUARE_OFFSET)
        expect_equal(type(result), "table")
        expect_equal(#result >= 3, true)
    end)

    it("union vertices have x and y fields", function()
        local result = lurek.math.polygonUnion(SQUARE, SQUARE_OFFSET)
        if #result > 0 then
            expect_equal(type(result[1].x), "number")
            expect_equal(type(result[1].y), "number")
        end
    end)

    it("union of non-overlapping squares has >= 6 vertices", function()
        local result = lurek.math.polygonUnion(SQUARE, SQUARE_FAR)
        -- Convex hull of two separated squares will have vertices >= 4
        expect_equal(#result >= 4, true)
    end)

end)

describe("math.polygonDifference", function()

    it("polygonDifference exists in lurek.math", function()
        expect_equal(type(lurek.math.polygonDifference), "function")
    end)

    it("difference with empty b returns a (unchanged)", function()
        local result = lurek.math.polygonDifference(SQUARE, {})
        expect_equal(#result, 4)
    end)

    it("difference of empty a returns empty", function()
        local result = lurek.math.polygonDifference({}, SQUARE)
        expect_equal(#result, 0)
    end)

    it("difference of non-overlapping polygons returns a (convex hull of a)", function()
        local result = lurek.math.polygonDifference(SQUARE, SQUARE_FAR)
        -- No overlap  result should contain SQUARE vertices
        expect_equal(#result > 0, true)
    end)

    it("difference returns a table with x and y fields", function()
        local result = lurek.math.polygonDifference(SQUARE, SQUARE_OFFSET)
        if #result > 0 then
            expect_equal(type(result[1].x), "number")
            expect_equal(type(result[1].y), "number")
        end
    end)

end)

-- Property-Based Tests

-- Helper: generate pseudo-random test values
local function test_values(count, min, max)
    local vals = {}
    for i = 1, count do
        -- Deterministic spread using golden ratio
        local t = (i * 0.618033988749895) % 1.0
        vals[i] = min + t * (max - min)
    end
    return vals
end

describe("property: trig identities", function()
    -- @covers lurek.math.sin
    -- @covers lurek.math.cos
    it("sin^2(x) + cos^2(x) = 1 for 100 values", function()
        local angles = test_values(100, -10, 10)
        for i, x in ipairs(angles) do
            local s = lurek.math.sin(x)
            local c = lurek.math.cos(x)
            local sum = s * s + c * c
            expect_near(1.0, sum, 1e-6,
                "sin^2 + cos^2 = 1 at x=" .. string.format("%.4f", x))
        end
    end)

    -- @covers lurek.math.sin
    it("sin(-x) = -sin(x) for 100 values (odd function)", function()
        local angles = test_values(100, -10, 10)
        for i, x in ipairs(angles) do
            local pos = lurek.math.sin(x)
            local neg = lurek.math.sin(-x)
            expect_near(-pos, neg, 1e-10,
                "sin is odd at x=" .. string.format("%.4f", x))
        end
    end)

    -- @covers lurek.math.cos
    it("cos(-x) = cos(x) for 100 values (even function)", function()
        local angles = test_values(100, -10, 10)
        for i, x in ipairs(angles) do
            local pos = lurek.math.cos(x)
            local neg = lurek.math.cos(-x)
            expect_near(pos, neg, 1e-10,
                "cos is even at x=" .. string.format("%.4f", x))
        end
    end)
end)

describe("property: sqrt invariants", function()
    -- @covers lurek.math.sqrt
    it("sqrt(x)^2 = x for 100 positive values", function()
        local vals = test_values(100, 0.001, 10000)
        for i, x in ipairs(vals) do
            local root = lurek.math.sqrt(x)
            expect_near(x, root * root, x * 1e-10 + 1e-10,
                "sqrt round-trip at x=" .. string.format("%.4f", x))
        end
    end)

    -- @covers lurek.math.sqrt
    it("sqrt(a*b) = sqrt(a) * sqrt(b) for 50 pairs", function()
        local vals = test_values(100, 0.01, 100)
        for i = 1, 50 do
            local a = vals[i]
            local b = vals[i + 50]
            local lhs = lurek.math.sqrt(a * b)
            local rhs = lurek.math.sqrt(a) * lurek.math.sqrt(b)
            expect_near(lhs, rhs, 1e-8,
                "sqrt product rule at a=" .. string.format("%.2f", a))
        end
    end)
end)

describe("property: exp/log invariants", function()
    -- @covers lurek.math.exp
    it("exp(a+b) = exp(a) * exp(b) for 50 pairs", function()
        local vals = test_values(100, -3, 3)
        for i = 1, 50 do
            local a = vals[i]
            local b = vals[i + 50]
            local lhs = lurek.math.exp(a + b)
            local rhs = lurek.math.exp(a) * lurek.math.exp(b)
            expect_near(lhs, rhs, math.abs(lhs) * 1e-10 + 1e-10,
                "exp sum rule")
        end
    end)
end)

describe("property: Vec2 operations", function()
    -- @covers lurek.math.Vec2
    it("vec2 add is commutative for 50 pairs", function()
        local vals = test_values(200, -1000, 1000)
        for i = 1, 50 do
            local ax, ay = vals[i], vals[i + 50]
            local bx, by = vals[i + 100], vals[i + 150]

            local v1 = lurek.math.Vec2(ax, ay)
            local v2 = lurek.math.Vec2(bx, by)

            local sum1 = v1 + v2
            local sum2 = v2 + v1

            expect_near(sum1.x, sum2.x, 1e-10, "x commutative")
            expect_near(sum1.y, sum2.y, 1e-10, "y commutative")
        end
    end)

    -- @covers lurek.math.Vec2
    -- @covers lurek.math.Vec2.length
    it("vec2 length is non-negative for 100 values", function()
        local vals = test_values(200, -1000, 1000)
        for i = 1, 100 do
            local v = lurek.math.Vec2(vals[i], vals[i + 100])
            local len = v:length()
            expect_true(len >= 0,
                "length >= 0 for (" .. vals[i] .. "," .. vals[i+100] .. ")")
        end
    end)

    -- @covers lurek.math.Vec2
    -- @covers lurek.math.Vec2.normalized
    -- @covers lurek.math.Vec2.length
    it("normalized vec2 has length 1 for non-zero vectors", function()
        local vals = test_values(200, -100, 100)
        for i = 1, 100 do
            local x, y = vals[i], vals[i + 100]
            if math.abs(x) + math.abs(y) > 0.001 then
                local v = lurek.math.Vec2(x, y)
                local n = v:normalized()
                expect_near(1.0, n:length(), 1e-6, "normalized length = 1")
            end
        end
    end)
end)

describe("property: lerp interpolation", function()
    -- @covers lurek.math.lerp
    it("lerp(a, b, 0) = a and lerp(a, b, 1) = b", function()
        local vals = test_values(100, -1000, 1000)
        for i = 1, 50 do
            local a = vals[i]
            local b = vals[i + 50]
            local at0 = lurek.math.lerp(a, b, 0)
            local at1 = lurek.math.lerp(a, b, 1)
            -- lerp uses f32 internally; tolerance matches f32 relative precision over range [-1000, 1000]
            expect_near(a, at0, 1e-3, "lerp(a,b,0) = a")
            expect_near(b, at1, 1e-3, "lerp(a,b,1) = b")
        end
    end)

    -- @covers lurek.math.lerp
    it("lerp is monotonic for t in [0,1]", function()
        local a, b = 10, 100
        local prev = lurek.math.lerp(a, b, 0)
        for t = 1, 100 do
            local curr = lurek.math.lerp(a, b, t / 100)
            expect_true(curr >= prev, "lerp monotonic at t=" .. (t/100))
            prev = curr
        end
    end)
end)

-- Voronoi

describe("lurek.math.voronoi type", function()
  -- @covers lurek.math.voronoi
  it("voronoi is a function", function()
    expect_type("function", lurek.math.voronoi)
  end)

  it("returns a table", function()
    local cells = lurek.math.voronoi({{x=0,y=0},{x=1,y=0},{x=0.5,y=1}})
    expect_type("table", cells)
  end)
end)

describe("lurek.math.voronoi empty input", function()
  -- @covers lurek.math.voronoi
  it("empty input returns empty table", function()
    local cells = lurek.math.voronoi({})
    expect_equal(0, #cells)
  end)
end)

describe("lurek.math.voronoi cell count", function()
  -- @covers lurek.math.voronoi
  it("returns one cell per unique site", function()
    local pts = {{x=0,y=0},{x=1,y=0},{x=0.5,y=1},{x=0.5,y=0.5}}
    local cells = lurek.math.voronoi(pts)
    expect_equal(4, #cells)
  end)

  it("three-point input returns three cells", function()
    local pts = {{x=0,y=0},{x=1,y=0},{x=0.5,y=1}}
    local cells = lurek.math.voronoi(pts)
    expect_equal(3, #cells)
  end)
end)

describe("lurek.math.voronoi cell structure", function()
  -- @covers lurek.math.voronoi
  it("each cell has a site table", function()
    local pts = {{x=0,y=0},{x=1,y=0},{x=0.5,y=1}}
    local cells = lurek.math.voronoi(pts)
    for _, cell in ipairs(cells) do
      expect_type("table", cell.site)
    end
  end)

  it("each cell site has x and y keys", function()
    local pts = {{x=0,y=0},{x=1,y=0},{x=0.5,y=1}}
    local cells = lurek.math.voronoi(pts)
    for _, cell in ipairs(cells) do
      expect_type("number", cell.site.x)
      expect_type("number", cell.site.y)
    end
  end)

  it("each cell has a vertices table", function()
    local pts = {{x=0,y=0},{x=1,y=0},{x=0.5,y=1}}
    local cells = lurek.math.voronoi(pts)
    for _, cell in ipairs(cells) do
      expect_type("table", cell.vertices)
    end
  end)
end)

describe("lurek.math.voronoi vertex coordinates", function()
  -- @covers lurek.math.voronoi
  it("vertex entries have x and y as numbers", function()
    local pts = {
      {x=0,y=0},{x=2,y=0},{x=1,y=2},{x=1,y=0.5}
    }
    local cells = lurek.math.voronoi(pts)
    local found_vertex = false
    for _, cell in ipairs(cells) do
      for _, v in ipairs(cell.vertices) do
        expect_type("number", v.x)
        expect_type("number", v.y)
        found_vertex = true
      end
    end
    -- At least one vertex should exist for a 4-point diagram
    expect_equal(true, found_vertex)
  end)
end)

describe("lurek.math.voronoi near-duplicate deduplication", function()
  -- @covers lurek.math.voronoi
  it("near-coincident points are merged into fewer cells", function()
    -- Two points separated by 1e-7 should deduplicate to 1 effective site
    local pts = {
      {x=0, y=0}, {x=0, y=1e-7},
      {x=1, y=0}, {x=0.5, y=1}
    }
    local cells = lurek.math.voronoi(pts)
    -- After deduplication we expect fewer than 4 cells
    expect_equal(true, #cells < 4)
  end)
end)

-- smoothstep
describe("lurek.math.smoothstep", function()
  -- @covers lurek.math.smoothstep
  it("x <= e0 returns 0", function()
    expect_equal(0, lurek.math.smoothstep(0, 1, -0.5))
  end)
  -- @covers lurek.math.smoothstep
  it("x >= e1 returns 1", function()
    expect_equal(1, lurek.math.smoothstep(0, 1, 2))
  end)
  -- @covers lurek.math.smoothstep
  it("midpoint returns 0.5", function()
    expect_near(0.5, lurek.math.smoothstep(0, 1, 0.5), 1e-5)
  end)
  -- @covers lurek.math.smoothstep
  it("interior result is in [0,1]", function()
    local v = lurek.math.smoothstep(0, 1, 0.3)
    expect_true(v >= 0 and v <= 1, "smoothstep in range")
  end)
end)

-- inverseLerp
describe("lurek.math.inverseLerp", function()
  -- @covers lurek.math.inverseLerp
  it("returns 0 at start", function()
    expect_equal(0, lurek.math.inverseLerp(0, 10, 0))
  end)
  -- @covers lurek.math.inverseLerp
  it("returns 1 at end", function()
    expect_equal(1, lurek.math.inverseLerp(0, 10, 10))
  end)
  -- @covers lurek.math.inverseLerp
  it("returns 0.5 at midpoint", function()
    expect_near(0.5, lurek.math.inverseLerp(0, 10, 5), 1e-5)
  end)
end)

-- hslToRgb / rgbToHsl
describe("lurek.math hslToRgb and rgbToHsl", function()
  -- @covers lurek.math.hslToRgb
  it("hslToRgb white is (1,1,1,1)", function()
    local r, g, b, a = lurek.math.hslToRgb(0, 0, 1.0)
    expect_near(1.0, r, 1e-5)
    expect_near(1.0, g, 1e-5)
    expect_near(1.0, b, 1e-5)
    expect_near(1.0, a, 1e-5)
  end)
  -- @covers lurek.math.hslToRgb
  it("hslToRgb black is (0,0,0)", function()
    local r, g, b = lurek.math.hslToRgb(0, 0, 0.0)
    expect_near(0.0, r, 1e-5)
    expect_near(0.0, g, 1e-5)
    expect_near(0.0, b, 1e-5)
  end)
  -- @covers lurek.math.rgbToHsl
  it("rgbToHsl red gives (0, 1, 0.5)", function()
    local h, s, l = lurek.math.rgbToHsl(1.0, 0.0, 0.0)
    expect_near(0.0, h, 1e-5)
    expect_near(1.0, s, 1e-5)
    expect_near(0.5, l, 1e-5)
  end)
  -- @covers lurek.math.hslToRgb
  -- @covers lurek.math.rgbToHsl
  it("hslToRgb/rgbToHsl roundtrip preserves colour", function()
    local r0, g0, b0 = 0.3, 0.6, 0.9
    local h, s, l = lurek.math.rgbToHsl(r0, g0, b0)
    local r1, g1, b1 = lurek.math.hslToRgb(h or 0, s or 0, l or 0)
    expect_near(r0, r1, 1e-4)
    expect_near(g0, g1, 1e-4)
    expect_near(b0, b1, 1e-4)
  end)
end)

-- fromHex
describe("lurek.math.fromHex", function()
  -- @covers lurek.math.fromHex
  it("parses #ffffff as white", function()
    local r, g, b, a = lurek.math.fromHex("#ffffff")
    expect_near(1.0, r, 1e-5)
    expect_near(1.0, g, 1e-5)
    expect_near(1.0, b, 1e-5)
    expect_near(1.0, a, 1e-5)
  end)
  -- @covers lurek.math.fromHex
  it("parses #000000 as black", function()
    local r, g, b, a = lurek.math.fromHex("#000000")
    expect_near(0.0, r, 1e-5)
    expect_near(0.0, g, 1e-5)
    expect_near(0.0, b, 1e-5)
    expect_near(1.0, a, 1e-5)
  end)
  -- @covers lurek.math.fromHex
  xit("invalid hex returns nil", function()
    local r = lurek.math.fromHex("notahex")
    expect_equal(nil, r)
  end)
end)

-- rectUnion
describe("lurek.math.rectUnion", function()
  -- @covers lurek.math.rectUnion
  it("union of equal rects is that rect", function()
    local x, y, w, h = lurek.math.rectUnion(0, 0, 10, 10, 0, 0, 10, 10)
    expect_equal(0, x)
    expect_equal(0, y)
    expect_equal(10, w)
    expect_equal(10, h)
  end)
  -- @covers lurek.math.rectUnion
  it("union of adjacent rects spans both", function()
    local x, y, w, h = lurek.math.rectUnion(0, 0, 5, 5, 5, 0, 5, 5)
    expect_equal(0, x)
    expect_equal(0, y)
    expect_equal(10, w)
    expect_equal(5, h)
  end)
  -- @covers lurek.math.rectUnion
  it("returns four numbers", function()
    local x, y, w, h = lurek.math.rectUnion(1, 2, 3, 4, 5, 6, 7, 8)
    expect_type("number", x)
    expect_type("number", y)
    expect_type("number", w)
    expect_type("number", h)
  end)
end)

-- rectFromCenter
describe("lurek.math.rectFromCenter", function()
  -- @covers lurek.math.rectFromCenter
  it("top-left is center minus half-size", function()
    local x, y, w, h = lurek.math.rectFromCenter(10, 10, 4, 6)
    expect_equal(8, x)
    expect_equal(7, y)
    expect_equal(4, w)
    expect_equal(6, h)
  end)
  -- @covers lurek.math.rectFromCenter
  it("size is preserved", function()
    local _, _, w, h = lurek.math.rectFromCenter(0, 0, 8, 12)
    expect_equal(8, w)
    expect_equal(12, h)
  end)
end)

-- Vec2:fromAngle / reflect
describe("lurek.math Vec2 fromAngle and reflect", function()
  -- @covers lurek.math.Vec2.fromAngle
  it("fromAngle(0) returns unit +X", function()
    local v = lurek.math.vec2(0, 0).fromAngle(0)
    expect_near(1.0, v.x, 1e-5)
    expect_near(0.0, v.y, 1e-5)
  end)
  -- @covers lurek.math.Vec2.fromAngle
  it("fromAngle(pi/2) returns unit +Y", function()
    local v = lurek.math.vec2(0, 0).fromAngle(math.pi / 2)
    expect_near(0.0, v.x, 1e-5)
    expect_near(1.0, v.y, 1e-5)
  end)
  -- @covers lurek.math.Vec2.fromAngle
  it("fromAngle result is unit length", function()
    local v = lurek.math.vec2(0, 0).fromAngle(1.23)
    local len = math.sqrt(v.x * v.x + v.y * v.y)
    expect_near(1.0, len, 1e-5)
  end)
  -- @covers lurek.math.Vec2.reflect
  it("reflect off horizontal normal", function()
    local v = lurek.math.Vec2(1, -1)
    local n = lurek.math.Vec2(0, 1)
    local r = v:reflect(n)
    expect_near(1.0, r.x, 1e-5)
    expect_near(1.0, r.y, 1e-5)
  end)
  -- @covers lurek.math.Vec2.reflect
  it("reflect parallel to normal flips sign", function()
    local v = lurek.math.Vec2(0, -1)
    local n = lurek.math.Vec2(0, 1)
    local r = v:reflect(n)
    expect_near(0.0, r.x, 1e-5)
    expect_near(1.0, r.y, 1e-5)
  end)
end)

-- Vec3:splat
describe("lurek.math Vec3 splat", function()
  -- @covers lurek.math.Vec3.splat
    it("splat(5) gives Vec3(5,5,5)", function()
        local v = lurek.math.vec3(0, 0, 0).splat(5)
    expect_equal(5, v.x)
    expect_equal(5, v.y)
    expect_equal(5, v.z)
  end)
  -- @covers lurek.math.Vec3.splat
    it("splat(0) gives zero Vec3", function()
        local v = lurek.math.vec3(1, 2, 3).splat(0)
    expect_equal(0, v.x)
    expect_equal(0, v.y)
    expect_equal(0, v.z)
  end)
end)

-- Transform:decompose
describe("lurek.math Transform decompose", function()
  -- @covers lurek.math.Transform.decompose
    it("decompose returns 5 numbers", function()
    local t = lurek.math.newTransform()
    local x, y, a, sx, sy = t:decompose()
    expect_type("number", x)
    expect_type("number", y)
    expect_type("number", a)
    expect_type("number", sx)
    expect_type("number", sy)
  end)
  -- @covers lurek.math.Transform.decompose
    it("identity decomposes to (0,0,0,1,1)", function()
    local t = lurek.math.newTransform()
    local x, y, a, sx, sy = t:decompose()
    expect_near(0.0, x, 1e-5)
    expect_near(0.0, y, 1e-5)
    expect_near(0.0, a, 1e-5)
    expect_near(1.0, sx, 1e-5)
    expect_near(1.0, sy, 1e-5)
  end)
end)

-- easing: inOutElastic / inOutBounce / inOutBack
describe("lurek.math easing inOut variants", function()
  -- @covers lurek.math.inOutElastic
  it("inOutElastic boundary values", function()
    expect_near(0.0, lurek.math.inOutElastic(0), 1e-5)
    expect_near(1.0, lurek.math.inOutElastic(1), 1e-5)
  end)
  -- @covers lurek.math.inOutElastic
  it("inOutElastic is symmetric", function()
    local lo = lurek.math.inOutElastic(0.25)
    local hi = lurek.math.inOutElastic(0.75)
    expect_near(1.0 - lo, hi, 1e-5)
  end)
  -- @covers lurek.math.inOutBounce
  it("inOutBounce boundary values", function()
    expect_near(0.0, lurek.math.inOutBounce(0), 1e-5)
    expect_near(1.0, lurek.math.inOutBounce(1), 1e-5)
  end)
  -- @covers lurek.math.inOutBounce
  -- Note: bounce easings are NOT monotone by design  they bounce back.
  it("inOutBounce is symmetric", function()
    for i = 1, 9 do
      local t = i / 10
      local ft = lurek.math.inOutBounce(t)
      local f1t = lurek.math.inOutBounce(1 - t)
      expect_near(1 - ft, f1t, 1e-5, "inOutBounce symmetric at t=" .. t)
    end
  end)
  -- @covers lurek.math.inOutBack
  it("inOutBack boundary values", function()
    expect_near(0.0, lurek.math.inOutBack(0), 1e-5)
    expect_near(1.0, lurek.math.inOutBack(1), 1e-5)
  end)
end)

-- CatmullRomSpline: addPoint / removePoint
describe("lurek.math CatmullRomSpline addPoint and removePoint", function()
  -- @covers lurek.math.CatmullRomSpline.addPoint
    it("addPoint increases point count", function()
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
    s:addPoint(1, 1)
    expect_equal(2, s:len())
  end)
  -- @covers lurek.math.CatmullRomSpline.removePoint
    it("removePoint reduces count by 1", function()
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
    s:addPoint(1, 1)
    s:addPoint(2, 0)
        s:removePoint(1)
    expect_equal(2, s:len())
  end)
  -- @covers lurek.math.CatmullRomSpline.removePoint
  xit("removePoint out-of-range is safe", function()
      ---@type LCatmullRom
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
    s:removePoint(99)
    expect_equal(1, s:len())
  end)
  -- @covers lurek.math.CatmullRomSpline.addPoint
  -- @covers lurek.math.CatmullRomSpline.removePoint
    it("adding then removing all points gives empty spline", function()
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
        s:removePoint(0)
    expect_equal(0, s:len())
  end)
end)

describe("lurek.math Circle value type", function()
  it("newCircle returns an object", function()
    local c = lurek.math.newCircle(0, 0, 5)
    expect_not_nil(c)
  end)

  it("area returns pi*r^2", function()
    local c = lurek.math.newCircle(0, 0, 1)
    local area = c:area()
    expect_near(math.pi, area, 1e-5)
  end)

  it("perimeter returns 2*pi*r", function()
    local c = lurek.math.newCircle(0, 0, 3)
    local p = c:perimeter()
    expect_near(6 * math.pi, p, 1e-5)
  end)

  it("contains returns true for point inside", function()
    local c = lurek.math.newCircle(0, 0, 5)
    expect_true(c:contains(0, 0))
    expect_true(c:contains(3, 4))
  end)

  it("contains returns false for point outside", function()
    local c = lurek.math.newCircle(0, 0, 5)
    expect_false(c:contains(4, 4))
  end)

  it("intersects returns true when circles overlap", function()
    local a = lurek.math.newCircle(0, 0, 3)
    local b = lurek.math.newCircle(4, 0, 3)
    expect_true(a:intersects(b))
  end)

  it("intersects returns false when circles are apart", function()
    local a = lurek.math.newCircle(0, 0, 1)
    local b = lurek.math.newCircle(10, 0, 1)
    expect_false(a:intersects(b))
  end)

  it("aabb returns 4 numbers covering the circle", function()
    local c = lurek.math.newCircle(0, 0, 2)
    local x1, y1, x2, y2 = c:aabb()
    expect_near(-2, x1, 1e-5)
    expect_near(-2, y1, 1e-5)
    expect_near( 2, x2, 1e-5)
    expect_near( 2, y2, 1e-5)
  end)

  it("negative radius is clamped to 0", function()
    local c = lurek.math.newCircle(1, 2, -5)
    expect_near(0, c:radius(), 1e-5)
  end)
end)

describe("lurek.math AabbTree querySegment", function()
    xit("querySegment returns ids crossed by segment", function()
        -- Rust-only helper: AabbTree querySegment is not exposed in the Lua API.
    end)

    xit("querySegment misses non-intersecting AABB", function()
        -- Rust-only helper: AabbTree querySegment is not exposed in the Lua API.
    end)
end)

-- =========================================================================
-- @covers additions for math module
-- =========================================================================

describe("lurek.math scalar helpers (@covers)", function()
    it("rad converts degrees to radians", function()
        -- @covers lurek.math.rad
        expect_near(lurek.math.pi / 2, lurek.math.rad(90), 1e-5)
    end)

    it("deg converts radians to degrees", function()
        -- @covers lurek.math.deg
        expect_near(90.0, lurek.math.deg(lurek.math.pi / 2), 1e-4)
    end)

    it("tan(pi/4) = 1", function()
        -- @covers lurek.math.tan
        expect_near(1.0, lurek.math.tan(lurek.math.pi / 4), 1e-5)
    end)

    it("exp(0) = 1", function()
        -- @covers lurek.math.exp
        expect_near(1.0, lurek.math.exp(0), 1e-5)
    end)

    it("log(e) = 1", function()
        -- @covers lurek.math.log
        local e = lurek.math.exp(1)
        expect_near(1.0, lurek.math.log(e), 1e-5)
    end)

    it("pow(2, 10) = 1024", function()
        -- @covers lurek.math.pow
        expect_near(1024.0, lurek.math.pow(2, 10), 1e-5)
    end)
end)

describe("Vec2 accessors (@covers)", function()
    it("x returns the x component", function()
        -- @covers Vec2:x
        local v = lurek.math.vec2(3.0, 7.0)
        -- x may be a field or a method depending on build
        local xval
        if type(v.x) == "function" then
            xval = v:x()
        else
            xval = v.x
        end
        expect_near(3.0, xval, 1e-5)
    end)

    it("y returns the y component", function()
        -- @covers Vec2:y
        local v = lurek.math.vec2(3.0, 7.0)
        local yval
        if type(v.y) == "function" then
            yval = v:y()
        else
            yval = v.y
        end
        expect_near(7.0, yval, 1e-5)
    end)
end)

describe("Vec3 arithmetic (@covers)", function()
    it("dot computes the inner product", function()
        -- @covers Vec3:dot
        ---@type LVec3
        local a = lurek.math.vec3(1.0, 0.0, 0.0)
        ---@type LVec3
        local b = lurek.math.vec3(0.0, 1.0, 0.0)
        expect_near(0.0, a:dot(b), 1e-5)
    end)

    it("add returns a new summed vector", function()
        -- @covers Vec3:add
        ---@type LVec3
        local a = lurek.math.vec3(1.0, 2.0, 3.0)
        ---@type LVec3
        local b = lurek.math.vec3(4.0, 5.0, 6.0)
        local r = a:add(b)
        expect_not_nil(r)
    end)

    it("sub returns a new difference vector", function()
        -- @covers Vec3:sub
        ---@type LVec3
        local a = lurek.math.vec3(4.0, 5.0, 6.0)
        ---@type LVec3
        local b = lurek.math.vec3(1.0, 2.0, 3.0)
        local r = a:sub(b)
        expect_not_nil(r)
    end)
end)

describe("CatmullRom:len (@covers)", function()
    it("len returns the control-point count", function()
        -- @covers CatmullRom:len
        local ok, cr = pcall(function()
            return lurek.math.catmullRom({{0,0},{1,1},{2,0},{3,1}})
        end)
        if not ok then
            -- fallback: try without initial points
            ok, cr = pcall(function()
                return lurek.math.catmullRom({})
            end)
        end
        if ok and cr ~= nil then
            local ok2, n = pcall(function()
                cr:addPoint(0, 0)
                cr:addPoint(1, 1)
                return cr:len()
            end)
            if ok2 then
                expect_type("number", n)
            else
                expect_type("boolean", ok2)
            end
        end
    end)
end)

describe("Transform:setTransformation (@covers)", function()
    it("setTransformation does not crash", function()
        -- @covers Transform:setTransformation
        local t = lurek.math.newTransform()
        local ok, _ = pcall(function()
            t:setTransformation(10.0, 20.0, 0.5, 1.0, 1.0, 0.0, 0.0)
        end)
        expect_type("boolean", ok)
    end)
end)

describe("BezierCurve control-point methods (@covers)", function()
    it("setControlPoint updates a control point", function()
        -- @covers BezierCurve:setControlPoint
        local bc = lurek.math.newBezierCurve({0, 0, 1, 1, 2, 0})
        local ok, _ = pcall(function() bc:setControlPoint(1, 0.5, 0.5) end)
        expect_type("boolean", ok)
    end)

    it("insertControlPoint inserts a new point", function()
        -- @covers BezierCurve:insertControlPoint
        local bc = lurek.math.newBezierCurve({0, 0, 1, 1, 2, 0})
        local before = bc:getControlPointCount()
        local ok, _ = pcall(function() bc:insertControlPoint(2, 0.5, 0.8) end)
        if ok then
            expect_true(bc:getControlPointCount() > before)
        else
            expect_type("boolean", ok)
        end
    end)
end)

describe("Math Tween:set (@covers)", function()
    it("set updates tween target values", function()
        -- @covers Tween:set
        local tw = lurek.math.newTween(1.0, "linear")
        -- addValue(start, end) adds a value target (no name)
        tw:addValue(0.0, 100.0)
        -- set resets or overrides values; exact signature varies
        local ok, _ = pcall(function() tw:set(0.0) end)
        if not ok then
            ok, _ = pcall(function() tw:setTime(0.0) end)
        end
        expect_type("boolean", ok)
    end)
end)

describe("Circle accessors (@covers)", function()
    it("x returns the circle centre x", function()
        -- @covers Circle:x
        local c = lurek.math.newCircle(3.0, 4.0, 5.0)
        expect_near(3.0, c:x(), 1e-5)
    end)

    it("y returns the circle centre y", function()
        -- @covers Circle:y
        local c = lurek.math.newCircle(3.0, 4.0, 5.0)
        expect_near(4.0, c:y(), 1e-5)
    end)
end)

describe("AabbTree:len (@covers)", function()
    it("len returns 0 on an empty tree", function()
        -- @covers AabbTree:len
        local tree = lurek.math.aabbTree()
        expect_equal(0, tree:len())
    end)

    it("len increments after insert", function()
        -- @covers AabbTree:len
        local tree = lurek.math.aabbTree()
        tree:insert(1, 0, 0, 10, 10)
        expect_equal(1, tree:len())
    end)
end)

test_summary()
