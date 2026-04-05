//! `luna.tilemap` Lua API bindings.
//!
//! Auto-generated skeleton from `src/tilemap/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaAutoTileSheet ────────────────────────────────────────────────────────────

pub struct LuaAutoTileSheet(/* TODO: add key + state fields */);


impl LuaAutoTileSheet {
    /// Returns the layout variant.
    ///
    ///
    /// # Returns
    /// `AutoTileLayout`.
    ///
    /// @return AutoTileLayout
    pub fn get_layout(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of tiles in this sheet.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tile_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the tile width in pixels.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tile_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the tile height in pixels.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tile_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Applies autotile rules from this sheet to a [`TileSet`].
    ///
    ///
    /// # Parameters
    /// - `tileset` — `mut TileSet` ...
    /// - `type_name` — `str` ...
    /// - `start_gid` — `integer?` ...
    ///
    /// @param tileset : mut TileSet
    /// @param type_name : str
    /// @param start_gid : integer?
    pub fn apply_to_tileset(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the bitmask value associated with a tile index, or 0 if out of bounds.
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    ///
    /// # Returns
    /// `u16`.
    ///
    /// @param index : integer
    /// @return u16
    pub fn get_bitmask_for_tile(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the tile index for a given bitmask, if one exists.
    ///
    ///
    /// # Parameters
    /// - `bitmask` — `u16` ...
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @param bitmask : u16
    /// @return integer?
    pub fn get_tile_for_bitmask(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the atlas region rectangle for the tile at the given index.
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    ///
    /// # Returns
    /// `Rect`.
    ///
    /// @param index : integer
    /// @return Rect
    pub fn get_quad(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the atlas region for a tile stored in a **grid-layout** atlas.
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    /// - `cols` — `integer` ...
    ///
    /// # Returns
    /// `Rect`.
    ///
    /// @param index : integer
    /// @param cols : integer
    /// @return Rect
    pub fn get_grid_quad(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the atlas region for a pre-composed 48-tile layout using the
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    ///
    /// # Returns
    /// `Rect`.
    ///
    /// @param index : integer
    /// @return Rect
    pub fn get_composite48_grid_quad(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the four quarter-tile source [`Rect`]s for the given raw 8-bit neighbour bitmask.
    ///
    ///
    /// # Parameters
    /// - `bitmask` — `u16` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param bitmask : u16
    /// @return The
    pub fn get_quarter_rects(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the four **destination** sub-rects within a tile at world position `(x, y)`.
    ///
    ///
    /// # Parameters
    /// - `x` — `number` ...
    /// - `y` — `number` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param x : number
    /// @param y : number
    /// @return The
    pub fn get_quarter_dst_rects(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaAutoTileSheet {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getLayout", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTileCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTileWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTileHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("applyToTileset", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBitmaskForTile", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTileForBitmask", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getQuad", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getGridQuad", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getComposite48GridQuad", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getQuarterRects", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getQuarterDstRects", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaChunkMap ────────────────────────────────────────────────────────────

pub struct LuaChunkMap(/* TODO: add key + state fields */);


impl LuaChunkMap {
    /// Returns the chunk size (tiles per side).
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_chunk_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the GID at tile coordinate `(x, y)`.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return integer
    pub fn get_tile(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns a list of all currently loaded chunk coordinates.
    ///
    ///
    /// # Returns
    /// `Vec<(i32`.
    ///
    /// @return Vec<(i32
    pub fn get_loaded_chunks(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of currently loaded chunks.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_loaded_chunk_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the chunk at `(cx, cy)` is currently loaded.
    ///
    ///
    /// # Parameters
    /// - `cx` — `integer` ...
    /// - `cy` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param cx : integer
    /// @param cy : integer
    /// @return boolean
    pub fn is_chunk_loaded(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Converts tile `(x, y)` to chunk coordinates `(cx, cy)`.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// @param x : integer
    /// @param y : integer
    pub fn tile_to_chunk(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the inclusive tile coordinate range for chunk `(cx, cy)` as `(x0, y0, x1, y1)`.
    ///
    ///
    /// # Parameters
    /// - `cx` — `integer` ...
    /// - `cy` — `integer` ...
    ///
    /// # Returns
    /// `x1`.
    ///
    /// @param cx : integer
    /// @param cy : integer
    /// @return x1
    pub fn chunk_tile_range(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the world-pixel bounding rectangle of chunk `(cx, cy)`.
    ///
    ///
    /// # Parameters
    /// - `cx` — `integer` ...
    /// - `cy` — `integer` ...
    /// - `tw` — `number` ...
    /// - `th` — `number` ...
    ///
    /// # Returns
    /// `Rect`.
    ///
    /// @param cx : integer
    /// @param cy : integer
    /// @param tw : number
    /// @param th : number
    /// @return Rect
    pub fn chunk_world_rect(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Provides read-only access to the raw GID slice for chunk `(cx, cy)`.
    ///
    ///
    /// # Parameters
    /// - `cx` — `integer` ...
    /// - `cy` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param cx : integer
    /// @param cy : integer
    /// @return Option<
    pub fn iter_chunk(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaChunkMap {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getChunkSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTile", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLoadedChunks", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLoadedChunkCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isChunkLoaded", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("tileToChunk", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("chunkTileRange", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("chunkWorldRect", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("iterChunk", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaIsoLevel ────────────────────────────────────────────────────────────

pub struct LuaIsoLevel(/* TODO: add key + state fields */);


impl LuaIsoLevel {
    /// Returns the [`IsoTile`] at `(x, y)`, or `None` if out of bounds.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return Option<
    pub fn get_tile(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaIsoLevel {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getTile", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaIsoMap ────────────────────────────────────────────────────────────

pub struct LuaIsoMap(/* TODO: add key + state fields */);


impl LuaIsoMap {
    /// Returns the number of Z-levels currently in the map.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_level_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the visibility of level `z`, or `true` if `z` is out of range.
    ///
    ///
    /// # Parameters
    /// - `z` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param z : integer
    /// @return boolean
    pub fn get_level_visible(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Reads the GID in the `part` slot of tile `(x, y)` on level `z`.
    ///
    ///
    /// # Parameters
    /// - `z` — `integer` ...
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    /// - `part` — `integer` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param z : integer
    /// @param x : integer
    /// @param y : integer
    /// @param part : integer
    /// @return integer
    pub fn get_tile_part(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Projects isometric tile coordinates `(tx, ty, tz)` to screen pixels.
    ///
    ///
    /// # Parameters
    /// - `tx` — `number` ...
    /// - `ty` — `number` ...
    /// - `tz` — `number` ...
    ///
    /// # Returns
    /// `All`.
    ///
    /// @param tx : number
    /// @param ty : number
    /// @param tz : number
    /// @return All
    pub fn tile_to_screen(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
    ///
    ///
    /// # Parameters
    /// - `sx` — `number` ...
    /// - `sy` — `number` ...
    ///
    /// # Returns
    /// `Returns`.
    ///
    /// @param sx : number
    /// @param sy : number
    /// @return Returns
    pub fn screen_to_tile(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all draw items in painter's algorithm order for rendering up to
    ///
    ///
    /// # Parameters
    /// - `active_z` — `integer` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param active_z : integer
    /// @return table
    pub fn draw_iter(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaIsoMap {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getLevelCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLevelVisible", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTilePart", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("tileToScreen", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("screenToTile", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("drawIter", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaLargeMapRenderer ────────────────────────────────────────────────────────────

pub struct LuaLargeMapRenderer(/* TODO: add key + state fields */);


impl LuaLargeMapRenderer {
    /// Returns the tile ID at `(x, y)` (0-based), or `None` if out of bounds.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return integer?
    pub fn get_tile(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current chunk size (tiles per side).
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_chunk_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of chunks currently visible given the camera
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_visible_chunks(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of chunks. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_total_chunks(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether LOD is enabled. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_lod_enabled(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of tileset columns. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tileset_columns(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaLargeMapRenderer {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getTile", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getChunkSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getVisibleChunks", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTotalChunks", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isLodEnabled", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTilesetColumns", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaMapBlock ────────────────────────────────────────────────────────────

pub struct LuaMapBlock(/* TODO: add key + state fields */);


impl LuaMapBlock {
    /// Returns the GID of the tile at `(x, y)` on the given layer. Returns 0 if out of bounds.
    ///
    ///
    /// # Parameters
    /// - `layer` — `integer` ...
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param layer : integer
    /// @param x : integer
    /// @param y : integer
    /// @return integer
    pub fn get_tile(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the side connection ID for a segment on a given edge, or 0 if not set.
    ///
    ///
    /// # Parameters
    /// - `edge` — `Edge` ...
    /// - `segment` — `integer` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param edge : Edge
    /// @param segment : integer
    /// @return integer
    pub fn get_side(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the block width in tiles. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the block height in tiles. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of layers in this block.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_layer_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the segment size in tiles. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_segment_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of segments along the width.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_width_in_segments(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of segments along the height.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_height_in_segments(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the segment count for a given edge direction.
    ///
    ///
    /// # Parameters
    /// - `edge` — `Edge` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param edge : Edge
    /// @return integer
    pub fn get_segment_count(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the placement weight. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_weight(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMapBlock {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getTile", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSide", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLayerCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSegmentSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getWidthInSegments", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getHeightInSegments", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSegmentCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getWeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaMapGen ────────────────────────────────────────────────────────────

pub struct LuaMapGen(/* TODO: add key + state fields */);


impl LuaMapGen {
    /// Returns the grid width in segments. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_grid_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the grid height in segments. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_grid_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the segment size in tiles. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_segment_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the tile pixel width. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tile_pixel_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the tile pixel height. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tile_pixel_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of placements made during the last generation.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_placement_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current map orientation. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `MapOrientation`.
    ///
    /// @return MapOrientation
    pub fn get_orientation(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of zones. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_zone_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns a zone by index. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param index : integer
    /// @return Option<
    pub fn get_zone(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current layer mode. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `LayerMode`.
    ///
    /// @return LayerMode
    pub fn get_layer_mode(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMapGen {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getGridWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getGridHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSegmentSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTilePixelWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTilePixelHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getPlacementCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getOrientation", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getZoneCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getZone", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLayerMode", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaMapGroup ────────────────────────────────────────────────────────────

pub struct LuaMapGroup(/* TODO: add key + state fields */);


impl LuaMapGroup {
    /// Returns a reference to a block by index.
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param index : integer
    /// @return Option<
    pub fn get_block(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of blocks in this group.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_block_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns a reference to a script by index.
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param index : integer
    /// @return Option<
    pub fn get_script(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of scripts in this group.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_script_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMapGroup {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getBlock", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBlockCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getScript", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getScriptCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaMapScript ────────────────────────────────────────────────────────────

pub struct LuaMapScript(/* TODO: add key + state fields */);


impl LuaMapScript {
    /// Returns a reference to a step by index.
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param index : integer
    /// @return Option<
    pub fn get_step(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of steps. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_step_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMapScript {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getStep", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getStepCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaPolygonMap ────────────────────────────────────────────────────────────

pub struct LuaPolygonMap(/* TODO: add key + state fields */);


impl LuaPolygonMap {
    /// Get the fill color of a region. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `Color?`.
    ///
    /// @param name : str
    /// @return Color?
    pub fn get_region_color(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return the name of the first region containing the point `(x, y)`.
    ///
    ///
    /// # Parameters
    /// - `x` — `number` ...
    /// - `y` — `number` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param x : number
    /// @param y : number
    /// @return Option<
    pub fn get_region_at(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Names of all regions. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn get_region_names(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Flat vertex slice for a region. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param name : str
    /// @return Option<
    pub fn get_region_vertices(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Centroid of a region (average of its vertices).
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `Option<(f32`.
    ///
    /// @param name : str
    /// @return Option<(f32
    pub fn get_region_center(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Axis-aligned bounding box of all regions: `(min_x, min_y, width, height)`.
    ///
    ///
    /// # Returns
    /// `Option<(f32`.
    ///
    /// @return Option<(f32
    pub fn get_bounding_box(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaPolygonMap {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getRegionColor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRegionAt", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRegionNames", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRegionVertices", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRegionCenter", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBoundingBox", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaTileMap ────────────────────────────────────────────────────────────

pub struct LuaTileMap(/* TODO: add key + state fields */);


impl LuaTileMap {
    /// Returns a reference to a tileset by index.
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param index : integer
    /// @return Option<
    pub fn get_tileset(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of tilesets attached to this map.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tileset_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of layers. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_layer_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the name of a layer by index.
    ///
    ///
    /// # Parameters
    /// - `idx` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param idx : integer
    /// @return Option<
    pub fn get_layer_name(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns layer visibility. Defaults to `false` for invalid index.
    ///
    ///
    /// # Parameters
    /// - `idx` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param idx : integer
    /// @return boolean
    pub fn get_layer_visible(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the RGBA tint color of a layer. Defaults to `[0,0,0,0]` for invalid index.
    ///
    ///
    /// # Parameters
    /// - `idx` — `integer` ...
    ///
    /// @param idx : integer
    pub fn get_layer_color(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the pixel offset of a layer. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `idx` — `integer` ...
    ///
    /// # Returns
    /// `Vec2`.
    ///
    /// @param idx : integer
    /// @return Vec2
    pub fn get_layer_offset(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the parallax factor of a layer. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `idx` — `integer` ...
    ///
    /// # Returns
    /// `Vec2`.
    ///
    /// @param idx : integer
    /// @return Vec2
    pub fn get_layer_parallax(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the (width, height) of a layer in tiles, or `None` if out of range.
    ///
    ///
    /// # Parameters
    /// - `idx` — `integer` ...
    ///
    /// # Returns
    /// `Option<(u32`.
    ///
    /// @param idx : integer
    /// @return Option<(u32
    pub fn get_layer_dimensions(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the GID at `(x, y)` on the given layer. Returns 0 if out of bounds.
    ///
    ///
    /// # Parameters
    /// - `layer` — `integer` ...
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param layer : integer
    /// @param x : integer
    /// @param y : integer
    /// @return integer
    pub fn get_tile(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the viewport as `(x, y, w, h)`, if set.
    ///
    ///
    /// # Returns
    /// `Option<(f32`.
    ///
    /// @return Option<(f32
    pub fn get_viewport(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Converts world pixel coordinates to tile coordinates.
    ///
    ///
    /// # Parameters
    /// - `wx` — `number` ...
    /// - `wy` — `number` ...
    ///
    /// @param wx : number
    /// @param wy : number
    pub fn world_to_tile(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Converts tile coordinates to world pixel coordinates (top-left of tile).
    ///
    ///
    /// # Parameters
    /// - `tx` — `integer` ...
    /// - `ty` — `integer` ...
    ///
    /// @param tx : integer
    /// @param ty : integer
    pub fn tile_to_world(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the tile width in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tile_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the tile height in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tile_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the chunk size used for spatial partitioning.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_chunk_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the map orientation (top-down or side-view).
    ///
    ///
    /// # Returns
    /// `MapOrientation`.
    ///
    /// @return MapOrientation
    pub fn get_orientation(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if the tile at `(x, y)` on `layer` is solid.
    ///
    ///
    /// # Parameters
    /// - `layer` — `integer` ...
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param layer : integer
    /// @param x : integer
    /// @param y : integer
    /// @return boolean
    pub fn is_solid(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if any solid tile overlaps the given world-space rectangle on `layer`.
    ///
    ///
    /// # Parameters
    /// - `layer` — `integer` ...
    /// - `rect` — `Rect` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param layer : integer
    /// @param rect : Rect
    /// @return boolean
    pub fn rect_overlaps_solid(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Performs a swept AABB collision test against solid tiles on `layer`.
    ///
    ///
    /// # Parameters
    /// - `layer` — `integer` ...
    /// - `rect` — `Rect` ...
    /// - `dx` — `number` ...
    /// - `dy` — `number` ...
    ///
    /// # Returns
    /// `SweepResult?`.
    ///
    /// @param layer : integer
    /// @param rect : Rect
    /// @param dx : number
    /// @param dy : number
    /// @return SweepResult?
    pub fn sweep_rect(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTileMap {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getTileset", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTilesetCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLayerCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLayerName", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLayerVisible", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLayerColor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLayerOffset", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLayerParallax", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLayerDimensions", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTile", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getViewport", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("worldToTile", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("tileToWorld", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTileWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTileHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getChunkSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getOrientation", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isSolid", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("rectOverlapsSolid", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("sweepRect", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaTileSet ────────────────────────────────────────────────────────────

pub struct LuaTileSet(/* TODO: add key + state fields */);


impl LuaTileSet {
    /// Returns the first global ID assigned to this tileset.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_first_gid(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of tiles in this tileset.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tile_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of tile columns in the atlas texture.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_columns(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the width of a single tile in pixels.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tile_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the height of a single tile in pixels.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_tile_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the spacing in pixels between tiles in the atlas.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_spacing(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the margin in pixels around the edges of the atlas.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_margin(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Computes the atlas source rectangle for a 0-based local tile ID.
    ///
    ///
    /// # Parameters
    /// - `local_tile_id` — `integer` ...
    ///
    /// # Returns
    /// `Rect`.
    ///
    /// @param local_tile_id : integer
    /// @return Rect
    pub fn get_quad(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the animation frames for a local tile ID, if any.
    ///
    ///
    /// # Parameters
    /// - `local_tile_id` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param local_tile_id : integer
    /// @return Option<
    pub fn get_animation(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether a local tile ID is solid. Out-of-bounds IDs return `false`.
    ///
    ///
    /// # Parameters
    /// - `local_tile_id` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param local_tile_id : integer
    /// @return boolean
    pub fn is_solid(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Looks up the local tile ID for a 4-bit cardinal autotile bitmask.
    ///
    ///
    /// # Parameters
    /// - `type_name` — `str` ...
    /// - `bitmask` — `u8` ...
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @param type_name : str
    /// @param bitmask : u8
    /// @return integer?
    pub fn get_auto_tile_id(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Looks up the local tile ID for an 8-bit directional autotile bitmask.
    ///
    ///
    /// # Parameters
    /// - `type_name` — `str` ...
    /// - `bitmask` — `u16` ...
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @param type_name : str
    /// @param bitmask : u16
    /// @return integer?
    pub fn get_auto_tile_id_8(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTileSet {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getFirstGid", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTileCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getColumns", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTileWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTileHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSpacing", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getMargin", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getQuad", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getAnimation", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isSolid", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getAutoTileId", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getAutoTileId8", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaTileWalker ────────────────────────────────────────────────────────────

pub struct LuaTileWalker(/* TODO: add key + state fields */);


impl LuaTileWalker {
    /// Returns the current X coordinate. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn x(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current Y coordinate. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn y(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current facing direction. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `Facing`.
    ///
    /// @return Facing
    pub fn facing(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns true if the walker can move forward without actually moving.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn can_move_forward(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns true if the walker can move backward without actually moving.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn can_move_backward(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns true if the walker can strafe left without actually moving.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn can_strafe_left(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns true if the walker can strafe right without actually moving.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn can_strafe_right(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the interpolated position between previous and current at time `t` in [0, 1].
    ///
    ///
    /// # Parameters
    /// - `t` — `number` ...
    ///
    /// @param t : number
    pub fn get_interpolated_position(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the interpolated angle between previous and current facing at time `t` in [0, 1].
    ///
    ///
    /// # Parameters
    /// - `t` — `number` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param t : number
    /// @return number
    pub fn get_interpolated_angle(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the relative direction from the walker to a target tile.
    ///
    ///
    /// # Parameters
    /// - `tx` — `integer` ...
    /// - `ty` — `integer` ...
    ///
    /// # Returns
    /// `Returns`.
    ///
    /// @param tx : integer
    /// @param ty : integer
    /// @return Returns
    pub fn get_relative_facing(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTileWalker {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("x", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("y", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("facing", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("canMoveForward", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("canMoveBackward", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("canStrafeLeft", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("canStrafeRight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getInterpolatedPosition", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getInterpolatedAngle", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRelativeFacing", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaTmxMap ────────────────────────────────────────────────────────────

pub struct LuaTmxMap(/* TODO: add key + state fields */);


impl LuaTmxMap {
    /// Returns only the tile layers, ignoring object / image layers.
    ///
    ///
    /// # Returns
    /// `impl`.
    ///
    /// @return impl
    pub fn tile_layers(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns only the object layers. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `impl`.
    ///
    /// @return impl
    pub fn object_layers(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTmxMap {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("tileLayers", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("objectLayers", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.tilemap.* functions ──────────────────────────────────────────

/// Sets the GID at tile coordinate `(x, y)`.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `gid` — `integer` ...
///
/// @param x : integer
/// @param y : integer
/// @param gid : integer
pub fn set_tile(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Clears the tile at `(x, y)` by setting its GID to 0.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
///
/// @param x : integer
/// @param y : integer
pub fn clear_tile(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Fills the rectangular tile region `[x0, x1) × [y0, y1)` with `gid`.
///
///
/// # Parameters
/// - `x0` — `integer` ...
/// - `y0` — `integer` ...
/// - `x1` — `integer` ...
/// - `y1` — `integer` ...
/// - `gid` — `integer` ...
///
/// @param x0 : integer
/// @param y0 : integer
/// @param x1 : integer
/// @param y1 : integer
/// @param gid : integer
pub fn fill_rect(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Pre-allocates the chunk at chunk coordinates `(cx, cy)`.
///
///
/// # Parameters
/// - `cx` — `integer` ...
/// - `cy` — `integer` ...
///
/// @param cx : integer
/// @param cy : integer
pub fn load_chunk(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes the chunk at chunk coordinates `(cx, cy)` from memory.
///
///
/// # Parameters
/// - `cx` — `integer` ...
/// - `cy` — `integer` ...
///
/// @param cx : integer
/// @param cy : integer
pub fn unload_chunk(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns chunk coordinates whose world-pixel footprint overlaps the given viewport.
///
///
/// # Parameters
/// - `vx` — `number` ...
/// - `vy` — `number` ...
/// - `vw` — `number` ...
/// - `vh` — `number` ...
/// - `tw` — `number` ...
/// - `th` — `number` ...
///
/// # Returns
/// `Vec<(i32`.
///
/// @param vx : number
/// @param vy : number
/// @param vw : number
/// @param vh : number
/// @param tw : number
/// @param th : number
/// @return Vec<(i32
pub fn get_chunks_in_view(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Converts tile coordinates to screen position using diamond isometric projection.
///
///
/// # Parameters
/// - `tx` — `number` ...
/// - `ty` — `number` ...
/// - `tile_w` — `number` ...
/// - `tile_h` — `number` ...
///
/// # Returns
/// `Vec2`.
///
/// @param tx : number
/// @param ty : number
/// @param tile_w : number
/// @param tile_h : number
/// @return Vec2
pub fn to_screen_iso(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Converts screen position back to tile coordinates for diamond isometric projection.
///
///
/// # Parameters
/// - `sx` — `number` ...
/// - `sy` — `number` ...
/// - `tile_w` — `number` ...
/// - `tile_h` — `number` ...
///
/// # Returns
/// `Vec2`.
///
/// @param sx : number
/// @param sy : number
/// @param tile_w : number
/// @param tile_h : number
/// @return Vec2
pub fn from_screen_iso(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Rotates an isometric direction (1–4) clockwise by `steps`.
///
///
/// # Parameters
/// - `direction` — `integer` ...
/// - `steps` — `integer` ...
///
/// # Returns
/// `integer`.
///
/// @param direction : integer
/// @param steps : integer
/// @return integer
pub fn iso_rotate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the name of an isometric direction (1–4).
///
///
/// # Parameters
/// - `direction` — `integer` ...
///
/// # Returns
/// `Returns`.
///
/// @param direction : integer
/// @return Returns
pub fn iso_direction_name(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Snaps an angle (in radians) to the nearest isometric direction (1–4).
///
///
/// # Parameters
/// - `angle` — `number` ...
///
/// # Returns
/// `integer`.
///
/// @param angle : number
/// @return integer
pub fn iso_direction_from_angle(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Converts axial hex coordinates to screen position (pointy-top layout).
///
///
/// # Parameters
/// - `q` — `integer` ...
/// - `r` — `integer` ...
/// - `size` — `number` ...
///
/// # Returns
/// `Vec2`.
///
/// @param q : integer
/// @param r : integer
/// @param size : number
/// @return Vec2
pub fn to_screen_hex(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Converts screen position back to axial hex coordinates (pointy-top layout).
///
///
/// # Parameters
/// - `sx` — `number` ...
/// - `sy` — `number` ...
/// - `size` — `number` ...
///
/// # Returns
/// `Uses`.
///
/// @param sx : number
/// @param sy : number
/// @param size : number
/// @return Uses
pub fn from_screen_hex(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the six axial neighbor offsets for pointy-top hexagonal grids.
///
///
/// # Parameters
/// - `q` — `integer` ...
/// - `r` — `integer` ...
///
/// @param q : integer
/// @param r : integer
pub fn hex_neighbors(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the hex distance between two axial coordinates using cube distance.
///
///
/// # Parameters
/// - `q1` — `integer` ...
/// - `r1` — `integer` ...
/// - `q2` — `integer` ...
/// - `r2` — `integer` ...
///
/// # Returns
/// `integer`.
///
/// @param q1 : integer
/// @param r1 : integer
/// @param q2 : integer
/// @param r2 : integer
/// @return integer
pub fn hex_distance(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Rounds fractional axial coordinates to the nearest hex cell using cube rounding.
///
///
/// # Parameters
/// - `q` — `number` ...
/// - `r` — `number` ...
///
/// @param q : number
/// @param r : number
pub fn hex_round(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns all hex cells along a line between two axial coordinates.
///
///
/// # Parameters
/// - `q1` — `integer` ...
/// - `r1` — `integer` ...
/// - `q2` — `integer` ...
/// - `r2` — `integer` ...
///
/// # Returns
/// `Vec<(i32`.
///
/// @param q1 : integer
/// @param r1 : integer
/// @param q2 : integer
/// @param r2 : integer
/// @return Vec<(i32
pub fn hex_line(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns all cells at exactly `radius` distance from `(q, r)`.
///
///
/// # Parameters
/// - `q` — `integer` ...
/// - `r` — `integer` ...
/// - `radius` — `integer` ...
///
/// # Returns
/// `Vec<(i32`.
///
/// @param q : integer
/// @param r : integer
/// @param radius : integer
/// @return Vec<(i32
pub fn hex_ring(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns all hex cells from center outward to `radius`, ring by ring.
///
///
/// # Parameters
/// - `q` — `integer` ...
/// - `r` — `integer` ...
/// - `radius` — `integer` ...
///
/// # Returns
/// `Vec<(i32`.
///
/// @param q : integer
/// @param r : integer
/// @param radius : integer
/// @return Vec<(i32
pub fn hex_spiral(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns all hex cells within `radius` distance (filled hex circle).
///
///
/// # Parameters
/// - `q` — `integer` ...
/// - `r` — `integer` ...
/// - `radius` — `integer` ...
///
/// # Returns
/// `Vec<(i32`.
///
/// @param q : integer
/// @param r : integer
/// @param radius : integer
/// @return Vec<(i32
pub fn hex_area(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Rotates hex coordinates `(q, r)` around `(center_q, center_r)` by `steps × 60°` clockwise.
///
///
/// # Parameters
/// - `q` — `integer` ...
/// - `r` — `integer` ...
/// - `center_q` — `integer` ...
/// - `center_r` — `integer` ...
/// - `steps` — `integer` ...
///
/// # Returns
/// `Uses`.
///
/// @param q : integer
/// @param r : integer
/// @param center_q : integer
/// @param center_r : integer
/// @param steps : integer
/// @return Uses
pub fn hex_rotate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Reflects hex coordinates across an axis through the center.
///
///
/// # Parameters
/// - `q` — `integer` ...
/// - `r` — `integer` ...
/// - `center_q` — `integer` ...
/// - `center_r` — `integer` ...
/// - `axis` — `str` ...
///
/// # Returns
/// `Axis`.
///
/// @param q : integer
/// @param r : integer
/// @param center_q : integer
/// @param center_r : integer
/// @param axis : str
/// @return Axis
pub fn hex_reflect(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Converts a 0-based index to an [`IsoTilePart`]. Returns `None` for indices ≥ 4.
///
///
/// # Parameters
/// - `i` — `integer` ...
///
/// # Returns
/// `Self?`.
///
/// @param i : integer
/// @return Self?
pub fn from_index(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the 0-based index of this part. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Returns
/// `integer`.
///
/// @return integer
pub fn index(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Returns mutable access to the [`IsoTile`] at `(x, y)`, or `None` if OOB.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
///
/// # Returns
/// `Option<`.
///
/// @param x : integer
/// @param y : integer
/// @return Option<
pub fn get_tile_mut(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Appends a new empty Z-level and returns its 0-based index.
///
///
/// # Returns
/// `integer`.
///
/// @return integer
pub fn add_level(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Sets the visibility of level `z`. Invisible levels are skipped in [`draw_iter`](Self::draw_iter).
///
///
/// # Parameters
/// - `z` — `integer` ...
/// - `visible` — `boolean` ...
///
/// @param z : integer
/// @param visible : boolean
pub fn set_level_visible(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Writes `gid` into the `part` slot of tile `(x, y)` on level `z`.
///
///
/// # Parameters
/// - `z` — `integer` ...
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `part` — `integer` ...
/// - `gid` — `integer` ...
///
/// @param z : integer
/// @param x : integer
/// @param y : integer
/// @param part : integer
/// @param gid : integer
pub fn set_tile_part(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Fills every cell in level `z` with `gid` for the given `part`.
///
///
/// # Parameters
/// - `z` — `integer` ...
/// - `part` — `integer` ...
/// - `gid` — `integer` ...
///
/// @param z : integer
/// @param part : integer
/// @param gid : integer
pub fn fill_level(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the screen pixel origin — the position where tile `(0, 0)` at level `0` projects.
///
///
/// # Parameters
/// - `x` — `number` ...
/// - `y` — `number` ...
///
/// @param x : number
/// @param y : number
pub fn set_origin(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the entire map tile data and rebuilds all chunks.
///
///
/// # Parameters
/// - `data` — `Flat` ...
/// - `width` — `Map` ...
/// - `height` — `Map` ...
///
/// @param data : Flat
/// @param width : Map
/// @param height : Map
pub fn set_map_data(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets a single tile at `(x, y)` (0-based) and marks the enclosing chunk dirty.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `tile_id` — `integer` ...
///
/// @param x : integer
/// @param y : integer
/// @param tile_id : integer
/// Changes the chunk size (tiles per side) and rebuilds all chunks.
///
///
/// # Parameters
/// - `size` — `integer` ...
///
/// @param size : integer
pub fn set_chunk_size(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Marks a specific chunk as dirty (needs rebuild).
///
///
/// # Parameters
/// - `cx` — `integer` ...
/// - `cy` — `integer` ...
///
/// @param cx : integer
/// @param cy : integer
pub fn invalidate_chunk(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the camera position and zoom. Replaces the current camera value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `x` — `number` ...
/// - `y` — `number` ...
/// - `zoom` — `number` ...
///
/// @param x : number
/// @param y : number
/// @param zoom : number
pub fn set_camera(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the viewport size in screen pixels.
///
///
/// # Parameters
/// - `w` — `number` ...
/// - `h` — `number` ...
///
/// @param w : number
/// @param h : number
pub fn set_viewport(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Enables or disables level-of-detail rendering.
///
///
/// # Parameters
/// - `enabled` — `boolean` ...
///
/// @param enabled : boolean
pub fn set_lod_enabled(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the zoom thresholds at which LOD levels change.
///
///
/// # Parameters
/// - `levels` — `table` ...
///
/// @param levels : table
pub fn set_lod_thresholds(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the number of columns in the tileset image.
///
///
/// # Parameters
/// - `cols` — `integer` ...
///
/// @param cols : integer
pub fn set_tileset_columns(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parses an edge from a lowercase string (`"north"`, `"east"`, `"south"`, `"west"`).
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Edge?`.
///
/// @param s : str
/// @return Edge?
pub fn from_str(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the GID of a tile at `(x, y)` on the given layer (0-based).
///
///
/// # Parameters
/// - `layer` — `integer` ...
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `gid` — `integer` ...
///
/// @param layer : integer
/// @param x : integer
/// @param y : integer
/// @param gid : integer
/// Sets the side connection ID for a segment on a given edge.
///
///
/// # Parameters
/// - `edge` — `Edge` ...
/// - `segment` — `integer` ...
/// - `side_id` — `integer` ...
///
/// @param edge : Edge
/// @param segment : integer
/// @param side_id : integer
pub fn set_side(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the human-readable name of this block.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// @param name : str
pub fn set_name(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the placement weight (default 1.0).
///
///
/// # Parameters
/// - `weight` — `number` ...
///
/// @param weight : number
pub fn set_weight(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a block to this group. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// # Parameters
/// - `block` — `MapBlock` ...
///
/// @param block : MapBlock
pub fn add_block(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns a mutable reference to a block by index.
///
///
/// # Parameters
/// - `index` — `integer` ...
///
/// # Returns
/// `Option<`.
///
/// @param index : integer
/// @return Option<
pub fn get_block_mut(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a block by index if in bounds.
///
///
/// # Parameters
/// - `index` — `integer` ...
///
/// @param index : integer
pub fn remove_block(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a script to this group. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// # Parameters
/// - `script` — `MapScript` ...
///
/// @param script : MapScript
pub fn add_script(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the name of this group. Replaces the current name value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// @param name : str
/// Parses a step type from a string identifier.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `StepType?`.
///
/// @param s : str
/// @return StepType?
/// Appends a step to this script. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// # Parameters
/// - `step` — `ScriptStep` ...
///
/// @param step : ScriptStep
pub fn add_step(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a step by index if in bounds.
///
///
/// # Parameters
/// - `index` — `integer` ...
///
/// @param index : integer
pub fn remove_step(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the name of this script. Replaces the current name value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// @param name : str
/// Generates a [`TileMap`] from a [`MapGroup`] using an optional script and seed.
///
///
/// # Parameters
/// - `group` — `MapGroup` ...
/// - `script_index` — `integer?` ...
/// - `seed` — `integer?` ...
///
/// # Returns
/// `TileMap`.
///
/// @param group : MapGroup
/// @param script_index : integer?
/// @param seed : integer?
/// @return TileMap
pub fn generate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Generates a larger map by tiling multiple generation regions.
///
///
/// # Parameters
/// - `group` — `MapGroup` ...
/// - `columns` — `integer` ...
/// - `rows` — `integer` ...
/// - `script_index` — `integer?` ...
/// - `seed` — `integer?` ...
///
/// # Returns
/// `TileMap`.
///
/// @param group : MapGroup
/// @param columns : integer
/// @param rows : integer
/// @param script_index : integer?
/// @param seed : integer?
/// @return TileMap
pub fn generate_world(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the tile pixel dimensions. Replaces the current tile size value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `w` — `integer` ...
/// - `h` — `integer` ...
///
/// @param w : integer
/// @param h : integer
pub fn set_tile_size(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the map orientation. Replaces the current orientation value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `orientation` — `MapOrientation` ...
///
/// @param orientation : MapOrientation
pub fn set_orientation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a named horizontal zone. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// # Parameters
/// - `name` — `str` ...
/// - `start_row` — `integer` ...
/// - `height` — `integer` ...
///
/// @param name : str
/// @param start_row : integer
/// @param height : integer
pub fn add_zone(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the layer mode. Replaces the current layer mode value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `mode` — `LayerMode` ...
///
/// @param mode : LayerMode
pub fn set_layer_mode(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a named polygon region with the given flat vertex data and color.
///
///
/// # Parameters
/// - `name` — `impl Into<String>` ...
/// - `vertices` — `table` ...
/// - `color` — `Color` ...
///
/// @param name : impl Into<String>
/// @param vertices : table
/// @param color : Color
pub fn add_region(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a region by name. Returns `true` if it existed.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// # Returns
/// `boolean`.
///
/// @param name : str
/// @return boolean
pub fn remove_region(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the fill color of a region. Returns `false` if the region doesn't exist.
///
///
/// # Parameters
/// - `name` — `str` ...
/// - `color` — `Color` ...
///
/// # Returns
/// `boolean`.
///
/// @param name : str
/// @param color : Color
/// @return boolean
pub fn set_region_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the label text and font size for a region.
///
///
/// # Parameters
/// - `name` — `str` ...
/// - `text` — `impl Into<String>` ...
/// - `font_size` — `number` ...
///
/// # Returns
/// `boolean`.
///
/// @param name : str
/// @param text : impl Into<String>
/// @param font_size : number
/// @return boolean
pub fn set_region_label(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the outline color for all regions. Replaces the current outline color value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `color` — `Color` ...
///
/// @param color : Color
pub fn set_outline_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the outline stroke width. Replaces the current outline width value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `width` — `number` ...
///
/// @param width : number
pub fn set_outline_width(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the highlight color. Replaces the current highlight color value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `color` — `Color` ...
///
/// @param color : Color
pub fn set_highlight_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Highlight a region by name. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `name` — `impl Into<String>` ...
///
/// @param name : impl Into<String>
pub fn highlight(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parses a facing direction from a string (case-insensitive).
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Self?`.
///
/// @param s : str
/// @return Self?
pub fn parse(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the angle in radians. North=3PI/2, East=0, South=PI/2, West=PI.
///
///
/// # Returns
/// `number`.
///
/// @return number
pub fn angle(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Returns the X delta for one step in this direction.
///
///
/// # Returns
/// `integer`.
///
/// @return integer
pub fn dx(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Returns the Y delta for one step in this direction.
///
///
/// # Returns
/// `integer`.
///
/// @return integer
pub fn dy(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Sets the position. Replaces the current position value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
///
/// @param x : integer
/// @param y : integer
pub fn set_position(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the facing direction. Replaces the current facing value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `facing` — `Facing` ...
///
/// @param facing : Facing
pub fn set_facing(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Moves forward one tile. Returns true if the move succeeded.
///
///
/// # Returns
/// `boolean`.
///
/// @return boolean
pub fn move_forward(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Moves backward one tile. Returns true if the move succeeded.
///
///
/// # Returns
/// `boolean`.
///
/// @return boolean
pub fn move_backward(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Strafes left one tile. Returns true if the move succeeded.
///
///
/// # Returns
/// `boolean`.
///
/// @return boolean
pub fn strafe_left(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Strafes right one tile. Returns true if the move succeeded.
///
///
/// # Returns
/// `boolean`.
///
/// @return boolean
pub fn strafe_right(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Adds a tileset to this map. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// # Parameters
/// - `ts` — `TileSet` ...
///
/// @param ts : TileSet
pub fn add_tileset(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a new empty layer and returns its 0-based index.
///
///
/// # Parameters
/// - `name` — `str` ...
/// - `width` — `integer` ...
/// - `height` — `integer` ...
///
/// # Returns
/// `integer`.
///
/// @param name : str
/// @param width : integer
/// @param height : integer
/// @return integer
pub fn add_layer(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets layer visibility. Replaces the current layer visible value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `idx` — `integer` ...
/// - `visible` — `boolean` ...
///
/// @param idx : integer
/// @param visible : boolean
pub fn set_layer_visible(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the RGBA tint color for a layer.
///
///
/// # Parameters
/// - `idx` — `integer` ...
/// - `r` — `number` ...
/// - `g` — `number` ...
/// - `b` — `number` ...
/// - `a` — `number` ...
///
/// @param idx : integer
/// @param r : number
/// @param g : number
/// @param b : number
/// @param a : number
pub fn set_layer_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the pixel offset for a layer. Replaces the current layer offset value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `idx` — `integer` ...
/// - `ox` — `number` ...
/// - `oy` — `number` ...
///
/// @param idx : integer
/// @param ox : number
/// @param oy : number
pub fn set_layer_offset(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the parallax scrolling factor for a layer.
///
///
/// # Parameters
/// - `idx` — `integer` ...
/// - `px` — `number` ...
/// - `py` — `number` ...
///
/// @param idx : integer
/// @param px : number
/// @param py : number
pub fn set_layer_parallax(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the GID of a tile at `(x, y)` on the given layer.
///
///
/// # Parameters
/// - `layer` — `integer` ...
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `gid` — `integer` ...
///
/// @param layer : integer
/// @param x : integer
/// @param y : integer
/// @param gid : integer
/// Sets a per-tile RGBA tint override. Replaces the current tile tint value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `layer` — `integer` ...
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `r` — `number` ...
/// - `g` — `number` ...
/// - `b` — `number` ...
/// - `a` — `number` ...
///
/// @param layer : integer
/// @param x : integer
/// @param y : integer
/// @param r : number
/// @param g : number
/// @param b : number
/// @param a : number
pub fn set_tile_tint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Clears a tile (sets GID to 0) at `(x, y)` on the given layer.
///
///
/// # Parameters
/// - `layer` — `integer` ...
/// - `x` — `integer` ...
/// - `y` — `integer` ...
///
/// @param layer : integer
/// @param x : integer
/// @param y : integer
/// Fills an entire layer with the given GID.
///
///
/// # Parameters
/// - `layer` — `integer` ...
/// - `gid` — `integer` ...
///
/// @param layer : integer
/// @param gid : integer
pub fn fill(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the viewport rectangle for rendering culling.
///
///
/// # Parameters
/// - `x` — `number` ...
/// - `y` — `number` ...
/// - `w` — `number` ...
/// - `h` — `number` ...
///
/// @param x : number
/// @param y : number
/// @param w : number
/// @param h : number
/// Advances tile animation timers by `dt` seconds.
///
///
/// # Parameters
/// - `dt` — `number` ...
///
/// @param dt : number
pub fn update(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the map orientation. Replaces the current orientation value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `orientation` — `MapOrientation` ...
///
/// @param orientation : MapOrientation
/// Applies 4-bit cardinal autotile rules to every tile on `layer`.
///
///
/// # Parameters
/// - `layer` — `integer` ...
/// - `type_name` — `str` ...
///
/// @param layer : integer
/// @param type_name : str
pub fn apply_autotile(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Applies 4-bit cardinal autotile at a single cell and its 3×3 neighborhood.
///
///
/// # Parameters
/// - `layer` — `integer` ...
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `type_name` — `str` ...
///
/// @param layer : integer
/// @param x : integer
/// @param y : integer
/// @param type_name : str
pub fn apply_autotile_at(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Applies 8-bit directional autotile rules to every tile on `layer`.
///
///
/// # Parameters
/// - `layer` — `integer` ...
/// - `type_name` — `str` ...
///
/// @param layer : integer
/// @param type_name : str
pub fn apply_autotile_8(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Applies 8-bit directional autotile at a single cell and its 3×3 neighborhood.
///
///
/// # Parameters
/// - `layer` — `integer` ...
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `type_name` — `str` ...
///
/// @param layer : integer
/// @param x : integer
/// @param y : integer
/// @param type_name : str
pub fn apply_autotile_8_at(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the animation frames for a local tile ID.
///
///
/// # Parameters
/// - `local_tile_id` — `integer` ...
/// - `frames` — `table` ...
///
/// @param local_tile_id : integer
/// @param frames : table
pub fn set_animation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets whether a local tile ID is solid for collision purposes.
///
///
/// # Parameters
/// - `local_tile_id` — `integer` ...
/// - `solid` — `boolean` ...
///
/// @param local_tile_id : integer
/// @param solid : boolean
pub fn set_solid(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers a 4-bit cardinal autotile rule mapping a bitmask to a local tile ID.
///
///
/// # Parameters
/// - `type_name` — `str` ...
/// - `bitmask` — `u8` ...
/// - `local_tile_id` — `integer` ...
///
/// @param type_name : str
/// @param bitmask : u8
/// @param local_tile_id : integer
pub fn set_auto_tile_rule(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers an 8-bit directional autotile rule mapping a bitmask to a local tile ID.
///
///
/// # Parameters
/// - `type_name` — `str` ...
/// - `bitmask` — `u16` ...
/// - `local_tile_id` — `integer` ...
///
/// @param type_name : str
/// @param bitmask : u16
/// @param local_tile_id : integer
pub fn set_auto_tile_rule_8(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parses a TMX file given its XML content as a string.
///
///
/// # Parameters
/// - `xml` — `str` ...
///
/// # Returns
/// `Result<TmxMap`.
///
/// @param xml : str
/// @return Result<TmxMap
pub fn load_tmx(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.tilemap` API table.
///
/// # Parameters
/// - `lua` — `&Lua` The Lua VM.
/// - `luna` — `&LuaTable<'_>` The top-level `luna` table.
/// - `state` — `Rc<RefCell<SharedState>>` Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("setTile", lua.create_function(set_tile)?)?;
    tbl.set("clearTile", lua.create_function(clear_tile)?)?;
    tbl.set("fillRect", lua.create_function(fill_rect)?)?;
    tbl.set("loadChunk", lua.create_function(load_chunk)?)?;
    tbl.set("unloadChunk", lua.create_function(unload_chunk)?)?;
    tbl.set("getChunksInView", lua.create_function(get_chunks_in_view)?)?;
    tbl.set("toScreenIso", lua.create_function(to_screen_iso)?)?;
    tbl.set("fromScreenIso", lua.create_function(from_screen_iso)?)?;
    tbl.set("isoRotate", lua.create_function(iso_rotate)?)?;
    tbl.set("isoDirectionName", lua.create_function(iso_direction_name)?)?;
    tbl.set("isoDirectionFromAngle", lua.create_function(iso_direction_from_angle)?)?;
    tbl.set("toScreenHex", lua.create_function(to_screen_hex)?)?;
    tbl.set("fromScreenHex", lua.create_function(from_screen_hex)?)?;
    tbl.set("hexNeighbors", lua.create_function(hex_neighbors)?)?;
    tbl.set("hexDistance", lua.create_function(hex_distance)?)?;
    tbl.set("hexRound", lua.create_function(hex_round)?)?;
    tbl.set("hexLine", lua.create_function(hex_line)?)?;
    tbl.set("hexRing", lua.create_function(hex_ring)?)?;
    tbl.set("hexSpiral", lua.create_function(hex_spiral)?)?;
    tbl.set("hexArea", lua.create_function(hex_area)?)?;
    tbl.set("hexRotate", lua.create_function(hex_rotate)?)?;
    tbl.set("hexReflect", lua.create_function(hex_reflect)?)?;
    tbl.set("fromIndex", lua.create_function(from_index)?)?;
    tbl.set("index", lua.create_function(index)?)?;
    tbl.set("getTileMut", lua.create_function(get_tile_mut)?)?;
    tbl.set("addLevel", lua.create_function(add_level)?)?;
    tbl.set("setLevelVisible", lua.create_function(set_level_visible)?)?;
    tbl.set("setTilePart", lua.create_function(set_tile_part)?)?;
    tbl.set("fillLevel", lua.create_function(fill_level)?)?;
    tbl.set("setOrigin", lua.create_function(set_origin)?)?;
    tbl.set("setMapData", lua.create_function(set_map_data)?)?;
    tbl.set("setTile", lua.create_function(set_tile)?)?;
    tbl.set("setChunkSize", lua.create_function(set_chunk_size)?)?;
    tbl.set("invalidateChunk", lua.create_function(invalidate_chunk)?)?;
    tbl.set("setCamera", lua.create_function(set_camera)?)?;
    tbl.set("setViewport", lua.create_function(set_viewport)?)?;
    tbl.set("setLodEnabled", lua.create_function(set_lod_enabled)?)?;
    tbl.set("setLodThresholds", lua.create_function(set_lod_thresholds)?)?;
    tbl.set("setTilesetColumns", lua.create_function(set_tileset_columns)?)?;
    tbl.set("fromStr", lua.create_function(from_str)?)?;
    tbl.set("setTile", lua.create_function(set_tile)?)?;
    tbl.set("setSide", lua.create_function(set_side)?)?;
    tbl.set("setName", lua.create_function(set_name)?)?;
    tbl.set("setWeight", lua.create_function(set_weight)?)?;
    tbl.set("addBlock", lua.create_function(add_block)?)?;
    tbl.set("getBlockMut", lua.create_function(get_block_mut)?)?;
    tbl.set("removeBlock", lua.create_function(remove_block)?)?;
    tbl.set("addScript", lua.create_function(add_script)?)?;
    tbl.set("setName", lua.create_function(set_name)?)?;
    tbl.set("fromStr", lua.create_function(from_str)?)?;
    tbl.set("addStep", lua.create_function(add_step)?)?;
    tbl.set("removeStep", lua.create_function(remove_step)?)?;
    tbl.set("setName", lua.create_function(set_name)?)?;
    tbl.set("generate", lua.create_function(generate)?)?;
    tbl.set("generateWorld", lua.create_function(generate_world)?)?;
    tbl.set("setTileSize", lua.create_function(set_tile_size)?)?;
    tbl.set("setOrientation", lua.create_function(set_orientation)?)?;
    tbl.set("addZone", lua.create_function(add_zone)?)?;
    tbl.set("setLayerMode", lua.create_function(set_layer_mode)?)?;
    tbl.set("addRegion", lua.create_function(add_region)?)?;
    tbl.set("removeRegion", lua.create_function(remove_region)?)?;
    tbl.set("setRegionColor", lua.create_function(set_region_color)?)?;
    tbl.set("setRegionLabel", lua.create_function(set_region_label)?)?;
    tbl.set("setOutlineColor", lua.create_function(set_outline_color)?)?;
    tbl.set("setOutlineWidth", lua.create_function(set_outline_width)?)?;
    tbl.set("setHighlightColor", lua.create_function(set_highlight_color)?)?;
    tbl.set("highlight", lua.create_function(highlight)?)?;
    tbl.set("parse", lua.create_function(parse)?)?;
    tbl.set("angle", lua.create_function(angle)?)?;
    tbl.set("dx", lua.create_function(dx)?)?;
    tbl.set("dy", lua.create_function(dy)?)?;
    tbl.set("setPosition", lua.create_function(set_position)?)?;
    tbl.set("setFacing", lua.create_function(set_facing)?)?;
    tbl.set("moveForward", lua.create_function(move_forward)?)?;
    tbl.set("moveBackward", lua.create_function(move_backward)?)?;
    tbl.set("strafeLeft", lua.create_function(strafe_left)?)?;
    tbl.set("strafeRight", lua.create_function(strafe_right)?)?;
    tbl.set("addTileset", lua.create_function(add_tileset)?)?;
    tbl.set("addLayer", lua.create_function(add_layer)?)?;
    tbl.set("setLayerVisible", lua.create_function(set_layer_visible)?)?;
    tbl.set("setLayerColor", lua.create_function(set_layer_color)?)?;
    tbl.set("setLayerOffset", lua.create_function(set_layer_offset)?)?;
    tbl.set("setLayerParallax", lua.create_function(set_layer_parallax)?)?;
    tbl.set("setTile", lua.create_function(set_tile)?)?;
    tbl.set("setTileTint", lua.create_function(set_tile_tint)?)?;
    tbl.set("clearTile", lua.create_function(clear_tile)?)?;
    tbl.set("fill", lua.create_function(fill)?)?;
    tbl.set("setViewport", lua.create_function(set_viewport)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("setOrientation", lua.create_function(set_orientation)?)?;
    tbl.set("applyAutotile", lua.create_function(apply_autotile)?)?;
    tbl.set("applyAutotileAt", lua.create_function(apply_autotile_at)?)?;
    tbl.set("applyAutotile8", lua.create_function(apply_autotile_8)?)?;
    tbl.set("applyAutotile8At", lua.create_function(apply_autotile_8_at)?)?;
    tbl.set("setAnimation", lua.create_function(set_animation)?)?;
    tbl.set("setSolid", lua.create_function(set_solid)?)?;
    tbl.set("setAutoTileRule", lua.create_function(set_auto_tile_rule)?)?;
    tbl.set("setAutoTileRule8", lua.create_function(set_auto_tile_rule_8)?)?;
    tbl.set("loadTmx", lua.create_function(load_tmx)?)?;
    luna.set("tilemap", tbl)?;
    Ok(())
}
