//! Cellular automata cave and dungeon generation.
//!
//! Produces a flat grid of wall/open cells via random fill followed by
//! iterative neighbor-count smoothing.

use mlua::prelude::*;
use super::lcg::Lcg;
use crate::runtime::log_messages::{PG01_CELLULAR_START, PG02_CELLULAR_DONE};
use crate::log_msg;

/// Options for cellular automata generation.
///
/// # Fields
/// - `fill` — `f32`.
/// - `iterations` — `u32`.
/// - `birth` — `u32`.
/// - `survive` — `u32`.
/// - `seed` — `u64`.
#[derive(Debug, Clone)]
pub struct CellularOpts {
    /// Fill ratio for initial random placement (0.0 to 1.0).
    pub fill: f32,
    /// Number of smoothing iterations.
    pub iterations: u32,
    /// Minimum neighbor count to birth a new cell.
    pub birth: u32,
    /// Minimum neighbor count to survive.
    pub survive: u32,
    /// Random seed.
    pub seed: u64,
}

impl Default for CellularOpts {
    fn default() -> Self {
        Self {
            fill: 0.45,
            iterations: 5,
            birth: 6,
            survive: 4,
            seed: 12345,
        }
    }
}

impl CellularOpts {
    /// Constructs `CellularOpts` from a Lua table, using defaults for missing keys.
    ///
    /// # Parameters
    /// - `t` -- `&LuaTable`.
    ///
    /// # Returns
    /// `LuaResult<Self>`.
    pub fn from_lua_table(t: &LuaTable) -> LuaResult<Self> {
        let mut opts = Self::default();
        if let Ok(v) = t.get::<_, f32>("fill") { opts.fill = v; }
        if let Ok(v) = t.get::<_, u32>("iterations") { opts.iterations = v; }
        if let Ok(v) = t.get::<_, u32>("birth") { opts.birth = v; }
        if let Ok(v) = t.get::<_, u32>("survive") { opts.survive = v; }
        if let Ok(v) = t.get::<_, u64>("seed") { opts.seed = v; }
        Ok(opts)
    }
}

/// Generates a cave/dungeon map using cellular automata.
///
/// # Parameters
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `opts` — `&CellularOpts`.
///
/// # Returns
/// `Vec<u8>`.
///
/// Returns a flat `Vec<u8>` of size `width * height` where 1 = wall, 0 = open.
pub fn cellular_automata(width: u32, height: u32, opts: &CellularOpts) -> Vec<u8> {
    log_msg!(debug, PG01_CELLULAR_START, "{}x{}", width, height);
    let size = (width * height) as usize;
    let mut grid = vec![0u8; size];
    let mut rng = Lcg::new(opts.seed);

    // Initialize randomly
    for cell in grid.iter_mut() {
        *cell = if rng.next_f32() < opts.fill { 1 } else { 0 };
    }

    // Smoothing iterations
    let mut next = vec![0u8; size];
    for _ in 0..opts.iterations {
        for y in 0..height {
            for x in 0..width {
                let idx = (y * width + x) as usize;
                let mut neighbors = 0u32;

                for dy in -1i32..=1 {
                    for dx in -1i32..=1 {
                        if dx == 0 && dy == 0 {
                            continue;
                        }
                        let nx = x as i32 + dx;
                        let ny = y as i32 + dy;
                        if nx < 0 || ny < 0 || nx >= width as i32 || ny >= height as i32 {
                            neighbors += 1; // treat out-of-bounds as wall
                        } else {
                            neighbors += grid[(ny as u32 * width + nx as u32) as usize] as u32;
                        }
                    }
                }

                next[idx] = if grid[idx] == 1 {
                    if neighbors >= opts.survive {
                        1
                    } else {
                        0
                    }
                } else if neighbors >= opts.birth {
                    1
                } else {
                    0
                };
            }
        }
        std::mem::swap(&mut grid, &mut next);
    }

    log_msg!(debug, PG02_CELLULAR_DONE, "{}x{}", width, height);
    grid
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cellular_automata_size() {
        let grid = cellular_automata(20, 15, &CellularOpts::default());
        assert_eq!(grid.len(), 300);
        // Should contain both 0s and 1s
        assert!(grid.contains(&0));
        assert!(grid.contains(&1));
    }

    #[test]
    fn test_cellular_automata_deterministic() {
        let g1 = cellular_automata(
            10,
            10,
            &CellularOpts {
                seed: 42,
                ..Default::default()
            },
        );
        let g2 = cellular_automata(
            10,
            10,
            &CellularOpts {
                seed: 42,
                ..Default::default()
            },
        );
        assert_eq!(g1, g2);
    }
}
