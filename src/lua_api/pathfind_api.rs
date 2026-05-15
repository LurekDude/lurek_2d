//! `lurek.pathfind` - Lua bindings for navigation grids, unit pathfinding, flow fields, path grids, hex grids, JPS grids, nav meshes, range maps, and tilemap-derived path data.

use super::tilemap_api::LuaTileMap;
use super::SharedState;
use crate::log_msg;
use crate::pathfind::ai_flow_field::FlowField as AiFlowField;
use crate::pathfind::hpa::{build_abstract, AbstractGraph};
use crate::pathfind::pathgrid::PathGrid;
use crate::pathfind::{
    bidirectional_astar, DiagonalMode, FlowField, NavGrid, NavMesh, UnitPathfinder, Waypoint,
};
use crate::pathfind::{HexGrid, HexLayout, JpsGrid, RangeMap};
use crate::runtime::log_messages::LA08_PATHFINDING_THREAD_UNIMPL;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
/// Converts zero-based Rust waypoints into one-based Lua point tables.
fn waypoints_to_lua<'a>(lua: &'a Lua, path: &[Waypoint]) -> LuaResult<LuaTable<'a>> {
    let tbl = lua.create_table()?;
    for (i, wp) in path.iter().enumerate() {
        let entry = lua.create_table()?;
        entry.set("x", wp.x + 1)?;
        entry.set("y", wp.y + 1)?;
        tbl.set(i + 1, entry)?;
    }
    Ok(tbl)
}
/// Converts one-based Lua point tables into zero-based Rust waypoints.
fn lua_to_waypoints(tbl: &LuaTable) -> LuaResult<Vec<Waypoint>> {
    let mut waypoints = Vec::new();
    for pair in tbl.clone().sequence_values::<LuaTable>() {
        let entry = pair?;
        let x: u32 = entry.get("x")?;
        let y: u32 = entry.get("y")?;
        waypoints.push(Waypoint { x: x - 1, y: y - 1 });
    }
    Ok(waypoints)
}
/// Lua-side wrapper for a navigation grid and optional abstract graph cache.
pub struct LuaNavGrid {
    /// Shared navigation grid data.
    inner: Rc<RefCell<NavGrid>>,
    /// Optional abstract graph built for hierarchical pathfinding.
    abstract_graph: Rc<RefCell<Option<AbstractGraph>>>,
}
/// Provides Lua methods for navigation grid dimensions, costs, blocking, serialization, dirty regions, and diagonal mode.
impl LuaUserData for LuaNavGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns grid width. This method is available to Lua scripts.
        /// @return | integer | Grid width.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });
        // -- getHeight --
        /// Returns grid height. This method is available to Lua scripts.
        /// @return | integer | Grid height.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });
        // -- getDimensions --
        /// Returns grid dimensions. This method is available to Lua scripts.
        /// @return | integer | Grid width.
        /// @return | integer | Grid height.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_dimensions())
        });
        // -- setCost --
        /// Sets movement cost at a one-based grid cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @param | cost | u8 | Lua argument for `cost`.
        /// @return | nil | No value is returned.
        methods.add_method("setCost", |_, this, (x, y, cost): (u32, u32, u8)| {
            this.inner.borrow_mut().set_cost(x - 1, y - 1, cost);
            Ok(())
        });
        // -- getCost --
        /// Returns movement cost at a one-based grid cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | integer | Movement cost.
        methods.add_method("getCost", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cost(x - 1, y - 1))
        });
        // -- setBlocked --
        /// Sets blocked state at a one-based grid cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @param | blocked | boolean | Lua argument for `blocked`.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setBlocked",
            |_, this, (x, y, blocked): (u32, u32, bool)| {
                this.inner.borrow_mut().set_blocked(x - 1, y - 1, blocked);
                Ok(())
            },
        );
        // -- isBlocked --
        /// Returns blocked state at a one-based grid cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | boolean | True when blocked.
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(x - 1, y - 1))
        });
        // -- isWalkable --
        /// Returns whether a one-based grid cell is walkable for a unit size.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @param | unit_size | integer? | Lua argument for `unit_size`.
        /// @return | boolean | True when walkable.
        methods.add_method(
            "isWalkable",
            |_, this, (x, y, unit_size): (u32, u32, Option<u32>)| {
                Ok(this
                    .inner
                    .borrow()
                    .is_walkable(x - 1, y - 1, unit_size.unwrap_or(1)))
            },
        );
        // -- fill --
        /// Fills the grid with a movement cost.
        /// @param | cost | integer | Movement cost.
        /// @return | nil | No value is returned.
        methods.add_method("fill", |_, this, cost: u8| {
            this.inner.borrow_mut().fill(cost);
            Ok(())
        });
        // -- fillRect --
        /// Fills a one-based rectangular area with a movement cost.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @param | w | integer | Lua argument for `w`.
        /// @param | h | integer | Lua argument for `h`.
        /// @param | cost | u8 | Lua argument for `cost`.
        /// @return | nil | No value is returned.
        methods.add_method(
            "fillRect",
            |_, this, (x, y, w, h, cost): (u32, u32, u32, u32, u8)| {
                this.inner.borrow_mut().fill_rect(x - 1, y - 1, w, h, cost);
                Ok(())
            },
        );
        // -- loadFromString --
        /// Loads grid data from a binary string.
        /// @param | data | string | Serialized grid bytes.
        /// @return | nil | No value is returned.
        methods.add_method("loadFromString", |_, this, data: LuaString| {
            this.inner
                .borrow_mut()
                .load_from_bytes(data.as_bytes())
                .map_err(LuaError::external)
        });
        // -- saveToString --
        /// Saves grid data to a binary string. This method is available to Lua scripts.
        /// @return | string | Serialized grid bytes.
        methods.add_method("saveToString", |lua, this, ()| {
            lua.create_string(this.inner.borrow().save_to_bytes())
        });
        // -- setChunkSize --
        /// Sets hierarchical chunk size. This method is available to Lua scripts.
        /// @param | size | integer | Lua argument for `size`.
        /// @return | nil | No value is returned.
        methods.add_method("setChunkSize", |_, this, size: u32| {
            this.inner.borrow_mut().set_chunk_size(size);
            Ok(())
        });
        // -- getChunkSize --
        /// Returns hierarchical chunk size. This method is available to Lua scripts.
        /// @return | integer | Chunk size.
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });
        // -- rebuildAbstract --
        /// Rebuilds the cached abstract graph for this grid.
        /// @return | nil | No value is returned.
        methods.add_method("rebuildAbstract", |_, this, ()| {
            let grid = this.inner.borrow();
            let chunk_size = grid.get_chunk_size();
            let graph = build_abstract(&grid, chunk_size);
            *this.abstract_graph.borrow_mut() = Some(graph);
            Ok(())
        });
        // -- setDirty --
        /// Marks a one-based rectangular region dirty.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @param | w | integer | Lua argument for `w`.
        /// @param | h | integer | Lua argument for `h`.
        /// @return | nil | No value is returned.
        methods.add_method("setDirty", |_, this, (x, y, w, h): (u32, u32, u32, u32)| {
            this.inner.borrow_mut().set_dirty(x - 1, y - 1, w, h);
            Ok(())
        });
        // -- clearDirty --
        /// Clears dirty regions. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method("clearDirty", |_, this, ()| {
            this.inner.borrow_mut().clear_dirty();
            Ok(())
        });
        // -- setDiagonalMode --
        /// Sets diagonal movement mode. This method is available to Lua scripts.
        /// @param | mode | string | Mode name: `none`, `always`, or `nocornercut`.
        /// @return | nil | No value is returned.
        methods.add_method("setDiagonalMode", |_, this, mode: String| {
            let dm = DiagonalMode::from_lua_str(&mode).ok_or_else(|| {
                LuaError::external(format!(
                    "invalid diagonal mode '{}' (expected 'none', 'always', or 'nocornercut')",
                    mode
                ))
            })?;
            this.inner.borrow_mut().set_diagonal_mode(dm);
            Ok(())
        });
        // -- getDiagonalMode --
        /// Returns diagonal movement mode. This method is available to Lua scripts.
        /// @return | string | Mode name.
        methods.add_method("getDiagonalMode", |_, this, ()| {
            Ok(this
                .inner
                .borrow()
                .get_diagonal_mode()
                .to_lua_str()
                .to_string())
        });
        // -- type --
        /// Returns the Lua-visible type name for this navigation grid handle.
        /// @return | string | The string `LNavGrid`.
        methods.add_method("type", |_, _, ()| Ok("LNavGrid"));
        // -- typeOf --
        /// Returns whether this navigation grid handle matches a supported type name.
        /// @param | name | string | String value for `name`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNavGrid" || name == "NavGrid" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a unit pathfinder over a navigation grid.
