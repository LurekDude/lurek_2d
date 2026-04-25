-- Golden test: math compare-only evidence validation.

-- @description Compares only pre-generated math evidence artifacts against committed math golden samples.
describe("golden: math Math constants and trig identities", function()
    -- @golden
    -- @description Compares the evidence-layer easing gallery PNGs against the committed math golden samples without generating any new content here.
    xit("matches golden sample", function()
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

local function check_png(name)
    local out = evidence_output_dir() .. name .. ".png"
    local sample = sample_dir() .. "/" .. name .. ".png"
    expect_golden_file_match(out, sample, 0.05) -- allow 5% difference for rendering variance
end

local function check_wav(name)
    local out = evidence_output_dir() .. name .. ".wav"
    local sample = sample_dir() .. "/" .. name .. ".wav"
    expect_golden_file_match(out, sample, 0.05)
end

-- @description Covers suite: Migrated Golden Tests 20.
describe("Migrated Golden Tests 20", function()
    -- @golden
    -- @covers check_png
    -- @description Compares the generated sprite_8x8 PNG evidence image against the migrated_20 sprite_8x8 golden sample.
    xit("matches fixture_sprite_8x8", function() check_png("sprite_8x8") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated sprite_16x16 PNG evidence image against the migrated_20 sprite_16x16 golden sample.
    xit("matches fixture_sprite_16x16", function() check_png("sprite_16x16") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated sprite_32x32 PNG evidence image against the migrated_20 sprite_32x32 golden sample.
    xit("matches fixture_sprite_32x32", function() check_png("sprite_32x32") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated sprite_64x64 PNG evidence image against the migrated_20 sprite_64x64 golden sample.
    xit("matches fixture_sprite_64x64", function() check_png("sprite_64x64") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated tileset_128x128 PNG evidence image against the migrated_20 tileset golden sample.
    xit("matches fixture_tileset_128x128", function() check_png("tileset_128x128") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated gradient_horizontal PNG evidence image against the migrated_20 horizontal gradient golden sample.
    xit("matches fixture_gradient_horizontal", function() check_png("gradient_horizontal") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated gradient_vertical PNG evidence image against the migrated_20 vertical gradient golden sample.
    xit("matches fixture_gradient_vertical", function() check_png("gradient_vertical") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated bezier_curve PNG evidence image against the migrated_20 math bezier golden sample.
    xit("matches evidence_math_bezier_curve", function() check_png("bezier_curve") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated bezier_multiple_curves PNG evidence image against the migrated_20 multi-curve bezier golden sample.
    xit("matches evidence_math_bezier_multiple", function() check_png("bezier_multiple_curves") end)
    -- @golden
    -- @covers check_wav
    -- @description Compares the generated stereo_two_tones WAV evidence artifact against the migrated_20 stereo audio golden sample.
    xit("matches evidence_audio_stereo", function() check_wav("stereo_two_tones") end)
    -- @golden
    -- @covers check_wav
    -- @description Compares the generated frequency_sweep_100_4000 WAV evidence artifact against the migrated_20 sweep audio golden sample.
    xit("matches evidence_audio_frequency_sweep", function() check_wav("frequency_sweep_100_4000") end)
    -- @golden
    -- @covers check_wav
    -- @description Compares the generated amplitude_envelope WAV evidence artifact against the migrated_20 envelope audio golden sample.
    xit("matches evidence_audio_amplitude_envelope", function() check_wav("amplitude_envelope") end)
    -- @golden
    -- @covers check_wav
    -- @description Compares the generated square_wave_440hz WAV evidence artifact against the migrated_20 square-wave audio golden sample.
    xit("matches evidence_audio_square_wave", function() check_wav("square_wave_440hz") end)
    -- @golden
    -- @covers check_wav
    -- @description Compares the generated sawtooth_wave_440hz WAV evidence artifact against the migrated_20 sawtooth-wave audio golden sample.
    xit("matches evidence_audio_sawtooth_wave", function() check_wav("sawtooth_wave_440hz") end)
    -- @golden
    -- @covers check_wav
    -- @description Compares the generated white_noise WAV evidence artifact against the migrated_20 white-noise audio golden sample.
    xit("matches evidence_audio_white_noise", function() check_wav("white_noise") end)
    -- @golden
    -- @covers check_wav
    -- @description Compares the generated silence_half_second WAV evidence artifact against the migrated_20 silence golden sample.
    xit("matches evidence_audio_silence", function() check_wav("silence_half_second") end)
    -- @golden
    -- @covers check_wav
    -- @description Compares the generated waveform_sine_440hz_audio WAV evidence artifact against the migrated_20 waveform visualization golden sample.
    xit("matches evidence_audio_waveform_visualization", function() check_wav("waveform_sine_440hz_audio") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated noise_heightmap_colored PNG evidence image against the migrated_20 noise heightmap golden sample.
    xit("matches evidence_noise_to_heightmap_render", function() check_png("noise_heightmap_colored") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated all_effects_grid PNG evidence image against the migrated_20 image effects golden sample.
    xit("matches evidence_image_all_effects_grid", function() check_png("all_effects_grid") end)
    -- @golden
    -- @covers check_png
    -- @description Compares the generated multi_layer PNG evidence image against the migrated_20 tilemap golden sample.
    xit("matches evidence_tilemap_multi_layer", function() check_png("multi_layer") end)
end)



-- ================================================================
-- Merged from: test_misc_golden.lua
-- ================================================================

-- Placeholder golden suite for migrated image-effect fixtures.
-- Documents the compare-only golden slots that still need real evidence artifacts and committed samples.

-- @description Covers suite: Golden misc.
describe('Golden misc', function()
    -- @description Placeholder stub: this test body is empty and currently does not compare the brightness effect evidence artifact against a golden sample.
    it('matches evidence_effect_brightness', function() end)
    -- @description Placeholder stub: this test body is empty and currently does not compare the contrast effect evidence artifact against a golden sample.
    it('matches evidence_effect_contrast', function() end)
    -- @description Placeholder stub: this test body is empty and currently does not compare the grayscale effect evidence artifact against a golden sample.
    it('matches evidence_effect_grayscale', function() end)
    -- @description Placeholder stub: this test body is empty and currently does not compare the sepia effect evidence artifact against a golden sample.
    it('matches evidence_effect_sepia', function() end)
    -- @description Placeholder stub: this test body is empty and currently does not compare the invert effect evidence artifact against a golden sample.
    it('matches evidence_effect_invert', function() end)
end)



-- ================================================================
-- Merged from: test_migrated_15_golden.lua
-- ================================================================

-- Golden test: migrated 15

-- @description Covers suite: golden: migrated 15 evidence comparison.
describe("golden: migrated 15 evidence comparison", function()
    local OUT = evidence_output_dir("migrated_15") ---@diagnostic disable-line: redundant-parameter
    local SAMP = "tests/samples/migrated_15/"

    -- @golden
    -- @covers expect_golden_file_match
    -- @description Compares the migrated_15 PNG batch, including blank, fill, transforms, blur, terrain, and generated map outputs, against the committed golden samples.
    xit("matches golden samples", function()
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
