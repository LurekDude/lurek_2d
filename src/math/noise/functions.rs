//! Standalone noise functions: Perlin, Simplex, and fractal FBM.
//!
//! All return values in approximately `[-1.0, 1.0]`. Private helpers
//! (`fade`, `lerp`, `hash*`, `grad*`, `simplex_contribution`) live below
//! the public functions.

use super::generator::NoiseGenerator;

/// Generates 2D Perlin noise at the given coordinates.
///
/// # Parameters
/// - `x` — X coordinate in noise space
/// - `y` — Y coordinate in noise space
/// - `seed` — numeric seed to vary the noise pattern
///
/// # Returns
/// A value in approximately `[-1.0, 1.0]`.
pub fn perlin2d(x: f32, y: f32, seed: u32) -> f32 {
    let xi = x.floor() as i32;
    let yi = y.floor() as i32;
    let xf = x - x.floor();
    let yf = y - y.floor();

    let u = fade(xf);
    let v = fade(yf);

    let aa = grad2d(hash2d(xi, yi, seed), xf, yf);
    let ba = grad2d(hash2d(xi + 1, yi, seed), xf - 1.0, yf);
    let ab = grad2d(hash2d(xi, yi + 1, seed), xf, yf - 1.0);
    let bb = grad2d(hash2d(xi + 1, yi + 1, seed), xf - 1.0, yf - 1.0);

    let x1 = lerp(aa, ba, u);
    let x2 = lerp(ab, bb, u);
    lerp(x1, x2, v)
}

/// Generates 2D Simplex noise at the given coordinates.
///
/// # Parameters
/// - `x` — X coordinate in noise space
/// - `y` — Y coordinate in noise space
/// - `seed` — numeric seed to vary the noise pattern
///
/// # Returns
/// A value in approximately `[-1.0, 1.0]`.
pub fn simplex2d(x: f32, y: f32, seed: u32) -> f32 {
    const F2: f32 = 0.366_025_4; // (sqrt(3) - 1) / 2
    const G2: f32 = 0.211_324_87; // (3 - sqrt(3)) / 6

    let s = (x + y) * F2;
    let i = (x + s).floor() as i32;
    let j = (y + s).floor() as i32;

    let t = (i + j) as f32 * G2;
    let x0 = x - (i as f32 - t);
    let y0 = y - (j as f32 - t);

    let (i1, j1) = if x0 > y0 { (1, 0) } else { (0, 1) };

    let x1 = x0 - i1 as f32 + G2;
    let y1 = y0 - j1 as f32 + G2;
    let x2 = x0 - 1.0 + 2.0 * G2;
    let y2 = y0 - 1.0 + 2.0 * G2;

    let n0 = simplex_contribution(hash2d(i, j, seed), x0, y0);
    let n1 = simplex_contribution(hash2d(i + i1, j + j1, seed), x1, y1);
    let n2 = simplex_contribution(hash2d(i + 1, j + 1, seed), x2, y2);

    // Scale to approximately [-1, 1]
    70.0 * (n0 + n1 + n2)
}

/// Returns 2D simplex noise for the given coordinates using seed 0.
///
/// Convenience wrapper around [`simplex2d`] with a fixed seed of `0`.
/// Use [`NoiseGenerator::simplexNoise`] for seeded output.
///
/// # Parameters
/// - `x` — X coordinate in noise space.
/// - `y` — Y coordinate in noise space.
///
/// # Returns
/// A value in approximately `[-1.0, 1.0]`.
pub fn simplex_noise_2d(x: f32, y: f32) -> f32 {
    simplex2d(x, y, 0)
}

/// Returns 3D simplex noise for the given coordinates using seed 0.
///
/// Delegates to [`NoiseGenerator::simplex_3d`] with seed `0`.
///
/// # Parameters
/// - `x` — X coordinate in noise space.
/// - `y` — Y coordinate in noise space.
/// - `z` — Z coordinate in noise space.
///
/// # Returns
/// A value in approximately `[-1.0, 1.0]`.
pub fn simplex_noise_3d(x: f32, y: f32, z: f32) -> f32 {
    NoiseGenerator::new(0).simplex_3d(x as f64, y as f64, z as f64) as f32
}