pub struct LuaUnitPathfinder {
    /// Shared pathfinder data.
    inner: Rc<RefCell<UnitPathfinder>>,
}
/// Provides Lua methods for path queries, reachability, line of sight, and cache settings.
impl LuaUserData for LuaUnitPathfinder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- findPath --
        /// Finds a path between one-based grid cells.
        /// @param | x1 | integer | Lua argument for `x1`.
        /// @param | y1 | integer | Lua argument for `y1`.
        /// @param | x2 | integer | Lua argument for `x2`.
        /// @param | y2 | integer | Lua argument for `y2`.
        /// @param | unit_size | integer? | Lua argument for `unit_size`.
        /// @return | table | Array table of waypoint tables, or nil when no path exists.
        methods.add_method(
            "findPath",
            |lua, this, (x1, y1, x2, y2, unit_size): (u32, u32, u32, u32, Option<u32>)| {
                let result = this.inner.borrow_mut().find_path(
                    x1 - 1,
                    y1 - 1,
                    x2 - 1,
                    y2 - 1,
                    unit_size.unwrap_or(1),
                );
                match result {
                    Some(path) => Ok(LuaValue::Table(waypoints_to_lua(lua, &path)?)),
                    None => Ok(LuaValue::Nil),
                }
            },
        );
        // -- findPathSmooth --
        /// Finds a smoothed path between one-based grid cells.
        /// @param | x1 | integer | Lua argument for `x1`.
        /// @param | y1 | integer | Lua argument for `y1`.
        /// @param | x2 | integer | Lua argument for `x2`.
        /// @param | y2 | integer | Lua argument for `y2`.
        /// @param | unit_size | integer? | Lua argument for `unit_size`.
        /// @return | table | Array table of waypoint tables, or nil when no path exists.
        methods.add_method(
            "findPathSmooth",
            |lua, this, (x1, y1, x2, y2, unit_size): (u32, u32, u32, u32, Option<u32>)| {
                let result = this.inner.borrow_mut().find_path_smooth(
                    x1 - 1,
                    y1 - 1,
                    x2 - 1,
                    y2 - 1,
                    unit_size.unwrap_or(1),
                );
                match result {
                    Some(path) => Ok(LuaValue::Table(waypoints_to_lua(lua, &path)?)),
                    None => Ok(LuaValue::Nil),
                }
            },
        );
        // -- findPathBidirectional --
        /// Finds a path using bidirectional A* and returns completion status.
        /// @param | x1 | integer | One-based column of the start cell.
        /// @param | y1 | integer | One-based row of the start cell.
        /// @param | x2 | integer | One-based column of the goal cell.
        /// @param | y2 | integer | One-based row of the goal cell.
        /// @param | unit_size | integer? | Width or height of the unit in grid cells for clearance checks (default 1).
        /// @param | max_nodes | integer? | Optional node-expansion budget; 0 uses the full search.
        /// @return | table | Array table of waypoint tables, or nil when no path exists.
        /// @return | boolean | True when the path is complete.
        methods.add_method(
            "findPathBidirectional",
            |lua,
             this,
             (x1, y1, x2, y2, unit_size, max_nodes): (
                u32,
                u32,
                u32,
                u32,
                Option<u32>,
                Option<u32>,
            )| {
                let pf = this.inner.borrow();
                let grid_borrowed = pf.nav_grid().borrow();
                let (path_opt, complete) = bidirectional_astar(
                    &grid_borrowed,
                    (x1 - 1, y1 - 1),
                    (x2 - 1, y2 - 1),
                    unit_size.unwrap_or(1),
                    max_nodes.unwrap_or(0),
                );
                match path_opt {
                    Some(cells) => {
                        let tbl = lua.create_table()?;
                        for (i, (cx, cy)) in cells.iter().enumerate() {
                            let entry = lua.create_table()?;
                            entry.set("x", cx + 1)?;
                            entry.set("y", cy + 1)?;
                            tbl.set(i + 1, entry)?;
                        }
                        Ok((LuaValue::Table(tbl), complete))
                    }
                    None => Ok((LuaValue::Nil, false)),
                }
            },
        );
        // -- getPathLength --
        /// Returns path length for a waypoint table.
        /// @param | path | table | Path-like input used by this call.
        /// @return | number | Path length.
        methods.add_method("getPathLength", |_, _this, path: LuaTable| {
            let waypoints = lua_to_waypoints(&path)?;
            Ok(UnitPathfinder::get_path_length(&waypoints))
        });
        // -- getPathCost --
        /// Returns path cost for a waypoint table.
        /// @param | path | table | Path-like input used by this call.
        /// @return | number | Path cost.
        methods.add_method("getPathCost", |_, this, path: LuaTable| {
            let waypoints = lua_to_waypoints(&path)?;
            Ok(this.inner.borrow().get_path_cost(&waypoints))
        });
        // -- findPartialPath --
        /// Finds the best reachable path from a start to a goal within a maximum node budget. Useful for incremental pathfinding across frames.
        /// @param | x1 | integer | One-based column of the start cell.
        /// @param | y1 | integer | One-based row of the start cell.
        /// @param | x2 | integer | One-based column of the goal cell.
        /// @param | y2 | integer | One-based row of the goal cell.
        /// @param | max_nodes | integer | Maximum number of nodes to expand before stopping.
        /// @param | unit_size | integer? | Width/height of the unit in grid cells for clearance checks (default 1).
        /// @return | table | Array of `{x, y}` waypoint tables forming the found partial path.
        /// @return | boolean | `true` if the returned path reaches the exact goal cell.
        methods.add_method("findPartialPath", |lua,
             this,
             (x1, y1, x2, y2, max_nodes, unit_size): (
                u32,
                u32,
                u32,
                u32,
                u32,
                Option<u32>,
            )| {
                let (path, complete) = this.inner.borrow().find_partial_path(
                    x1 - 1,
                    y1 - 1,
                    x2 - 1,
                    y2 - 1,
                    max_nodes,
                    unit_size.unwrap_or(1),
                );
                Ok((waypoints_to_lua(lua, &path)?, complete))
            },
        );
        // -- findNearestWalkable --
        /// Finds nearest walkable one-based grid cell within a radius.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @param | max_radius | integer | Lua argument for `max_radius`.
        /// @param | unit_size | integer? | Lua argument for `unit_size`.
        /// @return | integer | Result x coordinate, or nil.
        /// @return | integer | Result y coordinate, or nil.
        methods.add_method(
            "findNearestWalkable",
            |_, this, (x, y, max_radius, unit_size): (u32, u32, u32, Option<u32>)| match this
                .inner
                .borrow()
                .find_nearest_walkable(x - 1, y - 1, max_radius, unit_size.unwrap_or(1))
            {
                Some((rx, ry)) => Ok((
                    LuaValue::Integer((rx + 1) as i64),
                    LuaValue::Integer((ry + 1) as i64),
                )),
                None => Ok((LuaValue::Nil, LuaValue::Nil)),
            },
        );
        // -- isReachable --
        /// Returns whether a target cell is reachable.
        /// @param | x1 | integer | Lua argument for `x1`.
        /// @param | y1 | integer | Lua argument for `y1`.
        /// @param | x2 | integer | Lua argument for `x2`.
        /// @param | y2 | integer | Lua argument for `y2`.
        /// @param | unit_size | integer? | Lua argument for `unit_size`.
        /// @return | boolean | True when reachable.
        methods.add_method(
            "isReachable",
            |_, this, (x1, y1, x2, y2, unit_size): (u32, u32, u32, u32, Option<u32>)| {
                Ok(this.inner.borrow().is_reachable(
                    x1 - 1,
                    y1 - 1,
                    x2 - 1,
                    y2 - 1,
                    unit_size.unwrap_or(1),
                ))
            },
        );
        // -- heuristicDistance --
        /// Returns heuristic distance between two one-based cells.
        /// @param | x1 | integer | Lua argument for `x1`.
        /// @param | y1 | integer | Lua argument for `y1`.
        /// @param | x2 | integer | Lua argument for `x2`.
        /// @param | y2 | integer | Lua argument for `y2`.
        /// @return | number | Heuristic distance.
        methods.add_method(
            "heuristicDistance",
            |_, _this, (x1, y1, x2, y2): (u32, u32, u32, u32)| {
                Ok(UnitPathfinder::heuristic_distance(
                    x1 - 1,
                    y1 - 1,
                    x2 - 1,
                    y2 - 1,
                ))
            },
        );
        // -- lineOfSight --
        /// Returns whether two one-based cells have line of sight.
        /// @param | x1 | integer | Lua argument for `x1`.
        /// @param | y1 | integer | Lua argument for `y1`.
        /// @param | x2 | integer | Lua argument for `x2`.
        /// @param | y2 | integer | Lua argument for `y2`.
        /// @param | unit_size | integer? | Lua argument for `unit_size`.
        /// @return | boolean | True when line of sight is clear.
        methods.add_method(
            "lineOfSight",
            |_, this, (x1, y1, x2, y2, unit_size): (u32, u32, u32, u32, Option<u32>)| {
                Ok(this.inner.borrow().line_of_sight(
                    x1 - 1,
                    y1 - 1,
                    x2 - 1,
                    y2 - 1,
                    unit_size.unwrap_or(1),
                ))
            },
        );
        // -- setCacheEnabled --
        /// Enables or disables path cache. This method is available to Lua scripts.
        /// @param | enabled | boolean | Boolean flag that controls `enabled`.
        /// @return | nil | No value is returned.
        methods.add_method("setCacheEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_cache_enabled(enabled);
            Ok(())
        });
        // -- isCacheEnabled --
        /// Returns whether path cache is enabled.
        /// @return | boolean | True when enabled.
        methods.add_method("isCacheEnabled", |_, this, ()| {
            Ok(this.inner.borrow().is_cache_enabled())
        });
        // -- clearCache --
        /// Clears cached paths. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method("clearCache", |_, this, ()| {
            this.inner.borrow_mut().clear_cache();
            Ok(())
        });
        // -- getCacheSize --
        /// Returns current path cache size. This method is available to Lua scripts.
        /// @return | integer | Cache size.
        methods.add_method("getCacheSize", |_, this, ()| {
            Ok(this.inner.borrow().get_cache_size())
        });
        // -- setCacheMaxSize --
        /// Sets maximum path cache size. This method is available to Lua scripts.
        /// @param | n | integer | Lua argument for `n`.
        /// @return | nil | No value is returned.
        methods.add_method("setCacheMaxSize", |_, this, n: usize| {
            this.inner.borrow_mut().set_cache_max_size(n);
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this pathfinder handle.
        /// @return | string | The string `LUnitPathfinder`.
        methods.add_method("type", |_, _, ()| Ok("LUnitPathfinder"));
        // -- typeOf --
        /// Returns whether this pathfinder handle matches a supported type name.
        /// @param | name | string | String value for `name`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LUnitPathfinder" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a flow field over a navigation grid.
pub struct LuaFlowField {
    /// Shared flow field data.
    inner: Rc<RefCell<FlowField>>,
}
/// Provides Lua methods for flow field calculation, direction lookup, and steering.
impl LuaUserData for LuaFlowField {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- calculate --
        /// Calculates a flow field toward one target cell.
        /// @param | tx | integer | Lua argument for `tx`.
        /// @param | ty | integer | Lua argument for `ty`.
        /// @param | unit_size | integer? | Lua argument for `unit_size`.
        /// @return | nil | No value is returned.
        methods.add_method(
            "calculate",
            |_, this, (tx, ty, unit_size): (u32, u32, Option<u32>)| {
                this.inner
                    .borrow_mut()
                    .calculate(tx - 1, ty - 1, unit_size.unwrap_or(1));
                Ok(())
            },
        );
        // -- calculateMulti --
        /// Calculates a flow field toward multiple target cells.
        /// @param | targets | table | Lua argument for `targets`.
        /// @param | unit_size | integer? | Lua argument for `unit_size`.
        /// @return | nil | No value is returned.
        methods.add_method(
            "calculateMulti",
            |_, this, (targets, unit_size): (LuaTable, Option<u32>)| {
                let mut pts = Vec::new();
                for pair in targets.sequence_values::<LuaTable>() {
                    let entry = pair?;
                    let x: u32 = entry.get("x")?;
                    let y: u32 = entry.get("y")?;
                    pts.push((x - 1, y - 1));
                }
                this.inner
                    .borrow_mut()
                    .calculate_multi(&pts, unit_size.unwrap_or(1));
                Ok(())
            },
        );
        // -- getDirection --
        /// Returns flow direction at a one-based grid cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | LuaValue | Direction value from the pathfinding module.
        methods.add_method("getDirection", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_direction(x - 1, y - 1))
        });
        // -- getDirectionAngle --
        /// Returns flow direction angle at a one-based grid cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | number | Direction angle.
        methods.add_method("getDirectionAngle", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_direction_angle(x - 1, y - 1))
        });
        // -- getCostToTarget --
        /// Returns flow field cost to target from a one-based grid cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | LuaValue | Cost value from the pathfinding module.
        methods.add_method("getCostToTarget", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cost_to_target(x - 1, y - 1))
        });
        // -- isCalculated --
        /// Returns whether the flow field has been calculated.
        /// @return | boolean | True when calculated.
        methods.add_method("isCalculated", |_, this, ()| {
            Ok(this.inner.borrow().is_calculated())
        });
        // -- getTargets --
        /// Returns target cells for this flow field.
        /// @return | table | Array table of target point tables.
        methods.add_method("getTargets", |lua, this, ()| {
            let targets = this.inner.borrow().get_targets();
            let tbl = lua.create_table()?;
            for (i, (x, y)) in targets.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("x", x + 1)?;
                entry.set("y", y + 1)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        });
        // -- steer --
        /// Returns steering data for a world position.
        /// @param | wx | number | Lua argument for `wx`.
        /// @param | wy | number | Lua argument for `wy`.
        /// @param | speed | number | Lua argument for `speed`.
        /// @param | tw | number | Lua argument for `tw`.
        /// @param | th | number | Lua argument for `th`.
        /// @return | LuaValue | Steering tuple from the pathfinding module.
        methods.add_method(
            "steer",
            |_, this, (wx, wy, speed, tw, th): (f32, f32, f32, f32, f32)| {
                Ok(this.inner.borrow().steer(wx, wy, speed, tw, th))
            },
        );
        // -- type --
        /// Returns the Lua-visible type name for this flow field handle.
        /// @return | string | The string `LFlowField`.
        methods.add_method("type", |_, _, ()| Ok("LFlowField"));
        // -- typeOf --
        /// Returns whether this flow field handle matches a supported type name.
        /// @param | name | string | String value for `name`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFlowField" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a cell-size path grid.
