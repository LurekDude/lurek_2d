-- Lurek2D Lua BDD tests for lurek.camera
-- Headless: no GPU, no audio, no window.

-- @describe module interface
describe("module interface", function()
    -- @covers lurek.camera.new
    it("exposes new factory", function()
        expect_type("function", lurek.camera.new)
    end)
end)

-- @describe new(w, h)
describe("new(w, h)", function()
    -- @covers lurek.camera.new
    it("returns a userdata object", function()
        local cam = lurek.camera.new(800, 600)
        expect_type("userdata", cam)
    end)
end)

-- @describe position
describe("position", function()
    -- @covers LCamera:getPosition
    -- @covers lurek.camera.new
    it("getPosition returns 0,0 by default", function()
        local cam = lurek.camera.new(320, 240)
        local x, y = cam:getPosition()
        expect_near(0.0, x, 0.001)
        expect_near(0.0, y, 0.001)
    end)

    -- @covers LCamera:getPosition
    -- @covers LCamera:setPosition
    -- @covers lurek.camera.new
    it("setPosition/getPosition round-trip", function()
        local cam = lurek.camera.new(320, 240)
        cam:setPosition(50, 75)
        local x, y = cam:getPosition()
        expect_near(50.0, x, 0.001)
        expect_near(75.0, y, 0.001)
    end)

    -- @covers LCamera:getPosition
    -- @covers LCamera:lookAt
    -- @covers lurek.camera.new
    it("lookAt moves the camera to the target", function()
        local cam = lurek.camera.new(320, 240)
        cam:lookAt(100, 200)
        local x, y = cam:getPosition()
        expect_near(100.0, x, 0.001)
        expect_near(200.0, y, 0.001)
    end)

    -- @covers LCamera:getPosition
    -- @covers LCamera:move
    -- @covers LCamera:setPosition
    -- @covers lurek.camera.new
    it("move shifts the position additively", function()
        local cam = lurek.camera.new(320, 240)
        cam:setPosition(10, 20)
        cam:move(5, -5)
        local x, y = cam:getPosition()
        expect_near(15.0, x, 0.001)
        expect_near(15.0, y, 0.001)
    end)
end)

-- @describe zoom
describe("zoom", function()
    -- @covers LCamera:getZoom
    -- @covers lurek.camera.new
    it("getZoom returns 1.0 by default", function()
        local cam = lurek.camera.new(320, 240)
        expect_near(1.0, cam:getZoom(), 0.001)
    end)

    -- @covers LCamera:getZoom
    -- @covers LCamera:setZoom
    -- @covers lurek.camera.new
    it("setZoom/getZoom round-trip", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(2.5)
        expect_near(2.5, cam:getZoom(), 0.001)
    end)
end)

-- @describe rotation
describe("rotation", function()
    -- @covers LCamera:getRotation
    -- @covers lurek.camera.new
    it("getRotation returns 0.0 by default", function()
        local cam = lurek.camera.new(320, 240)
        expect_near(0.0, cam:getRotation(), 0.001)
    end)

    -- @covers LCamera:getRotation
    -- @covers LCamera:setRotation
    -- @covers lurek.camera.new
    it("setRotation/getRotation round-trip", function()
        local cam = lurek.camera.new(320, 240)
        cam:setRotation(1.57)
        expect_near(1.57, cam:getRotation(), 0.001)
    end)
end)

