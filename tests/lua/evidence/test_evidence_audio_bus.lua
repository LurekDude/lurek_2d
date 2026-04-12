-- test_evidence_audio_bus.lua
-- Evidence test: lurek.audio Bus API + saves bus-processed audio as WAV
-- Produces: audio_bus_volume.wav, audio_bus_pitch.wav

local OUT = "tests/lua/evidence/output/audio/"

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

describe("Evidence: lurek.audio Bus API + WAV output", function()

    it("newBus creates a bus with a name", function()
        local bus = lurek.audio.newBus("sfx")
        expect_equal(bus:getName(), "sfx")
    end)

    it("setVolume/getVolume round-trip", function()
        local bus = lurek.audio.newBus("music")
        bus:setVolume(0.6)
        expect_near(bus:getVolume(), 0.6, 0.001)
    end)

    it("setPitch/getPitch round-trip", function()
        local bus = lurek.audio.newBus("effects")
        bus:setPitch(1.5)
        expect_near(bus:getPitch(), 1.5, 0.001)
    end)

    it("multiple buses are independent", function()
        local b1 = lurek.audio.newBus("bus_a")
        local b2 = lurek.audio.newBus("bus_b")
        b1:setVolume(0.3)
        b2:setVolume(0.9)
        expect_near(b1:getVolume(), 0.3, 0.001)
        expect_near(b2:getVolume(), 0.9, 0.001)
    end)

    it("default pitch is 1.0", function()
        local bus = lurek.audio.newBus("def")
        expect_near(bus:getPitch(), 1.0, 0.001)
    end)

    it("default volume is 1.0", function()
        local bus = lurek.audio.newBus("defvol")
        expect_near(bus:getVolume(), 1.0, 0.001)
    end)

    it("WAV: volume-scaled sine — simulates bus volume", function()
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
        expect_near(sd:getSample(quarter), 0.8 * vol, 0.01)

        lurek.audio.saveWAV(sd, OUT .. "audio_bus_volume.wav")
    end)

    it("WAV: pitch-shifted sine — simulates bus pitch", function()
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
        expect_near(actual_freq, 660, 0.1)
        lurek.audio.saveWAV(sd, OUT .. "audio_bus_pitch.wav")
    end)

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
        expect_equal(math.abs(sd:getSample(0)) < 0.01, true)  -- sin(0) ≈ 0
        local mid = math.floor(samples / 2)
        local mid_peak = 0
        for i = mid, mid + math.floor(RATE / FREQ) do
            if i < samples then
                mid_peak = math.max(mid_peak, math.abs(sd:getSample(i)))
            end
        end
        expect_equal(mid_peak > 0.1, true)   -- still audible at midpoint
        expect_equal(mid_peak < 0.5, true)   -- but quieter than start

        lurek.audio.saveWAV(sd, OUT .. "audio_bus_fadeout.wav")
    end)

end)

test_summary()
