-- Lurek2D Input API Tests

-- @description Verifies that the keyboard namespace is exposed on lurek as a table.
describe("lurek.keyboard module exists", function()
    -- @covers lurek.gamepad.getAxis
    -- @covers lurek.gamepad.getAxisCount
    -- @covers lurek.gamepad.getButtonCount
    -- @covers lurek.gamepad.getCount
    -- @covers lurek.gamepad.getGUID
    -- @covers lurek.gamepad.getGamepadMappingString
    -- @covers lurek.gamepad.getHat
    -- @covers lurek.gamepad.getJoystickCount
    -- @covers lurek.gamepad.getJoysticks
    -- @covers lurek.gamepad.getName
    -- @covers lurek.gamepad.isConnected
    -- @covers lurek.gamepad.isDown
    -- @covers lurek.gamepad.isGamepad
    -- @covers lurek.gamepad.isVibrationSupported
    -- @covers lurek.gamepad.loadGamepadMappings
    -- @covers lurek.gamepad.saveGamepadMappings
    -- @covers lurek.gamepad.setGamepadMapping
    -- @covers lurek.gamepad.setVibration
    -- @covers lurek.keyboard.getKeyFromScancode
    -- @covers lurek.keyboard.getScancodeFromKey
    -- @covers lurek.keyboard.hasKeyRepeat
    -- @covers lurek.keyboard.hasTextInput
    -- @covers lurek.keyboard.isDown
    -- @covers lurek.keyboard.isModifierActive
    -- @covers lurek.keyboard.isScancodeDown
    -- @covers lurek.keyboard.setKeyRepeat
    -- @covers lurek.keyboard.setTextInput
    -- @covers lurek.mouse.getCursor
    -- @covers lurek.mouse.getPosition
    -- @covers lurek.mouse.getSystemCursor
    -- @covers lurek.mouse.getX
    -- @covers lurek.mouse.getY
    -- @covers lurek.mouse.isCursorSupported
    -- @covers lurek.mouse.isDown
    -- @covers lurek.mouse.setCursor
    -- @covers lurek.touch.getPosition
    -- @covers lurek.touch.getPressure
    -- @covers lurek.touch.getTouchCount
    -- @covers lurek.touch.getTouches
    -- @covers lurek.mouse.setVisible
    -- @covers lurek.mouse.isVisible
    -- @covers lurek.mouse.setGrabbed
    -- @covers lurek.mouse.isGrabbed
    -- @covers lurek.mouse.setRelativeMode
    -- @covers lurek.mouse.getRelativeMode
    -- @covers lurek.mouse.setPosition
    -- @covers lurek.mouse.getWheelDelta
    -- @covers lurek.mouse.newCursor
    -- @covers lurek.input.Cursor.release
    -- @covers lurek.input.Cursor.getType
    -- @description Confirms lurek.keyboard is present and typed as a table.
    it("lurek.keyboard is a table", function()
        expect_type("table", lurek.keyboard)
    end)
end)

-- @description Checks keyboard query and toggle helpers for type shape, default false states, and round-trip behavior.
describe("lurek.keyboard functions", function()
    -- @description Confirms the keyboard down query is exported as a callable function.
    it("isDown is a function", function()
        expect_type("function", lurek.keyboard.isDown)
    end)

    -- @description Calls isDown with "space" and asserts the result type is boolean.
    it("isDown returns a boolean", function()
        local val = lurek.keyboard.isDown("space")
        expect_type("boolean", val)
    end)

    -- @description Verifies space, a, and escape all report false when no keys are pressed.
    it("isDown returns false for unpressed key", function()
        expect_false(lurek.keyboard.isDown("space"))
        expect_false(lurek.keyboard.isDown("a"))
        expect_false(lurek.keyboard.isDown("escape"))
    end)

    -- @description Verifies the variadic key query returns false when space, a, and escape are all unpressed.
    it("isDown accepts multiple keys and returns false when none are pressed", function()
        expect_false(lurek.keyboard.isDown("space", "a", "escape"))
    end)

    -- @description Confirms the scancode down query is exported as a callable function.
    it("isScancodeDown is a function", function()
        expect_type("function", lurek.keyboard.isScancodeDown)
    end)

    -- @description Verifies the space scancode reports false before any input is pressed.
    it("isScancodeDown returns false for an unpressed scancode", function()
        expect_false(lurek.keyboard.isScancodeDown("space"))
    end)

    -- @description Verifies key repeat starts false, becomes true after enabling, and returns to false after disabling.
    it("setKeyRepeat and hasKeyRepeat round-trip", function()
        expect_type("function", lurek.keyboard.setKeyRepeat)
        expect_type("function", lurek.keyboard.hasKeyRepeat)
        expect_false(lurek.keyboard.hasKeyRepeat())
        lurek.keyboard.setKeyRepeat(true)
        expect_true(lurek.keyboard.hasKeyRepeat())
        lurek.keyboard.setKeyRepeat(false)
        expect_false(lurek.keyboard.hasKeyRepeat())
    end)

    -- @description Verifies text input starts false, becomes true after enabling, and returns to false after disabling.
    it("setTextInput and hasTextInput round-trip", function()
        expect_type("function", lurek.keyboard.setTextInput)
        expect_type("function", lurek.keyboard.hasTextInput)
        expect_false(lurek.keyboard.hasTextInput())
        lurek.keyboard.setTextInput(true)
        expect_true(lurek.keyboard.hasTextInput())
        lurek.keyboard.setTextInput(false)
        expect_false(lurek.keyboard.hasTextInput())
    end)

    -- @description Confirms both key-to-scancode and scancode-to-key lookup helpers are exported as functions.
    it("phase 03 scancode lookup helpers exist", function()
        expect_type("function", lurek.keyboard.getScancodeFromKey)
        expect_type("function", lurek.keyboard.getKeyFromScancode)
    end)
end)

