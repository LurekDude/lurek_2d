//! Compatibility free-noise API layered on top of [`super::noise_generator::NoiseGenerator`].
//!
//! Historically this module carried an independent implementation of Perlin/
//! Simplex/FBM, while [`NoiseGenerator`] offered the seeded object-oriented API.
//! To prevent drift between the two surfaces, all free functions now delegate to
//! `NoiseGenerator` and preserve the legacy function signatures.

use super::noise_generator::{NoiseGenerator, NoiseKind};

/// Quintic fade curve for smooth interpolation: `6t^5 - 15t^4 + 10t^3`.
///
/// Kept as a standalone helper for call-sites that need only the interpolation
/// curve without constructing a generator.
pub fn fade(t: f32) -> f32 {
    t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
}

/// Generates 2D Perlin noise at the given coordinates.
pub fn perlin2d(x: f32, y: f32, seed: u32) -> f32 {
    NoiseGenerator::new(seed as u64).perlin_2d(x as f64, y as f64) as f32
}

/// Generates 3D Perlin noise at the given coordinates.
pub fn perlin3d(x: f32, y: f32, z: f32, seed: u32) -> f32 {
    NoiseGenerator::new(seed as u64).perlin_3d(x as f64, y as f64, z as f64) as f32
}

/// Generates 4D Perlin noise at the given coordinates.
pub fn perlin4d(x: f32, y: f32, z: f32, w_coord: f32, seed: u32) -> f32 {
    NoiseGenerator::new(seed as u64).perlin_4d(x as f64, y as f64, z as f64, w_coord as f64) as f32
}

/// Generates 2D Simplex noise at the given coordinates.
pub fn simplex2d(x: f32, y: f32, seed: u32) -> f32 {
    NoiseGenerator::new(seed as u64).simplex_2d(x as f64, y as f64) as f32
}

/// Returns 2D simplex noise for the given coordinates using seed 0.
pub fn simplex_noise_2d(x: f32, y: f32) -> f32 {
    simplex2d(x, y, 0)
}

/// Returns 3D simplex noise for the given coordinates using seed 0.
pub fn simplex_noise_3d(x: f32, y: f32, z: f32) -> f32 {
    NoiseGenerator::new(0).simplex_3d(x as f64, y as f64, z as f64) as f32
}

/// Generates fractal Brownian motion noise by layering multiple octaves.
///
/// `gain` is clamped to `>= 0` to keep amplitudes stable for edge cases.
pub fn fbm(x: f32, y: f32, seed: u32, octaves: u32, lacunarity: f32, gain: f32) -> f32 {
    NoiseGenerator::new(seed as u64).fbm(
        x as f64,
        y as f64,
        octaves,
        lacunarity as f64,
        gain.max(0.0) as f64,
        NoiseKind::Perlin,
    ) as f32
}
