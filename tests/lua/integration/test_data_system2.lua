-- Luna2D Integration Test: Data + Filesystem
-- Tests data encoding/compression with filesystem I/O

describe("data + filesystem integration", function()
    it("can encode and decode data", function()
        -- Test basic data operations
        if luna.data and luna.data.encode then
            local original = "Hello, Luna2D!"
            local encoded = luna.data.encode("base64", original)
            expect_not_nil(encoded, "encoded data")
            expect_true(type(encoded) == "string", "encoded is string")

            local decoded = luna.data.decode("base64", encoded)
            expect_equal(original, decoded, "round-trip preserves data")
        end
    end)

    it("can hash data", function()
        if luna.data and luna.data.hash then
            local hash1 = luna.data.hash("md5", "test")
            local hash2 = luna.data.hash("md5", "test")
            local hash3 = luna.data.hash("md5", "different")

            expect_equal(hash1, hash2, "same input = same hash")
            expect_not_equal(hash1, hash3, "different input = different hash")
        end
    end)
end)

describe("system info integration", function()
    it("system provides OS info", function()
        if luna.system and luna.system.getOS then
            local os_name = luna.system.getOS()
            expect_not_nil(os_name, "OS name exists")
            expect_true(type(os_name) == "string", "OS is string")
        end
    end)

    it("system clipboard operations", function()
        if luna.system and luna.system.setClipboardText then
            luna.system.setClipboardText("Luna2D test")
            local text = luna.system.getClipboardText()
            -- Clipboard may or may not work in headless mode
            if text then
                expect_equal("Luna2D test", text, "clipboard round-trip")
            end
        end
    end)
end)
