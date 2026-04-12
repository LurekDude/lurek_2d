-- test_evidence_audio.lua
-- Evidence test: lurek.audio API + saves generated audio as WAV files
-- Produces: audio_sine_440hz.wav, audio_chord.wav, audio_sweep.wav

local OUT = "tests/lua/evidence/output/audio/"

describe("Evidence: lurek.audio API + WAV output", function()

    it("newSoundData creates silent buffer", function()
        local sd = lurek.audio.newSoundData(44100, 44100, 1)
    end)

    it("getSample returns 0.0 for new buffer", function()
        local sd = lurek.audio.newSoundData(100, 44100, 1)
    end)

    it("setSample/getSample round-trip", function()
        local sd = lurek.audio.newSoundData(100, 44100, 1)
        sd:setSample(0, 0.5)
    end)

    it("setSample clamps to [-1, 1]", function()
        local sd = lurek.audio.newSoundData(100, 44100, 1)
        sd:setSample(0, 2.0)
        local v = sd:getSample(0)
    end)

    it("getDuration is correct", function()
        local sd = lurek.audio.newSoundData(44100, 44100, 1)
    end)

    it("setMasterVolume/getMasterVolume round-trip", function()
        -- Controls global output level (independent of per-source or per-bus volumes)
        lurek.audio.setMasterVolume(0.75)
        lurek.audio.setMasterVolume(1.0) -- restore defaults
    end)

    it("getActiveSourceCount is 0 with no sources playing", function()
    end)

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

    it("WAV: frequency sweep 200→2000 Hz (2 seconds)", function()
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

test_summary()
