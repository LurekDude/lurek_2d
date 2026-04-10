-- Lurek2D Integration Test: Tween + Camera
-- Tests smooth camera pan and zoom via tweens.
-- @covers lurek.tween.newTween
-- @covers lurek.camera.newCamera

describe("integration: tween drives camera position and zoom", function()
    it("tween advances camera from A to B over simulated time", function()
        local cam  = lurek.camera.newCamera()
        local tw   = lurek.tween.newTween()

        cam:setPosition(0, 0)

        tw:setDuration(1.0)
        tw:setEasing("linear")
        tw:setFrom(0)
        tw:setTo(500)

        -- Simulate 30 frames (0.5 seconds at 60 FPS)
        local dt = 1 / 60
        for _ = 1, 30 do
            tw:update(dt)
        end

        local progress = tw:getValue()
        expect_near(250, progress, 5.0, "halfway through: value near 250")

        -- Apply to camera
        cam:setPosition(progress, 0)
        local cx, _ = cam:getPosition()
        expect_near(250, cx, 5.0, "camera x near 250 at halfway")
    end)

    it("tween reaches target at completion", function()
        local tw = lurek.tween.newTween()
        tw:setDuration(0.5)
        tw:setEasing("linear")
        tw:setFrom(100)
        tw:setTo(200)

        -- Advance past end
        tw:update(0.6)
        local val = tw:getValue()
        expect_near(200, val, 1.0, "tween reached target value")
    end)

    it("tween zoom from 1.0 to 2.0 over time", function()
        local cam = lurek.camera.newCamera()
        local tw  = lurek.tween.newTween()

        tw:setDuration(1.0)
        tw:setEasing("linear")
        tw:setFrom(1.0)
        tw:setTo(2.0)

        tw:seek(0.5)  -- jump to halfway
        local zoom_val = tw:getValue()
        expect_near(1.5, zoom_val, 0.01, "zoom at halfway = 1.5")

        cam:setZoom(zoom_val)
        expect_near(1.5, cam:getZoom(), 0.01, "camera zoom updated via tween")
    end)

    it("tween onComplete fires after full duration", function()
        local tw       = lurek.tween.newTween()
        local finished = false

        tw:setDuration(0.1)
        tw:setEasing("linear")
        tw:setFrom(0)
        tw:setTo(1)
        tw:onComplete(function() finished = true end)

        tw:update(0.2)
        expect_true(finished, "onComplete fired after tween ended")
    end)
end)

test_summary()