/// Generates fractal Brownian motion noise by layering multiple octaves of Perlin noise.
///
/// # Parameters
/// - `x` — X coordinate in noise space
/// - `y` — Y coordinate in noise space
/// - `seed` — numeric seed
/// - `octaves` — number of noise layers (1–8 typical)
/// - `lacunarity` — frequency multiplier per octave (typical: 2.0)
/// - `gain` — amplitude multiplier per octave (typical: 0.5)
///
/// # Returns
/// A value centred around `0.0` in approximately `[-1.0, 1.0]`.
pub fn fbm(x: f32, y: f32, seed: u32, octaves: u32, lacunarity: f32, gain: f32) -> f32 {
    let mut value = 0.0_f32;
    let mut amplitude = 1.0_f32;
    let mut frequency = 1.0_f32;
    let mut max_amplitude = 0.0_f32;

    for _ in 0..octaves {
        value += amplitude * perlin2d(x * frequency, y * frequency, seed);
        max_amplitude += amplitude;
        amplitude *= gain;
        frequency *= lacunarity;
    }

    if max_amplitude > 0.0 {
        value / max_amplitude
    } else {
        0.0
    }
}

// ── Internal helpers ───────────────────────────────────────────────────────

/// Quintic fade curve for smooth interpolation: 6t^5 - 15t^4 + 10t^3.
fn fade(t: f32) -> f32 {
    t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
}

/// Linear interpolation between `a` and `b` by factor `t`.
fn lerp(a: f32, b: f32, t: f32) -> f32 {
    a + t * (b - a)
}

/// Hash two integer coordinates and a seed into a pseudo-random byte.
fn hash2d(x: i32, y: i32, seed: u32) -> u8 {
    let mut h = seed;
    h = h.wrapping_add(x as u32).wrapping_mul(0x9E37_79B9);
    h ^= h >> 16;
    h = h.wrapping_add(y as u32).wrapping_mul(0x9E37_79B9);
    h ^= h >> 13;
    h = h.wrapping_mul(0x4586_5521);
    h ^= h >> 16;
    (h & 0xFF) as u8
}

/// Compute dot product of a pseudo-random gradient with offset vector.
fn grad2d(hash: u8, x: f32, y: f32) -> f32 {
    match hash & 3 {
        0 => x + y,
        1 => -x + y,
        2 => x - y,
        3 => -x - y,
        _ => unreachable!(),
    }
}

/// Compute the simplex contribution for one corner.
fn simplex_contribution(hash: u8, x: f32, y: f32) -> f32 {
    let t = 0.5 - x * x - y * y;
    if t < 0.0 {
        0.0
    } else {
        let t = t * t;
        t * t * grad2d(hash, x, y)
    }
}

/// Hash three integer coordinates and a seed into a pseudo-random byte.
fn hash3d(x: i32, y: i32, z: i32, seed: u32) -> u8 {
    let mut h = seed;
    h = h.wrapping_add(x as u32).wrapping_mul(0x9E37_79B9);
    h ^= h >> 16;
    h = h.wrapping_add(y as u32).wrapping_mul(0x9E37_79B9);
    h ^= h >> 13;
    h = h.wrapping_add(z as u32).wrapping_mul(0x4586_5521);
    h ^= h >> 16;
    h = h.wrapping_mul(0x9E37_79B9);
    h ^= h >> 13;
    (h & 0xFF) as u8
}

/// Hash four integer coordinates and a seed into a pseudo-random byte.
fn hash4d(x: i32, y: i32, z: i32, w: i32, seed: u32) -> u8 {
    let mut h = seed;
    h = h.wrapping_add(x as u32).wrapping_mul(0x9E37_79B9);
    h ^= h >> 16;
    h = h.wrapping_add(y as u32).wrapping_mul(0x9E37_79B9);
    h ^= h >> 13;
    h = h.wrapping_add(z as u32).wrapping_mul(0x4586_5521);
    h ^= h >> 16;
    h = h.wrapping_add(w as u32).wrapping_mul(0x9E37_79B9);
    h ^= h >> 13;
    h = h.wrapping_mul(0x4586_5521);
    h ^= h >> 16;
    (h & 0xFF) as u8
}

/// Dot product of a 3D pseudo-random gradient with offset vector.
fn grad3d(hash: u8, x: f32, y: f32, z: f32) -> f32 {
    match hash % 12 {
        0 => x + y,
        1 => -x + y,
        2 => x - y,
        3 => -x - y,
        4 => x + z,
        5 => -x + z,
        6 => x - z,
        7 => -x - z,
        8 => y + z,
        9 => -y + z,
        10 => y - z,
        11 => -y - z,
        _ => unreachable!(),
    }
}

