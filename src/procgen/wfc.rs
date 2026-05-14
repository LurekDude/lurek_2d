//! Wave Function Collapse tile map generator for `src/procgen`.
//! Owns `WfcTile`, `WfcRules`, `WfcOpts`, `WfcGrid`, and `wfc_generate`.
//! Does not own dungeon room layout or noise maps — those live in `rooms.rs` and `noise.rs`.

use crate::procgen::lcg::Lcg;
use std::collections::HashMap;

/// A tile variant with an identifier and a sampling weight.
#[derive(Debug, Clone)]
pub struct WfcTile {
    /// Unique tile identifier referenced by `WfcRules` adjacency maps.
    pub id: u32,
    /// Relative probability weight used when collapsing a superposition; must be > 0.
    pub weight: f32,
}

/// Adjacency constraints between tile IDs.
#[derive(Debug, Clone, Default)]
pub struct WfcRules {
    /// Map from tile ID to the set of tile IDs that may appear in any neighbouring cell.
    /// When a tile ID has no entry, all other tiles are considered valid neighbours.
    pub adjacencies: HashMap<u32, Vec<u32>>,
}

/// Configuration for a WFC generation run.
#[derive(Debug, Clone)]
pub struct WfcOpts {
    /// Grid width in cells.
    pub width: u32,
    /// Grid height in cells.
    pub height: u32,
    /// Full set of available tile variants.
    pub tiles: Vec<WfcTile>,
    /// Adjacency rules applied during constraint propagation.
    pub rules: WfcRules,
    /// Base seed; each retry increments this to avoid repeating the same contradiction.
    pub seed: u64,
    /// Number of generation attempts before returning an all-`None` grid.
    pub max_attempts: u32,
}

/// Completed WFC grid; cells with no valid assignment are `None` (contradiction).
#[derive(Debug, Clone)]
pub struct WfcGrid {
    /// Grid width in cells.
    pub width: u32,
    /// Grid height in cells.
    pub height: u32,
    /// Flat row-major assignment results; `None` indicates unresolved contradiction.
    pub cells: Vec<Option<u32>>,
}

/// Run WFC on `opts`, retrying up to `max_attempts` times; returns a fully-assigned grid or all-`None` on failure.
pub fn wfc_generate(opts: &WfcOpts) -> WfcGrid {
    let n = (opts.width * opts.height) as usize;
    if opts.tiles.is_empty() || n == 0 {
        return WfcGrid {
            width: opts.width,
            height: opts.height,
            cells: vec![None; n],
        };
    }
    let all_ids: Vec<u32> = opts.tiles.iter().map(|t| t.id).collect();
    let weight_map: HashMap<u32, f32> = opts.tiles.iter().map(|t| (t.id, t.weight)).collect();
    for attempt in 0..opts.max_attempts.max(1) {
        let mut rng = Lcg::new(opts.seed.wrapping_add(attempt as u64));
        let mut wave: Vec<Vec<u32>> = vec![all_ids.clone(); n];
        let mut collapsed = vec![false; n];
        let mut result = vec![None; n];
        let mut failed = false;
        let idx = |x: u32, y: u32| (y * opts.width + x) as usize;
        loop {
            let chosen = (0..n)
                .filter(|&i| !collapsed[i] && !wave[i].is_empty())
                .min_by_key(|&i| wave[i].len());
            let Some(chosen_idx) = chosen else {
                break;
            };
            let total: f32 = wave[chosen_idx]
                .iter()
                .map(|id| weight_map.get(id).copied().unwrap_or(1.0))
                .sum();
            let mut pick = rng.next_f32() * total;
            let mut chosen_tile = wave[chosen_idx][0];
            for &tid in &wave[chosen_idx] {
                let w = weight_map.get(&tid).copied().unwrap_or(1.0);
                if pick <= w {
                    chosen_tile = tid;
                    break;
                }
                pick -= w;
            }
            wave[chosen_idx] = vec![chosen_tile];
            collapsed[chosen_idx] = true;
            result[chosen_idx] = Some(chosen_tile);
            let mut stack = vec![chosen_idx];
            while let Some(cur) = stack.pop() {
                let cx = (cur as u32) % opts.width;
                let cy = (cur as u32) / opts.width;
                let cur_possible = wave[cur].clone();
                let dirs: [(i32, i32); 4] = [(1, 0), (-1, 0), (0, 1), (0, -1)];
                for (dx, dy) in dirs {
                    let nx = cx as i32 + dx;
                    let ny = cy as i32 + dy;
                    if nx < 0 || ny < 0 || nx >= opts.width as i32 || ny >= opts.height as i32 {
                        continue;
                    }
                    let ni = idx(nx as u32, ny as u32);
                    if collapsed[ni] {
                        continue;
                    }
                    let allowed: Vec<u32> = wave[ni]
                        .iter()
                        .cloned()
                        .filter(|nb_tile| {
                            cur_possible.iter().any(|cur_tile| {
                                opts.rules
                                    .adjacencies
                                    .get(cur_tile)
                                    .is_none_or(|adj| adj.contains(nb_tile))
                            })
                        })
                        .collect();
                    if allowed.len() != wave[ni].len() {
                        if allowed.is_empty() {
                            failed = true;
                            break;
                        }
                        wave[ni] = allowed;
                        stack.push(ni);
                    }
                }
                if failed {
                    break;
                }
            }
            if failed {
                break;
            }
        }
        if !failed {
            return WfcGrid {
                width: opts.width,
                height: opts.height,
                cells: result,
            };
        }
    }
    WfcGrid {
        width: opts.width,
        height: opts.height,
        cells: vec![None; n],
    }
}
