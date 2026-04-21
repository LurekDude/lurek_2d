-- Golden test: pathfinding â€” compare evidence output against golden samples

-- @description Covers suite: golden: pathfinding evidence comparison.
describe("golden: pathfinding evidence comparison", function()
    -- @golden
    -- @covers expect_golden_file_match
    -- @description Compares the generated pathfinding_grid.png evidence image against the committed pathfinding golden sample.
    it("matches golden sample for pathfinding_grid.png", function()
        local evidence = evidence_output_dir("pathfinding") .. "pathfinding_grid.png"
        local golden = "tests/lua/golden/samples/pathfinding/pathfinding_grid.png"
        expect_golden_file_match(evidence, golden)
    end)
end)
test_summary()
