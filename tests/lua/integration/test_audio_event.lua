-- Lurek2D Integration Test: Audio + Event System
-- Tests audio playback triggered by event dispatching.
-- Rewritten: lurek.event.newDispatcher does not exist; uses newSignal instead.

describe("audio + event integration", function()
    it("event triggers volume change", function()
        local mute_sig  = lurek.event.newSignal()
        local volume_set = false

        mute_sig:connect("mute", function()
            lurek.audio.setMasterVolume(0.0)
            volume_set = true
        end)

        mute_sig:emit("mute")
        expect_true(volume_set, "mute handler was called")
        expect_near(0.0, lurek.audio.getMasterVolume(), 0.01, "volume is 0")

        -- Restore
        lurek.audio.setMasterVolume(1.0)
    end)

    it("unmute event restores volume", function()
        local saved_volume = 0.8
        local unmute_sig  = lurek.event.newSignal()

        unmute_sig:connect("unmute", function()
            lurek.audio.setMasterVolume(saved_volume)
        end)

        lurek.audio.setMasterVolume(0.0)
        unmute_sig:emit("unmute")
        expect_near(saved_volume, lurek.audio.getMasterVolume(), 0.01, "volume restored")

        -- Reset
        lurek.audio.setMasterVolume(1.0)
    end)

    it("volume slider event applies value from data", function()
        local vol_sig = lurek.event.newSignal()

        vol_sig:connect("volume", function(level)
            lurek.audio.setMasterVolume(level)
        end)

        vol_sig:emit("volume", 0.42)
        expect_near(0.42, lurek.audio.getMasterVolume(), 0.01, "volume set from signal data")

        -- Reset
        lurek.audio.setMasterVolume(1.0)
    end)

    it("multiple event listeners on same event", function()
        local sfx_sig   = lurek.event.newSignal()
        local call_count = 0

        sfx_sig:connect("sfx", function() call_count = call_count + 1 end)
        sfx_sig:connect("sfx", function() call_count = call_count + 1 end)

        sfx_sig:emit("sfx")
        expect_equal(2, call_count, "both listeners called")
    end)
end)
test_summary()
