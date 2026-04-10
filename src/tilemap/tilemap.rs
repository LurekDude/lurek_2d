//! Main tile map container with layers, tiles, viewport, collision, and autotile support.
//!
//! This module is part of Lurek2D's `tilemap` subsystem and provides the implementation
//! details for tilemap-related operations and data management.
//! Key types exported from this module: `TileLayer`, `SweepResult`, `TileMap`.
//! Primary functions: `new()`, `add_tileset()`, `get_tileset()`, `get_tileset_count()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::collections::HashMap;

use crate::math::{Rect, Vec2};

use super::mapgen::MapOrientation;
use super::tileset::TileSet;
use crate::runtime::log_messages::{TM01_TILEMAP_INIT, TM02_TILESET_ADD, TM03_LAYER_ADD};
use crate::log_msg;

/// A single layer of tiles in a [`TileMap`].
///
/// # Fields
/// - `name` — `String`.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `visible` — `bool`.
/// - `tint` — `[f32; 4]`.
/// - `offset` — `Vec2`.
/// - `parallax` — `Vec2`.
///
/// Tiles are stored in row-major order. GID 0 means "empty / no tile".
#[derive(Debug, Clone)]
pub struct TileLayer {
    /// Human-readable layer name.
    pub name: String,
    /// Width of the layer in tiles.
    pub width: u32,
    /// Height of the layer in tiles.
    pub height: u32,
    /// Whether this layer is rendered.
    pub visible: bool,
    /// RGBA tint applied to every tile in this layer.
    pub tint: [f32; 4],
    /// Pixel offset for rendering.
    pub offset: Vec2,
    /// Parallax scrolling factor.
    pub parallax: Vec2,
    /// Row-major tile GIDs.
    tiles: Vec<u32>,
    /// Per-tile optional RGBA tint overrides.
    tile_tints: Vec<Option<[f32; 4]>>,
}

impl TileLayer {
    /// Creates a new empty tile layer.
    fn new(name: &str, width: u32, height: u32) -> Self {
        let cap = (width * height) as usize;
        Self {
            name: name.to_string(),
            width,
            height,
            visible: true,
            tint: [1.0, 1.0, 1.0, 1.0],
            offset: Vec2::ZERO,
            parallax: Vec2::new(1.0, 1.0),
            tiles: vec![0u32; cap],
            tile_tints: vec![None; cap],
        }
    }

    /// Returns the row-major index for `(x, y)`, or `None` if out of bounds.
    fn index(&self, x: u32, y: u32) -> Option<usize> {
        if x < self.width && y < self.height {
            Some((y * self.width + x) as usize)
        } else {
            None
        }
    }
}

/// Result of a swept-AABB collision test against solid tiles.
///
/// # Fields
/// - `contact_point` — `Vec2`.
/// - `normal` — `Vec2`.
/// - `tile_x` — `u32`.
/// - `tile_y` — `u32`.
/// - `t` — `f32`.
#[derive(Debug, Clone, Copy)]
pub struct SweepResult {
    /// World-space contact point on the tile edge.
    pub contact_point: Vec2,
    /// Surface normal at the contact.
    pub normal: Vec2,
    /// Tile column of the hit tile.
    pub tile_x: u32,
    /// Tile row of the hit tile.
    pub tile_y: u32,
    /// Parametric time of collision in `[0, 1]`.
    pub t: f32,
}

/// A 2D tile map composed of layers, tilesets, and viewport-clipped rendering state.
///
/// All tile coordinates are **0-based**. Lua helpers add 1-based conversion externally.
///
/// # Fields
/// - `tile_width` — `u32`.
/// - `tile_height` — `u32`.
/// - `chunk_size` — `u32`.
/// - `orientation` — `MapOrientation`.
/// - `tilesets` — `Vec<TileSet>`.
/// - `layers` — `Vec<TileLayer>`.
/// - `viewport` — `Option<Rect>`.
/// - `anim_timers` — `HashMap<u32`.
#[derive(Debug, Clone)]
pub struct TileMap {
    tile_width: u32,
    tile_height: u32,
    chunk_size: u32,
    orientation: MapOrientation,
    tilesets: Vec<TileSet>,
    layers: Vec<TileLayer>,
    viewport: Option<Rect>,
    anim_timers: HashMap<u32, (usize, f32)>,
}

impl TileMap {
    // ------------------------------------------------------------------
    // Construction
    // ------------------------------------------------------------------

