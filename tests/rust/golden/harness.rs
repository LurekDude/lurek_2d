//! Golden file tests — verify deterministic binary output.
//!
//! Creates known inputs, generates outputs, and compares against stored baselines
//! in `tests/rust/golden/expected/`. On first run, baselines are generated automatically.
//! Subsequent runs verify the output matches byte-for-byte.
//!
//! ## Screenshot tests
//!
//! [`save_test_screenshot`] captures CPU-rendered `ImageData` as PNG files to
//! `tests/rust/golden/screenshots/`. Screenshots are committed to the repository
//! as visual evidence of what the engine's pixel-level rendering produces.
//! They are not compared automatically — regenerate by re-running the tests.

use luna2d::data::compress::{compress, decompress, CompressFormat};
use luna2d::data::encode::{decode, encode, EncodeFormat};
use luna2d::data::hash::{hash, HashAlgorithm};
use luna2d::data::toml_convert::{encode_toml, parse_toml};
use luna2d::fx::post::PostFxStack;
use luna2d::fx::screen::atmosphere::{CloudState, FogState, HeatHazeState, VignetteState};
use luna2d::fx::screen::{FadeState, FlashState, ShakeState, WeatherState};
use luna2d::image::ImageData;
use luna2d::raycaster::Raycaster2D;
use std::fs;
use std::path::Path;

/// Saves an `ImageData` as a PNG screenshot to `tests/rust/golden/screenshots/`.
///
/// Screenshots are tracked in the repository as visual evidence of what the
/// engine produces. Use this helper in tests that exercise pixel-level
/// rendering logic (`ImageData`, colour fills, gradients, etc.).
///
/// The file is saved to `tests/rust/golden/screenshots/{name}.png`.
/// Any directory components in `name` are created automatically.
fn save_test_screenshot(name: &str, img: &ImageData) {
    let path = format!("tests/rust/golden/screenshots/{}.png", name);
    let dir = std::path::Path::new(&path).parent().unwrap();
    fs::create_dir_all(dir).expect("failed to create screenshot directory");
    let png = img.encode_png().expect("failed to encode screenshot PNG");
    fs::write(&path, &png).expect("failed to write screenshot file");
    println!("Screenshot saved: {}", path);
}

fn assert_golden(name: &str, actual: &[u8]) {
    let expected_path = format!("tests/rust/golden/expected/{}", name);
    let actual_path = format!("tests/rust/golden/actual/{}", name);

    // Always write the actual output for inspection
    fs::create_dir_all(Path::new(&actual_path).parent().unwrap()).unwrap();
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
        fs::create_dir_all(Path::new(&expected_path).parent().unwrap()).unwrap();
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
    assert_golden("image/solid_red_4x4.png", &png);
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
    assert_golden("image/gradient_8x8.png", &png);
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
    assert_golden("image/checkerboard_16x16.png", &png);
}

// ===========================================================================
// Hash stability
// ===========================================================================

#[test]
fn golden_hash_sha256_known_digest() {
    // SHA-256 of "Hello, Luna2D!" is deterministic
    let digest = hash(HashAlgorithm::Sha256, b"Hello, Luna2D!");
    assert_golden_text("hash/sha256_hello.txt", &digest);
    // Cross-check with known value
    assert_eq!(digest.len(), 64, "SHA-256 hex digest must be 64 chars");
}

#[test]
fn golden_hash_md5_known_digest() {
    let digest = hash(HashAlgorithm::Md5, b"Hello, Luna2D!");
    assert_golden_text("hash/md5_hello.txt", &digest);
    assert_eq!(digest.len(), 32, "MD5 hex digest must be 32 chars");
}

#[test]
fn golden_hash_sha512_known_digest() {
    let digest = hash(HashAlgorithm::Sha512, b"Luna2D engine test vector");
    assert_golden_text("hash/sha512_engine.txt", &digest);
    assert_eq!(digest.len(), 128, "SHA-512 hex digest must be 128 chars");
}

#[test]
fn golden_hash_sha1_known_digest() {
    let digest = hash(HashAlgorithm::Sha1, b"Luna2D engine test vector");
    assert_golden_text("hash/sha1_engine.txt", &digest);
    assert_eq!(digest.len(), 40, "SHA-1 hex digest must be 40 chars");
}

// ===========================================================================
// Encoding stability
// ===========================================================================

#[test]
fn golden_base64_encode() {
    let encoded = encode(EncodeFormat::Base64, b"Luna2D rocks!");
    assert_golden_text("encode/base64_encode.txt", &encoded);
}

