local function evidence_output_dir()
    return lurek.fs.getAppDir() .. "/tests/lua/golden/evidence_output/migrated_20"
end

local function sample_dir()
    return "tests/lua/golden/samples/migrated_20"
end

local function check_png(name)
    local out = evidence_output_dir() .. "/" .. name .. ".png"
    local sample = sample_dir() .. "/" .. name .. ".png"
    expect_golden_file_match(out, sample, 0.05) -- allow 5% difference for rendering variance
end

local function check_wav(name)
    local out = evidence_output_dir() .. "/" .. name .. ".wav"
    local sample = sample_dir() .. "/" .. name .. ".wav"
    expect_golden_file_match(out, sample, 0.05)
end

describe("Migrated Golden Tests 20", function()
    it("matches fixture_sprite_8x8", function() check_png("sprite_8x8") end)
    it("matches fixture_sprite_16x16", function() check_png("sprite_16x16") end)
    it("matches fixture_sprite_32x32", function() check_png("sprite_32x32") end)
    it("matches fixture_sprite_64x64", function() check_png("sprite_64x64") end)
    it("matches fixture_tileset_128x128", function() check_png("tileset_128x128") end)
    it("matches fixture_gradient_horizontal", function() check_png("gradient_horizontal") end)
    it("matches fixture_gradient_vertical", function() check_png("gradient_vertical") end)
    it("matches evidence_math_bezier_curve", function() check_png("bezier_curve") end)
    it("matches evidence_math_bezier_multiple", function() check_png("bezier_multiple_curves") end)
    it("matches evidence_audio_stereo", function() check_wav("stereo_two_tones") end)
    it("matches evidence_audio_frequency_sweep", function() check_wav("frequency_sweep_100_4000") end)
    it("matches evidence_audio_amplitude_envelope", function() check_wav("amplitude_envelope") end)
    it("matches evidence_audio_square_wave", function() check_wav("square_wave_440hz") end)
    it("matches evidence_audio_sawtooth_wave", function() check_wav("sawtooth_wave_440hz") end)
    it("matches evidence_audio_white_noise", function() check_wav("white_noise") end)
    it("matches evidence_audio_silence", function() check_wav("silence_half_second") end)
    it("matches evidence_audio_waveform_visualization", function() check_wav("waveform_sine_440hz_audio") end)
    it("matches evidence_noise_to_heightmap_render", function() check_png("noise_heightmap_colored") end)
    it("matches evidence_image_all_effects_grid", function() check_png("all_effects_grid") end)
    it("matches evidence_tilemap_multi_layer", function() check_png("multi_layer") end)
end)

test_summary()
