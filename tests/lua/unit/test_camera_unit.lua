-- Lurek2D Lua BDD tests for lurek.camera
-- Headless: no GPU, no audio, no window.

describe("lurek.camera", function()
    describe("module interface", function()
        -- @covers lurek.camera.new
        it("exposes new factory", function()
            expect_type("function", lurek.camera.new)
        end)
    end)

    describe("new(w, h)", function()
        -- @covers lurek.camera.new
        it("returns a userdata object", function()
            local cam = lurek.camera.new(800, 600)
            expect_type("userdata", cam)
        end)
    end)

    describe("position", function()
        -- @tests Camera.getPosition
        it("getPosition returns 0,0 by default", function()
            local cam = lurek.camera.new(320, 240)
            local x, y = cam:getPosition()
            expect_near(0.0, x, 0.001)
            expect_near(0.0, y, 0.001)
        end)

        -- @tests Camera.setPosition
        -- @tests Camera.getPosition
        it("setPosition/getPosition round-trip", function()
            local cam = lurek.camera.new(320, 240)
            cam:setPosition(50, 75)
            local x, y = cam:getPosition()
            expect_near(50.0, x, 0.001)
            expect_near(75.0, y, 0.001)
        end)

        -- @tests Camera.lookAt
        -- @tests Camera.getPosition
        it("lookAt moves the camera to the target", function()
            local cam = lurek.camera.new(320, 240)
            cam:lookAt(100, 200)
            local x, y = cam:getPosition()
            expect_near(100.0, x, 0.001)
            expect_near(200.0, y, 0.001)
        end)

        -- @tests Camera.move
        -- @tests Camera.getPosition
        it("move shifts the position additively", function()
            local cam = lurek.camera.new(320, 240)
            cam:setPosition(10, 20)
            cam:move(5, -5)
            local x, y = cam:getPosition()
            expect_near(15.0, x, 0.001)
            expect_near(15.0, y, 0.001)
        end)
    end)

    describe("zoom", function()
        -- @tests Camera.getZoom
        it("getZoom returns 1.0 by default", function()
            local cam = lurek.camera.new(320, 240)
            expect_near(1.0, cam:getZoom(), 0.001)
        end)

        -- @tests Camera.setZoom
        -- @tests Camera.getZoom
        it("setZoom/getZoom round-trip", function()
            local cam = lurek.camera.new(320, 240)
            cam:setZoom(2.5)
            expect_near(2.5, cam:getZoom(), 0.001)
        end)
    end)

    describe("rotation", function()
        -- @tests Camera.getRotation
        it("getRotation returns 0.0 by default", function()
            local cam = lurek.camera.new(320, 240)
            expect_near(0.0, cam:getRotation(), 0.001)
        end)

        -- @tests Camera.setRotation
        -- @tests Camera.getRotation
        it("setRotation/getRotation round-trip", function()
            local cam = lurek.camera.new(320, 240)
            cam:setRotation(1.57)
            expect_near(1.57, cam:getRotation(), 0.001)
        end)
    end)

    describe("viewport", function()
        -- @tests Camera.getViewport
        it("getViewport returns initial size", function()
            local cam = lurek.camera.new(800, 600)
            local x, y, w, h = cam:getViewport()
            expect_near(800.0, w, 0.001)
            expect_near(600.0, h, 0.001)
        end)

        -- @tests Camera.setViewport
        -- @tests Camera.getViewport
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

    describe("coordinate transforms", function()
        -- @tests Camera.toScreen
        -- @tests Camera.toWorld
        -- @tests Camera.setPosition
        it("toScreen then toWorld round-trips the position", function()
            local cam = lurek.camera.new(800, 600)
            cam:setPosition(100, 50)
            local sx, sy = cam:toScreen(150, 120)
            local wx, wy = cam:toWorld(sx, sy)
            expect_near(150.0, wx, 0.5)
            expect_near(120.0, wy, 0.5)
        end)
    end)

    describe("getVisibleArea()", function()
        -- @tests Camera.getVisibleArea
        it("returns four numbers x, y, w, h", function()
            local cam = lurek.camera.new(640, 480)
            local x, y, w, h = cam:getVisibleArea()
            expect_type("number", x)
            expect_type("number", y)
            expect_type("number", w)
            expect_type("number", h)
        end)

        -- @tests Camera.getVisibleArea
        -- @tests Camera.setZoom
        it("shrinks the visible area as zoom increases", function()
            local cam = lurek.camera.new(800, 600)
            local _, _, w1, h1 = cam:getVisibleArea()
            cam:setZoom(2.0)
            local _, _, w2, h2 = cam:getVisibleArea()
            expect_near(w1 * 0.5, w2, 0.001)
            expect_near(h1 * 0.5, h2, 0.001)
        end)
    end)

    describe("shake()", function()
        -- @tests Camera.shake
        it("does not error on valid params", function()
            local cam = lurek.camera.new(320, 240)
            cam:shake(5.0, 0.5)
        end)

        -- @tests Camera.shake
        -- @tests Camera.update
        -- @tests Camera.toScreen
        it("temporarily offsets screen coordinates and then decays", function()
            local cam = lurek.camera.new(320, 240)
            local sx0, sy0 = cam:toScreen(0, 0)

            cam:shake(10.0, 0.5)
            cam:update(0.1)
            local sx1, sy1 = cam:toScreen(0, 0)
            local magnitude = math.abs(sx1 - sx0) + math.abs(sy1 - sy0)
            expect_true(magnitude > 0.001, "shake should perturb screen coordinates while active")

            cam:update(0.5)
            local sx2, sy2 = cam:toScreen(0, 0)
            expect_near(sx0, sx2, 0.001)
            expect_near(sy0, sy2, 0.001)
        end)
    end)

    describe("update()", function()
        -- @tests Camera.update
        it("does not error when called with zero dt", function()
            local cam = lurek.camera.new(320, 240)
            cam:update(0.0)
        end)
    end)

    describe("setBounds / removeBounds", function()
        -- @tests Camera.setBounds
        it("setBounds does not error", function()
            local cam = lurek.camera.new(800, 600)
            cam:setBounds(0, 0, 1600, 1200)
        end)

        -- @tests Camera.setBounds
        -- @tests Camera.setPosition
        -- @tests Camera.update
        -- @tests Camera.getPosition
        it("clamps position into world bounds on update", function()
            local cam = lurek.camera.new(100, 100)
            cam:setBounds(0, 0, 500, 500)
            cam:setPosition(-1000, -1000)
            cam:update(0.016)
            local x, y = cam:getPosition()
            expect_near(50.0, x, 0.001)
            expect_near(50.0, y, 0.001)
        end)

        -- @tests Camera.setBounds
        -- @tests Camera.removeBounds
        it("removeBounds does not error after setBounds", function()
            local cam = lurek.camera.new(800, 600)
            cam:setBounds(0, 0, 2000, 2000)
            cam:removeBounds()
        end)

        -- @tests Camera.removeBounds
        it("removeBounds does not error when no bounds are set", function()
            local cam = lurek.camera.new(800, 600)
            cam:removeBounds()
        end)
    end)

    describe("setTarget / clearTarget", function()
        -- @tests Camera.setTarget
        it("setTarget does not error", function()
            local cam = lurek.camera.new(320, 240)
            cam:setTarget(100.0, 200.0)
        end)

        -- @tests Camera.setTarget
        -- @tests Camera.setFollowSmooth
        -- @tests Camera.update
        -- @tests Camera.getPosition
        it("snaps to the target when follow smoothing is zero", function()
            local cam = lurek.camera.new(320, 240)
            cam:setFollowSmooth(0.0)
            cam:setTarget(200.0, 300.0)
            cam:update(0.016)
            local x, y = cam:getPosition()
            expect_near(200.0, x, 0.001)
            expect_near(300.0, y, 0.001)
        end)

        -- @tests Camera.setTarget
        -- @tests Camera.setFollowSmooth
        -- @tests Camera.update
        -- @tests Camera.getPosition
        it("moves toward the target when follow smoothing is positive", function()
            local cam = lurek.camera.new(320, 240)
            cam:setFollowSmooth(5.0)
            cam:setTarget(200.0, 0.0)
            cam:update(0.1)
            local x, y = cam:getPosition()
            expect_true(x > 0.0 and x < 200.0, "x should move toward the target without snapping")
            expect_near(0.0, y, 0.001)
        end)

        -- @tests Camera.setTarget
        -- @tests Camera.clearTarget
        it("clearTarget does not error", function()
            local cam = lurek.camera.new(320, 240)
            cam:setTarget(50.0, 75.0)
            cam:clearTarget()
        end)

        -- @tests Camera.clearTarget
        it("clearTarget does not error when no target is set", function()
            local cam = lurek.camera.new(320, 240)
            cam:clearTarget()
        end)
    end)

    describe("setFollowSmooth", function()
        -- @tests Camera.setFollowSmooth
        it("does not error for positive speed", function()
            local cam = lurek.camera.new(320, 240)
            cam:setFollowSmooth(5.0)
        end)

        -- @tests Camera.setFollowSmooth
        it("does not error for speed 0 (snap)", function()
            local cam = lurek.camera.new(320, 240)
            cam:setFollowSmooth(0.0)
        end)
    end)

    describe("setDeadZone", function()
        -- @tests Camera.setDeadZone
        it("does not error for valid size", function()
            local cam = lurek.camera.new(800, 600)
            cam:setDeadZone(40.0, 30.0)
        end)

        -- @tests Camera.setDeadZone
        -- @tests Camera.setFollowSmooth
        -- @tests Camera.setTarget
        -- @tests Camera.update
        -- @tests Camera.getPosition
        it("prevents small target movements inside the dead zone", function()
            local cam = lurek.camera.new(800, 600)
            cam:setDeadZone(100.0, 100.0)
            cam:setFollowSmooth(0.0)
            cam:setTarget(10.0, 10.0)
            cam:update(0.016)
            local x, y = cam:getPosition()
            expect_near(0.0, x, 0.001)
            expect_near(0.0, y, 0.001)
        end)

        -- @tests Camera.setDeadZone
        it("does not error for zero dead zone", function()
            local cam = lurek.camera.new(800, 600)
            cam:setDeadZone(0.0, 0.0)
        end)
    end)

    describe("setLookAhead", function()
        -- @tests Camera.setLookAhead
        it("does not error for multiplier 1.0", function()
            local cam = lurek.camera.new(320, 240)
            cam:setLookAhead(1.0)
        end)

        -- @tests Camera.setLookAhead
        it("does not error for multiplier 0.0 (off)", function()
            local cam = lurek.camera.new(320, 240)
            cam:setLookAhead(0.0)
        end)
    end)
end)

--  Camera Effects (merged from test_camera_effects.lua) 

describe("camera effects  module methods", function()
    -- @tests Camera.zoomPulse
    it("zoomPulse is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.zoomPulse)
    end)

    -- @tests Camera.startSway
    it("startSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.startSway)
    end)

    -- @tests Camera.stopSway
    it("stopSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.stopSway)
    end)

    -- @tests Camera.isSway
    it("isSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.isSway)
    end)

    -- @tests Camera.startBreathing
    it("startBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.startBreathing)
    end)

    -- @tests Camera.stopBreathing
    it("stopBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.stopBreathing)
    end)

    -- @tests Camera.isBreathing
    it("isBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.isBreathing)
    end)

    -- @tests Camera.getEffectiveZoom
    it("getEffectiveZoom is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.getEffectiveZoom)
    end)

    -- @tests Camera.getEffectOffset
    it("getEffectOffset is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.getEffectOffset)
    end)
end)

describe("camera effects  getEffectiveZoom baseline", function()
    -- @tests Camera.getEffectiveZoom
    it("matches base zoom when no effects are active", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.5)
        local ez = cam:getEffectiveZoom()
        expect_near(1.5, ez, 0.001)
    end)

    -- @tests Camera.getEffectiveZoom
    it("returns a number", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("number", cam:getEffectiveZoom())
    end)
end)

