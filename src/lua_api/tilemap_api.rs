//! `lurek.tilemap` — Tile-based map authoring, chunk streaming, isometric and hex coordinate helpers.

use super::render_api::LuaImageData;
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::math::Rect;
use crate::tilemap::autotile_sheet::{AutoTileLayout, AutoTileSheet};
use crate::tilemap::chunk::ChunkMap;
use crate::tilemap::coords;
use crate::tilemap::isomap::IsoMap;
use crate::tilemap::mapgen::{
    Edge, MapBlock, MapGen, MapGroup, MapOrientation, MapScript, MapSize, ScriptStep, StepType,
};
use crate::tilemap::tilemap::TileMap;
use crate::tilemap::tileset::{TileAnimFrame, TileSet};

// -------------------------------------------------------------------------------
// LuaTileSet UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`TileSet`].
#[derive(Clone)]
pub struct LuaTileSet {
    inner: Rc<RefCell<TileSet>>,
}

impl LuaUserData for LuaTileSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getFirstGid --
        /// Returns the first global ID assigned to this tileset.
        /// @return integer
        methods.add_method("getFirstGid", |_, this, ()| {
            Ok(this.inner.borrow().get_first_gid())
        });

        // -- getTileCount --
        /// Returns the total number of tiles in this tileset.
        /// @return integer
        methods.add_method("getTileCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_count())
        });

        // -- getColumns --
        /// Returns the number of tile columns in the atlas texture.
        /// @return integer
        methods.add_method("getColumns", |_, this, ()| {
            Ok(this.inner.borrow().get_columns())
        });

        // -- getTileWidth --
        /// Returns the width of a single tile in pixels.
        /// @return integer
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });

        // -- getTileHeight --
        /// Returns the height of a single tile in pixels.
        /// @return integer
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });

        // -- getTileDimensions --
        /// Returns the tile dimensions as (width, height).
        /// @return integer, integer
        methods.add_method("getTileDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_tile_dimensions();
            Ok((w, h))
        });

        // -- getSpacing --
        /// Returns the spacing in pixels between tiles in the atlas.
        /// @return integer
        methods.add_method("getSpacing", |_, this, ()| {
            Ok(this.inner.borrow().get_spacing())
        });

        // -- getMargin --
        /// Returns the margin in pixels around the edges of the atlas.
        /// @return integer
        methods.add_method("getMargin", |_, this, ()| {
            Ok(this.inner.borrow().get_margin())
        });

        // -- getQuad --
        /// Computes the atlas source rectangle for a 1-based local tile ID.
        /// @param tileId : integer
        /// @return table  {x, y, width, height}
        methods.add_method("getQuad", |lua, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getQuad: tile_id must be >= 1".to_string(),
                ));
            }
            let r = this.inner.borrow().get_quad(tile_id - 1);
            // @return table — Quad source rect: {x, y, width, height}
            let tbl = lua.create_table()?;
            tbl.set("x", r.x)?;
            tbl.set("y", r.y)?;
            tbl.set("width", r.width)?;
            tbl.set("height", r.height)?;
            Ok(tbl)
        });

        // -- setAnimation --
        /// Sets the animation frames for a 1-based local tile ID from a table of {tileid, duration}.
        /// @param tileId : integer
        /// @param frames : table
        /// @return nil
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

        // -- getAnimation --
        /// Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
        /// @param tileId : integer
        /// @return table?
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
                        // @return table — Animation frame: {tileid, duration}
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

        // -- setSolid --
        /// Sets whether a 1-based local tile ID is solid for collision purposes.
        /// @param tileId : integer
        /// @param solid : boolean
        /// @return nil
        methods.add_method("setSolid", |_, this, (tile_id, solid): (u32, bool)| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "setSolid: tile_id must be >= 1".to_string(),
                ));
            }
            this.inner.borrow_mut().set_solid(tile_id - 1, solid);
            Ok(())
        });

        // -- isSolid --
        /// Returns whether a 1-based local tile ID is solid.
        /// @param tileId : integer
        /// @return boolean
        methods.add_method("isSolid", |_, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "isSolid: tile_id must be >= 1".to_string(),
                ));
            }
            Ok(this.inner.borrow().is_solid(tile_id - 1))
        });

        // -- setAutoTileRule --
        /// Registers a 4-bit cardinal autotile rule. tileId is 1-based.
        /// @param typeName : string
        /// @param bitmask : integer
        /// @param tileId : integer
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

        // -- getAutoTileId --
        /// Looks up the 1-based local tile ID for a 4-bit cardinal autotile bitmask, or nil.
        /// @param typeName : string
        /// @param bitmask : integer
        /// @return integer?
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

        // -- setAutoTileRule8 --
        /// Registers an 8-bit directional autotile rule. tileId is 1-based.
        /// @param typeName : string
        /// @param bitmask : integer
        /// @param tileId : integer
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

        // -- getAutoTileId8 --
        /// Looks up the 1-based local tile ID for an 8-bit directional autotile bitmask, or nil.
        /// @param typeName : string
        /// @param bitmask : integer
        /// @return integer?
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
    }
}

// -------------------------------------------------------------------------------
// LuaTileMap UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`TileMap`].
#[derive(Clone)]
pub struct LuaTileMap {
    pub(super) inner: Rc<RefCell<TileMap>>,
    state: Rc<RefCell<SharedState>>,
}

