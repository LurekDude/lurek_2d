//! `luna.procgen` Lua API bindings.
//!
//! Auto-generated skeleton from `src/procgen/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::SharedState;

// ── luna.procgen.* functions ──────────────────────────────────────────

/// Generates a cave/dungeon map using cellular automata.
///
/// @param width : integer
/// @param height : integer
/// @param opts : CellularOpts
/// @return table
pub fn cellular_automata(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// BFS flood fill on a grid. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param data : [u8]
/// @param width : integer
/// @param height : integer
/// @param sx : integer
/// @param sy : integer
/// @param threshold : u8
/// @param above : boolean
/// @return table
pub fn flood_fill(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Periodic Perlin noise that tiles over period (px, py).
///
/// @param x : number
/// @param y : number
/// @param px : number
/// @param py : number
/// @return number
pub fn perlin_noise_periodic(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Generates Poisson disk sample points using Bridson's algorithm.
///
/// @param width : number
/// @param height : number
/// @param min_dist : number
/// @param max_attempts : integer
/// @param seed : integer
/// @return Vec<(f32
pub fn poisson_disk(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Generates a Voronoi diagram. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param width : integer
/// @param height : integer
/// @param points : [(f32, f32)]
/// @param opts : VoronoiOpts
/// @return Returns
pub fn voronoi_diagram(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.procgen` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("cellularAutomata", lua.create_function(cellular_automata)?)?;
    tbl.set("floodFill", lua.create_function(flood_fill)?)?;
    tbl.set("perlinNoisePeriodic", lua.create_function(perlin_noise_periodic)?)?;
    tbl.set("poissonDisk", lua.create_function(poisson_disk)?)?;
    tbl.set("voronoiDiagram", lua.create_function(voronoi_diagram)?)?;
    luna.set("procgen", tbl)?;
    Ok(())
}