    /// Creates a new tile map with the given tile size and chunk size.
    ///
    /// # Parameters
    /// - `tile_width` — `u32`.
    /// - `tile_height` — `u32`.
    /// - `chunk_size` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(tile_width: u32, tile_height: u32, chunk_size: u32) -> Self {
        log_msg!(
            debug,
            TM01_TILEMAP_INIT,
            "{}x{} tiles, chunk={}",
            tile_width,
            tile_height,
            chunk_size
        );
        Self {
            tile_width,
            tile_height,
            chunk_size,
            orientation: MapOrientation::TopDown,
            tilesets: Vec::new(),
            layers: Vec::new(),
            viewport: None,
            anim_timers: HashMap::new(),
        }
    }

    // ------------------------------------------------------------------
    // TileSet management
    // ------------------------------------------------------------------

    /// Adds a tileset to this map. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `ts` — `TileSet`.
    pub fn add_tileset(&mut self, ts: TileSet) {
        log_msg!(debug, TM02_TILESET_ADD);
        self.tilesets.push(ts);
    }

    /// Returns a reference to a tileset by index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&TileSet>`.
    pub fn get_tileset(&self, index: usize) -> Option<&TileSet> {
        self.tilesets.get(index)
    }

    /// Returns the number of tilesets attached to this map.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_tileset_count(&self) -> usize {
        self.tilesets.len()
    }

    // ------------------------------------------------------------------
    // Layer management
    // ------------------------------------------------------------------

    /// Adds a new empty layer and returns its 0-based index.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_layer(&mut self, name: &str, width: u32, height: u32) -> usize {
        log_msg!(debug, TM03_LAYER_ADD, "{}", name);
        self.layers.push(TileLayer::new(name, width, height));
        self.layers.len() - 1
    }

    /// Returns the number of layers. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_layer_count(&self) -> usize {
        self.layers.len()
    }

    /// Returns the name of a layer by index.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_layer_name(&self, idx: usize) -> Option<&str> {
        self.layers.get(idx).map(|l| l.name.as_str())
    }

    /// Sets layer visibility. Replaces the current layer visible value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    /// - `visible` — `bool`.
    pub fn set_layer_visible(&mut self, idx: usize, visible: bool) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.visible = visible;
        }
    }

    /// Returns layer visibility. Defaults to `false` for invalid index.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn get_layer_visible(&self, idx: usize) -> bool {
        self.layers.get(idx).is_some_and(|l| l.visible)
    }

    /// Sets the RGBA tint color for a layer.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    /// - `r` — `f32`.
    /// - `g` — `f32`.
    /// - `b` — `f32`.
    /// - `a` — `f32`.
    pub fn set_layer_color(&mut self, idx: usize, r: f32, g: f32, b: f32, a: f32) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.tint = [r, g, b, a];
        }
    }

    /// Returns the RGBA tint color of a layer. Defaults to `[0,0,0,0]` for invalid index.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    ///
    /// # Returns
    /// `[f32; 4]`.
    pub fn get_layer_color(&self, idx: usize) -> [f32; 4] {
        self.layers.get(idx).map_or([0.0; 4], |l| l.tint)
    }

    /// Sets the pixel offset for a layer. Replaces the current layer offset value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    /// - `ox` — `f32`.
    /// - `oy` — `f32`.
    pub fn set_layer_offset(&mut self, idx: usize, ox: f32, oy: f32) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.offset = Vec2::new(ox, oy);
        }
    }

    /// Returns the pixel offset of a layer. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    ///
    /// # Returns
    /// `Vec2`.
    pub fn get_layer_offset(&self, idx: usize) -> Vec2 {
        self.layers.get(idx).map_or(Vec2::ZERO, |l| l.offset)
    }

    /// Sets the parallax scrolling factor for a layer.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    /// - `px` — `f32`.
    /// - `py` — `f32`.
    pub fn set_layer_parallax(&mut self, idx: usize, px: f32, py: f32) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.parallax = Vec2::new(px, py);
        }
    }

    /// Returns the parallax factor of a layer. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    ///
    /// # Returns
    /// `Vec2`.
    pub fn get_layer_parallax(&self, idx: usize) -> Vec2 {
        self.layers
            .get(idx)
            .map_or(Vec2::new(1.0, 1.0), |l| l.parallax)
    }

    /// Returns the (width, height) of a layer in tiles, or `None` if out of range.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    ///
    /// # Returns
    /// `Option<(u32, u32)>`.
    pub fn get_layer_dimensions(&self, idx: usize) -> Option<(u32, u32)> {
        self.layers.get(idx).map(|l| (l.width, l.height))
    }

    // ------------------------------------------------------------------
    // Tile access (0-based x/y)
    // ------------------------------------------------------------------

    /// Sets the GID of a tile at `(x, y)` on the given layer.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `gid` — `u32`.
    pub fn set_tile(&mut self, layer: usize, x: u32, y: u32, gid: u32) {
        if let Some(l) = self.layers.get_mut(layer) {
            if let Some(idx) = l.index(x, y) {
                l.tiles[idx] = gid;
            }
        }
    }

    /// Returns the GID at `(x, y)` on the given layer. Returns 0 if out of bounds.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tile(&self, layer: usize, x: u32, y: u32) -> u32 {
        if let Some(l) = self.layers.get(layer) {
            if let Some(idx) = l.index(x, y) {
                return l.tiles[idx];
            }
        }
        0
    }

    /// Sets a per-tile RGBA tint override. Replaces the current tile tint value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `r` — `f32`.
    /// - `g` — `f32`.
    /// - `b` — `f32`.
    /// - `a` — `f32`.
    #[allow(clippy::too_many_arguments)]
    pub fn set_tile_tint(&mut self, layer: usize, x: u32, y: u32, r: f32, g: f32, b: f32, a: f32) {
        if let Some(l) = self.layers.get_mut(layer) {
            if let Some(idx) = l.index(x, y) {
                l.tile_tints[idx] = Some([r, g, b, a]);
            }
        }
    }

    /// Clears a tile (sets GID to 0) at `(x, y)` on the given layer.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    pub fn clear_tile(&mut self, layer: usize, x: u32, y: u32) {
        self.set_tile(layer, x, y, 0);
    }

    /// Fills an entire layer with the given GID.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `gid` — `u32`.
    pub fn fill(&mut self, layer: usize, gid: u32) {
        if let Some(l) = self.layers.get_mut(layer) {
            for tile in l.tiles.iter_mut() {
                *tile = gid;
            }
        }
    }

    // ------------------------------------------------------------------
    // Viewport
    // ------------------------------------------------------------------

    /// Sets the viewport rectangle for rendering culling.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `w` — `f32`.
    /// - `h` — `f32`.
    pub fn set_viewport(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport = Some(Rect::new(x, y, w, h));
    }

    /// Returns the viewport as `(x, y, w, h)`, if set.
    ///
    /// # Returns
    /// `Option<(f32, f32, f32, f32)>`.
    pub fn get_viewport(&self) -> Option<(f32, f32, f32, f32)> {
        self.viewport.map(|v| (v.x, v.y, v.width, v.height))
    }

    // ------------------------------------------------------------------
    // Animation
    // ------------------------------------------------------------------

    /// Advances tile animation timers by `dt` seconds.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    ///
    /// For each tileset animation, the timer accumulates milliseconds. When the
    /// elapsed time exceeds the current frame's duration, the frame index advances
    /// (wrapping to 0).
    pub fn update(&mut self, dt: f32) {
        let dt_ms = dt * 1000.0;
        for ts in &self.tilesets {
            let first_gid = ts.get_first_gid();
            let count = ts.get_tile_count();
            for local_id in 0..count {
                if let Some(frames) = ts.get_animation(local_id) {
                    if frames.is_empty() {
                        continue;
                    }
                    let gid = first_gid + local_id;
                    let (frame_idx, elapsed) = self.anim_timers.entry(gid).or_insert((0, 0.0));
                    *elapsed += dt_ms;
                    while *elapsed >= frames[*frame_idx].duration_ms {
                        *elapsed -= frames[*frame_idx].duration_ms;
                        *frame_idx = (*frame_idx + 1) % frames.len();
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // Coordinate conversion
    // ------------------------------------------------------------------

    /// Converts world pixel coordinates to tile coordinates.
    ///
    /// # Parameters
    /// - `wx` — `f32`.
    /// - `wy` — `f32`.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn world_to_tile(&self, wx: f32, wy: f32) -> (u32, u32) {
        let tx = if wx < 0.0 {
            0
        } else {
            (wx / self.tile_width as f32) as u32
        };
        let ty = if wy < 0.0 {
            0
        } else {
            (wy / self.tile_height as f32) as u32
        };
        (tx, ty)
    }

    /// Converts tile coordinates to world pixel coordinates (top-left of tile).
    ///
    /// # Parameters
    /// - `tx` — `u32`.
    /// - `ty` — `u32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn tile_to_world(&self, tx: u32, ty: u32) -> (f32, f32) {
        (
            tx as f32 * self.tile_width as f32,
            ty as f32 * self.tile_height as f32,
        )
    }

    // ------------------------------------------------------------------
    // Dimensions
    // ------------------------------------------------------------------

    /// Returns the tile width in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tile_width(&self) -> u32 {
        self.tile_width
    }

    /// Returns the tile height in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tile_height(&self) -> u32 {
        self.tile_height
    }

    /// Returns tile dimensions as `(width, height)`.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_tile_dimensions(&self) -> (u32, u32) {
        (self.tile_width, self.tile_height)
    }

    /// Returns the chunk size used for spatial partitioning.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }

    /// Returns the map orientation (top-down or side-view).
    ///
    /// # Returns
    /// `MapOrientation`.
    pub fn get_orientation(&self) -> MapOrientation {
        self.orientation
    }

    /// Sets the map orientation. Replaces the current orientation value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `orientation` — `MapOrientation`.
    pub fn set_orientation(&mut self, orientation: MapOrientation) {
        self.orientation = orientation;
    }

    // ------------------------------------------------------------------
    // Collision helpers
    // ------------------------------------------------------------------

    /// Resolves a GID to its owning tileset and returns `(tileset_index, local_tile_id)`.
    fn resolve_gid(&self, gid: u32) -> Option<(usize, u32)> {
        if gid == 0 {
            return None;
        }
        for (i, ts) in self.tilesets.iter().enumerate() {
            let first = ts.get_first_gid();
            if gid >= first && gid < first + ts.get_tile_count() {
                return Some((i, gid - first));
            }
        }
        None
    }

    /// Returns `true` if the tile at `(x, y)` on `layer` is solid.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Resolves the GID to its owning tileset and checks the solid flag.
    pub fn is_solid(&self, layer: usize, x: u32, y: u32) -> bool {
        let gid = self.get_tile(layer, x, y);
        if let Some((ts_idx, local_id)) = self.resolve_gid(gid) {
            self.tilesets[ts_idx].is_solid(local_id)
        } else {
            false
        }
    }

    /// Returns `true` if any solid tile overlaps the given world-space rectangle on `layer`.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `rect` — `Rect`.
    ///
    /// # Returns
    /// `bool`.
    pub fn rect_overlaps_solid(&self, layer: usize, rect: Rect) -> bool {
        let (tx0, ty0) = self.world_to_tile(rect.x, rect.y);
        let (tx1, ty1) =
            self.world_to_tile(rect.x + rect.width - 0.001, rect.y + rect.height - 0.001);
        for ty in ty0..=ty1 {
            for tx in tx0..=tx1 {
                if self.is_solid(layer, tx, ty) {
                    return true;
                }
            }
        }
        false
    }

    /// Performs a swept AABB collision test against solid tiles on `layer`.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `rect` — `Rect`.
    /// - `dx` — `f32`.
    /// - `dy` — `f32`.
    ///
    /// # Returns
    /// `Option<SweepResult>`.
    ///
    /// Moves `rect` by `(dx, dy)` and returns the earliest collision, if any.
    pub fn sweep_rect(&self, layer: usize, rect: Rect, dx: f32, dy: f32) -> Option<SweepResult> {
        if dx == 0.0 && dy == 0.0 {
            return None;
        }

        // Determine the broad-phase tile range
        let min_x = rect.x.min(rect.x + dx);
        let min_y = rect.y.min(rect.y + dy);
        let max_x = (rect.x + rect.width).max(rect.x + rect.width + dx);
        let max_y = (rect.y + rect.height).max(rect.y + rect.height + dy);

        let (tx0, ty0) = self.world_to_tile(min_x, min_y);
        let (tx1, ty1) = self.world_to_tile(max_x, max_y);

        let tw = self.tile_width as f32;
        let th = self.tile_height as f32;

        let mut best: Option<SweepResult> = None;

        for ty in ty0..=ty1 {
            for tx in tx0..=tx1 {
                if !self.is_solid(layer, tx, ty) {
                    continue;
                }

                let tile_rect = Rect::new(tx as f32 * tw, ty as f32 * th, tw, th);

                if let Some(result) = sweep_aabb_vs_aabb(rect, dx, dy, tile_rect, tx, ty) {
                    if best.is_none() || result.t < best.as_ref().expect("best is Some when not is_none").t {
                        best = Some(result);
                    }
                }
            }
        }

        best
    }

    // ------------------------------------------------------------------
    // Autotile
    // ------------------------------------------------------------------

    /// Applies 4-bit cardinal autotile rules to every tile on `layer`.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `type_name` — `&str`.
    ///
    /// Bitmask: N=1, E=2, S=4, W=8. A neighbor "matches" if its GID is non-zero.
    pub fn apply_autotile(&mut self, layer: usize, type_name: &str) {
        let (width, height) = match self.layers.get(layer) {
            Some(l) => (l.width, l.height),
            None => return,
        };
        let mut replacements = Vec::new();
        for y in 0..height {
            for x in 0..width {
                if self.get_tile(layer, x, y) == 0 {
                    continue;
                }
                let mask = self.compute_bitmask_4(layer, x, y, width, height);
                if let Some(new_gid) = self.lookup_autotile_4(type_name, mask) {
                    replacements.push((x, y, new_gid));
                }
            }
        }
        for (x, y, gid) in replacements {
            self.set_tile(layer, x, y, gid);
        }
    }

    /// Applies 4-bit cardinal autotile at a single cell and its 3×3 neighborhood.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `type_name` — `&str`.
    pub fn apply_autotile_at(&mut self, layer: usize, x: u32, y: u32, type_name: &str) {
        let (width, height) = match self.layers.get(layer) {
            Some(l) => (l.width, l.height),
            None => return,
        };
        let mut replacements = Vec::new();
        let x_start = x.saturating_sub(1);
        let y_start = y.saturating_sub(1);
        let x_end = (x + 1).min(width - 1);
        let y_end = (y + 1).min(height - 1);
        for ny in y_start..=y_end {
            for nx in x_start..=x_end {
                if self.get_tile(layer, nx, ny) == 0 {
                    continue;
                }
                let mask = self.compute_bitmask_4(layer, nx, ny, width, height);
                if let Some(new_gid) = self.lookup_autotile_4(type_name, mask) {
                    replacements.push((nx, ny, new_gid));
                }
            }
        }
        for (x, y, gid) in replacements {
            self.set_tile(layer, x, y, gid);
        }
    }

    /// Applies 8-bit directional autotile rules to every tile on `layer`.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `type_name` — `&str`.
    ///
    /// Bitmask: N=1, E=2, S=4, W=8, NE=16, SE=32, SW=64, NW=128.
    /// Diagonals only count if both adjacent cardinals are present.
    pub fn apply_autotile_8(&mut self, layer: usize, type_name: &str) {
        let (width, height) = match self.layers.get(layer) {
            Some(l) => (l.width, l.height),
            None => return,
        };
        let mut replacements = Vec::new();
        for y in 0..height {
            for x in 0..width {
                if self.get_tile(layer, x, y) == 0 {
                    continue;
                }
                let mask = self.compute_bitmask_8(layer, x, y, width, height);
                if let Some(new_gid) = self.lookup_autotile_8(type_name, mask) {
                    replacements.push((x, y, new_gid));
                }
            }
        }
        for (x, y, gid) in replacements {
            self.set_tile(layer, x, y, gid);
        }
    }

    /// Applies 8-bit directional autotile at a single cell and its 3×3 neighborhood.
    ///
    /// # Parameters
    /// - `layer` — `usize`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `type_name` — `&str`.
    pub fn apply_autotile_8_at(&mut self, layer: usize, x: u32, y: u32, type_name: &str) {
        let (width, height) = match self.layers.get(layer) {
            Some(l) => (l.width, l.height),
            None => return,
        };
        let mut replacements = Vec::new();
        let x_start = x.saturating_sub(1);
        let y_start = y.saturating_sub(1);
        let x_end = (x + 1).min(width - 1);
        let y_end = (y + 1).min(height - 1);
        for ny in y_start..=y_end {
            for nx in x_start..=x_end {
                if self.get_tile(layer, nx, ny) == 0 {
                    continue;
                }
                let mask = self.compute_bitmask_8(layer, nx, ny, width, height);
                if let Some(new_gid) = self.lookup_autotile_8(type_name, mask) {
                    replacements.push((nx, ny, new_gid));
                }
            }
        }
        for (x, y, gid) in replacements {
            self.set_tile(layer, x, y, gid);
        }
    }

    // ------------------------------------------------------------------
    // Internal autotile helpers
    // ------------------------------------------------------------------

    /// Computes the 4-bit cardinal bitmask for the tile at `(x, y)`.
    fn compute_bitmask_4(&self, layer: usize, x: u32, y: u32, width: u32, height: u32) -> u8 {
        let mut mask = 0u8;
        // N (+1)
        if y > 0 && self.get_tile(layer, x, y - 1) != 0 {
            mask |= 1;
        }
        // E (+2)
        if x + 1 < width && self.get_tile(layer, x + 1, y) != 0 {
            mask |= 2;
        }
        // S (+4)
        if y + 1 < height && self.get_tile(layer, x, y + 1) != 0 {
            mask |= 4;
        }
        // W (+8)
        if x > 0 && self.get_tile(layer, x - 1, y) != 0 {
            mask |= 8;
        }
        mask
    }

    /// Computes the 8-bit directional bitmask for the tile at `(x, y)`.
    fn compute_bitmask_8(&self, layer: usize, x: u32, y: u32, width: u32, height: u32) -> u16 {
        let n = y > 0 && self.get_tile(layer, x, y - 1) != 0;
        let e = x + 1 < width && self.get_tile(layer, x + 1, y) != 0;
        let s = y + 1 < height && self.get_tile(layer, x, y + 1) != 0;
        let w = x > 0 && self.get_tile(layer, x - 1, y) != 0;

        let mut mask: u16 = 0;
        if n {
            mask |= 1;
        }
        if e {
            mask |= 2;
        }
        if s {
            mask |= 4;
        }
        if w {
            mask |= 8;
        }
        // Diagonals only count if both adjacent cardinals are present
        if n && e && y > 0 && x + 1 < width && self.get_tile(layer, x + 1, y - 1) != 0 {
            mask |= 16; // NE
        }
        if s && e && y + 1 < height && x + 1 < width && self.get_tile(layer, x + 1, y + 1) != 0 {
            mask |= 32; // SE
        }
        if s && w && y + 1 < height && x > 0 && self.get_tile(layer, x - 1, y + 1) != 0 {
            mask |= 64; // SW
        }
        if n && w && y > 0 && x > 0 && self.get_tile(layer, x - 1, y - 1) != 0 {
            mask |= 128; // NW
        }
        mask
    }

    /// Looks up a 4-bit autotile rule across all tilesets, returning the global GID.
    fn lookup_autotile_4(&self, type_name: &str, bitmask: u8) -> Option<u32> {
        for ts in &self.tilesets {
            if let Some(local_id) = ts.get_auto_tile_id(type_name, bitmask) {
                return Some(ts.get_first_gid() + local_id);
            }
        }
        None
    }

    /// Looks up an 8-bit autotile rule across all tilesets, returning the global GID.
    fn lookup_autotile_8(&self, type_name: &str, bitmask: u16) -> Option<u32> {
        for ts in &self.tilesets {
            if let Some(local_id) = ts.get_auto_tile_id_8(type_name, bitmask) {
                return Some(ts.get_first_gid() + local_id);
            }
        }
        None
    }


    // ------------------------------------------------------------------
    // Visualization
    // ------------------------------------------------------------------

    /// Render all layers to an image using default colors per tile GID.
    ///
    /// Each tile is drawn as a `tile_size × tile_size` block. Empty tiles
    /// (GID 0) use a dark background, GID 1 uses green, GID 2 darker green,
    /// and object GIDs (≥ 10) are drawn as colored circles. Tile borders are
    /// drawn for the bottom layer.
    ///
    /// # Parameters
    /// - `tile_size` — `u32`. Pixel size of each tile cell.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, tile_size: u32) -> crate::image::ImageData {
        if self.layers.is_empty() {
            return crate::image::ImageData::new(1, 1);
        }
        let lw = self.layers[0].width;
        let lh = self.layers[0].height;
        let mut img = crate::image::ImageData::new(lw * tile_size, lh * tile_size);
        img.fill(20, 20, 30, 255);

        for (li, layer) in self.layers.iter().enumerate() {
            let w = layer.width.min(lw);
            let h = layer.height.min(lh);
            for y in 0..h {
                for x in 0..w {
                    let idx = layer.index(x, y).unwrap_or(0);
                    let gid = layer.tiles[idx];
                    if gid == 0 && li > 0 {
                        continue; // transparent on upper layers
                    }
                    if gid >= 10 {
                        // Object tile — draw as a circle
                        let (r, g, b) = match gid {
                            10 => (200u8, 50, 50),
                            11 => (50, 50, 200),
                            12 => (200, 200, 50),
                            _ => (255, 255, 255),
                        };
                        let cx = (x * tile_size + tile_size / 2) as i32;
                        let cy = (y * tile_size + tile_size / 2) as i32;
                        img.draw_circle(cx, cy, 6, r, g, b, 255);
                    } else {
                        let (r, g, b) = match gid {
                            1 => (80u8, 160, 80),
                            2 => (60, 120, 60),
                            _ => (40, 40, 40),
                        };
                        for py in 0..tile_size {
                            for px in 0..tile_size {
                                img.set_pixel(x * tile_size + px, y * tile_size + py, r, g, b, 255);
                            }
                        }
                        if li == 0 {
                            // Tile border on base layer
                            for px in 0..tile_size {
                                img.set_pixel(x * tile_size + px, y * tile_size, 30, 30, 50, 255);
                            }
                            for py in 0..tile_size {
                                img.set_pixel(x * tile_size, y * tile_size + py, 30, 30, 50, 255);
                            }
                        }
                    }
                }
            }
        }
        img
    }

    /// Generates GPU `RenderCommand`s for the tile map at the given screen offset.
    ///
    /// Each non-empty tile is emitted as a `SetColor + Rectangle(Fill)`.
    /// Uses the same fallback colour table as [`draw_to_image`](Self::draw_to_image)
    /// when no tileset texture is available.
    ///
    /// # Parameters
    /// - `offset_x` — `f32` — Screen X offset.
    /// - `offset_y` — `f32` — Screen Y offset.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn build_render_commands(
        &self,
        offset_x: f32,
        offset_y: f32,
    ) -> Vec<crate::render::renderer::RenderCommand> {
        use crate::render::renderer::{DrawMode, RenderCommand};

        let mut cmds: Vec<RenderCommand> = Vec::new();
        if self.layers.is_empty() {
            return cmds;
        }
        let lw = self.layers[0].width;
        let lh = self.layers[0].height;
        let tw = self.tile_width as f32;
        let th = self.tile_height as f32;

        for (li, layer) in self.layers.iter().enumerate() {
            if !layer.visible {
                continue;
            }
            let w = layer.width.min(lw);
            let h = layer.height.min(lh);
            for y in 0..h {
                for x in 0..w {
                    let idx = layer.index(x, y).unwrap_or(0);
                    let gid = layer.tiles[idx];
                    if gid == 0 && li > 0 {
                        continue;
                    }
                    // Fallback colour by GID (same as draw_to_image)
                    let (r, g, b): (f32, f32, f32) = if gid >= 10 {
                        match gid {
                            10 => (200.0 / 255.0, 50.0 / 255.0, 50.0 / 255.0),
                            11 => (50.0 / 255.0, 50.0 / 255.0, 200.0 / 255.0),
                            12 => (200.0 / 255.0, 200.0 / 255.0, 50.0 / 255.0),
                            _ => (1.0, 1.0, 1.0),
                        }
                    } else {
                        match gid {
                            1 => (80.0 / 255.0, 160.0 / 255.0, 80.0 / 255.0),
                            2 => (60.0 / 255.0, 120.0 / 255.0, 60.0 / 255.0),
                            _ => (40.0 / 255.0, 40.0 / 255.0, 40.0 / 255.0),
                        }
                    };

                    // Apply per-tile tint if present
                    let tint = layer.tile_tints[idx].unwrap_or(layer.tint);
                    cmds.push(RenderCommand::SetColor(
                        r * tint[0],
                        g * tint[1],
                        b * tint[2],
                        tint[3],
                    ));

                    if gid >= 10 {
                        // Object tile — draw as circle
                        let cx = offset_x + x as f32 * tw + tw * 0.5;
                        let cy = offset_y + y as f32 * th + th * 0.5;
                        cmds.push(RenderCommand::Circle {
                            mode: DrawMode::Fill,
                            x: cx,
                            y: cy,
                            r: 6.0,
                        });
                    } else {
                        cmds.push(RenderCommand::Rectangle {
                            mode: DrawMode::Fill,
                            x: offset_x + x as f32 * tw,
                            y: offset_y + y as f32 * th,
                            w: tw,
                            h: th,
                        });
                    }
                }
            }
        }
        cmds
    }

    /// Render a coordinate-mapping diagram: draws the tile grid at the given
    /// image size with world points marked as coloured circles and highlighted
    /// cells.
    ///
    /// # Parameters
    /// - `img_width` — `u32`. Output image width in pixels.
    /// - `img_height` — `u32`. Output image height in pixels.
    /// - `world_points` — `&[(f32, f32, u8, u8, u8)]`. World (x, y) positions
    ///   with RGB colour. Each point is converted to tile coordinates, highlights
    ///   the containing cell, and draws the world position as a circle.
    ///
    /// # Returns
    /// `crate::image::ImageData`.
    pub fn draw_with_highlight_to_image(
        &self,
        img_width: u32,
        img_height: u32,
        world_points: &[(f32, f32, u8, u8, u8)],
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(img_width, img_height);
        img.fill(30, 30, 40, 255);

        // Grid lines at tile_width / tile_height intervals
        let mut x = 0u32;
        while x <= img_width {
            img.draw_line(x as i32, 0, x as i32, img_height as i32 - 1, 60, 60, 80, 255);
            x += self.tile_width;
        }
        let mut y = 0u32;
        while y <= img_height {
            img.draw_line(0, y as i32, img_width as i32 - 1, y as i32, 60, 60, 80, 255);
            y += self.tile_height;
        }

        // Highlight tiles and mark world positions
        for &(wx, wy, r, g, b) in world_points {
            let (tx, ty) = self.world_to_tile(wx, wy);
            let cell_x = tx * self.tile_width;
            let cell_y = ty * self.tile_height;
            img.draw_rect(
                cell_x as i32, cell_y as i32,
                self.tile_width, self.tile_height,
                r, g, b, 128,
            );
            img.draw_circle(wx as i32, wy as i32, 5, r, g, b, 255);
        }

        img
    }

    /// Draw all layers merged with colour-coding per layer.
    ///
    /// Ground tiles are drawn green, decor tiles coloured by tile type,
    /// and a layer count label is added at the bottom.
    ///
    /// # Parameters
    /// - `tile_px` — `u32`. Pixel size per tile.
    /// - `width` — `u32`. Image width.
    /// - `height` — `u32`. Image height.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_layers_to_image(&self, tile_px: u32, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(25, 25, 35, 255);

        let margin = 10i32;
        for layer_idx in 0..self.get_layer_count() {
            let dims = self.get_layer_dimensions(layer_idx);
            let (lw, lh) = dims.unwrap_or((0, 0));
            for y in 0..lh {
                for x in 0..lw {
                    let gid = self.get_tile(layer_idx, x as u32, y as u32);
                    if gid == 0 { continue; }
                    let px = x as i32 * tile_px as i32 + margin;
                    let py = y as i32 * tile_px as i32 + margin;
                    let (r, g, b) = match (layer_idx, gid) {
                        (0, 1) => (40u8, 80, 40),
                        (_, 2) => (120, 80, 60),
                        (_, 3) => (100, 70, 50),
                        (_, 4) => (80, 60, 40),
                        _ => (100, 100, 100),
                    };
                    if layer_idx == 0 {
                        img.draw_rect(px, py, tile_px, tile_px, r, g, b, 255);
                    } else {
                        img.draw_rect(px + 1, py + 1, tile_px.saturating_sub(2), tile_px.saturating_sub(2), r, g, b, 255);
                    }
                }
            }
        }

        let label = format!("{} LAYERS", self.get_layer_count());
        img.draw_label(&label, margin, (height - 20) as i32, 200, 200, 200);
        img.draw_label("TILEMAP LAYERS OK", 80, (height - 20) as i32, 100, 255, 100);
        img
    }


}

