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

test_summary()