impl LuaUserData for LuaTileMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addTileSet --
        /// Adds a tileset to this map.
        /// @param tileset : TileSet
        /// @return nil
        methods.add_method("addTileSet", |_, this, ts_ud: LuaAnyUserData| {
            let ts = ts_ud.borrow::<LuaTileSet>()?;
            this.inner
                .borrow_mut()
                .add_tileset(ts.inner.borrow().clone());
            Ok(())
        });

        // -- getTileSetCount --
        /// Returns the number of tilesets attached to this map.
        /// @return integer
        methods.add_method("getTileSetCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tileset_count())
        });

        // -- getTileSet --
        /// Returns a tileset by 1-based index, or nil if out of range.
        /// @param idx : integer
        /// @return TileSet?
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

        // -- addLayer --
        /// Adds a new empty layer and returns its 1-based index.
        /// @param name : string
        /// @param w : integer
        /// @param h : integer
        /// @return integer
        methods.add_method("addLayer", |_, this, (name, w, h): (String, u32, u32)| {
            let idx = this.inner.borrow_mut().add_layer(&name, w, h);
            Ok(idx + 1)
        });

        // -- getLayerCount --
        /// Returns the number of layers.
        /// @return integer
        methods.add_method("getLayerCount", |_, this, ()| {
            Ok(this.inner.borrow().get_layer_count())
        });

        // -- getLayerName --
        /// Returns the name of a layer by 1-based index.
        /// @param idx : integer
        /// @return string?
        methods.add_method("getLayerName", |_, this, idx: usize| {
            Ok(this
                .inner
                .borrow()
                .get_layer_name(idx - 1)
                .map(|s| s.to_string()))
        });

        // -- setLayerVisible --
        /// Sets layer visibility.
        /// @param idx : integer
        /// @param visible : boolean
        methods.add_method(
            "setLayerVisible",
            |_, this, (idx, visible): (usize, bool)| {
                this.inner.borrow_mut().set_layer_visible(idx - 1, visible);
                Ok(())
            },
        );

        // -- getLayerVisible --
        /// Returns layer visibility.
        /// @param idx : integer
        /// @return boolean
        methods.add_method("getLayerVisible", |_, this, idx: usize| {
            Ok(this.inner.borrow().get_layer_visible(idx - 1))
        });

        // -- setLayerColor --
        /// Sets the RGBA tint color for a layer.
        /// @param idx : integer
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        methods.add_method(
            "setLayerColor",
            |_, this, (idx, r, g, b, a): (usize, f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_layer_color(idx - 1, r, g, b, a);
                Ok(())
            },
        );

        // -- getLayerColor --
        /// Returns the RGBA tint color of a layer.
        /// @param idx : integer
        /// @return number, number, number, number
        methods.add_method("getLayerColor", |_, this, idx: usize| {
            let c = this.inner.borrow().get_layer_color(idx - 1);
            Ok((c[0], c[1], c[2], c[3]))
        });

        // -- setLayerOffset --
        /// Sets the pixel offset for a layer.
        /// @param idx : integer
        /// @param ox : number
        /// @param oy : number
        methods.add_method(
            "setLayerOffset",
            |_, this, (idx, ox, oy): (usize, f32, f32)| {
                this.inner.borrow_mut().set_layer_offset(idx - 1, ox, oy);
                Ok(())
            },
        );

        // -- getLayerOffset --
        /// Returns the pixel offset of a layer.
        /// @param idx : integer
        /// @return number, number
        methods.add_method("getLayerOffset", |_, this, idx: usize| {
            let v = this.inner.borrow().get_layer_offset(idx - 1);
            Ok((v.x, v.y))
        });

        // -- setLayerParallax --
        /// Sets the parallax scrolling factor for a layer.
        /// @param idx : integer
        /// @param px : number
        /// @param py : number
        methods.add_method(
            "setLayerParallax",
            |_, this, (idx, px, py): (usize, f32, f32)| {
                this.inner.borrow_mut().set_layer_parallax(idx - 1, px, py);
                Ok(())
            },
        );

        // -- getLayerParallax --
        /// Returns the parallax factor of a layer.
        /// @param idx : integer
        /// @return number, number
        methods.add_method("getLayerParallax", |_, this, idx: usize| {
            let v = this.inner.borrow().get_layer_parallax(idx - 1);
            Ok((v.x, v.y))
        });

        // -- setTile --
        /// Sets the GID of a tile at (x, y) on the given layer (1-based).
        /// @param layer : integer
        /// @param x : integer
        /// @param y : integer
        /// @param gid : integer
        methods.add_method(
            "setTile",
            |_, this, (layer, x, y, gid): (usize, u32, u32, u32)| {
                this.inner
                    .borrow_mut()
                    .set_tile(layer - 1, x - 1, y - 1, gid);
                Ok(())
            },
        );

        // -- getTile --
        /// Returns the GID at (x, y) on the given layer (1-based).
        /// @param layer : integer
        /// @param x : integer
        /// @param y : integer
        /// @return integer
        methods.add_method("getTile", |_, this, (layer, x, y): (usize, u32, u32)| {
            Ok(this.inner.borrow().get_tile(layer - 1, x - 1, y - 1))
        });

        // -- clearTile --
        /// Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
        /// @param layer : integer
        /// @param x : integer
        /// @param y : integer
        /// @return nil
        methods.add_method("clearTile", |_, this, (layer, x, y): (usize, u32, u32)| {
            this.inner.borrow_mut().clear_tile(layer - 1, x - 1, y - 1);
            Ok(())
        });

        // -- fill --
        /// Fills an entire layer with the given GID (1-based layer).
        /// @param layer : integer
        /// @param gid : integer
        /// @return nil
        methods.add_method("fill", |_, this, (layer, gid): (usize, u32)| {
            this.inner.borrow_mut().fill(layer - 1, gid);
            Ok(())
        });

        // -- setViewport --
        /// Sets the viewport rectangle for rendering culling.
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        methods.add_method(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport(x, y, w, h);
                Ok(())
            },
        );

        // -- getViewport --
        /// Returns the viewport as (x, y, w, h) or nil if not set.
        /// @return number, number, number, number
        methods.add_method("getViewport", |_, this, ()| {
            match this.inner.borrow().get_viewport() {
                Some((x, y, w, h)) => Ok((Some(x), Some(y), Some(w), Some(h))),
                None => Ok((None, None, None, None)),
            }
        });

        // -- update --
        /// Advances tile animation timers by dt seconds.
        /// @param dt : number
        /// @return nil
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- worldToTile --
        /// Converts world pixel coordinates to tile coordinates.
        /// @param wx : number
        /// @param wy : number
        /// @return integer, integer
        methods.add_method("worldToTile", |_, this, (wx, wy): (f32, f32)| {
            let (tx, ty) = this.inner.borrow().world_to_tile(wx, wy);
            Ok((tx + 1, ty + 1))
        });

        // -- tileToWorld --
        /// Converts tile coordinates to world pixel coordinates (1-based input).
        /// @param tx : integer
        /// @param ty : integer
        /// @return number, number
        methods.add_method("tileToWorld", |_, this, (tx, ty): (u32, u32)| {
            let (wx, wy) = this.inner.borrow().tile_to_world(tx - 1, ty - 1);
            Ok((wx, wy))
        });

        // -- getTileWidth --
        /// Returns the tile width in pixels.
        /// @return integer
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });

        // -- getTileHeight --
        /// Returns the tile height in pixels.
        /// @return integer
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });

        // -- getTileDimensions --
        /// Returns tile dimensions as (width, height).
        /// @return integer, integer
        methods.add_method("getTileDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_tile_dimensions();
            Ok((w, h))
        });

        // -- getChunkSize --
        /// Returns the chunk size used for spatial partitioning.
        /// @return integer
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });

        // -- isSolid --
        /// Returns true if the tile at (x, y) on layer is solid (1-based).
        /// @param layer : integer
        /// @param x : integer
        /// @param y : integer
        /// @return boolean
        methods.add_method("isSolid", |_, this, (layer, x, y): (usize, u32, u32)| {
            Ok(this.inner.borrow().is_solid(layer - 1, x - 1, y - 1))
        });

        // -- applyAutoTile --
        /// Applies 4-bit cardinal autotile rules to every tile on layer (1-based).
        /// @param layer : integer
        /// @param typeName : string
        methods.add_method(
            "applyAutoTile",
            |_, this, (layer, type_name): (usize, String)| {
                this.inner
                    .borrow_mut()
                    .apply_autotile(layer - 1, &type_name);
                Ok(())
            },
        );

        // -- applyAutoTileAt --
        /// Applies 4-bit cardinal autotile at a single cell and its 3x3 neighborhood (1-based).
        /// @param layer : integer
        /// @param x : integer
        /// @param y : integer
        /// @param typeName : string
        methods.add_method(
            "applyAutoTileAt",
            |_, this, (layer, x, y, type_name): (usize, u32, u32, String)| {
                this.inner
                    .borrow_mut()
                    .apply_autotile_at(layer - 1, x - 1, y - 1, &type_name);
                Ok(())
            },
        );

        // -- applyAutoTile8 --
        /// Applies 8-bit directional autotile rules to every tile on layer (1-based).
        /// @param layer : integer
        /// @param typeName : string
        methods.add_method(
            "applyAutoTile8",
            |_, this, (layer, type_name): (usize, String)| {
                this.inner
                    .borrow_mut()
                    .apply_autotile_8(layer - 1, &type_name);
                Ok(())
            },
        );

        // -- applyAutoTile8At --
        /// Applies 8-bit directional autotile at a single cell and its 3x3 neighborhood (1-based).
        /// @param layer : integer
        /// @param x : integer
        /// @param y : integer
        /// @param typeName : string
        methods.add_method(
            "applyAutoTile8At",
            |_, this, (layer, x, y, type_name): (usize, u32, u32, String)| {
                this.inner
                    .borrow_mut()
                    .apply_autotile_8_at(layer - 1, x - 1, y - 1, &type_name);
                Ok(())
            },
        );

        // -- rectOverlapsSolid --
        /// Returns true if any solid tile overlaps the given world-space rectangle on layer (1-based).
        /// @param layer : integer
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        /// @return boolean
        methods.add_method(
            "rectOverlapsSolid",
            |_, this, (layer, x, y, w, h): (usize, f32, f32, f32, f32)| {
                Ok(this
                    .inner
                    .borrow()
                    .rect_overlaps_solid(layer - 1, Rect::new(x, y, w, h)))
            },
        );

        // -- sweepRect --
        /// Performs a swept AABB collision test against solid tiles on layer (1-based).
        /// Returns (ox, oy, nx, ny, hx, hy) — final position, normal, and hit tile coords.
        /// When no obstacle is hit, ox = x+dx, oy = y+dy and normal/hit are zero.
        /// @param layer : integer
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        /// @param dx : number
        /// @param dy : number
        /// @return number, number, number, number, number, number
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

        // -- getOrientation --
        /// Returns the map orientation as a string ("topdown" or "sideview").
        /// @return string
        methods.add_method("getOrientation", |_, this, ()| {
            let o = this.inner.borrow().get_orientation();
            Ok(match o {
                MapOrientation::TopDown => "topdown",
                MapOrientation::SideView => "sideview",
            })
        });

        // -- setOrientation --
        /// Sets the map orientation from a string ("topdown" or "sideview").
        /// @param orientation : string
        /// @return nil
        methods.add_method("setOrientation", |_, this, orientation: String| {
            let o = match orientation.as_str() {
                "sideview" => MapOrientation::SideView,
                _ => MapOrientation::TopDown,
            };
            this.inner.borrow_mut().set_orientation(o);
            Ok(())
        });

        // -- setTileTint --
        /// Sets a per-tile RGBA tint override (1-based layer, x, y).
        /// @param layer : integer
        /// @param x : integer
        /// @param y : integer
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        methods.add_method(
            "setTileTint",
            |_, this, (layer, x, y, r, g, b, a): (usize, u32, u32, f32, f32, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .set_tile_tint(layer - 1, x - 1, y - 1, r, g, b, a);
                Ok(())
            },
        );

        // ── Rendering ──

        // -- render --
        /// Renders the tile map to the screen at the given offset.
        /// @param ox : number?
        /// @param oy : number?
        /// @return nil
        methods.add_method("render", |_, this, (ox, oy): (Option<f32>, Option<f32>)| {
            let sx = ox.unwrap_or(0.0);
            let sy = oy.unwrap_or(0.0);
            let cmds = this.inner.borrow().build_render_commands(sx, sy);
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });

        // -- drawToImage --
        /// Renders the tile map to a CPU ImageData using the given tile pixel size.
        /// @param tile_size : integer
        /// @return ImageData
        methods.add_method("drawToImage", |_, this, tile_size: u32| {
            let img = this.inner.borrow().draw_to_image(tile_size);
            Ok(LuaImageData { inner: img })
        });
    }
}

