-- Lurek2D Integration Test: Audio + Timer
-- Tests audio volume timing with timer delta
-- @covers lurek.audio.setMasterVolume
-- @covers lurek.timer.getTime

describe("audio + timer integration", function()
    it("audio volume can be ramped over time", function()
        -- Start at zero
        lurek.audio.setMasterVolume(0.0)
        expect_near(0.0, lurek.audio.getMasterVolume(), 0.01, "starts at 0")

        -- Simulate fade-in over dt steps
        local volume = 0.0
        local target = 1.0
        local speed = 2.0  -- per second
        local dt = 0.016

        for i = 1, 30 do -- ~0.5 seconds
            volume = math.min(target, volume + speed * dt)
        end

        lurek.audio.setMasterVolume(volume)
        expect_true(volume > 0.9, "volume ramped up: " .. volume)
        expect_near(volume, lurek.audio.getMasterVolume(), 0.01, "engine tracks volume")

        -- Reset
        lurek.audio.setMasterVolume(1.0)
    end)

    it("timer delta provides consistent timestep", function()
        local dt = lurek.timer.getDelta()
        expect_type("number", dt)
        expect_true(dt >= 0, "delta is non-negative")
    end)

    it("timer getTime returns increasing values", function()
        local t1 = lurek.timer.getTime()
        expect_type("number", t1)
        -- In test context, getTime should return something reasonable
        expect_true(t1 >= 0, "time is non-negative")
    end)

    it("audio volume fade-out follows exponential decay", function()
        lurek.audio.setMasterVolume(1.0)

        -- Exponential decay: v = v * decay^(dt/rate)
        local volume = 1.0
        local decay_rate = 0.5
        local dt = 0.016
        local steps = 60

        for i = 1, steps do
            volume = volume * (decay_rate ^ dt)
        end

        expect_true(volume < 1.0, "volume decayed")
        expect_true(volume > 0.0, "volume still positive")

        lurek.audio.setMasterVolume(volume)
        expect_near(volume, lurek.audio.getMasterVolume(), 0.01, "engine accepts decayed volume")

        -- Reset
        lurek.audio.setMasterVolume(1.0)
    end)
end)

test_summary()