pub struct LuaPathGrid {
    /// Shared path grid data.
    inner: Rc<RefCell<PathGrid>>,
}
/// Provides Lua methods for walkability, costs, and path queries on a path grid.
impl LuaUserData for LuaPathGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns grid width. This method is available to Lua scripts.
        /// @return | integer | Grid width.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().width as u32)
        });
        // -- getHeight --
        /// Returns grid height. This method is available to Lua scripts.
        /// @return | integer | Grid height.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().height as u32)
        });
        // -- getCellSize --
        /// Returns path grid cell size. This method is available to Lua scripts.
        /// @return | number | Cell size.
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size)
        });
        // -- setWalkable --
        /// Sets walkability at a one-based cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @param | w | boolean | Lua argument for `w`.
        /// @return | nil | No value is returned.
        methods.add_method("setWalkable", |_, this, (x, y, w): (usize, usize, bool)| {
            this.inner.borrow_mut().set_walkable(x - 1, y - 1, w);
            Ok(())
        });
        // -- isWalkable --
        /// Returns walkability at a one-based cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | boolean | True when walkable.
        methods.add_method("isWalkable", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().is_walkable(x - 1, y - 1))
        });
        // -- setCost --
        /// Sets movement cost at a one-based cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @param | cost | number | Lua argument for `cost`.
        /// @return | nil | No value is returned.
        methods.add_method("setCost", |_, this, (x, y, cost): (usize, usize, f32)| {
            this.inner.borrow_mut().set_cost(x - 1, y - 1, cost);
            Ok(())
        });
        // -- getCost --
        /// Returns movement cost at a one-based cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | number | Movement cost.
        methods.add_method("getCost", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().get_cost(x - 1, y - 1))
        });
        // -- findPath --
        /// Finds a path between one-based path grid cells.
        /// @param | sx | integer | Lua argument for `sx`.
        /// @param | sy | integer | Lua argument for `sy`.
        /// @param | gx | integer | Lua argument for `gx`.
        /// @param | gy | integer | Lua argument for `gy`.
        /// @return | table | Array table of point tables, or nil when no path exists.
        methods.add_method(
            "findPath",
            |lua, this, (sx, sy, gx, gy): (usize, usize, usize, usize)| -> LuaResult<LuaValue> {
                match this
                    .inner
                    .borrow()
                    .find_path(sx - 1, sy - 1, gx - 1, gy - 1)
                {
                    None => Ok(LuaValue::Nil),
                    Some(pts) => {
                        let tbl = lua.create_table()?;
                        for (i, (px, py)) in pts.iter().enumerate() {
                            let pt = lua.create_table()?;
                            pt.set("x", *px)?;
                            pt.set("y", *py)?;
                            tbl.set(i + 1, pt)?;
                        }
                        Ok(LuaValue::Table(tbl))
                    }
                }
            },
        );
        // -- findPathSmoothed --
        /// Finds a smoothed path between one-based path grid cells.
        /// @param | sx | integer | Lua argument for `sx`.
        /// @param | sy | integer | Lua argument for `sy`.
        /// @param | gx | integer | Lua argument for `gx`.
        /// @param | gy | integer | Lua argument for `gy`.
        /// @return | table | Array table of point tables, or nil when no path exists.
        methods.add_method(
            "findPathSmoothed",
            |lua, this, (sx, sy, gx, gy): (usize, usize, usize, usize)| -> LuaResult<LuaValue> {
                match this
                    .inner
                    .borrow()
                    .find_path_smoothed(sx - 1, sy - 1, gx - 1, gy - 1)
                {
                    None => Ok(LuaValue::Nil),
                    Some(pts) => {
                        let tbl = lua.create_table()?;
                        for (i, (px, py)) in pts.iter().enumerate() {
                            let pt = lua.create_table()?;
                            pt.set("x", *px)?;
                            pt.set("y", *py)?;
                            tbl.set(i + 1, pt)?;
                        }
                        Ok(LuaValue::Table(tbl))
                    }
                }
            },
        );
        // -- type --
        /// Returns the Lua-visible type name for this path grid handle.
        /// @return | string | The string `LPathGrid`.
        methods.add_method("type", |_, _, ()| Ok("LPathGrid"));
        // -- typeOf --
        /// Returns whether this path grid handle matches a supported type name.
        /// @param | name | string | String value for `name`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPathGrid" || name == "Object")
        });
    }
}
/// Lua-side wrapper for an AI flow field over a path grid.
pub struct LuaAiFlowField {
    /// Shared AI flow field data.
    inner: Rc<RefCell<AiFlowField>>,
}
/// Provides Lua methods for AI flow field dimensions, goal, direction, and distance.
impl LuaUserData for LuaAiFlowField {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns flow field width. This method is available to Lua scripts.
        /// @return | integer | Width.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().width as u32)
        });
        // -- getHeight --
        /// Returns flow field height. This method is available to Lua scripts.
        /// @return | integer | Height.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().height as u32)
        });
        // -- hasGoal --
        /// Returns whether a goal is set. This method is available to Lua scripts.
        /// @return | boolean | True when a goal exists.
        methods.add_method("hasGoal", |_, this, ()| {
            Ok(this.inner.borrow().goal.is_some())
        });
        // -- setGoal --
        /// Sets the one-based flow field goal.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | nil | No value is returned.
        methods.add_method("setGoal", |_, this, (x, y): (usize, usize)| {
            this.inner.borrow_mut().set_goal(x - 1, y - 1);
            Ok(())
        });
        // -- getGoal --
        /// Returns the one-based flow field goal when set.
        /// @return | integer | Goal x coordinate, or nil.
        /// @return | integer | Goal y coordinate, or nil.
        methods.add_method(
            "getGoal",
            |_, this, ()| -> LuaResult<(LuaValue, LuaValue)> {
                match this.inner.borrow().goal {
                    None => Ok((LuaValue::Nil, LuaValue::Nil)),
                    Some((gx, gy)) => Ok((
                        LuaValue::Integer((gx + 1) as i64),
                        LuaValue::Integer((gy + 1) as i64),
                    )),
                }
            },
        );
        // -- getDirection --
        /// Returns flow direction for a one-based cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | LuaValue | Direction value.
        methods.add_method("getDirection", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().get_direction(x - 1, y - 1))
        });
        // -- getDistance --
        /// Returns distance to goal for a one-based cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | LuaValue | Distance value.
        methods.add_method("getDistance", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().get_distance(x - 1, y - 1))
        });
        // -- type --
        /// Returns the Lua-visible type name for this AI flow field handle.
        /// @return | string | The string `LAIFlowField`.
        methods.add_method("type", |_, _, ()| Ok("LAIFlowField"));
        // -- typeOf --
        /// Returns whether this AI flow field handle matches a supported type name.
        /// @param | name | string | String value for `name`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAIFlowField" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a hexagonal grid.
