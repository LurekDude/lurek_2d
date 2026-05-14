//! Noise primitives and map generation for `src/procgen`.
//! Owns Perlin 1-4D, Simplex 2-4D, Worley/cellular, FBM, ridged, and turbulence
//! fractals via `NoiseGenerator`, plus standalone free functions and `MapGenOptions`.
//! Does not own biome classification or heightmap erosion — those live in `biome.rs`
//! and `heightmap.rs`. Depends on `rayon` for parallel map generation.

use rayon::prelude::*;

/// Distance metric used by Worley/cellular noise to measure feature-point distance.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DistType {
    /// Straight-line distance: `sqrt(dx² + dy²)`.
    Euclidean,
    /// City-block distance: `|dx| + |dy|`.
    Manhattan,
    /// Maximum-axis distance: `max(|dx|, |dy|)`.
    Chebyshev,
}

/// Base noise algorithm used when building fractal maps.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum NoiseKind {
    /// Classic gradient Perlin noise.
    Perlin,
    /// Simplex noise; fewer directional artefacts than Perlin.
    Simplex,
}

/// Fractal layering strategy applied when generating a `MapGenOptions` map.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FractalType {
    /// Fractional Brownian motion — sums octaves with decreasing amplitude.
    Fbm,
    /// Ridged multifractal — inverts octave values to produce ridges.
    Ridged,
    /// Turbulence — sums absolute octave values.
    Turbulence,
}

/// Parameters for `NoiseGenerator::generate_map` and `generate_map_parallel`.
#[derive(Debug, Clone)]
pub struct MapGenOptions {
    /// Frequency scale applied to the X axis; smaller = lower frequency.
    pub scale_x: f64,
    /// Frequency scale applied to the Y axis; smaller = lower frequency.
    pub scale_y: f64,
    /// Number of octaves summed in the fractal stack.
    pub octaves: u32,
    /// Frequency multiplier per octave (typically 2.0).
    pub lacunarity: f64,
    /// Amplitude multiplier per octave; controls contribution decay.
    pub persistence: f64,
    /// Base noise algorithm for each octave sample.
    pub kind: NoiseKind,
    /// Fractal combination strategy applied across octaves.
    pub fractal: FractalType,
    /// X offset added to each sample coordinate before scaling.
    pub offset_x: f64,
    /// Y offset added to each sample coordinate before scaling.
    pub offset_y: f64,
}

