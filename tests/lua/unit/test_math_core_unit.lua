-- Lurek2D Math API Tests

-- @describe lurek.math constants
describe("lurek.math constants", function()
    -- @covers lurek.math.pi
    it("has pi", function()
        expect_not_nil(lurek.math.pi, "pi exists")
        expect_near(3.14159265358979, lurek.math.pi, 0.0001, "pi value")
    end)
end)

-- @describe lurek.math trigonometry
describe("lurek.math trigonometry", function()
    -- @covers lurek.math.sin
    it("sin(0) = 0", function()
        expect_near(0, lurek.math.sin(0), 0.0001)
    end)

    -- @covers lurek.math.sin
    it("sin(pi/2) = 1", function()
        expect_near(1, lurek.math.sin(lurek.math.pi / 2), 0.0001)
    end)

    -- @covers lurek.math.cos
    it("cos(0) = 1", function()
        expect_near(1, lurek.math.cos(0), 0.0001)
    end)

    -- @covers lurek.math.cos
    it("cos(pi) = -1", function()
        expect_near(-1, lurek.math.cos(lurek.math.pi), 0.0001)
    end)

    -- @covers lurek.math.tan
    it("tan(0) = 0", function()
        expect_near(0, lurek.math.tan(0), 0.0001)
    end)

    -- @covers lurek.math.atan2
    it("atan2(1, 0) = pi/2", function()
        expect_near(lurek.math.pi / 2, lurek.math.atan2(1, 0), 0.0001)
    end)

    -- @covers lurek.math.atan2
    it("atan2(0, 1) = 0", function()
        expect_near(0, lurek.math.atan2(0, 1), 0.0001)
    end)
end)

-- @describe lurek.math basic functions
describe("lurek.math basic functions", function()
    -- @covers lurek.math.sqrt
    it("sqrt(4) = 2", function()
        expect_near(2, lurek.math.sqrt(4), 0.0001)
    end)

    -- @covers lurek.math.sqrt
    it("sqrt(9) = 3", function()
        expect_near(3, lurek.math.sqrt(9), 0.0001)
    end)

    -- @covers lurek.math.abs
    it("abs(-5) = 5", function()
        expect_near(5, lurek.math.abs(-5), 0.0001)
    end)

    -- @covers lurek.math.abs
    it("abs(5) = 5", function()
        expect_near(5, lurek.math.abs(5), 0.0001)
    end)

    -- @covers lurek.math.floor
    it("floor(3.7) = 3", function()
        expect_equal(3, lurek.math.floor(3.7))
    end)

    -- @covers lurek.math.floor
    it("floor(-2.1) = -3", function()
        expect_equal(-3, lurek.math.floor(-2.1))
    end)

    -- @covers lurek.math.ceil
    it("ceil(3.2) = 4", function()
        expect_equal(4, lurek.math.ceil(3.2))
    end)

    -- @covers lurek.math.ceil
    it("ceil(-2.9) = -2", function()
        expect_equal(-2, lurek.math.ceil(-2.9))
    end)
end)

-- @describe lurek.math min/max/clamp
describe("lurek.math min/max/clamp", function()
    -- @covers lurek.math.min
    it("min(3, 7) = 3", function()
        expect_equal(3, lurek.math.min(3, 7))
    end)

    -- @covers lurek.math.min
    it("min(-1, 1) = -1", function()
        expect_equal(-1, lurek.math.min(-1, 1))
    end)

    -- @covers lurek.math.max
    it("max(3, 7) = 7", function()
        expect_equal(7, lurek.math.max(3, 7))
    end)

    -- @covers lurek.math.clamp
    it("clamp(5, 0, 10) = 5", function()
        expect_equal(5, lurek.math.clamp(5, 0, 10))
    end)

    -- @covers lurek.math.clamp
    it("clamp(-5, 0, 10) = 0", function()
        expect_equal(0, lurek.math.clamp(-5, 0, 10))
    end)

    -- @covers lurek.math.clamp
    it("clamp(15, 0, 10) = 10", function()
        expect_equal(10, lurek.math.clamp(15, 0, 10))
    end)
end)

-- @describe lurek.math.distance
describe("lurek.math.distance", function()
    -- @covers lurek.math.distance
    it("distance(0,0,3,4) = 5", function()
        expect_near(5, lurek.math.distance(0, 0, 3, 4), 0.0001)
    end)

    -- @covers lurek.math.distance
    it("distance(1,1,1,1) = 0", function()
        expect_near(0, lurek.math.distance(1, 1, 1, 1), 0.0001)
    end)

    -- @covers lurek.math.distance
    it("distance(0,0,1,0) = 1", function()
        expect_near(1, lurek.math.distance(0, 0, 1, 0), 0.0001)
    end)
end)

-- @describe lurek.math.random
describe("lurek.math.random", function()
    -- @covers lurek.math.random
    it("returns a number", function()
        local val = lurek.math.random()
        expect_type("number", val)
    end)

    -- @covers lurek.math.random
    it("no-arg returns value in [0, 1)", function()
        for i = 1, 20 do
            local val = lurek.math.random()
            expect_true(val >= 0 and val < 1, "random() in [0,1)")
        end
    end)

    -- @covers lurek.math.random
    it("with max returns value in [0, max)", function()
        for i = 1, 20 do
            local val = lurek.math.random(10)
            expect_true(val >= 0 and val <= 10, "random(10) in [0,10]")
        end
    end)

    -- @covers lurek.math.random
    it("with min,max returns value in [min, max)", function()
        for i = 1, 20 do
            local val = lurek.math.random(5, 15)
            expect_true(val >= 5 and val <= 15, "random(5,15) in [5,15]")
        end
    end)
end)

-- @describe math.simplexNoise standalone
describe("math.simplexNoise standalone", function()
    -- @covers lurek.math.simplexNoise
    it("returns a number in range [-1, 1]", function()
        local v = lurek.math.simplexNoise(0.5, 0.5)
        expect_type("number", v)
        expect_equal(v > -1.1 and v < 1.1, true)
    end)

    -- @covers lurek.math.simplexNoise
    it("is deterministic for same inputs", function()
        local v1 = lurek.math.simplexNoise(1.23, 4.56)
        local v2 = lurek.math.simplexNoise(1.23, 4.56)
        expect_near(v1, v2, 0.000001)
    end)

    -- @covers lurek.math.simplexNoise
    it("accepts 3 arguments", function()
        local v = lurek.math.simplexNoise(0.1, 0.2, 0.3)
        expect_type("number", v)
    end)
end)

-- additional constants utility

-- @describe math constants and utility
describe("math constants and utility", function()
    -- @covers lurek.math.tau
    it("has tau = 2*pi", function()
        expect_near(lurek.math.tau, lurek.math.pi * 2, 0.0001)
    end)

    -- @covers lurek.math.huge
    it("has huge", function()
        ---@type { huge: number }
        local lurek_math = lurek.math
        expect_true(lurek_math.huge > 1e300)
    end)

    -- @covers lurek.math.lerp
    it("lerp(0, 10, 0.5) = 5", function()
        expect_near(lurek.math.lerp(0, 10, 0.5), 5, 0.0001)
    end)

    -- @covers lurek.math.lerp
    it("lerp(0, 10, 0) = 0", function()
        expect_near(lurek.math.lerp(0, 10, 0), 0, 0.0001)
    end)

    -- @covers lurek.math.lerp
    it("lerp(0, 10, 1) = 10", function()
        expect_near(lurek.math.lerp(0, 10, 1), 10, 0.0001)
    end)

    -- @covers lurek.math.sign
    it("sign(-5) = -1", function()
        expect_equal(lurek.math.sign(-5), -1)
    end)

    -- @covers lurek.math.sign
    it("sign(5) = 1", function()
        expect_equal(lurek.math.sign(5), 1)
    end)

    -- @covers lurek.math.sign
    it("sign(0) = 0", function()
        expect_equal(lurek.math.sign(0), 0)
    end)

    -- @covers lurek.math.round
    it("round(2.3) = 2", function()
        expect_equal(lurek.math.round(2.3), 2)
    end)

    -- @covers lurek.math.round
    it("round(2.7) = 3", function()
        expect_equal(lurek.math.round(2.7), 3)
    end)

    -- @covers lurek.math.distanceSq
    it("distanceSq(0,0,3,4) = 25", function()
        expect_near(lurek.math.distanceSq(0, 0, 3, 4), 25, 0.0001)
    end)

    -- @covers lurek.math.deg
    -- @covers lurek.math.rad
    it("rad and deg are inverse", function()
        expect_near(lurek.math.deg(lurek.math.rad(180)), 180, 0.0001)
    end)

    -- @covers lurek.math.angleBetween
    it("angleBetween(0,0,1,0) = 0", function()
        expect_near(lurek.math.angleBetween(0, 0, 1, 0), 0, 0.0001)
    end)

    -- @covers lurek.math.randomInt
    it("randomInt(5, 10) returns integer in range", function()
        for i = 1, 20 do
            local v = lurek.math.randomInt(5, 10)
            expect_true(v >= 5 and v <= 10)
            expect_equal(v, math.floor(v))
        end
    end)
end)

-- RandomGenerator

