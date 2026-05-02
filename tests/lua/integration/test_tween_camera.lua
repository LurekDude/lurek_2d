-- Lurek2D Integration Test: Tween + Camera
-- Tests smooth camera pan and zoom via tweens.
-- Rewritten to use lurek.tween.newState(duration, easing) API.

describe("integration: tween drives camera position and zoom", function()
    it("tween advances camera from A to B over simulated time", function()
        local cam   = lurek.camera.newCamera()
        local state = lurek.tween.newState(1.0, "linear")

        cam:setPosition(0, 0)

        -- Simulate 30 frames (0.5 seconds at 60 FPS)
        local dt = 1 / 60
        for _ = 1, 30 do
            state:tick(dt)
        end

        local progress = state:lerp(0, 500)
        expect_near(250, progress, 5.0, "halfway through: value near 250")

        cam:setPosition(progress, 0)
        local cx, _ = cam:getPosition()
        expect_near(250, cx, 5.0, "camera x near 250 at halfway")
    end)

    it("tween reaches target at completion", function()
        local state = lurek.tween.newState(0.5, "linear")

        -- Advance past end
        state:tick(0.6)
        local val = state:lerp(100, 200)
        expect_near(200, val, 1.0, "tween reached target value")
    end)

    it("tween zoom from 1.0 to 2.0 over time", function()
        local cam   = lurek.camera.newCamera()
        local state = lurek.tween.newState(1.0, "linear")

        -- Seek to 50% by ticking half the duration
        state:tick(0.5)
        local zoom_val = state:lerp(1.0, 2.0)
        expect_near(1.5, zoom_val, 0.05, "zoom at halfway = 1.5")

        cam:setZoom(zoom_val)
        expect_near(1.5, cam:getZoom(), 0.05, "camera zoom updated via tween")
    end)

    it("tween isComplete true after full duration", function()
        local state = lurek.tween.newState(0.1, "linear")

        -- Advance beyond duration
        local done = state:tick(0.2)
        expect_true(done or state:isComplete(), "tween completed after 0.2s > 0.1s duration")
    end)
end)
test_summary()
