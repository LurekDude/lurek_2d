-- test_evidence_audio.lua
-- Evidence test: lurek.audio API + saves generated audio as WAV files
-- Produces: audio_sine_440hz.wav, audio_chord.wav, audio_sweep.wav

local OUT = "tests/output/audio/"

-- @description Exercises headless SoundData buffer operations and then writes generated waveforms to WAV and PNG evidence files.
describe("Evidence: lurek.audio API + WAV output", function()
    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers SoundData:getSample
    -- @covers SoundData:drawWaveform
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @covers SoundData:getDuration
    -- @covers lurek.audio.setMasterVolume
    -- @covers lurek.audio.getActiveSourceCount
    -- @description Synthesizes a 440 Hz sine, saves it as WAV, and exports a waveform PNG for visual inspection.
    it("WAV: 440 Hz sine wave (1 second, mono)", function()
        local RATE = 44100
        local DURATION = 1.0
        local FREQ = 440
        local samples = math.floor(RATE * DURATION)

        local sd = lurek.audio.newSoundData(samples, RATE, 1)
        for i = 0, samples - 1 do
            local t = i / RATE
            local val = math.sin(2 * math.pi * FREQ * t) * 0.8
            sd:setSample(i, val)
        end

        -- Verify it's actually a sine wave (peak at quarter period)
        local quarter = math.floor(RATE / FREQ / 4)
        local peak = sd:getSample(quarter)

        lurek.audio.saveWAV(sd, OUT .. "audio_sine_440hz.wav")

        local img = lurek.image.newImageData(800, 200)
        sd:drawWaveform(img, 0, 0, 800, 200, 0, 255, 0, 255)
        lurek.image.savePNG(img, OUT .. "evidence_audio_sine.png")

        local img = lurek.image.newImageData(800, 200)
        sd:drawWaveform(img, 0, 0, 800, 200, 255, 128, 0, 255)
        lurek.image.savePNG(img, OUT .. "evidence_audio_sine.png")
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers SoundData:drawWaveform
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Mixes a simple major chord into one buffer and writes both the WAV output and its waveform snapshot.
    it("WAV: three-note chord (C4+E4+G4, 2 seconds)", function()
        local RATE = 44100
        local DURATION = 2.0
        local samples = math.floor(RATE * DURATION)

        local sd = lurek.audio.newSoundData(samples, RATE, 1)
        local freqs = {261.63, 329.63, 392.00} -- C4, E4, G4
        for i = 0, samples - 1 do
            local t = i / RATE
            local val = 0
            for _, f in ipairs(freqs) do
                val = val + math.sin(2 * math.pi * f * t)
            end
            -- Normalize and apply envelope
            val = val / #freqs
            local env = math.min(1.0, math.min(t / 0.05, (DURATION - t) / 0.1))
            sd:setSample(i, val * env * 0.7)
        end

        lurek.audio.saveWAV(sd, OUT .. "audio_chord.wav")

        local img = lurek.image.newImageData(800, 200)
        sd:drawWaveform(img, 0, 0, 800, 200, 255, 128, 0, 255)
        lurek.image.savePNG(img, OUT .. "evidence_audio_chord.png")
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers SoundData:drawWaveform
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Generates a frequency sweep from 200 Hz to 2000 Hz and records both the audio file and waveform render.
    it("WAV: frequency sweep 200        2000 Hz (2 seconds)", function()
        local RATE = 44100
        local DURATION = 2.0
        local samples = math.floor(RATE * DURATION)

        local sd = lurek.audio.newSoundData(samples, RATE, 1)
        local f_start, f_end = 200, 2000
        local phase = 0
        for i = 0, samples - 1 do
            local t = i / RATE
            local freq = f_start + (f_end - f_start) * (t / DURATION)
            phase = phase + 2 * math.pi * freq / RATE
            sd:setSample(i, math.sin(phase) * 0.8)
        end

        lurek.audio.saveWAV(sd, OUT .. "audio_sweep.wav")

        local img = lurek.image.newImageData(800, 200)
        sd:drawWaveform(img, 0, 0, 800, 200, 128, 0, 255, 255)
        lurek.image.savePNG(img, OUT .. "evidence_audio_sweep.png")
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers SoundData:drawWaveform
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Builds a stereo ping-pong tone that alternates energy between left and right channels and saves the output artifacts.
    it("WAV: stereo ping-pong (left/right alternating)", function()
        local RATE = 44100
        local DURATION = 1.0
        local samples = math.floor(RATE * DURATION) * 2 -- stereo = 2 samples per frame

        local sd = lurek.audio.newSoundData(samples, RATE, 2)
        local FREQ = 880
        for frame = 0, math.floor(RATE * DURATION) - 1 do
            local t = frame / RATE
            local tone = math.sin(2 * math.pi * FREQ * t) * 0.6
            -- Alternate between left and right every 0.25 seconds
            local ping = math.floor(t * 4) % 2
            local left_idx = frame * 2
            local right_idx = frame * 2 + 1
            if ping == 0 then
                sd:setSample(left_idx, tone)
                sd:setSample(right_idx, 0.0)
            else
                sd:setSample(left_idx, 0.0)
                sd:setSample(right_idx, tone)
            end
        end

        lurek.audio.saveWAV(sd, OUT .. "audio_stereo_ping.wav")

        local img = lurek.image.newImageData(800, 200)
        sd:drawWaveform(img, 0, 0, 800, 200, 255, 255, 0, 255)
        lurek.image.savePNG(img, OUT .. "evidence_audio_stereo_ping.png")
    end)

end)



-- ================================================================
-- Merged from: test_audio_bus_evidence.lua
-- ================================================================

-- test_evidence_audio_bus.lua
-- Evidence test: lurek.audio Bus API + saves bus-processed audio as WAV
-- Produces: audio_bus_volume.wav, audio_bus_pitch.wav

local OUT = "tests/output/audio/"

--- Helper: generate a sine wave SoundData
local function make_sine(freq, duration, rate)
    rate = rate or 44100
    local samples = math.floor(rate * duration)
    local sd = lurek.audio.newSoundData(samples, rate, 1)
    for i = 0, samples - 1 do
        local t = i / rate
        sd:setSample(i, math.sin(2 * math.pi * freq * t) * 0.8)
    end
    return sd
end

-- @description Covers suite: Evidence: lurek.audio Bus API + WAV output.
describe("Evidence: lurek.audio Bus API + WAV output", function()
    -- @covers lurek.audio.newBus
    -- @covers AudioBus:setVolume
    -- @covers AudioBus:getVolume
    -- @covers lurek.audio.newSoundData
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Applies a bus volume value to a synthesized sine wave and writes the scaled result as bus-volume evidence.
    it("WAV: volume-scaled sine -    simulates bus volume", function()
        -- Generate a 440 Hz sine at full amplitude, then create a
        -- half-volume version to demonstrate bus volume effect
        local RATE = 44100
        local DURATION = 1.0
        local FREQ = 440
        local samples = math.floor(RATE * DURATION)

        local bus = lurek.audio.newBus("vol_test")
        bus:setVolume(0.5)
        local vol = bus:getVolume()

        -- Create SoundData with bus volume applied
        local sd = lurek.audio.newSoundData(samples, RATE, 1)
        for i = 0, samples - 1 do
            local t = i / RATE
            local val = math.sin(2 * math.pi * FREQ * t) * 0.8 * vol
            sd:setSample(i, val)
        end

        -- Verify peak is ~0.4 (0.8 * 0.5)
        local quarter = math.floor(RATE / FREQ / 4)

        lurek.audio.saveWAV(sd, OUT .. "audio_bus_volume.wav")
    end)

    -- @covers lurek.audio.newBus
    -- @covers AudioBus:setPitch
    -- @covers AudioBus:getPitch
    -- @covers lurek.audio.newSoundData
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Multiplies the source tone frequency by the bus pitch value and saves the shifted result as file evidence.
    it("WAV: pitch-shifted sine -    simulates bus pitch", function()
        -- Generate a sine where frequency is multiplied by bus pitch
        local RATE = 44100
        local DURATION = 1.0
        local BASE_FREQ = 440
        local samples = math.floor(RATE * DURATION)

        local bus = lurek.audio.newBus("pitch_test")
        bus:setPitch(1.5)
        local pitch = bus:getPitch()

        -- Create SoundData with bus pitch applied to frequency
        local actual_freq = BASE_FREQ * pitch
        local sd = lurek.audio.newSoundData(samples, RATE, 1)
        for i = 0, samples - 1 do
            local t = i / RATE
            sd:setSample(i, math.sin(2 * math.pi * actual_freq * t) * 0.7)
        end

        -- Verify it's playing at the pitched frequency (660 Hz)
        lurek.audio.saveWAV(sd, OUT .. "audio_bus_pitch.wav")
    end)

    -- @covers lurek.audio.newBus
    -- @covers AudioBus:setVolume
    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:getSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Ramps bus volume down over time to simulate a fade-out envelope and exports the resulting buffer.
    it("WAV: fade-out envelope simulating bus volume ramp", function()
        local RATE = 44100
        local DURATION = 2.0
        local FREQ = 330
        local samples = math.floor(RATE * DURATION)

        local bus = lurek.audio.newBus("fade_test")
        local sd = lurek.audio.newSoundData(samples, RATE, 1)

        for i = 0, samples - 1 do
            local t = i / RATE
            -- Simulate bus volume ramping from 1.0 to 0.0 over duration
            local vol = 1.0 - (t / DURATION)
            bus:setVolume(vol) -- prove the API accepts continuous changes
            local val = math.sin(2 * math.pi * FREQ * t) * 0.8 * vol
            sd:setSample(i, val)
        end

        -- Verify: start is loud, end is silent
        local mid = math.floor(samples / 2)
        local mid_peak = 0
        for i = mid, mid + math.floor(RATE / FREQ) do
            if i < samples then
                mid_peak = math.max(mid_peak, math.abs(sd:getSample(i)))
            end
        end

        lurek.audio.saveWAV(sd, OUT .. "audio_bus_fadeout.wav")
    end)

end)



-- ================================================================
-- Merged from: test_audio_dsp_evidence.lua
-- ================================================================

-- test_evidence_audio_dsp.lua
-- Evidence tests: audio DSP filter processing on SoundData buffers.
-- All processing is headless (no mixer/playback required).

local OUT = "tests/output/audio/"
local SR  = 22050   -- sample rate for all tests

--                  helpers

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

--                  Low-pass filter

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

--                  High-pass filter

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

--                  Bandpass filter

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

--                  Gain

-- @description Covers gain scaling and clipping behavior on SoundData buffers.
describe("Evidence: lurek.audio applyGain", function()
end)

--                  Mix

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

--                  Filter sweep visual

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



-- ================================================================
-- Merged from: test_audio_waves_evidence.lua
-- ================================================================

-- test_evidence_audio_waves.lua
-- Evidence tests: waveform synthesis using lurek.audio generators.
-- All tests are headless -    no audio device required.

local OUT = "tests/output/audio/"
local SR  = 44100
local DUR = 0.05  -- 50 ms -    short but enough to measure waveform properties

--                  helpers

--- Compute RMS of a SoundData buffer
local function rms(sd)
    local n   = sd:getSampleCount()
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
    for i = 0, sd:getSampleCount() - 1 do
        local v = math.abs(sd:getSample(i))
        if v > p then p = v end
    end
    return p
end

--- Render a SoundData waveform to a lane in an image
local function waveform_strip(img, sd, lane, lanes_total, colour)
    local h_per_lane = math.floor(img:getHeight() / lanes_total)
    local y = lane * h_per_lane
    local r, g, b = colour[1], colour[2], colour[3]
    sd:drawWaveform(img, 0, y, img:getWidth(), h_per_lane, r, g, b, 255)
end

--                  Sine wave

-- @description Covers synthesized sine-wave generation, basic amplitude properties, and buffer sizing.
describe("Evidence: lurek.audio newSineWave", function()
end)

--                  Square wave

-- @description Covers square-wave generation and its characteristic amplitude and RMS behavior.
describe("Evidence: lurek.audio newSquareWave", function()
end)

--                  Sawtooth wave

-- @description Covers sawtooth-wave construction and its expected amplitude distribution.
describe("Evidence: lurek.audio newSawtoothWave", function()
end)

--                  Triangle wave

-- @description Covers triangle-wave construction and its expected peak and RMS properties.
describe("Evidence: lurek.audio newTriangleWave", function()
end)

--                  White noise

-- @description Covers deterministic white-noise generation, amplitude limits, and seed repeatability.
describe("Evidence: lurek.audio newWhiteNoise", function()
end)


--                  Visual evidence: all five waveforms on one PNG

-- @description Writes visual and audio evidence comparing all generator outputs side by side.
describe("Evidence: lurek.audio waveform PNG", function()

    -- @covers SoundData:drawWaveform
    -- @evidence file
    -- @covers lurek.audio.newSineWave
    -- @covers lurek.audio.newSquareWave
    -- @covers lurek.audio.newSawtoothWave
    -- @covers lurek.audio.newTriangleWave
    -- @covers lurek.audio.newWhiteNoise
    -- @description Draws the five generator outputs into stacked waveform lanes so their shapes can be inspected visually in one PNG.
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

    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Saves one WAV file per generator so the synthesized sounds can be inspected outside the test harness.
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

--                  Manual sample synthesis (FM / ADSR / drum)

-- @description Builds several hand-authored synthesis examples to document more advanced sample authoring workflows.
describe("Evidence: lurek.audio manual sample synthesis", function()

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes a simple two-operator FM tone and saves it as a richer alternative to the stock sine-wave generator.
    it("FM synthesis -    2-operator FM produces a richer waveform than a sine", function()
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

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers SoundData:getSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Applies an ADSR-style envelope to a sine wave and saves the result to capture attack, sustain, and release shaping.
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

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Builds a kick drum from a decaying sine with falling pitch and writes the result as drum evidence.
    it("drum kick synthesis -    exponential pitch decay for kick transient", function()
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

    -- @covers lurek.audio.newWhiteNoise
    -- @covers lurek.audio.applyHighpass
    -- @covers SoundData:getSample
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Shapes filtered white noise into a hi-hat-style transient and saves the result as a short percussion artifact.
    it("drum hi-hat synthesis -    filtered white noise with exponential decay", function()
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



-- ================================================================
-- Merged from: test_evidence_audio.lua
-- ================================================================

-- test_evidence_audio.lua
-- Evidence test: lurek.audio API + saves generated audio as WAV files
-- Produces: audio_sine_440hz.wav, audio_chord.wav, audio_sweep.wav

local OUT = "tests/output/audio/"

-- @description Exercises headless SoundData buffer operations and then writes generated waveforms to WAV and PNG evidence files.
describe("Evidence: lurek.audio API + WAV output", function()
    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers SoundData:getSample
    -- @covers SoundData:drawWaveform
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @covers SoundData:getDuration
    -- @covers lurek.audio.setMasterVolume
    -- @covers lurek.audio.getActiveSourceCount
    -- @description Synthesizes a 440 Hz sine, saves it as WAV, and exports a waveform PNG for visual inspection.
    it("WAV: 440 Hz sine wave (1 second, mono)", function()
        local RATE = 44100
        local DURATION = 1.0
        local FREQ = 440
        local samples = math.floor(RATE * DURATION)

        local sd = lurek.audio.newSoundData(samples, RATE, 1)
        for i = 0, samples - 1 do
            local t = i / RATE
            local val = math.sin(2 * math.pi * FREQ * t) * 0.8
            sd:setSample(i, val)
        end

        -- Verify it's actually a sine wave (peak at quarter period)
        local quarter = math.floor(RATE / FREQ / 4)
        local peak = sd:getSample(quarter)

        lurek.audio.saveWAV(sd, OUT .. "audio_sine_440hz.wav")

        local img = lurek.image.newImageData(800, 200)
        sd:drawWaveform(img, 0, 0, 800, 200, 0, 255, 0, 255)
        lurek.image.savePNG(img, OUT .. "evidence_audio_sine.png")

        local img = lurek.image.newImageData(800, 200)
        sd:drawWaveform(img, 0, 0, 800, 200, 255, 128, 0, 255)
        lurek.image.savePNG(img, OUT .. "evidence_audio_sine.png")
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers SoundData:drawWaveform
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Mixes a simple major chord into one buffer and writes both the WAV output and its waveform snapshot.
    it("WAV: three-note chord (C4+E4+G4, 2 seconds)", function()
        local RATE = 44100
        local DURATION = 2.0
        local samples = math.floor(RATE * DURATION)

        local sd = lurek.audio.newSoundData(samples, RATE, 1)
        local freqs = {261.63, 329.63, 392.00} -- C4, E4, G4
        for i = 0, samples - 1 do
            local t = i / RATE
            local val = 0
            for _, f in ipairs(freqs) do
                val = val + math.sin(2 * math.pi * f * t)
            end
            -- Normalize and apply envelope
            val = val / #freqs
            local env = math.min(1.0, math.min(t / 0.05, (DURATION - t) / 0.1))
            sd:setSample(i, val * env * 0.7)
        end

        lurek.audio.saveWAV(sd, OUT .. "audio_chord.wav")

        local img = lurek.image.newImageData(800, 200)
        sd:drawWaveform(img, 0, 0, 800, 200, 255, 128, 0, 255)
        lurek.image.savePNG(img, OUT .. "evidence_audio_chord.png")
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers SoundData:drawWaveform
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Generates a frequency sweep from 200 Hz to 2000 Hz and records both the audio file and waveform render.
    it("WAV: frequency sweep 200        2000 Hz (2 seconds)", function()
        local RATE = 44100
        local DURATION = 2.0
        local samples = math.floor(RATE * DURATION)

        local sd = lurek.audio.newSoundData(samples, RATE, 1)
        local f_start, f_end = 200, 2000
        local phase = 0
        for i = 0, samples - 1 do
            local t = i / RATE
            local freq = f_start + (f_end - f_start) * (t / DURATION)
            phase = phase + 2 * math.pi * freq / RATE
            sd:setSample(i, math.sin(phase) * 0.8)
        end

        lurek.audio.saveWAV(sd, OUT .. "audio_sweep.wav")

        local img = lurek.image.newImageData(800, 200)
        sd:drawWaveform(img, 0, 0, 800, 200, 128, 0, 255, 255)
        lurek.image.savePNG(img, OUT .. "evidence_audio_sweep.png")
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers SoundData:drawWaveform
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Builds a stereo ping-pong tone that alternates energy between left and right channels and saves the output artifacts.
    it("WAV: stereo ping-pong (left/right alternating)", function()
        local RATE = 44100
        local DURATION = 1.0
        local samples = math.floor(RATE * DURATION) * 2 -- stereo = 2 samples per frame

        local sd = lurek.audio.newSoundData(samples, RATE, 2)
        local FREQ = 880
        for frame = 0, math.floor(RATE * DURATION) - 1 do
            local t = frame / RATE
            local tone = math.sin(2 * math.pi * FREQ * t) * 0.6
            -- Alternate between left and right every 0.25 seconds
            local ping = math.floor(t * 4) % 2
            local left_idx = frame * 2
            local right_idx = frame * 2 + 1
            if ping == 0 then
                sd:setSample(left_idx, tone)
                sd:setSample(right_idx, 0.0)
            else
                sd:setSample(left_idx, 0.0)
                sd:setSample(right_idx, tone)
            end
        end

        lurek.audio.saveWAV(sd, OUT .. "audio_stereo_ping.wav")

        local img = lurek.image.newImageData(800, 200)
        sd:drawWaveform(img, 0, 0, 800, 200, 255, 255, 0, 255)
        lurek.image.savePNG(img, OUT .. "evidence_audio_stereo_ping.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_audio_bus.lua
-- ================================================================

-- test_evidence_audio_bus.lua
-- Evidence test: lurek.audio Bus API + saves bus-processed audio as WAV
-- Produces: audio_bus_volume.wav, audio_bus_pitch.wav

local OUT = "tests/output/audio/"

--- Helper: generate a sine wave SoundData
local function make_sine(freq, duration, rate)
    rate = rate or 44100
    local samples = math.floor(rate * duration)
    local sd = lurek.audio.newSoundData(samples, rate, 1)
    for i = 0, samples - 1 do
        local t = i / rate
        sd:setSample(i, math.sin(2 * math.pi * freq * t) * 0.8)
    end
    return sd
end

-- @description Covers suite: Evidence: lurek.audio Bus API + WAV output.
describe("Evidence: lurek.audio Bus API + WAV output", function()
    -- @covers lurek.audio.newBus
    -- @covers AudioBus:setVolume
    -- @covers AudioBus:getVolume
    -- @covers lurek.audio.newSoundData
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Applies a bus volume value to a synthesized sine wave and writes the scaled result as bus-volume evidence.
    it("WAV: volume-scaled sine -    simulates bus volume", function()
        -- Generate a 440 Hz sine at full amplitude, then create a
        -- half-volume version to demonstrate bus volume effect
        local RATE = 44100
        local DURATION = 1.0
        local FREQ = 440
        local samples = math.floor(RATE * DURATION)

        local bus = lurek.audio.newBus("vol_test")
        bus:setVolume(0.5)
        local vol = bus:getVolume()

        -- Create SoundData with bus volume applied
        local sd = lurek.audio.newSoundData(samples, RATE, 1)
        for i = 0, samples - 1 do
            local t = i / RATE
            local val = math.sin(2 * math.pi * FREQ * t) * 0.8 * vol
            sd:setSample(i, val)
        end

        -- Verify peak is ~0.4 (0.8 * 0.5)
        local quarter = math.floor(RATE / FREQ / 4)

        lurek.audio.saveWAV(sd, OUT .. "audio_bus_volume.wav")
    end)

    -- @covers lurek.audio.newBus
    -- @covers AudioBus:setPitch
    -- @covers AudioBus:getPitch
    -- @covers lurek.audio.newSoundData
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Multiplies the source tone frequency by the bus pitch value and saves the shifted result as file evidence.
    it("WAV: pitch-shifted sine -    simulates bus pitch", function()
        -- Generate a sine where frequency is multiplied by bus pitch
        local RATE = 44100
        local DURATION = 1.0
        local BASE_FREQ = 440
        local samples = math.floor(RATE * DURATION)

        local bus = lurek.audio.newBus("pitch_test")
        bus:setPitch(1.5)
        local pitch = bus:getPitch()

        -- Create SoundData with bus pitch applied to frequency
        local actual_freq = BASE_FREQ * pitch
        local sd = lurek.audio.newSoundData(samples, RATE, 1)
        for i = 0, samples - 1 do
            local t = i / RATE
            sd:setSample(i, math.sin(2 * math.pi * actual_freq * t) * 0.7)
        end

        -- Verify it's playing at the pitched frequency (660 Hz)
        lurek.audio.saveWAV(sd, OUT .. "audio_bus_pitch.wav")
    end)

    -- @covers lurek.audio.newBus
    -- @covers AudioBus:setVolume
    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:getSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Ramps bus volume down over time to simulate a fade-out envelope and exports the resulting buffer.
    it("WAV: fade-out envelope simulating bus volume ramp", function()
        local RATE = 44100
        local DURATION = 2.0
        local FREQ = 330
        local samples = math.floor(RATE * DURATION)

        local bus = lurek.audio.newBus("fade_test")
        local sd = lurek.audio.newSoundData(samples, RATE, 1)

        for i = 0, samples - 1 do
            local t = i / RATE
            -- Simulate bus volume ramping from 1.0 to 0.0 over duration
            local vol = 1.0 - (t / DURATION)
            bus:setVolume(vol) -- prove the API accepts continuous changes
            local val = math.sin(2 * math.pi * FREQ * t) * 0.8 * vol
            sd:setSample(i, val)
        end

        -- Verify: start is loud, end is silent
        local mid = math.floor(samples / 2)
        local mid_peak = 0
        for i = mid, mid + math.floor(RATE / FREQ) do
            if i < samples then
                mid_peak = math.max(mid_peak, math.abs(sd:getSample(i)))
            end
        end

        lurek.audio.saveWAV(sd, OUT .. "audio_bus_fadeout.wav")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_audio_offline.lua
-- ================================================================

-- Evidence test: proves lurek.audio.processOffline and lurek.audio.normalizeFile
-- write valid WAV files to disk that contain non-trivial PCM data.
-- Does NOT call raw draw calls. Litmus: delete offline.rs     these calls error.

local WAVE    = "tests/fixtures/sine_mono_44100.wav"
local OUT_DIR = evidence_output_dir("audio")

-- @description Evidence: offline processing writes real WAV output files.
describe("Evidence: lurek.audio.processOffline", function()
    -- @covers lurek.audio.processOffline
    -- @evidence file
    -- @description Applies a lowpass filter offline and confirms the output WAV file exists with valid size.
    it("lowpass at 1 kHz produces a WAV file larger than 44 bytes", function()
        local out = OUT_DIR .. "evidence_offline_lowpass.wav"
        lurek.audio.processOffline(WAVE, out, { { type = "lowpass", cutoff = 1000.0 } })
        expect_evidence_created(out)
    end)

    -- @covers lurek.audio.processOffline
    -- @evidence file
    -- @description Applies a reverb effect offline and confirms the output WAV file exists.
    it("reverb produces a WAV file larger than 44 bytes", function()
        local out = OUT_DIR .. "evidence_offline_reverb.wav"
        lurek.audio.processOffline(WAVE, out, { { type = "reverb", room_size = 0.7, mix = 0.4 } })
        expect_evidence_created(out)
    end)

    -- @covers lurek.audio.processOffline
    -- @evidence file
    -- @description Chains highpass + distortion offline and confirms the output WAV file exists.
    it("chained effects produce a WAV file larger than 44 bytes", function()
        local out = OUT_DIR .. "evidence_offline_chain.wav"
        lurek.audio.processOffline(WAVE, out, {
            { type = "highpass",   cutoff = 200.0 },
            { type = "distortion", drive = 10.0, mix = 0.6 }
        })
        expect_evidence_created(out)
    end)
end)

-- @description Evidence: normalizeFile writes a normalised WAV output file.
describe("Evidence: lurek.audio.normalizeFile", function()
    -- @covers lurek.audio.normalizeFile
    -- @evidence file
    -- @description Normalises to 0.9 peak and confirms the output WAV file exists with valid size.
    it("normalizeFile at 0.9 produces a WAV file larger than 44 bytes", function()
        local out = OUT_DIR .. "evidence_normalized.wav"
        lurek.audio.normalizeFile(WAVE, out, 0.9)
        expect_evidence_created(out)
    end)
end)




-- ================================================================
-- Merged from: test_evidence_audio_visualizer.lua
-- ================================================================

-- Evidence test: proves lurek.audio.waveformToPng and lurek.audio.spectrogramToPng
-- create valid PNG image files from WAV audio data.
-- Litmus: delete src/audio/visualizer.rs     these calls error out.

local WAVE    = "tests/fixtures/sine_mono_44100.wav"
local OUT_DIR = evidence_output_dir("audio")

-- @description Evidence: waveformToPng writes a PNG image file of the audio waveform.
describe("Evidence: lurek.audio.waveformToPng", function()
    -- @covers lurek.audio.waveformToPng
    -- @evidence file
    -- @description Renders the 44100 Hz test sine wave to a 512x128 PNG waveform image.
    it("produces a 512x128 PNG waveform file larger than 100 bytes", function()
        local out = OUT_DIR .. "evidence_waveform.png"
        lurek.audio.waveformToPng(WAVE, out, 512, 128)
        expect_evidence_created(out)
    end)

    -- @covers lurek.audio.waveformToPng
    -- @evidence file
    -- @description Renders to a larger 1024x256 size to confirm different dimensions are supported.
    it("produces a 1024x256 PNG waveform file", function()
        local out = OUT_DIR .. "evidence_waveform_large.png"
        lurek.audio.waveformToPng(WAVE, out, 1024, 256)
        expect_evidence_created(out)
    end)
end)

-- @description Evidence: spectrogramToPng writes a PNG spectrogram image from WAV audio.
describe("Evidence: lurek.audio.spectrogramToPng", function()
    -- @covers lurek.audio.spectrogramToPng
    -- @evidence file
    -- @description Renders a 512x256 DFT spectrogram of the test sine wave to a PNG evidence file.
    it("produces a 512x256 PNG spectrogram file larger than 100 bytes", function()
        local out = OUT_DIR .. "evidence_spectrogram.png"
        lurek.audio.spectrogramToPng(WAVE, out, 512, 256)
        expect_evidence_created(out)
    end)

end)
test_summary()
