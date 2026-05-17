//! `lurek.tilemap` - Provides tile-based map rendering with layers, animated tiles, auto-tiling, collision maps, and TMX/Tiled import.

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
/// Converts a one-based Lua index into a zero-based `usize` tile index.
fn one_based_usize(name: &str, val: usize) -> LuaResult<usize> {
    val.checked_sub(1)
        .ok_or_else(|| mlua::Error::RuntimeError(format!("{name} must be >= 1 (got {val})")))
}
/// Converts a one-based Lua index into a zero-based `u32` tile index.
fn one_based_u32(name: &str, val: u32) -> LuaResult<u32> {
    val.checked_sub(1)
        .ok_or_else(|| mlua::Error::RuntimeError(format!("{name} must be >= 1 (got {val})")))
}
/// Lua-side handle wrapping a `TileSet` for defining tile atlases, animations, solidity, and auto-tile rules.
#[derive(Clone)]
pub struct LuaTileSet {
    inner: Rc<RefCell<TileSet>>,
}
impl LuaUserData for LuaTileSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getFirstGid --
        /// Returns the first global tile ID (GID) of this tileset.
        /// @return | integer | First GID assigned to this tileset.
        methods.add_method("getFirstGid", |_, this, ()| {
            Ok(this.inner.borrow().get_first_gid())
        });
        // -- getTileCount --
        /// Returns the total number of tiles defined in this tileset.
        /// @return | integer | Total tile count.
        methods.add_method("getTileCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_count())
        });
        // -- getColumns --
        /// Returns the number of columns in the tileset atlas image.
        /// @return | integer | Column count.
        methods.add_method("getColumns", |_, this, ()| {
            Ok(this.inner.borrow().get_columns())
        });
        // -- getTileWidth --
        /// Returns the width of a single tile in pixels.
        /// @return | integer | Tile width in pixels.
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });
        // -- getTileHeight --
        /// Returns the height of a single tile in pixels.
        /// @return | integer | Tile height in pixels.
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });
        // -- getTileDimensions --
        /// Returns both tile width and height in pixels.
        /// @return | integer | Tile width in pixels.
        /// @return | integer | Tile height in pixels.
        methods.add_method("getTileDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_tile_dimensions();
            Ok((w, h))
        });
        // -- getSpacing --
        /// Returns the spacing between tiles in the atlas image, in pixels.
        /// @return | integer | Spacing in pixels.
        methods.add_method("getSpacing", |_, this, ()| {
            Ok(this.inner.borrow().get_spacing())
        });
        // -- getMargin --
        /// Returns the margin around the edge of the atlas image, in pixels.
        /// @return | integer | Margin in pixels.
        methods.add_method("getMargin", |_, this, ()| {
            Ok(this.inner.borrow().get_margin())
        });
        // -- getQuad --
        /// Returns the source rectangle (UV quad) for a tile in the atlas.
        /// @param | tileId | integer | Tile ID (1-based).
        /// @return | table | Table with fields `x`, `y`, `width`, `height` in pixels.
        methods.add_method("getQuad", |lua, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getQuad: tile_id must be >= 1".to_string(),
                ));
            }
            let r = this.inner.borrow().get_quad(tile_id - 1);
            let tbl = lua.create_table()?;
            /// Performs the 'x' operation.
            /// @return | nil | No value is returned.
            tbl.set("x", r.x)?;
            /// Performs the 'y' operation.
            /// @return | nil | No value is returned.
            tbl.set("y", r.y)?;
            /// Performs the 'width' operation.
            /// @return | nil | No value is returned.
            tbl.set("width", r.width)?;
            /// Performs the 'height' operation.
            /// @return | nil | No value is returned.
            tbl.set("height", r.height)?;
            Ok(tbl)
        });
        // -- setAnimation --
        /// Assigns an animation sequence to a tile. Each frame references another tile ID and a duration.
        /// @param | tileId | integer | Tile ID to animate (1-based).
        /// @param | frames | table | Array of `{tileid=number, duration=number}` frame definitions.
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
        /// Returns the animation frames for a tile, or nil if none are set.
        /// @param | tileId | integer | Tile ID to query (1-based).
        /// @return | table | Array of `{tileid=number, duration=number}` frames, or nil.
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
                        /// Performs the 'tileid' operation.
                        /// @return | nil | No value is returned.
                        entry.set("tileid", f.tile_id + 1)?;
                        /// Performs the 'duration' operation.
                        /// @return | nil | No value is returned.
                        entry.set("duration", f.duration_ms)?;
                        tbl.set(i + 1, entry)?;
                    }
                    Ok(LuaValue::Table(tbl))
                }
                None => Ok(LuaValue::Nil),
            }
        });
        // -- setSolid --
        /// Marks a tile as solid or non-solid for collision queries.
        /// @param | tileId | integer | Tile ID to modify (1-based).
        /// @param | solid | boolean | Whether the tile blocks movement.
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
        /// Checks whether a tile is marked as solid.
        /// @param | tileId | integer | Tile ID to check (1-based).
        /// @return | boolean | True if the tile is solid.
        methods.add_method("isSolid", |_, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "isSolid: tile_id must be >= 1".to_string(),
                ));
            }
            Ok(this.inner.borrow().is_solid(tile_id - 1))
        });
        // -- setAutoTileRule --
        /// Registers a 4-bit auto-tile rule mapping a bitmask to a tile ID for a named tile type.
        /// @param | typeName | string | Logical tile type name (e.g. "grass").
        /// @param | bitmask | integer | 4-bit neighbor bitmask (0..15).
        /// @param | tileId | integer | Tile ID to use for this bitmask (1-based).
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
        /// Looks up the tile ID for a 4-bit auto-tile bitmask and type name.
        /// @param | typeName | string | Logical tile type name.
        /// @param | bitmask | integer | 4-bit neighbor bitmask (0..15).
        /// @return | integer | Resolved tile ID (1-based), or nil if no rule matches.
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
        /// Registers an 8-bit auto-tile rule mapping a bitmask to a tile ID for a named tile type.
        /// @param | typeName | string | Logical tile type name.
        /// @param | bitmask | integer | 8-bit neighbor bitmask (0..255).
        /// @param | tileId | integer | Tile ID to use for this bitmask (1-based).
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
        /// Looks up the tile ID for an 8-bit auto-tile bitmask and type name.
        /// @param | typeName | string | Logical tile type name.
        /// @param | bitmask | integer | 8-bit neighbor bitmask (0..255).
        /// @return | integer | Resolved tile ID (1-based), or nil if no rule matches.
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
        /// Returns the type name of this userdata.
        /// @return | string | Always `"LTileSet"`.
        methods.add_method("type", |_, _, ()| Ok("LTileSet"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if `name` is `"LTileSet"` or `"Object"`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTileSet" || name == "Object")
        });
    }
}
/// Lua-side handle wrapping a `TileMap` with layers, tile data, collision, viewports, auto-tiling, and tile callbacks.
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
        /// Attaches a tileset to this map for tile rendering.
        /// @param | tileSet | LTileSet | Tileset to add.
        /// @return | nil | No value is returned.
        methods.add_method("addTileSet", |_, this, ts_ud: LuaAnyUserData| {
            let ts = ts_ud.borrow::<LuaTileSet>()?;
            this.inner
                .borrow_mut()
                .add_tileset(ts.inner.borrow().clone());
            Ok(())
        });
        // -- getTileSetCount --
        /// Returns how many tilesets are attached to this map.
        /// @return | integer | Tileset count.
        methods.add_method("getTileSetCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tileset_count())
        });
        // -- getTileSet --
        /// Returns the tileset at the given index.
        /// @param | idx | integer | Tileset index (1-based).
        /// @return | LTileSet | The tileset, or nil if index is out of range.
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
        /// Creates a new tile layer with the given name and dimensions.
        /// @param | name | string | Layer name.
        /// @param | w | integer | Width in tiles.
        /// @param | h | integer | Height in tiles.
        /// @return | integer | Index of the new layer (1-based).
        methods.add_method("addLayer", |_, this, (name, w, h): (String, u32, u32)| {
            let idx = this.inner.borrow_mut().add_layer(&name, w, h);
            Ok(idx + 1)
        });
        // -- getLayerCount --
        /// Returns the total number of layers in this map.
        /// @return | integer | Layer count.
        methods.add_method("getLayerCount", |_, this, ()| {
            Ok(this.inner.borrow().get_layer_count())
        });
        // -- getLayerName --
        /// Returns the name of a layer by index.
        /// @param | idx | integer | Layer index (1-based).
        /// @return | string | Layer name, or nil if index is out of range.
        methods.add_method("getLayerName", |_, this, idx: usize| {
            Ok(this
                .inner
                .borrow()
                .get_layer_name(idx - 1)
                .map(|s| s.to_string()))
        });
        // -- setLayerVisible --
        /// Sets whether a layer is drawn during rendering.
        /// @param | idx | integer | Layer index (1-based).
        /// @param | visible | boolean | True to show, false to hide.
        methods.add_method(
            "setLayerVisible",
            |_, this, (idx, visible): (usize, bool)| {
                this.inner.borrow_mut().set_layer_visible(idx - 1, visible);
                Ok(())
            },
        );
        // -- getLayerVisible --
        /// Returns whether a layer is currently visible.
        /// @param | idx | integer | Layer index (1-based).
        /// @return | boolean | True if the layer is visible.
        methods.add_method("getLayerVisible", |_, this, idx: usize| {
            Ok(this.inner.borrow().get_layer_visible(idx - 1))
        });
        // -- setLayerColor --
        /// Sets the tint color for an entire layer.
        /// @param | idx | integer | Layer index (1-based).
        /// @param | r | number | Red channel (0..1).
        /// @param | g | number | Green channel (0..1).
        /// @param | b | number | Blue channel (0..1).
        /// @param | a | number | Alpha channel (0..1).
        methods.add_method(
            "setLayerColor",
            |_, this, (idx, r, g, b, a): (usize, f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_layer_color(idx - 1, r, g, b, a);
                Ok(())
            },
        );
        // -- getLayerColor --
        /// Returns the tint color of a layer as four RGBA components.
        /// @param | idx | integer | Layer index (1-based).
        /// @return | number | Red (0..1).
        /// @return | number | Green (0..1).
        /// @return | number | Blue (0..1).
        /// @return | number | Alpha (0..1).
        methods.add_method("getLayerColor", |_, this, idx: usize| {
            let c = this.inner.borrow().get_layer_color(idx - 1);
            Ok((c[0], c[1], c[2], c[3]))
        });
        // -- setLayerOffset --
        /// Sets the pixel offset for a layer, shifting all tiles during rendering.
        /// @param | idx | integer | Layer index (1-based).
        /// @param | ox | number | Horizontal offset in pixels.
        /// @param | oy | number | Vertical offset in pixels.
        methods.add_method(
            "setLayerOffset",
            |_, this, (idx, ox, oy): (usize, f32, f32)| {
                this.inner.borrow_mut().set_layer_offset(idx - 1, ox, oy);
                Ok(())
            },
        );
        // -- getLayerOffset --
        /// Returns the pixel offset of a layer.
        /// @param | idx | integer | Layer index (1-based).
        /// @return | number | Horizontal offset.
        /// @return | number | Vertical offset.
        methods.add_method("getLayerOffset", |_, this, idx: usize| {
            let v = this.inner.borrow().get_layer_offset(idx - 1);
            Ok((v.x, v.y))
        });
        // -- setLayerParallax --
        /// Sets the parallax scroll factor for a layer. Values less than 1 scroll slower than the camera.
        /// @param | idx | integer | Layer index (1-based).
        /// @param | px | number | Horizontal parallax factor.
        /// @param | py | number | Vertical parallax factor.
        methods.add_method(
            "setLayerParallax",
            |_, this, (idx, px, py): (usize, f32, f32)| {
                this.inner.borrow_mut().set_layer_parallax(idx - 1, px, py);
                Ok(())
            },
        );
        // -- getLayerParallax --
        /// Returns the parallax scroll factor of a layer.
        /// @param | idx | integer | Layer index (1-based).
        /// @return | number | Horizontal parallax factor.
        /// @return | number | Vertical parallax factor.
        methods.add_method("getLayerParallax", |_, this, idx: usize| {
            let v = this.inner.borrow().get_layer_parallax(idx - 1);
            Ok((v.x, v.y))
        });
        // -- setTile --
        /// Sets the tile GID at a specific grid position on a layer.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @param | gid | integer | Global tile ID to place.
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
        /// Returns the tile GID at a specific grid position on a layer.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @return | integer | Global tile ID at that position.
        methods.add_method("getTile", |_, this, (layer, x, y): (usize, u32, u32)| {
            Ok(this.inner.borrow().get_tile(layer - 1, x - 1, y - 1))
        });
        // -- clearTile --
        /// Removes the tile at a specific grid position, setting it to empty (GID 0).
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @return | nil | No value is returned.
        methods.add_method("clearTile", |_, this, (layer, x, y): (usize, u32, u32)| {
            this.inner.borrow_mut().clear_tile(layer - 1, x - 1, y - 1);
            Ok(())
        });
        // -- fill --
        /// Fills every cell of a layer with the given GID.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | gid | integer | Global tile ID to fill with.
        /// @return | nil | No value is returned.
        methods.add_method("fill", |_, this, (layer, gid): (usize, u32)| {
            this.inner.borrow_mut().fill(layer - 1, gid);
            Ok(())
        });
        // -- tileTypeIndex --
        /// Builds an index mapping each GID present on a layer to an array of `{x, y}` positions.
        /// @param | layer | integer | Layer index (1-based).
        /// @return | table | Table keyed by GID, each value an array of `{x=number, y=number}`.
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
                    /// Performs the 'x' operation.
                    /// @return | nil | No value is returned.
                    pos.set("x", *x)?;
                    /// Performs the 'y' operation.
                    /// @return | nil | No value is returned.
                    pos.set("y", *y)?;
                    arr.set(i + 1, pos)?;
                }
                result.set(gid, arr)?;
            }
            Ok(result)
        });
        // -- findTilesByGid --
        /// Returns all positions on a layer that contain a specific GID.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | gid | integer | Global tile ID to search for.
        /// @return | table | Array of `{x=number, y=number}` positions.
        methods.add_method("findTilesByGid", |lua, this, (layer, gid): (usize, u32)| {
            if layer == 0 {
                return Err(mlua::Error::RuntimeError("layer must be >= 1".into()));
            }
            let positions = this.inner.borrow().find_tiles_by_gid(layer - 1, gid);
            let arr = lua.create_table()?;
            for (i, (x, y)) in positions.iter().enumerate() {
                let pos = lua.create_table()?;
                /// Performs the 'x' operation.
                /// @return | nil | No value is returned.
                pos.set("x", *x)?;
                /// Performs the 'y' operation.
                /// @return | nil | No value is returned.
                pos.set("y", *y)?;
                arr.set(i + 1, pos)?;
            }
            Ok(arr)
        });
        // -- setViewport --
        /// Sets the visible area of the map for culling during rendering.
        /// @param | x | number | Left edge in world pixels.
        /// @param | y | number | Top edge in world pixels.
        /// @param | w | number | Viewport width in pixels.
        /// @param | h | number | Viewport height in pixels.
        methods.add_method(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport(x, y, w, h);
                Ok(())
            },
        );
        // -- getViewport --
        /// Returns the current viewport rectangle, or nils if none is set.
        /// @return | number | Left edge.
        /// @return | number | Top edge.
        /// @return | number | Width.
        /// @return | number | Height.
        methods.add_method("getViewport", |_, this, ()| {
            match this.inner.borrow().get_viewport() {
                Some((x, y, w, h)) => Ok((Some(x), Some(y), Some(w), Some(h))),
                None => Ok((None, None, None, None)),
            }
        });
        // -- update --
        /// Advances tile animations by the given delta time.
        /// @param | dt | number | Time elapsed in seconds since last update.
        /// @return | nil | No value is returned.
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        // -- worldToTile --
        /// Converts world-space pixel coordinates to tile-grid coordinates.
        /// @param | wx | number | World X position in pixels.
        /// @param | wy | number | World Y position in pixels.
        /// @return | integer | Tile column (1-based).
        /// @return | integer | Tile row (1-based).
        methods.add_method("worldToTile", |_, this, (wx, wy): (f32, f32)| {
            let (tx, ty) = this.inner.borrow().world_to_tile(wx, wy);
            Ok((tx + 1, ty + 1))
        });
        // -- tileToWorld --
        /// Converts tile-grid coordinates to world-space pixel coordinates (top-left corner of the tile).
        /// @param | tx | integer | Tile column (1-based).
        /// @param | ty | integer | Tile row (1-based).
        /// @return | number | World X position in pixels.
        /// @return | number | World Y position in pixels.
        methods.add_method("tileToWorld", |_, this, (tx, ty): (u32, u32)| {
            let (wx, wy) = this.inner.borrow().tile_to_world(tx - 1, ty - 1);
            Ok((wx, wy))
        });
        // -- getTileWidth --
        /// Returns the width of a single tile in pixels for this map.
        /// @return | integer | Tile width in pixels.
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });
        // -- getTileHeight --
        /// Returns the height of a single tile in pixels for this map.
        /// @return | integer | Tile height in pixels.
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });
        // -- getTileDimensions --
        /// Returns both tile width and height in pixels.
        /// @return | integer | Tile width.
        /// @return | integer | Tile height.
        methods.add_method("getTileDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_tile_dimensions();
            Ok((w, h))
        });
        // -- getChunkSize --
        /// Returns the chunk size used for internal tile storage.
        /// @return | integer | Chunk size in tiles per side.
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });
        // -- isSolid --
        /// Checks whether the tile at a given position on a layer is solid.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @return | boolean | True if the tile at that position is marked solid.
        methods.add_method("isSolid", |_, this, (layer, x, y): (usize, u32, u32)| {
            Ok(this.inner.borrow().is_solid(layer - 1, x - 1, y - 1))
        });
        // -- applyAutoTile --
        /// Runs 4-bit auto-tiling on an entire layer, replacing tiles according to registered rules.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | typeName | string | Tile type name whose rules to apply.
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
        /// Runs 4-bit auto-tiling at a single tile position and updates it and its neighbors.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @param | typeName | string | Tile type name whose rules to apply.
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
        /// Runs 8-bit auto-tiling on an entire layer, considering diagonal neighbors.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | typeName | string | Tile type name whose rules to apply.
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
        /// Runs 8-bit auto-tiling at a single tile position and updates it and its neighbors.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @param | typeName | string | Tile type name whose rules to apply.
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
        /// Tests whether a world-space rectangle overlaps any solid tile on a layer.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | number | Rectangle left edge in world pixels.
        /// @param | y | number | Rectangle top edge in world pixels.
        /// @param | w | number | Rectangle width in pixels.
        /// @param | h | number | Rectangle height in pixels.
        /// @return | boolean | True if any solid tile is overlapped.
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
        /// Performs a swept AABB collision test against solid tiles on a layer, returning the contact point and normal.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | number | Rectangle left edge in world pixels.
        /// @param | y | number | Rectangle top edge in world pixels.
        /// @param | w | number | Rectangle width in pixels.
        /// @param | h | number | Rectangle height in pixels.
        /// @param | dx | number | Horizontal movement delta.
        /// @param | dy | number | Vertical movement delta.
        /// @return | number | Contact X position.
        /// @return | number | Contact Y position.
        /// @return | number | Normal X component.
        /// @return | number | Normal Y component.
        /// @return | number | Tile column hit (1-based, or 0 if no hit).
        /// @return | number | Tile row hit (1-based, or 0 if no hit).
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
        /// Returns the current map orientation as a string.
        /// @return | string | One of `"topdown"`, `"sideview"`, `"isometric"`, `"hexagonal"`.
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
        /// Sets the map orientation, affecting coordinate transforms and rendering.
        /// @param | orientation | string | One of `"topdown"`, `"sideview"`, `"isometric"`, `"hexagonal"`.
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
        /// Overrides the color tint for a single tile at a given position.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @param | r | number | Red channel (0..1).
        /// @param | g | number | Green channel (0..1).
        /// @param | b | number | Blue channel (0..1).
        /// @param | a | number | Alpha channel (0..1).
        methods.add_method(
            "setTileTint",
            |_, this, (layer, x, y, r, g, b, a): (usize, u32, u32, f32, f32, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .set_tile_tint(layer - 1, x - 1, y - 1, r, g, b, a);
                Ok(())
            },
        );
        // -- render --
        /// Submits render commands for all visible tiles, optionally offset by a scroll position.
        /// @param | ox? | number | Horizontal scroll offset (default 0).
        /// @param | oy? | number | Vertical scroll offset (default 0).
        /// @return | nil | No value is returned.
        methods.add_method("render", |_, this, (ox, oy): (Option<f32>, Option<f32>)| {
            let sx = ox.unwrap_or(0.0);
            let sy = oy.unwrap_or(0.0);
            let cmds = this.inner.borrow().build_render_commands(sx, sy);
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });
        // -- drawToImage --
        /// Rasterizes the map into an image using the given tile size, returning an image handle.
        /// @param | tileSize | integer | Pixel size of each tile in the output image.
        /// @return | LImage | Rasterized image of the map.
        methods.add_method("drawToImage", |_, this, tile_size: u32| {
            let img = this.inner.borrow().draw_to_image(tile_size);
            Ok(img)
        });
        // -- toNavGrid --
        /// Converts a layer into a 2D boolean grid for pathfinding. Tiles with GIDs in the given list are marked walkable.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | gids | table | Array of walkable GIDs.
        /// @return | table | 2D array of booleans (true = walkable).
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
        /// Registers a callback invoked when an entity enters a tile with the given GID.
        /// @param | gid | integer | Global tile ID to watch for.
        /// @param | func | function | Callback receiving `(wx, wy, tx, ty)`.
        methods.add_method_mut(
            "onTileEnter",
            |lua, this, (gid, func): (u32, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                this.tile_callbacks.borrow_mut().push((gid, key));
                Ok(())
            },
        );
        // -- checkEntities --
        /// Checks a list of entities against registered tile-enter callbacks on a layer.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | entities | table | Array of entity tables, each with `x`/`y` or `[1]`/`[2]` fields.
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
        // -- onTileStep --
        /// Registers a callback invoked each frame an entity remains on a tile with the given GID.
        /// @param | gid | integer | Global tile ID to watch for.
        /// @param | func | function | Callback receiving `(entity, tx, ty)`.
        methods.add_method_mut(
            "onTileStep",
            |lua, this, (gid, func): (u32, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                this.tile_step_callbacks.borrow_mut().insert(gid, key);
                Ok(())
            },
        );
        // -- onTileExit --
        /// Registers a callback invoked when an entity leaves a tile with the given GID.
        /// @param | gid | integer | Global tile ID to watch for.
        /// @param | func | function | Callback receiving `(entity, tx, ty)`.
        methods.add_method_mut(
            "onTileExit",
            |lua, this, (gid, func): (u32, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                this.tile_exit_callbacks.borrow_mut().insert(gid, key);
                Ok(())
            },
        );
        // -- fireTileStep --
        /// Manually fires the tile-step callback for a specific GID and entity at a tile position.
        /// @param | gid | integer | Global tile ID.
        /// @param | entity | table | Entity table to pass to the callback.
        /// @param | tx | integer | Tile column.
        /// @param | ty | integer | Tile row.
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
        /// Manually fires the tile-exit callback for a specific GID and entity at a tile position.
        /// @param | gid | integer | Global tile ID.
        /// @param | entity | table | Entity table to pass to the callback.
        /// @param | tx | integer | Tile column.
        /// @param | ty | integer | Tile row.
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
        /// Returns the type name of this userdata.
        /// @return | string | Always `"LTileMap"`.
        methods.add_method("type", |_, _, ()| Ok("LTileMap"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if `name` is `"LTileMap"` or `"Object"`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTileMap" || name == "Object")
        });
    }
}
/// Lua-side handle wrapping an `AutoTileSheet` that maps bitmasks to tile quads for auto-tiling.
#[derive(Clone)]
pub struct LuaAutoTileSheet {
    inner: Rc<RefCell<AutoTileSheet>>,
}
impl LuaUserData for LuaAutoTileSheet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getLayout --
        /// Returns the auto-tile layout type as a string.
        /// @return | string | One of `"blob47"`, `"composite48"`, `"minimal16"`.
        methods.add_method("getLayout", |_, this, ()| {
            let l = this.inner.borrow().get_layout();
            Ok(match l {
                AutoTileLayout::Blob47 => "blob47",
                AutoTileLayout::Composite48 => "composite48",
                AutoTileLayout::Minimal16 => "minimal16",
            })
        });
        // -- getTileCount --
        /// Returns the total number of tiles in this auto-tile sheet.
        /// @return | integer | Tile count.
        methods.add_method("getTileCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_count())
        });
        // -- getTileWidth --
        /// Returns the width of each tile in the auto-tile sheet, in pixels.
        /// @return | integer | Tile width.
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });
        // -- getTileHeight --
        /// Returns the height of each tile in the auto-tile sheet, in pixels.
        /// @return | integer | Tile height.
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });
        // -- applyToTileSet --
        /// Writes the auto-tile bitmask-to-tile rules from this sheet into a tileset.
        /// @param | tileSet | LTileSet | Target tileset to receive the rules.
        /// @param | typeName | string | Logical tile type name to register under.
        /// @param | startGid? | integer | Optional first GID offset.
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
        /// Returns the bitmask associated with a tile in this auto-tile sheet.
        /// @param | tileId | integer | Tile ID (1-based).
        /// @return | integer | Bitmask value, or nil if not found.
        methods.add_method("getBitmaskForTile", |_, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "getBitmaskForTile: tile_id must be >= 1".to_string(),
                ));
            }
            Ok(this.inner.borrow().get_bitmask_for_tile(tile_id - 1))
        });
        // -- getTileForBitmask --
        /// Looks up which tile corresponds to a given bitmask value.
        /// @param | bitmask | integer | Bitmask to resolve.
        /// @return | integer | Tile ID (1-based), or nil if no tile matches.
        methods.add_method("getTileForBitmask", |_, this, bitmask: u16| {
            Ok(this
                .inner
                .borrow()
                .get_tile_for_bitmask(bitmask)
                .map(|idx| idx + 1))
        });
        // -- getQuad --
        /// Returns the source rectangle for a tile in the auto-tile sheet.
        /// @param | tileId | integer | Tile ID (1-based).
        /// @return | integer | X offset in pixels.
        /// @return | integer | Y offset in pixels.
        /// @return | integer | Width in pixels.
        /// @return | integer | Height in pixels.
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
        /// Returns the type name of this userdata.
        /// @return | string | Always `"LAutoTileSheet"`.
        methods.add_method("type", |_, _, ()| Ok("LAutoTileSheet"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if `name` is `"LAutoTileSheet"` or `"Object"`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAutoTileSheet" || name == "Object")
        });
    }
}
/// Lua-side handle wrapping a `ChunkMap` for infinite or very large tile grids stored in dynamically loaded chunks.
#[derive(Clone)]
pub struct LuaChunkMap {
    inner: Rc<RefCell<ChunkMap>>,
}
impl LuaUserData for LuaChunkMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getTile --
        /// Returns the tile GID at the given world-tile coordinate.
        /// @param | x | integer | Tile X coordinate.
        /// @param | y | integer | Tile Y coordinate.
        /// @return | integer | Global tile ID.
        methods.add_method("getTile", |_, this, (x, y): (i32, i32)| {
            Ok(this.inner.borrow().get_tile(x, y))
        });
        // -- setTile --
        /// Sets the tile GID at the given world-tile coordinate.
        /// @param | x | integer | Tile X coordinate.
        /// @param | y | integer | Tile Y coordinate.
        /// @param | gid | integer | Global tile ID to place.
        /// @return | nil | No value is returned.
        methods.add_method("setTile", |_, this, (x, y, gid): (i32, i32, u32)| {
            this.inner.borrow_mut().set_tile(x, y, gid);
            Ok(())
        });
        // -- clearTile --
        /// Removes the tile at the given world-tile coordinate.
        /// @param | x | integer | Tile X coordinate.
        /// @param | y | integer | Tile Y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method("clearTile", |_, this, (x, y): (i32, i32)| {
            this.inner.borrow_mut().clear_tile(x, y);
            Ok(())
        });
        // -- fillRect --
        /// Fills a rectangular region of tiles with a given GID.
        /// @param | x0 | integer | Left tile coordinate.
        /// @param | y0 | integer | Top tile coordinate.
        /// @param | x1 | integer | Right tile coordinate (inclusive).
        /// @param | y1 | integer | Bottom tile coordinate (inclusive).
        /// @param | gid | integer | Global tile ID to fill with.
        methods.add_method(
            "fillRect",
            |_, this, (x0, y0, x1, y1, gid): (i32, i32, i32, i32, u32)| {
                this.inner.borrow_mut().fill_rect(x0, y0, x1, y1, gid);
                Ok(())
            },
        );
        // -- loadChunk --
        /// Loads a chunk into memory at the given chunk coordinates.
        /// @param | cx | integer | Chunk X coordinate.
        /// @param | cy | integer | Chunk Y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method("loadChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().load_chunk(cx, cy);
            Ok(())
        });
        // -- unloadChunk --
        /// Unloads a chunk from memory at the given chunk coordinates.
        /// @param | cx | integer | Chunk X coordinate.
        /// @param | cy | integer | Chunk Y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method("unloadChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().unload_chunk(cx, cy);
            Ok(())
        });
        // -- getChunkSize --
        /// Returns the size of each chunk in tiles per side.
        /// @return | integer | Chunk size.
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });
        // -- getLoadedChunks --
        /// Returns a list of all currently loaded chunk coordinates.
        /// @return | table | Array of `{cx, cy}` pairs.
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
        /// Returns chunk coordinates that overlap a viewport region, given tile dimensions.
        /// @param | vx | number | Viewport left edge in world pixels.
        /// @param | vy | number | Viewport top edge in world pixels.
        /// @param | vw | number | Viewport width in pixels.
        /// @param | vh | number | Viewport height in pixels.
        /// @param | tw | number | Tile width in pixels.
        /// @param | th | number | Tile height in pixels.
        /// @return | table | Array of `{cx, cy}` pairs.
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
        /// Returns the tile-coordinate range covered by a specific chunk.
        /// @param | cx | integer | Chunk X coordinate.
        /// @param | cy | integer | Chunk Y coordinate.
        /// @return | integer | Minimum tile X.
        /// @return | integer | Minimum tile Y.
        /// @return | integer | Maximum tile X.
        /// @return | integer | Maximum tile Y.
        methods.add_method("chunkTileRange", |_, this, (cx, cy): (i32, i32)| {
            let (x0, y0, x1, y1) = this.inner.borrow().chunk_tile_range(cx, cy);
            Ok((x0, y0, x1, y1))
        });
        // -- type --
        /// Returns the type name of this userdata.
        /// @return | string | Always `"LChunkMap"`.
        methods.add_method("type", |_, _, ()| Ok("LChunkMap"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if `name` is `"LChunkMap"` or `"Object"`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LChunkMap" || name == "Object")
        });
    }
}
/// Lua-side handle wrapping a `LargeMapRenderer` for chunk-based rendering of very large tile maps with LOD support.
#[derive(Clone)]
pub struct LuaLargeMapRenderer {
    inner: Rc<RefCell<LargeMapRenderer>>,
}
impl LuaUserData for LuaLargeMapRenderer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setMapData --
        /// Replaces all tile data with a flat array of GIDs for the given dimensions.
        /// @param | data | table | Flat array of tile GIDs (row-major order).
        /// @param | width | integer | Map width in tiles.
        /// @param | height | integer | Map height in tiles.
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
        /// Sets a single tile GID at a given position.
        /// @param | x | integer | Column.
        /// @param | y | integer | Row.
        /// @param | tileId | integer | Tile GID to place.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTile", |_, this, (x, y, tile_id): (u32, u32, u32)| {
            this.inner.borrow_mut().set_tile(x, y, tile_id);
            Ok(())
        });
        // -- getTile --
        /// Returns the tile GID at a given position.
        /// @param | x | integer | Column.
        /// @param | y | integer | Row.
        /// @return | integer | Tile GID.
        methods.add_method("getTile", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_tile(x, y))
        });
        // -- getMapSize --
        /// Returns the map dimensions in tiles.
        /// @return | integer | Width in tiles.
        /// @return | integer | Height in tiles.
        methods.add_method("getMapSize", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_map_size();
            Ok((w, h))
        });
        // -- setChunkSize --
        /// Sets the chunk size used for rendering subdivision.
        /// @param | size | integer | Chunk size in tiles per side.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setChunkSize", |_, this, size: u32| {
            this.inner.borrow_mut().set_chunk_size(size);
            Ok(())
        });
        // -- getChunkSize --
        /// Returns the current chunk size. This method is available to Lua scripts.
        /// @return | integer | Chunk size in tiles per side.
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });
        // -- invalidateChunk --
        /// Marks a specific chunk as dirty so it will be rebuilt on the next render.
        /// @param | cx | integer | Chunk X index.
        /// @param | cy | integer | Chunk Y index.
        /// @return | nil | No value is returned.
        methods.add_method_mut("invalidateChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().invalidate_chunk(cx, cy);
            Ok(())
        });
        // -- invalidateAll --
        /// Marks all chunks as dirty, forcing a full rebuild on the next render.
        /// @return | nil | No value is returned.
        methods.add_method_mut("invalidateAll", |_, this, ()| {
            this.inner.borrow_mut().invalidate_all();
            Ok(())
        });
        // -- getVisibleChunks --
        /// Returns the number of chunks currently visible in the viewport.
        /// @return | integer | Visible chunk count.
        methods.add_method("getVisibleChunks", |_, this, ()| {
            Ok(this.inner.borrow().get_visible_chunks())
        });
        // -- getTotalChunks --
        /// Returns the total number of chunks in the map.
        /// @return | integer | Total chunk count.
        methods.add_method("getTotalChunks", |_, this, ()| {
            Ok(this.inner.borrow().get_total_chunks())
        });
        // -- setCamera --
        /// Sets the camera position and zoom level for determining visible chunks.
        /// @param | x | number | Camera center X in world pixels.
        /// @param | y | number | Camera center Y in world pixels.
        /// @param | zoom | number | Zoom factor (1.0 = normal).
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCamera", |_, this, (x, y, zoom): (f32, f32, f32)| {
            this.inner.borrow_mut().set_camera(x, y, zoom);
            Ok(())
        });
        // -- setViewport --
        /// Sets the viewport dimensions for visibility calculations.
        /// @param | w | number | Viewport width in pixels.
        /// @param | h | number | Viewport height in pixels.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setViewport", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_viewport(w, h);
            Ok(())
        });
        // -- setLodEnabled --
        /// Enables or disables level-of-detail rendering for distant chunks.
        /// @param | enabled | boolean | True to enable LOD.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLodEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_lod_enabled(enabled);
            Ok(())
        });
        // -- isLodEnabled --
        /// Returns whether LOD rendering is currently enabled.
        /// @return | boolean | True if LOD is enabled.
        methods.add_method("isLodEnabled", |_, this, ()| {
            Ok(this.inner.borrow().is_lod_enabled())
        });
        // -- setLodThresholds --
        /// Sets the zoom thresholds at which LOD levels change.
        /// @param | levels | table | Array of zoom threshold values.
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
        /// Sets the column count of the associated tileset atlas for UV calculation.
        /// @param | cols | integer | Number of columns in the tileset image.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTilesetColumns", |_, this, cols: u32| {
            this.inner.borrow_mut().set_tileset_columns(cols);
            Ok(())
        });
        // -- getTilesetColumns --
        /// Returns the tileset column count used for UV calculation.
        /// @return | integer | Column count.
        methods.add_method("getTilesetColumns", |_, this, ()| {
            Ok(this.inner.borrow().get_tileset_columns())
        });
        // -- type --
        /// Returns the type name of this userdata.
        /// @return | string | Always `"LLargeMapRenderer"`.
        methods.add_method("type", |_, _, ()| Ok("LLargeMapRenderer"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if `name` is `"LLargeMapRenderer"` or `"Object"`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLargeMapRenderer" || name == "Object")
        });
    }
}
/// Lua-side handle wrapping an `IsoMap` for isometric tile rendering with multi-level support and configurable part ordering.
#[derive(Clone)]
pub struct LuaIsoMap {
    inner: Rc<RefCell<IsoMap>>,
}
impl LuaUserData for LuaIsoMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addLevel --
        /// Adds a new vertical level to the isometric map and returns its index.
        /// @return | integer | Index of the new level (1-based).
        methods.add_method("addLevel", |_, this, ()| {
            let idx = this.inner.borrow_mut().add_level();
            Ok(idx + 1)
        });
        // -- getLevelCount --
        /// Returns the number of vertical levels in the isometric map.
        /// @return | integer | Level count.
        methods.add_method("getLevelCount", |_, this, ()| {
            Ok(this.inner.borrow().get_level_count())
        });
        // -- setLevelVisible --
        /// Sets whether a vertical level is drawn during rendering.
        /// @param | z | integer | Level index (1-based).
        /// @param | visible | boolean | True to show, false to hide.
        /// @return | nil | No value is returned.
        methods.add_method("setLevelVisible", |_, this, (z, visible): (usize, bool)| {
            let z = one_based_usize("z", z)?;
            this.inner.borrow_mut().set_level_visible(z, visible);
            Ok(())
        });
        // -- isLevelVisible --
        /// Returns whether a vertical level is currently visible.
        /// @param | z | integer | Level index (1-based).
        /// @return | boolean | True if the level is visible.
        methods.add_method("isLevelVisible", |_, this, z: usize| {
            let z = one_based_usize("z", z)?;
            Ok(this.inner.borrow().get_level_visible(z))
        });
        // -- setTilePart --
        /// Sets the GID for a specific part of a tile at a given position and level.
        /// @param | z | integer | Level index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @param | part | integer | Part index (e.g. floor, wall, object).
        /// @param | gid | integer | Global tile ID to place.
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
        /// Returns the GID for a specific part of a tile at a given position and level.
        /// @param | z | integer | Level index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @param | part | integer | Part index.
        /// @return | integer | Global tile ID.
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
        /// Fills all tiles on a level for a given part with a single GID.
        /// @param | z | integer | Level index (1-based).
        /// @param | part | integer | Part index to fill.
        /// @param | gid | integer | Global tile ID to fill with.
        /// @return | nil | No value is returned.
        methods.add_method("fillLevel", |_, this, (z, part, gid): (usize, u32, u32)| {
            let z = one_based_usize("z", z)?;
            this.inner.borrow_mut().fill_level(z, part, gid);
            Ok(())
        });
        // -- setOrigin --
        /// Sets the screen-space origin (top-left anchor) for isometric rendering.
        /// @param | x | number | Origin X in pixels.
        /// @param | y | number | Origin Y in pixels.
        /// @return | nil | No value is returned.
        methods.add_method("setOrigin", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_origin(x, y);
            Ok(())
        });
        // -- getWidth --
        /// Returns the map width in tiles. This method is available to Lua scripts.
        /// @return | integer | Width.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));
        // -- getHeight --
        /// Returns the map height in tiles. This method is available to Lua scripts.
        /// @return | integer | Height.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));
        // -- getTileWidth --
        /// Returns the width of an isometric tile in pixels.
        /// @return | integer | Tile width.
        methods.add_method("getTileWidth", |_, this, ()| Ok(this.inner.borrow().tile_w));
        // -- getTileHeight --
        /// Returns the height of an isometric tile in pixels.
        /// @return | integer | Tile height.
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().tile_h)
        });
        // -- getLevelHeight --
        /// Returns the vertical pixel offset between levels.
        /// @return | integer | Level height in pixels.
        methods.add_method("getLevelHeight", |_, this, ()| {
            Ok(this.inner.borrow().level_height)
        });
        // -- tileToScreen --
        /// Converts tile-grid coordinates to screen-space pixel position.
        /// @param | tx | number | Tile X.
        /// @param | ty | number | Tile Y.
        /// @param | tz | number | Tile Z (level).
        /// @return | number | Screen X.
        /// @return | number | Screen Y.
        methods.add_method("tileToScreen", |_, this, (tx, ty, tz): (f32, f32, f32)| {
            let (sx, sy) = this.inner.borrow().tile_to_screen(tx, ty, tz);
            Ok((sx, sy))
        });
        // -- screenToTile --
        /// Converts screen-space pixel coordinates to tile-grid coordinates (ignoring Z).
        /// @param | sx | number | Screen X.
        /// @param | sy | number | Screen Y.
        /// @return | number | Tile X.
        /// @return | number | Tile Y.
        methods.add_method("screenToTile", |_, this, (sx, sy): (f32, f32)| {
            let (tx, ty) = this.inner.borrow().screen_to_tile(sx, sy);
            Ok((tx, ty))
        });
        // -- getPartCount --
        /// Returns the number of tile parts per cell.
        /// @return | integer | Part count.
        methods.add_method("getPartCount", |_, this, ()| {
            Ok(this.inner.borrow().get_part_count())
        });
        // -- getPartOrder --
        /// Returns the rendering order of tile parts as an array of part indices.
        /// @return | table | Array of part index values.
        methods.add_method("getPartOrder", |lua, this, ()| {
            let order = this.inner.borrow().get_part_order().to_vec();
            let tbl = lua.create_table()?;
            for (i, &idx) in order.iter().enumerate() {
                tbl.set(i + 1, idx)?;
            }
            Ok(tbl)
        });
        // -- setPartOrder --
        /// Overrides the rendering order of tile parts.
        /// @param | order | table | Array of part indices in desired draw order.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setPartOrder", |_, this, order: Vec<u32>| {
            this.inner
                .borrow_mut()
                .set_part_order(order)
                .map_err(LuaError::external)
        });
        // -- type --
        /// Returns the type name of this userdata.
        /// @return | string | Always `"LIsoMap"`.
        methods.add_method("type", |_, _, ()| Ok("LIsoMap"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if `name` is `"LIsoMap"` or `"Object"`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LIsoMap" || name == "Object")
        });
    }
}
/// Lua-side handle wrapping a `MapBlock` used for procedural map generation. A block is a tile grid with edge-matching sides.
#[derive(Clone)]
pub struct LuaMapBlock {
    inner: Rc<RefCell<MapBlock>>,
}
impl LuaUserData for LuaMapBlock {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setTile --
        /// Sets a tile GID at a position within the block.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @param | gid | integer | Global tile ID.
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
        /// Returns the tile GID at a position within the block.
        /// @param | layer | integer | Layer index (1-based).
        /// @param | x | integer | Column (1-based).
        /// @param | y | integer | Row (1-based).
        /// @return | integer | Global tile ID.
        methods.add_method("getTile", |_, this, (layer, x, y): (u32, u32, u32)| {
            Ok(this.inner.borrow().get_tile(layer - 1, x - 1, y - 1))
        });
        // -- setSide --
        /// Sets the side ID for an edge segment, used for edge matching in map generation.
        /// @param | edge | string | Edge direction: `"north"`, `"east"`, `"south"`, or `"west"`.
        /// @param | segment | integer | Segment index along the edge (1-based).
        /// @param | sideId | integer | Side identifier for matching.
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
        /// Returns the side ID for an edge segment.
        /// @param | edge | string | Edge direction: `"north"`, `"east"`, `"south"`, or `"west"`.
        /// @param | segment | integer | Segment index along the edge (1-based).
        /// @return | integer | Side identifier.
        methods.add_method("getSide", |_, this, (edge_str, segment): (String, u32)| {
            let edge = Edge::from_str(&edge_str)
                .ok_or_else(|| LuaError::external("invalid edge: use north/east/south/west"))?;
            Ok(this.inner.borrow().get_side(edge, segment - 1))
        });
        // -- getWidth --
        /// Returns the block width in tiles. This method is available to Lua scripts.
        /// @return | integer | Width.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });
        // -- getHeight --
        /// Returns the block height in tiles. This method is available to Lua scripts.
        /// @return | integer | Height.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });
        // -- getDimensions --
        /// Returns both width and height of the block in tiles.
        /// @return | integer | Width.
        /// @return | integer | Height.
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_dimensions();
            Ok((w, h))
        });
        // -- getLayerCount --
        /// Returns the number of tile layers in this block.
        /// @return | integer | Layer count.
        methods.add_method("getLayerCount", |_, this, ()| {
            Ok(this.inner.borrow().get_layer_count())
        });
        // -- getSegmentSize --
        /// Returns the segment size used for edge matching.
        /// @return | integer | Segment size in tiles.
        methods.add_method("getSegmentSize", |_, this, ()| {
            Ok(this.inner.borrow().get_segment_size())
        });
        // -- getWidthInSegments --
        /// Returns the block width measured in segments.
        /// @return | integer | Width in segments.
        methods.add_method("getWidthInSegments", |_, this, ()| {
            Ok(this.inner.borrow().get_width_in_segments())
        });
        // -- getHeightInSegments --
        /// Returns the block height measured in segments.
        /// @return | integer | Height in segments.
        methods.add_method("getHeightInSegments", |_, this, ()| {
            Ok(this.inner.borrow().get_height_in_segments())
        });
        // -- setName --
        /// Sets the block's name for identification during map generation.
        /// @param | name | string | Block name.
        /// @return | nil | No value is returned.
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().set_name(&name);
            Ok(())
        });
        // -- getName --
        /// Returns the block's name. This method is available to Lua scripts.
        /// @return | string | Block name.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });
        // -- setWeight --
        /// Sets the selection weight for this block during random placement.
        /// @param | weight | number | Relative weight (higher = more likely to be chosen).
        /// @return | nil | No value is returned.
        methods.add_method("setWeight", |_, this, weight: f32| {
            this.inner.borrow_mut().set_weight(weight);
            Ok(())
        });
        // -- getWeight --
        /// Returns the current selection weight.
        /// @return | number | Weight value.
        methods.add_method("getWeight", |_, this, ()| {
            Ok(this.inner.borrow().get_weight())
        });
        // -- type --
        /// Returns the type name of this userdata.
        /// @return | string | Always `"LMapBlock"`.
        methods.add_method("type", |_, _, ()| Ok("LMapBlock"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if `name` is `"LMapBlock"` or `"Object"`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapBlock" || name == "Object")
        });
    }
}
/// Lua-side handle wrapping a `MapGroup` that holds a collection of map blocks and generation scripts.
#[derive(Clone)]
pub struct LuaMapGroup {
    inner: Rc<RefCell<MapGroup>>,
}
impl LuaUserData for LuaMapGroup {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addBlock --
        /// Adds a map block to this group for use in generation.
        /// @param | block | LMapBlock | Block to add.
        /// @return | nil | No value is returned.
        methods.add_method("addBlock", |_, this, block_ud: LuaAnyUserData| {
            let block = block_ud.borrow::<LuaMapBlock>()?;
            this.inner
                .borrow_mut()
                .add_block(block.inner.borrow().clone());
            Ok(())
        });
        // -- getBlockCount --
        /// Returns how many blocks are in this group.
        /// @return | integer | Block count.
        methods.add_method("getBlockCount", |_, this, ()| {
            Ok(this.inner.borrow().get_block_count())
        });
        // -- removeBlock --
        /// Removes a block from the group by index.
        /// @param | idx | integer | Block index (1-based).
        /// @return | nil | No value is returned.
        methods.add_method("removeBlock", |_, this, idx: usize| {
            this.inner.borrow_mut().remove_block(idx - 1);
            Ok(())
        });
        // -- getName --
        /// Returns the group name. This method is available to Lua scripts.
        /// @return | string | Group name.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });
        // -- addScript --
        /// Attaches a map-generation script to this group.
        /// @param | script | LMapScript | Script to add.
        /// @return | nil | No value is returned.
        methods.add_method("addScript", |_, this, script_ud: LuaAnyUserData| {
            let script = script_ud.borrow::<LuaMapScript>()?;
            this.inner
                .borrow_mut()
                .add_script(script.inner.borrow().clone());
            Ok(())
        });
        // -- getScriptCount --
        /// Returns how many scripts are attached to this group.
        /// @return | integer | Script count.
        methods.add_method("getScriptCount", |_, this, ()| {
            Ok(this.inner.borrow().get_script_count())
        });
        // -- type --
        /// Returns the type name of this userdata.
        /// @return | string | Always `"LMapGroup"`.
        methods.add_method("type", |_, _, ()| Ok("LMapGroup"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if `name` is `"LMapGroup"` or `"Object"`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapGroup" || name == "Object")
        });
    }
}
/// Lua-side handle wrapping a `MapScript` that defines a sequence of procedural generation steps.
#[derive(Clone)]
pub struct LuaMapScript {
    inner: Rc<RefCell<MapScript>>,
}
impl LuaUserData for LuaMapScript {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getStepCount --
        /// Returns the number of generation steps in this script.
        /// @return | integer | Step count.
        methods.add_method("getStepCount", |_, this, ()| {
            Ok(this.inner.borrow().get_step_count())
        });
        // -- addStep --
        /// Appends a generation step. The step table must have a `type` field and optional parameters.
        /// @param | stepDef | table | Step definition with `type` and parameters like `x`, `y`, `w`, `h`, `gid`, `chance`, etc.
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
        /// Returns the type name of this userdata.
        /// @return | string | Always `"LMapScript"`.
        methods.add_method("type", |_, _, ()| Ok("LMapScript"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if `name` is `"LMapScript"` or `"Object"`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapScript" || name == "Object")
        });
    }
}
/// Lua-side handle wrapping a `MapGen` procedural map generator that assembles blocks into a tilemap.
#[derive(Clone)]
pub struct LuaMapGen {
    group: Rc<RefCell<MapGroup>>,
    inner: Rc<RefCell<crate::tilemap::mapgen::MapGen>>,
    state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaMapGen {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- generate --
        /// Runs the map generator, optionally using a specific script, seed, and layer name, returning a new tilemap.
        /// @param | scriptIdx? | integer | Script index in the group (1-based), or nil for default.
        /// @param | seed? | integer | Random seed, or nil for random.
        /// @param | layerName? | string | Output layer name (default `"main"`).
        /// @return | LTileMap | Generated tilemap.
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
        // -- type --
        /// Returns the type name of this userdata.
        /// @return | string | Always `"LMapGen"`.
        methods.add_method("type", |_, _, ()| Ok("LMapGen"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if `name` is `"LMapGen"` or `"Object"`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMapGen" || name == "Object")
        });
    }
}
/// Registers the `lurek.tilemap` module table and all factory functions.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newTileSet --
    /// Creates a new tileset from atlas parameters.
    /// @param | firstGid | integer | First global tile ID.
    /// @param | tileCount | integer | Total tiles in the set.
    /// @param | columns | integer | Columns in the atlas image.
    /// @param | tileWidth | integer | Tile width in pixels.
    /// @param | tileHeight | integer | Tile height in pixels.
    /// @param | spacing? | integer | Pixel spacing between tiles (default 0).
    /// @param | margin? | integer | Pixel margin around the atlas edge (default 0).
    /// @return | LTileSet | New tileset.
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
    // -- newTileMap --
    /// Creates a new empty tilemap with the given tile dimensions.
    /// @param | tileWidth | integer | Tile width in pixels.
    /// @param | tileHeight | integer | Tile height in pixels.
    /// @param | chunkSize? | integer | Internal chunk size in tiles (default 16).
    /// @return | LTileMap | New tilemap.
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
    // -- newAutoTileSheet --
    /// Creates an auto-tile sheet with a given tile size and layout.
    /// @param | tileW | integer | Tile width in pixels.
    /// @param | tileH | integer | Tile height in pixels.
    /// @param | layout | string | Layout type: `"blob47"`, `"composite48"`, or `"minimal16"`.
    /// @return | LAutoTileSheet | New auto-tile sheet.
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
    /// Creates a new infinite chunk-based tile map.
    /// @param | chunkSize? | integer | Tiles per chunk side (default 16).
    /// @return | LChunkMap | New chunk map.
    tbl.set(
        "newChunkMap",
        lua.create_function(|lua, chunk_size: Option<u32>| {
            lua.create_userdata(LuaChunkMap {
                inner: Rc::new(RefCell::new(ChunkMap::new(chunk_size.unwrap_or(16)))),
            })
        })?,
    )?;
    // -- newIsoMap --
    /// Creates a new isometric map with the given dimensions and tile geometry.
    /// @param | width | integer | Map width in tiles.
    /// @param | height | integer | Map height in tiles.
    /// @param | tileW | integer | Tile width in pixels.
    /// @param | tileH | integer | Tile height in pixels.
    /// @param | levelHeight | integer | Vertical pixel offset between levels.
    /// @param | partCount? | integer | Number of tile parts per cell (default 4).
    /// @return | LIsoMap | New isometric map.
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
    /// Creates a new procedural map block with the given dimensions.
    /// @param | width | integer | Block width in tiles.
    /// @param | height | integer | Block height in tiles.
    /// @param | layers? | integer | Number of tile layers (default 1).
    /// @param | segmentSize? | integer | Edge segment size in tiles (default 1).
    /// @return | LMapBlock | New map block.
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
    /// Creates a new map group to hold blocks and generation scripts.
    /// @param | name | string | Group name.
    /// @return | LMapGroup | New map group.
    tbl.set(
        "newMapGroup",
        lua.create_function(|lua, name: String| {
            lua.create_userdata(LuaMapGroup {
                inner: Rc::new(RefCell::new(MapGroup::new(&name))),
            })
        })?,
    )?;
    // -- toScreenIso --
    /// Converts tile coordinates to screen-space position for isometric projection.
    /// @param | tx | number | Tile X.
    /// @param | ty | number | Tile Y.
    /// @param | tw | number | Tile width in pixels.
    /// @param | th | number | Tile height in pixels.
    /// @return | number | Screen X.
    /// @return | number | Screen Y.
    tbl.set(
        "toScreenIso",
        lua.create_function(|_, (tx, ty, tw, th): (f32, f32, f32, f32)| {
            let v = coords::to_screen_iso(tx, ty, tw, th);
            Ok((v.x, v.y))
        })?,
    )?;
    // -- fromScreenIso --
    /// Converts screen-space coordinates back to tile coordinates for isometric projection.
    /// @param | sx | number | Screen X.
    /// @param | sy | number | Screen Y.
    /// @param | tw | number | Tile width in pixels.
    /// @param | th | number | Tile height in pixels.
    /// @return | number | Tile X.
    /// @return | number | Tile Y.
    tbl.set(
        "fromScreenIso",
        lua.create_function(|_, (sx, sy, tw, th): (f32, f32, f32, f32)| {
            let v = coords::from_screen_iso(sx, sy, tw, th);
            Ok((v.x, v.y))
        })?,
    )?;
    // -- toScreenHex --
    /// Converts axial hex coordinates to screen-space pixel position.
    /// @param | q | integer | Axial Q coordinate.
    /// @param | r | integer | Axial R coordinate.
    /// @param | size | number | Hex cell size in pixels.
    /// @return | number | Screen X.
    /// @return | number | Screen Y.
    tbl.set(
        "toScreenHex",
        lua.create_function(|_, (q, r, size): (i32, i32, f32)| {
            let v = coords::to_screen_hex(q, r, size);
            Ok((v.x, v.y))
        })?,
    )?;
    // -- fromScreenHex --
    /// Converts screen-space pixel coordinates to axial hex coordinates.
    /// @param | sx | number | Screen X.
    /// @param | sy | number | Screen Y.
    /// @param | size | number | Hex cell size in pixels.
    /// @return | integer | Axial Q.
    /// @return | integer | Axial R.
    tbl.set(
        "fromScreenHex",
        lua.create_function(|_, (sx, sy, size): (f32, f32, f32)| {
            let (q, r) = coords::from_screen_hex(sx, sy, size);
            Ok((q, r))
        })?,
    )?;
    // -- hexNeighbors --
    /// Returns the six neighboring hex cells of a given axial coordinate.
    /// @param | q | integer | Axial Q.
    /// @param | r | integer | Axial R.
    /// @return | table | Array of `{q=number, r=number}` neighbor cells.
    tbl.set(
        "hexNeighbors",
        lua.create_function(|lua, (q, r): (i32, i32)| {
            let n = coords::hex_neighbors(q, r);
            let tbl = lua.create_table()?;
            for (i, (nq, nr)) in n.iter().enumerate() {
                let entry = lua.create_table()?;
                /// Performs the 'q' operation.
                /// @return | nil | No value is returned.
                entry.set("q", *nq)?;
                /// Performs the 'r' operation.
                /// @return | nil | No value is returned.
                entry.set("r", *nr)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;
    // -- hexDistance --
    /// Computes the hex grid distance between two axial coordinates.
    /// @param | q1 | integer | First Q.
    /// @param | r1 | integer | First R.
    /// @param | q2 | integer | Second Q.
    /// @param | r2 | integer | Second R.
    /// @return | integer | Distance in hex steps.
    tbl.set(
        "hexDistance",
        lua.create_function(|_, (q1, r1, q2, r2): (i32, i32, i32, i32)| {
            Ok(coords::hex_distance(q1, r1, q2, r2))
        })?,
    )?;
    // -- hexRound --
    /// Rounds fractional axial hex coordinates to the nearest integer hex cell.
    /// @param | q | number | Fractional Q.
    /// @param | r | number | Fractional R.
    /// @return | integer | Rounded Q.
    /// @return | integer | Rounded R.
    tbl.set(
        "hexRound",
        lua.create_function(|_, (q, r): (f32, f32)| {
            let (rq, rr) = coords::hex_round(q, r);
            Ok((rq, rr))
        })?,
    )?;
    // -- hexLine --
    /// Returns all hex cells along a line between two axial coordinates.
    /// @param | q1 | integer | Start Q.
    /// @param | r1 | integer | Start R.
    /// @param | q2 | integer | End Q.
    /// @param | r2 | integer | End R.
    /// @return | table | Array of `{q, r}` pairs along the line.
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
    /// Returns all hex cells forming a ring at a given radius around a center.
    /// @param | q | integer | Center Q.
    /// @param | r | integer | Center R.
    /// @param | radius | integer | Ring radius in hex steps.
    /// @return | table | Array of `{q, r}` pairs on the ring.
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
    /// Returns all hex cells in a spiral pattern out to a given radius.
    /// @param | q | integer | Center Q.
    /// @param | r | integer | Center R.
    /// @param | radius | integer | Maximum radius.
    /// @return | table | Array of `{q, r}` pairs in spiral order.
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
    /// Returns all hex cells within a filled area of a given radius.
    /// @param | q | integer | Center Q.
    /// @param | r | integer | Center R.
    /// @param | radius | integer | Area radius.
    /// @return | table | Array of `{q, r}` pairs inside the area.
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
    /// Rotates a hex cell around a center point by a number of 60-degree steps.
    /// @param | q | integer | Cell Q.
    /// @param | r | integer | Cell R.
    /// @param | centerQ | integer | Pivot Q.
    /// @param | centerR | integer | Pivot R.
    /// @param | steps | integer | Number of 60-degree rotation steps (positive = clockwise).
    /// @return | integer | Rotated Q.
    /// @return | integer | Rotated R.
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
    /// Reflects a hex cell across an axis through a center point.
    /// @param | q | integer | Cell Q.
    /// @param | r | integer | Cell R.
    /// @param | centerQ | integer | Pivot Q.
    /// @param | centerR | integer | Pivot R.
    /// @param | axis | string | Reflection axis name.
    /// @return | integer | Reflected Q.
    /// @return | integer | Reflected R.
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
    /// Rotates an isometric direction index by a number of 90-degree steps.
    /// @param | direction | integer | Current direction (0..3).
    /// @param | steps | integer | Number of 90-degree steps.
    /// @return | integer | Rotated direction.
    tbl.set(
        "isoRotate",
        lua.create_function(|_, (direction, steps): (i32, i32)| {
            Ok(coords::iso_rotate(direction, steps))
        })?,
    )?;
    // -- isoDirectionName --
    /// Returns a human-readable name for an isometric direction index.
    /// @param | direction | integer | Direction index.
    /// @return | string | Direction name (e.g. `"north"`, `"east"`, `"south"`, `"west"`).
    tbl.set(
        "isoDirectionName",
        lua.create_function(|_, direction: i32| Ok(coords::iso_direction_name(direction)))?,
    )?;
    // -- isoDirectionFromAngle --
    /// Converts an angle in degrees to the nearest isometric direction index.
    /// @param | angle | number | Angle in degrees.
    /// @return | integer | Direction index.
    tbl.set(
        "isoDirectionFromAngle",
        lua.create_function(|_, angle: f32| Ok(coords::iso_direction_from_angle(angle)))?,
    )?;
    // -- newMapScript --
    /// Creates a new empty map-generation script.
    /// @return | LMapScript | New script.
    tbl.set(
        "newMapScript",
        lua.create_function(|_, ()| {
            Ok(LuaMapScript {
                inner: Rc::new(RefCell::new(MapScript::new("lua_script"))),
            })
        })?,
    )?;
    /// Floor layer index in a dual-layer tilemap cell (value 1).
    /// @return | nil | No value is returned.
    tbl.set("FLOOR", 1u32)?;
    /// North wall layer index in a tilemap cell (value 2).
    /// @return | nil | No value is returned.
    tbl.set("NORTH_WALL", 2u32)?;
    /// West wall layer index in a tilemap cell (value 3).
    /// @return | nil | No value is returned.
    tbl.set("WEST_WALL", 3u32)?;
    /// Object layer index in a tilemap cell (value 4).
    /// @return | nil | No value is returned.
    tbl.set("OBJECT", 4u32)?;
    let s3 = state.clone();
    // -- newMapGen --
    /// Creates a procedural map generator from a group and either a size preset or explicit dimensions.
    /// @param | group | LMapGroup | Block group to generate from.
    /// @param | presetOrWidth | string|integer | Size preset (`"small"`, `"medium"`, `"large"`) or width in tiles.
    /// @param | segmentSizeOrHeight | integer | Segment size (if preset) or height in tiles.
    /// @param | segmentSize? | integer | Segment size when using explicit dimensions.
    /// @return | LMapGen | New map generator.
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
    // -- loadTMX --
    /// Parses a TMX (Tiled XML) string and returns a table describing the map structure.
    /// @param | xml | string | Raw TMX XML content.
    /// @return | table | Parsed map with `width`, `height`, `tileWidth`, `tileHeight`, `orientation`, and `layers`.
    tbl.set(
        "loadTMX",
        lua.create_function(|lua, xml: String| {
            let tmx = crate::tilemap::tmx::load_tmx(&xml).map_err(LuaError::RuntimeError)?;
            let result = lua.create_table()?;
            /// Performs the 'width' operation.
            /// @return | nil | No value is returned.
            result.set("width", tmx.width)?;
            /// Performs the 'height' operation.
            /// @return | nil | No value is returned.
            result.set("height", tmx.height)?;
            /// Performs the 'tileWidth' operation.
            /// @return | nil | No value is returned.
            result.set("tileWidth", tmx.tile_width)?;
            /// Performs the 'tileHeight' operation.
            /// @return | nil | No value is returned.
            result.set("tileHeight", tmx.tile_height)?;
            let orient_str = match tmx.orientation {
                crate::tilemap::tmx::TmxOrientation::Orthogonal => "orthogonal",
                crate::tilemap::tmx::TmxOrientation::Isometric => "isometric",
                crate::tilemap::tmx::TmxOrientation::Staggered => "staggered",
                crate::tilemap::tmx::TmxOrientation::Hexagonal => "hexagonal",
            };
            /// Performs the 'orientation' operation.
            /// @return | nil | No value is returned.
            result.set("orientation", orient_str)?;
            let layers_tbl = lua.create_table()?;
            let mut layer_idx = 1usize;
            for layer in &tmx.layers {
                let entry = lua.create_table()?;
                match layer {
                    crate::tilemap::tmx::TmxLayer::Tile(t) => {
                        /// Performs the 'type' operation.
                        /// @return | nil | No value is returned.
                        entry.set("type", "tile")?;
                        /// Performs the 'name' operation.
                        /// @return | nil | No value is returned.
                        entry.set("name", t.name.as_str())?;
                        /// Performs the 'width' operation.
                        /// @return | nil | No value is returned.
                        entry.set("width", t.width)?;
                        /// Performs the 'height' operation.
                        /// @return | nil | No value is returned.
                        entry.set("height", t.height)?;
                    }
                    crate::tilemap::tmx::TmxLayer::Object(o) => {
                        /// Performs the 'type' operation.
                        /// @return | nil | No value is returned.
                        entry.set("type", "object")?;
                        /// Performs the 'name' operation.
                        /// @return | nil | No value is returned.
                        entry.set("name", o.name.as_str())?;
                    }
                }
                layers_tbl.set(layer_idx, entry)?;
                layer_idx += 1;
            }
            /// Performs the 'layers' operation.
            /// @return | nil | No value is returned.
            result.set("layers", layers_tbl)?;
            Ok(result)
        })?,
    )?;
    // -- fromLDtk --
    /// Loads a tilemap from an LDtk JSON string, optionally targeting a specific level.
    /// @param | jsonStr | string | Raw LDtk JSON content.
    /// @param | levelName? | string | Level name to load, or nil for the first level.
    /// @return | LTileMap | Loaded tilemap.
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
    /// Creates a chunk-based large-map renderer for efficient rendering of very large maps.
    /// @param | tileW | integer | Tile width in pixels.
    /// @param | tileH | integer | Tile height in pixels.
    /// @return | LLargeMapRenderer | New large-map renderer.
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
    /// Performs the 'tilemap' operation.
    /// @return | nil | No value is returned.
    lurek.set("tilemap", tbl)?;
    Ok(())
}
