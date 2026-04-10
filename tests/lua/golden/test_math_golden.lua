-- Lurek2D Golden File Test: Math Constants, Vectors, and Operations
-- Generates deterministic math output for golden file comparison
-- @golden lurek.math.cos
-- @golden lurek.math.exp
-- @golden lurek.math.pi
-- @golden lurek.math.rad
-- @golden lurek.math.sin
-- @golden lurek.math.sqrt
-- @golden lurek.math.lerp
-- @golden lurek.math.Vec2


local aa = lurek.graphics.newCanvas(1, 1)
aa.

describe("golden: math constants", function()
    it("generates constant table", function()
        local output = {}
        output[#output + 1] = "pi=" .. string.format("%.15f", lurek.math.pi)
        output[#output + 1] = "e=" .. string.format("%.15f", lurek.math.exp(1))
        output[#output + 1] = "sqrt2=" .. string.format("%.15f", lurek.math.sqrt(2))

        -- Trig identity: sin^2 + cos^2 = 1
        for deg = 0, 360, 15 do
            local rad = lurek.math.rad(deg)
            local s = lurek.math.sin(rad)
            local c = lurek.math.cos(rad)
            local identity = s * s + c * c
            output[#output + 1] = string.format("deg=%d sin2+cos2=%.10f", deg, identity)
        end

        -- This would write to tests/golden/actual/math_constants.txt
        -- For now, just verify the identities hold
        for deg = 0, 360, 15 do
            local rad = lurek.math.rad(deg)
            local s = lurek.math.sin(rad)
            local c = lurek.math.cos(rad)
            expect_near(1.0, s * s + c * c, 1e-10, "sin^2+cos^2=1 at " .. deg .. " deg")
        end
    end)
end)

describe("golden: math constants exact values", function()
    it("pi matches IEEE 754 double precision", function()
        expect_near(3.141592653589793, lurek.math.pi, 1e-12, "pi exact")
    end)

    it("e (exp(1)) matches IEEE 754 double precision", function()
        expect_near(2.718281828459045, lurek.math.exp(1), 1e-12, "e exact")
    end)

    it("sqrt(2) matches IEEE 754 double precision", function()
        expect_near(1.4142135623730951, lurek.math.sqrt(2), 1e-12, "sqrt2 exact")
    end)

    it("sqrt(4) == 2.0 exactly", function()
        expect_near(2.0, lurek.math.sqrt(4), 1e-15, "sqrt(4) = 2")
    end)
end)

describe("golden: math lerp determinism", function()
    it("lerp(0, 100, 0.0) == 0", function()
        expect_near(0.0, lurek.math.lerp(0, 100, 0.0), 1e-10, "lerp at t=0")
    end)

    it("lerp(0, 100, 0.25) == 25", function()
        expect_near(25.0, lurek.math.lerp(0, 100, 0.25), 1e-10, "lerp at t=0.25")
    end)

    it("lerp(0, 100, 0.5) == 50", function()
        expect_near(50.0, lurek.math.lerp(0, 100, 0.5), 1e-10, "lerp at t=0.5")
    end)

    it("lerp(0, 100, 1.0) == 100", function()
        expect_near(100.0, lurek.math.lerp(0, 100, 1.0), 1e-10, "lerp at t=1")
    end)

    it("lerp(-50, 50, 0.5) == 0", function()
        expect_near(0.0, lurek.math.lerp(-50, 50, 0.5), 1e-10, "lerp symmetric")
    end)
end)

describe("golden: Vec2 operations deterministic", function()
    it("Vec2(3,4) length == 5.0", function()
        local v = lurek.math.Vec2(3, 4)
        expect_near(5.0, v:length(), 1e-10, "Pythagorean 3-4-5 triangle")
    end)

    it("Vec2 dot product (1,2)·(3,4) == 11", function()
        local a = lurek.math.Vec2(1, 2)
        local b = lurek.math.Vec2(3, 4)
        expect_near(11.0, a:dot(b), 1e-10, "dot product = 1*3 + 2*4 = 11")
    end)

    it("Vec2(3,4) normalized == (0.6, 0.8)", function()
        local v = lurek.math.Vec2(3, 4)
        local n = v:normalize()
        expect_near(0.6, n.x, 1e-10, "normalized x = 0.6")
        expect_near(0.8, n.y, 1e-10, "normalized y = 0.8")
    end)

    it("Vec2 add component-wise", function()
        local a = lurek.math.Vec2(1, 2)
        local b = lurek.math.Vec2(3, 4)
        local c = a + b
        expect_near(4.0, c.x, 1e-10, "add x = 4")
        expect_near(6.0, c.y, 1e-10, "add y = 6")
    end)

    it("Vec2 scale by scalar", function()
        local v = lurek.math.Vec2(3, 5)
        local s = v * 2
        expect_near(6.0, s.x, 1e-10, "scale x = 6")
        expect_near(10.0, s.y, 1e-10, "scale y = 10")
    end)
end)

test_summary()

