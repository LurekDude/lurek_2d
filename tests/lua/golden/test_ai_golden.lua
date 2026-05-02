-- Golden test: ai compare-only evidence validation.

describe("golden: ai AI state machine transitions", function()
    it("matches golden sample", function()
        local evidence = "save/golden_text/ai/ai_golden.txt"
        local golden = "tests/samples/ai/ai_golden.txt"
        expect_golden_text_match(evidence, golden)
    end)
end)
test_summary()
