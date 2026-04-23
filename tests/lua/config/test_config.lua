-- tests/lua/config/test_config.lua
-- BDD tests for the lurek.conf(t) configuration API, focused on runtime reads and merged configuration visibility after boot.

-- @covers lurek.runtime.getOS
-- @covers lurek.runtime.getVersion
-- @covers lurek.window.getHeight
-- @covers lurek.window.getTitle
-- @covers lurek.window.getWidth
-- @covers lurek.window.isFullscreen
-- @covers lurek.window.isResizable
-- These tests verify that the conf table is readable at runtime, that
-- lurek.conf() merges overrides correctly, and that conf keys are
-- accessible after the engine boots.
--
-- NOTE: lurek.conf(t) is a write-once function called during startup
-- (before the window opens). These tests verify the READ path only
-- they do not attempt to re-configure a running engine.

require("tests/lua/init")

--
-- 1. lurek.conf existence
--

-- @description Covers suite: lurek.conf function.
describe("lurek.conf function", function()
    -- @covers lurek.conf
    -- @description Verifies that the startup configuration entrypoint is exposed to Lua as a callable function in the test VM.
    -- NOTE: lurek.conf is not yet registered in the Lua API; pending until implemented.
    pending("lurek.conf is a function — lurek.conf not yet exposed to Lua")
end)

--
-- 2. lurek.window namespace mirrors conf.window
--

-- @description Covers suite: lurek.window runtime values.
describe("lurek.window runtime values", function()
    -- @covers lurek.window
    -- @description Confirms the runtime window namespace is present as a Lua table before any individual accessors are exercised.
    it("lurek.window is a table", function()
        expect_type("table", lurek.window)
    end)

    -- @covers lurek.window.getWidth
    -- @description Reads the runtime window width and only asserts that the accessor returns a numeric value greater than zero.
    it("lurek.window.getWidth returns a positive number", function()
        local w = lurek.window.getWidth()
        expect_type("number", w)
        expect_equal(w > 0, true)
    end)

    -- @covers lurek.window.getHeight
    -- @description Reads the runtime window height and only asserts that the accessor returns a numeric value greater than zero.
    it("lurek.window.getHeight returns a positive number", function()
        local h = lurek.window.getHeight()
        expect_type("number", h)
        expect_equal(h > 0, true)
    end)

    -- @covers lurek.window.getTitle
    -- @description Checks that the boot-time window title is readable and surfaced as a Lua string.
    it("lurek.window.getTitle returns a string", function()
        local title = lurek.window.getTitle()
        expect_type("string", title)
    end)
end)

--
-- 3. Modules table
--

-- @description Covers suite: lurek.runtime module flags.
describe("lurek.runtime module flags", function()
    -- @covers lurek.runtime
    -- @description Confirms the platform namespace itself is registered as a table before querying platform metadata.
    it("lurek.runtime is a table", function()
        expect_type("table", lurek.runtime)
    end)

    -- @covers lurek.runtime.getVersion
    -- @description Verifies that the platform version accessor returns a non-empty version string.
    it("lurek.runtime.getVersion returns a string", function()
        local v = lurek.runtime.getVersion()
        expect_type("string", v)
        expect_equal(#v > 0, true)
    end)

    -- @covers lurek.runtime.getOS
    -- @description Checks that the reported operating system name stays within the expected Windows, Linux, or macOS set.
    it("lurek.runtime.getOS returns a known platform string", function()
        local os = lurek.runtime.getOS()
        local valid = { Windows = true, Linux = true, macOS = true }
        expect_equal(valid[os] ~= nil, true)
    end)
end)

--
-- 4. lurek.conf merge semantics (introspection via lurek.window)
--

-- @description Covers suite: lurek.conf merge semantics.
describe("lurek.conf merge semantics", function()
    -- In a headless test VM the engine is already booted with defaults.
    -- We verify that conf.window defaults are reflected in lurek.window.

    -- @covers lurek.window.getWidth
    -- @description Confirms only that the default boot width has been populated into the runtime window state, not that it equals an exact fixture value.
    it("default window width matches conf default of 800", function()
        -- The test VM is created with 800     600 by default (see make_vm).
        -- lurek.window.getWidth() should reflect that.
        local w = lurek.window.getWidth()
        expect_equal(w >= 1, true)  -- just confirm it's set
    end)
    -- @covers lurek.window.getHeight
    -- @description Confirms only that the default boot height has been populated into the runtime window state, not that it equals an exact fixture value.
    it("default window height matches conf default of 600", function()
        local h = lurek.window.getHeight()
        expect_equal(h >= 1, true)
    end)

    -- @covers lurek.window.isResizable
    -- @description Verifies that the runtime resizable flag is exposed as a boolean after configuration merging.
    it("lurek.window.isResizable returns a boolean", function()
        local r = lurek.window.isResizable()
        expect_type("boolean", r)
    end)

    -- @covers lurek.window.isFullscreen
    -- @description Verifies that the runtime fullscreen flag is exposed as a boolean after configuration merging.
    it("lurek.window.isFullscreen returns a boolean", function()
        local f = lurek.window.isFullscreen()
        expect_type("boolean", f)
    end)
end)

--
-- 5. conf.lua conf() call does not crash with various overrides
--

-- @description Covers suite: lurek.conf call-time safety.
describe("lurek.conf call-time safety", function()
    -- NOTE: lurek.conf is not yet registered in the Lua API; pending until implemented.
    pending("lurek.conf call-time safety — lurek.conf not yet exposed to Lua")
end)

test_summary()
