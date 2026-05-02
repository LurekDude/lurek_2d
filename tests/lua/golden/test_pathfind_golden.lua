-- Golden test: pathfind

describe("golden: pathfind evidence comparison", function()
    local OUT = evidence_output_dir("pathfind")
    local SAMP = "tests/samples/pathfind/"

    it("matches golden samples", function()
        expect_golden_file_match(evidence_output_dir("pathfind") .. "astar_basic.png", "tests/samples/pathfind/astar_basic.png")
        expect_golden_file_match(evidence_output_dir("pathfind") .. "navgrid_costs.png", "tests/samples/pathfind/navgrid_costs.png")
        expect_golden_file_match(evidence_output_dir("pathfind") .. "flow_field.png", "tests/samples/pathfind/flow_field.png")
        expect_golden_file_match(evidence_output_dir("pathfind") .. "influence_map.png", "tests/samples/pathfind/influence_map.png")
end)
end)



-- ================================================================
-- Merged from: test_pathfind_golden_grid.lua
-- ================================================================

-- Golden test: pathfinding          compare evidence output against golden samples

describe("golden: pathfinding evidence comparison", function()
    it("matches golden sample for pathfinding_grid.png", function()
        local evidence = evidence_output_dir("pathfind") .. "pathfinding_grid.png"
        local golden = "tests/samples/pathfinding/pathfinding_grid.png"
        expect_golden_file_match(evidence, golden)
    end)
end)
test_summary()