pub struct LuaHexGrid {
    /// Shared hex grid data.
    inner: Rc<RefCell<HexGrid>>,
}
/// Provides Lua methods for hex grid blocking, costs, pathing, visibility, movement range, and distance.
impl LuaUserData for LuaHexGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setBlocked --
        /// Sets blocked state for a one-based hex cell.
        /// @param | col | integer | Lua argument for `col`.
        /// @param | row | integer | Lua argument for `row`.
        /// @param | blocked | boolean | Lua argument for `blocked`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setBlocked",
            |_, this, (col, row, blocked): (u32, u32, bool)| {
                this.inner
                    .borrow_mut()
                    .set_blocked(col - 1, row - 1, blocked);
                Ok(())
            },
        );
        // -- setCost --
        /// Sets movement cost for a one-based hex cell.
        /// @param | col | integer | Lua argument for `col`.
        /// @param | row | integer | Lua argument for `row`.
        /// @param | cost | number | Lua argument for `cost`.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCost", |_, this, (col, row, cost): (u32, u32, f32)| {
            this.inner.borrow_mut().set_cost(col - 1, row - 1, cost);
            Ok(())
        });
        // -- isBlocked --
        /// Returns blocked state for a one-based hex cell.
        /// @param | col | integer | Lua argument for `col`.
        /// @param | row | integer | Lua argument for `row`.
        /// @return | boolean | True when blocked.
        methods.add_method("isBlocked", |_, this, (col, row): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(col - 1, row - 1))
        });
        // -- findPath --
        /// Finds a path between one-based hex cells.
        /// @param | fc | integer | Lua argument for `fc`.
        /// @param | fr | integer | Lua argument for `fr`.
        /// @param | tc | integer | Lua argument for `tc`.
        /// @param | tr | integer | Lua argument for `tr`.
        /// @return | table | Array table of hex cell tables, or nil when no path exists.
        methods.add_method(
            "findPath",
            |lua, this, (fc, fr, tc, tr): (u32, u32, u32, u32)| match this
                .inner
                .borrow()
                .find_path((fc - 1, fr - 1), (tc - 1, tr - 1))
            {
                None => Ok(LuaValue::Nil),
                Some(path) => {
                    let t = lua.create_table()?;
                    for (i, (c, r)) in path.iter().enumerate() {
                        let cell = lua.create_table()?;
                        cell.set("col", c + 1)?;
                        cell.set("row", r + 1)?;
                        t.set(i + 1, cell)?;
                    }
                    Ok(LuaValue::Table(t))
                }
            },
        );
        // -- lineOfSight --
        /// Returns whether two one-based hex cells have line of sight.
        /// @param | fc | integer | Lua argument for `fc`.
        /// @param | fr | integer | Lua argument for `fr`.
        /// @param | tc | integer | Lua argument for `tc`.
        /// @param | tr | integer | Lua argument for `tr`.
        /// @return | boolean | True when line of sight is clear.
        methods.add_method(
            "lineOfSight",
            |_, this, (fc, fr, tc, tr): (u32, u32, u32, u32)| {
                Ok(this
                    .inner
                    .borrow()
                    .line_of_sight((fc - 1, fr - 1), (tc - 1, tr - 1)))
            },
        );
        // -- fieldOfView --
        /// Returns visible hex cells within range.
        /// @param | col | integer | Lua argument for `col`.
        /// @param | row | integer | Lua argument for `row`.
        /// @param | max_range | integer | Lua argument for `max_range`.
        /// @return | table | Array table of hex cell tables.
        methods.add_method(
            "fieldOfView",
            |lua, this, (col, row, max_range): (u32, u32, u32)| {
                let cells = this
                    .inner
                    .borrow()
                    .field_of_view((col - 1, row - 1), max_range);
                let t = lua.create_table()?;
                for (i, (c, r)) in cells.iter().enumerate() {
                    let cell = lua.create_table()?;
                    cell.set("col", c + 1)?;
                    cell.set("row", r + 1)?;
                    t.set(i + 1, cell)?;
                }
                Ok(t)
            },
        );
        // -- rangeOfMovement --
        /// Returns reachable hex cells within movement budget.
        /// @param | col | integer | Lua argument for `col`.
        /// @param | row | integer | Lua argument for `row`.
        /// @param | budget | number | Lua argument for `budget`.
        /// @return | table | Array table of hex cell tables.
        methods.add_method(
            "rangeOfMovement",
            |lua, this, (col, row, budget): (u32, u32, f32)| {
                let cells = this
                    .inner
                    .borrow()
                    .range_of_movement((col - 1, row - 1), budget);
                let t = lua.create_table()?;
                for (i, (c, r)) in cells.iter().enumerate() {
                    let cell = lua.create_table()?;
                    cell.set("col", c + 1)?;
                    cell.set("row", r + 1)?;
                    t.set(i + 1, cell)?;
                }
                Ok(t)
            },
        );
        // -- distance --
        /// Returns distance between two one-based hex cells.
        /// @param | c1 | integer | Lua argument for `c1`.
        /// @param | r1 | integer | Lua argument for `r1`.
        /// @param | c2 | integer | Lua argument for `c2`.
        /// @param | r2 | integer | Lua argument for `r2`.
        /// @return | number | Hex distance.
        methods.add_method(
            "distance",
            |_, this, (c1, r1, c2, r2): (u32, u32, u32, u32)| {
                Ok(this
                    .inner
                    .borrow()
                    .distance((c1 - 1, r1 - 1), (c2 - 1, r2 - 1)))
            },
        );
        // -- type --
        /// Returns the Lua-visible type name for this hex grid handle.
        /// @return | string | The string `LHexGrid`.
        methods.add_method("type", |_, _, ()| Ok("LHexGrid"));
        // -- typeOf --
        /// Returns whether this hex grid handle matches a supported type name.
        /// @param | name | string | String value for `name`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHexGrid" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a Jump Point Search grid.
