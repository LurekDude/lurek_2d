//! `lurek.pathfind` - Grid pathfinding, flow fields, HPA*, and unit-aware navigation.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use super::tilemap_api::LuaTileMap;
use crate::log_msg;
use crate::pathfind::ai_flow_field::FlowField as AiFlowField;
use crate::pathfind::hpa::{build_abstract, AbstractGraph};
use crate::pathfind::pathgrid::PathGrid;
use crate::pathfind::{
    bidirectional_astar, DiagonalMode, FlowField, NavGrid, UnitPathfinder, Waypoint,
};
use crate::pathfind::{HexGrid, HexLayout, JpsGrid, RangeMap};
use crate::runtime::log_messages::LA08_PATHFINDING_THREAD_UNIMPL;

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

// Convert a slice of 0-based `Waypoint`s to a 1-based Lua table of `{x, y}`.
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

// Parse a Lua path table (array of `{x, y}`, 1-based) into 0-based `Waypoint`s.
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

// -------------------------------------------------------------------------------
// LuaNavGrid UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`NavGrid`] with optional HPA★ abstract graph.
pub struct LuaNavGrid {
    inner: Rc<RefCell<NavGrid>>,
    abstract_graph: Rc<RefCell<Option<AbstractGraph>>>,
}

impl LuaUserData for LuaNavGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the grid width in cells.
        /// @return | integer | Grid width in cells.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });

        // -- getHeight --
        /// Returns the grid height in cells.
        /// @return | integer | Grid height in cells.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });

        // -- getDimensions --
        /// Returns the grid dimensions as width, height.
        /// @return | integer, integer | Grid width and height in cells.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_dimensions())
        });

        // -- setCost --
        /// Sets the traversal cost of a cell (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @param | cost | integer | Traversal cost to assign to the cell.
        /// @return | nil | No value is returned.
        methods.add_method("setCost", |_, this, (x, y, cost): (u32, u32, u8)| {
            this.inner.borrow_mut().set_cost(x - 1, y - 1, cost);
            Ok(())
        });

        // -- getCost --
        /// Returns the traversal cost of a cell (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @return | integer | Traversal cost for the cell.
        methods.add_method("getCost", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cost(x - 1, y - 1))
        });

        // -- setBlocked --
        /// Marks a cell as blocked or unblocked (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @param | blocked | boolean | Whether the cell should be blocked.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setBlocked",
            |_, this, (x, y, blocked): (u32, u32, bool)| {
                this.inner.borrow_mut().set_blocked(x - 1, y - 1, blocked);
                Ok(())
            },
        );

        // -- isBlocked --
        /// Returns true if the cell is blocked (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @return | boolean | True when the cell is blocked.
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(x - 1, y - 1))
        });

        // -- isWalkable --
        /// Returns true if a unit footprint is fully walkable (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @param | unitSize | integer? | Optional unit footprint size in cells.
        /// @return | boolean | True when the footprint can occupy the cell.
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
        /// Sets every cell to the given cost.
        /// @param | cost | integer | Traversal cost to assign to every cell.
        /// @return | nil | No value is returned.
        methods.add_method("fill", |_, this, cost: u8| {
            this.inner.borrow_mut().fill(cost);
            Ok(())
        });

        // -- fillRect --
        /// Sets all cells in a rectangle to the given cost (1-based coordinates).
        /// @param | x | integer | 1-based rectangle origin X coordinate.
        /// @param | y | integer | 1-based rectangle origin Y coordinate.
        /// @param | w | integer | Rectangle width in cells.
        /// @param | h | integer | Rectangle height in cells.
        /// @param | cost | integer | Traversal cost to assign inside the rectangle.
        /// @return | nil | No value is returned.
        methods.add_method(
            "fillRect",
            |_, this, (x, y, w, h, cost): (u32, u32, u32, u32, u8)| {
                this.inner.borrow_mut().fill_rect(x - 1, y - 1, w, h, cost);
                Ok(())
            },
        );

        // -- loadFromString --
        /// Overwrites the grid from a raw byte string (row-major, one byte per cell).
        /// @param | data | string | Serialized grid bytes in row-major order.
        /// @return | nil | No value is returned.
        methods.add_method("loadFromString", |_, this, data: LuaString| {
            this.inner
                .borrow_mut()
                .load_from_bytes(data.as_bytes())
                .map_err(LuaError::external)
        });

        // -- saveToString --
        /// Exports the cost grid as a byte string (row-major, one byte per cell).
        /// @return | string | Serialized grid bytes in row-major order.
        methods.add_method("saveToString", |lua, this, ()| {
            lua.create_string(this.inner.borrow().save_to_bytes())
        });

        // -- setChunkSize --
        /// Sets the HPA★ chunk size.
        /// @param | size | integer | Chunk size in cells.
        /// @return | nil | No value is returned.
        methods.add_method("setChunkSize", |_, this, size: u32| {
            this.inner.borrow_mut().set_chunk_size(size);
            Ok(())
        });

        // -- getChunkSize --
        /// Returns the current HPA★ chunk size.
        /// @return | integer | Chunk size in cells.
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });

        // -- rebuildAbstract --
        /// Rebuilds the HPA★ abstract graph from the current grid state.
        /// @return | nil | No value is returned.
        methods.add_method("rebuildAbstract", |_, this, ()| {
            let grid = this.inner.borrow();
            let chunk_size = grid.get_chunk_size();
            let graph = build_abstract(&grid, chunk_size);
            *this.abstract_graph.borrow_mut() = Some(graph);
            Ok(())
        });

        // -- setDirty --
        /// Records a dirty rectangle for incremental HPA★ updates (1-based coordinates).
        /// @param | x | integer | 1-based dirty rectangle origin X coordinate.
        /// @param | y | integer | 1-based dirty rectangle origin Y coordinate.
        /// @param | w | integer | Dirty rectangle width in cells.
        /// @param | h | integer | Dirty rectangle height in cells.
        /// @return | nil | No value is returned.
        methods.add_method("setDirty", |_, this, (x, y, w, h): (u32, u32, u32, u32)| {
            this.inner.borrow_mut().set_dirty(x - 1, y - 1, w, h);
            Ok(())
        });

        // -- clearDirty --
        /// Clears all pending dirty rectangles.
        /// @return | nil | No value is returned.
        methods.add_method("clearDirty", |_, this, ()| {
            this.inner.borrow_mut().clear_dirty();
            Ok(())
        });

        // -- setDiagonalMode --
        /// Sets the diagonal movement mode.
        /// @param | mode | string | Diagonal mode name.
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
        /// Returns the current diagonal movement mode as a string.
        /// @return | string | Diagonal mode name.
        methods.add_method("getDiagonalMode", |_, this, ()| {
            Ok(this
                .inner
                .borrow()
                .get_diagonal_mode()
                .to_lua_str()
                .to_string())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LNavGrid"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNavGrid" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaUnitPathfinder UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`UnitPathfinder`].
pub struct LuaUnitPathfinder {
    inner: Rc<RefCell<UnitPathfinder>>,
}

impl LuaUserData for LuaUnitPathfinder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- findPath --
        /// Finds an A★ path between two cells (1-based coordinates).
        /// @param | x1 | integer | 1-based start cell X coordinate.
        /// @param | y1 | integer | 1-based start cell Y coordinate.
        /// @param | x2 | integer | 1-based goal cell X coordinate.
        /// @param | y2 | integer | 1-based goal cell Y coordinate.
        /// @param | unitSize | integer? | Optional unit footprint size in cells.
        /// @return | table | Path entries as 1-based `{x, y}` tables.
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
        /// Finds a Theta★ smoothed path between two cells (1-based coordinates).
        /// @param | x1 | integer | 1-based start cell X coordinate.
        /// @param | y1 | integer | 1-based start cell Y coordinate.
        /// @param | x2 | integer | 1-based goal cell X coordinate.
        /// @param | y2 | integer | 1-based goal cell Y coordinate.
        /// @param | unitSize | integer? | Optional unit footprint size in cells.
        /// @return | table | Smoothed path entries as 1-based `{x, y}` tables.
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
        /// Finds a path with bidirectional A★ between two cells.
        /// @param | x1 | integer | 1-based start cell X coordinate.
        /// @param | y1 | integer | 1-based start cell Y coordinate.
        /// @param | x2 | integer | 1-based goal cell X coordinate.
        /// @param | y2 | integer | 1-based goal cell Y coordinate.
        /// @param | unitSize | integer? | Optional unit footprint size in cells.
        /// @param | maxNodes | integer? | Optional node expansion limit.
        /// @return | table, boolean | Path entries and a completion flag.
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
        /// Returns the euclidean length of a path table.
        /// @param | path | table | Path entries as `{x, y}` tables.
        /// @return | number | Euclidean path length.
        methods.add_method("getPathLength", |_, _this, path: LuaTable| {
            let waypoints = lua_to_waypoints(&path)?;
            Ok(UnitPathfinder::get_path_length(&waypoints))
        });

        // -- getPathCost --
        /// Returns the sum of grid traversal costs along a path.
        /// @param | path | table | Path entries as `{x, y}` tables.
        /// @return | number | Total traversal cost along the path.
        methods.add_method("getPathCost", |_, this, path: LuaTable| {
            let waypoints = lua_to_waypoints(&path)?;
            Ok(this.inner.borrow().get_path_cost(&waypoints))
        });

        // -- findPartialPath --
        /// Finds a partial path with a node expansion limit (1-based coordinates).
        /// @param | x1 | integer | 1-based start cell X coordinate.
        /// @param | y1 | integer | 1-based start cell Y coordinate.
        /// @param | x2 | integer | 1-based goal cell X coordinate.
        /// @param | y2 | integer | 1-based goal cell Y coordinate.
        /// @param | maxNodes | integer | Maximum node expansions to allow.
        /// @param | unitSize | integer? | Optional unit footprint size in cells.
        /// @return | table, boolean | Partial path entries and a completion flag.
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
        /// Finds the nearest walkable cell within a radius (1-based coordinates).
        /// @param | x | integer | 1-based origin cell X coordinate.
        /// @param | y | integer | 1-based origin cell Y coordinate.
        /// @param | maxRadius | integer | Maximum search radius in cells.
        /// @param | unitSize | integer? | Optional unit footprint size in cells.
        /// @return | integer, integer | 1-based coordinates of the nearest walkable cell.
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
        /// Returns true if a path exists between two cells (1-based coordinates).
        /// @param | x1 | integer | 1-based start cell X coordinate.
        /// @param | y1 | integer | 1-based start cell Y coordinate.
        /// @param | x2 | integer | 1-based goal cell X coordinate.
        /// @param | y2 | integer | 1-based goal cell Y coordinate.
        /// @param | unitSize | integer? | Optional unit footprint size in cells.
        /// @return | boolean | True when a path exists.
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
        /// Returns the octile heuristic distance between two cells (1-based coordinates).
        /// @param | x1 | integer | 1-based first cell X coordinate.
        /// @param | y1 | integer | 1-based first cell Y coordinate.
        /// @param | x2 | integer | 1-based second cell X coordinate.
        /// @param | y2 | integer | 1-based second cell Y coordinate.
        /// @return | number | Octile heuristic distance.
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
        /// Returns true if there is a clear line of sight between two cells (1-based coordinates).
        /// @param | x1 | integer | 1-based start cell X coordinate.
        /// @param | y1 | integer | 1-based start cell Y coordinate.
        /// @param | x2 | integer | 1-based goal cell X coordinate.
        /// @param | y2 | integer | 1-based goal cell Y coordinate.
        /// @param | unitSize | integer? | Optional unit footprint size in cells.
        /// @return | boolean | True when line of sight is unobstructed.
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
        /// Enables or disables path result caching.
        /// @param | enabled | boolean | Whether path caching should be enabled.
        /// @return | nil | No value is returned.
        methods.add_method("setCacheEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_cache_enabled(enabled);
            Ok(())
        });

        // -- isCacheEnabled --
        /// Returns true if path result caching is enabled.
        /// @return | boolean | True when path result caching is enabled.
        methods.add_method("isCacheEnabled", |_, this, ()| {
            Ok(this.inner.borrow().is_cache_enabled())
        });

        // -- clearCache --
        /// Removes all cached path results.
        /// @return | nil | No value is returned.
        methods.add_method("clearCache", |_, this, ()| {
            this.inner.borrow_mut().clear_cache();
            Ok(())
        });

        // -- getCacheSize --
        /// Returns the number of entries in the path cache.
        /// @return | integer | Number of cached path results.
        methods.add_method("getCacheSize", |_, this, ()| {
            Ok(this.inner.borrow().get_cache_size())
        });

        // -- setCacheMaxSize --
        /// Sets the maximum number of cached path entries.
        /// @param | n | integer | Maximum number of cached path results.
        /// @return | nil | No value is returned.
        methods.add_method("setCacheMaxSize", |_, this, n: usize| {
            this.inner.borrow_mut().set_cache_max_size(n);
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LUnitPathfinder"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LUnitPathfinder" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaFlowField UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`FlowField`].
pub struct LuaFlowField {
    inner: Rc<RefCell<FlowField>>,
}

impl LuaUserData for LuaFlowField {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- calculate --
        /// Computes the flow field toward a single target (1-based coordinates).
        /// @param | tx | integer | 1-based target cell X coordinate.
        /// @param | ty | integer | 1-based target cell Y coordinate.
        /// @param | unitSize | integer? | Optional unit footprint size in cells.
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
        /// Computes the flow field toward multiple targets (1-based coordinates).
        /// @param | targets | table | Target cell entries as `{x, y}` tables.
        /// @param | unitSize | integer? | Optional unit footprint size in cells.
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
        /// Returns the normalised direction vector at a cell (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @return | number, number | Normalized X and Y direction components.
        methods.add_method("getDirection", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_direction(x - 1, y - 1))
        });

        // -- getDirectionAngle --
        /// Returns the flow direction as an angle in radians (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @return | number | Flow direction angle in radians.
        methods.add_method("getDirectionAngle", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_direction_angle(x - 1, y - 1))
        });

        // -- getCostToTarget --
        /// Returns the integrated cost to the nearest target (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @return | number | Integrated cost to the nearest target.
        methods.add_method("getCostToTarget", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cost_to_target(x - 1, y - 1))
        });

        // -- isCalculated --
        /// Returns true if the flow field has been computed at least once.
        /// @return | boolean | True when the flow field has been computed.
        methods.add_method("isCalculated", |_, this, ()| {
            Ok(this.inner.borrow().is_calculated())
        });

        // -- getTargets --
        /// Returns the target cells from the most recent computation (1-based coordinates).
        /// @return | table | Target cell entries as 1-based `{x, y}` tables.
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
        /// Converts a world-space position into a velocity vector via the flow field.
        /// @param | wx | number | World-space X position.
        /// @param | wy | number | World-space Y position.
        /// @param | speed | number | Desired movement speed.
        /// @param | tw | number | Tile width in world units.
        /// @param | th | number | Tile height in world units.
        /// @return | number, number | Steering velocity X and Y components.
        methods.add_method(
            "steer",
            |_, this, (wx, wy, speed, tw, th): (f32, f32, f32, f32, f32)| {
                Ok(this.inner.borrow().steer(wx, wy, speed, tw, th))
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LFlowField"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFlowField" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaPathGrid UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`PathGrid`] (A★ weighted grid with per-cell cost).
pub struct LuaPathGrid {
    inner: Rc<RefCell<PathGrid>>,
}

impl LuaUserData for LuaPathGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the grid width in cells.
        /// @return | integer | Grid width in cells.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().width as u32)
        });

        // -- getHeight --
        /// Returns the grid height in cells.
        /// @return | integer | Grid height in cells.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().height as u32)
        });

        // -- getCellSize --
        /// Returns the world-space size of each cell.
        /// @return | number | Cell size in world units.
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size)
        });

        // -- setWalkable --
        /// Sets the walkability of a cell (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @param | walkable | boolean | Whether the cell should be walkable.
        /// @return | nil | No value is returned.
        methods.add_method("setWalkable", |_, this, (x, y, w): (usize, usize, bool)| {
            this.inner.borrow_mut().set_walkable(x - 1, y - 1, w);
            Ok(())
        });

        // -- isWalkable --
        /// Returns true if a cell is walkable (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @return | boolean | True when the cell is walkable.
        methods.add_method("isWalkable", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().is_walkable(x - 1, y - 1))
        });

        // -- setCost --
        /// Sets the cost multiplier for a cell (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @param | cost | number | Cost multiplier to assign to the cell.
        /// @return | nil | No value is returned.
        methods.add_method("setCost", |_, this, (x, y, cost): (usize, usize, f32)| {
            this.inner.borrow_mut().set_cost(x - 1, y - 1, cost);
            Ok(())
        });

        // -- getCost --
        /// Returns the cost multiplier for a cell (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @return | number | Cost multiplier for the cell.
        methods.add_method("getCost", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().get_cost(x - 1, y - 1))
        });

        // -- findPath --
        /// Finds an A★ path returning world-space waypoints (1-based coordinates).
        /// @param | sx | integer | 1-based start cell X coordinate.
        /// @param | sy | integer | 1-based start cell Y coordinate.
        /// @param | gx | integer | 1-based goal cell X coordinate.
        /// @param | gy | integer | 1-based goal cell Y coordinate.
        /// @return | table | World-space waypoint entries as `{x, y}` tables.
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
        /// Finds a smoothed A★ path with string-pulling (1-based coordinates).
        /// @param | sx | integer | 1-based start cell X coordinate.
        /// @param | sy | integer | 1-based start cell Y coordinate.
        /// @param | gx | integer | 1-based goal cell X coordinate.
        /// @param | gy | integer | 1-based goal cell Y coordinate.
        /// @return | table | Smoothed world-space waypoint entries as `{x, y}` tables.
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
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LPathGrid"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPathGrid" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaAiFlowField UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a PathGrid-based [`AiFlowField`].
pub struct LuaAiFlowField {
    inner: Rc<RefCell<AiFlowField>>,
}

