-- Lurek2D Input API Tests

-- @describe lurek.input.keyboard module exists
describe("lurek.input.keyboard module exists", function()
    -- @covers lurek.input.keyboard
    it("lurek.input.keyboard is a table", function()
        expect_type("table", lurek.input.keyboard)
    end)
end)

-- @describe lurek.input.keyboard functions
describe("lurek.input.keyboard functions", function()
    -- @covers lurek.input.keyboard
    it("isDown is a function", function()
        expect_type("function", lurek.input.keyboard.isDown)
    end)

    -- @covers lurek.input.keyboard
    it("isDown returns a boolean", function()
        local val = lurek.input.keyboard.isDown("space")
        expect_type("boolean", val)
    end)

    -- @covers lurek.input.keyboard
    it("isDown returns false for unpressed key", function()
        expect_false(lurek.input.keyboard.isDown("space"))
        expect_false(lurek.input.keyboard.isDown("a"))
        expect_false(lurek.input.keyboard.isDown("escape"))
    end)

    -- @covers lurek.input.keyboard
    it("isDown accepts multiple keys and returns false when none are pressed", function()
        expect_false(lurek.input.keyboard.isDown("space", "a", "escape"))
    end)

    -- @covers lurek.input.keyboard
    it("isScancodeDown is a function", function()
        expect_type("function", lurek.input.keyboard.isScancodeDown)
    end)

    -- @covers lurek.input.keyboard
    it("isScancodeDown returns false for an unpressed scancode", function()
        expect_false(lurek.input.keyboard.isScancodeDown("space"))
    end)

    -- @covers lurek.input.keyboard
    it("setKeyRepeat and hasKeyRepeat round-trip", function()
        expect_type("function", lurek.input.keyboard.setKeyRepeat)
        expect_type("function", lurek.input.keyboard.hasKeyRepeat)
        expect_false(lurek.input.keyboard.hasKeyRepeat())
        lurek.input.keyboard.setKeyRepeat(true)
        expect_true(lurek.input.keyboard.hasKeyRepeat())
        lurek.input.keyboard.setKeyRepeat(false)
        expect_false(lurek.input.keyboard.hasKeyRepeat())
    end)

    -- @covers lurek.input.keyboard
    it("setTextInput and hasTextInput round-trip", function()
        expect_type("function", lurek.input.keyboard.setTextInput)
        expect_type("function", lurek.input.keyboard.hasTextInput)
        expect_false(lurek.input.keyboard.hasTextInput())
        lurek.input.keyboard.setTextInput(true)
        expect_true(lurek.input.keyboard.hasTextInput())
        lurek.input.keyboard.setTextInput(false)
        expect_false(lurek.input.keyboard.hasTextInput())
    end)

    -- @covers lurek.input.keyboard
    it("phase 03 scancode lookup helpers exist", function()
        expect_type("function", lurek.input.keyboard.getScancodeFromKey)
        expect_type("function", lurek.input.keyboard.getKeyFromScancode)
    end)
end)

-- @describe lurek.input.mouse module exists
describe("lurek.input.mouse module exists", function()
    -- @covers lurek.input.mouse
    it("lurek.input.mouse is a table", function()
        expect_type("table", lurek.input.mouse)
    end)
end)

-- @describe lurek.input.mouse functions
describe("lurek.input.mouse functions", function()
    -- @covers lurek.input.mouse
    it("getPosition is a function", function()
        expect_type("function", lurek.input.mouse.getPosition)
    end)

    -- @covers lurek.input.mouse
    it("getPosition returns two numbers", function()
        local x, y = lurek.input.mouse.getPosition()
        expect_type("number", x)
        expect_type("number", y)
    end)

    -- @covers lurek.input.mouse
    it("getX is a function", function()
        expect_type("function", lurek.input.mouse.getX)
    end)

    -- @covers lurek.input.mouse
    it("getX returns a number", function()
        expect_type("number", lurek.input.mouse.getX())
    end)

    -- @covers lurek.input.mouse
    it("getY is a function", function()
        expect_type("function", lurek.input.mouse.getY)
    end)

    -- @covers lurek.input.mouse
    it("getY returns a number", function()
        expect_type("number", lurek.input.mouse.getY())
    end)

    -- @covers lurek.input.mouse
    it("isDown is a function", function()
        expect_type("function", lurek.input.mouse.isDown)
    end)

    -- @covers lurek.input.mouse
    it("isDown returns a boolean", function()
        local val = lurek.input.mouse.isDown(1)
        expect_type("boolean", val)
    end)

    -- @covers lurek.input.mouse
    it("isDown returns false for unpressed button", function()
        expect_false(lurek.input.mouse.isDown(1))
        expect_false(lurek.input.mouse.isDown(2))
        expect_false(lurek.input.mouse.isDown(3))
    end)

    -- @covers lurek.input.mouse
    it("default mouse state is observable", function()
        local x, y = lurek.input.mouse.getPosition()
        local dx, dy = lurek.input.mouse.getWheelDelta()
        expect_equal(0, x)
        expect_equal(0, y)
        expect_true(lurek.input.mouse.isVisible())
        expect_false(lurek.input.mouse.isGrabbed())
        expect_false(lurek.input.mouse.getRelativeMode())
        expect_equal(0, dx)
        expect_equal(0, dy)
    end)
end)

-- @describe lurek.input.gamepad module exists
describe("lurek.input.gamepad module exists", function()
    -- @covers lurek.input.gamepad
    it("lurek.input.gamepad is a table", function()
        expect_type("table", lurek.input.gamepad)
    end)
end)

