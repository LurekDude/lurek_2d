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

    it("can parse and encode TOML", function()
        if luna.data and luna.data.parseToml and luna.data.encodeToml then
            local decoded = luna.data.parseToml('title = "Luna2D"\nenabled = true\ncount = 3')
            expect_equal("Luna2D", decoded.title, "parseToml decodes strings")
            expect_true(decoded.enabled == true, "parseToml decodes booleans")
            expect_equal(3, decoded.count, "parseToml decodes integers")

            local encoded = luna.data.encodeToml({ title = "Luna2D", enabled = true, count = 3 })
            expect_true(type(encoded) == "string", "encodeToml returns string")
            expect_true(string.find(encoded, 'title = "Luna2D"', 1, true) ~= nil, "encoded TOML contains title")
            expect_true(string.find(encoded, "enabled = true", 1, true) ~= nil, "encoded TOML contains boolean")
            expect_true(string.find(encoded, "count = 3", 1, true) ~= nil, "encoded TOML contains integer")
        end
    end)

    it("reports TOML errors with full function names", function()
        if luna.data and luna.data.parseToml and luna.data.encodeToml then
            local ok_parse, parse_err = pcall(function()
                luna.data.parseToml("invalid = [")
            end)
            local parse_err_text = tostring(parse_err)
            expect_false(ok_parse, "invalid TOML should fail")
            expect_true(type(parse_err) == "string", "parseToml error is string")
            expect_true(string.find(parse_err_text, "luna.data.parseToml", 1, true) ~= nil, "parseToml error includes function name")

            local ok_encode, encode_err = pcall(function()
                luna.data.encodeToml({ [1] = "first", name = "mixed" })
            end)
            local encode_err_text = tostring(encode_err)
            expect_false(ok_encode, "mixed table should fail")
            expect_true(type(encode_err) == "string", "encodeToml error is string")
            expect_true(string.find(encode_err_text, "luna.data.encodeToml", 1, true) ~= nil, "encodeToml error includes function name")
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
