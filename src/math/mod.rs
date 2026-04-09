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
/// RGBA color value type: named constants, `f32` and `u8` construction, packed `u32` output.
pub mod color;
/// Standard easing functions for smooth animation and interpolation.
pub mod easing;
/// 2D geometry utility functions: intersections, containment, polygon ops, rasterization.
pub mod geometry;

/// 3x3 column-major matrix for 2D transforms (translate, rotate, scale).
pub mod mat3;
/// Standalone noise functions: `perlin2d`, `perlin3d`, `perlin4d`, `simplex2d`, `simplex_noise_2d`, `simplex_noise_3d`, `fbm`.
pub mod noise_functions;
/// Configurable noise generator: `NoiseGenerator`, `NoiseKind`, `FractalType`, `DistType`, `MapGenOptions`.
pub mod noise_generator;
/// Polygon utilities: ear-clipping triangulation and convexity testing.
pub mod polygon;

/// Seedable random number generator for reproducible sequences.
pub mod random;
/// Axis-aligned rectangle with intersection and containment queries.
pub mod rect;
/// Spatial hash for efficient broad-phase AABB collision queries.
pub mod spatial_hash;
/// 2D affine transform with chainable methods wrapping Mat3.
pub mod transform;
/// Value interpolator with easing curves.
pub mod tween;
/// 2D floating-point vector with arithmetic operators and common helpers.
pub mod vec2;

pub use bezier::BezierCurve;
pub use color::{gamma_to_linear, linear_to_gamma, Color};
pub use geometry::*;
pub use mat3::Mat3;
pub use noise_functions::{
    fbm, perlin2d, perlin3d, perlin4d, simplex2d, simplex_noise_2d, simplex_noise_3d,
};
pub use noise_generator::{DistType, FractalType, MapGenOptions, NoiseGenerator, NoiseKind};
pub use random::RandomGenerator;
pub use rect::Rect;
pub use spatial_hash::SpatialHash;
pub use transform::Transform;
pub use tween::{Tween, TweenValue};
pub use vec2::Vec2;
