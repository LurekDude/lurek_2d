-- tests/lua/test_joystick_ext.lua
-- BDD-style integration tests for luna.gamepad background events extension

describe("luna.gamepad.getBackgroundEvents", function()
    it("defaults to false", function()
        expect_equal(false, luna.gamepad.getBackgroundEvents())
    end)
end)

describe("luna.gamepad.setBackgroundEvents", function()
    it("can enable background events", function()
        luna.gamepad.setBackgroundEvents(true)
        expect_equal(true, luna.gamepad.getBackgroundEvents())
    end)

    it("can disable background events", function()
        luna.gamepad.setBackgroundEvents(true)
        luna.gamepad.setBackgroundEvents(false)
        expect_equal(false, luna.gamepad.getBackgroundEvents())
    end)
end)

test_summary()
