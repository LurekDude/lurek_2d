//! Core noise algorithms: Perlin (1-D/2-D/3-D/4-D), Simplex (1-D/2-D/3-D), Worley cell noise,
//! fBm / ridged / turbulence fractals, domain warp, and full heightmap generation.
//! Used by procgen, tilemap, and globe terrain pipelines via NoiseGenerator.
//! Does not own thin Lua wrappers — those live in noise_functions.rs.

/// Distance metric used by Worley cell noise.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DistType {
    /// Standard Euclidean `sqrt(dx² + dy²)` distance.
    Euclidean,
    /// Manhattan `|dx| + |dy|` distance.
    Manhattan,
    /// Chebyshev `max(|dx|, |dy|)` distance.
    Chebyshev,
}

/// Base noise algorithm selected for fractal and single-octave queries.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum NoiseKind {
    /// Classic gradient Perlin noise.
    Perlin,
    /// Simplex noise (faster skewed-grid variant).
    Simplex,
}

/// Fractal layering strategy applied per octave pass.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FractalType {
    /// Fractional Brownian motion — sum of weighted octaves.
    Fbm,
    /// Ridged multifractal — inverts absolute values for sharp ridges.
    Ridged,
    /// Turbulence — sum of absolute values producing billowy detail.
    Turbulence,
}

/// Parameters controlling `NoiseGenerator::generate_map`.
#[derive(Debug, Clone)]
pub struct MapGenOptions {
    /// Horizontal frequency multiplier applied to world X coordinates.
    pub scale_x: f64,
    /// Vertical frequency multiplier applied to world Y coordinates.
    pub scale_y: f64,
    /// Number of fractal octave layers to accumulate.
    pub octaves: u32,
    /// Frequency multiplier between successive octaves (typically 2.0).
    pub lacunarity: f64,
    /// Amplitude multiplier between successive octaves (typically 0.5).
    pub persistence: f64,
    /// Base noise algorithm for each octave sample.
    pub kind: NoiseKind,
    /// Fractal combination strategy applied across octaves.
    pub fractal: FractalType,
    /// World-space X offset applied before scaling.
    pub offset_x: f64,
    /// World-space Y offset applied before scaling.
    pub offset_y: f64,
}

/// Provide sensible defaults: 4 octaves, lacunarity 2.0, persistence 0.5, Perlin fBm, no offset.
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

