-- Lurek2D Property-Based Test: Math Module
-- Tests mathematical invariants that must hold for ALL inputs
-- @covers lurek.math.sin
-- @covers lurek.math.cos

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

    it("sin(-x) = -sin(x) for 100 values (odd function)", function()
        local angles = test_values(100, -10, 10)
        for i, x in ipairs(angles) do
            local pos = lurek.math.sin(x)
            local neg = lurek.math.sin(-x)
            expect_near(-pos, neg, 1e-10,
                "sin is odd at x=" .. string.format("%.4f", x))
        end
    end)

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
    it("sqrt(x)^2 = x for 100 positive values", function()
        local vals = test_values(100, 0.001, 10000)
        for i, x in ipairs(vals) do
            local root = lurek.math.sqrt(x)
            expect_near(x, root * root, x * 1e-10 + 1e-10,
                "sqrt round-trip at x=" .. string.format("%.4f", x))
        end
    end)

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

    it("vec2 length is non-negative for 100 values", function()
        local vals = test_values(200, -1000, 1000)
        for i = 1, 100 do
            local v = lurek.math.Vec2(vals[i], vals[i + 100])
            local len = v:length()
            expect_true(len >= 0,
                "length >= 0 for (" .. vals[i] .. "," .. vals[i+100] .. ")")
        end
    end)

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
    it("lerp(a, b, 0) = a and lerp(a, b, 1) = b", function()
        local vals = test_values(100, -1000, 1000)
        for i = 1, 50 do
            local a = vals[i]
            local b = vals[i + 50]
            local at0 = lurek.math.lerp(a, b, 0)
            local at1 = lurek.math.lerp(a, b, 1)
            expect_near(a, at0, 1e-10, "lerp(a,b,0) = a")
            expect_near(b, at1, 1e-10, "lerp(a,b,1) = b")
        end
    end)

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

test_summary()
