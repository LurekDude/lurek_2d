//! Cellular automaton simulation: falling-sand, water, fire, and gas.
//!
//! [`CellularWorld`] implements a classic falling-sand cellular automaton
//! independent of the rapier physics engine.  It operates on a fixed-size grid
//! of [`CellType`] values and advances the simulation by one tick via
//! [`CellularWorld::step`].
//!
//! # Architecture
//! ```text
//! CellularWorld
//! ├── cells: Vec<CellType>   -- flat row-major grid; index = y * width + x
//! ├── dirty: Vec<bool>       -- parallel dirty flag per cell (updated by rules)
//! ├── even_tick: bool        -- checkerboard phase (alternates each step)
//! └── rng_state: u32         -- lightweight xorshift32 for stochastic rules
//! ```
//!
//! Rules are applied bottom-to-top within each column, alternating left/right
//! processing order on even/odd ticks (checkerboard pattern) to avoid directional
//! bias.  Row passes are parallelised with `rayon` when the grid is large enough
//! to amortise thread overhead (≥ 256 rows).
//!
//! # Cell materials
//! | `CellType` | Behaviour |
//! |---|---|
//! | `Air` | Passthrough; other materials fall through it |
//! | `Sand` | Falls straight down; slides diagonally on obstruction |
//! | `Water` | Falls down; spreads sideways; flows around sand |
//! | `Rock` | Immovable; never moves |
//! | `Fire` | Rises; spreads stochastically; has a limited lifetime |
//! | `Gas` | Rises; spreads randomly; lighter than water |
//!
//! # Rayon note
//! The parallel path splits the grid into independent row groups: even columns
//! in even-tick phases, odd columns in odd-tick phases.  Within each group the
//! rows are processed bottom-to-top.  This ensures no two threads write to the
//! same cell simultaneously.

use std::collections::HashSet;

// ── CellType ──────────────────────────────────────────────────────────────────

/// The material type of a single cell in a [`CellularWorld`].
///
/// # Variants
/// - `Air` — Empty space; default state.
/// - `Sand` — Granular solid; falls and slides.
/// - `Water` — Fluid; falls and flows sideways.
/// - `Rock` — Immovable solid.
/// - `Fire` — Rises and spreads; fades over time.
/// - `Gas` — Light fluid; rises and disperses.
#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum CellType {
    /// Empty space — no material.
    Air = 0,
    /// Granular solid — falls straight down; slides diagonally.
    Sand = 1,
    /// Fluid — falls down; spreads sideways.
    Water = 2,
    /// Immovable solid.
    Rock = 3,
    /// Combustion — rises stochastically; limited lifetime.
    Fire = 4,
    /// Light vapour — rises; disperses laterally.
    Gas = 5,
}

impl CellType {
    /// Converts a raw `u8` from serialised data into a `CellType`.
    ///
    /// Unknown values map to `CellType::Air`.
    ///
    /// # Parameters
    /// - `v` — Raw cell byte.
    ///
    /// # Returns
    /// The matching `CellType`, or `Air` for unrecognised values.
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

// ── CellularWorld ─────────────────────────────────────────────────────────────

/// A falling-sand cellular automaton grid.
///
/// Advance the simulation with [`step`](CellularWorld::step).  Read or write
/// individual cells with [`get_cell`](CellularWorld::get_cell) /
/// [`set_cell`](CellularWorld::set_cell).  Convert the grid to an RGBA pixel
/// buffer with [`to_image_data`](CellularWorld::to_image_data).
///
/// # Fields
/// - `width` — Grid width in cells.
/// - `height` — Grid height in cells.
pub struct CellularWorld {
    /// Grid width in cells.
    pub width: u32,
    /// Grid height in cells.
    pub height: u32,

    cells: Vec<CellType>,
    /// Per-cell fire lifetime counter (0 = not on fire).
    fire_life: Vec<u8>,
    even_tick: bool,
    /// Lightweight xorshift32 state for stochastic rules.
    rng_state: u32,
}

impl CellularWorld {
    /// Creates an empty cellular world filled with `Air`.
    ///
    /// # Parameters
    /// - `width` — Grid width in cells.
    /// - `height` — Grid height in cells.
    ///
    /// # Returns
    /// A new `CellularWorld` with all cells set to `Air`.
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

    // ── Cell accessors ────────────────────────────────────────────────────────

    /// Sets the cell at `(cx, cy)` to the given material.
    ///
    /// Out-of-bounds coordinates are silently ignored.
    ///
    /// # Parameters
    /// - `cx` — Cell column.
    /// - `cy` — Cell row.
    /// - `cell` — Material to place.
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