pub struct LuaJpsGrid {
    /// Shared JPS grid data.
    inner: Rc<RefCell<JpsGrid>>,
}
/// Provides Lua methods for JPS blocking and path queries.
impl LuaUserData for LuaJpsGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setBlocked --
        /// Sets blocked state for a one-based grid cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @param | blocked | boolean | Lua argument for `blocked`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setBlocked",
            |_, this, (x, y, blocked): (u32, u32, bool)| {
                this.inner.borrow_mut().set_blocked(x - 1, y - 1, blocked);
                Ok(())
            },
        );
        // -- isBlocked --
        /// Returns blocked state for a one-based grid cell.
        /// @param | x | integer | Numeric `x` argument for this call.
        /// @param | y | integer | Numeric `y` argument for this call.
        /// @return | boolean | True when blocked.
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(x - 1, y - 1))
        });
        // -- findPath --
        /// Finds a JPS path between one-based grid cells.
        /// @param | fx | integer | Lua argument for `fx`.
        /// @param | fy | integer | Lua argument for `fy`.
        /// @param | tx | integer | Lua argument for `tx`.
        /// @param | ty | integer | Lua argument for `ty`.
        /// @return | table | Array table of point tables, or nil when no path exists.
        methods.add_method(
            "findPath",
            |lua, this, (fx, fy, tx, ty): (u32, u32, u32, u32)| match this
                .inner
                .borrow()
                .find_path((fx - 1, fy - 1), (tx - 1, ty - 1))
            {
                None => Ok(LuaValue::Nil),
                Some(path) => {
                    let t = lua.create_table()?;
                    for (i, (x, y)) in path.iter().enumerate() {
                        let cell = lua.create_table()?;
                        cell.set("x", x + 1)?;
                        cell.set("y", y + 1)?;
                        t.set(i + 1, cell)?;
                    }
                    Ok(LuaValue::Table(t))
                }
            },
        );
        // -- type --
        /// Returns the Lua-visible type name for this JPS grid handle.
        /// @return | string | The string `LJpsGrid`.
        methods.add_method("type", |_, _, ()| Ok("LJpsGrid"));
        // -- typeOf --
        /// Returns whether this JPS grid handle matches a supported type name.
        /// @param | name | string | String value for `name`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LJpsGrid" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a navigation mesh.
