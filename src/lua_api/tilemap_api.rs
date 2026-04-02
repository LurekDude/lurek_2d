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

use crate::math::Rect;
use crate::tilemap::autotile_sheet::{AutoTileLayout, AutoTileSheet};
use crate::tilemap::chunk::ChunkMap;
use crate::tilemap::coords;
use crate::tilemap::isomap::IsoMap;
use crate::tilemap::mapgen::{
    Edge, LayerMode, MapBlock, MapGen, MapGroup, MapOrientation, MapScript, MapSize, ScriptStep,
    StepType,
};
use crate::tilemap::tilemap::TileMap;
use crate::tilemap::tileset::{TileAnimFrame, TileSet};
use crate::tilemap::tmx::{load_tmx, TmxLayer};

use super::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// Wrapper types
// ---------------------------------------------------------------------------

/// Lua wrapper around a [`TileSet`].
#[derive(Clone)]
struct LuaTileSet {
    inner: Rc<RefCell<TileSet>>,
}

/// Lua wrapper around a [`TileMap`].
///
/// # Fields
/// - `inner` — `Rc<RefCell<TileMap>>`.
#[derive(Clone)]
pub(super) struct LuaTileMap {
    pub(super) inner: Rc<RefCell<TileMap>>,
}

/// Lua wrapper around an [`AutoTileSheet`].
#[derive(Clone)]
struct LuaAutoTileSheet {
    inner: Rc<RefCell<AutoTileSheet>>,
}

/// Lua wrapper around a [`MapBlock`].
#[derive(Clone)]
struct LuaMapBlock {
    inner: Rc<RefCell<MapBlock>>,
}

/// Lua wrapper around a [`MapGroup`].
#[derive(Clone)]
struct LuaMapGroup {
    inner: Rc<RefCell<MapGroup>>,
}

/// Lua wrapper around a [`MapScript`].
#[derive(Clone)]
struct LuaMapScript {
    inner: Rc<RefCell<MapScript>>,
}

/// Lua wrapper around a [`MapGen`], storing the associated group for generation.
#[derive(Clone)]
struct LuaMapGen {
    inner: Rc<RefCell<MapGen>>,
    group: Rc<RefCell<MapGroup>>,
}

/// Lua wrapper around a [`ChunkMap`].
#[derive(Clone)]
struct LuaChunkMap {
    inner: Rc<RefCell<ChunkMap>>,
}

/// Lua wrapper around an [`IsoMap`].
#[derive(Clone)]
struct LuaIsoMap {
    inner: Rc<RefCell<IsoMap>>,
}

// ---------------------------------------------------------------------------
// LunaType impls
// ---------------------------------------------------------------------------

impl LunaType for LuaTileSet {
    const TYPE_NAME: &'static str = "TileSet";
    const TYPE_HIERARCHY: &'static [&'static str] = &["TileSet", "Object"];
}

impl LunaType for LuaTileMap {
    const TYPE_NAME: &'static str = "TileMap";
    const TYPE_HIERARCHY: &'static [&'static str] = &["TileMap", "Object"];
}

impl LunaType for LuaAutoTileSheet {
    const TYPE_NAME: &'static str = "AutoTileSheet";
    const TYPE_HIERARCHY: &'static [&'static str] = &["AutoTileSheet", "Object"];
}

impl LunaType for LuaMapBlock {
    const TYPE_NAME: &'static str = "MapBlock";
    const TYPE_HIERARCHY: &'static [&'static str] = &["MapBlock", "Object"];
}

impl LunaType for LuaMapGroup {
    const TYPE_NAME: &'static str = "MapGroup";
    const TYPE_HIERARCHY: &'static [&'static str] = &["MapGroup", "Object"];
}

impl LunaType for LuaMapScript {
    const TYPE_NAME: &'static str = "MapScript";
    const TYPE_HIERARCHY: &'static [&'static str] = &["MapScript", "Object"];
}

impl LunaType for LuaMapGen {
    const TYPE_NAME: &'static str = "MapGen";
    const TYPE_HIERARCHY: &'static [&'static str] = &["MapGen", "Object"];
}

impl LunaType for LuaChunkMap {
    const TYPE_NAME: &'static str = "ChunkMap";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ChunkMap", "Object"];
}

impl LunaType for LuaIsoMap {
    const TYPE_NAME: &'static str = "IsoMap";
    const TYPE_HIERARCHY: &'static [&'static str] = &["IsoMap", "Object"];
}

// ---------------------------------------------------------------------------
// Helper: Rect → Lua table
// ---------------------------------------------------------------------------

fn rect_to_table(lua: &Lua, r: Rect) -> LuaResult<LuaTable<'_>> {
    let t = lua.create_table()?;
    /// X on this IsoMap.
    ///
    /// # Returns
    /// The result.
    t.set("x", r.x)?;
    /// Y on this IsoMap.
    ///
    /// # Returns
    /// The result.
    t.set("y", r.y)?;
    /// Width on this IsoMap.
    ///
    /// # Returns
    /// The result.
    t.set("width", r.width)?;
    /// Height on this IsoMap.
    ///
    /// # Returns
    /// The result.
    t.set("height", r.height)?;
    Ok(t)
}

// ---------------------------------------------------------------------------
// Helper: parse Edge from string
// ---------------------------------------------------------------------------

fn parse_edge(s: &str) -> LuaResult<Edge> {
    Edge::from_str(s).ok_or_else(|| {
        LuaError::RuntimeError(format!(
            "invalid edge '{}': expected 'north', 'east', 'south', or 'west'",
            s
        ))
    })
}

