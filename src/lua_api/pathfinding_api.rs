//! Registers the `luna.pathfinding.*` grid-based pathfinding API.
//!
//! Exposes `NavGrid`, `UnitPathfinder`, and `FlowField` as Lua UserData
//! with 1-based tile coordinates at the Lua boundary.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::pathfinding::hpa::{build_abstract, AbstractGraph};
use crate::pathfinding::{DiagonalMode, FlowField, NavGrid, UnitPathfinder, Waypoint};

use super::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// LuaNavGrid
// ---------------------------------------------------------------------------

/// Lua wrapper around a [`NavGrid`] with optional HPA* abstract graph.
#[derive(Clone)]
struct LuaNavGrid {
    inner: Rc<RefCell<NavGrid>>,
    abstract_graph: Rc<RefCell<Option<AbstractGraph>>>,
}

impl LunaType for LuaNavGrid {
    const TYPE_NAME: &'static str = "NavGrid";
    const TYPE_HIERARCHY: &'static [&'static str] = &["NavGrid", "Object"];
}

impl LuaUserData for LuaNavGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the width.
        ///
        /// # Returns
        /// The current width.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });

        /// Returns the height.
        ///
        /// # Returns
        /// The current height.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });

        /// Returns the dimensions.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `cost` — `integer`.
        ///
        /// # Returns
        /// The current dimensions.
        methods.add_method("getDimensions", |_, this, ()| {
            let g = this.inner.borrow();
            let (w, h) = g.get_dimensions();
            Ok((w, h))
        });

        // 1-based coords at Lua boundary
        /// Sets the cost.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `cost` — `integer`.
        methods.add_method("setCost", |_, this, (x, y, cost): (u32, u32, u8)| {
            this.inner.borrow_mut().set_cost(x - 1, y - 1, cost);
            Ok(())
        });

        /// Returns the cost.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current cost.
        methods.add_method("getCost", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cost(x - 1, y - 1))
        });

        methods.add_method(
            "setBlocked",
            |_, this, (x, y, blocked): (u32, u32, bool)| {
                this.inner.borrow_mut().set_blocked(x - 1, y - 1, blocked);
                Ok(())
            },
        );

        /// Returns `true` if blocked.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(x - 1, y - 1))
        });

        methods.add_method(
            "isWalkable",
            |_, this, (x, y, unit_size): (u32, u32, Option<u32>)| {
                let us = unit_size.unwrap_or(1);
                Ok(this.inner.borrow().is_walkable(x - 1, y - 1, us))
            },
        );

        /// Fill on this NavGrid.
        ///
        /// # Parameters
        /// - `cost` — `integer`.
        methods.add_method("fill", |_, this, cost: u8| {
            this.inner.borrow_mut().fill(cost);
            Ok(())
        });

        // 1-based rect coords
        methods.add_method(
            "fillRect",
            |_, this, (x, y, w, h, cost): (u32, u32, u32, u32, u8)| {
                this.inner.borrow_mut().fill_rect(x - 1, y - 1, w, h, cost);
                Ok(())
            },
        );

        /// Load from string on this NavGrid.
        ///
        /// # Parameters
        /// - `data` — `string`.
        methods.add_method("loadFromString", |_, this, data: LuaString| {
            this.inner
                .borrow_mut()
                .load_from_bytes(data.as_bytes())
                .map_err(LuaError::external)
        });

        /// Save to string on this NavGrid.
        ///
        /// # Parameters
        /// - `size` — `integer`.
        methods.add_method("saveToString", |lua, this, ()| {
            let bytes = this.inner.borrow().save_to_bytes();
            lua.create_string(&bytes)
        });

        /// Sets the chunk size.
        ///
        /// # Parameters
        /// - `size` — `integer`.
        methods.add_method("setChunkSize", |_, this, size: u32| {
            this.inner.borrow_mut().set_chunk_size(size);
            Ok(())
        });

        /// Returns the chunk size.
        ///
        /// # Returns
        /// The current chunk size.
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });

        /// Rebuild abstract on this NavGrid.
        ///
        /// # Returns
        /// The result.
        methods.add_method("rebuildAbstract", |_, this, ()| {
            let grid = this.inner.borrow();
            let chunk_size = grid.get_chunk_size();
            let graph = build_abstract(&grid, chunk_size);
            *this.abstract_graph.borrow_mut() = Some(graph);
            Ok(())
        });

        // 1-based dirty rect
        /// Sets the dirty.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        methods.add_method("setDirty", |_, this, (x, y, w, h): (u32, u32, u32, u32)| {
            this.inner.borrow_mut().set_dirty(x - 1, y - 1, w, h);
            Ok(())
        });

        /// Clear dirty on this NavGrid.
        ///
        /// # Parameters
        /// - `mode` — `string`.
        methods.add_method("clearDirty", |_, this, ()| {
            this.inner.borrow_mut().clear_dirty();
            Ok(())
        });

        /// Sets the diagonal mode.
        ///
        /// # Parameters
        /// - `mode` — `string`.
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

        /// Returns the diagonal mode.
        ///
        /// # Returns
        /// The current diagonal mode.
        methods.add_method("getDiagonalMode", |_, this, ()| {
            let dm = this.inner.borrow().get_diagonal_mode();
            let s = match dm {
                DiagonalMode::None => "none",
                DiagonalMode::Always => "always",
                DiagonalMode::NoCornerCut => "nocornercut",
            };
            Ok(s.to_string())
        });
    }
}