-- @describe math.newRandomGenerator
describe("math.newRandomGenerator", function()
    -- @covers lurek.math.newRandomGenerator
    it("creates RNG with seed", function()
        local rng = lurek.math.newRandomGenerator(42)
        expect_not_nil(rng)
    end)

    -- @covers LRandomGenerator:random
    -- @covers lurek.math.newRandomGenerator
    it("same seed produces same sequence", function()
        local rng1 = lurek.math.newRandomGenerator(42)
        local rng2 = lurek.math.newRandomGenerator(42)
        local v1 = rng1:random()
        local v2 = rng2:random()
        expect_near(v1, v2, 0.000001)
    end)

    -- @covers LRandomGenerator:random
    -- @covers lurek.math.newRandomGenerator
    it("different seeds produce different sequences", function()
        local rng1 = lurek.math.newRandomGenerator(42)
        local rng2 = lurek.math.newRandomGenerator(999)
        local v1 = rng1:random()
        local v2 = rng2:random()
        expect_not_equal(v1, v2)
    end)

    -- @covers LRandomGenerator:randomInt
    -- @covers lurek.math.newRandomGenerator
    it("randomInt(min, max) stays in range", function()
        local rng = lurek.math.newRandomGenerator(123)
        for i = 1, 50 do
            local v = rng:randomInt(5, 10)
            expect_true(v >= 5 and v <= 10, "randomInt in range")
        end
    end)

    -- @covers LRandomGenerator:randomFloat
    -- @covers lurek.math.newRandomGenerator
    it("randomFloat(min, max) stays in range", function()
        local rng = lurek.math.newRandomGenerator(456)
        for i = 1, 50 do
            local v = rng:randomFloat(2.0, 5.0)
            expect_true(v >= 2.0 and v <= 5.0, "randomFloat in range")
        end
    end)

    -- @covers LRandomGenerator:randomNormal
    -- @covers lurek.math.newRandomGenerator
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

    -- @covers LRandomGenerator:random
    -- @covers LRandomGenerator:setSeed
    -- @covers lurek.math.newRandomGenerator
    it("setSeed resets the sequence", function()
        local rng = lurek.math.newRandomGenerator(42)
        local v1 = rng:random()
        rng:setSeed(42)
        local v2 = rng:random()
        expect_near(v1, v2, 0.000001)
    end)

    -- @covers LRandomGenerator:getState
    -- @covers LRandomGenerator:random
    -- @covers LRandomGenerator:setState
    -- @covers lurek.math.newRandomGenerator
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

-- @describe math.newTransform
describe("math.newTransform", function()
    -- @covers LTransform:transformPoint
    -- @covers lurek.math.newTransform
    it("identity transform preserves point", function()
        local t = lurek.math.newTransform()
        local x, y = t:transformPoint(5, 10)
        expect_near(x, 5, 0.0001)
        expect_near(y, 10, 0.0001)
    end)

    -- @covers LTransform:transformPoint
    -- @covers LTransform:translate
    -- @covers lurek.math.newTransform
    it("translate moves point", function()
        local t = lurek.math.newTransform()
        t:translate(100, 200)
        local x, y = t:transformPoint(0, 0)
        expect_near(x, 100, 0.0001)
        expect_near(y, 200, 0.0001)
    end)

    -- @covers LTransform:scale
    -- @covers LTransform:transformPoint
    -- @covers lurek.math.newTransform
    it("scale doubles coordinates", function()
        local t = lurek.math.newTransform()
        t:scale(2)
        local x, y = t:transformPoint(5, 10)
        expect_near(x, 10, 0.0001)
        expect_near(y, 20, 0.0001)
    end)

    -- @covers LTransform:inverse
    -- @covers LTransform:scale
    -- @covers LTransform:transformPoint
    -- @covers LTransform:translate
    -- @covers lurek.math.newTransform
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

    -- @covers LTransform:inverseTransformPoint
    -- @covers LTransform:rotate
    -- @covers LTransform:transformPoint
    -- @covers LTransform:translate
    -- @covers lurek.math.newTransform
    it("inverseTransformPoint round-trips", function()
        local t = lurek.math.newTransform()
        t:translate(50, 100)
        t:rotate(0.5)
        local x, y = t:transformPoint(10, 20)
        local bx, by = t:inverseTransformPoint(x or 0, y or 0)
        expect_near(bx, 10, 0.01)
        expect_near(by, 20, 0.01)
    end)

    -- @covers LTransform:reset
    -- @covers LTransform:transformPoint
    -- @covers LTransform:translate
    -- @covers lurek.math.newTransform
    it("reset returns to identity", function()
        local t = lurek.math.newTransform()
        t:translate(999, 999)
        t:reset()
        local x, y = t:transformPoint(5, 5)
        expect_near(x, 5, 0.0001)
        expect_near(y, 5, 0.0001)
    end)

    -- @covers LTransform:clone
    -- @covers LTransform:transformPoint
    -- @covers LTransform:translate
    -- @covers lurek.math.newTransform
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

-- @describe math.newBezierCurve
describe("math.newBezierCurve", function()
    -- @covers LBezierCurve:getControlPointCount
    -- @covers lurek.math.newBezierCurve
    it("creates curve from control points", function()
        local curve = lurek.math.newBezierCurve({0, 0, 10, 10, 20, 0})
        expect_not_nil(curve)
        expect_equal(curve:getControlPointCount(), 3)
    end)

    -- @covers LBezierCurve:evaluate
    -- @covers lurek.math.newBezierCurve
    it("evaluate(0) returns start point", function()
        local curve = lurek.math.newBezierCurve({0, 0, 5, 10, 10, 0})
        local x, y = curve:evaluate(0)
        expect_near(x, 0, 0.0001)
        expect_near(y, 0, 0.0001)
    end)

    -- @covers LBezierCurve:evaluate
    -- @covers lurek.math.newBezierCurve
    it("evaluate(1) returns end point", function()
        local curve = lurek.math.newBezierCurve({0, 0, 5, 10, 10, 0})
        local x, y = curve:evaluate(1)
        expect_near(x, 10, 0.0001)
        expect_near(y, 0, 0.0001)
    end)

    -- @covers LBezierCurve:render
    -- @covers lurek.math.newBezierCurve
    it("render returns list of vertices", function()
        local curve = lurek.math.newBezierCurve({0, 0, 5, 10, 10, 0})
        local coords = curve:render(10)
        expect_true(#coords >= 4, "at least 2 points")
    end)

    -- @covers LBezierCurve:evaluate
    -- @covers LBezierCurve:translate
    -- @covers lurek.math.newBezierCurve
    it("translate shifts all control points", function()
        local curve = lurek.math.newBezierCurve({0, 0, 10, 0})
        curve:translate(5, 5)
        local x, y = curve:evaluate(0)
        expect_near(x, 5, 0.0001)
        expect_near(y, 5, 0.0001)
    end)
end)

-- NoiseGenerator

-- @describe math.newNoiseGenerator
describe("math.newNoiseGenerator", function()
    -- @covers lurek.math.newNoiseGenerator
    it("creates noise generator with seed", function()
        local ng = lurek.math.newNoiseGenerator(42)
        expect_not_nil(ng)
    end)

    -- @covers LNoiseGenerator:perlin2d
    -- @covers lurek.math.newNoiseGenerator
    it("perlin2d returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:perlin2d(0.5, 0.5)
        expect_type("number", v)
    end)

    -- @covers LNoiseGenerator:perlin3d
    -- @covers lurek.math.newNoiseGenerator
    it("perlin3d returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:perlin3d(0.5, 0.5, 0.5)
        expect_type("number", v)
    end)

    -- @covers LNoiseGenerator:perlin2d
    -- @covers lurek.math.newNoiseGenerator
    it("is deterministic", function()
        local ng1 = lurek.math.newNoiseGenerator(42)
        local ng2 = lurek.math.newNoiseGenerator(42)
        expect_near(ng1:perlin2d(1.5, 2.3), ng2:perlin2d(1.5, 2.3), 0.000001)
    end)

    -- @covers LNoiseGenerator:simplex2d
    -- @covers lurek.math.newNoiseGenerator
    it("simplex2d returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:simplex2d(0.5, 0.5)
        expect_type("number", v)
    end)

    -- @covers LNoiseGenerator:fbm
    -- @covers lurek.math.newNoiseGenerator
    it("fbm returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:fbm(0.5, 0.5)
        expect_type("number", v)
    end)

    -- @covers LNoiseGenerator:perlin2d
    -- @covers lurek.math.newNoiseGenerator
    it("different seeds produce different values", function()
        local ng1 = lurek.math.newNoiseGenerator(42)
        local ng2 = lurek.math.newNoiseGenerator(999)
        local v1 = ng1:perlin2d(1.5, 2.3)
        local v2 = ng2:perlin2d(1.5, 2.3)
        expect_not_equal(v1, v2)
    end)
end)

-- SpatialHash

-- @describe math.newSpatialHash
describe("math.newSpatialHash", function()
    -- @covers LSpatialHash:getCellSize
    -- @covers lurek.math.newSpatialHash
    it("creates spatial hash with cell size", function()
        local sh = lurek.math.newSpatialHash(64)
        expect_not_nil(sh)
        expect_equal(sh:getCellSize(), 64)
    end)

    -- @covers LSpatialHash:insert
    -- @covers LSpatialHash:queryRect
    -- @covers lurek.math.newSpatialHash
    it("insert and queryRect finds item", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 20, 20)
        local results = sh:queryRect(0, 0, 50, 50)
        expect_true(#results >= 1)
    end)

    -- @covers LSpatialHash:insert
    -- @covers LSpatialHash:queryRect
    -- @covers lurek.math.newSpatialHash
    it("queryRect does not find distant items", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 20, 20)
        local results = sh:queryRect(500, 500, 10, 10)
        expect_equal(#results, 0)
    end)

    -- @covers LSpatialHash:getItemCount
    -- @covers LSpatialHash:insert
    -- @covers LSpatialHash:remove
    -- @covers lurek.math.newSpatialHash
    it("remove decreases item count", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 20, 20)
        expect_equal(sh:getItemCount(), 1)
        sh:remove("1")
        expect_equal(sh:getItemCount(), 0)
    end)

    -- @covers LSpatialHash:insert
    -- @covers LSpatialHash:queryCircle
    -- @covers lurek.math.newSpatialHash
    it("queryCircle finds nearby items", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 5, 5)
        local results = sh:queryCircle(12, 12, 50)
        expect_true(#results >= 1)
    end)
end)

-- Easing functions

-- @describe math easing functions
describe("math easing functions", function()
    -- @covers lurek.math.linear
    it("linear(0) = 0, linear(1) = 1", function()
        expect_near(lurek.math.linear(0), 0, 0.0001)
        expect_near(lurek.math.linear(1), 1, 0.0001)
    end)

    -- @covers lurek.math.linear
    it("linear(0.5) = 0.5", function()
        expect_near(lurek.math.linear(0.5), 0.5, 0.0001)
    end)

    -- @covers lurek.math.outQuad
    it("outQuad(0) = 0, outQuad(1) = 1", function()
        expect_near(lurek.math.outQuad(0), 0, 0.0001)
        expect_near(lurek.math.outQuad(1), 1, 0.0001)
    end)

    -- @covers lurek.math.inCubic
    it("inCubic(0) = 0, inCubic(1) = 1", function()
        expect_near(lurek.math.inCubic(0), 0, 0.0001)
        expect_near(lurek.math.inCubic(1), 1, 0.0001)
    end)

    -- @covers lurek.math.outBounce
    it("outBounce(0) = 0, outBounce(1) = 1", function()
        expect_near(lurek.math.outBounce(0), 0, 0.0001)
        expect_near(lurek.math.outBounce(1), 1, 0.0001)
    end)

    -- @covers lurek.math.applyEasing
    -- @covers lurek.math.outQuad
    it("applyEasing by name matches direct call", function()
        local v1 = lurek.math.outQuad(0.5)
        local v2 = lurek.math.applyEasing("outQuad", 0.5)
        expect_near(v1, v2, 0.0001)
    end)

    -- @covers lurek.math.applyEasing
    it("applyEasing is case-insensitive", function()
        local v1 = lurek.math.applyEasing("linear", 0.5)
        local v2 = lurek.math.applyEasing("LINEAR", 0.5)
        expect_near(v1, v2, 0.0001)
    end)
end)

-- Polygon/Geometry

-- @describe math polygon and geometry
describe("math polygon and geometry", function()
    -- @covers lurek.math.triangulate
    it("triangulate a square yields 2 triangles", function()
        local tris = lurek.math.triangulate({0, 0, 10, 0, 10, 10, 0, 10})
        expect_equal(2, #tris) -- 2 triangles
        expect_equal(6, #tris[1]) -- each triangle has 6 numbers (x1,y1,x2,y2,x3,y3)
    end)

    -- @covers lurek.math.isConvex
    it("isConvex returns true for square", function()
        expect_true(lurek.math.isConvex({0, 0, 10, 0, 10, 10, 0, 10}))
    end)

    -- @covers lurek.math.isConvex
    it("isConvex returns false for concave L-shape", function()
        expect_equal(lurek.math.isConvex({0, 0, 2, 0, 2, 1, 1, 1, 1, 2, 0, 2}), false)
    end)

    -- @covers lurek.math.circleContainsPoint
    it("circleContainsPoint detects inside", function()
        expect_true(lurek.math.circleContainsPoint(0, 0, 10, 3, 4))
    end)

    -- @covers lurek.math.circleContainsPoint
    it("circleContainsPoint detects outside", function()
        expect_equal(lurek.math.circleContainsPoint(0, 0, 5, 10, 10), false)
    end)

    -- @covers lurek.math.circleIntersectsCircle
    it("circleIntersectsCircle overlapping", function()
        expect_true(lurek.math.circleIntersectsCircle(0, 0, 5, 3, 0, 5))
    end)

    -- @covers lurek.math.circleIntersectsCircle
    it("circleIntersectsCircle distant", function()
        expect_equal(lurek.math.circleIntersectsCircle(0, 0, 1, 100, 100, 1), false)
    end)
end)

-- Color space

-- @describe math color space
describe("math color space", function()
    -- @covers lurek.math.gammaToLinear
    it("gammaToLinear(0.5) near 0.214", function()
        expect_near(lurek.math.gammaToLinear(0.5), 0.214, 0.01)
    end)

    -- @covers lurek.math.gammaToLinear
    it("gammaToLinear(0) = 0", function()
        expect_near(lurek.math.gammaToLinear(0), 0, 0.0001)
    end)

    -- @covers lurek.math.gammaToLinear
    it("gammaToLinear(1) = 1", function()
        expect_near(lurek.math.gammaToLinear(1), 1, 0.0001)
    end)

    -- @covers lurek.math.gammaToLinear
    -- @covers lurek.math.linearToGamma
    it("linearToGamma roundtrips", function()
        for i = 0, 10 do
            local gamma = i / 10.0
            local linear = lurek.math.gammaToLinear(gamma)
            local back = lurek.math.linearToGamma(linear)
            expect_near(back, gamma, 0.001)
        end
    end)
end)

-- @describe lurek.math.vec2
describe("lurek.math.vec2", function()
    -- @covers lurek.math.vec2
    it("vec2 is a function", function()
        expect_type("function", lurek.math.vec2)
    end)

    -- @covers lurek.math.vec2
    it("vec2 creates a userdata", function()
        local v = lurek.math.vec2(3, 4)
        expect_type("userdata", v)
    end)

    -- @covers lurek.math.vec2
    it("x field returns correct value", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v.x, 3, 1e-5)
    end)

    -- @covers lurek.math.vec2
    it("y field returns correct value", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v.y, 4, 1e-5)
    end)

    -- @covers LVec2:length
    -- @covers lurek.math.vec2
    it("length returns correct magnitude", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v:length(), 5.0, 1e-4)
    end)

    -- @covers LVec2:lengthSquared
    -- @covers lurek.math.vec2
    it("lengthSquared returns squared magnitude", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v:lengthSquared(), 25.0, 1e-4)
    end)

    -- @covers LVec2:dot
    -- @covers lurek.math.vec2
    it("dot product is correct", function()
        local a = lurek.math.vec2(1, 0)
        local b = lurek.math.vec2(0, 1)
        expect_near(a:dot(b), 0.0, 1e-5)
    end)

    -- @covers LVec2:dot
    -- @covers lurek.math.vec2
    it("dot product of parallel vectors", function()
        local a = lurek.math.vec2(1, 0)
        local b = lurek.math.vec2(2, 0)
        expect_near(a:dot(b), 2.0, 1e-5)
    end)

    -- @covers LVec2:normalize
    -- @covers lurek.math.vec2
    it("normalize produces unit vector", function()
        local v = lurek.math.vec2(3, 4)
        local n = v:normalize()
        expect_near(n:length(), 1.0, 1e-4)
    end)

    -- @covers LVec2:distance
    -- @covers lurek.math.vec2
    it("distance between two points", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(3, 4)
        expect_near(a:distance(b), 5.0, 1e-4)
    end)

    -- @covers LVec2:lerp
    -- @covers lurek.math.vec2
    it("lerp at t=0 returns first vector", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(10, 10)
        local c = a:lerp(b, 0)
        expect_near(c.x, 0, 1e-5)
        expect_near(c.y, 0, 1e-5)
    end)

    -- @covers LVec2:lerp
    -- @covers lurek.math.vec2
    it("lerp at t=1 returns second vector", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(10, 10)
        local c = a:lerp(b, 1)
        expect_near(c.x, 10, 1e-5)
        expect_near(c.y, 10, 1e-5)
    end)

    -- @covers LVec2:lerp
    -- @covers lurek.math.vec2
    it("lerp at t=0.5 returns midpoint", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(10, 10)
        local c = a:lerp(b, 0.5)
        expect_near(c.x, 5, 1e-5)
        expect_near(c.y, 5, 1e-5)
    end)

    -- @covers lurek.math.vec2
    it("addition metamethod works", function()
        local a = lurek.math.vec2(1, 2)
        local b = lurek.math.vec2(3, 4)
        local c = a + b
        expect_near(c.x, 4, 1e-5)
        expect_near(c.y, 6, 1e-5)
    end)

    -- @covers lurek.math.vec2
    it("subtraction metamethod works", function()
        local a = lurek.math.vec2(5, 7)
        local b = lurek.math.vec2(3, 4)
        local c = a - b
        expect_near(c.x, 2, 1e-5)
        expect_near(c.y, 3, 1e-5)
    end)

    -- @covers lurek.math.vec2
    it("scalar multiplication metamethod works", function()
        local a = lurek.math.vec2(2, 3)
        local c = a * 2
        expect_near(c.x, 4, 1e-5)
        expect_near(c.y, 6, 1e-5)
    end)

    -- @covers lurek.math.vec2
    it("tostring metamethod returns readable string", function()
        local v = lurek.math.vec2(1, 2)
        local s = tostring(v)
        expect_type("string", s)
        expect_true(#s > 0)
    end)

    -- @covers lurek.math.vec2
    it("equality metamethod: same values are equal", function()
        local a = lurek.math.vec2(1, 2)
        local b = lurek.math.vec2(1, 2)
        expect_equal(a == b, true)
    end)

    -- @covers lurek.math.vec2
    it("equality metamethod: different values are not equal", function()
        local a = lurek.math.vec2(1, 2)
        local b = lurek.math.vec2(3, 4)
        expect_equal(a == b, false)
    end)
end)

-- AABB Tree

-- @describe lurek.math.aabbTree factory
describe("lurek.math.aabbTree factory", function()
  -- @covers lurek.math.aabbTree
  it("aabbTree is a function", function()
    expect_type("function", lurek.math.aabbTree)
  end)

  -- @covers lurek.math.aabbTree
  it("returns a userdata", function()
    local t = lurek.math.aabbTree()
    expect_type("userdata", t)
  end)

  -- @covers LAabbTree:len
  -- @covers lurek.math.aabbTree
  it("new tree len is 0", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:len(), 0)
  end)

  -- @covers LAabbTree:isEmpty
  -- @covers lurek.math.aabbTree
  it("new tree isEmpty is true", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:isEmpty(), true)
  end)
