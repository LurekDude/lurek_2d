//! Foundational math and value types for the Lurek2D Baseline layer.
//!
//! This module is part of Lurek2D's Baseline (`math` subsystem) — the leaf of the
//! dependency graph with no Lurek2D dependencies of its own.
//!
//! [`Color`] (`sRGB [f32; 4]`) lives here as a pure value type. It was moved from
//! `src/graphics/srgb.rs` during the graphics-module-split session and is now the
//! canonical color type for the entire engine.
//!
//! All public items are documented. See `docs/architecture.md` for tier context
//! and the `lurek.*` Lua API for the scripting interface.
//!
/// Bezier curve evaluation using De Casteljau's algorithm.
pub mod bezier;
/// Circle value type for 2D collision geometry and containment queries.
pub mod circle;
/// RGBA color value type: named constants, `f32` and `u8` construction, packed `u32` output.
pub mod color;
/// Standard easing functions for smooth animation and interpolation.
pub mod easing;
/// 2D geometry utility functions: intersections, containment, polygon ops, rasterization.
pub mod geometry;

/// 3x3 column-major matrix for 2D transforms (translate, rotate, scale).
pub mod mat3;
/// Polygon utilities: ear-clipping triangulation and convexity testing.
pub mod polygon;
/// Interpolating and approximating splines: Catmull-Rom and Hermite.
pub mod spline;
/// 3D floating-point vector with arithmetic operators and common helpers.
pub mod vec3;

/// Dynamic AABB tree for efficient broad-phase overlap queries.
pub mod aabb_tree;
/// Noise sampling functions: raw Perlin/Simplex/Value/Worley noise primitives.
pub mod noise_functions;
/// Seeded procedural noise generator with fractal and map-generation helpers.
pub mod noise_generator;
/// Seedable random number generator for reproducible sequences.
pub mod random;
/// Axis-aligned rectangle with intersection and containment queries.
pub mod rect;
/// Runtime shelf rectangle packing for atlas/UI layout workflows.
pub mod rect_packing;
/// Spatial hash for efficient broad-phase AABB collision queries.
pub mod spatial_hash;
/// Spherical math helpers (lat/lon, ray-sphere, great-circle, axial tilt).
pub mod sphere;
/// 2D affine transform with chainable methods wrapping Mat3.
pub mod transform;
/// Value interpolator with easing curves.
pub mod tween;
/// 2D floating-point vector with arithmetic operators and common helpers.
pub mod vec2;
/// Voronoi tessellation (Bowyer–Watson Delaunay → Voronoi dual).
pub mod voronoi;

pub use aabb_tree::AabbTree;
pub use bezier::BezierCurve;
pub use circle::Circle;
pub use color::{gamma_to_linear, linear_to_gamma, Color};
pub use geometry::*;
pub use mat3::Mat3;
pub use noise_generator::{DistType, FractalType, MapGenOptions, NoiseGenerator, NoiseKind};
pub use random::RandomGenerator;
pub use rect::Rect;
pub use rect_packing::{PackedRect, RectPacker};
pub use spatial_hash::SpatialHash;
pub use spline::{CatmullRomSpline, HermiteSpline};
pub use transform::Transform;
pub use tween::{Tween, TweenValue};
pub use vec2::Vec2;
pub use vec3::Vec3;
pub use voronoi::{voronoi_from_points, VoronoiCell};

/// Linear interpolation between `a` and `b` by factor `t` in [0, 1].
///
/// # Parameters
/// - `a` — `f32`.
/// - `b` — `f32`.
/// - `t` — `f32`.
///
/// # Returns
/// `f32`.
pub fn lerp(a: f32, b: f32, t: f32) -> f32 {
    a + t * (b - a)
}

/// Remap `v` from `[in_min, in_max]` to `[out_min, out_max]`.
///
/// # Parameters
/// - `v` — `f32`.
/// - `in_min` — `f32`.
/// - `in_max` — `f32`.
/// - `out_min` — `f32`.
/// - `out_max` — `f32`.
///
/// # Returns
/// `f32`.
pub fn remap(v: f32, in_min: f32, in_max: f32, out_min: f32, out_max: f32) -> f32 {
    // Guard against near-zero input range to avoid division by zero
    let t = if (in_max - in_min).abs() < 1e-7 {
        0.0
    } else {
        (v - in_min) / (in_max - in_min)
    };
    out_min + t * (out_max - out_min)
}

/// Clamp `v` to the range `[min, max]`.
///
/// # Parameters
/// - `v` — Value to clamp.
/// - `min` — Lower bound.
/// - `max` — Upper bound.
///
/// # Returns
/// `f32` — `v` clamped to `[min, max]`.
pub fn clamp(v: f32, min: f32, max: f32) -> f32 {
    if v < min {
        min
    } else if v > max {
        max
    } else {
        v
    }
}

/// Returns the sign of `v`: `1.0` if positive, `-1.0` if negative, `0.0` if zero.
///
/// # Parameters
/// - `v` — `f32`.
///
/// # Returns
/// `f32` — `-1.0`, `0.0`, or `1.0`.
pub fn sign(v: f32) -> f32 {
    if v > 0.0 {
        1.0
    } else if v < 0.0 {
        -1.0
    } else {
        0.0
    }
}

/// Hermite smooth interpolation between 0 and 1 when `x` is in `[edge0, edge1]`.
///
/// Returns 0 if `x <= edge0`, 1 if `x >= edge1`, and a smooth cubic curve in between.
///
/// # Parameters
/// - `edge0` — Lower edge of the transition.
/// - `edge1` — Upper edge of the transition.
/// - `x` — Input value.
///
/// # Returns
/// `f32` — Smoothly interpolated value in `[0, 1]`.
pub fn smoothstep(edge0: f32, edge1: f32, x: f32) -> f32 {
    let t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    t * t * (3.0 - 2.0 * t)
}

/// Inverse linear interpolation: returns the `t` factor such that `lerp(a, b, t) ≈ v`.
///
/// # Parameters
/// - `a` — Start value.
/// - `b` — End value.
/// - `v` — Value between `a` and `b`.
///
/// # Returns
/// `f32` — Interpolation factor; `0.0` if `a ≈ b`.
pub fn inverse_lerp(a: f32, b: f32, v: f32) -> f32 {
    if (b - a).abs() < 1e-7 {
        0.0
    } else {
        (v - a) / (b - a)
    }
}
