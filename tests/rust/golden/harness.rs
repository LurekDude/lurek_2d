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

use lurek2d::image::ImageData;
use lurek2d::raycaster::Raycaster2D;
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