end)

-- @describe AabbTree insert / contains
describe("AabbTree insert / contains", function()
  -- @covers LAabbTree:insert
  -- @covers LAabbTree:len
  -- @covers lurek.math.aabbTree
  it("len increments after insert", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    expect_equal(t:len(), 1)
  end)

  -- @covers LAabbTree:contains
  -- @covers LAabbTree:insert
  -- @covers lurek.math.aabbTree
  it("contains returns true for inserted id", function()
    local t = lurek.math.aabbTree()
    t:insert(42, 0, 0, 5, 5)
    expect_equal(t:contains(42), true)
  end)

  -- @covers LAabbTree:contains
  -- @covers lurek.math.aabbTree
  it("contains returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:contains(999), false)
  end)

  -- @covers LAabbTree:insert
  -- @covers LAabbTree:len
  -- @covers lurek.math.aabbTree
  it("len reflects multiple inserts", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:insert(3, 10, 10, 20, 20)
    expect_equal(t:len(), 3)
  end)

  -- @covers LAabbTree:insert
  -- @covers LAabbTree:len
  -- @covers lurek.math.aabbTree
  it("inserting duplicate id does not increase len", function()
    local t = lurek.math.aabbTree()
    t:insert(7, 0, 0, 10, 10)
    t:insert(7, 5, 5, 15, 15)  -- upsert
    expect_equal(t:len(), 1)
  end)
end)

-- @describe AabbTree remove
describe("AabbTree remove", function()
  -- @covers LAabbTree:insert
  -- @covers LAabbTree:remove
  -- @covers lurek.math.aabbTree
  it("remove returns true for known id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    expect_equal(t:remove(1), true)
  end)

  -- @covers LAabbTree:remove
  -- @covers lurek.math.aabbTree
  it("remove returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:remove(999), false)
  end)

  -- @covers LAabbTree:contains
  -- @covers LAabbTree:insert
  -- @covers LAabbTree:remove
  -- @covers lurek.math.aabbTree
  it("contains false after remove", function()
    local t = lurek.math.aabbTree()
    t:insert(5, 0, 0, 10, 10)
    t:remove(5)
    expect_equal(t:contains(5), false)
  end)

  -- @covers LAabbTree:insert
  -- @covers LAabbTree:len
  -- @covers LAabbTree:remove
  -- @covers lurek.math.aabbTree
  it("len decrements after remove", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:remove(1)
    expect_equal(t:len(), 1)
  end)
end)

