-- Luna2D Math API Tests

describe("luna.math constants", function()
    it("has pi", function()
        expect_not_nil(luna.math.pi, "pi exists")
        expect_near(3.14159265358979, luna.math.pi, 0.0001, "pi value")
    end)
end)

describe("luna.math trigonometry", function()
    it("sin(0) = 0", function()
        expect_near(0, luna.math.sin(0), 0.0001)
    end)

    it("sin(pi/2) = 1", function()
        expect_near(1, luna.math.sin(luna.math.pi / 2), 0.0001)
    end)

    it("cos(0) = 1", function()
        expect_near(1, luna.math.cos(0), 0.0001)
    end)

    it("cos(pi) = -1", function()
        expect_near(-1, luna.math.cos(luna.math.pi), 0.0001)
    end)

    it("tan(0) = 0", function()
        expect_near(0, luna.math.tan(0), 0.0001)
    end)

    it("atan2(1, 0) = pi/2", function()
        expect_near(luna.math.pi / 2, luna.math.atan2(1, 0), 0.0001)
    end)

    it("atan2(0, 1) = 0", function()
        expect_near(0, luna.math.atan2(0, 1), 0.0001)
    end)
end)

describe("luna.math basic functions", function()
    it("sqrt(4) = 2", function()
        expect_near(2, luna.math.sqrt(4), 0.0001)
    end)

    it("sqrt(9) = 3", function()
        expect_near(3, luna.math.sqrt(9), 0.0001)
    end)

    it("abs(-5) = 5", function()
        expect_near(5, luna.math.abs(-5), 0.0001)
    end)

    it("abs(5) = 5", function()
        expect_near(5, luna.math.abs(5), 0.0001)
    end)

    it("floor(3.7) = 3", function()
        expect_equal(3, luna.math.floor(3.7))
    end)

    it("floor(-2.1) = -3", function()
        expect_equal(-3, luna.math.floor(-2.1))
    end)

    it("ceil(3.2) = 4", function()
        expect_equal(4, luna.math.ceil(3.2))
    end)

    it("ceil(-2.9) = -2", function()
        expect_equal(-2, luna.math.ceil(-2.9))
    end)
end)

describe("luna.math min/max/clamp", function()
    it("min(3, 7) = 3", function()
        expect_equal(3, luna.math.min(3, 7))
    end)

    it("min(-1, 1) = -1", function()
        expect_equal(-1, luna.math.min(-1, 1))
    end)

    it("max(3, 7) = 7", function()
        expect_equal(7, luna.math.max(3, 7))
    end)

    it("clamp(5, 0, 10) = 5", function()
        expect_equal(5, luna.math.clamp(5, 0, 10))
    end)

    it("clamp(-5, 0, 10) = 0", function()
        expect_equal(0, luna.math.clamp(-5, 0, 10))
    end)

    it("clamp(15, 0, 10) = 10", function()
        expect_equal(10, luna.math.clamp(15, 0, 10))
    end)
end)

describe("luna.math.distance", function()
    it("distance(0,0,3,4) = 5", function()
        expect_near(5, luna.math.distance(0, 0, 3, 4), 0.0001)
    end)

    it("distance(1,1,1,1) = 0", function()
        expect_near(0, luna.math.distance(1, 1, 1, 1), 0.0001)
    end)

    it("distance(0,0,1,0) = 1", function()
        expect_near(1, luna.math.distance(0, 0, 1, 0), 0.0001)
    end)
end)

describe("luna.math.random", function()
    it("returns a number", function()
        local val = luna.math.random()
        expect_type("number", val)
    end)

    it("no-arg returns value in [0, 1)", function()
        for i = 1, 20 do
            local val = luna.math.random()
            expect_true(val >= 0 and val < 1, "random() in [0,1)")
        end
    end)

    it("with max returns value in [0, max)", function()
        for i = 1, 20 do
            local val = luna.math.random(10)
            expect_true(val >= 0 and val <= 10, "random(10) in [0,10]")
        end
    end)

    it("with min,max returns value in [min, max)", function()
        for i = 1, 20 do
            local val = luna.math.random(5, 15)
            expect_true(val >= 5 and val <= 15, "random(5,15) in [5,15]")
        end
    end)
end)

test_summary()
