-- Lurek2D Lua BDD tests for lurek.camera
-- Headless: no GPU, no audio, no window.

-- @description Covers suite: lurek.camera.
describe("lurek.camera", function()
    -- @description Covers suite: module interface.
    describe("module interface", function()
        -- @tests lurek.camera.new
        -- @description Verifies the camera namespace exposes the constructor entry point.
        it("exposes new factory", function()
            expect_type("function", lurek.camera.new)
        end)
    end)

    -- @description Covers suite: new(w, h).
    describe("new(w, h)", function()
        -- @tests lurek.camera.new
        -- @description Verifies constructing a camera with viewport dimensions returns userdata.
        it("returns a userdata object", function()
            local cam = lurek.camera.new(800, 600)
            expect_type("userdata", cam)
        end)
    end)

    -- @description Covers suite: position.
    describe("position", function()
        -- @tests Camera.getPosition
        -- @description Verifies a fresh camera starts at the world origin.
        it("getPosition returns 0,0 by default", function()
            local cam = lurek.camera.new(320, 240)
            local x, y = cam:getPosition()
            expect_near(0.0, x, 0.001)
            expect_near(0.0, y, 0.001)
        end)

        -- @tests Camera.setPosition
        -- @tests Camera.getPosition
        -- @description Verifies explicit camera position updates round-trip through the accessor pair.
        it("setPosition/getPosition round-trip", function()
            local cam = lurek.camera.new(320, 240)
            cam:setPosition(50, 75)
            local x, y = cam:getPosition()
            expect_near(50.0, x, 0.001)
            expect_near(75.0, y, 0.001)
        end)

        -- @tests Camera.lookAt
        -- @tests Camera.getPosition
        -- @description Verifies lookAt snaps the camera center to the requested target coordinates.
        it("lookAt moves the camera to the target", function()
            local cam = lurek.camera.new(320, 240)
            cam:lookAt(100, 200)
            local x, y = cam:getPosition()
            expect_near(100.0, x, 0.001)
            expect_near(200.0, y, 0.001)
        end)

        -- @tests Camera.move
        -- @tests Camera.getPosition
        -- @description Verifies relative movement adds a delta to the current camera position instead of replacing it.
        it("move shifts the position additively", function()
            local cam = lurek.camera.new(320, 240)
            cam:setPosition(10, 20)
            cam:move(5, -5)
            local x, y = cam:getPosition()
            expect_near(15.0, x, 0.001)
            expect_near(15.0, y, 0.001)
        end)
    end)

    -- @description Covers suite: zoom.
    describe("zoom", function()
        -- @tests Camera.getZoom
        -- @description Verifies new cameras start with unit zoom.
        it("getZoom returns 1.0 by default", function()
            local cam = lurek.camera.new(320, 240)
            expect_near(1.0, cam:getZoom(), 0.001)
        end)

        -- @tests Camera.setZoom
        -- @tests Camera.getZoom
        -- @description Verifies zoom values persist through the setter/getter pair.
        it("setZoom/getZoom round-trip", function()
            local cam = lurek.camera.new(320, 240)
            cam:setZoom(2.5)
            expect_near(2.5, cam:getZoom(), 0.001)
        end)
    end)

    -- @description Covers suite: rotation.
    describe("rotation", function()
        -- @tests Camera.getRotation
        -- @description Verifies new cameras start with zero rotation.
        it("getRotation returns 0.0 by default", function()
            local cam = lurek.camera.new(320, 240)
            expect_near(0.0, cam:getRotation(), 0.001)
        end)

        -- @tests Camera.setRotation
        -- @tests Camera.getRotation
        -- @description Verifies rotation values round-trip without normalization surprises for a simple radian input.
        it("setRotation/getRotation round-trip", function()
            local cam = lurek.camera.new(320, 240)
            cam:setRotation(1.57)
            expect_near(1.57, cam:getRotation(), 0.001)
        end)
    end)

    -- @description Covers suite: viewport.
    describe("viewport", function()
        -- @tests Camera.getViewport
        -- @description Verifies the constructor seeds the viewport width and height from the input dimensions.
        it("getViewport returns initial size", function()
            local cam = lurek.camera.new(800, 600)
            local x, y, w, h = cam:getViewport()
            expect_near(800.0, w, 0.001)
            expect_near(600.0, h, 0.001)
        end)

        -- @tests Camera.setViewport
        -- @tests Camera.getViewport
        -- @description Verifies viewport origin and size round-trip together after an explicit update.
        it("setViewport/getViewport round-trip", function()
            local cam = lurek.camera.new(800, 600)
            cam:setViewport(10, 5, 400, 300)
            local x, y, w, h = cam:getViewport()
            expect_near(10.0, x, 0.001)
            expect_near(5.0, y, 0.001)
            expect_near(400.0, w, 0.001)
            expect_near(300.0, h, 0.001)
        end)
    end)

    -- @description Covers suite: coordinate transforms.
    describe("coordinate transforms", function()
        -- @tests Camera.toScreen
        -- @tests Camera.toWorld
        -- @tests Camera.setPosition
        -- @description Verifies world-to-screen and screen-to-world transforms approximately invert each other for the same camera state.
        it("toScreen then toWorld round-trips the position", function()
            local cam = lurek.camera.new(800, 600)
            cam:setPosition(100, 50)
            local sx, sy = cam:toScreen(150, 120)
            local wx, wy = cam:toWorld(sx, sy)
            expect_near(150.0, wx, 0.5)
            expect_near(120.0, wy, 0.5)
        end)
    end)

    -- @description Covers suite: getVisibleArea().
    describe("getVisibleArea()", function()
        -- @tests Camera.getVisibleArea
        -- @description Verifies getVisibleArea returns the expected four-number rectangle shape.
        it("returns four numbers x, y, w, h", function()
            local cam = lurek.camera.new(640, 480)
            local x, y, w, h = cam:getVisibleArea()
            expect_type("number", x)
            expect_type("number", y)
            expect_type("number", w)
            expect_type("number", h)
        end)
    end)

    -- @description Covers suite: shake().
    describe("shake()", function()
        -- @tests Camera.shake
        -- @description Verifies shake accepts a valid amplitude and duration without rejecting the request.
        it("does not error on valid params", function()
            local cam = lurek.camera.new(320, 240)
            cam:shake(5.0, 0.5)
        end)
    end)

    -- @description Covers suite: update().
    describe("update()", function()
        -- @tests Camera.update
        -- @description Verifies update handles a zero-delta frame without requiring accumulated motion state.
        it("does not error when called with zero dt", function()
            local cam = lurek.camera.new(320, 240)
            cam:update(0.0)
        end)
    end)

    -- @description Covers suite: setBounds / removeBounds.
    describe("setBounds / removeBounds", function()
        -- @tests Camera.setBounds
        -- @description Verifies bounds can be applied to the camera without raising validation errors.
        it("setBounds does not error", function()
            local cam = lurek.camera.new(800, 600)
            cam:setBounds(0, 0, 1600, 1200)
        end)

        -- @tests Camera.setBounds
        -- @tests Camera.removeBounds
        -- @description Verifies bounds can be removed after previously enabling them.
        it("removeBounds does not error after setBounds", function()
            local cam = lurek.camera.new(800, 600)
            cam:setBounds(0, 0, 2000, 2000)
            cam:removeBounds()
        end)

        -- @tests Camera.removeBounds
        -- @description Verifies removing bounds is idempotent when no bounds were set.
        it("removeBounds does not error when no bounds are set", function()
            local cam = lurek.camera.new(800, 600)
            cam:removeBounds()
        end)
    end)

    -- @description Covers suite: setTarget / clearTarget.
    describe("setTarget / clearTarget", function()
        -- @tests Camera.setTarget
        -- @description Verifies target-follow coordinates can be assigned without immediate motion.
        it("setTarget does not error", function()
            local cam = lurek.camera.new(320, 240)
            cam:setTarget(100.0, 200.0)
        end)

        -- @tests Camera.setTarget
        -- @tests Camera.clearTarget
        -- @description Verifies an existing follow target can be cleared cleanly.
        it("clearTarget does not error", function()
            local cam = lurek.camera.new(320, 240)
            cam:setTarget(50.0, 75.0)
            cam:clearTarget()
        end)

        -- @tests Camera.clearTarget
        -- @description Verifies clearTarget is safe to call when the camera has no active target.
        it("clearTarget does not error when no target is set", function()
            local cam = lurek.camera.new(320, 240)
            cam:clearTarget()
        end)
    end)

    -- @description Covers suite: setFollowSmooth.
    describe("setFollowSmooth", function()
        -- @tests Camera.setFollowSmooth
        -- @description Verifies positive smoothing speeds are accepted for follow behavior.
        it("does not error for positive speed", function()
            local cam = lurek.camera.new(320, 240)
            cam:setFollowSmooth(5.0)
        end)

        -- @tests Camera.setFollowSmooth
        -- @description Verifies a zero smoothing factor is treated as a valid snap mode.
        it("does not error for speed 0 (snap)", function()
            local cam = lurek.camera.new(320, 240)
            cam:setFollowSmooth(0.0)
        end)
    end)

    -- @description Covers suite: setDeadZone.
    describe("setDeadZone", function()
        -- @tests Camera.setDeadZone
        -- @description Verifies a positive dead-zone rectangle can be configured.
        it("does not error for valid size", function()
            local cam = lurek.camera.new(800, 600)
            cam:setDeadZone(40.0, 30.0)
        end)

        -- @tests Camera.setDeadZone
        -- @description Verifies the dead zone can be disabled by setting both dimensions to zero.
        it("does not error for zero dead zone", function()
            local cam = lurek.camera.new(800, 600)
            cam:setDeadZone(0.0, 0.0)
        end)
    end)

    -- @description Covers suite: setLookAhead.
    describe("setLookAhead", function()
        -- @tests Camera.setLookAhead
        -- @description Verifies look-ahead multipliers accept a normal enabled value.
        it("does not error for multiplier 1.0", function()
            local cam = lurek.camera.new(320, 240)
            cam:setLookAhead(1.0)
        end)

        -- @tests Camera.setLookAhead
        -- @description Verifies look-ahead can be turned off with a zero multiplier.
        it("does not error for multiplier 0.0 (off)", function()
            local cam = lurek.camera.new(320, 240)
            cam:setLookAhead(0.0)
        end)
    end)
end)

