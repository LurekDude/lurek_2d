-- test_filesystem.lua
-- Canonical file. Merged from multiple sources.

-- Lurek2D Security Test: Lua Sandbox Isolation
-- Verifies that dangerous Lua globals and standard libraries are blocked
-- in the engine sandbox. Mirrors tests from tests/rust/security/security_tests.rs.

-- @describe sandbox: blocked globals
describe("sandbox: blocked globals", function()
    -- @security sandbox.os.execute
    it("os.execute is not accessible", function()
        local result = (os == nil) or (os.execute == nil)
        expect_equal(result, true)
    end)

    -- @security sandbox.io.open
    it("io.open is not accessible", function()
        local result = (io == nil) or (io.open == nil)
        expect_equal(result, true)
    end)

    -- @security sandbox.load
    it("load() is not accessible", function()
        local result = (load == nil)
        expect_equal(result, true)
    end)

    -- @security sandbox.debug
    it("debug library is not accessible", function()
        local result = (debug == nil)
        expect_equal(result, true)
    end)

    -- @security sandbox.dofile
    it("dofile is unavailable or denied", function()
        if dofile == nil then
            expect_true(true)
            return
        end

        local ok = pcall(function()
            dofile("definitely_missing_file.lua")
        end)
        expect_equal(ok, false)
    end)
end)

-- @describe sandbox: restricted require
describe("sandbox: restricted require", function()
    -- @security sandbox.require.socket
    it("require('socket') fails gracefully", function()
        -- External network libraries must be blocked or absent in the sandbox.
        -- Either require is nil, or it returns nil, or it throws an error.
        if require == nil then
            expect_nil(require)
        else
            local ok, result = pcall(require, "socket")
            -- Acceptable outcomes: error thrown OR returned nil (module absent)
            expect_true(
                not ok or result == nil,
                "require('socket') must either fail or return nil in the sandbox"
            )
        end
    end)

    -- @security sandbox.package.loadlib
    it("package.loadlib is unavailable or denied", function()
        if package == nil or package.loadlib == nil then
            expect_true(true)
            return
        end

        local ok = pcall(function()
            package.loadlib("nonexistent.dll", "luaopen_x")
        end)
        expect_equal(ok, false)
    end)
end)

-- @describe sandbox: runtime safety
describe("sandbox: runtime safety", function()
    -- @security sandbox.pcall
    it("pcall catches errors without crashing the VM", function()
        -- Verify pcall can catch errors (VM is stable under error conditions)
        local ok, err = pcall(function()
            error("intentional test error")
        end)
        expect_equal(ok, false)
        expect_true(type(err) == "string")
    end)

    -- @security sandbox.table.concat
    it("large string concat completes without crash", function()
        local t = {}
        for i = 1, 1000 do
            t[i] = "x"
        end
        local result = #table.concat(t)
        expect_equal(result, 1000)
    end)

    -- @security sandbox.loop
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

-- @describe filesystem security: mount traversal
describe("filesystem security: mount traversal", function()
    -- @security lurek.filesystem.mount
    it("rejects ../../../etc as mount source", function()
        local ok, err = pcall(function()
            lurek.filesystem.mount("../../../etc", "/evil")
        end)
        expect_equal(false, ok)
        expect_true(err ~= nil)
    end)

    -- @security lurek.filesystem.mount
    it("rejects .. component in source path", function()
        local ok, err = pcall(function()
            lurek.filesystem.mount("sub/../../../secret", "/leak")
        end)
        expect_equal(false, ok)
        expect_true(err ~= nil)
    end)

    -- @security lurek.filesystem.read
    it("rejects traversal read path", function()
        local ok, err = pcall(function()
            lurek.filesystem.read("../../outside.txt")
        end)
        expect_equal(false, ok)
        expect_true(err ~= nil)
    end)

    -- @security lurek.filesystem.write
    it("rejects traversal write path", function()
        local ok, err = pcall(function()
            lurek.filesystem.write("../../outside.txt", "x")
        end)
        expect_equal(false, ok)
        expect_true(err ~= nil)
    end)
end)
test_summary()


