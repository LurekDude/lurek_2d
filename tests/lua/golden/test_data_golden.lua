-- Golden test: data compare-only evidence validation.

describe("golden: data TOML round-trip", function()
    it("matches migrated Rust TOML sample", function()
        local evidence = "save/golden_text/migrated_rust/data/toml_roundtrip.toml"
        local golden = "tests/samples/migrated_rust/data/toml_roundtrip.toml"
        expect_golden_text_match(evidence, golden)
    end)
end)



-- ================================================================
-- Merged from: test_migrated_rust_golden.lua
-- ================================================================

-- Golden test: migrated Rust text and binary baselines now compared from the Lua golden layer only.

describe("golden: migrated Rust baselines", function()
    it("matches migrated Rust TOML sample", function()
        expect_golden_text_match("save/golden_text/migrated_rust/data/toml_roundtrip.toml", "tests/samples/migrated_rust/data/toml_roundtrip.toml")
    end)

    it("matches migrated Rust encode samples", function()
        expect_golden_text_match("save/golden_text/migrated_rust/encode/base64_encode.txt", "tests/samples/migrated_rust/encode/base64_encode.txt")
        expect_golden_text_match("save/golden_text/migrated_rust/encode/hex_encode.txt", "tests/samples/migrated_rust/encode/hex_encode.txt")
    end)

    it("matches migrated Rust hash samples", function()
        expect_golden_text_match("save/golden_text/migrated_rust/hash/md5_hello.txt", "tests/samples/migrated_rust/hash/md5_hello.txt")
        expect_golden_text_match("save/golden_text/migrated_rust/hash/sha1_engine.txt", "tests/samples/migrated_rust/hash/sha1_engine.txt")
        expect_golden_text_match("save/golden_text/migrated_rust/hash/sha256_hello.txt", "tests/samples/migrated_rust/hash/sha256_hello.txt")
        expect_golden_text_match("save/golden_text/migrated_rust/hash/sha512_engine.txt", "tests/samples/migrated_rust/hash/sha512_engine.txt")
    end)

end)




-- ================================================================
-- Merged from: test_migrated_15_golden.lua
-- ================================================================

-- Golden test: migrated 15

describe("golden: migrated 15 evidence comparison", function()
    local OUT = evidence_output_dir("migrated_15")
    local SAMP = "tests/samples/migrated_15/"

    it("matches golden samples", function()
        expect_golden_file_match(OUT .. "new_blank_64x64.png", SAMP .. "new_blank_64x64.png")
        expect_golden_file_match(OUT .. "fill_orange.png", SAMP .. "fill_orange.png")
        expect_golden_file_match(OUT .. "diagonal_cross.png", SAMP .. "diagonal_cross.png")
        expect_golden_file_match(OUT .. "shapes_combined_scene.png", SAMP .. "shapes_combined_scene.png")
        expect_golden_file_match(OUT .. "paste_composite.png", SAMP .. "paste_composite.png")
        expect_golden_file_match(OUT .. "noise_after.png", SAMP .. "noise_after.png")
        expect_golden_file_match(OUT .. "flip_h_after.png", SAMP .. "flip_h_after.png")
        expect_golden_file_match(OUT .. "flip_v_after.png", SAMP .. "flip_v_after.png")
        expect_golden_file_match(OUT .. "rotate_90cw.png", SAMP .. "rotate_90cw.png")
        expect_golden_file_match(OUT .. "crop_center.png", SAMP .. "crop_center.png")
        expect_golden_file_match(OUT .. "resize_upscaled_128.png", SAMP .. "resize_upscaled_128.png")
        expect_golden_file_match(OUT .. "alpha_mask_50pct.png", SAMP .. "alpha_mask_50pct.png")
        expect_golden_file_match(OUT .. "pipeline_05_blur.png", SAMP .. "pipeline_05_blur.png")
        expect_golden_file_match(OUT .. "noise_terrain_map.png", SAMP .. "noise_terrain_map.png")
        expect_golden_file_match(OUT .. "generate_map.png", SAMP .. "generate_map.png")
    end)
end)
test_summary()
