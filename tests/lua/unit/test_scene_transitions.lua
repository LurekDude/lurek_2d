-- tests/lua/unit/test_scene_transitions.lua
-- Headless-safe (no window/GPU/audio needed).
-- Covers lurek.scene.transitions built-in factory functions.

-- @description Covers suite: Built-in transition library (lurek.scene.transitions).

describe("lurek.scene.transitions", function()
    -- @covers lurek.scene.transitions
    -- @description Verifies that the transitions table is present on lurek.scene.
    it("transitions table exists", function()
        expect_equal(type(lurek.scene.transitions), "table")
    end)

    -- @description Verifies that lurek.scene.transitions.fade is a function.
    it("fade transition exists as a function", function()
        expect_equal(type(lurek.scene.transitions.fade), "function")
    end)

    -- @description Verifies that lurek.scene.transitions.slide is a function.
    it("slide transition exists as a function", function()
        expect_equal(type(lurek.scene.transitions.slide), "function")
    end)

    -- @description Verifies that lurek.scene.transitions.wipe is a function.
    it("wipe transition exists as a function", function()
        expect_equal(type(lurek.scene.transitions.wipe), "function")
    end)

    -- @description Verifies that lurek.scene.transitions.iris is a function.
    it("iris transition exists as a function", function()
        expect_equal(type(lurek.scene.transitions.iris), "function")
    end)

    -- @description Verifies that fade() with no args returns type="fade" and a default duration.
    it("fade() returns a table with type=fade", function()
        local t = lurek.scene.transitions.fade()
        expect_equal(t.type, "fade")
    end)

    -- @description Verifies that fade() default duration is 0.5.
    it("fade() returns default duration 0.5", function()
        local t = lurek.scene.transitions.fade()
        expect_near(t.duration, 0.5, 0.001)
    end)

    -- @description Verifies that fade(1.0) stores the supplied duration.
    it("fade(1.0) returns duration=1.0", function()
        local t = lurek.scene.transitions.fade(1.0)
        expect_near(t.duration, 1.0, 0.001)
    end)

    -- @description Verifies that slide() default type is "left".
    it("slide() returns type=left by default", function()
        local t = lurek.scene.transitions.slide()
        expect_equal(t.type, "left")
    end)

    -- @description Verifies that slide("right") stores the supplied direction.
    it("slide(\"right\") returns type=right", function()
        local t = lurek.scene.transitions.slide("right")
        expect_equal(t.type, "right")
    end)

    -- @description Verifies that slide() default duration is 0.4.
    it("slide() returns default duration 0.4", function()
        local t = lurek.scene.transitions.slide()
        expect_near(t.duration, 0.4, 0.001)
    end)

    -- @description Verifies that wipe() returns type="wipe" and default duration 0.5.
    it("wipe() returns type=wipe with default duration", function()
        local t = lurek.scene.transitions.wipe()
        expect_equal(t.type, "wipe")
        expect_near(t.duration, 0.5, 0.001)
    end)

    -- @description Verifies that iris() returns type="iris" and default duration 0.6.
    it("iris() returns type=iris with default duration", function()
        local t = lurek.scene.transitions.iris()
        expect_equal(t.type, "iris")
        expect_near(t.duration, 0.6, 0.001)
    end)

    -- @description Verifies that factory functions return independent table instances.
    it("each factory call returns a fresh table", function()
        local a = lurek.scene.transitions.fade()
        local b = lurek.scene.transitions.fade()
        expect_false(a == b)
    end)
end)

test_summary()