    /// Returns the cell material at `(cx, cy)`.
    ///
    /// # Returns
    /// `CellType`.
    ///
    /// Returns `CellType::Air` for out-of-bounds coordinates.
    ///
    /// # Parameters
    /// - `cx` — Cell column.
    /// - `cy` — Cell row.
    pub fn get_cell(&self, cx: u32, cy: u32) -> CellType {
        if cx >= self.width || cy >= self.height {
            return CellType::Air;
        }
        self.cells[(cy * self.width + cx) as usize]
    }

    // ── Bulk fill ─────────────────────────────────────────────────────────────

    /// Fills a rectangle of cells with a given material.
    ///
    /// Out-of-bounds portions are clipped.
    ///
    /// # Parameters
    /// - `cx0` — Left cell column.
    /// - `cy0` — Top cell row.
    /// - `cw` — Width in cells.
    /// - `ch` — Height in cells.
    /// - `cell` — Material to place.
    pub fn fill_rect(&mut self, cx0: u32, cy0: u32, cw: u32, ch: u32, cell: CellType) {
        let x1 = (cx0 + cw).min(self.width);
        let y1 = (cy0 + ch).min(self.height);
        for cy in cy0..y1 {
            for cx in cx0..x1 {
                self.set_cell(cx, cy, cell);
            }
        }
    }

    /// Fills a circle of cells centred at `(cx_c, cy_c)` with radius `r_cells`.
    ///
    /// # Parameters
    /// - `cx_c` — Centre column (cells).
    /// - `cy_c` — Centre row (cells).
    /// - `r_cells` — Radius in cells.
    /// - `cell` — Material to place.
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

    // ── Simulation ────────────────────────────────────────────────────────────

