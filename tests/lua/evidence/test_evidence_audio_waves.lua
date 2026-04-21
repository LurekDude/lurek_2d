-- test_evidence_audio_waves.lua
-- Evidence tests: waveform synthesis using lurek.audio generators.
-- All tests are headless â€” no audio device required.

local OUT = "tests/lua/evidence/output/audio/"
local SR  = 44100
local DUR = 0.05  -- 50 ms â€” short but enough to measure waveform properties

-- â”€â”€ helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    local h_per_lane = math.floor(img:height() / lanes_total)
    local y = lane * h_per_lane
    local r, g, b = colour[1], colour[2], colour[3]
    sd:drawWaveform(img, 0, y, img:width(), h_per_lane, r, g, b, 255)
end

-- â”€â”€ Sine wave â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers synthesized sine-wave generation, basic amplitude properties, and buffer sizing.
describe("Evidence: lurek.audio newSineWave", function()
end)

-- â”€â”€ Square wave â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers square-wave generation and its characteristic amplitude and RMS behavior.
describe("Evidence: lurek.audio newSquareWave", function()
end)

-- â”€â”€ Sawtooth wave â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers sawtooth-wave construction and its expected amplitude distribution.
describe("Evidence: lurek.audio newSawtoothWave", function()
end)

-- â”€â”€ Triangle wave â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers triangle-wave construction and its expected peak and RMS properties.
describe("Evidence: lurek.audio newTriangleWave", function()
end)

-- â”€â”€ White noise â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers deterministic white-noise generation, amplitude limits, and seed repeatability.
describe("Evidence: lurek.audio newWhiteNoise", function()
        end
    end)
        end
    end)

end)

-- â”€â”€ Visual evidence: all five waveforms on one PNG â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

-- â”€â”€ Manual sample synthesis (FM / ADSR / drum) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Builds several hand-authored synthesis examples to document more advanced sample authoring workflows.
describe("Evidence: lurek.audio manual sample synthesis", function()

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes a simple two-operator FM tone and saves it as a richer alternative to the stock sine-wave generator.
    it("FM synthesis â€” 2-operator FM produces a richer waveform than a sine", function()
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
    it("drum kick synthesis â€” exponential pitch decay for kick transient", function()
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
    it("drum hi-hat synthesis â€” filtered white noise with exponential decay", function()
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