/// Dot product of a 4D pseudo-random gradient with offset vector.
fn grad4d(hash: u8, x: f32, y: f32, z: f32, w: f32) -> f32 {
    match hash & 31 {
        0 => x + y + z,
        1 => -x + y + z,
        2 => x - y + z,
        3 => -x - y + z,
        4 => x + y - z,
        5 => -x + y - z,
        6 => x - y - z,
        7 => -x - y - z,
        8 => x + y + w,
        9 => -x + y + w,
        10 => x - y + w,
        11 => -x - y + w,
        12 => x + y - w,
        13 => -x + y - w,
        14 => x - y - w,
        15 => -x - y - w,
        16 => x + z + w,
        17 => -x + z + w,
        18 => x - z + w,
        19 => -x - z + w,
        20 => x + z - w,
        21 => -x + z - w,
        22 => x - z - w,
        23 => -x - z - w,
        24 => y + z + w,
        25 => -y + z + w,
        26 => y - z + w,
        27 => -y - z + w,
        28 => y + z - w,
        29 => -y + z - w,
        30 => y - z - w,
        31 => -y - z - w,
        _ => unreachable!(),
    }
}

/// Generates 3D Perlin noise at the given coordinates.
///
/// # Parameters
/// - `x` — X coordinate in noise space
/// - `y` — Y coordinate in noise space
/// - `z` — Z coordinate in noise space
/// - `seed` — numeric seed to vary the noise pattern
///
/// # Returns
/// A value in approximately `[-1.0, 1.0]`.
pub fn perlin3d(x: f32, y: f32, z: f32, seed: u32) -> f32 {
    let xi = x.floor() as i32;
    let yi = y.floor() as i32;
    let zi = z.floor() as i32;
    let xf = x - x.floor();
    let yf = y - y.floor();
    let zf = z - z.floor();
    let u = fade(xf);
    let v = fade(yf);
    let w = fade(zf);

    let aaa = hash3d(xi, yi, zi, seed);
    let aab = hash3d(xi, yi, zi + 1, seed);
    let aba = hash3d(xi, yi + 1, zi, seed);
    let abb = hash3d(xi, yi + 1, zi + 1, seed);
    let baa = hash3d(xi + 1, yi, zi, seed);
    let bab = hash3d(xi + 1, yi, zi + 1, seed);
    let bba = hash3d(xi + 1, yi + 1, zi, seed);
    let bbb = hash3d(xi + 1, yi + 1, zi + 1, seed);

    let x1 = lerp(grad3d(aaa, xf, yf, zf), grad3d(baa, xf - 1.0, yf, zf), u);
    let x2 = lerp(
        grad3d(aba, xf, yf - 1.0, zf),
        grad3d(bba, xf - 1.0, yf - 1.0, zf),
        u,
    );
    let y1 = lerp(x1, x2, v);
    let x3 = lerp(
        grad3d(aab, xf, yf, zf - 1.0),
        grad3d(bab, xf - 1.0, yf, zf - 1.0),
        u,
    );
    let x4 = lerp(
        grad3d(abb, xf, yf - 1.0, zf - 1.0),
        grad3d(bbb, xf - 1.0, yf - 1.0, zf - 1.0),
        u,
    );
    let y2 = lerp(x3, x4, v);
    lerp(y1, y2, w)
}

