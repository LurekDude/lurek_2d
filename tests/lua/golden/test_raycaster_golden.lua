-- Golden test: raycaster

describe("golden: raycaster evidence comparison", function()
    local OUT = evidence_output_dir("raycaster")
    local SAMP = "tests/samples/raycaster/"

    it("matches golden samples", function()
        expect_golden_file_match(evidence_output_dir("raycaster") .. "top_down_view.png", "tests/samples/raycaster/top_down_view.png")
        expect_golden_file_match(evidence_output_dir("raycaster") .. "depth_column_view.png", "tests/samples/raycaster/depth_column_view.png")
        expect_golden_file_match(evidence_output_dir("raycaster") .. "line_of_sight.png", "tests/samples/raycaster/line_of_sight.png")
end)
end)
test_summary()