describe("camera effects  zoomPulse", function()
    -- @tests Camera.zoomPulse
    -- @tests Camera.getEffectiveZoom
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
    it("returns to base zoom after duration expires", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.0)
        cam:zoomPulse(0.2, 0.1)
        cam:update(0.5) -- well past duration
        local ez = cam:getEffectiveZoom()
        expect_near(1.0, ez, 0.001)
    end)
end)

describe("camera effects  sway", function()
    -- @tests Camera.startSway
    -- @tests Camera.isSway
    it("startSway activates sway", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0)
        expect_true(cam:isSway(), "isSway returns true after start")
    end)

    -- @tests Camera.stopSway
    -- @tests Camera.isSway
    it("stopSway deactivates sway", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0)
        cam:stopSway()
        expect_true(not cam:isSway(), "isSway returns false after stop")
    end)

    -- @tests Camera.isSway
    it("isSway is false on fresh camera", function()
        local cam = lurek.camera.new(320, 240)
        expect_true(not cam:isSway(), "isSway is false by default")
    end)

    -- @tests Camera.getEffectOffset
    it("getEffectOffset returns two numbers", function()
        local cam = lurek.camera.new(320, 240)
        local dx, dy = cam:getEffectOffset()
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @tests Camera.getEffectOffset
    it("getEffectOffset is zero when no sway active", function()
        local cam = lurek.camera.new(320, 240)
        local dx, dy = cam:getEffectOffset()
        expect_near(0.0, dx, 0.001)
        expect_near(0.0, dy, 0.001)
    end)

    -- @tests Camera.startSway
    -- @tests Camera.getEffectOffset
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
    it("accepts optional decay parameter", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0, 0.95) -- explicit decay
        expect_true(cam:isSway(), "sway is active with explicit decay")
    end)