// ---------------------------------------------------------------------------
// LuaUnitPathfinder
// ---------------------------------------------------------------------------

/// Lua wrapper around a [`UnitPathfinder`].
#[derive(Clone)]
struct LuaUnitPathfinder {
    inner: Rc<RefCell<UnitPathfinder>>,
}

impl LunaType for LuaUnitPathfinder {
    const TYPE_NAME: &'static str = "UnitPathfinder";
    const TYPE_HIERARCHY: &'static [&'static str] = &["UnitPathfinder", "Object"];
}

/// Convert a slice of 0-based `Waypoint`s to a 1-based Lua table of `{x, y}`.
fn waypoints_to_lua<'a>(lua: &'a Lua, path: &[Waypoint]) -> LuaResult<LuaTable<'a>> {
    let tbl = lua.create_table()?;
    for (i, wp) in path.iter().enumerate() {
        let entry = lua.create_table()?;
        /// X on this UnitPathfinder.
        ///
        /// # Returns
        /// The result.
        entry.set("x", wp.x + 1)?;
        /// Y on this UnitPathfinder.
        ///
        /// # Returns
        /// The result.
        entry.set("y", wp.y + 1)?;
        tbl.set(i + 1, entry)?;
    }
    Ok(tbl)
}

/// Parse a Lua path table (array of `{x, y}`, 1-based) into 0-based `Waypoint`s.
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