// ---------------------------------------------------------------------------
// Swept AABB helper (module-private)
// ---------------------------------------------------------------------------

/// Swept AABB test: moves `mover` by `(dx, dy)` against stationary `target`.
fn sweep_aabb_vs_aabb(
    mover: Rect,
    dx: f32,
    dy: f32,
    target: Rect,
    tile_x: u32,
    tile_y: u32,
) -> Option<SweepResult> {
    // Minkowski expansion: expand target by mover's half-sizes
    let ex = Rect::new(
        target.x - mover.width,
        target.y - mover.height,
        target.width + mover.width,
        target.height + mover.height,
    );

    // Ray from mover's top-left corner
    let origin_x = mover.x;
    let origin_y = mover.y;

    let (t_near_x, t_far_x) = if dx != 0.0 {
        let inv = 1.0 / dx;
        let t1 = (ex.x - origin_x) * inv;
        let t2 = (ex.x + ex.width - origin_x) * inv;
        if t1 < t2 {
            (t1, t2)
        } else {
            (t2, t1)
        }
    } else {
        if origin_x < ex.x || origin_x >= ex.x + ex.width {
            return None;
        }
        (f32::NEG_INFINITY, f32::INFINITY)
    };

    let (t_near_y, t_far_y) = if dy != 0.0 {
        let inv = 1.0 / dy;
        let t1 = (ex.y - origin_y) * inv;
        let t2 = (ex.y + ex.height - origin_y) * inv;
        if t1 < t2 {
            (t1, t2)
        } else {
            (t2, t1)
        }
    } else {
        if origin_y < ex.y || origin_y >= ex.y + ex.height {
            return None;
        }
        (f32::NEG_INFINITY, f32::INFINITY)
    };

    let t_near = t_near_x.max(t_near_y);
    let t_far = t_far_x.min(t_far_y);

    if t_near >= t_far || t_far <= 0.0 || t_near >= 1.0 {
        return None;
    }

    let t = t_near.max(0.0);

    let normal = if t_near_x > t_near_y {
        Vec2::new(if dx > 0.0 { -1.0 } else { 1.0 }, 0.0)
    } else {
        Vec2::new(0.0, if dy > 0.0 { -1.0 } else { 1.0 })
    };

    let contact = Vec2::new(origin_x + dx * t, origin_y + dy * t);

    Some(SweepResult {
        contact_point: contact,
        normal,
        tile_x,
        tile_y,
        t,
    })
}


