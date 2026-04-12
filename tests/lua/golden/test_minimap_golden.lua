-- Golden test: minimap
-- @golden

describe("golden: minimap evidence comparison", function()
    local OUT = evidence_output_dir("minimap")
    local SAMP = "tests/lua/golden/samples/minimap/"

    it("matches golden samples", function()
            expect_golden_file_match(evidence_output_dir("minimap") .. "terrain.png", "tests/lua/golden/samples/minimap/terrain.png")
        expect_golden_file_match(evidence_output_dir("minimap") .. "fog_of_war.png", "tests/lua/golden/samples/minimap/fog_of_war.png")
        expect_golden_file_match(evidence_output_dir("minimap") .. "objects_markers.png", "tests/lua/golden/samples/minimap/objects_markers.png")
        expect_golden_file_match(evidence_output_dir("minimap") .. "political_mode.png", "tests/lua/golden/samples/minimap/political_mode.png")
end)
end)

test_summary()