#[test]
fn golden_hex_encode() {
    let encoded = encode(EncodeFormat::Hex, b"Luna2D rocks!");
    assert_golden_text("encode/hex_encode.txt", &encoded);
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
    assert_golden("compress/deflate_compressed.bin", &compressed);
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
    assert_golden("compress/zlib_compressed.bin", &compressed);
}

#[test]
fn golden_compress_lz4_roundtrip() {
    let original = b"Luna2D lz4 test vector. Repeated: QWERTY QWERTY QWERTY.";
    let compressed = compress(original, CompressFormat::Lz4, 6).unwrap();
    let decompressed = decompress(&compressed, CompressFormat::Lz4).unwrap();
    assert_eq!(&decompressed[..], &original[..]);
    assert_golden("compress/lz4_compressed.bin", &compressed);
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
    assert_golden_text("data/toml_roundtrip.toml", &encoded);
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

// ===========================================================================
// FX screen state defaults
// ===========================================================================

#[test]
fn golden_fx_flash_state_default() {
    let state = FlashState::default();
    assert_golden_text("fx/flash_state_default.txt", &format!("{:?}", state));
}

#[test]
fn golden_fx_shake_state_default() {
    let state = ShakeState::default();
    assert_golden_text("fx/shake_state_default.txt", &format!("{:?}", state));
}

#[test]
fn golden_fx_fade_state_default() {
    let state = FadeState::default();
    assert_golden_text("fx/fade_state_default.txt", &format!("{:?}", state));
}

#[test]
fn golden_fx_weather_state_default() {
    let state = WeatherState::default();
    let text = format!(
        "weather_type={:?} intensity={} particle_count={} wind_direction={} wind_speed={}",
        state.weather_type,
        state.intensity,
        state.particles.len(),
        state.wind_direction,
        state.wind_speed
    );
    assert_golden_text("fx/weather_state_default.txt", &text);
}

#[test]
fn golden_fx_cloud_state_default() {
    let state = CloudState::default();
    assert_golden_text("fx/cloud_state_default.txt", &format!("{:?}", state));
}

#[test]
fn golden_fx_fog_state_default() {
    let state = FogState::default();
    assert_golden_text("fx/fog_state_default.txt", &format!("{:?}", state));
}

#[test]
fn golden_fx_heat_haze_state_default() {
    let state = HeatHazeState::default();
    assert_golden_text("fx/heat_haze_state_default.txt", &format!("{:?}", state));
}

#[test]
fn golden_fx_vignette_state_default() {
    let state = VignetteState::default();
    assert_golden_text("fx/vignette_state_default.txt", &format!("{:?}", state));
}

#[test]
fn golden_fx_postfx_stack_empty() {
    let stack = PostFxStack::new(320, 240);
    let text = format!(
        "effects={} enabled={} width={} height={} capturing={}",
        stack.effects.len(),
        stack.enabled.len(),
        stack.width,
        stack.height,
        stack.capturing
    );
    assert_golden_text("fx/postfx_stack_empty.txt", &text);
}

// ===========================================================================
// Raycaster: deterministic ray cast results
// ===========================================================================

/// Build a 5×5 grid with a wall ring and an open center.
///
/// Layout (W=wall, .=empty):
///   W W W W W
///   W . . . W
///   W . . . W
///   W . . . W
///   W W W W W
fn make_enclosed_5x5() -> Raycaster2D {
    let mut rc = Raycaster2D::new(5, 5);
    for x in 0..5 {
        rc.set_cell(x, 0, 1);
        rc.set_cell(x, 4, 1);
    }
    for y in 0..5 {
        rc.set_cell(0, y, 1);
        rc.set_cell(4, y, 1);
    }
    rc
}

#[test]
fn golden_raycaster_ray_hits_east_wall() {
    let rc = make_enclosed_5x5();
    // Origin: centre of inner area (2.5, 2.5), angle 0 = East (+x direction)
    let hit = rc
        .cast_ray(2.5, 2.5, 0.0, 20.0)
        .expect("ray must hit east wall");
    let text = format!(
        "hit={} cell_value={} side={} distance={:.4} tex_u={:.4} hit_x={:.4} hit_y={:.4}",
        hit.hit, hit.cell_value, hit.side, hit.distance, hit.tex_u, hit.hit_x, hit.hit_y
    );
    assert_golden_text("raycaster/ray_east_wall.txt", &text);
}

#[test]
fn golden_raycaster_ray_hits_north_wall() {
    let rc = make_enclosed_5x5();
    // Angle PI*1.5 points North (-y direction) in standard grid
    let angle = -std::f32::consts::FRAC_PI_2;
    let hit = rc
        .cast_ray(2.5, 2.5, angle, 20.0)
        .expect("ray must hit north wall");
    let text = format!(
        "hit={} cell_value={} side={} distance={:.4} tex_u={:.4} hit_x={:.4} hit_y={:.4}",
        hit.hit, hit.cell_value, hit.side, hit.distance, hit.tex_u, hit.hit_x, hit.hit_y
    );
    assert_golden_text("raycaster/ray_north_wall.txt", &text);
}

#[test]
fn golden_raycaster_ray_miss_no_wall() {
    // Empty 3×3 grid — ray must return None
    let rc = Raycaster2D::new(3, 3);
    let hit = rc.cast_ray(1.5, 1.5, 0.0, 0.5);
    assert!(hit.is_none(), "ray in empty grid must miss");
    assert_golden_text("raycaster/ray_empty_miss.txt", "hit=false");
}

#[test]
fn golden_raycaster_multi_ray_column_distances() {
    let rc = make_enclosed_5x5();
    // Cast 5 rays from centre pointing East with slight spread (-2° to +2°)
    let base_angle = 0.0_f32;
    let fov_step = std::f32::consts::PI / 180.0 * 1.0; // 1 degree per step
    let mut rows = Vec::new();
    for i in 0..5 {
        let angle = base_angle + (i as f32 - 2.0) * fov_step;
        let dist = rc
            .cast_ray(2.5, 2.5, angle, 20.0)
            .map(|h| format!("{:.4}", h.distance))
            .unwrap_or_else(|| "miss".to_string());
        rows.push(dist);
    }
    let text = rows.join("\n");
    assert_golden_text("raycaster/multi_ray_east_5col.txt", &text);
}

// ===========================================================================
// Screenshots — visual evidence of CPU-side rendering output
// ===========================================================================

#[test]
fn screenshot_solid_color_fill() {
    let mut img = ImageData::new(64, 64);
    for y in 0..64 {
        for x in 0..64 {
            img.set_pixel(x, y, 80, 160, 220, 255); // sky blue
        }
    }
    save_test_screenshot("solid_color_fill", &img);
    // Verify corner pixel is set correctly
    let (r, g, b, a) = img.get_pixel(0, 0).unwrap();
    assert_eq!((r, g, b, a), (80, 160, 220, 255));
}

#[test]
fn screenshot_procedural_gradient() {
    let mut img = ImageData::new(128, 128);
    for y in 0..128 {
        for x in 0..128 {
            let r = ((x as f32 / 127.0) * 255.0) as u8;
            let g = ((y as f32 / 127.0) * 255.0) as u8;
            let b = 128u8;
            img.set_pixel(x, y, r, g, b, 255);
        }
    }
    save_test_screenshot("gradient_rgb", &img);
    // Verify top-left is (0, 0, 128) and bottom-right is (255, 255, 128)
    let tl = img.get_pixel(0, 0).unwrap();
    assert_eq!((tl.0, tl.1, tl.2), (0, 0, 128));
    let br = img.get_pixel(127, 127).unwrap();
    assert_eq!((br.0, br.1, br.2), (255, 255, 128));
}

#[test]
fn screenshot_raycaster_depth_map() {
    // Render a 60-column depth map of the 5×5 enclosed grid as a grayscale strip.
    // Each column's brightness encodes wall distance (closer = brighter).
    let rc = make_enclosed_5x5();
    let columns = 60u32;
    let height = 40u32;
    let fov = std::f32::consts::FRAC_PI_2; // 90 degrees
    let mut img = ImageData::new(columns, height);

    for col in 0..columns {
        let angle = -fov / 2.0 + (col as f32 / (columns - 1) as f32) * fov;
        let max_dist = 10.0_f32;
        let dist = rc
            .cast_ray(2.5, 2.5, angle, max_dist)
            .map(|h| h.distance)
            .unwrap_or(max_dist);

        // Wall height proportional to inverse distance, clamped to image height
        let wall_h = ((1.0 / dist.max(0.1)) * height as f32).min(height as f32) as u32;
        let brightness = (255.0 * (1.0 - dist / max_dist)).clamp(0.0, 255.0) as u8;

        let wall_start = height.saturating_sub(wall_h) / 2;
        let wall_end = (wall_start + wall_h).min(height);

        for row in 0..height {
            let (r, g, b) = if row >= wall_start && row < wall_end {
                (brightness, brightness, brightness) // wall
            } else if row < wall_start {
                (20, 20, 40) // ceiling (dark blue-grey)
            } else {
                (40, 30, 20) // floor (dark brown)
            };
            img.set_pixel(col, row, r, g, b, 255);
        }
    }
    save_test_screenshot("raycaster_depth_map", &img);
    // Verify image dimensions
    assert_eq!(img.width(), columns);
    assert_eq!(img.height(), height);
}
