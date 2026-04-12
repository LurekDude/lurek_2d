-- Golden test: graph — compare evidence output against golden samples
-- @golden

describe("golden: graph evidence comparison", function()
    it("matches golden sample for graph_traversal.png", function()
        local evidence = evidence_output_dir("graph") .. "graph_traversal.png"
        local golden = "tests/lua/golden/samples/graph/graph_traversal.png"
        expect_golden_file_match(evidence, golden)
    end)
end)

test_summary()