/// Seeded noise generator holding a 512-entry permutation table for all noise variants.
pub struct NoiseGenerator {
    /// Seed used to build the permutation table; stored for `seed()` retrieval.
    seed: u64,
    /// Doubled permutation table (256 entries mirrored) for gradient lookups without index masking.
    perm: [u8; 512],
}
impl NoiseGenerator {
    /// Construct a generator from `seed`, immediately building its permutation table.
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
    /// Shuffle and fill `self.perm` using a linear congruential generator seeded from `self.seed`.
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
    /// Return `perm[(idx & 255)]` as a u8 hash byte.
    #[inline]
    fn p(&self, idx: i32) -> u8 {
        self.perm[(idx & 255) as usize]
    }
    /// Compute the Perlin smoothstep fade curve `6t⁵-15t⁴+10t³`.
    #[inline]
    fn fade(t: f64) -> f64 {
        t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
    }
    /// Linearly interpolate between `a` and `b` by factor `t`.
    #[inline]
    fn lerp(a: f64, b: f64, t: f64) -> f64 {
        a + t * (b - a)
    }
    /// Return the 1-D gradient contribution: `+x` or `-x` based on the low bit of `hash`.
    #[inline]
    fn grad1(hash: u8, x: f64) -> f64 {
        if hash & 1 == 0 {
            x
        } else {
            -x
        }
    }
    /// Return the 2-D gradient contribution selecting one of four diagonal directions.
    #[inline]
    fn grad2(hash: u8, x: f64, y: f64) -> f64 {
        match hash & 3 {
            0 => x + y,
            1 => -x + y,
            2 => x - y,
            _ => -x - y,
        }
    }
    /// Return the 3-D gradient contribution selecting one of 12 edge directions.
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
    /// Return the 4-D gradient contribution selecting one of 32 directions.
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
    /// Return a deterministic pseudo-random value in `[0,1)` for 2-D cell index.
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
    /// Return a deterministic pseudo-random value in `[0,1)` for 3-D cell index.
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
    /// Return 1-D Perlin noise in approximately `[-1, 1]`.
    pub fn perlin_1d(&self, x: f64) -> f64 {
        let xi = x.floor() as i32;
        let xf = x - x.floor();
        let u = Self::fade(xf);
        let a = self.p(xi);
        let b = self.p(xi + 1);
        Self::lerp(Self::grad1(a, xf), Self::grad1(b, xf - 1.0), u)
    }
    /// Return 2-D Perlin noise in approximately `[-1, 1]`.
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
    /// Return 3-D Perlin noise in approximately `[-1, 1]`.
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
    /// Return 4-D Perlin noise in approximately `[-1, 1]` via 16-corner trilinear interpolation.
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
                self.p(self.p(self.p(xi + dx) as i32 + yi + dy) as i32 + zi + dz) as i32 + wi + dw,
            );
            corners[idx] = Self::grad4(
                h,
                xf - dx as f64,
                yf - dy as f64,
                zf - dz as f64,
                wf - dw as f64,
            );
        }
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
    /// Return 1-D Simplex noise in approximately `[-1, 1]`.
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
        0.395 * (n0 + n1)
    }
    /// Return 2-D Simplex noise in approximately `[-1, 1]`.
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
    /// Return 3-D Simplex noise in approximately `[-1, 1]`.
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
    }    /// Return 2-D Worley (cell) noise using `dist` metric; returns F2-F1 when `f2` is true.    pub fn worley_2d(&self, x: f64, y: f64, dist: DistType, f2: bool) -> f64 {
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
    /// Return 3-D Worley (cell) noise using `dist` metric; returns F2-F1 when `f2` is true.
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
    /// Sample a single 2-D noise value using the given `kind` at coordinate (x, y).
    fn sample_2d(&self, x: f64, y: f64, kind: NoiseKind) -> f64 {
        match kind {
            NoiseKind::Perlin => self.perlin_2d(x, y),
            NoiseKind::Simplex => self.simplex_2d(x, y),
        }
    }
    /// Return amplitude-normalised fBm noise summing `octaves` layers of `kind`.
    pub fn fbm(&self, x: f64, y: f64, octaves: u32, lac: f64, pers: f64, kind: NoiseKind) -> f64 {
        let pers = pers.max(0.0);
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
    /// Return amplitude-normalised ridged multifractal noise summing `octaves` inverted absolute layers.
    pub fn ridged(
        &self,
        x: f64,
        y: f64,
        octaves: u32,
        lac: f64,
        pers: f64,
        kind: NoiseKind,
    ) -> f64 {
        let pers = pers.max(0.0);
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
    /// Return amplitude-normalised turbulence noise summing `octaves` absolute-value layers.
    pub fn turbulence(
        &self,
        x: f64,
        y: f64,
        octaves: u32,
        lac: f64,
        pers: f64,
        kind: NoiseKind,
    ) -> f64 {
        let pers = pers.max(0.0);
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
    /// Apply domain warping using Perlin offsets, returning the displaced coordinate pair.
    pub fn warp_domain(&self, x: f64, y: f64, strength: f64) -> (f64, f64) {
        let wx = x + strength * self.perlin_2d(x + 5.2, y + 1.3);
        let wy = y + strength * self.perlin_2d(x + 9.7, y + 8.1);
        (wx, wy)
    }
    /// Generate a `width × height` heightmap using `opts`; returns row-major `f64` values in `[-1, 1]`.
    pub fn generate_map(&self, width: u32, height: u32, opts: &MapGenOptions) -> Vec<f64> {
        let len = (width as usize) * (height as usize);
        let mut map = Vec::with_capacity(len);
        let persistence = opts.persistence.max(0.0);
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
                        persistence,
                        opts.kind,
                    ),
                    FractalType::Ridged => self.ridged(
                        nx,
                        ny,
                        opts.octaves,
                        opts.lacunarity,
                        persistence,
                        opts.kind,
                    ),
                    FractalType::Turbulence => self.turbulence(
                        nx,
                        ny,
                        opts.octaves,
                        opts.lacunarity,
                        persistence,
                        opts.kind,
                    ),
                };
                map.push(val);
            }
        }
        map
    }
    /// Alias for `generate_map`; future versions may dispatch to a compute shader.
    pub fn generate_map_compute(&self, width: u32, height: u32, opts: &MapGenOptions) -> Vec<f64> {
        self.generate_map(width, height, opts)
    }
}
