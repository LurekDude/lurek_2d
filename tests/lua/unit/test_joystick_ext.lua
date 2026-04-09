-- tests/lua/test_joystick_ext.lua
-- BDD-style integration tests for lurek.gamepad background events extension

describe("lurek.gamepad.getBackgroundEvents", function()
    it("defaults to false", function()
        expect_equal(false, lurek.gamepad.getBackgroundEvents())
    end)
end)

describe("lurek.gamepad.setBackgroundEvents", function()
    it("can enable background events", function()
        lurek.gamepad.setBackgroundEvents(true)
        expect_equal(true, lurek.gamepad.getBackgroundEvents())
    end)

    it("can disable background events", function()
        lurek.gamepad.setBackgroundEvents(true)
        lurek.gamepad.setBackgroundEvents(false)
        expect_equal(false, lurek.gamepad.getBackgroundEvents())
    end)
end)

test_summary()
