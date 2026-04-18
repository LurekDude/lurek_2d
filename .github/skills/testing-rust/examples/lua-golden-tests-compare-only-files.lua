-- tests/lua/golden/test_data_golden.lua
-- Golden tests compare pre-generated evidence only.

describe("data TOML round-trip golden", function()
    it("matches the committed TOML sample", function()
        expect_golden_text_match(
            "save/golden_text/migrated_rust/data/toml_roundtrip.toml",
            "tests/lua/golden/samples/migrated_rust/data/toml_roundtrip.toml"
        )
    end)
end)

test_summary()
