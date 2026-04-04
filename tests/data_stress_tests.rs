//! Stress tests for the data module — compression, hashing, encoding at scale.

use luna2d::data::compress::{compress, decompress, CompressFormat};
use luna2d::data::encode::{decode, encode, EncodeFormat};
use luna2d::data::hash::{hash, HashAlgorithm};
use luna2d::data::toml_convert::{encode_toml, parse_toml};

#[test]
fn stress_compress_all_formats_roundtrip() {
    let original: Vec<u8> = (0..100_000).map(|i| (i % 256) as u8).collect();
    let formats = [
        CompressFormat::Deflate,
        CompressFormat::Gzip,
        CompressFormat::Zlib,
        CompressFormat::Lz4,
    ];
    for fmt in &formats {
        let compressed = compress(&original, *fmt, 6).unwrap();
        let decompressed = decompress(&compressed, *fmt).unwrap();
        assert_eq!(decompressed, original, "roundtrip failed for {:?}", fmt);
    }
}

#[test]
fn stress_compress_all_levels() {
    let original: Vec<u8> = (0..50_000).map(|i| ((i * 7 + 13) % 256) as u8).collect();
    for level in 1..=9 {
        let compressed = compress(&original, CompressFormat::Deflate, level).unwrap();
        let decompressed = decompress(&compressed, CompressFormat::Deflate).unwrap();
        assert_eq!(decompressed, original, "level {} roundtrip failed", level);
    }
}

#[test]
fn stress_hash_large_data() {
    let data: Vec<u8> = (0..500_000).map(|i| (i % 256) as u8).collect();
    let algos = [
        HashAlgorithm::Md5,
        HashAlgorithm::Sha1,
        HashAlgorithm::Sha256,
        HashAlgorithm::Sha512,
    ];
    for algo in &algos {
        let digest = hash(*algo, &data);
        assert!(!digest.is_empty(), "{:?} should produce non-empty digest", algo);
    }
}

#[test]
fn stress_hash_determinism() {
    let data = b"Determinism test vector for stress testing";
    let first = hash(HashAlgorithm::Sha256, data);
    for _ in 0..1000 {
        let digest = hash(HashAlgorithm::Sha256, data);
        assert_eq!(digest, first, "SHA-256 must be deterministic");
    }
}

#[test]
fn stress_base64_large() {
    let data: Vec<u8> = (0..100_000).map(|i| (i % 256) as u8).collect();
    let encoded = encode(EncodeFormat::Base64, &data);
    let decoded = decode(EncodeFormat::Base64, &encoded).unwrap();
    assert_eq!(decoded, data, "base64 roundtrip must preserve data");
}

#[test]
fn stress_hex_large() {
    let data: Vec<u8> = (0..50_000).map(|i| (i % 256) as u8).collect();
    let encoded = encode(EncodeFormat::Hex, &data);
    assert_eq!(encoded.len(), data.len() * 2, "hex doubles length");
    let decoded = decode(EncodeFormat::Hex, &encoded).unwrap();
    assert_eq!(decoded, data, "hex roundtrip must preserve data");
}

#[test]
fn stress_toml_parse_valid() {
    let mut toml_str = String::new();
    for i in 0..500 {
        toml_str.push_str(&format!("[section_{}]\nkey = {}\nname = \"value_{}\"\n\n", i, i, i));
    }
    let parsed = parse_toml(&toml_str).unwrap();
    let encoded = encode_toml(&parsed).unwrap();
    let reparsed = parse_toml(&encoded).unwrap();
    assert_eq!(parsed, reparsed, "TOML roundtrip with 500 sections");
}

#[test]
fn stress_toml_parse_invalid_does_not_panic() {
    let long_key = "k".repeat(100_000);
    let invalid_inputs = vec![
        "",
        "key = ",
        "[unclosed",
        "key = 12.34.56",
        "dup = 1\ndup = 2",
        "\x00\x01\x02",
        &long_key,
    ];
    for input in invalid_inputs {
        // Should either parse or return error; must not panic
        let _ = parse_toml(input);
    }
}
