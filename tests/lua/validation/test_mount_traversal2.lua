-- Validate that mount() rejects path traversal attempts

describe("filesystem security: mount traversal", function()
    it("rejects ../../../etc as mount source", function()
        local ok, err = pcall(function()
            luna.filesystem.mount("../../../etc", "/evil")
        end)
        expect_equal(false, ok)
        expect_true(err ~= nil)
    end)

    it("rejects .. component in source path", function()
        local ok, err = pcall(function()
            luna.filesystem.mount("sub/../../../secret", "/leak")
        end)
        expect_equal(false, ok)
        expect_true(err ~= nil)
    end)
end)

test_summary()
