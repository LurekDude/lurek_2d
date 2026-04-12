-- Golden test: math — deterministic text output comparison
-- @golden
-- @covers lurek.math.pi
-- @covers lurek.math.sin
-- @covers lurek.math.cos
-- @covers lurek.math.exp
-- @covers lurek.math.sqrt
-- @covers lurek.math.rad

describe("golden: math Math constants and trig identities", function()
    it("produces deterministic text output", function()

        local output = {}
        output[#output + 1] = "pi=" .. string.format("%.15f", lurek.math.pi)
        output[#output + 1] = "e=" .. string.format("%.15f", lurek.math.exp(1))
        output[#output + 1] = "sqrt2=" .. string.format("%.15f", lurek.math.sqrt(2))
        for deg = 0, 360, 45 do
            local rad = lurek.math.rad(deg)
            local s = lurek.math.sin(rad)
            local c = lurek.math.cos(rad)
            output[#output + 1] = string.format("deg=%d sin=%.10f cos=%.10f", deg, s, c)
        end
        local text = table.concat(output, "\n") .. "\n"

        local path = evidence_output_dir("math") .. "math_golden.txt"
        ensure_evidence_dir("math")
        local f = io.open(path, "w")
        if f then f:write(text); f:close() end
        expect_evidence_created(path)
    end)

    it("matches golden sample", function()
        local evidence = evidence_output_dir("math") .. "math_golden.txt"
        local golden = "tests/lua/golden/samples/math/math_golden.txt"
        expect_golden_text_match(evidence, golden)
    end)
end)

test_summary()