// -------------------------------------------------------------------------------
// LuaAutoTileSheet UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around an [`AutoTileSheet`].
#[derive(Clone)]
pub struct LuaAutoTileSheet {
    inner: Rc<RefCell<AutoTileSheet>>,
}

impl LuaUserData for LuaAutoTileSheet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getLayout --
        /// Returns the layout variant as a string.
        /// @return string
        methods.add_method("getLayout", |_, this, ()| {
            let l = this.inner.borrow().get_layout();
            Ok(match l {
                AutoTileLayout::Blob47 => "blob47",
                AutoTileLayout::Composite48 => "composite48",
                AutoTileLayout::Minimal16 => "minimal16",
            })
        });

        // -- getTileCount --
        /// Returns the number of tiles in this sheet.
        /// @return integer
        methods.add_method("getTileCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_count())
        });

        // -- getTileWidth --
        /// Returns the tile width in pixels.
        /// @return integer
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });

        // -- getTileHeight --
        /// Returns the tile height in pixels.
        /// @return integer
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });

        // -- applyToTileSet --
        /// Applies autotile rules from this sheet to a TileSet.
        /// @param tileset : TileSet
        /// @param typeName : string
        /// @param startGid : integer?
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

        // -- getBitmaskForTile --
        /// Returns the bitmask value associated with a 1-based local tile ID.
        /// @param tileId : integer
        /// @return integer
        methods.add_method("getBitmaskForTile", |_, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getBitmaskForTile: tile_id must be >= 1".to_string(),
                ));
            }
            Ok(this.inner.borrow().get_bitmask_for_tile(tile_id - 1))
        });

        // -- getTileForBitmask --
        /// Returns the 1-based tile ID for a given bitmask, or nil.
        /// @param bitmask : integer
        /// @return integer?
        methods.add_method("getTileForBitmask", |_, this, bitmask: u16| {
            Ok(this
                .inner
                .borrow()
                .get_tile_for_bitmask(bitmask)
                .map(|idx| idx + 1))
        });

        // -- getQuad --
        /// Returns the atlas region rectangle for the 1-based tile ID.
        /// @param tileId : integer
        /// @return number, number, number, number
        methods.add_method("getQuad", |_, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getQuad: tile_id must be >= 1".to_string(),
                ));
            }
            let r = this.inner.borrow().get_quad(tile_id - 1);
            Ok((r.x, r.y, r.width, r.height))
        });
    }
}

