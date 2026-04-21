-- tests/lua/config/test_runtime_config_fallback.lua
--
-- BDD tests for the conf.lua parse-error fallback behaviour.
--
-- When conf.lua contains a syntax or runtime error, Config::load_from_conf_lua()
-- logs L052 + "Using default config." and continues with Config::default().
-- These tests verify that the default values are reachable through the Lua API
-- surface after the VM has been initialised with those defaults.
--
-- NOTE: This test suite does NOT attempt to parse a broken conf.lua file; that
-- requires filesystem fixtures outside the lightweight test VM.  Instead it
-- exercises every lurek.runtime.* introspection function that would be accessible
-- on a default-config boot, confirming the API surface itself is intact.
--
-- @covers lurek.runtime.getVersion
-- @covers lurek.runtime.getFrameBudget
-- @covers lurek.runtime.memoryUsage
-- @covers lurek.runtime.platform
-- @covers lurek.runtime.uptime

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. lurek.runtime namespace
-- ─────────────────────────────────────────────────────────────────────────────

-- @description Verifies the lurek.runtime introspection namespace is registered
-- as a table and all expected accessor keys are present.
describe("lurek.runtime namespace (post-default-config)", function()
    -- @covers lurek.runtime
    -- @description Confirms the engine introspection namespace is a Lua table.
    it("lurek.runtime is a table", function()
        expect_type("table", lurek.runtime)
    end)

    -- @covers lurek.runtime.getVersion
    -- @description Confirms getVersion is callable and present on the table.
    it("lurek.runtime.getVersion is a function", function()
        expect_type("function", lurek.runtime.getVersion)
    end)

    -- @covers lurek.runtime.getFrameBudget
    -- @description Confirms getFrameBudget is callable.
    it("lurek.runtime.getFrameBudget is a function", function()
        expect_type("function", lurek.runtime.getFrameBudget)
    end)

    -- @covers lurek.runtime.memoryUsage
    -- @description Confirms memoryUsage is callable.
    it("lurek.runtime.memoryUsage is a function", function()
        expect_type("function", lurek.runtime.memoryUsage)
    end)

    -- @covers lurek.runtime.platform
    -- @description Confirms platform is callable.
    it("lurek.runtime.platform is a function", function()
        expect_type("function", lurek.runtime.platform)
    end)

    -- @covers lurek.runtime.uptime
    -- @description Confirms uptime is callable.
    it("lurek.runtime.uptime is a function", function()
        expect_type("function", lurek.runtime.uptime)
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. lurek.runtime.getVersion — default config value
-- ─────────────────────────────────────────────────────────────────────────────

-- @description Verifies the engine version string is non-empty and follows the
-- expected MAJOR.MINOR.PATCH semver shape when the engine runs with defaults.
describe("lurek.runtime.getVersion (default config)", function()
    -- @covers lurek.runtime.getVersion
    -- @description getVersion() must return a non-empty string.
    it("returns a non-empty string", function()
        local v = lurek.runtime.getVersion()
        expect_type("string", v)
        expect_equal(#v > 0, true)
    end)

    -- @covers lurek.runtime.getVersion
    -- @description Version string must contain at least one dot (semver shape).
    it("version string contains a dot separator", function()
        local v = lurek.runtime.getVersion()
        expect_equal(v:find("%.") ~= nil, true)
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. lurek.runtime.getFrameBudget — default 60 fps target
-- ─────────────────────────────────────────────────────────────────────────────

-- @description Verifies the default frame budget is a positive number consistent
-- with the 60 FPS target baked into Config::default().
describe("lurek.runtime.getFrameBudget (default config)", function()
    -- @covers lurek.runtime.getFrameBudget
    -- @description Frame budget must be a positive number greater than zero.
    it("returns a positive number", function()
        local ms = lurek.runtime.getFrameBudget()
        expect_type("number", ms)
        expect_equal(ms > 0, true)
    end)

    -- @covers lurek.runtime.getFrameBudget
    -- @description Default 60 fps target gives ~16.667 ms per frame; budget must
    -- be within the plausible range [10, 50] ms.
    it("default budget is in the [10, 50] ms range", function()
        local ms = lurek.runtime.getFrameBudget()
        expect_equal(ms >= 10 and ms <= 50, true)
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. lurek.runtime.memoryUsage — Lua heap introspection
-- ─────────────────────────────────────────────────────────────────────────────

-- @description Verifies memoryUsage() returns a table with the expected fields
-- and that reported Lua heap usage is a non-negative number.
describe("lurek.runtime.memoryUsage (default config)", function()
    -- @covers lurek.runtime.memoryUsage
    -- @description Return value must be a table.
    it("returns a table", function()
        local m = lurek.runtime.memoryUsage()
        expect_type("table", m)
    end)

    -- @covers lurek.runtime.memoryUsage
    -- @description The lua_bytes field must be a non-negative integer.
    it("lua_bytes is a non-negative number", function()
        local m = lurek.runtime.memoryUsage()
        expect_not_nil(m.lua_bytes, "lua_bytes exists")
        expect_type("number", m.lua_bytes)
        expect_equal(m.lua_bytes >= 0, true)
    end)

    -- @covers lurek.runtime.memoryUsage
    -- @description The lua_kb field must be a non-negative number.
    it("lua_kb is a non-negative number", function()
        local m = lurek.runtime.memoryUsage()
        expect_not_nil(m.lua_kb, "lua_kb exists")
        expect_type("number", m.lua_kb)
        expect_equal(m.lua_kb >= 0, true)
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. lurek.runtime.platform — host OS identifier
-- ─────────────────────────────────────────────────────────────────────────────

-- @description Verifies the platform string is one of the known host OS names.
describe("lurek.runtime.platform (default config)", function()
    -- @covers lurek.runtime.platform
    -- @description platform() must return a known non-empty string.
    it("returns a non-empty string", function()
        local p = lurek.runtime.platform()
        expect_type("string", p)
        expect_equal(#p > 0, true)
    end)

    -- @covers lurek.runtime.platform
    -- @description Returned value must be one of the known OS identifiers.
    it("value is a known OS name", function()
        local p = lurek.runtime.platform()
        local known = { windows = true, linux = true, macos = true, unknown = true }
        expect_equal(known[p] ~= nil, true)
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. lurek.runtime.uptime — total elapsed time
-- ─────────────────────────────────────────────────────────────────────────────

-- @description Verifies uptime() returns a non-negative number (zero is expected
-- in the headless test VM where no frames have been stepped).
describe("lurek.runtime.uptime (default config)", function()
    -- @covers lurek.runtime.uptime
    -- @description uptime() must return a non-negative number.
    it("returns a non-negative number", function()
        local t = lurek.runtime.uptime()
        expect_type("number", t)
        expect_equal(t >= 0, true)
    end)
end)

test_summary()
