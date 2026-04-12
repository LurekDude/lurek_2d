-- Golden test: compute — deterministic text output comparison
-- @golden
-- @covers lurek.compute.zeros
-- @covers NdArray:fill
-- @covers NdArray:sum

describe("golden: compute NdArray deterministic operations", function()
    it("produces deterministic text output", function()

        local output = {}
        local arr = lurek.compute.zeros(2, 3)
        arr:fill(1.5)
        output[#output + 1] = "shape=2x3"
        output[#output + 1] = "fill_value=1.500000"
        output[#output + 1] = "sum=" .. string.format("%.6f", arr:sum())
        local text = table.concat(output, "\n") .. "\n"

        local path = evidence_output_dir("compute") .. "compute_golden.txt"
        ensure_evidence_dir("compute")
        local f = io.open(path, "w")
        if f then f:write(text); f:close() end
        expect_evidence_created(path)
    end)

    it("matches golden sample", function()
        local evidence = evidence_output_dir("compute") .. "compute_golden.txt"
        local golden = "tests/lua/golden/samples/compute/compute_golden.txt"
        expect_golden_text_match(evidence, golden)
    end)
end)

test_summary()
