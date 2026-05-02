-- Golden test: entity compare-only evidence validation.

describe("golden: entity Entity creation and component state", function()
    it("matches golden sample", function()
        local evidence = "save/golden_text/ecs/entity_golden.txt"
        local golden = "tests/samples/entity/entity_golden.txt"
        expect_golden_text_match(evidence, golden)
    end)
end)
test_summary()
