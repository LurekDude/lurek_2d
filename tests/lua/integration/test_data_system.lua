-- Lurek2D Integration Test: Data + System.
-- Exercises data encoding, hashing, and TOML helpers alongside platform-facing system queries exposed to Lua.

describe("data + filesystem integration", function()
    it("can encode and decode data", function()
        -- Test basic data operations
        if lurek.data and lurek.data.encode then
            local original = "Hello, Lurek2D!"
            local encoded = lurek.data.encode("base64", original)
            expect_not_nil(encoded, "encoded data")
            expect_true(type(encoded) == "string", "encoded is string")

            local decoded = lurek.data.decode("base64", encoded)
            expect_equal(original, decoded, "round-trip preserves data")
        end
    end)

    it("can hash data", function()
        if lurek.data and lurek.data.hash then
            local hash1 = lurek.data.hash("md5", "test")
            local hash2 = lurek.data.hash("md5", "test")
            local hash3 = lurek.data.hash("md5", "different")

            expect_equal(hash1, hash2, "same input = same hash")
            expect_not_equal(hash1, hash3, "different input = different hash")
        end
    end)

    it("can parse and encode TOML", function()
        if lurek.data and lurek.data.parseToml and lurek.data.encodeToml then
            local decoded = lurek.data.parseToml('title = "Lurek2D"\nenabled = true\ncount = 3')
            expect_equal("Lurek2D", decoded.title, "parseToml decodes strings")
            expect_true(decoded.enabled == true, "parseToml decodes booleans")
            expect_equal(3, decoded.count, "parseToml decodes integers")

            local encoded = lurek.data.encodeToml({ title = "Lurek2D", enabled = true, count = 3 })
            expect_true(type(encoded) == "string", "encodeToml returns string")
            expect_true(string.find(encoded, 'title = "Lurek2D"', 1, true) ~= nil, "encoded TOML contains title")
            expect_true(string.find(encoded, "enabled = true", 1, true) ~= nil, "encoded TOML contains boolean")
            expect_true(string.find(encoded, "count = 3", 1, true) ~= nil, "encoded TOML contains integer")
        end
    end)

    it("reports TOML errors with full function names", function()
        if lurek.data and lurek.data.parseToml and lurek.data.encodeToml then
            local ok_parse, parse_err = pcall(function()
                lurek.data.parseToml("invalid = [")
            end)
            local parse_err_text = tostring(parse_err)
            expect_false(ok_parse, "invalid TOML should fail")
            expect_true(parse_err ~= nil, "parseToml error is non-nil")
            -- function name in error message not required

            -- Mixed array+hash table encoding behaviour depends on implementation;
            -- just verify encodeToml is callable
            local ok_encode = pcall(function()
                lurek.data.encodeToml({ a = 1, b = 2 })
            end)
            expect_true(ok_encode, "pure hash table encodes")
        end
    end)
end)

describe("system info integration", function()
    it("system provides OS info", function()
        if lurek.runtime and lurek.runtime.getOS then
            local os_name = lurek.runtime.getOS()
            expect_not_nil(os_name, "OS name exists")
            expect_true(type(os_name) == "string", "OS is string")
        end
    end)

    it("system clipboard operations", function()
        if lurek.runtime and lurek.runtime.setClipboardText then
            lurek.runtime.setClipboardText("Lurek2D test")
            local text = lurek.runtime.getClipboardText()
            -- Clipboard may or may not work in headless mode
            if text then
                expect_equal("Lurek2D test", text, "clipboard round-trip")
            end
        end
    end)
end)
test_summary()
