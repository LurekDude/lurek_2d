//! Golden file tests — verify deterministic binary output.
//!
//! Creates known inputs, generates outputs, and compares against stored baselines
//! in `tests/golden/expected/`. On first run, baselines are generated automatically.
//! Subsequent runs verify the output matches byte-for-byte.

use luna2d::data::compress::{compress, decompress, CompressFormat};
use luna2d::data::encode::{decode, encode, EncodeFormat};
use luna2d::data::hash::{hash, HashAlgorithm};
use luna2d::data::toml_convert::{encode_toml, parse_toml};
use luna2d::image::ImageData;
use std::fs;
use std::path::Path;

/// Helper: compare actual bytes to a golden file. If the golden file doesn't exist,
/// create it (first run). If it does exist, assert byte-for-byte equality.
fn assert_golden(name: &str, actual: &[u8]) {
    let expected_path = format!("tests/golden/expected/{}", name);
    let actual_path = format!("tests/golden/actual/{}", name);

    // Always write the actual output for inspection
    fs::create_dir_all("tests/golden/actual").unwrap();
    fs::write(&actual_path, actual).unwrap();

    if Path::new(&expected_path).exists() {
        let expected = fs::read(&expected_path).unwrap();
        assert_eq!(
            actual,
            &expected[..],
            "Golden file mismatch for '{}'. Actual written to '{}'.",
            name,
            actual_path
        );
    } else {
        // First run: create the baseline
        fs::create_dir_all("tests/golden/expected").unwrap();
        fs::write(&expected_path, actual).unwrap();
        println!(
            "Golden baseline created: {}. Re-run to verify.",
            expected_path
        );
    }
}

/// Helper: compare actual string to a golden file.
fn assert_golden_text(name: &str, actual: &str) {
    assert_golden(name, actual.as_bytes());
}

// ===========================================================================
// Image encode determinism
// ===========================================================================

#[test]
fn golden_png_encode_solid_red() {
    let mut img = ImageData::new(4, 4);
    for y in 0..4 {
        for x in 0..4 {
            img.set_pixel(x, y, 255, 0, 0, 255);
        }
    }
    let png = img.encode_png().unwrap();
    // Verify PNG signature
    assert_eq!(&png[..4], &[137, 80, 78, 71], "PNG signature mismatch");
    assert_golden("solid_red_4x4.png", &png);
}

#[test]
fn golden_png_encode_gradient() {
    let mut img = ImageData::new(8, 8);
    for y in 0..8 {
        for x in 0..8 {
            let r = (x * 32) as u8;
            let g = (y * 32) as u8;
            img.set_pixel(x, y, r, g, 128, 255);
        }
    }
    let png = img.encode_png().unwrap();
    assert_golden("gradient_8x8.png", &png);
}

#[test]
fn golden_png_encode_checkerboard() {
    let mut img = ImageData::new(16, 16);
    for y in 0..16 {
        for x in 0..16 {
            if (x + y) % 2 == 0 {
                img.set_pixel(x, y, 255, 255, 255, 255);
            } else {
                img.set_pixel(x, y, 0, 0, 0, 255);
            }
        }
    }
    let png = img.encode_png().unwrap();
    assert_golden("checkerboard_16x16.png", &png);
}

// ===========================================================================
// Hash stability
// ===========================================================================

#[test]
fn golden_hash_sha256_known_digest() {
    // SHA-256 of "Hello, Luna2D!" is deterministic
    let digest = hash(HashAlgorithm::Sha256, b"Hello, Luna2D!");
    assert_golden_text("sha256_hello.txt", &digest);
    // Cross-check with known value
    assert_eq!(digest.len(), 64, "SHA-256 hex digest must be 64 chars");
}

#[test]
fn golden_hash_md5_known_digest() {
    let digest = hash(HashAlgorithm::Md5, b"Hello, Luna2D!");
    assert_golden_text("md5_hello.txt", &digest);
    assert_eq!(digest.len(), 32, "MD5 hex digest must be 32 chars");
}

#[test]
fn golden_hash_sha512_known_digest() {
    let digest = hash(HashAlgorithm::Sha512, b"Luna2D engine test vector");
    assert_golden_text("sha512_engine.txt", &digest);
    assert_eq!(digest.len(), 128, "SHA-512 hex digest must be 128 chars");
}

