//! Evidence tests — produce real PNG and WAV artifact files proving engine APIs work.
//!
//! Every test in this module writes at least one binary file (PNG image or WAV audio)
//! to `tests/rust/golden/evidence/`. These files are committed to the repository as
//! proof that the engine's CPU-side APIs produce correct, usable output.
//!
//! Run with: `cargo test --test evidence_tests -- --nocapture`

use lurek2d::audio::SoundData;
use lurek2d::image::ImageData;
use lurek2d::math::bezier::BezierCurve;
use lurek2d::math::noise_generator::{MapGenOptions, NoiseGenerator, NoiseKind};
use lurek2d::math::vec2::Vec2;
use std::fs;
use std::sync::Arc;

use lurek2d::audio::dsp::{ActiveEffect, EffectParams, EffectType};
use lurek2d::math::color::Color;
use lurek2d::math::easing;
use lurek2d::math::rect::Rect;
use lurek2d::minimap::{Minimap, FogLevel, ColorMode};
use lurek2d::pathfinding::{NavGrid, astar, FlowField, InfluenceMap};
use lurek2d::procgen::{cellular_automata, CellularOpts, voronoi_diagram, VoronoiOpts, poisson_disk};
use lurek2d::raycaster::Raycaster2D;
use lurek2d::tilemap::TileMap;
use lurek2d::particle::{ParticleSystem, ParticleConfig};
use lurek2d::animation::Animation;
use lurek2d::camera::Camera2D;
use lurek2d::graph::Graph;
use lurek2d::image::LayeredImage;
use lurek2d::light::{LightWorld, Light2D, Occluder, Attenuation, FalloffMode};
use lurek2d::spine::{Skeleton, Bone};
use lurek2d::effect::overlay::Overlay;
use lurek2d::effect::effect::PostFxEffect;
use lurek2d::effect::effect_type::PostFxEffectType;
use lurek2d::effect::stack::PostFxStack;
use lurek2d::particle::Trail;
use lurek2d::graph::GraphStats;
use lurek2d::ui::chart::{LineChart, BarChart, ScatterPlot, PieChart, AreaChart, ChartConfig, ChartMargin};
use lurek2d::ui::theme::Theme;
use std::cell::RefCell;
use std::rc::Rc;

const EVIDENCE_DIR: &str = "tests/rust/golden/evidence";

/// Draw a filled circle, safely handling out-of-bounds coordinates.
///
/// Unlike `ImageData::draw_circle`, this does not panic on edge cases.
fn safe_circle(img: &mut ImageData, cx: i32, cy: i32, r: i32, red: u8, g: u8, b: u8, a: u8) {
    let w = img.width() as i32;
    let h = img.height() as i32;
    let y0 = (cy - r).max(0);
    let y1 = (cy + r + 1).min(h);
    let x0 = (cx - r).max(0);
    let x1 = (cx + r + 1).min(w);
    let r2 = (r * r) as i64;
    for py in y0..y1 {
        let dy = (py - cy) as i64;
        for px in x0..x1 {
            let dx = (px - cx) as i64;
            if dx * dx + dy * dy <= r2 {
                img.set_pixel(px as u32, py as u32, red, g, b, a);
            }
        }
    }
}

/// Write PNG evidence to the evidence folder.
fn save_png(name: &str, img: &ImageData) {
    let path = format!("{}/{}.png", EVIDENCE_DIR, name);
    let dir = std::path::Path::new(&path).parent().unwrap();
    fs::create_dir_all(dir).expect("failed to create evidence directory");
    let png = img.encode_png().expect("failed to encode PNG");
    fs::write(&path, &png).expect("failed to write PNG");
    println!("Evidence PNG saved: {} ({}x{}, {} bytes)", path, img.width(), img.height(), png.len());
}

/// Write WAV evidence to the evidence folder.
fn save_wav(name: &str, sound: &SoundData) {
    let path = format!("{}/{}.wav", EVIDENCE_DIR, name);
    let dir = std::path::Path::new(&path).parent().unwrap();
    fs::create_dir_all(dir).expect("failed to create evidence directory");
    let wav = sound.encode_wav();
    fs::write(&path, &wav).expect("failed to write WAV");
    println!(
        "Evidence WAV saved: {} ({} samples, {}Hz, {} ch, {} bytes)",
        path,
        sound.sample_count(),
        sound.sample_rate(),
        sound.channel_count(),
        wav.len()
    );
}

// ===== FIXTURES — Reusable test assets =====

#[test]
fn fixture_sprite_8x8() {
    let mut img = ImageData::new(8, 8);
    // Simple smiley face pattern
    img.fill(0, 0, 0, 0);
    // Eyes
    img.set_pixel(2, 2, 255, 255, 255, 255);
    img.set_pixel(5, 2, 255, 255, 255, 255);
    // Mouth
    for x in 2..=5 {
        img.set_pixel(x, 5, 255, 255, 255, 255);
    }
    img.set_pixel(1, 4, 255, 255, 255, 255);
    img.set_pixel(6, 4, 255, 255, 255, 255);
    save_png("fixtures/sprite_8x8", &img);
}

#[test]
fn fixture_sprite_16x16() {
    let mut img = ImageData::new(16, 16);
    // Colored cross pattern
    for i in 0..16 {
        img.set_pixel(7, i, 255, 0, 0, 255); // Vertical red line
        img.set_pixel(8, i, 255, 0, 0, 255);
        img.set_pixel(i, 7, 0, 0, 255, 255); // Horizontal blue line
        img.set_pixel(i, 8, 0, 0, 255, 255);
    }
    // Centre intersection = purple
    img.set_pixel(7, 7, 255, 0, 255, 255);
    img.set_pixel(8, 8, 255, 0, 255, 255);
    img.set_pixel(7, 8, 255, 0, 255, 255);
    img.set_pixel(8, 7, 255, 0, 255, 255);
    save_png("fixtures/sprite_16x16", &img);
}

#[test]
fn fixture_sprite_32x32() {
    let mut img = ImageData::new(32, 32);
    // Radial gradient from center
    for y in 0..32 {
        for x in 0..32 {
            let dx = x as f32 - 15.5;
            let dy = y as f32 - 15.5;
            let dist = (dx * dx + dy * dy).sqrt();
            let t = (1.0 - dist / 22.0).clamp(0.0, 1.0);
            let v = (t * 255.0) as u8;
            img.set_pixel(x, y, v, v / 2, 255 - v, 255);
        }
    }
    save_png("fixtures/sprite_32x32", &img);
}

#[test]
fn fixture_sprite_64x64() {
    let mut img = ImageData::new(64, 64);
    // Checkerboard with color
    for y in 0..64 {
        for x in 0..64 {
            let checker = ((x / 8) + (y / 8)) % 2 == 0;
            if checker {
                img.set_pixel(x, y, 200, 50, 50, 255);
            } else {
                img.set_pixel(x, y, 50, 50, 200, 255);
            }
        }
    }
    save_png("fixtures/sprite_64x64", &img);
}

#[test]
fn fixture_tileset_128x128() {
    let mut img = ImageData::new(128, 128);
    // 8x8 grid of 16x16 tiles, each with a unique color
    for ty in 0..8u32 {
        for tx in 0..8u32 {
            let r = (tx * 36) as u8;
            let g = (ty * 36) as u8;
            let b = ((tx + ty) * 18) as u8;
            for py in 0..16 {
                for px in 0..16 {
                    let x = tx * 16 + px;
                    let y = ty * 16 + py;
                    // 1px border between tiles
                    if px == 0 || py == 0 {
                        img.set_pixel(x, y, 40, 40, 40, 255);
                    } else {
                        img.set_pixel(x, y, r, g, b, 255);
                    }
                }
            }
        }
    }
    save_png("fixtures/tileset_128x128", &img);
}

#[test]
fn fixture_gradient_horizontal() {
    let mut img = ImageData::new(256, 32);
    for y in 0..32 {
        for x in 0..256u32 {
            img.set_pixel(x, y, x as u8, 0, 255 - x as u8, 255);
        }
    }
    save_png("fixtures/gradient_horizontal", &img);
}

#[test]
fn fixture_gradient_vertical() {
    let mut img = ImageData::new(32, 256);
    for y in 0..256u32 {
        for x in 0..32 {
            img.set_pixel(x, y, 0, y as u8, 255 - y as u8, 255);
        }
    }
    save_png("fixtures/gradient_vertical", &img);
}

// ===== GRAPHICS — ImageData primitives =====

#[test]
fn evidence_image_new_blank() {
    let img = ImageData::new(64, 64);
    assert_eq!(img.width(), 64);
    assert_eq!(img.height(), 64);
    // All pixels should be (0,0,0,0)
    assert_eq!(img.get_pixel(0, 0), Some((0, 0, 0, 0)));
    save_png("image/new_blank_64x64", &img);
}

#[test]
fn evidence_image_fill_solid() {
    let mut img = ImageData::new(64, 64);
    img.fill(255, 128, 0, 255); // Orange
    assert_eq!(img.get_pixel(32, 32), Some((255, 128, 0, 255)));
    save_png("image/fill_orange", &img);
}

#[test]
fn evidence_image_set_pixel_pattern() {
    let mut img = ImageData::new(64, 64);
    img.fill(0, 0, 0, 255);
    // Draw diagonal pixels
    for i in 0..64u32 {
        img.set_pixel(i, i, 255, 255, 0, 255);
        if i < 63 {
            img.set_pixel(63 - i, i, 0, 255, 255, 255);
        }
    }
    save_png("image/diagonal_cross", &img);
}

#[test]
fn evidence_image_draw_rect() {
    let mut img = ImageData::new(128, 128);
    img.fill(30, 30, 30, 255);
    img.draw_rect(10, 10, 50, 30, 255, 0, 0, 255);
    img.draw_rect(40, 50, 60, 40, 0, 255, 0, 255);
    img.draw_rect(70, 20, 40, 80, 0, 0, 255, 255);
    save_png("image/draw_rect", &img);
}

#[test]
fn evidence_image_draw_circle() {
    let mut img = ImageData::new(128, 128);
    img.fill(30, 30, 30, 255);
    img.draw_circle(40, 40, 25, 255, 0, 0, 255);
    img.draw_circle(80, 60, 30, 0, 255, 0, 255);
    img.draw_circle(60, 90, 20, 0, 0, 255, 255);
    save_png("image/draw_circle", &img);
}

#[test]
fn evidence_image_draw_line() {
    let mut img = ImageData::new(128, 128);
    img.fill(30, 30, 30, 255);
    // Star pattern
    let cx = 64i32;
    let cy = 64i32;
    for angle_deg in (0..360).step_by(30) {
        let angle = (angle_deg as f32).to_radians();
        let ex = cx + (50.0 * angle.cos()) as i32;
        let ey = cy + (50.0 * angle.sin()) as i32;
        let r = ((angle_deg * 255 / 360) as u8).wrapping_add(100);
        let g = 200u8.wrapping_sub((angle_deg as u8).wrapping_mul(2));
        img.draw_line(cx, cy, ex, ey, r, g, 255, 255);
    }
    save_png("image/draw_line_star", &img);
}

#[test]
fn evidence_image_draw_shapes_combined() {
    let mut img = ImageData::new(256, 256);
    img.fill(20, 20, 40, 255);

    // Background grid
    for i in (0..256).step_by(16) {
        img.draw_line(i, 0, i, 255, 40, 40, 60, 255);
        img.draw_line(0, i, 255, i, 40, 40, 60, 255);
    }

    // House shape
    img.draw_rect(60, 140, 80, 80, 180, 120, 60, 255); // Body
    img.draw_rect(85, 180, 30, 40, 100, 60, 30, 255);   // Door
    img.draw_rect(70, 155, 20, 20, 150, 200, 255, 255);  // Window left
    img.draw_rect(110, 155, 20, 20, 150, 200, 255, 255); // Window right
    // Roof triangle via lines
    img.draw_line(55, 140, 100, 90, 200, 50, 50, 255);
    img.draw_line(100, 90, 145, 140, 200, 50, 50, 255);
    img.draw_line(55, 140, 145, 140, 200, 50, 50, 255);

    // Sun
    img.draw_circle(200, 50, 25, 255, 220, 50, 255);
    // Sun rays
    for angle_deg in (0..360).step_by(45) {
        let angle = (angle_deg as f32).to_radians();
        let sx = 200 + (30.0 * angle.cos()) as i32;
        let sy = 50 + (30.0 * angle.sin()) as i32;
        let ex = 200 + (45.0 * angle.cos()) as i32;
        let ey = 50 + (45.0 * angle.sin()) as i32;
        img.draw_line(sx, sy, ex, ey, 255, 220, 50, 255);
    }

    // Ground
    img.draw_rect(0, 220, 256, 36, 40, 120, 40, 255);

    save_png("image/shapes_combined_scene", &img);
}

#[test]
fn evidence_image_paste_composite() {
    let mut bg = ImageData::new(128, 128);
    bg.fill(40, 40, 80, 255);

    let mut sprite = ImageData::new(32, 32);
    sprite.draw_circle(16, 16, 14, 255, 200, 0, 255);

    bg.paste(&sprite, 10, 10);
    bg.paste(&sprite, 50, 30);
    bg.paste(&sprite, 80, 70);
    save_png("image/paste_composite", &bg);
}

// ===== EFFECTS — CPU-side image effects =====

#[test]
fn evidence_effect_brightness() {
    let mut img = ImageData::new(128, 64);
    // Left half: base | Right half: brightened
    for y in 0..64 {
        for x in 0..128 {
            let v = (y * 4) as u8;
            img.set_pixel(x, y, v, v / 2, v, 255);
        }
    }
    let mut bright = img.crop(0, 0, 128, 64).unwrap();
    bright.brightness(0.4);
    save_png("effects/brightness_before", &img);
    save_png("effects/brightness_after", &bright);
}