-- @description Verifies that the mouse namespace is exposed on lurek as a table.
describe("lurek.mouse module exists", function()
    -- @description Confirms lurek.mouse is present and typed as a table.
    it("lurek.mouse is a table", function()
        expect_type("table", lurek.mouse)
    end)
end)

-- @description Checks mouse position and button helpers for function shape, numeric coordinate results, and default unpressed buttons.
describe("lurek.mouse functions", function()
    -- @description Confirms the mouse position query is exported as a callable function.
    it("getPosition is a function", function()
        expect_type("function", lurek.mouse.getPosition)
    end)

    -- @description Calls getPosition and asserts both returned coordinates are numbers.
    it("getPosition returns two numbers", function()
        local x, y = lurek.mouse.getPosition()
        expect_type("number", x)
        expect_type("number", y)
    end)

    -- @description Confirms the X-coordinate accessor is exported as a callable function.
    it("getX is a function", function()
        expect_type("function", lurek.mouse.getX)
    end)

    -- @description Calls getX and asserts the returned cursor X coordinate is numeric.
    it("getX returns a number", function()
        expect_type("number", lurek.mouse.getX())
    end)

    -- @description Confirms the Y-coordinate accessor is exported as a callable function.
    it("getY is a function", function()
        expect_type("function", lurek.mouse.getY)
    end)

    -- @description Calls getY and asserts the returned cursor Y coordinate is numeric.
    it("getY returns a number", function()
        expect_type("number", lurek.mouse.getY())
    end)

    -- @description Confirms the mouse button query is exported as a callable function.
    it("isDown is a function", function()
        expect_type("function", lurek.mouse.isDown)
    end)

    -- @description Calls isDown for button 1 and asserts the result type is boolean.
    it("isDown returns a boolean", function()
        local val = lurek.mouse.isDown(1)
        expect_type("boolean", val)
    end)

    -- @description Verifies buttons 1, 2, and 3 all report false when no mouse buttons are pressed.
    it("isDown returns false for unpressed button", function()
        expect_false(lurek.mouse.isDown(1))
        expect_false(lurek.mouse.isDown(2))
        expect_false(lurek.mouse.isDown(3))
    end)
end)

-- @description Verifies that the gamepad namespace is exposed on lurek as a table.
describe("lurek.gamepad module exists", function()
    -- @description Confirms lurek.gamepad is present and typed as a table.
    it("lurek.gamepad is a table", function()
        expect_type("table", lurek.gamepad)
    end)
end)