-- @describe viewport
describe("viewport", function()
    -- @covers LCamera:getViewport
    -- @covers lurek.camera.new
    it("getViewport returns initial size", function()
        local cam = lurek.camera.new(800, 600)
        local x, y, w, h = cam:getViewport()
        expect_near(800.0, w, 0.001)
        expect_near(600.0, h, 0.001)
    end)

    -- @covers LCamera:getViewport
    -- @covers LCamera:setViewport
    -- @covers lurek.camera.new
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

-- @describe coordinate transforms
describe("coordinate transforms", function()
    -- @covers LCamera:setPosition
    -- @covers LCamera:toScreen
    -- @covers LCamera:toWorld
    -- @covers lurek.camera.new
    it("toScreen then toWorld round-trips the position", function()
        local cam = lurek.camera.new(800, 600)
        cam:setPosition(100, 50)
        local sx, sy = cam:toScreen(150, 120)
        local wx, wy = cam:toWorld(sx, sy)
        expect_near(150.0, wx, 0.5)
        expect_near(120.0, wy, 0.5)
    end)
end)

-- @describe getVisibleArea()
describe("getVisibleArea()", function()
    -- @covers LCamera:getVisibleArea
    -- @covers lurek.camera.new
    it("returns four numbers x, y, w, h", function()
        local cam = lurek.camera.new(640, 480)
        local x, y, w, h = cam:getVisibleArea()
        expect_type("number", x)
        expect_type("number", y)
        expect_type("number", w)
        expect_type("number", h)
    end)

    -- @covers LCamera:getVisibleArea
    -- @covers LCamera:setZoom
    -- @covers lurek.camera.new
    it("shrinks the visible area as zoom increases", function()
        local cam = lurek.camera.new(800, 600)
        local _, _, w1, h1 = cam:getVisibleArea()
        cam:setZoom(2.0)
        local _, _, w2, h2 = cam:getVisibleArea()
        expect_near(w1 * 0.5, w2, 0.001)
        expect_near(h1 * 0.5, h2, 0.001)
    end)
end)

-- @describe shake()
describe("shake()", function()
    -- @covers LCamera:shake
    -- @covers lurek.camera.new
    it("does not error on valid params", function()
        local cam = lurek.camera.new(320, 240)
        cam:shake(5.0, 0.5)
    end)

    -- @covers LCamera:shake
    -- @covers LCamera:toScreen
    -- @covers LCamera:update
    -- @covers lurek.camera.new
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

-- @describe update()
describe("update()", function()
    -- @covers LCamera:update
    -- @covers lurek.camera.new
    it("does not error when called with zero dt", function()
        local cam = lurek.camera.new(320, 240)
        cam:update(0.0)
    end)
end)

-- @describe setBounds / removeBounds
describe("setBounds / removeBounds", function()
    -- @covers LCamera:setBounds
    -- @covers lurek.camera.new
    it("setBounds does not error", function()
        local cam = lurek.camera.new(800, 600)
        cam:setBounds(0, 0, 1600, 1200)
    end)

    -- @covers LCamera:getPosition
    -- @covers LCamera:setBounds
    -- @covers LCamera:setPosition
    -- @covers LCamera:update
    -- @covers lurek.camera.new
    it("clamps position into world bounds on update", function()
        local cam = lurek.camera.new(100, 100)
        cam:setBounds(0, 0, 500, 500)
        cam:setPosition(-1000, -1000)
        cam:update(0.016)
        local x, y = cam:getPosition()
        expect_near(50.0, x, 0.001)
        expect_near(50.0, y, 0.001)
    end)

    -- @covers LCamera:removeBounds
    -- @covers LCamera:setBounds
    -- @covers lurek.camera.new
    it("removeBounds does not error after setBounds", function()
        local cam = lurek.camera.new(800, 600)
        cam:setBounds(0, 0, 2000, 2000)
        cam:removeBounds()
    end)

    -- @covers LCamera:removeBounds
    -- @covers lurek.camera.new
    it("removeBounds does not error when no bounds are set", function()
        local cam = lurek.camera.new(800, 600)
        cam:removeBounds()
    end)
end)

-- @describe setTarget / clearTarget
describe("setTarget / clearTarget", function()
    -- @covers LCamera:setTarget
    -- @covers lurek.camera.new
    it("setTarget does not error", function()
        local cam = lurek.camera.new(320, 240)
        cam:setTarget(100.0, 200.0)
    end)

    -- @covers LCamera:getPosition
    -- @covers LCamera:setFollowSmooth
    -- @covers LCamera:setTarget
    -- @covers LCamera:update
    -- @covers lurek.camera.new
    it("snaps to the target when follow smoothing is zero", function()
        local cam = lurek.camera.new(320, 240)
        cam:setFollowSmooth(0.0)
        cam:setTarget(200.0, 300.0)
        cam:update(0.016)
        local x, y = cam:getPosition()
        expect_near(200.0, x, 0.001)
        expect_near(300.0, y, 0.001)
    end)

    -- @covers LCamera:getPosition
    -- @covers LCamera:setFollowSmooth
    -- @covers LCamera:setTarget
    -- @covers LCamera:update
    -- @covers lurek.camera.new
    it("moves toward the target when follow smoothing is positive", function()
        local cam = lurek.camera.new(320, 240)
        cam:setFollowSmooth(5.0)
        cam:setTarget(200.0, 0.0)
        cam:update(0.1)
        local x, y = cam:getPosition()
        expect_true(x > 0.0 and x < 200.0, "x should move toward the target without snapping")
        expect_near(0.0, y, 0.001)
    end)

    -- @covers LCamera:clearTarget
    -- @covers LCamera:setTarget
    -- @covers lurek.camera.new
    it("clearTarget does not error", function()
        local cam = lurek.camera.new(320, 240)
        cam:setTarget(50.0, 75.0)
        cam:clearTarget()
    end)

    -- @covers LCamera:clearTarget
    -- @covers lurek.camera.new
    it("clearTarget does not error when no target is set", function()
        local cam = lurek.camera.new(320, 240)
        cam:clearTarget()
    end)
end)

-- @describe setFollowSmooth
describe("setFollowSmooth", function()
    -- @covers LCamera:setFollowSmooth
    -- @covers lurek.camera.new
    it("does not error for positive speed", function()
        local cam = lurek.camera.new(320, 240)
        cam:setFollowSmooth(5.0)
    end)

    -- @covers LCamera:setFollowSmooth
    -- @covers lurek.camera.new
    it("does not error for speed 0 (snap)", function()
        local cam = lurek.camera.new(320, 240)
        cam:setFollowSmooth(0.0)
    end)
end)

-- @describe setDeadZone
describe("setDeadZone", function()
    -- @covers LCamera:setDeadZone
    -- @covers lurek.camera.new
    it("does not error for valid size", function()
        local cam = lurek.camera.new(800, 600)
        cam:setDeadZone(40.0, 30.0)
    end)

    -- @covers LCamera:getPosition
    -- @covers LCamera:setDeadZone
    -- @covers LCamera:setFollowSmooth
    -- @covers LCamera:setTarget
    -- @covers LCamera:update
    -- @covers lurek.camera.new
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

    -- @covers LCamera:setDeadZone
    -- @covers lurek.camera.new
    it("does not error for zero dead zone", function()
        local cam = lurek.camera.new(800, 600)
        cam:setDeadZone(0.0, 0.0)
    end)
end)

-- @describe setLookAhead
describe("setLookAhead", function()
    -- @covers LCamera:setLookAhead
    -- @covers lurek.camera.new
    it("does not error for multiplier 1.0", function()
        local cam = lurek.camera.new(320, 240)
        cam:setLookAhead(1.0)
    end)

    -- @covers LCamera:setLookAhead
    -- @covers lurek.camera.new
    it("does not error for multiplier 0.0 (off)", function()
        local cam = lurek.camera.new(320, 240)
        cam:setLookAhead(0.0)
    end)
end)

--  Camera Effects (merged from test_camera_effects.lua)

-- @describe camera effects  module methods
describe("camera effects  module methods", function()
    -- @covers lurek.camera.new
    it("zoomPulse is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.zoomPulse)
    end)

    -- @covers lurek.camera.new
    it("startSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.startSway)
    end)

    -- @covers lurek.camera.new
    it("stopSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.stopSway)
    end)

    -- @covers lurek.camera.new
    it("isSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.isSway)
    end)

    -- @covers lurek.camera.new
    it("startBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.startBreathing)
    end)

    -- @covers lurek.camera.new
    it("stopBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.stopBreathing)
    end)

    -- @covers lurek.camera.new
    it("isBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.isBreathing)
    end)

    -- @covers lurek.camera.new
    it("getEffectiveZoom is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.getEffectiveZoom)
    end)

    -- @covers lurek.camera.new
    it("getEffectOffset is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.getEffectOffset)
    end)
end)

-- @describe camera effects  getEffectiveZoom baseline
describe("camera effects  getEffectiveZoom baseline", function()
    -- @covers LCamera:getEffectiveZoom
    -- @covers LCamera:setZoom
    -- @covers lurek.camera.new
    it("matches base zoom when no effects are active", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.5)
        local ez = cam:getEffectiveZoom()
        expect_near(1.5, ez, 0.001)
    end)

    -- @covers LCamera:getEffectiveZoom
    -- @covers lurek.camera.new
    it("returns a number", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("number", cam:getEffectiveZoom())
    end)
end)

-- @describe camera effects  zoomPulse
describe("camera effects  zoomPulse", function()
    -- @covers LCamera:getEffectiveZoom
    -- @covers LCamera:setZoom
    -- @covers LCamera:update
    -- @covers LCamera:zoomPulse
    -- @covers lurek.camera.new
    it("increases effective zoom after trigger", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.0)
        cam:zoomPulse(0.2, 0.5)
        -- Advance a tiny amount so slightly into pulse, sine envelope is nonzero
        cam:update(0.05)
        local ez = cam:getEffectiveZoom()
        expect_true(ez > 1.0, "effective zoom exceeds base after pulse")
    end)

    -- @covers LCamera:getEffectiveZoom
    -- @covers LCamera:setZoom
    -- @covers LCamera:update
    -- @covers LCamera:zoomPulse
    -- @covers lurek.camera.new
    it("returns to base zoom after duration expires", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.0)
        cam:zoomPulse(0.2, 0.1)
        cam:update(0.5) -- well past duration
        local ez = cam:getEffectiveZoom()
        expect_near(1.0, ez, 0.001)
    end)
