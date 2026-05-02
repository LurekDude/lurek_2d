-- Golden test: serial compare-only evidence validation.

describe("golden: serial Encode/decode deterministic output", function()
    it("matches migrated Rust encode samples", function()
        expect_golden_text_match("save/golden_text/migrated_rust/encode/base64_encode.txt", "tests/samples/migrated_rust/encode/base64_encode.txt")
        expect_golden_text_match("save/golden_text/migrated_rust/encode/hex_encode.txt", "tests/samples/migrated_rust/encode/hex_encode.txt")
    end)
end)
test_summary()
