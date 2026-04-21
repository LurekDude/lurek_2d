-- Golden test: entity compare-only evidence validation.

-- @description Compares entity_golden.txt emitted by the evidence layer against the committed deterministic entity sample.
describe("golden: entity Entity creation and component state", function()
    -- @golden
    -- @description Compares entity_golden.txt from the evidence layer against the committed entity sample.
    it("matches golden sample", function()
        local evidence = "save/golden_text/entity/entity_golden.txt"
        local golden = "tests/lua/golden/samples/entity/entity_golden.txt"
        expect_golden_text_match(evidence, golden)
    end)
end)
test_summary()