impl LuaUserData for LuaUnitPathfinder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method(
            "findPath",
            |lua, this, (x1, y1, x2, y2, unit_size): (u32, u32, u32, u32, Option<u32>)| {
                let us = unit_size.unwrap_or(1);
                let result = this
                    .inner
                    .borrow_mut()
                    .find_path(x1 - 1, y1 - 1, x2 - 1, y2 - 1, us);
                match result {
                    Some(path) => Ok(LuaValue::Table(waypoints_to_lua(lua, &path)?)),
                    None => Ok(LuaValue::Nil),
                }
            },
        );

        methods.add_method(
            "findPathSmooth",
            |lua, this, (x1, y1, x2, y2, unit_size): (u32, u32, u32, u32, Option<u32>)| {
                let us = unit_size.unwrap_or(1);
                let result =
                    this.inner
                        .borrow_mut()
                        .find_path_smooth(x1 - 1, y1 - 1, x2 - 1, y2 - 1, us);
                match result {
                    Some(path) => Ok(LuaValue::Table(waypoints_to_lua(lua, &path)?)),
                    None => Ok(LuaValue::Nil),
                }
            },
        );

        /// Returns the path length.
        ///
        /// # Parameters
        /// - `path` — `table`.
        ///
        /// # Returns
        /// The current path length.
        methods.add_method("getPathLength", |_, _this, path: LuaTable| {
            let waypoints = lua_to_waypoints(&path)?;
            Ok(UnitPathfinder::get_path_length(&waypoints))
        });

        /// Returns the path cost.
        ///
        /// # Parameters
        /// - `path` — `table`.
        ///
        /// # Returns
        /// The current path cost.
        methods.add_method("getPathCost", |_, this, path: LuaTable| {
            let waypoints = lua_to_waypoints(&path)?;
            Ok(this.inner.borrow().get_path_cost(&waypoints))
        });

        methods.add_method(
            "findPartialPath",
            |lua,
             this,
             (x1, y1, x2, y2, max_nodes, unit_size): (
                u32,
                u32,
                u32,
                u32,
                u32,
                Option<u32>,
            )| {
                let us = unit_size.unwrap_or(1);
                let (path, complete) = this.inner.borrow().find_partial_path(
                    x1 - 1,
                    y1 - 1,
                    x2 - 1,
                    y2 - 1,
                    max_nodes,
                    us,
                );
                let tbl = waypoints_to_lua(lua, &path)?;
                Ok((tbl, complete))
            },
        );

        methods.add_method(
            "findNearestWalkable",
            |_, this, (x, y, max_radius, unit_size): (u32, u32, u32, Option<u32>)| {
                let us = unit_size.unwrap_or(1);
                match this
                    .inner
                    .borrow()
                    .find_nearest_walkable(x - 1, y - 1, max_radius, us)
                {
                    Some((rx, ry)) => Ok((
                        LuaValue::Integer((rx + 1) as i64),
                        LuaValue::Integer((ry + 1) as i64),
                    )),
                    None => Ok((LuaValue::Nil, LuaValue::Nil)),
                }
            },
        );

        methods.add_method(
            "isReachable",
            |_, this, (x1, y1, x2, y2, unit_size): (u32, u32, u32, u32, Option<u32>)| {
                let us = unit_size.unwrap_or(1);
                Ok(this
                    .inner
                    .borrow()
                    .is_reachable(x1 - 1, y1 - 1, x2 - 1, y2 - 1, us))
            },
        );

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

        methods.add_method(
            "lineOfSight",
            |_, this, (x1, y1, x2, y2, unit_size): (u32, u32, u32, u32, Option<u32>)| {
                let us = unit_size.unwrap_or(1);
                Ok(this
                    .inner
                    .borrow()
                    .line_of_sight(x1 - 1, y1 - 1, x2 - 1, y2 - 1, us))
            },
        );

        /// Sets the cache enabled.
        ///
        /// # Parameters
        /// - `enabled` — `boolean`.
        methods.add_method("setCacheEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_cache_enabled(enabled);
            Ok(())
        });

        /// Returns `true` if cache enabled.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isCacheEnabled", |_, this, ()| {
            Ok(this.inner.borrow().is_cache_enabled())
        });

        /// Clear cache on this UnitPathfinder.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clearCache", |_, this, ()| {
            this.inner.borrow_mut().clear_cache();
            Ok(())
        });

        /// Returns the cache size.
        ///
        /// # Parameters
        /// - `n` — `integer`.
        ///
        /// # Returns
        /// The current cache size.
        methods.add_method("getCacheSize", |_, this, ()| {
            Ok(this.inner.borrow().get_cache_size())
        });

        /// Sets the cache max size.
        ///
        /// # Parameters
        /// - `n` — `integer`.
        methods.add_method("setCacheMaxSize", |_, this, n: usize| {
            this.inner.borrow_mut().set_cache_max_size(n);
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// LuaFlowField
// ---------------------------------------------------------------------------

/// Lua wrapper around a [`FlowField`].
#[derive(Clone)]
struct LuaFlowField {
    inner: Rc<RefCell<FlowField>>,
}

impl LunaType for LuaFlowField {
    const TYPE_NAME: &'static str = "FlowField";
    const TYPE_HIERARCHY: &'static [&'static str] = &["FlowField", "Object"];
}

impl LuaUserData for LuaFlowField {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method(
            "calculate",
            |_, this, (tx, ty, unit_size): (u32, u32, Option<u32>)| {
                let us = unit_size.unwrap_or(1);
                this.inner.borrow_mut().calculate(tx - 1, ty - 1, us);
                Ok(())
            },
        );

        methods.add_method(
            "calculateMulti",
            |_, this, (targets, unit_size): (LuaTable, Option<u32>)| {
                let us = unit_size.unwrap_or(1);
                let mut pts = Vec::new();
                for pair in targets.sequence_values::<LuaTable>() {
                    let entry = pair?;
                    let x: u32 = entry.get("x")?;
                    let y: u32 = entry.get("y")?;
                    pts.push((x - 1, y - 1));
                }
                this.inner.borrow_mut().calculate_multi(&pts, us);
                Ok(())
            },
        );

        /// Returns the direction.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current direction.
        methods.add_method("getDirection", |_, this, (x, y): (u32, u32)| {
            let (dx, dy) = this.inner.borrow().get_direction(x - 1, y - 1);
            Ok((dx, dy))
        });

        /// Returns the direction angle.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current direction angle.
        methods.add_method("getDirectionAngle", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_direction_angle(x - 1, y - 1))
        });

        /// Returns the cost to target.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current cost to target.
        methods.add_method("getCostToTarget", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cost_to_target(x - 1, y - 1))
        });

        /// Returns `true` if calculated.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isCalculated", |_, this, ()| {
            Ok(this.inner.borrow().is_calculated())
        });

        /// Returns the targets.
        ///
        /// # Returns
        /// The current targets.
        methods.add_method("getTargets", |lua, this, ()| {
            let targets = this.inner.borrow().get_targets();
            let tbl = lua.create_table()?;
            for (i, (x, y)) in targets.iter().enumerate() {
                let entry = lua.create_table()?;
                /// X on this FlowField.
                ///
                /// # Returns
                /// The result.
                entry.set("x", x + 1)?;
                /// Y on this FlowField.
                ///
                /// # Returns
                /// The result.
                entry.set("y", y + 1)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        });

        methods.add_method(
            "steer",
            |_, this, (wx, wy, speed, tw, th): (f32, f32, f32, f32, f32)| {
                let (vx, vy) = this.inner.borrow().steer(wx, wy, speed, tw, th);
                Ok((vx, vy))
            },
        );
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Register the `luna.pathfinding` namespace.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let pathfinding = lua.create_table()?;

    // luna.pathfinding.newNavGrid(width, height)
    pathfinding.set(
        "newNavGrid",
        lua.create_function(|_, (width, height): (u32, u32)| {
            Ok(LuaNavGrid {
                inner: Rc::new(RefCell::new(NavGrid::new(width, height))),
                abstract_graph: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;

    // luna.pathfinding.newNavGridFromTileMap(tilemap, layer, blockedGids)
    pathfinding.set(
        "newNavGridFromTileMap",
        lua.create_function(
            |_, (tilemap_ud, layer, blocked): (LuaAnyUserData, usize, LuaTable)| {
                let tm = tilemap_ud
                    .borrow::<super::tilemap_api::LuaTileMap>()
                    .map_err(|_| {
                        mlua::Error::RuntimeError(
                            "expected TileMap userdata as first argument".into(),
                        )
                    })?;
                let map = tm.inner.borrow();
                let lua_layer = layer
                    .checked_sub(1)
                    .ok_or_else(|| mlua::Error::RuntimeError("layer index must be >= 1".into()))?;
                let (w, h) = map.get_layer_dimensions(lua_layer).ok_or_else(|| {
                    mlua::Error::RuntimeError(format!("layer {} does not exist", layer))
                })?;
                let mut blocked_set = std::collections::HashSet::new();
                for v in blocked.sequence_values::<u32>() {
                    blocked_set.insert(v?);
                }
                let mut costs = Vec::with_capacity((w * h) as usize);
                for y in 0..h {
                    for x in 0..w {
                        let gid = map.get_tile(lua_layer, x, y);
                        if gid == 0 || blocked_set.contains(&gid) {
                            costs.push(0u8);
                        } else {
                            costs.push(1u8);
                        }
                    }
                }
                Ok(LuaNavGrid {
                    inner: Rc::new(RefCell::new(NavGrid::from_costs(w, h, costs))),
                    abstract_graph: Rc::new(RefCell::new(None)),
                })
            },
        )?,
    )?;

    // luna.pathfinding.newPathfinder(navGrid)
    pathfinding.set(
        "newPathfinder",
        lua.create_function(|_, grid_ud: LuaAnyUserData| {
            let grid = grid_ud.borrow::<LuaNavGrid>()?;
            Ok(LuaUnitPathfinder {
                inner: Rc::new(RefCell::new(UnitPathfinder::new(grid.inner.clone()))),
            })
        })?,
    )?;

    // luna.pathfinding.newFlowField(navGrid)
    pathfinding.set(
        "newFlowField",
        lua.create_function(|_, grid_ud: LuaAnyUserData| {
            let grid = grid_ud.borrow::<LuaNavGrid>()?;
            Ok(LuaFlowField {
                inner: Rc::new(RefCell::new(FlowField::new(grid.inner.clone()))),
            })
        })?,
    )?;

    // luna.pathfinding.setThreadCount(count) — no-op for now
    pathfinding.set(
        "setThreadCount",
        lua.create_function(|_, _count: u32| {
            log::warn!("luna.pathfinding.setThreadCount: async pathfinding not yet exposed to Lua");
            Ok(())
        })?,
    )?;

    // luna.pathfinding.getThreadCount() — returns 0 until async is wired up
    pathfinding.set(
        "getThreadCount",
        lua.create_function(|_, ()| -> LuaResult<u32> { Ok(0) })?,
    )?;

    /// Pathfinding on this FlowField.
    ///
    /// # Returns
    /// The result.
    luna.set("pathfinding", pathfinding)?;
    Ok(())
}
