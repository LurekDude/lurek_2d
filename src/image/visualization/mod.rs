//! Standalone visualization helpers for Tier 1 modules.
//!
//! Because Tier 1 modules (animation, camera) cannot import `crate::image`,
//! render helpers that produce `ImageData` from their structs live here,
//! accepting the domain object by reference.
//!
//! Submodules are organized by domain: animation, audio, camera, easing/bezier,
//! geometry, graph, image operations, noise/terrain, procedural generation, and UI.

pub mod animation;
pub mod audio;
pub mod camera;
pub mod easing;
pub mod geometry;
pub mod graph;
pub mod image_ops;
pub mod noise;
pub mod procgen;
pub mod ui;

pub use animation::*;
pub use audio::*;
pub use camera::*;
pub use easing::*;
pub use geometry::*;
pub use graph::*;
pub use image_ops::*;
pub use noise::*;
pub use procgen::*;
pub use ui::*;

/// Convert HSV colour to RGB bytes.
pub(crate) fn hsv_to_rgb_viz(h: u16, s: f32, v: f32) -> (u8, u8, u8) {
    let h = (h % 360) as f32;
    let c = v * s;
    let x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
    let m = v - c;
    let (r, g, b) = match (h / 60.0) as u8 {
        0 => (c, x, 0.0f32),
        1 => (x, c, 0.0),
        2 => (0.0, c, x),
        3 => (0.0, x, c),
        4 => (x, 0.0, c),
        _ => (c, 0.0, x),
    };
    (
        ((r + m) * 255.0) as u8,
        ((g + m) * 255.0) as u8,
        ((b + m) * 255.0) as u8,
    )
}