impl LuaUserData for LuaAiFlowField {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the flow field grid width in cells.
        /// @return | integer | Flow field width in cells.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().width as u32)
        });

        // -- getHeight --
        /// Returns the flow field grid height in cells.
        /// @return | integer | Flow field height in cells.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().height as u32)
        });

        // -- hasGoal --
        /// Returns true if a goal has been set.
        /// @return | boolean | True when a goal is set.
        methods.add_method("hasGoal", |_, this, ()| {
            Ok(this.inner.borrow().goal.is_some())
        });

        // -- setGoal --
        /// Sets the goal cell and triggers BFS recomputation (1-based coordinates).
        /// @param | x | integer | 1-based goal cell X coordinate.
        /// @param | y | integer | 1-based goal cell Y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method("setGoal", |_, this, (x, y): (usize, usize)| {
            this.inner.borrow_mut().set_goal(x - 1, y - 1);
            Ok(())
        });

        // -- getGoal --
        /// Returns the goal cell (1-based coordinates) or nil if unset.
        /// @return | integer, integer | 1-based goal cell coordinates.
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
        /// Returns the normalised direction toward the goal (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @return | number, number | Normalized X and Y direction components.
        methods.add_method("getDirection", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().get_direction(x - 1, y - 1))
        });

        // -- getDistance --
        /// Returns the BFS distance to the goal (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @return | number | BFS distance to the goal.
        methods.add_method("getDistance", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().get_distance(x - 1, y - 1))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LAIFlowField"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAIFlowField" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaHexGrid UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`HexGrid`].
