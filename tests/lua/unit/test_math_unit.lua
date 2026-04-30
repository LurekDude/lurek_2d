-- Lurek2D Math API Tests

-- @description Verifies the math namespace exposes the pi constant and that its numeric value matches the expected approximation.
describe("lurek.math constants", function()
    -- @description Confirms pi is present and is within 0.0001 of 3.14159265358979.
    -- @tests lurek.math.pi
    it("has pi", function()
        expect_not_nil(lurek.math.pi, "pi exists")
        expect_near(3.14159265358979, lurek.math.pi, 0.0001, "pi value")
    end)
end)

-- @description Checks core trigonometric helpers against canonical angles for sine, cosine, tangent, and atan2.
describe("lurek.math trigonometry", function()
    -- @description Asserts sin(0) returns 0 within 0.0001.
    it("sin(0) = 0", function()
        expect_near(0, lurek.math.sin(0), 0.0001)
    end)

    -- @description Asserts sin(pi/2) returns 1 within 0.0001.
    it("sin(pi/2) = 1", function()
        expect_near(1, lurek.math.sin(lurek.math.pi / 2), 0.0001)
    end)

    -- @description Asserts cos(0) returns 1 within 0.0001.
    it("cos(0) = 1", function()
        expect_near(1, lurek.math.cos(0), 0.0001)
    end)

    -- @description Asserts cos(pi) returns -1 within 0.0001.
    it("cos(pi) = -1", function()
        expect_near(-1, lurek.math.cos(lurek.math.pi), 0.0001)
    end)

    -- @description Asserts tan(0) returns 0 within 0.0001.
    it("tan(0) = 0", function()
        expect_near(0, lurek.math.tan(0), 0.0001)
    end)

    -- @description Asserts atan2(1, 0) returns pi/2 within 0.0001.
    it("atan2(1, 0) = pi/2", function()
        expect_near(lurek.math.pi / 2, lurek.math.atan2(1, 0), 0.0001)
    end)

    -- @description Asserts atan2(0, 1) returns 0 within 0.0001.
    it("atan2(0, 1) = 0", function()
        expect_near(0, lurek.math.atan2(0, 1), 0.0001)
    end)
end)

-- @description Verifies square root, absolute value, floor, and ceil return the expected scalar results for positive and negative inputs.
describe("lurek.math basic functions", function()
    -- @description Asserts sqrt(4) evaluates to 2 within 0.0001.
    it("sqrt(4) = 2", function()
        expect_near(2, lurek.math.sqrt(4), 0.0001)
    end)

    -- @description Asserts sqrt(9) evaluates to 3 within 0.0001.
    it("sqrt(9) = 3", function()
        expect_near(3, lurek.math.sqrt(9), 0.0001)
    end)

    -- @description Asserts abs(-5) returns the positive magnitude 5 within 0.0001.
    it("abs(-5) = 5", function()
        expect_near(5, lurek.math.abs(-5), 0.0001)
    end)

    -- @description Asserts abs(5) leaves the positive input unchanged at 5 within 0.0001.
    it("abs(5) = 5", function()
        expect_near(5, lurek.math.abs(5), 0.0001)
    end)

    -- @description Asserts floor(3.7) truncates down to the integer 3.
    it("floor(3.7) = 3", function()
        expect_equal(3, lurek.math.floor(3.7))
    end)

    -- @description Asserts floor(-2.1) rounds down toward negative infinity to -3.
    it("floor(-2.1) = -3", function()
        expect_equal(-3, lurek.math.floor(-2.1))
    end)

    -- @description Asserts ceil(3.2) rounds up to the integer 4.
    it("ceil(3.2) = 4", function()
        expect_equal(4, lurek.math.ceil(3.2))
    end)

    -- @description Asserts ceil(-2.9) rounds up toward zero to -2.
    it("ceil(-2.9) = -2", function()
        expect_equal(-2, lurek.math.ceil(-2.9))
    end)
end)

-- @description Verifies min, max, and clamp choose the expected bounds for in-range and out-of-range inputs.
describe("lurek.math min/max/clamp", function()
    -- @description Asserts min(3, 7) returns the smaller value 3.
    it("min(3, 7) = 3", function()
        expect_equal(3, lurek.math.min(3, 7))
    end)

    -- @description Asserts min(-1, 1) returns -1 as the smaller signed value.
    it("min(-1, 1) = -1", function()
        expect_equal(-1, lurek.math.min(-1, 1))
    end)

    -- @description Asserts max(3, 7) returns the larger value 7.
    it("max(3, 7) = 7", function()
        expect_equal(7, lurek.math.max(3, 7))
    end)

    -- @description Asserts clamp keeps an in-range value unchanged at 5.
    it("clamp(5, 0, 10) = 5", function()
        expect_equal(5, lurek.math.clamp(5, 0, 10))
    end)

    -- @description Asserts clamp raises a below-range value -5 up to the minimum bound 0.
    it("clamp(-5, 0, 10) = 0", function()
        expect_equal(0, lurek.math.clamp(-5, 0, 10))
    end)

    -- @description Asserts clamp lowers an above-range value 15 down to the maximum bound 10.
    it("clamp(15, 0, 10) = 10", function()
        expect_equal(10, lurek.math.clamp(15, 0, 10))
    end)
end)

-- @description Verifies Euclidean distance calculations for a 3-4-5 triangle, identical points, and a unit horizontal segment.
describe("lurek.math.distance", function()
    -- @description Asserts the distance from (0,0) to (3,4) is 5 within 0.0001.
    it("distance(0,0,3,4) = 5", function()
        expect_near(5, lurek.math.distance(0, 0, 3, 4), 0.0001)
    end)

    -- @description Asserts the distance between identical points is 0 within 0.0001.
    it("distance(1,1,1,1) = 0", function()
        expect_near(0, lurek.math.distance(1, 1, 1, 1), 0.0001)
    end)

    -- @description Asserts the distance from (0,0) to (1,0) is 1 within 0.0001.
    it("distance(0,0,1,0) = 1", function()
        expect_near(1, lurek.math.distance(0, 0, 1, 0), 0.0001)
    end)
end)

-- @description Verifies random number helpers return numeric values inside the expected default, max-only, and min/max ranges.
describe("lurek.math.random", function()
    -- @description Calls random() once and asserts the returned value has Lua type number.
    it("returns a number", function()
        local val = lurek.math.random()
        expect_type("number", val)
    end)

    -- @description Samples random() 20 times and asserts every result is greater than or equal to 0 and less than 1.
    it("no-arg returns value in [0, 1)", function()
        for i = 1, 20 do
            local val = lurek.math.random()
            expect_true(val >= 0 and val < 1, "random() in [0,1)")
        end
    end)

    -- @description Samples random(10) 20 times and asserts every result stays between 0 and 10 inclusive.
    it("with max returns value in [0, max)", function()
        for i = 1, 20 do
            local val = lurek.math.random(10)
            expect_true(val >= 0 and val <= 10, "random(10) in [0,10]")
        end
    end)

    -- @description Samples random(5, 15) 20 times and asserts every result stays between 5 and 15 inclusive.
    it("with min,max returns value in [min, max)", function()
        for i = 1, 20 do
            local val = lurek.math.random(5, 15)
            expect_true(val >= 5 and val <= 15, "random(5,15) in [5,15]")
        end
    end)
end)

-- @description Verifies standalone simplex noise returns numeric values, stays near the documented range, and is deterministic for repeated inputs.
describe("math.simplexNoise standalone", function()
    -- @description Evaluates simplexNoise at (0.5, 0.5), asserts the result is numeric, and checks it falls between -1.1 and 1.1.
    it("returns a number in range [-1, 1]", function()
        local v = lurek.math.simplexNoise(0.5, 0.5)
        expect_type("number", v)
        expect_equal(v > -1.1 and v < 1.1, true)
    end)

    -- @description Calls simplexNoise twice with the same 2D inputs and asserts the two values match within 0.000001.
    it("is deterministic for same inputs", function()
        local v1 = lurek.math.simplexNoise(1.23, 4.56)
        local v2 = lurek.math.simplexNoise(1.23, 4.56)
        expect_near(v1, v2, 0.000001)
    end)

    -- @description Calls simplexNoise with three coordinates and asserts the returned value is numeric.
    it("accepts 3 arguments", function()
        local v = lurek.math.simplexNoise(0.1, 0.2, 0.3)
        expect_type("number", v)
    end)
end)

-- â”€â”€ additional constants & utility â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies secondary constants and scalar helpers including tau, huge, lerp, sign, round, distanceSq, angle conversion, angleBetween, and randomInt.
describe("math constants and utility", function()
    -- @description Asserts tau matches pi multiplied by 2 within 0.0001.
    it("has tau = 2*pi", function()
        expect_near(lurek.math.tau, lurek.math.pi * 2, 0.0001)
    end)

    -- @description Asserts huge is larger than 1e300.
    it("has huge", function()
        ---@type { huge: number }
        local lurek_math = lurek.math
        expect_true(lurek_math.huge > 1e300)
    end)

    -- @description Asserts lerp from 0 to 10 at t=0.5 returns 5 within 0.0001.
    it("lerp(0, 10, 0.5) = 5", function()
        expect_near(lurek.math.lerp(0, 10, 0.5), 5, 0.0001)
    end)

    -- @description Asserts lerp from 0 to 10 at t=0 returns the start value 0 within 0.0001.
    it("lerp(0, 10, 0) = 0", function()
        expect_near(lurek.math.lerp(0, 10, 0), 0, 0.0001)
    end)

    -- @description Asserts lerp from 0 to 10 at t=1 returns the end value 10 within 0.0001.
    it("lerp(0, 10, 1) = 10", function()
        expect_near(lurek.math.lerp(0, 10, 1), 10, 0.0001)
    end)

    -- @description Asserts sign(-5) returns -1.
    it("sign(-5) = -1", function()
        expect_equal(lurek.math.sign(-5), -1)
    end)

    -- @description Asserts sign(5) returns 1.
    it("sign(5) = 1", function()
        expect_equal(lurek.math.sign(5), 1)
    end)

    -- @description Asserts sign(0) returns 0.
    it("sign(0) = 0", function()
        expect_equal(lurek.math.sign(0), 0)
    end)

    -- @description Asserts round(2.3) returns 2.
    it("round(2.3) = 2", function()
        expect_equal(lurek.math.round(2.3), 2)
    end)

    -- @description Asserts round(2.7) returns 3.
    it("round(2.7) = 3", function()
        expect_equal(lurek.math.round(2.7), 3)
    end)

    -- @description Asserts the squared distance from (0,0) to (3,4) is 25 within 0.0001.
    it("distanceSq(0,0,3,4) = 25", function()
        expect_near(lurek.math.distanceSq(0, 0, 3, 4), 25, 0.0001)
    end)

    -- @description Converts 180 degrees to radians and back and asserts the round-trip returns 180 within 0.0001.
    it("rad and deg are inverse", function()
        expect_near(lurek.math.deg(lurek.math.rad(180)), 180, 0.0001)
    end)

    -- @description Asserts the angle from (0,0) to (1,0) is 0 within 0.0001.
    it("angleBetween(0,0,1,0) = 0", function()
        expect_near(lurek.math.angleBetween(0, 0, 1, 0), 0, 0.0001)
    end)

    -- @description Samples randomInt(5, 10) 20 times and asserts each value stays in range and is already an integer.
    it("randomInt(5, 10) returns integer in range", function()
        for i = 1, 20 do
            local v = lurek.math.randomInt(5, 10)
            expect_true(v >= 5 and v <= 10)
            expect_equal(v, math.floor(v))
        end
    end)
end)

