-- test_filesystem.lua
-- Canonical file. Merged from multiple sources.

-- Lurek2D Security Test: Lua Sandbox Isolation
-- Verifies that dangerous Lua globals and standard libraries are blocked
-- in the engine sandbox. Mirrors tests from tests/rust/security/security_tests.rs.

local aa = {}
aa.__index = aa
aa.toemk = 10

-- @description Covers suite: sandbox: blocked globals.
describe("sandbox: blocked globals", function()
    -- @security sandbox
    -- @security isolation
    -- @description Verifies the Lua sandbox does not expose `os.execute`, preventing command execution from script code.
    it("os.execute is not accessible", function()
        local result = (os == nil) or (os.execute == nil)
        expect_equal(result, true)
    end)

    -- @description Confirms the sandbox strips `io.open` so scripts cannot open arbitrary host files.
    it("io.open is not accessible", function()
        local result = (io == nil) or (io.open == nil)
        expect_equal(result, true)
    end)

    -- @description Ensures dynamic code loading through `load()` is unavailable inside the restricted VM.
    it("load() is not accessible", function()
        local result = (load == nil)
        expect_equal(result, true)
    end)

    -- @description Checks that the Lua `debug` library is absent so scripts cannot introspect or tamper with VM internals.
    it("debug library is not accessible", function()
        local result = (debug == nil)
        expect_equal(result, true)
    end)
end)

-- @description Covers suite: sandbox: restricted require.
describe("sandbox: restricted require", function()
    -- @description Attempts to import an external networking library to verify the sandbox blocks or omits non-whitelisted modules.
    it("require('socket') fails gracefully", function()
        -- External network libraries must be blocked or absent in the sandbox.
        -- Either require is nil, or it returns nil, or it throws an error.
        if require == nil then
            expect_equal(true, true)
        else
            local ok, result = pcall(require, "socket")
            -- Acceptable outcomes: error thrown OR returned nil (module absent)
            expect_true(
                not ok or result == nil,
                "require('socket') must either fail or return nil in the sandbox"
            )
        end
    end)
end)

-- @description Covers suite: sandbox: runtime safety.
describe("sandbox: runtime safety", function()
    -- @covers pcall
    -- @description Verifies protected calls contain script-level exceptions so hostile Lua errors do not crash the VM host.
    it("pcall catches errors without crashing the VM", function()
        -- Verify pcall can catch errors (VM is stable under error conditions)
        local ok, err = pcall(function()
            error("intentional test error")
        end)
        expect_equal(ok, false)
        expect_true(type(err) == "string")
    end)

    -- @covers table.concat
    -- @description Builds a moderately large string through table concatenation to probe sandbox memory handling without invoking native APIs.
    it("large string concat completes without crash", function()
        local t = {}
        for i = 1, 1000 do
            t[i] = "x"
        end
        local result = #table.concat(t)
        expect_equal(result, 1000)
    end)

    -- @description Runs a simple arithmetic loop to verify ordinary script execution remains stable after prior sandbox error cases.
    it("basic arithmetic loop runs without error", function()
        local n = 0
        for i = 1, 1000 do
            n = n + 1
        end
        expect_equal(n, 1000)
    end)
end)



-- ================================================================
-- Merged from: test_mount_traversal.lua
-- ================================================================

-- Lurek2D Security Test: Mount traversal rejection.
-- Verifies that lurek.filesystem.mount refuses sandbox-escape paths and rejects traversal attempts before they can bind hostile sources.

-- @description Covers suite: filesystem security: mount traversal.
describe("filesystem security: mount traversal", function()
    -- @covers lurek.filesystem.mount
    -- @security lurek.filesystem.mount
    -- @description Attempts to mount an absolute traversal path that climbs out of the sandbox to verify the filesystem mount API blocks directory escape attacks.
    it("rejects ../../../etc as mount source", function()
        local ok, err = pcall(function()
            lurek.filesystem.mount("../../../etc", "/evil")
        end)
        expect_equal(false, ok)
        expect_true(err ~= nil)
    end)

    -- @covers lurek.filesystem.mount
    -- @description Uses an embedded `..` chain inside a nested path to ensure traversal filtering catches mixed in-sandbox and escape components.
    it("rejects .. component in source path", function()
        local ok, err = pcall(function()
            lurek.filesystem.mount("sub/../../../secret", "/leak")
        end)
        expect_equal(false, ok)
        expect_true(err ~= nil)
    end)
end)

test_summary()
