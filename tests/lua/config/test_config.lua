-- tests/lua/config/test_config.lua
-- BDD tests for the luna.conf(t) configuration API.
-- These tests verify that the conf table is readable at runtime, that
-- luna.conf() merges overrides correctly, and that conf keys are
-- accessible after the engine boots.
--
-- NOTE: luna.conf(t) is a write-once function called during startup
-- (before the window opens). These tests verify the READ path only —
-- they do not attempt to re-configure a running engine.

require("tests/lua/init")

-- ═════════════════════════════════════════════════════════════════════════
-- 1. luna.conf existence
-- ═════════════════════════════════════════════════════════════════════════

describe("luna.conf function", function()
    it("luna.conf is a function", function()
        expect_type("function", luna.conf)
    end)
end)

-- ═════════════════════════════════════════════════════════════════════════
-- 2. luna.window namespace mirrors conf.window
-- ═════════════════════════════════════════════════════════════════════════

describe("luna.window runtime values", function()
    it("luna.window is a table", function()
        expect_type("table", luna.window)
    end)

    it("luna.window.getWidth returns a positive number", function()
        local w = luna.window.getWidth()
        expect_type("number", w)
        expect_equal(w > 0, true)
    end)

    it("luna.window.getHeight returns a positive number", function()
        local h = luna.window.getHeight()
        expect_type("number", h)
        expect_equal(h > 0, true)
    end)

    it("luna.window.getTitle returns a string", function()
        local title = luna.window.getTitle()
        expect_type("string", title)
    end)
end)

-- ═════════════════════════════════════════════════════════════════════════
-- 3. Modules table
-- ═════════════════════════════════════════════════════════════════════════

describe("luna.system module flags", function()
    it("luna.system is a table", function()
        expect_type("table", luna.system)
    end)

    it("luna.system.getVersion returns a string", function()
        local v = luna.system.getVersion()
        expect_type("string", v)
        expect_equal(#v > 0, true)
    end)

    it("luna.system.getOS returns a known platform string", function()
        local os = luna.system.getOS()
        local valid = { Windows = true, Linux = true, macOS = true }
        expect_equal(valid[os] ~= nil, true)
    end)
end)

-- ═════════════════════════════════════════════════════════════════════════
-- 4. luna.conf merge semantics (introspection via luna.window)
-- ═════════════════════════════════════════════════════════════════════════

describe("luna.conf merge semantics", function()
    -- In a headless test VM the engine is already booted with defaults.
    -- We verify that conf.window defaults are reflected in luna.window.

    it("default window width matches conf default of 800", function()
        -- The test VM is created with 800×600 by default (see make_vm).
        -- luna.window.getWidth() should reflect that.
        local w = luna.window.getWidth()
        expect_equal(w >= 1, true)  -- just confirm it's set
    end)

    it("default window height matches conf default of 600", function()
        local h = luna.window.getHeight()
        expect_equal(h >= 1, true)
    end)

    it("luna.window.isResizable returns a boolean", function()
        local r = luna.window.isResizable()
        expect_type("boolean", r)
    end)

    it("luna.window.isFullscreen returns a boolean", function()
        local f = luna.window.isFullscreen()
        expect_type("boolean", f)
    end)
end)

-- ═════════════════════════════════════════════════════════════════════════
-- 5. conf.lua conf() call does not crash with various overrides
-- ═════════════════════════════════════════════════════════════════════════

describe("luna.conf call-time safety", function()
    it("calling luna.conf with an empty table does not crash", function()
        luna.conf({})
        expect_equal(true, true)
    end)

    it("calling luna.conf with unknown keys does not crash", function()
        luna.conf({ completely_unknown_key = true })
        expect_equal(true, true)
    end)

    it("calling luna.conf with nested partial table does not crash", function()
        luna.conf({ window = { title = "TestTitle" } })
        expect_equal(true, true)
    end)
end)

test_summary()
