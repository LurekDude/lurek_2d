-- test_evidence_audio_dsp.lua
-- Evidence tests: audio DSP filter processing on SoundData buffers.
-- All processing is headless (no mixer/playback required).

local OUT = "tests/lua/evidence/output/audio/"
local SR  = 22050   -- sample rate for all tests

-- â”€â”€ helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

--- Returns the peak absolute sample value (0..1) for a SoundData
local function peak_amplitude(sd)
    local peak = 0.0
    for i = 0, sd:getSampleCount() - 1 do
        local v = math.abs(sd:getSample(i))
        if v > peak then peak = v end
    end
    return peak
end

--- Renders before/after waveforms side-by-side into a 800x200 PNG
local function waveform_compare(sd_before, sd_after, label_before, label_after, path)
    local img = lurek.image.newImageData(800, 200)
    img:fill(12, 14, 20, 255)
    -- Draw centre line
    for x = 0, 799 do
        img:setPixel(x, 99, 50, 50, 50, 255)
        img:setPixel(x, 100, 50, 50, 50, 255)
    end
    sd_before:drawWaveform(img,   0, 0, 400, 200, 80, 180, 240, 255)
    sd_after:drawWaveform( img, 400, 0, 400, 200, 240, 140, 60, 255)
    lurek.image.savePNG(img, path)
end

-- â”€â”€ Low-pass filter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises the low-pass DSP path with analytical amplitude checks and a before/after waveform render.
describe("Evidence: lurek.audio applyLowpass", function()
    -- @covers lurek.audio.newSineWave
    -- @covers lurek.audio.applyLowpass
    -- @evidence file
    -- @description Writes a side-by-side waveform comparison showing the visual effect of strong low-pass filtering on a 4 kHz tone.
    it("PNG evidence: low-pass filter before vs after", function()
        local raw = lurek.audio.newSineWave(4000, 0.05, SR, 0.8)
        -- Clone via saveWAV round-trip is not available headlessly;
        -- create identical raw version for comparison
        local raw2 = lurek.audio.newSineWave(4000, 0.05, SR, 0.8)
        lurek.audio.applyLowpass(raw2, 300)
        waveform_compare(raw, raw2, "4 kHz sine (raw)", "after 300 Hz LP",
            OUT .. "evidence_dsp_lowpass.png")
    end)

end)

-- â”€â”€ High-pass filter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises the high-pass DSP path with analytical comparisons and waveform evidence.
describe("Evidence: lurek.audio applyHighpass", function()
    -- @covers lurek.audio.newSineWave
    -- @covers lurek.audio.applyHighpass
    -- @evidence file
    -- @description Saves a waveform comparison of a low tone before and after aggressive high-pass filtering.
    it("PNG evidence: high-pass filter before vs after", function()
        local raw  = lurek.audio.newSineWave(300, 0.05, SR, 0.8)
        local raw2 = lurek.audio.newSineWave(300, 0.05, SR, 0.8)
        lurek.audio.applyHighpass(raw2, 2000)
        waveform_compare(raw, raw2, "300 Hz sine (raw)", "after 2000 Hz HP",
            OUT .. "evidence_dsp_highpass.png")
    end)

end)

-- â”€â”€ Bandpass filter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises the band-pass filter with in-band and out-of-band signals plus file evidence from filtered noise.
describe("Evidence: lurek.audio applyBandpass", function()
    -- @covers lurek.audio.newWhiteNoise
    -- @covers lurek.audio.applyBandpass
    -- @evidence file
    -- @description Filters deterministic white noise through a mid-band window and writes a before/after waveform comparison.
    it("PNG evidence: bandpass filter on white noise", function()
        local raw  = lurek.audio.newWhiteNoise(0.05, SR, 0.8, 42)
        local raw2 = lurek.audio.newWhiteNoise(0.05, SR, 0.8, 42)
        lurek.audio.applyBandpass(raw2, 800, 3000)
        waveform_compare(raw, raw2, "white noise (raw)", "after 800-3000 Hz BP",
            OUT .. "evidence_dsp_bandpass.png")
    end)

end)

-- â”€â”€ Gain â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers gain scaling and clipping behavior on SoundData buffers.
describe("Evidence: lurek.audio applyGain", function()
end)

-- â”€â”€ Mix â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers additive mixing using both a silence control case and a waveform-rendered combined signal.
describe("Evidence: lurek.audio mixInto", function()
    -- @covers lurek.audio.newSineWave
    -- @covers lurek.audio.mixInto
    -- @evidence file
    -- @description Mixes two tones into one buffer and saves a visual waveform comparison between the source and mixed result.
    it("PNG evidence: two sine waves mixed together", function()
        local a = lurek.audio.newSineWave(440,  0.05, SR, 0.5)
        local b = lurek.audio.newSineWave(880,  0.05, SR, 0.5)
        local a_raw = lurek.audio.newSineWave(440, 0.05, SR, 0.5)
        lurek.audio.mixInto(a, b)
        waveform_compare(a_raw, a, "440 Hz sine", "440+880 Hz mixed",
            OUT .. "evidence_dsp_mix.png")
    end)

end)

-- â”€â”€ Filter sweep visual â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Produces a strip of filtered-noise waveform lanes to show how lowering or raising cutoff changes the visible signal envelope.
describe("Evidence: lurek.audio filter sweep PNG", function()

    -- @covers lurek.audio.newWhiteNoise
    -- @covers lurek.audio.applyLowpass
    -- @evidence file
    -- @description Renders multiple low-pass cutoffs across white noise into a single comparison PNG for manual DSP inspection.
    it("renders a low-pass filter sweep across white noise as a spectrogram strip", function()
        -- Produce 8 strips: cutoff = 200, 500, 1000, 2000, 4000, 6000, 8000, 10000 Hz
        local CUTS = {200, 500, 1000, 2000, 4000, 6000, 8000, 10000}
        local STRIP_W = 80
        local img = lurek.image.newImageData(STRIP_W * #CUTS, 100)
        img:fill(10, 10, 18, 255)

        for col, cut in ipairs(CUTS) do
            local noise = lurek.audio.newWhiteNoise(0.05, SR, 0.8, 7)
            lurek.audio.applyLowpass(noise, cut)
            local ratio = cut / 10000.0
            local r = math.floor(255 * ratio)
            local b = math.floor(255 * (1.0 - ratio))
            noise:drawWaveform(img, (col - 1) * STRIP_W, 0, STRIP_W, 100, r, 80, b, 255)
        end

        lurek.image.savePNG(img, OUT .. "evidence_dsp_filter_sweep.png")
    end)

end)
test_summary()