// -------------------------------------------------------------------------------
// LuaChunkMap UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`ChunkMap`].
#[derive(Clone)]
pub struct LuaChunkMap {
    inner: Rc<RefCell<ChunkMap>>,
}

impl LuaUserData for LuaChunkMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getTile --
        /// Returns the GID at tile coordinate (x, y).
        /// @param x : integer
        /// @param y : integer
        /// @return integer
        methods.add_method("getTile", |_, this, (x, y): (i32, i32)| {
            Ok(this.inner.borrow().get_tile(x, y))
        });

        // -- setTile --
        /// Sets the GID at tile coordinate (x, y).
        /// @param x : integer
        /// @param y : integer
        /// @param gid : integer
        /// @return nil
        methods.add_method("setTile", |_, this, (x, y, gid): (i32, i32, u32)| {
            this.inner.borrow_mut().set_tile(x, y, gid);
            Ok(())
        });

        // -- clearTile --
        /// Clears the tile at (x, y) by setting its GID to 0.
        /// @param x : integer
        /// @param y : integer
        /// @return nil
        methods.add_method("clearTile", |_, this, (x, y): (i32, i32)| {
            this.inner.borrow_mut().clear_tile(x, y);
            Ok(())
        });

        // -- fillRect --
        /// Fills the rectangular tile region with a GID.
        /// @param x0 : integer
        /// @param y0 : integer
        /// @param x1 : integer
        /// @param y1 : integer
        /// @param gid : integer
        methods.add_method(
            "fillRect",
            |_, this, (x0, y0, x1, y1, gid): (i32, i32, i32, i32, u32)| {
                this.inner.borrow_mut().fill_rect(x0, y0, x1, y1, gid);
                Ok(())
            },
        );

        // -- loadChunk --
        /// Pre-allocates the chunk at chunk coordinates (cx, cy).
        /// @param cx : integer
        /// @param cy : integer
        /// @return nil
        methods.add_method("loadChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().load_chunk(cx, cy);
            Ok(())
        });

        // -- unloadChunk --
        /// Removes the chunk at chunk coordinates (cx, cy) from memory.
        /// @param cx : integer
        /// @param cy : integer
        /// @return nil
        methods.add_method("unloadChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().unload_chunk(cx, cy);
            Ok(())
        });

        // -- getChunkSize --
        /// Returns the chunk size (tiles per side).
        /// @return integer
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });

        // -- getLoadedChunks --
        /// Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
        /// @return table
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

        // -- getChunksInView --
        /// Returns chunk coordinates whose world-pixel footprint overlaps the given viewport.
        /// @param vx : number
        /// @param vy : number
        /// @param vw : number
        /// @param vh : number
        /// @param tw : number
        /// @param th : number
        /// @return table
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

        // -- chunkTileRange --
        /// Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).
        /// @param cx : integer
        /// @param cy : integer
        /// @return integer, integer, integer, integer
        methods.add_method("chunkTileRange", |_, this, (cx, cy): (i32, i32)| {
            let (x0, y0, x1, y1) = this.inner.borrow().chunk_tile_range(cx, cy);
            Ok((x0, y0, x1, y1))
        });
    }
}

// -------------------------------------------------------------------------------
// LuaIsoMap UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around an [`IsoMap`].
#[derive(Clone)]
pub struct LuaIsoMap {
    inner: Rc<RefCell<IsoMap>>,
}