/// Provide sane defaults: scale 1.0, 4 octaves FBM Perlin, no offset.
impl Default for MapGenOptions {
    fn default() -> Self {
        Self {
            scale_x: 1.0,
            scale_y: 1.0,
            octaves: 4,
            lacunarity: 2.0,
            persistence: 0.5,
            kind: NoiseKind::Perlin,
            fractal: FractalType::Fbm,
            offset_x: 0.0,
            offset_y: 0.0,
        }
    }
}
    Euclidean,
    Manhattan,
    Chebyshev,
}
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum NoiseKind {
    Perlin,
    Simplex,
}
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FractalType {
    Fbm,
    Ridged,
    Turbulence,
}
#[derive(Debug, Clone)]
pub struct MapGenOptions {
    pub scale_x: f64,
    pub scale_y: f64,
    pub octaves: u32,
    pub lacunarity: f64,
    pub persistence: f64,
    pub kind: NoiseKind,
    pub fractal: FractalType,
    pub offset_x: f64,
    pub offset_y: f64,
}
impl Default for MapGenOptions {
    fn default() -> Self {
        Self {
            scale_x: 1.0,
            scale_y: 1.0,
            octaves: 4,
            lacunarity: 2.0,
            persistence: 0.5,
            kind: NoiseKind::Perlin,
            fractal: FractalType::Fbm,
            offset_x: 0.0,
            offset_y: 0.0,
        }
    }
}
/// Evaluate 2D Perlin noise at `(x, y)` with the given `seed`; returns a value roughly in -1.0..1.0.
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
    let x1 = lerp_f32(aa, ba, u);
    let x2 = lerp_f32(ab, bb, u);
    lerp_f32(x1, x2, v)
}
/// Evaluate 2D simplex noise at `(x, y)` with the given `seed`; scaled to approximately -1.0..1.0.
pub fn simplex2d(x: f32, y: f32, seed: u32) -> f32 {
    const F2: f32 = 0.366_025_4;
    const G2: f32 = 0.211_324_87;
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
    70.0 * (n0 + n1 + n2)
}
/// Evaluate 2D simplex noise at `(x, y)` with seed 0; convenience wrapper around `simplex2d`.
pub fn simplex_noise_2d(x: f32, y: f32) -> f32 {
    simplex2d(x, y, 0)
}
/// Evaluate 3D simplex noise at `(x, y, z)` with seed 0 via `NoiseGenerator`; returns f32.
pub fn simplex_noise_3d(x: f32, y: f32, z: f32) -> f32 {
    NoiseGenerator::new(0).simplex_3d(x as f64, y as f64, z as f64) as f32
}
/// Evaluate FBM over 2D Perlin noise; sums `octaves` layers and returns the normalised result.
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
/// Evaluate 3D Perlin noise at `(x, y, z)` with the given `seed`; returns a value roughly in -1.0..1.0.
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
    let x1 = lerp_f32(grad3d(aaa, xf, yf, zf), grad3d(baa, xf - 1.0, yf, zf), u);
    let x2 = lerp_f32(
        grad3d(aba, xf, yf - 1.0, zf),
        grad3d(bba, xf - 1.0, yf - 1.0, zf),
        u,
    );
    let y1 = lerp_f32(x1, x2, v);
    let x3 = lerp_f32(
        grad3d(aab, xf, yf, zf - 1.0),
        grad3d(bab, xf - 1.0, yf, zf - 1.0),
        u,
    );
    let x4 = lerp_f32(
        grad3d(abb, xf, yf - 1.0, zf - 1.0),
        grad3d(bbb, xf - 1.0, yf - 1.0, zf - 1.0),
        u,
    );
    let y2 = lerp_f32(x3, x4, v);
    lerp_f32(y1, y2, w)
}
/// Evaluate 4D Perlin noise at `(x, y, z, w)` with the given `seed`; returns a value roughly in -1.0..1.0.
pub fn perlin4d(x: f32, y: f32, z: f32, w: f32, seed: u32) -> f32 {
    let xi = x.floor() as i32;
    let yi = y.floor() as i32;
    let zi = z.floor() as i32;
    let wi = w.floor() as i32;
    let xf = x - x.floor();
    let yf = y - y.floor();
    let zf = z - z.floor();
    let wf = w - w.floor();
    let fu = fade(xf);
    let fv = fade(yf);
    let fw = fade(zf);
    let ft = fade(wf);
    let offsets: [(i32, i32, i32, i32); 16] = [
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
    ];
    let mut corners = [0.0f32; 16];
    for (idx, &(dx, dy, dz, dw)) in offsets.iter().enumerate() {
        let h = hash4d(xi + dx, yi + dy, zi + dz, wi + dw, seed);
        corners[idx] = grad4d(
            h,
            xf - dx as f32,
            yf - dy as f32,
            zf - dz as f32,
            wf - dw as f32,
        );
    }
    let x00 = lerp_f32(corners[0], corners[1], fu);
    let x10 = lerp_f32(corners[2], corners[3], fu);
    let x01 = lerp_f32(corners[4], corners[5], fu);
    let x11 = lerp_f32(corners[6], corners[7], fu);
    let x02 = lerp_f32(corners[8], corners[9], fu);
    let x12 = lerp_f32(corners[10], corners[11], fu);
    let x03 = lerp_f32(corners[12], corners[13], fu);
    let x13 = lerp_f32(corners[14], corners[15], fu);
    let y0 = lerp_f32(x00, x10, fv);
    let y1 = lerp_f32(x01, x11, fv);
    let y2 = lerp_f32(x02, x12, fv);
    let y3 = lerp_f32(x03, x13, fv);
    let z0 = lerp_f32(y0, y1, fw);
    let z1 = lerp_f32(y2, y3, fw);
    lerp_f32(z0, z1, ft)
}
/// Generate a `w × h` noise map in parallel using a default-seed `NoiseGenerator` and `opts`.
pub fn generate_noise_map_parallel(w: u32, h: u32, opts: &MapGenOptions) -> Vec<f64> {
    NoiseGenerator::new(0).generate_map_parallel(w, h, opts)
}
/// Smoothstep quintic fade curve: `6t⁵ − 15t⁴ + 10t³`.
fn fade(t: f32) -> f32 {
    t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
}
/// Linear interpolate between `a` and `b` by factor `t`.
fn lerp_f32(a: f32, b: f32, t: f32) -> f32 {
    a + t * (b - a)
}
/// Hash two integers and a seed to a `u8` gradient selector using multiply-xorshift mixing.
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
/// Map `hash` low bits to one of four 2D gradient vectors dotted with `(x, y)`.
fn grad2d(hash: u8, x: f32, y: f32) -> f32 {
    match hash & 3 {
        0 => x + y,
        1 => -x + y,
        2 => x - y,
        3 => -x - y,
        _ => unreachable!(),
    }
}
/// Compute the simplex kernel contribution at `(x, y)` using `hash`; returns 0 when outside the kernel radius.
fn simplex_contribution(hash: u8, x: f32, y: f32) -> f32 {
    let t = 0.5 - x * x - y * y;
    if t < 0.0 {
        0.0
    } else {
        let t = t * t;
        t * t * grad2d(hash, x, y)
    }
}
/// Hash three integers and a seed to a `u8` gradient selector using chained multiply-xorshift mixing.
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
/// Map `hash` low bits to one of twelve 3D gradient vectors dotted with `(x, y, z)`.
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
/// Hash four integers and a seed to a `u8` gradient selector for 4D Perlin noise.
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
/// Map `hash` low 5 bits to one of 32 4D gradient vectors dotted with `(x, y, z, w)`.
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
/// Seeded permutation-table noise generator providing Perlin, Simplex, Worley, and fractal methods.
pub struct NoiseGenerator {
    /// Current seed; rebuilt into `perm` by `set_seed` and `build_perm`.
    seed: u64,
    /// 512-entry permutation table (0..255 repeated) shuffled from `seed`.
    perm: [u8; 512],
}