// ---------------------------------------------------------------------------
// LuaTileSet UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaTileSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the global tile ID (GID) assigned to the first tile in this tileset.
        ///
        /// # Returns
        /// First GID as an integer.
        methods.add_method("getFirstGid", |_, this, ()| {
            Ok(this.inner.borrow().get_first_gid())
        });

        /// luna.tilemap.TileSet:getTileCount()
        methods.add_method("getTileCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_count())
        });

        /// Returns the number of tile columns in this tileset's source image.
        ///
        /// # Returns
        /// Column count as an integer.
        methods.add_method("getColumns", |_, this, ()| {
            Ok(this.inner.borrow().get_columns())
        });

        /// luna.tilemap.TileSet:getTileWidth()
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });

        /// luna.tilemap.TileSet:getTileHeight()
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });

        /// luna.tilemap.TileSet:getTileDimensions()
        methods.add_method("getTileDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_tile_dimensions();
            Ok((w, h))
        });

        /// Returns the pixel gap between adjacent tiles in the tileset source image.
        ///
        /// # Returns
        /// Spacing in pixels as an integer.
        methods.add_method("getSpacing", |_, this, ()| {
            Ok(this.inner.borrow().get_spacing())
        });

        /// Returns the pixel margin around the outside edge of the tileset image.
        ///
        /// # Returns
        /// Margin in pixels as an integer.
        methods.add_method("getMargin", |_, this, ()| {
            Ok(this.inner.borrow().get_margin())
        });

        /// luna.tilemap.TileSet:getQuad(tileId)
        methods.add_method("getQuad", |lua, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "tile ID must be >= 1 (1-based)".into(),
                ));
            }
            let r = this.inner.borrow().get_quad(tile_id - 1);
            rect_to_table(lua, r)
        });

        /// luna.tilemap.TileSet:setAnimation(tileId, frames)
        methods.add_method(
            "setAnimation",
            |_, this, (tile_id, frames_table): (u32, LuaTable)| {
                if tile_id == 0 {
                    return Err(LuaError::RuntimeError(
                        "tile ID must be >= 1 (1-based)".into(),
                    ));
                }
                let mut frames = Vec::new();
                for pair in frames_table.sequence_values::<LuaTable>() {
                    let t = pair?;
                    let tid: u32 = t.get("tileid")?;
                    if tid == 0 {
                        return Err(LuaError::RuntimeError(
                            "frame tileid must be >= 1 (1-based)".into(),
                        ));
                    }
                    let duration: f32 = t.get("duration")?;
                    frames.push(TileAnimFrame {
                        tile_id: tid - 1,
                        duration_ms: duration,
                    });
                }
                this.inner.borrow_mut().set_animation(tile_id - 1, frames);
                Ok(())
            },
        );

        /// luna.tilemap.TileSet:getAnimation(tileId)
        methods.add_method("getAnimation", |lua, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "tile ID must be >= 1 (1-based)".into(),
                ));
            }
            let inner = this.inner.borrow();
            match inner.get_animation(tile_id - 1) {
                Some(frames) => {
                    let t = lua.create_table()?;
                    for (i, f) in frames.iter().enumerate() {
                        let ft = lua.create_table()?;
                        /// Tileid on this TileSet.
                        ///
                        /// # Returns
                        /// The result.
                        ft.set("tileid", f.tile_id + 1)?;
                        /// Duration on this TileSet.
                        ///
                        /// # Returns
                        /// The result.
                        ft.set("duration", f.duration_ms)?;
                        t.set(i + 1, ft)?;
                    }
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        /// luna.tilemap.TileSet:setSolid(tileId, solid)
        methods.add_method("setSolid", |_, this, (tile_id, solid): (u32, bool)| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "tile ID must be >= 1 (1-based)".into(),
                ));
            }
            this.inner.borrow_mut().set_solid(tile_id - 1, solid);
            Ok(())
        });

        /// luna.tilemap.TileSet:isSolid(tileId)
        methods.add_method("isSolid", |_, this, tile_id: u32| {
            if tile_id == 0 {
                return Err(LuaError::RuntimeError(
                    "tile ID must be >= 1 (1-based)".into(),
                ));
            }
            Ok(this.inner.borrow().is_solid(tile_id - 1))
        });

        /// luna.tilemap.TileSet:setAutoTileRule(type, bitmask, tileId)
        methods.add_method(
            "setAutoTileRule",
            |_, this, (type_name, bitmask, tile_id): (String, u8, u32)| {
                if tile_id == 0 {
                    return Err(LuaError::RuntimeError(
                        "tile ID must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_auto_tile_rule(&type_name, bitmask, tile_id - 1);
                Ok(())
            },
        );

        /// luna.tilemap.TileSet:getAutoTileId(type, bitmask)
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

        /// luna.tilemap.TileSet:setAutoTileRule8(type, bitmask, tileId)
        methods.add_method(
            "setAutoTileRule8",
            |_, this, (type_name, bitmask, tile_id): (String, u16, u32)| {
                if tile_id == 0 {
                    return Err(LuaError::RuntimeError(
                        "tile ID must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_auto_tile_rule_8(&type_name, bitmask, tile_id - 1);
                Ok(())
            },
        );

        /// luna.tilemap.TileSet:getAutoTileId8(type, bitmask)
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

// ---------------------------------------------------------------------------
// LuaTileMap UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaTileMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- TileSet Management -----------------------------------------------

        /// luna.tilemap.TileMap:addTileSet(tileset)
        methods.add_method("addTileSet", |_, this, ts_ud: LuaAnyUserData| {
            let ts = ts_ud.borrow::<LuaTileSet>()?;
            let cloned = ts.inner.borrow().clone();
            this.inner.borrow_mut().add_tileset(cloned);
            Ok(())
        });

        /// luna.tilemap.TileMap:getTileSet(index)
        methods.add_method("getTileSet", |lua, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            let inner = this.inner.borrow();
            match inner.get_tileset(index - 1) {
                Some(ts) => {
                    let wrapped = LuaTileSet {
                        inner: Rc::new(RefCell::new(ts.clone())),
                    };
                    Ok(LuaValue::UserData(lua.create_userdata(wrapped)?))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        /// luna.tilemap.TileMap:getTileSetCount()
        methods.add_method("getTileSetCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tileset_count())
        });

        // -- Layer Management -------------------------------------------------

        /// luna.tilemap.TileMap:addLayer(name, width, height)
        methods.add_method(
            "addLayer",
            |_, this, (name, width, height): (String, u32, u32)| {
                let idx = this.inner.borrow_mut().add_layer(&name, width, height);
                Ok(idx + 1) // 1-based
            },
        );

        /// luna.tilemap.TileMap:getLayerCount()
        methods.add_method("getLayerCount", |_, this, ()| {
            Ok(this.inner.borrow().get_layer_count())
        });

        /// luna.tilemap.TileMap:getLayerName(layerIdx)
        methods.add_method("getLayerName", |_, this, idx: usize| {
            if idx == 0 {
                return Err(LuaError::RuntimeError(
                    "layer index must be >= 1 (1-based)".into(),
                ));
            }
            Ok(this
                .inner
                .borrow()
                .get_layer_name(idx - 1)
                .map(|s| s.to_string()))
        });

        /// luna.tilemap.TileMap:setLayerVisible(layerIdx, visible)
        methods.add_method(
            "setLayerVisible",
            |_, this, (idx, visible): (usize, bool)| {
                if idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer index must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner.borrow_mut().set_layer_visible(idx - 1, visible);
                Ok(())
            },
        );

        /// luna.tilemap.TileMap:getLayerVisible(layerIdx)
        methods.add_method("getLayerVisible", |_, this, idx: usize| {
            if idx == 0 {
                return Err(LuaError::RuntimeError(
                    "layer index must be >= 1 (1-based)".into(),
                ));
            }
            Ok(this.inner.borrow().get_layer_visible(idx - 1))
        });

        /// luna.tilemap.TileMap:setLayerColor(layerIdx, r, g, b, a)
        #[allow(clippy::too_many_arguments)]
        methods.add_method(
            "setLayerColor",
            |_, this, (idx, r, g, b, a): (usize, f32, f32, f32, Option<f32>)| {
                if idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer index must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_layer_color(idx - 1, r, g, b, a.unwrap_or(1.0));
                Ok(())
            },
        );

        /// luna.tilemap.TileMap:getLayerColor(layerIdx)
        methods.add_method("getLayerColor", |_, this, idx: usize| {
            if idx == 0 {
                return Err(LuaError::RuntimeError(
                    "layer index must be >= 1 (1-based)".into(),
                ));
            }
            let c = this.inner.borrow().get_layer_color(idx - 1);
            Ok((c[0], c[1], c[2], c[3]))
        });

        /// luna.tilemap.TileMap:setLayerOffset(layerIdx, ox, oy)
        methods.add_method(
            "setLayerOffset",
            |_, this, (idx, ox, oy): (usize, f32, f32)| {
                if idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer index must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner.borrow_mut().set_layer_offset(idx - 1, ox, oy);
                Ok(())
            },
        );

        /// luna.tilemap.TileMap:getLayerOffset(layerIdx)
        methods.add_method("getLayerOffset", |_, this, idx: usize| {
            if idx == 0 {
                return Err(LuaError::RuntimeError(
                    "layer index must be >= 1 (1-based)".into(),
                ));
            }
            let off = this.inner.borrow().get_layer_offset(idx - 1);
            Ok((off.x, off.y))
        });

        /// luna.tilemap.TileMap:setLayerParallax(layerIdx, px, py)
        methods.add_method(
            "setLayerParallax",
            |_, this, (idx, px, py): (usize, f32, f32)| {
                if idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer index must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner.borrow_mut().set_layer_parallax(idx - 1, px, py);
                Ok(())
            },
        );

        /// luna.tilemap.TileMap:getLayerParallax(layerIdx)
        methods.add_method("getLayerParallax", |_, this, idx: usize| {
            if idx == 0 {
                return Err(LuaError::RuntimeError(
                    "layer index must be >= 1 (1-based)".into(),
                ));
            }
            let p = this.inner.borrow().get_layer_parallax(idx - 1);
            Ok((p.x, p.y))
        });

        // -- Tile Access ------------------------------------------------------

        /// luna.tilemap.TileMap:setTile(layerIdx, x, y, gid)
        methods.add_method(
            "setTile",
            |_, this, (layer, x, y, gid): (usize, u32, u32, u32)| {
                if layer == 0 || x == 0 || y == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer, x, y must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_tile(layer - 1, x - 1, y - 1, gid);
                Ok(())
            },
        );

        /// luna.tilemap.TileMap:getTile(layerIdx, x, y)
        methods.add_method("getTile", |_, this, (layer, x, y): (usize, u32, u32)| {
            if layer == 0 || x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "layer, x, y must be >= 1 (1-based)".into(),
                ));
            }
            Ok(this.inner.borrow().get_tile(layer - 1, x - 1, y - 1))
        });

        /// luna.tilemap.TileMap:setTileTint(layerIdx, x, y, r, g, b, a)
        #[allow(clippy::too_many_arguments)]
        methods.add_method(
            "setTileTint",
            |_, this, (layer, x, y, r, g, b, a): (usize, u32, u32, f32, f32, f32, Option<f32>)| {
                if layer == 0 || x == 0 || y == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer, x, y must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner.borrow_mut().set_tile_tint(
                    layer - 1,
                    x - 1,
                    y - 1,
                    r,
                    g,
                    b,
                    a.unwrap_or(1.0),
                );
                Ok(())
            },
        );

        /// luna.tilemap.TileMap:clearTile(layerIdx, x, y)
        methods.add_method("clearTile", |_, this, (layer, x, y): (usize, u32, u32)| {
            if layer == 0 || x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "layer, x, y must be >= 1 (1-based)".into(),
                ));
            }
            this.inner.borrow_mut().clear_tile(layer - 1, x - 1, y - 1);
            Ok(())
        });

        /// luna.tilemap.TileMap:fill(layerIdx, gid)
        methods.add_method("fill", |_, this, (layer, gid): (usize, u32)| {
            if layer == 0 {
                return Err(LuaError::RuntimeError(
                    "layer index must be >= 1 (1-based)".into(),
                ));
            }
            this.inner.borrow_mut().fill(layer - 1, gid);
            Ok(())
        });

        // -- Viewport & Rendering ---------------------------------------------

        /// luna.tilemap.TileMap:setViewport(x, y, w, h)
        methods.add_method(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport(x, y, w, h);
                Ok(())
            },
        );

        /// Returns the visible tile range as x, y, width, height in tile coordinates.
        ///
        /// # Returns
        /// Viewport x, y, tileWidth, tileHeight.
        methods.add_method("getViewport", |_, this, ()| {
            match this.inner.borrow().get_viewport() {
                Some((x, y, w, h)) => Ok((Some(x), Some(y), Some(w), Some(h))),
                None => Ok((None, None, None, None)),
            }
        });

        /// Advances the map's animation timers and any attached script callbacks.
        ///
        /// # Parameters
        /// - `dt` — Delta time in seconds since the last update.
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        /// luna.tilemap.TileMap:drawLayer(layerIdx)
        methods.add_method("drawLayer", |_, this, idx: usize| {
            if idx == 0 {
                return Err(LuaError::RuntimeError(
                    "layer index must be >= 1 (1-based)".into(),
                ));
            }
            let inner = this.inner.borrow();
            if idx > inner.get_layer_count() {
                return Err(LuaError::RuntimeError(format!(
                    "layer index {} out of range (map has {} layers)",
                    idx,
                    inner.get_layer_count()
                )));
            }
            // No-op: rendering requires GPU integration
            Ok(())
        });

        // -- Coordinate Conversion --------------------------------------------

        /// luna.tilemap.TileMap:worldToTile(wx, wy)
        methods.add_method("worldToTile", |_, this, (wx, wy): (f32, f32)| {
            let (tx, ty) = this.inner.borrow().world_to_tile(wx, wy);
            Ok((tx + 1, ty + 1)) // 1-based
        });

        /// luna.tilemap.TileMap:tileToWorld(tx, ty)
        methods.add_method("tileToWorld", |_, this, (tx, ty): (u32, u32)| {
            if tx == 0 || ty == 0 {
                return Err(LuaError::RuntimeError(
                    "tile coords must be >= 1 (1-based)".into(),
                ));
            }
            let (wx, wy) = this.inner.borrow().tile_to_world(tx - 1, ty - 1);
            Ok((wx, wy))
        });

        // -- Dimension Getters ------------------------------------------------

        /// Returns the width of a single tile in pixels.
        ///
        /// # Returns
        /// `integer` — tile pixel width.
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });

        /// Returns the height of a single tile in pixels.
        ///
        /// # Returns
        /// `integer` — tile pixel height.
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });

        /// luna.tilemap.TileMap:getTileDimensions()
        methods.add_method("getTileDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_tile_dimensions();
            Ok((w, h))
        });

        /// luna.tilemap.TileMap:getChunkSize()
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });

        /// luna.tilemap.TileMap:getOrientation() -> "topdown"|"sideview"
        methods.add_method("getOrientation", |_, this, ()| {
            Ok(match this.inner.borrow().get_orientation() {
                crate::tilemap::mapgen::MapOrientation::TopDown => "topdown",
                crate::tilemap::mapgen::MapOrientation::SideView => "sideview",
            })
        });

        /// luna.tilemap.TileMap:setOrientation(mode)
        methods.add_method_mut("setOrientation", |_, this, mode: String| {
            let orientation = match mode.as_str() {
                "topdown" => crate::tilemap::mapgen::MapOrientation::TopDown,
                "sideview" => crate::tilemap::mapgen::MapOrientation::SideView,
                other => {
                    return Err(LuaError::RuntimeError(format!(
                        "invalid orientation '{}': expected 'topdown' or 'sideview'",
                        other
                    )))
                }
            };
            this.inner.borrow_mut().set_orientation(orientation);
            Ok(())
        });

        // -- Collision --------------------------------------------------------

        /// luna.tilemap.TileMap:isSolid(layerIdx, tx, ty)
        methods.add_method("isSolid", |_, this, (layer, tx, ty): (usize, u32, u32)| {
            if layer == 0 || tx == 0 || ty == 0 {
                return Err(LuaError::RuntimeError(
                    "layer, tx, ty must be >= 1 (1-based)".into(),
                ));
            }
            Ok(this.inner.borrow().is_solid(layer - 1, tx - 1, ty - 1))
        });

        /// luna.tilemap.TileMap:rectOverlapsSolid(layerIdx, x, y, w, h)
        methods.add_method(
            "rectOverlapsSolid",
            |_, this, (layer, x, y, w, h): (usize, f32, f32, f32, f32)| {
                if layer == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer index must be >= 1 (1-based)".into(),
                    ));
                }
                let rect = Rect::new(x, y, w, h);
                Ok(this.inner.borrow().rect_overlaps_solid(layer - 1, rect))
            },
        );

        /// luna.tilemap.TileMap:sweepRect(layerIdx, x, y, w, h, dx, dy)
        #[allow(clippy::too_many_arguments)]
        methods.add_method(
            "sweepRect",
            |_, this, (layer, x, y, w, h, dx, dy): (usize, f32, f32, f32, f32, f32, f32)| {
                if layer == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer index must be >= 1 (1-based)".into(),
                    ));
                }
                let rect = Rect::new(x, y, w, h);
                match this.inner.borrow().sweep_rect(layer - 1, rect, dx, dy) {
                    Some(sr) => Ok((
                        sr.contact_point.x,
                        sr.contact_point.y,
                        sr.normal.x,
                        sr.normal.y,
                        Some(sr.tile_x + 1),
                        Some(sr.tile_y + 1),
                    )),
                    None => Ok((x + dx, y + dy, 0.0, 0.0, None, None)),
                }
            },
        );

        // -- Autotile ---------------------------------------------------------

        /// luna.tilemap.TileMap:applyAutoTile(layerIdx, type)
        methods.add_method(
            "applyAutoTile",
            |_, this, (layer, type_name): (usize, String)| {
                if layer == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer index must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .apply_autotile(layer - 1, &type_name);
                Ok(())
            },
        );

        /// luna.tilemap.TileMap:applyAutoTileAt(layerIdx, x, y, type)
        methods.add_method(
            "applyAutoTileAt",
            |_, this, (layer, x, y, type_name): (usize, u32, u32, String)| {
                if layer == 0 || x == 0 || y == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer, x, y must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .apply_autotile_at(layer - 1, x - 1, y - 1, &type_name);
                Ok(())
            },
        );

        /// luna.tilemap.TileMap:applyAutoTile8(layerIdx, type)
        methods.add_method(
            "applyAutoTile8",
            |_, this, (layer, type_name): (usize, String)| {
                if layer == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer index must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .apply_autotile_8(layer - 1, &type_name);
                Ok(())
            },
        );

        /// luna.tilemap.TileMap:applyAutoTile8At(layerIdx, x, y, type)
        methods.add_method(
            "applyAutoTile8At",
            |_, this, (layer, x, y, type_name): (usize, u32, u32, String)| {
                if layer == 0 || x == 0 || y == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer, x, y must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .apply_autotile_8_at(layer - 1, x - 1, y - 1, &type_name);
                Ok(())
            },
        );
    }
}

