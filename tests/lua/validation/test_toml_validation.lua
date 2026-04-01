-- Luna2D Validation Test: Corrupted and Malformed TOML
-- Tests that the TOML parser handles invalid input gracefully

describe("validation: corrupted TOML", function()
    it("rejects empty string", function()
        -- Empty TOML should parse as empty table, not crash
        expect_no_error(function()
            local result = luna.data.parseToml("")
        end)
    end)

    it("rejects incomplete key-value", function()
        expect_error(function()
            luna.data.parseToml("key = ")
        end, "incomplete key-value should error")
    end)

    it("rejects unclosed string", function()
        expect_error(function()
            luna.data.parseToml('name = "unclosed')
        end, "unclosed string should error")
    end)

    it("rejects unclosed table header", function()
        expect_error(function()
            luna.data.parseToml("[section\nkey = 1")
        end, "unclosed table header should error")
    end)

    it("rejects duplicate keys", function()
        expect_error(function()
            luna.data.parseToml("key = 1\nkey = 2")
        end, "duplicate keys should error")
    end)

    it("rejects invalid number format", function()
        expect_error(function()
            luna.data.parseToml("num = 12.34.56")
        end, "invalid number should error")
    end)

    it("rejects binary garbage", function()
        expect_error(function()
            luna.data.parseToml("\x00\x01\x02\xFF\xFE")
        end, "binary garbage should error")
    end)

    it("rejects deeply nested invalid TOML", function()
        expect_error(function()
            luna.data.parseToml("[a]\n[a.b]\n[a.b.c]\nkey = [[[invalid]]]")
        end, "deeply nested invalid syntax should error")
    end)

    it("handles very long key names", function()
        local long_key = string.rep("k", 10000)
        expect_no_error(function()
            luna.data.parseToml(long_key .. ' = "value"')
        end, "long key name should not crash")
    end)

    it("handles very long values", function()
        local long_val = string.rep("v", 50000)
        expect_no_error(function()
            luna.data.parseToml('key = "' .. long_val .. '"')
        end, "long value should not crash")
    end)
end)

describe("validation: TOML edge cases", function()
    it("parses valid minimal TOML", function()
        expect_no_error(function()
            local result = luna.data.parseToml('x = 1')
            expect_not_nil(result, "minimal TOML parsed")
        end)
    end)

    it("parses TOML with mixed types", function()
        expect_no_error(function()
            local toml_str = [[
                [section]
                integer = 42
                float = 3.14
                string = "hello"
                bool = true
                array = [1, 2, 3]
            ]]
            local result = luna.data.parseToml(toml_str)
            expect_not_nil(result, "mixed type TOML parsed")
        end)
    end)

    it("encodeToml rejects non-table input", function()
        -- encodeToml should only accept table values
        expect_error(function()
            luna.data.encodeToml("not a table")
        end, "string input should error")
    end)
end)