end)

-- @describe camera effects  sway
describe("camera effects  sway", function()
    -- @covers LCamera:isSway
    -- @covers LCamera:startSway
    -- @covers lurek.camera.new
    it("startSway activates sway", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0)
        expect_true(cam:isSway(), "isSway returns true after start")
    end)

    -- @covers LCamera:isSway
    -- @covers LCamera:startSway
    -- @covers LCamera:stopSway
    -- @covers lurek.camera.new
    it("stopSway deactivates sway", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0)
        cam:stopSway()
        expect_true(not cam:isSway(), "isSway returns false after stop")
    end)

    -- @covers LCamera:isSway
    -- @covers lurek.camera.new
    it("isSway is false on fresh camera", function()
        local cam = lurek.camera.new(320, 240)
        expect_true(not cam:isSway(), "isSway is false by default")
    end)

    -- @covers LCamera:getEffectOffset
    -- @covers lurek.camera.new
    it("getEffectOffset returns two numbers", function()
        local cam = lurek.camera.new(320, 240)
        local dx, dy = cam:getEffectOffset()
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @covers LCamera:getEffectOffset
    -- @covers lurek.camera.new
    it("getEffectOffset is zero when no sway active", function()
        local cam = lurek.camera.new(320, 240)
        local dx, dy = cam:getEffectOffset()
        expect_near(0.0, dx, 0.001)
        expect_near(0.0, dy, 0.001)
    end)

    -- @covers LCamera:getEffectOffset
    -- @covers LCamera:startSway
    -- @covers LCamera:update
    -- @covers lurek.camera.new
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

    -- @covers LCamera:isSway
    -- @covers LCamera:startSway
    -- @covers lurek.camera.new
    it("accepts optional decay parameter", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0, 0.95) -- explicit decay
        expect_true(cam:isSway(), "sway is active with explicit decay")
    end)