impl LuaUserData for LuaIsoMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addLevel --
        /// Appends a new empty Z-level and returns its 1-based index.
        /// @return integer
        methods.add_method("addLevel", |_, this, ()| {
            let idx = this.inner.borrow_mut().add_level();
            Ok(idx + 1)
        });

        // -- getLevelCount --
        /// Returns the number of Z-levels currently in the map.
        /// @return integer
        methods.add_method("getLevelCount", |_, this, ()| {
            Ok(this.inner.borrow().get_level_count())
        });

        // -- setLevelVisible --
        /// Sets the visibility of a level (1-based z).
        /// @param z : integer
        /// @param visible : boolean
        /// @return nil
        methods.add_method("setLevelVisible", |_, this, (z, visible): (usize, bool)| {
            this.inner.borrow_mut().set_level_visible(z - 1, visible);
            Ok(())
        });

        // -- isLevelVisible --
        /// Returns the visibility of a level (1-based z).
        /// @param z : integer
        /// @return boolean
        methods.add_method("isLevelVisible", |_, this, z: usize| {
            Ok(this.inner.borrow().get_level_visible(z - 1))
        });

        // -- setTilePart --
        /// Writes a GID into the part slot of tile (x, y) on level z (1-based z, x, y; 0-based part).
        /// @param z : integer
        /// @param x : integer
        /// @param y : integer
        /// @param part : integer
        /// @param gid : integer
        methods.add_method(
            "setTilePart",
            |_, this, (z, x, y, part, gid): (usize, u32, u32, u32, u32)| {
                this.inner
                    .borrow_mut()
                    .set_tile_part(z - 1, x - 1, y - 1, part, gid);
                Ok(())
            },
        );

        // -- getTilePart --
        /// Reads the GID in the part slot of tile (x, y) on level z (1-based z, x, y; 0-based part).
        /// @param z : integer
        /// @param x : integer
        /// @param y : integer
        /// @param part : integer
        /// @return integer
        methods.add_method(
            "getTilePart",
            |_, this, (z, x, y, part): (usize, u32, u32, u32)| {
                Ok(this.inner.borrow().get_tile_part(z - 1, x - 1, y - 1, part))
            },
        );

        // -- fillLevel --
        /// Fills every cell in level z with gid for the given part (1-based z; 0-based part).
        /// @param z : integer
        /// @param part : integer
        /// @param gid : integer
        /// @return nil
        methods.add_method("fillLevel", |_, this, (z, part, gid): (usize, u32, u32)| {
            this.inner.borrow_mut().fill_level(z - 1, part, gid);
            Ok(())
        });

        // -- setOrigin --
        /// Sets the screen pixel origin.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("setOrigin", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_origin(x, y);
            Ok(())
        });

        // -- getWidth --
        /// Returns the map width in tiles.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));

        // -- getHeight --
        /// Returns the map height in tiles.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));

        // -- getTileWidth --
        /// Returns the tile footprint width in pixels.
        /// @return integer
        methods.add_method("getTileWidth", |_, this, ()| Ok(this.inner.borrow().tile_w));

        // -- getTileHeight --
        /// Returns the tile footprint height in pixels.
        /// @return integer
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().tile_h)
        });

        // -- getLevelHeight --
        /// Returns the vertical pixel offset between consecutive Z-levels.
        /// @return integer
        methods.add_method("getLevelHeight", |_, this, ()| {
            Ok(this.inner.borrow().level_height)
        });

        // -- tileToScreen --
        /// Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
        /// @param tx : number
        /// @param ty : number
        /// @param tz : number
        /// @return number, number
        methods.add_method("tileToScreen", |_, this, (tx, ty, tz): (f32, f32, f32)| {
            let (sx, sy) = this.inner.borrow().tile_to_screen(tx, ty, tz);
            Ok((sx, sy))
        });

        // -- screenToTile --
        /// Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
        /// @param sx : number
        /// @param sy : number
        /// @return number, number
        methods.add_method("screenToTile", |_, this, (sx, sy): (f32, f32)| {
            let (tx, ty) = this.inner.borrow().screen_to_tile(sx, sy);
            Ok((tx, ty))
        });
    }
}

// -------------------------------------------------------------------------------
// LuaMapBlock UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`MapBlock`].
#[derive(Clone)]
pub struct LuaMapBlock {
    inner: Rc<RefCell<MapBlock>>,
}

impl LuaUserData for LuaMapBlock {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setTile --
        /// Sets the GID of a tile at (x, y) on the given layer (1-based).
        /// @param layer : integer
        /// @param x : integer
        /// @param y : integer
        /// @param gid : integer
        methods.add_method(
            "setTile",
            |_, this, (layer, x, y, gid): (u32, u32, u32, u32)| {
                this.inner
                    .borrow_mut()
                    .set_tile(layer - 1, x - 1, y - 1, gid);
                Ok(())
            },
        );

        // -- getTile --
        /// Returns the GID of the tile at (x, y) on the given layer (1-based).
        /// @param layer : integer
        /// @param x : integer
        /// @param y : integer
        /// @return integer
        methods.add_method("getTile", |_, this, (layer, x, y): (u32, u32, u32)| {
            Ok(this.inner.borrow().get_tile(layer - 1, x - 1, y - 1))
        });

        // -- setSide --
        /// Sets the side connection ID for a segment on a given edge.
        /// @param edge : string
        /// @param segment : integer
        /// @param sideId : integer
        methods.add_method(
            "setSide",
            |_, this, (edge_str, segment, side_id): (String, u32, u32)| {
                let edge = Edge::from_str(&edge_str)
                    .ok_or_else(|| LuaError::external("invalid edge: use north/east/south/west"))?;
                this.inner.borrow_mut().set_side(edge, segment - 1, side_id);
                Ok(())
            },
        );

        // -- getSide --
        /// Returns the side connection ID for a segment on a given edge.
        /// @param edge : string
        /// @param segment : integer
        /// @return integer
        methods.add_method("getSide", |_, this, (edge_str, segment): (String, u32)| {
            let edge = Edge::from_str(&edge_str)
                .ok_or_else(|| LuaError::external("invalid edge: use north/east/south/west"))?;
            Ok(this.inner.borrow().get_side(edge, segment - 1))
        });

        // -- getWidth --
        /// Returns the block width in tiles.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });

        // -- getHeight --
        /// Returns the block height in tiles.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });

