-- Golden test: tilemap — compare evidence output against golden samples
-- @golden

describe("golden: tilemap evidence comparison", function()
    it("matches golden sample for tilemap_render.png", function()
        local evidence = evidence_output_dir("tilemap") .. "tilemap_render.png"
        local golden = "tests/lua/golden/samples/tilemap/tilemap_render.png"
        expect_golden_file_match(evidence, golden)
            expect_golden_file_match(evidence_output_dir("tilemap") .. "world_to_tile.png", "tests/lua/golden/samples/tilemap/world_to_tile.png")
end)
end)

test_summary()
