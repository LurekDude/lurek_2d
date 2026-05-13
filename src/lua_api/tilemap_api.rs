//! `lurek.tilemap` - Tile-based map authoring, chunk streaming, isometric and hex coordinate helpers.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

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

// Convert a 1-based `usize` Lua index to a 0-based engine index, returning a
// Lua error (not a panic) when the caller passes `0`.
fn one_based_usize(name: &str, val: usize) -> LuaResult<usize> {
    val.checked_sub(1)
        .ok_or_else(|| mlua::Error::RuntimeError(format!("{name} must be >= 1 (got {val})")))
}

// Convert a 1-based `u32` Lua index to a 0-based engine index, returning a
// Lua error (not a panic) when the caller passes `0`.
fn one_based_u32(name: &str, val: u32) -> LuaResult<u32> {
    val.checked_sub(1)
        .ok_or_else(|| mlua::Error::RuntimeError(format!("{name} must be >= 1 (got {val})")))
}

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
        /// @return | integer | First global tile ID assigned to this tileset.
        methods.add_method("getFirstGid", |_, this, ()| {
            Ok(this.inner.borrow().get_first_gid())
        });

        // -- getTileCount --
        /// Returns the total number of tiles in this tileset.
        /// @return | integer | Total number of tiles in this tileset.
        methods.add_method("getTileCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_count())
        });

        // -- getColumns --
        /// Returns the number of tile columns in the atlas texture.
        /// @return | integer | Number of tile columns in the atlas texture.
        methods.add_method("getColumns", |_, this, ()| {
            Ok(this.inner.borrow().get_columns())
        });

        // -- getTileWidth --
        /// Returns the width of a single tile in pixels.
        /// @return | integer | Width of a single tile in pixels.
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });

        // -- getTileHeight --
        /// Returns the height of a single tile in pixels.
        /// @return | integer | Height of a single tile in pixels.
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });

        // -- getTileDimensions --
        /// Returns the tile dimensions as (width, height).
        /// @return | integer | Tile width in pixels.
        /// @return | integer | Tile height in pixels.
        methods.add_method("getTileDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_tile_dimensions();
            Ok((w, h))
        });

        // -- getSpacing --
        /// Returns the spacing in pixels between tiles in the atlas.
        /// @return | integer | Spacing in pixels between tiles in the atlas.
        methods.add_method("getSpacing", |_, this, ()| {
            Ok(this.inner.borrow().get_spacing())
        });

        // -- getMargin --
        /// Returns the margin in pixels around the edges of the atlas.
        /// @return | integer | Margin in pixels around the atlas edges.
        methods.add_method("getMargin", |_, this, ()| {
            Ok(this.inner.borrow().get_margin())
        });

        // -- getQuad --
        /// Computes the atlas source rectangle for a 1-based local tile ID.
        /// @param | tileId | integer | 1-based local tile ID.
        /// @return | table | Atlas source rectangle table with x, y, width, and height fields.
        methods.add_method("getQuad", |lua, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getQuad: tile_id must be >= 1".to_string(),
                ));
            }
            let r = this.inner.borrow().get_quad(tile_id - 1);
            // Returns `{x, y, width, height}` for the tile's source rectangle.
            let tbl = lua.create_table()?;
            tbl.set("x", r.x)?;
            tbl.set("y", r.y)?;
            tbl.set("width", r.width)?;
            tbl.set("height", r.height)?;
            Ok(tbl)
        });

        // -- setAnimation --
        /// Sets the animation frames for a 1-based local tile ID from a table of {tileid, duration}.
        /// @param | tileId | integer | 1-based local tile ID.
        /// @param | frames | table | Sequential table of frame tables with tileid and duration fields.
        /// @return | nil | No value is returned.
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
        /// @param | tileId | integer | 1-based local tile ID.
        /// @return | table | Sequential table of frame tables, or nil if the tile has no animation.
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
                        // Returns `{tileid, duration}` for one animation frame.
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
        /// @param | tileId | integer | 1-based local tile ID.
        /// @param | solid | boolean | Whether the tile should be treated as solid.
        /// @return | nil | No value is returned.
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
        /// @param | tileId | integer | 1-based local tile ID.
        /// @return | boolean | Whether the tile is solid.
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
        /// @param | typeName | string | Autotile rule set name.
        /// @param | bitmask | integer | 4-bit cardinal autotile bitmask.
        /// @param | tileId | integer | 1-based local tile ID to assign.
        /// @return | nil | No value is returned.
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
        /// @param | typeName | string | Autotile rule set name.
        /// @param | bitmask | integer | 4-bit cardinal autotile bitmask.
        /// @return | integer | Matching 1-based local tile ID, or nil if no rule matches.
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
        /// @param | typeName | string | Autotile rule set name.
        /// @param | bitmask | integer | 8-bit directional autotile bitmask.
        /// @param | tileId | integer | 1-based local tile ID to assign.
        /// @return | nil | No value is returned.
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
        /// @param | typeName | string | Autotile rule set name.
        /// @param | bitmask | integer | 8-bit directional autotile bitmask.
        /// @return | integer | Matching 1-based local tile ID, or nil if no rule matches.
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

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Literal type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LTileSet"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | Whether this userdata matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTileSet" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaTileMap UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`TileMap`] with callback registries and shared engine state.`r`n#[derive(Clone)]
pub struct LuaTileMap {
    pub(super) inner: Rc<RefCell<TileMap>>,
    state: Rc<RefCell<SharedState>>,
    tile_callbacks: Rc<RefCell<Vec<(u32, LuaRegistryKey)>>>,
    tile_exit_callbacks: Rc<RefCell<HashMap<u32, LuaRegistryKey>>>,
    tile_step_callbacks: Rc<RefCell<HashMap<u32, LuaRegistryKey>>>,
}