#[cfg(test)]
mod tests {
    use super::*;
    use crate::tilemap::tileset::TileSet;

    fn make_test_tileset() -> TileSet {
        let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
        ts.set_solid(0, true); // local tile 0 is solid (GID 1)
        ts
    }

    fn make_test_map() -> TileMap {
        let mut map = TileMap::new(32, 32, 8);
        map.add_tileset(make_test_tileset());
        map.add_layer("ground", 10, 10);
        map
    }

    #[test]
    fn layer_add_and_get() {
        let mut map = TileMap::new(32, 32, 8);
        let idx = map.add_layer("bg", 20, 15);
        assert_eq!(idx, 0);
        assert_eq!(map.get_layer_count(), 1);
        assert_eq!(map.get_layer_name(0), Some("bg"));
        assert!(map.get_layer_visible(0));
    }

    #[test]
    fn tile_set_get() {
        let mut map = make_test_map();
        map.set_tile(0, 3, 4, 5);
        assert_eq!(map.get_tile(0, 3, 4), 5);
        assert_eq!(map.get_tile(0, 0, 0), 0); // default
        assert_eq!(map.get_tile(0, 100, 100), 0); // out of bounds
    }

    #[test]
    fn fill_layer() {
        let mut map = make_test_map();
        map.fill(0, 3);
        for y in 0..10 {
            for x in 0..10 {
                assert_eq!(map.get_tile(0, x, y), 3);
            }
        }
    }

