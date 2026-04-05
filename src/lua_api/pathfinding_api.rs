//! `luna.pathfinding` Lua API bindings.
//!
//! Auto-generated skeleton from `src/pathfinding/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaFlowField ────────────────────────────────────────────────────────────

pub struct LuaFlowField(/* TODO: add key + state fields */);


impl LuaFlowField {
    /// Gets the normalized direction toward the goal for a cell (0-based).
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// @param x : integer
    /// @param y : integer
    pub fn get_direction(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Gets the BFS distance for a cell (0-based). Returns f32::INFINITY if unreachable.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return number
    pub fn get_distance(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the normalised direction vector at cell `(x, y)`.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `Returns`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return Returns
    /// Get the direction as an angle in radians (via `atan2`).
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return number
    pub fn get_direction_angle(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the integrated cost from cell `(x, y)` to the nearest target.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return number
    pub fn get_cost_to_target(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Whether the flow field has been computed at least once.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_calculated(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Target cells from the most recent computation.
    ///
    ///
    /// # Returns
    /// `Vec<(u32`.
    ///
    /// @return Vec<(u32
    pub fn get_targets(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaFlowField {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getDirection", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDistance", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDirection", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDirectionAngle", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCostToTarget", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isCalculated", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTargets", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaGrid ────────────────────────────────────────────────────────────

pub struct LuaGrid(/* TODO: add key + state fields */);


impl LuaGrid {
    /// Returns the grid width in cells. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the grid height in cells. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the cell at `(x, y)` is walkable.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return boolean
    pub fn is_walkable(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the movement cost of the cell at `(x, y)`.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return number
    pub fn get_cost(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Builds a flow field pointing toward `(gx, gy)`.
    ///
    ///
    /// # Parameters
    /// - `gx` — `integer` ...
    /// - `gy` — `integer` ...
    ///
    /// # Returns
    /// `Vec<(f32`.
    ///
    /// @param gx : integer
    /// @param gy : integer
    /// @return Vec<(f32
    pub fn build_flow_field(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaGrid {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("width", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("height", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isWalkable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCost", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("buildFlowField", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaInfluenceMap ────────────────────────────────────────────────────────────

pub struct LuaInfluenceMap(/* TODO: add key + state fields */);


impl LuaInfluenceMap {
    /// Returns whether a layer exists. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param name : str
    /// @return boolean
    pub fn has_layer(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Gets influence at a grid cell (0-based). Returns 0 for out-of-bounds.
    ///
    ///
    /// # Parameters
    /// - `layer` — `str` ...
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param layer : str
    /// @param x : integer
    /// @param y : integer
    /// @return number
    pub fn get_influence(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the world-space position of the cell with the highest value.
    ///
    ///
    /// # Parameters
    /// - `layer` — `str` ...
    ///
    /// @param layer : str
    pub fn max_position(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the world-space position of the cell with the lowest value.
    ///
    ///
    /// # Parameters
    /// - `layer` — `str` ...
    ///
    /// @param layer : str
    pub fn min_position(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Sums influence within a world-space rectangle.
    ///
    ///
    /// # Parameters
    /// - `layer` — `str` ...
    /// - `wx` — `number` ...
    /// - `wy` — `number` ...
    /// - `ww` — `number` ...
    /// - `wh` — `number` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param layer : str
    /// @param wx : number
    /// @param wy : number
    /// @param ww : number
    /// @param wh : number
    /// @return number
    pub fn query_rect(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaInfluenceMap {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("hasLayer", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getInfluence", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("maxPosition", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("minPosition", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("queryRect", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaNavGrid ────────────────────────────────────────────────────────────

pub struct LuaNavGrid(/* TODO: add key + state fields */);


impl LuaNavGrid {
    /// Grid width in cells. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Grid height in cells. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the traversal cost of cell `(x, y)`. Returns 0 for out-of-bounds.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `u8`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return u8
    pub fn get_cost(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if cell `(x, y)` is blocked (cost 0 or out-of-bounds).
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return boolean
    pub fn is_blocked(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Check whether an `NxN` unit footprint anchored at `(x, y)` is fully walkable.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    /// - `unit_size` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @param unit_size : integer
    /// @return boolean
    pub fn is_walkable(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Export the cost grid as a byte vector (row-major, one byte per cell).
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn save_to_bytes(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Current HPA* chunk size. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_chunk_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Current diagonal movement mode. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `DiagonalMode`.
    ///
    /// @return DiagonalMode
    pub fn get_diagonal_mode(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Return walkable neighbours of `(x, y)` respecting the current diagonal mode.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `Vec<(u32`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return Vec<(u32
    pub fn neighbors(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Create a lightweight clone suitable for use on another thread.
    ///
    ///
    /// # Returns
    /// `Self`.
    ///
    /// @return Self
    pub fn snapshot(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaNavGrid {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCost", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isBlocked", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isWalkable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("saveToBytes", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getChunkSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDiagonalMode", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("neighbors", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("snapshot", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaPathGrid ────────────────────────────────────────────────────────────

pub struct LuaPathGrid(/* TODO: add key + state fields */);


impl LuaPathGrid {
    /// Returns true if (x, y) is within grid bounds.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return boolean
    pub fn in_bounds(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether a cell is walkable (0-based coords).
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return boolean
    pub fn is_walkable(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Gets cost multiplier for a cell (0-based coords).
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return number
    pub fn get_cost(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// A★ search from (sx,sy) to (gx,gy) in 0-based grid coords.
    ///
    ///
    /// # Parameters
    /// - `sx` — `integer` ...
    /// - `sy` — `integer` ...
    /// - `gx` — `integer` ...
    /// - `gy` — `integer` ...
    ///
    /// # Returns
    /// `Option<Vec<(f32`.
    ///
    /// @param sx : integer
    /// @param sy : integer
    /// @param gx : integer
    /// @param gy : integer
    /// @return Option<Vec<(f32
    pub fn find_path(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the world-space center of cell (x, y).
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// @param x : integer
    /// @param y : integer
    pub fn cell_center(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaPathGrid {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("inBounds", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isWalkable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCost", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("findPath", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("cellCenter", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaPathThreadPool ────────────────────────────────────────────────────────────

pub struct LuaPathThreadPool(/* TODO: add key + state fields */);


impl LuaPathThreadPool {
    /// Collect all completed results without blocking.
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn poll(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Mark a request as cancelled (best-effort — may already be in progress).
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    ///
    /// @param id : integer
    pub fn cancel(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Number of requests submitted but not yet returned via [`poll`].
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn pending_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Current configured thread count. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_thread_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaPathThreadPool {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("poll", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("cancel", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("pendingCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getThreadCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaUnitPathfinder ────────────────────────────────────────────────────────────

pub struct LuaUnitPathfinder(/* TODO: add key + state fields */);


impl LuaUnitPathfinder {
    /// Sum of grid traversal costs along a path.
    ///
    ///
    /// # Parameters
    /// - `path` — `[Waypoint]` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param path : [Waypoint]
    /// @return number
    pub fn get_path_cost(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Quick connectivity check: can `(x2, y2)` be reached from `(x1, y1)`?
    ///
    ///
    /// # Parameters
    /// - `x1` — `integer` ...
    /// - `y1` — `integer` ...
    /// - `x2` — `integer` ...
    /// - `y2` — `integer` ...
    /// - `unit_size` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param x1 : integer
    /// @param y1 : integer
    /// @param x2 : integer
    /// @param y2 : integer
    /// @param unit_size : integer
    /// @return boolean
    pub fn is_reachable(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Line-of-sight check between two cells, respecting unit footprint.
    ///
    ///
    /// # Parameters
    /// - `x1` — `integer` ...
    /// - `y1` — `integer` ...
    /// - `x2` — `integer` ...
    /// - `y2` — `integer` ...
    /// - `unit_size` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param x1 : integer
    /// @param y1 : integer
    /// @param x2 : integer
    /// @param y2 : integer
    /// @param unit_size : integer
    /// @return boolean
    pub fn line_of_sight(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if caching is enabled. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_cache_enabled(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Number of entries currently in the cache.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_cache_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaUnitPathfinder {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getPathCost", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isReachable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("lineOfSight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isCacheEnabled", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCacheSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.pathfinding.* functions ──────────────────────────────────────────

/// Sets the goal cell and triggers BFS recomputation.
///
///
/// # Parameters
/// - `gx` — `integer` ...
/// - `gy` — `integer` ...
///
/// @param gx : integer
/// @param gy : integer
pub fn set_goal(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Run A★ search on `grid` from `start` to `goal`.
///
///
/// # Parameters
/// - `grid` — `NavGrid` ...
/// - `start` — `(u32, u32)` ...
/// - `goal` — `(u32, u32)` ...
/// - `unit_size` — `integer` ...
/// - `max_nodes` — `integer` ...
///
/// # Returns
/// `Returns`.
///
/// @param grid : NavGrid
/// @param start : (u32, u32)
/// @param goal : (u32, u32)
/// @param unit_size : integer
/// @param max_nodes : integer
/// @return Returns
pub fn astar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Check line-of-sight between two cells using Bresenham's algorithm,
///
///
/// # Parameters
/// - `grid` — `NavGrid` ...
/// - `x1` — `integer` ...
/// - `y1` — `integer` ...
/// - `x2` — `integer` ...
/// - `y2` — `integer` ...
/// - `unit_size` — `integer` ...
///
/// # Returns
/// `boolean`.
///
/// @param grid : NavGrid
/// @param x1 : integer
/// @param y1 : integer
/// @param x2 : integer
/// @param y2 : integer
/// @param unit_size : integer
/// @return boolean
pub fn line_of_sight(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Smooth a path by removing unnecessary waypoints via line-of-sight checks
///
///
/// # Parameters
/// - `grid` — `NavGrid` ...
/// - `path` — `[(u32, u32)]` ...
/// - `unit_size` — `integer` ...
///
/// # Returns
/// `Vec<(u32`.
///
/// @param grid : NavGrid
/// @param path : [(u32, u32)]
/// @param unit_size : integer
/// @return Vec<(u32
pub fn smooth_path(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Submit a pathfinding request. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `id` — `integer` ...
/// - `grid_snapshot` — `NavGrid` ...
/// - `start` — `(u32, u32)` ...
/// - `goal` — `(u32, u32)` ...
/// - `unit_size` — `integer` ...
///
/// @param id : integer
/// @param grid_snapshot : NavGrid
/// @param start : (u32, u32)
/// @param goal : (u32, u32)
/// @param unit_size : integer
pub fn submit(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Update the thread count. Takes effect on next pool creation only;
/// existing workers continue until the pool is dropped.
///
///
/// # Parameters
/// - `count` — `integer` ...
///
/// @param count : integer
pub fn set_thread_count(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Compute the flow field toward a single target cell.
///
///
/// # Parameters
/// - `target_x` — `integer` ...
/// - `target_y` — `integer` ...
/// - `unit_size` — `integer` ...
///
/// @param target_x : integer
/// @param target_y : integer
/// @param unit_size : integer
pub fn calculate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Compute the flow field toward multiple target cells simultaneously.
///
///
/// # Parameters
/// - `targets` — `[(u32, u32)]` ...
/// - `unit_size` — `integer` ...
///
/// @param targets : [(u32, u32)]
/// @param unit_size : integer
pub fn calculate_multi(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Convert a world-space position into a velocity vector.
///
///
/// # Parameters
/// - `world_x` — `number` ...
/// - `world_y` — `number` ...
/// - `speed` — `number` ...
/// - `tile_w` — `number` ...
/// - `tile_h` — `number` ...
///
/// # Returns
/// `tile_w`.
///
/// @param world_x : number
/// @param world_y : number
/// @param speed : number
/// @param tile_w : number
/// @param tile_h : number
/// @return tile_w
pub fn steer(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Find a path between two provinces using A* with centroid distance heuristic.
///
///
/// # Parameters
/// - `neighbors` — `HashMap<u32` ...
/// - `centroids` — `HashMap<u32` ...
///
/// # Returns
/// `ProvincePath?`.
///
/// @param neighbors : HashMap<u32
/// @param centroids : HashMap<u32
/// @return ProvincePath?
pub fn find_province_path(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Find all provinces reachable from `start` within a cost budget using Dijkstra.
///
/// Returns a map of `province_id → cost_to_reach` for all reachable provinces
/// (including `start` at cost 0).
///
///
/// # Parameters
/// - `neighbors` — `HashMap<u32` ...
/// - `edge_tags` — `HashMap<(u32` ...
///
/// # Returns
/// `HashMap<u32`.
///
/// @param neighbors : HashMap<u32
/// @param edge_tags : HashMap<(u32
/// @return HashMap<u32
pub fn province_reachable(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets whether the cell at `(x, y)` is walkable.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `walkable` — `boolean` ...
///
/// @param x : integer
/// @param y : integer
/// @param walkable : boolean
pub fn set_walkable(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the movement cost of the cell at `(x, y)`.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `cost` — `number` ...
///
/// @param x : integer
/// @param y : integer
/// @param cost : number
pub fn set_cost(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Finds a path from `(sx, sy)` to `(gx, gy)` using A*.
///
///
/// # Parameters
/// - `sx` — `integer` ...
/// - `sy` — `integer` ...
/// - `gx` — `integer` ...
/// - `gy` — `integer` ...
/// - `diagonal` — `boolean` ...
///
/// # Returns
/// `Option<Vec<(u32`.
///
/// @param sx : integer
/// @param sy : integer
/// @param gx : integer
/// @param gy : integer
/// @param diagonal : boolean
/// @return Option<Vec<(u32
pub fn find_path_astar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Finds a path from `(sx, sy)` to `(gx, gy)` using Dijkstra's algorithm.
///
///
/// # Parameters
/// - `sx` — `integer` ...
/// - `sy` — `integer` ...
/// - `gx` — `integer` ...
/// - `gy` — `integer` ...
/// - `diagonal` — `boolean` ...
///
/// # Returns
/// `Option<Vec<(u32`.
///
/// @param sx : integer
/// @param sy : integer
/// @param gx : integer
/// @param gy : integer
/// @param diagonal : boolean
/// @return Option<Vec<(u32
pub fn find_path_dijkstra(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Finds a shortest-hop path from `(sx, sy)` to `(gx, gy)` using BFS.
///
///
/// # Parameters
/// - `sx` — `integer` ...
/// - `sy` — `integer` ...
/// - `gx` — `integer` ...
/// - `gy` — `integer` ...
/// - `diagonal` — `boolean` ...
///
/// # Returns
/// `Option<Vec<(u32`.
///
/// @param sx : integer
/// @param sy : integer
/// @param gx : integer
/// @param gy : integer
/// @param diagonal : boolean
/// @return Option<Vec<(u32
pub fn find_path_bfs(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Build the abstract graph from a `NavGrid`.
///
///
/// # Parameters
/// - `grid` — `NavGrid` ...
/// - `chunk_size` — `integer` ...
///
/// # Returns
/// `AbstractGraph`.
///
/// @param grid : NavGrid
/// @param chunk_size : integer
/// @return AbstractGraph
pub fn build_abstract(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Run HPA★ from `start` to `goal` on the abstract graph, then refine to tiles.
///
///
/// # Parameters
/// - `grid` — `NavGrid` ...
/// - `abstract_graph` — `AbstractGraph` ...
/// - `start` — `(u32, u32)` ...
/// - `goal` — `(u32, u32)` ...
/// - `unit_size` — `integer` ...
///
/// # Returns
/// `Option<Vec<(u32`.
///
/// @param grid : NavGrid
/// @param abstract_graph : AbstractGraph
/// @param start : (u32, u32)
/// @param goal : (u32, u32)
/// @param unit_size : integer
/// @return Option<Vec<(u32
pub fn hpa_star(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Check if `goal` is reachable from `start` using the abstract graph.
///
///
/// # Parameters
/// - `abstract_graph` — `AbstractGraph` ...
/// - `start` — `(u32, u32)` ...
/// - `goal` — `(u32, u32)` ...
///
/// # Returns
/// `boolean`.
///
/// @param abstract_graph : AbstractGraph
/// @param start : (u32, u32)
/// @param goal : (u32, u32)
/// @return boolean
pub fn is_reachable(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a new named layer initialized to zero.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// @param name : str
pub fn add_layer(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets influence at a grid cell (0-based).
///
///
/// # Parameters
/// - `layer` — `str` ...
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `value` — `number` ...
///
/// @param layer : str
/// @param x : integer
/// @param y : integer
/// @param value : number
pub fn set_influence(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Stamps circular influence in world-space coordinates with linear falloff.
///
///
/// # Parameters
/// - `layer` — `str` ...
/// - `wx` — `number` ...
/// - `wy` — `number` ...
/// - `radius` — `number` ...
/// - `value` — `number` ...
/// - `falloff` — `number` ...
///
/// @param layer : str
/// @param wx : number
/// @param wy : number
/// @param radius : number
/// @param value : number
/// @param falloff : number
pub fn stamp_influence(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// 3×3 averaging diffusion. newVal = old * momentum + avg * (1 - momentum).
///
///
/// # Parameters
/// - `layer` — `str` ...
/// - `momentum` — `number` ...
///
/// @param layer : str
/// @param momentum : number
pub fn propagate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Multiplies every cell in a layer by the decay factor.
///
///
/// # Parameters
/// - `layer` — `str` ...
/// - `factor` — `number` ...
///
/// @param layer : str
/// @param factor : number
pub fn decay(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Clears all cells in a layer to zero.
///
///
/// # Parameters
/// - `layer` — `str` ...
///
/// @param layer : str
pub fn clear_layer(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Blends two layers into a destination: dest = wA * A + wB * B.
///
///
/// # Parameters
/// - `layer_a` — `str` ...
/// - `weight_a` — `number` ...
/// - `layer_b` — `str` ...
/// - `weight_b` — `number` ...
/// - `dest` — `str` ...
///
/// @param layer_a : str
/// @param weight_a : number
/// @param layer_b : str
/// @param weight_b : number
/// @param dest : str
pub fn blend(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse a Lua string into a `DiagonalMode`.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Self?`.
///
/// @param s : str
/// @return Self?
pub fn from_lua_str(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a grid from a pre-built cost array.
///
///
/// # Parameters
/// - `width` — `integer` ...
/// - `height` — `integer` ...
/// - `costs` — `table` ...
///
/// # Returns
/// `Self`.
///
/// @param width : integer
/// @param height : integer
/// @param costs : table
/// @return Self
pub fn from_costs(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the traversal cost of cell `(x, y)`. No-op for out-of-bounds.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `cost` — `u8` ...
///
/// @param x : integer
/// @param y : integer
/// @param cost : u8
/// Mark cell `(x, y)` as blocked (cost 0) or unblocked (cost 1).
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `blocked` — `boolean` ...
///
/// @param x : integer
/// @param y : integer
/// @param blocked : boolean
pub fn set_blocked(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set every cell to `cost`. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `cost` — `u8` ...
///
/// @param cost : u8
pub fn fill(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set all cells in the rectangle `(x, y, w, h)` to `cost`, clamped to grid bounds.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `w` — `integer` ...
/// - `h` — `integer` ...
/// - `cost` — `u8` ...
///
/// @param x : integer
/// @param y : integer
/// @param w : integer
/// @param h : integer
/// @param cost : u8
pub fn fill_rect(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Overwrite the grid from a raw byte slice (row-major, one byte per cell).
///
///
/// # Parameters
/// - `data` — `[u8]` ...
///
/// # Returns
/// `Result<()`.
///
/// @param data : [u8]
/// @return Result<()
pub fn load_from_bytes(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the HPA* chunk size (clamped to `[2, min(width, height)]`).
///
///
/// # Parameters
/// - `size` — `integer` ...
///
/// @param size : integer
pub fn set_chunk_size(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the diagonal movement mode. Replaces the current diagonal mode value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `mode` — `DiagonalMode` ...
///
/// @param mode : DiagonalMode
pub fn set_diagonal_mode(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Record a dirty rectangle `(x, y, w, h)` for incremental HPA* updates.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `w` — `integer` ...
/// - `h` — `integer` ...
///
/// @param x : integer
/// @param y : integer
/// @param w : integer
/// @param h : integer
pub fn set_dirty(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets walkability for a cell (0-based coords).
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `walkable` — `boolean` ...
///
/// @param x : integer
/// @param y : integer
/// @param walkable : boolean
/// Sets cost multiplier for a cell (0-based coords).
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `cost` — `number` ...
///
/// @param x : integer
/// @param y : integer
/// @param cost : number
/// A★ + string-pulling (greedy LOS post-processing).
///
///
/// # Parameters
/// - `sx` — `integer` ...
/// - `sy` — `integer` ...
/// - `gx` — `integer` ...
/// - `gy` — `integer` ...
///
/// # Returns
/// `Option<Vec<(f32`.
///
/// @param sx : integer
/// @param sy : integer
/// @param gx : integer
/// @param gy : integer
/// @return Option<Vec<(f32
pub fn find_path_smoothed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Find a path from `(x1, y1)` to `(x2, y2)` for a `unit_size×unit_size` unit.
///
///
/// # Parameters
/// - `x1` — `integer` ...
/// - `y1` — `integer` ...
/// - `x2` — `integer` ...
/// - `y2` — `integer` ...
/// - `unit_size` — `integer` ...
///
/// # Returns
/// `table?`.
///
/// @param x1 : integer
/// @param y1 : integer
/// @param x2 : integer
/// @param y2 : integer
/// @param unit_size : integer
/// @return table?
pub fn find_path(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Find a path and apply Theta★ line-of-sight smoothing.
///
///
/// # Parameters
/// - `x1` — `integer` ...
/// - `y1` — `integer` ...
/// - `x2` — `integer` ...
/// - `y2` — `integer` ...
/// - `unit_size` — `integer` ...
///
/// # Returns
/// `table?`.
///
/// @param x1 : integer
/// @param y1 : integer
/// @param x2 : integer
/// @param y2 : integer
/// @param unit_size : integer
/// @return table?
pub fn find_path_smooth(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sum of euclidean distances between consecutive waypoints.
///
///
/// # Parameters
/// - `path` — `[Waypoint]` ...
///
/// # Returns
/// `number`.
///
/// @param path : [Waypoint]
/// @return number
pub fn get_path_length(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Search with a node expansion limit; returns `(path, complete)`.
///
///
/// # Parameters
/// - `x1` — `integer` ...
/// - `y1` — `integer` ...
/// - `x2` — `integer` ...
/// - `y2` — `integer` ...
/// - `max_nodes` — `integer` ...
/// - `unit_size` — `integer` ...
///
/// # Returns
/// `If`.
///
/// @param x1 : integer
/// @param y1 : integer
/// @param x2 : integer
/// @param y2 : integer
/// @param max_nodes : integer
/// @param unit_size : integer
/// @return If
pub fn find_partial_path(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Find the nearest walkable cell within `max_radius` of `(x, y)` using BFS.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `max_radius` — `integer` ...
/// - `unit_size` — `integer` ...
///
/// # Returns
/// `Option<(u32`.
///
/// @param x : integer
/// @param y : integer
/// @param max_radius : integer
/// @param unit_size : integer
/// @return Option<(u32
pub fn find_nearest_walkable(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Octile heuristic distance between two points.
///
///
/// # Parameters
/// - `x1` — `integer` ...
/// - `y1` — `integer` ...
/// - `x2` — `integer` ...
/// - `y2` — `integer` ...
///
/// # Returns
/// `number`.
///
/// @param x1 : integer
/// @param y1 : integer
/// @param x2 : integer
/// @param y2 : integer
/// @return number
pub fn heuristic_distance(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Enable or disable path caching. Replaces the current cache enabled value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `enabled` — `boolean` ...
///
/// @param enabled : boolean
pub fn set_cache_enabled(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the maximum cache size. Evicts oldest entries if over the new limit.
///
///
/// # Parameters
/// - `max_size` — `integer` ...
///
/// @param max_size : integer
pub fn set_cache_max_size(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.pathfinding` API table.
///
/// # Parameters
/// - `lua` — `&Lua` The Lua VM.
/// - `luna` — `&LuaTable<'_>` The top-level `luna` table.
/// - `state` — `Rc<RefCell<SharedState>>` Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("setGoal", lua.create_function(set_goal)?)?;
    tbl.set("astar", lua.create_function(astar)?)?;
    tbl.set("lineOfSight", lua.create_function(line_of_sight)?)?;
    tbl.set("smoothPath", lua.create_function(smooth_path)?)?;
    tbl.set("submit", lua.create_function(submit)?)?;
    tbl.set("setThreadCount", lua.create_function(set_thread_count)?)?;
    tbl.set("calculate", lua.create_function(calculate)?)?;
    tbl.set("calculateMulti", lua.create_function(calculate_multi)?)?;
    tbl.set("steer", lua.create_function(steer)?)?;
    tbl.set("findProvincePath", lua.create_function(find_province_path)?)?;
    tbl.set("provinceReachable", lua.create_function(province_reachable)?)?;
    tbl.set("setWalkable", lua.create_function(set_walkable)?)?;
    tbl.set("setCost", lua.create_function(set_cost)?)?;
    tbl.set("findPathAstar", lua.create_function(find_path_astar)?)?;
    tbl.set("findPathDijkstra", lua.create_function(find_path_dijkstra)?)?;
    tbl.set("findPathBfs", lua.create_function(find_path_bfs)?)?;
    tbl.set("buildAbstract", lua.create_function(build_abstract)?)?;
    tbl.set("hpaStar", lua.create_function(hpa_star)?)?;
    tbl.set("isReachable", lua.create_function(is_reachable)?)?;
    tbl.set("addLayer", lua.create_function(add_layer)?)?;
    tbl.set("setInfluence", lua.create_function(set_influence)?)?;
    tbl.set("stampInfluence", lua.create_function(stamp_influence)?)?;
    tbl.set("propagate", lua.create_function(propagate)?)?;
    tbl.set("decay", lua.create_function(decay)?)?;
    tbl.set("clearLayer", lua.create_function(clear_layer)?)?;
    tbl.set("blend", lua.create_function(blend)?)?;
    tbl.set("fromLuaStr", lua.create_function(from_lua_str)?)?;
    tbl.set("fromCosts", lua.create_function(from_costs)?)?;
    tbl.set("setCost", lua.create_function(set_cost)?)?;
    tbl.set("setBlocked", lua.create_function(set_blocked)?)?;
    tbl.set("fill", lua.create_function(fill)?)?;
    tbl.set("fillRect", lua.create_function(fill_rect)?)?;
    tbl.set("loadFromBytes", lua.create_function(load_from_bytes)?)?;
    tbl.set("setChunkSize", lua.create_function(set_chunk_size)?)?;
    tbl.set("setDiagonalMode", lua.create_function(set_diagonal_mode)?)?;
    tbl.set("setDirty", lua.create_function(set_dirty)?)?;
    tbl.set("setWalkable", lua.create_function(set_walkable)?)?;
    tbl.set("setCost", lua.create_function(set_cost)?)?;
    tbl.set("findPathSmoothed", lua.create_function(find_path_smoothed)?)?;
    tbl.set("findPath", lua.create_function(find_path)?)?;
    tbl.set("findPathSmooth", lua.create_function(find_path_smooth)?)?;
    tbl.set("getPathLength", lua.create_function(get_path_length)?)?;
    tbl.set("findPartialPath", lua.create_function(find_partial_path)?)?;
    tbl.set("findNearestWalkable", lua.create_function(find_nearest_walkable)?)?;
    tbl.set("heuristicDistance", lua.create_function(heuristic_distance)?)?;
    tbl.set("setCacheEnabled", lua.create_function(set_cache_enabled)?)?;
    tbl.set("setCacheMaxSize", lua.create_function(set_cache_max_size)?)?;
    luna.set("pathfinding", tbl)?;
    Ok(())
}