/// Generates 4D Perlin noise at the given coordinates.
///
/// # Parameters
/// - `x` — X coordinate in noise space
/// - `y` — Y coordinate in noise space
/// - `z` — Z coordinate in noise space
/// - `w_coord` — W coordinate in noise space
/// - `seed` — numeric seed to vary the noise pattern
///
/// # Returns
/// A value in approximately `[-1.0, 1.0]`.
pub fn perlin4d(x: f32, y: f32, z: f32, w_coord: f32, seed: u32) -> f32 {
    let xi = x.floor() as i32;
    let yi = y.floor() as i32;
    let zi = z.floor() as i32;
    let wi = w_coord.floor() as i32;
    let xf = x - x.floor();
    let yf = y - y.floor();
    let zf = z - z.floor();
    let wf = w_coord - w_coord.floor();
    let fu = fade(xf);
    let fv = fade(yf);
    let fw = fade(zf);
    let ft = fade(wf);

    // Interpolate along w first, then z, y, x
    let mut corners = [0.0f32; 16];
    for (idx, &(dx, dy, dz, dw)) in [
        (0, 0, 0, 0),
        (1, 0, 0, 0),
        (0, 1, 0, 0),
        (1, 1, 0, 0),
        (0, 0, 1, 0),
        (1, 0, 1, 0),
        (0, 1, 1, 0),
        (1, 1, 1, 0),
        (0, 0, 0, 1),
        (1, 0, 0, 1),
        (0, 1, 0, 1),
        (1, 1, 0, 1),
        (0, 0, 1, 1),
        (1, 0, 1, 1),
        (0, 1, 1, 1),
        (1, 1, 1, 1),
    ]
    .iter()
    .enumerate()
    {
        let h = hash4d(xi + dx, yi + dy, zi + dz, wi + dw, seed);
        corners[idx] = grad4d(
            h,
            xf - dx as f32,
            yf - dy as f32,
            zf - dz as f32,
            wf - dw as f32,
        );
    }

    // 4D linear interpolation
    let x00 = lerp(corners[0], corners[1], fu);
    let x10 = lerp(corners[2], corners[3], fu);
    let x01 = lerp(corners[4], corners[5], fu);
    let x11 = lerp(corners[6], corners[7], fu);
    let x02 = lerp(corners[8], corners[9], fu);
    let x12 = lerp(corners[10], corners[11], fu);
    let x03 = lerp(corners[12], corners[13], fu);
    let x13 = lerp(corners[14], corners[15], fu);

    let y0 = lerp(x00, x10, fv);
    let y1 = lerp(x01, x11, fv);
    let y2 = lerp(x02, x12, fv);
    let y3 = lerp(x03, x13, fv);

    let z0 = lerp(y0, y1, fw);
    let z1 = lerp(y2, y3, fw);

    lerp(z0, z1, ft)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_perlin2d_deterministic() {
        let a = perlin2d(1.5, 2.3, 42);
        let b = perlin2d(1.5, 2.3, 42);
        assert!(
            (a - b).abs() < f32::EPSILON,
            "Perlin noise not deterministic"
        );
    }

    #[test]
    fn test_perlin2d_range() {
        for i in 0..100 {
            let x = i as f32 * 0.37;
            let y = i as f32 * 0.53;
            let v = perlin2d(x, y, 0);
            assert!(
                v >= -1.5 && v <= 1.5,
                "Perlin out of range: {v} at ({x}, {y})"
            );
        }
    }

    #[test]
    fn test_perlin2d_different_seeds() {
        let a = perlin2d(1.5, 2.3, 0);
        let b = perlin2d(1.5, 2.3, 999);
        // Very unlikely to be identical with different seeds
        assert!(
            (a - b).abs() > f32::EPSILON,
            "Different seeds should produce different noise"
        );
    }

    #[test]
    fn test_simplex2d_deterministic() {
        let a = simplex2d(1.5, 2.3, 42);
        let b = simplex2d(1.5, 2.3, 42);
        assert!(
            (a - b).abs() < f32::EPSILON,
            "Simplex noise not deterministic"
        );
    }

    #[test]
    fn test_simplex2d_range() {
        for i in 0..100 {
            let x = i as f32 * 0.37;
            let y = i as f32 * 0.53;
            let v = simplex2d(x, y, 0);
            assert!(
                v >= -1.5 && v <= 1.5,
                "Simplex out of range: {v} at ({x}, {y})"
            );
        }
    }

    #[test]
    fn test_fbm_deterministic() {
        let a = fbm(1.0, 2.0, 42, 4, 2.0, 0.5);
        let b = fbm(1.0, 2.0, 42, 4, 2.0, 0.5);
        assert!((a - b).abs() < f32::EPSILON);
    }

    #[test]
    fn test_fbm_single_octave_equals_perlin() {
        let a = fbm(1.5, 2.3, 42, 1, 2.0, 0.5);
        let b = perlin2d(1.5, 2.3, 42);
        assert!((a - b).abs() < 1e-5);
    }

    #[test]
    fn test_fade_boundaries() {
        assert!((fade(0.0)).abs() < f32::EPSILON);
        assert!((fade(1.0) - 1.0).abs() < f32::EPSILON);
    }
}
