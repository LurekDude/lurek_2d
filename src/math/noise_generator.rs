//! Seeded procedural noise generator with multiple noise algorithms.
//!
//! Wraps a permutation table built from a seed, providing Perlin, Simplex,
//! and Worley noise in 1D–4D, plus fractal combinators (FBM, ridged,
//! turbulence), domain warping, and full 2D map generation.

/// Distance metric for Worley noise.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DistType {
    /// Standard Euclidean distance.
    Euclidean,
    /// Manhattan (taxicab) distance.
    Manhattan,
    /// Chebyshev (chessboard) distance.
    Chebyshev,
}

/// Noise algorithm kind used by fractal combinators.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum NoiseKind {
    /// Classic Perlin gradient noise.
    Perlin,
    /// Simplex noise.
    Simplex,
}

/// Fractal type for multi-octave noise.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FractalType {
    /// Fractal Brownian motion — smooth layered noise.
    Fbm,
    /// Ridged multi-fractal — sharp ridges.
    Ridged,
    /// Turbulence — absolute-value layered noise.
    Turbulence,
}

/// Options for 2D noise map generation.
#[derive(Debug, Clone)]
pub struct MapGenOptions {
    /// Horizontal scale factor applied to coordinates.
    pub scale_x: f64,
    /// Vertical scale factor applied to coordinates.
    pub scale_y: f64,
    /// Number of fractal octaves.
    pub octaves: u32,
    /// Frequency multiplier per octave.
    pub lacunarity: f64,
    /// Amplitude multiplier per octave.
    pub persistence: f64,
    /// Base noise algorithm.
    pub kind: NoiseKind,
    /// Fractal combination mode.
    pub fractal: FractalType,
    /// Horizontal offset applied to coordinates.
    pub offset_x: f64,
    /// Vertical offset applied to coordinates.
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

/// Seeded procedural noise generator.
///
/// Holds a 512-entry permutation table derived deterministically from the
/// seed.  All noise methods are pure functions of the seed and coordinates —
/// the same inputs always produce the same output.
pub struct NoiseGenerator {
    seed: u64,
    perm: [u8; 512],
}

impl NoiseGenerator {
    /// Creates a new generator with the given seed.
    pub fn new(seed: u64) -> Self {
        let mut gen = Self {
            seed,
            perm: [0; 512],
        };
        gen.build_perm();
        gen
    }

    /// Replaces the seed and rebuilds the permutation table.
    pub fn set_seed(&mut self, seed: u64) {
        self.seed = seed;
        self.build_perm();
    }

    /// Returns the current seed.
    pub fn seed(&self) -> u64 {
        self.seed
    }

    // ── Permutation table ──────────────────────────────────────────────

    /// Build a deterministic permutation table from `self.seed` using an LCG.
    fn build_perm(&mut self) {
        let mut table: Vec<u8> = (0..=255).collect();
        let mut lcg = self.seed;
        // Fisher–Yates shuffle driven by LCG
        for i in (1..256).rev() {
            lcg = lcg.wrapping_mul(6_364_136_223_846_793_005).wrapping_add(1);
            let j = (lcg >> 33) as usize % (i + 1);
            table.swap(i, j);
        }
        self.perm[..256].copy_from_slice(&table);
        self.perm[256..].copy_from_slice(&table);
    }

    /// Hash helper: look up the permutation table.
    #[inline]
    fn p(&self, idx: i32) -> u8 {
        self.perm[(idx & 255) as usize]
    }

    // ── Shared helpers ─────────────────────────────────────────────────

    /// Quintic fade curve.
    #[inline]
    fn fade(t: f64) -> f64 {
        t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
    }

    /// Linear interpolation.
    #[inline]
    fn lerp(a: f64, b: f64, t: f64) -> f64 {
        a + t * (b - a)
    }

    /// 1D gradient.
    #[inline]
    fn grad1(hash: u8, x: f64) -> f64 {
        if hash & 1 == 0 {
            x
        } else {
            -x
        }
    }

    /// 2D gradient.
    #[inline]
    fn grad2(hash: u8, x: f64, y: f64) -> f64 {
        match hash & 3 {
            0 => x + y,
            1 => -x + y,
            2 => x - y,
            _ => -x - y,
        }
    }

    /// 3D gradient.
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

    /// 4D gradient.
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

    /// Seed-based cell hash for Worley noise — returns a pseudo-random f64 in [0,1).
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

    /// 3D cell hash for Worley noise.
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

    // ── Perlin noise ───────────────────────────────────────────────────

    /// 1D Perlin noise. Returns a value in approximately `[-1, 1]`.
    pub fn perlin_1d(&self, x: f64) -> f64 {
        let xi = x.floor() as i32;
        let xf = x - x.floor();
        let u = Self::fade(xf);
        let a = self.p(xi);
        let b = self.p(xi + 1);
        Self::lerp(Self::grad1(a, xf), Self::grad1(b, xf - 1.0), u)
    }

    /// 2D Perlin noise. Returns a value in approximately `[-1, 1]`.
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

    /// 3D Perlin noise. Returns a value in approximately `[-1, 1]`.
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