impl LuaUserData for LuaTileMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addTileSet --
        /// Adds a tileset to this map.
        /// @param | tileset | LTileSet | Tileset userdata to attach to the map.
        /// @return | nil | No value is returned.
        methods.add_method("addTileSet", |_, this, ts_ud: LuaAnyUserData| {
            let ts = ts_ud.borrow::<LuaTileSet>()?;
            this.inner
                .borrow_mut()
                .add_tileset(ts.inner.borrow().clone());
            Ok(())
        });

        // -- getTileSetCount --
        /// Returns the number of tilesets attached to this map.
        /// @return | integer | Number of tilesets attached to this map.
        methods.add_method("getTileSetCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tileset_count())
        });

        // -- getTileSet --
        /// Returns a tileset by 1-based index, or nil if out of range.
        /// @param | idx | integer | 1-based tileset index.
        /// @return | LTileSet | Tileset userdata at the index, or nil if the index is out of range.
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
        /// @param | name | string | Layer name.
        /// @param | w | integer | Layer width in tiles.
        /// @param | h | integer | Layer height in tiles.
        /// @return | integer | 1-based index of the new layer.
        methods.add_method("addLayer", |_, this, (name, w, h): (String, u32, u32)| {
            let idx = this.inner.borrow_mut().add_layer(&name, w, h);
            Ok(idx + 1)
        });

        // -- getLayerCount --
        /// Returns the number of layers.
        /// @return | integer | Number of layers in this map.
        methods.add_method("getLayerCount", |_, this, ()| {
            Ok(this.inner.borrow().get_layer_count())
        });

        // -- getLayerName --
        /// Returns the name of a layer by 1-based index.
        /// @param | idx | integer | 1-based layer index.
        /// @return | string | Layer name, or nil if the index is out of range.
        methods.add_method("getLayerName", |_, this, idx: usize| {
            Ok(this
                .inner
                .borrow()
                .get_layer_name(idx - 1)
                .map(|s| s.to_string()))
        });

        // -- setLayerVisible --
        /// Shows or hides a tile layer by its 1-based index.
        /// @param | idx | integer | 1-based layer index.
        /// @param | visible | boolean | Whether the layer should be visible.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setLayerVisible",
            |_, this, (idx, visible): (usize, bool)| {
                this.inner.borrow_mut().set_layer_visible(idx - 1, visible);
                Ok(())
            },
        );

        // -- getLayerVisible --
        /// Returns layer visibility.
        /// @param | idx | integer | 1-based layer index.
        /// @return | boolean | Whether the layer is visible.
        methods.add_method("getLayerVisible", |_, this, idx: usize| {
            Ok(this.inner.borrow().get_layer_visible(idx - 1))
        });

        // -- setLayerColor --
        /// Sets the RGBA tint color for a layer.
        /// @param | idx | integer | 1-based layer index.
        /// @param | r | number | Red tint component.
        /// @param | g | number | Green tint component.
        /// @param | b | number | Blue tint component.
        /// @param | a | number | Alpha tint component.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setLayerColor",
            |_, this, (idx, r, g, b, a): (usize, f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_layer_color(idx - 1, r, g, b, a);
                Ok(())
            },
        );

        // -- getLayerColor --
        /// Returns the RGBA tint color of a layer.
        /// @param | idx | integer | 1-based layer index.
        /// @return | number | Layer red tint component.
        /// @return | number | Layer green tint component.
        /// @return | number | Layer blue tint component.
        /// @return | number | Layer alpha tint component.
        methods.add_method("getLayerColor", |_, this, idx: usize| {
            let c = this.inner.borrow().get_layer_color(idx - 1);
            Ok((c[0], c[1], c[2], c[3]))
        });

        // -- setLayerOffset --
        /// Sets the pixel offset for a layer.
        /// @param | idx | integer | 1-based layer index.
        /// @param | ox | number | Horizontal pixel offset.
        /// @param | oy | number | Vertical pixel offset.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setLayerOffset",
            |_, this, (idx, ox, oy): (usize, f32, f32)| {
                this.inner.borrow_mut().set_layer_offset(idx - 1, ox, oy);
                Ok(())
            },
        );

        // -- getLayerOffset --
        /// Returns the pixel offset of a layer.
        /// @param | idx | integer | 1-based layer index.
        /// @return | number | Horizontal pixel offset.
        /// @return | number | Vertical pixel offset.
        methods.add_method("getLayerOffset", |_, this, idx: usize| {
            let v = this.inner.borrow().get_layer_offset(idx - 1);
            Ok((v.x, v.y))
        });

        // -- setLayerParallax --
        /// Sets the parallax scrolling factor for a layer.
        /// @param | idx | integer | 1-based layer index.
        /// @param | px | number | Horizontal parallax factor.
        /// @param | py | number | Vertical parallax factor.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setLayerParallax",
            |_, this, (idx, px, py): (usize, f32, f32)| {
                this.inner.borrow_mut().set_layer_parallax(idx - 1, px, py);
                Ok(())
            },
        );

        // -- getLayerParallax --
        /// Returns the parallax factor of a layer.
        /// @param | idx | integer | 1-based layer index.
        /// @return | number | Horizontal parallax factor.
        /// @return | number | Vertical parallax factor.
        methods.add_method("getLayerParallax", |_, this, idx: usize| {
            let v = this.inner.borrow().get_layer_parallax(idx - 1);
            Ok((v.x, v.y))
        });

        // -- setTile --
        /// Sets the GID of a tile at (x, y) on the given layer (1-based).
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @param | gid | integer | Tile global ID to assign.
        /// @return | nil | No value is returned.
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
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @return | integer | Tile global ID at the requested cell.
        methods.add_method("getTile", |_, this, (layer, x, y): (usize, u32, u32)| {
            Ok(this.inner.borrow().get_tile(layer - 1, x - 1, y - 1))
        });

        // -- clearTile --
        /// Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @return | nil | No value is returned.
        methods.add_method("clearTile", |_, this, (layer, x, y): (usize, u32, u32)| {
            this.inner.borrow_mut().clear_tile(layer - 1, x - 1, y - 1);
            Ok(())
        });

        // -- fill --
        /// Fills an entire layer with the given GID (1-based layer).
        /// @param | layer | integer | 1-based layer index.
        /// @param | gid | integer | Tile global ID to write into every cell.
        /// @return | nil | No value is returned.
        methods.add_method("fill", |_, this, (layer, gid): (usize, u32)| {
            this.inner.borrow_mut().fill(layer - 1, gid);
            Ok(())
        });

        // -- tileTypeIndex --
        /// Builds a GID-to-positions index for the given layer.
        /// Returns a table mapping each non-zero GID to an array of {x, y} positions.
        /// Useful for "find all tiles of type T" queries.
        /// @param | layer | integer | 1-based layer index.
        /// @return | table | Table mapping each GID (integer key) to an array of {x, y} tables.
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

        // -- findTilesByGid --
        /// Returns all (x, y) positions in the layer where the tile GID matches the given value.
        /// @param | layer | integer | 1-based layer index.
        /// @param | gid | integer | Tile GID to search for.
        /// @return | table | Array of {x, y} tables for each matching position.
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

        // -- setViewport --
        /// Sets the viewport rectangle for rendering culling.
        /// @param | x | number | Viewport left position in world pixels.
        /// @param | y | number | Viewport top position in world pixels.
        /// @param | w | number | Viewport width in pixels.
        /// @param | h | number | Viewport height in pixels.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport(x, y, w, h);
                Ok(())
            },
        );

        // -- getViewport --
        /// Returns the viewport as (x, y, w, h) or nil if not set.
        /// @return | number | Viewport X coordinate.
        /// @return | number | Viewport Y coordinate.
        /// @return | number | Viewport width.
        /// @return | number | Viewport height.
        methods.add_method("getViewport", |_, this, ()| {
            match this.inner.borrow().get_viewport() {
                Some((x, y, w, h)) => Ok((Some(x), Some(y), Some(w), Some(h))),
                None => Ok((None, None, None, None)),
            }
        });

        // -- update --
        /// Advances tile animation timers by dt seconds.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- worldToTile --
        /// Converts world pixel coordinates to tile coordinates.
        /// @param | wx | number | World x position in pixels.
        /// @param | wy | number | World y position in pixels.
        /// @return | integer | 1-based tile column.
        /// @return | integer | 1-based tile row.
        methods.add_method("worldToTile", |_, this, (wx, wy): (f32, f32)| {
            let (tx, ty) = this.inner.borrow().world_to_tile(wx, wy);
            Ok((tx + 1, ty + 1))
        });

        // -- tileToWorld --
        /// Converts tile coordinates to world pixel coordinates (1-based input).
        /// @param | tx | integer | 1-based tile column.
        /// @param | ty | integer | 1-based tile row.
        /// @return | number | World X position in pixels.
        /// @return | number | World Y position in pixels.
        methods.add_method("tileToWorld", |_, this, (tx, ty): (u32, u32)| {
            let (wx, wy) = this.inner.borrow().tile_to_world(tx - 1, ty - 1);
            Ok((wx, wy))
        });

        // -- getTileWidth --
        /// Returns the tile width in pixels.
        /// @return | integer | Tile width in pixels.
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });

        // -- getTileHeight --
        /// Returns the tile height in pixels.
        /// @return | integer | Tile height in pixels.
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });

        // -- getTileDimensions --
        /// Returns tile dimensions as (width, height).
        /// @return | integer | Tile width in pixels.
        /// @return | integer | Tile height in pixels.
        methods.add_method("getTileDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_tile_dimensions();
            Ok((w, h))
        });

        // -- getChunkSize --
        /// Returns the chunk size used for spatial partitioning.
        /// @return | integer | Chunk size used for spatial partitioning.
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });

        // -- isSolid --
        /// Returns true if the tile at (x, y) on layer is solid (1-based).
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @return | boolean | Whether the tile at the requested cell is solid.
        methods.add_method("isSolid", |_, this, (layer, x, y): (usize, u32, u32)| {
            Ok(this.inner.borrow().is_solid(layer - 1, x - 1, y - 1))
        });

        // -- applyAutoTile --
        /// Applies 4-bit cardinal autotile rules to every tile on layer (1-based).
        /// @param | layer | integer | 1-based layer index.
        /// @param | typeName | string | Autotile rule set name.
        /// @return | nil | No value is returned.
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
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @param | typeName | string | Autotile rule set name.
        /// @return | nil | No value is returned.
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
        /// @param | layer | integer | 1-based layer index.
        /// @param | typeName | string | Autotile rule set name.
        /// @return | nil | No value is returned.
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
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @param | typeName | string | Autotile rule set name.
        /// @return | nil | No value is returned.
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
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | number | Rectangle left position in world pixels.
        /// @param | y | number | Rectangle top position in world pixels.
        /// @param | w | number | Rectangle width in pixels.
        /// @param | h | number | Rectangle height in pixels.
        /// @return | boolean | Whether any solid tile overlaps the rectangle.
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
        /// Performs a swept AABB collision test against solid tiles on a 1-based layer.
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | number | Starting rectangle left position in world pixels.
        /// @param | y | number | Starting rectangle top position in world pixels.
        /// @param | w | number | Rectangle width in pixels.
        /// @param | h | number | Rectangle height in pixels.
        /// @param | dx | number | Horizontal movement delta in pixels.
        /// @param | dy | number | Vertical movement delta in pixels.
        /// @return | number | Contact X position.
        /// @return | number | Contact Y position.
        /// @return | number | Collision normal X component.
        /// @return | number | Collision normal Y component.
        /// @return | number | 1-based hit tile column.
        /// @return | number | 1-based hit tile row.
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
        /// Returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal").
        /// @return | string | Current map orientation name.
        methods.add_method("getOrientation", |_, this, ()| {
            let o = this.inner.borrow().get_orientation();
            Ok(match o {
                MapOrientation::TopDown => "topdown",
                MapOrientation::SideView => "sideview",
                MapOrientation::Isometric => "isometric",
                MapOrientation::Hexagonal => "hexagonal",
            })
        });

        // -- setOrientation --
        /// Sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal").
        /// @param | orientation | string | Orientation name to apply.
        /// @return | nil | No value is returned.
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

        // -- setTileTint --
        /// Sets a per-tile RGBA tint override (1-based layer, x, y).
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @param | r | number | Red tint component.
        /// @param | g | number | Green tint component.
        /// @param | b | number | Blue tint component.
        /// @param | a | number | Alpha tint component.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setTileTint",
            |_, this, (layer, x, y, r, g, b, a): (usize, u32, u32, f32, f32, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .set_tile_tint(layer - 1, x - 1, y - 1, r, g, b, a);
                Ok(())
            },
        );

        // -- Rendering --

        // -- render --
        /// Renders the tile map to the screen at the given offset.
        /// @param | ox | number? | Optional horizontal render offset in pixels.
        /// @param | oy | number? | Optional vertical render offset in pixels.
        /// @return | nil | No value is returned.
        methods.add_method("render", |_, this, (ox, oy): (Option<f32>, Option<f32>)| {
            let sx = ox.unwrap_or(0.0);
            let sy = oy.unwrap_or(0.0);
            let cmds = this.inner.borrow().build_render_commands(sx, sy);
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });

        // -- drawToImage --
        /// Renders the tile map to a CPU ImageData using the given tile pixel size.
        /// @param | tile_size | integer | Tile size in pixels used for rasterization.
        /// @return | LImageData | CPU image data containing the rendered tile map.
        methods.add_method("drawToImage", |_, this, tile_size: u32| {
            let img = this.inner.borrow().draw_to_image(tile_size);
            Ok(img)
        });

        // -- toNavGrid --
        /// Converts the given layer into a 2D navigation grid.
        /// @param | layer | integer | Layer index passed through to the underlying navigation-grid builder.
        /// @param | walkable_gids | table | Sequential table of tile global IDs to treat as walkable.
        /// @return | table | Table of row tables where true marks a walkable cell.
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

        // -- onTileEnter --
        /// Registers a callback fired when an entity reaches a tile with the given GID.
        /// @param | gid | integer | Tile global ID to watch for.
        /// @param | func | function | Callback receiving world_x, world_y, tile_x, and tile_y.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "onTileEnter",
            |lua, this, (gid, func): (u32, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                this.tile_callbacks.borrow_mut().push((gid, key));
                Ok(())
            },
        );

        // -- checkEntities --
        /// Checks entity positions against registered tile-enter callbacks and fires matching callbacks.
        /// @param | layer | integer | Layer index passed through to the tile lookup.
        /// @param | entities | table | Sequential table of entity position tables with x and y fields.
        /// @return | nil | No value is returned.
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
        // -------------------------------------------------------------------
        // Tile Event Callbacks
        // -------------------------------------------------------------------

        // -- onTileStep --
        /// Registers a callback for when an entity steps on a tile with the given GID.
        /// @param | gid | integer | Tile global ID to watch for.
        /// @param | fn | function | Callback receiving entity, tile_x, and tile_y.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "onTileStep",
            |lua, this, (gid, func): (u32, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                this.tile_step_callbacks.borrow_mut().insert(gid, key);
                Ok(())
            },
        );

        // -- onTileExit --
        /// Registers a callback for when an entity exits a tile with the given GID.
        /// @param | gid | integer | Tile global ID to watch for.
        /// @param | fn | function | Callback receiving entity, tile_x, and tile_y.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "onTileExit",
            |lua, this, (gid, func): (u32, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                this.tile_exit_callbacks.borrow_mut().insert(gid, key);
                Ok(())
            },
        );

        // -- fireTileStep --
        /// Fires the tile-step callback for the given GID.
        /// @param | gid | integer | Tile global ID whose callback should be fired.
        /// @param | entity | table | Entity data passed to the callback.
        /// @param | tile_x | integer | Tile column passed to the callback.
        /// @param | tile_y | integer | Tile row passed to the callback.
        /// @return | nil | No value is returned.
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

        // -- fireTileExit --
        /// Fires the tile-exit callback for the given GID.
        /// @param | gid | integer | Tile global ID whose callback should be fired.
        /// @param | entity | table | Entity data passed to the callback.
        /// @param | tile_x | integer | Tile column passed to the callback.
        /// @param | tile_y | integer | Tile row passed to the callback.
        /// @return | nil | No value is returned.
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

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Literal type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LTileMap"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | Whether this userdata matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTileMap" || name == "Object")
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
        /// @return | string | Layout variant name.
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
        /// @return | integer | Number of tiles in this sheet.
        methods.add_method("getTileCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_count())
        });

        // -- getTileWidth --
        /// Returns the tile width in pixels.
        /// @return | integer | Tile width in pixels.
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });

        // -- getTileHeight --
        /// Returns the tile height in pixels.
        /// @return | integer | Tile height in pixels.
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });

        // -- applyToTileSet --
        /// Applies autotile rules from this sheet to a TileSet.
        /// @param | tileset | LTileSet | Tileset userdata to modify.
        /// @param | typeName | string | Autotile rule set name to populate.
        /// @param | startGid | integer? | Optional starting global ID offset.
        /// @return | nil | No value is returned.
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
        /// @param | tileId | integer | 1-based local tile ID.
        /// @return | integer | Bitmask value associated with the tile.
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
        /// @param | bitmask | integer | Bitmask value to look up.
        /// @return | integer | Matching 1-based tile ID, or nil if no tile matches.
        methods.add_method("getTileForBitmask", |_, this, bitmask: u16| {
            Ok(this
                .inner
                .borrow()
                .get_tile_for_bitmask(bitmask)
                .map(|idx| idx + 1))
        });

        // -- getQuad --
        /// Returns the atlas region rectangle for the 1-based tile ID.
        /// @param | tileId | integer | 1-based tile ID.
        /// @return | number | Atlas X coordinate.
        /// @return | number | Atlas Y coordinate.
        /// @return | number | Atlas region width.
        /// @return | number | Atlas region height.
        methods.add_method("getQuad", |_, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getQuad: tile_id must be >= 1".to_string(),
                ));
            }
            let r = this.inner.borrow().get_quad(tile_id - 1);
            Ok((r.x, r.y, r.width, r.height))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Literal type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LAutoTileSheet"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | Whether this userdata matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAutoTileSheet" || name == "Object")
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
        /// @param | x | integer | Tile column.
        /// @param | y | integer | Tile row.
        /// @return | integer | Tile global ID at the requested coordinate.
        methods.add_method("getTile", |_, this, (x, y): (i32, i32)| {
            Ok(this.inner.borrow().get_tile(x, y))
        });

        // -- setTile --
        /// Sets the GID at tile coordinate (x, y).
        /// @param | x | integer | Tile column.
        /// @param | y | integer | Tile row.
        /// @param | gid | integer | Tile global ID to assign.
        /// @return | nil | No value is returned.
        methods.add_method("setTile", |_, this, (x, y, gid): (i32, i32, u32)| {
            this.inner.borrow_mut().set_tile(x, y, gid);
            Ok(())
        });

        // -- clearTile --
        /// Clears the tile at (x, y) by setting its GID to 0.
        /// @param | x | integer | Tile column.
        /// @param | y | integer | Tile row.
        /// @return | nil | No value is returned.
        methods.add_method("clearTile", |_, this, (x, y): (i32, i32)| {
            this.inner.borrow_mut().clear_tile(x, y);
            Ok(())
        });

        // -- fillRect --
        /// Fills the rectangular tile region with a GID.
        /// @param | x0 | integer | Starting tile column.
        /// @param | y0 | integer | Starting tile row.
        /// @param | x1 | integer | Ending tile column.
        /// @param | y1 | integer | Ending tile row.
        /// @param | gid | integer | Tile global ID to write.
        /// @return | nil | No value is returned.
        methods.add_method(
            "fillRect",
            |_, this, (x0, y0, x1, y1, gid): (i32, i32, i32, i32, u32)| {
                this.inner.borrow_mut().fill_rect(x0, y0, x1, y1, gid);
                Ok(())
            },
        );

        // -- loadChunk --
        /// Pre-allocates the chunk at chunk coordinates (cx, cy).
        /// @param | cx | integer | Chunk column.
        /// @param | cy | integer | Chunk row.
        /// @return | nil | No value is returned.
        methods.add_method("loadChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().load_chunk(cx, cy);
            Ok(())
        });

        // -- unloadChunk --
        /// Removes the chunk at chunk coordinates (cx, cy) from memory.
        /// @param | cx | integer | Chunk column.
        /// @param | cy | integer | Chunk row.
        /// @return | nil | No value is returned.
        methods.add_method("unloadChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().unload_chunk(cx, cy);
            Ok(())
        });

        // -- getChunkSize --
        /// Returns the chunk size (tiles per side).
        /// @return | integer | Chunk size in tiles per side.
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });

        // -- getLoadedChunks --
        /// Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
        /// @return | table | Sequential table of chunk coordinate pairs.
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
        /// @param | vx | number | Viewport left position in world pixels.
        /// @param | vy | number | Viewport top position in world pixels.
        /// @param | vw | number | Viewport width in pixels.
        /// @param | vh | number | Viewport height in pixels.
        /// @param | tw | number | Tile width in pixels.
        /// @param | th | number | Tile height in pixels.
        /// @return | table | Sequential table of visible chunk coordinate pairs.
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
        /// @param | cx | integer | Chunk column.
        /// @param | cy | integer | Chunk row.
        /// @return | integer | Starting tile column for the chunk.
        /// @return | integer | Starting tile row for the chunk.
        /// @return | integer | Ending tile column for the chunk.
        /// @return | integer | Ending tile row for the chunk.
        methods.add_method("chunkTileRange", |_, this, (cx, cy): (i32, i32)| {
            let (x0, y0, x1, y1) = this.inner.borrow().chunk_tile_range(cx, cy);
            Ok((x0, y0, x1, y1))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Literal type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LChunkMap"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | Whether this userdata matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LChunkMap" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaLargeMapRenderer UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`LargeMapRenderer`] for chunk-level occlusion culling on large worlds.
///
/// # Fields
/// - `inner` - `Rc<RefCell<LargeMapRenderer>>`.
#[derive(Clone)]
pub struct LuaLargeMapRenderer {
    inner: Rc<RefCell<LargeMapRenderer>>,
}

impl LuaUserData for LuaLargeMapRenderer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setMapData --
        /// Loads a flat row-major array of tile IDs covering width by height tiles.
        /// @param | data | table | Sequential table of tile IDs where 0 represents an empty tile.
        /// @param | width | integer | Map width in tiles.
        /// @param | height | integer | Map height in tiles.
        /// @return | nil | No value is returned.
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

        // -- setTile --
        /// Sets a single tile ID at (x, y).  Coordinates are 0-based.
        /// @param | x | integer | 0-based tile column.
        /// @param | y | integer | 0-based tile row.
        /// @param | tileId | integer | Tile ID to assign.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTile", |_, this, (x, y, tile_id): (u32, u32, u32)| {
            this.inner.borrow_mut().set_tile(x, y, tile_id);
            Ok(())
        });

        // -- getTile --
        /// Returns the tile ID at (x, y), or nil if out of bounds.
        /// @param | x | integer | 0-based tile column.
        /// @param | y | integer | 0-based tile row.
        /// @return | integer | Tile ID at the requested coordinate, or nil if it is out of bounds.
        methods.add_method("getTile", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_tile(x, y))
        });

        // -- getMapSize --
        /// Returns the map dimensions as (width, height) in tiles.
        /// @return | integer | Map width in tiles.
        /// @return | integer | Map height in tiles.
        methods.add_method("getMapSize", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_map_size();
            Ok((w, h))
        });

        // -- setChunkSize --
        /// Sets the chunk size used for culling (default 16).
        /// @param | size | integer | Chunk size used for culling.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setChunkSize", |_, this, size: u32| {
            this.inner.borrow_mut().set_chunk_size(size);
            Ok(())
        });

        // -- getChunkSize --
        /// Returns the current chunk size.
        /// @return | integer | Current chunk size.
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });

        // -- invalidateChunk --
        /// Marks a chunk at chunk-grid coordinates (cx, cy) as dirty.
        /// @param | cx | integer | Chunk column.
        /// @param | cy | integer | Chunk row.
        /// @return | nil | No value is returned.
        methods.add_method_mut("invalidateChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().invalidate_chunk(cx, cy);
            Ok(())
        });

        // -- invalidateAll --
        /// Marks every chunk as dirty.
        /// @return | nil | No value is returned.
        methods.add_method_mut("invalidateAll", |_, this, ()| {
            this.inner.borrow_mut().invalidate_all();
            Ok(())
        });

        // -- getVisibleChunks --
        /// Returns the number of chunks currently within the camera viewport.
        /// @return | integer | Number of chunks currently within the camera viewport.
        methods.add_method("getVisibleChunks", |_, this, ()| {
            Ok(this.inner.borrow().get_visible_chunks())
        });

        // -- getTotalChunks --
        /// Returns the total number of chunks that cover the loaded map.
        /// @return | integer | Total number of chunks that cover the loaded map.
        methods.add_method("getTotalChunks", |_, this, ()| {
            Ok(this.inner.borrow().get_total_chunks())
        });

        // -- setCamera --
        /// Updates the camera position and zoom used for visibility culling.
        /// @param | x | number | Camera x position.
        /// @param | y | number | Camera y position.
        /// @param | zoom | number | Camera zoom factor.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCamera", |_, this, (x, y, zoom): (f32, f32, f32)| {
            this.inner.borrow_mut().set_camera(x, y, zoom);
            Ok(())
        });

        // -- setViewport --
        /// Sets the viewport dimensions in pixels used for visibility culling.
        /// @param | width | number | Viewport width in pixels.
        /// @param | height | number | Viewport height in pixels.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setViewport", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_viewport(w, h);
            Ok(())
        });

        // -- setLodEnabled --
        /// Enables or disables level-of-detail rendering for distant chunks.
        /// @param | enabled | boolean | Whether LOD rendering should be enabled.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLodEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_lod_enabled(enabled);
            Ok(())
        });

        // -- isLodEnabled --
        /// Returns whether LOD rendering is currently enabled.
        /// @return | boolean | Whether LOD rendering is currently enabled.
        methods.add_method("isLodEnabled", |_, this, ()| {
            Ok(this.inner.borrow().is_lod_enabled())
        });

        // -- setLodThresholds --
        /// Sets the distance thresholds (in tile units) at which each LOD level activates.
        /// @param | levels | table | Sequential table of LOD threshold distances in tile units.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLodThresholds", |_, this, levels: LuaTable| {
            let mut thresholds: Vec<f32> = Vec::new();
            for v in levels.sequence_values::<f32>() {
                thresholds.push(v?);
            }
            this.inner.borrow_mut().set_lod_thresholds(thresholds);
            Ok(())
        });

        // -- setTilesetColumns --
        /// Sets the number of tile columns in the atlas texture used for UV calculation.
        /// @param | cols | integer | Number of atlas columns.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTilesetColumns", |_, this, cols: u32| {
            this.inner.borrow_mut().set_tileset_columns(cols);
            Ok(())
        });

        // -- getTilesetColumns --
        /// Returns the number of tileset atlas columns.
        /// @return | integer | Number of tileset atlas columns.
        methods.add_method("getTilesetColumns", |_, this, ()| {
            Ok(this.inner.borrow().get_tileset_columns())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Literal type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LLargeMapRenderer"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | Whether this userdata matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLargeMapRenderer" || name == "Object")
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
        /// @return | integer | 1-based index of the new level.
        methods.add_method("addLevel", |_, this, ()| {
            let idx = this.inner.borrow_mut().add_level();
            Ok(idx + 1)
        });

        // -- getLevelCount --
        /// Returns the number of Z-levels currently in the map.
        /// @return | integer | Number of Z-levels in the map.
        methods.add_method("getLevelCount", |_, this, ()| {
            Ok(this.inner.borrow().get_level_count())
        });

        // -- setLevelVisible --
        /// Sets the visibility of a level (1-based z).
        /// @param | z | integer | 1-based level index.
        /// @param | visible | boolean | Whether the level should be visible.
        /// @return | nil | No value is returned.
        methods.add_method("setLevelVisible", |_, this, (z, visible): (usize, bool)| {
            let z = one_based_usize("z", z)?;
            this.inner.borrow_mut().set_level_visible(z, visible);
            Ok(())
        });

        // -- isLevelVisible --
        /// Returns the visibility of a level (1-based z).
        /// @param | z | integer | 1-based level index.
        /// @return | boolean | Whether the level is visible.
        methods.add_method("isLevelVisible", |_, this, z: usize| {
            let z = one_based_usize("z", z)?;
            Ok(this.inner.borrow().get_level_visible(z))
        });

        // -- setTilePart --
        /// Writes a GID into the part slot of tile (x, y) on level z (1-based z, x, y; 0-based part).
        /// @param | z | integer | 1-based level index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @param | part | integer | 0-based part slot index.
        /// @param | gid | integer | Tile global ID to write.
        /// @return | nil | No value is returned.
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

        // -- getTilePart --
        /// Reads the GID in the part slot of tile (x, y) on level z (1-based z, x, y; 0-based part).
        /// @param | z | integer | 1-based level index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @param | part | integer | 0-based part slot index.
        /// @return | integer | Tile global ID stored in the requested part slot.
        methods.add_method(
            "getTilePart",
            |_, this, (z, x, y, part): (usize, u32, u32, u32)| {
                let z = one_based_usize("z", z)?;
                let x = one_based_u32("x", x)?;
                let y = one_based_u32("y", y)?;
                Ok(this.inner.borrow().get_tile_part(z, x, y, part))
            },
        );

        // -- fillLevel --
        /// Fills every cell in level z with gid for the given part (1-based z; 0-based part).
        /// @param | z | integer | 1-based level index.
        /// @param | part | integer | 0-based part slot index.
        /// @param | gid | integer | Tile global ID to write.
        /// @return | nil | No value is returned.
        methods.add_method("fillLevel", |_, this, (z, part, gid): (usize, u32, u32)| {
            let z = one_based_usize("z", z)?;
            this.inner.borrow_mut().fill_level(z, part, gid);
            Ok(())
        });

        // -- setOrigin --
        /// Sets the screen pixel origin.
        /// @param | x | number | Screen x origin in pixels.
        /// @param | y | number | Screen y origin in pixels.
        /// @return | nil | No value is returned.
        methods.add_method("setOrigin", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_origin(x, y);
            Ok(())
        });

        // -- getWidth --
        /// Returns the map width in tiles.
        /// @return | integer | Map width in tiles.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));

        // -- getHeight --
        /// Returns the map height in tiles.
        /// @return | integer | Map height in tiles.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));

        // -- getTileWidth --
        /// Returns the tile footprint width in pixels.
        /// @return | integer | Tile footprint width in pixels.
        methods.add_method("getTileWidth", |_, this, ()| Ok(this.inner.borrow().tile_w));

        // -- getTileHeight --
        /// Returns the tile footprint height in pixels.
        /// @return | integer | Tile footprint height in pixels.
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().tile_h)
        });

        // -- getLevelHeight --
        /// Returns the vertical pixel offset between consecutive Z-levels.
        /// @return | integer | Vertical pixel offset between consecutive Z-levels.
        methods.add_method("getLevelHeight", |_, this, ()| {
            Ok(this.inner.borrow().level_height)
        });

        // -- tileToScreen --
        /// Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
        /// @param | tx | number | Tile x coordinate.
        /// @param | ty | number | Tile y coordinate.
        /// @param | tz | number | Tile z coordinate.
        /// @return | number | Screen X position in pixels.
        /// @return | number | Screen Y position in pixels.
        methods.add_method("tileToScreen", |_, this, (tx, ty, tz): (f32, f32, f32)| {
            let (sx, sy) = this.inner.borrow().tile_to_screen(tx, ty, tz);
            Ok((sx, sy))
        });

        // -- screenToTile --
        /// Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
        /// @param | sx | number | Screen x position in pixels.
        /// @param | sy | number | Screen y position in pixels.
        /// @return | number | Tile X coordinate at level 0.
        /// @return | number | Tile Y coordinate at level 0.
        methods.add_method("screenToTile", |_, this, (sx, sy): (f32, f32)| {
            let (tx, ty) = this.inner.borrow().screen_to_tile(sx, sy);
            Ok((tx, ty))
        });

        // -- getPartCount --
        /// Returns the number of GID slots per tile.
        /// @return | integer | Number of GID slots per tile.
        methods.add_method("getPartCount", |_, this, ()| {
            Ok(this.inner.borrow().get_part_count())
        });

        // -- getPartOrder --
        /// Returns the current draw-order array (0-based part slot indices).
        /// @return | table | Sequential table of 0-based part slot indices.
        methods.add_method("getPartOrder", |lua, this, ()| {
            let order = this.inner.borrow().get_part_order().to_vec();
            let tbl = lua.create_table()?;
            for (i, &idx) in order.iter().enumerate() {
                tbl.set(i + 1, idx)?;
            }
            Ok(tbl)
        });

        // -- setPartOrder --
        /// Overrides the draw order for this IsoMap.
        /// @param | order | table | Sequential table of 0-based part slot indices with one entry per part.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setPartOrder", |_, this, order: Vec<u32>| {
            this.inner
                .borrow_mut()
                .set_part_order(order)
                .map_err(LuaError::external)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Literal type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LIsoMap"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | Whether this userdata matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LIsoMap" || name == "Object")
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
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @param | gid | integer | Tile global ID to assign.
        /// @return | nil | No value is returned.
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
        /// @param | layer | integer | 1-based layer index.
        /// @param | x | integer | 1-based tile column.
        /// @param | y | integer | 1-based tile row.
        /// @return | integer | Tile global ID at the requested cell.
        methods.add_method("getTile", |_, this, (layer, x, y): (u32, u32, u32)| {
            Ok(this.inner.borrow().get_tile(layer - 1, x - 1, y - 1))
        });

        // -- setSide --
        /// Sets the side connection ID for a segment on a given edge.
        /// @param | edge | string | Edge name: north, east, south, or west.
        /// @param | segment | integer | 1-based segment index on that edge.
        /// @param | sideId | integer | Side connection ID to assign.
        /// @return | nil | No value is returned.
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
        /// @param | edge | string | Edge name: north, east, south, or west.
        /// @param | segment | integer | 1-based segment index on that edge.
        /// @return | integer | Side connection ID for the segment.
        methods.add_method("getSide", |_, this, (edge_str, segment): (String, u32)| {
            let edge = Edge::from_str(&edge_str)
                .ok_or_else(|| LuaError::external("invalid edge: use north/east/south/west"))?;
            Ok(this.inner.borrow().get_side(edge, segment - 1))
        });

        // -- getWidth --
        /// Returns the block width in tiles.
        /// @return | integer | Block width in tiles.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });

        // -- getHeight --
        /// Returns the block height in tiles.
        /// @return | integer | Block height in tiles.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });

        // -- getDimensions --
        /// Returns the block dimensions as (width, height) in tiles.
        /// @return | integer | Block width in tiles.
        /// @return | integer | Block height in tiles.
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_dimensions();
            Ok((w, h))
        });

        // -- getLayerCount --
        /// Returns the number of layers in this block.
        /// @return | integer | Number of layers in this block.
        methods.add_method("getLayerCount", |_, this, ()| {
            Ok(this.inner.borrow().get_layer_count())
        });

        // -- getSegmentSize --
        /// Returns the segment size in tiles.
        /// @return | integer | Segment size in tiles.
        methods.add_method("getSegmentSize", |_, this, ()| {
            Ok(this.inner.borrow().get_segment_size())
        });

        // -- getWidthInSegments --
        /// Returns the number of segments along the width.
        /// @return | integer | Number of segments along the width.
        methods.add_method("getWidthInSegments", |_, this, ()| {
            Ok(this.inner.borrow().get_width_in_segments())
        });

        // -- getHeightInSegments --
        /// Returns the number of segments along the height.
        /// @return | integer | Number of segments along the height.
        methods.add_method("getHeightInSegments", |_, this, ()| {
            Ok(this.inner.borrow().get_height_in_segments())
        });

        // -- setName --
        /// Sets the human-readable name of this block.
        /// @param | name | string | Human-readable block name.
        /// @return | nil | No value is returned.
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().set_name(&name);
            Ok(())
        });

        // -- getName --
        /// Returns the name of this block.
        /// @return | string | Human-readable block name.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });

        // -- setWeight --
        /// Sets the placement weight.
        /// @param | weight | number | Placement weight value.
        /// @return | nil | No value is returned.
        methods.add_method("setWeight", |_, this, weight: f32| {
            this.inner.borrow_mut().set_weight(weight);
            Ok(())
        });

        // -- getWeight --
        /// Returns the placement weight.
        /// @return | number | Placement weight value.
        methods.add_method("getWeight", |_, this, ()| {
            Ok(this.inner.borrow().get_weight())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Literal type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LMapBlock"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | Whether this userdata matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapBlock" || name == "Object")
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
        /// @param | block | LMapBlock | Map block userdata to add.
        /// @return | nil | No value is returned.
        methods.add_method("addBlock", |_, this, block_ud: LuaAnyUserData| {
            let block = block_ud.borrow::<LuaMapBlock>()?;
            this.inner
                .borrow_mut()
                .add_block(block.inner.borrow().clone());
            Ok(())
        });

        // -- getBlockCount --
        /// Returns the number of blocks in this group.
        /// @return | integer | Number of blocks in this group.
        methods.add_method("getBlockCount", |_, this, ()| {
            Ok(this.inner.borrow().get_block_count())
        });

        // -- removeBlock --
        /// Removes a block by 1-based index.
        /// @param | idx | integer | 1-based block index.
        /// @return | nil | No value is returned.
        methods.add_method("removeBlock", |_, this, idx: usize| {
            this.inner.borrow_mut().remove_block(idx - 1);
            Ok(())
        });

        // -- getName --
        /// Returns the name of this group.
        /// @return | string | Group name.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });

        // -- addScript --
        /// Adds a MapScript to this group.
        /// @param | script | LMapScript | Map script userdata to add.
        /// @return | nil | No value is returned.
        methods.add_method("addScript", |_, this, script_ud: LuaAnyUserData| {
            let script = script_ud.borrow::<LuaMapScript>()?;
            this.inner
                .borrow_mut()
                .add_script(script.inner.borrow().clone());
            Ok(())
        });

        // -- getScriptCount --
        /// Returns the number of scripts in this group.
        /// @return | integer | Number of scripts in this group.
        methods.add_method("getScriptCount", |_, this, ()| {
            Ok(this.inner.borrow().get_script_count())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Literal type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LMapGroup"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | Whether this userdata matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapGroup" || name == "Object")
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
        /// @return | integer | Number of steps in this script.
        methods.add_method("getStepCount", |_, this, ()| {
            Ok(this.inner.borrow().get_step_count())
        });

        // -- addStep --
        /// Appends a generation step from a step-definition table.
        /// @param | stepDef | table | Step definition table with a type field and optional placement fields.
        /// @return | nil | No value is returned.
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

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Literal type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LMapScript"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | Whether this userdata matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapScript" || name == "Object")
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
        /// @param | scriptIndex | integer? | Optional 1-based script index to run.
        /// @param | seed | integer? | Optional random seed.
        /// @param | layerName | string? | Optional name for the generated layer.
        /// @return | LTileMap | Generated tile map userdata.
        methods.add_method("generate", |_, this, (script_idx, seed, layer_name): (Option<usize>, Option<u64>, Option<String>)| {
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
                    tile_callbacks: Rc::new(RefCell::new(Vec::new())),
                    tile_step_callbacks: Rc::new(RefCell::new(HashMap::new())),
                    tile_exit_callbacks: Rc::new(RefCell::new(HashMap::new())),
                })
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Literal type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LMapGen"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | Whether this userdata matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapGen" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.tilemap` API table with the Lua VM.
/// @param | lua | any | Lua VM receiving the registration.
/// @param | lurek | table | Root lurek namespace table.
/// @param | state | any | Shared engine state used by tilemap userdata.
/// @return | nil | No value is returned.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- Factory functions -------------------------------------------------

    // -- newTileSet --
    /// Creates a new TileSet with the given atlas layout parameters.
    /// @param | firstGid | integer | First global tile ID assigned to the tileset.
    /// @param | tileCount | integer | Number of tiles in the tileset.
    /// @param | columns | integer | Number of columns in the atlas.
    /// @param | tileWidth | integer | Tile width in pixels.
    /// @param | tileHeight | integer | Tile height in pixels.
    /// @param | spacing | integer? | Optional spacing in pixels between atlas tiles.
    /// @param | margin | integer? | Optional margin in pixels around the atlas.
    /// @return | LTileSet | New tileset userdata.
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
    /// @param | tileWidth | integer | Tile width in pixels.
    /// @param | tileHeight | integer | Tile height in pixels.
    /// @param | chunkSize | integer? | Optional chunk size in tiles.
    /// @return | LTileMap | New tile map userdata.
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
                    tile_callbacks: Rc::new(RefCell::new(Vec::new())),
                    tile_step_callbacks: Rc::new(RefCell::new(HashMap::new())),
                    tile_exit_callbacks: Rc::new(RefCell::new(HashMap::new())),
                })
            },
        )?,
    )?;

    // -- newAutoTileSheet --
    /// Creates a new AutoTileSheet with the given tile dimensions and layout.
    /// @param | tileWidth | integer | Tile width in pixels.
    /// @param | tileHeight | integer | Tile height in pixels.
    /// @param | layout | string | Layout name: blob47, composite48, or minimal16.
    /// @return | LAutoTileSheet | New autotile sheet userdata.
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

    // -- newChunkMap --
    /// Creates a new ChunkMap with the given chunk size.
    /// @param | chunkSize | integer? | Optional chunk size in tiles.
    /// @return | LChunkMap | New chunk map userdata.
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
    /// @param | width | integer | Map width in tiles.
    /// @param | height | integer | Map height in tiles.
    /// @param | tileW | integer | Tile footprint width in pixels.
    /// @param | tileH | integer | Tile footprint height in pixels.
    /// @param | levelHeight | integer | Vertical pixel offset between levels.
    /// @param | partCount | integer? | Optional number of part slots per tile.
    /// @return | LIsoMap | New isometric map userdata.
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

    // -- newMapBlock --
    /// Creates a new MapBlock with the given dimensions.
    /// @param | width | integer | Block width in tiles.
    /// @param | height | integer | Block height in tiles.
    /// @param | layers | integer? | Optional number of layers.
    /// @param | segmentSize | integer? | Optional segment size in tiles.
    /// @return | LMapBlock | New map block userdata.
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
    /// @param | name | string | Group name.
    /// @return | LMapGroup | New map group userdata.
    tbl.set(
        "newMapGroup",
        lua.create_function(|lua, name: String| {
            lua.create_userdata(LuaMapGroup {
                inner: Rc::new(RefCell::new(MapGroup::new(&name))),
            })
        })?,
    )?;

    // -- Coordinate helper functions -------------------------------------------------

    // -- toScreenIso --
    /// Converts tile coordinates to screen position using diamond isometric projection.
    /// @param | tx | number | Tile x coordinate.
    /// @param | ty | number | Tile y coordinate.
    /// @param | tileW | number | Tile width in pixels.
    /// @param | tileH | number | Tile height in pixels.
    /// @return | number | Screen X position.
    /// @return | number | Screen Y position.
    tbl.set(
        "toScreenIso",
        lua.create_function(|_, (tx, ty, tw, th): (f32, f32, f32, f32)| {
            let v = coords::to_screen_iso(tx, ty, tw, th);
            Ok((v.x, v.y))
        })?,
    )?;

    // -- fromScreenIso --
    /// Converts screen position back to tile coordinates for diamond isometric projection.
    /// @param | sx | number | Screen x position.
    /// @param | sy | number | Screen y position.
    /// @param | tileW | number | Tile width in pixels.
    /// @param | tileH | number | Tile height in pixels.
    /// @return | number | Tile X coordinate.
    /// @return | number | Tile Y coordinate.
    tbl.set(
        "fromScreenIso",
        lua.create_function(|_, (sx, sy, tw, th): (f32, f32, f32, f32)| {
            let v = coords::from_screen_iso(sx, sy, tw, th);
            Ok((v.x, v.y))
        })?,
    )?;

    // -- toScreenHex --
    /// Converts axial hex coordinates to screen position (pointy-top layout).
    /// @param | q | integer | Axial q coordinate.
    /// @param | r | integer | Axial r coordinate.
    /// @param | size | number | Hex size in pixels.
    /// @return | number | Screen X position.
    /// @return | number | Screen Y position.
    tbl.set(
        "toScreenHex",
        lua.create_function(|_, (q, r, size): (i32, i32, f32)| {
            let v = coords::to_screen_hex(q, r, size);
            Ok((v.x, v.y))
        })?,
    )?;

    // -- fromScreenHex --
    /// Converts screen position back to axial hex coordinates (pointy-top layout).
    /// @param | sx | number | Screen x position.
    /// @param | sy | number | Screen y position.
    /// @param | size | number | Hex size in pixels.
    /// @return | integer | Axial q coordinate.
    /// @return | integer | Axial r coordinate.
    tbl.set(
        "fromScreenHex",
        lua.create_function(|_, (sx, sy, size): (f32, f32, f32)| {
            let (q, r) = coords::from_screen_hex(sx, sy, size);
            Ok((q, r))
        })?,
    )?;

    // -- hexNeighbors --
    /// Returns the six axial neighbor coordinates as a table of {q, r} pairs.
    /// @param | q | integer | Axial q coordinate.
    /// @param | r | integer | Axial r coordinate.
    /// @return | table | Sequential table of neighbor coordinate tables.
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
    /// @param | q1 | integer | First axial q coordinate.
    /// @param | r1 | integer | First axial r coordinate.
    /// @param | q2 | integer | Second axial q coordinate.
    /// @param | r2 | integer | Second axial r coordinate.
    /// @return | integer | Hex distance between the two coordinates.
    tbl.set(
        "hexDistance",
        lua.create_function(|_, (q1, r1, q2, r2): (i32, i32, i32, i32)| {
            Ok(coords::hex_distance(q1, r1, q2, r2))
        })?,
    )?;

    // -- hexRound --
    /// Rounds fractional axial coordinates to the nearest hex cell.
    /// @param | q | number | Fractional axial q coordinate.
    /// @param | r | number | Fractional axial r coordinate.
    /// @return | integer | Rounded axial q coordinate.
    /// @return | integer | Rounded axial r coordinate.
    tbl.set(
        "hexRound",
        lua.create_function(|_, (q, r): (f32, f32)| {
            let (rq, rr) = coords::hex_round(q, r);
            Ok((rq, rr))
        })?,
    )?;

    // -- hexLine --
    /// Returns all hex cells along a line between two axial coordinates as a table.
    /// @param | q1 | integer | Starting axial q coordinate.
    /// @param | r1 | integer | Starting axial r coordinate.
    /// @param | q2 | integer | Ending axial q coordinate.
    /// @param | r2 | integer | Ending axial r coordinate.
    /// @return | table | Sequential table of axial coordinate pairs along the line.
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
    /// @param | q | integer | Center axial q coordinate.
    /// @param | r | integer | Center axial r coordinate.
    /// @param | radius | integer | Ring radius.
    /// @return | table | Sequential table of axial coordinate pairs in the ring.
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
    /// @param | q | integer | Center axial q coordinate.
    /// @param | r | integer | Center axial r coordinate.
    /// @param | radius | integer | Maximum spiral radius.
    /// @return | table | Sequential table of axial coordinate pairs in spiral order.
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
    /// @param | q | integer | Center axial q coordinate.
    /// @param | r | integer | Center axial r coordinate.
    /// @param | radius | integer | Area radius.
    /// @return | table | Sequential table of axial coordinate pairs in the area.
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
    /// @param | q | integer | Axial q coordinate to rotate.
    /// @param | r | integer | Axial r coordinate to rotate.
    /// @param | centerQ | integer | Center axial q coordinate.
    /// @param | centerR | integer | Center axial r coordinate.
    /// @param | steps | integer | Number of 60-degree clockwise steps.
    /// @return | integer | Rotated axial q coordinate.
    /// @return | integer | Rotated axial r coordinate.
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
    /// @param | q | integer | Axial q coordinate to reflect.
    /// @param | r | integer | Axial r coordinate to reflect.
    /// @param | centerQ | integer | Center axial q coordinate.
    /// @param | centerR | integer | Center axial r coordinate.
    /// @param | axis | string | Reflection axis name.
    /// @return | integer | Reflected axial q coordinate.
    /// @return | integer | Reflected axial r coordinate.
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
    /// @param | direction | integer | Isometric direction index from 1 to 4.
    /// @param | steps | integer | Number of clockwise rotation steps.
    /// @return | integer | Rotated isometric direction index.
    tbl.set(
        "isoRotate",
        lua.create_function(|_, (direction, steps): (i32, i32)| {
            Ok(coords::iso_rotate(direction, steps))
        })?,
    )?;

    // -- isoDirectionName --
    /// Returns the name of an isometric direction (1-4).
    /// @param | direction | integer | Isometric direction index from 1 to 4.
    /// @return | string | Direction name.
    tbl.set(
        "isoDirectionName",
        lua.create_function(|_, direction: i32| Ok(coords::iso_direction_name(direction)))?,
    )?;

    // -- isoDirectionFromAngle --
    /// Snaps an angle (in radians) to the nearest isometric direction (1-4).
    /// @param | angle | number | Angle in radians.
    /// @return | integer | Nearest isometric direction index.
    tbl.set(
        "isoDirectionFromAngle",
        lua.create_function(|_, angle: f32| Ok(coords::iso_direction_from_angle(angle)))?,
    )?;

    // -- newMapScript --
    /// Creates a new empty MapScript procedural generation script.
    /// @return | LMapScript | New map script userdata.
    tbl.set(
        "newMapScript",
        lua.create_function(|_, ()| {
            Ok(LuaMapScript {
                inner: Rc::new(RefCell::new(MapScript::new("lua_script"))),
            })
        })?,
    )?;

    // -- IsoMap layer constants --
    // @return integer - IsoMap layer index constant
    /// IsoMap floor layer index (1).
    tbl.set("FLOOR", 1u32)?;
    /// IsoMap north-wall layer index (2).
    tbl.set("NORTH_WALL", 2u32)?;
    /// IsoMap west-wall layer index (3).
    tbl.set("WEST_WALL", 3u32)?;
    /// IsoMap object layer index (4).
    tbl.set("OBJECT", 4u32)?;

    let s3 = state.clone();
    // -- newMapGen --
    /// Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
    /// @param | group | LMapGroup | Source map group userdata.
    /// @param | presetOrWidth | any | Preset name string or explicit width integer.
    /// @param | segmentSizeOrHeight | any | Segment size for preset form or explicit height integer.
    /// @param | segmentSize | integer? | Optional segment size when using explicit width and height.
    /// @return | LMapGen | New map generator userdata.
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
                    // Use a Custom variant by creating MapGen directly with wÄ‚-h
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
    /// @param | xml | string | TMX XML source string.
    /// @return | table | Table containing map metadata and layer summaries.
    tbl.set(
        "loadTMX",
        lua.create_function(|lua, xml: String| {
            let tmx = crate::tilemap::tmx::load_tmx(&xml).map_err(LuaError::RuntimeError)?;
            let result = lua.create_table()?;
            result.set("width", tmx.width)?;
            result.set("height", tmx.height)?;
            result.set("tileWidth", tmx.tile_width)?;
            result.set("tileHeight", tmx.tile_height)?;
            // @return table - TMX map data: {width, height, tileWidth, tileHeight, orientation, layers}
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
                // @return table - Layer entry: {type, name, width?, height?}
                let entry = lua.create_table()?;
                match layer {
                    crate::tilemap::tmx::TmxLayer::Tile(t) => {
                        entry.set("type", "tile")?;
                        entry.set("name", t.name.as_str())?;
                        entry.set("width", t.width)?;
                        entry.set("height", t.height)?;
                    }
                    crate::tilemap::tmx::TmxLayer::Object(o) => {
                        // @return table - Object layer entry: {type, name}
                        entry.set("type", "object")?;
                        entry.set("name", o.name.as_str())?;
                    }
                }
                layers_tbl.set(layer_idx, entry)?;
                layer_idx += 1;
            }
            // @return table - full TMX result with layers list
            result.set("layers", layers_tbl)?;
            Ok(result)
        })?,
    )?;

    // -- fromLDtk --
    /// Parses an LDtk JSON export string and returns a TileMap.
    /// @param | json_str | string | LDtk JSON export string.
    /// @param | level_name | string? | Optional level name to load.
    /// @return | LTileMap | Tile map userdata created from the LDtk data.
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

    // -- newLargeMapRenderer --
    /// Creates a LargeMapRenderer for chunk-level occlusion culling on maps larger than 200x200 tiles.
    /// @param | tileW | integer | Tile width in pixels.
    /// @param | tileH | integer | Tile height in pixels.
    /// @return | LLargeMapRenderer | New large-map renderer userdata.
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

    // Namespace containing the tilemap API module.
    // Provides tile-based levels, chunks, layouts, and rendering helpers.
    lurek.set("tilemap", tbl)?;
    Ok(())
}
