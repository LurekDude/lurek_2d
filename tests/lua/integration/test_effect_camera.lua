-- Integration: post-processing effects using camera viewport state
describe("effect + camera integration", function()
    -- @integration LCamera:getViewport
    -- @integration LCamera:setViewport
    -- @integration LOverlay:getDimensions
    -- @integration LOverlay:resize
    -- @integration lurek.camera.newCamera
    -- @integration lurek.effect.newOverlay
    it("vignette effect scales to camera viewport dimensions", function()
        local cam = lurek.camera.newCamera()
        local overlay = lurek.effect.newOverlay(1, 1)

        cam:setViewport(0, 0, 320, 180)
        local _, _, width, height = cam:getViewport()
        overlay:resize(width, height)
        overlay:setVignetteEnabled(true)
        overlay:setVignetteStrength(0.4)

        local overlay_w, overlay_h = overlay:getDimensions()
        expect_equal(320, overlay_w)
        expect_equal(180, overlay_h)
        expect_equal(true, overlay:isVignetteEnabled())
        expect_near(0.4, overlay:getVignetteStrength(), 0.001)
    end)

    -- @integration LCamera:getPosition
    -- @integration LCamera:setPosition
    -- @integration LOverlay:getShakeOffset
    -- @integration LOverlay:triggerShake
    -- @integration LOverlay:update
    -- @integration lurek.camera.newCamera
    -- @integration lurek.effect.newOverlay
    it("screen-shake overlay follows camera position offset", function()
        local cam = lurek.camera.newCamera()
        local overlay = lurek.effect.newOverlay(320, 180)

        cam:setPosition(128, 96)
        overlay:triggerShake(8.0, 0.5)
        overlay:update(0.1)

        local cx, cy = cam:getPosition()
        local sx, sy = overlay:getShakeOffset()
        expect_near(128, cx, 0.001)
        expect_near(96, cy, 0.001)
        expect_true(math.abs(sx) > 0 or math.abs(sy) > 0, "shake should produce a non-zero screen offset")
    end)

    -- @integration LCamera:getZoom
    -- @integration LCamera:setViewport
    -- @integration LCamera:setZoom
    -- @integration LOverlay:getDimensions
    -- @integration LOverlay:resize
    -- @integration lurek.camera.newCamera
    -- @integration lurek.effect.newOverlay
    it("camera zoom does not distort full-screen overlay geometry", function()
        local cam = lurek.camera.newCamera()
        local overlay = lurek.effect.newOverlay(640, 360)

        cam:setViewport(0, 0, 640, 360)
        cam:setZoom(2.5)
        local _, _, width, height = cam:getViewport()
        overlay:resize(width, height)

        local zoom = cam:getZoom()
        local overlay_w, overlay_h = overlay:getDimensions()
        expect_near(2.5, zoom, 0.001)
        expect_equal(640, overlay_w)
        expect_equal(360, overlay_h)
    end)
end)
test_summary()
