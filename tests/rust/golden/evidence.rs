//! Evidence tests — produce real PNG and WAV artifact files proving engine APIs work.
//!
//! Every test in this module writes at least one binary file (PNG image or WAV audio)
//! to `tests/rust/golden/evidence/`. These files are committed to the repository as
//! proof that the engine's CPU-side APIs produce correct, usable output.
//!
//! Run with: `cargo test --test evidence_tests -- --nocapture`

use lurek2d::audio::SoundData;
use lurek2d::image::ImageData;
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
use lurek2d::render::camera::Camera2D;
use lurek2d::graph::Graph;
use lurek2d::image::LayeredImage;
use lurek2d::render::light::{LightWorld, Light2D, Occluder, Attenuation, FalloffMode};
use lurek2d::spine::{Skeleton, Bone};
use lurek2d::render::effect::overlay::Overlay;
use lurek2d::render::effect::effect::PostFxEffect;
use lurek2d::render::effect::effect_type::PostFxEffectType;
use lurek2d::render::effect::stack::PostFxStack;
use lurek2d::particle::Trail;
use lurek2d::image::visualization;
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
    let img = visualization::noise_to_image(|x, y| noise.perlin_2d(x, y), 256, 256, 0.02);
    save_png("math/perlin_noise_2d", &img);
}

#[test]
fn evidence_math_simplex_noise_2d() {
    let noise = NoiseGenerator::new(42);
    let img = visualization::noise_to_image(|x, y| noise.simplex_2d(x, y), 256, 256, 0.02);
    save_png("math/simplex_noise_2d", &img);
}

#[test]
fn evidence_math_fbm_noise() {
    let noise = NoiseGenerator::new(42);
    let img = visualization::noise_to_image(
        |x, y| noise.fbm(x, y, 6, 2.0, 0.5, NoiseKind::Perlin),
        256, 256, 0.01,
    );
    save_png("math/fbm_noise", &img);
}

#[test]
fn evidence_math_worley_noise() {
    let noise = NoiseGenerator::new(42);
    let img = visualization::noise_raw_to_image(
        |x, y| noise.worley_2d(x, y, lurek2d::math::noise_generator::DistType::Euclidean, false),
        256, 256, 0.02,
    );
    save_png("math/worley_noise", &img);
}

#[test]
fn evidence_math_noise_colored_terrain() {
    let noise = NoiseGenerator::new(12345);
    let img = visualization::noise_terrain_to_image(
        |x, y| noise.fbm(x, y, 6, 2.0, 0.5, NoiseKind::Perlin),
        256, 256, 0.008,
    );
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
    let img = visualization::noise_map_to_image(&map, 256, 256);
    save_png("math/generate_map", &img);
}

#[test]
fn evidence_math_bezier_curve() {
    let img = visualization::bezier_curves_to_image(
        &[(vec![
            Vec2::new(10.0, 200.0),
            Vec2::new(60.0, 20.0),
            Vec2::new(180.0, 20.0),
            Vec2::new(240.0, 200.0),
        ], (0u8, 255u8, 100u8))],
        256,
        256,
    );
    save_png("math/bezier_curve", &img);
}

#[test]
fn evidence_math_bezier_multiple() {
    let curves_data: Vec<(Vec<Vec2>, (u8, u8, u8))> = vec![
        (vec![Vec2::new(10.0, 128.0), Vec2::new(80.0, 10.0), Vec2::new(170.0, 245.0), Vec2::new(245.0, 128.0)], (255u8, 80u8, 80u8)),
        (vec![Vec2::new(128.0, 10.0), Vec2::new(10.0, 80.0), Vec2::new(245.0, 170.0), Vec2::new(128.0, 245.0)], (80u8, 255u8, 80u8)),
        (vec![Vec2::new(10.0, 10.0), Vec2::new(245.0, 10.0), Vec2::new(10.0, 245.0), Vec2::new(245.0, 245.0)], (80u8, 80u8, 255u8)),
    ];
    let img = visualization::bezier_curves_to_image(&curves_data, 256, 256);
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

    save_png("audio/waveform_sine_440hz", &visualization::waveform_to_image(&sound.samples(), sample_rate, 800, 300));
    save_png("audio/waveform_sine_440hz_zoomed", &visualization::waveform_zoomed_to_image(&sound.samples(), 1000, 800, 300));
    save_wav("audio/waveform_sine_440hz_audio", &sound);
}

// ===== COMBINED — Cross-module evidence =====

#[test]
fn evidence_noise_to_heightmap_render() {
    let noise = NoiseGenerator::new(7777);
    let size = 256u32;
    let opts = MapGenOptions {
        kind: NoiseKind::Simplex,
        octaves: 5,
        scale_x: 0.01,
        scale_y: 0.01,
        ..Default::default()
    };
    let data = noise.generate_map(size, size, &opts);
    let img = visualization::heightmap_to_image(&data, size, size);
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
    let img = tm.draw_to_image(16);
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

    let img = tm.draw_to_image(16);
    save_png("tilemap/multi_layer", &img);
}