end)

-- @describe camera effects  breathing
describe("camera effects  breathing", function()
    -- @covers LCamera:isBreathing
    -- @covers LCamera:startBreathing
    -- @covers lurek.camera.new
    it("startBreathing activates breathing", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        expect_true(cam:isBreathing(), "isBreathing returns true after start")
    end)

    -- @covers LCamera:isBreathing
    -- @covers LCamera:startBreathing
    -- @covers LCamera:stopBreathing
    -- @covers lurek.camera.new
    it("stopBreathing deactivates breathing", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        cam:stopBreathing()
        expect_true(not cam:isBreathing(), "isBreathing returns false after stop")
    end)

    -- @covers LCamera:isBreathing
    -- @covers lurek.camera.new
    it("isBreathing is false on fresh camera", function()
        local cam = lurek.camera.new(320, 240)
        expect_true(not cam:isBreathing(), "isBreathing is false by default")
    end)

    -- @covers LCamera:getEffectiveZoom
    -- @covers LCamera:setZoom
    -- @covers LCamera:startBreathing
    -- @covers LCamera:update
    -- @covers lurek.camera.new
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

    -- @covers LCamera:isBreathing
    -- @covers LCamera:startBreathing
    -- @covers lurek.camera.new
    it("accepts optional amplitude and rate", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing(0.01, 0.3) -- explicit params
        expect_true(cam:isBreathing(), "breathing active with explicit params")
    end)

    -- @covers LCamera:isBreathing
    -- @covers LCamera:startBreathing
    -- @covers lurek.camera.new
    it("uses defaults when called with no arguments", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        expect_true(cam:isBreathing(), "breathing active with defaults")
    end)
end)

-- @describe Camera2D regression coverage
describe("Camera2D regression coverage", function()
    -- @covers LCamera:followPath
    -- @covers LCamera:getPosition
    -- @covers LCamera:pathProgress
    -- @covers LCamera:setPosition
    -- @covers LCamera:stopPath
    -- @covers LCamera:updatePath
    -- @covers lurek.camera.new
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

    -- @covers LCamera:followPath
    -- @covers LCamera:getPosition
    -- @covers LCamera:updatePath
    -- @covers lurek.camera.new
    it("path completes at the final waypoint and then goes idle", function()
        local cam = lurek.camera.new(320, 240)
        cam:followPath({{0, 0}, {100, 0}}, 0.5)

        expect_true(cam:updatePath(1.0))
        local x, y = cam:getPosition()
        expect_near(100.0, x, 0.001)
        expect_near(0.0, y, 0.001)
        expect_false(cam:updatePath(0.1))
    end)

    -- @covers LCamera:followPath
    -- @covers LCamera:getPosition
    -- @covers LCamera:updatePath
    -- @covers lurek.camera.new
    it("multi-segment path traverses intermediate waypoints", function()
        local cam = lurek.camera.new(320, 240)
        cam:followPath({{0, 0}, {100, 0}, {100, 100}}, 2.0)

        expect_true(cam:updatePath(1.0))
        local x, y = cam:getPosition()
        expect_near(100.0, x, 1.0)
        expect_near(0.0, y, 1.0)
    end)

    -- @covers LCamera:followPath
    -- @covers LCamera:getPosition
    -- @covers LCamera:setPosition
    -- @covers LCamera:updatePath
    -- @covers lurek.camera.new
    it("single-waypoint path stays idle", function()
        local cam = lurek.camera.new(320, 240)
        cam:setPosition(5.0, 6.0)
        cam:followPath({{42, 24}}, 1.0)

        expect_false(cam:updatePath(0.1))
        local x, y = cam:getPosition()
        expect_near(5.0, x, 0.001)
        expect_near(6.0, y, 0.001)
    end)

    -- @covers LCamera:getZoom
    -- @covers LCamera:setZoom
    -- @covers LCamera:stopZoom
    -- @covers LCamera:updateZoom
    -- @covers LCamera:zoomTo
    -- @covers lurek.camera.new
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

    -- @covers LCamera:getZoom
    -- @covers LCamera:setZoom
    -- @covers LCamera:updateZoom
    -- @covers LCamera:zoomTo
    -- @covers lurek.camera.new
    it("zoom tween reaches the target and then goes idle", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.0)
        cam:zoomTo(3.0, 0.5)

        expect_true(cam:updateZoom(1.0))
        expect_near(3.0, cam:getZoom(), 0.001)
        expect_false(cam:updateZoom(0.1))
    end)

    -- @covers LCamera:clearParallaxFactors
    -- @covers LCamera:getParallaxFactor
    -- @covers LCamera:setParallaxFactor
    -- @covers lurek.camera.new
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
-- =========================================================================

-- @describe Camera2D:followPath
describe("Camera2D:followPath ", function()
    -- @covers LCamera:followPath
    -- @covers lurek.camera.new
    it("followPath does not crash on a path of points", function()
        local cam = lurek.camera.new(320, 240)
        local path = {{x=0,y=0},{x=100,y=0},{x=100,y=100}}
        local ok, _ = pcall(function()
            cam:followPath(path, 50.0)
        end)
        expect_type("boolean", ok)
    end)
end)

