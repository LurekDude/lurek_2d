-- Golden test: dataframe compare-only evidence validation.

describe("golden: dataframe DataFrame deterministic statistics", function()
    it("matches golden sample", function()
        local evidence = "save/golden_text/dataframe/dataframe_golden.txt"
        local golden = "tests/samples/dataframe/dataframe_golden.txt"
        expect_golden_text_match(evidence, golden)
    end)
end)
test_summary()