    #[test]
    fn clear_tile_sets_zero() {
        let mut map = make_test_map();
        map.set_tile(0, 2, 2, 7);
        assert_eq!(map.get_tile(0, 2, 2), 7);
        map.clear_tile(0, 2, 2);
        assert_eq!(map.get_tile(0, 2, 2), 0);
    }

    #[test]
    fn viewport_set_get() {
        let mut map = make_test_map();
        assert!(map.get_viewport().is_none());
        map.set_viewport(10.0, 20.0, 640.0, 480.0);
        let vp = map.get_viewport().expect("viewport set before use");
        assert!((vp.0 - 10.0).abs() < 1e-5);
        assert!((vp.1 - 20.0).abs() < 1e-5);
        assert!((vp.2 - 640.0).abs() < 1e-5);
        assert!((vp.3 - 480.0).abs() < 1e-5);
    }

    #[test]
    fn world_to_tile_roundtrip() {
        let map = make_test_map();
        let (wx, wy) = map.tile_to_world(3, 5);
        assert!((wx - 96.0).abs() < 1e-5);
        assert!((wy - 160.0).abs() < 1e-5);
        let (tx, ty) = map.world_to_tile(wx, wy);
        assert_eq!(tx, 3);
        assert_eq!(ty, 5);
    }

