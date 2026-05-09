-- Integration: animation frame stepping + tween interpolation
describe("animation + tween integration", function()
    -- @integration LAnimation:addClip
    -- @integration LAnimation:addFramesFromGrid
    -- @integration LAnimation:getCurrentFrame
    -- @integration LAnimation:isPlaying
    -- @integration LAnimation:play
    -- @integration LAnimation:update
    -- @integration lurek.animation.new
    -- @integration lurek.tween.tween
    -- @integration lurek.tween.update
    it("animation plays frames while tween advances a value", function()
        local anim = lurek.animation.new()
        -- addFramesFromGrid(tex_w, tex_h, frame_w, frame_h, start, count)
        anim:addFramesFromGrid(128, 16, 16, 16, 0, 8)
        -- addClip(name, indices_table, fps, looping)
        anim:addClip("run", {0, 1, 2, 3, 4, 5, 6, 7}, 10.0, false)
        anim:play("run")

        -- Use property tween: lurek.tween.tween(duration, target, fields, easing)
        local progress = { value = 0.0 }
        lurek.tween.tween(0.8, progress, { value = 1.0 }, "linear")

        -- simulate 4 frames at 0.1 s each; advance engine tweens with update()
        for _ = 1, 4 do
            anim:update(0.1)
            lurek.tween.update(0.1)
        end

        expect_true(anim:isPlaying(), "animation is still playing")
        local frame = anim:getCurrentFrame()
        expect_true(frame >= 0, "animation frame is valid")
        expect_true(progress.value > 0.0 and progress.value < 1.0,
            "tween is in-progress after 0.4 s of 0.8 s duration")
    end)

    -- @integration LAnimation:addClip
    -- @integration LAnimation:addFramesFromGrid
    -- @integration LAnimation:isLooping
    -- @integration LAnimation:isPlaying
    -- @integration LAnimation:play
    -- @integration LAnimation:update
    -- @integration lurek.animation.new
    -- @integration lurek.tween.tween
    -- @integration lurek.tween.update
    it("tween reaches target before animation loops", function()
        local anim = lurek.animation.new()
        anim:addFramesFromGrid(64, 16, 16, 16, 0, 4)
        -- looping is set via addClip, not setLooping
        anim:addClip("idle", {0, 1, 2, 3}, 10.0, true)
        anim:play("idle")

        local obj = { alpha = 0.0 }
        lurek.tween.tween(0.2, obj, { alpha = 1.0 }, "linear")

        -- advance past tween duration
        lurek.tween.update(0.25)
        anim:update(0.25)

        expect_near(obj.alpha, 1.0, 0.001, "tween reached 1.0")
        expect_true(anim:isPlaying(), "animation still playing after loop")
        expect_true(anim:isLooping(), "animation clip is looping")
    end)

    -- @integration LAnimation:addClip
    -- @integration LAnimation:addFrame
    -- @integration LAnimation:getCurrentFrame
    -- @integration LAnimation:play
    -- @integration lurek.animation.new
    -- @integration lurek.tween.tween
    -- @integration lurek.tween.update
    it("animation addFrame and tween compose without error", function()
        local anim = lurek.animation.new()
        -- addFrame(x, y, w, h)
        anim:addFrame(1, 1, 16, 16)
        anim:addFrame(17, 1, 16, 16)
        anim:addClip("single", {0, 1}, 10.0, false)
        anim:play("single")

        local obj = { scale = 1.0 }
        lurek.tween.tween(0.1, obj, { scale = 2.0 }, "linear")

        lurek.tween.update(0.1)
        expect_near(obj.scale, 2.0, 0.01, "scale tweened to 2.0")
        expect_true(anim:getCurrentFrame() >= 0, "animation frame is valid")
    end)
end)
test_summary()
