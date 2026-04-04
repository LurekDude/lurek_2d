//! Registers the `luna.procgen` namespace.
//!
//! Exposes stateless procedural generation utilities: cellular-automata
//! cave maps, BFS flood fill, Poisson disk sampling, periodic Perlin noise,
//! and Voronoi diagrams.
//!
//! This module is part of Luna2D's `lua_api` subsystem.
//! Primary functions: `register()`.

use mlua::prelude::*;

use crate::procgen::{
    cellular_automata, flood_fill, perlin_noise_periodic, poisson_disk, voronoi_diagram,
    CellularOpts, VoronoiOpts,
};

// ── Registration ──────────────────────────────────────────────────────────────

/// Registers the `luna.procgen` namespace into the given `luna` table.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let pg = lua.create_table()?;

    // ── cellular_automata ─────────────────────────────────────────────────

    /// Generates a cave-like map using cellular automata.
    ///
    /// `opts` fields (all optional):
    /// - `fill`       — `number`  Initial fill probability 0–1 (default 0.45).
    /// - `iterations` — `number`  Smoothing iterations (default 5).
    /// - `birth`      — `number`  Live-cell birth threshold (default 4).
    /// - `survive`    — `number`  Live-cell survival threshold (default 3).
    /// - `seed`       — `number`  Random seed (default 0).
    ///
    /// Returns a flat Lua table of `w * h` bytes (0 = empty, 1 = wall).
    /// @param w    number  Grid width.
    /// @param h    number  Grid height.
    /// @param opts table   (optional)
    /// @return table
    pg.set(
        "cellularAutomata",
        lua.create_function(|lua, (w, h, opts): (u32, u32, Option<LuaTable>)| {
            let mut cfg = CellularOpts::default();
            if let Some(tbl) = opts {
                if let Ok(v) = tbl.get::<_, f32>("fill") { cfg.fill = v; }
                if let Ok(v) = tbl.get::<_, u32>("iterations") { cfg.iterations = v; }
                if let Ok(v) = tbl.get::<_, u32>("birth") { cfg.birth = v; }
                if let Ok(v) = tbl.get::<_, u32>("survive") { cfg.survive = v; }
                if let Ok(v) = tbl.get::<_, u64>("seed") { cfg.seed = v; }
            }
            let data = cellular_automata(w, h, &cfg);
            let tbl = lua.create_table()?;
            for (i, v) in data.iter().enumerate() {
                tbl.set(i + 1, *v)?;
            }
            Ok(tbl)
        })?,
    )?;

    // ── flood_fill ────────────────────────────────────────────────────────

    /// BFS flood fill on a flat grid of bytes.
    ///
    /// Returns a flat Lua table (same size as `data`) with 1 for filled cells
    /// and 0 for unfilled cells.
    ///
    /// @param data      table   Flat grid of byte values (1-based).
    /// @param w         number  Grid width.
    /// @param h         number  Grid height.
    /// @param sx        number  Seed column (0-based).
    /// @param sy        number  Seed row    (0-based).
    /// @param threshold number  Fill boundary value (default 128).
    /// @param above     boolean If true fill cells >= threshold; else <= threshold (default false).
    /// @return table
    pg.set(
        "floodFill",
        lua.create_function(
            |lua,
             (data_tbl, w, h, sx, sy, threshold, above): (
                LuaTable,
                u32,
                u32,
                u32,
                u32,
                Option<u8>,
                Option<bool>,
            )| {
                let mut data: Vec<u8> = Vec::with_capacity((w * h) as usize);
                for v in data_tbl.sequence_values::<u8>() {
                    data.push(v?);
                }
                let threshold = threshold.unwrap_or(128);
                let above = above.unwrap_or(false);
                let result = flood_fill(&data, w, h, sx, sy, threshold, above);
                let tbl = lua.create_table()?;
                for (i, v) in result.iter().enumerate() {
                    tbl.set(i + 1, *v)?;
                }
                Ok(tbl)
            },
        )?,
    )?;

    // ── perlin_noise ──────────────────────────────────────────────────────

    /// Evaluates a single periodic Perlin noise value at `(x, y)`.
    ///
    /// `px` and `py` are the tile periods — the noise wraps seamlessly when
    /// coordinates advance by one period.
    ///
    /// @param x  number
    /// @param y  number
    /// @param px number  X period (tile width in noise space).
    /// @param py number  Y period (tile height in noise space).
    /// @return number  Value in [-1, 1].
    pg.set(
        "perlinNoise",
        lua.create_function(
            |_, (x, y, px, py): (f64, f64, f64, f64)| {
                Ok(perlin_noise_periodic(x, y, px, py))
            },
        )?,
    )?;

    // ── poisson_disk ──────────────────────────────────────────────────────

    /// Generates Poisson disk sample points using Bridson's algorithm.
    ///
    /// Returns a Lua table of `{x, y}` point tables.
    ///
    /// @param w           number  Domain width.
    /// @param h           number  Domain height.
    /// @param min_dist    number  Minimum distance between any two points.
    /// @param max_attempts number (default 30) Candidates per active point.
    /// @param seed        number  (default 0) Random seed.
    /// @return table
    pg.set(
        "poissonDisk",
        lua.create_function(
            |lua, (w, h, min_dist, max_attempts, seed): (f32, f32, f32, Option<u32>, Option<u64>)| {
                let max_attempts = max_attempts.unwrap_or(30);
                let seed = seed.unwrap_or(0);
                let points = poisson_disk(w, h, min_dist, max_attempts, seed);
                let tbl = lua.create_table()?;
                for (i, (px, py)) in points.iter().enumerate() {
                    let pt = lua.create_table()?;
                    pt.set("x", *px)?;
                    pt.set("y", *py)?;
                    tbl.set(i + 1, pt)?;
                }
                Ok(tbl)
            },
        )?,
    )?;

    // ── voronoi ───────────────────────────────────────────────────────────

    /// Generates a Voronoi diagram for a set of seed points.
    ///
    /// `pts` is a Lua array of `{x, y}` tables (seed points).
    ///
    /// `opts` fields (all optional):
    /// - `warp_scale`    — `number`  Warp noise frequency (default 0.1).
    /// - `warp_strength` — `number`  Warp noise amplitude; 0 = no warp (default 0).
    /// - `seed`          — `number`  Seed for warp noise (default 0).
    ///
    /// Returns three flat tables of size `w * h`:
    /// - `regions`   — `u32` index of the closest seed point.
    /// - `dist`      — `f32` distance to the closest seed.
    /// - `dist2`     — `f32` distance to the second-closest seed.
    ///
    /// @param w    number
    /// @param h    number
    /// @param pts  table
    /// @param opts table  (optional)
    /// @return table, table, table
    pg.set(
        "voronoi",
        lua.create_function(
            |lua,
             (w, h, pts_tbl, opts_tbl): (u32, u32, LuaTable, Option<LuaTable>)| {
                let mut points: Vec<(f32, f32)> = Vec::new();
                for v in pts_tbl.sequence_values::<LuaTable>() {
                    let pt = v?;
                    let x: f32 = pt.get("x")?;
                    let y: f32 = pt.get("y")?;
                    points.push((x, y));
                }
                let mut opts = VoronoiOpts::default();
                if let Some(ot) = opts_tbl {
                    if let Ok(v) = ot.get::<_, f32>("warp_scale") { opts.warp_scale = v; }
                    if let Ok(v) = ot.get::<_, f32>("warp_strength") { opts.warp_strength = v; }
                    if let Ok(v) = ot.get::<_, u64>("seed") { opts.seed = v; }
                }
                let (regions, distances, distances2) = voronoi_diagram(w, h, &points, &opts);

                let r_tbl = lua.create_table()?;
                let d_tbl = lua.create_table()?;
                let d2_tbl = lua.create_table()?;
                for (i, ((r, d), d2)) in regions
                    .iter()
                    .zip(distances.iter())
                    .zip(distances2.iter())
                    .enumerate()
                {
                    r_tbl.set(i + 1, *r)?;
                    d_tbl.set(i + 1, *d)?;
                    d2_tbl.set(i + 1, *d2)?;
                }
                Ok((r_tbl, d_tbl, d2_tbl))
            },
        )?,
    )?;

    luna.set("procgen", pg)?;
    Ok(())
}