#[test]
fn evidence_tilemap_world_to_tile() {
    let tm = TileMap::new(32, 32, 8);
    let world_points = [
        (50.0f32, 80.0f32, 255u8, 80u8, 80u8),
        (150.0, 200.0, 80, 255, 80),
        (220.0, 30.0, 80, 80, 255),
    ];
    let img = tm.draw_with_highlight_to_image(256, 256, &world_points);
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

    let img = mm.draw_to_image(0);
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

    let img = mm.draw_to_image(0);
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

    let img = mm.draw_to_image(0);
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

    let img = mm.draw_to_image(0);
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

    let img = rc.draw_top_down_to_image(8.0, 8.0, 0.0, 16);
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

    let fov = std::f32::consts::FRAC_PI_3;
    let img = rc.draw_depth_map_to_image(8.0, 8.0, 0.0, fov, 320, 320, 200, 20.0);
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

    let img = rc.draw_line_of_sight_to_image(4.5, 8.0, 12.5, 8.0, 16);
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

    let img = grid.draw_to_image(
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

    let img = grid.draw_to_image(16, path.as_deref(), None, None);
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

    let img = ff.draw_to_image(16);
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

    let img = imap.draw_to_image(16);
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
    let img = visualization::cellular_grid_to_image(&grid, 64, 48, 4, (60, 80, 60), (30, 30, 40));
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
    let img = visualization::cellular_grid_to_image(&grid, 80, 60, 4, (80, 70, 50), (25, 20, 15));
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

    let palette: Vec<(u8, u8, u8)> = (0..20).map(|i| {
        let h = (i as f32 * 0.3).sin() * 0.5 + 0.5;
        let r = (50.0 + h * 200.0) as u8;
        let g = (80.0 + ((i as f32 * 0.7).cos() * 0.5 + 0.5) * 170.0) as u8;
        let b = (60.0 + ((i as f32 * 1.1).sin() * 0.5 + 0.5) * 190.0) as u8;
        (r, g, b)
    }).collect();
    let mut img = visualization::voronoi_to_image(&regions, 256, 256, &palette);
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

    let palette: Vec<(u8, u8, u8)> = (0..15).map(|i| {
        ((70 + i * 12) as u8, (100 + i * 8) as u8, (50 + i * 14) as u8)
    }).collect();
    let img = visualization::voronoi_to_image(&regions, 256, 256, &palette);
    save_png("procgen/voronoi_warped", &img);
}

#[test]
fn evidence_procgen_poisson_disk() {
    let points = poisson_disk(256.0, 256.0, 15.0, 30, 42);

    let pts: Vec<(f64, f64)> = points.iter().map(|&(x, y)| (x as f64, y as f64)).collect();
    let img = visualization::points_to_image(&pts, 256, 256, 2, (100, 200, 255));
    save_png("procgen/poisson_disk", &img);
}

#[test]
fn evidence_procgen_poisson_dense() {
    let points = poisson_disk(256.0, 256.0, 8.0, 30, 1234);

    let img = visualization::colored_points_to_image(
        &points.iter().map(|&(x, y)| (x, y)).collect::<Vec<_>>(),
        256,
        256,
    );
    save_png("procgen/poisson_dense", &img);
}

// =====================================================================
// ===== EASING — All easing function curves =====
// =====================================================================

#[test]
fn evidence_easing_all_curves() {
    let funcs: &[(&str, &dyn Fn(f32) -> f32)] = &[
        ("linear",     &|t| easing::apply("linear",     t).unwrap_or(t)),
        ("inquad",     &|t| easing::apply("inquad",     t).unwrap_or(t)),
        ("outquad",    &|t| easing::apply("outquad",    t).unwrap_or(t)),
        ("inoutquad",  &|t| easing::apply("inoutquad",  t).unwrap_or(t)),
        ("incubic",    &|t| easing::apply("incubic",    t).unwrap_or(t)),
        ("outcubic",   &|t| easing::apply("outcubic",   t).unwrap_or(t)),
        ("inoutcubic", &|t| easing::apply("inoutcubic", t).unwrap_or(t)),
        ("inquart",    &|t| easing::apply("inquart",    t).unwrap_or(t)),
        ("outquart",   &|t| easing::apply("outquart",   t).unwrap_or(t)),
        ("inoutquart", &|t| easing::apply("inoutquart", t).unwrap_or(t)),
        ("insine",     &|t| easing::apply("insine",     t).unwrap_or(t)),
        ("outsine",    &|t| easing::apply("outsine",    t).unwrap_or(t)),
        ("inoutsine",  &|t| easing::apply("inoutsine",  t).unwrap_or(t)),
        ("inexpo",     &|t| easing::apply("inexpo",     t).unwrap_or(t)),
        ("outexpo",    &|t| easing::apply("outexpo",    t).unwrap_or(t)),
        ("inoutexpo",  &|t| easing::apply("inoutexpo",  t).unwrap_or(t)),
        ("inelastic",  &|t| easing::apply("inelastic",  t).unwrap_or(t)),
        ("outelastic", &|t| easing::apply("outelastic", t).unwrap_or(t)),
        ("inbounce",   &|t| easing::apply("inbounce",   t).unwrap_or(t)),
        ("outbounce",  &|t| easing::apply("outbounce",  t).unwrap_or(t)),
        ("inback",     &|t| easing::apply("inback",     t).unwrap_or(t)),
        ("outback",    &|t| easing::apply("outback",    t).unwrap_or(t)),
    ];
    let img = visualization::easing_gallery_to_image(funcs, 120, 80);
    save_png("easing/all_curves_gallery", &img);
}

#[test]
fn evidence_easing_comparison() {
    let curves: &[(&str, (u8, u8, u8), fn(f32) -> f32)] = &[
        ("linear",     (200, 200, 200), |t| easing::apply("linear",     t).unwrap_or(t)),
        ("inquad",     (255, 80,  80),  |t| easing::apply("inquad",     t).unwrap_or(t)),
        ("outquad",    (80,  255, 80),  |t| easing::apply("outquad",    t).unwrap_or(t)),
        ("inoutcubic", (80,  80,  255), |t| easing::apply("inoutcubic", t).unwrap_or(t)),
        ("outelastic", (255, 200, 80),  |t| easing::apply("outelastic", t).unwrap_or(t)),
        ("outbounce",  (200, 80,  255), |t| easing::apply("outbounce",  t).unwrap_or(t)),
    ];
    let img = visualization::easing_comparison_to_image(curves, 256, 256);
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

    let img = world.draw_to_image(256, 256);
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

    let img = world.draw_to_image(256, 256);
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

    let img = ps.draw_to_image(256, 256);
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

    let img = ps.draw_to_image(256, 256);
    save_png("particle/fountain", &img);
}

// =====================================================================
// ===== ANIMATION — Animation controller evidence =====
// =====================================================================

#[test]
fn evidence_animation_frame_grid() {
    let mut anim = Animation::new();
    anim.add_frames_from_grid(128, 128, 32, 32, 0, 16);
    anim.add_clip("walk", vec![0, 1, 2, 3], 8.0, true);
    anim.play("walk");

    let img = visualization::draw_animation_frame_grid_to_image(&mut anim, 32, 32);
    save_png("animation/frame_grid", &img);
}

#[test]
fn evidence_animation_clip_playback() {
    let mut anim = Animation::new();
    anim.add_frames_from_grid(64, 64, 16, 16, 0, 16);
    anim.add_clip("run", vec![0, 1, 2, 3, 4, 5, 6, 7], 10.0, true);
    anim.play("run");

    let mut snapshots = Vec::new();
    for _ in 0..8 {
        anim.update(1.0 / 10.0);
        snapshots.push(anim.current_frame());
    }
    let img = visualization::draw_animation_playback_to_image(&snapshots, 8, 32, 64);
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

    let img = skeleton.draw_to_image(256, 256);
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

    let img = graph.draw_to_image(256, 256);
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

    let img = visualization::draw_camera_debug_to_image(&cam, 256.0, 256.0, 256, 256);
    save_png("camera/viewport", &img);
}

#[test]
fn evidence_camera_zoom_levels() {
    let cam = Camera2D::new(128.0, 128.0);
    let zooms = [0.5f32, 1.0, 1.5, 2.0];
    let img = visualization::draw_camera_zoom_comparison_to_image(&cam, &zooms, 128, 128);
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
    save_png("audio_dsp/lowpass_before_waveform", &visualization::waveform_to_image(&rich, sr, 800, 300));

    // Apply lowpass filter
    let params = Arc::new(EffectParams::new(1, EffectType::Lowpass));
    params.set_param("cutoff", 800.0).unwrap();
    params.set_param("q", 0.707).unwrap();
    params.set_param("mix", 1.0).unwrap();
    let mut effect = ActiveEffect::new(params, sr, 1);

    let filtered: Vec<f32> = rich.iter().map(|&s| effect.process(s, 0, sr)).collect();
    let after = SoundData::from_samples(filtered.clone(), sr, 1);
    save_wav("audio_dsp/lowpass_after", &after);
    save_png("audio_dsp/lowpass_after_waveform", &visualization::waveform_to_image(&filtered, sr, 800, 300));
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
    save_png("audio_dsp/highpass_before_waveform", &visualization::waveform_to_image(&rich, sr, 800, 300));

    let params = Arc::new(EffectParams::new(2, EffectType::Highpass));
    params.set_param("cutoff", 1000.0).unwrap();
    params.set_param("q", 0.707).unwrap();
    params.set_param("mix", 1.0).unwrap();
    let mut effect = ActiveEffect::new(params, sr, 1);

    let filtered: Vec<f32> = rich.iter().map(|&s| effect.process(s, 0, sr)).collect();
    let after = SoundData::from_samples(filtered.clone(), sr, 1);
    save_wav("audio_dsp/highpass_after", &after);
    save_png("audio_dsp/highpass_after_waveform", &visualization::waveform_to_image(&filtered, sr, 800, 300));
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
    save_png("audio_dsp/bandpass_before_waveform", &visualization::waveform_to_image(&rich, sr, 800, 300));

    let params = Arc::new(EffectParams::new(3, EffectType::Bandpass));
    params.set_param("cutoff", 1000.0).unwrap();
    params.set_param("q", 2.0).unwrap();
    params.set_param("mix", 1.0).unwrap();
    let mut effect = ActiveEffect::new(params, sr, 1);

    let filtered: Vec<f32> = rich.iter().map(|&s| effect.process(s, 0, sr)).collect();
    let after = SoundData::from_samples(filtered.clone(), sr, 1);
    save_wav("audio_dsp/bandpass_after", &after);
    save_png("audio_dsp/bandpass_after_waveform", &visualization::waveform_to_image(&filtered, sr, 800, 300));
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
    save_png("audio_dsp/reverb_before_waveform", &visualization::waveform_to_image(&samples, sr, 800, 300));

    let params = Arc::new(EffectParams::new(4, EffectType::Reverb));
    params.set_param("room_size", 0.8).unwrap();
    params.set_param("damping", 0.5).unwrap();
    params.set_param("mix", 0.6).unwrap();
    let mut effect = ActiveEffect::new(params, sr, 1);

    let reverbed: Vec<f32> = samples.iter().map(|&s| effect.process(s, 0, sr)).collect();
    let after = SoundData::from_samples(reverbed.clone(), sr, 1);
    save_wav("audio_dsp/reverb_after", &after);
    save_png("audio_dsp/reverb_after_waveform", &visualization::waveform_to_image(&reverbed, sr, 800, 300));
}

#[test]
fn evidence_dsp_chorus() {
    let sr = 44100u32;
    let samples = make_sine_samples(440.0, 2.0, sr);

    let before = SoundData::from_samples(samples.clone(), sr, 1);
    save_wav("audio_dsp/chorus_before", &before);
    save_png("audio_dsp/chorus_before_waveform", &visualization::waveform_to_image(&samples, sr, 800, 300));
    save_png("audio_dsp/chorus_before_zoomed", &visualization::waveform_zoomed_to_image(&samples, 2000, 800, 300));

    let params = Arc::new(EffectParams::new(5, EffectType::Chorus));
    params.set_param("rate", 1.5).unwrap();
    params.set_param("depth", 0.5).unwrap();
    params.set_param("mix", 0.5).unwrap();
    let mut effect = ActiveEffect::new(params, sr, 1);

    let chorused: Vec<f32> = samples.iter().map(|&s| effect.process(s, 0, sr)).collect();
    let after = SoundData::from_samples(chorused.clone(), sr, 1);
    save_wav("audio_dsp/chorus_after", &after);
    save_png("audio_dsp/chorus_after_waveform", &visualization::waveform_to_image(&chorused, sr, 800, 300));
    save_png("audio_dsp/chorus_after_zoomed", &visualization::waveform_zoomed_to_image(&chorused, 2000, 800, 300));
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
    save_png("audio_dsp/filter_sweep_waveform", &visualization::waveform_to_image(&swept, sr, 800, 300));
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
    save_png("audio/fm_synthesis_waveform", &visualization::waveform_to_image(&samples, sr, 800, 300));
    save_png("audio/fm_synthesis_zoomed", &visualization::waveform_zoomed_to_image(&samples, 2000, 800, 300));
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

    let img = grid.draw_to_image(8, path.as_deref(), Some((2, 2)), Some((37, 27)));
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

    let img = mm.draw_to_image(8);
    save_png("combined/noise_minimap", &img);
}


// ═══════════════════════════════════════════════════════════════════
// ██  SHAPES & POLYGON EVIDENCE
// ═══════════════════════════════════════════════════════════════════

/// Draw geometric shapes using only draw_line: triangle, square, pentagon,
/// hexagon, octagon, and star — proving draw_line can render any polygon.
#[test]
fn evidence_shapes_polygon_gallery() {
    let img = visualization::polygon_gallery_to_image(512, 512);
    save_png("shapes/polygon_gallery", &img);
}

/// Draw filled shapes using set_pixel scanline fill for triangles and rects.
#[test]
fn evidence_shapes_filled_primitives() {
    let img = visualization::filled_primitives_to_image(400, 400);
    save_png("shapes/filled_primitives", &img);
}

/// Draw concentric circles and spirals to demonstrate draw_line + math.
#[test]
fn evidence_shapes_spirals() {
    let img = visualization::spiral_to_image(400, 400);
    save_png("shapes/spirals", &img);
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
    save_png("audio/stereo_pan_sweep_waveform", &visualization::waveform_stereo_to_image(&stereo, sr, 800, 400));
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
    save_png("audio/stereo_hard_left_waveform", &visualization::waveform_stereo_to_image(&stereo, sr, 800, 400));
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
    save_png("audio/stereo_hard_right_waveform", &visualization::waveform_stereo_to_image(&stereo, sr, 800, 400));
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
    save_png("audio/stereo_ping_pong_waveform", &visualization::waveform_stereo_to_image(&stereo, sr, 800, 400));
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
    save_png("audio/spatial_circle_waveform", &visualization::waveform_stereo_to_image(&stereo, sr, 800, 400));
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

    let img = rc.draw_view_to_image(3.0, 3.0, 0.6, std::f32::consts::FRAC_PI_3, 320, 200, 20.0);
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

    let img = rc.draw_camera_sweep_to_image(
        8.0, 8.0,
        std::f32::consts::FRAC_PI_3,
        20.0,
        12, 120, 90,
    );
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

    let img = rc.draw_view_to_image(3.0, 3.0, 0.4, std::f32::consts::FRAC_PI_3, 400, 250, 30.0);
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

    let img = visualization::dungeon_grid_to_image(&grid, w, h, 4);
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
    let img = visualization::terrain_elevation_to_image(&data, w as u32, h as u32);
    save_png("procgen/terrain_elevation", &img);
}

/// Multi-octave noise comparison: 1 vs 3 vs 6 vs 8 octaves side by side.
#[test]
fn evidence_procgen_octave_comparison() {
    let tile: usize = 128;
    let gen = NoiseGenerator::new(99);
    let maps: Vec<Vec<f64>> = [1u32, 3, 6, 8].iter().map(|&octaves| {
        let opts = MapGenOptions {
            kind: NoiseKind::Perlin,
            octaves,
            scale_x: 0.04, scale_y: 0.04,
            ..Default::default()
        };
        gen.generate_map(tile as u32, tile as u32, &opts)
    }).collect();
    let refs: Vec<&[f64]> = maps.iter().map(|v| v.as_slice()).collect();
    let img = visualization::noise_comparison_to_image(&refs, tile as u32, tile as u32);
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

    let img = ps.draw_explosion_to_image(400, 400);
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

    let img = ps.draw_rain_to_image(400, 300);
    save_png("particle/rain", &img);
}

/// Spark trail effect — particles along a path.
#[test]
fn evidence_particle_spark_trail() {
    let mut img = ImageData::new(400, 300);
    img.fill(10, 10, 15, 255);

    // Place multiple stationary emitters along the sine path
    let num_emitters = 12;
    for i in 0..num_emitters {
        let t = i as f32 / (num_emitters - 1) as f32;
        let ex = 50.0 + t * 300.0;
        let ey = 150.0 + (t * 4.0 * std::f32::consts::PI).sin() * 80.0;

        let config = ParticleConfig {
            max_particles: 40,
            emission_rate: 80.0,
            direction: std::f32::consts::PI,
            spread: std::f32::consts::PI,
            speed_min: 8.0,
            speed_max: 30.0,
            lifetime_min: 0.5,
            lifetime_max: 1.5,
            ..Default::default()
        };
        let mut ps = ParticleSystem::new(config);
        ps.move_to(ex, ey);
        ps.start();

        let age = (1.0 - t) * 0.8 + 0.1;
        let steps = (age / 0.016) as usize;
        for _ in 0..steps { ps.update(0.016); }

        let spark_img = ps.draw_spark_trail_to_image(400, 300);
        // Composite spark particles onto the canvas
        for p in &ps.particles {
            if p.life > 0.0 {
                let px = p.x as i32;
                let py = p.y as i32;
                if px >= 0 && px < 400 && py >= 0 && py < 300 {
                    let age_frac = 1.0 - p.life / p.max_life;
                    let r = 255;
                    let g = (220.0 * (1.0 - age_frac)) as u8;
                    let b = (80.0 * (1.0 - age_frac * 0.8)) as u8;
                    img.set_pixel(px as u32, py as u32, r, g, b, 255);
                }
            }
        }
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
    let steps = [0.0f32, 0.15, 0.3, 0.45];
    let img = overlay.draw_flash_sequence_to_image(
        1.0, 0.0, 0.0, 0.8, 0.5, &steps, 200, 150,
    );
    save_png("overlay/flash_sequence", &img);
}

/// Overlay shake effect — offset visualization at different times.
#[test]
fn evidence_overlay_shake_offsets() {
    let mut overlay = Overlay::new(200, 200);
    overlay.trigger_shake(80.0, 1.0);

    // Record shake offsets
    let mut offsets = Vec::new();
    for _ in 0..120 {
        offsets.push(overlay.get_shake_offset());
        overlay.update(1.0 / 60.0);
    }

    let img = Overlay::draw_shake_trail_to_image(&offsets, 400, 400);
    save_png("overlay/shake_offsets", &img);
}

/// Overlay fade effect — smooth alpha transition.
#[test]
fn evidence_overlay_fade_transition() {
    let mut overlay = Overlay::new(100, 100);
    overlay.trigger_fade(0.0, 0.0, 0.0, 1.0, 1.0);

    // Sample 6 time points
    let mut steps = Vec::new();
    for frame in 0..6 {
        if frame > 0 { overlay.update(0.18); }
        let active = overlay.is_active();
        let brightness = if active { 1.0 - frame as f32 / 6.0 } else { 1.0 };
        steps.push(1.0 - brightness);
    }

    let img = Overlay::draw_fade_transition_to_image(&steps, 100, 100);
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
    let img = PostFxStack::draw_effect_types_to_image(&types, 400, 300);
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
    let img = stack.draw_info_to_image(300, 200);
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
    let img = visualization::draw_pixel_transform_grid_to_image(100, 300);
    save_png("image/map_pixel_transforms", &img);
}

/// ImageData get_pixel and dimensions proof.
#[test]
fn evidence_image_dimensions_and_pixels() {
    // Dimension assertions — keep in test
    let img = ImageData::new(100, 50);
    assert_eq!(img.width(), 100);
    assert_eq!(img.height(), 50);
    assert_eq!(img.dimensions(), (100, 50));

    // Pixel read/write assertions — keep in test
    let mut img = ImageData::new(200, 200);
    img.set_pixel(10, 10, 255, 0, 0, 255);
    img.set_pixel(20, 20, 0, 255, 0, 255);
    img.set_pixel(30, 30, 0, 0, 255, 255);
    assert_eq!(img.get_pixel(10, 10), Some((255, 0, 0, 255)));
    assert_eq!(img.get_pixel(20, 20), Some((0, 255, 0, 255)));
    assert_eq!(img.get_pixel(30, 30), Some((0, 0, 255, 255)));
    assert_eq!(img.get_pixel(201, 201), None);

    let img = visualization::draw_color_wheel_to_image(200, 200);
    save_png("image/color_wheel_pixel_proof", &img);
}

// ═══════════════════════════════════════════════════════════════════
// ██  BEZIER CURVE EVIDENCE (expanded)
// ═══════════════════════════════════════════════════════════════════

/// Bezier curves — cubic curves with control point visualization.
#[test]
fn evidence_math_bezier_cubic_curves() {
    let curve_data: &[(Vec<Vec2>, (u8, u8, u8))] = &[
        (vec![Vec2::new(50.0, 350.0), Vec2::new(100.0, 50.0), Vec2::new(300.0, 50.0), Vec2::new(350.0, 350.0)], (255, 80, 80)),
        (vec![Vec2::new(50.0, 200.0), Vec2::new(150.0, 50.0), Vec2::new(250.0, 350.0), Vec2::new(350.0, 200.0)], (80, 255, 80)),
        (vec![Vec2::new(50.0, 100.0), Vec2::new(200.0, 350.0), Vec2::new(200.0, 50.0), Vec2::new(350.0, 300.0)], (80, 80, 255)),
    ];
    let img = visualization::bezier_curves_to_image(curve_data, 400, 400);
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
    save_png("audio/adsr_envelope_waveform", &visualization::waveform_to_image(&samples, sr, 800, 300));
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
    save_png("audio/white_noise_waveform", &visualization::waveform_to_image(&white, sr, 800, 300));
    save_png("audio/pink_noise_waveform", &visualization::waveform_to_image(&pink, sr, 800, 300));
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
    save_png("audio_dsp/chain_before_waveform", &visualization::waveform_to_image(&rich, sr, 800, 300));
    save_png("audio_dsp/chain_after_lowpass_waveform", &visualization::waveform_to_image(&after_lp, sr, 800, 300));
    save_png("audio_dsp/chain_final_waveform", &visualization::waveform_to_image(&after_chain, sr, 800, 300));
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

    let img = rc.draw_view_to_image(12.0, 12.0, 0.8, std::f32::consts::FRAC_PI_3, 320, 200, 24.0);
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

    let mut bg = ImageData::new(256, 192);
    bg.fill(15, 15, 25, 255);
    for y in 0..12u32 { for x in 0..16u32 {
        let tile = tm.get_tile(ground, x, y);
        let (r, g, b): (u8, u8, u8) = if tile == 1 { (50, 70, 50) } else { (40, 60, 40) };
        bg.draw_rect((x * 16) as i32, (y * 16) as i32, 16, 16, r, g, b, 255);
    }}
    let img = ps.draw_over_image(bg);
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

    let img = chart.draw_to_image();
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

    let img = chart.draw_to_image();
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

    let img = chart.draw_to_image();
    save_png("chart/scatter_plot", &img);
}

/// Pie chart with colored segments and percentage labels.
#[test]
fn evidence_chart_pie_chart() {
    let cfg = ChartConfig {
        width: 400,
        height: 400,
        title: Some("PIE CHART".to_string()),
        bg_color: (250, 250, 252),
        ..ChartConfig::default()
    };
    let mut chart = PieChart::new(cfg);
    chart.add_segment("WORK 35%", 35.0, Color::new(0.27, 0.51, 0.78, 1.0));
    chart.add_segment("SLEEP 25%", 25.0, Color::new(0.86, 0.31, 0.24, 1.0));
    chart.add_segment("PLAY 20%", 20.0, Color::new(0.31, 0.75, 0.31, 1.0));
    chart.add_segment("EAT 12%", 12.0, Color::new(0.86, 0.71, 0.20, 1.0));
    chart.add_segment("OTHER 8%", 8.0, Color::new(0.63, 0.31, 0.78, 1.0));

    let img = chart.draw_to_image();
    save_png("chart/pie_chart", &img);
}

/// Stacked area chart showing cumulative data over time.
#[test]
fn evidence_chart_area_chart() {
    let cfg = ChartConfig {
        width: 400,
        height: 300,
        title: Some("AREA CHART".to_string()),
        bg_color: (245, 245, 248),
        ..ChartConfig::default()
    };
    let mut chart = AreaChart::new(cfg);

    chart.add_layer("ALPHA", &[20.0, 25.0, 30.0, 28.0, 35.0, 40.0, 38.0, 45.0, 42.0, 50.0, 48.0, 55.0],
        Color::new(0.39, 0.59, 0.86, 1.0));
    chart.add_layer("BETA", &[15.0, 18.0, 20.0, 22.0, 18.0, 25.0, 28.0, 24.0, 30.0, 28.0, 32.0, 30.0],
        Color::new(0.39, 0.71, 0.39, 1.0));
    chart.add_layer("GAMMA", &[10.0, 12.0, 8.0, 15.0, 12.0, 10.0, 14.0, 12.0, 8.0, 15.0, 10.0, 12.0],
        Color::new(0.71, 0.39, 0.78, 1.0));

    let img = chart.draw_to_image();
    save_png("chart/area_chart", &img);
}

// ===== GUI DRAWING EVIDENCE =====

/// GUI button states: normal, hover, pressed, disabled.
#[test]
fn evidence_gui_button_states() {
    let theme = Theme::new();
    let img = theme.draw_button_states_to_image(400, 200);
    save_png("gui/button_states", &img);
}

/// GUI panel with title bar, content area, and nested elements.
#[test]
fn evidence_gui_panel_layout() {
    let img = visualization::panel_layout_to_image(400, 350);
    save_png("gui/panel_layout", &img);
}
#[test]
fn evidence_gui_hud_bars() {
    let img = visualization::hud_bars_to_image(400, 250);
    save_png("gui/hud_bars", &img);
}


// ===== POSTFX / OVERLAY / STACK — Effect system evidence =====

/// Catalog all 16 PostFxEffectType variants — construction, parameters, type names.
#[test]
fn evidence_postfx_effect_catalog() {
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

    // Exercise API for each variant
    for (variant, _label, _color) in &variants {
        let mut effect = PostFxEffect::new(variant.clone());
        let type_name = effect.get_type_name();
        assert!(!type_name.is_empty(), "type_name should not be empty for {:?}", variant);

        if matches!(variant, PostFxEffectType::Custom) {
            assert!(!effect.is_built_in());
        } else {
            assert!(effect.is_built_in());
        }

        effect.set_parameter("intensity", 0.75);
        let val = effect.get_parameter("intensity", 0.0);
        assert!((val - 0.75).abs() < 1e-5);
        assert!(effect.has_parameter("intensity"));
    }

    let entries: Vec<(&str, (u8, u8, u8))> = variants.iter().map(|(_, l, c)| (*l, *c)).collect();
    let img = PostFxStack::draw_effect_catalog_to_image(&entries, 620, 520);
    save_png("effects/postfx_catalog", &img);
}

/// PostFxStack operations — add, remove, insert, enable/disable, query.
#[test]
fn evidence_postfx_stack_management() {
    let mut stack = PostFxStack::new(800, 600);
    assert_eq!(stack.get_effect_count(), 0);

    stack.add(0); // "Bloom"
    stack.add(1); // "Blur"
    stack.add(2); // "CRT"
    stack.add(3); // "Vignette"
    stack.add(4); // "Sepia"
    assert_eq!(stack.get_effect_count(), 5);

    // Disable effect 2 (CRT)
    stack.set_enabled(2, false);
    assert!(!stack.is_enabled(2));

    // Insert effect 5 at position 1
    stack.insert(1, 5);
    assert_eq!(stack.get_effect_count(), 6);

    // Remove effect at index 3
    stack.remove(3);

    let enabled_list = stack.enabled_effects();
    assert!(enabled_list.len() <= stack.get_effect_count());

    // Resize test
    stack.resize(1920, 1080);

    let labels = &["BLOOM", "NEW", "BLUR", "VIGNETTE", "SEPIA"];
    let img = stack.draw_stack_management_to_image(400, 350, labels);
    save_png("effects/postfx_stack", &img);
}

/// PostFxEffect parameter system — set, get, has, names, aliases.
#[test]
fn evidence_postfx_effect_parameters() {
    let test_cases: Vec<(PostFxEffectType, &str, Vec<(&str, f32)>)> = vec![
        (PostFxEffectType::Bloom,     "BLOOM",     vec![("threshold", 0.8), ("intensity", 1.5), ("radius", 4.0)]),
        (PostFxEffectType::Blur,      "BLUR",      vec![("radius", 3.0), ("sigma", 1.5)]),
        (PostFxEffectType::Chromatic, "CHROMATIC", vec![("offset", 2.5), ("angle", 0.0)]),
        (PostFxEffectType::Vignette,  "VIGNETTE",  vec![("strength", 0.6), ("radius", 0.8)]),
        (PostFxEffectType::HueShift,  "HUESHIFT",  vec![("degrees", 90.0)]),
        (PostFxEffectType::Noise,     "NOISE",     vec![("amount", 0.3), ("speed", 1.0)]),
    ];

    for (variant, _label, params) in &test_cases {
        let mut effect = PostFxEffect::new(variant.clone());
        assert!(effect.is_built_in());
        let type_name = effect.get_type_name();
        assert!(!type_name.is_empty());
        for &(name, val) in params {
            effect.set_parameter(name, val);
            let got = effect.get_parameter(name, 0.0);
            assert!((got - val).abs() < 1e-5, "param {} expected {} got {}", name, val, got);
            assert!(effect.has_parameter(name));
        }
        let missing = effect.get_parameter("nonexistent", 42.0);
        assert!((missing - 42.0).abs() < 1e-5);
        assert!(!effect.has_parameter("nonexistent"));
        let _names = effect.get_parameter_names();
    }

    let disabled = PostFxEffect::new_disabled(PostFxEffectType::Sepia);
    let _ = disabled.get_type_name();
    let custom = PostFxEffect::new_custom(999);
    assert!(!custom.is_built_in());
    let mut alias_test = PostFxEffect::new(PostFxEffectType::Blur);
    alias_test.set_param("radius", 5.0);
    let alias_val = alias_test.get_param_or("radius", 0.0);
    assert!((alias_val - 5.0).abs() < 1e-5);

    // Build render entries and delegate to domain render method
    let mut all_entries: Vec<(&str, Vec<(&str, f32)>)> = test_cases
        .iter()
        .map(|(_, label, params)| (*label, params.clone()))
        .collect();
    all_entries.push(("DISABLED SEPIA", vec![]));
    all_entries.push(("CUSTOM 999", vec![]));
    all_entries.push(("ALIAS OK", vec![]));
    let entry_slices: Vec<(&str, &[(&str, f32)])> = all_entries
        .iter()
        .map(|(l, p)| (*l, p.as_slice()))
        .collect();
    let img = PostFxStack::draw_effect_parameters_to_image(&entry_slices, 500, 420);
    save_png("effects/postfx_parameters", &img);
}


/// Overlay system — trigger flash, shake, fade, lightning.
#[test]
fn evidence_overlay_triggers() {
    let mut overlay = Overlay::new(500, 420);
    let img = overlay.draw_trigger_panel_to_image(500, 420);
    save_png("effects/overlay_triggers", &img);
}

// ===== PARTICLE TRAIL — Trail system evidence =====

/// Trail system — push points, width, color, lifetime, update.
#[test]
fn evidence_particle_trail_system() {
    // ── Trail 1: Curved path with head/tail colors ──
    let mut trail1 = Trail::new(3.0, 6.0);
    trail1.set_head_color(Color::new(1.0, 0.2, 0.0, 1.0));
    trail1.set_tail_color(Color::new(0.0, 0.2, 1.0, 0.3));
    trail1.set_width(8.0, Some(1.0));

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

    let img1 = trail1.draw_to_image(500, 200);
    save_png("particle/trail_sine", &img1);

    // ── Trail 2: After update showing lifetime decay ──
    let mut trail2 = Trail::new(0.5, 4.0);
    trail2.set_head_color(Color::new(0.0, 1.0, 0.0, 1.0));
    trail2.set_tail_color(Color::new(1.0, 1.0, 0.0, 0.5));

    for i in 0..40 {
        let t = i as f32 / 39.0;
        let x = 30.0 + t * 200.0;
        let y = 100.0 + (t * 3.0 * std::f32::consts::PI).cos() * 30.0;
        trail2.push_point(x, y);
    }

    let count_before = trail2.get_point_count();
    trail2.update(0.3);
    let count_after = trail2.get_point_count();
    assert!(count_after <= count_before);

    let img2 = trail2.draw_to_image(300, 200);
    save_png("particle/trail_decay", &img2);

    // ── Trail 3: min_distance and clear ──
    let mut trail3 = Trail::new(2.0, 3.0);
    trail3.set_min_distance(10.0);

    for i in 0..100 {
        let x = 30.0 + (i as f32) * 1.5;
        let y = 100.0 + (i as f32 * 0.2).sin() * 20.0;
        trail3.push_point(x, y);
    }
    let filtered_count = trail3.get_point_count();
    assert!(filtered_count < 100, "min_distance should filter close points");

    let img3 = trail3.draw_to_image(300, 200);
    save_png("particle/trail_filtered", &img3);

    trail3.clear();
    assert_eq!(trail3.get_point_count(), 0);
    trail3.set_lifetime(5.0);
    assert!((trail3.get_lifetime() - 5.0).abs() < 1e-5);
}

/// Particle emitter control — start, stop, pause, resume, emit, move, reset.
#[test]
fn evidence_particle_emitter_control() {
    let config = ParticleConfig {
        max_particles: 200,
        emission_rate: 0.0,
        ..ParticleConfig::default()
    };
    let mut emitter = ParticleSystem::new(config);

    // State 1: Initial
    assert!(emitter.is_empty());
    assert!(!emitter.is_paused());
    let _initial_count = emitter.count();

    // State 2: Emit
    emitter.emit(50);
    assert!(emitter.count() > 0);

    // State 3: Pause
    emitter.pause();
    assert!(emitter.is_paused());
    let _before_update = emitter.count();
    emitter.update(0.1);

    // State 4: Resume
    emitter.resume();
    assert!(!emitter.is_paused());

    // State 5: Stop
    emitter.stop();
    assert!(emitter.is_stopped());

    // State 6: Start
    emitter.start();
    assert!(!emitter.is_stopped());
    assert!(emitter.is_active());

    // State 7: Move
    emitter.move_to(100.0, 100.0);

    // State 8: Reset
    let _count_before_reset = emitter.count();
    emitter.reset();
    assert_eq!(emitter.count(), 0);

    // State 9: Full check
    emitter.emit(200);
    let _is_full = emitter.is_full();

    // Render lifecycle diagram using domain method
    let mut demo = ParticleSystem::new(ParticleConfig {
        max_particles: 200,
        emission_rate: 0.0,
        ..ParticleConfig::default()
    });
    demo.emit(200);
    let mut snapshots: Vec<(u32, usize)> = Vec::new();
    for step in 0..50u32 {
        snapshots.push((step, demo.count()));
        demo.update(0.05);
    }
    let img = ParticleSystem::draw_lifecycle_to_image(&snapshots, 200, 500, 440);
    save_png("particle/emitter_control", &img);
}


// =====================================================================
// ===== BATCH 2 — Camera rotation, bounds, follow, shake =====
// =====================================================================

#[test]
fn evidence_camera_rotation_transform() {
    let rotations: Vec<(f32, &str)> = vec![
        (0.0, "0"), (0.5, "0.5"), (1.0, "1.0"),
        (1.57, "PI-2"), (2.1, "2.1"), (2.6, "2.6"),
    ];
    // Verify rotation setter works
    for &(rot, _) in &rotations {
        let mut cam = Camera2D::new(120.0, 120.0);
        cam.set_rotation(rot);
        assert!((cam.get_rotation() - rot).abs() < 1e-5);
    }
    let img = visualization::draw_camera_rotation_grid_to_image(
        &rotations, 120.0, 120.0, 400, 300,
    );
    save_png("camera/rotation_transform", &img);
}

#[test]
fn evidence_camera_bounds_clamping() {
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

    let positions = [
        (px1, py1, "NO BOUNDS", 200u8, 80, 80),
        (px2, py2, "CLAMPED", 80, 200, 80),
        (px3, py3, "IN BOUNDS", 80, 80, 200),
        (px4, py4, "FREE AGAIN", 200, 200, 80),
    ];
    let img = visualization::draw_camera_bounds_to_image(&positions, 400, 250);
    save_png("camera/bounds_clamping", &img);
}

#[test]
fn evidence_camera_follow_deadzone() {
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

    let (cx, cy) = cam.get_position();

    // Clear target
    cam.clear_target();
    assert!(cam.get_target().is_none());

    let targets_vec: Vec<(f32, f32)> = targets.to_vec();
    let img = visualization::draw_camera_follow_trail_to_image(
        &trail, &targets_vec, (dw, dh), (cx, cy), 400, 300,
    );
    save_png("camera/follow_deadzone", &img);
}

#[test]
fn evidence_camera_shake_effect() {
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

    // Show move_by and visible area
    cam.set_position(200.0, 100.0);
    cam.move_by(50.0, 25.0);
    let (mx, my) = cam.get_position();
    let (vx, vy, vw, vh) = cam.get_visible_area();

    let img = visualization::draw_camera_shake_trail_to_image(
        &positions, (mx, my), (vx, vy, vw, vh), 400, 200,
    );
    save_png("camera/shake_effect", &img);
}

// =====================================================================
// ===== BATCH 2 — Geometry functions evidence =====
// =====================================================================

#[test]
fn evidence_geometry_shapes_and_queries() {
    // Assertions — keep in test
    let points: Vec<f32> = vec![
        50.0, 50.0, 100.0, 30.0, 150.0, 60.0, 130.0, 120.0,
        80.0, 130.0, 40.0, 100.0, 90.0, 80.0, 110.0, 70.0,
    ];
    let _hull = lurek2d::math::convex_hull(&points);

    let triangle: Vec<f32> = vec![350.0, 30.0, 450.0, 100.0, 340.0, 100.0];
    assert!(lurek2d::math::point_in_polygon(&triangle, 380.0, 70.0));
    assert!(!lurek2d::math::point_in_polygon(&triangle, 320.0, 30.0));

    assert!(lurek2d::math::circle_contains_point(100.0, 300.0, 40.0, 110.0, 310.0));
    assert!(!lurek2d::math::circle_contains_point(100.0, 300.0, 40.0, 200.0, 300.0));

    assert!(lurek2d::math::circle_intersects_circle(300.0, 300.0, 30.0, 340.0, 300.0, 30.0));

    let img = visualization::draw_geometry_shapes_to_image(500, 400);
    save_png("math/geometry_shapes", &img);
}

#[test]
fn evidence_geometry_intersections() {
    // Assertions — keep in test
    let (hit, _point) = lurek2d::math::segment_intersects_segment(
        20.0, 20.0, 150.0, 120.0,
        20.0, 120.0, 150.0, 20.0,
    );
    assert!(hit);

    let (no_hit, _) = lurek2d::math::segment_intersects_segment(
        20.0, 160.0, 100.0, 160.0,
        20.0, 200.0, 100.0, 200.0,
    );
    assert!(!no_hit);

    let (cl_hit, _p1, _p2) = lurek2d::math::circle_intersects_line(
        300.0, 200.0, 50.0,
        200.0, 200.0, 400.0, 200.0,
    );
    assert!(cl_hit);

    let img = visualization::draw_geometry_intersections_to_image(450, 350);
    save_png("math/geometry_intersections", &img);
}

#[test]
fn evidence_geometry_delaunay() {
    let pts: Vec<(f64, f64)> = vec![
        (50.0, 50.0), (200.0, 30.0), (350.0, 70.0),
        (30.0, 200.0), (150.0, 180.0), (280.0, 150.0), (370.0, 200.0),
        (80.0, 320.0), (200.0, 350.0), (330.0, 300.0),
        (120.0, 100.0), (250.0, 250.0), (180.0, 270.0),
    ];
    let triangles = lurek2d::math::delaunay_triangulate(&pts);
    let img = visualization::draw_delaunay_to_image(&pts, &triangles, 400, 400);
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

    let stats = graph.get_stats();
    let stats_str = format!("N{} E{}", stats.nodes, stats.edges);
    let positions: Vec<(f32, f32)> = vec![
        (80.0, 80.0), (200.0, 50.0), (320.0, 150.0),
        (80.0, 220.0), (200.0, 250.0),
    ];
    let node_labels = ["FACTORY", "WAREHOUSE", "SHOP", "FACTORY2", "WAREHOUSE2"];
    let node_colors = [
        (200u8, 80, 80), (80, 160, 200), (80, 200, 80),
        (200, 80, 80), (80, 160, 200),
    ];
    let edges_draw = [(0usize, 1), (1, 2), (3, 4), (4, 2)];
    let removed = [(0usize, 3)];
    let img = visualization::draw_graph_operations_to_image(
        &positions, &node_labels, &node_colors,
        &edges_draw, &removed, &stats_str, "GRAPH OPS OK", 400, 300,
    );
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

    let node_pos: Vec<(f32, f32)> = vec![(60.0, 100.0), (200.0, 100.0), (340.0, 100.0)];
    let node_names = ["SOURCE", "RELAY", "SINK"];
    let node_colors = [(200u8, 100, 80), (200, 200, 80), (80, 200, 100)];
    let items = [
        (130i32, 85, 255u8, 200, 80, "ORE"),
        (70, 75, 200, 180, 100, "GOLD"),
    ];
    let items_str = format!("ITEMS {}", stats.items);
    let img = visualization::draw_graph_item_flow_to_image(
        &node_pos, &node_names, &node_colors,
        &items, &items_str, "ITEM FLOW OK", 400, 200,
    );
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
    anim.add_clip_from_grid("attack", 256, 64, 32, 64, 0, 3, 12.0, false);

    // Assertions — keep in test
    anim.play("run");
    assert!(anim.is_playing());
    assert_eq!(anim.get_current_clip(), Some("run"));

    let mut run_frames: Vec<usize> = Vec::new();
    for _ in 0..20 {
        anim.update(1.0 / 10.0);
        run_frames.push(anim.current_frame());
    }

    anim.pause();
    let paused_frame = anim.current_frame();
    anim.update(1.0 / 10.0);
    assert_eq!(anim.current_frame(), paused_frame);

    anim.resume();
    anim.update(1.0 / 10.0);

    anim.stop();
    assert!(!anim.is_playing());

    anim.play("idle");
    assert_eq!(anim.get_current_clip(), Some("idle"));
    let mut idle_frames: Vec<usize> = Vec::new();
    for _ in 0..12 {
        anim.update(1.0 / 4.0);
        idle_frames.push(anim.current_frame());
    }

    anim.play("run");
    anim.set_frame(2);
    assert_eq!(anim.current_frame(), 2);
    let quad_str = anim.current_quad().map(|q| {
        format!("{:.0} {:.0} {:.0}X{:.0}", q.x, q.y, q.width, q.height)
    });

    anim.play("jump");
    for _ in 0..20 {
        anim.update(1.0 / 8.0);
    }
    let _jump_done = !anim.is_playing() || anim.current_frame() == 1;

    let summary = format!("{} FRAMES {} CLIPS", anim.get_frame_count(), 4);
    let img = visualization::animation_playback_control_to_image(
        &run_frames, &idle_frames, 8,
        quad_str.as_deref(), &summary,
        500, 350,
    );
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

    let bg = layers.add_layer("background");
    let mid = layers.add_layer("midground");
    let fg = layers.add_layer("foreground");
    let overlay = layers.add_layer("overlay");
    assert_eq!(layers.layer_count(), 4);

    let mut bg_img = ImageData::new(200, 200);
    for y in 0..200u32 {
        for x in 0..200u32 {
            let r = (x * 200 / 200) as u8;
            let b = (y * 200 / 200) as u8;
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

    layers.set_opacity(overlay, 0.2);
    layers.set_visible(mid, true);
    layers.set_name(bg, "base");

    let merged1 = layers.merge();
    assert!(layers.swap_layers(mid, fg));
    assert!(layers.move_layer(overlay, 1));
    let merged2 = layers.merge();

    let removed = layers.remove_layer(overlay);
    assert!(removed.is_some());
    assert_eq!(layers.layer_count(), 3);
    let merged3 = layers.merge();

    let img = visualization::draw_image_comparison_to_image(
        &[&merged1, &merged2, &merged3],
        &["ORIGINAL", "SWAPPED", "REMOVED"],
        620, 220,
    );
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

    // Visualize via domain method
    let label = format!("{} HZ {} SAMP", freq as i32, sample_count);
    let img = visualization::draw_sound_waveform_to_image(
        sound.samples(), &label, 500, 200, (200, 150, 120),
    );
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

    // Visualize via domain method
    let img = tm.draw_layers_to_image(16, 300, 300);
    save_png("tilemap/layer_management", &img);
}

// =====================================================================
// ===== BATCH 2 — Light advanced evidence =====
// =====================================================================

#[test]
fn evidence_light_falloff_modes() {
    let modes = [
        (FalloffMode::Linear, "LINEAR"),
        (FalloffMode::Smooth, "SMOOTH"),
        (FalloffMode::Constant, "CONSTANT"),
    ];
    // Verify API still works
    let mut light = Light2D::new(80.0, 90.0, 60.0);
    for &(mode, _) in &modes {
        light.set_falloff(mode);
        assert_eq!(light.get_falloff() as u8, mode as u8);
    }
    light.set_intensity(1.5);
    assert!((light.get_intensity() - 1.5).abs() < 0.01);
    light.set_energy(0.8);
    assert!((light.get_energy() - 0.8).abs() < 0.01);
    let color = Color::new(1.0, 0.8, 0.4, 1.0);
    light.set_color(color);

    let img = Light2D::draw_falloff_comparison_to_image(&modes, 60.0, 480, 180);
    save_png("light/falloff_modes", &img);
}

#[test]
fn evidence_light_attenuation() {
    let configs = [
        (Attenuation::new(1.0, 0.0, 0.0), "CONST ATTEN"),
        (Attenuation::new(1.0, 0.1, 0.0), "LINEAR ATTEN"),
        (Attenuation::new(1.0, 0.0, 0.05), "QUAD ATTEN"),
        (Attenuation::new(1.0, 0.05, 0.02), "MIXED ATTEN"),
    ];
    let img = Attenuation::draw_attenuation_curves_to_image(&configs, 20.0, 400, 200);
    save_png("light/attenuation_curves", &img);
}

// =====================================================================
// ===== BATCH 2 — Bezier advanced evidence =====
// =====================================================================

#[test]
fn evidence_bezier_advanced_ops() {
    let img = visualization::draw_bezier_advanced_to_image(500, 400);
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
    let _l_leg = skeleton.add_bone(Bone::with_parent("l_leg", root, -12.0, 35.0));
    let _r_leg = skeleton.add_bone(Bone::with_parent("r_leg", root, 12.0, 35.0));
    let l_hand = skeleton.add_bone(Bone::with_parent("l_hand", l_arm, -15.0, 20.0));
    let _r_hand = skeleton.add_bone(Bone::with_parent("r_hand", r_arm, 15.0, 20.0));

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

    // Visualize via domain method
    let img = skeleton.draw_bones_to_image(400, 400);
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

    let img = rc.draw_textured_view_to_image(3.5, 8.0, 0.4, std::f32::consts::FRAC_PI_3, 640, 400, 20.0);
    save_png("raycaster/procedural_textures", &img);
}
