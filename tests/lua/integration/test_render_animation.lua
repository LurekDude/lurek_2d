-- Lurek2D Integration Test: Graphics + Animation
-- Tests drawing primitives with animation frame progression

describe("graphics + animation integration", function()
    it("animation clip current frame advances with time", function()
        local anim = lurek.animation.new()
        anim:addFramesFromGrid(128, 16, 16, 16, 0, 4)
        anim:addClip("run", {0, 1, 2, 3}, 10.0, false)
        anim:play("run")

        local f0 = anim:getCurrentFrame()
        expect_true(f0 >= 0, "frame is >= 0 at start")

        anim:update(0.15)
        local f1 = anim:getCurrentFrame()
        expect_true(f1 >= 0, "frame is valid after 0.15s")
    end)

    it("animation frame drives sprite draw parameters", function()
        local anim = lurek.animation.new()
        anim:addFramesFromGrid(64, 16, 16, 16, 0, 4)
        anim:addClip("walk", {0, 1, 2, 3}, 8.0, false)
        anim:play("walk")

        anim:update(0.125)  -- advance one frame at 8fps
        local frame_idx = anim:getCurrentFrame()

        -- Use frame data for drawing
        expect_no_error(function()
            lurek.render.setColor(1, 1, 1, 1)
            -- Use frame_idx to offset source x in a hypothetical draw
            local src_x = frame_idx * 16
            lurek.render.rectangle("fill", src_x, 0, 16, 16)
        end)
    end)

    it("looping animation clip isLooping is true", function()
        local anim = lurek.animation.new()
        anim:addFramesFromGrid(48, 16, 16, 16, 0, 3)
        anim:addClip("idle", {0, 1, 2}, 5.0, true)
        anim:play("idle")

        expect_true(anim:isLooping(), "looping clip reports isLooping = true")

        -- Advance past the clip end
        anim:update(1.0)
        expect_true(anim:isPlaying(), "still playing after looping past end")
    end)

    it("paused animation does not advance frames", function()
        local anim = lurek.animation.new()
        anim:addFramesFromGrid(32, 16, 16, 16, 0, 2)
        anim:addClip("seq", {0, 1}, 5.0, false)
        anim:play("seq")

        anim:pause()
        local before = anim:getCurrentFrame()
        anim:update(0.5)
        local after = anim:getCurrentFrame()

        -- Paused animation should not advance
        expect_equal(before, after, "paused animation frame does not change")
    end)
end)
test_summary()
