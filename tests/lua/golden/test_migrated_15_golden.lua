-- Golden test: migrated 15
-- @golden

describe("golden: migrated 15 evidence comparison", function()
    local OUT = evidence_output_dir("migrated_15")
    local SAMP = "tests/lua/golden/samples/migrated_15/"

    it("matches golden samples", function()
        expect_golden_file_match(OUT .. "new_blank_64x64.png", SAMP .. "new_blank_64x64.png")
        expect_golden_file_match(OUT .. "fill_orange.png", SAMP .. "fill_orange.png")
        expect_golden_file_match(OUT .. "diagonal_cross.png", SAMP .. "diagonal_cross.png")
        expect_golden_file_match(OUT .. "shapes_combined_scene.png", SAMP .. "shapes_combined_scene.png")
        expect_golden_file_match(OUT .. "paste_composite.png", SAMP .. "paste_composite.png")
        expect_golden_file_match(OUT .. "noise_after.png", SAMP .. "noise_after.png")
        expect_golden_file_match(OUT .. "flip_h_after.png", SAMP .. "flip_h_after.png")
        expect_golden_file_match(OUT .. "flip_v_after.png", SAMP .. "flip_v_after.png")
        expect_golden_file_match(OUT .. "rotate_90cw.png", SAMP .. "rotate_90cw.png")
        expect_golden_file_match(OUT .. "crop_center.png", SAMP .. "crop_center.png")
        expect_golden_file_match(OUT .. "resize_upscaled_128.png", SAMP .. "resize_upscaled_128.png")
        expect_golden_file_match(OUT .. "alpha_mask_50pct.png", SAMP .. "alpha_mask_50pct.png")
        expect_golden_file_match(OUT .. "pipeline_05_blur.png", SAMP .. "pipeline_05_blur.png")
        expect_golden_file_match(OUT .. "noise_terrain_map.png", SAMP .. "noise_terrain_map.png")
        expect_golden_file_match(OUT .. "generate_map.png", SAMP .. "generate_map.png")
    end)
end)

test_summary()
