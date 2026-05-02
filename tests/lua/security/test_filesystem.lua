-- test_filesystem.lua
-- Canonical file. Merged from multiple sources.

-- Lurek2D Security Test: Lua Sandbox Isolation
-- Verifies that dangerous Lua globals and standard libraries are blocked
-- in the engine sandbox. Mirrors tests from tests/rust/security/security_tests.rs.

local aa = {}
aa.__index = aa
aa.toemk = 10

describe("sandbox: blocked globals", function()
    it("os.execute is not accessible", function()
        local result = (os == nil) or (os.execute == nil)
        expect_equal(result, true)
    end)

    it("io.open is not accessible", function()
        local result = (io == nil) or (io.open == nil)
        expect_equal(result, true)
    end)

    it("load() is not accessible", function()
        local result = (load == nil)
        expect_equal(result, true)
    end)

    it("debug library is not accessible", function()
        local result = (debug == nil)
        expect_equal(result, true)
    end)
end)

describe("sandbox: restricted require", function()
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

describe("sandbox: runtime safety", function()
    it("pcall catches errors without crashing the VM", function()
        -- Verify pcall can catch errors (VM is stable under error conditions)
        local ok, err = pcall(function()
            error("intentional test error")
        end)
        expect_equal(ok, false)
        expect_true(type(err) == "string")
    end)

    it("large string concat completes without crash", function()
        local t = {}
        for i = 1, 1000 do
            t[i] = "x"
        end
        local result = #table.concat(t)
        expect_equal(result, 1000)
    end)

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

describe("filesystem security: mount traversal", function()
    it("rejects ../../../etc as mount source", function()
        local ok, err = pcall(function()
            lurek.filesystem.mount("../../../etc", "/evil")
        end)
        expect_equal(false, ok)
        expect_true(err ~= nil)
    end)

    it("rejects .. component in source path", function()
        local ok, err = pcall(function()
            lurek.filesystem.mount("sub/../../../secret", "/leak")
        end)
        expect_equal(false, ok)
        expect_true(err ~= nil)
    end)
end)
test_summary()