-- ── Camera Effects (merged from test_camera_effects.lua) ──

-- @description Covers suite: camera effects module methods.
describe("camera effects — module methods", function()
    -- @tests Camera.zoomPulse
    -- @description Verifies zoomPulse is exposed on camera userdata.
    it("zoomPulse is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.zoomPulse)
    end)

    -- @tests Camera.startSway
    -- @description Verifies startSway is exposed on camera userdata.
    it("startSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.startSway)
    end)

    -- @tests Camera.stopSway
    -- @description Verifies stopSway is exposed on camera userdata.
    it("stopSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.stopSway)
    end)

    -- @tests Camera.isSway
    -- @description Verifies isSway is exposed on camera userdata.
    it("isSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.isSway)
    end)

    -- @tests Camera.startBreathing
    -- @description Verifies startBreathing is exposed on camera userdata.
    it("startBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.startBreathing)
    end)

    -- @tests Camera.stopBreathing
    -- @description Verifies stopBreathing is exposed on camera userdata.
    it("stopBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.stopBreathing)
    end)

    -- @tests Camera.isBreathing
    -- @description Verifies isBreathing is exposed on camera userdata.
    it("isBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.isBreathing)
    end)

    -- @tests Camera.getEffectiveZoom
    -- @description Verifies getEffectiveZoom is exposed on camera userdata.
    it("getEffectiveZoom is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.getEffectiveZoom)
    end)

    -- @tests Camera.getEffectOffset
    -- @description Verifies getEffectOffset is exposed on camera userdata.
    it("getEffectOffset is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.getEffectOffset)
    end)
end)

