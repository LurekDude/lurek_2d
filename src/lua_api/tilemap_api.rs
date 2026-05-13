use super::SharedState;
use crate::math::Rect;
use crate::tilemap::autotile_sheet::{AutoTileLayout, AutoTileSheet};
use crate::tilemap::chunk::ChunkMap;
use crate::tilemap::coords;
use crate::tilemap::isomap::IsoMap;
use crate::tilemap::large_map_renderer::LargeMapRenderer;
use crate::tilemap::ldtk::load_ldtk;
use crate::tilemap::mapgen::{
    Edge, MapBlock, MapGen, MapGroup, MapOrientation, MapScript, MapSize, ScriptStep, StepType,
};
use crate::tilemap::tilemap::TileMap;
use crate::tilemap::tileset::{TileAnimFrame, TileSet};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
fn one_based_usize(name: &str, val: usize) -> LuaResult<usize> {
    val.checked_sub(1)
        .ok_or_else(|| mlua::Error::RuntimeError(format!("{name} must be >= 1 (got {val})")))
}
fn one_based_u32(name: &str, val: u32) -> LuaResult<u32> {
    val.checked_sub(1)
        .ok_or_else(|| mlua::Error::RuntimeError(format!("{name} must be >= 1 (got {val})")))
}
#[derive(Clone)]
pub struct LuaTileSet {
    inner: Rc<RefCell<TileSet>>,
}
impl LuaUserData for LuaTileSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getFirstGid", |_, this, ()| {
            Ok(this.inner.borrow().get_first_gid())
        });
        methods.add_method("getTileCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_count())
        });
        methods.add_method("getColumns", |_, this, ()| {
            Ok(this.inner.borrow().get_columns())
        });
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });
        methods.add_method("getTileDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_tile_dimensions();
            Ok((w, h))
        });
        methods.add_method("getSpacing", |_, this, ()| {
            Ok(this.inner.borrow().get_spacing())
        });
        methods.add_method("getMargin", |_, this, ()| {
            Ok(this.inner.borrow().get_margin())
        });
        methods.add_method("getQuad", |lua, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getQuad: tile_id must be >= 1".to_string(),
                ));
            }
            let r = this.inner.borrow().get_quad(tile_id - 1);
            let tbl = lua.create_table()?;
            tbl.set("x", r.x)?;
            tbl.set("y", r.y)?;
            tbl.set("width", r.width)?;
            tbl.set("height", r.height)?;
            Ok(tbl)
        });
        methods.add_method(
            "setAnimation",
            |_, this, (tile_id, frames): (u32, LuaTable)| {
                if tile_id == 0 {
                    return Err(LuaError::RuntimeError(
                        "setAnimation: tile_id must be >= 1".to_string(),
                    ));
                }
                let mut anim_frames = Vec::new();
                for pair in frames.sequence_values::<LuaTable>() {
                    let frame_tbl = pair?;
                    let fid: u32 = frame_tbl.get("tileid")?;
                    let dur: f32 = frame_tbl.get("duration")?;
                    if fid == 0 {
                        return Err(LuaError::RuntimeError(
                            "setAnimation: frame tileid must be >= 1".to_string(),
                        ));
                    }
                    anim_frames.push(TileAnimFrame {
                        tile_id: fid - 1,
                        duration_ms: dur,
                    });
                }
                this.inner
                    .borrow_mut()
                    .set_animation(tile_id - 1, anim_frames);
                Ok(())
            },
        );
        methods.add_method("getAnimation", |lua, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getAnimation: tile_id must be >= 1".to_string(),
                ));
            }
            let inner = this.inner.borrow();
            match inner.get_animation(tile_id - 1) {
                Some(frames) => {
                    let tbl = lua.create_table()?;
                    for (i, f) in frames.iter().enumerate() {
                        let entry = lua.create_table()?;
                        entry.set("tileid", f.tile_id + 1)?;
                        entry.set("duration", f.duration_ms)?;
                        tbl.set(i + 1, entry)?;
                    }
                    Ok(LuaValue::Table(tbl))
                }
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("setSolid", |_, this, (tile_id, solid): (u32, bool)| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "setSolid: tile_id must be >= 1".to_string(),
                ));
            }
            this.inner.borrow_mut().set_solid(tile_id - 1, solid);
            Ok(())
        });
        methods.add_method("isSolid", |_, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "isSolid: tile_id must be >= 1".to_string(),
                ));
            }
            Ok(this.inner.borrow().is_solid(tile_id - 1))
        });
        methods.add_method(
            "setAutoTileRule",
            |_, this, (type_name, bitmask, tile_id): (String, u8, u32)| {
                if tile_id == 0 {
                    return Err(LuaError::RuntimeError(
                        "setAutoTileRule: tileId must be >= 1".to_string(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_auto_tile_rule(&type_name, bitmask, tile_id - 1);
                Ok(())
            },
        );
        methods.add_method(
            "getAutoTileId",
            |_, this, (type_name, bitmask): (String, u8)| {
                Ok(this
                    .inner
                    .borrow()
                    .get_auto_tile_id(&type_name, bitmask)
                    .map(|id| id + 1))
            },
        );
        methods.add_method(
            "setAutoTileRule8",
            |_, this, (type_name, bitmask, tile_id): (String, u16, u32)| {
                if tile_id == 0 {
                    return Err(LuaError::RuntimeError(
                        "setAutoTileRule8: tileId must be >= 1".to_string(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_auto_tile_rule_8(&type_name, bitmask, tile_id - 1);
                Ok(())
            },
        );
        methods.add_method(
            "getAutoTileId8",
            |_, this, (type_name, bitmask): (String, u16)| {
                Ok(this
                    .inner
                    .borrow()
                    .get_auto_tile_id_8(&type_name, bitmask)
                    .map(|id| id + 1))
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LTileSet"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTileSet" || name == "Object")
        });
    }
}
pub struct LuaTileMap {
    pub(super) inner: Rc<RefCell<TileMap>>,
    state: Rc<RefCell<SharedState>>,
    tile_callbacks: Rc<RefCell<Vec<(u32, LuaRegistryKey)>>>,
    tile_exit_callbacks: Rc<RefCell<HashMap<u32, LuaRegistryKey>>>,
    tile_step_callbacks: Rc<RefCell<HashMap<u32, LuaRegistryKey>>>,
}
impl LuaUserData for LuaTileMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("addTileSet", |_, this, ts_ud: LuaAnyUserData| {
            let ts = ts_ud.borrow::<LuaTileSet>()?;
            this.inner
                .borrow_mut()
                .add_tileset(ts.inner.borrow().clone());
            Ok(())
        });
        methods.add_method("getTileSetCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tileset_count())
        });
        methods.add_method("getTileSet", |_, this, idx: usize| {
            if idx == 0 {
                return Err(LuaError::RuntimeError(
                    "getTileSet: idx must be >= 1".to_string(),
                ));
            }
            let inner = this.inner.borrow();
            match inner.get_tileset(idx - 1) {
                Some(ts) => Ok(Some(LuaTileSet {
                    inner: Rc::new(RefCell::new(ts.clone())),
                })),
                None => Ok(None),
            }
        });
        methods.add_method("addLayer", |_, this, (name, w, h): (String, u32, u32)| {
            let idx = this.inner.borrow_mut().add_layer(&name, w, h);
            Ok(idx + 1)
        });
        methods.add_method("getLayerCount", |_, this, ()| {
            Ok(this.inner.borrow().get_layer_count())
        });
        methods.add_method("getLayerName", |_, this, idx: usize| {
            Ok(this
                .inner
                .borrow()
                .get_layer_name(idx - 1)
                .map(|s| s.to_string()))
        });
        methods.add_method(
            "setLayerVisible",
            |_, this, (idx, visible): (usize, bool)| {
                this.inner.borrow_mut().set_layer_visible(idx - 1, visible);
                Ok(())
            },
        );
        methods.add_method("getLayerVisible", |_, this, idx: usize| {
            Ok(this.inner.borrow().get_layer_visible(idx - 1))
        });
        methods.add_method(
            "setLayerColor",
            |_, this, (idx, r, g, b, a): (usize, f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_layer_color(idx - 1, r, g, b, a);
                Ok(())
            },
        );
        methods.add_method("getLayerColor", |_, this, idx: usize| {
            let c = this.inner.borrow().get_layer_color(idx - 1);
            Ok((c[0], c[1], c[2], c[3]))
        });
        methods.add_method(
            "setLayerOffset",
            |_, this, (idx, ox, oy): (usize, f32, f32)| {
                this.inner.borrow_mut().set_layer_offset(idx - 1, ox, oy);
                Ok(())
            },
        );
        methods.add_method("getLayerOffset", |_, this, idx: usize| {
            let v = this.inner.borrow().get_layer_offset(idx - 1);
            Ok((v.x, v.y))
        });
        methods.add_method(
            "setLayerParallax",
            |_, this, (idx, px, py): (usize, f32, f32)| {
                this.inner.borrow_mut().set_layer_parallax(idx - 1, px, py);
                Ok(())
            },
        );
        methods.add_method("getLayerParallax", |_, this, idx: usize| {
            let v = this.inner.borrow().get_layer_parallax(idx - 1);
            Ok((v.x, v.y))
        });
        methods.add_method(
            "setTile",
            |_, this, (layer, x, y, gid): (usize, u32, u32, u32)| {
                this.inner
                    .borrow_mut()
                    .set_tile(layer - 1, x - 1, y - 1, gid);
                Ok(())
            },
        );
        methods.add_method("getTile", |_, this, (layer, x, y): (usize, u32, u32)| {
            Ok(this.inner.borrow().get_tile(layer - 1, x - 1, y - 1))
        });
        methods.add_method("clearTile", |_, this, (layer, x, y): (usize, u32, u32)| {
            this.inner.borrow_mut().clear_tile(layer - 1, x - 1, y - 1);
            Ok(())
        });
        methods.add_method("fill", |_, this, (layer, gid): (usize, u32)| {
            this.inner.borrow_mut().fill(layer - 1, gid);
            Ok(())
        });
        methods.add_method("tileTypeIndex", |lua, this, layer: usize| {
            if layer == 0 {
                return Err(mlua::Error::RuntimeError("layer must be >= 1".into()));
            }
            let index = this.inner.borrow().tile_type_index(layer - 1);
            let result = lua.create_table()?;
            for (gid, positions) in index {
                let arr = lua.create_table()?;
                for (i, (x, y)) in positions.iter().enumerate() {
                    let pos = lua.create_table()?;
                    pos.set("x", *x)?;
                    pos.set("y", *y)?;
                    arr.set(i + 1, pos)?;
                }
                result.set(gid, arr)?;
            }
            Ok(result)
        });
        methods.add_method("findTilesByGid", |lua, this, (layer, gid): (usize, u32)| {
            if layer == 0 {
                return Err(mlua::Error::RuntimeError("layer must be >= 1".into()));
            }
            let positions = this.inner.borrow().find_tiles_by_gid(layer - 1, gid);
            let arr = lua.create_table()?;
            for (i, (x, y)) in positions.iter().enumerate() {
                let pos = lua.create_table()?;
                pos.set("x", *x)?;
                pos.set("y", *y)?;
                arr.set(i + 1, pos)?;
            }
            Ok(arr)
        });
        methods.add_method(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport(x, y, w, h);
                Ok(())
            },
        );
        methods.add_method("getViewport", |_, this, ()| {
            match this.inner.borrow().get_viewport() {
                Some((x, y, w, h)) => Ok((Some(x), Some(y), Some(w), Some(h))),
                None => Ok((None, None, None, None)),
            }
        });
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        methods.add_method("worldToTile", |_, this, (wx, wy): (f32, f32)| {
            let (tx, ty) = this.inner.borrow().world_to_tile(wx, wy);
            Ok((tx + 1, ty + 1))
        });
        methods.add_method("tileToWorld", |_, this, (tx, ty): (u32, u32)| {
            let (wx, wy) = this.inner.borrow().tile_to_world(tx - 1, ty - 1);
            Ok((wx, wy))
        });
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });
        methods.add_method("getTileDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_tile_dimensions();
            Ok((w, h))
        });
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });
        methods.add_method("isSolid", |_, this, (layer, x, y): (usize, u32, u32)| {
            Ok(this.inner.borrow().is_solid(layer - 1, x - 1, y - 1))
        });
        methods.add_method(
            "applyAutoTile",
            |_, this, (layer, type_name): (usize, String)| {
                this.inner
                    .borrow_mut()
                    .apply_autotile(layer - 1, &type_name);
                Ok(())
            },
        );
        methods.add_method(
            "applyAutoTileAt",
            |_, this, (layer, x, y, type_name): (usize, u32, u32, String)| {
                this.inner
                    .borrow_mut()
                    .apply_autotile_at(layer - 1, x - 1, y - 1, &type_name);
                Ok(())
            },
        );
        methods.add_method(
            "applyAutoTile8",
            |_, this, (layer, type_name): (usize, String)| {
                this.inner
                    .borrow_mut()
                    .apply_autotile_8(layer - 1, &type_name);
                Ok(())
            },
        );
        methods.add_method(
            "applyAutoTile8At",
            |_, this, (layer, x, y, type_name): (usize, u32, u32, String)| {
                this.inner
                    .borrow_mut()
                    .apply_autotile_8_at(layer - 1, x - 1, y - 1, &type_name);
                Ok(())
            },
        );
        methods.add_method(
            "rectOverlapsSolid",
            |_, this, (layer, x, y, w, h): (usize, f32, f32, f32, f32)| {
                Ok(this
                    .inner
                    .borrow()
                    .rect_overlaps_solid(layer - 1, Rect::new(x, y, w, h)))
            },
        );
        methods.add_method(
            "sweepRect",
            |_, this, (layer, x, y, w, h, dx, dy): (usize, f32, f32, f32, f32, f32, f32)| match this
                .inner
                .borrow()
                .sweep_rect(layer - 1, Rect::new(x, y, w, h), dx, dy)
            {
                Some(result) => Ok((
                    result.contact_point.x,
                    result.contact_point.y,
                    result.normal.x,
                    result.normal.y,
                    (result.tile_x + 1) as f32,
                    (result.tile_y + 1) as f32,
                )),
                None => Ok((x + dx, y + dy, 0.0f32, 0.0f32, 0.0f32, 0.0f32)),
            },
        );
        methods.add_method("getOrientation", |_, this, ()| {
            let o = this.inner.borrow().get_orientation();
            Ok(match o {
                MapOrientation::TopDown => "topdown",
                MapOrientation::SideView => "sideview",
                MapOrientation::Isometric => "isometric",
                MapOrientation::Hexagonal => "hexagonal",
            })
        });
        methods.add_method("setOrientation", |_, this, orientation: String| {
            let o = match orientation.as_str() {
                "topdown" => MapOrientation::TopDown,
                "sideview" => MapOrientation::SideView,
                "isometric" => MapOrientation::Isometric,
                "hexagonal" => MapOrientation::Hexagonal,
                other => {
                    return Err(LuaError::RuntimeError(format!(
                    "setOrientation: unknown '{}' (valid: topdown, sideview, isometric, hexagonal)",
                    other
                )))
                }
            };
            this.inner.borrow_mut().set_orientation(o);
            Ok(())
        });
        methods.add_method(
            "setTileTint",
            |_, this, (layer, x, y, r, g, b, a): (usize, u32, u32, f32, f32, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .set_tile_tint(layer - 1, x - 1, y - 1, r, g, b, a);
                Ok(())
            },
        );
        methods.add_method("render", |_, this, (ox, oy): (Option<f32>, Option<f32>)| {
            let sx = ox.unwrap_or(0.0);
            let sy = oy.unwrap_or(0.0);
            let cmds = this.inner.borrow().build_render_commands(sx, sy);
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });
        methods.add_method("drawToImage", |_, this, tile_size: u32| {
            let img = this.inner.borrow().draw_to_image(tile_size);
            Ok(img)
        });
        methods.add_method(
            "toNavGrid",
            |lua, this, (layer, gids_tbl): (usize, LuaTable)| {
                let mut gids: Vec<u32> = Vec::new();
                for v in gids_tbl.sequence_values::<u32>() {
                    gids.push(v?);
                }
                let grid = this.inner.borrow().to_nav_grid(layer, &gids);
                let outer = lua.create_table()?;
                for (row_idx, row) in grid.iter().enumerate() {
                    let inner_tbl = lua.create_table()?;
                    for (col_idx, &walkable) in row.iter().enumerate() {
                        inner_tbl.set(col_idx + 1, walkable)?;
                    }
                    outer.set(row_idx + 1, inner_tbl)?;
                }
                Ok(outer)
            },
        );
        methods.add_method_mut(
            "onTileEnter",
            |lua, this, (gid, func): (u32, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                this.tile_callbacks.borrow_mut().push((gid, key));
                Ok(())
            },
        );
        methods.add_method(
            "checkEntities",
            |lua, this, (layer, entities): (usize, LuaTable)| {
                let callbacks = this.tile_callbacks.borrow();
                if callbacks.is_empty() {
                    return Ok(());
                }
                for entity_val in entities.sequence_values::<LuaTable>() {
                    let entity = entity_val?;
                    let wx: f32 = entity.get("x").or_else(|_| entity.get(1)).unwrap_or(0.0);
                    let wy: f32 = entity.get("y").or_else(|_| entity.get(2)).unwrap_or(0.0);
                    let map = this.inner.borrow();
                    let (tx, ty) = map.world_to_tile(wx, wy);
                    let gid = map.get_tile(layer, tx, ty);
                    drop(map);
                    for (cb_gid, key) in callbacks.iter() {
                        if *cb_gid == gid {
                            let func: LuaFunction = lua.registry_value(key)?;
                            func.call::<_, ()>((wx, wy, tx, ty))?;
                        }
                    }
                }
                Ok(())
            },
        );
        methods.add_method_mut(
            "onTileStep",
            |lua, this, (gid, func): (u32, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                this.tile_step_callbacks.borrow_mut().insert(gid, key);
                Ok(())
            },
        );
        methods.add_method_mut(
            "onTileExit",
            |lua, this, (gid, func): (u32, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                this.tile_exit_callbacks.borrow_mut().insert(gid, key);
                Ok(())
            },
        );
        methods.add_method(
            "fireTileStep",
            |lua, this, (gid, entity, tx, ty): (u32, LuaTable, i32, i32)| {
                if let Some(key) = this.tile_step_callbacks.borrow().get(&gid) {
                    let func: mlua::Function = lua.registry_value(key)?;
                    let _: () = func.call((entity, tx, ty))?;
                }
                Ok(())
            },
        );
        methods.add_method(
            "fireTileExit",
            |lua, this, (gid, entity, tx, ty): (u32, LuaTable, i32, i32)| {
                if let Some(key) = this.tile_exit_callbacks.borrow().get(&gid) {
                    let func: mlua::Function = lua.registry_value(key)?;
                    let _: () = func.call((entity, tx, ty))?;
                }
                Ok(())
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LTileMap"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTileMap" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaAutoTileSheet {
    inner: Rc<RefCell<AutoTileSheet>>,
}
impl LuaUserData for LuaAutoTileSheet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getLayout", |_, this, ()| {
            let l = this.inner.borrow().get_layout();
            Ok(match l {
                AutoTileLayout::Blob47 => "blob47",
                AutoTileLayout::Composite48 => "composite48",
                AutoTileLayout::Minimal16 => "minimal16",
            })
        });
        methods.add_method("getTileCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_count())
        });
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });
        methods.add_method(
            "applyToTileSet",
            |_, this, (ts_ud, type_name, start_gid): (LuaAnyUserData, String, Option<u32>)| {
                let ts = ts_ud.borrow::<LuaTileSet>()?;
                this.inner.borrow().apply_to_tileset(
                    &mut ts.inner.borrow_mut(),
                    &type_name,
                    start_gid,
                );
                Ok(())
            },
        );
        methods.add_method("getBitmaskForTile", |_, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getBitmaskForTile: tile_id must be >= 1".to_string(),
                ));
            }
            Ok(this.inner.borrow().get_bitmask_for_tile(tile_id - 1))
        });
        methods.add_method("getTileForBitmask", |_, this, bitmask: u16| {
            Ok(this
                .inner
                .borrow()
                .get_tile_for_bitmask(bitmask)
                .map(|idx| idx + 1))
        });
        methods.add_method("getQuad", |_, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getQuad: tile_id must be >= 1".to_string(),
                ));
            }
            let r = this.inner.borrow().get_quad(tile_id - 1);
            Ok((r.x, r.y, r.width, r.height))
        });
        methods.add_method("type", |_, _, ()| Ok("LAutoTileSheet"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAutoTileSheet" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaChunkMap {
    inner: Rc<RefCell<ChunkMap>>,
}
impl LuaUserData for LuaChunkMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getTile", |_, this, (x, y): (i32, i32)| {
            Ok(this.inner.borrow().get_tile(x, y))
        });
        methods.add_method("setTile", |_, this, (x, y, gid): (i32, i32, u32)| {
            this.inner.borrow_mut().set_tile(x, y, gid);
            Ok(())
        });
        methods.add_method("clearTile", |_, this, (x, y): (i32, i32)| {
            this.inner.borrow_mut().clear_tile(x, y);
            Ok(())
        });
        methods.add_method(
            "fillRect",
            |_, this, (x0, y0, x1, y1, gid): (i32, i32, i32, i32, u32)| {
                this.inner.borrow_mut().fill_rect(x0, y0, x1, y1, gid);
                Ok(())
            },
        );
        methods.add_method("loadChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().load_chunk(cx, cy);
            Ok(())
        });
        methods.add_method("unloadChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().unload_chunk(cx, cy);
            Ok(())
        });
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });
        methods.add_method("getLoadedChunks", |lua, this, ()| {
            let chunks = this.inner.borrow().get_loaded_chunks();
            let tbl = lua.create_table()?;
            for (i, (cx, cy)) in chunks.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set(1, *cx)?;
                entry.set(2, *cy)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        });
        methods.add_method(
            "getChunksInView",
            |lua, this, (vx, vy, vw, vh, tw, th): (f32, f32, f32, f32, f32, f32)| {
                let chunks = this
                    .inner
                    .borrow()
                    .get_chunks_in_view(vx, vy, vw, vh, tw, th);
                let tbl = lua.create_table()?;
                for (i, (cx, cy)) in chunks.iter().enumerate() {
                    let entry = lua.create_table()?;
                    entry.set(1, *cx)?;
                    entry.set(2, *cy)?;
                    tbl.set(i + 1, entry)?;
                }
                Ok(tbl)
            },
        );
        methods.add_method("chunkTileRange", |_, this, (cx, cy): (i32, i32)| {
            let (x0, y0, x1, y1) = this.inner.borrow().chunk_tile_range(cx, cy);
            Ok((x0, y0, x1, y1))
        });
        methods.add_method("type", |_, _, ()| Ok("LChunkMap"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LChunkMap" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaLargeMapRenderer {
    inner: Rc<RefCell<LargeMapRenderer>>,
}
impl LuaUserData for LuaLargeMapRenderer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "setMapData",
            |_, this, (data, width, height): (LuaTable, u32, u32)| {
                let mut ids: Vec<u32> = Vec::new();
                for v in data.sequence_values::<u32>() {
                    ids.push(v?);
                }
                this.inner.borrow_mut().set_map_data(ids, width, height);
                Ok(())
            },
        );
        methods.add_method_mut("setTile", |_, this, (x, y, tile_id): (u32, u32, u32)| {
            this.inner.borrow_mut().set_tile(x, y, tile_id);
            Ok(())
        });
        methods.add_method("getTile", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_tile(x, y))
        });
        methods.add_method("getMapSize", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_map_size();
            Ok((w, h))
        });
        methods.add_method_mut("setChunkSize", |_, this, size: u32| {
            this.inner.borrow_mut().set_chunk_size(size);
            Ok(())
        });
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });
        methods.add_method_mut("invalidateChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().invalidate_chunk(cx, cy);
            Ok(())
        });
        methods.add_method_mut("invalidateAll", |_, this, ()| {
            this.inner.borrow_mut().invalidate_all();
            Ok(())
        });
        methods.add_method("getVisibleChunks", |_, this, ()| {
            Ok(this.inner.borrow().get_visible_chunks())
        });
        methods.add_method("getTotalChunks", |_, this, ()| {
            Ok(this.inner.borrow().get_total_chunks())
        });
        methods.add_method_mut("setCamera", |_, this, (x, y, zoom): (f32, f32, f32)| {
            this.inner.borrow_mut().set_camera(x, y, zoom);
            Ok(())
        });
        methods.add_method_mut("setViewport", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_viewport(w, h);
            Ok(())
        });
        methods.add_method_mut("setLodEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_lod_enabled(enabled);
            Ok(())
        });
        methods.add_method("isLodEnabled", |_, this, ()| {
            Ok(this.inner.borrow().is_lod_enabled())
        });
        methods.add_method_mut("setLodThresholds", |_, this, levels: LuaTable| {
            let mut thresholds: Vec<f32> = Vec::new();
            for v in levels.sequence_values::<f32>() {
                thresholds.push(v?);
            }
            this.inner.borrow_mut().set_lod_thresholds(thresholds);
            Ok(())
        });
        methods.add_method_mut("setTilesetColumns", |_, this, cols: u32| {
            this.inner.borrow_mut().set_tileset_columns(cols);
            Ok(())
        });
        methods.add_method("getTilesetColumns", |_, this, ()| {
            Ok(this.inner.borrow().get_tileset_columns())
        });
        methods.add_method("type", |_, _, ()| Ok("LLargeMapRenderer"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLargeMapRenderer" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaIsoMap {
    inner: Rc<RefCell<IsoMap>>,
}
impl LuaUserData for LuaIsoMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("addLevel", |_, this, ()| {
            let idx = this.inner.borrow_mut().add_level();
            Ok(idx + 1)
        });
        methods.add_method("getLevelCount", |_, this, ()| {
            Ok(this.inner.borrow().get_level_count())
        });
        methods.add_method("setLevelVisible", |_, this, (z, visible): (usize, bool)| {
            let z = one_based_usize("z", z)?;
            this.inner.borrow_mut().set_level_visible(z, visible);
            Ok(())
        });
        methods.add_method("isLevelVisible", |_, this, z: usize| {
            let z = one_based_usize("z", z)?;
            Ok(this.inner.borrow().get_level_visible(z))
        });
        methods.add_method(
            "setTilePart",
            |_, this, (z, x, y, part, gid): (usize, u32, u32, u32, u32)| {
                let z = one_based_usize("z", z)?;
                let x = one_based_u32("x", x)?;
                let y = one_based_u32("y", y)?;
                this.inner.borrow_mut().set_tile_part(z, x, y, part, gid);
                Ok(())
            },
        );
        methods.add_method(
            "getTilePart",
            |_, this, (z, x, y, part): (usize, u32, u32, u32)| {
                let z = one_based_usize("z", z)?;
                let x = one_based_u32("x", x)?;
                let y = one_based_u32("y", y)?;
                Ok(this.inner.borrow().get_tile_part(z, x, y, part))
            },
        );
        methods.add_method("fillLevel", |_, this, (z, part, gid): (usize, u32, u32)| {
            let z = one_based_usize("z", z)?;
            this.inner.borrow_mut().fill_level(z, part, gid);
            Ok(())
        });
        methods.add_method("setOrigin", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_origin(x, y);
            Ok(())
        });
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));
        methods.add_method("getTileWidth", |_, this, ()| Ok(this.inner.borrow().tile_w));
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().tile_h)
        });
        methods.add_method("getLevelHeight", |_, this, ()| {
            Ok(this.inner.borrow().level_height)
        });
        methods.add_method("tileToScreen", |_, this, (tx, ty, tz): (f32, f32, f32)| {
            let (sx, sy) = this.inner.borrow().tile_to_screen(tx, ty, tz);
            Ok((sx, sy))
        });
        methods.add_method("screenToTile", |_, this, (sx, sy): (f32, f32)| {
            let (tx, ty) = this.inner.borrow().screen_to_tile(sx, sy);
            Ok((tx, ty))
        });
        methods.add_method("getPartCount", |_, this, ()| {
            Ok(this.inner.borrow().get_part_count())
        });
        methods.add_method("getPartOrder", |lua, this, ()| {
            let order = this.inner.borrow().get_part_order().to_vec();
            let tbl = lua.create_table()?;
            for (i, &idx) in order.iter().enumerate() {
                tbl.set(i + 1, idx)?;
            }
            Ok(tbl)
        });
        methods.add_method_mut("setPartOrder", |_, this, order: Vec<u32>| {
            this.inner
                .borrow_mut()
                .set_part_order(order)
                .map_err(LuaError::external)
        });
        methods.add_method("type", |_, _, ()| Ok("LIsoMap"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LIsoMap" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaMapBlock {
    inner: Rc<RefCell<MapBlock>>,
}
impl LuaUserData for LuaMapBlock {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method(
            "setTile",
            |_, this, (layer, x, y, gid): (u32, u32, u32, u32)| {
                this.inner
                    .borrow_mut()
                    .set_tile(layer - 1, x - 1, y - 1, gid);
                Ok(())
            },
        );
        methods.add_method("getTile", |_, this, (layer, x, y): (u32, u32, u32)| {
            Ok(this.inner.borrow().get_tile(layer - 1, x - 1, y - 1))
        });
        methods.add_method(
            "setSide",
            |_, this, (edge_str, segment, side_id): (String, u32, u32)| {
                let edge = Edge::from_str(&edge_str)
                    .ok_or_else(|| LuaError::external("invalid edge: use north/east/south/west"))?;
                this.inner.borrow_mut().set_side(edge, segment - 1, side_id);
                Ok(())
            },
        );
        methods.add_method("getSide", |_, this, (edge_str, segment): (String, u32)| {
            let edge = Edge::from_str(&edge_str)
                .ok_or_else(|| LuaError::external("invalid edge: use north/east/south/west"))?;
            Ok(this.inner.borrow().get_side(edge, segment - 1))
        });
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_dimensions();
            Ok((w, h))
        });
        methods.add_method("getLayerCount", |_, this, ()| {
            Ok(this.inner.borrow().get_layer_count())
        });
        methods.add_method("getSegmentSize", |_, this, ()| {
            Ok(this.inner.borrow().get_segment_size())
        });
        methods.add_method("getWidthInSegments", |_, this, ()| {
            Ok(this.inner.borrow().get_width_in_segments())
        });
        methods.add_method("getHeightInSegments", |_, this, ()| {
            Ok(this.inner.borrow().get_height_in_segments())
        });
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().set_name(&name);
            Ok(())
        });
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });
        methods.add_method("setWeight", |_, this, weight: f32| {
            this.inner.borrow_mut().set_weight(weight);
            Ok(())
        });
        methods.add_method("getWeight", |_, this, ()| {
            Ok(this.inner.borrow().get_weight())
        });
        methods.add_method("type", |_, _, ()| Ok("LMapBlock"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapBlock" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaMapGroup {
    inner: Rc<RefCell<MapGroup>>,
}
impl LuaUserData for LuaMapGroup {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("addBlock", |_, this, block_ud: LuaAnyUserData| {
            let block = block_ud.borrow::<LuaMapBlock>()?;
            this.inner
                .borrow_mut()
                .add_block(block.inner.borrow().clone());
            Ok(())
        });
        methods.add_method("getBlockCount", |_, this, ()| {
            Ok(this.inner.borrow().get_block_count())
        });
        methods.add_method("removeBlock", |_, this, idx: usize| {
            this.inner.borrow_mut().remove_block(idx - 1);
            Ok(())
        });
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });
        methods.add_method("addScript", |_, this, script_ud: LuaAnyUserData| {
            let script = script_ud.borrow::<LuaMapScript>()?;
            this.inner
                .borrow_mut()
                .add_script(script.inner.borrow().clone());
            Ok(())
        });
        methods.add_method("getScriptCount", |_, this, ()| {
            Ok(this.inner.borrow().get_script_count())
        });
        methods.add_method("type", |_, _, ()| Ok("LMapGroup"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapGroup" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaMapScript {
    inner: Rc<RefCell<MapScript>>,
}
impl LuaUserData for LuaMapScript {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getStepCount", |_, this, ()| {
            Ok(this.inner.borrow().get_step_count())
        });
        methods.add_method("addStep", |_, this, step_def: LuaTable| {
            let step_type_str: String = step_def.get("type")?;
            let st = match step_type_str.as_str() {
                "fillRandom"  => StepType::FillRandom,
                "placeBlock"  => StepType::PlaceBlock,
                "placeRandom" => StepType::PlaceRandom,
                "placeLine"   => StepType::PlaceLine,
                "floodFill"   => StepType::FloodFill,
                "fillArea"    => StepType::FillArea,
                "drawPath"    => StepType::DrawPath,
                "fillRect"    => StepType::FillRect,
                other => {
                    return Err(LuaError::RuntimeError(format!(
                        "addStep: unknown step type '{}'; valid: fillRandom, placeBlock, placeRandom, placeLine, floodFill, fillArea, drawPath, fillRect",
                        other
                    )))
                }
            };
            let get_u32_field = |tbl: &LuaTable, key: &str| -> u32 {
                match tbl.get::<_, LuaValue>(key) {
                    Ok(LuaValue::Integer(n)) => n as u32,
                    Ok(LuaValue::Number(n)) => n as u32,
                    _ => 0,
                }
            };
            let get_f32_field = |tbl: &LuaTable, key: &str| -> f32 {
                match tbl.get::<_, LuaValue>(key) {
                    Ok(LuaValue::Number(n)) => n as f32,
                    Ok(LuaValue::Integer(n)) => n as f32,
                    _ => 1.0,
                }
            };
            let get_i32_field = |tbl: &LuaTable, key: &str, default: i32| -> i32 {
                match tbl.get::<_, LuaValue>(key) {
                    Ok(LuaValue::Integer(n)) => n as i32,
                    Ok(LuaValue::Number(n)) => n as i32,
                    _ => default,
                }
            };
            let step = ScriptStep {
                step_type: st,
                x: get_u32_field(&step_def, "x"),
                y: get_u32_field(&step_def, "y"),
                width: get_u32_field(&step_def, "w"),
                height: get_u32_field(&step_def, "h"),
                tile_id: get_u32_field(&step_def, "gid"),
                chance: get_f32_field(&step_def, "chance"),
                direction: get_u32_field(&step_def, "direction"),
                path_width: {
                    let v = get_u32_field(&step_def, "pathWidth");
                    if v == 0 { 1 } else { v }
                },
                repeat_count: {
                    let v = get_u32_field(&step_def, "repeatCount");
                    if v == 0 { 1 } else { v }
                },
                count: {
                    let v = get_u32_field(&step_def, "count");
                    if v == 0 { 1 } else { v }
                },
                group_index: get_i32_field(&step_def, "groupIndex", -1),
                block_index: get_i32_field(&step_def, "blockIndex", -1),
                tile_layer: get_u32_field(&step_def, "tileLayer"),
                ..Default::default()
            };
            this.inner.borrow_mut().add_step(step);
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LMapScript"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapScript" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaMapGen {
    group: Rc<RefCell<MapGroup>>,
    inner: Rc<RefCell<crate::tilemap::mapgen::MapGen>>,
    state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaMapGen {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("generate", |_, this, (script_idx, seed, layer_name): (Option<usize>, Option<u64>, Option<String>)| {
                let script_index = script_idx.map(|i| if i == 0 { 0 } else { i - 1 });
                let name = layer_name.as_deref().unwrap_or("main");
                let tm = this
                    .inner
                    .borrow_mut()
                    .generate(&this.group.borrow(), script_index, seed, name);
                let inner_rc = Rc::new(RefCell::new(tm));
                this.state.borrow_mut().auto_tilemaps.push(Rc::downgrade(&inner_rc));
                Ok(LuaTileMap {
                    inner: inner_rc,
                    state: this.state.clone(),
                    tile_callbacks: Rc::new(RefCell::new(Vec::new())),
                    tile_step_callbacks: Rc::new(RefCell::new(HashMap::new())),
                    tile_exit_callbacks: Rc::new(RefCell::new(HashMap::new())),
                })
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LMapGen"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapGen" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newTileSet",
        lua.create_function(
            |lua,
             (first_gid, tile_count, columns, tile_width, tile_height, spacing, margin): (
                u32,
                u32,
                u32,
                u32,
                u32,
                Option<u32>,
                Option<u32>,
            )| {
                lua.create_userdata(LuaTileSet {
                    inner: Rc::new(RefCell::new(TileSet::new(
                        first_gid,
                        tile_count,
                        columns,
                        tile_width,
                        tile_height,
                        spacing.unwrap_or(0),
                        margin.unwrap_or(0),
                    ))),
                })
            },
        )?,
    )?;
    let s = state.clone();
    tbl.set(
        "newTileMap",
        lua.create_function(
            move |lua, (tile_width, tile_height, chunk_size): (u32, u32, Option<u32>)| {
                let inner_rc = Rc::new(RefCell::new(TileMap::new(
                    tile_width,
                    tile_height,
                    chunk_size.unwrap_or(16),
                )));
                s.borrow_mut().auto_tilemaps.push(Rc::downgrade(&inner_rc));
                lua.create_userdata(LuaTileMap {
                    inner: inner_rc,
                    state: s.clone(),
                    tile_callbacks: Rc::new(RefCell::new(Vec::new())),
                    tile_step_callbacks: Rc::new(RefCell::new(HashMap::new())),
                    tile_exit_callbacks: Rc::new(RefCell::new(HashMap::new())),
                })
            },
        )?,
    )?;
    tbl.set("newAutoTileSheet", lua.create_function(
            |lua, (tile_w, tile_h, layout_str): (u32, u32, String)| {
                let layout = match layout_str.as_str() {
                    "blob47" => AutoTileLayout::Blob47,
                    "composite48" => AutoTileLayout::Composite48,
                    "minimal16" => AutoTileLayout::Minimal16,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "newAutoTileSheet: unknown layout '{}', use 'blob47', 'composite48', or 'minimal16'",
                            other
                        )))
                    }
                };
                lua.create_userdata(LuaAutoTileSheet {
                    inner: Rc::new(RefCell::new(AutoTileSheet::new(tile_w, tile_h, layout))),
                })
            },
        )?,
    )?;
    tbl.set(
        "newChunkMap",
        lua.create_function(|lua, chunk_size: Option<u32>| {
            lua.create_userdata(LuaChunkMap {
                inner: Rc::new(RefCell::new(ChunkMap::new(chunk_size.unwrap_or(16)))),
            })
        })?,
    )?;
    tbl.set(
        "newIsoMap",
        lua.create_function(
            |lua,
             (width, height, tile_w, tile_h, level_height, part_count): (
                u32,
                u32,
                u32,
                u32,
                u32,
                Option<u32>,
            )| {
                lua.create_userdata(LuaIsoMap {
                    inner: Rc::new(RefCell::new(IsoMap::new(
                        width,
                        height,
                        tile_w,
                        tile_h,
                        level_height,
                        part_count.unwrap_or(4),
                    ))),
                })
            },
        )?,
    )?;
    tbl.set(
        "newMapBlock",
        lua.create_function(
            |lua, (width, height, layers, segment_size): (u32, u32, Option<u32>, Option<u32>)| {
                lua.create_userdata(LuaMapBlock {
                    inner: Rc::new(RefCell::new(MapBlock::new(
                        width,
                        height,
                        layers.unwrap_or(1),
                        segment_size.unwrap_or(1),
                    ))),
                })
            },
        )?,
    )?;
    tbl.set(
        "newMapGroup",
        lua.create_function(|lua, name: String| {
            lua.create_userdata(LuaMapGroup {
                inner: Rc::new(RefCell::new(MapGroup::new(&name))),
            })
        })?,
    )?;
    tbl.set(
        "toScreenIso",
        lua.create_function(|_, (tx, ty, tw, th): (f32, f32, f32, f32)| {
            let v = coords::to_screen_iso(tx, ty, tw, th);
            Ok((v.x, v.y))
        })?,
    )?;
    tbl.set(
        "fromScreenIso",
        lua.create_function(|_, (sx, sy, tw, th): (f32, f32, f32, f32)| {
            let v = coords::from_screen_iso(sx, sy, tw, th);
            Ok((v.x, v.y))
        })?,
    )?;
    tbl.set(
        "toScreenHex",
        lua.create_function(|_, (q, r, size): (i32, i32, f32)| {
            let v = coords::to_screen_hex(q, r, size);
            Ok((v.x, v.y))
        })?,
    )?;
    tbl.set(
        "fromScreenHex",
        lua.create_function(|_, (sx, sy, size): (f32, f32, f32)| {
            let (q, r) = coords::from_screen_hex(sx, sy, size);
            Ok((q, r))
        })?,
    )?;
    tbl.set(
        "hexNeighbors",
        lua.create_function(|lua, (q, r): (i32, i32)| {
            let n = coords::hex_neighbors(q, r);
            let tbl = lua.create_table()?;
            for (i, (nq, nr)) in n.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("q", *nq)?;
                entry.set("r", *nr)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;
    tbl.set(
        "hexDistance",
        lua.create_function(|_, (q1, r1, q2, r2): (i32, i32, i32, i32)| {
            Ok(coords::hex_distance(q1, r1, q2, r2))
        })?,
    )?;
    tbl.set(
        "hexRound",
        lua.create_function(|_, (q, r): (f32, f32)| {
            let (rq, rr) = coords::hex_round(q, r);
            Ok((rq, rr))
        })?,
    )?;
    tbl.set(
        "hexLine",
        lua.create_function(|lua, (q1, r1, q2, r2): (i32, i32, i32, i32)| {
            let cells = coords::hex_line(q1, r1, q2, r2);
            let tbl = lua.create_table()?;
            for (i, (q, r)) in cells.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set(1, *q)?;
                entry.set(2, *r)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;
    tbl.set(
        "hexRing",
        lua.create_function(|lua, (q, r, radius): (i32, i32, i32)| {
            let cells = coords::hex_ring(q, r, radius);
            let tbl = lua.create_table()?;
            for (i, (cq, cr)) in cells.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set(1, *cq)?;
                entry.set(2, *cr)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;
    tbl.set(
        "hexSpiral",
        lua.create_function(|lua, (q, r, radius): (i32, i32, i32)| {
            let cells = coords::hex_spiral(q, r, radius);
            let tbl = lua.create_table()?;
            for (i, (cq, cr)) in cells.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set(1, *cq)?;
                entry.set(2, *cr)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;
    tbl.set(
        "hexArea",
        lua.create_function(|lua, (q, r, radius): (i32, i32, i32)| {
            let cells = coords::hex_area(q, r, radius);
            let tbl = lua.create_table()?;
            for (i, (cq, cr)) in cells.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set(1, *cq)?;
                entry.set(2, *cr)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;
    tbl.set(
        "hexRotate",
        lua.create_function(
            |_, (q, r, center_q, center_r, steps): (i32, i32, i32, i32, i32)| {
                let (rq, rr) = coords::hex_rotate(q, r, center_q, center_r, steps);
                Ok((rq, rr))
            },
        )?,
    )?;
    tbl.set(
        "hexReflect",
        lua.create_function(
            |_, (q, r, center_q, center_r, axis): (i32, i32, i32, i32, String)| {
                let (rq, rr) = coords::hex_reflect(q, r, center_q, center_r, &axis);
                Ok((rq, rr))
            },
        )?,
    )?;
    tbl.set(
        "isoRotate",
        lua.create_function(|_, (direction, steps): (i32, i32)| {
            Ok(coords::iso_rotate(direction, steps))
        })?,
    )?;
    tbl.set(
        "isoDirectionName",
        lua.create_function(|_, direction: i32| Ok(coords::iso_direction_name(direction)))?,
    )?;
    tbl.set(
        "isoDirectionFromAngle",
        lua.create_function(|_, angle: f32| Ok(coords::iso_direction_from_angle(angle)))?,
    )?;
    tbl.set(
        "newMapScript",
        lua.create_function(|_, ()| {
            Ok(LuaMapScript {
                inner: Rc::new(RefCell::new(MapScript::new("lua_script"))),
            })
        })?,
    )?;
    tbl.set("FLOOR", 1u32)?;
    tbl.set("NORTH_WALL", 2u32)?;
    tbl.set("WEST_WALL", 3u32)?;
    tbl.set("OBJECT", 4u32)?;
    let s3 = state.clone();
    tbl.set(
        "newMapGen",
        lua.create_function(move |_, args: mlua::Variadic<LuaValue>| {
            if args.len() < 3 {
                return Err(LuaError::RuntimeError(
                    "newMapGen: expected (group, preset, segmentSize) or (group, w, h, segmentSize)"
                        .to_string(),
                ));
            }
            let group_rc = if let LuaValue::UserData(ud) = &args[0] {
                let g = ud.borrow::<LuaMapGroup>()?;
                g.inner.clone()
            } else {
                return Err(LuaError::RuntimeError(
                    "newMapGen: first argument must be a MapGroup".to_string(),
                ));
            };
            let (size, segment_size) = match &args[1] {
                LuaValue::String(s) => {
                    let size = match s.to_str()? {
                        "small" => MapSize::Small,
                        "medium" => MapSize::Medium,
                        "large" => MapSize::Large,
                        other => {
                            return Err(LuaError::RuntimeError(format!(
                                "newMapGen: unknown preset '{}', use 'small', 'medium', or 'large'",
                                other
                            )))
                        }
                    };
                    let seg = match &args[2] {
                        LuaValue::Integer(n) => *n as u32,
                        LuaValue::Number(n) => *n as u32,
                        _ => {
                            return Err(LuaError::RuntimeError(
                                "newMapGen: third argument (segmentSize) must be integer"
                                    .to_string(),
                            ))
                        }
                    };
                    (size, seg)
                }
                LuaValue::Integer(w) => {
                    let w = *w as u32;
                    let h = match &args[2] {
                        LuaValue::Integer(n) => *n as u32,
                        LuaValue::Number(n) => *n as u32,
                        _ => {
                            return Err(LuaError::RuntimeError(
                                "newMapGen: third argument must be integer h".to_string(),
                            ))
                        }
                    };
                    let seg = if args.len() >= 4 {
                        match &args[3] {
                            LuaValue::Integer(n) => *n as u32,
                            LuaValue::Number(n) => *n as u32,
                            _ => 1,
                        }
                    } else {
                        1
                    };
                    let mut gen = MapGen::new(MapSize::Small, seg);
                    gen.set_grid_dimensions(w, h);
                    return Ok(LuaMapGen {
                        group: group_rc,
                        inner: Rc::new(RefCell::new(gen)),
                        state: s3.clone(),
                    });
                }
                LuaValue::Number(w) => {
                    let w = *w as u32;
                    let h = match &args[2] {
                        LuaValue::Integer(n) => *n as u32,
                        LuaValue::Number(n) => *n as u32,
                        _ => {
                            return Err(LuaError::RuntimeError(
                                "newMapGen: third argument must be integer h".to_string(),
                            ))
                        }
                    };
                    let seg = if args.len() >= 4 {
                        match &args[3] {
                            LuaValue::Integer(n) => *n as u32,
                            LuaValue::Number(n) => *n as u32,
                            _ => 1,
                        }
                    } else {
                        1
                    };
                    let mut gen = MapGen::new(MapSize::Small, seg);
                    gen.set_grid_dimensions(w, h);
                    return Ok(LuaMapGen {
                        group: group_rc,
                        inner: Rc::new(RefCell::new(gen)),
                        state: s3.clone(),
                    });
                }
                _ => {
                    return Err(LuaError::RuntimeError(
                        "newMapGen: second argument must be preset string or integer width"
                            .to_string(),
                    ))
                }
            };
            let gen = MapGen::new(size, segment_size);
            Ok(LuaMapGen {
                group: group_rc,
                inner: Rc::new(RefCell::new(gen)),
                state: s3.clone(),
            })
        })?,
    )?;
    tbl.set(
        "loadTMX",
        lua.create_function(|lua, xml: String| {
            let tmx = crate::tilemap::tmx::load_tmx(&xml).map_err(LuaError::RuntimeError)?;
            let result = lua.create_table()?;
            result.set("width", tmx.width)?;
            result.set("height", tmx.height)?;
            result.set("tileWidth", tmx.tile_width)?;
            result.set("tileHeight", tmx.tile_height)?;
            let orient_str = match tmx.orientation {
                crate::tilemap::tmx::TmxOrientation::Orthogonal => "orthogonal",
                crate::tilemap::tmx::TmxOrientation::Isometric => "isometric",
                crate::tilemap::tmx::TmxOrientation::Staggered => "staggered",
                crate::tilemap::tmx::TmxOrientation::Hexagonal => "hexagonal",
            };
            result.set("orientation", orient_str)?;
            let layers_tbl = lua.create_table()?;
            let mut layer_idx = 1usize;
            for layer in &tmx.layers {
                let entry = lua.create_table()?;
                match layer {
                    crate::tilemap::tmx::TmxLayer::Tile(t) => {
                        entry.set("type", "tile")?;
                        entry.set("name", t.name.as_str())?;
                        entry.set("width", t.width)?;
                        entry.set("height", t.height)?;
                    }
                    crate::tilemap::tmx::TmxLayer::Object(o) => {
                        entry.set("type", "object")?;
                        entry.set("name", o.name.as_str())?;
                    }
                }
                layers_tbl.set(layer_idx, entry)?;
                layer_idx += 1;
            }
            result.set("layers", layers_tbl)?;
            Ok(result)
        })?,
    )?;
    tbl.set(
        "fromLDtk",
        lua.create_function({
            let state = state.clone();
            move |lua, (json_str, level_name): (String, Option<String>)| match load_ldtk(
                &json_str,
                level_name.as_deref(),
            ) {
                Ok(map) => {
                    let ud = lua.create_userdata(LuaTileMap {
                        inner: Rc::new(RefCell::new(map)),
                        state: state.clone(),
                        tile_callbacks: Rc::new(RefCell::new(Vec::new())),
                        tile_step_callbacks: Rc::new(RefCell::new(HashMap::new())),
                        tile_exit_callbacks: Rc::new(RefCell::new(HashMap::new())),
                    })?;
                    Ok(LuaValue::UserData(ud))
                }
                Err(e) => Err(LuaError::RuntimeError(format!("fromLDtk: {}", e))),
            }
        })?,
    )?;
    tbl.set(
        "newLargeMapRenderer",
        lua.create_function(|lua, (tile_w, tile_h): (u32, u32)| {
            if tile_w == 0 || tile_h == 0 {
                return Err(LuaError::RuntimeError(
                    "newLargeMapRenderer: tileW and tileH must be > 0".to_string(),
                ));
            }
            let renderer = LargeMapRenderer::new(tile_w, tile_h);
            let ud = lua.create_userdata(LuaLargeMapRenderer {
                inner: Rc::new(RefCell::new(renderer)),
            })?;
            Ok(LuaValue::UserData(ud))
        })?,
    )?;
    lurek.set("tilemap", tbl)?;
    Ok(())
}
