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
