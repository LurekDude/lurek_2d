-- tests/lua/unit/test_scene_overlay.lua
-- Headless-safe (no window/GPU/audio needed).
-- Covers lurek.scene.pushOverlay and related overlay query functions.

-- @description Covers suite: Overlay mode (pushOverlay / isOverlay / depth).

describe("lurek.scene overlay mode", function()
    -- @covers lurek.scene.pushOverlay
    -- @covers lurek.scene.isOverlay
    -- @covers lurek.scene.depth
    -- @covers lurek.scene.getActiveScenes
    -- @description Verifies that pushOverlay is a registered function.
    it("pushOverlay is a function", function()
        expect_equal(type(lurek.scene.pushOverlay), "function")
    end)

    -- @description Verifies that pushOverlay accepts a scene table without error
    -- and that depth() correctly counts it on the stack.
    it("pushOverlay accepts a scene table and increments depth", function()
        lurek.scene.clear()
        local overlay = { enter = function() end, draw = function() end }
        lurek.scene.pushOverlay(overlay)
        expect_equal(lurek.scene.depth(), 1)
        lurek.scene.pop()
        expect_equal(lurek.scene.depth(), 0)
    end)

    -- @description Verifies that isOverlay() returns true for a scene pushed via pushOverlay.
    it("isOverlay returns true after pushOverlay", function()
        lurek.scene.clear()
        local overlay = {}
        lurek.scene.pushOverlay(overlay)
        expect_true(lurek.scene.isOverlay())
        lurek.scene.pop()
    end)

    -- @description Verifies that a normal push does NOT mark the scene as an overlay.
    it("isOverlay returns false after a normal push", function()
        lurek.scene.clear()
        local scene = {}
        lurek.scene.push(scene)
        expect_false(lurek.scene.isOverlay())
        lurek.scene.pop()
    end)

    -- @description Verifies that a background scene and overlay are both active (getActiveScenes).
    it("both background and overlay are in getActiveScenes", function()
        lurek.scene.clear()
        local bg      = { name = "bg"      }
        local overlay = { name = "overlay" }
        lurek.scene.push(bg)
        lurek.scene.pushOverlay(overlay)
        local active = lurek.scene.getActiveScenes()
        expect_equal(#active, 2)
        lurek.scene.clear()
    end)

    -- @description Verifies that depth() alias equals getStackSize().
    it("depth() equals getStackSize()", function()
        lurek.scene.clear()
        local s1 = {}
        local s2 = {}
        lurek.scene.push(s1)
        lurek.scene.pushOverlay(s2)
        expect_equal(lurek.scene.depth(), lurek.scene.getStackSize())
        lurek.scene.clear()
    end)
end)

test_summary()
