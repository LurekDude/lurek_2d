//! `lurek.procgen` — Stateless procedural generation utilities.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::procgen::{
    cellular_automata, flood_fill, perlin_noise_periodic, poisson_disk, voronoi_diagram,
    CellularOpts, VoronoiOpts,
};

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.procgen` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`. The Lua VM.
/// - `luna` — `&LuaTable`. The top-level `luna` table to register into.
/// - `state` — `Rc<RefCell<SharedState>>`. Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- cellularAutomata --
    /// Generates a cave-like map using cellular automata.
    /// @param w : integer
    /// @param h : integer
    /// @param opts : table?
    /// @return table
    tbl.set(
        "cellularAutomata",
        lua.create_function(|lua, (w, h, opts): (u32, u32, Option<LuaTable>)| {
            let cfg = opts.map(|t| CellularOpts::from_lua_table(&t)).transpose()?.unwrap_or_default();
            let data = cellular_automata(w, h, &cfg);
            let out = lua.create_table()?;
            for (i, v) in data.iter().enumerate() {
                out.set(i + 1, *v)?;
            }
            Ok(out)
        })?,
    )?;

    // -- floodFill --
    /// BFS flood fill on a flat grid of bytes.
    /// @param data : table
    /// @param w : integer
    /// @param h : integer
    /// @param sx : integer
    /// @param sy : integer
    /// @param threshold : integer?
    /// @param above : boolean?
    /// @return table
    tbl.set(
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
                let result = flood_fill(&data, w, h, sx, sy, threshold.unwrap_or(128), above.unwrap_or(false));
                let out = lua.create_table()?;
                for (i, v) in result.iter().enumerate() {
                    out.set(i + 1, *v)?;
                }
                Ok(out)
            },
        )?,
    )?;

    // -- perlinNoise --
    /// Evaluates periodic Perlin noise at a point.
    /// @param x : number
    /// @param y : number
    /// @param px : number
    /// @param py : number
    /// @return number
    tbl.set(
        "perlinNoise",
        lua.create_function(|_, (x, y, px, py): (f64, f64, f64, f64)| {
            Ok(perlin_noise_periodic(x, y, px, py))
        })?,
    )?;

    // -- poissonDisk --
    /// Generates Poisson disk sample points using Bridson's algorithm.
    /// @param w : number
    /// @param h : number
    /// @param min_dist : number
    /// @param max_attempts : integer?
    /// @param seed : integer?
    /// @return table
    tbl.set(
        "poissonDisk",
        lua.create_function(
            |lua, (w, h, min_dist, max_attempts, seed): (f32, f32, f32, Option<u32>, Option<u64>)| {
                let points = poisson_disk(w, h, min_dist, max_attempts.unwrap_or(30), seed.unwrap_or(0));
                let out = lua.create_table()?;
                for (i, (px, py)) in points.iter().enumerate() {
                    let pt = lua.create_table()?;
                    pt.set("x", *px)?;
                    pt.set("y", *py)?;
                    out.set(i + 1, pt)?;
                }
                Ok(out)
            },
        )?,
    )?;

    // -- voronoi --
    /// Generates a Voronoi diagram for a set of seed points.
    /// @param w : integer
    /// @param h : integer
    /// @param pts : table
    /// @param opts : table?
    /// @return table, table, table
    tbl.set(
        "voronoi",
        lua.create_function(
            |lua, (w, h, pts_tbl, opts_tbl): (u32, u32, LuaTable, Option<LuaTable>)| {
                let mut points: Vec<(f32, f32)> = Vec::new();
                for v in pts_tbl.sequence_values::<LuaTable>() {
                    let pt = v?;
                    let x: f32 = pt.get("x")?;
                    let y: f32 = pt.get("y")?;
                    points.push((x, y));
                }
                let vopts = opts_tbl.map(|t| VoronoiOpts::from_lua_table(&t)).transpose()?.unwrap_or_default();
                let (regions, distances, distances2) = voronoi_diagram(w, h, &points, &vopts);
                let r_tbl = lua.create_table()?;
                let d_tbl = lua.create_table()?;
                let d2_tbl = lua.create_table()?;
                for (i, ((r, d), d2)) in regions.iter().zip(distances.iter()).zip(distances2.iter()).enumerate() {
                    r_tbl.set(i + 1, *r + 1)?;
                    d_tbl.set(i + 1, *d)?;
                    d2_tbl.set(i + 1, *d2)?;
                }
                Ok((r_tbl, d_tbl, d2_tbl))
            },
        )?,
    )?;

    luna.set("procgen", tbl)?;
    Ok(())
}