        // -- getDimensions --
        /// Returns the block dimensions as (width, height) in tiles.
        /// @return integer, integer
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_dimensions();
            Ok((w, h))
        });

        // -- getLayerCount --
        /// Returns the number of layers in this block.
        /// @return integer
        methods.add_method("getLayerCount", |_, this, ()| {
            Ok(this.inner.borrow().get_layer_count())
        });

        // -- getSegmentSize --
        /// Returns the segment size in tiles.
        /// @return integer
        methods.add_method("getSegmentSize", |_, this, ()| {
            Ok(this.inner.borrow().get_segment_size())
        });

        // -- getWidthInSegments --
        /// Returns the number of segments along the width.
        /// @return integer
        methods.add_method("getWidthInSegments", |_, this, ()| {
            Ok(this.inner.borrow().get_width_in_segments())
        });

        // -- getHeightInSegments --
        /// Returns the number of segments along the height.
        /// @return integer
        methods.add_method("getHeightInSegments", |_, this, ()| {
            Ok(this.inner.borrow().get_height_in_segments())
        });

        // -- setName --
        /// Sets the human-readable name of this block.
        /// @param name : string
        /// @return nil
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().set_name(&name);
            Ok(())
        });

        // -- getName --
        /// Returns the name of this block.
        /// @return string
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });

        // -- setWeight --
        /// Sets the placement weight.
        /// @param weight : number
        /// @return nil
        methods.add_method("setWeight", |_, this, weight: f32| {
            this.inner.borrow_mut().set_weight(weight);
            Ok(())
        });

        // -- getWeight --
        /// Returns the placement weight.
        /// @return number
        methods.add_method("getWeight", |_, this, ()| {
            Ok(this.inner.borrow().get_weight())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaMapGroup UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`MapGroup`].
#[derive(Clone)]
pub struct LuaMapGroup {
    inner: Rc<RefCell<MapGroup>>,
}

impl LuaUserData for LuaMapGroup {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addBlock --
        /// Adds a block to this group.
        /// @param block : MapBlock
        /// @return nil
        methods.add_method("addBlock", |_, this, block_ud: LuaAnyUserData| {
            let block = block_ud.borrow::<LuaMapBlock>()?;
            this.inner
                .borrow_mut()
                .add_block(block.inner.borrow().clone());
            Ok(())
        });

        // -- getBlockCount --
        /// Returns the number of blocks in this group.
        /// @return integer
        methods.add_method("getBlockCount", |_, this, ()| {
            Ok(this.inner.borrow().get_block_count())
        });

        // -- removeBlock --
        /// Removes a block by 1-based index.
        /// @param idx : integer
        /// @return nil
        methods.add_method("removeBlock", |_, this, idx: usize| {
            this.inner.borrow_mut().remove_block(idx - 1);
            Ok(())
        });

        // -- getName --
        /// Returns the name of this group.
        /// @return string
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });

        // -- addScript --
        /// Adds a MapScript to this group.
        /// @param script : MapScript
        /// @return nil
        methods.add_method("addScript", |_, this, script_ud: LuaAnyUserData| {
            let script = script_ud.borrow::<LuaMapScript>()?;
            this.inner
                .borrow_mut()
                .add_script(script.inner.borrow().clone());
            Ok(())
        });

        // -- getScriptCount --
        /// Returns the number of scripts in this group.
        /// @return integer
        methods.add_method("getScriptCount", |_, this, ()| {
            Ok(this.inner.borrow().get_script_count())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaMapScript UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`MapScript`] procedural generation script.
#[derive(Clone)]
pub struct LuaMapScript {
    inner: Rc<RefCell<MapScript>>,
}

impl LuaUserData for LuaMapScript {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getStepCount --
        /// Returns the number of steps in this script.
        /// @return integer
        methods.add_method("getStepCount", |_, this, ()| {
            Ok(this.inner.borrow().get_step_count())
        });

        // -- addStep --
        /// Appends a generation step from a step-definition table.
        /// Accepted type strings: "fillRandom", "placeBlock", "fillArea".
        /// @param stepDef : table  {type, x?, y?, w?, h?, gid?, chance?}
        /// @return nil
        methods.add_method("addStep", |_, this, step_def: LuaTable| {
            let step_type_str: String = step_def.get("type")?;
            let st = match step_type_str.as_str() {
                "fillRandom" => StepType::FillRandom,
                "placeBlock" => StepType::PlaceBlock,
                "fillArea" => StepType::FillArea,
                other => {
                    return Err(LuaError::RuntimeError(format!(
                        "addStep: unknown step type '{}'",
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
            let step = ScriptStep {
                step_type: st,
                x: get_u32_field(&step_def, "x"),
                y: get_u32_field(&step_def, "y"),
                width: get_u32_field(&step_def, "w"),
                height: get_u32_field(&step_def, "h"),
                tile_id: get_u32_field(&step_def, "gid"),
                chance: get_f32_field(&step_def, "chance"),
                ..Default::default()
            };
            this.inner.borrow_mut().add_step(step);
            Ok(())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaMapGen UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper for a map generator (size preset or explicit dimensions).
#[derive(Clone)]
pub struct LuaMapGen {
    group: Rc<RefCell<MapGroup>>,
    inner: Rc<RefCell<crate::tilemap::mapgen::MapGen>>,
    state: Rc<RefCell<SharedState>>,
}

impl LuaUserData for LuaMapGen {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- generate --
        /// Generates a TileMap using the group's blocks and an optional script index, seed, and layer name.
        /// @param scriptIndex : integer?
        /// @param seed : integer?
        /// @param layerName : string?
        /// @return TileMap
        methods.add_method(
            "generate",
            |_, this, (script_idx, seed, layer_name): (Option<usize>, Option<u64>, Option<String>)| {
                let script_index = script_idx.map(|i| if i == 0 { 0 } else { i - 1 });
                let name = layer_name.as_deref().unwrap_or("main");
                let tm = this
                    .inner
                    .borrow_mut()
                    .generate(&this.group.borrow(), script_index, seed, name);
                let inner_rc = Rc::new(RefCell::new(tm));
                // Register a weak ref for engine auto-collection.
                this.state.borrow_mut().auto_tilemaps.push(Rc::downgrade(&inner_rc));
                Ok(LuaTileMap {
                    inner: inner_rc,
                    state: this.state.clone(),
                })
            },
        );
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.tilemap` API table with the Lua VM.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ── Factory functions ───────────────────────────────────────────────

    // -- newTileSet --
    /// Creates a new TileSet with the given atlas layout parameters.
    /// @param firstGid : integer
    /// @param tileCount : integer
    /// @param columns : integer
    /// @param tileWidth : integer
    /// @param tileHeight : integer
    /// @param spacing : integer?
    /// @param margin : integer?
    /// @return TileSet
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

    // -- newTileMap --
    /// Creates a new TileMap with the given tile size and chunk size.
    /// @param tileWidth : integer
    /// @param tileHeight : integer
    /// @param chunkSize : integer?
    /// @return TileMap
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
                // Register a weak ref for engine auto-collection.
                s.borrow_mut().auto_tilemaps.push(Rc::downgrade(&inner_rc));
                lua.create_userdata(LuaTileMap {
                    inner: inner_rc,
                    state: s.clone(),
                })
            },
        )?,
    )?;

    // -- newAutoTileSheet --
    /// Creates a new AutoTileSheet with the given tile dimensions and layout.
    /// @param tileWidth : integer
    /// @param tileHeight : integer
    /// @param layout : string?
    /// @return AutoTileSheet
    tbl.set(
        "newAutoTileSheet",
        lua.create_function(
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

    // -- newChunkMap --
    /// Creates a new ChunkMap with the given chunk size.
    /// @param chunkSize : integer?
    /// @return ChunkMap
    tbl.set(
        "newChunkMap",
        lua.create_function(|lua, chunk_size: Option<u32>| {
            lua.create_userdata(LuaChunkMap {
                inner: Rc::new(RefCell::new(ChunkMap::new(chunk_size.unwrap_or(16)))),
            })
        })?,
    )?;

    // -- newIsoMap --
    /// Creates a new IsoMap with no levels.
    /// @param width : integer
    /// @param height : integer
    /// @param tileW : integer
    /// @param tileH : integer
    /// @param levelHeight : integer
    /// @return IsoMap
    tbl.set(
        "newIsoMap",
        lua.create_function(
            |lua, (width, height, tile_w, tile_h, level_height): (u32, u32, u32, u32, u32)| {
                lua.create_userdata(LuaIsoMap {
                    inner: Rc::new(RefCell::new(IsoMap::new(
                        width,
                        height,
                        tile_w,
                        tile_h,
                        level_height,
                    ))),
                })
            },
        )?,
    )?;

    // -- newMapBlock --
    /// Creates a new MapBlock with the given dimensions.
    /// @param width : integer
    /// @param height : integer
    /// @param layers : integer?
    /// @param segmentSize : integer?
    /// @return MapBlock
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

    // -- newMapGroup --
    /// Creates a new empty MapGroup with the given name.
    /// @param name : string
    /// @return MapGroup
    tbl.set(
        "newMapGroup",
        lua.create_function(|lua, name: String| {
            lua.create_userdata(LuaMapGroup {
                inner: Rc::new(RefCell::new(MapGroup::new(&name))),
            })
        })?,
    )?;

    // ── Coordinate helper functions ─────────────────────────────────────

    // -- toScreenIso --
    /// Converts tile coordinates to screen position using diamond isometric projection.
    /// @param tx : number
    /// @param ty : number
    /// @param tileW : number
    /// @param tileH : number
    /// @return number, number
    tbl.set(
        "toScreenIso",
        lua.create_function(|_, (tx, ty, tw, th): (f32, f32, f32, f32)| {
            let v = coords::to_screen_iso(tx, ty, tw, th);
            Ok((v.x, v.y))
        })?,
    )?;

    // -- fromScreenIso --
    /// Converts screen position back to tile coordinates for diamond isometric projection.
    /// @param sx : number
    /// @param sy : number
    /// @param tileW : number
    /// @param tileH : number
    /// @return number, number
    tbl.set(
        "fromScreenIso",
        lua.create_function(|_, (sx, sy, tw, th): (f32, f32, f32, f32)| {
            let v = coords::from_screen_iso(sx, sy, tw, th);
            Ok((v.x, v.y))
        })?,
    )?;

    // -- toScreenHex --
    /// Converts axial hex coordinates to screen position (pointy-top layout).
    /// @param q : integer
    /// @param r : integer
    /// @param size : number
    /// @return number, number
    tbl.set(
        "toScreenHex",
        lua.create_function(|_, (q, r, size): (i32, i32, f32)| {
            let v = coords::to_screen_hex(q, r, size);
            Ok((v.x, v.y))
        })?,
    )?;

    // -- fromScreenHex --
    /// Converts screen position back to axial hex coordinates (pointy-top layout).
    /// @param sx : number
    /// @param sy : number
    /// @param size : number
    /// @return integer, integer
    tbl.set(
        "fromScreenHex",
        lua.create_function(|_, (sx, sy, size): (f32, f32, f32)| {
            let (q, r) = coords::from_screen_hex(sx, sy, size);
            Ok((q, r))
        })?,
    )?;

    // -- hexNeighbors --
    /// Returns the six axial neighbor coordinates as a table of {q, r} pairs.
    /// @param q : integer
    /// @param r : integer
    /// @return table
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

    // -- hexDistance --
    /// Returns the hex distance between two axial coordinates.
    /// @param q1 : integer
    /// @param r1 : integer
    /// @param q2 : integer
    /// @param r2 : integer
    /// @return integer
    tbl.set(
        "hexDistance",
        lua.create_function(|_, (q1, r1, q2, r2): (i32, i32, i32, i32)| {
            Ok(coords::hex_distance(q1, r1, q2, r2))
        })?,
    )?;

    // -- hexRound --
    /// Rounds fractional axial coordinates to the nearest hex cell.
    /// @param q : number
    /// @param r : number
    /// @return integer, integer
    tbl.set(
        "hexRound",
        lua.create_function(|_, (q, r): (f32, f32)| {
            let (rq, rr) = coords::hex_round(q, r);
            Ok((rq, rr))
        })?,
    )?;

    // -- hexLine --
    /// Returns all hex cells along a line between two axial coordinates as a table.
    /// @param q1 : integer
    /// @param r1 : integer
    /// @param q2 : integer
    /// @param r2 : integer
    /// @return table
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

    // -- hexRing --
    /// Returns all cells at exactly radius distance from (q, r) as a table.
    /// @param q : integer
    /// @param r : integer
    /// @param radius : integer
    /// @return table
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

    // -- hexSpiral --
    /// Returns all hex cells from center outward to radius, ring by ring, as a table.
    /// @param q : integer
    /// @param r : integer
    /// @param radius : integer
    /// @return table
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

    // -- hexArea --
    /// Returns all hex cells within radius distance (filled hex circle) as a table.
    /// @param q : integer
    /// @param r : integer
    /// @param radius : integer
    /// @return table
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

    // -- hexRotate --
    /// Rotates hex coordinates around a center by steps x 60 degrees clockwise.
    /// @param q : integer
    /// @param r : integer
    /// @param centerQ : integer
    /// @param centerR : integer
    /// @param steps : integer
    /// @return integer, integer
    tbl.set(
        "hexRotate",
        lua.create_function(
            |_, (q, r, center_q, center_r, steps): (i32, i32, i32, i32, i32)| {
                let (rq, rr) = coords::hex_rotate(q, r, center_q, center_r, steps);
                Ok((rq, rr))
            },
        )?,
    )?;

    // -- hexReflect --
    /// Reflects hex coordinates across an axis through the center.
    /// @param q : integer
    /// @param r : integer
    /// @param centerQ : integer
    /// @param centerR : integer
    /// @param axis : string
    /// @return integer, integer
    tbl.set(
        "hexReflect",
        lua.create_function(
            |_, (q, r, center_q, center_r, axis): (i32, i32, i32, i32, String)| {
                let (rq, rr) = coords::hex_reflect(q, r, center_q, center_r, &axis);
                Ok((rq, rr))
            },
        )?,
    )?;

    // -- isoRotate --
    /// Rotates an isometric direction (1-4) clockwise by steps.
    /// @param direction : integer
    /// @param steps : integer
    /// @return integer
    tbl.set(
        "isoRotate",
        lua.create_function(|_, (direction, steps): (i32, i32)| {
            Ok(coords::iso_rotate(direction, steps))
        })?,
    )?;

    // -- isoDirectionName --
    /// Returns the name of an isometric direction (1-4).
    /// @param direction : integer
    /// @return string
    tbl.set(
        "isoDirectionName",
        lua.create_function(|_, direction: i32| Ok(coords::iso_direction_name(direction)))?,
    )?;

    // -- isoDirectionFromAngle --
    /// Snaps an angle (in radians) to the nearest isometric direction (1-4).
    /// @param angle : number
    /// @return integer
    tbl.set(
        "isoDirectionFromAngle",
        lua.create_function(|_, angle: f32| Ok(coords::iso_direction_from_angle(angle)))?,
    )?;

    // -- IsoMap layer constants --
    // @return integer — IsoMap layer index constant
    /// IsoMap floor layer index (1).
    tbl.set("FLOOR", 1u32)?;
    /// IsoMap north-wall layer index (2).
    tbl.set("NORTH_WALL", 2u32)?;
    /// IsoMap west-wall layer index (3).
    tbl.set("WEST_WALL", 3u32)?;
    /// IsoMap object layer index (4).
    tbl.set("OBJECT", 4u32)?;

    // -- newMapScript --
    /// Creates a new empty MapScript procedural generation script.
    /// @return MapScript
    tbl.set(
        "newMapScript",
        lua.create_function(|_, ()| {
            Ok(LuaMapScript {
                inner: Rc::new(RefCell::new(MapScript::new("lua_script"))),
            })
        })?,
    )?;

    let s3 = state.clone();
    // -- newMapGen --
    /// Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
    /// @param group : MapGroup
    /// @param preset : string  OR  w : integer
    /// @param segmentSize : integer  OR  h : integer
    /// @param segmentSize : integer?   (only used when w,h form)
    /// @return MapGen
    tbl.set(
        "newMapGen",
        lua.create_function(move |_, args: mlua::Variadic<LuaValue>| {
            if args.len() < 3 {
                return Err(LuaError::RuntimeError(
                    "newMapGen: expected (group, preset, segmentSize) or (group, w, h, segmentSize)"
                        .to_string(),
                ));
            }
            // arg[0]: MapGroup userdata
            let group_rc = if let LuaValue::UserData(ud) = &args[0] {
                let g = ud.borrow::<LuaMapGroup>()?;
                g.inner.clone()
            } else {
                return Err(LuaError::RuntimeError(
                    "newMapGen: first argument must be a MapGroup".to_string(),
                ));
            };

            // arg[1]: preset string OR width integer; arg[2]: segmentSize OR height
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
                    // numeric form: (group, w, h, segmentSize)
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
                    // Use a Custom variant by creating MapGen directly with w×h
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

    // -- loadTMX --
    /// Parses a TMX XML string and returns a table with map metadata and layers.
    /// @param xml : string
    /// @return table, string?  — (result_table, nil) on success; (nil, error_message) on failure
    tbl.set(
        "loadTMX",
        lua.create_function(|lua, xml: String| {
            let tmx = crate::tilemap::tmx::load_tmx(&xml).map_err(LuaError::RuntimeError)?;
            let result = lua.create_table()?;
            result.set("width", tmx.width)?;
            result.set("height", tmx.height)?;
            result.set("tileWidth", tmx.tile_width)?;
            result.set("tileHeight", tmx.tile_height)?;
            // @return table — TMX map data: {width, height, tileWidth, tileHeight, orientation, layers}
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
                // @return table — Layer entry: {type, name, width?, height?}
                let entry = lua.create_table()?;
                match layer {
                    crate::tilemap::tmx::TmxLayer::Tile(t) => {
                        entry.set("type", "tile")?;
                        entry.set("name", t.name.as_str())?;
                        entry.set("width", t.width)?;
                        entry.set("height", t.height)?;
                    }
                    crate::tilemap::tmx::TmxLayer::Object(o) => {
                        // @return table — Object layer entry: {type, name}
                        entry.set("type", "object")?;
                        entry.set("name", o.name.as_str())?;
                    }
                }
                layers_tbl.set(layer_idx, entry)?;
                layer_idx += 1;
            }
            // @return table — full TMX result with layers list
            result.set("layers", layers_tbl)?;
            Ok(result)
        })?,
    )?;

    // @param tbl : table — tilemap module registration
    luna.set("tilemap", tbl)?;
    Ok(())
}
