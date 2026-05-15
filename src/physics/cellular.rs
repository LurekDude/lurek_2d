//! - Fixed-size cellular automaton grid simulating falling sand, flowing water, rising gas, and spreading fire.
//! - Material interaction rules: sand displaces water, fire consumes gas, gravity pulls solids down.
//! - Alternating sweep direction each tick to reduce lateral bias in material flow.
//! - RGBA image export with pluggable palette for rendering grid state to textures.
//! - Compact byte serialization and deserialization for save/load of grid snapshots.
//! - Geometric fill helpers (rect, circle) for painting materials into the grid.

/// Cell material type used in `CellularWorld`.
#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum CellType {
    /// Empty cell.
    Air = 0,
    /// Granular solid that falls and displaces water.
    Sand = 1,
    /// Liquid that flows sideways and falls.
    Water = 2,
    /// Immovable solid.
    Rock = 3,
    /// Burning cell that rises and spreads.
    Fire = 4,
    /// Light gas that rises and disperses.
    Gas = 5,
}
/// Conversion from raw byte to `CellType`.
impl CellType {
    /// Map a raw `u8` to `CellType`; unmapped values return `Air`.
    pub fn from_u8(v: u8) -> Self {
        match v {
            1 => CellType::Sand,
            2 => CellType::Water,
            3 => CellType::Rock,
            4 => CellType::Fire,
            5 => CellType::Gas,
            _ => CellType::Air,
        }
    }
}
/// Fixed-size grid simulating material interactions each step.
pub struct CellularWorld {
    /// Grid width in cells.
    pub width: u32,
    /// Grid height in cells.
    pub height: u32,
    /// Flat row-major cell storage.
    cells: Vec<CellType>,
    /// Per-cell fire lifetime counter.
    fire_life: Vec<u8>,
    /// Alternates each step to reduce left/right bias.
    even_tick: bool,
    /// Internal xorshift RNG state.
    rng_state: u32,
}
/// All methods for `CellularWorld`.
impl CellularWorld {
    /// Create an all-air grid of `width`×`height` cells.
    pub fn new(width: u32, height: u32) -> Self {
        let total = (width * height) as usize;
        Self {
            width,
            height,
            cells: vec![CellType::Air; total],
            fire_life: vec![0u8; total],
            even_tick: true,
            rng_state: 0xDEAD_BEEF,
        }
    }
    /// Set the cell at `(cx,cy)` to `cell`; initializes fire lifetime when cell is Fire.
    pub fn set_cell(&mut self, cx: u32, cy: u32, cell: CellType) {
        if cx >= self.width || cy >= self.height {
            return;
        }
        let idx = (cy * self.width + cx) as usize;
        self.cells[idx] = cell;
        if cell == CellType::Fire {
            self.fire_life[idx] = 80 + (self.rng_u8() % 40);
        } else {
            self.fire_life[idx] = 0;
        }
    }
    /// Return the cell type at `(cx,cy)`; returns Air when out of bounds.
    pub fn get_cell(&self, cx: u32, cy: u32) -> CellType {
        if cx >= self.width || cy >= self.height {
            return CellType::Air;
        }
        self.cells[(cy * self.width + cx) as usize]
    }
    /// Fill a rectangular region with `cell`; clips to grid bounds.
    pub fn fill_rect(&mut self, cx0: u32, cy0: u32, cw: u32, ch: u32, cell: CellType) {
        let x1 = (cx0 + cw).min(self.width);
        let y1 = (cy0 + ch).min(self.height);
        for cy in cy0..y1 {
            for cx in cx0..x1 {
                self.set_cell(cx, cy, cell);
            }
        }
    }
    /// Fill a circular region of radius `r_cells` around `(cx_c,cy_c)` with `cell`.
    pub fn fill_circle(&mut self, cx_c: u32, cy_c: u32, r_cells: u32, cell: CellType) {
        let r = r_cells as i64;
        let r2 = r * r;
        for dy in -r..=r {
            for dx in -r..=r {
                if dx * dx + dy * dy <= r2 {
                    let cx = cx_c as i64 + dx;
                    let cy = cy_c as i64 + dy;
                    if cx >= 0 && cy >= 0 && cx < self.width as i64 && cy < self.height as i64 {
                        self.set_cell(cx as u32, cy as u32, cell);
                    }
                }
            }
        }
    }
    /// Advance the simulation by one tick, applying material rules to every cell.
    pub fn step(&mut self) {
        self.even_tick = !self.even_tick;
        let mut next = self.cells.clone();
        let mut next_fire = self.fire_life.clone();
        let w = self.width as i64;
        let h = self.height as i64;
        for cy in (0..h).rev() {
            let col_iter: Box<dyn Iterator<Item = i64>> = if self.even_tick {
                Box::new(0..w)
            } else {
                Box::new((0..w).rev())
            };
            for cx in col_iter {
                let idx = (cy * w + cx) as usize;
                match self.cells[idx] {
                    CellType::Air | CellType::Rock => {}
                    CellType::Sand => {
                        if cy + 1 < h {
                            let below = (cy + 1) * w + cx;
                            if next[below as usize] == CellType::Air {
                                next[below as usize] = CellType::Sand;
                                next[idx] = CellType::Air;
                                continue;
                            }
                            let bias = if self.even_tick { 1i64 } else { -1i64 };
                            for &dx in &[bias, -bias] {
                                let nx = cx + dx;
                                if nx >= 0 && nx < w {
                                    let diag = ((cy + 1) * w + nx) as usize;
                                    if next[diag] == CellType::Air {
                                        next[diag] = CellType::Sand;
                                        next[idx] = CellType::Air;
                                        break;
                                    }
                                    if next[diag] == CellType::Water {
                                        next[diag] = CellType::Sand;
                                        next[idx] = CellType::Water;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    CellType::Water => {
                        if cy + 1 < h {
                            let below = ((cy + 1) * w + cx) as usize;
                            if next[below] == CellType::Air {
                                next[below] = CellType::Water;
                                next[idx] = CellType::Air;
                                continue;
                            }
                        }
                        let bias = if self.even_tick { 1i64 } else { -1i64 };
                        for &dx in &[bias, -bias] {
                            let nx = cx + dx;
                            if nx >= 0 && nx < w {
                                let side = (cy * w + nx) as usize;
                                if next[side] == CellType::Air {
                                    next[side] = CellType::Water;
                                    next[idx] = CellType::Air;
                                    break;
                                }
                            }
                        }
                    }
                    CellType::Fire => {
                        let life = &mut next_fire[idx];
                        if *life == 0 {
                            next[idx] = CellType::Air;
                            continue;
                        }
                        *life -= 1;
                        if cy > 0 {
                            let above = ((cy - 1) * w + cx) as usize;
                            if next[above] == CellType::Air && (self.rng_u8() & 3) != 0 {
                                next_fire[above] = next_fire[idx].saturating_sub(1);
                                next[above] = CellType::Fire;
                                next[idx] = CellType::Air;
                                next_fire[idx] = 0;
                                continue;
                            }
                        }
                        let spread_dirs: [(i64, i64); 4] = [(-1, 0), (1, 0), (0, -1), (0, 1)];
                        if (self.rng_u8() & 15) == 0 {
                            let di = (self.rng_u8() as usize) % 4;
                            let (dx, dy) = spread_dirs[di];
                            let nx = cx + dx;
                            let ny = cy + dy;
                            if nx >= 0 && nx < w && ny >= 0 && ny < h {
                                let ni = (ny * w + nx) as usize;
                                if next[ni] == CellType::Air || next[ni] == CellType::Gas {
                                    next[ni] = CellType::Fire;
                                    next_fire[ni] = 40 + (self.rng_u8() % 20);
                                }
                            }
                        }
                    }
                    CellType::Gas => {
                        if cy > 0 {
                            let above = ((cy - 1) * w + cx) as usize;
                            if next[above] == CellType::Air {
                                next[above] = CellType::Gas;
                                next[idx] = CellType::Air;
                                continue;
                            }
                        }
                        let bias = if self.even_tick { 1i64 } else { -1i64 };
                        for &dx in &[bias, -bias] {
                            let nx = cx + dx;
                            if nx >= 0 && nx < w {
                                let side = (cy * w + nx) as usize;
                                if next[side] == CellType::Air {
                                    next[side] = CellType::Gas;
                                    next[idx] = CellType::Air;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        self.cells = next;
        self.fire_life = next_fire;
    }
    /// Run `n` simulation steps. This function is part of the public API.
    pub fn step_n(&mut self, n: u32) {
        for _ in 0..n {
            self.step();
        }
    }
    /// Encode the full grid as RGBA pixel data using `palette`.
    pub fn to_image_data<F: Fn(CellType) -> [u8; 4]>(&self, palette: F) -> Vec<u8> {
        let mut buf = Vec::with_capacity((self.width * self.height * 4) as usize);
        for &cell in &self.cells {
            buf.extend_from_slice(&palette(cell));
        }
        buf
    }
    /// Encode a rectangular sub-region as RGBA pixel data using `palette`.
    pub fn to_image_data_region<F: Fn(CellType) -> [u8; 4]>(
        &self,
        cx0: u32,
        cy0: u32,
        cw: u32,
        ch: u32,
        palette: F,
    ) -> Vec<u8> {
        let mut buf = Vec::with_capacity((cw * ch * 4) as usize);
        for dy in 0..ch {
            for dx in 0..cw {
                let cx = cx0 + dx;
                let cy = cy0 + dy;
                let cell = self.get_cell(cx, cy);
                buf.extend_from_slice(&palette(cell));
            }
        }
        buf
    }
    /// Return all `(cx,cy)` positions containing `cell_type`.
    pub fn find_cells(&self, cell_type: CellType) -> Vec<(u32, u32)> {
        let mut out = Vec::new();
        for cy in 0..self.height {
            for cx in 0..self.width {
                if self.cells[(cy * self.width + cx) as usize] == cell_type {
                    out.push((cx, cy));
                }
            }
        }
        out
    }
    /// Return the count of cells matching `cell_type`.
    pub fn count_cells(&self, cell_type: CellType) -> u32 {
        self.cells.iter().filter(|&&c| c == cell_type).count() as u32
    }
    /// Serialize the grid to a compact byte buffer (`width u32 LE` + `height u32 LE` + cell bytes).
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(8 + self.cells.len());
        buf.extend_from_slice(&self.width.to_le_bytes());
        buf.extend_from_slice(&self.height.to_le_bytes());
        for &cell in &self.cells {
            buf.push(cell as u8);
        }
        buf
    }
    /// Deserialize a grid from a byte buffer produced by `to_bytes`; return `None` on malformed input.
    pub fn from_bytes(bytes: &[u8]) -> Option<Self> {
        if bytes.len() < 8 {
            return None;
        }
        let width = u32::from_le_bytes(bytes[0..4].try_into().ok()?);
        let height = u32::from_le_bytes(bytes[4..8].try_into().ok()?);
        let total = (width * height) as usize;
        let cell_bytes = &bytes[8..];
        if cell_bytes.len() < total {
            return None;
        }
        let cells: Vec<CellType> = cell_bytes[..total]
            .iter()
            .map(|&b| CellType::from_u8(b))
            .collect();
        Some(Self {
            width,
            height,
            cells,
            fire_life: vec![0u8; total],
            even_tick: true,
            rng_state: 0xDEAD_BEEF,
        })
    }
    /// Advance the internal xorshift RNG and return one byte.
    fn rng_u8(&mut self) -> u8 {
        let mut x = self.rng_state;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        self.rng_state = x;
        x as u8
    }
}
/// Default RGBA palette mapping each `CellType` to a recognizable colour.
pub fn default_palette(cell: CellType) -> [u8; 4] {
    match cell {
        CellType::Air => [20, 20, 30, 255],
        CellType::Sand => [194, 178, 128, 255],
        CellType::Water => [64, 164, 223, 200],
        CellType::Rock => [120, 120, 120, 255],
        CellType::Fire => [230, 80, 20, 255],
        CellType::Gas => [140, 220, 120, 160],
    }
}
#[allow(unused_imports)]
use std::collections::HashSet as _HashSet;