    /// 4D Perlin noise. Returns a value in approximately `[-1, 1]`.
    pub fn perlin_4d(&self, x: f64, y: f64, z: f64, w: f64) -> f64 {
        let xi = x.floor() as i32;
        let yi = y.floor() as i32;
        let zi = z.floor() as i32;
        let wi = w.floor() as i32;
        let xf = x - x.floor();
        let yf = y - y.floor();
        let zf = z - z.floor();
        let wf = w - w.floor();
        let fu = Self::fade(xf);
        let fv = Self::fade(yf);
        let fw = Self::fade(zf);
        let ft = Self::fade(wf);

        // Hash all 16 corners
        let mut corners = [0.0f64; 16];
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
        for (idx, &(dx, dy, dz, dw)) in offsets.iter().enumerate() {
            let h = self.p(
                self.p(self.p(self.p(xi + dx) as i32 + yi + dy) as i32 + zi + dz) as i32
                    + wi
                    + dw,
            );
            corners[idx] = Self::grad4(
                h,
                xf - dx as f64,
                yf - dy as f64,
                zf - dz as f64,
                wf - dw as f64,
            );
        }

        // 4D lerp
        let x00 = Self::lerp(corners[0], corners[1], fu);
        let x10 = Self::lerp(corners[2], corners[3], fu);
        let x01 = Self::lerp(corners[4], corners[5], fu);
        let x11 = Self::lerp(corners[6], corners[7], fu);
        let x02 = Self::lerp(corners[8], corners[9], fu);
        let x12 = Self::lerp(corners[10], corners[11], fu);
        let x03 = Self::lerp(corners[12], corners[13], fu);
        let x13 = Self::lerp(corners[14], corners[15], fu);
        let y0 = Self::lerp(x00, x10, fv);
        let y1 = Self::lerp(x01, x11, fv);
        let y2 = Self::lerp(x02, x12, fv);
        let y3 = Self::lerp(x03, x13, fv);
        let z0 = Self::lerp(y0, y1, fw);
        let z1 = Self::lerp(y2, y3, fw);
        Self::lerp(z0, z1, ft)
    }

    // ── Simplex noise ──────────────────────────────────────────────────

    /// 1D Simplex noise. Returns a value in approximately `[-1, 1]`.
    pub fn simplex_1d(&self, x: f64) -> f64 {
        let i0 = x.floor() as i32;
        let i1 = i0 + 1;
        let x0 = x - i0 as f64;
        let x1 = x0 - 1.0;

        let mut t0 = 1.0 - x0 * x0;
        t0 *= t0;
        let n0 = t0 * t0 * Self::grad1(self.p(i0), x0);

        let mut t1 = 1.0 - x1 * x1;
        t1 *= t1;
        let n1 = t1 * t1 * Self::grad1(self.p(i1), x1);

        // Scale to [-1, 1]
        0.395 * (n0 + n1)
    }

    /// 2D Simplex noise. Returns a value in approximately `[-1, 1]`.
    pub fn simplex_2d(&self, x: f64, y: f64) -> f64 {
        const F2: f64 = 0.366_025_403_784_438_6; // (sqrt(3) - 1) / 2
        const G2: f64 = 0.211_324_865_405_187_1; // (3 - sqrt(3)) / 6

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

        let n0 = {
            let t = 0.5 - x0 * x0 - y0 * y0;
            if t < 0.0 {
                0.0
            } else {
                t * t * t * t * Self::grad2(gi0, x0, y0)
            }
        };
        let n1 = {
            let t = 0.5 - x1 * x1 - y1 * y1;
            if t < 0.0 {
                0.0
            } else {
                t * t * t * t * Self::grad2(gi1, x1, y1)
            }
        };
        let n2 = {
            let t = 0.5 - x2 * x2 - y2 * y2;
            if t < 0.0 {
                0.0
            } else {
                t * t * t * t * Self::grad2(gi2, x2, y2)
            }
        };

        70.0 * (n0 + n1 + n2)
    }

    /// 3D Simplex noise. Returns a value in approximately `[-1, 1]`.
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