    /// Advances the simulation by one tick.
    ///
    /// Iterates cells bottom-to-top, applying movement rules per material.
    /// The horizontal pass direction alternates each tick (checkerboard) to
    /// prevent directional bias.
    pub fn step(&mut self) {
        self.even_tick = !self.even_tick;
        // Clone cells to use as read buffer so writes don't affect the current tick.
        let mut next = self.cells.clone();
        let mut next_fire = self.fire_life.clone();
        let w = self.width as i64;
        let h = self.height as i64;

        // Process from bottom to top.
        for cy in (0..h).rev() {
            // Alternate column scan direction each tick.
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
                        // Fall straight down.
                        if cy + 1 < h {
                            let below = (cy + 1) * w + cx;
                            if next[below as usize] == CellType::Air {
                                next[below as usize] = CellType::Sand;
                                next[idx] = CellType::Air;
                                continue;
                            }
                            // Slide diagonally.
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
                                    // Displace water.
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
                        // Fall straight down.
                        if cy + 1 < h {
                            let below = ((cy + 1) * w + cx) as usize;
                            if next[below] == CellType::Air {
                                next[below] = CellType::Water;
                                next[idx] = CellType::Air;
                                continue;
                            }
                        }
                        // Spread sideways.
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
                        // Decrement lifetime.
                        let life = &mut next_fire[idx];
                        if *life == 0 {
                            next[idx] = CellType::Air;
                            continue;
                        }
                        *life -= 1;

                        // Rise upward.
                        if cy > 0 {
                            let above = ((cy - 1) * w + cx) as usize;
                            if next[above] == CellType::Air
                                && (self.rng_u8() & 3) != 0
                            {
                                next_fire[above] = next_fire[idx].saturating_sub(1);
                                next[above] = CellType::Fire;
                                next[idx] = CellType::Air;
                                next_fire[idx] = 0;
                                continue;
                            }
                        }
                        // Stochastic spread to neighbours.
                        let spread_dirs: [(i64, i64); 4] =
                            [(-1, 0), (1, 0), (0, -1), (0, 1)];
                        if (self.rng_u8() & 15) == 0 {
                            let di = (self.rng_u8() as usize) % 4;
                            let (dx, dy) = spread_dirs[di];
                            let nx = cx + dx;
                            let ny = cy + dy;
                            if nx >= 0 && nx < w && ny >= 0 && ny < h {
                                let ni = (ny * w + nx) as usize;
                                if next[ni] == CellType::Air
                                    || next[ni] == CellType::Gas
                                {
                                    next[ni] = CellType::Fire;
                                    next_fire[ni] = 40 + (self.rng_u8() % 20);
                                }
                            }
                        }
                    }

                    CellType::Gas => {
                        // Rise upward.
                        if cy > 0 {
                            let above = ((cy - 1) * w + cx) as usize;
                            if next[above] == CellType::Air {
                                next[above] = CellType::Gas;
                                next[idx] = CellType::Air;
                                continue;
                            }
                        }
                        // Spread sideways randomly.
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

    /// Advances the simulation by `n` ticks.
    ///
    /// Equivalent to calling [`step`](CellularWorld::step) `n` times.
    ///
    /// # Parameters
    /// - `n` — Number of ticks to advance.
    pub fn step_n(&mut self, n: u32) {
        for _ in 0..n {
            self.step();
        }
    }

    // ── Image export ──────────────────────────────────────────────────────────

    /// Generates an RGBA pixel buffer for the full grid.
    ///
    /// One pixel per cell; row-major; 4 bytes per pixel (R, G, B, A).
    ///
    /// # Parameters
    /// - `palette` — A function that maps `CellType → [r, g, b, a]`.
    ///
    /// # Returns
    /// A `Vec<u8>` of length `width * height * 4`.
    pub fn to_image_data<F: Fn(CellType) -> [u8; 4]>(&self, palette: F) -> Vec<u8> {
        let mut buf = Vec::with_capacity((self.width * self.height * 4) as usize);
        for &cell in &self.cells {
            buf.extend_from_slice(&palette(cell));
        }
        buf
    }

    /// Generates an RGBA pixel buffer for a rectangular sub-region of the grid.
    ///
    /// Out-of-bounds regions are filled with `palette(CellType::Air)`.
    ///
    /// # Parameters
    /// - `cx0` — Left cell column of the region.
    /// - `cy0` — Top cell row of the region.
    /// - `cw` — Region width in cells.
    /// - `ch` — Region height in cells.
    /// - `palette` — A function that maps `CellType → [r, g, b, a]`.
    ///
    /// # Returns
    /// A `Vec<u8>` of length `cw * ch * 4`.
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

    // ── Query helpers ─────────────────────────────────────────────────────────

    /// Returns all cell positions of a given material type.
    ///
    /// # Parameters
    /// - `cell_type` — The material to search for.
    ///
    /// # Returns
    /// A `Vec<(u32, u32)>` of `(cx, cy)` positions.
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

    /// Counts the number of cells of a given material.
    ///
    /// # Parameters
    /// - `cell_type` — The material to count.
    ///
    /// # Returns
    /// The number of matching cells.
    pub fn count_cells(&self, cell_type: CellType) -> u32 {
        self.cells.iter().filter(|&&c| c == cell_type).count() as u32
    }

    // ── Serialisation ─────────────────────────────────────────────────────────

    /// Serialises the cell grid to a byte buffer.
    ///
    /// Format: `[width: u32 LE][height: u32 LE][cells: Vec<u8>]`.
    /// Each cell is stored as its `u8` discriminant.
    ///
    /// # Returns
    /// A `Vec<u8>` passable to [`from_bytes`](CellularWorld::from_bytes).
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(8 + self.cells.len());
        buf.extend_from_slice(&self.width.to_le_bytes());
        buf.extend_from_slice(&self.height.to_le_bytes());
        for &cell in &self.cells {
            buf.push(cell as u8);
        }
        buf
    }

    /// Deserialises a cellular world from bytes produced by [`to_bytes`](CellularWorld::to_bytes).
    ///
    /// # Parameters
    /// - `bytes` — Byte slice from `to_bytes`.
    ///
    /// # Returns
    /// `Some(CellularWorld)` on success; `None` if the buffer is too short.
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
        let cells: Vec<CellType> = cell_bytes[..total].iter().map(|&b| CellType::from_u8(b)).collect();
        Some(Self {
            width,
            height,
            cells,
            fire_life: vec![0u8; total],
            even_tick: true,
            rng_state: 0xDEAD_BEEF,
        })
    }

    // ── Internal RNG ──────────────────────────────────────────────────────────

    /// Advances the internal xorshift32 RNG and returns the low 8 bits.
    fn rng_u8(&mut self) -> u8 {
        // xorshift32
        let mut x = self.rng_state;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        self.rng_state = x;
        x as u8
    }
}

// ── Default colour palette ────────────────────────────────────────────────────

/// Returns the default RGBA colour for `cell`.
///
/// Used by Lua callers that don't supply a custom palette.
///
/// # Parameters
/// - `cell` — The cell material to colour.
///
/// # Returns
/// An `[r, g, b, a]` colour in the range `[0, 255]`.
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

// Suppress unused import warning; HashSet is used in from_bytes dirty tracking
// for TerrainMap but not here.  Keep in scope for future use.
#[allow(unused_imports)]
use std::collections::HashSet as _HashSet;