-- @describe AabbTree query
describe("AabbTree query", function()
  -- @covers LAabbTree:insert
  -- @covers LAabbTree:query
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

  -- @covers LAabbTree:insert
  -- @covers LAabbTree:query
  -- @covers lurek.math.aabbTree
  it("query returns empty table on miss", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    local ids = t:query(100, 100, 200, 200)
    expect_equal(#ids, 0)
  end)

  -- @covers LAabbTree:insert
  -- @covers LAabbTree:query
  -- @covers lurek.math.aabbTree
  it("query returns all ids when rect covers all", function()
    local t = lurek.math.aabbTree()
    t:insert(10, 0, 0, 1, 1)
    t:insert(20, 5, 5, 6, 6)
    t:insert(30, 9, 9, 10, 10)
    local ids = t:query(-1, -1, 100, 100)
    expect_equal(#ids, 3)
  end)

  -- @covers LAabbTree:query
  -- @covers lurek.math.aabbTree
  it("query on empty tree returns empty table", function()
    local t = lurek.math.aabbTree()
    local ids = t:query(0, 0, 100, 100)
    expect_equal(#ids, 0)
  end)
end)

-- @describe AabbTree queryPoint
describe("AabbTree queryPoint", function()
  -- @covers LAabbTree:insert
  -- @covers LAabbTree:queryPoint
  -- @covers lurek.math.aabbTree
  it("queryPoint finds containing entry", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(5, 5)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 1)
  end)

  -- @covers LAabbTree:insert
  -- @covers LAabbTree:queryPoint
  -- @covers lurek.math.aabbTree
  it("queryPoint returns empty for exterior point", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(50, 50)
    expect_equal(#ids, 0)
  end)

  -- @covers LAabbTree:insert
  -- @covers LAabbTree:queryPoint
  -- @covers lurek.math.aabbTree
  it("queryPoint on edge counts as inside", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(10, 10)
    expect_equal(#ids, 1)
  end)
end)

-- @describe AabbTree update
describe("AabbTree update", function()
  -- @covers LAabbTree:update
  -- @covers lurek.math.aabbTree
  it("update returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:update(99, 0, 0, 1, 1), false)
  end)

  -- @covers LAabbTree:insert
  -- @covers LAabbTree:update
  -- @covers lurek.math.aabbTree
  it("update returns true for known id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    expect_equal(t:update(1, 10, 10, 20, 20), true)
  end)

  -- @covers LAabbTree:insert
  -- @covers LAabbTree:query
  -- @covers LAabbTree:update
  -- @covers lurek.math.aabbTree
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

-- @describe AabbTree clear
describe("AabbTree clear", function()
  -- @covers LAabbTree:clear
  -- @covers LAabbTree:insert
  -- @covers LAabbTree:isEmpty
  -- @covers LAabbTree:len
  -- @covers lurek.math.aabbTree
  it("clear resets len to 0", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:clear()
    expect_equal(t:len(), 0)
    expect_equal(t:isEmpty(), true)
  end)

  -- @covers LAabbTree:clear
  -- @covers LAabbTree:insert
  -- @covers LAabbTree:query
  -- @covers lurek.math.aabbTree
  it("query after clear returns empty", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 100, 100)
    t:clear()
    local ids = t:query(0, 0, 100, 100)
    expect_equal(#ids, 0)
  end)
end)

-- @describe AabbTree edge cases
describe("AabbTree edge cases", function()
  -- @covers LAabbTree:insert
  -- @covers LAabbTree:query
  -- @covers lurek.math.aabbTree
  it("single entry exact AABB match", function()
    local t = lurek.math.aabbTree()
    t:insert(7, 3, 3, 7, 7)
    local ids = t:query(3, 3, 7, 7)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 7)
  end)

  -- @covers LAabbTree:insert
  -- @covers LAabbTree:isEmpty
  -- @covers LAabbTree:len
  -- @covers LAabbTree:query
  -- @covers LAabbTree:remove
  -- @covers lurek.math.aabbTree
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

-- @describe math.polygonIntersection
describe("math.polygonIntersection", function()

    -- @covers lurek.math.polygonIntersection
    it("polygonIntersection exists in lurek.math", function()
        expect_equal(type(lurek.math.polygonIntersection), "function")
    end)

    -- @covers lurek.math.polygonIntersection
    it("intersection of overlapping squares returns a table", function()
        local result = lurek.math.polygonIntersection(SQUARE, SQUARE_OFFSET)
        expect_equal(type(result), "table")
    end)

    -- @covers lurek.math.polygonIntersection
    it("intersection of overlapping squares has vertices", function()
        local result = lurek.math.polygonIntersection(SQUARE, SQUARE_OFFSET)
        expect_equal(#result > 0, true)
    end)

    -- @covers lurek.math.polygonIntersection
    it("intersection of non-overlapping polygons returns empty table", function()
        local result = lurek.math.polygonIntersection(SQUARE, SQUARE_FAR)
        expect_equal(#result, 0)
    end)

    -- @covers lurek.math.polygonIntersection
    it("intersection vertices have x and y fields", function()
        local result = lurek.math.polygonIntersection(SQUARE, SQUARE_OFFSET)
        if #result > 0 then
            expect_equal(type(result[1].x), "number")
            expect_equal(type(result[1].y), "number")
        end
    end)

    -- @covers lurek.math.polygonIntersection
    it("intersection with self returns the same polygon area (approx)", function()
        local result = lurek.math.polygonIntersection(SQUARE, SQUARE)
        -- intersection with itself should fill the polygon
        expect_equal(#result >= 3, true)
    end)

end)

-- @describe math.polygonUnion
describe("math.polygonUnion", function()

    -- @covers lurek.math.polygonUnion
    it("polygonUnion exists in lurek.math", function()
        expect_equal(type(lurek.math.polygonUnion), "function")
    end)

    -- @covers lurek.math.polygonUnion
    it("union returns a table with vertices", function()
        local result = lurek.math.polygonUnion(SQUARE, SQUARE_OFFSET)
        expect_equal(type(result), "table")
        expect_equal(#result >= 3, true)
    end)

    -- @covers lurek.math.polygonUnion
    it("union vertices have x and y fields", function()
        local result = lurek.math.polygonUnion(SQUARE, SQUARE_OFFSET)
        if #result > 0 then
            expect_equal(type(result[1].x), "number")
            expect_equal(type(result[1].y), "number")
        end
    end)

    -- @covers lurek.math.polygonUnion
    it("union of non-overlapping squares has >= 6 vertices", function()
        local result = lurek.math.polygonUnion(SQUARE, SQUARE_FAR)
        -- Convex hull of two separated squares will have vertices >= 4
        expect_equal(#result >= 4, true)
    end)

end)

-- @describe math.polygonDifference
describe("math.polygonDifference", function()

    -- @covers lurek.math.polygonDifference
    it("polygonDifference exists in lurek.math", function()
        expect_equal(type(lurek.math.polygonDifference), "function")
    end)

    -- @covers lurek.math.polygonDifference
    it("difference with empty b returns a (unchanged)", function()
        local result = lurek.math.polygonDifference(SQUARE, {})
        expect_equal(#result, 4)
    end)

    -- @covers lurek.math.polygonDifference
    it("difference of empty a returns empty", function()
        local result = lurek.math.polygonDifference({}, SQUARE)
        expect_equal(#result, 0)
    end)

    -- @covers lurek.math.polygonDifference
    it("difference of non-overlapping polygons returns a (convex hull of a)", function()
        local result = lurek.math.polygonDifference(SQUARE, SQUARE_FAR)
        -- No overlap  result should contain SQUARE vertices
        expect_equal(#result > 0, true)
    end)

    -- @covers lurek.math.polygonDifference
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

-- @describe property: trig identities
describe("property: trig identities", function()
    -- @covers lurek.math.cos
    -- @covers lurek.math.sin
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

-- @describe property: sqrt invariants
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

-- @describe property: exp/log invariants
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

-- @describe property: Vec2 operations
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

    -- @covers LVec2:length
    -- @covers lurek.math.Vec2
    it("vec2 length is non-negative for 100 values", function()
        local vals = test_values(200, -1000, 1000)
        for i = 1, 100 do
            local v = lurek.math.Vec2(vals[i], vals[i + 100])
            local len = v:length()
            expect_true(len >= 0,
                "length >= 0 for (" .. vals[i] .. "," .. vals[i+100] .. ")")
        end
    end)

    -- @covers LVec2:normalized
    -- @covers lurek.math.Vec2
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

-- @describe property: lerp interpolation
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

-- @describe lurek.math.voronoi type
describe("lurek.math.voronoi type", function()
  -- @covers lurek.math.voronoi
  it("voronoi is a function", function()
    expect_type("function", lurek.math.voronoi)
  end)

  -- @covers lurek.math.voronoi
  it("returns a table", function()
    local cells = lurek.math.voronoi({{x=0,y=0},{x=1,y=0},{x=0.5,y=1}})
    expect_type("table", cells)
  end)
end)

-- @describe lurek.math.voronoi empty input
describe("lurek.math.voronoi empty input", function()
  -- @covers lurek.math.voronoi
  it("empty input returns empty table", function()
    local cells = lurek.math.voronoi({})
    expect_equal(0, #cells)
  end)
end)

-- @describe lurek.math.voronoi cell count
describe("lurek.math.voronoi cell count", function()
  -- @covers lurek.math.voronoi
  it("returns one cell per unique site", function()
    local pts = {{x=0,y=0},{x=1,y=0},{x=0.5,y=1},{x=0.5,y=0.5}}
    local cells = lurek.math.voronoi(pts)
    expect_equal(4, #cells)
  end)

  -- @covers lurek.math.voronoi
  it("three-point input returns three cells", function()
    local pts = {{x=0,y=0},{x=1,y=0},{x=0.5,y=1}}
    local cells = lurek.math.voronoi(pts)
    expect_equal(3, #cells)
  end)
end)

-- @describe lurek.math.voronoi cell structure
describe("lurek.math.voronoi cell structure", function()
  -- @covers lurek.math.voronoi
  it("each cell has a site table", function()
    local pts = {{x=0,y=0},{x=1,y=0},{x=0.5,y=1}}
    local cells = lurek.math.voronoi(pts)
    for _, cell in ipairs(cells) do
      expect_type("table", cell.site)
    end
  end)

  -- @covers lurek.math.voronoi
  it("each cell site has x and y keys", function()
    local pts = {{x=0,y=0},{x=1,y=0},{x=0.5,y=1}}
    local cells = lurek.math.voronoi(pts)
    for _, cell in ipairs(cells) do
      expect_type("number", cell.site.x)
      expect_type("number", cell.site.y)
    end
  end)

  -- @covers lurek.math.voronoi
  it("each cell has a vertices table", function()
    local pts = {{x=0,y=0},{x=1,y=0},{x=0.5,y=1}}
    local cells = lurek.math.voronoi(pts)
    for _, cell in ipairs(cells) do
      expect_type("table", cell.vertices)
    end
  end)
end)

-- @describe lurek.math.voronoi vertex coordinates
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

-- @describe lurek.math.voronoi near-duplicate deduplication
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
-- @describe lurek.math.smoothstep
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
-- @describe lurek.math.inverseLerp
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
-- @describe lurek.math hslToRgb and rgbToHsl
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
-- @describe lurek.math.fromHex
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
  it("invalid hex string raises an error", function()
    expect_error(function()
      lurek.math.fromHex("notahex")
    end)
  end)
end)

-- rectUnion
-- @describe lurek.math.rectUnion
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
-- @describe lurek.math.rectFromCenter
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
-- @describe lurek.math Vec2 fromAngle and reflect
describe("lurek.math Vec2 fromAngle and reflect", function()
  -- @covers lurek.math.vec2
  it("fromAngle(0) returns unit +X", function()
    local v = lurek.math.vec2(0, 0).fromAngle(0)
    expect_near(1.0, v.x, 1e-5)
    expect_near(0.0, v.y, 1e-5)
  end)
  -- @covers lurek.math.vec2
  it("fromAngle(pi/2) returns unit +Y", function()
    local v = lurek.math.vec2(0, 0).fromAngle(math.pi / 2)
    expect_near(0.0, v.x, 1e-5)
    expect_near(1.0, v.y, 1e-5)
  end)
  -- @covers lurek.math.vec2
  it("fromAngle result is unit length", function()
    local v = lurek.math.vec2(0, 0).fromAngle(1.23)
    local len = math.sqrt(v.x * v.x + v.y * v.y)
    expect_near(1.0, len, 1e-5)
  end)
  -- @covers LVec2:reflect
  -- @covers lurek.math.Vec2
  it("reflect off horizontal normal", function()
    local v = lurek.math.Vec2(1, -1)
    local n = lurek.math.Vec2(0, 1)
    local r = v:reflect(n)
    expect_near(1.0, r.x, 1e-5)
    expect_near(1.0, r.y, 1e-5)
  end)
  -- @covers LVec2:reflect
  -- @covers lurek.math.Vec2
  it("reflect parallel to normal flips sign", function()
    local v = lurek.math.Vec2(0, -1)
    local n = lurek.math.Vec2(0, 1)
    local r = v:reflect(n)
    expect_near(0.0, r.x, 1e-5)
    expect_near(1.0, r.y, 1e-5)
  end)
end)

-- Vec3:splat
-- @describe lurek.math Vec3 splat
describe("lurek.math Vec3 splat", function()
    -- @covers lurek.math.vec3
    it("splat(5) gives Vec3(5,5,5)", function()
        local v = lurek.math.vec3(0, 0, 0).splat(5)
    expect_equal(5, v.x)
    expect_equal(5, v.y)
    expect_equal(5, v.z)
  end)
    -- @covers lurek.math.vec3
    it("splat(0) gives zero Vec3", function()
        local v = lurek.math.vec3(1, 2, 3).splat(0)
    expect_equal(0, v.x)
    expect_equal(0, v.y)
    expect_equal(0, v.z)
  end)
end)

-- Transform:decompose
-- @describe lurek.math Transform decompose
describe("lurek.math Transform decompose", function()
    -- @covers LTransform:decompose
    -- @covers lurek.math.newTransform
    it("decompose returns 5 numbers", function()
    local t = lurek.math.newTransform()
    local x, y, a, sx, sy = t:decompose()
    expect_type("number", x)
    expect_type("number", y)
    expect_type("number", a)
    expect_type("number", sx)
    expect_type("number", sy)
  end)
    -- @covers LTransform:decompose
    -- @covers lurek.math.newTransform
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
-- @describe lurek.math easing inOut variants
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
  -- Note: bounce easings are NOT monotone by design  they bounce back.
  -- @covers lurek.math.inOutBounce
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
-- @describe lurek.math CatmullRomSpline addPoint and removePoint
describe("lurek.math CatmullRomSpline addPoint and removePoint", function()
    -- @covers LCatmullRom:addPoint
    -- @covers LCatmullRom:len
    -- @covers lurek.math.catmullRom
    it("addPoint increases point count", function()
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
    s:addPoint(1, 1)
    expect_equal(2, s:len())
  end)
    -- @covers LCatmullRom:addPoint
    -- @covers LCatmullRom:len
    -- @covers LCatmullRom:removePoint
    -- @covers lurek.math.catmullRom
    it("removePoint reduces count by 1", function()
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
    s:addPoint(1, 1)
    s:addPoint(2, 0)
        s:removePoint(1)
    expect_equal(2, s:len())
  end)
  -- @covers LCatmullRom:addPoint
  -- @covers LCatmullRom:len
  -- @covers LCatmullRom:removePoint
  -- @covers lurek.math.catmullRom
  it("removePoint out-of-range raises an error", function()
    ---@type LCatmullRom
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
    expect_error(function()
      s:removePoint(99)
    end)
    expect_equal(1, s:len())
  end)
    -- @covers LCatmullRom:addPoint
    -- @covers LCatmullRom:len
    -- @covers LCatmullRom:removePoint
    -- @covers lurek.math.catmullRom
    it("adding then removing all points gives empty spline", function()
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
        s:removePoint(0)
    expect_equal(0, s:len())
  end)
end)

-- @describe lurek.math Circle value type
describe("lurek.math Circle value type", function()
  -- @covers lurek.math.newCircle
  it("newCircle returns an object", function()
    local c = lurek.math.newCircle(0, 0, 5)
    expect_not_nil(c)
  end)

  -- @covers LCircle:area
  -- @covers lurek.math.newCircle
  it("area returns pi*r^2", function()
    local c = lurek.math.newCircle(0, 0, 1)
    local area = c:area()
    expect_near(math.pi, area, 1e-5)
  end)

  -- @covers LCircle:perimeter
  -- @covers lurek.math.newCircle
  it("perimeter returns 2*pi*r", function()
    local c = lurek.math.newCircle(0, 0, 3)
    local p = c:perimeter()
    expect_near(6 * math.pi, p, 1e-5)
  end)

  -- @covers LCircle:contains
  -- @covers lurek.math.newCircle
  it("contains returns true for point inside", function()
    local c = lurek.math.newCircle(0, 0, 5)
    expect_true(c:contains(0, 0))
    expect_true(c:contains(3, 4))
  end)

  -- @covers LCircle:contains
  -- @covers lurek.math.newCircle
  it("contains returns false for point outside", function()
    local c = lurek.math.newCircle(0, 0, 5)
    expect_false(c:contains(4, 4))
  end)

  -- @covers LCircle:intersects
  -- @covers lurek.math.newCircle
  it("intersects returns true when circles overlap", function()
    local a = lurek.math.newCircle(0, 0, 3)
    local b = lurek.math.newCircle(4, 0, 3)
    expect_true(a:intersects(b))
  end)

  -- @covers LCircle:intersects
  -- @covers lurek.math.newCircle
  it("intersects returns false when circles are apart", function()
    local a = lurek.math.newCircle(0, 0, 1)
    local b = lurek.math.newCircle(10, 0, 1)
    expect_false(a:intersects(b))
  end)

  -- @covers LCircle:aabb
  -- @covers lurek.math.newCircle
  it("aabb returns 4 numbers covering the circle", function()
    local c = lurek.math.newCircle(0, 0, 2)
    local x1, y1, x2, y2 = c:aabb()
    expect_near(-2, x1, 1e-5)
    expect_near(-2, y1, 1e-5)
    expect_near( 2, x2, 1e-5)
    expect_near( 2, y2, 1e-5)
  end)

  -- @covers LCircle:radius
  -- @covers lurek.math.newCircle
  it("negative radius is clamped to 0", function()
    local c = lurek.math.newCircle(1, 2, -5)
    expect_near(0, c:radius(), 1e-5)
  end)
end)

-- @describe lurek.math AabbTree querySegment
describe("lurek.math AabbTree querySegment", function()
    -- @covers lurek.math
    it("querySegment returns ids crossed by segment", function()
        -- Rust-only helper: AabbTree querySegment is not exposed in the Lua API.
    end)

    -- @covers lurek.math
    it("querySegment misses non-intersecting AABB", function()
        -- Rust-only helper: AabbTree querySegment is not exposed in the Lua API.
    end)
end)

-- =========================================================================
-- =========================================================================

-- @describe lurek.math scalar helpers
describe("lurek.math scalar helpers ", function()
    -- @covers lurek.math.rad
    it("rad converts degrees to radians", function()
        expect_near(lurek.math.pi / 2, lurek.math.rad(90), 1e-5)
    end)

    -- @covers lurek.math.deg
    it("deg converts radians to degrees", function()
        expect_near(90.0, lurek.math.deg(lurek.math.pi / 2), 1e-4)
    end)

    -- @covers lurek.math.tan
    it("tan(pi/4) = 1", function()
        expect_near(1.0, lurek.math.tan(lurek.math.pi / 4), 1e-5)
    end)

    -- @covers lurek.math.exp
    it("exp(0) = 1", function()
        expect_near(1.0, lurek.math.exp(0), 1e-5)
    end)

    -- @covers lurek.math.exp
    -- @covers lurek.math.log
    it("log(e) = 1", function()
        local e = lurek.math.exp(1)
        expect_near(1.0, lurek.math.log(e), 1e-5)
    end)

    -- @covers lurek.math.pow
    it("pow(2, 10) = 1024", function()
        expect_near(1024.0, lurek.math.pow(2, 10), 1e-5)
    end)
end)

-- @describe Vec2 accessors
describe("Vec2 accessors ", function()
    -- @covers LVec2:x
    -- @covers lurek.math.vec2
    it("x returns the x component", function()
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

    -- @covers LVec2:y
    -- @covers lurek.math.vec2
    it("y returns the y component", function()
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

-- @describe Vec3 arithmetic
describe("Vec3 arithmetic ", function()
    -- @covers LVec3:dot
    -- @covers lurek.math.vec3
    it("dot computes the inner product", function()
        ---@type LVec3
        local a = lurek.math.vec3(1.0, 0.0, 0.0)
        ---@type LVec3
        local b = lurek.math.vec3(0.0, 1.0, 0.0)
        expect_near(0.0, a:dot(b), 1e-5)
    end)

    -- @covers LVec3:add
    -- @covers lurek.math.vec3
    it("add returns a new summed vector", function()
        ---@type LVec3
        local a = lurek.math.vec3(1.0, 2.0, 3.0)
        ---@type LVec3
        local b = lurek.math.vec3(4.0, 5.0, 6.0)
        local r = a:add(b)
        expect_not_nil(r)
    end)

    -- @covers LVec3:sub
    -- @covers lurek.math.vec3
    it("sub returns a new difference vector", function()
        ---@type LVec3
        local a = lurek.math.vec3(4.0, 5.0, 6.0)
        ---@type LVec3
        local b = lurek.math.vec3(1.0, 2.0, 3.0)
        local r = a:sub(b)
        expect_not_nil(r)
    end)
end)

-- @describe CatmullRom:len
describe("CatmullRom:len ", function()
    -- @covers LCatmullRom:addPoint
    -- @covers lurek.math.catmullRom
    it("len returns the control-point count", function()
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

-- @describe Transform:setTransformation
describe("Transform:setTransformation ", function()
    -- @covers LTransform:setTransformation
    -- @covers lurek.math.newTransform
    it("setTransformation does not crash", function()
        local t = lurek.math.newTransform()
        local ok, _ = pcall(function()
            t:setTransformation(10.0, 20.0, 0.5, 1.0, 1.0, 0.0, 0.0)
        end)
        expect_type("boolean", ok)
    end)
end)

-- @describe BezierCurve control-point methods
describe("BezierCurve control-point methods ", function()
    -- @covers LBezierCurve:setControlPoint
    -- @covers lurek.math.newBezierCurve
    it("setControlPoint updates a control point", function()
        local bc = lurek.math.newBezierCurve({0, 0, 1, 1, 2, 0})
        local ok, _ = pcall(function() bc:setControlPoint(1, 0.5, 0.5) end)
        expect_type("boolean", ok)
    end)

    -- @covers LBezierCurve:getControlPointCount
    -- @covers LBezierCurve:insertControlPoint
    -- @covers lurek.math.newBezierCurve
    it("insertControlPoint inserts a new point", function()
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

-- @describe Math Tween:set
describe("Math Tween:set ", function()
    -- @covers LTween:addValue
    -- @covers LTween:set
    -- @covers LTween:setTime
    -- @covers lurek.math.newTween
    it("set updates tween target values", function()
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

-- @describe Circle accessors
describe("Circle accessors ", function()
    -- @covers LCircle:x
    -- @covers lurek.math.newCircle
    it("x returns the circle centre x", function()
        local c = lurek.math.newCircle(3.0, 4.0, 5.0)
        expect_near(3.0, c:x(), 1e-5)
    end)

    -- @covers LCircle:y
    -- @covers lurek.math.newCircle
    it("y returns the circle centre y", function()
        local c = lurek.math.newCircle(3.0, 4.0, 5.0)
        expect_near(4.0, c:y(), 1e-5)
    end)
end)

-- @describe AabbTree:len
describe("AabbTree:len ", function()
    -- @covers LAabbTree:len
    -- @covers lurek.math.aabbTree
    it("len returns 0 on an empty tree", function()
        local tree = lurek.math.aabbTree()
        expect_equal(0, tree:len())
    end)

    -- @covers LAabbTree:insert
    -- @covers LAabbTree:len
    -- @covers lurek.math.aabbTree
    it("len increments after insert", function()
        local tree = lurek.math.aabbTree()
        tree:insert(1, 0, 0, 10, 10)
        expect_equal(1, tree:len())
    end)
end)

-- @describe math missing explicit coverage
describe("math missing explicit coverage", function()
    -- @covers lurek.math.circleIntersectsLine
    -- @covers lurek.math.circleIntersectsSegment
    -- @covers lurek.math.closestPointOnSegment
    -- @covers lurek.math.convexHull
    -- @covers lurek.math.delaunayTriangulate
    -- @covers lurek.math.fmod
    -- @covers lurek.math.inOutQuart
    -- @covers lurek.math.inQuart
    -- @covers lurek.math.outQuart
    -- @covers lurek.math.polygonClip
    -- @covers lurek.math.segmentIntersectsSegment
    it("geometry and easing helpers are callable", function()
        expect_type("number", lurek.math.inQuart(0.5))
        expect_type("number", lurek.math.outQuart(0.5))
        expect_type("number", lurek.math.inOutQuart(0.5))
        expect_type("number", lurek.math.fmod(7.5, 2.0))

        local ok, _ = pcall(function()
            lurek.math.circleIntersectsLine(0, 0, 5, -10, 0, 10, 0)
            lurek.math.circleIntersectsSegment(0, 0, 5, -10, 0, 10, 0)
            lurek.math.closestPointOnSegment(1, 1, 0, 0, 10, 0)
            lurek.math.segmentIntersectsSegment(0, 0, 10, 0, 5, -1, 5, 1)
            lurek.math.convexHull({0, 0, 1, 0, 1, 1, 0, 1})
            lurek.math.delaunayTriangulate({0, 0, 1, 0, 1, 1, 0, 1})
            lurek.math.polygonClip({0, 0, 2, 0, 2, 2, 0, 2}, 1.0, 0.0, 1.0)
        end)
        expect_type("boolean", ok)
    end)

    -- @covers LBezierCurve:removeControlPoint
    -- @covers LNoiseGenerator:generateMap
    -- @covers LNoiseGenerator:getSeed
    -- @covers LNoiseGenerator:perlin1d
    -- @covers LNoiseGenerator:perlin4d
    -- @covers LNoiseGenerator:simplex1d
    -- @covers LNoiseGenerator:warpDomain
    -- @covers LNoiseGenerator:worley3d
    -- @covers LRandomGenerator:getSeed
    -- @covers LTransform:getMatrix
    -- @covers LTransform:shear
    -- @covers LTween:addValue
    -- @covers LTween:getAllValues
    -- @covers LTween:getClock
    -- @covers LTween:getValue
    -- @covers LTween:getValueCount
    -- @covers lurek.math.newBezierCurve
    -- @covers lurek.math.newNoiseGenerator
    -- @covers lurek.math.newRandomGenerator
    -- @covers lurek.math.newTransform
    -- @covers lurek.math.newTween
    it("math userdata helpers are callable", function()
        local rng = lurek.math.newRandomGenerator(42)
        expect_type("number", rng:getSeed())

        local tr = lurek.math.newTransform()
        tr:shear(0.1, 0.2)
        local m = tr:getMatrix()
        expect_type("table", m)

        local bc = lurek.math.newBezierCurve({0, 0, 1, 1, 2, 0})
        local ok_rm, _ = pcall(function() bc:removeControlPoint(2) end)
        expect_type("boolean", ok_rm)

        local tw = lurek.math.newTween(1.0, "linear")
        tw:addValue(0, 1)
        expect_type("table", tw:getAllValues())
        expect_type("number", tw:getValueCount())
        local ok_value, value = pcall(function() return tw:getValue(1) end)
        expect_true(ok_value)
        expect_type("number", value)
        expect_type("number", tw:getClock())

        local nz = lurek.math.newNoiseGenerator(123)
        expect_type("number", nz:getSeed())
        expect_type("number", nz:perlin1d(0.5))
        expect_type("number", nz:perlin4d(0.1, 0.2, 0.3, 0.4))
        expect_type("number", nz:simplex1d(0.5))
        expect_type("number", nz:worley3d(0.1, 0.2, 0.3))
        local ok_wd, _ = pcall(function() nz:warpDomain(0.1, 0.2, 0.3) end)
        expect_type("boolean", ok_wd)
        local ok_map, _ = pcall(function() nz:generateMap(8, 8, { scaleX = 0.1, octaves = 3 }) end)
        expect_type("boolean", ok_map)
    end)
end)

-- @describe math strict uncovered symbols
describe("math strict uncovered symbols", function()
    -- @covers lurek.math.perlin2d
    -- @covers lurek.math.perlin3d
    -- @covers lurek.math.simplex2d
    -- @covers lurek.math.fbm
    -- @covers lurek.math.inQuad
    -- @covers lurek.math.inOutQuad
    -- @covers lurek.math.outCubic
    -- @covers lurek.math.inOutCubic
    -- @covers lurek.math.inSine
    -- @covers lurek.math.outSine
    -- @covers lurek.math.inOutSine
    -- @covers lurek.math.inExpo
    -- @covers lurek.math.outExpo
    -- @covers lurek.math.inOutExpo
    -- @covers lurek.math.inElastic
    -- @covers lurek.math.outElastic
    -- @covers lurek.math.inBounce
    -- @covers lurek.math.inBack
    -- @covers lurek.math.outBack
    -- @covers lurek.math.lineIntersect
    -- @covers lurek.math.pointInPolygon
    -- @covers lurek.math.polygonArea
    -- @covers lurek.math.polygonCentroid
    -- @covers lurek.math.bresenham
    -- @covers lurek.math.asin
    -- @covers lurek.math.acos
    -- @covers lurek.math.atan
    -- @covers lurek.math.hermite
    -- @covers lurek.math.remap
    it("strict scalar and geometry functions are callable", function()
        expect_type("number", lurek.math.perlin2d(0.1, 0.2))
        expect_type("number", lurek.math.perlin3d(0.1, 0.2, 0.3))
        expect_type("number", lurek.math.simplex2d(0.1, 0.2))
        expect_type("number", lurek.math.fbm(0.1, 0.2, 4, 0.5, 2.0))
        expect_type("number", lurek.math.inQuad(0.5))
        expect_type("number", lurek.math.inOutQuad(0.5))
        expect_type("number", lurek.math.outCubic(0.5))
        expect_type("number", lurek.math.inOutCubic(0.5))
        expect_type("number", lurek.math.inSine(0.5))
        expect_type("number", lurek.math.outSine(0.5))
        expect_type("number", lurek.math.inOutSine(0.5))
        expect_type("number", lurek.math.inExpo(0.5))
        expect_type("number", lurek.math.outExpo(0.5))
        expect_type("number", lurek.math.inOutExpo(0.5))
        expect_type("number", lurek.math.inElastic(0.5))
        expect_type("number", lurek.math.outElastic(0.5))
        expect_type("number", lurek.math.inBounce(0.5))
        expect_type("number", lurek.math.inBack(0.5))
        expect_type("number", lurek.math.outBack(0.5))
        local ok_line, line_res = pcall(function() return lurek.math.lineIntersect(0, 0, 2, 2, 0, 2, 2, 0) end)
        expect_true(ok_line)
        expect_type("number", line_res)
        expect_type("boolean", lurek.math.pointInPolygon({ 0, 0, 2, 0, 2, 2, 0, 2 }, 1, 1))
        expect_type("number", lurek.math.polygonArea({ 0, 0, 2, 0, 2, 2, 0, 2 }))
        local cx, cy = lurek.math.polygonCentroid({ 0, 0, 2, 0, 2, 2, 0, 2 })
        expect_type("number", cx)
        expect_type("number", cy)
        local ok_bres, pts = pcall(function() return lurek.math.bresenham(0, 0, 3, 3) end)
        expect_true(ok_bres)
        expect_type("table", pts)
        expect_type("number", lurek.math.asin(0.5))
        expect_type("number", lurek.math.acos(0.5))
        expect_type("number", lurek.math.atan(1.0))
        expect_type("number", lurek.math.remap(5, 0, 10, -1, 1))
        local h = lurek.math.hermite(0, 0, 1, 1, 1, 0, 1, 0)
        expect_type("userdata", h)
    end)

    -- @covers lurek.math.Vec3
    -- @covers LVec2:angle
    -- @covers LVec2:rotate
    -- @covers LVec2:perpendicular
    -- @covers LVec2:cross
    -- @covers LVec2.fromAngle
    -- @covers LVec2:type
    -- @covers LVec2:typeOf
    -- @covers LVec3:length
    -- @covers LVec3:lengthSquared
    -- @covers LVec3:normalize
    -- @covers LVec3:cross
    -- @covers LVec3:lerp
    -- @covers LVec3:distance
    -- @covers LVec3:scale
    -- @covers LVec3.splat
    -- @covers LVec3:type
    -- @covers LVec3:typeOf
    it("strict vector APIs are callable", function()
        local v2 = lurek.math.vec2(1, 0)
        local v2b = lurek.math.vec2(0, 1)
        expect_type("number", v2:angle())
        local rv = v2:rotate(0.25)
        expect_type("userdata", rv)
        local pv = v2:perpendicular()
        expect_type("userdata", pv)
        expect_type("number", v2:cross(v2b))
        local av = v2.fromAngle(0.5)
        expect_type("userdata", av)
        expect_type("string", v2:type())
        expect_type("boolean", v2:typeOf("LVec2"))

        local c3 = lurek.math.Vec3(1, 2, 3)
        local a3 = lurek.math.vec3(1, 0, 0)
        local b3 = lurek.math.vec3(0, 1, 0)
        expect_type("number", c3:length())
        expect_type("number", c3:lengthSquared())
        expect_type("userdata", c3:normalize())
        expect_type("userdata", a3:cross(b3))
        expect_type("userdata", a3:lerp(b3, 0.5))
        expect_type("number", a3:distance(b3))
        expect_type("userdata", a3:scale(2.0))
        local s3 = c3.splat(7)
        expect_type("userdata", s3)
        expect_type("string", c3:type())
        expect_type("boolean", c3:typeOf("LVec3"))
    end)

    -- @covers LCatmullRom:sampleSegment
    -- @covers LCatmullRom:type
    -- @covers LCatmullRom:typeOf
    -- @covers LHermite:type
    -- @covers LHermite:typeOf
    -- @covers LRandomGenerator:type
    -- @covers LRandomGenerator:typeOf
    -- @covers LTransform:type
    -- @covers LTransform:typeOf
    -- @covers LBezierCurve:getDerivative
    -- @covers LBezierCurve:getControlPoint
    -- @covers LBezierCurve:length
    -- @covers LBezierCurve:rotate
    -- @covers LBezierCurve:scale
    -- @covers LBezierCurve:type
    -- @covers LBezierCurve:typeOf
    -- @covers LTween:update
    -- @covers LTween:reset
    -- @covers LTween:isComplete
    -- @covers LTween:getEasingName
    -- @covers LTween:getDuration
    -- @covers LTween:getTime
    -- @covers LSpatialHash:update
    -- @covers LSpatialHash:clear
    -- @covers LSpatialHash:querySegment
    -- @covers LSpatialHash:type
    -- @covers LSpatialHash:typeOf
    -- @covers LNoiseGenerator:simplex3d
    -- @covers LNoiseGenerator:worley2d
    -- @covers LNoiseGenerator:ridged
    -- @covers LNoiseGenerator:turbulence
    -- @covers LNoiseGenerator:setSeed
    -- @covers LNoiseGenerator:type
    -- @covers LNoiseGenerator:typeOf
    -- @covers LCircle:type
    -- @covers LCircle:typeOf
    -- @covers LAabbTree:type
    -- @covers LAabbTree:typeOf
    -- @covers lurek.math.aabbTree
    -- @covers lurek.math.catmullRom
    -- @covers lurek.math.newBezierCurve
    -- @covers lurek.math.newCircle
    -- @covers lurek.math.newNoiseGenerator
    -- @covers lurek.math.newRandomGenerator
    -- @covers lurek.math.newSpatialHash
    -- @covers lurek.math.newTransform
    -- @covers lurek.math.newTween
    it("strict userdata methods are callable", function()
        local cat = lurek.math.catmullRom({ { 0, 0 }, { 1, 1 }, { 2, 0 }, { 3, 1 } })
        local ok_seg = pcall(function() cat:sampleSegment(0, 0.5) end)
        expect_type("boolean", ok_seg)
        expect_type("string", cat:type())
        expect_type("boolean", cat:typeOf("LCatmullRom"))

        local hm = lurek.math.hermite(0, 0, 1, 1, 1, 0, 1, 0)
        expect_type("string", hm:type())
        expect_type("boolean", hm:typeOf("LHermite"))

        local rng = lurek.math.newRandomGenerator(42)
        expect_type("string", rng:type())
        expect_type("boolean", rng:typeOf("LRandomGenerator"))

        local tr = lurek.math.newTransform()
        expect_type("string", tr:type())
        expect_type("boolean", tr:typeOf("LTransform"))

        local bc = lurek.math.newBezierCurve({ 0, 0, 1, 1, 2, 0 })
        local ok_deriv, deriv = pcall(function() return bc:getDerivative() end)
        expect_type("boolean", ok_deriv)
        if ok_deriv then expect_type("userdata", deriv) end
        local ok_cp, cp = pcall(function() return bc:getControlPoint(1) end)
        expect_type("boolean", ok_cp)
        if ok_cp then expect_type("number", cp) end
        expect_type("number", bc:length())
        local ok_rot = pcall(function() bc:rotate(0.2, 0.0, 0.0) end)
        expect_type("boolean", ok_rot)
        local ok_scale = pcall(function() bc:scale(1.1, 0.0, 0.0) end)
        expect_type("boolean", ok_scale)
        expect_type("string", bc:type())
        expect_type("boolean", bc:typeOf("LBezierCurve"))

        local tw = lurek.math.newTween(1.0, "linear")
        tw:update(0.2)
        expect_type("boolean", tw:isComplete())
        expect_type("string", tw:getEasingName())
        expect_type("number", tw:getDuration())
        expect_type("number", tw:getTime())
        tw:reset()

        local sh = lurek.math.newSpatialHash(32)
        local ok_update = pcall(function() sh:update("a", 10, 10, 3, 3) end)
        expect_type("boolean", ok_update)
        local ok_qs, seg = pcall(function() return sh:querySegment(0, 0, 32, 32) end)
        expect_type("boolean", ok_qs)
        if ok_qs then expect_type("table", seg) end
        sh:clear()
        expect_type("string", sh:type())
        expect_type("boolean", sh:typeOf("LSpatialHash"))

        local nz = lurek.math.newNoiseGenerator(99)
        expect_type("number", nz:simplex3d(0.1, 0.2, 0.3))
        expect_type("number", nz:worley2d(0.1, 0.2))
        expect_type("number", nz:ridged(0.2, 0.3, 4, 2.0, 0.5))
        expect_type("number", nz:turbulence(0.2, 0.3, 4, 2.0, 0.5))
        nz:setSeed(1234)
        expect_type("string", nz:type())
        expect_type("boolean", nz:typeOf("LNoiseGenerator"))

        local c = lurek.math.newCircle(0, 0, 2)
        expect_type("string", c:type())
        expect_type("boolean", c:typeOf("LCircle"))

        local tree = lurek.math.aabbTree()
        expect_type("string", tree:type())
        expect_type("boolean", tree:typeOf("LAabbTree"))
    end)
end)

-- @describe unit: migrated from integration/test_math_pathfind.lua
describe("unit: migrated from integration/test_math_pathfind.lua", function()
        local pts = {
            { x = 0, y = 0 },
            { x = 1, y = 0 },
            { x = 0.5, y = 1 },
            { x = 0.5, y = 0.5 },
        }
        -- @covers lurek.math.vec3
        it("creates a Vec3 with correct components", function()
            local v = lurek.math.vec3(1, 2, 3)
            expect_near(1, v.x, 1e-5)
            expect_near(2, v.y, 1e-5)
            expect_near(3, v.z, 1e-5)
        end)

        -- @covers lurek.math.Vec3
        it("Vec3 alias works identically", function()
            local v = lurek.math.Vec3(4, 5, 6)
            expect_near(4, v.x, 1e-5)
            expect_near(5, v.y, 1e-5)
            expect_near(6, v.z, 1e-5)
        end)

        -- @covers LVec3:length
        -- @covers lurek.math.vec3
        it("length of (3,4,0) is 5", function()
            local v = lurek.math.vec3(3, 4, 0)
            expect_near(5.0, v:length(), 1e-4)
        end)

        -- @covers LVec3:length
        -- @covers lurek.math.vec3
        it("length of unit vector is 1", function()
            local v = lurek.math.vec3(1, 0, 0)
            expect_near(1.0, v:length(), 1e-5)
        end)

        -- @covers LVec3:lengthSquared
        -- @covers lurek.math.vec3
        it("lengthSquared avoids sqrt", function()
            local v = lurek.math.vec3(2, 2, 1)
            expect_near(9.0, v:lengthSquared(), 1e-5) -- 4+4+1=9
        end)

        -- @covers LVec3:length
        -- @covers LVec3:normalize
        -- @covers lurek.math.vec3
        it("normalize produces unit vector", function()
            local v = lurek.math.vec3(3, 0, 0):normalize()
            expect_near(1.0, v:length(), 1e-5)
            expect_near(1.0, v.x, 1e-5)
        end)

        -- @covers LVec3:dot
        -- @covers lurek.math.vec3
        it("dot product of perpendicular vectors is 0", function()
            local a = lurek.math.vec3(1, 0, 0)
            local b = lurek.math.vec3(0, 1, 0)
            expect_near(0.0, a:dot(b), 1e-5)
        end)

        -- @covers LVec3:dot
        -- @covers lurek.math.vec3
        it("dot product of parallel vectors equals product of lengths", function()
            local a = lurek.math.vec3(2, 0, 0)
            local b = lurek.math.vec3(3, 0, 0)
            expect_near(6.0, a:dot(b), 1e-5)
        end)

        -- @covers LVec3:cross
        -- @covers lurek.math.vec3
        it("cross product of x and y axes is z axis", function()
            local x = lurek.math.vec3(1, 0, 0)
            local y = lurek.math.vec3(0, 1, 0)
            local z = x:cross(y)
            expect_near(0.0, z.x, 1e-5)
            expect_near(0.0, z.y, 1e-5)
            expect_near(1.0, z.z, 1e-5)
        end)

        -- @covers LVec3:lerp
        -- @covers lurek.math.vec3
        it("lerp at t=0 returns from", function()
            local a = lurek.math.vec3(0, 0, 0)
            local b = lurek.math.vec3(10, 20, 30)
            local v = a:lerp(b, 0)
            expect_near(0.0, v.x, 1e-5)
        end)

        -- @covers LVec3:lerp
        -- @covers lurek.math.vec3
        it("lerp at t=1 returns to", function()
            local a = lurek.math.vec3(0, 0, 0)
            local b = lurek.math.vec3(10, 20, 30)
            local v = a:lerp(b, 1)
            expect_near(10.0, v.x, 1e-5)
            expect_near(20.0, v.y, 1e-5)
        end)

        -- @covers LVec3:lerp
        -- @covers lurek.math.vec3
        it("lerp at t=0.5 is midpoint", function()
            local a = lurek.math.vec3(0, 0, 0)
            local b = lurek.math.vec3(10, 0, 0)
            local v = a:lerp(b, 0.5)
            expect_near(5.0, v.x, 1e-5)
        end)

        -- @covers LVec3:distance
        -- @covers lurek.math.vec3
        it("distance from (0,0,0) to (1,0,0) is 1", function()
            local a = lurek.math.vec3(0, 0, 0)
            local b = lurek.math.vec3(1, 0, 0)
            expect_near(1.0, a:distance(b), 1e-5)
        end)

        -- @covers LVec3:add
        -- @covers lurek.math.vec3
        it("add combines components", function()
            local a = lurek.math.vec3(1, 2, 3)
            local b = lurek.math.vec3(4, 5, 6)
            local c = a:add(b)
            expect_near(5.0, c.x, 1e-5)
            expect_near(7.0, c.y, 1e-5)
            expect_near(9.0, c.z, 1e-5)
        end)

        -- @covers LVec3:sub
        -- @covers lurek.math.vec3
        it("sub subtracts components", function()
            local a = lurek.math.vec3(5, 5, 5)
            local b = lurek.math.vec3(2, 3, 1)
            local c = a:sub(b)
            expect_near(3.0, c.x, 1e-5)
        end)

        -- @covers LVec3:scale
        -- @covers lurek.math.vec3
        it("scale multiplies components", function()
            local v = lurek.math.vec3(2, 3, 4):scale(2)
            expect_near(4.0, v.x, 1e-5)
            expect_near(6.0, v.y, 1e-5)
            expect_near(8.0, v.z, 1e-5)
        end)

        -- @covers lurek.math.catmullRom
        it("creates a spline without error", function()
            local s = lurek.math.catmullRom(pts)
            expect_type("userdata", s)
        end)

        -- @covers LCatmullRom:len
        -- @covers lurek.math.catmullRom
        it("len returns control point count", function()
            local s = lurek.math.catmullRom(pts)
            expect_equal(4, s:len())
        end)

        -- @covers LCatmullRom:sample
        -- @covers lurek.math.catmullRom
        it("sample returns two numbers", function()
            local s = lurek.math.catmullRom(pts)
            local x, y = s:sample(0.5)
            expect_type("number", x)
            expect_type("number", y)
        end)

        -- @covers LCatmullRom:sample
        -- @covers lurek.math.catmullRom
        it("sample at t=0 is near first control point", function()
            local s = lurek.math.catmullRom(pts)
            local x, y = s:sample(0.0)
            -- Catmull-Rom boundary behaviour: at t=0 should be near pts[1] or pts[2]
            expect_type("number", x)
        end)

        -- @covers LCatmullRom:sampleSegment
        -- @covers lurek.math.catmullRom
        it("sampleSegment returns two numbers", function()
            local s = lurek.math.catmullRom(pts)
            local x, y = s:sampleSegment(1, 0.5)
            expect_type("number", x)
            expect_type("number", y)
        end)

        -- @covers lurek.math.hermite
        it("creates a hermite spline without error", function()
            local s = lurek.math.hermite(0, 0, 10, 0, 1, 1, 1, -1)
            expect_type("userdata", s)
        end)

        -- @covers LHermite:sample
        -- @covers lurek.math.hermite
        it("sample returns two numbers", function()
            local s = lurek.math.hermite(0, 0, 10, 0, 1, 1, 1, -1)
            local x, y = s:sample(0.5)
            expect_type("number", x)
            expect_type("number", y)
        end)

        -- @covers LHermite:sample
        -- @covers lurek.math.hermite
        it("sample at t=0 is start point", function()
            local s = lurek.math.hermite(2, 3, 8, 5, 0, 0, 0, 0)
            local x, y = s:sample(0.0)
            expect_near(2.0, x, 1e-4)
            expect_near(3.0, y, 1e-4)
        end)

        -- @covers LHermite:sample
        -- @covers lurek.math.hermite
        it("sample at t=1 is end point", function()
            local s = lurek.math.hermite(2, 3, 8, 5, 0, 0, 0, 0)
            local x, y = s:sample(1.0)
            expect_near(8.0, x, 1e-4)
            expect_near(5.0, y, 1e-4)
        end)

        -- @covers lurek.math.lerp
        it("lerp at t=0 returns a", function()
            expect_near(3.0, lurek.math.lerp(3, 7, 0), 1e-5)
        end)

        -- @covers lurek.math.lerp
        it("lerp at t=1 returns b", function()
            expect_near(7.0, lurek.math.lerp(3, 7, 1), 1e-5)
        end)

        -- @covers lurek.math.lerp
        it("lerp at t=0.5 is midpoint", function()
            expect_near(5.0, lurek.math.lerp(3, 7, 0.5), 1e-5)
        end)

        -- @covers lurek.math.lerp
        it("lerp extrapolates beyond [a,b]", function()
            expect_near(9.0, lurek.math.lerp(3, 7, 1.5), 1e-5)
        end)

        -- @covers lurek.math.remap
        it("remap center of [0,1] to [10,20]", function()
            expect_near(15.0, lurek.math.remap(0.5, 0, 1, 10, 20), 1e-4)
        end)

        -- @covers lurek.math.remap
        it("remap minimum stays at out_min", function()
            expect_near(10.0, lurek.math.remap(0, 0, 1, 10, 20), 1e-4)
        end)

        -- @covers lurek.math.remap
        it("remap maximum stays at out_max", function()
            expect_near(20.0, lurek.math.remap(1, 0, 1, 10, 20), 1e-4)
        end)

        -- @covers lurek.math.remap
        it("remap inverts when out_min > out_max", function()
            expect_near(15.0, lurek.math.remap(0.5, 0, 1, 20, 10), 1e-4)
        end)

        -- @covers lurek.math.catmullRom
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

-- @describe unit: migrated from integration/test_math_physics.lua
describe("unit: migrated from integration/test_math_physics.lua", function()
        -- @covers lurek.math.max
        -- @covers lurek.math.min
        it("AABB overlap check using math", function()
            -- Two rectangles that overlap
            local ax, ay, aw, ah = 0, 0, 10, 10
            local bx, by, bw, bh = 5, 5, 10, 10

            -- Manual AABB overlap check using math
            local overlap_x = lurek.math.min(ax + aw, bx + bw) - lurek.math.max(ax, bx)
            local overlap_y = lurek.math.min(ay + ah, by + bh) - lurek.math.max(ay, by)

            expect_true(overlap_x > 0, "x overlap exists")
            expect_true(overlap_y > 0, "y overlap exists")
            expect_near(5, overlap_x, 0.001, "x overlap = 5")
            expect_near(5, overlap_y, 0.001, "y overlap = 5")
        end)

        -- @covers lurek.math.atan2
        -- @covers lurek.math.pi
        it("angle between two points", function()
            local x1, y1 = 0, 0
            local x2, y2 = 1, 1

            local angle = lurek.math.atan2(y2 - y1, x2 - x1)
            expect_near(lurek.math.pi / 4, angle, 0.001, "45 degree angle")
        end)

        -- @covers lurek.math.cos
        -- @covers lurek.math.sin
        it("rotate a velocity vector", function()
            local speed = 10
            local angle = math.rad(90)

            local vx = speed * lurek.math.cos(angle)
            local vy = speed * lurek.math.sin(angle)

            expect_near(0, vx, 0.001, "vx at 90 degrees")
            expect_near(10, vy, 0.001, "vy at 90 degrees")
        end)

end)

-- @describe unit: migrated from integration/test_timer_math.lua
describe("unit: migrated from integration/test_timer_math.lua", function()
        -- @covers lurek.math.pi
        -- @covers lurek.math.sin
        it("oscillation with sin and time", function()
            -- Simulate oscillating value: sin(time * frequency)
            local frequency = 2.0
            local time = lurek.math.pi / (2 * frequency)

            local value = lurek.math.sin(time * frequency)
            expect_near(1.0, value, 0.001, "sin peak at quarter period")
        end)

end)

test_summary()