pub struct LuaHexGrid {
    inner: Rc<RefCell<HexGrid>>,
}

impl LuaUserData for LuaHexGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setBlocked --
        /// Mark/unmark a cell as blocked (1-based coordinates).
        /// @param | col | integer | 1-based cell column.
        /// @param | row | integer | 1-based cell row.
        /// @param | blocked | boolean | Whether the cell should be blocked.
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
        /// Set movement cost for a cell (1-based coordinates).
        /// @param | col | integer | 1-based cell column.
        /// @param | row | integer | 1-based cell row.
        /// @param | cost | number | Movement cost to assign to the cell.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCost", |_, this, (col, row, cost): (u32, u32, f32)| {
            this.inner.borrow_mut().set_cost(col - 1, row - 1, cost);
            Ok(())
        });

        // -- isBlocked --
        /// Returns true if a cell is blocked (1-based coordinates).
        /// @param | col | integer | 1-based cell column.
        /// @param | row | integer | 1-based cell row.
        /// @return | boolean | True when the cell is blocked.
        methods.add_method("isBlocked", |_, this, (col, row): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(col - 1, row - 1))
        });

        // -- findPath --
        /// Find A* path between two cells (1-based coordinates).
        /// @param | from_col | integer | 1-based start column.
        /// @param | from_row | integer | 1-based start row.
        /// @param | to_col | integer | 1-based goal column.
        /// @param | to_row | integer | 1-based goal row.
        /// @return | table | Path entries as 1-based `{col, row}` tables.
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
        /// Returns true if there is an unobstructed line between two cells (1-based).
        /// @param | from_col | integer | 1-based start column.
        /// @param | from_row | integer | 1-based start row.
        /// @param | to_col | integer | 1-based goal column.
        /// @param | to_row | integer | 1-based goal row.
        /// @return | boolean | True when the line is unobstructed.
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
        /// Returns all cells visible from origin within max_range (1-based coordinates).
        /// @param | col | integer | 1-based origin column.
        /// @param | row | integer | 1-based origin row.
        /// @param | max_range | integer | Maximum visibility range in cells.
        /// @return | table | Visible cell entries as 1-based `{col, row}` tables.
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
        /// Returns all cells reachable from origin within movement budget (1-based).
        /// @param | col | integer | 1-based origin column.
        /// @param | row | integer | 1-based origin row.
        /// @param | budget | number | Movement budget to spend.
        /// @return | table | Reachable cell entries as 1-based `{col, row}` tables.
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
        /// Hex-distance between two cells.
        /// @param | col1 | integer | 1-based first column.
        /// @param | row1 | integer | 1-based first row.
        /// @param | col2 | integer | 1-based second column.
        /// @param | row2 | integer | 1-based second row.
        /// @return | integer | Hex distance in cells.
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
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LHexGrid"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHexGrid" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaJpsGrid UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`JpsGrid`].
pub struct LuaJpsGrid {
    inner: Rc<RefCell<JpsGrid>>,
}