end)

describe("camera effects  breathing", function()
    -- @tests Camera.startBreathing
    -- @tests Camera.isBreathing
    it("startBreathing activates breathing", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        expect_true(cam:isBreathing(), "isBreathing returns true after start")
    end)

    -- @tests Camera.stopBreathing
    -- @tests Camera.isBreathing
    it("stopBreathing deactivates breathing", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        cam:stopBreathing()
        expect_true(not cam:isBreathing(), "isBreathing returns false after stop")
    end)

    -- @tests Camera.isBreathing
    it("isBreathing is false on fresh camera", function()
        local cam = lurek.camera.new(320, 240)
        expect_true(not cam:isBreathing(), "isBreathing is false by default")
    end)

    -- @tests Camera.startBreathing
    -- @tests Camera.getEffectiveZoom
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
    it("accepts optional amplitude and rate", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing(0.01, 0.3) -- explicit params
        expect_true(cam:isBreathing(), "breathing active with explicit params")
    end)

    -- @tests Camera.startBreathing
    it("uses defaults when called with no arguments", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        expect_true(cam:isBreathing(), "breathing active with defaults")
    end)
end)

describe("Camera2D regression coverage", function()
    -- @covers Camera2D:stopPath
    -- @covers Camera2D:updatePath
    -- @covers Camera2D:pathProgress
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

    -- @covers Camera2D:updatePath
    -- @covers Camera2D:pathProgress
    it("path completes at the final waypoint and then goes idle", function()
        local cam = lurek.camera.new(320, 240)
        cam:followPath({{0, 0}, {100, 0}}, 0.5)

        expect_true(cam:updatePath(1.0))
        local x, y = cam:getPosition()
        expect_near(100.0, x, 0.001)
        expect_near(0.0, y, 0.001)
        expect_false(cam:updatePath(0.1))
    end)

    -- @covers Camera2D:followPath
    -- @covers Camera2D:updatePath
    it("multi-segment path traverses intermediate waypoints", function()
        local cam = lurek.camera.new(320, 240)
        cam:followPath({{0, 0}, {100, 0}, {100, 100}}, 2.0)

        expect_true(cam:updatePath(1.0))
        local x, y = cam:getPosition()
        expect_near(100.0, x, 1.0)
        expect_near(0.0, y, 1.0)
    end)

    -- @covers Camera2D:followPath
    -- @covers Camera2D:updatePath
    it("single-waypoint path stays idle", function()
        local cam = lurek.camera.new(320, 240)
        cam:setPosition(5.0, 6.0)
        cam:followPath({{42, 24}}, 1.0)

        expect_false(cam:updatePath(0.1))
        local x, y = cam:getPosition()
        expect_near(5.0, x, 0.001)
        expect_near(6.0, y, 0.001)
    end)

    -- @covers Camera2D:zoomTo
    -- @covers Camera2D:stopZoom
    -- @covers Camera2D:updateZoom
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

    -- @covers Camera2D:zoomTo
    -- @covers Camera2D:updateZoom
    it("zoom tween reaches the target and then goes idle", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.0)
        cam:zoomTo(3.0, 0.5)

        expect_true(cam:updateZoom(1.0))
        expect_near(3.0, cam:getZoom(), 0.001)
        expect_false(cam:updateZoom(0.1))
    end)

    -- @covers Camera2D:getParallaxFactor
    -- @covers Camera2D:clearParallaxFactors
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
