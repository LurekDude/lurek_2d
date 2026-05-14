use super::noise_generator::{NoiseGenerator, NoiseKind};

/// Return the Ken Perlin smooth-step polynomial `6t⁵ - 15t⁴ + 10t³`.
pub fn fade(t: f32) -> f32 {
    t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
}

/// Return seeded 2-D Perlin noise in approximately `[-1, 1]`.
pub fn perlin2d(x: f32, y: f32, seed: u32) -> f32 {
    NoiseGenerator::new(seed as u64).perlin_2d(x as f64, y as f64) as f32
}

/// Return seeded 3-D Perlin noise in approximately `[-1, 1]`.
pub fn perlin3d(x: f32, y: f32, z: f32, seed: u32) -> f32 {
    NoiseGenerator::new(seed as u64).perlin_3d(x as f64, y as f64, z as f64) as f32
}

/// Return seeded 4-D Perlin noise in approximately `[-1, 1]`.
pub fn perlin4d(x: f32, y: f32, z: f32, w_coord: f32, seed: u32) -> f32 {
    NoiseGenerator::new(seed as u64).perlin_4d(x as f64, y as f64, z as f64, w_coord as f64) as f32
}

/// Return seeded 2-D Simplex noise in approximately `[-1, 1]`.
pub fn simplex2d(x: f32, y: f32, seed: u32) -> f32 {
    NoiseGenerator::new(seed as u64).simplex_2d(x as f64, y as f64) as f32
}

/// Return unseeded 2-D Simplex noise (seed 0) in approximately `[-1, 1]`.
pub fn simplex_noise_2d(x: f32, y: f32) -> f32 {
    simplex2d(x, y, 0)
}

/// Return unseeded 3-D Simplex noise (seed 0) in approximately `[-1, 1]`.
pub fn simplex_noise_3d(x: f32, y: f32, z: f32) -> f32 {
    NoiseGenerator::new(0).simplex_3d(x as f64, y as f64, z as f64) as f32
}

/// Return seeded 2-D fractional Brownian motion (fBm) summing `octaves` Perlin layers.
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
