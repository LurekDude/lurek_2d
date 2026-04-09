-- Lurek2D Golden File Test: Math Constants
-- Generates deterministic math output for golden file comparison

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
