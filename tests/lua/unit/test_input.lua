-- Lurek2D Input API Tests
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


describe("lurek.keyboard module exists", function()
    it("lurek.keyboard is a table", function()
        expect_type("table", lurek.keyboard)
    end)
end)

describe("lurek.keyboard functions", function()
    it("isDown is a function", function()
        expect_type("function", lurek.keyboard.isDown)
    end)

    it("isDown returns a boolean", function()
        local val = lurek.keyboard.isDown("space")
        expect_type("boolean", val)
    end)

    it("isDown returns false for unpressed key", function()
        expect_false(lurek.keyboard.isDown("space"))
        expect_false(lurek.keyboard.isDown("a"))
        expect_false(lurek.keyboard.isDown("escape"))
    end)

    it("isDown accepts multiple keys and returns false when none are pressed", function()
        expect_false(lurek.keyboard.isDown("space", "a", "escape"))
    end)

    it("isScancodeDown is a function", function()
        expect_type("function", lurek.keyboard.isScancodeDown)
    end)

    it("isScancodeDown returns false for an unpressed scancode", function()
        expect_false(lurek.keyboard.isScancodeDown("space"))
    end)

    it("setKeyRepeat and hasKeyRepeat round-trip", function()
        expect_type("function", lurek.keyboard.setKeyRepeat)
        expect_type("function", lurek.keyboard.hasKeyRepeat)
        expect_false(lurek.keyboard.hasKeyRepeat())
        lurek.keyboard.setKeyRepeat(true)
        expect_true(lurek.keyboard.hasKeyRepeat())
        lurek.keyboard.setKeyRepeat(false)
        expect_false(lurek.keyboard.hasKeyRepeat())
    end)

    it("setTextInput and hasTextInput round-trip", function()
        expect_type("function", lurek.keyboard.setTextInput)
        expect_type("function", lurek.keyboard.hasTextInput)
        expect_false(lurek.keyboard.hasTextInput())
        lurek.keyboard.setTextInput(true)
        expect_true(lurek.keyboard.hasTextInput())
        lurek.keyboard.setTextInput(false)
        expect_false(lurek.keyboard.hasTextInput())
    end)

    it("phase 03 scancode lookup helpers exist", function()
        expect_type("function", lurek.keyboard.getScancodeFromKey)
        expect_type("function", lurek.keyboard.getKeyFromScancode)
    end)
end)

describe("lurek.mouse module exists", function()
    it("lurek.mouse is a table", function()
        expect_type("table", lurek.mouse)
    end)
end)

describe("lurek.mouse functions", function()
    it("getPosition is a function", function()
        expect_type("function", lurek.mouse.getPosition)
    end)

    it("getPosition returns two numbers", function()
        local x, y = lurek.mouse.getPosition()
        expect_type("number", x)
        expect_type("number", y)
    end)

    it("getX is a function", function()
        expect_type("function", lurek.mouse.getX)
    end)

    it("getX returns a number", function()
        expect_type("number", lurek.mouse.getX())
    end)

    it("getY is a function", function()
        expect_type("function", lurek.mouse.getY)
    end)

    it("getY returns a number", function()
        expect_type("number", lurek.mouse.getY())
    end)

    it("isDown is a function", function()
        expect_type("function", lurek.mouse.isDown)
    end)

    it("isDown returns a boolean", function()
        local val = lurek.mouse.isDown(1)
        expect_type("boolean", val)
    end)

    it("isDown returns false for unpressed button", function()
        expect_false(lurek.mouse.isDown(1))
        expect_false(lurek.mouse.isDown(2))
        expect_false(lurek.mouse.isDown(3))
    end)
end)

describe("lurek.gamepad module exists", function()
    it("lurek.gamepad is a table", function()
        expect_type("table", lurek.gamepad)
    end)
end)

