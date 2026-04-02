//! Registers the `luna.tilemap.*` tilemap API.

//! Registers the `luna.tilemap.*` tile map, tileset, autotile, and procedural generation API.
//!
//! Exposes `LuaTileSet`, `LuaTileMap`, `LuaAutoTileSheet`, `LuaMapBlock`, `LuaMapGroup`,
//! `LuaMapScript`, and `LuaMapGen` UserData types wrapping the `crate::tilemap` module.
//!
//! All Lua-facing tile/layer/segment indices are **1-based**; Rust internals are 0-based.
#![allow(unused_doc_comments)]

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::tilemap::autotile_sheet::{AutoTileLayout, AutoTileSheet};
use crate::tilemap::chunk::ChunkMap;
use crate::tilemap::mapgen::{
    MapBlock, MapGen, MapGroup, MapScript, MapSize,
};
use crate::tilemap::tilemap::TileMap;
use crate::tilemap::tileset::TileSet;
use crate::tilemap::tmx::{load_tmx, TmxLayer};


mod helpers;
pub(super) mod ext;
#[allow(unused_imports)]
use helpers::*;
// Re-export for sibling modules (e.g. pathfinding_api) that use LuaTileMap.
pub(super) use helpers::LuaTileMap;

pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let tilemap_table = lua.create_table()?;

    // =======================================================================
    // Factory functions
    // =======================================================================

    /// luna.tilemap.newTileSet(firstGid, tileCount, columns, tileW, tileH, spacing, margin)
    tilemap_table.set(
        "newTileSet",
        lua.create_function(
            |_,
             (first_gid, tile_count, columns, tile_w, tile_h, spacing, margin): (
                u32,
                u32,
                u32,
                u32,
                u32,
                Option<u32>,
                Option<u32>,
            )| {
                Ok(LuaTileSet {
                    inner: Rc::new(RefCell::new(TileSet::new(
                        first_gid,
                        tile_count,
                        columns,
                        tile_w,
                        tile_h,
                        spacing.unwrap_or(0),
                        margin.unwrap_or(0),
                    ))),
                })
            },
        )?,
    )?;

    /// luna.tilemap.newTileMap(tileW, tileH, chunkSize)
    tilemap_table.set(
        "newTileMap",
        lua.create_function(|_, (tile_w, tile_h, chunk_size): (u32, u32, Option<u32>)| {
            Ok(LuaTileMap {
                inner: Rc::new(RefCell::new(TileMap::new(
                    tile_w,
                    tile_h,
                    chunk_size.unwrap_or(16),
                ))),
            })
        })?,
    )?;

    /// luna.tilemap.newAutoTileSheet(tileW, tileH, layout)
    tilemap_table.set(
        "newAutoTileSheet",
        lua.create_function(|_, (tile_w, tile_h, layout_str): (u32, u32, String)| {
            let layout = match layout_str.as_str() {
                "blob47" => AutoTileLayout::Blob47,
                "composite48" => AutoTileLayout::Composite48,
                "minimal16" => AutoTileLayout::Minimal16,
                _ => {
                    return Err(LuaError::RuntimeError(format!(
                        "invalid layout '{}': expected 'blob47', 'composite48', or 'minimal16'",
                        layout_str
                    )))
                }
            };
            Ok(LuaAutoTileSheet {
                inner: Rc::new(RefCell::new(AutoTileSheet::new(tile_w, tile_h, layout))),
            })
        })?,
    )?;

    /// luna.tilemap.newChunkMap(chunkSize) -> ChunkMap
    tilemap_table.set(
        "newChunkMap",
        lua.create_function(|_, chunk_size: Option<u32>| {
            Ok(LuaChunkMap {
                inner: Rc::new(RefCell::new(ChunkMap::new(chunk_size.unwrap_or(16)))),
            })
        })?,
    )?;

    /// luna.tilemap.loadTMX(xmlString) -> table with TmxMap fields, or nil+err
    tilemap_table.set(
        "loadTMX",
        lua.create_function(|lua, xml: String| {
            match load_tmx(&xml) {
                Err(e) => Err(LuaError::RuntimeError(e)),
                Ok(tmx) => {
                    let t = lua.create_table()?;
                    /// Width on this ChunkMap.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("width", tmx.width)?;
                    /// Height on this ChunkMap.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("height", tmx.height)?;
                    /// Tile width on this ChunkMap.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("tileWidth", tmx.tile_width)?;
                    /// Tile height on this ChunkMap.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("tileHeight", tmx.tile_height)?;
                    t.set(
                        "orientation",
                        match tmx.orientation {
                            crate::tilemap::tmx::TmxOrientation::Orthogonal => "orthogonal",
                            crate::tilemap::tmx::TmxOrientation::Isometric => "isometric",
                            crate::tilemap::tmx::TmxOrientation::Staggered => "staggered",
                            crate::tilemap::tmx::TmxOrientation::Hexagonal => "hexagonal",
                        },
                    )?;

                    // tilesets
                    let ts_table = lua.create_table()?;
                    for (i, ts) in tmx.tilesets.iter().enumerate() {
                        let entry = lua.create_table()?;
                        /// First gid on this ChunkMap.
                        ///
                        /// # Returns
                        /// The result.
                        entry.set("firstGid", ts.first_gid)?;
                        /// Name on this ChunkMap.
                        ///
                        /// # Returns
                        /// The result.
                        entry.set("name", ts.name.as_str())?;
                        /// Tile width on this ChunkMap.
                        ///
                        /// # Returns
                        /// The result.
                        entry.set("tileWidth", ts.tile_width)?;
                        /// Tile height on this ChunkMap.
                        ///
                        /// # Returns
                        /// The result.
                        entry.set("tileHeight", ts.tile_height)?;
                        /// Spacing on this ChunkMap.
                        ///
                        /// # Returns
                        /// The result.
                        entry.set("spacing", ts.spacing)?;
                        /// Margin on this ChunkMap.
                        ///
                        /// # Returns
                        /// The result.
                        entry.set("margin", ts.margin)?;
                        /// Tile count on this ChunkMap.
                        ///
                        /// # Returns
                        /// The result.
                        entry.set("tileCount", ts.tile_count)?;
                        /// Columns on this ChunkMap.
                        ///
                        /// # Returns
                        /// The result.
                        entry.set("columns", ts.columns)?;
                        /// Image source on this ChunkMap.
                        ///
                        /// # Returns
                        /// The result.
                        entry.set("imageSource", ts.image_source.as_deref().unwrap_or(""))?;
                        if let Some(ref source) = ts.source {
                            /// Source on this ChunkMap.
                            ///
                            /// # Returns
                            /// The result.
                            entry.set("source", source.as_str())?;
                        }
                        ts_table.set(i + 1, entry)?;
                    }
                    /// Tilesets on this ChunkMap.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("tilesets", ts_table)?;

                    // layers
                    let layers_table = lua.create_table()?;
                    for (i, layer) in tmx.layers.iter().enumerate() {
                        let entry = lua.create_table()?;
                        match layer {
                            TmxLayer::Tile(tl) => {
                                entry.set("type", "tile")?;
                                /// Name on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("name", tl.name.as_str())?;
                                /// Width on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("width", tl.width)?;
                                /// Height on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("height", tl.height)?;
                                /// Visible on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("visible", tl.visible)?;
                                /// Opacity on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("opacity", tl.opacity)?;
                                /// Offset x on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("offsetX", tl.offset_x)?;
                                /// Offset y on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("offsetY", tl.offset_y)?;
                                let tiles_t = lua.create_table()?;
                                for (ti, &gid) in tl.tiles.iter().enumerate() {
                                    tiles_t.set(ti + 1, gid)?;
                                }
                                /// Tiles on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("tiles", tiles_t)?;
                            }
                            TmxLayer::Object(ol) => {
                                entry.set("type", "object")?;
                                /// Name on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("name", ol.name.as_str())?;
                                /// Visible on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("visible", ol.visible)?;
                                let objs_t = lua.create_table()?;
                                for (oi, obj) in ol.objects.iter().enumerate() {
                                    let oe = lua.create_table()?;
                                    /// Id on this ChunkMap.
                                    ///
                                    /// # Returns
                                    /// The result.
                                    oe.set("id", obj.id)?;
                                    /// Name on this ChunkMap.
                                    ///
                                    /// # Returns
                                    /// The result.
                                    oe.set("name", obj.name.as_str())?;
                                    /// Obj_type on this ChunkMap.
                                    ///
                                    /// # Returns
                                    /// The result.
                                    oe.set("obj_type", obj.obj_type.as_str())?;
                                    /// X on this ChunkMap.
                                    ///
                                    /// # Returns
                                    /// The result.
                                    oe.set("x", obj.x)?;
                                    /// Y on this ChunkMap.
                                    ///
                                    /// # Returns
                                    /// The result.
                                    oe.set("y", obj.y)?;
                                    /// Width on this ChunkMap.
                                    ///
                                    /// # Returns
                                    /// The result.
                                    oe.set("width", obj.width)?;
                                    /// Height on this ChunkMap.
                                    ///
                                    /// # Returns
                                    /// The result.
                                    oe.set("height", obj.height)?;
                                    /// Gid on this ChunkMap.
                                    ///
                                    /// # Returns
                                    /// The result.
                                    oe.set("gid", obj.gid)?;
                                    objs_t.set(oi + 1, oe)?;
                                }
                                /// Objects on this ChunkMap.
                                ///
                                /// # Returns
                                /// The result.
                                entry.set("objects", objs_t)?;
                            }
                        }
                        layers_table.set(i + 1, entry)?;
                    }
                    /// Layers on this ChunkMap.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("layers", layers_table)?;

                    Ok(t)
                }
            }
        })?,
    )?;

    /// luna.tilemap.newMapBlock(width, height, layers, segmentSize)
    tilemap_table.set(
        "newMapBlock",
        lua.create_function(
            |_, (width, height, layers, segment_size): (u32, u32, u32, u32)| {
                Ok(LuaMapBlock {
                    inner: Rc::new(RefCell::new(MapBlock::new(
                        width,
                        height,
                        layers,
                        segment_size,
                    ))),
                })
            },
        )?,
    )?;

    /// Creates a named group layer for organizing child layers inside a tile map.
    ///
    /// # Parameters
    /// - `name` ÔÇö Display name for the group layer.
    ///
    /// # Returns
    /// New group layer object.
    tilemap_table.set(
        "newMapGroup",
        lua.create_function(|_, name: String| {
            Ok(LuaMapGroup {
                inner: Rc::new(RefCell::new(MapGroup::new(&name))),
            })
        })?,
    )?;

    /// Creates a script object attached to a tile map layer for custom logic.
    ///
    /// # Parameters
    /// - `name` ÔÇö Identifier name for the script component.
    ///
    /// # Returns
    /// New script component object.
    tilemap_table.set(
        "newMapScript",
        lua.create_function(|_, name: Option<String>| {
            Ok(LuaMapScript {
                inner: Rc::new(RefCell::new(MapScript::new(&name.unwrap_or_default()))),
            })
        })?,
    )?;

    /// luna.tilemap.newMapGen(group, sizeOrW, hOrSegSize, segSize)
    tilemap_table.set(
        "newMapGen",
        lua.create_function(
            |_,
             (group_ud, size_or_w, h_or_seg, seg_size): (
                LuaAnyUserData,
                LuaValue,
                LuaValue,
                Option<u32>,
            )| {
                let group = group_ud.borrow::<LuaMapGroup>()?;
                let (map_size, segment_size) = match &size_or_w {
                    LuaValue::String(s) => {
                        let size = match s.to_str()? {
                            "small" => MapSize::Small,
                            "medium" => MapSize::Medium,
                            "large" => MapSize::Large,
                            other => {
                                return Err(LuaError::RuntimeError(format!(
                                    "invalid size '{}': expected 'small', 'medium', or 'large'",
                                    other
                                )))
                            }
                        };
                        let ss = match &h_or_seg {
                            LuaValue::Integer(v) => *v as u32,
                            LuaValue::Number(v) => *v as u32,
                            _ => 4,
                        };
                        (size, ss)
                    }
                    LuaValue::Integer(w) => {
                        let h = match &h_or_seg {
                            LuaValue::Integer(v) => *v as u32,
                            LuaValue::Number(v) => *v as u32,
                            _ => {
                                return Err(LuaError::RuntimeError(
                                    "height parameter required when using numeric width".into(),
                                ))
                            }
                        };
                        (MapSize::Custom(*w as u32, h), seg_size.unwrap_or(4))
                    }
                    LuaValue::Number(w) => {
                        let h = match &h_or_seg {
                            LuaValue::Integer(v) => *v as u32,
                            LuaValue::Number(v) => *v as u32,
                            _ => {
                                return Err(LuaError::RuntimeError(
                                    "height parameter required when using numeric width".into(),
                                ))
                            }
                        };
                        (MapSize::Custom(*w as u32, h), seg_size.unwrap_or(4))
                    }
                    _ => {
                        return Err(LuaError::RuntimeError(
                            "first argument must be a size string or numeric width".into(),
                        ))
                    }
                };

                let group_rc = group.inner.clone();
                drop(group);
                Ok(LuaMapGen {
                    inner: Rc::new(RefCell::new(MapGen::new(map_size, segment_size))),
                    group: group_rc,
                })
            },
        )?,
    )?;


    ext::register_ext(lua, &tilemap_table)?;

    luna.set("tilemap", tilemap_table)?;
    Ok(())
}