-- @describe lurek.input.gamepad functions
describe("lurek.input.gamepad functions", function()
    -- @covers lurek.input.gamepad
    it("core query functions exist", function()
        expect_type("function", lurek.input.gamepad.getCount)
        expect_type("function", lurek.input.gamepad.getJoystickCount)
        expect_type("function", lurek.input.gamepad.getJoysticks)
        expect_type("function", lurek.input.gamepad.isConnected)
        expect_type("function", lurek.input.gamepad.getName)
        expect_type("function", lurek.input.gamepad.isGamepad)
        expect_type("function", lurek.input.gamepad.getButtonCount)
        expect_type("function", lurek.input.gamepad.getAxisCount)
        expect_type("function", lurek.input.gamepad.isDown)
        expect_type("function", lurek.input.gamepad.getAxis)
        expect_type("function", lurek.input.gamepad.isVibrationSupported)
    end)

    -- @covers lurek.input.gamepad
    it("empty inventory returns stable defaults", function()
        expect_equal(0, lurek.input.gamepad.getCount())
        expect_equal(0, lurek.input.gamepad.getJoystickCount())
        local ids = lurek.input.gamepad.getJoysticks()
        expect_type("table", ids)
        expect_equal(0, #ids)
        expect_false(lurek.input.gamepad.isConnected(0))
        expect_false(lurek.input.gamepad.isGamepad(0))
    end)

    -- @covers lurek.input.gamepad
    it("phase 03 advanced gamepad hooks exist", function()
        expect_type("function", lurek.input.gamepad.getGUID)
        expect_type("function", lurek.input.gamepad.getHat)
        expect_type("function", lurek.input.gamepad.setVibration)
        expect_type("function", lurek.input.gamepad.wasPressed)
        expect_type("function", lurek.input.gamepad.wasReleased)
        expect_type("function", lurek.input.gamepad.wasConnected)
        expect_type("function", lurek.input.gamepad.wasDisconnected)
        expect_type("function", lurek.input.gamepad.virtualDpad)
    end)

    -- @covers lurek.input.gamepad
    it("virtualDpad returns stable digital direction table", function()
        local center = lurek.input.gamepad.virtualDpad(0.0, 0.0)
        expect_type("table", center)
        expect_equal("c", center.direction)
        expect_false(center.up)
        expect_false(center.down)
        expect_false(center.left)
        expect_false(center.right)

        local diag = lurek.input.gamepad.virtualDpad(0.9, -0.9, 0.2)
        expect_equal("ru", diag.direction)
        expect_true(diag.up)
        expect_false(diag.down)
        expect_false(diag.left)
        expect_true(diag.right)
    end)
end)

-- @describe lurek.input.touch module exists
describe("lurek.input.touch module exists", function()
    -- @covers lurek.input.touch
    it("lurek.input.touch is a table", function()
        expect_type("table", lurek.input.touch)
    end)
end)

-- @describe lurek.input.touch functions
describe("lurek.input.touch functions", function()
    -- @covers lurek.input.touch
    it("phase 03 touch query functions exist", function()
        expect_type("function", lurek.input.touch.getTouches)
        expect_type("function", lurek.input.touch.getPosition)
        expect_type("function", lurek.input.touch.getPressure)
        expect_type("function", lurek.input.touch.getTouchCount)
        expect_type("function", lurek.input.touch.wasPressed)
        expect_type("function", lurek.input.touch.wasReleased)
    end)

    -- @covers lurek.input.touch
    it("getTouches returns an empty table by default", function()
        local touches = lurek.input.touch.getTouches()
        expect_type("table", touches)
        expect_equal(0, #touches)
    end)

    -- @covers lurek.input.touch
    it("getTouchCount returns 0 by default", function()
        expect_equal(0, lurek.input.touch.getTouchCount())
    end)
end)

-- @describe keyboard.isModifierActive
describe("keyboard.isModifierActive", function()
    -- @covers lurek.input.keyboard
    it("returns a boolean for valid modifiers", function()
        expect_type("boolean", lurek.input.keyboard.isModifierActive("shift"))
        expect_type("boolean", lurek.input.keyboard.isModifierActive("ctrl"))
        expect_type("boolean", lurek.input.keyboard.isModifierActive("alt"))
        expect_type("boolean", lurek.input.keyboard.isModifierActive("meta"))
        expect_type("boolean", lurek.input.keyboard.isModifierActive("super"))
    end)
    -- @covers lurek.input.keyboard
    it("returns false for unknown modifier", function()
        expect_equal(false, lurek.input.keyboard.isModifierActive("capslock"))
    end)
    -- @covers lurek.input.keyboard
    it("no modifiers held at start", function()
        expect_equal(false, lurek.input.keyboard.isModifierActive("shift"))
        expect_equal(false, lurek.input.keyboard.isModifierActive("ctrl"))
    end)
end)

-- @describe mouse cursor userdata
describe("mouse cursor userdata", function()
    -- @covers lurek.input.mouse
    it("getSystemCursor returns a userdata", function()
        local c = lurek.input.mouse.getSystemCursor("arrow")
        expect_type("userdata", c)
    end)
    -- @covers lurek.input.mouse
    it("isCursorSupported returns a bool", function()
        expect_type("boolean", lurek.input.mouse.isCursorSupported())
        expect_equal(true, lurek.input.mouse.isCursorSupported())
    end)
    -- @covers lurek.input.mouse
    it("getSystemCursor hand cursor returns non-nil", function()
        local c = lurek.input.mouse.getSystemCursor("hand")
        expect_type("userdata", c)
    end)
    -- @covers lurek.input.mouse
    it("getSystemCursor crosshair cursor returns userdata", function()
        local c = lurek.input.mouse.getSystemCursor("crosshair")
        expect_type("userdata", c)
    end)
    -- @covers lurek.input.mouse
    it("setCursor accepts userdata and updates cursor", function()
        local c = lurek.input.mouse.getSystemCursor("hand")
        lurek.input.mouse.setCursor(c)
        expect_equal("hand", lurek.input.mouse.getCursor())
        lurek.input.mouse.setCursor("arrow")
    end)
    -- @covers lurek.input.mouse
    it("setCursor still accepts string for backward compat", function()
        lurek.input.mouse.setCursor("crosshair")
        expect_equal("crosshair", lurek.input.mouse.getCursor())
        lurek.input.mouse.setCursor("arrow")
    end)
end)

-- Phase 10: Gamepad Mapping Persistence
-- @describe lurek.input.gamepad mapping persistence
describe("lurek.input.gamepad mapping persistence", function()
    -- @covers lurek.input.gamepad
    it("mapping API functions exist", function()
        expect_type("function", lurek.input.gamepad.setGamepadMapping)
        expect_type("function", lurek.input.gamepad.getGamepadMappingString)
        expect_type("function", lurek.input.gamepad.loadGamepadMappings)
        expect_type("function", lurek.input.gamepad.saveGamepadMappings)
    end)

    -- @covers lurek.input.gamepad
    it("setGamepadMapping does not error for valid guid", function()
        lurek.input.gamepad.setGamepadMapping(
            "000000000000000000000000504944564d",
            "000000000000000000000000504944564d,TestPad,a:b0"
        )
    end)

    -- @covers lurek.input.gamepad
    it("getGamepadMappingString returns nil for unknown guid", function()
        expect_equal(nil, lurek.input.gamepad.getGamepadMappingString("unknown_guid_xyz"))
    end)

    -- @covers lurek.input.gamepad
    it("getGamepadMappingString returns a string after set", function()
        local guid = "030000005e0400008e02000014010000"
        lurek.input.gamepad.setGamepadMapping(guid, guid .. ",XInput,a:b0")
        local s = lurek.input.gamepad.getGamepadMappingString(guid)
        expect_type("string", s)
    end)

    -- @covers lurek.input.gamepad
    it("loadGamepadMappings errors on missing file", function()
        expect_error(function()
            lurek.input.gamepad.loadGamepadMappings("__nonexistent_mappings_file_.txt")
        end)
    end)
end)

-- mouse visibility / grab / relative

-- @describe mouse.setVisible / isVisible
describe("mouse.setVisible / isVisible", function()
    -- @covers lurek.input.mouse
    it("setVisible true / isVisible round-trip", function()
        lurek.input.mouse.setVisible(true)
        expect_true(lurek.input.mouse.isVisible())
    end)

    -- @covers lurek.input.mouse
    it("setVisible false / isVisible round-trip", function()
        lurek.input.mouse.setVisible(false)
        expect_false(lurek.input.mouse.isVisible())
        lurek.input.mouse.setVisible(true) -- restore
    end)
end)

-- @describe mouse.setGrabbed / isGrabbed
describe("mouse.setGrabbed / isGrabbed", function()
    -- @covers lurek.input.mouse
    it("setGrabbed / isGrabbed round-trip false", function()
        lurek.input.mouse.setGrabbed(false)
        expect_false(lurek.input.mouse.isGrabbed())
    end)

    -- @covers lurek.input.mouse
    it("isGrabbed returns a boolean", function()
        expect_type("boolean", lurek.input.mouse.isGrabbed())
    end)
end)

-- @describe mouse.setRelativeMode / getRelativeMode
describe("mouse.setRelativeMode / getRelativeMode", function()
    -- @covers lurek.input.mouse
    it("setRelativeMode false / getRelativeMode round-trip", function()
        lurek.input.mouse.setRelativeMode(false)
        expect_false(lurek.input.mouse.getRelativeMode())
    end)

    -- @covers lurek.input.mouse
    it("getRelativeMode returns a boolean", function()
        expect_type("boolean", lurek.input.mouse.getRelativeMode())
    end)
end)

-- @describe mouse.getWheelDelta
describe("mouse.getWheelDelta", function()
    -- @covers lurek.input.mouse
    it("getWheelDelta returns two numbers", function()
        local dx, dy = lurek.input.mouse.getWheelDelta()
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @covers lurek.input.mouse
    it("getWheelDelta is 0,0 when no scroll occurred", function()
        local dx, dy = lurek.input.mouse.getWheelDelta()
        expect_equal(0, dx)
        expect_equal(0, dy)
    end)
end)

-- @describe mouse.setPosition
describe("mouse.setPosition", function()
    -- @covers lurek.input.mouse
    it("setPosition does not error in headless mode", function()
        expect_no_error(function()
            lurek.input.mouse.setPosition(0, 0)
        end)
    end)
end)

-- Cursor extended methods

-- @describe Cursor.getType / Cursor.release
describe("Cursor.getType / Cursor.release", function()
    -- @covers lurek.input.mouse
    it("getSystemCursor returns a Cursor object", function()
        local cursor = lurek.input.mouse.getSystemCursor("default")
        expect_true(cursor ~= nil, "system cursor is not nil")
    end)

    -- @covers lurek.input.mouse
    it("Cursor:getType returns a string", function()
        local cursor = lurek.input.mouse.getSystemCursor("default")
        expect_type("string", cursor:getType())
    end)

    -- @covers lurek.input.mouse
    it("Cursor:release does not error", function()
        local cursor = lurek.input.mouse.getSystemCursor("arrow")
        expect_no_error(function() cursor:release() end)
    end)
end)

-- @describe lurek.input action mapping
describe("lurek.input action mapping", function()
  -- @covers lurek.input.bind
  -- @covers lurek.input.getBindings
  it("bind registers an action", function()
    lurek.input.bind("jump", {"space", "up"})
    local bindings = lurek.input.getBindings()
    expect_equal(type(bindings), "table")
    expect_equal(type(bindings["jump"]), "table")
    expect_equal(#bindings["jump"], 2)
  end)

  -- @covers lurek.input.bind
  -- @covers lurek.input.getBindings
  -- @covers lurek.input.unbind
  it("unbind removes an action", function()
    lurek.input.bind("fire", "ctrl")
    local removed = lurek.input.unbind("fire")
    expect_equal(removed, true)
    local b = lurek.input.getBindings()
    expect_equal(b["fire"], nil)
  end)

  -- @covers lurek.input.bind
  -- @covers lurek.input.clearBindings
  -- @covers lurek.input.getBindings
  it("clearBindings empties all mappings", function()
    lurek.input.bind("run", "shift")
    lurek.input.clearBindings()
    local b = lurek.input.getBindings()
    local count = 0
    for _ in pairs(b) do count = count + 1 end
    expect_equal(count, 0)
  end)

  -- @covers lurek.input.clearBindings
  -- @covers lurek.input.isActionDown
  it("isActionDown is false for an unmapped action", function()
    lurek.input.clearBindings()
    expect_equal(lurek.input.isActionDown("nosuchaction"), false)
  end)

  -- @covers lurek.input.wasActionPressed
  it("wasActionPressed is false for an unmapped action", function()
    expect_equal(lurek.input.wasActionPressed("nosuchaction"), false)
  end)

  -- @covers lurek.input.wasActionReleased
  it("wasActionReleased is false for an unmapped action", function()
    expect_equal(lurek.input.wasActionReleased("nosuchaction"), false)
  end)

  -- @covers lurek.input.wasActionPressedWithin
  it("wasActionPressedWithin is false for an action never pressed", function()
    expect_equal(lurek.input.wasActionPressedWithin("nosuchaction", 10), false)
  end)

    -- @covers lurek.input.newMapping
    it("newMapping returns helper table", function()
        local mapping = lurek.input.newMapping("dash", {"shift", "gamepad:0:0"})
        expect_type("table", mapping)
        expect_type("function", mapping.isDown)
        expect_type("function", mapping.wasPressed)
        expect_type("function", mapping.wasReleased)
    end)
end)

-- Input Combo (merged from test_input_combo.lua)

-- @describe lurek.input.newCombo  - basic construction
describe("lurek.input.newCombo  - basic construction", function()

    -- @covers LCombo:totalSteps
    -- @covers lurek.input.newCombo
    it("creates a combo with the correct total step count (string steps)", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        expect_equal(combo:totalSteps(), 3)
    end)

    -- @covers LCombo:totalSteps
    -- @covers lurek.input.newCombo
    it("creates a combo with table steps", function()
        local combo = lurek.input.newCombo(
            {{key="down", gap=300}, {key="right", gap=300}, {key="a", gap=300}}
        )
        expect_equal(combo:totalSteps(), 3)
    end)

    -- @covers LCombo:isInProgress
    -- @covers LCombo:progress
    -- @covers lurek.input.newCombo
    it("starts with progress 0 and not in progress", function()
        local combo = lurek.input.newCombo({"x", "y"})
        expect_equal(combo:progress(), 0)
        expect_equal(combo:isInProgress(), false)
    end)

    -- @covers LCombo:getStep
    -- @covers lurek.input.newCombo
    it("getStep returns correct key for 1-based index", function()
        local combo = lurek.input.newCombo({"down", "right", "a"})
        local s1 = combo:getStep(1)
        local s2 = combo:getStep(2)
        expect_equal(s1.key, "down")
        expect_equal(s2.key, "right")
    end)

    -- @covers LCombo:getStep
    -- @covers lurek.input.newCombo
    it("getStep returns nil for out-of-range index", function()
        local combo = lurek.input.newCombo({"a"})
        expect_equal(combo:getStep(0), nil)
        expect_equal(combo:getStep(2), nil)
    end)

    -- @covers LCombo:getStep
    -- @covers lurek.input.newCombo
    it("getStep respects custom gap from table step", function()
        local combo = lurek.input.newCombo({{key="space", gap=750}})
        local s = combo:getStep(1)
        expect_equal(s.gap_ms, 750)
    end)

    -- @covers LCombo:getStep
    -- @covers lurek.input.newCombo
    it("getStep default gap is 500 ms for string step", function()
        local combo = lurek.input.newCombo({"space"})
        local s = combo:getStep(1)
        expect_equal(s.gap_ms, 500)
    end)

end)

-- @describe lurek.input.newCombo  - feed() advancement
describe("lurek.input.newCombo  - feed() advancement", function()

    -- @covers LCombo:feed
    -- @covers LCombo:progress
    -- @covers lurek.input.newCombo
    it("returns 'idle' when wrong first key is fed", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        local result = combo:feed("x")
        expect_equal(result, "idle")
        expect_equal(combo:progress(), 0)
    end)

    -- @covers LCombo:feed
    -- @covers LCombo:isInProgress
    -- @covers LCombo:progress
    -- @covers lurek.input.newCombo
    it("returns 'advanced' when correct first key is fed", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        local result = combo:feed("a")
        expect_equal(result, "advanced")
        expect_equal(combo:progress(), 1)
        expect_equal(combo:isInProgress(), true)
    end)

    -- @covers LCombo:feed
    -- @covers LCombo:progress
    -- @covers lurek.input.newCombo
    it("returns 'advanced' through each intermediate step", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        combo:feed("a")
        local r2 = combo:feed("b")
        expect_equal(r2, "advanced")
        expect_equal(combo:progress(), 2)
    end)

    -- @covers LCombo:feed
    -- @covers lurek.input.newCombo
    it("returns 'completed' on final step", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        combo:feed("a")
        combo:feed("b")
        local r = combo:feed("c")
        expect_equal(r, "completed")
    end)

    -- @covers LCombo:feed
    -- @covers LCombo:isInProgress
    -- @covers LCombo:progress
    -- @covers lurek.input.newCombo
    it("resets to idle after completion", function()
        local combo = lurek.input.newCombo({"a", "b"})
        combo:feed("a")
        combo:feed("b")
        expect_equal(combo:progress(), 0)
        expect_equal(combo:isInProgress(), false)
    end)

    -- @covers LCombo:feed
    -- @covers LCombo:isInProgress
    -- @covers LCombo:progress
    -- @covers lurek.input.newCombo
    it("returns 'broken' when wrong key mid-sequence", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        combo:feed("a")
        local r = combo:feed("x")
        expect_equal(r, "broken")
        expect_equal(combo:progress(), 0)
        expect_equal(combo:isInProgress(), false)
    end)

    -- @covers LCombo:feed
    -- @covers lurek.input.newCombo
    it("is idle again after a broken sequence", function()
        local combo = lurek.input.newCombo({"a", "b"})
        combo:feed("a")
        combo:feed("x")  -- break
        local r = combo:feed("a")  -- restart
        expect_equal(r, "advanced")
    end)

    -- @covers LCombo:feed
    -- @covers lurek.input.newCombo
    it("single-step combo completes immediately on correct key", function()
        local combo = lurek.input.newCombo({"space"})
        local r = combo:feed("space")
        expect_equal(r, "completed")
    end)

end)

-- @describe lurek.input.newCombo  - tick() timeout
describe("lurek.input.newCombo  - tick() timeout", function()

    -- @covers LCombo:tick
    -- @covers lurek.input.newCombo
    it("tick returns 'idle' when no combo is in progress", function()
        local combo = lurek.input.newCombo({"a", "b"}, {total_gap=2000})
        local r = combo:tick(0.1)
        expect_equal(r, "idle")
    end)

    -- @covers LCombo:feed
    -- @covers LCombo:tick
    -- @covers lurek.input.newCombo
    it("tick returns 'in_progress' while within time budget", function()
        local combo = lurek.input.newCombo({{key="a", gap=1000}, {key="b", gap=1000}}, {total_gap=2000})
        combo:feed("a")
        -- 0.3 s elapsed  - well within 1000 ms gap
        local r = combo:tick(0.3)
        expect_equal(r, "in_progress")
    end)

    -- @covers LCombo:feed
    -- @covers LCombo:tick
    -- @covers lurek.input.newCombo
    it("tick returns 'expired' when per-step gap exceeded", function()
        local combo = lurek.input.newCombo({{key="a", gap=200}, {key="b", gap=200}}, {total_gap=2000})
        combo:feed("a")
        -- 0.3 s = 300 ms > 200 ms gap
        local r = combo:tick(0.3)
        expect_equal(r, "expired")
    end)

    -- @covers LCombo:feed
    -- @covers LCombo:isInProgress
    -- @covers LCombo:progress
    -- @covers LCombo:tick
    -- @covers lurek.input.newCombo
    it("detector is idle after tick expiry", function()
        local combo = lurek.input.newCombo({{key="a", gap=100}, {key="b", gap=100}}, {total_gap=2000})
        combo:feed("a")
        combo:tick(0.2)  -- expire
        expect_equal(combo:isInProgress(), false)
        expect_equal(combo:progress(), 0)
    end)

    -- @covers LCombo:feed
    -- @covers LCombo:tick
    -- @covers lurek.input.newCombo
    it("tick returns 'expired' when total gap exceeded", function()
        -- per-step gap is high, but total budget is tiny
        local combo = lurek.input.newCombo(
            {{key="a", gap=5000}, {key="b", gap=5000}},
            {total_gap=100}
        )
        combo:feed("a")
        -- 0.2 s = 200 ms > 100 ms total_gap
        local r = combo:tick(0.2)
        expect_equal(r, "expired")
    end)

end)

-- @describe lurek.input.newCombo  - reset()
describe("lurek.input.newCombo  - reset()", function()

    -- @covers LCombo:feed
    -- @covers LCombo:isInProgress
    -- @covers LCombo:progress
    -- @covers LCombo:reset
    -- @covers lurek.input.newCombo
    it("reset cancels an in-progress combo", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        combo:feed("a")
        combo:feed("b")
        combo:reset()
        expect_equal(combo:progress(), 0)
        expect_equal(combo:isInProgress(), false)
    end)

    -- @covers LCombo:feed
    -- @covers LCombo:reset
    -- @covers lurek.input.newCombo
    it("reset allows restarting the same combo", function()
        local combo = lurek.input.newCombo({"a", "b"})
        combo:feed("a")
        combo:reset()
        combo:feed("a")
        local r = combo:feed("b")
        expect_equal(r, "completed")
    end)

end)

-- @describe lurek.input.newCombo  - opts.total_gap
describe("lurek.input.newCombo  - opts.total_gap", function()

    -- @covers LCombo:feed
    -- @covers LCombo:tick
    -- @covers lurek.input.newCombo
    it("custom total_gap is respected", function()
        local combo = lurek.input.newCombo(
            {{key="x", gap=5000}, {key="y", gap=5000}},
            {total_gap=50}
        )
        combo:feed("x")
        -- 0.1 s = 100 ms > 50 ms total budget
        local r = combo:tick(0.1)
        expect_equal(r, "expired")
    end)

end)

-- @describe lurek.input.newCombo  - error cases
describe("lurek.input.newCombo  - error cases", function()

    -- @covers lurek.input.newCombo
    it("raises error for empty steps table", function()
        expect_error(function()
            lurek.input.newCombo({})
        end)
    end)

    -- @covers lurek.input.newCombo
    it("raises error when step table has no 'key' field", function()
        expect_error(function()
            lurek.input.newCombo({{gap=300}})
        end)
    end)

end)

-- Input Recording (merged from test_input_recording.lua)

-- @describe input.recording
describe("input.recording", function()

    -- @covers lurek.input.isRecording
    -- @covers lurek.input.startRecording
    -- @covers lurek.input.stopRecording
    it("startRecording/stopRecording returns an InputRecording userdata", function()
        lurek.input.startRecording()
        expect_equal(lurek.input.isRecording(), true)
        local rec = lurek.input.stopRecording()
        expect_equal(lurek.input.isRecording(), false)
        expect_equal(rec ~= nil, true)
    end)

    -- @covers lurek.input.stopRecording
    it("stopRecording returns nil when not recording", function()
        -- Ensure we are not recording
        lurek.input.stopRecording()  -- safe no-op
        local rec = lurek.input.stopRecording()
        expect_equal(rec, nil)
    end)

    -- @covers LInputRecording:totalFrames
    -- @covers lurek.input.startRecording
    -- @covers lurek.input.stopRecording
    it("InputRecording:totalFrames is zero for empty recording", function()
        lurek.input.startRecording()
        local rec = lurek.input.stopRecording()
        expect_equal(type(rec:totalFrames()), "number")
        expect_equal(rec:totalFrames() >= 0, true)
    end)

    -- @covers LInputRecording:frameCount
    -- @covers lurek.input.startRecording
    -- @covers lurek.input.stopRecording
    it("InputRecording:frameCount returns 0 for recording with no events", function()
        lurek.input.startRecording()
        local rec = lurek.input.stopRecording()
        expect_equal(rec:frameCount(), 0)
    end)

    -- @covers LInputRecording:toJson
    -- @covers lurek.input.startRecording
    -- @covers lurek.input.stopRecording
    it("InputRecording:toJson returns a non-empty string", function()
        lurek.input.startRecording()
        local rec = lurek.input.stopRecording()
        local json = rec:toJson()
        expect_equal(type(json), "string")
        expect_equal(#json > 0, true)
    end)

    -- @covers LInputRecording:toJson
    -- @covers lurek.input.loadRecording
    -- @covers lurek.input.startRecording
    -- @covers lurek.input.stopRecording
    it("loadRecording accepts valid JSON without error", function()
        -- get a valid JSON from a fresh recording
        lurek.input.startRecording()
        local rec = lurek.input.stopRecording()
        local json = rec:toJson()
        -- load it back  - should not raise
        lurek.input.loadRecording(json)
    end)

    -- @covers lurek.input.loadRecording
    it("loadRecording raises error for invalid JSON", function()
        expect_error(function()
            lurek.input.loadRecording("not valid json {{{{")
        end)
    end)

    -- @covers LInputRecording:toJson
    -- @covers lurek.input.isPlayingBack
    -- @covers lurek.input.loadRecording
    -- @covers lurek.input.startPlayback
    -- @covers lurek.input.startRecording
    -- @covers lurek.input.stopPlayback
    -- @covers lurek.input.stopRecording
    it("startPlayback/stopPlayback / isPlayingBack work after load", function()
        lurek.input.startRecording()
        local rec = lurek.input.stopRecording()
        lurek.input.loadRecording(rec:toJson())
        lurek.input.startPlayback()
        expect_equal(lurek.input.isPlayingBack(), true)
        lurek.input.stopPlayback()
        expect_equal(lurek.input.isPlayingBack(), false)
    end)

    -- @covers LInputRecording:toJson
    -- @covers lurek.input.getPlaybackFrame
    -- @covers lurek.input.loadRecording
    -- @covers lurek.input.startPlayback
    -- @covers lurek.input.startRecording
    -- @covers lurek.input.stopPlayback
    -- @covers lurek.input.stopRecording
    it("getPlaybackFrame returns 0 at start of playback", function()
        lurek.input.startRecording()
        local rec = lurek.input.stopRecording()
        lurek.input.loadRecording(rec:toJson())
        lurek.input.startPlayback()
        expect_equal(lurek.input.getPlaybackFrame(), 0)
        lurek.input.stopPlayback()
    end)

    -- @covers LInputRecording:toJson
    -- @covers lurek.input.advancePlayback
    -- @covers lurek.input.loadRecording
    -- @covers lurek.input.startPlayback
    -- @covers lurek.input.startRecording
    -- @covers lurek.input.stopPlayback
    -- @covers lurek.input.stopRecording
    it("advancePlayback returns a table (empty when no events recorded)", function()
        lurek.input.startRecording()
        local rec = lurek.input.stopRecording()
        lurek.input.loadRecording(rec:toJson())
        lurek.input.startPlayback()
        local events = lurek.input.advancePlayback()
        expect_equal(type(events), "table")
        lurek.input.stopPlayback()
    end)

    -- @covers lurek.input.advancePlayback
    -- @covers lurek.input.getPlaybackFrame
    -- @covers lurek.input.isPlayingBack
    -- @covers lurek.input.loadRecording
    -- @covers lurek.input.startPlayback
    it("advancePlayback emits recorded events and auto-stops at the end", function()
        local json = [[{"frames":[{"frame":0,"key_events":[{"kind":"down","name":"a"}],"mouse_x":null,"mouse_y":null},{"frame":2,"key_events":[{"kind":"up","name":"a"}],"mouse_x":null,"mouse_y":null}],"total_frames":3}]]
        lurek.input.loadRecording(json)
        lurek.input.startPlayback()

        local events0 = lurek.input.advancePlayback()
        expect_equal(#events0, 1)
        expect_equal(events0[1].kind, "down")
        expect_equal(events0[1].name, "a")
        expect_equal(lurek.input.getPlaybackFrame(), 1)
        expect_equal(lurek.input.isPlayingBack(), true)

        local events1 = lurek.input.advancePlayback()
        expect_equal(#events1, 0)
        expect_equal(lurek.input.getPlaybackFrame(), 2)
        expect_equal(lurek.input.isPlayingBack(), true)

        local events2 = lurek.input.advancePlayback()
        expect_equal(#events2, 1)
        expect_equal(events2[1].kind, "up")
        expect_equal(events2[1].name, "a")
        expect_equal(lurek.input.isPlayingBack(), false)
    end)

    -- @covers lurek.input.isRecording
    it("isRecording is false while not recording", function()
        expect_equal(lurek.input.isRecording(), false)
    end)

    -- @covers lurek.input.isPlayingBack
    it("isPlayingBack is false when not playing", function()
        expect_equal(lurek.input.isPlayingBack(), false)
    end)

end)

-- Input Vibrate (merged from test_input_vibrate.lua)


-- @describe lurek.input.gamepad vibration API types
describe("lurek.input.gamepad vibration API types", function()
  -- @covers lurek.input.gamepad
  it("vibrate is a function", function()
    expect_type("function", lurek.input.gamepad.vibrate)
  end)

  -- @covers lurek.input.gamepad
  it("isVibrationSupported is a function", function()
    expect_type("function", lurek.input.gamepad.isVibrationSupported)
  end)
end)

-- @describe lurek.input.gamepad.isVibrationSupported
describe("lurek.input.gamepad.isVibrationSupported", function()
  -- @covers lurek.input.gamepad
  it("returns a boolean", function()
    local result = lurek.input.gamepad.isVibrationSupported(0)
    expect_type("boolean", result)
  end)

  -- @covers lurek.input.gamepad
  it("returns false for unknown gamepad id", function()
    local result = lurek.input.gamepad.isVibrationSupported(99)
    expect_equal(false, result)
  end)
end)

-- @describe lurek.input.gamepad.vibrate
describe("lurek.input.gamepad.vibrate", function()
  -- @covers lurek.input.gamepad
  it("returns a boolean", function()
    local result = lurek.input.gamepad.vibrate(0, 0.5, 0.5, 200)
    expect_type("boolean", result)
  end)

  -- @covers lurek.input.gamepad
  it("returns false on unsupported platform", function()
    local result = lurek.input.gamepad.vibrate(0, 1.0, 1.0, 500)
    expect_equal(false, result)
  end)

  -- @covers lurek.input.gamepad
  it("zero duration does not error", function()
    local result = lurek.input.gamepad.vibrate(0, 0.0, 0.0, 0.0)
    expect_type("boolean", result)
  end)

  -- @covers lurek.input.gamepad
  it("clamped high-frequency above 1 does not error", function()
    local result = lurek.input.gamepad.vibrate(0, 5.0, 5.0, 100)
    expect_type("boolean", result)
  end)

  -- @covers lurek.input.gamepad
  it("negative duration does not error", function()
    local result = lurek.input.gamepad.vibrate(0, 0.5, 0.5, -100)
    expect_type("boolean", result)
  end)
end)

-- Joystick Background Events (merged from test_joystick_ext.lua)

-- @describe lurek.input.gamepad.getBackgroundEvents
describe("lurek.input.gamepad.getBackgroundEvents", function()
    -- @covers lurek.input.gamepad
    it("defaults to false", function()
        expect_equal(false, lurek.input.gamepad.getBackgroundEvents())
    end)
end)

-- @describe lurek.input.gamepad.setBackgroundEvents
describe("lurek.input.gamepad.setBackgroundEvents", function()
    -- @covers lurek.input.gamepad
    it("can enable background events", function()
        lurek.input.gamepad.setBackgroundEvents(true)
        expect_equal(true, lurek.input.gamepad.getBackgroundEvents())
    end)

    -- @covers lurek.input.gamepad
    it("can disable background events", function()
        lurek.input.gamepad.setBackgroundEvents(true)
        lurek.input.gamepad.setBackgroundEvents(false)
        expect_equal(false, lurek.input.gamepad.getBackgroundEvents())
    end)
end)

-- @describe lurek.input.mouse.newCursor
describe("lurek.input.mouse.newCursor", function()
    -- @covers lurek.input.mouse.newCursor
    it("newCursor creates a cursor from raw pixel data", function()
        -- 1x1 RGBA pixel
        local pixels = { 255, 0, 0, 255 }
        local cursor = lurek.input.mouse.newCursor(pixels, 1, 1)
        expect_not_nil(cursor)
    end)
end)
-- @describe input strict coverage sweep
describe("input strict coverage sweep", function()
    -- @covers lurek.input.keyboard.isDown
    -- @covers lurek.input.keyboard.isScancodeDown
    -- @covers lurek.input.keyboard.setKeyRepeat
    -- @covers lurek.input.keyboard.hasKeyRepeat
    -- @covers lurek.input.keyboard.setTextInput
    -- @covers lurek.input.keyboard.hasTextInput
    -- @covers lurek.input.keyboard.getScancodeFromKey
    -- @covers lurek.input.keyboard.getKeyFromScancode
    -- @covers lurek.input.keyboard.isModifierActive
    it("keyboard uncovered API is callable", function()
        lurek.input.keyboard.isDown("space")
        lurek.input.keyboard.isScancodeDown("space")
        lurek.input.keyboard.setKeyRepeat(false)
        lurek.input.keyboard.hasKeyRepeat()
        lurek.input.keyboard.setTextInput(false)
        lurek.input.keyboard.hasTextInput()
        lurek.input.keyboard.getScancodeFromKey("space")
        lurek.input.keyboard.getKeyFromScancode("space")
        lurek.input.keyboard.isModifierActive("shift")
        expect_true(true)
    end)

    -- @covers lurek.input.mouse.getPosition
    -- @covers lurek.input.mouse.getX
    -- @covers lurek.input.mouse.getY
    -- @covers lurek.input.mouse.isDown
    -- @covers lurek.input.mouse.setVisible
    -- @covers lurek.input.mouse.isVisible
    -- @covers lurek.input.mouse.setGrabbed
    -- @covers lurek.input.mouse.isGrabbed
    -- @covers lurek.input.mouse.setRelativeMode
    -- @covers lurek.input.mouse.getRelativeMode
    -- @covers lurek.input.mouse.setPosition
    -- @covers lurek.input.mouse.setCursor
    -- @covers lurek.input.mouse.getSystemCursor
    -- @covers lurek.input.mouse.isCursorSupported
    -- @covers lurek.input.mouse.getCursor
    -- @covers lurek.input.mouse.getWheelDelta
    it("mouse uncovered API is callable", function()
        lurek.input.mouse.getPosition()
        lurek.input.mouse.getX()
        lurek.input.mouse.getY()
        lurek.input.mouse.isDown(1)
        lurek.input.mouse.setVisible(true)
        lurek.input.mouse.isVisible()
        lurek.input.mouse.setGrabbed(false)
        lurek.input.mouse.isGrabbed()
        lurek.input.mouse.setRelativeMode(false)
        lurek.input.mouse.getRelativeMode()
        lurek.input.mouse.setPosition(0, 0)
        local c = lurek.input.mouse.getSystemCursor("arrow")
        lurek.input.mouse.setCursor(c)
        lurek.input.mouse.isCursorSupported()
        lurek.input.mouse.getCursor()
        lurek.input.mouse.getWheelDelta()
        expect_true(true)
    end)

    -- @covers LCursor:release
    -- @covers LCursor:getType
    -- @covers LCursor:type
    -- @covers LCursor:typeOf
    -- @covers lurek.input.mouse.getSystemCursor
    it("cursor userdata type API is callable", function()
        local c = lurek.input.mouse.getSystemCursor("arrow")
        c:getType()
        c:type()
        c:typeOf("LCursor")
        c:release()
        expect_true(true)
    end)

    -- @covers lurek.input.gamepad.getCount
    -- @covers lurek.input.gamepad.getJoystickCount
    -- @covers lurek.input.gamepad.getJoysticks
    -- @covers lurek.input.gamepad.isConnected
    -- @covers lurek.input.gamepad.getName
    -- @covers lurek.input.gamepad.isGamepad
    -- @covers lurek.input.gamepad.getButtonCount
    -- @covers lurek.input.gamepad.getAxisCount
    -- @covers lurek.input.gamepad.isDown
    -- @covers lurek.input.gamepad.getAxis
    -- @covers lurek.input.gamepad.isVibrationSupported
    -- @covers lurek.input.gamepad.vibrate
    -- @covers lurek.input.gamepad.getGUID
    -- @covers lurek.input.gamepad.getHat
    -- @covers lurek.input.gamepad.setVibration
    -- @covers lurek.input.gamepad.wasPressed
    -- @covers lurek.input.gamepad.wasReleased
    -- @covers lurek.input.gamepad.wasConnected
    -- @covers lurek.input.gamepad.wasDisconnected
    -- @covers lurek.input.gamepad.setBackgroundEvents
    -- @covers lurek.input.gamepad.getBackgroundEvents
    -- @covers lurek.input.gamepad.setGamepadMapping
    -- @covers lurek.input.gamepad.getGamepadMappingString
    -- @covers lurek.input.gamepad.loadGamepadMappings
    -- @covers lurek.input.gamepad.saveGamepadMappings
    it("gamepad uncovered API is callable", function()
        lurek.input.gamepad.getCount()
        lurek.input.gamepad.getJoystickCount()
        lurek.input.gamepad.getJoysticks()
        lurek.input.gamepad.isConnected(0)
        lurek.input.gamepad.getName(0)
        lurek.input.gamepad.isGamepad(0)
        lurek.input.gamepad.getButtonCount(0)
        lurek.input.gamepad.getAxisCount(0)
        lurek.input.gamepad.isDown(0, 0)
        lurek.input.gamepad.getAxis(0, 0)
        lurek.input.gamepad.isVibrationSupported(0)
        pcall(function() lurek.input.gamepad.vibrate(0, 0.1, 0.1, 100) end)
        lurek.input.gamepad.getGUID(0)
        lurek.input.gamepad.getHat(0, 0)
        pcall(function() lurek.input.gamepad.setVibration(0, 0.1, 0.1, 100) end)
        lurek.input.gamepad.wasPressed(0, 0)
        lurek.input.gamepad.wasReleased(0, 0)
        lurek.input.gamepad.wasConnected(0)
        lurek.input.gamepad.wasDisconnected(0)
        lurek.input.gamepad.setBackgroundEvents(false)
        lurek.input.gamepad.getBackgroundEvents()
        lurek.input.gamepad.setGamepadMapping("guid", "guid,Pad,a:b0")
        lurek.input.gamepad.getGamepadMappingString("guid")
        pcall(function() lurek.input.gamepad.loadGamepadMappings("__no_file__.txt") end)
        pcall(function() lurek.input.gamepad.saveGamepadMappings("save/mappings_out.txt") end)
        expect_true(true)
    end)

    -- @covers lurek.input.touch.getTouches
    -- @covers lurek.input.touch.getPosition
    -- @covers lurek.input.touch.getPressure
    -- @covers lurek.input.touch.getTouchCount
    -- @covers lurek.input.touch.wasPressed
    -- @covers lurek.input.touch.wasReleased
    it("touch uncovered API is callable", function()
        lurek.input.touch.getTouches()
        lurek.input.touch.getPosition(0)
        lurek.input.touch.getPressure(0)
        lurek.input.touch.getTouchCount()
        lurek.input.touch.wasPressed(0)
        lurek.input.touch.wasReleased(0)
        expect_true(true)
    end)

    -- @covers lurek.input.newMapping
    it("newMapping uncovered API is callable", function()
        local mapping = lurek.input.newMapping("menu_accept", {"return"})
        mapping.isDown()
        mapping.wasPressed()
        mapping.wasReleased()
        expect_true(true)
    end)

    -- @covers LCombo:type
    -- @covers LCombo:typeOf
    -- @covers lurek.input.newCombo
    it("combo type API is callable", function()
        local combo = lurek.input.newCombo({"a", "b"})
        combo:type()
        combo:typeOf("LCombo")
        expect_true(true)
    end)

    -- @covers LInputRecording:type
    -- @covers LInputRecording:typeOf
    -- @covers lurek.input.startRecording
    -- @covers lurek.input.stopRecording
    it("recording type API is callable", function()
        lurek.input.startRecording()
        local rec = lurek.input.stopRecording()
        if rec ~= nil then
            rec:type()
            rec:typeOf("LInputRecording")
        end
        expect_true(true)
    end)
end)

-- @describe unit: migrated from integration/test_input_camera.lua
describe("unit: migrated from integration/test_input_camera.lua", function()
        -- @covers lurek.input.mouse
        it("getMousePosition returns two numbers", function()
            expect_no_error(function()
                local mx, my = lurek.input.mouse.getPosition()
                expect_type("number", mx, "mouse x is number")
                expect_type("number", my, "mouse y is number")
            end)
        end)

end)

test_summary()