    #[test]
    fn is_solid_with_tileset() {
        let mut map = make_test_map();
        // GID 1 → tileset first_gid=1, local=0 → solid
        map.set_tile(0, 5, 5, 1);
        assert!(map.is_solid(0, 5, 5));
        // GID 2 → tileset first_gid=1, local=1 → not solid
        map.set_tile(0, 6, 6, 2);
        assert!(!map.is_solid(0, 6, 6));
        // GID 0 → empty
        assert!(!map.is_solid(0, 0, 0));
    }

    #[test]
    fn rect_overlaps_solid_test() {
        let mut map = make_test_map();
        map.set_tile(0, 3, 3, 1); // solid tile at (3,3) = world (96,96)-(128,128)
                                  // Rect overlapping that tile
        assert!(map.rect_overlaps_solid(0, Rect::new(90.0, 90.0, 20.0, 20.0)));
        // Rect not overlapping
        assert!(!map.rect_overlaps_solid(0, Rect::new(0.0, 0.0, 10.0, 10.0)));
    }

    #[test]
    fn sweep_rect_basic() {
        let mut map = make_test_map();
        map.set_tile(0, 5, 0, 1); // solid at world x=160

        // Moving right from x=0 toward solid tile
        let result = map.sweep_rect(0, Rect::new(0.0, 0.0, 16.0, 16.0), 200.0, 0.0);
        assert!(result.is_some());
        let r = result.expect("sweep result is Some");
        assert!(r.t > 0.0 && r.t < 1.0);
        assert!((r.normal.x - (-1.0)).abs() < 1e-5);
        assert_eq!(r.tile_x, 5);
    }