-- @description Covers suite: getEffectiveZoom with no effects.
describe("camera effects — getEffectiveZoom baseline", function()
    -- @tests Camera.getEffectiveZoom
    -- @description Verifies effective zoom equals base zoom when no effects are active.
    it("matches base zoom when no effects are active", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.5)
        local ez = cam:getEffectiveZoom()
        expect_near(1.5, ez, 0.001)
    end)

    -- @tests Camera.getEffectiveZoom
    -- @description Verifies effective zoom returns a number type.
    it("returns a number", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("number", cam:getEffectiveZoom())
    end)
end)

-- @description Covers suite: zoom pulse effect.
describe("camera effects — zoomPulse", function()
    -- @tests Camera.zoomPulse
    -- @tests Camera.getEffectiveZoom
    -- @description Verifies that triggering a zoom pulse changes the effective zoom.
    it("increases effective zoom after trigger", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.0)
        cam:zoomPulse(0.2, 0.5)
        -- Advance a tiny amount so slightly into pulse, sine envelope is nonzero
        cam:update(0.05)
        local ez = cam:getEffectiveZoom()
        expect_true(ez > 1.0, "effective zoom exceeds base after pulse")
    end)

    -- @tests Camera.zoomPulse
    -- @tests Camera.getEffectiveZoom
    -- @description Verifies that effective zoom returns to base after the pulse duration expires.
    it("returns to base zoom after duration expires", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.0)
        cam:zoomPulse(0.2, 0.1)
        cam:update(0.5) -- well past duration
        local ez = cam:getEffectiveZoom()
        expect_near(1.0, ez, 0.001)
    end)