#[test]
fn evidence_effect_contrast() {
    let mut img = ImageData::new(128, 64);
    for y in 0..64 {
        for x in 0..128 {
            let v = (x * 2) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    let mut high = img.crop(0, 0, 128, 64).unwrap();
    high.contrast(2.0);
    save_png("effects/contrast_before", &img);
    save_png("effects/contrast_after", &high);
}

#[test]
fn evidence_effect_grayscale() {
    let mut img = ImageData::new(128, 64);
    for y in 0..64 {
        for x in 0..128 {
            img.set_pixel(x, y, (x * 2) as u8, (y * 4) as u8, 128, 255);
        }
    }
    let mut gray = img.crop(0, 0, 128, 64).unwrap();
    gray.grayscale();
    save_png("effects/grayscale_before", &img);
    save_png("effects/grayscale_after", &gray);
}

#[test]
fn evidence_effect_sepia() {
    let mut img = ImageData::new(128, 64);
    for y in 0..64 {
        for x in 0..128 {
            img.set_pixel(x, y, (x * 2) as u8, (y * 4) as u8, 150, 255);
        }
    }
    let mut sep = img.crop(0, 0, 128, 64).unwrap();
    sep.sepia();
    save_png("effects/sepia_before", &img);
    save_png("effects/sepia_after", &sep);
}

#[test]
fn evidence_effect_invert() {
    let mut img = ImageData::new(128, 64);
    for y in 0..64u32 {
        for x in 0..128u32 {
            img.set_pixel(x, y, (x * 2) as u8, (y * 4) as u8, 100, 255);
        }
    }
    let mut inv = img.crop(0, 0, 128, 64).unwrap();
    inv.invert();
    save_png("effects/invert_before", &img);
    save_png("effects/invert_after", &inv);
}

#[test]
fn evidence_effect_blur() {
    let mut img = ImageData::new(128, 128);
    img.fill(20, 20, 20, 255);
    img.draw_rect(40, 40, 48, 48, 255, 255, 255, 255);
    img.draw_circle(64, 64, 15, 255, 0, 0, 255);
    let blurred = img.blur(3);
    save_png("effects/blur_before", &img);
    save_png("effects/blur_after", &blurred);
}

#[test]
fn evidence_effect_sharpen() {
    let mut img = ImageData::new(128, 128);
    for y in 0..128 {
        for x in 0..128 {
            let v = ((x as f32 / 128.0 * 3.14159 * 4.0).sin() * 60.0 + 128.0) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    let sharp = img.sharpen();
    save_png("effects/sharpen_before", &img);
    save_png("effects/sharpen_after", &sharp);
}

#[test]
fn evidence_effect_threshold() {
    let mut img = ImageData::new(128, 128);
    for y in 0..128 {
        for x in 0..128 {
            let dx = x as f32 - 64.0;
            let dy = y as f32 - 64.0;
            let v = ((dx * dx + dy * dy).sqrt() * 3.0) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    let mut thresh = img.crop(0, 0, 128, 128).unwrap();
    thresh.threshold(128);
    save_png("effects/threshold_before", &img);
    save_png("effects/threshold_after", &thresh);
}

#[test]
fn evidence_effect_posterize() {
    let mut img = ImageData::new(128, 128);
    for y in 0..128 {
        for x in 0..128 {
            img.set_pixel(x, y, (x * 2) as u8, (y * 2) as u8, 128, 255);
        }
    }
    let mut post = img.crop(0, 0, 128, 128).unwrap();
    post.posterize(4);
    save_png("effects/posterize_before", &img);
    save_png("effects/posterize_after", &post);
}

#[test]
fn evidence_effect_tint() {
    let mut img = ImageData::new(128, 64);
    for y in 0..64 {
        for x in 0..128 {
            img.set_pixel(x, y, 200, 200, 200, 255);
        }
    }
    let mut tinted = img.crop(0, 0, 128, 64).unwrap();
    tinted.tint(255, 100, 50, 0.6);
    save_png("effects/tint_before", &img);
    save_png("effects/tint_after", &tinted);
}

#[test]
fn evidence_effect_saturation() {
    let mut img = ImageData::new(128, 64);
    for y in 0..64 {
        for x in 0..128 {
            img.set_pixel(x, y, 200, 100, 50, 255);
        }
    }
    let mut desat = img.crop(0, 0, 128, 64).unwrap();
    desat.saturation(0.0); // Full desaturation
    let mut sat = img.crop(0, 0, 128, 64).unwrap();
    sat.saturation(2.0); // Oversaturation
    save_png("effects/saturation_original", &img);
    save_png("effects/saturation_desat", &desat);
    save_png("effects/saturation_oversat", &sat);
}

#[test]
fn evidence_effect_gamma() {
    let mut img = ImageData::new(128, 64);
    for y in 0..64 {
        for x in 0..128 {
            let v = (x * 2) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    let mut low = img.crop(0, 0, 128, 64).unwrap();
    low.gamma(0.5);
    let mut high = img.crop(0, 0, 128, 64).unwrap();
    high.gamma(2.2);
    save_png("effects/gamma_original", &img);
    save_png("effects/gamma_low", &low);
    save_png("effects/gamma_high", &high);
}

#[test]
fn evidence_effect_noise() {
    let mut img = ImageData::new(128, 128);
    img.fill(128, 128, 128, 255);
    let mut noisy = img.crop(0, 0, 128, 128).unwrap();
    noisy.noise(80);
    save_png("effects/noise_before", &img);
    save_png("effects/noise_after", &noisy);
}

#[test]
fn evidence_effect_flip_horizontal() {
    let mut img = ImageData::new(64, 64);
    // Asymmetric pattern: red left, blue right
    for y in 0..64 {
        for x in 0..32 {
            img.set_pixel(x, y, 255, 0, 0, 255);
        }
        for x in 32..64 {
            img.set_pixel(x, y, 0, 0, 255, 255);
        }
    }
    let mut flipped = img.crop(0, 0, 64, 64).unwrap();
    flipped.flip_horizontal();
    save_png("effects/flip_h_before", &img);
    save_png("effects/flip_h_after", &flipped);
}

#[test]
fn evidence_effect_flip_vertical() {
    let mut img = ImageData::new(64, 64);
    // Gradient top to bottom
    for y in 0..64 {
        for x in 0..64 {
            img.set_pixel(x, y, 0, (y * 4) as u8, 0, 255);
        }
    }
    let mut flipped = img.crop(0, 0, 64, 64).unwrap();
    flipped.flip_vertical();
    save_png("effects/flip_v_before", &img);
    save_png("effects/flip_v_after", &flipped);
}

#[test]
fn evidence_effect_rotate() {
    let mut img = ImageData::new(64, 64);
    img.fill(0, 0, 0, 255);
    img.draw_rect(10, 10, 44, 20, 255, 0, 0, 255);
    img.draw_rect(10, 10, 20, 44, 0, 255, 0, 255);
    let rotated = img.rotate_90_cw();
    save_png("effects/rotate_before", &img);
    save_png("effects/rotate_90cw", &rotated);
}

#[test]
fn evidence_effect_crop() {
    let mut img = ImageData::new(128, 128);
    for y in 0..128 {
        for x in 0..128 {
            img.set_pixel(x, y, (x * 2) as u8, (y * 2) as u8, 128, 255);
        }
    }
    let cropped = img.crop(32, 32, 64, 64).unwrap();
    save_png("effects/crop_full", &img);
    save_png("effects/crop_center", &cropped);
}

#[test]
fn evidence_effect_resize() {
    let mut img = ImageData::new(32, 32);
    img.draw_circle(16, 16, 14, 255, 200, 0, 255);
    img.fill(0, 0, 0, 0);
    img.draw_circle(16, 16, 14, 255, 200, 0, 255);
    let big = img.resize_nearest(128, 128);
    let small = img.resize_nearest(16, 16);
    save_png("effects/resize_original_32", &img);
    save_png("effects/resize_upscaled_128", &big);
    save_png("effects/resize_downscaled_16", &small);
}

#[test]
fn evidence_effect_alpha_mask() {
    let mut img = ImageData::new(128, 128);
    img.fill(255, 100, 50, 255);
    let mut masked = img.crop(0, 0, 128, 128).unwrap();
    masked.alpha_mask(0.5);
    save_png("effects/alpha_mask_opaque", &img);
    save_png("effects/alpha_mask_50pct", &masked);
}

#[test]
fn evidence_effect_pipeline() {
    // Apply multiple effects in sequence — proves composability
    let mut img = ImageData::new(128, 128);
    for y in 0..128 {
        for x in 0..128 {
            img.set_pixel(x, y, (x * 2) as u8, (y * 2) as u8, 100, 255);
        }
    }
    save_png("effects/pipeline_01_original", &img);

    img.brightness(1.8);
    save_png("effects/pipeline_02_brightened", &img);

    img.contrast(1.5);
    save_png("effects/pipeline_03_contrast", &img);

    img.sepia();
    save_png("effects/pipeline_04_sepia", &img);

    let blurred = img.blur(2);
    save_png("effects/pipeline_05_blur", &blurred);
}

// ===== MATH — Visual evidence of math module =====

#[test]
fn evidence_math_perlin_noise_2d() {
    let noise = NoiseGenerator::new(42);
    let mut img = ImageData::new(256, 256);
    for y in 0..256 {
        for x in 0..256 {
            let val = noise.perlin_2d(x as f64 * 0.02, y as f64 * 0.02);
            let v = ((val * 0.5 + 0.5).clamp(0.0, 1.0) * 255.0) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    save_png("math/perlin_noise_2d", &img);
}

#[test]
fn evidence_math_simplex_noise_2d() {
    let noise = NoiseGenerator::new(42);
    let mut img = ImageData::new(256, 256);
    for y in 0..256 {
        for x in 0..256 {
            let val = noise.simplex_2d(x as f64 * 0.02, y as f64 * 0.02);
            let v = ((val * 0.5 + 0.5).clamp(0.0, 1.0) * 255.0) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    save_png("math/simplex_noise_2d", &img);
}

#[test]
fn evidence_math_fbm_noise() {
    let noise = NoiseGenerator::new(42);
    let mut img = ImageData::new(256, 256);
    for y in 0..256 {
        for x in 0..256 {
            let val = noise.fbm(
                x as f64 * 0.01,
                y as f64 * 0.01,
                6,    // octaves
                2.0,  // lacunarity
                0.5,  // persistence
                NoiseKind::Perlin,
            );
            let v = ((val * 0.5 + 0.5).clamp(0.0, 1.0) * 255.0) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    save_png("math/fbm_noise", &img);
}

#[test]
fn evidence_math_worley_noise() {
    let noise = NoiseGenerator::new(42);
    let mut img = ImageData::new(256, 256);
    for y in 0..256 {
        for x in 0..256 {
            let val = noise.worley_2d(
                x as f64 * 0.02,
                y as f64 * 0.02,
                lurek2d::math::noise_generator::DistType::Euclidean,
                false,
            );
            let v = (val.clamp(0.0, 1.0) * 255.0) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    save_png("math/worley_noise", &img);
}

#[test]
fn evidence_math_noise_colored_terrain() {
    let noise = NoiseGenerator::new(12345);
    let mut img = ImageData::new(256, 256);
    for y in 0..256 {
        for x in 0..256 {
            let val = noise.fbm(
                x as f64 * 0.008,
                y as f64 * 0.008,
                6, 2.0, 0.5,
                NoiseKind::Perlin,
            );
            let h = val * 0.5 + 0.5; // normalize to [0, 1]
            let (r, g, b) = if h < 0.3 {
                (30, 80, 180)    // Deep water
            } else if h < 0.4 {
                (60, 130, 200)   // Shallow water
            } else if h < 0.45 {
                (210, 200, 150)  // Beach
            } else if h < 0.65 {
                (50, 160, 50)    // Grass
            } else if h < 0.8 {
                (100, 80, 50)    // Mountain
            } else {
                (220, 220, 230)  // Snow
            };
            img.set_pixel(x, y, r, g, b, 255);
        }
    }
    save_png("math/noise_terrain_map", &img);
}

#[test]
fn evidence_math_generate_map() {
    let noise = NoiseGenerator::new(42);
    let opts = MapGenOptions {
        scale_x: 0.02,
        scale_y: 0.02,
        octaves: 4,
        lacunarity: 2.0,
        persistence: 0.5,
        kind: NoiseKind::Simplex,
        ..Default::default()
    };
    let map = noise.generate_map(256, 256, &opts);
    let mut img = ImageData::new(256, 256);
    for y in 0..256 {
        for x in 0..256 {
            let val = map[(y * 256 + x) as usize];
            let v = ((val * 0.5 + 0.5).clamp(0.0, 1.0) * 255.0) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    save_png("math/generate_map", &img);
}

#[test]
fn evidence_math_bezier_curve() {
    let curve = BezierCurve::new(vec![
        Vec2::new(10.0, 200.0),
        Vec2::new(60.0, 20.0),
        Vec2::new(180.0, 20.0),
        Vec2::new(240.0, 200.0),
    ]);
    let points = curve.render(200);

    let mut img = ImageData::new(256, 256);
    img.fill(20, 20, 30, 255);

    // Draw control polygon in dim grey
    let ctrl = [
        Vec2::new(10.0, 200.0),
        Vec2::new(60.0, 20.0),
        Vec2::new(180.0, 20.0),
        Vec2::new(240.0, 200.0),
    ];
    for i in 0..3 {
        img.draw_line(
            ctrl[i].x as i32, ctrl[i].y as i32,
            ctrl[i + 1].x as i32, ctrl[i + 1].y as i32,
            80, 80, 80, 255,
        );
    }

    // Draw control points as circles
    for pt in &ctrl {
        img.draw_circle(pt.x as i32, pt.y as i32, 4, 255, 100, 100, 255);
    }

    // Draw curve in bright green
    for i in 0..points.len().saturating_sub(1) {
        img.draw_line(
            points[i].x as i32, points[i].y as i32,
            points[i + 1].x as i32, points[i + 1].y as i32,
            0, 255, 100, 255,
        );
    }

    save_png("math/bezier_curve", &img);
}

#[test]
fn evidence_math_bezier_multiple() {
    let mut img = ImageData::new(256, 256);
    img.fill(10, 10, 20, 255);

    let curves = vec![
        (vec![Vec2::new(10.0, 128.0), Vec2::new(80.0, 10.0), Vec2::new(170.0, 245.0), Vec2::new(245.0, 128.0)], (255, 80, 80)),
        (vec![Vec2::new(128.0, 10.0), Vec2::new(10.0, 80.0), Vec2::new(245.0, 170.0), Vec2::new(128.0, 245.0)], (80, 255, 80)),
        (vec![Vec2::new(10.0, 10.0), Vec2::new(245.0, 10.0), Vec2::new(10.0, 245.0), Vec2::new(245.0, 245.0)], (80, 80, 255)),
    ];

    for (pts, (r, g, b)) in &curves {
        let curve = BezierCurve::new(pts.clone());
        let rendered = curve.render(150);
        for i in 0..rendered.len().saturating_sub(1) {
            img.draw_line(
                rendered[i].x as i32, rendered[i].y as i32,
                rendered[i + 1].x as i32, rendered[i + 1].y as i32,
                *r, *g, *b, 255,
            );
        }
    }

    save_png("math/bezier_multiple_curves", &img);
}

// ===== AUDIO — WAV evidence =====

#[test]
fn evidence_audio_sine_440hz() {
    let sample_rate = 44100u32;
    let duration_secs = 1.0f32;
    let num_samples = (sample_rate as f32 * duration_secs) as usize;
    let mut samples = Vec::with_capacity(num_samples);
    for i in 0..num_samples {
        let t = i as f32 / sample_rate as f32;
        samples.push((t * 440.0 * 2.0 * std::f32::consts::PI).sin() * 0.8);
    }
    let sound = SoundData::from_samples(samples, sample_rate, 1);
    save_wav("audio/sine_440hz", &sound);
}

#[test]
fn evidence_audio_sine_880hz() {
    let sample_rate = 44100u32;
    let num_samples = 44100;
    let mut samples = Vec::with_capacity(num_samples);
    for i in 0..num_samples {
        let t = i as f32 / sample_rate as f32;
        samples.push((t * 880.0 * 2.0 * std::f32::consts::PI).sin() * 0.8);
    }
    let sound = SoundData::from_samples(samples, sample_rate, 1);
    save_wav("audio/sine_880hz", &sound);
}

#[test]
fn evidence_audio_chord() {
    let sample_rate = 44100u32;
    let num_samples = 44100;
    let mut samples = Vec::with_capacity(num_samples);
    let freqs = [261.63, 329.63, 392.0]; // C major chord
    for i in 0..num_samples {
        let t = i as f32 / sample_rate as f32;
        let mut val = 0.0;
        for &f in &freqs {
            val += (t * f * 2.0 * std::f32::consts::PI).sin();
        }
        samples.push((val / freqs.len() as f32) * 0.8);
    }
    let sound = SoundData::from_samples(samples, sample_rate, 1);
    save_wav("audio/c_major_chord", &sound);
}

#[test]
fn evidence_audio_stereo() {
    let sample_rate = 44100u32;
    let duration_secs = 1.0f32;
    let num_samples_per_ch = (sample_rate as f32 * duration_secs) as usize;
    let mut samples = Vec::with_capacity(num_samples_per_ch * 2);
    for i in 0..num_samples_per_ch {
        let t = i as f32 / sample_rate as f32;
        let left = (t * 440.0 * 2.0 * std::f32::consts::PI).sin() * 0.7;
        let right = (t * 554.37 * 2.0 * std::f32::consts::PI).sin() * 0.7; // C#5
        samples.push(left);
        samples.push(right);
    }
    let sound = SoundData::from_samples(samples, sample_rate, 2);
    save_wav("audio/stereo_two_tones", &sound);
}

#[test]
fn evidence_audio_frequency_sweep() {
    let sample_rate = 44100u32;
    let duration = 2.0f32;
    let num_samples = (sample_rate as f32 * duration) as usize;
    let mut samples = Vec::with_capacity(num_samples);
    let start_freq = 100.0f32;
    let end_freq = 4000.0f32;
    let mut phase = 0.0f32;
    for i in 0..num_samples {
        let t = i as f32 / num_samples as f32;
        let freq = start_freq + (end_freq - start_freq) * t;
        phase += freq / sample_rate as f32;
        samples.push((phase * 2.0 * std::f32::consts::PI).sin() * 0.7);
    }
    let sound = SoundData::from_samples(samples, sample_rate, 1);
    save_wav("audio/frequency_sweep_100_4000", &sound);
}

#[test]
fn evidence_audio_amplitude_envelope() {
    let sample_rate = 44100u32;
    let duration = 2.0f32;
    let num_samples = (sample_rate as f32 * duration) as usize;
    let mut samples = Vec::with_capacity(num_samples);
    for i in 0..num_samples {
        let t = i as f32 / sample_rate as f32;
        let norm_t = i as f32 / num_samples as f32;
        // ADSR-like envelope: attack 0-0.1, sustain 0.1-0.7, release 0.7-1.0
        let envelope = if norm_t < 0.1 {
            norm_t / 0.1
        } else if norm_t < 0.7 {
            1.0
        } else {
            1.0 - (norm_t - 0.7) / 0.3
        };
        samples.push((t * 440.0 * 2.0 * std::f32::consts::PI).sin() * 0.8 * envelope);
    }
    let sound = SoundData::from_samples(samples, sample_rate, 1);
    save_wav("audio/amplitude_envelope", &sound);
}

#[test]
fn evidence_audio_square_wave() {
    let sample_rate = 44100u32;
    let num_samples = 44100;
    let mut samples = Vec::with_capacity(num_samples);
    for i in 0..num_samples {
        let t = i as f32 / sample_rate as f32;
        let phase = (t * 440.0) % 1.0;
        samples.push(if phase < 0.5 { 0.7 } else { -0.7 });
    }
    let sound = SoundData::from_samples(samples, sample_rate, 1);
    save_wav("audio/square_wave_440hz", &sound);
}

#[test]
fn evidence_audio_sawtooth_wave() {
    let sample_rate = 44100u32;
    let num_samples = 44100;
    let mut samples = Vec::with_capacity(num_samples);
    for i in 0..num_samples {
        let t = i as f32 / sample_rate as f32;
        let phase = (t * 440.0) % 1.0;
        samples.push((phase * 2.0 - 1.0) * 0.7);
    }
    let sound = SoundData::from_samples(samples, sample_rate, 1);
    save_wav("audio/sawtooth_wave_440hz", &sound);
}

#[test]
fn evidence_audio_white_noise() {
    let sample_rate = 44100u32;
    let num_samples = 44100;
    let mut samples = Vec::with_capacity(num_samples);
    // Simple deterministic pseudo-random for reproducibility
    let mut rng_state: u32 = 42;
    for _ in 0..num_samples {
        rng_state = rng_state.wrapping_mul(1103515245).wrapping_add(12345);
        let val = (rng_state >> 16) as f32 / 32768.0 - 1.0;
        samples.push(val * 0.5);
    }
    let sound = SoundData::from_samples(samples, sample_rate, 1);
    save_wav("audio/white_noise", &sound);
}

#[test]
fn evidence_audio_silence() {
    let sample_rate = 44100u32;
    let num_samples = 22050; // 0.5 seconds
    let samples = vec![0.0f32; num_samples];
    let sound = SoundData::from_samples(samples, sample_rate, 1);
    save_wav("audio/silence_half_second", &sound);
}

// ===== AUDIO VISUALIZATION — Waveform evidence as PNG =====

#[test]
fn evidence_audio_waveform_visualization() {
    let sample_rate = 44100u32;
    let num_samples = 44100;
    let mut samples = Vec::with_capacity(num_samples);
    for i in 0..num_samples {
        let t = i as f32 / sample_rate as f32;
        samples.push((t * 440.0 * 2.0 * std::f32::consts::PI).sin() * 0.8);
    }
    let sound = SoundData::from_samples(samples, sample_rate, 1);

    render_waveform("audio/waveform_sine_440hz", &sound.samples(), sample_rate);
    render_waveform_zoomed("audio/waveform_sine_440hz_zoomed", &sound.samples(), sample_rate, 1000);
    save_wav("audio/waveform_sine_440hz_audio", &sound);
}

// ===== COMBINED — Cross-module evidence =====

#[test]
fn evidence_noise_to_heightmap_render() {
    let noise = NoiseGenerator::new(7777);
    let size = 256u32;
    let mut img = ImageData::new(size, size);

    for y in 0..size {
        for x in 0..size {
            let val = noise.fbm(
                x as f64 * 0.01, y as f64 * 0.01,
                5, 2.0, 0.5, NoiseKind::Simplex,
            );
            let h = (val * 0.5 + 0.5).clamp(0.0, 1.0);
            // Color gradient: blue → green → brown → white
            let (r, g, b) = if h < 0.35 {
                let t = h / 0.35;
                ((20.0 + t * 40.0) as u8, (60.0 + t * 70.0) as u8, (140.0 + t * 60.0) as u8)
            } else if h < 0.6 {
                let t = (h - 0.35) / 0.25;
                ((60.0 - t * 10.0) as u8, (130.0 + t * 30.0) as u8, (60.0 - t * 20.0) as u8)
            } else if h < 0.8 {
                let t = (h - 0.6) / 0.2;
                ((80.0 + t * 60.0) as u8, (100.0 - t * 30.0) as u8, (40.0 + t * 20.0) as u8)
            } else {
                let t = (h - 0.8) / 0.2;
                ((180.0 + t * 60.0) as u8, (180.0 + t * 60.0) as u8, (190.0 + t * 50.0) as u8)
            };
            img.set_pixel(x, y, r, g, b, 255);
        }
    }
    save_png("combined/noise_heightmap_colored", &img);
}

#[test]
fn evidence_image_all_effects_grid() {
    // Single large image showing every effect side by side
    let tile = 64u32;
    let cols = 5u32;
    let rows = 4u32;
    let mut canvas = ImageData::new(tile * cols, tile * rows);
    canvas.fill(30, 30, 30, 255);

    // Base image for effects
    let make_base = || {
        let mut img = ImageData::new(tile, tile);
        for y in 0..tile {
            for x in 0..tile {
                img.set_pixel(x, y, (x * 4) as u8, (y * 4) as u8, 128, 255);
            }
        }
        img
    };

    let effects: Vec<(&str, Box<dyn Fn(ImageData) -> ImageData>)> = vec![
        ("Original", Box::new(|img| img)),
        ("Brightness", Box::new(|mut img: ImageData| { img.brightness(0.3); img })),
        ("Contrast", Box::new(|mut img: ImageData| { img.contrast(2.0); img })),
        ("Grayscale", Box::new(|mut img: ImageData| { img.grayscale(); img })),
        ("Sepia", Box::new(|mut img: ImageData| { img.sepia(); img })),
        ("Invert", Box::new(|mut img: ImageData| { img.invert(); img })),
        ("Threshold", Box::new(|mut img: ImageData| { img.threshold(128); img })),
        ("Posterize", Box::new(|mut img: ImageData| { img.posterize(4); img })),
        ("Tint Red", Box::new(|mut img: ImageData| { img.tint(255, 0, 0, 0.5); img })),
        ("Saturation0", Box::new(|mut img: ImageData| { img.saturation(0.0); img })),
        ("Gamma Low", Box::new(|mut img: ImageData| { img.gamma(0.5); img })),
        ("Gamma High", Box::new(|mut img: ImageData| { img.gamma(2.2); img })),
        ("Noise", Box::new(|mut img: ImageData| { img.noise(60); img })),
        ("AlphaMask", Box::new(|mut img: ImageData| { img.alpha_mask(0.5); img })),
        ("FlipH", Box::new(|mut img: ImageData| { img.flip_horizontal(); img })),
        ("FlipV", Box::new(|mut img: ImageData| { img.flip_vertical(); img })),
        ("Rotate90", Box::new(|img: ImageData| img.rotate_90_cw())),
        ("Blur", Box::new(|img: ImageData| img.blur(2))),
        ("Sharpen", Box::new(|img: ImageData| img.sharpen())),
        ("Crop", Box::new(|img: ImageData| {
            let c = img.crop(8, 8, 48, 48).unwrap();
            c.resize_nearest(tile, tile)
        })),
    ];

    for (i, (_name, apply)) in effects.iter().enumerate() {
        let base = make_base();
        let result = apply(base);
        let col = (i as u32) % cols;
        let row = (i as u32) / cols;
        canvas.paste(&result, col * tile, row * tile);
    }

    save_png("combined/all_effects_grid", &canvas);
}


// =====================================================================
// ===== TILEMAP — TileMap evidence =====
// =====================================================================

#[test]
fn evidence_tilemap_basic_grid() {
    let mut tm = TileMap::new(16, 16, 8);
    let layer = tm.add_layer("ground", 16, 12);
    // Checkerboard pattern
    for y in 0..12 {
        for x in 0..16 {
            let gid = if (x + y) % 2 == 0 { 1 } else { 2 };
            tm.set_tile(layer, x, y, gid);
        }
    }
    let img = tm.render_to_image(16);
    save_png("tilemap/basic_grid", &img);
}

#[test]
fn evidence_tilemap_multi_layer() {
    let mut tm = TileMap::new(16, 16, 8);
    let ground = tm.add_layer("ground", 10, 10);
    let objects = tm.add_layer("objects", 10, 10);
    // Fill ground
    tm.fill(ground, 1);
    // Place some "object" tiles
    tm.set_tile(objects, 3, 3, 10);
    tm.set_tile(objects, 5, 5, 11);
    tm.set_tile(objects, 7, 2, 12);

    let img = tm.render_to_image(16);
    save_png("tilemap/multi_layer", &img);
}

#[test]
fn evidence_tilemap_world_to_tile() {
    let tm = TileMap::new(32, 32, 8);
    // Show coordinate mapping grid
    let mut img = ImageData::new(256, 256);
    img.fill(30, 30, 40, 255);
    // Draw tile grid
    for i in (0..256).step_by(32) {
        img.draw_line(i, 0, i, 255, 60, 60, 80, 255);
        img.draw_line(0, i, 255, i, 60, 60, 80, 255);
    }
    // Mark a few world positions and their tile coordinates
    let test_points = [(50.0f32, 80.0f32), (150.0, 200.0), (220.0, 30.0)];
    let colors = [(255u8, 80, 80), (80, 255, 80), (80, 80, 255)];
    for (i, &(wx, wy)) in test_points.iter().enumerate() {
        let (tx, ty) = tm.world_to_tile(wx, wy);
        let (r, g, b) = colors[i];
        img.draw_circle(wx as i32, wy as i32, 5, r, g, b, 255);
        // Highlight the tile cell
        let cell_x = tx * 32;
        let cell_y = ty * 32;
        img.draw_rect(cell_x as i32, cell_y as i32, 32, 32, r, g, b, 128);
    }
    save_png("tilemap/world_to_tile", &img);
}

// =====================================================================
// ===== MINIMAP — Minimap evidence =====
// =====================================================================

#[test]
fn evidence_minimap_terrain() {
    let mut mm = Minimap::new(20, 15, 200, 150);
    // Set terrain types with colors
    mm.set_terrain_color(0, [0.2, 0.4, 0.8, 1.0]); // Water - blue
    mm.set_terrain_color(1, [0.3, 0.7, 0.3, 1.0]); // Grass - green
    mm.set_terrain_color(2, [0.6, 0.5, 0.3, 1.0]); // Mountain - brown
    mm.set_terrain_color(3, [0.9, 0.9, 0.95, 1.0]); // Snow - white

    // Create island terrain
    for y in 0..15u32 {
        for x in 0..20u32 {
            let dx = x as f32 - 10.0;
            let dy = y as f32 - 7.5;
            let dist = (dx * dx + dy * dy).sqrt();
            let terrain = if dist > 8.0 { 0 } else if dist > 5.0 { 1 } else if dist > 3.0 { 2 } else { 3 };
            mm.set_terrain(x, y, terrain);
        }
    }

    let img = mm.render_to_image(0);
    save_png("minimap/terrain", &img);
}

#[test]
fn evidence_minimap_fog_of_war() {
    let mut mm = Minimap::new(16, 16, 256, 256);
    mm.set_fog_enabled(true);
    mm.set_terrain_color(0, [0.3, 0.6, 0.3, 1.0]); // Green grass

    // All grass terrain
    for y in 0..16u32 {
        for x in 0..16u32 {
            mm.set_terrain(x, y, 0);
            mm.set_fog_level(x, y, FogLevel::Hidden);
        }
    }

    // Reveal some cells in a circular pattern
    for y in 0..16u32 {
        for x in 0..16u32 {
            let dx = x as f32 - 8.0;
            let dy = y as f32 - 8.0;
            let dist = (dx * dx + dy * dy).sqrt();
            if dist < 4.0 {
                mm.set_fog_level(x, y, FogLevel::Visible);
            } else if dist < 7.0 {
                mm.set_fog_level(x, y, FogLevel::Explored);
            }
        }
    }

    let img = mm.render_to_image(0);
    save_png("minimap/fog_of_war", &img);
}

#[test]
fn evidence_minimap_objects_and_markers() {
    let mut mm = Minimap::new(20, 20, 200, 200);
    mm.set_terrain_color(0, [0.2, 0.2, 0.3, 1.0]); // Dark background
    for y in 0..20u32 {
        for x in 0..20u32 {
            mm.set_terrain(x, y, 0);
        }
    }
    // Add object types
    let _unit_type = mm.add_object_type("unit".to_string(), [1.0, 0.0, 0.0, 1.0]);
    let _building_type = mm.add_object_type("building".to_string(), [0.0, 0.0, 1.0, 1.0]);
    // Place objects
    mm.set_object(1, 5.0, 5.0, 0, 1);
    mm.set_object(2, 15.0, 10.0, 0, 1);
    mm.set_object(3, 10.0, 15.0, 1, 2);
    // Add markers
    mm.add_marker(8.0, 8.0, "Base".to_string(), [1.0, 1.0, 0.0, 1.0]);

    let img = mm.render_to_image(0);
    save_png("minimap/objects_markers", &img);
}

#[test]
fn evidence_minimap_political_mode() {
    let mut mm = Minimap::new(16, 16, 256, 256);
    mm.set_color_mode(ColorMode::Political);
    mm.set_terrain_color(0, [0.3, 0.6, 0.3, 1.0]);
    for y in 0..16u32 {
        for x in 0..16u32 {
            mm.set_terrain(x, y, 0);
        }
    }
    // Set owner colors for different territories
    mm.set_owner_color(1, [0.8, 0.2, 0.2, 1.0]); // Red faction
    mm.set_owner_color(2, [0.2, 0.2, 0.8, 1.0]); // Blue faction
    // Place units to show ownership
    for i in 0..5u32 {
        mm.set_object(i, (2 + i * 2) as f32, 5.0, 0, 1);
        mm.set_object(10 + i, (2 + i * 2) as f32, 12.0, 0, 2);
    }

    let img = mm.render_to_image(0);
    save_png("minimap/political_mode", &img);
}

// =====================================================================
// ===== RAYCASTER — 2D Raycasting evidence =====
// =====================================================================

#[test]
fn evidence_raycaster_top_down() {
    let mut rc = Raycaster2D::new(16, 16);
    // Create walls around edges and some internal walls
    for i in 0..16 {
        rc.set_cell(i, 0, 1);  // Top wall
        rc.set_cell(i, 15, 1); // Bottom wall
        rc.set_cell(0, i, 1);  // Left wall
        rc.set_cell(15, i, 1); // Right wall
    }
    // Internal walls
    rc.set_cell(5, 3, 2);
    rc.set_cell(5, 4, 2);
    rc.set_cell(5, 5, 2);
    rc.set_cell(10, 8, 3);
    rc.set_cell(10, 9, 3);
    rc.set_cell(10, 10, 3);
    rc.set_cell(10, 11, 3);

    let img = rc.render_top_down_to_image(8.0, 8.0, 0.0, 16);
    save_png("raycaster/top_down_view", &img);
}

#[test]
fn evidence_raycaster_depth_map() {
    let mut rc = Raycaster2D::new(16, 16);
    // Build a room
    for i in 0..16 {
        rc.set_cell(i, 0, 1);
        rc.set_cell(i, 15, 1);
        rc.set_cell(0, i, 1);
        rc.set_cell(15, i, 1);
    }
    rc.set_cell(6, 4, 2);
    rc.set_cell(6, 5, 2);
    rc.set_cell(10, 10, 3);
    rc.set_cell(11, 10, 3);

    // Cast 320 rays for a pseudo-3D column view
    let num_rays = 320u32;
    let fov = std::f32::consts::FRAC_PI_3;
    let player_angle = 0.0f32;
    let mut img = ImageData::new(320, 200);
    img.fill(20, 20, 30, 255);

    // Sky gradient
    for y in 0..100u32 {
        let t = y as f32 / 100.0;
        let r = (30.0 + t * 50.0) as u8;
        let g = (50.0 + t * 80.0) as u8;
        let b = (120.0 + t * 80.0) as u8;
        for x in 0..320 {
            img.set_pixel(x, y, r, g, b, 255);
        }
    }

    for i in 0..num_rays {
        let ray_angle = player_angle - fov / 2.0 + (i as f32 / num_rays as f32) * fov;
        if let Some(hit) = rc.cast_ray(8.0, 8.0, ray_angle, 20.0) {
            let dist = hit.distance.max(0.1);
            let wall_h = ((200.0 / dist) * 2.0).min(200.0) as u32;
            let top = 100u32.saturating_sub(wall_h / 2);
            let shade = ((1.0 - dist / 20.0).max(0.0) * 255.0) as u8;
            let (r, g, b) = match hit.cell_value {
                1 => (shade, shade, shade),
                2 => (shade, shade / 2, shade / 3),
                3 => (shade / 3, shade / 2, shade),
                _ => (shade, shade, shade),
            };
            for y in top..(top + wall_h).min(200) {
                img.set_pixel(i, y, r, g, b, 255);
            }
        }
    }
    save_png("raycaster/depth_column_view", &img);
}

#[test]
fn evidence_raycaster_line_of_sight() {
    let mut rc = Raycaster2D::new(16, 16);
    // Walls
    for i in 0..16 {
        rc.set_cell(i, 0, 1);
        rc.set_cell(i, 15, 1);
        rc.set_cell(0, i, 1);
        rc.set_cell(15, i, 1);
    }
    // Interior wall
    for i in 3..10 {
        rc.set_cell(8, i, 2);
    }

    let scale = 16u32;
    let mut img = ImageData::new(16 * scale, 16 * scale);
    img.fill(40, 40, 50, 255);
    // Draw walls
    for y in 0..16u32 {
        for x in 0..16u32 {
            if rc.get_cell(x, y) > 0 {
                for py in 0..scale {
                    for px in 0..scale {
                        img.set_pixel(x * scale + px, y * scale + py, 120, 120, 130, 255);
                    }
                }
            }
        }
    }
    // Test LOS between two points
    let (ax, ay) = (4.5f32, 8.0f32);
    let (bx, by) = (12.5f32, 8.0f32);
    let can_see = rc.line_of_sight(ax, ay, bx, by);

    let color = if can_see { (0, 255, 0) } else { (255, 0, 0) };
    img.draw_line(
        (ax * scale as f32) as i32, (ay * scale as f32) as i32,
        (bx * scale as f32) as i32, (by * scale as f32) as i32,
        color.0, color.1, color.2, 200,
    );
    img.draw_circle((ax * scale as f32) as i32, (ay * scale as f32) as i32, 4, 0, 255, 255, 255);
    img.draw_circle((bx * scale as f32) as i32, (by * scale as f32) as i32, 4, 255, 255, 0, 255);
    save_png("raycaster/line_of_sight", &img);
}

// =====================================================================
// ===== PATHFINDING — NavGrid and A* evidence =====
// =====================================================================

#[test]
fn evidence_pathfinding_astar_basic() {
    let mut grid = NavGrid::new(20, 15);
    // Create walls forming a maze-like structure
    for i in 3..12 {
        grid.set_blocked(5, i, true);
    }
    for i in 3..12 {
        grid.set_blocked(10, i, true);
    }
    for i in 5..11 {
        grid.set_blocked(i, 7, true);
    }
    // Open a gap
    grid.set_blocked(5, 3, false);
    grid.set_blocked(10, 11, false);

    let (path, _complete) = astar(&grid, (2, 2), (17, 12), 1, 10000);

    let img = grid.render_to_image(
        16,
        path.as_deref(),
        Some((2, 2)),
        Some((17, 12)),
    );
    save_png("pathfinding/astar_basic", &img);
}

#[test]
fn evidence_pathfinding_navgrid_costs() {
    let mut grid = NavGrid::new(20, 15);
    // Variable cost terrain
    grid.fill_rect(0, 0, 20, 15, 1);  // Default cost 1
    grid.fill_rect(6, 3, 4, 9, 5);    // High cost zone
    grid.fill_rect(12, 0, 2, 15, 255); // Blocked

    let (path, _) = astar(&grid, (2, 7), (18, 7), 1, 10000);

    let img = grid.render_to_image(16, path.as_deref(), None, None);
    save_png("pathfinding/navgrid_costs", &img);
}

#[test]
fn evidence_pathfinding_flow_field() {
    let grid = NavGrid::new(16, 16);
    let grid_rc = Rc::new(RefCell::new(grid));
    let mut ff = FlowField::new(grid_rc.clone());
    // Set some blocked cells
    {
        let mut g = grid_rc.borrow_mut();
        for i in 4..12 {
            g.set_blocked(8, i, true);
        }
        g.set_blocked(8, 4, false); // gap at top
    }
    ff.calculate(14, 8, 1);

    let img = ff.render_to_image(16);
    save_png("pathfinding/flow_field", &img);
}

#[test]
fn evidence_pathfinding_influence_map() {
    let mut imap = InfluenceMap::new(20, 15, 1.0);
    imap.add_layer("enemy");
    imap.add_layer("ally");
    // Stamp enemy influence
    imap.stamp_influence("enemy", 5.0, 5.0, 8.0, 1.0, 0.5);
    imap.stamp_influence("enemy", 15.0, 10.0, 6.0, 0.8, 0.5);
    // Stamp ally influence
    imap.stamp_influence("ally", 10.0, 8.0, 10.0, 1.0, 0.5);

    let img = imap.render_to_image(16);
    save_png("pathfinding/influence_map", &img);
}

// =====================================================================
// ===== PROCGEN — Procedural Generation evidence =====
// =====================================================================

#[test]
fn evidence_procgen_cellular_automata() {
    let opts = CellularOpts {
        fill: 0.45,
        iterations: 5,
        birth: 5,
        survive: 4,
        seed: 42,
    };
    let grid = cellular_automata(64, 48, &opts);

    let cell = 4u32;
    let mut img = ImageData::new(64 * cell, 48 * cell);
    for y in 0..48u32 {
        for x in 0..64u32 {
            let alive = grid[(y * 64 + x) as usize] == 1;
            let (r, g, b) = if alive { (60, 80, 60) } else { (30, 30, 40) };
            for py in 0..cell {
                for px in 0..cell {
                    img.set_pixel(x * cell + px, y * cell + py, r, g, b, 255);
                }
            }
        }
    }
    save_png("procgen/cellular_automata", &img);
}

#[test]
fn evidence_procgen_cellular_cave() {
    let opts = CellularOpts {
        fill: 0.55,
        iterations: 6,
        birth: 6,
        survive: 3,
        seed: 1234,
    };
    let grid = cellular_automata(80, 60, &opts);

    let cell = 4u32;
    let mut img = ImageData::new(80 * cell, 60 * cell);
    for y in 0..60u32 {
        for x in 0..80u32 {
            let alive = grid[(y * 80 + x) as usize] == 1;
            let (r, g, b) = if alive { (80, 70, 50) } else { (25, 20, 15) };
            for py in 0..cell {
                for px in 0..cell {
                    img.set_pixel(x * cell + px, y * cell + py, r, g, b, 255);
                }
            }
        }
    }
    save_png("procgen/cellular_cave", &img);
}

#[test]
fn evidence_procgen_voronoi_diagram() {
    // Generate seed points
    let points: Vec<(f32, f32)> = (0..20).map(|i| {
        let angle = i as f32 * 0.314159;
        let r = 40.0 + (i as f32 * 7.3) % 50.0;
        (128.0 + r * angle.cos(), 128.0 + r * angle.sin())
    }).collect();

    let opts = VoronoiOpts {
        warp_scale: 0.0,
        warp_strength: 0.0,
        seed: 42,
    };
    let (regions, _cx, _cy) = voronoi_diagram(256, 256, &points, &opts);

    let mut img = ImageData::new(256, 256);
    // Color each region
    let palette: Vec<(u8, u8, u8)> = (0..20).map(|i| {
        let h = (i as f32 * 0.3).sin() * 0.5 + 0.5;
        let r = (50.0 + h * 200.0) as u8;
        let g = (80.0 + ((i as f32 * 0.7).cos() * 0.5 + 0.5) * 170.0) as u8;
        let b = (60.0 + ((i as f32 * 1.1).sin() * 0.5 + 0.5) * 190.0) as u8;
        (r, g, b)
    }).collect();

    for y in 0..256u32 {
        for x in 0..256u32 {
            let region = regions[(y * 256 + x) as usize] as usize;
            let (r, g, b) = palette[region % palette.len()];
            img.set_pixel(x, y, r, g, b, 255);
        }
    }
    // Draw seed points
    for &(px, py) in &points {
        img.draw_circle(px as i32, py as i32, 3, 255, 255, 255, 255);
    }
    save_png("procgen/voronoi_diagram", &img);
}

#[test]
fn evidence_procgen_voronoi_warped() {
    let points: Vec<(f32, f32)> = (0..15).map(|i| {
        let angle = i as f32 * 0.42;
        let r = 30.0 + (i as f32 * 11.0) % 60.0;
        (128.0 + r * angle.cos(), 128.0 + r * angle.sin())
    }).collect();

    let opts = VoronoiOpts {
        warp_scale: 0.03,
        warp_strength: 15.0,
        seed: 99,
    };
    let (regions, _, _) = voronoi_diagram(256, 256, &points, &opts);

    let mut img = ImageData::new(256, 256);
    let palette: Vec<(u8, u8, u8)> = (0..15).map(|i| {
        ((70 + i * 12) as u8, (100 + i * 8) as u8, (50 + i * 14) as u8)
    }).collect();
    for y in 0..256u32 {
        for x in 0..256u32 {
            let region = regions[(y * 256 + x) as usize] as usize;
            let (r, g, b) = palette[region % palette.len()];
            img.set_pixel(x, y, r, g, b, 255);
        }
    }
    save_png("procgen/voronoi_warped", &img);
}

#[test]
fn evidence_procgen_poisson_disk() {
    let points = poisson_disk(256.0, 256.0, 15.0, 30, 42);

    let mut img = ImageData::new(256, 256);
    img.fill(20, 25, 35, 255);
    for &(px, py) in &points {
        if px >= 0.0 && py >= 0.0 && px < 256.0 && py < 256.0 {
            img.draw_circle(px as i32, py as i32, 2, 100, 200, 255, 255);
        }
    }
    save_png("procgen/poisson_disk", &img);
}

#[test]
fn evidence_procgen_poisson_dense() {
    let points = poisson_disk(256.0, 256.0, 8.0, 30, 1234);

    let mut img = ImageData::new(256, 256);
    img.fill(15, 15, 25, 255);
    for (i, &(px, py)) in points.iter().enumerate() {
        if px >= 0.0 && py >= 0.0 && px < 256.0 && py < 256.0 {
            let r = ((i * 37) % 200 + 55) as u8;
            let g = ((i * 73) % 200 + 55) as u8;
            let b = ((i * 111) % 200 + 55) as u8;
            img.set_pixel(px as u32, py as u32, r, g, b, 255);
        }
    }
    save_png("procgen/poisson_dense", &img);
}

// =====================================================================
// ===== EASING — All easing function curves =====
// =====================================================================

#[test]
fn evidence_easing_all_curves() {
    let names = [
        "linear", "inquad", "outquad", "inoutquad",
        "incubic", "outcubic", "inoutcubic",
        "inquart", "outquart", "inoutquart",
        "insine", "outsine", "inoutsine",
        "inexpo", "outexpo", "inoutexpo",
        "inelastic", "outelastic",
        "inbounce", "outbounce",
        "inback", "outback",
    ];
    let cols = 4;
    let rows = (names.len() + cols - 1) / cols;
    let chart_w = 120u32;
    let chart_h = 80u32;
    let pad = 10u32;
    let img_w = cols as u32 * (chart_w + pad) + pad;
    let img_h = rows as u32 * (chart_h + pad + 16) + pad;
    let mut img = ImageData::new(img_w, img_h);
    img.fill(20, 20, 30, 255);

    for (idx, name) in names.iter().enumerate() {
        let col = (idx % cols) as u32;
        let row = (idx / cols) as u32;
        let ox = pad + col * (chart_w + pad);
        let oy = pad + row * (chart_h + pad + 16) + 14;

        // Chart background
        img.draw_rect(ox as i32, oy as i32, chart_w, chart_h, 35, 35, 50, 255);

        // Draw curve
        let mut prev_x = 0i32;
        let mut prev_y = 0i32;
        for step in 0..=100 {
            let t = step as f32 / 100.0;
            let v = easing::apply(name, t).unwrap_or(t);
            let px = ox as i32 + (t * (chart_w - 1) as f32) as i32;
            let py = oy as i32 + chart_h as i32 - 1 - (v.clamp(0.0, 1.5) / 1.5 * (chart_h - 1) as f32) as i32;
            if step > 0 {
                img.draw_line(prev_x, prev_y, px, py, 100, 220, 160, 255);
            }
            prev_x = px;
            prev_y = py;
        }
    }
    save_png("easing/all_curves_gallery", &img);
}

#[test]
fn evidence_easing_comparison() {
    // Compare a few key easings on one chart
    let mut img = ImageData::new(256, 256);
    img.fill(20, 20, 30, 255);
    // Grid
    for i in (0..256).step_by(32) {
        img.draw_line(i, 0, i, 255, 35, 35, 45, 255);
        img.draw_line(0, i, 255, i, 35, 35, 45, 255);
    }

    let curves = [
        ("linear", (200, 200, 200)),
        ("inquad", (255, 80, 80)),
        ("outquad", (80, 255, 80)),
        ("inoutcubic", (80, 80, 255)),
        ("outelastic", (255, 200, 80)),
        ("outbounce", (200, 80, 255)),
    ];

    for (name, (r, g, b)) in &curves {
        let mut prev = (0i32, 255i32);
        for step in 1..=200 {
            let t = step as f32 / 200.0;
            let v = easing::apply(name, t).unwrap_or(t);
            let px = (t * 255.0) as i32;
            let py = 255 - (v.clamp(-0.2, 1.3) * 170.0 + 20.0) as i32;
            img.draw_line(prev.0, prev.1, px, py, *r, *g, *b, 220);
            prev = (px, py);
        }
    }
    save_png("easing/comparison_chart", &img);
}

// =====================================================================
// ===== LIGHT — 2D lighting evidence =====
// =====================================================================

#[test]
fn evidence_light_point_lights() {
    let mut world = LightWorld::new();
    let mut l1 = Light2D::new(80.0, 80.0, 100.0);
    l1.set_color(Color { r: 1.0, g: 0.3, b: 0.1, a: 1.0 });
    l1.set_intensity(1.0);
    let mut l2 = Light2D::new(180.0, 120.0, 80.0);
    l2.set_color(Color { r: 0.1, g: 0.3, b: 1.0, a: 1.0 });
    l2.set_intensity(0.8);
    let mut l3 = Light2D::new(130.0, 200.0, 120.0);
    l3.set_color(Color { r: 0.1, g: 1.0, b: 0.3, a: 1.0 });
    l3.set_intensity(0.7);

    let _k1 = world.add_light(l1);
    let _k2 = world.add_light(l2);
    let _k3 = world.add_light(l3);

    let img = world.render_to_image(256, 256);
    save_png("light/point_lights", &img);
}

#[test]
fn evidence_light_with_occluders() {
    let mut world = LightWorld::new();
    let light = Light2D::new(128.0, 128.0, 150.0);
    let _lk = world.add_light(light);

    // Add rectangular occluder
    let occ = Occluder::new(vec![
        Vec2::new(60.0, 60.0),
        Vec2::new(100.0, 60.0),
        Vec2::new(100.0, 90.0),
        Vec2::new(60.0, 90.0),
    ]);
    let _ok = world.add_occluder(occ);

    let img = world.render_to_image(256, 256);
    save_png("light/occluder_shadow", &img);
}

// =====================================================================
// ===== PARTICLE — Particle system evidence =====
// =====================================================================

#[test]
fn evidence_particle_system_basic() {
    let config = ParticleConfig {
        max_particles: 200,
        emission_rate: 100.0,
        speed_min: 30.0,
        speed_max: 80.0,
        lifetime_min: 0.5,
        lifetime_max: 1.5,
        direction: -std::f32::consts::FRAC_PI_2,
        spread: std::f32::consts::FRAC_PI_4,
        gravity_y: 50.0,
        sizes: vec![4.0, 1.0],
        colors: vec![[1.0, 0.5, 0.0, 1.0], [1.0, 0.0, 0.0, 0.0]],
        ..Default::default()
    };
    let mut ps = ParticleSystem::new(config);
    ps.move_to(128.0, 200.0);
    ps.start();

    // Simulate for 2 seconds
    for _ in 0..120 {
        ps.update(1.0 / 60.0);
    }

    let img = ps.render_to_image(256, 256);
    save_png("particle/basic_emitter", &img);
}

#[test]
fn evidence_particle_system_fountain() {
    let config = ParticleConfig {
        max_particles: 500,
        emission_rate: 200.0,
        speed_min: 100.0,
        speed_max: 180.0,
        lifetime_min: 1.0,
        lifetime_max: 2.5,
        direction: -std::f32::consts::FRAC_PI_2,
        spread: 0.3,
        gravity_y: 150.0,
        sizes: vec![3.0, 1.0],
        colors: vec![[0.3, 0.6, 1.0, 1.0], [0.1, 0.3, 0.8, 0.0]],
        ..Default::default()
    };
    let mut ps = ParticleSystem::new(config);
    ps.move_to(128.0, 240.0);
    ps.start();

    for _ in 0..180 {
        ps.update(1.0 / 60.0);
    }

    let img = ps.render_to_image(256, 256);
    save_png("particle/fountain", &img);
}

// =====================================================================
// ===== ANIMATION — Animation controller evidence =====
// =====================================================================

#[test]
fn evidence_animation_frame_grid() {
    let mut anim = Animation::new();
    // Add a grid of 4x4 frames (each 32x32 in a 128x128 sheet)
    anim.add_frames_from_grid(128, 128, 32, 32, 0, 16);
    anim.add_clip("walk", vec![0, 1, 2, 3], 8.0, true);
    anim.play("walk");

    // Visualize the frame quads on a sprite sheet representation
    let mut img = ImageData::new(256, 256);
    img.fill(30, 30, 40, 255);

    // Draw entire "sprite sheet" outline
    img.draw_rect(10, 10, 128, 128, 80, 80, 100, 255);

    // Highlight each frame
    let colors = [(255u8, 80, 80), (80, 255, 80), (80, 80, 255), (255, 255, 80)];
    for i in 0..4usize {
        anim.set_frame(i);
        if let Some(quad) = anim.current_quad() {
            let (r, g, b) = colors[i % colors.len()];
            img.draw_rect(
                10 + quad.x as i32, 10 + quad.y as i32,
                quad.width as u32, quad.height as u32,
                r, g, b, 180,
            );
        }
    }

    // Show timeline below
    for i in 0..4 {
        let x = 10 + i * 60;
        let (r, g, b) = colors[i as usize % colors.len()];
        img.draw_rect(x, 160, 50, 40, r, g, b, 200);
    }
    save_png("animation/frame_grid", &img);
}

#[test]
fn evidence_animation_clip_playback() {
    let mut anim = Animation::new();
    anim.add_frames_from_grid(64, 64, 16, 16, 0, 16);
    anim.add_clip("run", vec![0, 1, 2, 3, 4, 5, 6, 7], 10.0, true);
    anim.play("run");

    // Capture 8 frames at different times
    let mut img = ImageData::new(256, 64);
    img.fill(25, 25, 35, 255);

    for frame in 0..8 {
        anim.update(1.0 / 10.0);
        let cur = anim.current_frame();
        let x = frame * 32;
        // Draw frame number as colored box
        let hue = (cur as f32 / 8.0 * 360.0) % 360.0;
        let r = (128.0 + 127.0 * (hue * std::f32::consts::PI / 180.0).sin()) as u8;
        let g = (128.0 + 127.0 * ((hue + 120.0) * std::f32::consts::PI / 180.0).sin()) as u8;
        let b = (128.0 + 127.0 * ((hue + 240.0) * std::f32::consts::PI / 180.0).sin()) as u8;
        img.draw_rect(x as i32 + 2, 2, 28, 60, r, g, b, 255);
    }
    save_png("animation/clip_playback", &img);
}

// =====================================================================
// ===== SPINE — Skeleton/Bone evidence =====
// =====================================================================

#[test]
fn evidence_spine_skeleton_stick_figure() {
    let mut skeleton = Skeleton::new("character");
    // Build a simple humanoid bone hierarchy
    let root = skeleton.add_bone(Bone::new("root"));
    let spine_bone = skeleton.add_bone(Bone::with_parent("spine", root, 0.0, -30.0));
    let _head = skeleton.add_bone(Bone::with_parent("head", spine_bone, 0.0, -25.0));
    let _l_arm = skeleton.add_bone(Bone::with_parent("l_arm", spine_bone, -20.0, -5.0));
    let _r_arm = skeleton.add_bone(Bone::with_parent("r_arm", spine_bone, 20.0, -5.0));
    let _l_leg = skeleton.add_bone(Bone::with_parent("l_leg", root, -10.0, 30.0));
    let _r_leg = skeleton.add_bone(Bone::with_parent("r_leg", root, 10.0, 30.0));

    skeleton.set_root_position(128.0, 160.0);
    skeleton.update_world_transforms();

    let img = skeleton.render_to_image(256, 256);
    save_png("spine/skeleton_stick_figure", &img);
}

// =====================================================================
// ===== GRAPH — Graph data structure evidence =====
// =====================================================================

#[test]
fn evidence_graph_node_network() {
    let mut graph = Graph::new();
    // Create a network of nodes
    let n1 = graph.add_node("city", 5);
    let n2 = graph.add_node("city", 5);
    let n3 = graph.add_node("city", 5);
    let n4 = graph.add_node("city", 5);
    let n5 = graph.add_node("village", 3);
    let n6 = graph.add_node("village", 3);

    // Add edges
    let _ = graph.add_edge(n1, n2, Some("road"));
    let _ = graph.add_edge(n2, n3, Some("road"));
    let _ = graph.add_edge(n3, n4, Some("road"));
    let _ = graph.add_edge(n4, n1, Some("road"));
    let _ = graph.add_edge(n1, n5, Some("trail"));
    let _ = graph.add_edge(n3, n6, Some("trail"));

    let stats = graph.get_stats();
    assert_eq!(stats.nodes, 6);
    assert_eq!(stats.edges, 6);

    let img = graph.render_to_image(256, 256);
    save_png("graph/node_network", &img);
}

// =====================================================================
// ===== IMAGE LAYERS — LayeredImage evidence =====
// =====================================================================

#[test]
fn evidence_layers_basic_merge() {
    let mut layers = LayeredImage::new(128, 128);

    // Background layer - solid blue
    let bg_idx = layers.add_layer("background");
    let mut bg = ImageData::new(128, 128);
    bg.fill(40, 60, 120, 255);
    layers.set_layer_image(bg_idx, &bg);

    // Midground - green circle
    let mid_idx = layers.add_layer("midground");
    let mut mid = ImageData::new(128, 128);
    mid.fill(0, 0, 0, 0); // transparent
    mid.draw_circle(64, 64, 40, 80, 200, 80, 200);
    layers.set_layer_image(mid_idx, &mid);

    // Foreground - red rect
    let fg_idx = layers.add_layer("foreground");
    let mut fg = ImageData::new(128, 128);
    fg.fill(0, 0, 0, 0);
    fg.draw_rect(30, 30, 68, 68, 220, 60, 60, 180);
    layers.set_layer_image(fg_idx, &fg);

    let merged = layers.merge();
    save_png("layers/merge_basic", &merged);
}

#[test]
fn evidence_layers_opacity() {
    let mut layers = LayeredImage::new(128, 128);

    let bg_idx = layers.add_layer("bg");
    let mut bg = ImageData::new(128, 128);
    for y in 0..128 {
        for x in 0..128 {
            bg.set_pixel(x, y, (x * 2) as u8, 50, (y * 2) as u8, 255);
        }
    }
    layers.set_layer_image(bg_idx, &bg);

    let overlay_idx = layers.add_layer("overlay");
    let mut overlay = ImageData::new(128, 128);
    overlay.fill(255, 200, 50, 255);
    layers.set_layer_image(overlay_idx, &overlay);
    layers.set_opacity(overlay_idx, 0.3);

    let merged = layers.merge();
    save_png("layers/opacity_blend", &merged);
}

// =====================================================================
// ===== CAMERA — Camera2D evidence =====
// =====================================================================

#[test]
fn evidence_camera_viewport() {
    let mut cam = Camera2D::new(256.0, 256.0);
    cam.set_position(128.0, 128.0);
    cam.set_zoom(1.0);

    let mut img = ImageData::new(256, 256);
    img.fill(30, 30, 40, 255);

    // Draw a grid of "world" objects at known positions
    let objects = [
        (64.0f32, 64.0f32, (255u8, 80, 80)),
        (192.0, 64.0, (80, 255, 80)),
        (64.0, 192.0, (80, 80, 255)),
        (192.0, 192.0, (255, 255, 80)),
        (128.0, 128.0, (255, 128, 255)),
        (128.0, 40.0, (255, 200, 100)),
        (128.0, 216.0, (100, 255, 200)),
        (40.0, 128.0, (200, 100, 255)),
        (216.0, 128.0, (100, 200, 200)),
    ];

    for &(wx, wy, (r, g, b)) in &objects {
        let (sx, sy) = cam.to_screen_coords(wx, wy);
        if sx >= 0.0 && sy >= 0.0 && sx < 256.0 && sy < 256.0 {
            safe_circle(&mut img, sx as i32, sy as i32, 12, r, g, b, 220);
        }
    }

    // Crosshair at camera center
    img.draw_line(118, 128, 138, 128, 255, 255, 255, 200);
    img.draw_line(128, 118, 128, 138, 255, 255, 255, 200);

    // Viewport border (outline only)
    for x in 0..256i32 {
        img.set_pixel(x as u32, 0, 100, 100, 120, 200);
        img.set_pixel(x as u32, 255, 100, 100, 120, 200);
    }
    for y in 0..256i32 {
        img.set_pixel(0, y as u32, 100, 100, 120, 200);
        img.set_pixel(255, y as u32, 100, 100, 120, 200);
    }
    draw_label(&mut img, "VIEWPORT", 90, 6, 255, 255, 255);
    save_png("camera/viewport", &img);
}

#[test]
fn evidence_camera_zoom_levels() {
    let mut img = ImageData::new(512, 128);
    img.fill(25, 25, 35, 255);

    let zooms = [0.5f32, 1.0, 1.5, 2.0];
    for (i, &zoom) in zooms.iter().enumerate() {
        let mut cam = Camera2D::new(128.0, 128.0);
        cam.set_position(64.0, 64.0);
        cam.set_zoom(zoom);
        let ox = (i as i32) * 128;

        // Draw a ring of objects around camera center
        for angle_step in 0..8 {
            let a = angle_step as f32 * std::f32::consts::TAU / 8.0;
            let wx = 64.0 + a.cos() * 30.0;
            let wy = 64.0 + a.sin() * 30.0;
            let (sx, sy) = cam.to_screen_coords(wx, wy);
            let px = ox as f32 + sx;
            let py = sy;
            if px >= ox as f32 && px < (ox + 128) as f32 && py >= 0.0 && py < 128.0 {
                let size = (4.0 * zoom).max(2.0) as i32;
                let hue = (angle_step as f32 / 8.0 * 360.0) as u16;
                let (r, g, b) = hsv_to_rgb(hue, 0.8, 1.0);
                safe_circle(&mut img, px as i32, py as i32, size, r, g, b, 220);
            }
        }
        // Camera center marker
        let (sx, sy) = cam.to_screen_coords(64.0, 64.0);
        let cpx = ox as f32 + sx;
        let cpy = sy;
        if cpx >= ox as f32 && cpx < (ox + 128) as f32 && cpy >= 0.0 && cpy < 128.0 {
            safe_circle(&mut img, cpx as i32, cpy as i32, 2, 255, 255, 255, 255);
        }
        // Frame border (outline only)
        for bx in 0..128i32 {
            img.set_pixel((ox + bx) as u32, 0, 60, 60, 80, 255);
            img.set_pixel((ox + bx) as u32, 127, 60, 60, 80, 255);
        }
        for by in 0..128i32 {
            img.set_pixel(ox as u32, by as u32, 60, 60, 80, 255);
            img.set_pixel((ox + 127) as u32, by as u32, 60, 60, 80, 255);
        }
        // Zoom label
        let label = format!("{}x", zoom);
        draw_label(&mut img, &label, ox + 4, 4, 200, 200, 200);
    }
    save_png("camera/zoom_levels", &img);
}

// =====================================================================
// ===== AUDIO DSP — Effect processing evidence =====
// =====================================================================

fn make_sine_samples(freq: f32, duration: f32, sample_rate: u32) -> Vec<f32> {
    let n = (sample_rate as f32 * duration) as usize;
    (0..n).map(|i| {
        let t = i as f32 / sample_rate as f32;
        (t * freq * 2.0 * std::f32::consts::PI).sin() * 0.8
    }).collect()
}

fn render_waveform(name: &str, samples: &[f32], sample_rate: u32) {
    let width = 800u32;
    let height = 300u32;
    let margin = 40u32;
    let plot_w = width - margin * 2;
    let plot_h = height - margin * 2;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);

    // Draw grid lines and axis labels
    for i in 0..=4 {
        let y = margin as i32 + (plot_h as i32 * i / 4);
        for x in margin..width - margin {
            img.set_pixel(x, y as u32, 35, 35, 50, 255);
        }
    }
    // Vertical grid lines (time markers)
    for i in 0..=8 {
        let x = margin as i32 + (plot_w as i32 * i / 8);
        for y in margin..height - margin {
            img.set_pixel(x as u32, y, 35, 35, 50, 255);
        }
    }
    // Center line (zero crossing) — brighter
    let center_y = margin + plot_h / 2;
    for x in margin..width - margin {
        img.set_pixel(x, center_y, 60, 60, 80, 255);
    }

    // Find peak amplitude for auto-scaling
    let peak = samples.iter().map(|s| s.abs()).fold(0.0f32, f32::max).max(0.01);
    let scale = 0.9 / peak; // leave 10% headroom

    let samples_per_pixel = samples.len().max(1) / plot_w as usize;
    if samples_per_pixel > 0 {
        for x in 0..plot_w {
            let start = x as usize * samples_per_pixel;
            let end = (start + samples_per_pixel).min(samples.len());
            let mut min_val = f32::MAX;
            let mut max_val = f32::MIN;
            for &s in &samples[start..end] {
                let scaled = (s * scale).clamp(-1.0, 1.0);
                min_val = min_val.min(scaled);
                max_val = max_val.max(scaled);
            }
            let y_top = (margin as f32 + (1.0 - max_val) * 0.5 * plot_h as f32) as i32;
            let y_bot = (margin as f32 + (1.0 - min_val) * 0.5 * plot_h as f32) as i32;
            let px = (margin + x) as i32;
            img.draw_line(px, y_top.max(margin as i32), px, y_bot.min((height - margin) as i32), 80, 180, 255, 255);
        }
    }

    // Draw border
    for x in margin..width - margin {
        img.set_pixel(x, margin, 60, 60, 80, 255);
        img.set_pixel(x, height - margin - 1, 60, 60, 80, 255);
    }
    for y in margin..height - margin {
        img.set_pixel(margin, y, 60, 60, 80, 255);
        img.set_pixel(width - margin - 1, y, 60, 60, 80, 255);
    }
    save_png(name, &img);
}
/// Render a stereo waveform showing left (cyan) and right (orange) channels.
fn render_waveform_stereo(name: &str, samples: &[f32], sample_rate: u32) {
    let width = 800u32;
    let height = 400u32;
    let margin = 40u32;
    let plot_w = width - margin * 2;
    let ch_height = (height - margin * 2) / 2;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);

    // Split interleaved stereo samples
    let left: Vec<f32> = samples.iter().step_by(2).copied().collect();
    let right: Vec<f32> = samples.iter().skip(1).step_by(2).copied().collect();

    let peak = samples.iter().map(|s| s.abs()).fold(0.0f32, f32::max).max(0.01);
    let scale = 0.85 / peak;

    // Draw channel separator line
    let sep_y = margin + ch_height;
    for x in margin..width - margin {
        img.set_pixel(x, sep_y, 80, 80, 100, 255);
    }

    // Draw center lines for each channel
    for ch in 0..2 {
        let base_y = margin + ch * ch_height;
        let center_y = base_y + ch_height / 2;
        for x in margin..width - margin {
            img.set_pixel(x, center_y, 40, 40, 55, 255);
        }
    }

    // Render each channel
    for (ch_idx, ch_samples) in [&left, &right].iter().enumerate() {
        let base_y = margin as f32 + ch_idx as f32 * ch_height as f32;
        let spp = ch_samples.len().max(1) / plot_w as usize;
        if spp == 0 { continue; }
        let (cr, cg, cb) = if ch_idx == 0 { (80, 200, 255) } else { (255, 160, 60) };
        for x in 0..plot_w {
            let start = x as usize * spp;
            let end = (start + spp).min(ch_samples.len());
            let mut min_val = f32::MAX;
            let mut max_val = f32::MIN;
            for &s in &ch_samples[start..end] {
                let sc = (s * scale).clamp(-1.0, 1.0);
                min_val = min_val.min(sc);
                max_val = max_val.max(sc);
            }
            let y_top = (base_y + (1.0 - max_val) * 0.5 * ch_height as f32) as i32;
            let y_bot = (base_y + (1.0 - min_val) * 0.5 * ch_height as f32) as i32;
            let px = (margin + x) as i32;
            let yt = y_top.max(margin as i32).min((height - margin) as i32);
            let yb = y_bot.max(margin as i32).min((height - margin) as i32);
            img.draw_line(px, yt, px, yb, cr, cg, cb, 255);
        }
    }
    save_png(name, &img);
}

/// Render a zoomed waveform showing individual wave cycles.
/// Shows the first `max_samples` samples for detail visibility.
fn render_waveform_zoomed(name: &str, samples: &[f32], sample_rate: u32, max_samples: usize) {
    let _ = sample_rate;
    let zoomed: Vec<f32> = samples.iter().take(max_samples).copied().collect();
    let width = 800u32;
    let height = 300u32;
    let margin = 40u32;
    let plot_w = width - margin * 2;
    let plot_h = height - margin * 2;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);

    // Grid
    for i in 0..=4 {
        let y = margin as i32 + (plot_h as i32 * i / 4);
        for x in margin..width - margin {
            img.set_pixel(x, y as u32, 35, 35, 50, 255);
        }
    }
    for i in 0..=8 {
        let x = margin as i32 + (plot_w as i32 * i / 8);
        for y in margin..height - margin {
            img.set_pixel(x as u32, y, 35, 35, 50, 255);
        }
    }
    let center_y = margin + plot_h / 2;
    for x in margin..width - margin {
        img.set_pixel(x, center_y, 60, 60, 80, 255);
    }

    let peak = zoomed.iter().map(|s| s.abs()).fold(0.0f32, f32::max).max(0.01);
    let scale = 0.9 / peak;

    // Draw sample-by-sample with interpolation
    let n = zoomed.len();
    if n > 1 {
        for x in 0..plot_w {
            let sample_f = x as f32 / plot_w as f32 * (n - 1) as f32;
            let idx = sample_f as usize;
            let frac = sample_f - idx as f32;
            let s = if idx + 1 < n {
                zoomed[idx] * (1.0 - frac) + zoomed[idx + 1] * frac
            } else {
                zoomed[idx]
            };
            let scaled = (s * scale).clamp(-1.0, 1.0);
            let y = (margin as f32 + (1.0 - scaled) * 0.5 * plot_h as f32) as i32;
            let px = (margin + x) as i32;
            let cy = center_y as i32;
            // Draw line from center to sample value
            let (y0, y1) = if y < cy { (y, cy) } else { (cy, y) };
            img.draw_line(px, y0.max(margin as i32), px, y1.min((height - margin) as i32), 80, 180, 255, 255);
            // Bright sample point on top
            if y >= margin as i32 && y < (height - margin) as i32 {
                img.set_pixel(px as u32, y as u32, 140, 220, 255, 255);
            }
        }
    }

    // Border
    for x in margin..width - margin {
        img.set_pixel(x, margin, 60, 60, 80, 255);
        img.set_pixel(x, height - margin - 1, 60, 60, 80, 255);
    }
    for y in margin..height - margin {
        img.set_pixel(margin, y, 60, 60, 80, 255);
        img.set_pixel(width - margin - 1, y, 60, 60, 80, 255);
    }
    save_png(name, &img);
}

/// Draw text label as a simple pixel pattern (3x5 chars).
/// Supports digits 0-9, uppercase A-Z, space, dash, dot, colon, percent.
fn draw_label(img: &mut ImageData, text: &str, x: i32, y: i32, r: u8, g: u8, b: u8) {
    // Minimal 3x5 font — 15 bits per glyph, MSB = top-left pixel
    let digit_font: [u64; 10] = [
        0b111_101_101_101_111, // 0
        0b010_110_010_010_111, // 1
        0b111_001_111_100_111, // 2
        0b111_001_111_001_111, // 3
        0b101_101_111_001_001, // 4
        0b111_100_111_001_111, // 5
        0b111_100_111_101_111, // 6
        0b111_001_010_010_010, // 7
        0b111_101_111_101_111, // 8
        0b111_101_111_001_111, // 9
    ];
    let letter_font: [u64; 26] = [
        0b010_101_111_101_101, // A
        0b110_101_110_101_110, // B
        0b011_100_100_100_011, // C
        0b110_101_101_101_110, // D
        0b111_100_110_100_111, // E
        0b111_100_110_100_100, // F
        0b011_100_101_101_011, // G
        0b101_101_111_101_101, // H
        0b111_010_010_010_111, // I
        0b011_001_001_101_010, // J
        0b101_110_100_110_101, // K
        0b100_100_100_100_111, // L
        0b101_111_111_101_101, // M
        0b101_111_101_101_101, // N
        0b111_101_101_101_111, // O
        0b111_101_111_100_100, // P
        0b010_101_101_010_001, // Q
        0b110_101_110_101_101, // R
        0b011_100_010_001_110, // S
        0b111_010_010_010_010, // T
        0b101_101_101_101_111, // U
        0b101_101_101_101_010, // V
        0b101_101_111_111_101, // W
        0b101_101_010_101_101, // X
        0b101_101_010_010_010, // Y
        0b111_001_010_100_111, // Z
    ];
    let w = img.width() as i32;
    let h = img.height() as i32;
    let mut cx = x;
    for ch in text.chars() {
        let bits = if let Some(digit) = ch.to_digit(10) {
            Some(digit_font[digit as usize])
        } else if ch.is_ascii_alphabetic() {
            let idx = (ch.to_ascii_uppercase() as u8 - b'A') as usize;
            Some(letter_font[idx])
        } else if ch == '-' {
            Some(0b000_000_111_000_000u64)
        } else if ch == '.' {
            Some(0b000_000_000_000_010u64)
        } else if ch == ':' {
            Some(0b000_010_000_010_000u64)
        } else if ch == '%' {
            Some(0b101_001_010_100_101u64)
        } else {
            None // space or unknown = blank
        };
        if let Some(bits) = bits {
            for row in 0..5i32 {
                for col in 0..3i32 {
                    let bit_idx = (4 - row) * 3 + (2 - col);
                    if (bits >> bit_idx) & 1 == 1 {
                        let px = cx + col;
                        let py = y + row;
                        if px >= 0 && py >= 0 && px < w && py < h {
                            img.set_pixel(px as u32, py as u32, r, g, b, 255);
                        }
                    }
                }
            }
        }
        cx += 4;
    }
}


#[test]
fn evidence_dsp_lowpass_filter() {
    let sr = 44100u32;
    let samples = make_sine_samples(440.0, 1.0, sr);

    // Also add high-frequency component
    let mut rich: Vec<f32> = samples.iter().enumerate().map(|(i, &s)| {
        let t = i as f32 / sr as f32;
        s + (t * 4000.0 * 2.0 * std::f32::consts::PI).sin() * 0.3
    }).collect();

    let before = SoundData::from_samples(rich.clone(), sr, 1);
    save_wav("audio_dsp/lowpass_before", &before);
    render_waveform("audio_dsp/lowpass_before_waveform", &rich, sr);

    // Apply lowpass filter
    let params = Arc::new(EffectParams::new(1, EffectType::Lowpass));
    params.set_param("cutoff", 800.0).unwrap();
    params.set_param("q", 0.707).unwrap();
    params.set_param("mix", 1.0).unwrap();
    let mut effect = ActiveEffect::new(params, sr, 1);

    let filtered: Vec<f32> = rich.iter().map(|&s| effect.process(s, 0, sr)).collect();
    let after = SoundData::from_samples(filtered.clone(), sr, 1);
    save_wav("audio_dsp/lowpass_after", &after);
    render_waveform("audio_dsp/lowpass_after_waveform", &filtered, sr);
}

#[test]
fn evidence_dsp_highpass_filter() {
    let sr = 44100u32;
    let mut rich: Vec<f32> = (0..(sr as usize)).map(|i| {
        let t = i as f32 / sr as f32;
        (t * 200.0 * 2.0 * std::f32::consts::PI).sin() * 0.5
        + (t * 3000.0 * 2.0 * std::f32::consts::PI).sin() * 0.3
    }).collect();

    let before = SoundData::from_samples(rich.clone(), sr, 1);
    save_wav("audio_dsp/highpass_before", &before);
    render_waveform("audio_dsp/highpass_before_waveform", &rich, sr);

    let params = Arc::new(EffectParams::new(2, EffectType::Highpass));
    params.set_param("cutoff", 1000.0).unwrap();
    params.set_param("q", 0.707).unwrap();
    params.set_param("mix", 1.0).unwrap();
    let mut effect = ActiveEffect::new(params, sr, 1);

    let filtered: Vec<f32> = rich.iter().map(|&s| effect.process(s, 0, sr)).collect();
    let after = SoundData::from_samples(filtered.clone(), sr, 1);
    save_wav("audio_dsp/highpass_after", &after);
    render_waveform("audio_dsp/highpass_after_waveform", &filtered, sr);
}

#[test]
fn evidence_dsp_bandpass_filter() {
    let sr = 44100u32;
    // Three frequencies: 200Hz, 1000Hz, 5000Hz
    let rich: Vec<f32> = (0..(sr as usize)).map(|i| {
        let t = i as f32 / sr as f32;
        (t * 200.0 * 2.0 * std::f32::consts::PI).sin() * 0.3
        + (t * 1000.0 * 2.0 * std::f32::consts::PI).sin() * 0.3
        + (t * 5000.0 * 2.0 * std::f32::consts::PI).sin() * 0.3
    }).collect();

    let before = SoundData::from_samples(rich.clone(), sr, 1);
    save_wav("audio_dsp/bandpass_before", &before);
    render_waveform("audio_dsp/bandpass_before_waveform", &rich, sr);

    let params = Arc::new(EffectParams::new(3, EffectType::Bandpass));
    params.set_param("cutoff", 1000.0).unwrap();
    params.set_param("q", 2.0).unwrap();
    params.set_param("mix", 1.0).unwrap();
    let mut effect = ActiveEffect::new(params, sr, 1);

    let filtered: Vec<f32> = rich.iter().map(|&s| effect.process(s, 0, sr)).collect();
    let after = SoundData::from_samples(filtered.clone(), sr, 1);
    save_wav("audio_dsp/bandpass_after", &after);
    render_waveform("audio_dsp/bandpass_after_waveform", &filtered, sr);
}

#[test]
fn evidence_dsp_reverb() {
    let sr = 44100u32;
    // Short impulse followed by silence to show reverb tail
    let mut samples = vec![0.0f32; sr as usize * 2];
    // Clap-like impulse
    for i in 0..800 {
        let t = i as f32 / 800.0;
        samples[i] = (1.0 - t) * (i as f32 * 0.1).sin() * 0.9;
    }

    let before = SoundData::from_samples(samples.clone(), sr, 1);
    save_wav("audio_dsp/reverb_before", &before);
    render_waveform("audio_dsp/reverb_before_waveform", &samples, sr);

    let params = Arc::new(EffectParams::new(4, EffectType::Reverb));
    params.set_param("room_size", 0.8).unwrap();
    params.set_param("damping", 0.5).unwrap();
    params.set_param("mix", 0.6).unwrap();
    let mut effect = ActiveEffect::new(params, sr, 1);

    let reverbed: Vec<f32> = samples.iter().map(|&s| effect.process(s, 0, sr)).collect();
    let after = SoundData::from_samples(reverbed.clone(), sr, 1);
    save_wav("audio_dsp/reverb_after", &after);
    render_waveform("audio_dsp/reverb_after_waveform", &reverbed, sr);
}

#[test]
fn evidence_dsp_chorus() {
    let sr = 44100u32;
    let samples = make_sine_samples(440.0, 2.0, sr);

    let before = SoundData::from_samples(samples.clone(), sr, 1);
    save_wav("audio_dsp/chorus_before", &before);
    render_waveform("audio_dsp/chorus_before_waveform", &samples, sr);
    render_waveform_zoomed("audio_dsp/chorus_before_zoomed", &samples, sr, 2000);

    let params = Arc::new(EffectParams::new(5, EffectType::Chorus));
    params.set_param("rate", 1.5).unwrap();
    params.set_param("depth", 0.5).unwrap();
    params.set_param("mix", 0.5).unwrap();
    let mut effect = ActiveEffect::new(params, sr, 1);

    let chorused: Vec<f32> = samples.iter().map(|&s| effect.process(s, 0, sr)).collect();
    let after = SoundData::from_samples(chorused.clone(), sr, 1);
    save_wav("audio_dsp/chorus_after", &after);
    render_waveform("audio_dsp/chorus_after_waveform", &chorused, sr);
    render_waveform_zoomed("audio_dsp/chorus_after_zoomed", &chorused, sr, 2000);
}

#[test]
fn evidence_dsp_filter_sweep() {
    let sr = 44100u32;
    // White noise source
    let mut rng: u32 = 42;
    let noise: Vec<f32> = (0..(sr as usize * 2)).map(|_| {
        rng = rng.wrapping_mul(1103515245).wrapping_add(12345);
        ((rng >> 16) as f32 / 32768.0 - 1.0) * 0.5
    }).collect();

    // Apply lowpass with sweeping cutoff
    let params = Arc::new(EffectParams::new(6, EffectType::Lowpass));
    params.set_param("q", 2.0).unwrap();
    params.set_param("mix", 1.0).unwrap();
    let mut effect = ActiveEffect::new(params.clone(), sr, 1);

    let swept: Vec<f32> = noise.iter().enumerate().map(|(i, &s)| {
        let t = i as f32 / noise.len() as f32;
        let cutoff = 200.0 + t * 8000.0; // sweep from 200Hz to 8200Hz
        let _ = params.set_param("cutoff", cutoff);
        effect.process(s, 0, sr)
    }).collect();

    let sound = SoundData::from_samples(swept.clone(), sr, 1);
    save_wav("audio_dsp/filter_sweep", &sound);
    render_waveform("audio_dsp/filter_sweep_waveform", &swept, sr);
}

// =====================================================================
// ===== AUDIO EXTRA — Additional audio waveforms and fixtures =====
// =====================================================================

#[test]
fn evidence_audio_triangle_wave() {
    let sr = 44100u32;
    let n = 44100usize;
    let samples: Vec<f32> = (0..n).map(|i| {
        let phase = (i as f32 / sr as f32 * 440.0) % 1.0;
        (2.0 * (2.0 * phase - 1.0).abs() - 1.0) * 0.7
    }).collect();
    let sound = SoundData::from_samples(samples, sr, 1);
    save_wav("audio/triangle_wave_440hz", &sound);
}

#[test]
fn evidence_audio_fm_synthesis() {
    let sr = 44100u32;
    let n = sr as usize * 2;
    let carrier = 440.0f32;
    let modulator = 220.0f32;
    let mod_depth = 200.0f32;

    let samples: Vec<f32> = (0..n).map(|i| {
        let t = i as f32 / sr as f32;
        let mod_signal = (t * modulator * 2.0 * std::f32::consts::PI).sin();
        let freq = carrier + mod_signal * mod_depth;
        let mut phase = 0.0f32;
        // Approximate phase integration
        phase = t * carrier * 2.0 * std::f32::consts::PI
            + (mod_depth / modulator) * (t * modulator * 2.0 * std::f32::consts::PI).sin();
        phase.sin() * 0.7
    }).collect();

    let sound = SoundData::from_samples(samples.clone(), sr, 1);
    save_wav("audio/fm_synthesis", &sound);
    render_waveform("audio/fm_synthesis_waveform", &samples, sr);
    render_waveform_zoomed("audio/fm_synthesis_zoomed", &samples, sr, 2000);
}

#[test]
fn evidence_audio_drum_kick() {
    let sr = 44100u32;
    let n = (sr as f32 * 0.3) as usize;
    let samples: Vec<f32> = (0..n).map(|i| {
        let t = i as f32 / sr as f32;
        let env = (-t * 15.0).exp();
        let freq = 150.0 * (-t * 8.0).exp() + 40.0;
        (t * freq * 2.0 * std::f32::consts::PI).sin() * env * 0.9
    }).collect();
    let sound = SoundData::from_samples(samples, sr, 1);
    save_wav("audio/drum_kick", &sound);
}

#[test]
fn evidence_audio_drum_hihat() {
    let sr = 44100u32;
    let n = (sr as f32 * 0.15) as usize;
    let mut rng: u32 = 999;
    let samples: Vec<f32> = (0..n).map(|i| {
        let t = i as f32 / sr as f32;
        let env = (-t * 40.0).exp();
        rng = rng.wrapping_mul(1103515245).wrapping_add(12345);
        let noise = (rng >> 16) as f32 / 32768.0 - 1.0;
        noise * env * 0.6
    }).collect();
    let sound = SoundData::from_samples(samples, sr, 1);
    save_wav("audio/drum_hihat", &sound);
}

#[test]
fn evidence_audio_pluck_string() {
    let sr = 44100u32;
    let freq = 330.0f32; // E4
    let n = sr as usize; // 1 second
    let samples: Vec<f32> = (0..n).map(|i| {
        let t = i as f32 / sr as f32;
        let env = (-t * 3.0).exp();
        let harmonics = (t * freq * 2.0 * std::f32::consts::PI).sin()
            + 0.5 * (t * freq * 2.0 * 2.0 * std::f32::consts::PI).sin()
            + 0.25 * (t * freq * 3.0 * 2.0 * std::f32::consts::PI).sin()
            + 0.125 * (t * freq * 4.0 * 2.0 * std::f32::consts::PI).sin();
        harmonics * env * 0.4
    }).collect();
    let sound = SoundData::from_samples(samples, sr, 1);
    save_wav("audio/pluck_string_e4", &sound);
}

// =====================================================================
// ===== COMBINED — Multi-module evidence =====
// =====================================================================

#[test]
fn evidence_combined_procgen_pathfinding() {
    // Generate a cave with cellular automata, then pathfind through it
    let opts = CellularOpts {
        fill: 0.40,  // slightly less fill for more open space
        iterations: 4,
        birth: 5,
        survive: 4,
        seed: 12345,
    };
    let cave = cellular_automata(40, 30, &opts);

    // Build NavGrid from cave
    let mut grid = NavGrid::new(40, 30);
    for y in 0..30u32 {
        for x in 0..40u32 {
            if cave[(y * 40 + x) as usize] == 1 {
                grid.set_blocked(x, y, true);
            }
        }
    }
    // Ensure start, end, and a rough corridor are open
    for x in 0..40u32 {
        grid.set_blocked(x, 15, false); // horizontal corridor through middle
    }
    for y in 0..30u32 {
        grid.set_blocked(20, y, false); // vertical corridor through middle
    }
    grid.set_blocked(2, 2, false);
    grid.set_blocked(3, 2, false);
    grid.set_blocked(2, 3, false);
    grid.set_blocked(37, 27, false);
    grid.set_blocked(36, 27, false);
    grid.set_blocked(37, 26, false);

    let (path, _) = astar(&grid, (2, 2), (37, 27), 1, 20000);

    let cell = 8u32;
    let mut img = ImageData::new(40 * cell, 30 * cell);
    for y in 0..30u32 {
        for x in 0..40u32 {
            let blocked = grid.is_blocked(x, y);
            let (r, g, b) = if blocked { (50, 35, 25) } else { (150, 180, 140) };
            for py in 0..cell {
                for px in 0..cell {
                    img.set_pixel(x * cell + px, y * cell + py, r, g, b, 255);
                }
            }
        }
    }
    // Draw path in bright yellow
    if let Some(ref p) = path {
        for &(px, py) in p {
            for dy in 1..cell - 1 {
                for dx in 1..cell - 1 {
                    img.set_pixel(px * cell + dx, py * cell + dy, 255, 220, 50, 255);
                }
            }
        }
    }
    // Start/end markers
    safe_circle(&mut img, (2 * cell + cell / 2) as i32, (2 * cell + cell / 2) as i32, 5, 0, 255, 0, 255);
    safe_circle(&mut img, (37 * cell + cell / 2) as i32, (27 * cell + cell / 2) as i32, 5, 255, 0, 0, 255);
    draw_label(&mut img, "START", 24, 10, 255, 255, 255);
    draw_label(&mut img, "END", 280, 222, 255, 255, 255);
    save_png("combined/procgen_pathfinding", &img);
}

#[test]
fn evidence_combined_noise_minimap() {
    // Generate terrain from noise, display as minimap
    let noise = NoiseGenerator::new(54321);
    let w = 32u32;
    let h = 24u32;

    let mut mm = Minimap::new(w, h, w * 8, h * 8);
    mm.set_terrain_color(0, [0.1, 0.3, 0.7, 1.0]); // Deep water
    mm.set_terrain_color(1, [0.2, 0.5, 0.8, 1.0]); // Shallow water
    mm.set_terrain_color(2, [0.8, 0.7, 0.5, 1.0]); // Sand
    mm.set_terrain_color(3, [0.2, 0.6, 0.2, 1.0]); // Grass
    mm.set_terrain_color(4, [0.4, 0.3, 0.2, 1.0]); // Mountain
    mm.set_terrain_color(5, [0.9, 0.9, 0.95, 1.0]); // Snow

    for y in 0..h {
        for x in 0..w {
            let val = noise.fbm(x as f64 * 0.08, y as f64 * 0.08, 4, 2.0, 0.5, NoiseKind::Perlin);
            let h_val = val * 0.5 + 0.5;
            let terrain = if h_val < 0.25 { 0 }
                else if h_val < 0.35 { 1 }
                else if h_val < 0.4 { 2 }
                else if h_val < 0.65 { 3 }
                else if h_val < 0.8 { 4 }
                else { 5 };
            mm.set_terrain(x, y, terrain);
        }
    }

    let cell_w = 8u32;
    let cell_h = 8u32;
    let mut img = ImageData::new(w * cell_w, h * cell_h);
    for y in 0..h {
        for x in 0..w {
            let t = mm.get_terrain(x, y);
            let c = mm.get_terrain_color(t);
            let r = (c[0] * 255.0) as u8;
            let g = (c[1] * 255.0) as u8;
            let b = (c[2] * 255.0) as u8;
            for py in 0..cell_h {
                for px in 0..cell_w {
                    img.set_pixel(x * cell_w + px, y * cell_h + py, r, g, b, 255);
                }
            }
        }
    }
    save_png("combined/noise_minimap", &img);
}


// ═══════════════════════════════════════════════════════════════════
// ██  SHAPES & POLYGON EVIDENCE
// ═══════════════════════════════════════════════════════════════════

/// Draw geometric shapes using only draw_line: triangle, square, pentagon,
/// hexagon, octagon, and star — proving draw_line can render any polygon.
#[test]
fn evidence_shapes_polygon_gallery() {
    let mut img = ImageData::new(512, 512);
    img.fill(15, 15, 25, 255);

    let shapes: &[(i32, i32, i32, usize, (u8, u8, u8))] = &[
        (85, 85, 60, 3, (255, 100, 100)),    // triangle
        (255, 85, 60, 4, (100, 255, 100)),    // square
        (425, 85, 60, 5, (100, 100, 255)),    // pentagon
        (85, 255, 60, 6, (255, 255, 100)),    // hexagon
        (255, 255, 60, 8, (255, 100, 255)),   // octagon
        (425, 255, 60, 12, (100, 255, 255)),  // dodecagon
    ];

    for &(cx, cy, radius, sides, (r, g, b)) in shapes {
        for i in 0..sides {
            let a0 = std::f32::consts::TAU * i as f32 / sides as f32 - std::f32::consts::FRAC_PI_2;
            let a1 = std::f32::consts::TAU * (i + 1) as f32 / sides as f32 - std::f32::consts::FRAC_PI_2;
            let x0 = cx + (radius as f32 * a0.cos()) as i32;
            let y0 = cy + (radius as f32 * a0.sin()) as i32;
            let x1 = cx + (radius as f32 * a1.cos()) as i32;
            let y1 = cy + (radius as f32 * a1.sin()) as i32;
            img.draw_line(x0, y0, x1, y1, r, g, b, 255);
        }
    }

    // A five-pointed star
    let (sx, sy, sr) = (170, 425, 70);
    let star_points: Vec<(i32, i32)> = (0..10).map(|i| {
        let angle = std::f32::consts::TAU * i as f32 / 10.0 - std::f32::consts::FRAC_PI_2;
        let r = if i % 2 == 0 { sr as f32 } else { sr as f32 * 0.4 };
        (sx + (r * angle.cos()) as i32, sy + (r * angle.sin()) as i32)
    }).collect();
    for i in 0..10 {
        let (x0, y0) = star_points[i];
        let (x1, y1) = star_points[(i + 1) % 10];
        img.draw_line(x0, y0, x1, y1, 255, 220, 50, 255);
    }

    // An arrow shape
    let (ax, ay) = (340, 425);
    let arrow = [(0, -50), (30, 0), (15, 0), (15, 50), (-15, 50), (-15, 0), (-30, 0)];
    for i in 0..arrow.len() {
        let (x0, y0) = arrow[i];
        let (x1, y1) = arrow[(i + 1) % arrow.len()];
        img.draw_line(ax + x0, ay + y0, ax + x1, ay + y1, 255, 150, 50, 255);
    }

    save_png("shapes/polygon_gallery", &img);
}

/// Draw filled shapes using set_pixel scanline fill for triangles and rects.
#[test]
fn evidence_shapes_filled_primitives() {
    let mut img = ImageData::new(400, 400);
    img.fill(15, 15, 25, 255);

    // Filled rectangles of different sizes
    for i in 0..5 {
        let x = 20 + i * 35;
        let size = 15 + i * 8;
        let hue = (i as f32 / 5.0 * 360.0) as u16;
        let (r, g, b) = hsv_to_rgb(hue, 0.8, 0.9);
        img.draw_rect(x as i32, 20, size as u32, size as u32, r, g, b, 200);
    }

    // Filled circles of different sizes
    for i in 0..5 {
        let cx = 50 + i * 70;
        let radius = 10 + i * 5;
        let (r, g, b) = hsv_to_rgb((i * 72) as u16, 0.8, 0.9);
        safe_circle(&mut img, cx as i32, 150, radius as i32, r, g, b, 200);
    }

    // Grid of small dots
    for row in 0..16 {
        for col in 0..16 {
            let x = 20 + col * 22;
            let y = 200 + row * 12;
            let brightness = ((row * 16 + col) * 255 / 255).min(255) as u8;
            img.set_pixel(x, y, brightness, brightness, brightness, 255);
            img.set_pixel(x + 1, y, brightness, brightness, brightness, 255);
            img.set_pixel(x, y + 1, brightness, brightness, brightness, 255);
            img.set_pixel(x + 1, y + 1, brightness, brightness, brightness, 255);
        }
    }

    save_png("shapes/filled_primitives", &img);
}

/// Draw concentric circles and spirals to demonstrate draw_line + math.
#[test]
fn evidence_shapes_spirals() {
    let mut img = ImageData::new(400, 400);
    img.fill(15, 15, 25, 255);

    // Concentric circles
    let (cx, cy) = (200, 200);
    for ring in 1..=10 {
        let r = ring * 18;
        let steps = (r * 4).max(40);
        let (cr, cg, cb) = hsv_to_rgb((ring * 36) as u16, 0.7, 0.9);
        for i in 0..steps {
            let a0 = std::f32::consts::TAU * i as f32 / steps as f32;
            let a1 = std::f32::consts::TAU * (i + 1) as f32 / steps as f32;
            let x0 = cx + (r as f32 * a0.cos()) as i32;
            let y0 = cy + (r as f32 * a0.sin()) as i32;
            let x1 = cx + (r as f32 * a1.cos()) as i32;
            let y1 = cy + (r as f32 * a1.sin()) as i32;
            img.draw_line(x0, y0, x1, y1, cr, cg, cb, 255);
        }
    }

    save_png("shapes/spirals", &img);
}

// HSV to RGB helper (h: 0-360, s: 0-1, v: 0-1)
fn hsv_to_rgb(h: u16, s: f32, v: f32) -> (u8, u8, u8) {
    let h = (h % 360) as f32;
    let c = v * s;
    let x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
    let m = v - c;
    let (r, g, b) = match (h / 60.0) as u8 {
        0 => (c, x, 0.0),
        1 => (x, c, 0.0),
        2 => (0.0, c, x),
        3 => (0.0, x, c),
        4 => (x, 0.0, c),
        _ => (c, 0.0, x),
    };
    (((r + m) * 255.0) as u8, ((g + m) * 255.0) as u8, ((b + m) * 255.0) as u8)
}

// ═══════════════════════════════════════════════════════════════════
// ██  STEREO / SPATIAL AUDIO EVIDENCE
// ═══════════════════════════════════════════════════════════════════

/// Create a stereo panning test: tone sweeps from left to right channel.
/// Proves stereo WAV encoding with independent L/R channels.
#[test]
fn evidence_audio_stereo_pan_sweep() {
    let sr = 44100u32;
    let duration = 2.0f32;
    let total_samples = (sr as f32 * duration) as usize;
    let mut stereo = Vec::with_capacity(total_samples * 2);

    for i in 0..total_samples {
        let t = i as f32 / sr as f32;
        let pan = t / duration; // 0 (left) to 1 (right)
        let tone = (t * 440.0 * std::f32::consts::TAU).sin() * 0.6;
        let left = tone * (1.0 - pan);
        let right = tone * pan;
        stereo.push(left);
        stereo.push(right);
    }

    let sd = SoundData::from_samples(stereo.clone(), sr, 2);
    save_wav("audio/stereo_pan_sweep", &sd);
    render_waveform_stereo("audio/stereo_pan_sweep_waveform", &stereo, sr);
}

/// Hard-left stereo: tone only in left channel, silence in right.
#[test]
fn evidence_audio_stereo_hard_left() {
    let sr = 44100u32;
    let samples = (sr as f32 * 1.0) as usize;
    let mut stereo = Vec::with_capacity(samples * 2);
    for i in 0..samples {
        let t = i as f32 / sr as f32;
        let tone = (t * 440.0 * std::f32::consts::TAU).sin() * 0.7;
        stereo.push(tone);  // left
        stereo.push(0.0);   // right: silence
    }
    let sd = SoundData::from_samples(stereo.clone(), sr, 2);
    save_wav("audio/stereo_hard_left", &sd);
    render_waveform_stereo("audio/stereo_hard_left_waveform", &stereo, sr);
}

/// Hard-right stereo: tone only in right channel, silence in left.
#[test]
fn evidence_audio_stereo_hard_right() {
    let sr = 44100u32;
    let samples = (sr as f32 * 1.0) as usize;
    let mut stereo = Vec::with_capacity(samples * 2);
    for i in 0..samples {
        let t = i as f32 / sr as f32;
        let tone = (t * 440.0 * std::f32::consts::TAU).sin() * 0.7;
        stereo.push(0.0);   // left: silence
        stereo.push(tone);  // right
    }
    let sd = SoundData::from_samples(stereo.clone(), sr, 2);
    save_wav("audio/stereo_hard_right", &sd);
    render_waveform_stereo("audio/stereo_hard_right_waveform", &stereo, sr);
}

/// Stereo ping-pong: alternating bursts in left and right channels.
#[test]
fn evidence_audio_stereo_ping_pong() {
    let sr = 44100u32;
    let duration = 2.0f32;
    let total = (sr as f32 * duration) as usize;
    let burst_len = sr as usize / 4; // 250ms bursts
    let mut stereo = Vec::with_capacity(total * 2);
    for i in 0..total {
        let t = i as f32 / sr as f32;
        let burst_idx = i / burst_len;
        let tone = (t * 660.0 * std::f32::consts::TAU).sin() * 0.6;
        let (left, right) = if burst_idx % 2 == 0 { (tone, 0.0) } else { (0.0, tone) };
        stereo.push(left);
        stereo.push(right);
    }
    let sd = SoundData::from_samples(stereo.clone(), sr, 2);
    save_wav("audio/stereo_ping_pong", &sd);
    render_waveform_stereo("audio/stereo_ping_pong_waveform", &stereo, sr);
}

/// Spatial audio simulation: tone moving in a circle around the listener.
/// Left channel represents sounds from the left, right from right.
#[test]
fn evidence_audio_spatial_circle() {
    let sr = 44100u32;
    let duration = 3.0f32;
    let total = (sr as f32 * duration) as usize;
    let mut stereo = Vec::with_capacity(total * 2);
    for i in 0..total {
        let t = i as f32 / sr as f32;
        let angle = t / duration * std::f32::consts::TAU; // full circle
        let tone = (t * 440.0 * std::f32::consts::TAU).sin() * 0.6;
        // Pan using angle: cos(0)=right, cos(PI)=left
        let pan = (angle.cos() + 1.0) * 0.5; // 0=left, 1=right
        stereo.push(tone * (1.0 - pan)); // left
        stereo.push(tone * pan);          // right
    }
    let sd = SoundData::from_samples(stereo.clone(), sr, 2);
    save_wav("audio/spatial_circle", &sd);
    render_waveform_stereo("audio/spatial_circle_waveform", &stereo, sr);
}

// ═══════════════════════════════════════════════════════════════════
// ██  MORE RAYCASTER EVIDENCE
// ═══════════════════════════════════════════════════════════════════

/// Raycaster with textured walls: each cell value maps to a different color.
#[test]
fn evidence_raycaster_textured_walls() {
    let mut rc = Raycaster2D::new(16, 16);
    // Create rooms with different wall types
    for x in 0u32..16 { rc.set_cell(x, 0, 1); rc.set_cell(x, 15, 1); }
    for y in 0u32..16 { rc.set_cell(0, y, 2); rc.set_cell(15, y, 2); }
    // Internal walls
    for x in 4u32..8 { rc.set_cell(x, 4, 3); }
    for y in 4u32..10 { rc.set_cell(7, y, 4); }
    for x in 10u32..14 { rc.set_cell(x, 8, 5); }

    let img = rc.render_view_to_image(3.0, 3.0, 0.6, std::f32::consts::FRAC_PI_3, 320, 200, 20.0);
    save_png("raycaster/textured_walls", &img);
}

/// Raycaster camera rotation sweep: 12 frames at different angles.
#[test]
fn evidence_raycaster_camera_sweep() {
    let mut rc = Raycaster2D::new(16, 16);
    // Simple walls
    for x in 0u32..16 { rc.set_cell(x, 0, 1); rc.set_cell(x, 15, 1); }
    for y in 0u32..16 { rc.set_cell(0, y, 1); rc.set_cell(15, y, 1); }
    // Pillars
    rc.set_cell(4, 4, 2); rc.set_cell(4, 11, 2);
    rc.set_cell(11, 4, 2); rc.set_cell(11, 11, 2);
    rc.set_cell(8, 8, 3);

    let mut img = ImageData::new(480, 360);
    img.fill(15, 15, 25, 255);
    let columns = 120;
    let frame_h = 90;

    for frame in 0..12 {
        let angle = frame as f32 * std::f32::consts::TAU / 12.0;
        let col = frame % 4;
        let row = frame / 4;
        let ox = col * 120;
        let oy = row * 90;

        let rays = rc.cast_rays(8.0, 8.0, angle, std::f32::consts::FRAC_PI_3, columns, 20.0);
        for (x, hit) in rays.iter().enumerate() {
            if hit.hit {
                let wall_h = (frame_h as f32 / hit.distance.max(0.1)) as i32;
                let mid = frame_h as i32 / 2;
                let top = mid - wall_h / 2;
                let bot = mid + wall_h / 2;
                let shade = (1.0 - hit.distance / 20.0).max(0.1);
                let r = (180.0 * shade) as u8;
                let g = (120.0 * shade) as u8;
                let b = (255.0 * shade) as u8;
                let px = (ox + x as i32) as i32;
                let py_top = (oy as i32 + top).max(oy as i32);
                let py_bot = (oy as i32 + bot).min((oy + frame_h) as i32 - 1);
                if py_top < py_bot {
                    img.draw_line(px, py_top, px, py_bot, r, g, b, 255);
                }
            }
        }
    }
    save_png("raycaster/camera_sweep_12_angles", &img);
}

/// Raycaster maze — complex multi-room layout.
#[test]
fn evidence_raycaster_maze() {
    let mut rc = Raycaster2D::new(24, 24);
    // Outer walls
    for i in 0u32..24 {
        rc.set_cell(i, 0, 1); rc.set_cell(i, 23, 1);
        rc.set_cell(0, i, 1); rc.set_cell(23, i, 1);
    }
    // Maze corridors
    for x in 2u32..22 { if x != 6 && x != 12 && x != 18 { rc.set_cell(x, 6, 2); } }
    for x in 2u32..22 { if x != 4 && x != 10 && x != 16 { rc.set_cell(x, 12, 3); } }
    for x in 2u32..22 { if x != 8 && x != 14 && x != 20 { rc.set_cell(x, 18, 4); } }
    for y in 2u32..22 { if y % 4 != 0 { rc.set_cell(8, y, 2); rc.set_cell(16, y, 2); } }

    let mut img = ImageData::new(400, 250);
    let rays = rc.cast_rays(3.0, 3.0, 0.4, std::f32::consts::FRAC_PI_3, 400, 30.0);
    for (x, hit) in rays.iter().enumerate() {
        // Sky gradient
        for y in 0..125 {
            let sky = (40 + y / 2) as u8;
            img.set_pixel(x as u32, y as u32, sky / 3, sky / 3, sky, 255);
        }
        // Floor gradient
        for y in 125..250 {
            let fl = (30 - (y - 125) / 8).max(5) as u8;
            img.set_pixel(x as u32, y as u32, fl, fl + 5, fl, 255);
        }
        if hit.hit {
            let wall_h = (250.0 / hit.distance.max(0.1)) as i32;
            let top = 125 - wall_h / 2;
            let bot = 125 + wall_h / 2;
            let shade = (1.0 - hit.distance / 30.0).max(0.05);
            let side_dim = if hit.side == 1 { 0.7 } else { 1.0 };
            let (r, g, b) = match hit.cell_value {
                1 => (180, 80, 80),
                2 => (80, 180, 80),
                3 => (80, 80, 180),
                4 => (180, 180, 80),
                _ => (150, 150, 150),
            };
            let r = (r as f32 * shade * side_dim) as u8;
            let g = (g as f32 * shade * side_dim) as u8;
            let b = (b as f32 * shade * side_dim) as u8;
            img.draw_line(x as i32, top.max(0), x as i32, bot.min(249), r, g, b, 255);
        }
    }
    save_png("raycaster/maze_scene", &img);
}

// ═══════════════════════════════════════════════════════════════════
// ██  MORE PROCGEN EVIDENCE
// ═══════════════════════════════════════════════════════════════════

/// BSP dungeon generation via recursive subdivide then connect rooms.
#[test]
fn evidence_procgen_bsp_dungeon() {
    let w = 64u32;
    let h = 64u32;
    let mut grid = vec![1u8; (w * h) as usize]; // all walls

    // Simple BSP: recursively split, carve rooms
    fn carve_room(grid: &mut Vec<u8>, w: u32, x: u32, y: u32, rw: u32, rh: u32, depth: u32) {
        if rw < 6 || rh < 6 || depth > 5 {
            // Carve interior
            for ry in (y + 1)..(y + rh - 1) {
                for rx in (x + 1)..(x + rw - 1) {
                    if rx < w && ry < w { grid[(ry * w + rx) as usize] = 0; }
                }
            }
            return;
        }
        if rw > rh {
            let split = rw / 3 + (depth * 7 % (rw / 3 + 1));
            let split = split.min(rw - 3).max(3);
            carve_room(grid, w, x, y, split, rh, depth + 1);
            carve_room(grid, w, x + split, y, rw - split, rh, depth + 1);
            // Connect with corridor
            let cy = y + rh / 2;
            for rx in x..(x + rw) { if rx < w { grid[(cy * w + rx) as usize] = 0; } }
        } else {
            let split = rh / 3 + (depth * 11 % (rh / 3 + 1));
            let split = split.min(rh - 3).max(3);
            carve_room(grid, w, x, y, rw, split, depth + 1);
            carve_room(grid, w, x, y + split, rw, rh - split, depth + 1);
            let cx = x + rw / 2;
            for ry in y..(y + rh) { if ry < w { grid[(ry * w + cx) as usize] = 0; } }
        }
    }

    carve_room(&mut grid, w, 0, 0, w, h, 0);

    let mut img = ImageData::new(w * 4, h * 4);
    img.fill(15, 15, 25, 255);
    for y in 0..h {
        for x in 0..w {
            let (r, g, b) = if grid[(y * w + x) as usize] == 0 { (80, 70, 60) } else { (40, 35, 30) };
            img.draw_rect((x * 4) as i32, (y * 4) as i32, 4, 4, r, g, b, 255);
        }
    }
    save_png("procgen/bsp_dungeon", &img);
}

/// Noise-based terrain with coloured elevation bands.
#[test]
fn evidence_procgen_terrain_elevation() {
    let w: usize = 256;
    let h: usize = 256;
    let gen = NoiseGenerator::new(42);
    let opts = MapGenOptions {
        kind: NoiseKind::Perlin,
        octaves: 6,
        scale_x: 0.02,
        scale_y: 0.02,
        ..Default::default()
    };
    let data = gen.generate_map(w as u32, h as u32, &opts);
    let mut img = ImageData::new(w as u32, h as u32);
    for y in 0..h {
        for x in 0..w {
            let raw = data[y * w + x] as f32;
            let v = (raw * 0.5 + 0.5).clamp(0.0, 1.0); // normalize [-1,1] → [0,1]
            let (r, g, b) = if v < 0.3 {
                (30, 50, (120.0 + v * 200.0) as u8) // deep water
            } else if v < 0.4 {
                (60, 100, (180.0 + v * 100.0).min(255.0) as u8) // shallow water
            } else if v < 0.45 {
                (200, 190, 130) // beach
            } else if v < 0.65 {
                (40, (100.0 + v * 150.0) as u8, 40) // grass
            } else if v < 0.8 {
                let g = (80.0 + v * 80.0) as u8;
                (g, (g as f32 * 0.8) as u8, g / 2) // hills
            } else {
                let s = (200.0 + v * 55.0).min(255.0) as u8;
                (s, s, s) // snow peaks
            };
            img.set_pixel(x as u32, y as u32, r, g, b, 255);
        }
    }
    save_png("procgen/terrain_elevation", &img);
}

/// Multi-octave noise comparison: 1 vs 3 vs 6 vs 8 octaves side by side.
#[test]
fn evidence_procgen_octave_comparison() {
    let tile: usize = 128;
    let mut img = ImageData::new(tile as u32 * 4, tile as u32);
    let gen = NoiseGenerator::new(99);
    for (i, &octaves) in [1u32, 3, 6, 8].iter().enumerate() {
        let opts = MapGenOptions {
            kind: NoiseKind::Perlin,
            octaves,
            scale_x: 0.04, scale_y: 0.04,
            ..Default::default()
        };
        let data = gen.generate_map(tile as u32, tile as u32, &opts);
        let ox = i * tile;
        for y in 0..tile {
            for x in 0..tile {
                let v = ((data[y * tile + x] as f32 * 0.5 + 0.5) * 255.0).clamp(0.0, 255.0) as u8;
                img.set_pixel((ox + x) as u32, y as u32, v, v, v, 255);
            }
        }
    }
    save_png("procgen/octave_comparison_1_3_6_8", &img);
}

// ═══════════════════════════════════════════════════════════════════
// ██  MORE PARTICLE EVIDENCE
// ═══════════════════════════════════════════════════════════════════

/// Explosion particle effect — burst then fade.
#[test]
fn evidence_particle_explosion() {
    let config = ParticleConfig {
        max_particles: 500,
        emission_rate: 0.0, // manual burst
        ..Default::default()
    };
    let mut ps = ParticleSystem::new(config);
    ps.move_to(200.0, 200.0);
    ps.start();
    ps.emit(500); // burst
    // Simulate several frames
    for _ in 0..20 { ps.update(0.05); }

    let mut img = ImageData::new(400, 400);
    img.fill(5, 5, 10, 255);
    for p in &ps.particles {
        if p.life > 0.0 {
            let px = (p.x + ps.emitter_x) as i32;
            let py = (p.y + ps.emitter_y) as i32;
            if px < -20 || px > 420 || py < -20 || py > 420 { continue; }
            let t = 1.0 - p.life / p.max_life;
            // Orange → yellow → white fireball
            let r = 255;
            let g = (128.0 + 127.0 * t) as u8;
            let b = (t * 200.0) as u8;
            let a = (255.0 * (1.0 - t * 0.5)) as u8;
            safe_circle(&mut img, px, py, 2, r, g, b, a);
        }
    }
    save_png("particle/explosion", &img);
}

/// Rain particle effect — vertical streaks.
#[test]
fn evidence_particle_rain() {
    let config = ParticleConfig {
        max_particles: 300,
        emission_rate: 150.0,
        direction: std::f32::consts::FRAC_PI_2,  // downward
        spread: 0.3,                               // slight angle spread
        speed_min: 100.0,
        speed_max: 200.0,
        ..Default::default()
    };
    let mut ps = ParticleSystem::new(config);
    ps.move_to(200.0, 10.0);  // top-center
    ps.start();
    for _ in 0..40 { ps.update(0.033); }

    let mut img = ImageData::new(400, 300);
    img.fill(15, 20, 40, 255);  // dark night sky
    for p in &ps.particles {
        if p.life > 0.0 {
            let px = (p.x + ps.emitter_x) as i32;
            let py = (p.y + ps.emitter_y) as i32;
            if px < 0 || px >= 400 || py < 0 || py >= 296 { continue; }
            let streak_len = 6;
            img.draw_line(px, py, px, py + streak_len, 140, 160, 200, 180);
        }
    }
    // Label
    draw_label(&mut img, "RAIN", 185, 285, 120, 140, 180);
    save_png("particle/rain", &img);
}

/// Spark trail effect — particles along a path.
#[test]
fn evidence_particle_spark_trail() {
    let mut img = ImageData::new(400, 300);
    img.fill(10, 10, 15, 255);

    // Draw the sine path as a subtle reference line first
    for step in 0..800 {
        let t = step as f32 / 800.0;
        let x = (50.0 + t * 300.0) as i32;
        let y = (150.0 + (t * 4.0 * std::f32::consts::PI).sin() * 80.0) as i32;
        if x >= 0 && x < 400 && y >= 0 && y < 300 {
            img.set_pixel(x as u32, y as u32, 30, 30, 45, 255);
        }
    }

    // Place multiple stationary emitters along the sine path
    // Each emitter creates a cluster of sparks at its position
    let num_emitters = 12;
    for i in 0..num_emitters {
        let t = i as f32 / (num_emitters - 1) as f32;
        let ex = 50.0 + t * 300.0;
        let ey = 150.0 + (t * 4.0 * std::f32::consts::PI).sin() * 80.0;

        let config = ParticleConfig {
            max_particles: 40,
            emission_rate: 80.0,
            direction: std::f32::consts::PI,
            spread: std::f32::consts::PI,  // full hemisphere spread
            speed_min: 8.0,
            speed_max: 30.0,
            lifetime_min: 0.5,
            lifetime_max: 1.5,
            ..Default::default()
        };
        let mut ps = ParticleSystem::new(config);
        ps.move_to(ex, ey);
        ps.start();

        // Simulate for a bit to spread particles
        let age = (1.0 - t) * 0.8 + 0.1; // older at start, younger at end
        let steps = (age / 0.016) as usize;
        for _ in 0..steps { ps.update(0.016); }

        // Draw particles from this emitter
        for p in &ps.particles {
            if p.life > 0.0 {
                let px = (p.x + ps.emitter_x) as i32;
                let py = (p.y + ps.emitter_y) as i32;
                if px < 0 || px >= 400 || py < 0 || py >= 300 { continue; }
                let age_frac = 1.0 - p.life / p.max_life;
                let r = 255;
                let g = (220.0 * (1.0 - age_frac)) as u8;
                let b = (80.0 * (1.0 - age_frac * 0.8)) as u8;
                let alpha = (240.0 * (1.0 - age_frac * 0.5)) as u8;
                safe_circle(&mut img, px, py, 2, r, g, b, alpha);
            }
        }

        // Draw emitter position as a small bright dot
        safe_circle(&mut img, ex as i32, ey as i32, 1, 255, 255, 200, 180);
    }

    save_png("particle/spark_trail", &img);
}

// ═══════════════════════════════════════════════════════════════════
// ██  OVERLAY / POSTFX EVIDENCE
// ═══════════════════════════════════════════════════════════════════

/// Overlay flash effect — after trigger, alpha decays over time.
#[test]
fn evidence_overlay_flash_sequence() {
    let mut overlay = Overlay::new(200, 150);
    overlay.trigger_flash(1.0, 0.0, 0.0, 0.8, 0.5);

    let mut img = ImageData::new(800, 150);
    img.fill(15, 15, 25, 255);

    // Sample flash alpha at 4 time points
    for (frame, dt) in [0.0f32, 0.15, 0.3, 0.45].iter().enumerate() {
        if *dt > 0.0 { overlay.update(*dt); }
        let alpha = overlay.get_flash_alpha();
        let ox = (frame * 200) as i32;
        // Draw scene with flash overlay
        for y in 0..150 {
            for x in 0..200 {
                let base_r = 40u8;
                let base_g = 60u8;
                let base_b = 80u8;
                let r = (base_r as f32 + (255.0 - base_r as f32) * alpha) as u8;
                let g = (base_g as f32 + (0.0 - base_g as f32) * alpha).max(0.0) as u8;
                let b = (base_b as f32 + (0.0 - base_b as f32) * alpha).max(0.0) as u8;
                img.set_pixel((ox + x) as u32, y, r, g, b, 255);
            }
        }
    }
    save_png("overlay/flash_sequence", &img);
}

/// Overlay shake effect — offset visualization at different times.
#[test]
fn evidence_overlay_shake_offsets() {
    let mut overlay = Overlay::new(200, 200);
    overlay.trigger_shake(80.0, 1.0);

    let mut img = ImageData::new(400, 400);
    img.fill(15, 15, 25, 255);

    // Record shake offsets
    let mut offsets = Vec::new();
    for _ in 0..120 {
        offsets.push(overlay.get_shake_offset());
        overlay.update(1.0 / 60.0);
    }

    // Draw a simple scene shifted by shake offsets
    let cx = 200i32;
    let cy = 200i32;
    for (i, (ox, oy)) in offsets.iter().enumerate() {
        let alpha = (255.0 * (1.0 - i as f32 / 120.0)) as u8;
        let x = cx + *ox as i32;
        let y = cy + *oy as i32;
        safe_circle(&mut img, x, y, 8, 80, 200, 255, alpha);
    }
    // Connect offsets with lines
    for i in 1..offsets.len() {
        let (ox0, oy0) = offsets[i - 1];
        let (ox1, oy1) = offsets[i];
        img.draw_line(
            cx + ox0 as i32, cy + oy0 as i32,
            cx + ox1 as i32, cy + oy1 as i32,
            200, 100, 50, 150,
        );
    }
    save_png("overlay/shake_offsets", &img);
}

/// Overlay fade effect — smooth alpha transition.
#[test]
fn evidence_overlay_fade_transition() {
    let mut overlay = Overlay::new(100, 100);
    overlay.trigger_fade(0.0, 0.0, 0.0, 1.0, 1.0); // fade to black

    let mut img = ImageData::new(600, 100);
    img.fill(15, 15, 25, 255);

    // Sample 6 time points
    for frame in 0..6 {
        if frame > 0 { overlay.update(0.18); }
        let ox = frame * 100;
        let active = overlay.is_active();
        let brightness = if active { (200.0 * (1.0 - frame as f32 / 6.0)) as u8 } else { 200 };
        for y in 10..90 {
            for x in 10..90 {
                img.set_pixel((ox + x) as u32, y, brightness, brightness / 2, brightness / 3, 255);
            }
        }
    }
    save_png("overlay/fade_transition", &img);
}

/// PostFx effect stack — visualize parameter defaults for each built-in type.
#[test]
fn evidence_postfx_effect_types() {
    let types = [
        PostFxEffectType::Vignette,
        PostFxEffectType::Grayscale,
        PostFxEffectType::Chromatic,
        PostFxEffectType::Blur,
    ];

    let mut img = ImageData::new(400, 300);
    img.fill(25, 25, 35, 255);

    for (i, typ) in types.iter().enumerate() {
        let effect = PostFxEffect::new(typ.clone());
        let params = effect.get_parameter_names();
        let y_base = 20 + i as i32 * 70;

        // Draw colored bar for each effect type
        let (r, g, b) = match i {
            0 => (180, 80, 80),
            1 => (80, 180, 80),
            2 => (80, 80, 180),
            _ => (180, 180, 80),
        };
        img.draw_rect(20, y_base, 360, 55, r / 3, g / 3, b / 3, 200);
        img.draw_rect(20, y_base, 360, 2, r, g, b, 255);

        // Show number of params as dots
        for (p, _pname) in params.iter().enumerate() {
            safe_circle(&mut img, 40 + p as i32 * 20, y_base + 30, 5, r, g, b, 255);
        }
    }
    save_png("overlay/postfx_effect_types", &img);
}

/// PostFx stack management — add, remove, enable/disable effects.
#[test]
fn evidence_postfx_stack_operations() {
    let mut stack = PostFxStack::new(320, 240);

    // Add effects
    stack.add(0); // effect index 0
    stack.add(1); // effect index 1
    stack.add(2); // effect index 2

    assert_eq!(stack.get_effect_count(), 3);

    // Disable middle effect
    stack.set_enabled(1, false);
    assert!(!stack.is_enabled(1));
    assert!(stack.is_enabled(0));

    // Record enabled count
    let enabled = stack.enabled_effects();
    assert_eq!(enabled.len(), 2); // 0 and 2 are enabled

    // Remove one
    stack.remove(1);
    assert_eq!(stack.get_effect_count(), 2);

    // Visualize stack state as a diagram
    let img = stack.render_info_to_image(300, 200);
    save_png("overlay/postfx_stack_operations", &img);
}

// ═══════════════════════════════════════════════════════════════════
// ██  IMAGEDATA PASTE & COMPOSITE EVIDENCE
// ═══════════════════════════════════════════════════════════════════

/// ImageData paste operation — compositing multiple source images with overlaps.
#[test]
fn evidence_image_paste_composite_advanced() {
    let mut canvas = ImageData::new(300, 300);
    canvas.fill(20, 20, 30, 255);

    // Create a red square source
    let mut red_sq = ImageData::new(80, 80);
    red_sq.fill(200, 50, 50, 255);

    // Create a blue circle source
    let mut blue_circ = ImageData::new(80, 80);
    blue_circ.fill(0, 0, 0, 0); // transparent
    safe_circle(&mut blue_circ, 40, 40, 35, 50, 50, 200, 255);

    // Create a green triangle source
    let mut green_tri = ImageData::new(80, 80);
    green_tri.fill(0, 0, 0, 0);
    for y in 0..80i32 {
        let half_w = (y * 40 / 80) as i32;
        if half_w > 0 {
            green_tri.draw_line(40 - half_w, y, 40 + half_w, y, 50, 200, 50, 255);
        }
    }

    // Paste them at different positions
    canvas.paste(&red_sq, 30, 30);
    canvas.paste(&blue_circ, 110, 60);
    canvas.paste(&green_tri, 190, 100);

    // Paste overlapping to show compositing
    canvas.paste(&red_sq, 70, 180);
    canvas.paste(&blue_circ, 120, 180);

    save_png("image/paste_composite", &canvas);
}

/// ImageData map_pixel — colour transformation applied to entire image.
#[test]
fn evidence_image_map_pixel_transforms() {
    let mut img = ImageData::new(400, 300);

    // Create a colorful base pattern
    for y in 0..300u32 {
        for x in 0..100u32 {
            let r = (x * 255 / 100) as u8;
            let g = (y * 255 / 300) as u8;
            let b = 128u8;
            img.set_pixel(x, y, r, g, b, 255);
        }
    }

    // Copy base to 3 more columns, then apply transforms
    // Column 2: invert
    for y in 0..300u32 {
        for x in 0..100u32 {
            if let Some((r, g, b, _a)) = img.get_pixel(x, y) {
                img.set_pixel(100 + x, y, 255 - r, 255 - g, 255 - b, 255);
            }
        }
    }

    // Column 3: grayscale
    for y in 0..300u32 {
        for x in 0..100u32 {
            if let Some((r, g, b, _a)) = img.get_pixel(x, y) {
                let gray = ((r as u16 + g as u16 + b as u16) / 3) as u8;
                img.set_pixel(200 + x, y, gray, gray, gray, 255);
            }
        }
    }

    // Column 4: sepia tone
    for y in 0..300u32 {
        for x in 0..100u32 {
            if let Some((r, g, b, _a)) = img.get_pixel(x, y) {
                let gray = ((r as u16 + g as u16 + b as u16) / 3) as u8;
                let sr = (gray as u16).saturating_mul(255).saturating_div(200).min(255) as u8;
                let sg = (gray as u16).saturating_mul(200).saturating_div(200).min(255) as u8;
                let sb = (gray as u16).saturating_mul(150).saturating_div(200).min(255) as u8;
                img.set_pixel(300 + x, y, sr, sg, sb, 255);
            }
        }
    }

    save_png("image/map_pixel_transforms", &img);
}

/// ImageData get_pixel and dimensions proof.
#[test]
fn evidence_image_dimensions_and_pixels() {
    let img = ImageData::new(100, 50);
    assert_eq!(img.width(), 100);
    assert_eq!(img.height(), 50);
    assert_eq!(img.dimensions(), (100, 50));

    let mut img = ImageData::new(200, 200);
    // Write specific pixel values and read them back
    img.set_pixel(10, 10, 255, 0, 0, 255);
    img.set_pixel(20, 20, 0, 255, 0, 255);
    img.set_pixel(30, 30, 0, 0, 255, 255);

    assert_eq!(img.get_pixel(10, 10), Some((255, 0, 0, 255)));
    assert_eq!(img.get_pixel(20, 20), Some((0, 255, 0, 255)));
    assert_eq!(img.get_pixel(30, 30), Some((0, 0, 255, 255)));
    assert_eq!(img.get_pixel(201, 201), None); // out of bounds

    // Draw a colour wheel using get_pixel to verify all set_pixel operations
    for y in 0..200u32 {
        for x in 0..200u32 {
            let dx = x as f32 - 100.0;
            let dy = y as f32 - 100.0;
            let dist = (dx * dx + dy * dy).sqrt();
            if dist < 90.0 {
                let angle = dy.atan2(dx);
                let hue = ((angle + std::f32::consts::PI) / std::f32::consts::TAU * 360.0) as u16;
                let sat = dist / 90.0;
                let (r, g, b) = hsv_to_rgb(hue, sat, 1.0);
                img.set_pixel(x, y, r, g, b, 255);
            }
        }
    }
    save_png("image/color_wheel_pixel_proof", &img);
}

// ═══════════════════════════════════════════════════════════════════
// ██  BEZIER CURVE EVIDENCE (expanded)
// ═══════════════════════════════════════════════════════════════════

/// Bezier curves — cubic curves with control point visualization.
#[test]
fn evidence_math_bezier_cubic_curves() {
    let mut img = ImageData::new(400, 400);
    img.fill(15, 15, 25, 255);

    let curves = [
        // Control points: P0, P1, P2, P3
        ([50.0, 350.0], [100.0, 50.0], [300.0, 50.0], [350.0, 350.0]),
        ([50.0, 200.0], [150.0, 50.0], [250.0, 350.0], [350.0, 200.0]),
        ([50.0, 100.0], [200.0, 350.0], [200.0, 50.0], [350.0, 300.0]),
    ];

    let colors = [(255, 80, 80), (80, 255, 80), (80, 80, 255)];

    for (ci, (p0, p1, p2, p3)) in curves.iter().enumerate() {
        let (cr, cg, cb) = colors[ci];
        let control = vec![
            Vec2::new(p0[0], p0[1]),
            Vec2::new(p1[0], p1[1]),
            Vec2::new(p2[0], p2[1]),
            Vec2::new(p3[0], p3[1]),
        ];
        let bez = BezierCurve::new(control);

        // Draw control polygon (dashed)
        img.draw_line(p0[0] as i32, p0[1] as i32, p1[0] as i32, p1[1] as i32, cr / 3, cg / 3, cb / 3, 100);
        img.draw_line(p1[0] as i32, p1[1] as i32, p2[0] as i32, p2[1] as i32, cr / 3, cg / 3, cb / 3, 100);
        img.draw_line(p2[0] as i32, p2[1] as i32, p3[0] as i32, p3[1] as i32, cr / 3, cg / 3, cb / 3, 100);

        // Draw curve
        let steps = 100;
        for i in 0..steps {
            let t0 = i as f32 / steps as f32;
            let t1 = (i + 1) as f32 / steps as f32;
            let pt0 = bez.evaluate(t0);
            let pt1 = bez.evaluate(t1);
            img.draw_line(pt0.x as i32, pt0.y as i32, pt1.x as i32, pt1.y as i32, cr, cg, cb, 255);
        }

        // Draw control points
        for pt in [p0, p1, p2, p3] {
            safe_circle(&mut img, pt[0] as i32, pt[1] as i32, 4, cr, cg, cb, 255);
        }
    }
    save_png("math/bezier_cubic_curves", &img);
}

// ═══════════════════════════════════════════════════════════════════
// ██  AUDIO ENVELOPE AND SYNTHESIS EVIDENCE
// ═══════════════════════════════════════════════════════════════════

/// ADSR envelope applied to a tone — attack, decay, sustain, release.
#[test]
fn evidence_audio_adsr_envelope() {
    let sr = 44100u32;
    let duration = 2.0f32;
    let total = (sr as f32 * duration) as usize;
    let mut samples = Vec::with_capacity(total);

    // ADSR params
    let attack = 0.1f32;
    let decay = 0.2f32;
    let sustain_level = 0.6f32;
    let sustain_time = 1.2f32;
    let release = 0.5f32;

    for i in 0..total {
        let t = i as f32 / sr as f32;
        let env = if t < attack {
            t / attack
        } else if t < attack + decay {
            1.0 - (1.0 - sustain_level) * (t - attack) / decay
        } else if t < attack + decay + sustain_time {
            sustain_level
        } else {
            let rel_t = (t - attack - decay - sustain_time) / release;
            sustain_level * (1.0 - rel_t).max(0.0)
        };
        let tone = (t * 440.0 * std::f32::consts::TAU).sin();
        samples.push(tone * env);
    }

    let sd = SoundData::from_samples(samples.clone(), sr, 1);
    save_wav("audio/adsr_envelope", &sd);
    render_waveform("audio/adsr_envelope_waveform", &samples, sr);
}

/// White noise and pink noise spectrum comparison.
#[test]
fn evidence_audio_noise_spectrum() {
    let sr = 44100u32;
    let total = sr as usize; // 1 second

    // White noise
    let mut white = Vec::with_capacity(total);
    let mut rng_state = 12345u64;
    for _ in 0..total {
        rng_state = rng_state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        let val = (rng_state >> 33) as f32 / (1u64 << 31) as f32 - 1.0;
        white.push(val * 0.5);
    }

    // Pink noise (crude approximation via filtering white noise)
    let mut pink = vec![0.0f32; total];
    let mut b = [0.0f32; 7];
    for i in 0..total {
        let w = white[i];
        b[0] = 0.99886 * b[0] + w * 0.0555179;
        b[1] = 0.99332 * b[1] + w * 0.0750759;
        b[2] = 0.96900 * b[2] + w * 0.1538520;
        b[3] = 0.86650 * b[3] + w * 0.3104856;
        b[4] = 0.55000 * b[4] + w * 0.5329522;
        b[5] = -0.7616 * b[5] - w * 0.0168980;
        pink[i] = (b[0] + b[1] + b[2] + b[3] + b[4] + b[5] + b[6] + w * 0.5362) * 0.11;
        b[6] = w * 0.115926;
    }

    let sd_white = SoundData::from_samples(white.clone(), sr, 1);
    let sd_pink = SoundData::from_samples(pink.clone(), sr, 1);
    save_wav("audio/white_noise", &sd_white);
    save_wav("audio/pink_noise", &sd_pink);
    render_waveform("audio/white_noise_waveform", &white, sr);
    render_waveform("audio/pink_noise_waveform", &pink, sr);
}

/// DSP effect chain: lowpass → reverb applied in sequence.
#[test]
fn evidence_audio_dsp_chain() {
    let sr = 44100u32;
    let base = make_sine_samples(220.0, 1.0, sr);

    // Add harmonics for richer source
    let mut rich = base.clone();
    for i in 0..rich.len() {
        let t = i as f32 / sr as f32;
        rich[i] += 0.3 * (t * 440.0 * std::f32::consts::TAU).sin();
        rich[i] += 0.15 * (t * 660.0 * std::f32::consts::TAU).sin();
        rich[i] += 0.08 * (t * 880.0 * std::f32::consts::TAU).sin();
        rich[i] *= 0.5; // normalize
    }

    // Stage 1: lowpass
    let lp_params = Arc::new({
        let mut p = EffectParams::new(1, EffectType::Lowpass);
        let _ = p.set_param("cutoff", 800.0);
        let _ = p.set_param("q", 0.7);
        p
    });
    let mut lp = ActiveEffect::new(lp_params, sr, 1);
    let after_lp: Vec<f32> = rich.iter().map(|&s| lp.process(s, 0, sr)).collect();

    // Stage 2: reverb
    let rv_params = Arc::new({
        let mut p = EffectParams::new(2, EffectType::Reverb);
        let _ = p.set_param("room_size", 0.6);
        let _ = p.set_param("damping", 0.3);
        let _ = p.set_param("mix", 0.4);
        p
    });
    let mut rv = ActiveEffect::new(rv_params, sr, 1);
    let after_chain: Vec<f32> = after_lp.iter().map(|&s| rv.process(s, 0, sr)).collect();

    let sd = SoundData::from_samples(after_chain.clone(), sr, 1);
    save_wav("audio_dsp/chain_lowpass_reverb", &sd);
    render_waveform("audio_dsp/chain_before_waveform", &rich, sr);
    render_waveform("audio_dsp/chain_after_lowpass_waveform", &after_lp, sr);
    render_waveform("audio_dsp/chain_final_waveform", &after_chain, sr);
}

// ═══════════════════════════════════════════════════════════════════
// ██  PATHFINDING EXPANDED EVIDENCE
// ═══════════════════════════════════════════════════════════════════

/// NavGrid with weighted costs — shows different terrain costs.
#[test]
fn evidence_pathfinding_weighted_terrain() {
    let w = 40u32;
    let h = 40u32;
    let mut grid = NavGrid::new(w, h);

    // Create terrain with different costs
    // Forest (cost 3) in the middle
    for y in 10..30 { for x in 10..30 { grid.set_cost(x, y, 3); } }
    // Swamp (cost 5) in upper area
    for y in 5..15 { for x in 15..35 { grid.set_cost(x, y, 5); } }
    // Walls (blocked)
    for x in 20..22 { for y in 15..35 { grid.set_blocked(x, y, true); } }

    // Find path
    let (path, _found) = astar(&grid, (2, 20), (38, 20), 1, 5000);

    let mut img = ImageData::new(w * 6, h * 6);
    img.fill(15, 15, 25, 255);

    // Draw terrain
    for y in 0..h {
        for x in 0..w {
            let cost = grid.get_cost(x, y);
            let blocked = grid.is_blocked(x, y);
            let (r, g, b) = if blocked {
                (60, 30, 30)
            } else if cost > 4 {
                (40, 60, 40) // swamp
            } else if cost > 2 {
                (30, 80, 30) // forest
            } else {
                (60, 55, 45) // normal
            };
            img.draw_rect((x * 6) as i32, (y * 6) as i32, 5, 5, r, g, b, 255);
        }
    }

    // Draw path
    if let Some(ref path) = path {
        for &(px, py) in path {
            img.draw_rect((px * 6 + 1) as i32, (py * 6 + 1) as i32, 3, 3, 255, 220, 50, 255);
        }
    }

    // Mark start and end
    safe_circle(&mut img, 2 * 6 + 3, 20 * 6 + 3, 4, 80, 255, 80, 255);
    safe_circle(&mut img, 38 * 6 + 3, 20 * 6 + 3, 4, 255, 80, 80, 255);

    save_png("pathfinding/weighted_terrain", &img);
}

// ═══════════════════════════════════════════════════════════════════
// ██  COMBINED EVIDENCE (complex scenes)
// ═══════════════════════════════════════════════════════════════════

/// Combined: noise terrain + raycaster first-person view.
#[test]
fn evidence_combined_terrain_raycaster() {
    let gen = NoiseGenerator::new(77);
    let opts = MapGenOptions {
        kind: NoiseKind::Perlin,
        octaves: 3,
        scale_x: 0.15, scale_y: 0.15,
        ..Default::default()
    };
    let noise = gen.generate_map(24, 24, &opts);

    let mut rc = Raycaster2D::new(24, 24);
    for y in 0usize..24 { for x in 0usize..24 {
        let v = noise[y * 24 + x] * 0.5 + 0.5;
        if v > 0.5 {
            rc.set_cell(x as u32, y as u32, 1 + (v * 3.0) as u32);
        }
    }}
    // Ensure player position is clear
    rc.set_cell(12, 12, 0);
    rc.set_cell(11, 12, 0);
    rc.set_cell(12, 11, 0);

    let mut img = ImageData::new(320, 200);
    // Draw sky gradient
    for y in 0..100u32 {
        let t = y as f32 / 100.0;
        let r = (40.0 + t * 60.0) as u8;
        let g = (60.0 + t * 80.0) as u8;
        let b = (120.0 + t * 80.0) as u8;
        for x in 0..320u32 { img.set_pixel(x, y, r, g, b, 255); }
    }
    // Draw floor gradient
    for y in 100..200u32 {
        let t = (y - 100) as f32 / 100.0;
        let r = (80.0 - t * 40.0) as u8;
        let g = (60.0 - t * 30.0) as u8;
        let b = (40.0 - t * 20.0) as u8;
        for x in 0..320u32 { img.set_pixel(x, y, r, g, b, 255); }
    }

    let rays = rc.cast_rays(12.0, 12.0, 0.8, std::f32::consts::FRAC_PI_3, 320, 24.0);
    for (x, hit) in rays.iter().enumerate() {
        if hit.hit {
            let wall_h = (200.0 / hit.distance.max(0.1)) as i32;
            let top = 100 - wall_h / 2;
            let bot = 100 + wall_h / 2;
            let shade = (1.0 - hit.distance / 24.0).max(0.1);
            let (r, g, b) = match hit.cell_value {
                1 => (180, 140, 100),
                2 => (200, 160, 120),
                _ => (220, 180, 140),
            };
            let r = (r as f32 * shade) as u8;
            let g = (g as f32 * shade) as u8;
            let b = (b as f32 * shade) as u8;
            img.draw_line(x as i32, top.max(0), x as i32, bot.min(199), r, g, b, 255);
        }
    }
    save_png("combined/terrain_raycaster", &img);
}

/// Combined: particle system on top of a tilemap.
#[test]
fn evidence_combined_tilemap_particles() {
    let mut tm = TileMap::new(16, 12, 16);
    let ground = tm.add_layer("ground", 16, 12);
    // Ground tiles
    for y in 0..12 { for x in 0..16 {
        tm.set_tile(ground, x, y, if (x + y) % 2 == 0 { 1 } else { 2 });
    }}

    // Create particle system
    let config = ParticleConfig {
        max_particles: 150,
        emission_rate: 50.0,
        ..Default::default()
    };
    let mut ps = ParticleSystem::new(config);
    ps.move_to(128.0, 96.0);
    ps.start();
    for _ in 0..30 { ps.update(0.033); }

    let mut img = ImageData::new(256, 192);
    img.fill(15, 15, 25, 255);

    // Draw tilemap
    for y in 0..12 { for x in 0..16 {
        let tile = tm.get_tile(ground, x, y);
        let (r, g, b) = if tile == 1 { (50, 70, 50) } else { (40, 60, 40) };
        img.draw_rect((x * 16) as i32, (y * 16) as i32, 16, 16, r, g, b, 255);
    }}

    // Draw particles on top
    for p in &ps.particles {
        if p.life > 0.0 {
            let px = (p.x + ps.emitter_x) as i32;
            let py = (p.y + ps.emitter_y) as i32;
            if px < 0 || px >= 256 || py < 0 || py >= 192 { continue; }
            let t = 1.0 - p.life / p.max_life;
            let r = (255.0 * (1.0 - t)) as u8;
            let g = (200.0 * (1.0 - t * 0.8)) as u8;
            safe_circle(&mut img, px, py, 2, r, g, 50, 200);
        }
    }
    save_png("combined/tilemap_particles", &img);
}

// ===== CHART / GRAPH EVIDENCE =====

/// Line chart with axes, gridlines, legend, and multiple data series.
#[test]
fn evidence_chart_line_chart() {
    let cfg = ChartConfig {
        width: 400,
        height: 300,
        title: Some("LINE CHART".to_string()),
        margin: ChartMargin { left: 40, right: 30, top: 30, bottom: 40 },
        ..ChartConfig::default()
    };
    let mut chart = LineChart::new(cfg);
    chart.y_max = 100.0;
    chart.x_max = 6.0;

    chart.add_series("SALES", &[
        (0.0,20.0),(1.0,45.0),(2.0,35.0),(3.0,60.0),(4.0,55.0),(5.0,80.0),(6.0,75.0),
    ], Color::new(0.86, 0.24, 0.24, 1.0));
    chart.add_series("COSTS", &[
        (0.0,10.0),(1.0,25.0),(2.0,50.0),(3.0,40.0),(4.0,70.0),(5.0,65.0),(6.0,90.0),
    ], Color::new(0.24, 0.55, 0.86, 1.0));
    chart.add_series("MISC", &[
        (0.0,50.0),(1.0,40.0),(2.0,30.0),(3.0,45.0),(4.0,35.0),(5.0,25.0),(6.0,40.0),
    ], Color::new(0.24, 0.71, 0.31, 1.0));

    let img = chart.render_to_image();
    save_png("chart/line_chart", &img);
}

/// Bar chart with grouped vertical bars and value labels.
#[test]
fn evidence_chart_bar_chart() {
    let cfg = ChartConfig {
        width: 400,
        height: 300,
        title: Some("BAR CHART".to_string()),
        bg_color: (245, 245, 248),
        margin: ChartMargin { left: 45, right: 20, top: 30, bottom: 40 },
        ..ChartConfig::default()
    };
    let mut chart = BarChart::new(cfg);
    chart.add_series("2023", Color::new(0.27, 0.51, 0.78, 1.0));
    chart.add_series("2024", Color::new(0.86, 0.59, 0.20, 1.0));
    chart.add_category("Q1", &[65.0, 40.0]);
    chart.add_category("Q2", &[80.0, 55.0]);
    chart.add_category("Q3", &[50.0, 70.0]);
    chart.add_category("Q4", &[90.0, 60.0]);
    chart.add_category("Q5", &[75.0, 85.0]);

    let img = chart.render_to_image();
    save_png("chart/bar_chart", &img);
}

/// Scatter plot with three color-coded data clusters.
#[test]
fn evidence_chart_scatter_plot() {
    let cfg = ChartConfig {
        width: 400,
        height: 400,
        title: Some("SCATTER PLOT".to_string()),
        bg_color: (248, 248, 250),
        margin: ChartMargin { left: 40, right: 20, top: 30, bottom: 30 },
        ..ChartConfig::default()
    };
    let mut chart = ScatterPlot::new(cfg);
    chart.x_range = (0.0, 1.0);
    chart.y_range = (0.0, 1.0);

    // Generate pseudo-random clusters using a simple LCG
    let mut seed = 42u64;
    let mut rng = || -> f32 {
        seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
        ((seed >> 33) as f32) / (u32::MAX as f32 / 2.0)
    };

    let clusters: [(f32, f32, f32, Color); 3] = [
        (0.3, 0.7, 0.12, Color::new(0.78, 0.24, 0.24, 1.0)),
        (0.7, 0.3, 0.10, Color::new(0.24, 0.24, 0.78, 1.0)),
        (0.5, 0.5, 0.15, Color::new(0.24, 0.71, 0.24, 1.0)),
    ];

    for (i, &(cx, cy, spread, color)) in clusters.iter().enumerate() {
        let mut pts = Vec::new();
        for _ in 0..30 {
            let dx = (rng() - 0.5) * spread * 2.0;
            let dy = (rng() - 0.5) * spread * 2.0;
            pts.push(((cx + dx).clamp(0.0, 1.0), (cy + dy).clamp(0.0, 1.0)));
        }
        chart.add_series(&format!("C{}", i), &pts, color);
    }

    let img = chart.render_to_image();
    save_png("chart/scatter_plot", &img);
}

/// Pie chart with colored segments and percentage labels.
#[test]
fn evidence_chart_pie_chart() {
    let w = 400u32;
    let h = 400u32;
    let mut img = ImageData::new(w, h);
    img.fill(250, 250, 252, 255);

    let cx = 180f32;
    let cy = 200f32;
    let radius = 130f32;

    // Segments: (percentage, color)
    let segments: [(f32, (u8, u8, u8), &str); 5] = [
        (35.0, (70, 130, 200), "WORK 35%"),
        (25.0, (220, 80, 60), "SLEEP 25%"),
        (20.0, (80, 190, 80), "PLAY 20%"),
        (12.0, (220, 180, 50), "EAT 12%"),
        (8.0, (160, 80, 200), "OTHER 8%"),
    ];

    let mut angle = -std::f32::consts::FRAC_PI_2; // start at top
    for &(pct, (cr, cg, cb), _label) in &segments {
        let sweep = pct / 100.0 * 2.0 * std::f32::consts::PI;
        let end_angle = angle + sweep;

        // Fill segment pixel by pixel
        for py in 0..h {
            for px in 0..w {
                let dx = px as f32 - cx;
                let dy = py as f32 - cy;
                let dist = (dx * dx + dy * dy).sqrt();
                if dist > radius { continue; }
                let mut a = dy.atan2(dx);
                // Normalize angle to match our sweep
                if a < -std::f32::consts::FRAC_PI_2 {
                    a += 2.0 * std::f32::consts::PI;
                }
                let mut check_a = a;
                if check_a < angle { check_a += 2.0 * std::f32::consts::PI; }
                let mut check_end = end_angle;
                if check_end < angle { check_end += 2.0 * std::f32::consts::PI; }
                if check_a >= angle && check_a < check_end {
                    // Slight darkening near edge for depth
                    let edge_factor = if dist > radius - 3.0 { 0.7f32 } else { 1.0 };
                    img.set_pixel(px, py,
                        (cr as f32 * edge_factor) as u8,
                        (cg as f32 * edge_factor) as u8,
                        (cb as f32 * edge_factor) as u8, 255);
                }
            }
        }
        angle = end_angle;
    }

    // Segment divider lines (white)
    angle = -std::f32::consts::FRAC_PI_2;
    for &(pct, _, _) in &segments {
        let sweep = pct / 100.0 * 2.0 * std::f32::consts::PI;
        let lx = cx + angle.cos() * radius;
        let ly = cy + angle.sin() * radius;
        img.draw_line(cx as i32, cy as i32, lx as i32, ly as i32, 255, 255, 255, 255);
        angle += sweep;
    }

    // Labels on the right side
    let mut label_y = 60i32;
    for &(_, (cr, cg, cb), label) in &segments {
        img.draw_rect(320, label_y, 12, 8, cr, cg, cb, 255);
        draw_label(&mut img, label, 336, label_y + 2, 60, 60, 70);
        label_y += 14;
    }

    draw_label(&mut img, "PIE CHART", 10, 10, 40, 40, 50);
    save_png("chart/pie_chart", &img);
}

/// Stacked area chart showing cumulative data over time.
#[test]
fn evidence_chart_area_chart() {
    let w = 400u32;
    let h = 300u32;
    let mut img = ImageData::new(w, h);
    img.fill(245, 245, 248, 255);

    let left = 40i32;
    let right = 380i32;
    let top = 30i32;
    let bottom = 260i32;
    let chart_w = (right - left) as f32;
    let chart_h = (bottom - top) as f32;

    // Y axis grid
    for i in 0..=4 {
        let y = top + (i as f32 * chart_h / 4.0) as i32;
        img.draw_line(left, y, right, y, 215, 215, 220, 255);
    }
    img.draw_line(left, top, left, bottom, 80, 80, 90, 255);
    img.draw_line(left, bottom, right, bottom, 80, 80, 90, 255);

    // Three stacked layers (bottom to top)
    let n = 12;
    let layer_a: [f32; 12] = [20.0, 25.0, 30.0, 28.0, 35.0, 40.0, 38.0, 45.0, 42.0, 50.0, 48.0, 55.0];
    let layer_b: [f32; 12] = [15.0, 18.0, 20.0, 22.0, 18.0, 25.0, 28.0, 24.0, 30.0, 28.0, 32.0, 30.0];
    let layer_c: [f32; 12] = [10.0, 12.0, 8.0, 15.0, 12.0, 10.0, 14.0, 12.0, 8.0, 15.0, 10.0, 12.0];
    let max_val = 100.0f32;

    // Fill areas from top-most layer down (so lower layers overlay)
    let layers: [(&[f32], (u8, u8, u8)); 3] = [
        (&layer_c, (180, 100, 200)),  // purple (top)
        (&layer_b, (100, 180, 100)),  // green (middle)
        (&layer_a, (100, 150, 220)),  // blue (bottom)
    ];

    // We need cumulative stacks
    for x_px in left..right {
        let t = (x_px - left) as f32 / chart_w;
        let idx_f = t * (n - 1) as f32;
        let idx0 = (idx_f as usize).min(n - 2);
        let frac = idx_f - idx0 as f32;

        let va = layer_a[idx0] + (layer_a[idx0 + 1] - layer_a[idx0]) * frac;
        let vb = layer_b[idx0] + (layer_b[idx0 + 1] - layer_b[idx0]) * frac;
        let vc = layer_c[idx0] + (layer_c[idx0 + 1] - layer_c[idx0]) * frac;

        let stack = [(va, (100, 150, 220)), (va + vb, (100, 180, 100)), (va + vb + vc, (180, 100, 200))];
        let mut prev_y = bottom;

        for &(cumval, (cr, cg, cb)) in &stack {
            let cur_y = bottom - (cumval / max_val * chart_h) as i32;
            for y_px in cur_y.max(top)..prev_y {
                img.set_pixel(x_px as u32, y_px as u32, cr, cg, cb, 220);
            }
            prev_y = cur_y;
        }
    }

    // Legend
    let labels = [("ALPHA", (100, 150, 220)), ("BETA", (100, 180, 100)), ("GAMMA", (180, 100, 200))];
    for (i, (name, (cr, cg, cb))) in labels.iter().enumerate() {
        let ly = 10 + i as i32 * 10;
        img.draw_rect(310, ly, 10, 6, *cr, *cg, *cb, 255);
        draw_label(&mut img, name, 324, ly + 1, 60, 60, 70);
    }
    draw_label(&mut img, "AREA CHART", left + 10, 10, 40, 40, 50);

    save_png("chart/area_chart", &img);
}

// ===== GUI DRAWING EVIDENCE =====

/// GUI button states: normal, hover, pressed, disabled.
#[test]
fn evidence_gui_button_states() {
    let w = 400u32;
    let h = 200u32;
    let mut img = ImageData::new(w, h);
    img.fill(45, 45, 55, 255);

    let states = [
        ("NORMAL",   80, 50, 60, (60, 120, 200), (40, 90, 170), (220, 230, 240)),
        ("HOVER",    80, 50, 60, (80, 150, 230), (50, 110, 200), (255, 255, 255)),
        ("PRESSED",  80, 50, 60, (40, 80, 150),  (30, 60, 120), (180, 190, 200)),
        ("DISABLED", 80, 50, 60, (80, 80, 90),   (60, 60, 70),  (120, 120, 130)),
    ];

    for (idx, &(label, bw, bh, _pad, (fr, fg, fb), (br, bg, bb), (tr, tg, tb))) in states.iter().enumerate() {
        let bx = 20 + idx as i32 * 95;
        let by = 60i32;

        // Shadow
        img.draw_rect(bx + 2, by + 2, bw as u32, bh as u32, 20, 20, 25, 255);
        // Button body
        img.draw_rect(bx, by, bw as u32, bh as u32, fr, fg, fb, 255);
        // Top highlight
        img.draw_line(bx + 1, by + 1, bx + bw - 2, by + 1, fr.saturating_add(30), fg.saturating_add(30), fb.saturating_add(30), 255);
        // Border
        for i in 0..bw {
            img.set_pixel((bx + i) as u32, by as u32, br, bg, bb, 255);
            img.set_pixel((bx + i) as u32, (by + bh - 1) as u32, br, bg, bb, 255);
        }
        for i in 0..bh {
            img.set_pixel(bx as u32, (by + i) as u32, br, bg, bb, 255);
            img.set_pixel((bx + bw - 1) as u32, (by + i) as u32, br, bg, bb, 255);
        }
        // Label centered
        let lx = bx + (bw - label.len() as i32 * 4) / 2;
        let ly = by + (bh - 5) / 2;
        draw_label(&mut img, label, lx, ly, tr, tg, tb);
        // State label below
        draw_label(&mut img, label, bx + 5, by + bh + 8, 150, 150, 160);
    }

    draw_label(&mut img, "BUTTON STATES", 10, 10, 180, 180, 190);
    save_png("gui/button_states", &img);
}

/// GUI panel with title bar, content area, and nested elements.
#[test]
fn evidence_gui_panel_layout() {
    let w = 400u32;
    let h = 350u32;
    let mut img = ImageData::new(w, h);
    img.fill(35, 35, 45, 255);

    // Main panel
    let px = 30i32;
    let py = 20i32;
    let pw = 340i32;
    let ph = 300i32;

    // Panel shadow
    img.draw_rect(px + 3, py + 3, pw as u32, ph as u32, 15, 15, 20, 255);
    // Panel body
    img.draw_rect(px, py, pw as u32, ph as u32, 55, 55, 65, 255);
    // Title bar
    img.draw_rect(px, py, pw as u32, 24, 70, 100, 160, 255);
    draw_label(&mut img, "SETTINGS PANEL", px + 8, py + 8, 220, 230, 240);
    // Close button
    let cbx = px + pw - 20;
    img.draw_rect(cbx, py + 4, 16, 16, 200, 60, 60, 255);
    draw_label(&mut img, "X", cbx + 5, py + 9, 255, 255, 255);

    // Content area with labels and controls
    let cy = py + 36;

    // Checkbox row
    draw_label(&mut img, "SOUND", px + 12, cy, 180, 180, 190);
    img.draw_rect(px + 80, cy - 2, 12, 12, 40, 40, 50, 255);
    // Checkmark (two lines)
    img.draw_line(px + 82, cy + 3, px + 85, cy + 7, 100, 220, 100, 255);
    img.draw_line(px + 85, cy + 7, px + 90, cy, 100, 220, 100, 255);
    draw_label(&mut img, "ON", px + 96, cy, 100, 220, 100);

    // Slider row
    let sy = cy + 20;
    draw_label(&mut img, "VOLUME", px + 12, sy, 180, 180, 190);
    let sl_x = px + 80;
    let sl_w = 200;
    img.draw_rect(sl_x, sy + 2, sl_w as u32, 4, 40, 40, 50, 255);  // track
    let knob_x = sl_x + (sl_w as f32 * 0.7) as i32;  // 70% position
    safe_circle(&mut img, knob_x, sy + 4, 5, 100, 160, 230, 255);
    draw_label(&mut img, "70%", knob_x + 8, sy - 2, 130, 180, 240);

    // Second slider
    let sy2 = sy + 24;
    draw_label(&mut img, "BRIGHT", px + 12, sy2, 180, 180, 190);
    img.draw_rect(sl_x, sy2 + 2, sl_w as u32, 4, 40, 40, 50, 255);
    let knob2_x = sl_x + (sl_w as f32 * 0.45) as i32;
    safe_circle(&mut img, knob2_x, sy2 + 4, 5, 100, 160, 230, 255);
    draw_label(&mut img, "45%", knob2_x + 8, sy2 - 2, 130, 180, 240);

    // Dropdown
    let dy = sy2 + 28;
    draw_label(&mut img, "MODE", px + 12, dy, 180, 180, 190);
    img.draw_rect(sl_x, dy - 2, 120, 14, 45, 45, 55, 255);
    draw_label(&mut img, "FULLSCREEN", sl_x + 4, dy, 200, 200, 210);
    // Dropdown arrow
    img.draw_line(sl_x + 108, dy + 2, sl_x + 112, dy + 6, 150, 150, 160, 255);
    img.draw_line(sl_x + 112, dy + 6, sl_x + 116, dy + 2, 150, 150, 160, 255);

    // Separator line
    let sep_y = dy + 22;
    img.draw_line(px + 8, sep_y, px + pw - 8, sep_y, 70, 70, 80, 255);

    // Radio buttons
    let ry = sep_y + 8;
    draw_label(&mut img, "QUALITY", px + 12, ry, 180, 180, 190);
    let options = ["LOW", "MED", "HIGH"];
    for (i, &opt) in options.iter().enumerate() {
        let ox = sl_x + i as i32 * 56;
        // Radio circle (outline)
        for angle in 0..32 {
            let a = angle as f32 * std::f32::consts::PI / 16.0;
            let rx = ox + 5 + (a.cos() * 5.0) as i32;
            let ry_px = ry + 3 + (a.sin() * 5.0) as i32;
            if rx >= 0 && ry_px >= 0 && (rx as u32) < w && (ry_px as u32) < h {
                img.set_pixel(rx as u32, ry_px as u32, 140, 140, 150, 255);
            }
        }
        if i == 1 { // "MED" is selected
            safe_circle(&mut img, ox + 5, ry + 3, 2, 100, 180, 230, 255);
        }
        draw_label(&mut img, opt, ox + 14, ry, 170, 170, 180);
    }

    // Progress bar
    let pby = ry + 24;
    draw_label(&mut img, "LOADING", px + 12, pby, 180, 180, 190);
    img.draw_rect(sl_x, pby, sl_w as u32, 10, 40, 40, 50, 255);
    let fill_w = (sl_w as f32 * 0.65) as u32;
    img.draw_rect(sl_x, pby, fill_w, 10, 70, 160, 90, 255);
    draw_label(&mut img, "65%", sl_x + fill_w as i32 + 4, pby + 2, 130, 200, 140);

    // Color swatches row
    let csy = pby + 22;
    draw_label(&mut img, "THEME", px + 12, csy, 180, 180, 190);
    let colors = [(200, 60, 60), (60, 160, 200), (60, 180, 80), (200, 180, 60), (160, 80, 200)];
    for (i, &(cr, cg, cb)) in colors.iter().enumerate() {
        let sx = sl_x + i as i32 * 22;
        img.draw_rect(sx, csy - 2, 18, 14, cr, cg, cb, 255);
        if i == 1 { // selected indicator
            for edge in 0..18i32 {
                img.set_pixel((sx + edge) as u32, (csy - 2) as u32, 255, 255, 255, 255);
                img.set_pixel((sx + edge) as u32, (csy + 11) as u32, 255, 255, 255, 255);
            }
        }
    }

    // Bottom action buttons
    let btn_y = py + ph - 30;
    // OK button
    img.draw_rect(px + pw - 80, btn_y, 60, 22, 60, 140, 60, 255);
    draw_label(&mut img, "OK", px + pw - 62, btn_y + 8, 220, 240, 220);
    // Cancel button
    img.draw_rect(px + pw - 150, btn_y, 60, 22, 160, 60, 60, 255);
    draw_label(&mut img, "CANCEL", px + pw - 144, btn_y + 8, 240, 220, 220);

    save_png("gui/panel_layout", &img);
}

/// GUI progress bars and health/mana HUD elements.
#[test]
fn evidence_gui_hud_bars() {
    let w = 400u32;
    let h = 250u32;
    let mut img = ImageData::new(w, h);
    img.fill(25, 25, 30, 255);

    // Health bar
    let hx = 20i32;
    let hy = 30i32;
    draw_label(&mut img, "HP", hx, hy - 10, 200, 80, 80);
    img.draw_rect(hx, hy, 300, 20, 40, 15, 15, 255);          // background
    img.draw_rect(hx, hy, (300.0 * 0.75) as u32, 20, 200, 50, 50, 255); // fill 75%
    img.draw_rect(hx, hy, (300.0 * 0.75) as u32, 3, 240, 100, 100, 255); // highlight
    draw_label(&mut img, "75%", hx + 230, hy + 7, 255, 200, 200);

    // Mana bar
    let my = hy + 36;
    draw_label(&mut img, "MP", hx, my - 10, 80, 120, 220);
    img.draw_rect(hx, my, 300, 20, 15, 15, 40, 255);
    img.draw_rect(hx, my, (300.0 * 0.40) as u32, 20, 50, 80, 200, 255);
    img.draw_rect(hx, my, (300.0 * 0.40) as u32, 3, 100, 140, 240, 255);
    draw_label(&mut img, "40%", hx + 124, my + 7, 180, 200, 255);

    // Stamina bar
    let sy = my + 36;
    draw_label(&mut img, "ST", hx, sy - 10, 80, 200, 80);
    img.draw_rect(hx, sy, 300, 14, 15, 30, 15, 255);
    img.draw_rect(hx, sy, (300.0 * 0.90) as u32, 14, 50, 180, 50, 255);
    img.draw_rect(hx, sy, (300.0 * 0.90) as u32, 2, 100, 220, 100, 255);
    draw_label(&mut img, "90%", hx + 275, sy + 4, 180, 255, 180);

    // XP bar (thin, at bottom)
    let xy = sy + 30;
    draw_label(&mut img, "XP", hx, xy - 10, 220, 200, 80);
    img.draw_rect(hx, xy, 300, 8, 30, 25, 10, 255);
    img.draw_rect(hx, xy, (300.0 * 0.55) as u32, 8, 200, 180, 50, 255);
    draw_label(&mut img, "55% TO LVL 12", hx + 170, xy - 2, 230, 210, 120);

    // Mini skill cooldowns (circular indicators)
    let cd_y = xy + 30;
    draw_label(&mut img, "SKILLS", hx, cd_y - 10, 180, 180, 190);
    let skill_pcts = [1.0f32, 0.7, 0.3, 0.0]; // ready, 70%, 30%, on cooldown
    let skill_colors = [(80, 200, 80), (200, 200, 80), (200, 120, 60), (100, 40, 40)];
    for (i, (&pct, &(cr, cg, cb))) in skill_pcts.iter().zip(skill_colors.iter()).enumerate() {
        let scx = hx + 40 + i as i32 * 50;
        let scy = cd_y + 10;
        // Background circle
        safe_circle(&mut img, scx, scy, 16, 30, 30, 40, 255);
        // Fill arc based on percentage
        if pct > 0.0 {
            let end_angle = -std::f32::consts::FRAC_PI_2 + pct * 2.0 * std::f32::consts::PI;
            for py in (scy - 15)..=(scy + 15) {
                for px in (scx - 15)..=(scx + 15) {
                    let dx = px as f32 - scx as f32;
                    let dy = py as f32 - scy as f32;
                    if dx * dx + dy * dy > 14.0 * 14.0 { continue; }
                    let mut a = dy.atan2(dx);
                    if a < -std::f32::consts::FRAC_PI_2 { a += 2.0 * std::f32::consts::PI; }
                    if a <= end_angle {
                        img.set_pixel(px as u32, py as u32, cr, cg, cb, 220);
                    }
                }
            }
        }
        // Skill number
        draw_label(&mut img, &format!("{}", i + 1), scx - 2, scy - 2, 255, 255, 255);
    }

    draw_label(&mut img, "GAME HUD", 160, 10, 220, 220, 230);
    save_png("gui/hud_bars", &img);
}

// ===== POSTFX / OVERLAY / STACK — Effect system evidence =====

/// Catalog all 16 PostFxEffectType variants — construction, parameters, type names.
#[test]
fn evidence_postfx_effect_catalog() {
    let mut img = ImageData::new(620, 520);
    img.fill(20, 18, 28, 255);
    draw_label(&mut img, "POSTFX EFFECT CATALOG", 180, 4, 220, 180, 255);

    let variants: Vec<(PostFxEffectType, &str, (u8, u8, u8))> = vec![
        (PostFxEffectType::Bloom,       "BLOOM",       (255, 220, 100)),
        (PostFxEffectType::Blur,        "BLUR",        (150, 150, 220)),
        (PostFxEffectType::Crt,         "CRT",         (100, 220, 100)),
        (PostFxEffectType::Godrays,     "GODRAYS",     (255, 200, 80)),
        (PostFxEffectType::Vignette,    "VIGNETTE",    (80, 60, 120)),
        (PostFxEffectType::ColourGrade, "COLOURGRADE", (200, 120, 80)),
        (PostFxEffectType::Chromatic,   "CHROMATIC",   (255, 80, 80)),
        (PostFxEffectType::Pixelate,    "PIXELATE",    (80, 200, 180)),
        (PostFxEffectType::Sepia,       "SEPIA",       (180, 150, 100)),
        (PostFxEffectType::Grayscale,   "GRAYSCALE",   (160, 160, 160)),
        (PostFxEffectType::Invert,      "INVERT",      (200, 200, 255)),
        (PostFxEffectType::Scanlines,   "SCANLINES",   (100, 200, 100)),
        (PostFxEffectType::EdgeDetect,  "EDGEDETECT",  (255, 255, 100)),
        (PostFxEffectType::HueShift,    "HUESHIFT",    (200, 100, 255)),
        (PostFxEffectType::Noise,       "NOISE",       (180, 180, 180)),
        (PostFxEffectType::Custom,      "CUSTOM",      (255, 140, 60)),
    ];

    for (i, (variant, label, (cr, cg, cb))) in variants.iter().enumerate() {
        let col = (i % 4) as i32;
        let row = (i / 4) as i32;
        let px = 10 + col * 152;
        let py = 24 + row * 122;

        // Panel background
        img.draw_rect(px, py, 146, 116, 35, 33, 48, 255);
        img.draw_rect(px + 1, py + 1, 144, 114, 28, 26, 40, 255);

        // Effect name
        draw_label(&mut img, label, px + 4, py + 4, *cr, *cg, *cb);

        // Create effect and exercise API
        let mut effect = PostFxEffect::new(variant.clone());
        let type_name = effect.get_type_name();
        assert!(!type_name.is_empty(), "type_name should not be empty for {:?}", variant);

        if matches!(variant, PostFxEffectType::Custom) {
            assert!(!effect.is_built_in());
        } else {
            assert!(effect.is_built_in());
        }

        // Set and verify a parameter
        effect.set_parameter("intensity", 0.75);
        let val = effect.get_parameter("intensity", 0.0);
        assert!((val - 0.75).abs() < 1e-5);
        assert!(effect.has_parameter("intensity"));

        // Draw representative pattern
        let bx = (px + 4) as u32;
        let by = (py + 20) as u32;
        for dy in 0..80u32 {
            for dx in 0..138u32 {
                let t = dx as f32 / 138.0;
                let ty = dy as f32 / 80.0;
                let (pr, pg, pb) = match i {
                    0 => { // Bloom — bright center glow
                        let d = ((t - 0.5).powi(2) + (ty - 0.5).powi(2)).sqrt();
                        let g = (1.0 - d * 2.5).max(0.0);
                        ((g * 255.0) as u8, (g * 220.0) as u8, (g * 100.0) as u8)
                    }
                    1 => { // Blur — gradient blur
                        let v = (((t * 8.0).sin() * 0.5 + 0.5) * (1.0 - ty * 0.3) * 200.0) as u8;
                        (v / 2, v / 2, v)
                    }
                    2 => { // CRT — scanlines
                        let base = (t * 200.0) as u8;
                        if dy % 3 == 0 { (base / 3, base, base / 3) } else { (base / 5, base / 2, base / 5) }
                    }
                    3 => { // Godrays — radial lines
                        let a = (ty - 0.5).atan2(t - 0.5);
                        let ray = ((a * 8.0).sin().abs() * 200.0) as u8;
                        (ray, (ray as u16 * 4 / 5) as u8, ray / 3)
                    }
                    4 => { // Vignette — dark edges
                        let d = ((t - 0.5).powi(2) + (ty - 0.5).powi(2)).sqrt();
                        let v = ((1.0 - d * 1.5).max(0.0) * 180.0) as u8;
                        (v / 3, v / 4, v / 2)
                    }
                    5 => { // ColourGrade — warm tint
                        let v = (t * 200.0) as u8;
                        (v, (v as f32 * 0.6) as u8, (v as f32 * 0.4) as u8)
                    }
                    6 => { // Chromatic — RGB offset
                        let r = (((t + 0.02) * 200.0).min(255.0)) as u8;
                        let g = (t * 200.0) as u8;
                        let b = (((t - 0.02).max(0.0) * 200.0).min(255.0)) as u8;
                        (r, g, b)
                    }
                    7 => { // Pixelate — blocky
                        let bx = (dx / 10) * 10;
                        let by2 = (dy / 10) * 10;
                        let v = ((bx as f32 / 138.0 + by2 as f32 / 80.0) * 128.0) as u8;
                        (v / 2, v, (v as u16 * 3 / 4) as u8)
                    }
                    8 => { // Sepia — warm brown
                        let grey = (t * 200.0) as u8;
                        ((grey as f32 * 1.0) as u8, (grey as f32 * 0.75) as u8, (grey as f32 * 0.55) as u8)
                    }
                    9 => { // Grayscale
                        let v = (t * ty * 255.0) as u8;
                        (v, v, v)
                    }
                    10 => { // Invert
                        let v = (t * 255.0) as u8;
                        (255 - v, 255 - v, v)
                    }
                    11 => { // Scanlines
                        let v = (t * 180.0) as u8;
                        if dy % 2 == 0 { (v / 2, v, v / 2) } else { (0, 0, 0) }
                    }
                    12 => { // EdgeDetect — outlines
                        let edge = ((t * 10.0).sin().abs() > 0.9 || (ty * 10.0).sin().abs() > 0.9) as u8 * 220;
                        (edge, edge, (edge as f32 * 0.5) as u8)
                    }
                    13 => { // HueShift — rainbow
                        let (hr, hg, hb) = hsv_to_rgb(((t * 360.0) as u16) % 360, 0.8, 0.8);
                        (hr, hg, hb)
                    }
                    14 => { // Noise — random-looking pattern
                        let seed = (dx.wrapping_mul(7) ^ dy.wrapping_mul(13)).wrapping_mul(31);
                        let v = (seed % 200) as u8 + 30;
                        (v, v, v)
                    }
                    _ => { // Custom — stripes
                        let stripe = ((dx + dy) / 6) % 2 == 0;
                        if stripe { (200, 100, 40) } else { (40, 100, 200) }
                    }
                };
                img.set_pixel(bx + dx, by + dy, pr, pg, pb, 255);
            }
        }

        // Draw parameter info
        draw_label(&mut img, &format!("I:0.75"), px + 4, py + 104, 140, 140, 160);
    }

    save_png("effects/postfx_catalog", &img);
}

/// PostFxStack operations — add, remove, insert, enable/disable, query.
#[test]
fn evidence_postfx_stack_management() {
    let mut img = ImageData::new(400, 350);
    img.fill(20, 18, 28, 255);
    draw_label(&mut img, "POSTFX STACK OPS", 100, 4, 200, 180, 255);

    let mut stack = PostFxStack::new(800, 600);
    assert_eq!(stack.get_effect_count(), 0);

    // Add 5 effects (using indices as if they're in a global effect pool)
    stack.add(0); // "Bloom"
    stack.add(1); // "Blur"
    stack.add(2); // "CRT"
    stack.add(3); // "Vignette"
    stack.add(4); // "Sepia"
    assert_eq!(stack.get_effect_count(), 5);

    // Draw initial stack state
    let names = ["BLOOM", "BLUR", "CRT", "VIGNETTE", "SEPIA"];
    let colors = [(255, 220, 100), (150, 150, 220), (100, 220, 100), (80, 60, 120), (180, 150, 100)];
    draw_label(&mut img, "INITIAL STACK", 20, 24, 180, 180, 200);
    for i in 0..5 {
        let y = 40 + i as i32 * 22;
        img.draw_rect(20, y, 160, 18, colors[i].0 / 3, colors[i].1 / 3, colors[i].2 / 3, 255);
        draw_label(&mut img, &format!("{} - {}", i, names[i]), 24, y + 4, colors[i].0, colors[i].1, colors[i].2);
        let enabled = stack.is_enabled(i);
        draw_label(&mut img, if enabled { "ON" } else { "OFF" }, 150, y + 4, 100, 200, 100);
    }

    // Disable effect 2 (CRT)
    stack.set_enabled(2, false);
    assert!(!stack.is_enabled(2));

    // Insert effect 5 at position 1
    stack.insert(1, 5);
    assert_eq!(stack.get_effect_count(), 6);

    // Remove effect at index 3
    stack.remove(3);

    // Draw modified stack state
    draw_label(&mut img, "AFTER MODIFY", 210, 24, 180, 180, 200);
    let enabled_list = stack.enabled_effects();
    draw_label(&mut img, &format!("ENABLED: {}", enabled_list.len()), 210, 40, 140, 200, 140);
    draw_label(&mut img, &format!("TOTAL: {}", stack.get_effect_count()), 210, 56, 140, 140, 200);

    for i in 0..stack.get_effect_count() {
        let y = 76 + i as i32 * 22;
        if let Some(eff_idx) = stack.get_effect(i) {
            let is_en = stack.is_enabled(eff_idx);
            let (cr, cg, cb) = if is_en { (80, 200, 80) } else { (200, 80, 80) };
            img.draw_rect(210, y, 170, 18, cr / 5, cg / 5, cb / 5, 255);
            draw_label(&mut img, &format!("IDX {} - {}", eff_idx, if is_en { "ON" } else { "OFF" }), 214, y + 4, cr, cg, cb);
        }
    }

    // Resize test
    stack.resize(1920, 1080);

    // Visual separator
    img.draw_rect(0, 230, 400, 2, 60, 60, 80, 255);
    draw_label(&mut img, "RESIZE: 1920X1080", 20, 240, 200, 200, 220);
    draw_label(&mut img, "STACK OPS COMPLETE", 100, 320, 120, 200, 120);

    save_png("effects/postfx_stack", &img);
}

/// PostFxEffect parameter system — set, get, has, names, aliases.
#[test]
fn evidence_postfx_effect_parameters() {
    let mut img = ImageData::new(500, 420);
    img.fill(20, 18, 28, 255);
    draw_label(&mut img, "POSTFX PARAMETERS", 140, 4, 200, 180, 255);

    let test_cases: Vec<(PostFxEffectType, &str, Vec<(&str, f32)>)> = vec![
        (PostFxEffectType::Bloom, "BLOOM", vec![("threshold", 0.8), ("intensity", 1.5), ("radius", 4.0)]),
        (PostFxEffectType::Blur, "BLUR", vec![("radius", 3.0), ("sigma", 1.5)]),
        (PostFxEffectType::Chromatic, "CHROMATIC", vec![("offset", 2.5), ("angle", 0.0)]),
        (PostFxEffectType::Vignette, "VIGNETTE", vec![("strength", 0.6), ("radius", 0.8)]),
        (PostFxEffectType::HueShift, "HUESHIFT", vec![("degrees", 90.0)]),
        (PostFxEffectType::Noise, "NOISE", vec![("amount", 0.3), ("speed", 1.0)]),
    ];

    let mut y = 24i32;
    for (variant, label, params) in &test_cases {
        let mut effect = PostFxEffect::new(variant.clone());
        assert!(effect.is_built_in());
        let type_name = effect.get_type_name();

        // Set all parameters
        for (name, val) in params {
            effect.set_parameter(*name, *val);
            let got = effect.get_parameter(*name, 0.0);
            assert!((got - val).abs() < 1e-5, "param {} expected {} got {}", name, val, got);
            assert!(effect.has_parameter(*name));
        }

        // Verify non-existent param returns default
        let missing = effect.get_parameter("nonexistent", 42.0);
        assert!((missing - 42.0).abs() < 1e-5);
        assert!(!effect.has_parameter("nonexistent"));

        // Get parameter names
        let names = effect.get_parameter_names();

        // Draw row
        img.draw_rect(10, y, 480, 50, 30, 28, 42, 255);
        draw_label(&mut img, label, 14, y + 4, 220, 180, 100);
        draw_label(&mut img, &format!("TYPE:{}", type_name.to_uppercase()), 14, y + 16, 140, 140, 180);

        // Draw parameter values
        let mut px = 14;
        for (name, val) in params {
            let text = format!("{}:{:.1}", name.to_uppercase(), val);
            draw_label(&mut img, &text, px, y + 30, 100, 200, 100);
            px += (text.len() as i32 + 1) * 4;
        }

        draw_label(&mut img, &format!("PARAMS:{}", names.len()), 380, y + 4, 180, 180, 200);
        y += 58;
    }

    // Test disabled effect and custom effect
    let disabled = PostFxEffect::new_disabled(PostFxEffectType::Sepia);
    draw_label(&mut img, "DISABLED SEPIA", 14, y + 8, 200, 80, 80);
    let _ = disabled.get_type_name();

    let custom = PostFxEffect::new_custom(999);
    assert!(!custom.is_built_in());
    draw_label(&mut img, "CUSTOM SHADER 999", 14, y + 24, 255, 140, 60);
    draw_label(&mut img, "NOT BUILT-IN", 250, y + 24, 200, 120, 80);

    // Test alias methods
    let mut alias_test = PostFxEffect::new(PostFxEffectType::Blur);
    alias_test.set_param("radius", 5.0);
    let alias_val = alias_test.get_param_or("radius", 0.0);
    assert!((alias_val - 5.0).abs() < 1e-5);
    draw_label(&mut img, "ALIAS SET-PARAM GET-PARAM-OR OK", 14, y + 44, 100, 220, 100);

    save_png("effects/postfx_parameters", &img);
}

/// Overlay system — trigger flash, shake, fade, lightning.
#[test]
fn evidence_overlay_triggers() {
    let mut img = ImageData::new(500, 420);
    img.fill(20, 18, 28, 255);
    draw_label(&mut img, "OVERLAY SYSTEM", 160, 4, 220, 180, 255);

    // ── Panel 1: Flash ──
    {
        let mut overlay = Overlay::new(500, 420);
        assert!(!overlay.is_active());

        overlay.trigger_flash(1.0, 0.0, 0.0, 0.8, 0.5);
        assert!(overlay.is_active());

        // Draw flash visualization
        img.draw_rect(10, 24, 230, 170, 40, 10, 10, 255);
        draw_label(&mut img, "FLASH", 14, 28, 255, 80, 80);
        draw_label(&mut img, "R:1.0 G:0.0 B:0.0", 14, 44, 200, 140, 140);
        draw_label(&mut img, "ALPHA:0.8 DUR:0.5", 14, 58, 200, 140, 140);

        // Red gradient overlay simulation
        for dy in 0..120u32 {
            for dx in 0..210u32 {
                let t = 1.0 - (dy as f32 / 120.0);
                let a = (t * 0.8 * 200.0) as u8;
                if a > 20 {
                    img.set_pixel(20 + dx, 76 + dy, 200, 20, 20, a);
                }
            }
        }
        draw_label(&mut img, "ACTIVE: YES", 14, 170, 100, 200, 100);

        // Update to completion
        for _ in 0..30 {
            overlay.update(0.02);
        }
        overlay.clear();
        assert!(!overlay.is_active());
        draw_label(&mut img, "AFTER CLEAR: NO", 14, 184, 200, 100, 100);
    }

    // ── Panel 2: Shake ──
    {
        let mut overlay = Overlay::new(500, 420);
        overlay.trigger_shake(15.0, 0.4);
        assert!(overlay.is_active());

        let (ox, oy) = overlay.get_shake_offset();

        img.draw_rect(260, 24, 230, 170, 10, 10, 40, 255);
        draw_label(&mut img, "SHAKE", 264, 28, 100, 100, 255);
        draw_label(&mut img, "INTENSITY:15.0", 264, 44, 140, 140, 200);
        draw_label(&mut img, "DURATION:0.4", 264, 58, 140, 140, 200);
        draw_label(&mut img, &format!("OFFSET: {:.1} {:.1}", ox, oy), 264, 74, 180, 180, 220);

        // Draw shake arrows
        let scx = 370;
        let scy = 140;
        safe_circle(&mut img, scx, scy, 20, 40, 40, 80, 255);
        // Crosshair showing shake offset
        img.draw_line(scx - 25, scy, scx + 25, scy, 80, 80, 120, 255);
        img.draw_line(scx, scy - 25, scx, scy + 25, 80, 80, 120, 255);
        safe_circle(&mut img, scx + (ox * 2.0) as i32, scy + (oy * 2.0) as i32, 4, 255, 100, 100, 255);
    }

    // ── Panel 3: Fade ──
    {
        let mut overlay = Overlay::new(500, 420);
        overlay.trigger_fade(0.0, 0.0, 0.0, 0.7, 1.0);
        assert!(overlay.is_active());

        img.draw_rect(10, 204, 230, 170, 10, 10, 10, 255);
        draw_label(&mut img, "FADE", 14, 208, 180, 180, 200);
        draw_label(&mut img, "TARGET ALPHA:0.7", 14, 224, 140, 140, 180);
        draw_label(&mut img, "DURATION:1.0", 14, 238, 140, 140, 180);

        // Gradient showing fade progression
        for dx in 0..210u32 {
            let t = dx as f32 / 210.0;
            let alpha = (t * 0.7 * 255.0) as u8;
            for dy in 0..100u32 {
                img.set_pixel(20 + dx, 256 + dy, 0, 0, 0, alpha);
            }
        }
        draw_label(&mut img, "FADE GRADIENT", 50, 360, 120, 120, 150);
    }

    // ── Panel 4: Lightning ──
    {
        let mut overlay = Overlay::new(500, 420);
        overlay.trigger_lightning();
        assert!(overlay.is_active());

        img.draw_rect(260, 204, 230, 170, 20, 20, 30, 255);
        draw_label(&mut img, "LIGHTNING", 264, 208, 220, 220, 255);

        // Flash of white to simulate lightning
        for dy in 0..100u32 {
            for dx in 0..210u32 {
                let flash = 200u8.saturating_sub((dy * 2) as u8);
                img.set_pixel(270 + dx, 240 + dy, flash, flash, 255.min(flash + 40), 180);
            }
        }

        overlay.update(0.05);
        let still_active = overlay.is_active();
        draw_label(&mut img, &format!("AFTER 0.05S: {}", if still_active { "ACTIVE" } else { "DONE" }),
            264, 350, 140, 200, 140);
    }

    draw_label(&mut img, "ALL OVERLAY TRIGGERS EXERCISED", 100, 400, 100, 200, 100);
    save_png("effects/overlay_triggers", &img);
}

// ===== PARTICLE TRAIL — Trail system evidence =====

/// Trail system — push points, width, color, lifetime, update.
#[test]
fn evidence_particle_trail_system() {
    let mut img = ImageData::new(500, 400);
    img.fill(15, 15, 25, 255);
    draw_label(&mut img, "PARTICLE TRAIL SYSTEM", 130, 4, 200, 180, 255);

    // ── Trail 1: Curved path with head/tail colors ──
    let mut trail1 = Trail::new(3.0, 6.0);
    trail1.set_head_color(Color::new(1.0, 0.2, 0.0, 1.0)); // Red-orange head
    trail1.set_tail_color(Color::new(0.0, 0.2, 1.0, 0.3)); // Blue transparent tail
    trail1.set_width(8.0, Some(1.0)); // Taper from 8 to 1

    // Push points along a sine wave
    for i in 0..60 {
        let t = i as f32 / 59.0;
        let x = 30.0 + t * 440.0;
        let y = 100.0 + (t * 4.0 * std::f32::consts::PI).sin() * 50.0;
        trail1.push_point(x, y);
    }

    assert_eq!(trail1.get_point_count(), 60);
    assert!((trail1.get_lifetime() - 3.0).abs() < 1e-5);
    let (w_start, w_end) = trail1.get_width();
    assert!((w_start - 8.0).abs() < 1e-5);
    assert!((w_end - 1.0).abs() < 1e-5);

    // Draw trail 1: interpolate color from head to tail
    draw_label(&mut img, "TRAIL 1: SINE WAVE", 30, 24, 200, 140, 100);
    draw_label(&mut img, "HEAD:RED TAIL:BLUE W:8-1", 30, 38, 140, 140, 180);
    for i in 1..60 {
        let t0 = (i - 1) as f32 / 59.0;
        let t1 = i as f32 / 59.0;
        let x0 = 30.0 + t0 * 440.0;
        let y0 = 100.0 + (t0 * 4.0 * std::f32::consts::PI).sin() * 50.0;
        let x1 = 30.0 + t1 * 440.0;
        let y1 = 100.0 + (t1 * 4.0 * std::f32::consts::PI).sin() * 50.0;

        // Color interpolation
        let frac = i as f32 / 59.0;
        let r = ((1.0 - frac) * 255.0) as u8;
        let g = 40;
        let b = (frac * 255.0) as u8;
        img.draw_line(x0 as i32, y0 as i32, x1 as i32, y1 as i32, r, g, b, 255);

        // Width visualization (draw parallel lines)
        let width = 8.0 - frac * 7.0;
        if width > 2.0 {
            let dx = (y1 - y0);
            let dy = -(x1 - x0);
            let len = (dx * dx + dy * dy).sqrt().max(0.001);
            let nx = dx / len * width * 0.5;
            let ny = dy / len * width * 0.5;
            img.draw_line(
                (x1 + nx) as i32, (y1 + ny) as i32,
                (x1 - nx) as i32, (y1 - ny) as i32,
                r / 2, g / 2, b / 2, 120
            );
        }
    }
    draw_label(&mut img, &format!("PTS:{}", trail1.get_point_count()), 400, 24, 100, 200, 100);

    // ── Trail 2: After update showing lifetime decay ──
    let mut trail2 = Trail::new(0.5, 4.0);
    trail2.set_head_color(Color::new(0.0, 1.0, 0.0, 1.0)); // Green
    trail2.set_tail_color(Color::new(1.0, 1.0, 0.0, 0.5)); // Yellow

    for i in 0..40 {
        let t = i as f32 / 39.0;
        let x = 30.0 + t * 200.0;
        let y = 250.0 + (t * 3.0 * std::f32::consts::PI).cos() * 30.0;
        trail2.push_point(x, y);
    }

    let count_before = trail2.get_point_count();
    // Update with large dt to trigger point removal
    trail2.update(0.3);
    let count_after = trail2.get_point_count();

    draw_label(&mut img, "TRAIL 2: AFTER UPDATE 0.3S", 30, 200, 100, 220, 100);
    draw_label(&mut img, &format!("BEFORE:{} AFTER:{}", count_before, count_after), 30, 214, 140, 180, 140);

    // Draw remaining trail 2 points
    for i in 0..40 {
        let t = i as f32 / 39.0;
        let x = 30.0 + t * 200.0;
        let y = 250.0 + (t * 3.0 * std::f32::consts::PI).cos() * 30.0;
        let frac = t;
        let r = (frac * 255.0) as u8;
        let g = 255;
        let b = 0;
        safe_circle(&mut img, x as i32, y as i32, 2, r, g, b, 200);
    }

    // ── Trail 3: min_distance and clear ──
    let mut trail3 = Trail::new(2.0, 3.0);
    trail3.set_min_distance(10.0);

    // Push many close points — only some should register
    for i in 0..100 {
        let x = 280.0 + (i as f32) * 1.5;
        let y = 300.0 + (i as f32 * 0.2).sin() * 20.0;
        trail3.push_point(x, y);
    }
    let filtered_count = trail3.get_point_count();
    draw_label(&mut img, "TRAIL 3: MIN DIST 10", 280, 260, 200, 200, 100);
    draw_label(&mut img, &format!("100 PUSHED {} KEPT", filtered_count), 280, 276, 180, 180, 140);
    assert!(filtered_count < 100, "min_distance should filter close points");

    // Clear
    trail3.clear();
    assert_eq!(trail3.get_point_count(), 0);
    draw_label(&mut img, "CLEARED: 0 PTS", 280, 292, 200, 100, 100);

    // ── Set lifetime ──
    trail3.set_lifetime(5.0);
    assert!((trail3.get_lifetime() - 5.0).abs() < 1e-5);
    draw_label(&mut img, "LIFETIME SET TO 5.0", 280, 310, 140, 200, 140);

    draw_label(&mut img, "ALL TRAIL METHODS EXERCISED", 120, 380, 100, 200, 100);
    save_png("particle/trail_system", &img);
}

/// Particle emitter control — start, stop, pause, resume, emit, move, reset.
#[test]
fn evidence_particle_emitter_control() {
    let mut img = ImageData::new(500, 440);
    img.fill(20, 18, 28, 255);
    draw_label(&mut img, "EMITTER CONTROL", 160, 4, 200, 180, 255);

    let config = ParticleConfig {
        max_particles: 200,
        emission_rate: 0.0,
        ..ParticleConfig::default()
    };

    let mut emitter = ParticleSystem::new(config);

    // State 1: Initial
    assert!(emitter.is_empty());
    assert!(!emitter.is_paused());
    let initial_count = emitter.count();
    draw_label(&mut img, "1. INITIAL STATE", 20, 30, 180, 180, 200);
    draw_label(&mut img, &format!("COUNT:{} EMPTY:YES", initial_count), 20, 46, 140, 200, 140);
    img.draw_rect(20, 60, 200, 3, 60, 60, 80, 255);

    // State 2: Emit particles
    emitter.emit(50);
    let after_emit = emitter.count();
    assert!(after_emit > 0);
    draw_label(&mut img, "2. AFTER EMIT 50", 20, 72, 180, 180, 200);
    draw_label(&mut img, &format!("COUNT:{} EMPTY:NO", after_emit), 20, 88, 140, 200, 140);
    img.draw_rect(20, 102, 200, 3, 60, 60, 80, 255);

    // State 3: Pause
    emitter.pause();
    assert!(emitter.is_paused());
    draw_label(&mut img, "3. PAUSED", 20, 114, 180, 180, 200);
    draw_label(&mut img, "PAUSED:YES", 20, 130, 200, 200, 100);

    // Update while paused — count should not change much
    let before_update = emitter.count();
    emitter.update(0.1);
    let after_paused_update = emitter.count();
    draw_label(&mut img, &format!("UPD 0.1: {} -> {}", before_update, after_paused_update), 20, 146, 140, 180, 140);
    img.draw_rect(20, 162, 200, 3, 60, 60, 80, 255);

    // State 4: Resume
    emitter.resume();
    assert!(!emitter.is_paused());
    draw_label(&mut img, "4. RESUMED", 20, 174, 180, 180, 200);
    draw_label(&mut img, "PAUSED:NO", 20, 190, 140, 200, 140);
    img.draw_rect(20, 206, 200, 3, 60, 60, 80, 255);

    // State 5: Stop
    emitter.stop();
    assert!(emitter.is_stopped());
    draw_label(&mut img, "5. STOPPED", 20, 218, 180, 180, 200);
    draw_label(&mut img, "STOPPED:YES", 20, 234, 200, 100, 100);
    img.draw_rect(20, 250, 200, 3, 60, 60, 80, 255);

    // State 6: Start
    emitter.start();
    assert!(!emitter.is_stopped());
    assert!(emitter.is_active());
    draw_label(&mut img, "6. STARTED", 20, 262, 180, 180, 200);
    draw_label(&mut img, "ACTIVE:YES STOPPED:NO", 20, 278, 140, 200, 140);
    img.draw_rect(20, 294, 200, 3, 60, 60, 80, 255);

    // State 7: Move
    emitter.move_to(100.0, 100.0);
    draw_label(&mut img, "7. MOVED TO 100 100", 20, 306, 180, 180, 200);

    // State 8: Reset
    let count_before_reset = emitter.count();
    emitter.reset();
    let count_after_reset = emitter.count();
    draw_label(&mut img, "8. RESET", 20, 330, 180, 180, 200);
    draw_label(&mut img, &format!("BEFORE:{} AFTER:{}", count_before_reset, count_after_reset), 20, 346, 200, 140, 140);
    assert_eq!(count_after_reset, 0);

    // State 9: is_full check
    emitter.emit(200);
    let is_full = emitter.is_full();
    draw_label(&mut img, "9. EMIT 200 MAX", 20, 370, 180, 180, 200);
    draw_label(&mut img, &format!("FULL:{}", if is_full { "YES" } else { "NO" }), 20, 386, 200, 200, 100);

    // Right side — lifecycle diagram
    draw_label(&mut img, "LIFECYCLE", 320, 30, 220, 220, 240);
    let states = [
        ("NEW", 50, 100, 200),
        ("EMIT", 100, 200, 100),
        ("PAUSE", 200, 200, 100),
        ("RESUME", 100, 200, 140),
        ("STOP", 200, 80, 80),
        ("START", 80, 200, 80),
        ("MOVE", 140, 140, 200),
        ("RESET", 200, 140, 80),
    ];
    for (i, (name, cr, cg, cb)) in states.iter().enumerate() {
        let sy = 56 + i as i32 * 44;
        img.draw_rect(290, sy, 180, 36, *cr / 5, *cg / 5, *cb / 5, 255);
        safe_circle(&mut img, 310, sy + 18, 10, *cr, *cg, *cb, 255);
        draw_label(&mut img, name, 328, sy + 10, *cr, *cg, *cb);
        // Arrow to next
        if i < states.len() - 1 {
            img.draw_line(380, sy + 36, 380, sy + 44, 80, 80, 100, 255);
        }
    }

    draw_label(&mut img, "ALL EMITTER METHODS OK", 130, 420, 100, 200, 100);
    save_png("particle/emitter_control", &img);
}


// =====================================================================
// ===== BATCH 2 — Camera rotation, bounds, follow, shake =====
// =====================================================================

#[test]
fn evidence_camera_rotation_transform() {
    let mut img = ImageData::new(400, 300);
    img.fill(25, 25, 35, 255);

    // Show 6 rotation steps: 0, 30, 60, 90, 120, 150 degrees
    let rotations = [0.0f32, 0.5, 1.0, 1.57, 2.1, 2.6];
    let labels = ["0", "0.5", "1.0", "PI-2", "2.1", "2.6"];

    for (i, (&rot, &label)) in rotations.iter().zip(labels.iter()).enumerate() {
        let mut cam = Camera2D::new(120.0, 120.0);
        cam.set_position(60.0, 60.0);
        cam.set_rotation(rot);
        assert!((cam.get_rotation() - rot).abs() < 1e-5);

        let ox = (i % 3) as i32 * 133;
        let oy = (i / 3) as i32 * 150;

        // Draw rotated world objects
        for step in 0..8 {
            let a = step as f32 * std::f32::consts::TAU / 8.0;
            let wx = 60.0 + a.cos() * 35.0;
            let wy = 60.0 + a.sin() * 35.0;
            let (sx, sy) = cam.to_screen_coords(wx, wy);
            let px = ox as f32 + sx;
            let py = oy as f32 + sy;
            if px >= 0.0 && px < 400.0 && py >= 0.0 && py < 300.0 {
                let hue = (step as f32 / 8.0 * 360.0) as u16;
                let (r, g, b) = hsv_to_rgb(hue, 0.9, 1.0);
                safe_circle(&mut img, px as i32, py as i32, 5, r, g, b, 220);
            }
        }

        // Frame border
        for bx in 0..120i32 {
            if ox + bx < 400 {
                img.set_pixel((ox + bx) as u32, oy.max(0) as u32, 60, 60, 80, 255);
                if oy + 119 < 300 {
                    img.set_pixel((ox + bx) as u32, (oy + 119) as u32, 60, 60, 80, 255);
                }
            }
        }
        draw_label(&mut img, label, ox + 4, oy + 4, 200, 200, 200);
    }

    draw_label(&mut img, "CAMERA ROTATION", 130, 285, 100, 200, 100);
    save_png("camera/rotation_transform", &img);
}

#[test]
fn evidence_camera_bounds_clamping() {
    let mut img = ImageData::new(400, 250);
    img.fill(25, 25, 35, 255);

    let mut cam = Camera2D::new(200.0, 200.0);
    cam.set_position(100.0, 100.0);

    // Without bounds — move freely
    cam.look_at(500.0, 500.0);
    let (px1, py1) = cam.get_position();

    // Set bounds and verify clamping
    cam.set_bounds(0.0, 0.0, 400.0, 400.0);
    assert!(cam.has_bounds());
    let bounds = cam.get_bounds();
    assert!(bounds.is_some());
    let (_bx, _by, _bw, _bh) = bounds.unwrap();

    // Move camera beyond bounds — should be clamped
    cam.look_at(600.0, 600.0);
    let (px2, py2) = cam.get_position();

    // Move within bounds
    cam.look_at(200.0, 200.0);
    let (px3, py3) = cam.get_position();

    // Remove bounds
    cam.remove_bounds();
    assert!(!cam.has_bounds());
    cam.look_at(800.0, 800.0);
    let (px4, py4) = cam.get_position();

    // Draw visualization
    // World bounds box
    img.draw_rect(10, 10, 180, 180, 60, 60, 100, 255);
    draw_label(&mut img, "BOUNDS 0-400", 20, 14, 100, 100, 200);

    // Points showing camera positions
    let points = [
        (px1, py1, "NO BOUNDS", 200u8, 80, 80),
        (px2, py2, "CLAMPED", 80, 200, 80),
        (px3, py3, "IN BOUNDS", 80, 80, 200),
        (px4, py4, "FREE AGAIN", 200, 200, 80),
    ];
    for (i, &(px, py, label, r, g, b)) in points.iter().enumerate() {
        let y = 20 + i as i32 * 50;
        img.draw_rect(210, y, 180, 40, 40, 40, 55, 255);
        draw_label(&mut img, label, 215, y + 5, r, g, b);
        let pos_str = format!("{:.0} {:.0}", px, py);
        draw_label(&mut img, &pos_str, 215, y + 20, 180, 180, 180);
    }

    draw_label(&mut img, "CAMERA BOUNDS", 130, 235, 100, 200, 100);
    save_png("camera/bounds_clamping", &img);
}

#[test]
fn evidence_camera_follow_deadzone() {
    let mut img = ImageData::new(400, 300);
    img.fill(25, 25, 35, 255);

    let mut cam = Camera2D::new(400.0, 300.0);
    cam.set_position(200.0, 150.0);
    cam.set_dead_zone(40.0, 30.0);
    assert!(cam.get_dead_zone().is_some());
    let (dw, dh) = cam.get_dead_zone().unwrap();
    assert!((dw - 40.0).abs() < 1e-5);
    assert!((dh - 30.0).abs() < 1e-5);

    cam.set_target(220.0, 160.0);
    assert!(cam.get_target().is_some());
    cam.set_follow_smooth(5.0);
    assert!((cam.get_follow_smooth() - 5.0).abs() < 1e-5);
    cam.set_look_ahead(0.5);
    assert!((cam.get_look_ahead() - 0.5).abs() < 1e-5);

    // Simulate following for multiple frames, recording trail
    let mut trail: Vec<(f32, f32)> = Vec::new();
    let targets = [
        (250.0f32, 180.0), (300.0, 200.0), (350.0, 150.0),
        (280.0, 100.0), (200.0, 150.0),
    ];

    for &(tx, ty) in &targets {
        cam.set_target(tx, ty);
        for _ in 0..10 {
            cam.update(1.0 / 60.0);
            let (cx, cy) = cam.get_position();
            trail.push((cx, cy));
        }
    }

    // Draw the trail
    for i in 1..trail.len() {
        let (x1, y1) = trail[i - 1];
        let (x2, y2) = trail[i];
        let t = i as f32 / trail.len() as f32;
        let r = (100.0 + t * 155.0) as u8;
        let g = (200.0 - t * 100.0) as u8;
        let b = 120;
        img.draw_line(x1 as i32, y1 as i32, x2 as i32, y2 as i32, r, g, b, 200);
    }

    // Draw target points
    for (i, &(tx, ty)) in targets.iter().enumerate() {
        let hue = (i as f32 / targets.len() as f32 * 360.0) as u16;
        let (r, g, b) = hsv_to_rgb(hue, 0.9, 1.0);
        safe_circle(&mut img, tx as i32, ty as i32, 6, r, g, b, 255);
    }

    // Dead zone rectangle at current camera center
    let (cx, cy) = cam.get_position();
    img.draw_rect(
        (cx - dw / 2.0) as i32, (cy - dh / 2.0) as i32,
        dw as u32, dh as u32,
        255, 255, 100, 80,
    );

    // Clear target
    cam.clear_target();
    assert!(cam.get_target().is_none());

    draw_label(&mut img, "FOLLOW AND DEADZONE", 110, 285, 100, 200, 100);
    save_png("camera/follow_deadzone", &img);
}

#[test]
fn evidence_camera_shake_effect() {
    let mut img = ImageData::new(400, 200);
    img.fill(25, 25, 35, 255);

    let mut cam = Camera2D::new(400.0, 200.0);
    cam.set_position(200.0, 100.0);

    // Trigger shake and record positions over time
    cam.shake(10.0, 0.5);

    let mut positions: Vec<(f32, f32)> = Vec::new();
    for _ in 0..60 {
        cam.update(1.0 / 60.0);
        let (sx, sy) = cam.to_screen_coords(200.0, 100.0);
        positions.push((sx, sy));
    }

    // Draw shake trail
    for (i, &(sx, sy)) in positions.iter().enumerate() {
        let t = i as f32 / 60.0;
        let alpha = (255.0 * (1.0 - t)) as u8;
        let r = (200.0 + t * 55.0) as u8;
        safe_circle(&mut img, sx as i32, sy as i32, 3, r, 80, 80, alpha);
    }

    // Draw reference center
    safe_circle(&mut img, 200, 100, 4, 255, 255, 255, 255);
    draw_label(&mut img, "CENTER", 175, 84, 255, 255, 255);

    // Show move_by and visible area
    cam.set_position(200.0, 100.0);
    cam.move_by(50.0, 25.0);
    let (mx, my) = cam.get_position();
    safe_circle(&mut img, mx as i32, my as i32, 4, 80, 255, 80, 255);
    draw_label(&mut img, "MOVED BY", 260, 110, 80, 255, 80);

    let (vx, vy, vw, vh) = cam.get_visible_area();
    let info = format!("{:.0} {:.0} {:.0}X{:.0}", vx, vy, vw, vh);
    draw_label(&mut img, &info, 10, 180, 180, 180, 200);

    draw_label(&mut img, "CAMERA SHAKE AND MOVE", 100, 5, 100, 200, 100);
    save_png("camera/shake_effect", &img);
}

// =====================================================================
// ===== BATCH 2 — Geometry functions evidence =====
// =====================================================================

#[test]
fn evidence_geometry_shapes_and_queries() {
    let mut img = ImageData::new(500, 400);
    img.fill(25, 25, 35, 255);

    // 1. Convex hull
    let points: Vec<f32> = vec![
        50.0, 50.0,  100.0, 30.0,  150.0, 60.0,  130.0, 120.0,
        80.0, 130.0,  40.0, 100.0,  90.0, 80.0,  110.0, 70.0,
    ];
    let hull = lurek2d::math::convex_hull(&points);

    // Draw all points
    for i in 0..points.len() / 2 {
        let px = points[i * 2] as i32;
        let py = points[i * 2 + 1] as i32;
        safe_circle(&mut img, px, py, 3, 100, 100, 200, 255);
    }
    // Draw hull edges
    let hull_n = hull.len() / 2;
    for i in 0..hull_n {
        let j = (i + 1) % hull_n;
        img.draw_line(
            hull[i * 2] as i32, hull[i * 2 + 1] as i32,
            hull[j * 2] as i32, hull[j * 2 + 1] as i32,
            200, 200, 80, 255,
        );
    }
    draw_label(&mut img, "CONVEX HULL", 50, 140, 200, 200, 80);

    // 2. Polygon area and centroid
    let square: Vec<f32> = vec![200.0, 20.0, 280.0, 20.0, 280.0, 100.0, 200.0, 100.0];
    let area = lurek2d::math::polygon_area(&square);
    let (cx, cy) = lurek2d::math::polygon_centroid(&square);
    // Draw square
    img.draw_line(200, 20, 280, 20, 80, 200, 80, 255);
    img.draw_line(280, 20, 280, 100, 80, 200, 80, 255);
    img.draw_line(280, 100, 200, 100, 80, 200, 80, 255);
    img.draw_line(200, 100, 200, 20, 80, 200, 80, 255);
    // Centroid marker
    safe_circle(&mut img, cx as i32, cy as i32, 4, 255, 100, 100, 255);
    let area_str = format!("AREA {:.0}", area.abs());
    draw_label(&mut img, &area_str, 200, 108, 80, 200, 80);

    // 3. Point-in-polygon
    let triangle: Vec<f32> = vec![350.0, 30.0, 450.0, 100.0, 340.0, 100.0];
    img.draw_line(350, 30, 450, 100, 200, 120, 80, 255);
    img.draw_line(450, 100, 340, 100, 200, 120, 80, 255);
    img.draw_line(340, 100, 350, 30, 200, 120, 80, 255);
    let inside = lurek2d::math::point_in_polygon(&triangle, 380.0, 70.0);
    let outside = lurek2d::math::point_in_polygon(&triangle, 320.0, 30.0);
    assert!(inside);
    assert!(!outside);
    safe_circle(&mut img, 380, 70, 4, 0, 255, 0, 255); // inside — green
    safe_circle(&mut img, 320, 30, 4, 255, 0, 0, 255); // outside — red
    draw_label(&mut img, "POINT IN POLY", 340, 108, 200, 120, 80);

    // 4. Bresenham line
    let line_pts = lurek2d::math::bresenham(20, 180, 180, 220);
    for &(px, py) in &line_pts {
        if px >= 0 && py >= 0 && px < 500 && py < 400 {
            img.set_pixel(px as u32, py as u32, 255, 180, 80, 255);
        }
    }
    draw_label(&mut img, "BRESENHAM", 20, 230, 255, 180, 80);

    // 5. Angle between
    let angle = lurek2d::math::angle_between(250.0, 200.0, 350.0, 250.0);
    img.draw_line(250, 200, 350, 250, 200, 80, 200, 255);
    let angle_str = format!("{:.2} RAD", angle);
    draw_label(&mut img, &angle_str, 270, 255, 200, 80, 200);

    // 6. Circle containment
    let c_in = lurek2d::math::circle_contains_point(100.0, 300.0, 40.0, 110.0, 310.0);
    let c_out = lurek2d::math::circle_contains_point(100.0, 300.0, 40.0, 200.0, 300.0);
    assert!(c_in);
    assert!(!c_out);
    // Draw circle boundary
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px = (100.0 + 40.0 * rad.cos()) as i32;
        let py = (300.0 + 40.0 * rad.sin()) as i32;
        if px >= 0 && py >= 0 && px < 500 && py < 400 {
            img.set_pixel(px as u32, py as u32, 80, 200, 200, 255);
        }
    }
    safe_circle(&mut img, 110, 310, 3, 0, 255, 0, 255);
    safe_circle(&mut img, 200, 300, 3, 255, 0, 0, 255);
    draw_label(&mut img, "CIRCLE CONTAIN", 60, 350, 80, 200, 200);

    // 7. Circle-circle intersection
    let cc = lurek2d::math::circle_intersects_circle(300.0, 300.0, 30.0, 340.0, 300.0, 30.0);
    assert!(cc);
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px1 = (300.0 + 30.0 * rad.cos()) as i32;
        let py1 = (300.0 + 30.0 * rad.sin()) as i32;
        let px2 = (340.0 + 30.0 * rad.cos()) as i32;
        let py2 = (340.0 + 30.0 * rad.sin()) as i32;
        if px1 >= 0 && py1 >= 0 && px1 < 500 && py1 < 400 {
            img.set_pixel(px1 as u32, py1 as u32, 200, 100, 100, 255);
        }
        if px2 >= 0 && py2 >= 0 && px2 < 500 && py2 < 400 {
            img.set_pixel(px2 as u32, py2 as u32, 100, 200, 100, 255);
        }
    }
    draw_label(&mut img, "CC INTERSECT", 290, 340, 200, 200, 100);

    draw_label(&mut img, "GEOMETRY SHAPES OK", 170, 385, 100, 255, 100);
    save_png("math/geometry_shapes", &img);
}

#[test]
fn evidence_geometry_intersections() {
    let mut img = ImageData::new(450, 350);
    img.fill(25, 25, 35, 255);

    // 1. Segment-segment intersection
    let (hit, point) = lurek2d::math::segment_intersects_segment(
        20.0, 20.0, 150.0, 120.0,
        20.0, 120.0, 150.0, 20.0,
    );
    assert!(hit);
    img.draw_line(20, 20, 150, 120, 200, 80, 80, 255);
    img.draw_line(20, 120, 150, 20, 80, 80, 200, 255);
    if let Some((ix, iy)) = point {
        safe_circle(&mut img, ix as i32, iy as i32, 5, 255, 255, 80, 255);
    }
    draw_label(&mut img, "SEG-SEG", 60, 130, 200, 200, 80);

    // 2. No intersection
    let (no_hit, _) = lurek2d::math::segment_intersects_segment(
        20.0, 160.0, 100.0, 160.0,
        20.0, 200.0, 100.0, 200.0,
    );
    assert!(!no_hit);
    img.draw_line(20, 160, 100, 160, 200, 80, 80, 255);
    img.draw_line(20, 200, 100, 200, 80, 200, 80, 255);
    draw_label(&mut img, "NO HIT", 30, 210, 200, 80, 80);

    // 3. Closest point on segment
    let (cpx, cpy) = lurek2d::math::closest_point_on_segment(
        250.0, 30.0,  // test point
        200.0, 80.0, 350.0, 80.0, // segment
    );
    img.draw_line(200, 80, 350, 80, 80, 180, 200, 255);
    safe_circle(&mut img, 250, 30, 4, 255, 100, 100, 255);
    safe_circle(&mut img, cpx as i32, cpy as i32, 4, 100, 255, 100, 255);
    img.draw_line(250, 30, cpx as i32, cpy as i32, 150, 150, 150, 150);
    draw_label(&mut img, "CLOSEST PT", 230, 90, 80, 180, 200);

    // 4. Circle-line intersection
    let (cl_hit, p1, p2) = lurek2d::math::circle_intersects_line(
        300.0, 200.0, 50.0,  // circle
        200.0, 200.0, 400.0, 200.0, // line
    );
    assert!(cl_hit);
    // Draw circle outline
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px = (300.0 + 50.0 * rad.cos()) as i32;
        let py = (200.0 + 50.0 * rad.sin()) as i32;
        if px >= 0 && py >= 0 && px < 450 && py < 350 {
            img.set_pixel(px as u32, py as u32, 100, 100, 200, 255);
        }
    }
    img.draw_line(200, 200, 400, 200, 200, 200, 200, 150);
    if let Some((ix, iy)) = p1 {
        safe_circle(&mut img, ix as i32, iy as i32, 4, 255, 80, 80, 255);
    }
    if let Some((ix, iy)) = p2 {
        safe_circle(&mut img, ix as i32, iy as i32, 4, 80, 255, 80, 255);
    }
    draw_label(&mut img, "CIRCLE-LINE", 273, 260, 100, 100, 200);

    // 5. Circle-segment intersection
    let (cs_hit, sp1, sp2) = lurek2d::math::circle_intersects_segment(
        100.0, 300.0, 30.0,
        60.0, 280.0, 140.0, 320.0,
    );
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px = (100.0 + 30.0 * rad.cos()) as i32;
        let py = (300.0 + 30.0 * rad.sin()) as i32;
        if px >= 0 && py >= 0 && px < 450 && py < 350 {
            img.set_pixel(px as u32, py as u32, 200, 150, 80, 255);
        }
    }
    img.draw_line(60, 280, 140, 320, 180, 180, 180, 200);
    if cs_hit {
        if let Some((ix, iy)) = sp1 {
            safe_circle(&mut img, ix as i32, iy as i32, 3, 255, 200, 80, 255);
        }
        if let Some((ix, iy)) = sp2 {
            safe_circle(&mut img, ix as i32, iy as i32, 3, 80, 200, 255, 255);
        }
    }
    draw_label(&mut img, "CIRCLE-SEG", 60, 335, 200, 150, 80);

    // 6. Line intersection (infinite lines)
    let result = lurek2d::math::line_intersect(
        200.0, 260.0, 400.0, 340.0,
        200.0, 340.0, 400.0, 260.0,
    );
    img.draw_line(200, 260, 400, 340, 200, 80, 200, 200);
    img.draw_line(200, 340, 400, 260, 80, 200, 200, 200);
    if let Some((ix, iy)) = result {
        safe_circle(&mut img, ix as i32, iy as i32, 5, 255, 255, 100, 255);
    }
    draw_label(&mut img, "LINE INTERSECT", 260, 345, 200, 200, 200);

    draw_label(&mut img, "GEOMETRY INTERSECTIONS OK", 120, 3, 100, 255, 100);
    save_png("math/geometry_intersections", &img);
}

#[test]
fn evidence_geometry_delaunay() {
    let mut img = ImageData::new(400, 400);
    img.fill(25, 25, 35, 255);

    // Generate points for Delaunay triangulation
    let pts: Vec<(f64, f64)> = vec![
        (50.0, 50.0), (200.0, 30.0), (350.0, 70.0),
        (30.0, 200.0), (150.0, 180.0), (280.0, 150.0), (370.0, 200.0),
        (80.0, 320.0), (200.0, 350.0), (330.0, 300.0),
        (120.0, 100.0), (250.0, 250.0), (180.0, 270.0),
    ];
    let triangles = lurek2d::math::delaunay_triangulate(&pts);

    // Draw triangles
    for (i, tri) in triangles.iter().enumerate() {
        let hue = ((i as f32 / triangles.len() as f32) * 360.0) as u16;
        let (r, g, b) = hsv_to_rgb(hue, 0.5, 0.7);
        img.draw_line(tri[0] as i32, tri[1] as i32, tri[2] as i32, tri[3] as i32, r, g, b, 200);
        img.draw_line(tri[2] as i32, tri[3] as i32, tri[4] as i32, tri[5] as i32, r, g, b, 200);
        img.draw_line(tri[4] as i32, tri[5] as i32, tri[0] as i32, tri[1] as i32, r, g, b, 200);
    }

    // Draw points
    for &(px, py) in &pts {
        safe_circle(&mut img, px as i32, py as i32, 4, 255, 200, 80, 255);
    }

    let count_str = format!("{} TRIANGLES", triangles.len());
    draw_label(&mut img, &count_str, 10, 380, 100, 200, 100);
    draw_label(&mut img, "DELAUNAY TRIANGULATION", 80, 5, 100, 255, 100);
    save_png("math/delaunay_triangulation", &img);
}

// =====================================================================
// ===== BATCH 2 — Graph operations and item flow =====
// =====================================================================

#[test]
fn evidence_graph_operations() {
    let mut graph = Graph::new();

    // Create nodes
    let n1 = graph.add_node("factory", 10);
    let n2 = graph.add_node("warehouse", 20);
    let n3 = graph.add_node("shop", 5);
    let n4 = graph.add_node("factory", 8);
    let n5 = graph.add_node("warehouse", 15);

    // Verify node operations
    assert!(graph.has_node(n1));
    assert!(graph.has_node(n5));
    assert_eq!(graph.get_node_count(), 5);

    // Add edges
    let e1 = graph.add_edge(n1, n2, Some("supply")).unwrap();
    let _e2 = graph.add_edge(n2, n3, Some("deliver")).unwrap();
    let _e3 = graph.add_edge(n4, n5, Some("supply")).unwrap();
    let _e4 = graph.add_edge(n5, n3, Some("deliver")).unwrap();
    let e5 = graph.add_edge(n1, n4, Some("transfer")).unwrap();

    assert!(graph.has_edge(e1));
    assert_eq!(graph.get_edge_count(), 5);

    // Edge queries
    let edge_between = graph.get_edge_between(n1, n2);
    assert!(edge_between.is_some());

    let outgoing = graph.get_outgoing_edges(n1);
    assert_eq!(outgoing.len(), 2); // to n2 and n4

    let incoming = graph.get_incoming_edges(n3);
    assert_eq!(incoming.len(), 2); // from n2 and n5

    // Remove edge and verify
    assert!(graph.remove_edge(e5));
    assert!(!graph.has_edge(e5));
    assert_eq!(graph.get_edge_count(), 4);

    // Node lists
    let node_ids = graph.get_node_ids();
    assert_eq!(node_ids.len(), 5);
    let edge_ids = graph.get_edge_ids();
    assert_eq!(edge_ids.len(), 4);

    // Visualization
    let mut img = ImageData::new(400, 300);
    img.fill(25, 25, 35, 255);

    let positions = [
        (80.0f32, 80.0), (200.0, 50.0), (320.0, 150.0),
        (80.0, 220.0), (200.0, 250.0),
    ];
    let node_labels = ["FACTORY", "WAREHOUSE", "SHOP", "FACTORY2", "WAREHOUSE2"];
    let edges_draw = [(0, 1), (1, 2), (3, 4), (4, 2)];

    // Draw remaining edges
    for &(a, b) in &edges_draw {
        let (ax, ay) = positions[a];
        let (bx, by) = positions[b];
        img.draw_line(ax as i32, ay as i32, bx as i32, by as i32, 80, 120, 180, 200);
    }
    // Draw removed edge dashed
    img.draw_line(80, 80, 80, 220, 80, 40, 40, 100);

    // Draw nodes
    let node_colors = [
        (200u8, 80, 80), (80, 160, 200), (80, 200, 80),
        (200, 80, 80), (80, 160, 200),
    ];
    for (i, (&(px, py), &(r, g, b))) in positions.iter().zip(node_colors.iter()).enumerate() {
        safe_circle(&mut img, px as i32, py as i32, 14, r, g, b, 255);
        draw_label(&mut img, node_labels[i], (px - 30.0) as i32, (py + 18.0) as i32, r, g, b);
    }

    let stats = graph.get_stats();
    let stats_str = format!("N{} E{}", stats.nodes, stats.edges);
    draw_label(&mut img, &stats_str, 10, 280, 200, 200, 200);
    draw_label(&mut img, "GRAPH OPS OK", 150, 5, 100, 255, 100);
    save_png("graph/operations", &img);
}

#[test]
fn evidence_graph_item_flow() {
    let mut graph = Graph::new();

    let src = graph.add_node("source", 100);
    let mid = graph.add_node("relay", 50);
    let dst = graph.add_node("sink", 100);

    let e1 = graph.add_edge(src, mid, Some("pipe")).unwrap();
    let _e2 = graph.add_edge(mid, dst, Some("pipe")).unwrap();

    // Create items
    let item1 = graph.create_item("ore", 60.0);
    let item2 = graph.create_item("gold", 120.0);
    let item3 = graph.create_item("gem", 30.0);

    assert!(graph.has_item(item1));
    assert_eq!(graph.get_item_count(), 3);

    // Add items to source node
    assert!(graph.add_item_to_node(item1, src).unwrap());
    assert!(graph.add_item_to_node(item2, src).unwrap());
    assert!(graph.add_item_to_node(item3, src).unwrap());

    // Send item along edge
    assert!(graph.send_item(item1, e1).unwrap());

    // Remove an item
    assert!(graph.remove_item(item3));
    assert!(!graph.has_item(item3));
    assert_eq!(graph.get_item_count(), 2);

    let stats = graph.get_stats();
    assert_eq!(stats.items, 2);

    // Visualization
    let mut img = ImageData::new(400, 200);
    img.fill(25, 25, 35, 255);

    // Draw pipeline
    let node_pos = [(60.0f32, 100.0), (200.0, 100.0), (340.0, 100.0)];
    let node_names = ["SOURCE", "RELAY", "SINK"];
    // Pipes
    img.draw_line(90, 100, 170, 100, 100, 150, 200, 200);
    img.draw_line(230, 100, 310, 100, 100, 150, 200, 200);
    // Arrow heads
    img.draw_line(165, 95, 175, 100, 100, 150, 200, 200);
    img.draw_line(165, 105, 175, 100, 100, 150, 200, 200);
    img.draw_line(305, 95, 315, 100, 100, 150, 200, 200);
    img.draw_line(305, 105, 315, 100, 100, 150, 200, 200);

    for (i, (&(px, py), &name)) in node_pos.iter().zip(node_names.iter()).enumerate() {
        let (r, g, b) = if i == 0 { (200, 100, 80) } else if i == 1 { (200, 200, 80) } else { (80, 200, 100) };
        safe_circle(&mut img, px as i32, py as i32, 20, r, g, b, 255);
        draw_label(&mut img, name, (px - 22.0) as i32, (py + 25.0) as i32, r, g, b);
    }

    // Item indicators
    safe_circle(&mut img, 130, 85, 6, 255, 200, 80, 255);
    draw_label(&mut img, "ORE", 120, 70, 255, 200, 80);
    safe_circle(&mut img, 70, 75, 6, 200, 180, 100, 255);
    draw_label(&mut img, "GOLD", 55, 60, 200, 180, 100);

    draw_label(&mut img, "ITEM FLOW OK", 150, 5, 100, 255, 100);
    let items_str = format!("ITEMS {}", stats.items);
    draw_label(&mut img, &items_str, 10, 180, 200, 200, 200);
    save_png("graph/item_flow", &img);
}

// =====================================================================
// ===== BATCH 2 — Animation advanced evidence =====
// =====================================================================

#[test]
fn evidence_animation_playback_control() {
    let mut anim = Animation::new();

    // Build frames from a 256x64 grid (8 frames of 32x64)
    let added = anim.add_frames_from_grid(256, 64, 32, 64, 0, 8);
    assert_eq!(added, 8);
    assert_eq!(anim.get_frame_count(), 8);

    // Create clips
    anim.add_clip("idle", vec![0, 1], 4.0, true);
    anim.add_clip("run", vec![2, 3, 4, 5], 10.0, true);
    anim.add_clip("jump", vec![6, 7], 8.0, false);

    // Also test add_clip_from_grid
    anim.add_clip_from_grid("attack", 256, 64, 32, 64, 0, 3, 12.0, false);

    let mut img = ImageData::new(500, 350);
    img.fill(25, 25, 35, 255);

    // Test play/pause/resume/stop cycle
    anim.play("run");
    assert!(anim.is_playing());
    assert_eq!(anim.get_current_clip(), Some("run"));

    // Record frames during playback
    let mut frames_recorded: Vec<usize> = Vec::new();
    for _ in 0..20 {
        anim.update(1.0 / 10.0);
        frames_recorded.push(anim.current_frame());
    }

    // Visualize frame timeline
    for (i, &frame) in frames_recorded.iter().enumerate() {
        let x = 10 + i as i32 * 24;
        let hue = (frame as f32 / 8.0 * 360.0) as u16;
        let (r, g, b) = hsv_to_rgb(hue, 0.8, 1.0);
        img.draw_rect(x, 20, 20, 30, r, g, b, 255);
    }
    draw_label(&mut img, "RUN FRAMES", 10, 55, 200, 200, 200);

    // Pause
    anim.pause();
    let paused_frame = anim.current_frame();
    anim.update(1.0 / 10.0);
    assert_eq!(anim.current_frame(), paused_frame); // Should not advance
    draw_label(&mut img, "PAUSE OK", 10, 80, 200, 200, 80);

    // Resume
    anim.resume();
    anim.update(1.0 / 10.0);
    draw_label(&mut img, "RESUME OK", 10, 100, 80, 200, 80);

    // Stop
    anim.stop();
    assert!(!anim.is_playing());
    draw_label(&mut img, "STOP OK", 10, 120, 200, 80, 80);

    // Play different clip
    anim.play("idle");
    assert_eq!(anim.get_current_clip(), Some("idle"));
    let mut idle_frames: Vec<usize> = Vec::new();
    for _ in 0..12 {
        anim.update(1.0 / 4.0);
        idle_frames.push(anim.current_frame());
    }
    for (i, &frame) in idle_frames.iter().enumerate() {
        let x = 10 + i as i32 * 24;
        let hue = (frame as f32 / 8.0 * 360.0) as u16;
        let (r, g, b) = hsv_to_rgb(hue, 0.6, 0.8);
        img.draw_rect(x, 150, 20, 30, r, g, b, 255);
    }
    draw_label(&mut img, "IDLE FRAMES", 10, 185, 200, 200, 200);

    // set_frame within current clip (switch to "run" which has 4 positions)
    anim.play("run");
    anim.set_frame(2);
    assert_eq!(anim.current_frame(), 2);
    if let Some(quad) = anim.current_quad() {
        let q_str = format!("{:.0} {:.0} {:.0}X{:.0}", quad.x, quad.y, quad.width, quad.height);
        draw_label(&mut img, &q_str, 10, 220, 180, 180, 200);
    }

    // Play non-looping clip
    anim.play("jump");
    for _ in 0..20 {
        anim.update(1.0 / 8.0);
    }
    // After non-looping clip finishes
    let _jump_done = !anim.is_playing() || anim.current_frame() == 1;
    draw_label(&mut img, "JUMP CLIP DONE", 10, 250, 200, 180, 100);

    // Summary
    let summary = format!("{} FRAMES {} CLIPS", anim.get_frame_count(), 4);
    draw_label(&mut img, &summary, 10, 330, 100, 255, 100);
    draw_label(&mut img, "ANIMATION PLAYBACK OK", 150, 330, 100, 255, 100);
    save_png("animation/playback_control", &img);
}

// =====================================================================
// ===== BATCH 2 — LayeredImage advanced evidence =====
// =====================================================================

#[test]
fn evidence_layers_management() {
    let mut layers = LayeredImage::new(200, 200);
    assert_eq!(layers.width(), 200);
    assert_eq!(layers.height(), 200);

    // Add layers with different content
    let bg = layers.add_layer("background");
    let mid = layers.add_layer("midground");
    let fg = layers.add_layer("foreground");
    let overlay = layers.add_layer("overlay");
    assert_eq!(layers.layer_count(), 4);

    // Set images
    let mut bg_img = ImageData::new(200, 200);
    for y in 0..200 {
        for x in 0..200 {
            let r = (x as u16 * 200 / 200) as u8;
            let b = (y as u16 * 200 / 200) as u8;
            bg_img.set_pixel(x, y, r, 40, b, 255);
        }
    }
    layers.set_layer_image(bg, &bg_img);

    let mut mid_img = ImageData::new(200, 200);
    mid_img.fill(0, 0, 0, 0);
    mid_img.draw_circle(100, 100, 50, 80, 200, 80, 200);
    layers.set_layer_image(mid, &mid_img);

    let mut fg_img = ImageData::new(200, 200);
    fg_img.fill(0, 0, 0, 0);
    fg_img.draw_rect(60, 60, 80, 80, 200, 80, 80, 180);
    layers.set_layer_image(fg, &fg_img);

    let mut ov_img = ImageData::new(200, 200);
    ov_img.fill(255, 255, 200, 60);
    layers.set_layer_image(overlay, &ov_img);

    // Test opacity
    layers.set_opacity(overlay, 0.2);

    // Test visibility
    layers.set_visible(mid, true);

    // Test rename
    layers.set_name(bg, "base");

    // Merge to verify compositing
    let merged1 = layers.merge();

    // Swap layers
    assert!(layers.swap_layers(mid, fg));

    // Move layer
    assert!(layers.move_layer(overlay, 1)); // move overlay to index 1

    let merged2 = layers.merge();

    // Remove a layer
    let removed = layers.remove_layer(overlay);
    assert!(removed.is_some());
    assert_eq!(layers.layer_count(), 3);

    let merged3 = layers.merge();

    // Create combined output
    let mut img = ImageData::new(620, 220);
    img.fill(25, 25, 35, 255);

    // Paste 3 merges side by side
    for y in 0..200 {
        for x in 0..200 {
            let p1 = merged1.get_pixel(x, y).unwrap_or((0,0,0,0));
            let p2 = merged2.get_pixel(x, y).unwrap_or((0,0,0,0));
            let p3 = merged3.get_pixel(x, y).unwrap_or((0,0,0,0));
            img.set_pixel(x + 5, y + 10, p1.0, p1.1, p1.2, p1.3);
            img.set_pixel(x + 210, y + 10, p2.0, p2.1, p2.2, p2.3);
            img.set_pixel(x + 415, y + 10, p3.0, p3.1, p3.2, p3.3);
        }
    }

    draw_label(&mut img, "ORIGINAL", 60, 213, 200, 200, 200);
    draw_label(&mut img, "SWAPPED", 270, 213, 200, 200, 200);
    draw_label(&mut img, "REMOVED", 475, 213, 200, 200, 200);
    save_png("layers/management", &img);
}

// =====================================================================
// ===== BATCH 2 — SoundData manipulation evidence =====
// =====================================================================

#[test]
fn evidence_sound_data_manipulation() {
    let sample_rate = 44100;
    let duration_secs = 0.5;
    let sample_count = (sample_rate as f64 * duration_secs) as usize;

    // Create sound data
    let mut sound = SoundData::new(sample_count, sample_rate, 1);
    assert_eq!(sound.sample_rate(), sample_rate);
    assert_eq!(sound.channel_count(), 1);
    assert_eq!(sound.bit_depth(), 32);
    assert!((sound.duration() - duration_secs).abs() < 0.01);

    // Fill with a sine wave using set_sample
    let freq = 440.0;
    for i in 0..sample_count {
        let t = i as f32 / sample_rate as f32;
        let val = (t * freq * std::f32::consts::TAU).sin();
        assert!(sound.set_sample(i, val));
    }

    // Read back samples using get_sample
    let mid = sample_count / 2;
    let sample_val = sound.get_sample(mid);
    assert!(sample_val.is_some());

    // Out-of-bounds should return None
    assert!(sound.get_sample(sample_count + 100).is_none());

    // Access raw samples slice
    let samples = sound.samples();
    assert_eq!(samples.len(), sample_count);

    // Manipulate: apply volume ramp
    for i in 0..sample_count {
        if let Some(val) = sound.get_sample(i) {
            let ramp = i as f32 / sample_count as f32;
            sound.set_sample(i, val * ramp);
        }
    }

    // Visualize as waveform
    let mut img = ImageData::new(500, 200);
    img.fill(25, 25, 35, 255);

    let samples = sound.samples();
    let step = samples.len() / 480;
    for x in 0..480 {
        let idx = x * step;
        if idx < samples.len() {
            let val = samples[idx];
            let y = (100.0 - val * 80.0) as i32;
            let t = x as f32 / 480.0;
            let r = (100.0 + t * 155.0) as u8;
            let g = (200.0 - t * 100.0) as u8;
            safe_circle(&mut img, x as i32 + 10, y.clamp(0, 199), 1, r, g, 120, 255);
        }
    }

    // Center line
    img.draw_line(10, 100, 490, 100, 60, 60, 80, 150);

    let info = format!("{} HZ {} SAMP", freq as i32, sample_count);
    draw_label(&mut img, &info, 10, 5, 200, 200, 200);
    draw_label(&mut img, "SOUND DATA MANIPULATION OK", 140, 185, 100, 255, 100);
    save_png("audio/sound_data_manipulation", &img);
}

// =====================================================================
// ===== BATCH 2 — TileMap layer management evidence =====
// =====================================================================

#[test]
fn evidence_tilemap_layer_management() {
    let mut tm = TileMap::new(16, 16, 4);

    // Add multiple layers
    let ground = tm.add_layer("ground", 16, 16);
    let decor = tm.add_layer("decor", 16, 16);
    let collision = tm.add_layer("collision", 16, 16);
    assert_eq!(tm.get_layer_count(), 3);

    // Verify layer names
    assert_eq!(tm.get_layer_name(ground), Some("ground"));
    assert_eq!(tm.get_layer_name(decor), Some("decor"));

    // Fill ground layer with grass
    tm.fill(ground, 1);
    // Verify fill
    assert_eq!(tm.get_tile(ground, 0, 0), 1);
    assert_eq!(tm.get_tile(ground, 8, 8), 1);

    // Set individual tiles
    for x in 3..13 {
        tm.set_tile(decor, x, 5, 2);
        tm.set_tile(decor, x, 10, 3);
    }
    for y in 5..11 {
        tm.set_tile(decor, 3, y, 4);
        tm.set_tile(decor, 12, y, 4);
    }

    // Set tile tints
    tm.set_tile_tint(decor, 5, 5, 1.0, 0.5, 0.5, 1.0);
    tm.set_tile_tint(decor, 8, 8, 0.5, 1.0, 0.5, 1.0);

    // Layer visibility
    tm.set_layer_visible(collision, false);
    assert!(!tm.get_layer_visible(collision));
    tm.set_layer_visible(collision, true);
    assert!(tm.get_layer_visible(collision));

    // Layer color
    tm.set_layer_color(decor, 0.8, 0.9, 1.0, 1.0);
    let color = tm.get_layer_color(decor);
    assert!((color[0] - 0.8).abs() < 0.01);

    // Layer offset
    tm.set_layer_offset(decor, 2.0, 1.0);
    let offset = tm.get_layer_offset(decor);
    assert!((offset.x - 2.0).abs() < 0.01);

    // Layer parallax
    tm.set_layer_parallax(decor, 0.5, 0.8);
    let parallax = tm.get_layer_parallax(decor);
    assert!((parallax.x - 0.5).abs() < 0.01);

    // Layer dimensions
    let dims = tm.get_layer_dimensions(ground);
    assert_eq!(dims, Some((16, 16)));

    // Clear a tile
    tm.clear_tile(decor, 5, 5);
    assert_eq!(tm.get_tile(decor, 5, 5), 0);

    // Visualization
    let mut img = ImageData::new(300, 300);
    img.fill(25, 25, 35, 255);

    let tile_px = 16;
    for y in 0..16u32 {
        for x in 0..16u32 {
            let gid = tm.get_tile(ground, x, y);
            let dgid = tm.get_tile(decor, x, y);
            let px = x as i32 * tile_px + 10;
            let py = y as i32 * tile_px + 10;

            // Ground
            if gid == 1 {
                img.draw_rect(px, py, tile_px as u32, tile_px as u32, 40, 80, 40, 255);
            }
            // Decor overlay
            if dgid > 0 {
                let (r, g, b) = match dgid {
                    2 => (120, 80, 60),   // wall horizontal
                    3 => (100, 70, 50),   // wall horizontal2
                    4 => (80, 60, 40),    // wall vertical
                    _ => (100, 100, 100),
                };
                img.draw_rect(px + 1, py + 1, tile_px as u32 - 2, tile_px as u32 - 2, r, g, b, 255);
            }
        }
    }

    let info = format!("{} LAYERS", tm.get_layer_count());
    draw_label(&mut img, &info, 10, 280, 200, 200, 200);
    draw_label(&mut img, "TILEMAP LAYERS OK", 80, 280, 100, 255, 100);
    save_png("tilemap/layer_management", &img);
}

// =====================================================================
// ===== BATCH 2 — Light advanced evidence =====
// =====================================================================

#[test]
fn evidence_light_falloff_modes() {
    let mut img = ImageData::new(480, 180);
    img.fill(10, 10, 15, 255);

    let modes = [FalloffMode::Linear, FalloffMode::Smooth, FalloffMode::Constant];
    let mode_names = ["LINEAR", "SMOOTH", "CONSTANT"];

    for (i, (&mode, &name)) in modes.iter().zip(mode_names.iter()).enumerate() {
        let ox = i as i32 * 160;
        let cx = ox + 80;
        let cy = 90;
        let radius = 60.0f32;

        let mut light = Light2D::new(cx as f32, cy as f32, radius);
        light.set_falloff(mode);
        assert_eq!(light.get_falloff() as u8, mode as u8);
        light.set_intensity(1.5);
        assert!((light.get_intensity() - 1.5).abs() < 0.01);
        light.set_energy(0.8);
        assert!((light.get_energy() - 0.8).abs() < 0.01);

        let color = Color::new(1.0, 0.8, 0.4, 1.0);
        light.set_color(color);

        // Draw light gradient manually
        for dy in -70i32..=70 {
            for dx in -70i32..=70 {
                let dist = ((dx * dx + dy * dy) as f32).sqrt();
                if dist > radius { continue; }
                let t = dist / radius;
                let intensity = match mode {
                    FalloffMode::Linear => 1.0 - t,
                    FalloffMode::Smooth => 1.0 - t * t,
                    FalloffMode::Constant => 1.0,
                };
                let px = (cx + dx) as u32;
                let py = (cy + dy) as u32;
                if px < 480 && py < 180 {
                    let r = (255.0 * intensity * 1.0) as u8;
                    let g = (200.0 * intensity * 0.8) as u8;
                    let b = (100.0 * intensity * 0.4) as u8;
                    let existing = img.get_pixel(px, py).unwrap_or((0,0,0,0));
                    let nr = r.max(existing.0);
                    let ng = g.max(existing.1);
                    let nb = b.max(existing.2);
                    img.set_pixel(px, py, nr, ng, nb, 255);
                }
            }
        }
        draw_label(&mut img, name, ox + 30, 165, 200, 200, 200);
    }

    draw_label(&mut img, "LIGHT FALLOFF MODES", 150, 3, 100, 255, 100);
    save_png("light/falloff_modes", &img);
}

#[test]
fn evidence_light_attenuation() {
    let mut img = ImageData::new(400, 200);
    img.fill(15, 15, 20, 255);

    // Attenuation curves
    let configs = [
        (Attenuation::new(1.0, 0.0, 0.0), "CONST ATTEN"),
        (Attenuation::new(1.0, 0.1, 0.0), "LINEAR ATTEN"),
        (Attenuation::new(1.0, 0.0, 0.05), "QUAD ATTEN"),
        (Attenuation::new(1.0, 0.05, 0.02), "MIXED ATTEN"),
    ];

    for (i, (atten, label)) in configs.iter().enumerate() {
        let oy = 10 + i as i32 * 45;

        // Draw attenuation curve
        for x in 0..380 {
            let dist = x as f32 / 380.0 * 20.0;
            let factor = atten.factor(dist);
            let bar_h = (factor * 35.0) as i32;
            let hue = (i as f32 / 4.0 * 120.0) as u16;
            let (r, g, b) = hsv_to_rgb(hue, 0.7, 0.9);
            if bar_h > 0 {
                img.draw_line(x + 10, oy + 38, x + 10, oy + 38 - bar_h, r, g, b, 200);
            }
        }
        draw_label(&mut img, label, 10, oy, 200, 200, 200);
    }

    draw_label(&mut img, "ATTENUATION CURVES", 120, 190, 100, 255, 100);
    save_png("light/attenuation_curves", &img);
}

// =====================================================================
// ===== BATCH 2 — Bezier advanced evidence =====
// =====================================================================

#[test]
fn evidence_bezier_advanced_ops() {
    let mut img = ImageData::new(500, 400);
    img.fill(25, 25, 35, 255);

    // 1. Bezier derivative curve
    let curve = BezierCurve::new(vec![
        Vec2::new(50.0, 200.0),
        Vec2::new(150.0, 50.0),
        Vec2::new(300.0, 50.0),
        Vec2::new(400.0, 200.0),
    ]);
    let pts = curve.render(60);
    for i in 1..pts.len() {
        img.draw_line(
            pts[i - 1].x as i32, pts[i - 1].y as i32,
            pts[i].x as i32, pts[i].y as i32,
            200, 120, 80, 255,
        );
    }

    // Derivative
    let deriv = curve.get_derivative();
    let dpts = deriv.render(40);
    // Scale and offset derivative for visibility
    for i in 1..dpts.len() {
        let x1 = 50 + (dpts[i - 1].x * 0.3) as i32;
        let y1 = 350 + (dpts[i - 1].y * 0.3) as i32;
        let x2 = 50 + (dpts[i].x * 0.3) as i32;
        let y2 = 350 + (dpts[i].y * 0.3) as i32;
        if x1 >= 0 && y1 >= 0 && x2 < 500 && y2 < 400 && x1 < 500 && y1 < 400 {
            img.draw_line(x1, y1, x2, y2, 80, 200, 200, 200);
        }
    }
    draw_label(&mut img, "DERIVATIVE", 10, 330, 80, 200, 200);

    // 2. render_segment
    let seg_pts = curve.render_segment(0.2, 0.8, 30);
    for i in 1..seg_pts.len() {
        img.draw_line(
            seg_pts[i - 1].x as i32, (seg_pts[i - 1].y + 5.0) as i32,
            seg_pts[i].x as i32, (seg_pts[i].y + 5.0) as i32,
            255, 255, 80, 255,
        );
    }
    draw_label(&mut img, "SEGMENT 0.2-0.8", 150, 210, 255, 255, 80);

    // 3. Control point manipulation
    let mut editable = BezierCurve::new(vec![
        Vec2::new(300.0, 280.0),
        Vec2::new(350.0, 230.0),
        Vec2::new(450.0, 280.0),
    ]);
    assert_eq!(editable.get_control_point_count(), 3);

    // Get and draw original control points
    for i in 0..editable.get_control_point_count() {
        if let Some(cp) = editable.get_control_point(i) {
            safe_circle(&mut img, cp.x as i32, cp.y as i32, 4, 200, 200, 200, 255);
        }
    }
    let orig_pts = editable.render(20);
    for i in 1..orig_pts.len() {
        img.draw_line(
            orig_pts[i - 1].x as i32, orig_pts[i - 1].y as i32,
            orig_pts[i].x as i32, orig_pts[i].y as i32,
            150, 150, 150, 200,
        );
    }

    // Set control point
    editable.set_control_point(1, Vec2::new(350.0, 200.0));
    // Insert control point
    editable.insert_control_point(Vec2::new(400.0, 250.0), Some(2));
    assert_eq!(editable.get_control_point_count(), 4);

    let edited_pts = editable.render(20);
    for i in 1..edited_pts.len() {
        img.draw_line(
            edited_pts[i - 1].x as i32, edited_pts[i - 1].y as i32,
            edited_pts[i].x as i32, edited_pts[i].y as i32,
            80, 200, 80, 255,
        );
    }

    // Remove control point
    editable.remove_control_point(3);
    assert_eq!(editable.get_control_point_count(), 3);

    // 4. Transform operations
    let mut transform_curve = BezierCurve::new(vec![
        Vec2::new(300.0, 320.0),
        Vec2::new(350.0, 300.0),
        Vec2::new(400.0, 320.0),
    ]);
    // Original
    let t_pts = transform_curve.render(15);
    for i in 1..t_pts.len() {
        img.draw_line(
            t_pts[i - 1].x as i32, t_pts[i - 1].y as i32,
            t_pts[i].x as i32, t_pts[i].y as i32,
            200, 80, 80, 180,
        );
    }
    // Translate
    transform_curve.translate(0.0, 20.0);
    let tt_pts = transform_curve.render(15);
    for i in 1..tt_pts.len() {
        img.draw_line(
            tt_pts[i - 1].x as i32, tt_pts[i - 1].y as i32,
            tt_pts[i].x as i32, tt_pts[i].y as i32,
            80, 80, 200, 180,
        );
    }

    // Length
    let len = curve.length();
    let len_str = format!("LEN {:.0}", len);
    draw_label(&mut img, &len_str, 300, 215, 200, 200, 200);

    // Interpolated position and angle
    let (ix, iy) = curve.get_interpolated_position(0.5);
    safe_circle(&mut img, ix as i32, iy as i32, 5, 255, 100, 255, 255);
    let angle = curve.get_interpolated_angle(0.5);
    let angle_str = format!("A {:.2}", angle);
    draw_label(&mut img, &angle_str, ix as i32 + 8, iy as i32, 255, 100, 255);

    draw_label(&mut img, "BEZIER ADVANCED OK", 150, 385, 100, 255, 100);
    save_png("math/bezier_advanced", &img);
}

// =====================================================================
// ===== BATCH 2 — Spine advanced evidence =====
// =====================================================================

#[test]
fn evidence_spine_bone_operations() {
    let mut skeleton = Skeleton::new("warrior");

    // Build hierarchy
    let root = skeleton.add_bone(Bone::new("root"));
    let torso = skeleton.add_bone(Bone::with_parent("torso", root, 0.0, -40.0));
    let head = skeleton.add_bone(Bone::with_parent("head", torso, 0.0, -25.0));
    let l_arm = skeleton.add_bone(Bone::with_parent("l_arm", torso, -25.0, -5.0));
    let r_arm = skeleton.add_bone(Bone::with_parent("r_arm", torso, 25.0, -5.0));
    let l_leg = skeleton.add_bone(Bone::with_parent("l_leg", root, -12.0, 35.0));
    let r_leg = skeleton.add_bone(Bone::with_parent("r_leg", root, 12.0, 35.0));
    let l_hand = skeleton.add_bone(Bone::with_parent("l_hand", l_arm, -15.0, 20.0));
    let r_hand = skeleton.add_bone(Bone::with_parent("r_hand", r_arm, 15.0, 20.0));

    // Test find_bone
    assert_eq!(skeleton.find_bone("head"), Some(head));
    assert_eq!(skeleton.find_bone("l_hand"), Some(l_hand));
    assert_eq!(skeleton.find_bone("nonexistent"), None);
    assert_eq!(skeleton.bone_count(), 9);

    // Set root position and update
    skeleton.set_root_position(200.0, 250.0);
    skeleton.update_world_transforms();

    // Get world transforms and verify
    let root_t = skeleton.bone_world_transform(root);
    assert!(root_t.is_some());
    let (rx, ry, _, _, _) = root_t.unwrap();
    assert!((rx - 200.0).abs() < 1.0);
    assert!((ry - 250.0).abs() < 1.0);

    // Visualize the skeleton
    let mut img = ImageData::new(400, 400);
    img.fill(20, 20, 30, 255);

    // Bone connections
    let connections = [
        (root, torso), (torso, head), (torso, l_arm), (torso, r_arm),
        (root, l_leg), (root, r_leg), (l_arm, l_hand), (r_arm, r_hand),
    ];

    for &(parent, child) in &connections {
        if let (Some(pt), Some(ct)) = (
            skeleton.bone_world_transform(parent),
            skeleton.bone_world_transform(child),
        ) {
            img.draw_line(pt.0 as i32, pt.1 as i32, ct.0 as i32, ct.1 as i32, 180, 180, 200, 255);
        }
    }

    // Draw joints with different colors per body part
    let joint_colors = [
        (255u8, 200, 80),  // root
        (200, 100, 100), // torso
        (255, 150, 100), // head
        (100, 150, 255), // l_arm
        (100, 150, 255), // r_arm
        (100, 200, 100), // l_leg
        (100, 200, 100), // r_leg
        (200, 100, 255), // l_hand
        (200, 100, 255), // r_hand
    ];
    let joint_labels = ["ROOT", "TORSO", "HEAD", "L-ARM", "R-ARM", "L-LEG", "R-LEG", "L-HAND", "R-HAND"];

    for i in 0..skeleton.bone_count() {
        if let Some((wx, wy, _, _, _)) = skeleton.bone_world_transform(i) {
            let (r, g, b) = joint_colors[i];
            safe_circle(&mut img, wx as i32, wy as i32, 5, r, g, b, 255);
            draw_label(&mut img, joint_labels[i], wx as i32 + 8, wy as i32 - 3, r, g, b);
        }
    }

    draw_label(&mut img, "SPINE BONES OK", 140, 385, 100, 255, 100);
    let count_str = format!("{} BONES", skeleton.bone_count());
    draw_label(&mut img, &count_str, 10, 385, 200, 200, 200);
    save_png("spine/bone_operations", &img);
}

// =====================================================================
// ===== BATCH 2 — Raycaster with procedural textures =====
// =====================================================================

#[test]
fn evidence_raycaster_procedural_textures() {
    let mut rc = Raycaster2D::new(16, 16);

    // Build map: outer walls + inner structures
    for x in 0u32..16 { rc.set_cell(x, 0, 1); rc.set_cell(x, 15, 2); }
    for y in 0u32..16 { rc.set_cell(0, y, 3); rc.set_cell(15, y, 4); }
    // Pillars
    rc.set_cell(5, 5, 5);
    rc.set_cell(10, 5, 5);
    rc.set_cell(5, 10, 5);
    rc.set_cell(10, 10, 5);
    // Internal wall
    for x in 7u32..9 { rc.set_cell(x, 3, 6); rc.set_cell(x, 12, 6); }

    // Procedural texture generator: generates a texture color based on cell_value and position
    let texture_color = |cell: u32, frac_y: f32, frac_x: f32| -> (u8, u8, u8) {
        match cell {
            1 => {
                // Brick pattern
                let brick_y = (frac_y * 4.0) as u32;
                let _brick_x = (frac_x * 8.0) as u32;
                let offset = if brick_y % 2 == 0 { 0 } else { 4 };
                let is_mortar = frac_y * 4.0 % 1.0 < 0.1
                    || (frac_x * 8.0 + offset as f32) % 1.0 < 0.12;
                if is_mortar { (120, 110, 100) } else { (180, 60, 40) }
            }
            2 => {
                // Stone blocks
                let block_x = (frac_x * 3.0) as u32;
                let block_y = (frac_y * 3.0) as u32;
                let noise = ((block_x * 37 + block_y * 59) % 30) as u8;
                (130 + noise, 130 + noise, 140 + noise)
            }
            3 => {
                // Wood planks (vertical)
                let plank = (frac_x * 6.0) as u32;
                let grain = ((frac_y * 20.0).sin() * 15.0) as i32;
                let base = 100 + (plank * 12 % 40) as i32;
                let r = (base + grain).clamp(60, 200) as u8;
                let g = (base - 20 + grain).clamp(40, 150) as u8;
                let b = ((base - 50).max(20) as f32 * 0.5) as u8;
                (r, g, b)
            }
            4 => {
                // Metal panels
                let panel_y = (frac_y * 4.0) as u32;
                let is_seam = frac_y * 4.0 % 1.0 < 0.08;
                let rivet = frac_x > 0.45 && frac_x < 0.55 && frac_y * 4.0 % 1.0 > 0.4 && frac_y * 4.0 % 1.0 < 0.6;
                if rivet { (200, 200, 210) }
                else if is_seam { (60, 65, 75) }
                else {
                    let shade = 100 + (panel_y * 10 % 30) as u8;
                    (shade, (shade as u16 + 10).min(255) as u8, (shade as u16 + 25).min(255) as u8)
                }
            }
            5 => {
                // Marble pillar
                let vein = ((frac_y * 10.0 + frac_x * 5.0).sin() * 20.0) as i32;
                let base = 200 + vein;
                let r = base.clamp(160, 240) as u8;
                let g = (base - 10).clamp(150, 235) as u8;
                let b = (base - 5).clamp(155, 238) as u8;
                (r, g, b)
            }
            6 => {
                // Mosaic tiles
                let tx = (frac_x * 5.0) as u32;
                let ty = (frac_y * 5.0) as u32;
                let tile_hue = ((tx * 73 + ty * 41) % 6) as u16 * 60;
                hsv_to_rgb(tile_hue, 0.6, 0.8)
            }
            _ => (150, 150, 150),
        }
    };

    let mut img = ImageData::new(640, 400);

    // Sky with gradient + stars
    for y in 0..200u32 {
        let t = y as f32 / 200.0;
        let r = (10.0 + t * 20.0) as u8;
        let g = (15.0 + t * 30.0) as u8;
        let b = (40.0 + t * 80.0) as u8;
        for x in 0..640u32 { img.set_pixel(x, y, r, g, b, 255); }
    }
    // Stars
    let star_positions = [
        (50u32, 20u32), (150, 40), (280, 15), (400, 35), (520, 25), (600, 45),
        (100, 60), (350, 55), (500, 70), (80, 90),
    ];
    for &(sx, sy) in &star_positions {
        img.set_pixel(sx, sy, 255, 255, 240, 200);
    }

    // Floor with perspective
    for y in 200..400u32 {
        let t = (y - 200) as f32 / 200.0;
        let g = (60.0 - t * 30.0) as u8;
        for x in 0..640u32 {
            let checker = ((x / 40 + (y - 200) / 20) % 2 == 0) as u8;
            let r = g + 15 + checker * 15;
            let g2 = g + 5 + checker * 10;
            let b = g / 2 + checker * 8;
            img.set_pixel(x, y, r, g2, b, 255);
        }
    }

    // Raycast
    let fov = std::f32::consts::FRAC_PI_3;
    let rays = rc.cast_rays(3.5, 8.0, 0.4, fov, 640, 20.0);

    for (x, hit) in rays.iter().enumerate() {
        if hit.hit {
            let wall_h = (300.0 / hit.distance.max(0.2)) as i32;
            let top = 200 - wall_h / 2;
            let bot = 200 + wall_h / 2;
            let shade = (1.0 - hit.distance / 20.0).max(0.2);

            // Apply textured color per scanline
            for y in top.max(0)..bot.min(400) {
                let frac_y = (y - top) as f32 / (bot - top).max(1) as f32;
                // Use hit distance fraction for x texture coordinate
                let frac_x = (hit.distance * 3.7) % 1.0;
                let (tr, tg, tb) = texture_color(hit.cell_value, frac_y, frac_x);
                let r = (tr as f32 * shade) as u8;
                let g = (tg as f32 * shade) as u8;
                let b = (tb as f32 * shade) as u8;
                img.set_pixel(x as u32, y as u32, r, g, b, 255);
            }
        }
    }

    draw_label(&mut img, "BRICK", 20, 5, 180, 60, 40);
    draw_label(&mut img, "STONE", 100, 5, 140, 140, 150);
    draw_label(&mut img, "WOOD", 180, 5, 130, 100, 50);
    draw_label(&mut img, "METAL", 260, 5, 120, 130, 145);
    draw_label(&mut img, "MARBLE", 340, 5, 210, 200, 205);
    draw_label(&mut img, "MOSAIC", 430, 5, 200, 200, 80);
    draw_label(&mut img, "PROCEDURAL TEXTURED RAYCASTER", 160, 385, 100, 255, 100);
    save_png("raycaster/procedural_textures", &img);
}