impl LuaUserData for LuaJpsGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setBlocked --
        /// Mark/unmark a cell as blocked (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @param | blocked | boolean | Whether the cell should be blocked.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setBlocked",
            |_, this, (x, y, blocked): (u32, u32, bool)| {
                this.inner.borrow_mut().set_blocked(x - 1, y - 1, blocked);
                Ok(())
            },
        );

        // -- isBlocked --
        /// Returns true if the cell is blocked (1-based coordinates).
        /// @param | x | integer | 1-based cell X coordinate.
        /// @param | y | integer | 1-based cell Y coordinate.
        /// @return | boolean | True when the cell is blocked.
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(x - 1, y - 1))
        });

        // -- findPath --
        /// Find a JPS path between two cells (1-based coordinates).
        /// @param | from_x | integer | 1-based start cell X coordinate.
        /// @param | from_y | integer | 1-based start cell Y coordinate.
        /// @param | to_x | integer | 1-based goal cell X coordinate.
        /// @param | to_y | integer | 1-based goal cell Y coordinate.
        /// @return | table | Path entries as 1-based `{x, y}` tables.
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
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LJpsGrid"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LJpsGrid" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.pathfind` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newNavGrid --
    /// Creates a new NavGrid with all cells walkable.
    /// @param | width | integer | Grid width in cells.
    /// @param | height | integer | Grid height in cells.
    /// @return | LNavGrid | New navigation grid userdata.
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
    /// Creates a new UnitPathfinder backed by a NavGrid.
    /// @param | grid | LNavGrid | Navigation grid to path over.
    /// @return | LUnitPathfinder | New pathfinder userdata.
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
    /// Creates a new FlowField backed by a NavGrid.
    /// @param | grid | LNavGrid | Navigation grid to build from.
    /// @return | LFlowField | New flow-field userdata.
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
    /// Creates a new PathGrid with per-cell cost and walkability.
    /// @param | w | integer | Grid width in cells.
    /// @param | h | integer | Grid height in cells.
    /// @param | cellSize | number | Cell size in world units.
    /// @return | LPathGrid | New weighted path grid userdata.
    tbl.set(
        "newPathGrid",
        lua.create_function(|_, (w, h, cell_size): (usize, usize, f32)| {
            Ok(LuaPathGrid {
                inner: Rc::new(RefCell::new(PathGrid::new(w, h, cell_size))),
            })
        })?,
    )?;

    // -- newPathFlowField --
    /// Creates a new BFS flow field from a PathGrid.
    /// @param | grid | LPathGrid | Weighted path grid to build from.
    /// @return | LAIFlowField | New PathGrid-based flow-field userdata.
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
    /// Sets the background pathfinding thread count (currently a no-op).
    /// @param | count | integer | Requested background thread count.
    /// @return | nil | No value is returned.
    tbl.set(
        "setThreadCount",
        lua.create_function(|_, _count: u32| {
            log_msg!(warn, LA08_PATHFINDING_THREAD_UNIMPL);
            Ok(())
        })?,
    )?;

    // -- getThreadCount --
    /// Returns the background pathfinding thread count (currently always 0).
    /// @return | integer | Current background thread count.
    tbl.set(
        "getThreadCount",
        lua.create_function(|_, ()| -> LuaResult<u32> { Ok(0) })?,
    )?;

    // -- newNavGridFromTileMap --
    /// Builds a NavGrid from a TileMap layer, treating specified GIDs as blocked (unwalkable).
    /// @param | tilemap | LTileMap | Source tilemap userdata.
    /// @param | layer_index | integer | 1-based tilemap layer index.
    /// @param | blocked_gids | table | GID values to treat as blocked.
    /// @return | LNavGrid | Navigation grid built from the selected layer.
    tbl.set(
        "newNavGridFromTileMap",
        lua.create_function(
            |_, (tm_ud, layer_index, blocked_table): (LuaAnyUserData, usize, mlua::Table)| {
                let tilemap_ud = tm_ud.borrow::<LuaTileMap>()?;
                let tm = tilemap_ud.inner.borrow();
                let layer_idx = layer_index.saturating_sub(1); // 1-based → 0-based
                let (w, h) = tm.get_layer_dimensions(layer_idx).ok_or_else(|| {
                    LuaError::RuntimeError(format!("layer {} does not exist", layer_index))
                })?;

                // Collect blocked GIDs into a HashSet for O(1) lookup
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
    /// Creates a hex grid for pathfinding, LOS, FOV, and range queries.
    /// @param | width | integer | Grid width in cells.
    /// @param | height | integer | Grid height in cells.
    /// @param | layout | string? | Optional hex layout name: `flat` or `pointy`.
    /// @return | LHexGrid | New hex-grid userdata.
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
    /// Creates a uniform-cost grid optimised for Jump Point Search (orthogonal + diagonal).
    /// @param | width | integer | Grid width in cells.
    /// @param | height | integer | Grid height in cells.
    /// @return | LJpsGrid | New Jump Point Search grid userdata.
    tbl.set(
        "newJpsGrid",
        lua.create_function(|_, (width, height): (u32, u32)| {
            Ok(LuaJpsGrid {
                inner: Rc::new(RefCell::new(JpsGrid::new(width, height))),
            })
        })?,
    )?;

    // -- rangeMap --
    /// Computes a Dijkstra range-of-movement map from an origin within a movement budget.
    /// @param | opts | table | Range-map options: width, height, costs, blocked, origin_x, origin_y, budget, and optional diagonal.
    /// @return | table | Result table with `cells`, `width`, and `height` fields.
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