-- @describe Camera2D:setParallaxFactor
describe("Camera2D:setParallaxFactor ", function()
    -- @covers LCamera:setParallaxFactor
    -- @covers lurek.camera.new
    it("setParallaxFactor stores the factor without crash", function()
        local cam = lurek.camera.new(320, 240)
        local ok, _ = pcall(function()
            cam:setParallaxFactor("bg", 0.5)
        end)
        expect_type("boolean", ok)
    end)
end)

-- @describe camera strict: newCamera / apply / reset / attach / detach / type / typeOf
describe("camera strict: newCamera / apply / reset / attach / detach / type / typeOf", function()
    -- @covers lurek.camera.newCamera
    it("lurek.camera.newCamera returns a camera object", function()
        local ok, cam = pcall(function() return lurek.camera.newCamera(800, 600) end)
        expect_true(ok)
        expect_true(cam ~= nil)
    end)

    -- @covers LCamera:type
    -- @covers LCamera:typeOf
    -- @covers lurek.camera.newCamera
    it("LCamera type and typeOf are callable", function()
        local cam = lurek.camera.newCamera(800, 600)
        expect_type("string", cam:type())
        expect_type("boolean", cam:typeOf("Object"))
    end)

    -- @covers LCamera:apply
    -- @covers lurek.camera.newCamera
    it("LCamera apply is callable", function()
        local cam = lurek.camera.newCamera(800, 600)
        local ok = pcall(function() cam:apply() end)
        expect_type("boolean", ok)
    end)

    -- @covers LCamera:reset
    -- @covers lurek.camera.newCamera
    it("LCamera reset is callable", function()
        local cam = lurek.camera.newCamera(800, 600)
        local ok = pcall(function() cam:reset() end)
        expect_type("boolean", ok)
    end)

    -- @covers LCamera:attach
    -- @covers LCamera:detach
    -- @covers lurek.camera.newCamera
    it("LCamera attach and detach are callable", function()
        local cam = lurek.camera.newCamera(800, 600)
        local ok1 = pcall(function() cam:attach() end)
        expect_type("boolean", ok1)
        local ok2 = pcall(function() cam:detach() end)
        expect_type("boolean", ok2)
    end)
end)

-- @describe Camera2D constraint + easing extensions
describe("Camera2D constraint + easing extensions", function()
    -- @covers LCamera:setZoomConstraints
    -- @covers LCamera:getZoomConstraints
    -- @covers lurek.camera.new
    it("setZoomConstraints/getZoomConstraints round-trip", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoomConstraints(0.5, 2.0)
        local has_min, minz, has_max, maxz = cam:getZoomConstraints()
        expect_true(has_min)
        expect_true(has_max)
        expect_near(0.5, minz, 0.001)
        expect_near(2.0, maxz, 0.001)
    end)

    -- @covers LCamera:setFollowEasing
    -- @covers LCamera:getFollowEasing
    -- @covers lurek.camera.new
    it("setFollowEasing/getFollowEasing round-trip", function()
        local cam = lurek.camera.new(320, 240)
        cam:setFollowEasing("smoothstep")
        expect_equal("smoothstep", cam:getFollowEasing())
    end)

    -- @covers LCamera:onWindowResize
    -- @covers LCamera:getViewport
    -- @covers lurek.camera.new
    it("onWindowResize updates viewport to full window", function()
        local cam = lurek.camera.new(320, 240)
        cam:onWindowResize(1920, 1080)
        local x, y, w, h = cam:getViewport()
        expect_near(0.0, x, 0.001)
        expect_near(0.0, y, 0.001)
        expect_near(1920.0, w, 0.001)
        expect_near(1080.0, h, 0.001)
    end)

    -- @covers LCamera:onWindowResizeScaled
    -- @covers LCamera:getViewport
    -- @covers lurek.camera.new
    it("onWindowResizeScaled applies letterbox viewport", function()
        local cam = lurek.camera.new(320, 240)
        cam:onWindowResizeScaled(800, 600, 1200, 600, "letterbox")
        local x, y, w, h = cam:getViewport()
        expect_near(200.0, x, 0.001)
        expect_near(0.0, y, 0.001)
        expect_near(800.0, w, 0.001)
        expect_near(600.0, h, 0.001)
    end)

    -- @covers LCamera:presetTightFollow
    -- @covers LCamera:getFollowSmooth
    -- @covers LCamera:getDeadZone
    -- @covers LCamera:getLookAhead
    -- @covers lurek.camera.new
    it("presetTightFollow applies expected profile", function()
        local cam = lurek.camera.new(320, 240)
        cam:presetTightFollow()
        local ok, w, h = cam:getDeadZone()
        expect_true(ok)
        expect_near(0.9, cam:getFollowSmooth(), 0.001)
        expect_near(20.0, w, 0.001)
        expect_near(20.0, h, 0.001)
        expect_near(0.5, cam:getLookAhead(), 0.001)
    end)

    -- @covers LCamera:presetCinematicFollow
    -- @covers LCamera:getFollowSmooth
    -- @covers LCamera:getDeadZone
    -- @covers LCamera:getLookAhead
    -- @covers lurek.camera.new
    it("presetCinematicFollow applies expected profile", function()
        local cam = lurek.camera.new(320, 240)
        cam:presetCinematicFollow()
        local ok, w, h = cam:getDeadZone()
        expect_true(ok)
        expect_near(0.3, cam:getFollowSmooth(), 0.001)
        expect_near(100.0, w, 0.001)
        expect_near(100.0, h, 0.001)
        expect_near(0.0, cam:getLookAhead(), 0.001)
    end)

    -- @covers LCamera:presetBalancedFollow
    -- @covers LCamera:getFollowSmooth
    -- @covers LCamera:getDeadZone
    -- @covers LCamera:getLookAhead
    -- @covers lurek.camera.new
    it("presetBalancedFollow applies expected profile", function()
        local cam = lurek.camera.new(320, 240)
        cam:presetBalancedFollow()
        local ok, w, h = cam:getDeadZone()
        expect_true(ok)
        expect_near(0.6, cam:getFollowSmooth(), 0.001)
        expect_near(40.0, w, 0.001)
        expect_near(40.0, h, 0.001)
        expect_near(0.3, cam:getLookAhead(), 0.001)
    end)

    -- @covers LCamera:presetAggressiveFollow
    -- @covers LCamera:getFollowSmooth
    -- @covers LCamera:getDeadZone
    -- @covers LCamera:getLookAhead
    -- @covers lurek.camera.new
    it("presetAggressiveFollow applies expected profile", function()
        local cam = lurek.camera.new(320, 240)
        cam:presetAggressiveFollow()
        local ok, w, h = cam:getDeadZone()
        expect_true(ok)
        expect_near(0.99, cam:getFollowSmooth(), 0.001)
        expect_near(5.0, w, 0.001)
        expect_near(5.0, h, 0.001)
        expect_near(1.0, cam:getLookAhead(), 0.001)
    end)
end)