    #[test]
    fn sweep_rect_no_collision() {
        let map = make_test_map(); // no solid tiles
        let result = map.sweep_rect(0, Rect::new(0.0, 0.0, 16.0, 16.0), 100.0, 0.0);
        assert!(result.is_none());
    }

    #[test]
    fn layer_color_offset_parallax() {
        let mut map = make_test_map();
        map.set_layer_color(0, 1.0, 0.5, 0.25, 0.8);
        let c = map.get_layer_color(0);
        assert!((c[0] - 1.0).abs() < 1e-5);
        assert!((c[1] - 0.5).abs() < 1e-5);
        assert!((c[2] - 0.25).abs() < 1e-5);
        assert!((c[3] - 0.8).abs() < 1e-5);

        map.set_layer_offset(0, 10.0, 20.0);
        let o = map.get_layer_offset(0);
        assert!((o.x - 10.0).abs() < 1e-5);
        assert!((o.y - 20.0).abs() < 1e-5);

        map.set_layer_parallax(0, 0.5, 0.75);
        let p = map.get_layer_parallax(0);
        assert!((p.x - 0.5).abs() < 1e-5);
        assert!((p.y - 0.75).abs() < 1e-5);
    }

    #[test]
    fn tileset_management() {
        let mut map = TileMap::new(32, 32, 8);
        assert_eq!(map.get_tileset_count(), 0);
        map.add_tileset(TileSet::new(1, 16, 4, 32, 32, 0, 0));
        assert_eq!(map.get_tileset_count(), 1);
        assert!(map.get_tileset(0).is_some());
        assert!(map.get_tileset(1).is_none());
    }