        // Determine simplex
        let (i1, j1, k1, i2, j2, k2) = if x0 >= y0 {
            if y0 >= z0 {
                (1, 0, 0, 1, 1, 0)
            } else if x0 >= z0 {
                (1, 0, 0, 1, 0, 1)
            } else {
                (0, 0, 1, 1, 0, 1)
            }
        } else if y0 < z0 {
            (0, 0, 1, 0, 1, 1)
        } else if x0 < z0 {
            (0, 1, 0, 0, 1, 1)
        } else {
            (0, 1, 0, 1, 1, 0)
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

    // ── Worley noise ───────────────────────────────────────────────────

    /// 2D Worley (cellular) noise. Returns a value in `[0, ~1]`.
    ///
    /// When `f2` is `false`, returns distance to nearest feature point.
    /// When `f2` is `true`, returns `F2 - F1` (cell border pattern).
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
                    DistType::Euclidean => ((x - px) * (x - px) + (y - py) * (y - py)).sqrt(),
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

    /// 3D Worley (cellular) noise. Returns a value in `[0, ~1]`.
    ///
    /// When `f2` is `false`, returns distance to nearest feature point.
    /// When `f2` is `true`, returns `F2 - F1` (cell border pattern).
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

    // ── Fractal combinators ────────────────────────────────────────────

    /// Samples the chosen noise kind at (x, y).
    fn sample_2d(&self, x: f64, y: f64, kind: NoiseKind) -> f64 {
        match kind {
            NoiseKind::Perlin => self.perlin_2d(x, y),
            NoiseKind::Simplex => self.simplex_2d(x, y),
        }
    }

    /// Fractal Brownian motion — sum of octaves with decreasing amplitude.
    pub fn fbm(
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

    /// Ridged multi-fractal — sharp ridges from `1 - |noise|`.
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

    /// Turbulence noise — sum of `|noise|` per octave.
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

    // ── Advanced ───────────────────────────────────────────────────────

    /// Domain warping — offsets the input coordinates by noise, producing organic distortion.
    ///
    /// Returns the warped `(x, y)` pair.
    pub fn warp_domain(&self, x: f64, y: f64, strength: f64) -> (f64, f64) {
        let wx = x + strength * self.perlin_2d(x + 5.2, y + 1.3);
        let wy = y + strength * self.perlin_2d(x + 9.7, y + 8.1);
        (wx, wy)
    }

    /// Generates a 2D noise map of `width * height` values using the given options.
    ///
    /// Values are stored in row-major order: `map[y * width + x]`.
    pub fn generate_map(&self, width: u32, height: u32, opts: &MapGenOptions) -> Vec<f64> {
        let len = (width as usize) * (height as usize);
        let mut map = Vec::with_capacity(len);

        for iy in 0..height {
            for ix in 0..width {
                let nx = (ix as f64 + opts.offset_x) * opts.scale_x;
                let ny = (iy as f64 + opts.offset_y) * opts.scale_y;
                let val = match opts.fractal {
                    FractalType::Fbm => {
                        self.fbm(nx, ny, opts.octaves, opts.lacunarity, opts.persistence, opts.kind)
                    }
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
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn deterministic_same_seed() {
        let g1 = NoiseGenerator::new(42);
        let g2 = NoiseGenerator::new(42);
        assert!((g1.perlin_2d(1.5, 2.3) - g2.perlin_2d(1.5, 2.3)).abs() < 1e-12);
        assert!((g1.simplex_2d(1.5, 2.3) - g2.simplex_2d(1.5, 2.3)).abs() < 1e-12);
    }

    #[test]
    fn different_seeds_differ() {
        let g1 = NoiseGenerator::new(1);
        let g2 = NoiseGenerator::new(999);
        // Extremely unlikely to be equal at an arbitrary point
        assert!((g1.perlin_2d(3.7, 8.1) - g2.perlin_2d(3.7, 8.1)).abs() > 1e-6);
    }

    #[test]
    fn perlin_in_range() {
        let gen = NoiseGenerator::new(0);
        for i in 0..200 {
            let x = i as f64 * 0.37;
            let y = i as f64 * 0.53;
            let v = gen.perlin_2d(x, y);
            assert!(
                v >= -1.5 && v <= 1.5,
                "perlin_2d out of range: {} at ({}, {})",
                v,
                x,
                y
            );
        }
    }

    #[test]
    fn simplex_in_range() {
        let gen = NoiseGenerator::new(7);
        for i in 0..200 {
            let x = i as f64 * 0.29;
            let y = i as f64 * 0.47;
            let v = gen.simplex_2d(x, y);
            assert!(
                v >= -1.5 && v <= 1.5,
                "simplex_2d out of range: {} at ({}, {})",
                v,
                x,
                y
            );
        }
    }

    #[test]
    fn generate_map_size() {
        let gen = NoiseGenerator::new(123);
        let map = gen.generate_map(16, 8, &MapGenOptions::default());
        assert_eq!(map.len(), 16 * 8);
    }

    #[test]
    fn worley_non_negative() {
        let gen = NoiseGenerator::new(55);
        for i in 0..50 {
            let x = i as f64 * 0.4 + 0.1;
            let y = i as f64 * 0.6 + 0.2;
            let v = gen.worley_2d(x, y, DistType::Euclidean, false);
            assert!(v >= 0.0, "worley_2d returned negative: {}", v);
        }
    }

    #[test]
    fn fbm_deterministic() {
        let g = NoiseGenerator::new(77);
        let a = g.fbm(1.0, 2.0, 4, 2.0, 0.5, NoiseKind::Perlin);
        let b = g.fbm(1.0, 2.0, 4, 2.0, 0.5, NoiseKind::Perlin);
        assert!((a - b).abs() < 1e-12);
    }

    #[test]
    fn set_seed_changes_output() {
        let mut gen = NoiseGenerator::new(1);
        let v1 = gen.perlin_2d(3.7, 8.1);
        gen.set_seed(9999);
        let v2 = gen.perlin_2d(3.7, 8.1);
        assert!((v1 - v2).abs() > 1e-6);
    }
}
