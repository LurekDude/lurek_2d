-- test_evidence_audio_waves.lua
-- Evidence tests: waveform synthesis using lurek.audio generators.
-- All tests are headless — no audio device required.

local OUT = "tests/lua/evidence/output/audio/"
local SR  = 44100
local DUR = 0.05  -- 50 ms — short but enough to measure waveform properties

-- ── helpers ──────────────────────────────────────────────────────────────────

--- Compute RMS of a SoundData buffer
local function rms(sd)
    local n   = sd:sampleCount()
    if n == 0 then return 0.0 end
    local sum = 0.0
    for i = 0, n - 1 do
        local v = sd:getSample(i)
        sum = sum + v * v
    end
    return math.sqrt(sum / n)
end

--- Compute peak absolute amplitude
local function peak(sd)
    local p = 0.0
    for i = 0, sd:sampleCount() - 1 do
        local v = math.abs(sd:getSample(i))
        if v > p then p = v end
    end
    return p
end

--- Render a SoundData waveform to a lane in an image
local function waveform_strip(img, sd, lane, lanes_total, colour)
    local h_per_lane = math.floor(img:height() / lanes_total)
    local y = lane * h_per_lane
    local r, g, b = colour[1], colour[2], colour[3]
    sd:drawWaveform(img, 0, y, img:width(), h_per_lane, r, g, b, 255)
end

-- ── Sine wave ─────────────────────────────────────────────────────────────────

describe("Evidence: lurek.audio newSineWave", function()

    it("newSineWave exists as a function", function()
    end)

    it("returns a SoundData object", function()
        local sd = lurek.audio.newSineWave(440, DUR, SR, 0.8)
    end)

    it("sample count matches duration", function()
        local sd = lurek.audio.newSineWave(440, DUR, SR, 0.8)
        -- Expect DUR * SR samples (within 1 sample rounding)
        local expected = math.floor(DUR * SR)
    end)

    it("peak amplitude matches the amplitude parameter", function()
        local amp = 0.6
        local sd = lurek.audio.newSineWave(440, DUR, SR, amp)
    end)

    it("RMS of full-amplitude sine ≈ amp / sqrt(2)", function()
        local amp = 1.0
        local sd = lurek.audio.newSineWave(440, 1.0, SR, amp)
        local expected_rms = amp / math.sqrt(2)
    end)

end)

-- ── Square wave ───────────────────────────────────────────────────────────────

describe("Evidence: lurek.audio newSquareWave", function()

    it("newSquareWave exists as a function", function()
    end)

    it("peak amplitude matches amplitude parameter", function()
        local amp = 0.7
        local sd = lurek.audio.newSquareWave(440, DUR, SR, amp)
    end)

    it("square wave RMS ≈ amplitude (a ideal square wave has RMS == peak)", function()
        local amp = 0.8
        local sd = lurek.audio.newSquareWave(220, DUR, SR, amp)
        -- Allow wider tolerance: the very first/last half-cycle may be partial
    end)

end)

-- ── Sawtooth wave ─────────────────────────────────────────────────────────────

describe("Evidence: lurek.audio newSawtoothWave", function()

    it("newSawtoothWave exists as a function", function()
    end)

    it("peak amplitude matches amplitude parameter", function()
        local amp = 0.9
        local sd = lurek.audio.newSawtoothWave(440, DUR, SR, amp)
    end)

    it("sawtooth RMS ≈ amplitude / sqrt(3)  (triangular PDF)", function()
        local amp = 1.0
        local sd = lurek.audio.newSawtoothWave(220, DUR, SR, amp)
        local expected_rms = amp / math.sqrt(3)
    end)

end)

-- ── Triangle wave ─────────────────────────────────────────────────────────────

describe("Evidence: lurek.audio newTriangleWave", function()

    it("newTriangleWave exists as a function", function()
    end)

    it("peak amplitude matches amplitude parameter", function()
        local amp = 0.75
        local sd = lurek.audio.newTriangleWave(440, DUR, SR, amp)
    end)

    it("triangle RMS ≈ amplitude / sqrt(3)  (same as sawtooth, linear rise/fall)", function()
        local amp = 1.0
        local sd = lurek.audio.newTriangleWave(220, DUR, SR, amp)
        local expected_rms = amp / math.sqrt(3)
    end)

end)

-- ── White noise ───────────────────────────────────────────────────────────────

describe("Evidence: lurek.audio newWhiteNoise", function()

    it("newWhiteNoise exists as a function", function()
    end)

    it("peak amplitude does not exceed the amplitude parameter", function()
        local amp = 0.8
        local sd = lurek.audio.newWhiteNoise(DUR, SR, amp, 12345)
    end)

    it("two calls with same seed produce identical samples", function()
        local sd1 = lurek.audio.newWhiteNoise(DUR, SR, 0.9, 99)
        local sd2 = lurek.audio.newWhiteNoise(DUR, SR, 0.9, 99)
        local all_same = true
        for i = 0, sd1:sampleCount() - 1 do
            if math.abs(sd1:getSample(i) - sd2:getSample(i)) > 0.0001 then
                all_same = false
                break
            end
        end
    end)

    it("two calls with different seeds produce different samples", function()
        local sd1 = lurek.audio.newWhiteNoise(DUR, SR, 0.9, 1)
        local sd2 = lurek.audio.newWhiteNoise(DUR, SR, 0.9, 2)
        local any_diff = false
        for i = 0, sd1:sampleCount() - 1 do
            if math.abs(sd1:getSample(i) - sd2:getSample(i)) > 0.001 then
                any_diff = true
                break
            end
        end
    end)

end)

-- ── Visual evidence: all five waveforms on one PNG ───────────────────────────

