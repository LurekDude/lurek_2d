-- Integration: audio state driven by scene enter/leave/resume hooks

local function reset_scene_audio_state()
    lurek.scene.clear()
    lurek.audio.setMasterVolume(1.0)
end

describe("audio + scene integration", function()
    -- @integration lurek.audio.getMasterVolume
    -- @integration lurek.audio.setMasterVolume
    -- @integration lurek.scene.clear
    -- @integration lurek.scene.push
    it("plays background music when scene loads", function()
        reset_scene_audio_state()

        local music_scene = {
            enter = function()
                lurek.audio.setMasterVolume(0.35)
            end,
        }

        lurek.audio.setMasterVolume(0.0)
        lurek.scene.push(music_scene)

        expect_near(0.35, lurek.audio.getMasterVolume(), 0.01)
        reset_scene_audio_state()
    end)

    -- @integration lurek.audio.getMasterVolume
    -- @integration lurek.audio.setMasterVolume
    -- @integration lurek.scene.clear
    -- @integration lurek.scene.pop
    -- @integration lurek.scene.push
    it("stops all audio sources on scene unload", function()
        reset_scene_audio_state()

        local music_scene = {
            enter = function()
                lurek.audio.setMasterVolume(0.5)
            end,
            leave = function()
                lurek.audio.setMasterVolume(0.0)
            end,
        }

        lurek.scene.push(music_scene)
        expect_near(0.5, lurek.audio.getMasterVolume(), 0.01)

        lurek.scene.pop()

        expect_near(0.0, lurek.audio.getMasterVolume(), 0.01)
        reset_scene_audio_state()
    end)

    -- @integration lurek.audio.getMasterVolume
    -- @integration lurek.audio.setMasterVolume
    -- @integration lurek.scene.clear
    -- @integration lurek.scene.pop
    -- @integration lurek.scene.push
    it("resumes paused audio on scene resume", function()
        reset_scene_audio_state()

        local gameplay_scene = {
            enter = function()
                lurek.audio.setMasterVolume(0.6)
            end,
            pause = function()
                lurek.audio.setMasterVolume(0.1)
            end,
            resume = function()
                lurek.audio.setMasterVolume(0.6)
            end,
        }
        local pause_scene = {}

        lurek.scene.push(gameplay_scene)
        expect_near(0.6, lurek.audio.getMasterVolume(), 0.01)

        lurek.scene.push(pause_scene)
        expect_near(0.1, lurek.audio.getMasterVolume(), 0.01)

        lurek.scene.pop()
        expect_near(0.6, lurek.audio.getMasterVolume(), 0.01)

        reset_scene_audio_state()
    end)
end)
test_summary()