    #[test]
    fn dimensions() {
        let map = TileMap::new(16, 24, 4);
        assert_eq!(map.get_tile_width(), 16);
        assert_eq!(map.get_tile_height(), 24);
        assert_eq!(map.get_tile_dimensions(), (16, 24));
        assert_eq!(map.get_chunk_size(), 4);
    }

    #[test]
    fn layer_visibility() {
        let mut map = make_test_map();
        assert!(map.get_layer_visible(0));
        map.set_layer_visible(0, false);
        assert!(!map.get_layer_visible(0));
    }

    #[test]
    fn world_to_tile_negative_clamps() {
        let map = make_test_map();
        let (tx, ty) = map.world_to_tile(-10.0, -5.0);
        assert_eq!(tx, 0);
        assert_eq!(ty, 0);
    }

    #[test]
    fn autotile_4bit_basic() {
        // Set up a 3x3 grid of tiles, apply autotile, verify center gets correct mask
        let mut ts = TileSet::new(1, 256, 16, 32, 32, 0, 0);
        // mask 15 (all cardinal neighbors) → local tile 42
        ts.set_auto_tile_rule("wall", 15, 42);
        // mask 5 (N+S only) → local tile 10
        ts.set_auto_tile_rule("wall", 5, 10);

        let mut map = TileMap::new(32, 32, 8);
        map.add_tileset(ts);
        map.add_layer("ground", 3, 3);

        // Fill entire 3x3 with GID 1
        map.fill(0, 1);
        map.apply_autotile(0, "wall");

        // Center (1,1) has all 4 cardinal neighbors → mask=15 → GID = 1+42 = 43
        assert_eq!(map.get_tile(0, 1, 1), 43);
    }

}