-- @description Checks gamepad discovery helpers, empty-state defaults, and presence of advanced GUID, hat, and vibration hooks.
describe("lurek.gamepad functions", function()
    -- @description Confirms the core gamepad inventory and state query API is exported as functions.
    it("core query functions exist", function()
        expect_type("function", lurek.gamepad.getCount)
        expect_type("function", lurek.gamepad.getJoystickCount)
        expect_type("function", lurek.gamepad.getJoysticks)
        expect_type("function", lurek.gamepad.isConnected)
        expect_type("function", lurek.gamepad.getName)
        expect_type("function", lurek.gamepad.isGamepad)
        expect_type("function", lurek.gamepad.getButtonCount)
        expect_type("function", lurek.gamepad.getAxisCount)
        expect_type("function", lurek.gamepad.isDown)
        expect_type("function", lurek.gamepad.getAxis)
        expect_type("function", lurek.gamepad.isVibrationSupported)
    end)

    -- @description Verifies an empty gamepad inventory reports zero counts, an empty joystick table, and false for connection and gamepad checks on id 0.
    it("empty inventory returns stable defaults", function()
        expect_equal(0, lurek.gamepad.getCount())
        expect_equal(0, lurek.gamepad.getJoystickCount())
        local ids = lurek.gamepad.getJoysticks()
        expect_type("table", ids)
        expect_equal(0, #ids)
        expect_false(lurek.gamepad.isConnected(0))
        expect_false(lurek.gamepad.isGamepad(0))
    end)

    -- @description Confirms GUID lookup, hat query, and vibration setter are all exported as functions.
    it("phase 03 advanced gamepad hooks exist", function()
        expect_type("function", lurek.gamepad.getGUID)
        expect_type("function", lurek.gamepad.getHat)
        expect_type("function", lurek.gamepad.setVibration)
    end)
end)

-- @description Verifies that the touch namespace is exposed on lurek as a table.
describe("lurek.touch module exists", function()
    -- @description Confirms lurek.touch is present and typed as a table.
    it("lurek.touch is a table", function()
        expect_type("table", lurek.touch)
    end)
end)

-- @description Checks touch query helpers for presence and verifies the default touch list is empty.
describe("lurek.touch functions", function()
    -- @description Confirms touch list, position, pressure, and count helpers are all exported as functions.
    it("phase 03 touch query functions exist", function()
        expect_type("function", lurek.touch.getTouches)
        expect_type("function", lurek.touch.getPosition)
        expect_type("function", lurek.touch.getPressure)
        expect_type("function", lurek.touch.getTouchCount)
    end)

    -- @description Verifies getTouches returns a table whose length is zero before any touches are active.
    it("getTouches returns an empty table by default", function()
        local touches = lurek.touch.getTouches()
        expect_type("table", touches)
        expect_equal(0, #touches)
    end)
end)

-- @description Verifies modifier queries return booleans for supported names and false for unknown or inactive modifiers.
describe("keyboard.isModifierActive", function()
    -- @description Confirms shift, ctrl, alt, meta, and super each return a boolean result.
    it("returns a boolean for valid modifiers", function()
        expect_type("boolean", lurek.keyboard.isModifierActive("shift"))
        expect_type("boolean", lurek.keyboard.isModifierActive("ctrl"))
        expect_type("boolean", lurek.keyboard.isModifierActive("alt"))
        expect_type("boolean", lurek.keyboard.isModifierActive("meta"))
        expect_type("boolean", lurek.keyboard.isModifierActive("super"))
    end)
    -- @description Verifies an unsupported modifier name capslock returns false.
    it("returns false for unknown modifier", function()
        expect_equal(false, lurek.keyboard.isModifierActive("capslock"))
    end)
    -- @description Verifies shift and ctrl both start inactive at test startup.
    it("no modifiers held at start", function()
        expect_equal(false, lurek.keyboard.isModifierActive("shift"))
        expect_equal(false, lurek.keyboard.isModifierActive("ctrl"))
    end)
end)

-- @description Checks cursor userdata creation, support reporting, cursor switching with userdata and strings, and current cursor reporting.
describe("mouse cursor userdata", function()
    -- @description Verifies getSystemCursor("arrow") returns userdata.
    it("getSystemCursor returns a userdata", function()
        local c = lurek.mouse.getSystemCursor("arrow")
        expect_type("userdata", c)
    end)
    -- @description Verifies cursor support reports a boolean and currently returns true.
    it("isCursorSupported returns a bool", function()
        expect_type("boolean", lurek.mouse.isCursorSupported())
        expect_equal(true, lurek.mouse.isCursorSupported())
    end)
    -- @description Verifies requesting the hand system cursor returns userdata.
    it("getSystemCursor hand cursor returns non-nil", function()
        local c = lurek.mouse.getSystemCursor("hand")
        expect_type("userdata", c)
    end)
    -- @description Verifies requesting the crosshair system cursor returns userdata.
    it("getSystemCursor crosshair cursor returns userdata", function()
        local c = lurek.mouse.getSystemCursor("crosshair")
        expect_type("userdata", c)
    end)
    -- @description Sets the cursor from userdata, checks getCursor reports hand, then restores arrow.
    it("setCursor accepts userdata and updates cursor", function()
        local c = lurek.mouse.getSystemCursor("hand")
        lurek.mouse.setCursor(c)
        expect_equal("hand", lurek.mouse.getCursor())
        lurek.mouse.setCursor("arrow")
    end)
    -- @description Sets the cursor from the string name crosshair, checks getCursor matches, then restores arrow for backward compatibility.
    it("setCursor still accepts string for backward compat", function()
        lurek.mouse.setCursor("crosshair")
        expect_equal("crosshair", lurek.mouse.getCursor())
        lurek.mouse.setCursor("arrow")
    end)
end)

-- Phase 10: Gamepad Mapping Persistence
-- @description Checks mapping persistence helpers for presence, successful mapping insertion, string retrieval, and missing-file error handling.
describe("lurek.gamepad mapping persistence", function()
    -- @description Confirms set, get, load, and save mapping functions are all exported as callables.
    it("mapping API functions exist", function()
        expect_type("function", lurek.gamepad.setGamepadMapping)
        expect_type("function", lurek.gamepad.getGamepadMappingString)
        expect_type("function", lurek.gamepad.loadGamepadMappings)
        expect_type("function", lurek.gamepad.saveGamepadMappings)
    end)

    -- @description Verifies setGamepadMapping accepts a valid GUID and mapping string without raising an error.
    it("setGamepadMapping does not error for valid guid", function()
        lurek.gamepad.setGamepadMapping(
            "000000000000000000000000504944564d",
            "000000000000000000000000504944564d,TestPad,a:b0"
        )
    end)

    -- @description Verifies an unknown GUID returns nil from getGamepadMappingString.
    it("getGamepadMappingString returns nil for unknown guid", function()
        expect_equal(nil, lurek.gamepad.getGamepadMappingString("unknown_guid_xyz"))
    end)

    -- @description Sets a mapping for a known GUID and verifies getGamepadMappingString returns a string.
    it("getGamepadMappingString returns a string after set", function()
        local guid = "030000005e0400008e02000014010000"
        lurek.gamepad.setGamepadMapping(guid, guid .. ",XInput,a:b0")
        local s = lurek.gamepad.getGamepadMappingString(guid)
        expect_type("string", s)
    end)

    -- @description Verifies loading mappings from a nonexistent file raises an error.
    it("loadGamepadMappings errors on missing file", function()
        expect_error(function()
            lurek.gamepad.loadGamepadMappings("__nonexistent_mappings_file_.txt")
        end)
    end)
end)

-- â”€â”€ mouse visibility / grab / relative â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies mouse visibility toggles reflect the value last set and restores visibility after the false case.
describe("mouse.setVisible / isVisible", function()
    -- @description Sets visibility to true and verifies isVisible returns true.
    it("setVisible true / isVisible round-trip", function()
        lurek.mouse.setVisible(true)
        expect_true(lurek.mouse.isVisible())
    end)

    -- @description Sets visibility to false, verifies isVisible returns false, then restores visibility to true.
    it("setVisible false / isVisible round-trip", function()
        lurek.mouse.setVisible(false)
        expect_false(lurek.mouse.isVisible())
        lurek.mouse.setVisible(true) -- restore
    end)
end)

-- @description Verifies mouse grab state can be set false and that the grab query returns a boolean.
describe("mouse.setGrabbed / isGrabbed", function()
    -- @description Sets grabbed to false and verifies isGrabbed reports false.
    it("setGrabbed / isGrabbed round-trip false", function()
        lurek.mouse.setGrabbed(false)
        expect_false(lurek.mouse.isGrabbed())
    end)

    -- @description Confirms isGrabbed returns a boolean result.
    it("isGrabbed returns a boolean", function()
        expect_type("boolean", lurek.mouse.isGrabbed())
    end)
end)

-- @description Verifies relative mouse mode can be set false and that the relative mode query returns a boolean.
describe("mouse.setRelativeMode / getRelativeMode", function()
    -- @description Sets relative mode to false and verifies getRelativeMode reports false.
    it("setRelativeMode false / getRelativeMode round-trip", function()
        lurek.mouse.setRelativeMode(false)
        expect_false(lurek.mouse.getRelativeMode())
    end)

    -- @description Confirms getRelativeMode returns a boolean result.
    it("getRelativeMode returns a boolean", function()
        expect_type("boolean", lurek.mouse.getRelativeMode())
    end)
end)

-- @description Checks wheel delta return types and verifies the default delta is exactly 0,0 without scrolling.
describe("mouse.getWheelDelta", function()
    -- @description Calls getWheelDelta and asserts both returned deltas are numbers.
    it("getWheelDelta returns two numbers", function()
        local dx, dy = lurek.mouse.getWheelDelta()
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @description Verifies getWheelDelta returns 0 for both axes when no scroll input has occurred.
    it("getWheelDelta is 0,0 when no scroll occurred", function()
        local dx, dy = lurek.mouse.getWheelDelta()
        expect_equal(0, dx)
        expect_equal(0, dy)
    end)
end)

-- @description Verifies setPosition can be called in headless mode without raising an error.
describe("mouse.setPosition", function()
    -- @description Wraps setPosition(0, 0) and asserts the call completes without error.
    it("setPosition does not error in headless mode", function()
        expect_no_error(function()
            lurek.mouse.setPosition(0, 0)
        end)
    end)
end)

-- â”€â”€ Cursor extended methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Checks Cursor userdata helper methods by creating system cursors, reading the type string, and releasing without error.
describe("Cursor.getType / Cursor.release", function()
    -- @description Verifies getSystemCursor("default") returns a non-nil Cursor object.
    it("getSystemCursor returns a Cursor object", function()
        local cursor = lurek.mouse.getSystemCursor("default")
        expect_true(cursor ~= nil, "system cursor is not nil")
    end)

    -- @description Verifies Cursor:getType returns a string for the default system cursor.
    it("Cursor:getType returns a string", function()
        local cursor = lurek.mouse.getSystemCursor("default")
        expect_type("string", cursor:getType())
    end)

    -- @description Verifies calling Cursor:release on the arrow cursor completes without error.
    it("Cursor:release does not error", function()
        local cursor = lurek.mouse.getSystemCursor("arrow")
        expect_no_error(function() cursor:release() end)
    end)
end)

-- @description Tests for the new lurek.input action-mapping namespace.
describe("lurek.input action mapping", function()
  -- @covers lurek.input.bind
  -- @covers lurek.input.getBindings
  -- @description Binds an action to keys and verifies getBindings returns a non-empty table.
  it("bind registers an action", function()
    lurek.input.bind("jump", {"space", "up"})
    local bindings = lurek.input.getBindings()
    expect_equal(type(bindings), "table")
    expect_equal(type(bindings["jump"]), "table")
    expect_equal(#bindings["jump"], 2)
  end)

  -- @covers lurek.input.unbind
  -- @description After unbind, the action should no longer appear in getBindings.
  it("unbind removes an action", function()
    lurek.input.bind("fire", "ctrl")
    local removed = lurek.input.unbind("fire")
    expect_equal(removed, true)
    local b = lurek.input.getBindings()
    expect_equal(b["fire"], nil)
  end)

  -- @covers lurek.input.clearBindings
  -- @description clearBindings leaves getBindings returning an empty table.
  it("clearBindings empties all mappings", function()
    lurek.input.bind("run", "shift")
    lurek.input.clearBindings()
    local b = lurek.input.getBindings()
    local count = 0
    for _ in pairs(b) do count = count + 1 end
    expect_equal(count, 0)
  end)

  -- @covers lurek.input.isActionDown
  -- @description isActionDown on an unbound action returns false.
  it("isActionDown is false for an unmapped action", function()
    lurek.input.clearBindings()
    expect_equal(lurek.input.isActionDown("nosuchaction"), false)
  end)

  -- @covers lurek.input.wasActionPressed
  -- @description wasActionPressed on an unbound action returns false.
  it("wasActionPressed is false for an unmapped action", function()
    expect_equal(lurek.input.wasActionPressed("nosuchaction"), false)
  end)

  -- @covers lurek.input.wasActionReleased
  -- @description wasActionReleased on an unbound action returns false.
  it("wasActionReleased is false for an unmapped action", function()
    expect_equal(lurek.input.wasActionReleased("nosuchaction"), false)
  end)

  -- @covers lurek.input.wasActionPressedWithin
  -- @description wasActionPressedWithin returns false for an action that was never pressed.
  it("wasActionPressedWithin is false for an action never pressed", function()
    expect_equal(lurek.input.wasActionPressedWithin("nosuchaction", 10), false)
  end)
end)

test_summary()