describe("lurek.gamepad functions", function()
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

    it("empty inventory returns stable defaults", function()
        expect_equal(0, lurek.gamepad.getCount())
        expect_equal(0, lurek.gamepad.getJoystickCount())
        local ids = lurek.gamepad.getJoysticks()
        expect_type("table", ids)
        expect_equal(0, #ids)
        expect_false(lurek.gamepad.isConnected(0))
        expect_false(lurek.gamepad.isGamepad(0))
    end)

    it("phase 03 advanced gamepad hooks exist", function()
        expect_type("function", lurek.gamepad.getGUID)
        expect_type("function", lurek.gamepad.getHat)
        expect_type("function", lurek.gamepad.setVibration)
    end)
end)

describe("lurek.touch module exists", function()
    it("lurek.touch is a table", function()
        expect_type("table", lurek.touch)
    end)
end)

describe("lurek.touch functions", function()
    it("phase 03 touch query functions exist", function()
        expect_type("function", lurek.touch.getTouches)
        expect_type("function", lurek.touch.getPosition)
        expect_type("function", lurek.touch.getPressure)
        expect_type("function", lurek.touch.getTouchCount)
    end)

    it("getTouches returns an empty table by default", function()
        local touches = lurek.touch.getTouches()
        expect_type("table", touches)
        expect_equal(0, #touches)
    end)
end)

describe("keyboard.isModifierActive", function()
    it("returns a boolean for valid modifiers", function()
        expect_type("boolean", lurek.keyboard.isModifierActive("shift"))
        expect_type("boolean", lurek.keyboard.isModifierActive("ctrl"))
        expect_type("boolean", lurek.keyboard.isModifierActive("alt"))
        expect_type("boolean", lurek.keyboard.isModifierActive("meta"))
        expect_type("boolean", lurek.keyboard.isModifierActive("super"))
    end)
    it("returns false for unknown modifier", function()
        expect_equal(false, lurek.keyboard.isModifierActive("capslock"))
    end)
    it("no modifiers held at start", function()
        expect_equal(false, lurek.keyboard.isModifierActive("shift"))
        expect_equal(false, lurek.keyboard.isModifierActive("ctrl"))
    end)
end)

describe("mouse cursor userdata", function()
    it("getSystemCursor returns a userdata", function()
        local c = lurek.mouse.getSystemCursor("arrow")
        expect_type("userdata", c)
    end)
    it("isCursorSupported returns a bool", function()
        expect_type("boolean", lurek.mouse.isCursorSupported())
        expect_equal(true, lurek.mouse.isCursorSupported())
    end)
    it("getSystemCursor hand cursor returns non-nil", function()
        local c = lurek.mouse.getSystemCursor("hand")
        expect_type("userdata", c)
    end)
    it("getSystemCursor crosshair cursor returns userdata", function()
        local c = lurek.mouse.getSystemCursor("crosshair")
        expect_type("userdata", c)
    end)
    it("setCursor accepts userdata and updates cursor", function()
        local c = lurek.mouse.getSystemCursor("hand")
        lurek.mouse.setCursor(c)
        expect_equal("hand", lurek.mouse.getCursor())
        lurek.mouse.setCursor("arrow")
    end)
    it("setCursor still accepts string for backward compat", function()
        lurek.mouse.setCursor("crosshair")
        expect_equal("crosshair", lurek.mouse.getCursor())
        lurek.mouse.setCursor("arrow")
    end)
end)

-- Phase 10: Gamepad Mapping Persistence
describe("lurek.gamepad mapping persistence", function()
    it("mapping API functions exist", function()
        expect_type("function", lurek.gamepad.setGamepadMapping)
        expect_type("function", lurek.gamepad.getGamepadMappingString)
        expect_type("function", lurek.gamepad.loadGamepadMappings)
        expect_type("function", lurek.gamepad.saveGamepadMappings)
    end)

    it("setGamepadMapping does not error for valid guid", function()
        lurek.gamepad.setGamepadMapping(
            "000000000000000000000000504944564d",
            "000000000000000000000000504944564d,TestPad,a:b0"
        )
    end)

    it("getGamepadMappingString returns nil for unknown guid", function()
        expect_equal(nil, lurek.gamepad.getGamepadMappingString("unknown_guid_xyz"))
    end)

    it("getGamepadMappingString returns a string after set", function()
        local guid = "030000005e0400008e02000014010000"
        lurek.gamepad.setGamepadMapping(guid, guid .. ",XInput,a:b0")
        local s = lurek.gamepad.getGamepadMappingString(guid)
        expect_type("string", s)
    end)

    it("loadGamepadMappings errors on missing file", function()
        expect_error(function()
            lurek.gamepad.loadGamepadMappings("__nonexistent_mappings_file_.txt")
        end)
    end)
end)

test_summary()