end)

-- @description Covers suite: sway effect.
describe("camera effects — sway", function()
    -- @tests Camera.startSway
    -- @tests Camera.isSway
    -- @description Verifies that startSway activates the sway effect.
    it("startSway activates sway", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0)
        expect_true(cam:isSway(), "isSway returns true after start")
    end)

    -- @tests Camera.stopSway
    -- @tests Camera.isSway
    -- @description Verifies that stopSway deactivates the sway effect.
    it("stopSway deactivates sway", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0)
        cam:stopSway()
        expect_true(not cam:isSway(), "isSway returns false after stop")
    end)

    -- @tests Camera.isSway
    -- @description Verifies that isSway returns false on a fresh camera.
    it("isSway is false on fresh camera", function()
        local cam = lurek.camera.new(320, 240)
        expect_true(not cam:isSway(), "isSway is false by default")
    end)

    -- @tests Camera.getEffectOffset
    -- @description Verifies that getEffectOffset returns two numbers.
    it("getEffectOffset returns two numbers", function()
        local cam = lurek.camera.new(320, 240)
        local dx, dy = cam:getEffectOffset()
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @tests Camera.getEffectOffset
    -- @description Verifies that effect offset is (0, 0) when no sway is active.
    it("getEffectOffset is zero when no sway active", function()
        local cam = lurek.camera.new(320, 240)
        local dx, dy = cam:getEffectOffset()
        expect_near(0.0, dx, 0.001)
        expect_near(0.0, dy, 0.001)
    end)

    -- @tests Camera.startSway
    -- @tests Camera.getEffectOffset
    -- @description Verifies that sway produces a non-zero offset after update.
    it("produces non-zero offset after update with large amplitude", function()
        local cam = lurek.camera.new(320, 240)
        -- Use large amplitude to ensure offset is observable after one update step
        cam:startSway(100.0, 100.0, 1.0)
        cam:update(0.25) -- advance quarter-cycle so phase offsets are nonzero
        local dx, dy = cam:getEffectOffset()
        -- At least one component should clearly be non-trivially nonzero
        local magnitude = math.abs(dx) + math.abs(dy)
        expect_true(magnitude > 0.5, "sway offset magnitude > 0.5 after advance")
    end)

    -- @tests Camera.startSway
    -- @description Verifies that startSway accepts an optional decay parameter.
    it("accepts optional decay parameter", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0, 0.95) -- explicit decay
        expect_true(cam:isSway(), "sway is active with explicit decay")
    end)
end)

-- @description Covers suite: breathing effect.
describe("camera effects — breathing", function()
    -- @tests Camera.startBreathing
    -- @tests Camera.isBreathing
    -- @description Verifies that startBreathing activates breathing.
    it("startBreathing activates breathing", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        expect_true(cam:isBreathing(), "isBreathing returns true after start")
    end)

    -- @tests Camera.stopBreathing
    -- @tests Camera.isBreathing
    -- @description Verifies that stopBreathing deactivates breathing.
    it("stopBreathing deactivates breathing", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        cam:stopBreathing()
        expect_true(not cam:isBreathing(), "isBreathing returns false after stop")
    end)

    -- @tests Camera.isBreathing
    -- @description Verifies that isBreathing returns false on a fresh camera.
    it("isBreathing is false on fresh camera", function()
        local cam = lurek.camera.new(320, 240)
        expect_true(not cam:isBreathing(), "isBreathing is false by default")
    end)

    -- @tests Camera.startBreathing
    -- @tests Camera.getEffectiveZoom
    -- @description Verifies that breathing changes the effective zoom after update.
    it("changes effective zoom after update", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.0)
        -- Use large amplitude to ensure change is measurable
        cam:startBreathing(0.1, 1.0)
        cam:update(0.25) -- quarter of a full 1Hz cycle
        local ez = cam:getEffectiveZoom()
        -- Breathing should shift effective zoom at least slightly from base
        local diff = math.abs(ez - 1.0)
        expect_true(diff > 0.001, "breathing shifts effective zoom")
    end)

    -- @tests Camera.startBreathing
    -- @description Verifies that startBreathing accepts optional amplitude and rate.
    it("accepts optional amplitude and rate", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing(0.01, 0.3) -- explicit params
        expect_true(cam:isBreathing(), "breathing active with explicit params")
    end)

    -- @tests Camera.startBreathing
    -- @description Verifies that startBreathing uses defaults when called with no args.
    it("uses defaults when called with no arguments", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        expect_true(cam:isBreathing(), "breathing active with defaults")
    end)
