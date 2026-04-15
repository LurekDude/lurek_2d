-- Lurek2D Lua BDD tests for camera extended effects (zoom pulse, sway, breathing).
-- Headless: no GPU, no audio, no window.

-- @description Covers suite: camera effects module methods.
describe("camera effects — module methods", function()
    -- @covers Camera.zoomPulse
    -- @description Verifies zoomPulse is exposed on camera userdata.
    it("zoomPulse is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.zoomPulse)
    end)

    -- @covers Camera.startSway
    -- @description Verifies startSway is exposed on camera userdata.
    it("startSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.startSway)
    end)

    -- @covers Camera.stopSway
    -- @description Verifies stopSway is exposed on camera userdata.
    it("stopSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.stopSway)
    end)

    -- @covers Camera.isSway
    -- @description Verifies isSway is exposed on camera userdata.
    it("isSway is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.isSway)
    end)

    -- @covers Camera.startBreathing
    -- @description Verifies startBreathing is exposed on camera userdata.
    it("startBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.startBreathing)
    end)

    -- @covers Camera.stopBreathing
    -- @description Verifies stopBreathing is exposed on camera userdata.
    it("stopBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.stopBreathing)
    end)

    -- @covers Camera.isBreathing
    -- @description Verifies isBreathing is exposed on camera userdata.
    it("isBreathing is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.isBreathing)
    end)

    -- @covers Camera.getEffectiveZoom
    -- @description Verifies getEffectiveZoom is exposed on camera userdata.
    it("getEffectiveZoom is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.getEffectiveZoom)
    end)

    -- @covers Camera.getEffectOffset
    -- @description Verifies getEffectOffset is exposed on camera userdata.
    it("getEffectOffset is a method", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("function", cam.getEffectOffset)
    end)
end)

-- @description Covers suite: getEffectiveZoom with no effects.
describe("camera effects — getEffectiveZoom baseline", function()
    -- @covers Camera.getEffectiveZoom
    -- @description Verifies effective zoom equals base zoom when no effects are active.
    it("matches base zoom when no effects are active", function()
        local cam = lurek.camera.new(320, 240)
        cam:setZoom(1.5)
        local ez = cam:getEffectiveZoom()
        expect_near(1.5, ez, 0.001)
    end)

    -- @covers Camera.getEffectiveZoom
    -- @description Verifies effective zoom returns a number type.
    it("returns a number", function()
        local cam = lurek.camera.new(320, 240)
        expect_type("number", cam:getEffectiveZoom())
    end)
end)

-- @description Covers suite: zoom pulse effect.
describe("camera effects — zoomPulse", function()
    -- @covers Camera.zoomPulse
    -- @covers Camera.getEffectiveZoom
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

    -- @covers Camera.zoomPulse
    -- @covers Camera.getEffectiveZoom
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
    -- @covers Camera.startSway
    -- @covers Camera.isSway
    -- @description Verifies that startSway activates the sway effect.
    it("startSway activates sway", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0)
        expect_true(cam:isSway(), "isSway returns true after start")
    end)

    -- @covers Camera.stopSway
    -- @covers Camera.isSway
    -- @description Verifies that stopSway deactivates the sway effect.
    it("stopSway deactivates sway", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0)
        cam:stopSway()
        expect_true(not cam:isSway(), "isSway returns false after stop")
    end)

    -- @covers Camera.isSway
    -- @description Verifies that isSway returns false on a fresh camera.
    it("isSway is false on fresh camera", function()
        local cam = lurek.camera.new(320, 240)
        expect_true(not cam:isSway(), "isSway is false by default")
    end)

    -- @covers Camera.getEffectOffset
    -- @description Verifies that getEffectOffset returns two numbers.
    it("getEffectOffset returns two numbers", function()
        local cam = lurek.camera.new(320, 240)
        local dx, dy = cam:getEffectOffset()
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @covers Camera.getEffectOffset
    -- @description Verifies that effect offset is (0, 0) when no sway is active.
    it("getEffectOffset is zero when no sway active", function()
        local cam = lurek.camera.new(320, 240)
        local dx, dy = cam:getEffectOffset()
        expect_near(0.0, dx, 0.001)
        expect_near(0.0, dy, 0.001)
    end)

    -- @covers Camera.startSway
    -- @covers Camera.getEffectOffset
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

    -- @covers Camera.startSway
    -- @description Verifies that startSway accepts an optional decay parameter.
    it("accepts optional decay parameter", function()
        local cam = lurek.camera.new(320, 240)
        cam:startSway(5.0, 3.0, 1.0, 0.95) -- explicit decay
        expect_true(cam:isSway(), "sway is active with explicit decay")
    end)
end)

-- @description Covers suite: breathing effect.
describe("camera effects — breathing", function()
    -- @covers Camera.startBreathing
    -- @covers Camera.isBreathing
    -- @description Verifies that startBreathing activates breathing.
    it("startBreathing activates breathing", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        expect_true(cam:isBreathing(), "isBreathing returns true after start")
    end)

    -- @covers Camera.stopBreathing
    -- @covers Camera.isBreathing
    -- @description Verifies that stopBreathing deactivates breathing.
    it("stopBreathing deactivates breathing", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        cam:stopBreathing()
        expect_true(not cam:isBreathing(), "isBreathing returns false after stop")
    end)

    -- @covers Camera.isBreathing
    -- @description Verifies that isBreathing returns false on a fresh camera.
    it("isBreathing is false on fresh camera", function()
        local cam = lurek.camera.new(320, 240)
        expect_true(not cam:isBreathing(), "isBreathing is false by default")
    end)

    -- @covers Camera.startBreathing
    -- @covers Camera.getEffectiveZoom
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

    -- @covers Camera.startBreathing
    -- @description Verifies that startBreathing accepts optional amplitude and rate.
    it("accepts optional amplitude and rate", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing(0.01, 0.3) -- explicit params
        expect_true(cam:isBreathing(), "breathing active with explicit params")
    end)

    -- @covers Camera.startBreathing
    -- @description Verifies that startBreathing uses defaults when called with no args.
    it("uses defaults when called with no arguments", function()
        local cam = lurek.camera.new(320, 240)
        cam:startBreathing()
        expect_true(cam:isBreathing(), "breathing active with defaults")
    end)
end)

test_summary()
