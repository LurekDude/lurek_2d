-- Golden test: math compare-only evidence validation.

describe("golden: math Math constants and trig identities", function()
    it("matches golden sample", function()
        expect_golden_file_match(evidence_output_dir("math") .. "all_curves_gallery.png", "tests/samples/math/all_curves_gallery.png")
        expect_golden_file_match(evidence_output_dir("math") .. "comparison_chart.png", "tests/samples/math/comparison_chart.png")
    end)
end)



-- ================================================================
-- Merged from: test_migrated_20_golden.lua
-- ================================================================

-- Compare-only golden suite for migrated_20 artifacts.
-- Validates migrated image and audio fixtures against committed migrated_20 samples without generating new content in the golden layer.

local function evidence_output_dir()
    return "tests/output/migrated_20/"
end

local function sample_dir()
    return "tests/samples/migrated_20"
end

local function verify_png(name)
    local out = evidence_output_dir() .. name .. ".png"
    local sample = sample_dir() .. "/" .. name .. ".png"
    expect_golden_file_match(out, sample)
end

local function verify_wav(name)
    local out = evidence_output_dir() .. name .. ".wav"
    local sample = sample_dir() .. "/" .. name .. ".wav"
    expect_golden_file_match(out, sample)
end

describe("Migrated Golden Tests 20", function()
    it("matches fixture_sprite_8x8", function() verify_png("sprite_8x8") end)
    it("matches fixture_sprite_16x16", function() verify_png("sprite_16x16") end)
    it("matches fixture_sprite_32x32", function() verify_png("sprite_32x32") end)
    it("matches fixture_sprite_64x64", function() verify_png("sprite_64x64") end)
    it("matches fixture_tileset_128x128", function() verify_png("tileset_128x128") end)
    it("matches fixture_gradient_horizontal", function() verify_png("gradient_horizontal") end)
    it("matches fixture_gradient_vertical", function() verify_png("gradient_vertical") end)
    it("matches evidence_math_bezier_curve", function() verify_png("bezier_curve") end)
    it("matches evidence_math_bezier_multiple", function() verify_png("bezier_multiple_curves") end)
    it("matches evidence_audio_stereo", function() verify_wav("stereo_two_tones") end)
    it("matches evidence_audio_frequency_sweep", function() verify_wav("frequency_sweep_100_4000") end)
    it("matches evidence_audio_amplitude_envelope", function() verify_wav("amplitude_envelope") end)
    it("matches evidence_audio_square_wave", function() verify_wav("square_wave_440hz") end)
    it("matches evidence_audio_sawtooth_wave", function() verify_wav("sawtooth_wave_440hz") end)
    it("matches evidence_audio_white_noise", function() verify_wav("white_noise") end)
    it("matches evidence_audio_silence", function() verify_wav("silence_half_second") end)
    it("matches evidence_audio_waveform_visualization", function() verify_wav("waveform_sine_440hz_audio") end)
    it("matches evidence_noise_to_heightmap_render", function() verify_png("noise_heightmap_colored") end)
    it("matches evidence_image_all_effects_grid", function() verify_png("all_effects_grid") end)
    it("matches evidence_tilemap_multi_layer", function() verify_png("multi_layer") end)
end)



-- ================================================================
-- Merged from: test_misc_golden.lua
-- ================================================================

-- Documents the compare-only golden slots that still need real evidence artifacts and committed samples.

describe('Golden misc', function()
    it('matches evidence_effect_brightness', function() end)
    it('matches evidence_effect_contrast', function() end)
    it('matches evidence_effect_grayscale', function() end)
    it('matches evidence_effect_sepia', function() end)
    it('matches evidence_effect_invert', function() end)
end)



-- ================================================================
-- Merged from: test_migrated_15_golden.lua
-- ================================================================

-- Golden test: migrated 15

describe("golden: migrated 15 evidence comparison", function()
    local OUT = evidence_output_dir("migrated_15") ---@diagnostic disable-line: redundant-parameter
    local SAMP = "tests/samples/migrated_15/"

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