// ---------------------------------------------------------------------------
// LuaAutoTileSheet UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaAutoTileSheet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// luna.tilemap.AutoTileSheet:getLayout()
        methods.add_method("getLayout", |_, this, ()| {
            let layout = this.inner.borrow().get_layout();
            Ok(match layout {
                AutoTileLayout::Blob47 => "blob47",
                AutoTileLayout::Composite48 => "composite48",
                AutoTileLayout::Minimal16 => "minimal16",
            })
        });

        /// luna.tilemap.AutoTileSheet:getTileCount()
        methods.add_method("getTileCount", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_count())
        });

        /// luna.tilemap.AutoTileSheet:getTileWidth()
        methods.add_method("getTileWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_width())
        });

        /// luna.tilemap.AutoTileSheet:getTileHeight()
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_height())
        });

        /// luna.tilemap.AutoTileSheet:applyToTileSet(tileset, type, startGid)
        methods.add_method(
            "applyToTileSet",
            |_, this, (ts_ud, type_name, start_gid): (LuaAnyUserData, String, Option<u32>)| {
                let ts = ts_ud.borrow::<LuaTileSet>()?;
                let inner = this.inner.borrow();
                let mut ts_inner = ts.inner.borrow_mut();
                inner.apply_to_tileset(&mut ts_inner, &type_name, start_gid);
                Ok(())
            },
        );

        /// luna.tilemap.AutoTileSheet:getBitmaskForTile(index)
        methods.add_method("getBitmaskForTile", |_, this, index: u32| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            Ok(this.inner.borrow().get_bitmask_for_tile(index - 1))
        });

        /// luna.tilemap.AutoTileSheet:getTileForBitmask(bitmask)
        methods.add_method("getTileForBitmask", |_, this, bitmask: u16| {
            Ok(this
                .inner
                .borrow()
                .get_tile_for_bitmask(bitmask)
                .map(|id| id + 1))
        });

        /// luna.tilemap.AutoTileSheet:getQuad(index)
        methods.add_method("getQuad", |lua, this, index: u32| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            let r = this.inner.borrow().get_quad(index - 1);
            rect_to_table(lua, r)
        });

        /// luna.tilemap.AutoTileSheet:getGridQuad(index, cols) -> {x,y,width,height}
        methods.add_method("getGridQuad", |lua, this, (index, cols): (u32, u32)| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            let r = this.inner.borrow().get_grid_quad(index - 1, cols);
            rect_to_table(lua, r)
        });

        /// luna.tilemap.AutoTileSheet:getComposite48GridQuad(index) -> {x,y,width,height}
        methods.add_method("getComposite48GridQuad", |lua, this, index: u32| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            let r = this.inner.borrow().get_composite48_grid_quad(index - 1);
            rect_to_table(lua, r)
        });

        /// luna.tilemap.AutoTileSheet:getQuarterRects(bitmask) -> {[1]={x,y,w,h},...[4]=...}
        methods.add_method("getQuarterRects", |lua, this, bitmask: u16| {
            let rects = this.inner.borrow().get_quarter_rects(bitmask);
            let t = lua.create_table()?;
            for (i, r) in rects.iter().enumerate() {
                t.set(i + 1, rect_to_table(lua, *r)?)?;
            }
            Ok(t)
        });

        /// luna.tilemap.AutoTileSheet:getQuarterDstRects(x, y) -> {[1],...[4]}
        methods.add_method("getQuarterDstRects", |lua, this, (x, y): (f32, f32)| {
            let rects = this.inner.borrow().get_quarter_dst_rects(x, y);
            let t = lua.create_table()?;
            for (i, r) in rects.iter().enumerate() {
                t.set(i + 1, rect_to_table(lua, *r)?)?;
            }
            Ok(t)
        });
    }
}

