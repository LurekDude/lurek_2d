-- Golden test: minimap

describe("golden: minimap evidence comparison", function()
    local OUT = evidence_output_dir("minimap")
    local SAMP = "tests/samples/minimap/"

    it("matches golden samples", function()
        expect_golden_file_match(evidence_output_dir("minimap") .. "terrain.png", "tests/samples/minimap/terrain.png")
        expect_golden_file_match(evidence_output_dir("minimap") .. "fog_of_war.png", "tests/samples/minimap/fog_of_war.png")
        expect_golden_file_match(evidence_output_dir("minimap") .. "objects_markers.png", "tests/samples/minimap/objects_markers.png")
        expect_golden_file_match(evidence_output_dir("minimap") .. "political_mode.png", "tests/samples/minimap/political_mode.png")
end)
end)
test_summary()