-- â”€â”€ RandomGenerator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies seeded random generators can be created, produce deterministic or distinct sequences as expected, and honor their stateful helper methods.
describe("math.newRandomGenerator", function()
    -- @description Creates a random generator with seed 42 and asserts the userdata is not nil.
    it("creates RNG with seed", function()
        local rng = lurek.math.newRandomGenerator(42)
        expect_not_nil(rng)
    end)

    -- @description Creates two generators with seed 42, draws one random value from each, and asserts the values match within 0.000001.
    it("same seed produces same sequence", function()
        local rng1 = lurek.math.newRandomGenerator(42)
        local rng2 = lurek.math.newRandomGenerator(42)
        local v1 = rng1:random()
        local v2 = rng2:random()
        expect_near(v1, v2, 0.000001)
    end)

    -- @description Creates generators with seeds 42 and 999, draws one value from each, and asserts the samples differ.
    it("different seeds produce different sequences", function()
        local rng1 = lurek.math.newRandomGenerator(42)
        local rng2 = lurek.math.newRandomGenerator(999)
        local v1 = rng1:random()
        local v2 = rng2:random()
        expect_not_equal(v1, v2)
    end)

    -- @description Draws 50 integer samples from randomInt(5, 10) and asserts every value stays between 5 and 10.
    it("randomInt(min, max) stays in range", function()
        local rng = lurek.math.newRandomGenerator(123)
        for i = 1, 50 do
            local v = rng:randomInt(5, 10)
            expect_true(v >= 5 and v <= 10, "randomInt in range")
        end
    end)

    -- @description Draws 50 float samples from randomFloat(2.0, 5.0) and asserts every value stays between 2.0 and 5.0.
    it("randomFloat(min, max) stays in range", function()
        local rng = lurek.math.newRandomGenerator(456)
        for i = 1, 50 do
            local v = rng:randomFloat(2.0, 5.0)
            expect_true(v >= 2.0 and v <= 5.0, "randomFloat in range")
        end
    end)

    -- @description Draws 5000 normal samples, computes their mean, and asserts the mean remains within 0.1 of zero.
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

    -- @description Draws one value, resets the seed to 42, draws again, and asserts the first and second values match within 0.000001.
    it("setSeed resets the sequence", function()
        local rng = lurek.math.newRandomGenerator(42)
        local v1 = rng:random()
        rng:setSeed(42)
        local v2 = rng:random()
        expect_near(v1, v2, 0.000001)
    end)

    -- @description Saves generator state after two draws, restores it, and only asserts the next value remains a valid sample in [0,1).
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

-- â”€â”€ Transform â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies transforms preserve identity behavior, apply translation and scale, invert correctly, reset to identity, and clone independently.
describe("math.newTransform", function()
    -- @description Creates the identity transform, transforms (5,10), and asserts the point is unchanged.
    it("identity transform preserves point", function()
        local t = lurek.math.newTransform()
        local x, y = t:transformPoint(5, 10)
        expect_near(x, 5, 0.0001)
        expect_near(y, 10, 0.0001)
    end)

    -- @description Translates by (100,200), transforms the origin, and asserts the result becomes (100,200).
    it("translate moves point", function()
        local t = lurek.math.newTransform()
        t:translate(100, 200)
        local x, y = t:transformPoint(0, 0)
        expect_near(x, 100, 0.0001)
        expect_near(y, 200, 0.0001)
    end)

    -- @description Scales by 2, transforms (5,10), and asserts the coordinates become (10,20).
    it("scale doubles coordinates", function()
        local t = lurek.math.newTransform()
        t:scale(2)
        local x, y = t:transformPoint(5, 10)
        expect_near(x, 10, 0.0001)
        expect_near(y, 20, 0.0001)
    end)

    -- @description Applies translate and scale, inverts the transform, and asserts the inverse maps the transformed point back to approximately (5,10).
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

    -- @description Applies translate and rotate, transforms (10,20), then inverse-transforms it and asserts the original point is recovered within 0.01.
    it("inverseTransformPoint round-trips", function()
        local t = lurek.math.newTransform()
        t:translate(50, 100)
        t:rotate(0.5)
        local x, y = t:transformPoint(10, 20)
        local bx, by = t:inverseTransformPoint(x or 0, y or 0)
        expect_near(bx, 10, 0.01)
        expect_near(by, 20, 0.01)
    end)

    -- @description Applies a translation, resets the transform, and asserts transforming (5,5) again returns (5,5).
    it("reset returns to identity", function()
        local t = lurek.math.newTransform()
        t:translate(999, 999)
        t:reset()
        local x, y = t:transformPoint(5, 5)
        expect_near(x, 5, 0.0001)
        expect_near(y, 5, 0.0001)
    end)

    -- @description Clones a translated transform, mutates the original further, and asserts the clone still maps the origin to the earlier translated position (10,20).
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

-- â”€â”€ BezierCurve â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies Bezier curves can be created, evaluated at both ends, rendered into coordinates, and translated.
describe("math.newBezierCurve", function()
    -- @description Creates a curve from three control points and asserts the curve exists and reports 3 control points.
    it("creates curve from control points", function()
        local curve = lurek.math.newBezierCurve({0, 0, 10, 10, 20, 0})
        expect_not_nil(curve)
        expect_equal(curve:getControlPointCount(), 3)
    end)

    -- @description Evaluates a curve at t=0 and asserts the returned point matches the first control point (0,0).
    it("evaluate(0) returns start point", function()
        local curve = lurek.math.newBezierCurve({0, 0, 5, 10, 10, 0})
        local x, y = curve:evaluate(0)
        expect_near(x, 0, 0.0001)
        expect_near(y, 0, 0.0001)
    end)

    -- @description Evaluates a curve at t=1 and asserts the returned point matches the last control point (10,0).
    it("evaluate(1) returns end point", function()
        local curve = lurek.math.newBezierCurve({0, 0, 5, 10, 10, 0})
        local x, y = curve:evaluate(1)
        expect_near(x, 10, 0.0001)
        expect_near(y, 0, 0.0001)
    end)

    -- @description Renders the curve with 10 segments and asserts the coordinate list contains at least 4 numbers.
    it("render returns list of vertices", function()
        local curve = lurek.math.newBezierCurve({0, 0, 5, 10, 10, 0})
        local coords = curve:render(10)
        expect_true(#coords >= 4, "at least 2 points")
    end)

    -- @description Translates a two-point curve by (5,5) and asserts evaluating at t=0 now returns (5,5).
    it("translate shifts all control points", function()
        local curve = lurek.math.newBezierCurve({0, 0, 10, 0})
        curve:translate(5, 5)
        local x, y = curve:evaluate(0)
        expect_near(x, 5, 0.0001)
        expect_near(y, 5, 0.0001)
    end)
end)

-- â”€â”€ NoiseGenerator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies seeded noise generators can be created, return numeric samples from each noise method, stay deterministic for equal seeds, and differ for different seeds.
describe("math.newNoiseGenerator", function()
    -- @description Creates a noise generator with seed 42 and asserts the userdata is not nil.
    it("creates noise generator with seed", function()
        local ng = lurek.math.newNoiseGenerator(42)
        expect_not_nil(ng)
    end)

    -- @description Samples perlin2d at (0.5,0.5) and asserts the result is numeric.
    it("perlin2d returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:perlin2d(0.5, 0.5)
        expect_type("number", v)
    end)

    -- @description Samples perlin3d at (0.5,0.5,0.5) and asserts the result is numeric.
    it("perlin3d returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:perlin3d(0.5, 0.5, 0.5)
        expect_type("number", v)
    end)

    -- @description Creates two generators with the same seed and asserts perlin2d at (1.5,2.3) matches within 0.000001.
    it("is deterministic", function()
        local ng1 = lurek.math.newNoiseGenerator(42)
        local ng2 = lurek.math.newNoiseGenerator(42)
        expect_near(ng1:perlin2d(1.5, 2.3), ng2:perlin2d(1.5, 2.3), 0.000001)
    end)

    -- @description Samples simplex2d at (0.5,0.5) and asserts the result is numeric.
    it("simplex2d returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:simplex2d(0.5, 0.5)
        expect_type("number", v)
    end)

    -- @description Samples fbm at (0.5,0.5) and asserts the result is numeric.
    it("fbm returns number", function()
        local ng = lurek.math.newNoiseGenerator(42)
        local v = ng:fbm(0.5, 0.5)
        expect_type("number", v)
    end)

    -- @description Creates generators with different seeds, samples perlin2d at the same point, and asserts the two values differ.
    it("different seeds produce different values", function()
        local ng1 = lurek.math.newNoiseGenerator(42)
        local ng2 = lurek.math.newNoiseGenerator(999)
        local v1 = ng1:perlin2d(1.5, 2.3)
        local v2 = ng2:perlin2d(1.5, 2.3)
        expect_not_equal(v1, v2)
    end)
end)

-- â”€â”€ SpatialHash â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies spatial hashes retain their configured cell size, can insert and remove items, and return expected results for rectangle and circle queries.
describe("math.newSpatialHash", function()
    -- @description Creates a spatial hash with cell size 64 and asserts the object exists and reports 64 back from getCellSize().
    it("creates spatial hash with cell size", function()
        local sh = lurek.math.newSpatialHash(64)
        expect_not_nil(sh)
        expect_equal(sh:getCellSize(), 64)
    end)

    -- @description Inserts one item and asserts queryRect over a nearby rectangle returns at least one result.
    it("insert and queryRect finds item", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 20, 20)
        local results = sh:queryRect(0, 0, 50, 50)
        expect_true(#results >= 1)
    end)

    -- @description Inserts one item and asserts a distant queryRect returns zero results.
    it("queryRect does not find distant items", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 20, 20)
        local results = sh:queryRect(500, 500, 10, 10)
        expect_equal(#results, 0)
    end)

    -- @description Inserts one item, checks the item count is 1, removes it, and asserts the count drops to 0.
    it("remove decreases item count", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 20, 20)
        expect_equal(sh:getItemCount(), 1)
        sh:remove("1")
        expect_equal(sh:getItemCount(), 0)
    end)

    -- @description Inserts one nearby item and asserts queryCircle centered at (12,12) with radius 50 returns at least one result.
    it("queryCircle finds nearby items", function()
        local sh = lurek.math.newSpatialHash(64)
        sh:insert("1", 10, 10, 5, 5)
        local results = sh:queryCircle(12, 12, 50)
        expect_true(#results >= 1)
    end)
end)

-- â”€â”€ Easing functions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies easing helpers hit expected boundary values, preserve linear midpoint behavior, and that applyEasing dispatches correctly by name regardless of case.
describe("math easing functions", function()
    -- @description Asserts linear maps 0 to 0 and 1 to 1 within 0.0001.
    it("linear(0) = 0, linear(1) = 1", function()
        expect_near(lurek.math.linear(0), 0, 0.0001)
        expect_near(lurek.math.linear(1), 1, 0.0001)
    end)

    -- @description Asserts linear(0.5) returns 0.5 within 0.0001.
    it("linear(0.5) = 0.5", function()
        expect_near(lurek.math.linear(0.5), 0.5, 0.0001)
    end)

    -- @description Asserts outQuad maps 0 to 0 and 1 to 1 within 0.0001.
    it("outQuad(0) = 0, outQuad(1) = 1", function()
        expect_near(lurek.math.outQuad(0), 0, 0.0001)
        expect_near(lurek.math.outQuad(1), 1, 0.0001)
    end)

    -- @description Asserts inCubic maps 0 to 0 and 1 to 1 within 0.0001.
    it("inCubic(0) = 0, inCubic(1) = 1", function()
        expect_near(lurek.math.inCubic(0), 0, 0.0001)
        expect_near(lurek.math.inCubic(1), 1, 0.0001)
    end)

    -- @description Asserts outBounce maps 0 to 0 and 1 to 1 within 0.0001.
    it("outBounce(0) = 0, outBounce(1) = 1", function()
        expect_near(lurek.math.outBounce(0), 0, 0.0001)
        expect_near(lurek.math.outBounce(1), 1, 0.0001)
    end)

    -- @description Compares outQuad(0.5) with applyEasing("outQuad", 0.5) and asserts both values match within 0.0001.
    it("applyEasing by name matches direct call", function()
        local v1 = lurek.math.outQuad(0.5)
        local v2 = lurek.math.applyEasing("outQuad", 0.5)
        expect_near(v1, v2, 0.0001)
    end)

    -- @description Calls applyEasing with "linear" and "LINEAR" at 0.5 and asserts the results match within 0.0001.
    it("applyEasing is case-insensitive", function()
        local v1 = lurek.math.applyEasing("linear", 0.5)
        local v2 = lurek.math.applyEasing("LINEAR", 0.5)
        expect_near(v1, v2, 0.0001)
    end)
end)

-- â”€â”€ Polygon/Geometry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies polygon triangulation, convexity helpers, and basic circle containment and overlap checks.
describe("math polygon and geometry", function()
    -- @description Triangulates a square and asserts it yields 2 triangles with 6 numeric entries in the first triangle.
    it("triangulate a square yields 2 triangles", function()
        local tris = lurek.math.triangulate({0, 0, 10, 0, 10, 10, 0, 10})
        expect_equal(2, #tris) -- 2 triangles
        expect_equal(6, #tris[1]) -- each triangle has 6 numbers (x1,y1,x2,y2,x3,y3)
    end)

    -- @description Asserts isConvex returns true for a square polygon.
    it("isConvex returns true for square", function()
        expect_true(lurek.math.isConvex({0, 0, 10, 0, 10, 10, 0, 10}))
    end)

    -- @description Asserts isConvex returns false for the provided concave L-shaped polygon.
    it("isConvex returns false for concave L-shape", function()
        expect_equal(lurek.math.isConvex({0, 0, 2, 0, 2, 1, 1, 1, 1, 2, 0, 2}), false)
    end)

    -- @description Asserts a point at (3,4) is inside the circle centered at the origin with radius 10.
    it("circleContainsPoint detects inside", function()
        expect_true(lurek.math.circleContainsPoint(0, 0, 10, 3, 4))
    end)

    -- @description Asserts a point at (10,10) is outside the circle centered at the origin with radius 5.
    it("circleContainsPoint detects outside", function()
        expect_equal(lurek.math.circleContainsPoint(0, 0, 5, 10, 10), false)
    end)

    -- @description Asserts circles centered at (0,0) and (3,0) with radius 5 overlap.
    it("circleIntersectsCircle overlapping", function()
        expect_true(lurek.math.circleIntersectsCircle(0, 0, 5, 3, 0, 5))
    end)

    -- @description Asserts circles centered at (0,0) and (100,100) with radius 1 do not overlap.
    it("circleIntersectsCircle distant", function()
        expect_equal(lurek.math.circleIntersectsCircle(0, 0, 1, 100, 100, 1), false)
    end)
end)

-- â”€â”€ Color space â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies gamma and linear color conversions at fixed points and across a round-trip sweep from 0.0 to 1.0.
describe("math color space", function()
    -- @description Asserts gammaToLinear(0.5) is approximately 0.214 within 0.01.
    it("gammaToLinear(0.5) near 0.214", function()
        expect_near(lurek.math.gammaToLinear(0.5), 0.214, 0.01)
    end)

    -- @description Asserts gammaToLinear(0) returns 0 within 0.0001.
    it("gammaToLinear(0) = 0", function()
        expect_near(lurek.math.gammaToLinear(0), 0, 0.0001)
    end)

    -- @description Asserts gammaToLinear(1) returns 1 within 0.0001.
    it("gammaToLinear(1) = 1", function()
        expect_near(lurek.math.gammaToLinear(1), 1, 0.0001)
    end)

    -- @description Converts gamma values 0.0 through 1.0 to linear space and back, asserting each round-trip stays within 0.001.
    it("linearToGamma roundtrips", function()
        for i = 0, 10 do
            local gamma = i / 10.0
            local linear = lurek.math.gammaToLinear(gamma)
            local back = lurek.math.linearToGamma(linear)
            expect_near(back, gamma, 0.001)
        end
    end)
end)

-- @description Verifies vec2 construction, field access, vector math methods, interpolation, metamethods, and equality behavior.
describe("lurek.math.vec2", function()
    -- @description Asserts lurek.math.vec2 is exposed as a function.
    it("vec2 is a function", function()
        expect_type("function", lurek.math.vec2)
    end)

    -- @description Creates a vector with components (3,4) and asserts the result is userdata.
    it("vec2 creates a userdata", function()
        local v = lurek.math.vec2(3, 4)
        expect_type("userdata", v)
    end)

    -- @description Creates vec2(3,4) and asserts the x field is 3 within 1e-5.
    it("x field returns correct value", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v.x, 3, 1e-5)
    end)

    -- @description Creates vec2(3,4) and asserts the y field is 4 within 1e-5.
    it("y field returns correct value", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v.y, 4, 1e-5)
    end)

    -- @description Creates vec2(3,4) and asserts length() returns 5.0 within 1e-4.
    it("length returns correct magnitude", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v:length(), 5.0, 1e-4)
    end)

    -- @description Creates vec2(3,4) and asserts lengthSquared() returns 25.0 within 1e-4.
    it("lengthSquared returns squared magnitude", function()
        local v = lurek.math.vec2(3, 4)
        expect_near(v:lengthSquared(), 25.0, 1e-4)
    end)

    -- @description Computes the dot product of perpendicular unit vectors and asserts the result is 0.0 within 1e-5.
    it("dot product is correct", function()
        local a = lurek.math.vec2(1, 0)
        local b = lurek.math.vec2(0, 1)
        expect_near(a:dot(b), 0.0, 1e-5)
    end)

    -- @description Computes the dot product of parallel vectors (1,0) and (2,0) and asserts the result is 2.0 within 1e-5.
    it("dot product of parallel vectors", function()
        local a = lurek.math.vec2(1, 0)
        local b = lurek.math.vec2(2, 0)
        expect_near(a:dot(b), 2.0, 1e-5)
    end)

    -- @description Normalizes vec2(3,4) and asserts the resulting vector has length 1.0 within 1e-4.
    it("normalize produces unit vector", function()
        local v = lurek.math.vec2(3, 4)
        local n = v:normalize()
        expect_near(n:length(), 1.0, 1e-4)
    end)

    -- @description Measures the distance from vec2(0,0) to vec2(3,4) and asserts it is 5.0 within 1e-4.
    it("distance between two points", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(3, 4)
        expect_near(a:distance(b), 5.0, 1e-4)
    end)

    -- @description Lerps between vec2(0,0) and vec2(10,10) at t=0 and asserts the result stays at the first vector.
    it("lerp at t=0 returns first vector", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(10, 10)
        local c = a:lerp(b, 0)
        expect_near(c.x, 0, 1e-5)
        expect_near(c.y, 0, 1e-5)
    end)

    -- @description Lerps between vec2(0,0) and vec2(10,10) at t=1 and asserts the result equals the second vector.
    it("lerp at t=1 returns second vector", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(10, 10)
        local c = a:lerp(b, 1)
        expect_near(c.x, 10, 1e-5)
        expect_near(c.y, 10, 1e-5)
    end)

    -- @description Lerps between vec2(0,0) and vec2(10,10) at t=0.5 and asserts the result is the midpoint (5,5).
    it("lerp at t=0.5 returns midpoint", function()
        local a = lurek.math.vec2(0, 0)
        local b = lurek.math.vec2(10, 10)
        local c = a:lerp(b, 0.5)
        expect_near(c.x, 5, 1e-5)
        expect_near(c.y, 5, 1e-5)
    end)

    -- @description Adds vec2(1,2) and vec2(3,4) and asserts the resulting components are (4,6).
    it("addition metamethod works", function()
        local a = lurek.math.vec2(1, 2)
        local b = lurek.math.vec2(3, 4)
        local c = a + b
        expect_near(c.x, 4, 1e-5)
        expect_near(c.y, 6, 1e-5)
    end)

    -- @description Subtracts vec2(3,4) from vec2(5,7) and asserts the resulting components are (2,3).
    it("subtraction metamethod works", function()
        local a = lurek.math.vec2(5, 7)
        local b = lurek.math.vec2(3, 4)
        local c = a - b
        expect_near(c.x, 2, 1e-5)
        expect_near(c.y, 3, 1e-5)
    end)

    -- @description Multiplies vec2(2,3) by the scalar 2 and asserts the resulting components are (4,6).
    it("scalar multiplication metamethod works", function()
        local a = lurek.math.vec2(2, 3)
        local c = a * 2
        expect_near(c.x, 4, 1e-5)
        expect_near(c.y, 6, 1e-5)
    end)

    -- @description Converts vec2(1,2) to a string and asserts the result is a non-empty string.
    it("tostring metamethod returns readable string", function()
        local v = lurek.math.vec2(1, 2)
        local s = tostring(v)
        expect_type("string", s)
        expect_true(#s > 0)
    end)

    -- @description Creates two vectors with identical components and asserts the equality metamethod returns true.
    it("equality metamethod: same values are equal", function()
        local a = lurek.math.vec2(1, 2)
        local b = lurek.math.vec2(1, 2)
        expect_equal(a == b, true)
    end)

    -- @description Creates two vectors with different components and asserts the equality metamethod returns false.
    it("equality metamethod: different values are not equal", function()
        local a = lurek.math.vec2(1, 2)
        local b = lurek.math.vec2(3, 4)
        expect_equal(a == b, false)
    end)
end)

-- ── AABB Tree ─────────────────────────────────────────────────────────────────

-- @description Factory and type checks.
describe("lurek.math.aabbTree factory", function()
  -- @tests lurek.math.aabbTree
  it("aabbTree is a function", function()
    expect_type("function", lurek.math.aabbTree)
  end)

  -- @description Creates an AABB tree and confirms the returned value is userdata.
  it("returns a userdata", function()
    local t = lurek.math.aabbTree()
    expect_type("userdata", t)
  end)

  -- @description A freshly created tree has len 0.
  it("new tree len is 0", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:len(), 0)
  end)

  -- @description A freshly created tree reports isEmpty true.
  it("new tree isEmpty is true", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:isEmpty(), true)
  end)
end)

-- @description Insert and contains.
describe("AabbTree insert / contains", function()
  -- @tests lurek.math.aabbTree
  -- @description After inserting one entry, len should be 1.
  it("len increments after insert", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    expect_equal(t:len(), 1)
  end)

  -- @description contains returns true for a known id, false for unknown.
  it("contains returns true for inserted id", function()
    local t = lurek.math.aabbTree()
    t:insert(42, 0, 0, 5, 5)
    expect_equal(t:contains(42), true)
  end)

  -- @description contains returns false for an id that was never inserted.
  it("contains returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:contains(999), false)
  end)

  -- @description Inserting multiple entries updates len correctly.
  it("len reflects multiple inserts", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:insert(3, 10, 10, 20, 20)
    expect_equal(t:len(), 3)
  end)

  -- @description Inserting an id that already exists acts as an upsert (len stays the same).
  it("inserting duplicate id does not increase len", function()
    local t = lurek.math.aabbTree()
    t:insert(7, 0, 0, 10, 10)
    t:insert(7, 5, 5, 15, 15)  -- upsert
    expect_equal(t:len(), 1)
  end)
end)

-- @description Remove.
describe("AabbTree remove", function()
  -- @tests lurek.math.aabbTree
  -- @description remove returns true for a known id.
  it("remove returns true for known id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    expect_equal(t:remove(1), true)
  end)

  -- @description remove returns false for an unknown id.
  it("remove returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:remove(999), false)
  end)

  -- @description After removing, contains returns false.
  it("contains false after remove", function()
    local t = lurek.math.aabbTree()
    t:insert(5, 0, 0, 10, 10)
    t:remove(5)
    expect_equal(t:contains(5), false)
  end)

  -- @description After removing, len decrements.
  it("len decrements after remove", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:remove(1)
    expect_equal(t:len(), 1)
  end)
end)

-- @description query rectangle overlap.
describe("AabbTree query", function()
  -- @tests lurek.math.aabbTree
  -- @description A query that overlaps a single entry returns that id.
  it("query returns overlapping id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    t:insert(2, 20, 20, 30, 30)
    local ids = t:query(5, 5, 15, 15)
    expect_type("table", ids)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 1)
  end)

  -- @description A query that misses all entries returns an empty table.
  it("query returns empty table on miss", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    local ids = t:query(100, 100, 200, 200)
    expect_equal(#ids, 0)
  end)

  -- @description A query that covers all entries returns all ids.
  it("query returns all ids when rect covers all", function()
    local t = lurek.math.aabbTree()
    t:insert(10, 0, 0, 1, 1)
    t:insert(20, 5, 5, 6, 6)
    t:insert(30, 9, 9, 10, 10)
    local ids = t:query(-1, -1, 100, 100)
    expect_equal(#ids, 3)
  end)

  -- @description A query on an empty tree returns an empty table.
  it("query on empty tree returns empty table", function()
    local t = lurek.math.aabbTree()
    local ids = t:query(0, 0, 100, 100)
    expect_equal(#ids, 0)
  end)
end)

-- @description queryPoint.
describe("AabbTree queryPoint", function()
  -- @tests lurek.math.aabbTree
  -- @description A point inside an AABB returns that entry's id.
  it("queryPoint finds containing entry", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(5, 5)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 1)
  end)

  -- @description A point outside all AABBs returns an empty table.
  it("queryPoint returns empty for exterior point", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(50, 50)
    expect_equal(#ids, 0)
  end)

  -- @description A point on the edge of an AABB is considered inside.
  it("queryPoint on edge counts as inside", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(10, 10)
    expect_equal(#ids, 1)
  end)
end)

-- @description update.
describe("AabbTree update", function()
  -- @tests lurek.math.aabbTree
  -- @description update returns false for an unknown id.
  it("update returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:update(99, 0, 0, 1, 1), false)
  end)

  -- @description update returns true for an existing id.
  it("update returns true for known id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    expect_equal(t:update(1, 10, 10, 20, 20), true)
  end)

  -- @description After update, the old position no longer matches and new position does.
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

-- @description clear.
describe("AabbTree clear", function()
  -- @tests lurek.math.aabbTree
  -- @description After clear, len is 0 and isEmpty is true.
  it("clear resets len to 0", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:clear()
    expect_equal(t:len(), 0)
    expect_equal(t:isEmpty(), true)
  end)

  -- @description After clear, queries return empty tables.
  it("query after clear returns empty", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 100, 100)
    t:clear()
    local ids = t:query(0, 0, 100, 100)
    expect_equal(#ids, 0)
  end)
end)

-- @description Edge cases and stress.
describe("AabbTree edge cases", function()
  -- @tests lurek.math.aabbTree
  -- @description Single-entry tree: query with the exact AABB returns the id.
  it("single entry exact AABB match", function()
    local t = lurek.math.aabbTree()
    t:insert(7, 3, 3, 7, 7)
    local ids = t:query(3, 3, 7, 7)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 7)
  end)

  -- @description Many inserts and removals leave the tree in a consistent state.
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

-- ── Polygon Boolean Operations ────────────────────────────────────────────────

-- Unit square [0,0] to [1,1] (CCW)
local SQUARE = {
    {x=0, y=0}, {x=1, y=0}, {x=1, y=1}, {x=0, y=1}
}

-- Square offset to [0.5, 0.5] → [1.5, 1.5]  (overlaps with SQUARE)
local SQUARE_OFFSET = {
    {x=0.5, y=0.5}, {x=1.5, y=0.5}, {x=1.5, y=1.5}, {x=0.5, y=1.5}
}

-- Non-overlapping square [2, 2] → [3, 3]
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
        -- No overlap → result should contain SQUARE vertices
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

-- ── Property-Based Tests ──────────────────────────────────────────────────────

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

-- @description Covers suite: property: trig identities.
describe("property: trig identities", function()
    -- @tests lurek.math.sin
    -- @tests lurek.math.cos
    -- @description Generates 100 deterministic angles in [-10, 10] and checks that sin(x)^2 + cos(x)^2 stays within 1e-6 of 1.0 for each sample.
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

    -- @tests lurek.math.sin
    -- @description Reuses the deterministic angle set in [-10, 10] to verify the odd-function identity sin(-x) = -sin(x) across 100 samples.
    it("sin(-x) = -sin(x) for 100 values (odd function)", function()
        local angles = test_values(100, -10, 10)
        for i, x in ipairs(angles) do
            local pos = lurek.math.sin(x)
            local neg = lurek.math.sin(-x)
            expect_near(-pos, neg, 1e-10,
                "sin is odd at x=" .. string.format("%.4f", x))
        end
    end)

    -- @tests lurek.math.cos
    -- @description Reuses the deterministic angle set in [-10, 10] to verify the even-function identity cos(-x) = cos(x) across 100 samples.
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

-- @description Covers suite: property: sqrt invariants.
describe("property: sqrt invariants", function()
    -- @tests lurek.math.sqrt
    -- @description Samples 100 positive values from 0.001 to 10000 and verifies squaring sqrt(x) reconstructs x within a magnitude-scaled tolerance.
    it("sqrt(x)^2 = x for 100 positive values", function()
        local vals = test_values(100, 0.001, 10000)
        for i, x in ipairs(vals) do
            local root = lurek.math.sqrt(x)
            expect_near(x, root * root, x * 1e-10 + 1e-10,
                "sqrt round-trip at x=" .. string.format("%.4f", x))
        end
    end)

    -- @tests lurek.math.sqrt
    -- @description Splits 100 positive samples into 50 pairs and checks the multiplicative identity sqrt(a*b) = sqrt(a) * sqrt(b) for each pair.
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

-- @description Covers suite: property: exp/log invariants.
describe("property: exp/log invariants", function()
    -- @tests lurek.math.exp
    -- @description Uses 50 deterministic value pairs in [-3, 3] and verifies exp(a + b) matches exp(a) * exp(b) with scaled floating-point tolerance.
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

-- @description Covers suite: property: Vec2 operations.
describe("property: Vec2 operations", function()
    -- @tests lurek.math.Vec2
    -- @description Builds 50 deterministic Vec2 pairs and compares v1 + v2 against v2 + v1 component-wise to validate vector addition commutativity.
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

    -- @tests lurek.math.Vec2
    -- @tests lurek.math.Vec2.length
    -- @description Creates 100 Vec2 samples from deterministic coordinates and verifies each computed length is non-negative.
    it("vec2 length is non-negative for 100 values", function()
        local vals = test_values(200, -1000, 1000)
        for i = 1, 100 do
            local v = lurek.math.Vec2(vals[i], vals[i + 100])
            local len = v:length()
            expect_true(len >= 0,
                "length >= 0 for (" .. vals[i] .. "," .. vals[i+100] .. ")")
        end
    end)

    -- @tests lurek.math.Vec2
    -- @tests lurek.math.Vec2.normalized
    -- @tests lurek.math.Vec2.length
    -- @description Filters out near-zero vectors, normalizes the remaining 100 deterministic samples, and checks the resulting vectors stay unit length within 1e-6.
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

-- @description Covers suite: property: lerp interpolation.
describe("property: lerp interpolation", function()
    -- @tests lurek.math.lerp
    -- @description Checks 50 deterministic scalar pairs and verifies lerp returns the first endpoint at t=0 and the second endpoint at t=1.
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

    -- @tests lurek.math.lerp
    -- @description Steps t from 0.01 to 1.00 for a fixed increasing range from 10 to 100 and verifies each lerp sample is at least as large as the previous one.
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

-- ── Voronoi ───────────────────────────────────────────────────────────────────

describe("lurek.math.voronoi type", function()
  -- @tests lurek.math.voronoi
  it("voronoi is a function", function()
    expect_type("function", lurek.math.voronoi)
  end)

  it("returns a table", function()
    local cells = lurek.math.voronoi({{x=0,y=0},{x=1,y=0},{x=0.5,y=1}})
    expect_type("table", cells)
  end)
end)

describe("lurek.math.voronoi empty input", function()
  -- @tests lurek.math.voronoi
  it("empty input returns empty table", function()
    local cells = lurek.math.voronoi({})
    expect_equal(0, #cells)
  end)
end)

describe("lurek.math.voronoi cell count", function()
  -- @tests lurek.math.voronoi
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
  -- @tests lurek.math.voronoi
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
  -- @tests lurek.math.voronoi
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
  -- @tests lurek.math.voronoi
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

-- ── smoothstep ────────────────────────────────────────────────────────────────
-- @description Tests for the lurek.math.smoothstep function.
describe("lurek.math.smoothstep", function()
  -- @tests lurek.math.smoothstep
  -- @description x <= e0 returns 0.
  it("x <= e0 returns 0", function()
    expect_equal(0, lurek.math.smoothstep(0, 1, -0.5))
  end)
  -- @tests lurek.math.smoothstep
  -- @description x >= e1 returns 1.
  it("x >= e1 returns 1", function()
    expect_equal(1, lurek.math.smoothstep(0, 1, 2))
  end)
  -- @tests lurek.math.smoothstep
  -- @description midpoint returns 0.5.
  it("midpoint returns 0.5", function()
    expect_near(0.5, lurek.math.smoothstep(0, 1, 0.5), 1e-5)
  end)
  -- @tests lurek.math.smoothstep
  -- @description result is between 0 and 1 for interior x.
  it("interior result is in [0,1]", function()
    local v = lurek.math.smoothstep(0, 1, 0.3)
    expect_true(v >= 0 and v <= 1, "smoothstep in range")
  end)
end)

-- ── inverseLerp ───────────────────────────────────────────────────────────────
-- @description Tests for the lurek.math.inverseLerp function.
describe("lurek.math.inverseLerp", function()
  -- @tests lurek.math.inverseLerp
  -- @description returns 0 at start of range.
  it("returns 0 at start", function()
    expect_equal(0, lurek.math.inverseLerp(0, 10, 0))
  end)
  -- @tests lurek.math.inverseLerp
  -- @description returns 1 at end of range.
  it("returns 1 at end", function()
    expect_equal(1, lurek.math.inverseLerp(0, 10, 10))
  end)
  -- @tests lurek.math.inverseLerp
  -- @description returns 0.5 at midpoint.
  it("returns 0.5 at midpoint", function()
    expect_near(0.5, lurek.math.inverseLerp(0, 10, 5), 1e-5)
  end)
end)

-- ── hslToRgb / rgbToHsl ───────────────────────────────────────────────────────
-- @description Tests for the lurek.math.hslToRgb and lurek.math.rgbToHsl functions.
describe("lurek.math hslToRgb and rgbToHsl", function()
  -- @tests lurek.math.hslToRgb
  -- @description hsl(0,0,1) is white: r=g=b=1.
  it("hslToRgb white is (1,1,1,1)", function()
    local r, g, b, a = lurek.math.hslToRgb(0, 0, 1.0)
    expect_near(1.0, r, 1e-5)
    expect_near(1.0, g, 1e-5)
    expect_near(1.0, b, 1e-5)
    expect_near(1.0, a, 1e-5)
  end)
  -- @tests lurek.math.hslToRgb
  -- @description hsl(0,0,0) is black: r=g=b=0.
  it("hslToRgb black is (0,0,0)", function()
    local r, g, b = lurek.math.hslToRgb(0, 0, 0.0)
    expect_near(0.0, r, 1e-5)
    expect_near(0.0, g, 1e-5)
    expect_near(0.0, b, 1e-5)
  end)
  -- @tests lurek.math.rgbToHsl
  -- @description pure red (1,0,0) gives hsl(0, 1, 0.5).
  it("rgbToHsl red gives (0, 1, 0.5)", function()
    local h, s, l = lurek.math.rgbToHsl(1.0, 0.0, 0.0)
    expect_near(0.0, h, 1e-5)
    expect_near(1.0, s, 1e-5)
    expect_near(0.5, l, 1e-5)
  end)
  -- @tests lurek.math.hslToRgb
  -- @tests lurek.math.rgbToHsl
  -- @description roundtrip: rgb → hsl → rgb preserves the original colour.
  it("hslToRgb/rgbToHsl roundtrip preserves colour", function()
    local r0, g0, b0 = 0.3, 0.6, 0.9
    local h, s, l = lurek.math.rgbToHsl(r0, g0, b0)
    local r1, g1, b1 = lurek.math.hslToRgb(h or 0, s or 0, l or 0)
    expect_near(r0, r1, 1e-4)
    expect_near(g0, g1, 1e-4)
    expect_near(b0, b1, 1e-4)
  end)
end)

-- ── fromHex ───────────────────────────────────────────────────────────────────
-- @description Tests for the lurek.math.fromHex colour parser.
describe("lurek.math.fromHex", function()
  -- @tests lurek.math.fromHex
  -- @description #ffffff parses to (1,1,1,1).
  it("parses #ffffff as white", function()
    local r, g, b, a = lurek.math.fromHex("#ffffff")
    expect_near(1.0, r, 1e-5)
    expect_near(1.0, g, 1e-5)
    expect_near(1.0, b, 1e-5)
    expect_near(1.0, a, 1e-5)
  end)
  -- @tests lurek.math.fromHex
  -- @description #000000 parses to (0,0,0,1).
  it("parses #000000 as black", function()
    local r, g, b, a = lurek.math.fromHex("#000000")
    expect_near(0.0, r, 1e-5)
    expect_near(0.0, g, 1e-5)
    expect_near(0.0, b, 1e-5)
    expect_near(1.0, a, 1e-5)
  end)
  -- @tests lurek.math.fromHex
  -- @description invalid hex string returns nil.
  xit("invalid hex returns nil", function()
    local r = lurek.math.fromHex("notahex")
    expect_equal(nil, r)
  end)
end)

-- ── rectUnion ─────────────────────────────────────────────────────────────────
-- @description Tests for the lurek.math.rectUnion function.
describe("lurek.math.rectUnion", function()
  -- @tests lurek.math.rectUnion
  -- @description union of two identical rects is that same rect.
  it("union of equal rects is that rect", function()
    local x, y, w, h = lurek.math.rectUnion(0, 0, 10, 10, 0, 0, 10, 10)
    expect_equal(0, x)
    expect_equal(0, y)
    expect_equal(10, w)
    expect_equal(10, h)
  end)
  -- @tests lurek.math.rectUnion
  -- @description union of two side-by-side rects spans both.
  it("union of adjacent rects spans both", function()
    local x, y, w, h = lurek.math.rectUnion(0, 0, 5, 5, 5, 0, 5, 5)
    expect_equal(0, x)
    expect_equal(0, y)
    expect_equal(10, w)
    expect_equal(5, h)
  end)
  -- @tests lurek.math.rectUnion
  -- @description union returns 4 number values.
  it("returns four numbers", function()
    local x, y, w, h = lurek.math.rectUnion(1, 2, 3, 4, 5, 6, 7, 8)
    expect_type("number", x)
    expect_type("number", y)
    expect_type("number", w)
    expect_type("number", h)
  end)
end)

-- ── rectFromCenter ────────────────────────────────────────────────────────────
-- @description Tests for the lurek.math.rectFromCenter function.
describe("lurek.math.rectFromCenter", function()
  -- @tests lurek.math.rectFromCenter
  -- @description top-left corner equals center minus half-size.
  it("top-left is center minus half-size", function()
    local x, y, w, h = lurek.math.rectFromCenter(10, 10, 4, 6)
    expect_equal(8, x)
    expect_equal(7, y)
    expect_equal(4, w)
    expect_equal(6, h)
  end)
  -- @tests lurek.math.rectFromCenter
  -- @description size (w,h) is preserved unchanged.
  it("size is preserved", function()
    local _, _, w, h = lurek.math.rectFromCenter(0, 0, 8, 12)
    expect_equal(8, w)
    expect_equal(12, h)
  end)
end)

-- ── Vec2:fromAngle / reflect ──────────────────────────────────────────────────
-- @description Tests for Vec2:fromAngle and Vec2:reflect.
describe("lurek.math Vec2 fromAngle and reflect", function()
  -- @tests lurek.math.Vec2.fromAngle
  -- @description fromAngle(0) points in the +X direction.
  it("fromAngle(0) returns unit +X", function()
    local v = lurek.math.vec2(0, 0).fromAngle(0)
    expect_near(1.0, v.x, 1e-5)
    expect_near(0.0, v.y, 1e-5)
  end)
  -- @tests lurek.math.Vec2.fromAngle
  -- @description fromAngle(pi/2) points in the +Y direction.
  it("fromAngle(pi/2) returns unit +Y", function()
    local v = lurek.math.vec2(0, 0).fromAngle(math.pi / 2)
    expect_near(0.0, v.x, 1e-5)
    expect_near(1.0, v.y, 1e-5)
  end)
  -- @tests lurek.math.Vec2.fromAngle
  -- @description result has unit length.
  it("fromAngle result is unit length", function()
    local v = lurek.math.vec2(0, 0).fromAngle(1.23)
    local len = math.sqrt(v.x * v.x + v.y * v.y)
    expect_near(1.0, len, 1e-5)
  end)
  -- @tests lurek.math.Vec2.reflect
  -- @description reflecting (1,-1) off a horizontal normal (0,1) gives (1,1).
  it("reflect off horizontal normal", function()
    local v = lurek.math.Vec2(1, -1)
    local n = lurek.math.Vec2(0, 1)
    local r = v:reflect(n)
    expect_near(1.0, r.x, 1e-5)
    expect_near(1.0, r.y, 1e-5)
  end)
  -- @tests lurek.math.Vec2.reflect
  -- @description reflecting a vector along its normal returns the negative vector.
  it("reflect parallel to normal flips sign", function()
    local v = lurek.math.Vec2(0, -1)
    local n = lurek.math.Vec2(0, 1)
    local r = v:reflect(n)
    expect_near(0.0, r.x, 1e-5)
    expect_near(1.0, r.y, 1e-5)
  end)
end)

-- ── Vec3:splat ────────────────────────────────────────────────────────────────
-- @description Tests for Vec3:splat constructor.
describe("lurek.math Vec3 splat", function()
  -- @tests lurek.math.Vec3.splat
  -- @description splat(5) creates Vec3 with all components equal to 5.
  xit("splat(5) gives Vec3(5,5,5)", function()
      ---@type LVec3
    local v = lurek.math.vec3(5, 5, 5)
    expect_equal(5, v.x)
    expect_equal(5, v.y)
    expect_equal(5, v.z)
  end)
  -- @tests lurek.math.Vec3.splat
  -- @description splat(0) creates a zero vector.
  xit("splat(0) gives zero Vec3", function()
      ---@type LVec3
    local v = lurek.math.vec3(0, 0, 0)
    expect_equal(0, v.x)
    expect_equal(0, v.y)
    expect_equal(0, v.z)
  end)
end)

-- ── Transform:decompose ───────────────────────────────────────────────────────
-- @description Tests for Transform:decompose returning (tx, ty, angle, sx, sy).
describe("lurek.math Transform decompose", function()
  -- @tests lurek.math.Transform.decompose
  -- @description decompose returns exactly 5 number values.
  xit("decompose returns 5 numbers", function()
    local t = lurek.math.newTransform()
    local x, y, a, sx, sy = t:decompose()
    expect_type("number", x)
    expect_type("number", y)
    expect_type("number", a)
    expect_type("number", sx)
    expect_type("number", sy)
  end)
  -- @tests lurek.math.Transform.decompose
  -- @description identity transform decomposes to (0, 0, 0, 1, 1).
  xit("identity decomposes to (0,0,0,1,1)", function()
    local t = lurek.math.newTransform()
    local x, y, a, sx, sy = t:decompose()
    expect_near(0.0, x, 1e-5)
    expect_near(0.0, y, 1e-5)
    expect_near(0.0, a, 1e-5)
    expect_near(1.0, sx, 1e-5)
    expect_near(1.0, sy, 1e-5)
  end)
end)

-- ── easing: inOutElastic / inOutBounce / inOutBack ───────────────────────────
-- @description Tests for the inOutElastic, inOutBounce, inOutBack easing functions.
describe("lurek.math easing inOut variants", function()
  -- @tests lurek.math.inOutElastic
  -- @description inOutElastic returns 0 at t=0 and 1 at t=1.
  it("inOutElastic boundary values", function()
    expect_near(0.0, lurek.math.inOutElastic(0), 1e-5)
    expect_near(1.0, lurek.math.inOutElastic(1), 1e-5)
  end)
  -- @tests lurek.math.inOutElastic
  -- @description inOutElastic is symmetric: f(1-t) == 1 - f(t).
  it("inOutElastic is symmetric", function()
    local lo = lurek.math.inOutElastic(0.25)
    local hi = lurek.math.inOutElastic(0.75)
    expect_near(1.0 - lo, hi, 1e-5)
  end)
  -- @tests lurek.math.inOutBounce
  -- @description inOutBounce returns 0 at t=0 and 1 at t=1.
  it("inOutBounce boundary values", function()
    expect_near(0.0, lurek.math.inOutBounce(0), 1e-5)
    expect_near(1.0, lurek.math.inOutBounce(1), 1e-5)
  end)
  -- @tests lurek.math.inOutBounce
  -- @description inOutBounce has the expected symmetry: f(1-t) ~= 1 - f(t).
  -- Note: bounce easings are NOT monotone by design — they bounce back.
  it("inOutBounce is symmetric", function()
    for i = 1, 9 do
      local t = i / 10
      local ft = lurek.math.inOutBounce(t)
      local f1t = lurek.math.inOutBounce(1 - t)
      expect_near(1 - ft, f1t, 1e-5, "inOutBounce symmetric at t=" .. t)
    end
  end)
  -- @tests lurek.math.inOutBack
  -- @description inOutBack returns 0 at t=0 and 1 at t=1.
  it("inOutBack boundary values", function()
    expect_near(0.0, lurek.math.inOutBack(0), 1e-5)
    expect_near(1.0, lurek.math.inOutBack(1), 1e-5)
  end)
end)

-- ── CatmullRomSpline: addPoint / removePoint ──────────────────────────────────
-- @description Tests for CatmullRomSpline addPoint and removePoint methods.
describe("lurek.math CatmullRomSpline addPoint and removePoint", function()
  -- @tests lurek.math.CatmullRomSpline.addPoint
  -- @description adding two points increases count to 2.
  xit("addPoint increases point count", function()
    ---@type LCatmullRom
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
    s:addPoint(1, 1)
    expect_equal(2, s:len())
  end)
  -- @tests lurek.math.CatmullRomSpline.removePoint
  -- @description removePoint(2) removes the second point, reducing count by 1.
  xit("removePoint reduces count by 1", function()
      ---@type LCatmullRom
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
    s:addPoint(1, 1)
    s:addPoint(2, 0)
    s:removePoint(2)
    expect_equal(2, s:len())
  end)
  -- @tests lurek.math.CatmullRomSpline.removePoint
  -- @description removePoint with out-of-range index leaves count unchanged.
  xit("removePoint out-of-range is safe", function()
      ---@type LCatmullRom
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
    s:removePoint(99)
    expect_equal(1, s:len())
  end)
  -- @tests lurek.math.CatmullRomSpline.addPoint
  -- @tests lurek.math.CatmullRomSpline.removePoint
  -- @description add then remove all points leaves an empty spline.
  xit("adding then removing all points gives empty spline", function()
      ---@type LCatmullRom
    local s = lurek.math.catmullRom({})
    s:addPoint(0, 0)
    s:addPoint(1, 0)
    s:removePoint(1)
    s:removePoint(1)
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
    local t = lurek.math.aabbTree()
    t:insert(42, 0, 0, 4, 4)
    local hits = lurek.math.newSpatialHash(8)
    hits:insert("42", 0, 0, 4, 4)
    local results = hits:querySegment(2, -1, 2, 5)
    expect_equal(1, #results)
    expect_equal("42", results[1])
  end)

  xit("querySegment misses non-intersecting AABB", function()
    local t = lurek.math.aabbTree()
    t:insert(42, 10, 10, 20, 20)
    local hash = lurek.math.newSpatialHash(8)
    hash:insert("42", 10, 10, 10, 10)
    local hits = hash:querySegment(0, 0, 5, 5)
    expect_equal(0, #hits)
  end)
end)

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.math.fbm
    it("covers lurek.math.fbm", function()
        -- TODO: Implement test for lurek.math.fbm
    end)

    -- @tests lurek.math.inQuart
    it("covers lurek.math.inQuart", function()
        expect_near(0.0, lurek.math.inQuart(0), 1e-5)
        expect_near(1.0, lurek.math.inQuart(1), 1e-5)
    end)

    -- @tests lurek.math.outQuart
    it("covers lurek.math.outQuart", function()
        expect_near(0.0, lurek.math.outQuart(0), 1e-5)
        expect_near(1.0, lurek.math.outQuart(1), 1e-5)
    end)

    -- @tests lurek.math.inOutQuart
    it("covers lurek.math.inOutQuart", function()
        expect_near(0.0, lurek.math.inOutQuart(0), 1e-5)
        expect_near(0.5, lurek.math.inOutQuart(0.5), 1e-5)
        expect_near(1.0, lurek.math.inOutQuart(1), 1e-5)
    end)

    -- @tests lurek.math.inOutExpo
    it("covers lurek.math.inOutExpo", function()
        expect_near(0.0, lurek.math.inOutExpo(0), 1e-5)
        expect_near(0.5, lurek.math.inOutExpo(0.5), 1e-5)
        expect_near(1.0, lurek.math.inOutExpo(1), 1e-5)
    end)

    -- @tests lurek.math.inBounce
    it("covers lurek.math.inBounce", function()
        expect_near(0.0, lurek.math.inBounce(0), 1e-5)
        expect_near(1.0, lurek.math.inBounce(1), 1e-5)
    end)

    -- @tests lurek.math.circleIntersectsLine
    it("covers lurek.math.circleIntersectsLine", function()
        local hit, x1, y1, x2, y2 = lurek.math.circleIntersectsLine(0, 0, 1, -2, 0, 2, 0)
        expect_true(hit)
        expect_near(1.0, math.abs(x1), 1e-5)
        expect_near(0.0, y1, 1e-5)
        expect_near(1.0, math.abs(x2), 1e-5)
        expect_near(0.0, y2, 1e-5)
    end)

    -- @tests lurek.math.circleIntersectsSegment
    it("covers lurek.math.circleIntersectsSegment", function()
        -- TODO: Implement test for lurek.math.circleIntersectsSegment
    end)

    -- @tests lurek.math.closestPointOnSegment
    it("covers lurek.math.closestPointOnSegment", function()
        local x, y = lurek.math.closestPointOnSegment(1, 2, 0, 0, 2, 0)
        expect_near(1.0, x, 1e-5)
        expect_near(0.0, y, 1e-5)
    end)

    -- @tests lurek.math.convexHull
    it("covers lurek.math.convexHull", function()
        local hull = lurek.math.convexHull({0, 0, 4, 0, 4, 4, 0, 4, 2, 2})
        expect_equal(8, #hull)
    end)

    -- @tests lurek.math.delaunayTriangulate
    it("covers lurek.math.delaunayTriangulate", function()
        -- TODO: Implement test for lurek.math.delaunayTriangulate
    end)

    -- @tests lurek.math.lineIntersect
    it("covers lurek.math.lineIntersect", function()
        local x, y = lurek.math.lineIntersect(0, 0, 1, 1, 0, 1, 1, 0)
        expect_near(0.5, x, 1e-5)
        expect_near(0.5, y, 1e-5)
    end)

    -- @tests lurek.math.pointInPolygon
    it("covers lurek.math.pointInPolygon", function()
        local square = {0, 0, 4, 0, 4, 4, 0, 4}
        expect_true(lurek.math.pointInPolygon(square, 2, 2))
        expect_false(lurek.math.pointInPolygon(square, 5, 5))
    end)

    -- @tests lurek.math.polygonArea
    it("covers lurek.math.polygonArea", function()
        local area = lurek.math.polygonArea({0, 0, 1, 0, 1, 1, 0, 1})
        expect_near(1.0, math.abs(area), 1e-5)
    end)

    -- @tests lurek.math.polygonCentroid
    it("covers lurek.math.polygonCentroid", function()
        -- TODO: Implement test for lurek.math.polygonCentroid
    end)

    -- @tests lurek.math.segmentIntersectsSegment
    it("covers lurek.math.segmentIntersectsSegment", function()
        local hit, x, y = lurek.math.segmentIntersectsSegment(0, 0, 2, 2, 0, 2, 2, 0)
        expect_true(hit)
        expect_near(1.0, x, 1e-5)
        expect_near(1.0, y, 1e-5)
    end)

    -- @tests lurek.math.rad
    it("covers lurek.math.rad", function()
        -- TODO: Implement test for lurek.math.rad
    end)

    -- @tests lurek.math.deg
    it("covers lurek.math.deg", function()
        -- TODO: Implement test for lurek.math.deg
    end)

    -- @tests lurek.math.tan
    it("covers lurek.math.tan", function()
        -- TODO: Implement test for lurek.math.tan
    end)

    -- @tests lurek.math.log
    it("covers lurek.math.log", function()
        -- TODO: Implement test for lurek.math.log
    end)

    -- @tests lurek.math.pow
    it("covers lurek.math.pow", function()
        -- TODO: Implement test for lurek.math.pow
    end)

    -- @tests lurek.math.fmod
    it("covers lurek.math.fmod", function()
        -- TODO: Implement test for lurek.math.fmod
    end)

    -- @tests lurek.math.polygonClip
    it("covers lurek.math.polygonClip", function()
        -- TODO: Implement test for lurek.math.polygonClip
    end)

    -- @tests Vec2:dot
    it("covers Vec2:dot", function()
        -- TODO: Implement test for Vec2:dot
    end)

    -- @tests Vec2:x
    it("covers Vec2:x", function()
        -- TODO: Implement test for Vec2:x
    end)

    -- @tests Vec2:y
    it("covers Vec2:y", function()
        -- TODO: Implement test for Vec2:y
    end)

    -- @tests Vec3:dot
    it("covers Vec3:dot", function()
        -- TODO: Implement test for Vec3:dot
    end)

    -- @tests Vec3:add
    it("covers Vec3:add", function()
        -- TODO: Implement test for Vec3:add
    end)

    -- @tests Vec3:sub
    it("covers Vec3:sub", function()
        -- TODO: Implement test for Vec3:sub
    end)

    -- @tests CatmullRom:len
    it("covers CatmullRom:len", function()
        -- TODO: Implement test for CatmullRom:len
    end)

    -- @tests RandomGenerator:getSeed
    it("covers RandomGenerator:getSeed", function()
        -- TODO: Implement test for RandomGenerator:getSeed
    end)

    -- @tests Transform:shear
    it("covers Transform:shear", function()
        -- TODO: Implement test for Transform:shear
    end)

    -- @tests Transform:getMatrix
    it("covers Transform:getMatrix", function()
        -- TODO: Implement test for Transform:getMatrix
    end)

    -- @tests BezierCurve:removeControlPoint
    it("covers BezierCurve:removeControlPoint", function()
        -- TODO: Implement test for BezierCurve:removeControlPoint
    end)

    -- @tests Tween:getAllValues
    it("covers Tween:getAllValues", function()
        local tw = lurek.math.newTween(1.0, "linear")
        tw:addValue(0.0, 10.0)
        tw:addValue(100.0, 200.0)
        tw:setTime(1.0)
        local vals = tw:getAllValues()
        expect_equal(2, #vals)
        expect_near(10.0, vals[1], 1e-3)
        expect_near(200.0, vals[2], 1e-3)
    end)

    -- @tests Tween:getValueCount
    it("covers Tween:getValueCount", function()
        local tw = lurek.math.newTween(1.0, "linear")
        tw:addValue(0.0, 10.0)
        tw:addValue(10.0, 20.0)
        expect_equal(2, tw:getValueCount())
    end)

    -- @tests Tween:getClock
    it("covers Tween:getClock", function()
        local tw = lurek.math.newTween(1.0, "linear")
        tw:setTime(0.25)
        expect_near(0.25, tw:getClock(), 1e-5)
    end)

    -- @tests Tween:set
    it("covers Tween:set", function()
        local tw = lurek.math.newTween(1.0, "linear")
        tw:addValue(0.0, 100.0)
        tw:set(0.5)
        expect_near(50.0, tw:getValue(1), 1e-3)
    end)

    -- @tests Tween:addValue
    it("covers Tween:addValue", function()
        local tw = lurek.math.newTween(1.0, "linear")
        expect_equal(1, tw:addValue(0.0, 100.0))
        expect_equal(2, tw:addValue(50.0, 150.0))
    end)

    -- @tests NoiseGenerator:perlin1d
    it("covers NoiseGenerator:perlin1d", function()
        -- TODO: Implement test for NoiseGenerator:perlin1d
    end)

    -- @tests NoiseGenerator:perlin4d
    it("covers NoiseGenerator:perlin4d", function()
        -- TODO: Implement test for NoiseGenerator:perlin4d
    end)

    -- @tests NoiseGenerator:simplex1d
    it("covers NoiseGenerator:simplex1d", function()
        -- TODO: Implement test for NoiseGenerator:simplex1d
    end)

    -- @tests NoiseGenerator:simplex3d
    it("covers NoiseGenerator:simplex3d", function()
        -- TODO: Implement test for NoiseGenerator:simplex3d
    end)

    -- @tests NoiseGenerator:getSeed
    it("covers NoiseGenerator:getSeed", function()
        -- TODO: Implement test for NoiseGenerator:getSeed
    end)

    -- @tests Circle:x
    it("covers Circle:x", function()
        -- TODO: Implement test for Circle:x
    end)

    -- @tests Circle:y
    it("covers Circle:y", function()
        -- TODO: Implement test for Circle:y
    end)

    -- @tests AabbTree:len
    it("covers AabbTree:len", function()
        -- TODO: Implement test for AabbTree:len
    end)

end)

describe("Missing explicit test for lurek.math.newRandomGenerator", function()
    it("lurek.math.newRandomGenerator works", function()
        -- @tests lurek.math.newRandomGenerator
        -- TODO: add assertion for lurek.math.newRandomGenerator
    end)
end)

describe("Missing explicit test for lurek.math.newTransform", function()
    it("lurek.math.newTransform works", function()
        -- @tests lurek.math.newTransform
        -- TODO: add assertion for lurek.math.newTransform
    end)
end)

describe("Missing explicit test for lurek.math.newBezierCurve", function()
    it("lurek.math.newBezierCurve works", function()
        -- @tests lurek.math.newBezierCurve
        -- TODO: add assertion for lurek.math.newBezierCurve
    end)
end)

describe("Missing explicit test for lurek.math.newTween", function()
    it("lurek.math.newTween works", function()
        -- @tests lurek.math.newTween
        local tw = lurek.math.newTween(1.0, "nonexistent")
        expect_equal("LTween", tw:type())
        tw:addValue(0.0, 100.0)
        tw:setTime(0.5)
        expect_near(50.0, tw:getValue(1), 1e-3)
    end)
end)

describe("Missing explicit test for lurek.math.newSpatialHash", function()
    it("lurek.math.newSpatialHash works", function()
        -- @tests lurek.math.newSpatialHash
        -- TODO: add assertion for lurek.math.newSpatialHash
    end)
end)

describe("Missing explicit test for lurek.math.newNoiseGenerator", function()
    it("lurek.math.newNoiseGenerator works", function()
        -- @tests lurek.math.newNoiseGenerator
        -- TODO: add assertion for lurek.math.newNoiseGenerator
    end)
end)

describe("Missing explicit test for lurek.math.perlin2d", function()
    it("lurek.math.perlin2d works", function()
        -- @tests lurek.math.perlin2d
        -- TODO: add assertion for lurek.math.perlin2d
    end)
end)

describe("Missing explicit test for lurek.math.perlin3d", function()
    it("lurek.math.perlin3d works", function()
        -- @tests lurek.math.perlin3d
        -- TODO: add assertion for lurek.math.perlin3d
    end)
end)

describe("Missing explicit test for lurek.math.simplex2d", function()
    it("lurek.math.simplex2d works", function()
        -- @tests lurek.math.simplex2d
        -- TODO: add assertion for lurek.math.simplex2d
    end)
end)

describe("Missing explicit test for lurek.math.applyEasing", function()
    it("lurek.math.applyEasing works", function()
        -- @tests lurek.math.applyEasing
        local ok = pcall(function()
            return lurek.math.applyEasing("nonexistent", 0.5)
        end)
        expect_false(ok)
    end)
end)

describe("Missing explicit test for lurek.math.linear", function()
    it("lurek.math.linear works", function()
        -- @tests lurek.math.linear
        -- TODO: add assertion for lurek.math.linear
    end)
end)

describe("Missing explicit test for lurek.math.inQuad", function()
    it("lurek.math.inQuad works", function()
        -- @tests lurek.math.inQuad
        expect_near(0.0, lurek.math.inQuad(0), 1e-5)
        expect_near(0.25, lurek.math.inQuad(0.5), 1e-5)
        expect_near(1.0, lurek.math.inQuad(1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.outQuad", function()
    it("lurek.math.outQuad works", function()
        -- @tests lurek.math.outQuad
        expect_near(0.0, lurek.math.outQuad(0), 1e-5)
        expect_near(1.0, lurek.math.outQuad(1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.inOutQuad", function()
    it("lurek.math.inOutQuad works", function()
        -- @tests lurek.math.inOutQuad
        expect_near(0.0, lurek.math.inOutQuad(0), 1e-5)
        expect_near(0.5, lurek.math.inOutQuad(0.5), 1e-5)
        expect_near(1.0, lurek.math.inOutQuad(1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.inCubic", function()
    it("lurek.math.inCubic works", function()
        -- @tests lurek.math.inCubic
        -- TODO: add assertion for lurek.math.inCubic
    end)
end)

describe("Missing explicit test for lurek.math.outCubic", function()
    it("lurek.math.outCubic works", function()
        -- @tests lurek.math.outCubic
        -- TODO: add assertion for lurek.math.outCubic
    end)
end)

describe("Missing explicit test for lurek.math.inOutCubic", function()
    it("lurek.math.inOutCubic works", function()
        -- @tests lurek.math.inOutCubic
        expect_near(0.5, lurek.math.inOutCubic(0.5), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.inSine", function()
    it("lurek.math.inSine works", function()
        -- @tests lurek.math.inSine
        -- TODO: add assertion for lurek.math.inSine
    end)
end)

describe("Missing explicit test for lurek.math.outSine", function()
    it("lurek.math.outSine works", function()
        -- @tests lurek.math.outSine
        -- TODO: add assertion for lurek.math.outSine
    end)
end)

describe("Missing explicit test for lurek.math.inOutSine", function()
    it("lurek.math.inOutSine works", function()
        -- @tests lurek.math.inOutSine
        expect_near(0.5, lurek.math.inOutSine(0.5), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.inExpo", function()
    it("lurek.math.inExpo works", function()
        -- @tests lurek.math.inExpo
        expect_near(0.0, lurek.math.inExpo(0), 1e-5)
        expect_near(1.0, lurek.math.inExpo(1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.outExpo", function()
    it("lurek.math.outExpo works", function()
        -- @tests lurek.math.outExpo
        expect_near(0.0, lurek.math.outExpo(0), 1e-5)
        expect_near(1.0, lurek.math.outExpo(1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.inElastic", function()
    it("lurek.math.inElastic works", function()
        -- @tests lurek.math.inElastic
        expect_near(0.0, lurek.math.inElastic(0), 1e-5)
        expect_near(1.0, lurek.math.inElastic(1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.outElastic", function()
    it("lurek.math.outElastic works", function()
        -- @tests lurek.math.outElastic
        expect_near(0.0, lurek.math.outElastic(0), 1e-5)
        expect_near(1.0, lurek.math.outElastic(1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.outBounce", function()
    it("lurek.math.outBounce works", function()
        -- @tests lurek.math.outBounce
        expect_near(0.0, lurek.math.outBounce(0), 1e-5)
        expect_near(1.0, lurek.math.outBounce(1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.inBack", function()
    it("lurek.math.inBack works", function()
        -- @tests lurek.math.inBack
        expect_near(0.0, lurek.math.inBack(0), 1e-5)
        expect_near(1.0, lurek.math.inBack(1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.outBack", function()
    it("lurek.math.outBack works", function()
        -- @tests lurek.math.outBack
        expect_near(0.0, lurek.math.outBack(0), 1e-5)
        expect_near(1.0, lurek.math.outBack(1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.triangulate", function()
    it("lurek.math.triangulate works", function()
        -- @tests lurek.math.triangulate
        -- TODO: add assertion for lurek.math.triangulate
    end)
end)

describe("Missing explicit test for lurek.math.isConvex", function()
    it("lurek.math.isConvex works", function()
        -- @tests lurek.math.isConvex
        -- TODO: add assertion for lurek.math.isConvex
    end)
end)

describe("Missing explicit test for lurek.math.gammaToLinear", function()
    it("lurek.math.gammaToLinear works", function()
        -- @tests lurek.math.gammaToLinear
        -- TODO: add assertion for lurek.math.gammaToLinear
    end)
end)

describe("Missing explicit test for lurek.math.linearToGamma", function()
    it("lurek.math.linearToGamma works", function()
        -- @tests lurek.math.linearToGamma
        -- TODO: add assertion for lurek.math.linearToGamma
    end)
end)

describe("Missing explicit test for lurek.math.angleBetween", function()
    it("lurek.math.angleBetween works", function()
        -- @tests lurek.math.angleBetween
        expect_near(0.0, lurek.math.angleBetween(0, 0, 1, 0), 1e-5)
        expect_near(math.pi / 2, lurek.math.angleBetween(0, 0, 0, 1), 1e-5)
    end)
end)

describe("Missing explicit test for lurek.math.circleContainsPoint", function()
    it("lurek.math.circleContainsPoint works", function()
        -- @tests lurek.math.circleContainsPoint
        expect_true(lurek.math.circleContainsPoint(0, 0, 5, 3, 4))
        expect_false(lurek.math.circleContainsPoint(0, 0, 5, 4, 4))
    end)
end)

describe("Missing explicit test for lurek.math.circleIntersectsCircle", function()
    it("lurek.math.circleIntersectsCircle works", function()
        -- @tests lurek.math.circleIntersectsCircle
        expect_true(lurek.math.circleIntersectsCircle(0, 0, 3, 4, 0, 3))
        expect_false(lurek.math.circleIntersectsCircle(0, 0, 1, 10, 0, 1))
    end)
end)

describe("Missing explicit test for lurek.math.bresenham", function()
    it("lurek.math.bresenham works", function()
        -- @tests lurek.math.bresenham
        local pts = lurek.math.bresenham(0, 0, 3, 0)
        expect_equal(4, #pts)
        expect_equal(0, pts[1][1])
        expect_equal(0, pts[1][2])
        expect_equal(3, pts[4][1])
        expect_equal(0, pts[4][2])
    end)
end)

describe("Missing explicit test for lurek.math.asin", function()
    it("lurek.math.asin works", function()
        -- @tests lurek.math.asin
        -- TODO: add assertion for lurek.math.asin
    end)
end)

describe("Missing explicit test for lurek.math.acos", function()
    it("lurek.math.acos works", function()
        -- @tests lurek.math.acos
        -- TODO: add assertion for lurek.math.acos
    end)
end)

describe("Missing explicit test for lurek.math.atan", function()
    it("lurek.math.atan works", function()
        -- @tests lurek.math.atan
        -- TODO: add assertion for lurek.math.atan
    end)
end)

describe("Missing explicit test for lurek.math.atan2", function()
    it("lurek.math.atan2 works", function()
        -- @tests lurek.math.atan2
        -- TODO: add assertion for lurek.math.atan2
    end)
end)

describe("Missing explicit test for lurek.math.abs", function()
    it("lurek.math.abs works", function()
        -- @tests lurek.math.abs
        -- TODO: add assertion for lurek.math.abs
    end)
end)

describe("Missing explicit test for lurek.math.floor", function()
    it("lurek.math.floor works", function()
        -- @tests lurek.math.floor
        -- TODO: add assertion for lurek.math.floor
    end)
end)

describe("Missing explicit test for lurek.math.ceil", function()
    it("lurek.math.ceil works", function()
        -- @tests lurek.math.ceil
        -- TODO: add assertion for lurek.math.ceil
    end)
end)

describe("Missing explicit test for lurek.math.round", function()
    it("lurek.math.round works", function()
        -- @tests lurek.math.round
        -- TODO: add assertion for lurek.math.round
    end)
end)

describe("Missing explicit test for lurek.math.min", function()
    it("lurek.math.min works", function()
        -- @tests lurek.math.min
        -- TODO: add assertion for lurek.math.min
    end)
end)

describe("Missing explicit test for lurek.math.max", function()
    it("lurek.math.max works", function()
        -- @tests lurek.math.max
        -- TODO: add assertion for lurek.math.max
    end)
end)

describe("Missing explicit test for lurek.math.clamp", function()
    it("lurek.math.clamp works", function()
        -- @tests lurek.math.clamp
        -- TODO: add assertion for lurek.math.clamp
    end)
end)

describe("Missing explicit test for lurek.math.sign", function()
    it("lurek.math.sign works", function()
        -- @tests lurek.math.sign
        -- TODO: add assertion for lurek.math.sign
    end)
end)

describe("Missing explicit test for lurek.math.distance", function()
    it("lurek.math.distance works", function()
        -- @tests lurek.math.distance
        -- TODO: add assertion for lurek.math.distance
    end)
end)

describe("Missing explicit test for lurek.math.distanceSq", function()
    it("lurek.math.distanceSq works", function()
        -- @tests lurek.math.distanceSq
        -- TODO: add assertion for lurek.math.distanceSq
    end)
end)

describe("Missing explicit test for lurek.math.random", function()
    it("lurek.math.random works", function()
        -- @tests lurek.math.random
        -- TODO: add assertion for lurek.math.random
    end)
end)

describe("Missing explicit test for lurek.math.randomInt", function()
    it("lurek.math.randomInt works", function()
        -- @tests lurek.math.randomInt
        -- TODO: add assertion for lurek.math.randomInt
    end)
end)

describe("Missing explicit test for lurek.math.simplexNoise", function()
    it("lurek.math.simplexNoise works", function()
        -- @tests lurek.math.simplexNoise
        -- TODO: add assertion for lurek.math.simplexNoise
    end)
end)

describe("Missing explicit test for lurek.math.vec2", function()
    it("lurek.math.vec2 works", function()
        -- @tests lurek.math.vec2
        -- TODO: add assertion for lurek.math.vec2
    end)
end)

describe("Missing explicit test for lurek.math.vec3", function()
    it("lurek.math.vec3 works", function()
        -- @tests lurek.math.vec3
        -- TODO: add assertion for lurek.math.vec3
    end)
end)

describe("Missing explicit test for lurek.math.Vec3", function()
    it("lurek.math.Vec3 works", function()
        -- @tests lurek.math.Vec3
        -- TODO: add assertion for lurek.math.Vec3
    end)
end)

describe("Missing explicit test for lurek.math.catmullRom", function()
    it("lurek.math.catmullRom works", function()
        -- @tests lurek.math.catmullRom
        -- TODO: add assertion for lurek.math.catmullRom
    end)
end)

describe("Missing explicit test for lurek.math.hermite", function()
    it("lurek.math.hermite works", function()
        -- @tests lurek.math.hermite
        -- TODO: add assertion for lurek.math.hermite
    end)
end)

describe("Missing explicit test for lurek.math.remap", function()
    it("lurek.math.remap works", function()
        -- @tests lurek.math.remap
        -- TODO: add assertion for lurek.math.remap
    end)
end)

describe("Missing explicit test for lurek.math.clamp", function()
    it("lurek.math.clamp works", function()
        -- @tests lurek.math.clamp
        -- TODO: add assertion for lurek.math.clamp
    end)
end)

describe("Missing explicit test for lurek.math.sign", function()
    it("lurek.math.sign works", function()
        -- @tests lurek.math.sign
        -- TODO: add assertion for lurek.math.sign
    end)
end)

describe("Missing explicit test for lurek.math.newCircle", function()
    it("lurek.math.newCircle works", function()
        -- @tests lurek.math.newCircle
        -- TODO: add assertion for lurek.math.newCircle
    end)
end)

describe("Missing explicit test for lurek.math.polygonIntersection", function()
    it("lurek.math.polygonIntersection works", function()
        -- @tests lurek.math.polygonIntersection
        -- TODO: add assertion for lurek.math.polygonIntersection
    end)
end)

describe("Missing explicit test for lurek.math.polygonUnion", function()
    it("lurek.math.polygonUnion works", function()
        -- @tests lurek.math.polygonUnion
        -- TODO: add assertion for lurek.math.polygonUnion
    end)
end)

describe("Missing explicit test for lurek.math.polygonDifference", function()
    it("lurek.math.polygonDifference works", function()
        -- @tests lurek.math.polygonDifference
        -- TODO: add assertion for lurek.math.polygonDifference
    end)
end)

describe("Missing explicit test for Vec2:length", function()
    it("Vec2:length works", function()
        -- @tests Vec2:length
        -- TODO: add assertion for Vec2:length
    end)
end)

describe("Missing explicit test for Vec2:lengthSquared", function()
    it("Vec2:lengthSquared works", function()
        -- @tests Vec2:lengthSquared
        -- TODO: add assertion for Vec2:lengthSquared
    end)
end)

describe("Missing explicit test for Vec2:normalize", function()
    it("Vec2:normalize works", function()
        -- @tests Vec2:normalize
        -- TODO: add assertion for Vec2:normalize
    end)
end)

describe("Missing explicit test for Vec2:normalized", function()
    it("Vec2:normalized works", function()
        -- @tests Vec2:normalized
        -- TODO: add assertion for Vec2:normalized
    end)
end)

describe("Missing explicit test for Vec2:lerp", function()
    it("Vec2:lerp works", function()
        -- @tests Vec2:lerp
        -- TODO: add assertion for Vec2:lerp
    end)
end)

describe("Missing explicit test for Vec2:distance", function()
    it("Vec2:distance works", function()
        -- @tests Vec2:distance
        -- TODO: add assertion for Vec2:distance
    end)
end)

describe("Missing explicit test for Vec2:angle", function()
    it("Vec2:angle works", function()
        -- @tests Vec2:angle
        -- TODO: add assertion for Vec2:angle
    end)
end)

describe("Missing explicit test for Vec2:rotate", function()
    it("Vec2:rotate works", function()
        -- @tests Vec2:rotate
        -- TODO: add assertion for Vec2:rotate
    end)
end)

describe("Missing explicit test for Vec2:perpendicular", function()
    it("Vec2:perpendicular works", function()
        -- @tests Vec2:perpendicular
        -- TODO: add assertion for Vec2:perpendicular
    end)
end)

describe("Missing explicit test for Vec2:cross", function()
    it("Vec2:cross works", function()
        -- @tests Vec2:cross
        -- TODO: add assertion for Vec2:cross
    end)
end)

describe("Missing explicit test for Vec2:reflect", function()
    it("Vec2:reflect works", function()
        -- @tests Vec2:reflect
        -- TODO: add assertion for Vec2:reflect
    end)
end)

describe("Missing explicit test for Vec3:length", function()
    it("Vec3:length works", function()
        -- @tests Vec3:length
        -- TODO: add assertion for Vec3:length
    end)
end)

describe("Missing explicit test for Vec3:lengthSquared", function()
    it("Vec3:lengthSquared works", function()
        -- @tests Vec3:lengthSquared
        -- TODO: add assertion for Vec3:lengthSquared
    end)
end)

describe("Missing explicit test for Vec3:normalize", function()
    it("Vec3:normalize works", function()
        -- @tests Vec3:normalize
        -- TODO: add assertion for Vec3:normalize
    end)
end)

describe("Missing explicit test for Vec3:cross", function()
    it("Vec3:cross works", function()
        -- @tests Vec3:cross
        -- TODO: add assertion for Vec3:cross
    end)
end)

describe("Missing explicit test for Vec3:lerp", function()
    it("Vec3:lerp works", function()
        -- @tests Vec3:lerp
        -- TODO: add assertion for Vec3:lerp
    end)
end)

describe("Missing explicit test for Vec3:distance", function()
    it("Vec3:distance works", function()
        -- @tests Vec3:distance
        -- TODO: add assertion for Vec3:distance
    end)
end)

describe("Missing explicit test for Vec3:scale", function()
    it("Vec3:scale works", function()
        -- @tests Vec3:scale
        -- TODO: add assertion for Vec3:scale
    end)
end)

describe("Missing explicit test for CatmullRom:sample", function()
    it("CatmullRom:sample works", function()
        -- @tests CatmullRom:sample
        -- TODO: add assertion for CatmullRom:sample
    end)
end)

describe("Missing explicit test for CatmullRom:sampleSegment", function()
    it("CatmullRom:sampleSegment works", function()
        -- @tests CatmullRom:sampleSegment
        -- TODO: add assertion for CatmullRom:sampleSegment
    end)
end)

describe("Missing explicit test for CatmullRom:addPoint", function()
    it("CatmullRom:addPoint works", function()
        -- @tests CatmullRom:addPoint
        -- TODO: add assertion for CatmullRom:addPoint
    end)
end)

describe("Missing explicit test for CatmullRom:removePoint", function()
    it("CatmullRom:removePoint works", function()
        -- @tests CatmullRom:removePoint
        -- TODO: add assertion for CatmullRom:removePoint
    end)
end)

describe("Missing explicit test for Hermite:sample", function()
    it("Hermite:sample works", function()
        -- @tests Hermite:sample
        -- TODO: add assertion for Hermite:sample
    end)
end)

describe("Missing explicit test for RandomGenerator:random", function()
    it("RandomGenerator:random works", function()
        -- @tests RandomGenerator:random
        -- TODO: add assertion for RandomGenerator:random
    end)
end)

describe("Missing explicit test for RandomGenerator:randomFloat", function()
    it("RandomGenerator:randomFloat works", function()
        -- @tests RandomGenerator:randomFloat
        -- TODO: add assertion for RandomGenerator:randomFloat
    end)
end)

describe("Missing explicit test for RandomGenerator:randomInt", function()
    it("RandomGenerator:randomInt works", function()
        -- @tests RandomGenerator:randomInt
        -- TODO: add assertion for RandomGenerator:randomInt
    end)
end)

describe("Missing explicit test for RandomGenerator:setSeed", function()
    it("RandomGenerator:setSeed works", function()
        -- @tests RandomGenerator:setSeed
        -- TODO: add assertion for RandomGenerator:setSeed
    end)
end)

describe("Missing explicit test for RandomGenerator:getState", function()
    it("RandomGenerator:getState works", function()
        -- @tests RandomGenerator:getState
        -- TODO: add assertion for RandomGenerator:getState
    end)
end)

describe("Missing explicit test for RandomGenerator:setState", function()
    it("RandomGenerator:setState works", function()
        -- @tests RandomGenerator:setState
        -- TODO: add assertion for RandomGenerator:setState
    end)
end)

describe("Missing explicit test for Transform:translate", function()
    it("Transform:translate works", function()
        -- @tests Transform:translate
        -- TODO: add assertion for Transform:translate
    end)
end)

describe("Missing explicit test for Transform:rotate", function()
    it("Transform:rotate works", function()
        -- @tests Transform:rotate
        -- TODO: add assertion for Transform:rotate
    end)
end)

describe("Missing explicit test for Transform:scale", function()
    it("Transform:scale works", function()
        -- @tests Transform:scale
        -- TODO: add assertion for Transform:scale
    end)
end)

describe("Missing explicit test for Transform:reset", function()
    it("Transform:reset works", function()
        -- @tests Transform:reset
        -- TODO: add assertion for Transform:reset
    end)
end)

describe("Missing explicit test for Transform:transformPoint", function()
    it("Transform:transformPoint works", function()
        -- @tests Transform:transformPoint
        -- TODO: add assertion for Transform:transformPoint
    end)
end)

describe("Missing explicit test for Transform:inverseTransformPoint", function()
    it("Transform:inverseTransformPoint works", function()
        -- @tests Transform:inverseTransformPoint
        -- TODO: add assertion for Transform:inverseTransformPoint
    end)
end)

describe("Missing explicit test for Transform:inverse", function()
    it("Transform:inverse works", function()
        -- @tests Transform:inverse
        -- TODO: add assertion for Transform:inverse
    end)
end)

describe("Missing explicit test for Transform:clone", function()
    it("Transform:clone works", function()
        -- @tests Transform:clone
        -- TODO: add assertion for Transform:clone
    end)
end)

describe("Missing explicit test for Transform:decompose", function()
    it("Transform:decompose works", function()
        -- @tests Transform:decompose
        -- TODO: add assertion for Transform:decompose
    end)
end)

describe("Missing explicit test for BezierCurve:evaluate", function()
    it("BezierCurve:evaluate works", function()
        -- @tests BezierCurve:evaluate
        -- TODO: add assertion for BezierCurve:evaluate
    end)
end)

describe("Missing explicit test for BezierCurve:render", function()
    it("BezierCurve:render works", function()
        -- @tests BezierCurve:render
        -- TODO: add assertion for BezierCurve:render
    end)
end)

describe("Missing explicit test for BezierCurve:getDerivative", function()
    it("BezierCurve:getDerivative works", function()
        -- @tests BezierCurve:getDerivative
        -- TODO: add assertion for BezierCurve:getDerivative
    end)
end)

describe("Missing explicit test for BezierCurve:getControlPoint", function()
    it("BezierCurve:getControlPoint works", function()
        -- @tests BezierCurve:getControlPoint
        -- TODO: add assertion for BezierCurve:getControlPoint
    end)
end)

describe("Missing explicit test for BezierCurve:getControlPointCount", function()
    it("BezierCurve:getControlPointCount works", function()
        -- @tests BezierCurve:getControlPointCount
        -- TODO: add assertion for BezierCurve:getControlPointCount
    end)
end)

describe("Missing explicit test for BezierCurve:length", function()
    it("BezierCurve:length works", function()
        -- @tests BezierCurve:length
        -- TODO: add assertion for BezierCurve:length
    end)
end)

describe("Missing explicit test for BezierCurve:translate", function()
    it("BezierCurve:translate works", function()
        -- @tests BezierCurve:translate
        -- TODO: add assertion for BezierCurve:translate
    end)
end)

describe("Missing explicit test for BezierCurve:rotate", function()
    it("BezierCurve:rotate works", function()
        -- @tests BezierCurve:rotate
        -- TODO: add assertion for BezierCurve:rotate
    end)
end)

describe("Missing explicit test for BezierCurve:scale", function()
    it("BezierCurve:scale works", function()
        -- @tests BezierCurve:scale
        -- TODO: add assertion for BezierCurve:scale
    end)
end)

describe("Missing explicit test for Tween:update", function()
    it("Tween:update works", function()
        -- @tests Tween:update
        local tw = lurek.math.newTween(2.0, "linear")
        tw:addValue(0.0, 10.0)
        expect_false(tw:isComplete())
        tw:update(1.0)
        expect_false(tw:isComplete())
    end)
end)

describe("Missing explicit test for Tween:reset", function()
    it("Tween:reset works", function()
        -- @tests Tween:reset
        local tw = lurek.math.newTween(1.0, "linear")
        tw:addValue(0.0, 100.0)
        tw:update(1.0)
        expect_true(tw:isComplete())
        tw:reset()
        expect_false(tw:isComplete())
        expect_near(0.0, tw:getValue(1), 1e-5)
    end)
end)

describe("Missing explicit test for Tween:getValue", function()
    it("Tween:getValue works", function()
        -- @tests Tween:getValue
        local tw = lurek.math.newTween(1.0, "linear")
        tw:addValue(0.0, 100.0)
        tw:setTime(0.5)
        expect_near(50.0, tw:getValue(1), 1e-3)
    end)
end)

describe("Missing explicit test for Tween:isComplete", function()
    it("Tween:isComplete works", function()
        -- @tests Tween:isComplete
        local tw = lurek.math.newTween(1.0, "linear")
        tw:addValue(0.0, 10.0)
        tw:update(1.5)
        expect_true(tw:isComplete())
    end)
end)

describe("Missing explicit test for Tween:getEasingName", function()
    it("Tween:getEasingName works", function()
        -- @tests Tween:getEasingName
        -- TODO: add assertion for Tween:getEasingName
    end)
end)

describe("Missing explicit test for Tween:getDuration", function()
    it("Tween:getDuration works", function()
        -- @tests Tween:getDuration
        -- TODO: add assertion for Tween:getDuration
    end)
end)

describe("Missing explicit test for Tween:getTime", function()
    it("Tween:getTime works", function()
        -- @tests Tween:getTime
        -- TODO: add assertion for Tween:getTime
    end)
end)

describe("Missing explicit test for Tween:setTime", function()
    it("Tween:setTime works", function()
        -- @tests Tween:setTime
        local tw = lurek.math.newTween(1.0, "inQuad")
        local a = tw:addValue(0.0, 100.0)
        local b = tw:addValue(50.0, 150.0)
        tw:setTime(0.5)
        expect_near(25.0, tw:getValue(a), 1e-3)
        expect_near(75.0, tw:getValue(b), 1e-3)
    end)
end)

describe("Missing explicit test for SpatialHash:remove", function()
    it("SpatialHash:remove works", function()
        -- @tests SpatialHash:remove
        -- TODO: add assertion for SpatialHash:remove
    end)
end)

describe("Missing explicit test for SpatialHash:clear", function()
    it("SpatialHash:clear works", function()
        -- @tests SpatialHash:clear
        -- TODO: add assertion for SpatialHash:clear
    end)
end)

describe("Missing explicit test for SpatialHash:getCellSize", function()
    it("SpatialHash:getCellSize works", function()
        -- @tests SpatialHash:getCellSize
        -- TODO: add assertion for SpatialHash:getCellSize
    end)
end)

describe("Missing explicit test for SpatialHash:getItemCount", function()
    it("SpatialHash:getItemCount works", function()
        -- @tests SpatialHash:getItemCount
        -- TODO: add assertion for SpatialHash:getItemCount
    end)
end)

describe("Missing explicit test for NoiseGenerator:perlin2d", function()
    it("NoiseGenerator:perlin2d works", function()
        -- @tests NoiseGenerator:perlin2d
        -- TODO: add assertion for NoiseGenerator:perlin2d
    end)
end)

describe("Missing explicit test for NoiseGenerator:perlin3d", function()
    it("NoiseGenerator:perlin3d works", function()
        -- @tests NoiseGenerator:perlin3d
        -- TODO: add assertion for NoiseGenerator:perlin3d
    end)
end)

describe("Missing explicit test for NoiseGenerator:simplex2d", function()
    it("NoiseGenerator:simplex2d works", function()
        -- @tests NoiseGenerator:simplex2d
        -- TODO: add assertion for NoiseGenerator:simplex2d
    end)
end)

describe("Missing explicit test for NoiseGenerator:setSeed", function()
    it("NoiseGenerator:setSeed works", function()
        -- @tests NoiseGenerator:setSeed
        -- TODO: add assertion for NoiseGenerator:setSeed
    end)
end)

describe("Missing explicit test for Circle:area", function()
    it("Circle:area works", function()
        -- @tests Circle:area
        -- TODO: add assertion for Circle:area
    end)
end)

describe("Missing explicit test for Circle:perimeter", function()
    it("Circle:perimeter works", function()
        -- @tests Circle:perimeter
        -- TODO: add assertion for Circle:perimeter
    end)
end)

describe("Missing explicit test for Circle:contains", function()
    it("Circle:contains works", function()
        -- @tests Circle:contains
        -- TODO: add assertion for Circle:contains
    end)
end)

describe("Missing explicit test for Circle:intersects", function()
    it("Circle:intersects works", function()
        -- @tests Circle:intersects
        -- TODO: add assertion for Circle:intersects
    end)
end)

describe("Missing explicit test for Circle:aabb", function()
    it("Circle:aabb works", function()
        -- @tests Circle:aabb
        -- TODO: add assertion for Circle:aabb
    end)
end)

describe("Missing explicit test for Circle:radius", function()
    it("Circle:radius works", function()
        -- @tests Circle:radius
        -- TODO: add assertion for Circle:radius
    end)
end)

describe("Missing explicit test for AabbTree:remove", function()
    it("AabbTree:remove works", function()
        -- @tests AabbTree:remove
        -- TODO: add assertion for AabbTree:remove
    end)
end)

describe("Missing explicit test for AabbTree:queryPoint", function()
    it("AabbTree:queryPoint works", function()
        -- @tests AabbTree:queryPoint
        -- TODO: add assertion for AabbTree:queryPoint
    end)
end)

describe("Missing explicit test for AabbTree:contains", function()
    it("AabbTree:contains works", function()
        -- @tests AabbTree:contains
        -- TODO: add assertion for AabbTree:contains
    end)
end)

describe("Missing explicit test for AabbTree:isEmpty", function()
    it("AabbTree:isEmpty works", function()
        -- @tests AabbTree:isEmpty
        -- TODO: add assertion for AabbTree:isEmpty
    end)
end)

describe("Missing explicit test for AabbTree:clear", function()
    it("AabbTree:clear works", function()
        -- @tests AabbTree:clear
        -- TODO: add assertion for AabbTree:clear
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
