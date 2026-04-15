-- tests/lua/unit/test_scene_preload.lua
-- Headless-safe (no window/GPU/audio needed).
-- Covers lurek.scene.preload, isPreloaded, and pushPreloaded.

-- @description Covers suite: Scene preloading (preload / isPreloaded / pushPreloaded).

describe("lurek.scene.preload", function()
    -- @covers lurek.scene.preload
    -- @covers lurek.scene.isPreloaded
    -- @covers lurek.scene.pushPreloaded
    -- @description Verifies that preload is a registered function.
    it("preload is a function", function()
        expect_equal(type(lurek.scene.preload), "function")
    end)

    -- @description Verifies that isPreloaded is a registered function.
    it("isPreloaded is a function", function()
        expect_equal(type(lurek.scene.isPreloaded), "function")
    end)

    -- @description Verifies that pushPreloaded is a registered function.
    it("pushPreloaded is a function", function()
        expect_equal(type(lurek.scene.pushPreloaded), "function")
    end)

    -- @description Verifies that registering a preload function completes without error.
    it("can register a preload function without error", function()
        lurek.scene.preload("test_scene", function()
            -- heavy asset load would go here
        end)
        expect_equal(true, true)
    end)

    -- @description Verifies that a scene is NOT marked as preloaded before it is pushed.
    it("scene is not preloaded before pushPreloaded is called", function()
        lurek.scene.clear()
        lurek.scene.preload("lazy_scene", function() end)
        expect_false(lurek.scene.isPreloaded("lazy_scene"))
    end)

    -- @description Verifies that the loader is called at most once even when pushPreloaded
    -- is invoked multiple times for the same name.
    it("loader is invoked exactly once across multiple pushPreloaded calls", function()
        lurek.scene.clear()
        local call_count = 0
        local dummy = {}
        lurek.scene.registerScene("once_scene", dummy)
        lurek.scene.preload("once_scene", function()
            call_count = call_count + 1
        end)
        lurek.scene.pushPreloaded("once_scene")
        lurek.scene.pop()
        lurek.scene.pushPreloaded("once_scene")
        lurek.scene.pop()
        expect_equal(call_count, 1)
        lurek.scene.unregisterScene("once_scene")
        lurek.scene.clear()
    end)

    -- @description Verifies that isPreloaded returns true after pushPreloaded runs the loader.
    it("isPreloaded returns true after pushPreloaded triggers the loader", function()
        lurek.scene.clear()
        local scene_tbl = {}
        lurek.scene.registerScene("preload_check", scene_tbl)
        lurek.scene.preload("preload_check", function() end)
        lurek.scene.pushPreloaded("preload_check")
        expect_true(lurek.scene.isPreloaded("preload_check"))
        lurek.scene.pop()
        lurek.scene.unregisterScene("preload_check")
        lurek.scene.clear()
    end)
end)

test_summary()
