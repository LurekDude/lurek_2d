-- test_evidence_audio_dsp.lua
-- Evidence tests: audio DSP filter processing on SoundData buffers.
-- All processing is headless (no mixer/playback required).

local OUT = "tests/lua/evidence/output/audio/"
local SR  = 22050   -- sample rate for all tests

-- ── helpers ──────────────────────────────────────────────────────────────────

--- Returns the peak absolute sample value (0..1) for a SoundData
local function peak_amplitude(sd)
    local peak = 0.0
    for i = 0, sd:sampleCount() - 1 do
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

-- ── Low-pass filter ───────────────────────────────────────────────────────────

describe("Evidence: lurek.audio applyLowpass", function()

    it("applyLowpass exists as a function", function()
        expect_equal(type(lurek.audio.applyLowpass), "function")
    end)

    it("low-pass attenuates a high-frequency tone more than a low-frequency tone", function()
        -- High-frequency sine at 8000 Hz — should be heavily attenuated by 500 Hz cutoff
        local high_freq = lurek.audio.newSineWave(8000, 0.1, SR, 1.0)
        local low_freq  = lurek.audio.newSineWave(200,  0.1, SR, 1.0)

        local peak_hf_before = peak_amplitude(high_freq)

        lurek.audio.applyLowpass(high_freq, 500)
        lurek.audio.applyLowpass(low_freq,  500)

        local peak_hf_after = peak_amplitude(high_freq)
        local peak_lf_after = peak_amplitude(low_freq)

        -- HF must lose amplitude significantly
        expect_equal(peak_hf_after < peak_hf_before * 0.5, true)
        -- LF survives mostly intact
        expect_equal(peak_lf_after > peak_hf_after, true)
    end)

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

-- ── High-pass filter ──────────────────────────────────────────────────────────

describe("Evidence: lurek.audio applyHighpass", function()

    it("applyHighpass exists as a function", function()
        expect_equal(type(lurek.audio.applyHighpass), "function")
    end)

    it("high-pass attenuates a low-frequency tone more than a high-frequency tone", function()
        local low_freq  = lurek.audio.newSineWave(100,  0.1, SR, 1.0)
        local high_freq = lurek.audio.newSineWave(6000, 0.1, SR, 1.0)

        local peak_lf_before = peak_amplitude(low_freq)

        lurek.audio.applyHighpass(low_freq,  2000)
        lurek.audio.applyHighpass(high_freq, 2000)

        local peak_lf_after = peak_amplitude(low_freq)
        local peak_hf_after = peak_amplitude(high_freq)

        expect_equal(peak_lf_after < peak_lf_before * 0.5, true)
        expect_equal(peak_hf_after > peak_lf_after, true)
    end)

    it("PNG evidence: high-pass filter before vs after", function()
        local raw  = lurek.audio.newSineWave(300, 0.05, SR, 0.8)
        local raw2 = lurek.audio.newSineWave(300, 0.05, SR, 0.8)
        lurek.audio.applyHighpass(raw2, 2000)
        waveform_compare(raw, raw2, "300 Hz sine (raw)", "after 2000 Hz HP",
            OUT .. "evidence_dsp_highpass.png")
    end)

end)

-- ── Bandpass filter ───────────────────────────────────────────────────────────

describe("Evidence: lurek.audio applyBandpass", function()

    it("applyBandpass exists as a function", function()
        expect_equal(type(lurek.audio.applyBandpass), "function")
    end)

    it("bandpass passes a mid-frequency signal more than out-of-band frequencies", function()
        local in_band  = lurek.audio.newSineWave(1000, 0.1, SR, 1.0)
        local out_low  = lurek.audio.newSineWave(50,   0.1, SR, 1.0)
        local out_high = lurek.audio.newSineWave(8000, 0.1, SR, 1.0)

        lurek.audio.applyBandpass(in_band,  500, 2000)
        lurek.audio.applyBandpass(out_low,  500, 2000)
        lurek.audio.applyBandpass(out_high, 500, 2000)

        local p_in   = peak_amplitude(in_band)
        local p_low  = peak_amplitude(out_low)
        local p_high = peak_amplitude(out_high)

        expect_equal(p_in > p_low, true)
        expect_equal(p_in > p_high, true)
    end)

    it("PNG evidence: bandpass filter on white noise", function()
        local raw  = lurek.audio.newWhiteNoise(0.05, SR, 0.8, 42)
        local raw2 = lurek.audio.newWhiteNoise(0.05, SR, 0.8, 42)
        lurek.audio.applyBandpass(raw2, 800, 3000)
        waveform_compare(raw, raw2, "white noise (raw)", "after 800-3000 Hz BP",
            OUT .. "evidence_dsp_bandpass.png")
    end)

end)

-- ── Gain ──────────────────────────────────────────────────────────────────────

describe("Evidence: lurek.audio applyGain", function()

    it("applyGain halves peak amplitude when gain = 0.5", function()
        local sd = lurek.audio.newSineWave(440, 0.05, SR, 1.0)
        local before = peak_amplitude(sd)
        lurek.audio.applyGain(sd, 0.5)
        local after = peak_amplitude(sd)
        expect_near(after / before, 0.5, 0.05)
    end)

    it("applyGain clips at 1.0 when gain > 1", function()
        local sd = lurek.audio.newSineWave(440, 0.05, SR, 0.8)
        lurek.audio.applyGain(sd, 5.0)
        expect_equal(peak_amplitude(sd) <= 1.0, true)
    end)

end)

-- ── Mix ───────────────────────────────────────────────────────────────────────

describe("Evidence: lurek.audio mixInto", function()

    it("mixInto exists as a function", function()
        expect_equal(type(lurek.audio.mixInto), "function")
    end)

    it("mixing silence does not change signal", function()
        local signal  = lurek.audio.newSineWave(440, 0.05, SR, 0.5)
        local silence = lurek.audio.newSineWave(440, 0.05, SR, 0.0)
        local before  = peak_amplitude(signal)
        lurek.audio.mixInto(signal, silence)
        local after = peak_amplitude(signal)
        expect_near(after, before, 0.01)
    end)

    it("PNG evidence: two sine waves mixed together", function()
        local a = lurek.audio.newSineWave(440,  0.05, SR, 0.5)
        local b = lurek.audio.newSineWave(880,  0.05, SR, 0.5)
        local a_raw = lurek.audio.newSineWave(440, 0.05, SR, 0.5)
        lurek.audio.mixInto(a, b)
        waveform_compare(a_raw, a, "440 Hz sine", "440+880 Hz mixed",
            OUT .. "evidence_dsp_mix.png")
    end)

end)

-- ── Filter sweep visual ───────────────────────────────────────────────────────

describe("Evidence: lurek.audio filter sweep PNG", function()

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
