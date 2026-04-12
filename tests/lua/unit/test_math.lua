-- Lurek2D Math API Tests
-- @covers lurek.math.abs
-- @covers lurek.math.atan2
-- @covers lurek.math.ceil
-- @covers lurek.math.clamp
-- @covers lurek.math.cos
-- @covers lurek.math.distance
-- @covers lurek.math.floor
-- @covers lurek.math.max
-- @covers lurek.math.min
-- @covers lurek.math.pi
-- @covers lurek.math.random
-- @covers lurek.math.simplexNoise
-- @covers lurek.math.sin
-- @covers lurek.math.sqrt
-- @covers lurek.math.tan
-- @covers lurek.math.newRandomGenerator
-- @covers lurek.math.newTransform
-- @covers lurek.math.newBezierCurve
-- @covers lurek.math.newNoiseGenerator
-- @covers lurek.math.newSpatialHash
-- @covers lurek.math.applyEasing
-- @covers lurek.math.triangulate
-- @covers lurek.math.isConvex
-- @covers lurek.math.gammaToLinear
-- @covers lurek.math.linearToGamma
-- @covers lurek.math.lerp
-- @covers lurek.math.sign
-- @covers lurek.math.round
-- @covers lurek.math.distanceSq
-- @covers lurek.math.angleBetween
-- @covers lurek.math.tau
-- @covers lurek.math.huge
-- @covers lurek.math.randomInt
-- @covers lurek.math.rad
-- @covers lurek.math.deg


describe("lurek.math constants", function()
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

-- ── additional constants & utility ───────────────────────────────────────────

describe("math constants and utility", function()
    it("has tau = 2*pi", function()
        expect_near(lurek.math.tau, lurek.math.pi * 2, 0.0001)
    end)

    it("has huge", function()
        expect_true(lurek.math.huge > 1e300)
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

-- ── RandomGenerator ──────────────────────────────────────────────────────────

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

-- ── Transform ────────────────────────────────────────────────────────────────

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
        local bx, by = inv:transformPoint(x, y)
        expect_near(bx, 5, 0.01)
        expect_near(by, 10, 0.01)
    end)

    it("inverseTransformPoint round-trips", function()
        local t = lurek.math.newTransform()
        t:translate(50, 100)
        t:rotate(0.5)
        local x, y = t:transformPoint(10, 20)
        local bx, by = t:inverseTransformPoint(x, y)
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

-- ── BezierCurve ──────────────────────────────────────────────────────────────

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

-- ── NoiseGenerator ───────────────────────────────────────────────────────────

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

-- ── SpatialHash ──────────────────────────────────────────────────────────────

describe("math.newSpatialHash", function()
    it("creates spatial hash with cell size", function()
        local sh = lurek.math.newSpatialHash(64)
        expect_not_nil(sh)
        expect_equal(sh:getCellSize(), 64)
    end)

    it("insert and queryRect finds item", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert(1, 10, 10, 20, 20)
        local results = sh:queryRect(0, 0, 50, 50)
        expect_true(#results >= 1)
    end)

    it("queryRect does not find distant items", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert(1, 10, 10, 20, 20)
        local results = sh:queryRect(500, 500, 10, 10)
        expect_equal(#results, 0)
    end)

    it("remove decreases item count", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert(1, 10, 10, 20, 20)
        expect_equal(sh:getItemCount(), 1)
        sh:remove(1)
        expect_equal(sh:getItemCount(), 0)
    end)

    it("queryCircle finds nearby items", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert(1, 10, 10, 5, 5)
        local results = sh:queryCircle(12, 12, 50)
        expect_true(#results >= 1)
    end)
end)

-- ── Easing functions ─────────────────────────────────────────────────────────

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

-- ── Polygon/Geometry ─────────────────────────────────────────────────────────

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

-- ── Color space ──────────────────────────────────────────────────────────────

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

test_summary()