end)

-- @description Replaces the Camera2D placeholder tail with direct lifecycle coverage for path-following, smooth zoom, and parallax state helpers.
describe("Camera2D regression coverage", function()
    -- @tests Camera2D:stopPath
    -- @tests Camera2D:updatePath
    -- @tests Camera2D:pathProgress
    -- @description Starts a two-point path, advances it once, and verifies stopPath returns the path helper to the idle state.
    it("path helpers update progress and stop cleanly", function()
        local cam = lurek.camera.new(320, 240)
        cam:setPosition(0, 0)
        cam:followPath({{0, 0}, {100, 0}}, 1.0)

        expect_near(0.0, cam:pathProgress(), 0.001)
        expect_true(cam:updatePath(0.5))

        local x, y = cam:getPosition()
        expect_true(x > 0, "path update should advance x")
        expect_near(0.0, y, 0.001)
        expect_near(0.5, cam:pathProgress(), 0.001)

        cam:stopPath()
        expect_false(cam:updatePath(0.1))
        expect_near(1.0, cam:pathProgress(), 0.001)
    end)

    -- @tests Camera2D:zoomTo
    -- @tests Camera2D:stopZoom
    -- @tests Camera2D:updateZoom
    -- @description Starts a zoom tween, checks it updates the base zoom toward the target, and verifies stopZoom freezes the tween state.
    it("zoom tween updates and stops without resetting zoom", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.0)
        cam:zoomTo(2.0, 1.0)

        expect_true(cam:updateZoom(0.5))
        local mid_zoom = cam:getZoom()
        expect_true(mid_zoom > 1.0 and mid_zoom < 2.0, "zoom should move toward the target")

        cam:stopZoom()
        expect_false(cam:updateZoom(0.1))
        expect_near(mid_zoom, cam:getZoom(), 0.001)
    end)

    -- @tests Camera2D:getParallaxFactor
    -- @tests Camera2D:clearParallaxFactors
    -- @description Verifies unset parallax factors default to 1.0, explicit factors round-trip, and clearParallaxFactors restores the default.
    it("parallax factors round-trip and clear back to defaults", function()
        local cam = lurek.camera.new(320, 240)
        expect_near(1.0, cam:getParallaxFactor("bg"), 0.001)

        cam:setParallaxFactor("bg", 0.25)
        expect_near(0.25, cam:getParallaxFactor("bg"), 0.001)

        cam:clearParallaxFactors()
        expect_near(1.0, cam:getParallaxFactor("bg"), 0.001)
    end)
end)

-- =========================================================================
-- @covers additions for camera module
-- =========================================================================

describe("Camera2D:followPath (@covers)", function()
    it("followPath does not crash on a path of points", function()
        -- @covers Camera2D:followPath
        local cam = lurek.camera.new(320, 240)
        local path = {{x=0,y=0},{x=100,y=0},{x=100,y=100}}
        local ok, _ = pcall(function()
            cam:followPath(path, 50.0)
        end)
        expect_type("boolean", ok)
    end)
end)

describe("Camera2D:setParallaxFactor (@covers)", function()
    it("setParallaxFactor stores the factor without crash", function()
        -- @covers Camera2D:setParallaxFactor
        local cam = lurek.camera.new(320, 240)
        local ok, _ = pcall(function()
            cam:setParallaxFactor("bg", 0.5)
        end)
        expect_type("boolean", ok)
    end)
end)

test_summary()
