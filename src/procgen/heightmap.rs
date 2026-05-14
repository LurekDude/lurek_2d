//! Heightmap generation and simple hydraulic erosion for `src/procgen`.
//! Owns `HeightmapOpts`, `Heightmap`, and its FBM-noise construction, cellular
//! conversion, normalisation, erosion, and RGBA export methods. Does not own
//! biome classification or noise primitives — those live in `biome.rs` and `noise.rs`.

use crate::procgen::noise::{FractalType, MapGenOptions, NoiseGenerator, NoiseKind};
use crate::procgen::scalar_map_to_rgba_bytes;

/// Parameters for procedural heightmap generation.
#[derive(Debug, Clone)]
pub struct HeightmapOpts {
    /// Grid width in cells.
    pub width: u32,
    /// Grid height in cells.
    pub height: u32,
    /// Noise frequency scale applied to both axes; smaller = smoother features.
    pub scale: f64,
    /// Number of FBM octaves summed together.
    pub octaves: u32,
    /// Frequency multiplier per octave (typically 2.0).
    pub lacunarity: f64,
    /// Amplitude multiplier per octave; controls how much each octave contributes.
    pub persistence: f64,
    /// Seed passed to `NoiseGenerator::new`.
    pub seed: u64,
    /// Number of simple hydraulic erosion passes run after noise generation; 0 = none.
    pub erosion_passes: u32,
}

/// Default for a 64×64 map with 5 octaves, no erosion.
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

/// Normalised heightmap grid with float cells in 0.0–1.0 after construction.
#[derive(Debug, Clone)]
pub struct Heightmap {
    /// Grid width in cells.
    pub width: u32,
    /// Grid height in cells.
    pub height: u32,
    /// Flat row-major cell values; index = `y * width + x`.
    pub cells: Vec<f32>,
}

impl Heightmap {
    /// Generate a heightmap from `opts` using FBM Perlin noise, normalised and optionally eroded.
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

    /// Build a heightmap from a pre-computed `f64` noise slice; normalises the result.
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

    /// Build a heightmap from a cellular automata `u8` grid: cells != `floor_value` map to 1.0, others to 0.0.
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

    /// Return the cell value at `(x, y)`, clamping out-of-bounds coordinates to the grid edge.
    pub fn get(&self, x: u32, y: u32) -> f32 {
        let x = x.min(self.width.saturating_sub(1));
        let y = y.min(self.height.saturating_sub(1));
        self.cells[(y * self.width + x) as usize]
    }

    /// Overwrite the cell at `(x, y)` with `v`; assumes coordinates are in-bounds.
    fn set(&mut self, x: u32, y: u32, v: f32) {
        let idx = (y * self.width + x) as usize;
        self.cells[idx] = v;
    }

    /// Remap all cells to 0.0–1.0 by dividing by the current min/max range; no-op if range < 1e-7.
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

    /// Apply `passes` rounds of simple hydraulic erosion: each cell deposits 10 % of its height difference into its lowest 4-connected neighbour.
    pub fn erode(&mut self, passes: u32) {
        for _ in 0..passes {
            let w = self.width;
            let h = self.height;
            for y in 0..h {
                for x in 0..w {
                    let center = self.get(x, y);
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

    /// Convert the cell grid to a flat grayscale RGBA byte buffer at 4 bytes per cell.
    pub fn to_rgba_bytes(&self) -> Vec<u8> {
        scalar_map_to_rgba_bytes(&self.cells)
    }
}
    pub width: u32,
    pub height: u32,
    pub scale: f64,
    pub octaves: u32,
    pub lacunarity: f64,
    pub persistence: f64,
    pub seed: u64,
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
#[derive(Debug, Clone)]
pub struct Heightmap {
    pub width: u32,
    pub height: u32,
    pub cells: Vec<f32>,
}
impl Heightmap {
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
    pub fn get(&self, x: u32, y: u32) -> f32 {
        let x = x.min(self.width.saturating_sub(1));
        let y = y.min(self.height.saturating_sub(1));
        self.cells[(y * self.width + x) as usize]
    }
    fn set(&mut self, x: u32, y: u32, v: f32) {
        let idx = (y * self.width + x) as usize;
        self.cells[idx] = v;
    }
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
    pub fn erode(&mut self, passes: u32) {
        for _ in 0..passes {
            let w = self.width;
            let h = self.height;
            for y in 0..h {
                for x in 0..w {
                    let center = self.get(x, y);
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
    pub fn to_rgba_bytes(&self) -> Vec<u8> {
        scalar_map_to_rgba_bytes(&self.cells)
    }
}