// ---------------------------------------------------------------------------
// LuaMapBlock UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaMapBlock {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// luna.tilemap.MapBlock:setTile(layer, x, y, gid)
        methods.add_method(
            "setTile",
            |_, this, (layer, x, y, gid): (u32, u32, u32, u32)| {
                if layer == 0 || x == 0 || y == 0 {
                    return Err(LuaError::RuntimeError(
                        "layer, x, y must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_tile(layer - 1, x - 1, y - 1, gid);
                Ok(())
            },
        );

        /// luna.tilemap.MapBlock:getTile(layer, x, y)
        methods.add_method("getTile", |_, this, (layer, x, y): (u32, u32, u32)| {
            if layer == 0 || x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "layer, x, y must be >= 1 (1-based)".into(),
                ));
            }
            Ok(this.inner.borrow().get_tile(layer - 1, x - 1, y - 1))
        });

        /// luna.tilemap.MapBlock:setSide(edge, segment, sideId)
        methods.add_method(
            "setSide",
            |_, this, (edge_str, segment, side_id): (String, u32, u32)| {
                let edge = parse_edge(&edge_str)?;
                if segment == 0 {
                    return Err(LuaError::RuntimeError(
                        "segment must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner.borrow_mut().set_side(edge, segment - 1, side_id);
                Ok(())
            },
        );

        /// luna.tilemap.MapBlock:getSide(edge, segment)
        methods.add_method("getSide", |_, this, (edge_str, segment): (String, u32)| {
            let edge = parse_edge(&edge_str)?;
            if segment == 0 {
                return Err(LuaError::RuntimeError(
                    "segment must be >= 1 (1-based)".into(),
                ));
            }
            Ok(this.inner.borrow().get_side(edge, segment - 1))
        });

        /// Returns the width of this map block section in tile coordinates.
        ///
        /// # Returns
        /// Width in tiles.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });

        /// Returns the height of this map block section in tile coordinates.
        ///
        /// # Returns
        /// Height in tiles.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });

        /// luna.tilemap.MapBlock:getDimensions()
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_dimensions();
            Ok((w, h))
        });

        /// luna.tilemap.MapBlock:getLayerCount()
        methods.add_method("getLayerCount", |_, this, ()| {
            Ok(this.inner.borrow().get_layer_count())
        });

        /// luna.tilemap.MapBlock:getSegmentSize()
        methods.add_method("getSegmentSize", |_, this, ()| {
            Ok(this.inner.borrow().get_segment_size())
        });

        /// luna.tilemap.MapBlock:getWidthInSegments()
        methods.add_method("getWidthInSegments", |_, this, ()| {
            Ok(this.inner.borrow().get_width_in_segments())
        });

        /// luna.tilemap.MapBlock:getHeightInSegments()
        methods.add_method("getHeightInSegments", |_, this, ()| {
            Ok(this.inner.borrow().get_height_in_segments())
        });

        /// luna.tilemap.MapBlock:getSegmentCount(edge)
        methods.add_method("getSegmentCount", |_, this, edge_str: String| {
            let edge = parse_edge(&edge_str)?;
            Ok(this.inner.borrow().get_segment_count(edge))
        });

        /// luna.tilemap.MapBlock:setName(name)
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().set_name(&name);
            Ok(())
        });

        /// Returns the name string assigned to this map block in the tile editor.
        ///
        /// # Returns
        /// Block name string.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });

        /// luna.tilemap.MapBlock:setWeight(weight)
        methods.add_method("setWeight", |_, this, weight: f32| {
            this.inner.borrow_mut().set_weight(weight);
            Ok(())
        });

        /// Returns the numeric weight used by procedural generators when placing this block.
        ///
        /// # Returns
        /// Weight as a number.
        methods.add_method("getWeight", |_, this, ()| {
            Ok(this.inner.borrow().get_weight())
        });
    }
}

