//! Heightmap generation using fractal noise, erosion, and normalization.
//!
//! Produces a 2D grid of elevation values in [0, 1] suitable for terrain generation,
//! shadow maps, or any application requiring smooth height data.

use crate::procgen::noise::{FractalType, MapGenOptions, NoiseGenerator, NoiseKind};
use crate::procgen::scalar_map_to_rgba_bytes;

/// Options for heightmap generation.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `scale` — `f64`.
/// - `octaves` — `u32`.
/// - `lacunarity` — `f64`.
/// - `persistence` — `f64`.
/// - `seed` — `u64`.
/// - `erosion_passes` — `u32`.
#[derive(Debug, Clone)]
pub struct HeightmapOpts {
    /// Map width in cells.
    pub width: u32,
    /// Map height in cells.
    pub height: u32,
    /// Coordinate scale (zoom). Larger = more zoomed out.
    pub scale: f64,
    /// Number of noise octaves for fractal detail.
    pub octaves: u32,
    /// Frequency multiplier per octave.
    pub lacunarity: f64,
    /// Amplitude multiplier per octave (persistence).
    pub persistence: f64,
    /// Random seed.
    pub seed: u64,
    /// Number of hydraulic erosion passes.
    pub erosion_passes: u32,
}

impl Default for HeightmapOpts {
    fn default() -> Self {
        Self {
            width: 64,
            height: 64,
            scale: 1.0 / 32.0,
            octaves: 5,
            lacunarity: 2.0,
            persistence: 0.5,
            seed: 0,
            erosion_passes: 0,
        }
    }
}

/// A 2D heightmap with float elevation values.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `cells` — `Vec<f32>`.
#[derive(Debug, Clone)]
pub struct Heightmap {
    /// Map width.
    pub width: u32,
    /// Map height.
    pub height: u32,
    /// Elevation values in row-major order.
    pub cells: Vec<f32>,
}

impl Heightmap {
    /// Generate a heightmap from the given options.
    ///
    /// # Parameters
    /// - `opts` — `&HeightmapOpts`.
    ///
    /// # Returns
    /// `Self`.
    pub fn generate(opts: &HeightmapOpts) -> Self {
        let gen = NoiseGenerator::new(opts.seed);
        let map_opts = MapGenOptions {
            scale_x: opts.scale,
            scale_y: opts.scale,
            octaves: opts.octaves,
            lacunarity: opts.lacunarity,
            persistence: opts.persistence,
            kind: NoiseKind::Perlin,
            fractal: FractalType::Fbm,
            offset_x: 0.0,
            offset_y: 0.0,
        };

        let raw = gen.generate_map(opts.width, opts.height, &map_opts);
        let cells: Vec<f32> = raw.iter().map(|&v| v as f32).collect();

        let mut hm = Self {
            width: opts.width,
            height: opts.height,
            cells,
        };
        hm.normalize();
        if opts.erosion_passes > 0 {
            hm.erode(opts.erosion_passes);
            hm.normalize();
        }
        hm
    }

    /// Builds a heightmap from an existing flat scalar array.
    ///
    /// Missing values are filled with `0.0` and excess values are ignored.
    pub fn from_noise_map(width: u32, height: u32, values: &[f64]) -> Self {
        let len = (width * height) as usize;
        let mut cells = Vec::with_capacity(len);
        for i in 0..len {
            cells.push(values.get(i).copied().unwrap_or(0.0) as f32);
        }
        let mut hm = Self {
            width,
            height,
            cells,
        };
        hm.normalize();
        hm
    }

    /// Converts a cellular map (`0`/`1`) into a normalized heightmap.
    ///
    /// Cells equal to `floor_value` become 0.0, all others become 1.0.
    pub fn from_cellular(width: u32, height: u32, cells: &[u8], floor_value: u8) -> Self {
        let len = (width * height) as usize;
        let mut out = Vec::with_capacity(len);
        for i in 0..len {
            let v = cells.get(i).copied().unwrap_or(floor_value);
            out.push(if v == floor_value { 0.0 } else { 1.0 });
        }
        Self {
            width,
            height,
            cells: out,
        }
    }

    /// Get the elevation at `(x, y)`, clamped to valid range.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get(&self, x: u32, y: u32) -> f32 {
        let x = x.min(self.width.saturating_sub(1));
        let y = y.min(self.height.saturating_sub(1));
        self.cells[(y * self.width + x) as usize]
    }

    fn set(&mut self, x: u32, y: u32, v: f32) {
        let idx = (y * self.width + x) as usize;
        self.cells[idx] = v;
    }

    /// Normalize all elevation values to [0, 1].
    pub fn normalize(&mut self) {
        let min = self.cells.iter().cloned().fold(f32::MAX, f32::min);
        let max = self.cells.iter().cloned().fold(f32::MIN, f32::max);
        let range = max - min;
        if range < 1e-7 {
            return;
        }
        for v in &mut self.cells {
            *v = (*v - min) / range;
        }
    }

    /// Apply simplified hydraulic erosion: sediment flows from high to low neighbours.
    ///
    /// # Parameters
    /// - `passes` — `u32`.
    ///
    /// Each pass moves a fraction of height from each cell to its lowest neighbor.
    pub fn erode(&mut self, passes: u32) {
        for _ in 0..passes {
            let w = self.width;
            let h = self.height;
            for y in 0..h {
                for x in 0..w {
                    let center = self.get(x, y);
                    // Find the lowest of 4-directional neighbours
                    let dirs: [(i32, i32); 4] = [(1, 0), (-1, 0), (0, 1), (0, -1)];
                    let mut lowest_val = center;
                    let mut lowest_dir: Option<(u32, u32)> = None;
                    for (dx, dy) in dirs {
                        let nx = x as i32 + dx;
                        let ny = y as i32 + dy;
                        if nx >= 0 && ny >= 0 && nx < w as i32 && ny < h as i32 {
                            let nv = self.get(nx as u32, ny as u32);
                            if nv < lowest_val {
                                lowest_val = nv;
                                lowest_dir = Some((nx as u32, ny as u32));
                            }
                        }
                    }
                    if let Some((lx, ly)) = lowest_dir {
                        let diff = (center - lowest_val) * 0.1;
                        let new_center = center - diff;
                        let new_low = lowest_val + diff;
                        self.set(x, y, new_center);
                        self.set(lx, ly, new_low);
                    }
                }
            }
        }
    }

    /// Convert the heightmap to RGBA bytes (grayscale: `r = g = b = height * 255`, `a = 255`).
    ///
    /// # Returns
    /// `Vec<u8>`.
    pub fn to_rgba_bytes(&self) -> Vec<u8> {
        scalar_map_to_rgba_bytes(&self.cells)
    }
}