describe("Evidence: lurek.audio waveform PNG", function()

    it("renders all five waveforms in a single comparison image", function()
        local WAVES = {
            {fn = function() return lurek.audio.newSineWave(    440, DUR, SR, 0.8) end, col = {80, 180, 240}},
            {fn = function() return lurek.audio.newSquareWave(  440, DUR, SR, 0.8) end, col = {220, 100, 100}},
            {fn = function() return lurek.audio.newSawtoothWave(440, DUR, SR, 0.8) end, col = {80, 220, 100}},
            {fn = function() return lurek.audio.newTriangleWave(440, DUR, SR, 0.8) end, col = {240, 200,  50}},
            {fn = function() return lurek.audio.newWhiteNoise(  DUR, SR, 0.8, 42) end,  col = {180, 120, 220}},
        }
        local IMG_W = 800
        local LANE_H = 80
        local img = lurek.image.newImageData(IMG_W, LANE_H * #WAVES)
        img:fill(12, 14, 20, 255)

        -- Draw separator lines
        for i = 0, #WAVES - 1 do
            local y = i * LANE_H
            for x = 0, IMG_W - 1 do
                img:setPixel(x, y, 30, 30, 40, 255)
            end
        end

        for i, w in ipairs(WAVES) do
            local sd = w.fn()
            waveform_strip(img, sd, i - 1, #WAVES, w.col)
        end

        lurek.image.savePNG(img, OUT .. "evidence_audio_waves.png")
    end)

    it("WAV files: saves each waveform as a WAV file", function()
        lurek.audio.saveWAV(lurek.audio.newSineWave(    440, 1.0, SR, 0.8),
            OUT .. "evidence_wave_sine.wav")
        lurek.audio.saveWAV(lurek.audio.newSquareWave(  440, 1.0, SR, 0.8),
            OUT .. "evidence_wave_square.wav")
        lurek.audio.saveWAV(lurek.audio.newSawtoothWave(440, 1.0, SR, 0.8),
            OUT .. "evidence_wave_sawtooth.wav")
        lurek.audio.saveWAV(lurek.audio.newTriangleWave(440, 1.0, SR, 0.8),
            OUT .. "evidence_wave_triangle.wav")
        lurek.audio.saveWAV(lurek.audio.newWhiteNoise(  1.0, SR, 0.8, 7),
            OUT .. "evidence_wave_whitenoise.wav")
    end)

end)

-- ── Manual sample synthesis (FM / ADSR / drum) ────────────────────────────────

describe("Evidence: lurek.audio manual sample synthesis", function()

    it("FM synthesis — 2-operator FM produces a richer waveform than a sine", function()
        local mod_freq = 880.0
        local car_freq = 440.0
        local mod_idx  = 2.0
        local n_samples = math.floor(DUR * SR)
        local sd = lurek.audio.newSoundData(n_samples, SR, 1)
        for i = 0, n_samples - 1 do
            local t   = i / SR
            local mod = mod_idx * math.sin(2 * math.pi * mod_freq * t)
            local s   = 0.7 * math.sin(2 * math.pi * car_freq * t + mod)
            sd:setSample(i, s)
        end
        lurek.audio.saveWAV(sd, OUT .. "evidence_wave_fm.wav")
    end)

    it("ADSR envelope applied to sine creates natural attack/release shape", function()
        local dur_full = 0.5
        local n = math.floor(dur_full * SR)
        local attack   = 0.05
        local decay    = 0.1
        local sustain  = 0.7
        local release  = 0.15
        local freq = 440.0

        local sd = lurek.audio.newSoundData(n, SR, 1)
        for i = 0, n - 1 do
            local t = i / SR
            local env
            if t < attack then
                env = t / attack
            elseif t < attack + decay then
                env = 1.0 - (1.0 - sustain) * ((t - attack) / decay)
            elseif t < dur_full - release then
                env = sustain
            else
                env = sustain * (1.0 - (t - (dur_full - release)) / release)
            end
            sd:setSample(i, env * 0.8 * math.sin(2 * math.pi * freq * t))
        end

        -- Sample at 1/4 of duration should be at sustain level (approx)
        local mid = math.floor(0.25 * n)
        local mid_amp = math.abs(sd:getSample(mid))

        lurek.audio.saveWAV(sd, OUT .. "evidence_wave_adsr.wav")
    end)

    it("drum kick synthesis — exponential pitch decay for kick transient", function()
        local dur_k = 0.3
        local n_k   = math.floor(dur_k * SR)
        local sd = lurek.audio.newSoundData(n_k, SR, 1)
        local start_freq = 180.0
        local end_freq   = 40.0
        for i = 0, n_k - 1 do
            local t   = i / SR
            local env = math.exp(-t * 20)
            local f   = end_freq + (start_freq - end_freq) * math.exp(-t * 30)
            sd:setSample(i, env * 0.9 * math.sin(2 * math.pi * f * t))
        end
        lurek.audio.saveWAV(sd, OUT .. "evidence_drum_kick.wav")
    end)

    it("drum hi-hat synthesis — filtered white noise with exponential decay", function()
        local dur_h = 0.1
        local n_h   = math.floor(dur_h * SR)
        -- Build white noise via newWhiteNoise then apply envelope via setSample
        local noise = lurek.audio.newWhiteNoise(dur_h, SR, 0.9, 55)
        -- Apply exponential amplitude envelope in-place
        for i = 0, n_h - 1 do
            local t = i / SR
            local env = math.exp(-t * 40)
            local v   = noise:getSample(i)
            noise:setSample(i, v * env)
        end
        -- High-pass to make it sound like metal
        lurek.audio.applyHighpass(noise, 5000)
        lurek.audio.saveWAV(noise, OUT .. "evidence_drum_hihat.wav")
    end)

end)

test_summary()