// ---------------------------------------------------------------------------
// LuaMapGroup UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaMapGroup {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// luna.tilemap.MapGroup:addBlock(block)
        methods.add_method("addBlock", |_, this, block_ud: LuaAnyUserData| {
            let block = block_ud.borrow::<LuaMapBlock>()?;
            let cloned = block.inner.borrow().clone();
            this.inner.borrow_mut().add_block(cloned);
            Ok(())
        });

        /// luna.tilemap.MapGroup:getBlock(index)
        methods.add_method("getBlock", |lua, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            let inner = this.inner.borrow();
            match inner.get_block(index - 1) {
                Some(block) => {
                    let wrapped = LuaMapBlock {
                        inner: Rc::new(RefCell::new(block.clone())),
                    };
                    Ok(LuaValue::UserData(lua.create_userdata(wrapped)?))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        /// luna.tilemap.MapGroup:getBlockCount()
        methods.add_method("getBlockCount", |_, this, ()| {
            Ok(this.inner.borrow().get_block_count())
        });

        /// luna.tilemap.MapGroup:removeBlock(index)
        methods.add_method("removeBlock", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            this.inner.borrow_mut().remove_block(index - 1);
            Ok(())
        });

        /// luna.tilemap.MapGroup:addScript(script)
        methods.add_method("addScript", |_, this, script_ud: LuaAnyUserData| {
            let script = script_ud.borrow::<LuaMapScript>()?;
            let cloned = script.inner.borrow().clone();
            this.inner.borrow_mut().add_script(cloned);
            Ok(())
        });

        /// luna.tilemap.MapGroup:getScript(index)
        methods.add_method("getScript", |lua, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            let inner = this.inner.borrow();
            match inner.get_script(index - 1) {
                Some(script) => {
                    let wrapped = LuaMapScript {
                        inner: Rc::new(RefCell::new(script.clone())),
                    };
                    Ok(LuaValue::UserData(lua.create_userdata(wrapped)?))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        /// luna.tilemap.MapGroup:getScriptCount()
        methods.add_method("getScriptCount", |_, this, ()| {
            Ok(this.inner.borrow().get_script_count())
        });

        /// Returns the display name string of this map group layer.
        ///
        /// # Returns
        /// Group layer name string.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });

        /// luna.tilemap.MapGroup:setName(name)
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().set_name(&name);
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// LuaMapScript UserData — helpers
// ---------------------------------------------------------------------------

/// Parses a Lua table into a [`ScriptStep`].
fn parse_script_step(t: &LuaTable) -> LuaResult<ScriptStep> {
    let type_str: String = t.get::<_, Option<String>>("type")?.unwrap_or_default();
    let step_type = StepType::from_str(&type_str).unwrap_or(StepType::FillRandom);

    // Helper for 1-based → 0-based conversion on coordinate/index fields
    let lua_to_rust = |val: i32| -> u32 {
        if val >= 1 {
            (val - 1) as u32
        } else {
            0
        }
    };

    let x: i32 = t.get::<_, Option<i32>>("x")?.unwrap_or(1);
    let y: i32 = t.get::<_, Option<i32>>("y")?.unwrap_or(1);
    let tile_layer: i32 = t.get::<_, Option<i32>>("tileLayer")?.unwrap_or(1);
    let zone_start_y: i32 = t.get::<_, Option<i32>>("zoneStartY")?.unwrap_or(-1);
    let zone_end_y: i32 = t.get::<_, Option<i32>>("zoneEndY")?.unwrap_or(-1);
    let condition_step: i32 = t.get::<_, Option<i32>>("conditionStep")?.unwrap_or(-1);

    Ok(ScriptStep {
        step_type,
        group_index: t.get::<_, Option<i32>>("groupIndex")?.unwrap_or(-1),
        block_index: t.get::<_, Option<i32>>("blockIndex")?.unwrap_or(-1),
        x: lua_to_rust(x),
        y: lua_to_rust(y),
        width: t.get::<_, Option<u32>>("width")?.unwrap_or(0),
        height: t.get::<_, Option<u32>>("height")?.unwrap_or(0),
        count: t.get::<_, Option<u32>>("count")?.unwrap_or(1),
        rotation: t.get::<_, Option<u32>>("rotation")?.unwrap_or(0),
        mirror: t.get::<_, Option<bool>>("mirror")?.unwrap_or(false),
        random_rotation: t.get::<_, Option<bool>>("randomRotation")?.unwrap_or(false),
        random_mirror: t.get::<_, Option<bool>>("randomMirror")?.unwrap_or(false),
        direction: t.get::<_, Option<u32>>("direction")?.unwrap_or(0),
        match_sides: t.get::<_, Option<bool>>("matchSides")?.unwrap_or(true),
        condition_step: if condition_step >= 1 {
            condition_step - 1
        } else {
            -1
        },
        condition_success: t
            .get::<_, Option<bool>>("conditionSuccess")?
            .unwrap_or(true),
        chance: t.get::<_, Option<f32>>("chance")?.unwrap_or(1.0),
        repeat_count: t.get::<_, Option<u32>>("repeatCount")?.unwrap_or(1),
        min_count: t.get::<_, Option<i32>>("minCount")?.unwrap_or(-1),
        max_count: t.get::<_, Option<i32>>("maxCount")?.unwrap_or(-1),
        size_filter_w: t.get::<_, Option<i32>>("sizeFilterW")?.unwrap_or(-1),
        size_filter_h: t.get::<_, Option<i32>>("sizeFilterH")?.unwrap_or(-1),
        tile_id: t.get::<_, Option<u32>>("tileId")?.unwrap_or(1),
        path_width: t.get::<_, Option<u32>>("pathWidth")?.unwrap_or(1),
        tile_layer: lua_to_rust(tile_layer),
        zone_start_y: if zone_start_y >= 1 {
            zone_start_y - 1
        } else {
            -1
        },
        zone_end_y: if zone_end_y >= 1 { zone_end_y - 1 } else { -1 },
    })
}

/// Converts a [`ScriptStep`] back to a Lua table.
fn step_to_table<'lua>(lua: &'lua Lua, step: &ScriptStep) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    t.set("type", step.step_type.as_str())?;
    /// Group index on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("groupIndex", step.group_index)?;
    /// Block index on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("blockIndex", step.block_index)?;
    /// X on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("x", step.x + 1)?; // 0-based → 1-based
    /// Y on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("y", step.y + 1)?;
    /// Width on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("width", step.width)?;
    /// Height on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("height", step.height)?;
    /// Returns the number of items.
    ///
    /// # Returns
    /// `integer`.
    t.set("count", step.count)?;
    /// Rotation on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("rotation", step.rotation)?;
    /// Mirror on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("mirror", step.mirror)?;
    /// Random rotation on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("randomRotation", step.random_rotation)?;
    /// Random mirror on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("randomMirror", step.random_mirror)?;
    /// Direction on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("direction", step.direction)?;
    /// Match sides on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("matchSides", step.match_sides)?;
    t.set(
        "conditionStep",
        if step.condition_step >= 0 {
            step.condition_step + 1
        } else {
            -1
        },
    )?;
    /// Condition success on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("conditionSuccess", step.condition_success)?;
    /// Chance on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("chance", step.chance)?;
    /// Repeat count on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("repeatCount", step.repeat_count)?;
    /// Min count on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("minCount", step.min_count)?;
    /// Max count on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("maxCount", step.max_count)?;
    /// Returns the number of filter w.
    ///
    /// # Returns
    /// `integer`.
    t.set("sizeFilterW", step.size_filter_w)?;
    /// Returns the number of filter h.
    ///
    /// # Returns
    /// `integer`.
    t.set("sizeFilterH", step.size_filter_h)?;
    /// Tile id on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("tileId", step.tile_id)?;
    /// Path width on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("pathWidth", step.path_width)?;
    /// Tile layer on this MapGroup.
    ///
    /// # Returns
    /// The result.
    t.set("tileLayer", step.tile_layer + 1)?; // 0-based → 1-based
    t.set(
        "zoneStartY",
        if step.zone_start_y >= 0 {
            step.zone_start_y + 1
        } else {
            -1
        },
    )?;
    t.set(
        "zoneEndY",
        if step.zone_end_y >= 0 {
            step.zone_end_y + 1
        } else {
            -1
        },
    )?;
    Ok(t)
}

// ---------------------------------------------------------------------------
// LuaMapScript UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaMapScript {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// luna.tilemap.MapScript:addStep(stepTable)
        methods.add_method("addStep", |_, this, step_table: LuaTable| {
            let step = parse_script_step(&step_table)?;
            this.inner.borrow_mut().add_step(step);
            Ok(())
        });

        /// luna.tilemap.MapScript:getStep(index)
        methods.add_method("getStep", |lua, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            let inner = this.inner.borrow();
            match inner.get_step(index - 1) {
                Some(step) => Ok(LuaValue::Table(step_to_table(lua, step)?)),
                None => Ok(LuaValue::Nil),
            }
        });

        /// luna.tilemap.MapScript:getStepCount()
        methods.add_method("getStepCount", |_, this, ()| {
            Ok(this.inner.borrow().get_step_count())
        });

        /// luna.tilemap.MapScript:removeStep(index)
        methods.add_method("removeStep", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            this.inner.borrow_mut().remove_step(index - 1);
            Ok(())
        });

        /// luna.tilemap.MapScript:clearSteps()
        methods.add_method("clearSteps", |_, this, ()| {
            this.inner.borrow_mut().clear_steps();
            Ok(())
        });

        /// luna.tilemap.MapScript:setName(name)
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().set_name(&name);
            Ok(())
        });

        /// Returns the identifier name assigned to this map script component.
        ///
        /// # Returns
        /// Script name string.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().get_name().to_string())
        });
    }
}

