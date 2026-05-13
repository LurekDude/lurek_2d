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
pub struct LuaNavGrid {
    inner: Rc<RefCell<NavGrid>>,
    abstract_graph: Rc<RefCell<Option<AbstractGraph>>>,
}
impl LuaUserData for LuaNavGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_dimensions())
        });
        methods.add_method("setCost", |_, this, (x, y, cost): (u32, u32, u8)| {
            this.inner.borrow_mut().set_cost(x - 1, y - 1, cost);
            Ok(())
        });
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
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(x - 1, y - 1))
        });
        methods.add_method(
            "isWalkable",
            |_, this, (x, y, unit_size): (u32, u32, Option<u32>)| {
                Ok(this
                    .inner
                    .borrow()
                    .is_walkable(x - 1, y - 1, unit_size.unwrap_or(1)))
            },
        );
        methods.add_method("fill", |_, this, cost: u8| {
            this.inner.borrow_mut().fill(cost);
            Ok(())
        });
        methods.add_method(
            "fillRect",
            |_, this, (x, y, w, h, cost): (u32, u32, u32, u32, u8)| {
                this.inner.borrow_mut().fill_rect(x - 1, y - 1, w, h, cost);
                Ok(())
            },
        );
        methods.add_method("loadFromString", |_, this, data: LuaString| {
            this.inner
                .borrow_mut()
                .load_from_bytes(data.as_bytes())
                .map_err(LuaError::external)
        });
        methods.add_method("saveToString", |lua, this, ()| {
            lua.create_string(this.inner.borrow().save_to_bytes())
        });
        methods.add_method("setChunkSize", |_, this, size: u32| {
            this.inner.borrow_mut().set_chunk_size(size);
            Ok(())
        });
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });
        methods.add_method("rebuildAbstract", |_, this, ()| {
            let grid = this.inner.borrow();
            let chunk_size = grid.get_chunk_size();
            let graph = build_abstract(&grid, chunk_size);
            *this.abstract_graph.borrow_mut() = Some(graph);
            Ok(())
        });
        methods.add_method("setDirty", |_, this, (x, y, w, h): (u32, u32, u32, u32)| {
            this.inner.borrow_mut().set_dirty(x - 1, y - 1, w, h);
            Ok(())
        });
        methods.add_method("clearDirty", |_, this, ()| {
            this.inner.borrow_mut().clear_dirty();
            Ok(())
        });
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
        methods.add_method("getDiagonalMode", |_, this, ()| {
            Ok(this
                .inner
                .borrow()
                .get_diagonal_mode()
                .to_lua_str()
                .to_string())
        });
        methods.add_method("type", |_, _, ()| Ok("LNavGrid"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNavGrid" || name == "NavGrid" || name == "Object")
        });
    }
}
pub struct LuaUnitPathfinder {
    inner: Rc<RefCell<UnitPathfinder>>,
}
impl LuaUserData for LuaUnitPathfinder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("getPathLength", |_, _this, path: LuaTable| {
            let waypoints = lua_to_waypoints(&path)?;
            Ok(UnitPathfinder::get_path_length(&waypoints))
        });
        methods.add_method("getPathCost", |_, this, path: LuaTable| {
            let waypoints = lua_to_waypoints(&path)?;
            Ok(this.inner.borrow().get_path_cost(&waypoints))
        });
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
                Ok(this.inner.borrow().line_of_sight(
                    x1 - 1,
                    y1 - 1,
                    x2 - 1,
                    y2 - 1,
                    unit_size.unwrap_or(1),
                ))
            },
        );
        methods.add_method("setCacheEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_cache_enabled(enabled);
            Ok(())
        });
        methods.add_method("isCacheEnabled", |_, this, ()| {
            Ok(this.inner.borrow().is_cache_enabled())
        });
        methods.add_method("clearCache", |_, this, ()| {
            this.inner.borrow_mut().clear_cache();
            Ok(())
        });
        methods.add_method("getCacheSize", |_, this, ()| {
            Ok(this.inner.borrow().get_cache_size())
        });
        methods.add_method("setCacheMaxSize", |_, this, n: usize| {
            this.inner.borrow_mut().set_cache_max_size(n);
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LUnitPathfinder"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LUnitPathfinder" || name == "Object")
        });
    }
}
pub struct LuaFlowField {
    inner: Rc<RefCell<FlowField>>,
}
impl LuaUserData for LuaFlowField {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method(
            "calculate",
            |_, this, (tx, ty, unit_size): (u32, u32, Option<u32>)| {
                this.inner
                    .borrow_mut()
                    .calculate(tx - 1, ty - 1, unit_size.unwrap_or(1));
                Ok(())
            },
        );
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
        methods.add_method("getDirection", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_direction(x - 1, y - 1))
        });
        methods.add_method("getDirectionAngle", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_direction_angle(x - 1, y - 1))
        });
        methods.add_method("getCostToTarget", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cost_to_target(x - 1, y - 1))
        });
        methods.add_method("isCalculated", |_, this, ()| {
            Ok(this.inner.borrow().is_calculated())
        });
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
        methods.add_method(
            "steer",
            |_, this, (wx, wy, speed, tw, th): (f32, f32, f32, f32, f32)| {
                Ok(this.inner.borrow().steer(wx, wy, speed, tw, th))
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LFlowField"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFlowField" || name == "Object")
        });
    }
}
pub struct LuaPathGrid {
    inner: Rc<RefCell<PathGrid>>,
}
impl LuaUserData for LuaPathGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().width as u32)
        });
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().height as u32)
        });
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size)
        });
        methods.add_method("setWalkable", |_, this, (x, y, w): (usize, usize, bool)| {
            this.inner.borrow_mut().set_walkable(x - 1, y - 1, w);
            Ok(())
        });
        methods.add_method("isWalkable", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().is_walkable(x - 1, y - 1))
        });
        methods.add_method("setCost", |_, this, (x, y, cost): (usize, usize, f32)| {
            this.inner.borrow_mut().set_cost(x - 1, y - 1, cost);
            Ok(())
        });
        methods.add_method("getCost", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().get_cost(x - 1, y - 1))
        });
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
        methods.add_method("type", |_, _, ()| Ok("LPathGrid"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPathGrid" || name == "Object")
        });
    }
}
pub struct LuaAiFlowField {
    inner: Rc<RefCell<AiFlowField>>,
}
impl LuaUserData for LuaAiFlowField {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().width as u32)
        });
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().height as u32)
        });
        methods.add_method("hasGoal", |_, this, ()| {
            Ok(this.inner.borrow().goal.is_some())
        });
        methods.add_method("setGoal", |_, this, (x, y): (usize, usize)| {
            this.inner.borrow_mut().set_goal(x - 1, y - 1);
            Ok(())
        });
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
        methods.add_method("getDirection", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().get_direction(x - 1, y - 1))
        });
        methods.add_method("getDistance", |_, this, (x, y): (usize, usize)| {
            Ok(this.inner.borrow().get_distance(x - 1, y - 1))
        });
        methods.add_method("type", |_, _, ()| Ok("LAIFlowField"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAIFlowField" || name == "Object")
        });
    }
}
pub struct LuaHexGrid {
    inner: Rc<RefCell<HexGrid>>,
}
impl LuaUserData for LuaHexGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "setBlocked",
            |_, this, (col, row, blocked): (u32, u32, bool)| {
                this.inner
                    .borrow_mut()
                    .set_blocked(col - 1, row - 1, blocked);
                Ok(())
            },
        );
        methods.add_method_mut("setCost", |_, this, (col, row, cost): (u32, u32, f32)| {
            this.inner.borrow_mut().set_cost(col - 1, row - 1, cost);
            Ok(())
        });
        methods.add_method("isBlocked", |_, this, (col, row): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(col - 1, row - 1))
        });
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
        methods.add_method(
            "lineOfSight",
            |_, this, (fc, fr, tc, tr): (u32, u32, u32, u32)| {
                Ok(this
                    .inner
                    .borrow()
                    .line_of_sight((fc - 1, fr - 1), (tc - 1, tr - 1)))
            },
        );
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
        methods.add_method(
            "distance",
            |_, this, (c1, r1, c2, r2): (u32, u32, u32, u32)| {
                Ok(this
                    .inner
                    .borrow()
                    .distance((c1 - 1, r1 - 1), (c2 - 1, r2 - 1)))
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LHexGrid"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHexGrid" || name == "Object")
        });
    }
}
pub struct LuaJpsGrid {
    inner: Rc<RefCell<JpsGrid>>,
}
impl LuaUserData for LuaJpsGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "setBlocked",
            |_, this, (x, y, blocked): (u32, u32, bool)| {
                this.inner.borrow_mut().set_blocked(x - 1, y - 1, blocked);
                Ok(())
            },
        );
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(x - 1, y - 1))
        });
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
        methods.add_method("type", |_, _, ()| Ok("LJpsGrid"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LJpsGrid" || name == "Object")
        });
    }
}
pub struct LuaNavMesh {
    inner: Rc<RefCell<NavMesh>>,
}
impl LuaUserData for LuaNavMesh {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("getPolygonCount", |_, this, ()| {
            Ok(this.inner.borrow().polygon_count() as u32)
        });
        methods.add_method("type", |_, _, ()| Ok("LNavMesh"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNavMesh" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newNavGrid",
        lua.create_function(|_, (width, height): (u32, u32)| {
            Ok(LuaNavGrid {
                inner: Rc::new(RefCell::new(NavGrid::new(width, height))),
                abstract_graph: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;
    tbl.set(
        "newPathfinder",
        lua.create_function(|_, grid_ud: LuaAnyUserData| {
            let grid = grid_ud.borrow::<LuaNavGrid>()?;
            Ok(LuaUnitPathfinder {
                inner: Rc::new(RefCell::new(UnitPathfinder::new(grid.inner.clone()))),
            })
        })?,
    )?;
    tbl.set(
        "newFlowField",
        lua.create_function(|_, grid_ud: LuaAnyUserData| {
            let grid = grid_ud.borrow::<LuaNavGrid>()?;
            Ok(LuaFlowField {
                inner: Rc::new(RefCell::new(FlowField::new(grid.inner.clone()))),
            })
        })?,
    )?;
    tbl.set(
        "newPathGrid",
        lua.create_function(|_, (w, h, cell_size): (usize, usize, f32)| {
            Ok(LuaPathGrid {
                inner: Rc::new(RefCell::new(PathGrid::new(w, h, cell_size))),
            })
        })?,
    )?;
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
    tbl.set(
        "setThreadCount",
        lua.create_function(|_, _count: u32| {
            log_msg!(warn, LA08_PATHFINDING_THREAD_UNIMPL);
            Ok(())
        })?,
    )?;
    tbl.set(
        "getThreadCount",
        lua.create_function(|_, ()| -> LuaResult<u32> { Ok(0) })?,
    )?;
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
    tbl.set(
        "newJpsGrid",
        lua.create_function(|_, (width, height): (u32, u32)| {
            Ok(LuaJpsGrid {
                inner: Rc::new(RefCell::new(JpsGrid::new(width, height))),
            })
        })?,
    )?;
    tbl.set(
        "newNavMesh",
        lua.create_function(|_, ()| {
            Ok(LuaNavMesh {
                inner: Rc::new(RefCell::new(NavMesh::new())),
            })
        })?,
    )?;
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
