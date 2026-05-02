-- Golden test: compute compare-only evidence validation.

describe("golden: compute NdArray deterministic operations", function()
    it("matches golden sample", function()
        local evidence = "save/golden_text/compute/compute_golden.txt"
        local golden = "tests/samples/compute/compute_golden.txt"
        expect_golden_text_match(evidence, golden)
    end)
end)
test_summary()