impl NoiseGenerator {
    /// Create a generator seeded with `seed` and build the permutation table.
    pub fn new(seed: u64) -> Self {
        let mut gen = Self {
            seed,
            perm: [0; 512],
        };
        gen.build_perm();
        gen
    }
    /// Replace the current seed and rebuild the permutation table.
    pub fn set_seed(&mut self, seed: u64) {
        self.seed = seed;
        self.build_perm();
    }
    /// Return the current seed value.
    pub fn seed(&self) -> u64 {
        self.seed
    }
    /// Fisher-Yates shuffle of 0..255 driven by an inline LCG to populate `perm[0..512]`.
    fn build_perm(&mut self) {
        let mut table: Vec<u8> = (0..=255).collect();
        let mut lcg = self.seed;
        for i in (1..256).rev() {
            lcg = lcg.wrapping_mul(6_364_136_223_846_793_005).wrapping_add(1);
            let j = (lcg >> 33) as usize % (i + 1);
            table.swap(i, j);
        }
        self.perm[..256].copy_from_slice(&table);
        self.perm[256..].copy_from_slice(&table);
    }
    /// Return `perm[(idx & 255) as usize]`; wraps negative indices safely via masking.
    #[inline]
    fn p(&self, idx: i32) -> u8 {
        self.perm[(idx & 255) as usize]
    }
    /// Quintic smoothstep fade curve used in Perlin and FBM calculations.
    #[inline]
    fn fade(t: f64) -> f64 {
        t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
    }
    /// Linear interpolate between `a` and `b` by factor `t`.
    #[inline]
    fn lerp(a: f64, b: f64, t: f64) -> f64 {
        a + t * (b - a)
    }
    /// Map `hash` bit 0 to a 1D gradient dotted with `x`.
    #[inline]
    fn grad1(hash: u8, x: f64) -> f64 {
        if hash & 1 == 0 {
            x
        } else {
            -x
        }
    }
    /// Map `hash` low 2 bits to one of four 2D gradient vectors dotted with `(x, y)`.
    #[inline]
    fn grad2(hash: u8, x: f64, y: f64) -> f64 {
        match hash & 3 {
            0 => x + y,
            1 => -x + y,
            2 => x - y,
            _ => -x - y,
        }
    }
    /// Map `hash % 12` to one of twelve 3D gradient vectors dotted with `(x, y, z)`.
    #[inline]
    fn grad3(hash: u8, x: f64, y: f64, z: f64) -> f64 {
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
            _ => -y - z,
        }
    }
    /// Map `hash & 31` to one of 32 4D gradient vectors dotted with `(x, y, z, w)`.
    #[inline]
    fn grad4(hash: u8, x: f64, y: f64, z: f64, w: f64) -> f64 {
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
            _ => -y - z - w,
        }
    }
    /// Hash a 2D cell coordinate and `component` index to a reproducible [0, 1) float.
    fn cell_hash(&self, ix: i32, iy: i32, component: u32) -> f64 {
        let mut h = self.seed.wrapping_add(component as u64);
        h = h
            .wrapping_add(ix as u64)
            .wrapping_mul(6_364_136_223_846_793_005);
        h ^= h >> 33;
        h = h
            .wrapping_add(iy as u64)
            .wrapping_mul(6_364_136_223_846_793_005);
        h ^= h >> 33;
        h = h.wrapping_mul(0x4586_5521_0000_0001);
        h ^= h >> 33;
        (h & 0x00FF_FFFF_FFFF_FFFF) as f64 / (0x0100_0000_0000_0000u64 as f64)
    }
    /// Hash a 3D cell coordinate and `component` index to a reproducible [0, 1) float.
    fn cell_hash_3d(&self, ix: i32, iy: i32, iz: i32, component: u32) -> f64 {
        let mut h = self.seed.wrapping_add(component as u64);
        h = h
            .wrapping_add(ix as u64)
            .wrapping_mul(6_364_136_223_846_793_005);
        h ^= h >> 33;
        h = h
            .wrapping_add(iy as u64)
            .wrapping_mul(6_364_136_223_846_793_005);
        h ^= h >> 33;
        h = h
            .wrapping_add(iz as u64)
            .wrapping_mul(0x4586_5521_0000_0001);
        h ^= h >> 33;
        h = h.wrapping_mul(6_364_136_223_846_793_005);
        h ^= h >> 33;
        (h & 0x00FF_FFFF_FFFF_FFFF) as f64 / (0x0100_0000_0000_0000u64 as f64)
    }
    /// Evaluate 1D Perlin noise at `x`; returns a value roughly in -1.0..1.0.
    pub fn perlin_1d(&self, x: f64) -> f64 {
        let xi = x.floor() as i32;
        let xf = x - x.floor();
        let u = Self::fade(xf);
        let a = self.p(xi);
        let b = self.p(xi + 1);
        Self::lerp(Self::grad1(a, xf), Self::grad1(b, xf - 1.0), u)
    }
    /// Evaluate 2D Perlin noise at `(x, y)`; returns a value roughly in -1.0..1.0.
    pub fn perlin_2d(&self, x: f64, y: f64) -> f64 {
        let xi = x.floor() as i32;
        let yi = y.floor() as i32;
        let xf = x - x.floor();
        let yf = y - y.floor();
        let u = Self::fade(xf);
        let v = Self::fade(yf);
        let aa = self.p(self.p(xi) as i32 + yi);
        let ab = self.p(self.p(xi) as i32 + yi + 1);
        let ba = self.p(self.p(xi + 1) as i32 + yi);
        let bb = self.p(self.p(xi + 1) as i32 + yi + 1);
        let x1 = Self::lerp(Self::grad2(aa, xf, yf), Self::grad2(ba, xf - 1.0, yf), u);
        let x2 = Self::lerp(
            Self::grad2(ab, xf, yf - 1.0),
            Self::grad2(bb, xf - 1.0, yf - 1.0),
            u,
        );
        Self::lerp(x1, x2, v)
    }
    /// Evaluate 3D Perlin noise at `(x, y, z)`; returns a value roughly in -1.0..1.0.
    pub fn perlin_3d(&self, x: f64, y: f64, z: f64) -> f64 {
        let xi = x.floor() as i32;
        let yi = y.floor() as i32;
        let zi = z.floor() as i32;
        let xf = x - x.floor();
        let yf = y - y.floor();
        let zf = z - z.floor();
        let u = Self::fade(xf);
        let v = Self::fade(yf);
        let w = Self::fade(zf);
        let aaa = self.p(self.p(self.p(xi) as i32 + yi) as i32 + zi);
        let aab = self.p(self.p(self.p(xi) as i32 + yi) as i32 + zi + 1);
        let aba = self.p(self.p(self.p(xi) as i32 + yi + 1) as i32 + zi);
        let abb = self.p(self.p(self.p(xi) as i32 + yi + 1) as i32 + zi + 1);
        let baa = self.p(self.p(self.p(xi + 1) as i32 + yi) as i32 + zi);
        let bab = self.p(self.p(self.p(xi + 1) as i32 + yi) as i32 + zi + 1);
        let bba = self.p(self.p(self.p(xi + 1) as i32 + yi + 1) as i32 + zi);
        let bbb = self.p(self.p(self.p(xi + 1) as i32 + yi + 1) as i32 + zi + 1);
        let x1 = Self::lerp(
            Self::grad3(aaa, xf, yf, zf),
            Self::grad3(baa, xf - 1.0, yf, zf),
            u,
        );
        let x2 = Self::lerp(
            Self::grad3(aba, xf, yf - 1.0, zf),
            Self::grad3(bba, xf - 1.0, yf - 1.0, zf),
            u,
        );
        let y1 = Self::lerp(x1, x2, v);
        let x3 = Self::lerp(
            Self::grad3(aab, xf, yf, zf - 1.0),
            Self::grad3(bab, xf - 1.0, yf, zf - 1.0),
            u,
        );
        let x4 = Self::lerp(
            Self::grad3(abb, xf, yf - 1.0, zf - 1.0),
            Self::grad3(bbb, xf - 1.0, yf - 1.0, zf - 1.0),
            u,
        );
        let y2 = Self::lerp(x3, x4, v);
        Self::lerp(y1, y2, w)
    }
    /// Evaluate 2D simplex noise at `(x, y)`; scaled to approximately -1.0..1.0.
    pub fn simplex_2d(&self, x: f64, y: f64) -> f64 {
        const F2: f64 = 0.366_025_403_784_438_6;
        const G2: f64 = 0.211_324_865_405_187_1;
        let s = (x + y) * F2;
        let i = (x + s).floor() as i32;
        let j = (y + s).floor() as i32;
        let t = (i + j) as f64 * G2;
        let x0 = x - (i as f64 - t);
        let y0 = y - (j as f64 - t);
        let (i1, j1) = if x0 > y0 { (1, 0) } else { (0, 1) };
        let x1 = x0 - i1 as f64 + G2;
        let y1 = y0 - j1 as f64 + G2;
        let x2 = x0 - 1.0 + 2.0 * G2;
        let y2 = y0 - 1.0 + 2.0 * G2;
        let gi0 = self.p(self.p(i) as i32 + j);
        let gi1 = self.p(self.p(i + i1) as i32 + j + j1);
        let gi2 = self.p(self.p(i + 1) as i32 + j + 1);
        let contrib = |gi: u8, cx: f64, cy: f64| -> f64 {
            let t = 0.5 - cx * cx - cy * cy;
            if t < 0.0 {
                0.0
            } else {
                t * t * t * t * Self::grad2(gi, cx, cy)
            }
        };
        70.0 * (contrib(gi0, x0, y0) + contrib(gi1, x1, y1) + contrib(gi2, x2, y2))
    }
    /// Evaluate 3D simplex noise at `(x, y, z)`; scaled to approximately -1.0..1.0.
    pub fn simplex_3d(&self, x: f64, y: f64, z: f64) -> f64 {
        const F3: f64 = 1.0 / 3.0;
        const G3: f64 = 1.0 / 6.0;
        let s = (x + y + z) * F3;
        let i = (x + s).floor() as i32;
        let j = (y + s).floor() as i32;
        let k = (z + s).floor() as i32;
        let t = (i + j + k) as f64 * G3;
        let x0 = x - (i as f64 - t);
        let y0 = y - (j as f64 - t);
        let z0 = z - (k as f64 - t);
        let (i1, j1, k1, i2, j2, k2) = if x0 >= y0 {
            if y0 >= z0 {
                (1, 0, 0, 1, 1, 0)
            } else if x0 >= z0 {
                (1, 0, 0, 1, 0, 1)
            } else {
                (0, 0, 1, 1, 0, 1)
            }
        } else {
            if y0 < z0 {
                (0, 0, 1, 0, 1, 1)
            } else if x0 < z0 {
                (0, 1, 0, 0, 1, 1)
            } else {
                (0, 1, 0, 1, 1, 0)
            }
        };
        let x1 = x0 - i1 as f64 + G3;
        let y1 = y0 - j1 as f64 + G3;
        let z1 = z0 - k1 as f64 + G3;
        let x2 = x0 - i2 as f64 + 2.0 * G3;
        let y2 = y0 - j2 as f64 + 2.0 * G3;
        let z2 = z0 - k2 as f64 + 2.0 * G3;
        let x3 = x0 - 1.0 + 3.0 * G3;
        let y3 = y0 - 1.0 + 3.0 * G3;
        let z3 = z0 - 1.0 + 3.0 * G3;
        let gi0 = self.p(self.p(self.p(i) as i32 + j) as i32 + k);
        let gi1 = self.p(self.p(self.p(i + i1) as i32 + j + j1) as i32 + k + k1);
        let gi2 = self.p(self.p(self.p(i + i2) as i32 + j + j2) as i32 + k + k2);
        let gi3 = self.p(self.p(self.p(i + 1) as i32 + j + 1) as i32 + k + 1);
        let contrib = |gi: u8, cx: f64, cy: f64, cz: f64| -> f64 {
            let t = 0.6 - cx * cx - cy * cy - cz * cz;
            if t < 0.0 {
                0.0
            } else {
                t * t * t * t * Self::grad3(gi, cx, cy, cz)
            }
        };
        32.0 * (contrib(gi0, x0, y0, z0)
            + contrib(gi1, x1, y1, z1)
            + contrib(gi2, x2, y2, z2)
            + contrib(gi3, x3, y3, z3))
    }
    /// Evaluate 4D simplex noise at `(x, y, z, w)`; scaled to approximately -1.0..1.0.
    pub fn simplex_4d(&self, x: f64, y: f64, z: f64, w: f64) -> f64 {
        const F4: f64 = 0.309_016_994_374_947;
        const G4: f64 = 0.138_196_601_125_011;
        let s = (x + y + z + w) * F4;
        let i = (x + s).floor() as i32;
        let j = (y + s).floor() as i32;
        let k = (z + s).floor() as i32;
        let l = (w + s).floor() as i32;
        let t = (i + j + k + l) as f64 * G4;
        let x0 = x - (i as f64 - t);
        let y0 = y - (j as f64 - t);
        let z0 = z - (k as f64 - t);
        let w0 = w - (l as f64 - t);
        let rank_x = (if x0 > y0 { 1 } else { 0 })
            + (if x0 > z0 { 1 } else { 0 })
            + (if x0 > w0 { 1 } else { 0 });
        let rank_y = (if y0 >= x0 { 1 } else { 0 })
            + (if y0 > z0 { 1 } else { 0 })
            + (if y0 > w0 { 1 } else { 0 });
        let rank_z = (if z0 >= x0 { 1 } else { 0 })
            + (if z0 >= y0 { 1 } else { 0 })
            + (if z0 > w0 { 1 } else { 0 });
        let rank_w = (if w0 >= x0 { 1 } else { 0 })
            + (if w0 >= y0 { 1 } else { 0 })
            + (if w0 >= z0 { 1 } else { 0 });
        let i1 = if rank_x >= 3 { 1 } else { 0 };
        let j1 = if rank_y >= 3 { 1 } else { 0 };
        let k1 = if rank_z >= 3 { 1 } else { 0 };
        let l1 = if rank_w >= 3 { 1 } else { 0 };
        let i2 = if rank_x >= 2 { 1 } else { 0 };
        let j2 = if rank_y >= 2 { 1 } else { 0 };
        let k2 = if rank_z >= 2 { 1 } else { 0 };
        let l2 = if rank_w >= 2 { 1 } else { 0 };
        let i3 = if rank_x >= 1 { 1 } else { 0 };
        let j3 = if rank_y >= 1 { 1 } else { 0 };
        let k3 = if rank_z >= 1 { 1 } else { 0 };
        let l3 = if rank_w >= 1 { 1 } else { 0 };
        let offsets = [
            (0, 0, 0, 0),
            (i1, j1, k1, l1),
            (i2, j2, k2, l2),
            (i3, j3, k3, l3),
            (1, 1, 1, 1),
        ];
        let g_factors = [0.0, G4, 2.0 * G4, 3.0 * G4, 4.0 * G4];
        let mut n = 0.0f64;
        for (idx, &(oi, oj, ok, ol)) in offsets.iter().enumerate() {
            let cx = x0 - oi as f64 + g_factors[idx];
            let cy = y0 - oj as f64 + g_factors[idx];
            let cz = z0 - ok as f64 + g_factors[idx];
            let cw = w0 - ol as f64 + g_factors[idx];
            let t2 = 0.6 - cx * cx - cy * cy - cz * cz - cw * cw;
            if t2 >= 0.0 {
                let gi = self.p(
                    self.p(self.p(self.p(i + oi) as i32 + j + oj) as i32 + k + ok) as i32 + l + ol,
                );
                n += t2 * t2 * t2 * t2 * Self::grad4(gi, cx, cy, cz, cw);
            }
        }
        27.0 * n
    }
    /// Evaluate 2D Worley noise; returns F1 distance when `f2=false`, F2−F1 when `f2=true`.
    pub fn worley_2d(&self, x: f64, y: f64, dist: DistType, f2: bool) -> f64 {
        let ix = x.floor() as i32;
        let iy = y.floor() as i32;
        let mut min1 = f64::MAX;
        let mut min2 = f64::MAX;
        for dy in -1..=1 {
            for dx in -1..=1 {
                let cx = ix + dx;
                let cy = iy + dy;
                let px = cx as f64 + self.cell_hash(cx, cy, 0);
                let py = cy as f64 + self.cell_hash(cx, cy, 1);
                let d = match dist {
                    DistType::Euclidean => ((x - px).powi(2) + (y - py).powi(2)).sqrt(),
                    DistType::Manhattan => (x - px).abs() + (y - py).abs(),
                    DistType::Chebyshev => (x - px).abs().max((y - py).abs()),
                };
                if d < min1 {
                    min2 = min1;
                    min1 = d;
                } else if d < min2 {
                    min2 = d;
                }
            }
        }
        if f2 {
            min2 - min1
        } else {
            min1
        }
    }
    /// Evaluate 3D Worley noise; returns F1 distance when `f2=false`, F2−F1 when `f2=true`.
    pub fn worley_3d(&self, x: f64, y: f64, z: f64, dist: DistType, f2: bool) -> f64 {
        let ix = x.floor() as i32;
        let iy = y.floor() as i32;
        let iz = z.floor() as i32;
        let mut min1 = f64::MAX;
        let mut min2 = f64::MAX;
        for dz in -1..=1 {
            for dy in -1..=1 {
                for dx in -1..=1 {
                    let cx = ix + dx;
                    let cy = iy + dy;
                    let cz = iz + dz;
                    let px = cx as f64 + self.cell_hash_3d(cx, cy, cz, 0);
                    let py = cy as f64 + self.cell_hash_3d(cx, cy, cz, 1);
                    let pz = cz as f64 + self.cell_hash_3d(cx, cy, cz, 2);
                    let d = match dist {
                        DistType::Euclidean => {
                            ((x - px).powi(2) + (y - py).powi(2) + (z - pz).powi(2)).sqrt()
                        }
                        DistType::Manhattan => (x - px).abs() + (y - py).abs() + (z - pz).abs(),
                        DistType::Chebyshev => {
                            (x - px).abs().max((y - py).abs()).max((z - pz).abs())
                        }
                    };
                    if d < min1 {
                        min2 = min1;
                        min1 = d;
                    } else if d < min2 {
                        min2 = d;
                    }
                }
            }
        }
        if f2 {
            min2 - min1
        } else {
            min1
        }
    }
    /// Sample a single 2D noise value using the configured `kind` (Perlin or Simplex).
    fn sample_2d(&self, x: f64, y: f64, kind: NoiseKind) -> f64 {
        match kind {
            NoiseKind::Perlin => self.perlin_2d(x, y),
            NoiseKind::Simplex => self.simplex_2d(x, y),
        }
    }
    /// Evaluate FBM fractal at `(x, y)` using `kind` noise; sums `octaves` normalised octaves.
    pub fn fbm(&self, x: f64, y: f64, octaves: u32, lac: f64, pers: f64, kind: NoiseKind) -> f64 {
        let mut total = 0.0;
        let mut amplitude = 1.0;
        let mut frequency = 1.0;
        let mut max_amp = 0.0;
        for _ in 0..octaves {
            total += amplitude * self.sample_2d(x * frequency, y * frequency, kind);
            max_amp += amplitude;
            frequency *= lac;
            amplitude *= pers;
        }
        if max_amp > 0.0 {
            total / max_amp
        } else {
            0.0
        }
    }
    /// Evaluate ridged multifractal at `(x, y)` using `kind` noise; inverts octaves to produce ridges.
    pub fn ridged(
        &self,
        x: f64,
        y: f64,
        octaves: u32,
        lac: f64,
        pers: f64,
        kind: NoiseKind,
    ) -> f64 {
        let mut total = 0.0;
        let mut amplitude = 1.0;
        let mut frequency = 1.0;
        let mut max_amp = 0.0;
        for _ in 0..octaves {
            let n = self.sample_2d(x * frequency, y * frequency, kind);
            total += amplitude * (1.0 - n.abs());
            max_amp += amplitude;
            frequency *= lac;
            amplitude *= pers;
        }
        if max_amp > 0.0 {
            total / max_amp
        } else {
            0.0
        }
    }
    /// Evaluate turbulence fractal at `(x, y)` using `kind` noise; sums absolute octave values.
    pub fn turbulence(
        &self,
        x: f64,
        y: f64,
        octaves: u32,
        lac: f64,
        pers: f64,
        kind: NoiseKind,
    ) -> f64 {
        let mut total = 0.0;
        let mut amplitude = 1.0;
        let mut frequency = 1.0;
        let mut max_amp = 0.0;
        for _ in 0..octaves {
            let n = self.sample_2d(x * frequency, y * frequency, kind);
            total += amplitude * n.abs();
            max_amp += amplitude;
            frequency *= lac;
            amplitude *= pers;
        }
        if max_amp > 0.0 {
            total / max_amp
        } else {
            0.0
        }
    }
    /// Apply domain-warp to `(x, y)` using `perlin_2d` offsets scaled by `strength`; returns warped coordinates.
    pub fn warp_domain(&self, x: f64, y: f64, strength: f64) -> (f64, f64) {
        let wx = x + strength * self.perlin_2d(x + 5.2, y + 1.3);
        let wy = y + strength * self.perlin_2d(x + 9.7, y + 8.1);
        (wx, wy)
    }
    /// Generate a flat `width × height` noise map sequentially using `opts`; returns values in approximately -1.0..1.0.
    pub fn generate_map(&self, width: u32, height: u32, opts: &MapGenOptions) -> Vec<f64> {
        let len = (width as usize) * (height as usize);
        let mut map = Vec::with_capacity(len);
        for iy in 0..height {
            for ix in 0..width {
                let nx = (ix as f64 + opts.offset_x) * opts.scale_x;
                let ny = (iy as f64 + opts.offset_y) * opts.scale_y;
                let val = match opts.fractal {
                    FractalType::Fbm => self.fbm(
                        nx,
                        ny,
                        opts.octaves,
                        opts.lacunarity,
                        opts.persistence,
                        opts.kind,
                    ),
                    FractalType::Ridged => self.ridged(
                        nx,
                        ny,
                        opts.octaves,
                        opts.lacunarity,
                        opts.persistence,
                        opts.kind,
                    ),
                    FractalType::Turbulence => self.turbulence(
                        nx,
                        ny,
                        opts.octaves,
                        opts.lacunarity,
                        opts.persistence,
                        opts.kind,
                    ),
                };
                map.push(val);
            }
        }
        map
    }
    /// Generate a flat `width × height` noise map using rayon parallel iteration; faster than `generate_map` for large grids.
    pub fn generate_map_parallel(&self, width: u32, height: u32, opts: &MapGenOptions) -> Vec<f64> {
        let len = (width as usize) * (height as usize);
        let scale_x = opts.scale_x;
        let scale_y = opts.scale_y;
        let offset_x = opts.offset_x;
        let offset_y = opts.offset_y;
        let octaves = opts.octaves;
        let lacunarity = opts.lacunarity;
        let persistence = opts.persistence;
        let kind = opts.kind;
        let fractal = opts.fractal;
        (0..len)
            .into_par_iter()
            .map(|idx| {
                let ix = (idx % width as usize) as u32;
                let iy = (idx / width as usize) as u32;
                let nx = (ix as f64 + offset_x) * scale_x;
                let ny = (iy as f64 + offset_y) * scale_y;
                match fractal {
                    FractalType::Fbm => self.fbm(nx, ny, octaves, lacunarity, persistence, kind),
                    FractalType::Ridged => {
                        self.ridged(nx, ny, octaves, lacunarity, persistence, kind)
                    }
                    FractalType::Turbulence => {
                        self.turbulence(nx, ny, octaves, lacunarity, persistence, kind)
                    }
                }
            })
            .collect()
    }
}
/// Evaluate tileable 2D Perlin noise at `(x, y)` with periods `(px, py)`; useful for seamless textures.
pub fn perlin_noise_periodic(x: f64, y: f64, px: f64, py: f64) -> f64 {
    let px = px.max(1.0) as i64;
    let py = py.max(1.0) as i64;
    let xi = x.floor() as i64;
    let yi = y.floor() as i64;
    let xf = x - x.floor();
    let yf = y - y.floor();
    let fade = |t: f64| t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    let u = fade(xf);
    let v = fade(yf);
    let wrap_x = |i: i64| ((i % px) + px) % px;
    let wrap_y = |i: i64| ((i % py) + py) % py;
    let grad = |hash: i64, gx: f64, gy: f64| -> f64 {
        match hash & 3 {
            0 => gx + gy,
            1 => -gx + gy,
            2 => gx - gy,
            3 => -gx - gy,
            _ => 0.0,
        }
    };
    let perm_hash = |ix: i64, iy: i64| -> i64 {
        let h = (wrap_x(ix).wrapping_mul(374761393) as u64)
            .wrapping_add(wrap_y(iy).wrapping_mul(668265263) as u64);
        let h = h.wrapping_mul(h).wrapping_mul(h).wrapping_mul(60493);
        (h >> 13) as i64
    };
    let n00 = grad(perm_hash(xi, yi), xf, yf);
    let n10 = grad(perm_hash(xi + 1, yi), xf - 1.0, yf);
    let n01 = grad(perm_hash(xi, yi + 1), xf, yf - 1.0);
    let n11 = grad(perm_hash(xi + 1, yi + 1), xf - 1.0, yf - 1.0);
    let lerp = |t: f64, a: f64, b: f64| a + t * (b - a);
    let x1 = lerp(u, n00, n10);
    let x2 = lerp(u, n01, n11);
    lerp(v, x1, x2)
}