pub struct LuaNavMesh {
    /// Shared navmesh data.
    inner: Rc<RefCell<NavMesh>>,
}
/// Provides Lua methods for navmesh polygons, links, and path queries.
impl LuaUserData for LuaNavMesh {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addPolygon --
        /// Adds a polygon from vertex tables and returns a one-based id.
        /// @param | vertices | table | Lua argument for `vertices`.
        /// @return | integer | One-based polygon id.
        methods.add_method_mut("addPolygon", |_, this, vertices: LuaTable| {
            let mut points = Vec::new();
            for entry in vertices.sequence_values::<LuaTable>() {
                let v = entry?;
                let x: f32 = v.get("x")?;
                let y: f32 = v.get("y")?;
                points.push((x, y));
            }
            let id = this
                .inner
                .borrow_mut()
                .add_polygon(points)
                .ok_or_else(|| LuaError::runtime("addPolygon requires at least 3 vertices"))?;
            Ok((id + 1) as u32)
        });
        // -- connectPolygons --
        /// Connects two polygons by one-based id.
        /// @param | a | integer | Lua argument for `a`.
        /// @param | b | integer | Lua argument for `b`.
        /// @param | bidirectional | boolean? | Lua argument for `bidirectional`.
        /// @return | boolean | True when the connection was added.
        methods.add_method_mut(
            "connectPolygons",
            |_, this, (a, b, bidirectional): (u32, u32, Option<bool>)| {
                Ok(this.inner.borrow_mut().connect(
                    a.saturating_sub(1) as usize,
                    b.saturating_sub(1) as usize,
                    bidirectional.unwrap_or(true),
                ))
            },
        );
        // -- findPath --
        /// Finds a path through the navmesh between world points.
        /// @param | sx | number | Lua argument for `sx`.
        /// @param | sy | number | Lua argument for `sy`.
        /// @param | gx | number | Lua argument for `gx`.
        /// @param | gy | number | Lua argument for `gy`.
        /// @return | table | Array table of point tables, or nil when no path exists.
        methods.add_method(
            "findPath",
            |lua, this, (sx, sy, gx, gy): (f32, f32, f32, f32)| {
                let path = this.inner.borrow().find_path((sx, sy), (gx, gy));
                match path {
                    Some(points) => {
                        let out = lua.create_table()?;
                        for (i, (x, y)) in points.iter().enumerate() {
                            let node = lua.create_table()?;
                            node.set("x", *x)?;
                            node.set("y", *y)?;
                            out.set(i + 1, node)?;
                        }
                        Ok(LuaValue::Table(out))
                    }
                    None => Ok(LuaValue::Nil),
                }
            },
        );
        // -- getPolygonCount --
        /// Returns navmesh polygon count. This method is available to Lua scripts.
        /// @return | integer | Polygon count.
        methods.add_method("getPolygonCount", |_, this, ()| {
            Ok(this.inner.borrow().polygon_count() as u32)
        });
        // -- type --
        /// Returns the Lua-visible type name for this navmesh handle.
        /// @return | string | The string `LNavMesh`.
        methods.add_method("type", |_, _, ()| Ok("LNavMesh"));
        // -- typeOf --
        /// Returns whether this navmesh handle matches a supported type name.
        /// @param | name | string | String value for `name`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNavMesh" || name == "Object")
        });
    }
}
/// Registers the `lurek.pathfind` module.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newNavGrid --
    /// Creates a navigation grid. This function is exposed to Lua scripts.
    /// @param | width | integer | Numeric `width` argument for this call.
    /// @param | height | integer | Numeric `height` argument for this call.
    /// @return | LNavGrid | New navigation grid handle.
    tbl.set(
        "newNavGrid",
        lua.create_function(|_, (width, height): (u32, u32)| {
            Ok(LuaNavGrid {
                inner: Rc::new(RefCell::new(NavGrid::new(width, height))),
                abstract_graph: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;
    // -- newPathfinder --
    /// Creates a unit pathfinder for a navigation grid.
    /// @param | grid_ud | userdata | Lua argument for `grid_ud`.
    /// @return | LUnitPathfinder | New pathfinder handle.
    tbl.set(
        "newPathfinder",
        lua.create_function(|_, grid_ud: LuaAnyUserData| {
            let grid = grid_ud.borrow::<LuaNavGrid>()?;
            Ok(LuaUnitPathfinder {
                inner: Rc::new(RefCell::new(UnitPathfinder::new(grid.inner.clone()))),
            })
        })?,
    )?;
    // -- newFlowField --
    /// Creates a flow field for a navigation grid.
    /// @param | grid_ud | userdata | Lua argument for `grid_ud`.
    /// @return | LFlowField | New flow field handle.
    tbl.set(
        "newFlowField",
        lua.create_function(|_, grid_ud: LuaAnyUserData| {
            let grid = grid_ud.borrow::<LuaNavGrid>()?;
            Ok(LuaFlowField {
                inner: Rc::new(RefCell::new(FlowField::new(grid.inner.clone()))),
            })
        })?,
    )?;
    // -- newPathGrid --
    /// Creates a cell-size path grid. This function is exposed to Lua scripts.
    /// @param | w | integer | Lua argument for `w`.
    /// @param | h | integer | Lua argument for `h`.
    /// @param | cell_size | number | Lua argument for `cell_size`.
    /// @return | LPathGrid | New path grid handle.
    tbl.set(
        "newPathGrid",
        lua.create_function(|_, (w, h, cell_size): (usize, usize, f32)| {
            Ok(LuaPathGrid {
                inner: Rc::new(RefCell::new(PathGrid::new(w, h, cell_size))),
            })
        })?,
    )?;
    // -- newPathFlowField --
    /// Creates an AI flow field from a path grid.
    /// @param | grid_ud | userdata | Lua argument for `grid_ud`.
    /// @return | LAIFlowField | New AI flow field handle.
    tbl.set(
        "newPathFlowField",
        lua.create_function(|_, grid_ud: LuaAnyUserData| {
            let grid = grid_ud.borrow::<LuaPathGrid>()?;
            let g = grid.inner.borrow();
            let walkable: Vec<bool> = (0..g.height)
                .flat_map(|y| (0..g.width).map(move |x| (x, y)))
                .map(|(x, y)| g.is_walkable(x, y))
                .collect();
            Ok(LuaAiFlowField {
                inner: Rc::new(RefCell::new(AiFlowField::new(g.width, g.height, walkable))),
            })
        })?,
    )?;
    // -- setThreadCount --
    /// Records a warning because pathfinding thread count is not implemented.
    /// @param | count | integer | Lua argument for `count`.
    /// @return | nil | No value is returned.
    tbl.set(
        "setThreadCount",
        lua.create_function(|_, _count: u32| {
            log_msg!(warn, LA08_PATHFINDING_THREAD_UNIMPL);
            Ok(())
        })?,
    )?;
    // -- getThreadCount --
    /// Returns the pathfinding thread count.
    /// @return | integer | Thread count, currently 0.
    tbl.set(
        "getThreadCount",
        lua.create_function(|_, ()| -> LuaResult<u32> { Ok(0) })?,
    )?;
    // -- newNavGridFromTileMap --
    /// Creates a navigation grid from a tilemap layer and blocked gid table.
    /// @param | tm_ud | userdata | Lua argument for `tm_ud`.
    /// @param | layer_index | integer | Lua argument for `layer_index`.
    /// @param | blocked_table | table | Lua argument for `blocked_table`.
    /// @return | LNavGrid | New navigation grid handle.
    tbl.set(
        "newNavGridFromTileMap",
        lua.create_function(
            |_, (tm_ud, layer_index, blocked_table): (LuaAnyUserData, usize, mlua::Table)| {
                let tilemap_ud = tm_ud.borrow::<LuaTileMap>()?;
                let tm = tilemap_ud.inner.borrow();
                let layer_idx = layer_index.saturating_sub(1);
                let (w, h) = tm.get_layer_dimensions(layer_idx).ok_or_else(|| {
                    LuaError::RuntimeError(format!("layer {} does not exist", layer_index))
                })?;
                let mut blocked: std::collections::HashSet<u32> = std::collections::HashSet::new();
                for v in blocked_table.sequence_values::<u32>() {
                    blocked.insert(v?);
                }
                let mut grid = NavGrid::new(w, h);
                for y in 0..h {
                    for x in 0..w {
                        let gid = tm.get_tile(layer_idx, x, y);
                        if blocked.contains(&gid) {
                            grid.set_cost(x, y, 0);
                        }
                    }
                }
                Ok(LuaNavGrid {
                    inner: Rc::new(RefCell::new(grid)),
                    abstract_graph: Rc::new(RefCell::new(None)),
                })
            },
        )?,
    )?;
    // -- newHexGrid --
    /// Creates a hex grid. This function is exposed to Lua scripts.
    /// @param | width | integer | Numeric `width` argument for this call.
    /// @param | height | integer | Numeric `height` argument for this call.
    /// @param | layout_str | string? | Lua argument for `layout_str`.
    /// @return | LHexGrid | New hex grid handle.
    tbl.set(
        "newHexGrid",
        lua.create_function(
            |_, (width, height, layout_str): (u32, u32, Option<String>)| {
                let layout = match layout_str.as_deref().unwrap_or("flat") {
                    "pointy" => HexLayout::PointyTop,
                    _ => HexLayout::FlatTop,
                };
                Ok(LuaHexGrid {
                    inner: Rc::new(RefCell::new(HexGrid::new(width, height, layout))),
                })
            },
        )?,
    )?;
    // -- newJpsGrid --
    /// Creates a Jump Point Search grid. This function is exposed to Lua scripts.
    /// @param | width | integer | Numeric `width` argument for this call.
    /// @param | height | integer | Numeric `height` argument for this call.
    /// @return | LJpsGrid | New JPS grid handle.
    tbl.set(
        "newJpsGrid",
        lua.create_function(|_, (width, height): (u32, u32)| {
            Ok(LuaJpsGrid {
                inner: Rc::new(RefCell::new(JpsGrid::new(width, height))),
            })
        })?,
    )?;
    // -- newNavMesh --
    /// Creates an empty navigation mesh. This function is exposed to Lua scripts.
    /// @return | LNavMesh | New navmesh handle.
    tbl.set(
        "newNavMesh",
        lua.create_function(|_, ()| {
            Ok(LuaNavMesh {
                inner: Rc::new(RefCell::new(NavMesh::new())),
            })
        })?,
    )?;
    // -- rangeMap --
    /// Computes reachable cells from range map options.
    /// @param | opts | table | Options with dimensions, origin, budget, optional diagonal flag, costs, and blocked cells.
    /// @return | table | Range map result with `cells`, `width`, and `height` fields.
    tbl.set(
        "rangeMap",
        lua.create_function(|lua, opts: LuaTable| {
            let width: u32 = opts.get("width")?;
            let height: u32 = opts.get("height")?;
            let ox: u32 = opts.get("origin_x")?;
            let oy: u32 = opts.get("origin_y")?;
            let budget: f32 = opts.get("budget")?;
            let diagonal: bool = opts.get("diagonal").unwrap_or(false);
            let cost_n = (width * height) as usize;
            let mut costs_v = vec![1.0f32; cost_n];
            let mut blocked_v = vec![false; cost_n];
            if let Ok(ct) = opts.get::<_, LuaTable>("costs") {
                for (i, v) in ct.sequence_values::<f32>().enumerate() {
                    if i < cost_n {
                        costs_v[i] = v?;
                    }
                }
            }
            if let Ok(bt) = opts.get::<_, LuaTable>("blocked") {
                for (i, v) in bt.sequence_values::<bool>().enumerate() {
                    if i < cost_n {
                        blocked_v[i] = v?;
                    }
                }
            }
            let rm = RangeMap::from_grid(
                width,
                height,
                &costs_v,
                &blocked_v,
                ox - 1,
                oy - 1,
                budget,
                diagonal,
            );
            let cells_tbl = lua.create_table()?;
            let mut count = 0;
            for (x, y, cost) in rm.reachable_cells_with_cost() {
                let ct = lua.create_table()?;
                ct.set("x", x + 1)?;
                ct.set("y", y + 1)?;
                ct.set("cost", cost)?;
                count += 1;
                cells_tbl.set(count, ct)?;
            }
            let out = lua.create_table()?;
            out.set("cells", cells_tbl)?;
            out.set("width", width)?;
            out.set("height", height)?;
            Ok(out)
        })?,
    )?;
    lurek.set("pathfind", tbl)?;
    Ok(())
}