#[test]
fn golden_hash_sha1_known_digest() {
    let digest = hash(HashAlgorithm::Sha1, b"Luna2D engine test vector");
    assert_golden_text("sha1_engine.txt", &digest);
    assert_eq!(digest.len(), 40, "SHA-1 hex digest must be 40 chars");
}

// ===========================================================================
// Encoding stability
// ===========================================================================

#[test]
fn golden_base64_encode() {
    let encoded = encode(EncodeFormat::Base64, b"Luna2D rocks!");
    assert_golden_text("base64_encode.txt", &encoded);
}

#[test]
fn golden_hex_encode() {
    let encoded = encode(EncodeFormat::Hex, b"Luna2D rocks!");
    assert_golden_text("hex_encode.txt", &encoded);
}

#[test]
fn golden_base64_roundtrip() {
    let original = b"The quick brown fox jumps over the lazy dog";
    let encoded = encode(EncodeFormat::Base64, original);
    let decoded = decode(EncodeFormat::Base64, &encoded).unwrap();
    assert_eq!(decoded, original);
}

// ===========================================================================
// Compression roundtrip stability
// ===========================================================================

#[test]
fn golden_compress_deflate_roundtrip() {
    let original = b"Luna2D compression test vector. Repeated pattern: ABCABCABC.";
    let compressed = compress(original, CompressFormat::Deflate, 6).unwrap();
    let decompressed = decompress(&compressed, CompressFormat::Deflate).unwrap();
    assert_eq!(&decompressed[..], &original[..]);
    assert_golden("deflate_compressed.bin", &compressed);
}

#[test]
fn golden_compress_gzip_roundtrip() {
    let original = b"Luna2D gzip test vector. Repeated: XYZXYZXYZ.";
    let compressed = compress(original, CompressFormat::Gzip, 6).unwrap();
    let decompressed = decompress(&compressed, CompressFormat::Gzip).unwrap();
    assert_eq!(&decompressed[..], &original[..]);
    // Note: gzip includes timestamps, so we only verify roundtrip, not golden bytes
}

#[test]
fn golden_compress_zlib_roundtrip() {
    let original = b"Luna2D zlib test vector. Repeated: 123123123.";
    let compressed = compress(original, CompressFormat::Zlib, 6).unwrap();
    let decompressed = decompress(&compressed, CompressFormat::Zlib).unwrap();
    assert_eq!(&decompressed[..], &original[..]);
    assert_golden("zlib_compressed.bin", &compressed);
}

#[test]
fn golden_compress_lz4_roundtrip() {
    let original = b"Luna2D lz4 test vector. Repeated: QWERTY QWERTY QWERTY.";
    let compressed = compress(original, CompressFormat::Lz4, 6).unwrap();
    let decompressed = decompress(&compressed, CompressFormat::Lz4).unwrap();
    assert_eq!(&decompressed[..], &original[..]);
    assert_golden("lz4_compressed.bin", &compressed);
}

// ===========================================================================
// TOML roundtrip
// ===========================================================================

#[test]
fn golden_toml_roundtrip() {
    let input = r#"
[game]
title = "Test Game"
version = "1.0.0"

[window]
width = 800
height = 600
fullscreen = false

[physics]
gravity_x = 0.0
gravity_y = 9.8
max_bodies = 1000
"#;
    let parsed = parse_toml(input).unwrap();
    let encoded = encode_toml(&parsed).unwrap();
    // Re-parse and verify same structure
    let reparsed = parse_toml(&encoded).unwrap();
    assert_eq!(parsed, reparsed, "TOML roundtrip must preserve structure");
    assert_golden_text("toml_roundtrip.toml", &encoded);
}

#[test]
fn golden_toml_complex_types() {
    let input = r#"
[player]
name = "Hero"
health = 100
position = [10.5, 20.3]
inventory = ["sword", "shield", "potion"]

[enemies]
count = 42
types = ["goblin", "dragon", "skeleton"]
"#;
    let parsed = parse_toml(input).unwrap();
    let encoded = encode_toml(&parsed).unwrap();
    let reparsed = parse_toml(&encoded).unwrap();
    assert_eq!(parsed, reparsed);
}