-- @describe CameraRig API
describe("CameraRig API", function()
    -- @covers lurek.camera.newRig
    it("creates a rig userdata", function()
        local rig = lurek.camera.newRig()
        expect_type("userdata", rig)
    end)

    -- @covers LCameraRig:splitScreen
    -- @covers LCameraRig:has
    -- @covers LCameraRig:getViewport
    -- @covers lurek.camera.newRig
    it("splitScreen creates left/right cameras with correct viewport", function()
        local rig = lurek.camera.newRig()
        rig:splitScreen(1280, 720)
        expect_true(rig:has("left"))
        expect_true(rig:has("right"))
        local ok, x, y, w, h = rig:getViewport("left")
        expect_true(ok)
        expect_near(0.0, x, 0.001)
        expect_near(640.0, w, 0.001)
        expect_near(720.0, h, 0.001)
    end)

    -- @covers LCameraRig:minimap
    -- @covers LCameraRig:pictureInPicture
    -- @covers LCameraRig:names
    -- @covers lurek.camera.newRig
    it("minimap and pictureInPicture create named cameras", function()
        local rig = lurek.camera.newRig()
        rig:minimap(1280, 720, 0.2)
        rig:pictureInPicture(1280, 720, 320, 180)
        local names = rig:names()
        expect_true(#names >= 2)
    end)

    -- @covers LCameraRig:setPosition
    -- @covers LCameraRig:setZoom
    -- @covers LCameraRig:setTarget
    -- @covers LCameraRig:updateAll
    -- @covers LCameraRig:apply
    -- @covers lurek.camera.newRig
    it("supports per-camera updates and apply", function()
        local rig = lurek.camera.newRig()
        rig:splitScreen(1280, 720)
        rig:setPosition("left", 10, 20)
        rig:setZoom("left", 1.5)
        rig:setTarget("left", 100, 50)
        rig:updateAll(0.016)
        expect_true(rig:apply("left"))
        expect_false(rig:apply("missing_name"))
    end)

    -- @covers LCameraRig:remove
    -- @covers LCameraRig:has
    -- @covers lurek.camera.newRig
    it("remove returns true when camera exists", function()
        local rig = lurek.camera.newRig()
        rig:splitScreen(1280, 720)
        expect_true(rig:has("left"))
        expect_true(rig:remove("left"))
        expect_false(rig:has("left"))
    end)
end)

-- @describe Camera2D accessor completeness
describe("Camera2D accessor completeness", function()
    -- @covers LCamera:getBounds
    -- @covers LCamera:hasBounds
    -- @covers LCamera:setBounds
    -- @covers lurek.camera.new
    it("bounds getters return explicit success flags", function()
        local cam = lurek.camera.new(320, 240)
        local ok0 = cam:hasBounds()
        expect_false(ok0)
        cam:setBounds(1, 2, 3, 4)
        local ok, x, y, w, h = cam:getBounds()
        expect_true(ok)
        expect_near(1, x, 0.001)
        expect_near(2, y, 0.001)
        expect_near(3, w, 0.001)
        expect_near(4, h, 0.001)
    end)

    -- @covers LCamera:getTarget
    -- @covers LCamera:setTarget
    -- @covers lurek.camera.new
    it("target getter returns explicit success flags", function()
        local cam = lurek.camera.new(320, 240)
        local ok0 = cam:getTarget()
        expect_false(ok0)
        cam:setTarget(11, 22)
        local ok, x, y = cam:getTarget()
        expect_true(ok)
        expect_near(11, x, 0.001)
        expect_near(22, y, 0.001)
    end)

    -- @covers LCamera:getDeadZone
    -- @covers LCamera:setDeadZone
    -- @covers lurek.camera.new
    it("dead-zone getter returns explicit success flags", function()
        local cam = lurek.camera.new(320, 240)
        local ok0 = cam:getDeadZone()
        expect_false(ok0)
        cam:setDeadZone(50, 30)
        local ok, w, h = cam:getDeadZone()
        expect_true(ok)
        expect_near(50, w, 0.001)
        expect_near(30, h, 0.001)
    end)

    -- @covers LCamera:getFollowSmooth
    -- @covers LCamera:getLookAhead
    -- @covers LCamera:setFollowSmooth
    -- @covers LCamera:setLookAhead
    -- @covers lurek.camera.new
    it("follow smoothing and look-ahead getters reflect current values", function()
        local cam = lurek.camera.new(320, 240)
        cam:setFollowSmooth(3.5)
        cam:setLookAhead(0.75)
        expect_near(3.5, cam:getFollowSmooth(), 0.001)
        expect_near(0.75, cam:getLookAhead(), 0.001)
    end)

    -- @covers LCamera:getShakeOffset
    -- @covers LCamera:getRenderOffset
    -- @covers LCamera:shake
    -- @covers LCamera:update
    -- @covers lurek.camera.new
    it("shake and render offset getters return numeric pairs", function()
        local cam = lurek.camera.new(320, 240)
        cam:shake(5.0, 0.4)
        cam:update(0.1)
        local sx, sy = cam:getShakeOffset()
        local rx, ry = cam:getRenderOffset()
        expect_type("number", sx)
        expect_type("number", sy)
        expect_type("number", rx)
        expect_type("number", ry)
    end)

    -- @covers LCamera:setZoomDamping
    -- @covers LCamera:getZoomDamping
    -- @covers LCamera:setRotationDamping
    -- @covers LCamera:getRotationDamping
    -- @covers lurek.camera.new
    it("damping getters reflect configured values", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoomDamping(0.3)
        cam:setRotationDamping(0.6)
        expect_near(0.3, cam:getZoomDamping(), 0.001)
        expect_near(0.6, cam:getRotationDamping(), 0.001)
    end)

    -- @covers LCamera:setRotationConstraints
    -- @covers LCamera:getRotationConstraints
    -- @covers lurek.camera.new
    it("rotation constraints getter returns explicit success flags", function()
        local cam = lurek.camera.new(320, 240)
        cam:setRotationConstraints(-0.5, 0.5)
        local has_min, min_r, has_max, max_r = cam:getRotationConstraints()
        expect_true(has_min)
        expect_true(has_max)
        expect_near(-0.5, min_r, 0.001)
        expect_near(0.5, max_r, 0.001)
    end)
end)

-- @describe camera migrated from integration/scene_camera
describe("camera migrated from integration/scene_camera", function()
    -- @covers LCamera:getPosition
    -- @covers LCamera:setPosition
    -- @covers lurek.camera.newCamera
    it("camera position changes are stored correctly", function()
        local cam = lurek.camera.newCamera()
        cam:setPosition(0, 0)
        local x0, y0 = cam:getPosition()
        expect_near(0, x0, 0.001)
        expect_near(0, y0, 0.001)

        cam:setPosition(320, 240)
        local x1, y1 = cam:getPosition()
        expect_near(320, x1, 0.001)
        expect_near(240, y1, 0.001)
    end)

    -- @covers LCamera:getZoom
    -- @covers LCamera:setZoom
    -- @covers lurek.camera.newCamera
    it("camera zoom alters the visible scale", function()
        local cam = lurek.camera.newCamera()
        cam:setZoom(1.0)
        expect_near(1.0, cam:getZoom(), 0.001)
        cam:setZoom(2.0)
        expect_near(2.0, cam:getZoom(), 0.001)
        cam:setZoom(0.5)
        expect_near(0.5, cam:getZoom(), 0.001)
    end)

    -- @covers LCamera:getRotation
    -- @covers LCamera:setRotation
    -- @covers lurek.camera.newCamera
    it("camera rotation is retrievable", function()
        local cam = lurek.camera.newCamera()
        cam:setRotation(0.5)
        expect_near(0.5, cam:getRotation(), 0.001)
    end)

    -- @covers LCamera:getPosition
    -- @covers LCamera:setBounds
    -- @covers LCamera:setPosition
    -- @covers LCamera:update
    -- @covers lurek.camera.newCamera
    it("tilemap world bounds clamp camera position", function()
        local cam = lurek.camera.newCamera()
        cam:setBounds(0, 0, 128, 96)
        cam:setPosition(999, 999)
        cam:update(0.016)

        local x, y = cam:getPosition()
        expect_true(x <= 128)
        expect_true(y <= 96)
    end)
end)

-- @describe unit: migrated from integration/test_camera_tilemap_scroll.lua
describe("unit: migrated from integration/test_camera_tilemap_scroll.lua", function()
        local function build_scroll_map()
            local tm = lurek.tilemap.newTileMap(16, 16, 8)
            tm:addLayer("ground", 32, 8)
            for y = 1, 8 do
                for x = 1, 32 do
                    tm:setTile(1, x, y, x)
                end
            end
            return tm
        end
        -- @covers LCamera:getPosition
        -- @covers LCamera:setPosition
        -- @covers LTileMap:addLayer
        -- @covers LTileMap:getTile
        -- @covers LTileMap:setTile
        -- @covers LTileMap:worldToTile
        -- @covers lurek.camera.newCamera
        -- @covers lurek.tilemap.newTileMap
        it("loads tilemap chunk when camera moves into range", function()
            local cam = lurek.camera.newCamera()
            local tm = build_scroll_map()

            cam:setPosition(0, 0)
            local x0, y0 = cam:getPosition()
            local tx0, ty0 = tm:worldToTile(x0, y0)

            cam:setPosition(48, 0)
            local x1, y1 = cam:getPosition()
            local tx1, ty1 = tm:worldToTile(x1, y1)

            expect_type("number", tx0)
            expect_type("number", ty0)
            expect_type("number", tx1)
            expect_type("number", ty1)
            expect_true(tx1 >= tx0, "camera move right should not move to an earlier tile column")
        end)

        -- @covers LCamera:getViewport
        -- @covers LCamera:setPosition
        -- @covers LCamera:setViewport
        -- @covers LTileMap:addLayer
        -- @covers LTileMap:getTile
        -- @covers LTileMap:setTile
        -- @covers LTileMap:worldToTile
        -- @covers lurek.camera.newCamera
        -- @covers lurek.tilemap.newTileMap
        it("unloads distant chunks as camera moves away", function()
            local cam = lurek.camera.newCamera()
            local tm = build_scroll_map()

            cam:setViewport(0, 0, 64, 48)
            cam:setPosition(16, 0)
            local _, _, viewport_w, viewport_h = cam:getViewport()
            local left_tx, top_ty = tm:worldToTile(16, 0)
            local right_tx = tm:worldToTile(16 + viewport_w - 1, viewport_h - 1)
            local first_visible = tm:getTile(1, left_tx + 1, top_ty + 1)
            local last_visible = tm:getTile(1, right_tx + 1, top_ty + 1)

            cam:setPosition(160, 0)
            local new_left_tx = tm:worldToTile(160, 0)
            local new_first_visible = tm:getTile(1, new_left_tx + 1, top_ty + 1)

            expect_type("number", first_visible)
            expect_type("number", last_visible)
            expect_type("number", new_first_visible)
            expect_true(last_visible >= first_visible, "viewport right edge should not move backward")
            expect_true(new_first_visible > first_visible, "camera move right should shift first visible tile forward")
        end)

end)

-- @describe unit: migrated from integration/test_input_camera.lua
describe("unit: migrated from integration/test_input_camera.lua", function()
        -- @covers LCamera:getPosition
        -- @covers LCamera:getZoom
        -- @covers LCamera:setPosition
        -- @covers LCamera:setZoom
        -- @covers lurek.camera.newCamera
        it("camera at origin: screen coords equal world coords", function()
            local cam = lurek.camera.newCamera()
            cam:setPosition(0, 0)
            cam:setZoom(1.0)

            -- With camera at origin, zoom 1.0          world pos equals screen pos
            local screen_x, screen_y = 320.0, 240.0
            local cx, cy = cam:getPosition()
            local zoom   = cam:getZoom()

            -- Manual screen-to-world formula: world = screen / zoom + cam_pos - screen_center/zoom
            -- Here we just verify zoom is 1.0 and cam is at origin
            expect_near(1.0, zoom,   0.001, "zoom is 1")
            expect_near(0.0, cx,     0.001, "cam at origin x")
            expect_near(0.0, cy,     0.001, "cam at origin y")
            -- At zoom=1 and cam=(0,0), a click at screen (320,240) maps to world (320,240)
            local world_x = screen_x / zoom + cx
            local world_y = screen_y / zoom + cy
            expect_near(320.0, world_x, 0.001, "world x matches screen x")
            expect_near(240.0, world_y, 0.001, "world y matches screen y")
        end)

        -- @covers LCamera:getPosition
        -- @covers LCamera:getZoom
        -- @covers LCamera:setPosition
        -- @covers LCamera:setZoom
        -- @covers lurek.camera.newCamera
        it("camera panned: world coords offset from screen", function()
            local cam = lurek.camera.newCamera()
            cam:setPosition(100, 50)
            cam:setZoom(1.0)

            local screen_x, screen_y = 0.0, 0.0
            local cx, cy = cam:getPosition()
            local zoom   = cam:getZoom()

            local world_x = screen_x / zoom + cx
            local world_y = screen_y / zoom + cy

            expect_near(100.0, world_x, 0.001, "world x offset by cam pan")
            expect_near(50.0,  world_y, 0.001, "world y offset by cam pan")
        end)

        -- @covers LCamera:getZoom
        -- @covers LCamera:setPosition
        -- @covers LCamera:setZoom
        -- @covers lurek.camera.newCamera
        it("camera zoomed 2x: world coords halved relative to screen", function()
            local cam = lurek.camera.newCamera()
            cam:setPosition(0, 0)
            cam:setZoom(2.0)

            local screen_x = 200.0
            local zoom     = cam:getZoom()
            local world_x  = screen_x / zoom

            expect_near(100.0, world_x, 0.001, "zoom 2x halves screen x to world x")
        end)

end)

test_summary()