// ---------------------------------------------------------------------------
// LuaMapGen UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaMapGen {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// luna.tilemap.MapGen:generate(scriptIndex, seed)
        methods.add_method(
            "generate",
            |lua, this, (script_index, seed): (Option<usize>, Option<u64>)| {
                let si = script_index.map(|i| if i == 0 { 0 } else { i - 1 });
                let group = this.group.borrow();
                let mut gen = this.inner.borrow_mut();
                let tilemap = gen.generate(&group, si, seed);
                let wrapped = LuaTileMap {
                    inner: Rc::new(RefCell::new(tilemap)),
                };
                lua.create_userdata(wrapped)
            },
        );

        /// luna.tilemap.MapGen:generateWorld(columns, rows, scriptIndex, seed)
        methods.add_method(
            "generateWorld",
            |lua,
             this,
             (columns, rows, script_index, seed): (u32, u32, Option<usize>, Option<u64>)| {
                let si = script_index.map(|i| {
                    if i == 0 {
                        0
                    } else {
                        i - 1
                    }
                });
                let group = this.group.borrow();
                let mut gen = this.inner.borrow_mut();
                let tilemap = gen.generate_world(&group, columns, rows, si, seed);
                let wrapped = LuaTileMap {
                    inner: Rc::new(RefCell::new(tilemap)),
                };
                lua.create_userdata(wrapped)
            },
        );

        /// Returns the width of the generation grid in block-sized units.
        ///
        /// # Returns
        /// Grid width in block columns.
        methods.add_method("getGridWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_grid_width())
        });

        /// luna.tilemap.MapGen:getGridHeight()
        methods.add_method("getGridHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_grid_height())
        });

        /// luna.tilemap.MapGen:getGridDimensions()
        methods.add_method("getGridDimensions", |_, this, ()| {
            let (w, h) = this.inner.borrow().get_grid_dimensions();
            Ok((w, h))
        });

        /// luna.tilemap.MapGen:getSegmentSize()
        methods.add_method("getSegmentSize", |_, this, ()| {
            Ok(this.inner.borrow().get_segment_size())
        });

        /// luna.tilemap.MapGen:setTileSize(w, h)
        methods.add_method("setTileSize", |_, this, (w, h): (u32, u32)| {
            this.inner.borrow_mut().set_tile_size(w, h);
            Ok(())
        });

        /// luna.tilemap.MapGen:getTilePixelWidth()
        methods.add_method("getTilePixelWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_pixel_width())
        });

        /// luna.tilemap.MapGen:getTilePixelHeight()
        methods.add_method("getTilePixelHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_tile_pixel_height())
        });

        /// luna.tilemap.MapGen:getPlacementCount()
        methods.add_method("getPlacementCount", |_, this, ()| {
            Ok(this.inner.borrow().get_placement_count())
        });

        /// luna.tilemap.MapGen:setOrientation(orientation)
        methods.add_method("setOrientation", |_, this, orientation: String| {
            let o = match orientation.as_str() {
                "topDown" => MapOrientation::TopDown,
                "sideView" => MapOrientation::SideView,
                _ => {
                    return Err(LuaError::RuntimeError(format!(
                        "invalid orientation '{}': expected 'topDown' or 'sideView'",
                        orientation
                    )))
                }
            };
            this.inner.borrow_mut().set_orientation(o);
            Ok(())
        });

        /// luna.tilemap.MapGen:getOrientation()
        methods.add_method("getOrientation", |_, this, ()| {
            Ok(match this.inner.borrow().get_orientation() {
                MapOrientation::TopDown => "topDown",
                MapOrientation::SideView => "sideView",
            })
        });

        /// luna.tilemap.MapGen:addZone(name, startRow, height)
        methods.add_method(
            "addZone",
            |_, this, (name, start_row, height): (String, u32, u32)| {
                if start_row == 0 {
                    return Err(LuaError::RuntimeError(
                        "startRow must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .add_zone(&name, start_row - 1, height);
                Ok(())
            },
        );

        /// Returns the total number of zone definitions registered in this generator.
        ///
        /// # Returns
        /// Zone count as an integer.
        methods.add_method("getZoneCount", |_, this, ()| {
            Ok(this.inner.borrow().get_zone_count())
        });

        /// Returns the zone definition table at the given 1-based index.
        ///
        /// # Parameters
        /// - `index` — 1-based index into the zone list.
        ///
        /// # Returns
        /// Zone definition table.
        methods.add_method("getZone", |lua, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError(
                    "index must be >= 1 (1-based)".into(),
                ));
            }
            let inner = this.inner.borrow();
            match inner.get_zone(index - 1) {
                Some(zone) => {
                    let t = lua.create_table()?;
                    /// Name on this MapGen.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("name", zone.name.as_str())?;
                    /// Start row on this MapGen.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("startRow", zone.start_row + 1)?; // 0-based → 1-based
                    /// Height on this MapGen.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("height", zone.height)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        /// Removes all zone definitions from this map generator's zone list.
        methods.add_method("clearZones", |_, this, ()| {
            this.inner.borrow_mut().clear_zones();
            Ok(())
        });

        /// luna.tilemap.MapGen:setLayerMode(mode)
        methods.add_method("setLayerMode", |_, this, mode: String| {
            let m = match mode.as_str() {
                "unified" => LayerMode::Unified,
                "independent" => LayerMode::Independent,
                _ => {
                    return Err(LuaError::RuntimeError(format!(
                        "invalid layer mode '{}': expected 'unified' or 'independent'",
                        mode
                    )))
                }
            };
            this.inner.borrow_mut().set_layer_mode(m);
            Ok(())
        });

        /// Returns the layer stacking mode used by this generator.
        ///
        /// # Returns
        /// Layer mode string such as 'stack' or 'replace'.
        methods.add_method("getLayerMode", |_, this, ()| {
            Ok(match this.inner.borrow().get_layer_mode() {
                LayerMode::Unified => "unified",
                LayerMode::Independent => "independent",
            })
        });
    }
}

// ---------------------------------------------------------------------------
// LuaIsoMap UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaIsoMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- Level management ------------------------------------------------

        /// Adds an elevation level layer to the isometric map for multi-height rendering.
        ///
        /// # Parameters
        /// - `level` — Level definition table or level index integer.
        methods.add_method("addLevel", |_, this, ()| {
            let idx = this.inner.borrow_mut().add_level();
            Ok(idx + 1) // 1-based
        });

        /// luna.tilemap.IsoMap:getLevelCount()
        methods.add_method("getLevelCount", |_, this, ()| {
            Ok(this.inner.borrow().get_level_count())
        });

        /// luna.tilemap.IsoMap:setLevelVisible(levelIdx, visible)
        methods.add_method(
            "setLevelVisible",
            |_, this, (idx, visible): (usize, bool)| {
                if idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "level index must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner.borrow_mut().set_level_visible(idx - 1, visible);
                Ok(())
            },
        );

        /// luna.tilemap.IsoMap:isLevelVisible(levelIdx)
        methods.add_method("isLevelVisible", |_, this, idx: usize| {
            if idx == 0 {
                return Err(LuaError::RuntimeError(
                    "level index must be >= 1 (1-based)".into(),
                ));
            }
            Ok(this.inner.borrow().get_level_visible(idx - 1))
        });

        // -- Tile access ------------------------------------------------------

        /// luna.tilemap.IsoMap:setTilePart(levelIdx, x, y, part, gid)
        methods.add_method(
            "setTilePart",
            |_, this, (level, x, y, part, gid): (usize, u32, u32, u32, u32)| {
                if level == 0 || x == 0 || y == 0 || part == 0 {
                    return Err(LuaError::RuntimeError(
                        "level, x, y, part must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_tile_part(level - 1, x - 1, y - 1, part - 1, gid);
                Ok(())
            },
        );

        /// luna.tilemap.IsoMap:getTilePart(levelIdx, x, y, part)
        methods.add_method(
            "getTilePart",
            |_, this, (level, x, y, part): (usize, u32, u32, u32)| {
                if level == 0 || x == 0 || y == 0 || part == 0 {
                    return Err(LuaError::RuntimeError(
                        "level, x, y, part must be >= 1 (1-based)".into(),
                    ));
                }
                Ok(this
                    .inner
                    .borrow()
                    .get_tile_part(level - 1, x - 1, y - 1, part - 1))
            },
        );

        /// luna.tilemap.IsoMap:fillLevel(levelIdx, part, gid)
        methods.add_method(
            "fillLevel",
            |_, this, (level, part, gid): (usize, u32, u32)| {
                if level == 0 || part == 0 {
                    return Err(LuaError::RuntimeError(
                        "level and part must be >= 1 (1-based)".into(),
                    ));
                }
                this.inner.borrow_mut().fill_level(level - 1, part - 1, gid);
                Ok(())
            },
        );

        // -- Origin ----------------------------------------------------------

        /// luna.tilemap.IsoMap:setOrigin(x, y)
        methods.add_method("setOrigin", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_origin(x, y);
            Ok(())
        });

        // -- Dimension getters -----------------------------------------------

        /// Returns the width of the isometric map in tile columns.
        ///
        /// # Returns
        /// Map width in tile columns.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));

        /// Returns the height of the isometric map in tile rows.
        ///
        /// # Returns
        /// Map height in tile rows.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));

        /// Returns the width in pixels of a single isometric tile.
        ///
        /// # Returns
        /// Tile width in pixels.
        methods.add_method("getTileWidth", |_, this, ()| Ok(this.inner.borrow().tile_w));

        /// luna.tilemap.IsoMap:getTileHeight()
        methods.add_method("getTileHeight", |_, this, ()| {
            Ok(this.inner.borrow().tile_h)
        });

        /// luna.tilemap.IsoMap:getLevelHeight()
        methods.add_method("getLevelHeight", |_, this, ()| {
            Ok(this.inner.borrow().level_height)
        });

        // -- Coordinate conversion -------------------------------------------

        /// luna.tilemap.IsoMap:tileToScreen(tx, ty, tz)
        ///
        /// All parameters are 1-based; returns (screen_x, screen_y).
        methods.add_method("tileToScreen", |_, this, (tx, ty, tz): (f32, f32, f32)| {
            // tx/ty are 1-based tile coords; subtract 1 for 0-based Rust
            let (sx, sy) = this
                .inner
                .borrow()
                .tile_to_screen(tx - 1.0, ty - 1.0, tz - 1.0);
            Ok((sx, sy))
        });

        /// luna.tilemap.IsoMap:screenToTile(sx, sy)
        ///
        /// Returns (tx, ty) as 1-based floats.
        methods.add_method("screenToTile", |_, this, (sx, sy): (f32, f32)| {
            let (tx, ty) = this.inner.borrow().screen_to_tile(sx, sy);
            Ok((tx + 1.0, ty + 1.0)) // shift to 1-based
        });

        // -- Draw iteration --------------------------------------------------

        /// luna.tilemap.IsoMap:iterDrawOrder(activeLevel, callback)
        ///
        /// Iterates every draw item in painter's algorithm order, calling
        /// `callback(level, tx, ty, part, gid, sx, sy)` for each.
        /// All indices are 1-based; a GID of 0 means the slot is empty.
        methods.add_method(
            "iterDrawOrder",
            |_, this, (active_level, callback): (usize, LuaFunction)| {
                if active_level == 0 {
                    return Err(LuaError::RuntimeError(
                        "activeLevel must be >= 1 (1-based)".into(),
                    ));
                }
                let items = this.inner.borrow().draw_iter(active_level - 1);
                for item in items {
                    callback.call::<_, ()>((
                        item.level + 1,  // 1-based
                        item.tile_x + 1, // 1-based
                        item.tile_y + 1, // 1-based
                        item.part + 1,   // 1-based
                        item.gid,
                        item.screen_x,
                        item.screen_y,
                    ))?;
                }
                Ok(())
            },
        );
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

// Registers the `luna.tilemap` table with all factory functions and coordinate helpers.

// ---------------------------------------------------------------------------
// LuaChunkMap UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaChunkMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// luna.tilemap.ChunkMap:getTile(x, y) -- 0-based tile coords
        methods.add_method("getTile", |_, this, (x, y): (i32, i32)| {
            Ok(this.inner.borrow().get_tile(x, y))
        });

        /// luna.tilemap.ChunkMap:setTile(x, y, gid) -- 0-based tile coords
        methods.add_method("setTile", |_, this, (x, y, gid): (i32, i32, u32)| {
            this.inner.borrow_mut().set_tile(x, y, gid);
            Ok(())
        });

        /// luna.tilemap.ChunkMap:clearTile(x, y)
        methods.add_method("clearTile", |_, this, (x, y): (i32, i32)| {
            this.inner.borrow_mut().clear_tile(x, y);
            Ok(())
        });

        /// luna.tilemap.ChunkMap:fillRect(x0, y0, x1, y1, gid)
        methods.add_method(
            "fillRect",
            |_, this, (x0, y0, x1, y1, gid): (i32, i32, i32, i32, u32)| {
                this.inner.borrow_mut().fill_rect(x0, y0, x1, y1, gid);
                Ok(())
            },
        );

        /// luna.tilemap.ChunkMap:loadChunk(cx, cy)
        methods.add_method("loadChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().load_chunk(cx, cy);
            Ok(())
        });

        /// luna.tilemap.ChunkMap:unloadChunk(cx, cy)
        methods.add_method("unloadChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().unload_chunk(cx, cy);
            Ok(())
        });

        /// luna.tilemap.ChunkMap:getChunkSize()
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });

        /// luna.tilemap.ChunkMap:getLoadedChunks() -> [{cx,cy}, ...]
        methods.add_method("getLoadedChunks", |lua, this, ()| {
            let chunks = this.inner.borrow().get_loaded_chunks();
            let t = lua.create_table()?;
            for (i, (cx, cy)) in chunks.iter().enumerate() {
                let entry = lua.create_table()?;
                /// Cx on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                entry.set("cx", *cx)?;
                /// Cy on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                entry.set("cy", *cy)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });

        /// luna.tilemap.ChunkMap:getChunksInView(vx, vy, vw, vh, tileW, tileH) -> [{cx,cy},...]
        methods.add_method(
            "getChunksInView",
            |lua, this, (vx, vy, vw, vh, tw, th): (f32, f32, f32, f32, f32, f32)| {
                let chunks = this
                    .inner
                    .borrow()
                    .get_chunks_in_view(vx, vy, vw, vh, tw, th);
                let t = lua.create_table()?;
                for (i, (cx, cy)) in chunks.iter().enumerate() {
                    let entry = lua.create_table()?;
                    /// Cx on this ChunkMap.
                    ///
                    /// # Returns
                    /// The result.
                    entry.set("cx", *cx)?;
                    /// Cy on this ChunkMap.
                    ///
                    /// # Returns
                    /// The result.
                    entry.set("cy", *cy)?;
                    t.set(i + 1, entry)?;
                }
                Ok(t)
            },
        );

        /// luna.tilemap.ChunkMap:chunkTileRange(cx, cy) -> x0,y0,x1,y1
        methods.add_method("chunkTileRange", |_, this, (cx, cy): (i32, i32)| {
            let (x0, y0, x1, y1) = this.inner.borrow().chunk_tile_range(cx, cy);
            Ok((x0, y0, x1, y1))
        });
    }
}

/// register.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
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
    /// - `name` — Display name for the group layer.
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
    /// - `name` — Identifier name for the script component.
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

    // =======================================================================
    // Coordinate functions
    // =======================================================================

    /// luna.tilemap.toScreenIso(tx, ty, tileW, tileH)
    tilemap_table.set(
        "toScreenIso",
        lua.create_function(|_, (tx, ty, tile_w, tile_h): (f32, f32, f32, f32)| {
            let v = coords::to_screen_iso(tx, ty, tile_w, tile_h);
            Ok((v.x, v.y))
        })?,
    )?;

    /// luna.tilemap.fromScreenIso(sx, sy, tileW, tileH)
    tilemap_table.set(
        "fromScreenIso",
        lua.create_function(|_, (sx, sy, tile_w, tile_h): (f32, f32, f32, f32)| {
            let v = coords::from_screen_iso(sx, sy, tile_w, tile_h);
            Ok((v.x, v.y))
        })?,
    )?;

    /// luna.tilemap.isoRotate(direction, steps)
    tilemap_table.set(
        "isoRotate",
        lua.create_function(|_, (direction, steps): (i32, i32)| {
            Ok(coords::iso_rotate(direction, steps))
        })?,
    )?;

    /// luna.tilemap.isoDirectionName(direction)
    tilemap_table.set(
        "isoDirectionName",
        lua.create_function(|_, direction: i32| Ok(coords::iso_direction_name(direction)))?,
    )?;

    /// luna.tilemap.isoDirectionFromAngle(angle)
    tilemap_table.set(
        "isoDirectionFromAngle",
        lua.create_function(|_, angle: f32| Ok(coords::iso_direction_from_angle(angle)))?,
    )?;

    /// luna.tilemap.toScreenHex(q, r, size)
    tilemap_table.set(
        "toScreenHex",
        lua.create_function(|_, (q, r, size): (i32, i32, f32)| {
            let v = coords::to_screen_hex(q, r, size);
            Ok((v.x, v.y))
        })?,
    )?;

    /// luna.tilemap.fromScreenHex(sx, sy, size)
    tilemap_table.set(
        "fromScreenHex",
        lua.create_function(|_, (sx, sy, size): (f32, f32, f32)| {
            let (q, r) = coords::from_screen_hex(sx, sy, size);
            Ok((q, r))
        })?,
    )?;

    /// Returns the six hex grid coordinates adjacent to the cell at (q, r).
    ///
    /// # Parameters
    /// - `q` — Integer q (column) coordinate of the center cell.
    /// - `r` — Integer r (row) coordinate of the center cell.
    ///
    /// # Returns
    /// Table of six {q, r} neighbor coordinate tables.
    tilemap_table.set(
        "hexNeighbors",
        lua.create_function(|lua, (q, r): (i32, i32)| {
            let neighbors = coords::hex_neighbors(q, r);
            let t = lua.create_table()?;
            for (i, (nq, nr)) in neighbors.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Q on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("q", *nq)?;
                /// R on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("r", *nr)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;

    /// luna.tilemap.hexDistance(q1, r1, q2, r2)
    tilemap_table.set(
        "hexDistance",
        lua.create_function(|_, (q1, r1, q2, r2): (i32, i32, i32, i32)| {
            Ok(coords::hex_distance(q1, r1, q2, r2))
        })?,
    )?;

    /// Rounds fractional hex coordinates (q, r) to the nearest integer hex cell center.
    ///
    /// # Parameters
    /// - `q` — Fractional q (column) coordinate.
    /// - `r` — Fractional r (row) coordinate.
    ///
    /// # Returns
    /// Rounded integer q and r coordinates.
    tilemap_table.set(
        "hexRound",
        lua.create_function(|_, (q, r): (f32, f32)| {
            let (rq, rr) = coords::hex_round(q, r);
            Ok((rq, rr))
        })?,
    )?;

    /// luna.tilemap.hexLine(q1, r1, q2, r2)
    tilemap_table.set(
        "hexLine",
        lua.create_function(|lua, (q1, r1, q2, r2): (i32, i32, i32, i32)| {
            let cells = coords::hex_line(q1, r1, q2, r2);
            let t = lua.create_table()?;
            for (i, (q, r)) in cells.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Q on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("q", *q)?;
                /// R on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("r", *r)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;

    /// Returns all hex cell coordinates forming the ring at exactly the given radius from (q, r).
    ///
    /// # Parameters
    /// - `q` — Center q coordinate.
    /// - `r` — Center r coordinate.
    /// - `radius` — Ring distance in hex steps.
    ///
    /// # Returns
    /// Table of {q, r} coordinates for each cell on the ring.
    tilemap_table.set(
        "hexRing",
        lua.create_function(|lua, (q, r, radius): (i32, i32, i32)| {
            let cells = coords::hex_ring(q, r, radius);
            let t = lua.create_table()?;
            for (i, (cq, cr)) in cells.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Q on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("q", *cq)?;
                /// R on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("r", *cr)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;

    /// luna.tilemap.hexSpiral(q, r, radius)
    tilemap_table.set(
        "hexSpiral",
        lua.create_function(|lua, (q, r, radius): (i32, i32, i32)| {
            let cells = coords::hex_spiral(q, r, radius);
            let t = lua.create_table()?;
            for (i, (cq, cr)) in cells.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Q on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("q", *cq)?;
                /// R on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("r", *cr)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;

    /// Returns all hex cell coordinates within a given radius of center (q, r).
    ///
    /// # Parameters
    /// - `q` — Center q coordinate.
    /// - `r` — Center r coordinate.
    /// - `radius` — Radius in hex steps (1 = immediate ring, 2 = two rings, etc.).
    ///
    /// # Returns
    /// Table of {q, r} coordinates for every cell within the radius.
    tilemap_table.set(
        "hexArea",
        lua.create_function(|lua, (q, r, radius): (i32, i32, i32)| {
            let cells = coords::hex_area(q, r, radius);
            let t = lua.create_table()?;
            for (i, (cq, cr)) in cells.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Q on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("q", *cq)?;
                /// R on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("r", *cr)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;

    /// luna.tilemap.hexRotate(q, r, centerQ, centerR, steps)
    tilemap_table.set(
        "hexRotate",
        lua.create_function(
            |_, (q, r, center_q, center_r, steps): (i32, i32, i32, i32, i32)| {
                let (rq, rr) = coords::hex_rotate(q, r, center_q, center_r, steps);
                Ok((rq, rr))
            },
        )?,
    )?;

    /// luna.tilemap.hexReflect(q, r, centerQ, centerR, axis)
    tilemap_table.set(
        "hexReflect",
        lua.create_function(
            |_, (q, r, center_q, center_r, axis): (i32, i32, i32, i32, String)| {
                let (rq, rr) = coords::hex_reflect(q, r, center_q, center_r, &axis);
                Ok((rq, rr))
            },
        )?,
    )?;

    /// luna.tilemap.newIsoMap(width, height, tileW, tileH, levelHeight)
    tilemap_table.set(
        "newIsoMap",
        lua.create_function(
            |_, (width, height, tile_w, tile_h, level_height): (u32, u32, u32, u32, u32)| {
                Ok(LuaIsoMap {
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

    // Tile-part constants (1-based for Lua callers)
    /// F l o o r on this ChunkMap.
    ///
    /// # Returns
    /// The result.
    tilemap_table.set("FLOOR", 1u32)?;
    /// N o r t h_ w a l l on this ChunkMap.
    ///
    /// # Returns
    /// The result.
    tilemap_table.set("NORTH_WALL", 2u32)?;
    /// W e s t_ w a l l on this ChunkMap.
    ///
    /// # Returns
    /// The result.
    tilemap_table.set("WEST_WALL", 3u32)?;
    /// O b j e c t on this ChunkMap.
    ///
    /// # Returns
    /// The result.
    tilemap_table.set("OBJECT", 4u32)?;

    /// Tilemap on this ChunkMap.
    ///
    /// # Returns
    /// The result.
    luna.set("tilemap", tilemap_table)?;
    Ok(())
}
