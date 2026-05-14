//! Core tilemap types: `TileMap` with layered `TileLayer` storage, sweep-cast collision, and autotile resolution.
//! Owns tile GID storage, layer visibility/tint/parallax, tileset attachment, autotile bitmask computation,
//! viewport, animation timers, and debug render-command generation.
//! Does not own the render pipeline, physics, or asset loading — these are handled by callers.
//! Depends on `tileset`, `mapgen`, `render`, `image`, `math`, and `log`.

use super::mapgen::MapOrientation;
use super::tileset::TileSet;
use crate::log_msg;
use crate::math::{Rect, Vec2};
use crate::runtime::log_messages::{TM01_TILEMAP_INIT, TM02_TILESET_ADD, TM03_LAYER_ADD};
use std::collections::HashMap;

/// A single tile layer with per-tile GID and optional per-tile tint data.
#[derive(Debug, Clone)]
pub struct TileLayer {
    /// Layer identifier shown in editors and log messages.
    pub name: String,
    /// Tile count along the X axis.
    pub width: u32,
    /// Tile count along the Y axis.
    pub height: u32,
    /// Whether this layer is included in render-command output.
    pub visible: bool,
    /// Multiplicative tint `[r, g, b, a]` applied to every tile in the layer.
    pub tint: [f32; 4],
    /// World-space draw offset applied to this layer.
    pub offset: Vec2,
    /// Per-axis parallax scroll factor; `(1, 1)` = full scroll, `(0, 0)` = fixed.
    pub parallax: Vec2,
    /// Flat GID array in row-major order; `0` means empty.
    tiles: Vec<u32>,
    /// Optional per-tile tint override; `None` falls back to `tint`.
    tile_tints: Vec<Option<[f32; 4]>>,
}
impl TileLayer {
    /// Create a fully-empty `TileLayer` of `width × height` tiles with all GIDs set to `0`.
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
    /// Convert `(x, y)` into a flat index; returns `None` when out of bounds.
    fn index(&self, x: u32, y: u32) -> Option<usize> {
        if x < self.width && y < self.height {
            Some((y * self.width + x) as usize)
        } else {
            None
        }
    }
}
/// Result of a continuous sweep-cast between a moving AABB and a tile AABB.
#[derive(Debug, Clone, Copy)]
pub struct SweepResult {
    /// World-space contact point at the moment of first collision.
    pub contact_point: Vec2,
    /// Surface normal at the collision face.
    pub normal: Vec2,
    /// Grid X coordinate of the hit tile.
    pub tile_x: u32,
    /// Grid Y coordinate of the hit tile.
    pub tile_y: u32,
    /// Normalized time of impact in [0, 1] along the displacement vector.
    pub t: f32,
}
/// Multi-layer tile map with tileset attachment, collision, autotile, animation, and debug rendering.
#[derive(Debug, Clone)]
pub struct TileMap {
    /// Width of each tile in pixels.
    tile_width: u32,
    /// Height of each tile in pixels.
    tile_height: u32,
    /// Chunk size used by the streaming chunk sub-system.
    chunk_size: u32,
    /// World-space coordinate interpretation (TopDown, Isometric, Hex, etc.).
    orientation: MapOrientation,
    /// Ordered list of tilesets attached to this map.
    tilesets: Vec<TileSet>,
    /// Ordered list of tile layers.
    layers: Vec<TileLayer>,
    /// Per-layer GID-to-position reverse index for fast `find_tiles_by_gid`.
    tile_type_index_cache: Vec<HashMap<u32, Vec<(u32, u32)>>>,
    /// Optional viewport rect for camera-culled render-command generation.
    viewport: Option<Rect>,
    /// Per-GID animation state `(frame_index, elapsed_ms)`.
    anim_timers: HashMap<u32, (usize, f32)>,
}
impl TileMap {
    /// Create an empty `TileMap` with the given tile dimensions and chunk size.
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
            tile_type_index_cache: Vec::new(),
            viewport: None,
            anim_timers: HashMap::new(),
        }
    }
    /// Append a tileset and take ownership; called during map load or runtime attachment.
    pub fn add_tileset(&mut self, ts: TileSet) {
        log_msg!(debug, TM02_TILESET_ADD);
        self.tilesets.push(ts);
    }
    /// Return the tileset at `index`, or `None` when out of range.
    pub fn get_tileset(&self, index: usize) -> Option<&TileSet> {
        self.tilesets.get(index)
    }
    /// Return the number of attached tilesets.
    pub fn get_tileset_count(&self) -> usize {
        self.tilesets.len()
    }
    /// Add a new empty layer of `width × height` tiles; return its layer index.
    pub fn add_layer(&mut self, name: &str, width: u32, height: u32) -> usize {
        log_msg!(debug, TM03_LAYER_ADD, "{}", name);
        self.layers.push(TileLayer::new(name, width, height));
        self.tile_type_index_cache.push(HashMap::new());
        self.layers.len() - 1
    }
    /// Return the total number of layers.
    pub fn get_layer_count(&self) -> usize {
        self.layers.len()
    }
    /// Return the name of layer `idx`, or `None` when out of range.
    pub fn get_layer_name(&self, idx: usize) -> Option<&str> {
        self.layers.get(idx).map(|l| l.name.as_str())
    }
    /// Set the visibility flag on layer `idx`; no-op when out of range.
    pub fn set_layer_visible(&mut self, idx: usize, visible: bool) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.visible = visible;
        }
    }
    /// Return `true` when layer `idx` is visible; returns `false` when out of range.
    pub fn get_layer_visible(&self, idx: usize) -> bool {
        self.layers.get(idx).is_some_and(|l| l.visible)
    }
    /// Set the tint RGBA of layer `idx`; no-op when out of range.
    pub fn set_layer_color(&mut self, idx: usize, r: f32, g: f32, b: f32, a: f32) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.tint = [r, g, b, a];
        }
    }
    /// Return the tint `[r, g, b, a]` of layer `idx`; returns `[0; 4]` when out of range.
    pub fn get_layer_color(&self, idx: usize) -> [f32; 4] {
        self.layers.get(idx).map_or([0.0; 4], |l| l.tint)
    }
    /// Set the world-space draw offset `(ox, oy)` of layer `idx`; no-op when out of range.
    pub fn set_layer_offset(&mut self, idx: usize, ox: f32, oy: f32) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.offset = Vec2::new(ox, oy);
        }
    }
    /// Return the draw offset of layer `idx`; returns `Vec2::ZERO` when out of range.
    pub fn get_layer_offset(&self, idx: usize) -> Vec2 {
        self.layers.get(idx).map_or(Vec2::ZERO, |l| l.offset)
    }
    /// Set the parallax factor `(px, py)` of layer `idx`; no-op when out of range.
    pub fn set_layer_parallax(&mut self, idx: usize, px: f32, py: f32) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.parallax = Vec2::new(px, py);
        }
    }
    /// Return the parallax factor of layer `idx`; returns `(1, 1)` when out of range.
    pub fn get_layer_parallax(&self, idx: usize) -> Vec2 {
        self.layers
            .get(idx)
            .map_or(Vec2::new(1.0, 1.0), |l| l.parallax)
    }
    /// Return the `(width, height)` tile dimensions of layer `idx`, or `None` when out of range.
    pub fn get_layer_dimensions(&self, idx: usize) -> Option<(u32, u32)> {
        self.layers.get(idx).map(|l| (l.width, l.height))
    }
    /// Write GID `gid` at `(x, y)` in layer `layer`; updates the type-index cache; no-op when out of bounds.
    pub fn set_tile(&mut self, layer: usize, x: u32, y: u32, gid: u32) {
        if let Some(l) = self.layers.get_mut(layer) {
            if let Some(idx) = l.index(x, y) {
                let old_gid = l.tiles[idx];
                l.tiles[idx] = gid;
                if let Some(layer_index) = self.tile_type_index_cache.get_mut(layer) {
                    if old_gid != 0 {
                        remove_pos_from_gid(layer_index, old_gid, x, y);
                    }
                    if gid != 0 {
                        layer_index.entry(gid).or_default().push((x, y));
                    }
                }
            }
        }
    }
    /// Return the GID at `(x, y)` in layer `layer`; returns `0` when out of bounds.
    pub fn get_tile(&self, layer: usize, x: u32, y: u32) -> u32 {
        if let Some(l) = self.layers.get(layer) {
            if let Some(idx) = l.index(x, y) {
                return l.tiles[idx];
            }
        }
        0
    }
    #[allow(clippy::too_many_arguments)]
    /// Set a per-tile RGBA tint override at `(x, y)` in `layer`; no-op when out of bounds.
    pub fn set_tile_tint(&mut self, layer: usize, x: u32, y: u32, r: f32, g: f32, b: f32, a: f32) {
        if let Some(l) = self.layers.get_mut(layer) {
            if let Some(idx) = l.index(x, y) {
                l.tile_tints[idx] = Some([r, g, b, a]);
            }
        }
    }
    /// Set the tile at `(x, y)` in `layer` to GID `0`; updates the type-index cache.
    pub fn clear_tile(&mut self, layer: usize, x: u32, y: u32) {
        self.set_tile(layer, x, y, 0);
    }
    /// Fill all tiles in `layer` with `gid`; rebuilds the type-index cache for that layer.
    pub fn fill(&mut self, layer: usize, gid: u32) {
        if let Some(l) = self.layers.get_mut(layer) {
            for tile in l.tiles.iter_mut() {
                *tile = gid;
            }
            if let Some(layer_index) = self.tile_type_index_cache.get_mut(layer) {
                layer_index.clear();
                if gid != 0 {
                    let mut positions = Vec::with_capacity((l.width * l.height) as usize);
                    for y in 0..l.height {
                        for x in 0..l.width {
                            positions.push((x, y));
                        }
                    }
                    layer_index.insert(gid, positions);
                }
            }
        }
    }
    /// Return a copy of the GID-to-positions index for `layer`; empty map when out of range.
    pub fn tile_type_index(&self, layer: usize) -> HashMap<u32, Vec<(u32, u32)>> {
        self.tile_type_index_cache
            .get(layer)
            .cloned()
            .unwrap_or_default()
    }
    /// Return all `(x, y)` positions for tiles matching `gid` in `layer`; empty vec when not found.
    pub fn find_tiles_by_gid(&self, layer: usize, gid: u32) -> Vec<(u32, u32)> {
        self.tile_type_index_cache
            .get(layer)
            .and_then(|idx| idx.get(&gid).cloned())
            .unwrap_or_default()
    }
    /// Set the active camera viewport rect; enables culled render-command generation.
    pub fn set_viewport(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport = Some(Rect::new(x, y, w, h));
    }
    /// Return the viewport as `(x, y, w, h)`, or `None` when not set.
    pub fn get_viewport(&self) -> Option<(f32, f32, f32, f32)> {
        self.viewport.map(|v| (v.x, v.y, v.width, v.height))
    }
    /// Advance all GID animation timers by `dt` seconds; updates frame indices for each animated tileset.
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
    /// Convert world position `(wx, wy)` to tile grid coordinates; clamps negative values to `0`.
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
    /// Convert tile grid coordinates `(tx, ty)` to world-space top-left pixel position.
    pub fn tile_to_world(&self, tx: u32, ty: u32) -> (f32, f32) {
        (
            tx as f32 * self.tile_width as f32,
            ty as f32 * self.tile_height as f32,
        )
    }
    /// Return tile width in pixels.
    pub fn get_tile_width(&self) -> u32 {
        self.tile_width
    }
    /// Return tile height in pixels.
    pub fn get_tile_height(&self) -> u32 {
        self.tile_height
    }
    /// Return tile dimensions as `(width, height)` in pixels.
    pub fn get_tile_dimensions(&self) -> (u32, u32) {
        (self.tile_width, self.tile_height)
    }
    /// Return the streaming chunk size.
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }
    /// Return the map orientation.
    pub fn get_orientation(&self) -> MapOrientation {
        self.orientation
    }
    /// Set the map orientation.
    pub fn set_orientation(&mut self, orientation: MapOrientation) {
        self.orientation = orientation;
    }
    /// Resolve global GID `gid` to a `(tileset_index, local_id)` pair; returns `None` for GID `0` or unknown GIDs.
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
    /// Return `true` when the tile at `(x, y)` in `layer` is marked solid in its tileset.
    pub fn is_solid(&self, layer: usize, x: u32, y: u32) -> bool {
        let gid = self.get_tile(layer, x, y);
        if let Some((ts_idx, local_id)) = self.resolve_gid(gid) {
            self.tilesets[ts_idx].is_solid(local_id)
        } else {
            false
        }
    }
    /// Return `true` when any tile overlapped by `rect` in `layer` is solid.
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
    /// Continuous AABB sweep through solid tiles in `layer` along `(dx, dy)`; returns the earliest hit or `None`.
    pub fn sweep_rect(&self, layer: usize, rect: Rect, dx: f32, dy: f32) -> Option<SweepResult> {
        if dx == 0.0 && dy == 0.0 {
            return None;
        }
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
                    if best.is_none()
                        || result.t < best.as_ref().expect("best is Some when not is_none").t
                    {
                        best = Some(result);
                    }
                }
            }
        }
        best
    }
    /// Apply 4-neighbour autotile GID substitution to all non-empty tiles in `layer` matching `type_name`.
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
    /// Apply 4-neighbour autotile substitution to the 3×3 neighbourhood around `(x, y)` only.
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
    /// Apply 8-neighbour autotile GID substitution to all non-empty tiles in `layer` matching `type_name`.
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
    /// Apply 8-neighbour autotile substitution to the 3×3 neighbourhood around `(x, y)` only.
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
    /// Compute the 4-bit cardinal-neighbour bitmask for `(x, y)` in `layer`; bits: N=1, E=2, S=4, W=8.
    fn compute_bitmask_4(&self, layer: usize, x: u32, y: u32, width: u32, height: u32) -> u8 {
        let mut mask = 0u8;
        if y > 0 && self.get_tile(layer, x, y - 1) != 0 {
            mask |= 1;
        }
        if x + 1 < width && self.get_tile(layer, x + 1, y) != 0 {
            mask |= 2;
        }
        if y + 1 < height && self.get_tile(layer, x, y + 1) != 0 {
            mask |= 4;
        }
        if x > 0 && self.get_tile(layer, x - 1, y) != 0 {
            mask |= 8;
        }
        mask
    }
    /// Compute the 8-bit full-neighbour bitmask for `(x, y)` in `layer`; cardinals=1..8, diagonals=16..128.
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
        if n && e && y > 0 && x + 1 < width && self.get_tile(layer, x + 1, y - 1) != 0 {
            mask |= 16;
        }
        if s && e && y + 1 < height && x + 1 < width && self.get_tile(layer, x + 1, y + 1) != 0 {
            mask |= 32;
        }
        if s && w && y + 1 < height && x > 0 && self.get_tile(layer, x - 1, y + 1) != 0 {
            mask |= 64;
        }
        if n && w && y > 0 && x > 0 && self.get_tile(layer, x - 1, y - 1) != 0 {
            mask |= 128;
        }
        mask
    }
    /// Search all tilesets for a 4-bit autotile match for `type_name` and `bitmask`; returns the global GID or `None`.
    fn lookup_autotile_4(&self, type_name: &str, bitmask: u8) -> Option<u32> {
        for ts in &self.tilesets {
            if let Some(local_id) = ts.get_auto_tile_id(type_name, bitmask) {
                return Some(ts.get_first_gid() + local_id);
            }
        }
        None
    }
    /// Search all tilesets for an 8-bit autotile match for `type_name` and `bitmask`; returns the global GID or `None`.
    fn lookup_autotile_8(&self, type_name: &str, bitmask: u16) -> Option<u32> {
        for ts in &self.tilesets {
            if let Some(local_id) = ts.get_auto_tile_id_8(type_name, bitmask) {
                return Some(ts.get_first_gid() + local_id);
            }
        }
        None
    }
    /// Render all layers to an `ImageData` using the debug color palette; `tile_size` is the render pixel size per tile.
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
                        continue;
                    }
                    if gid >= 10 {
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
    /// Build a flat `RenderCommand` list for all visible layers using the debug color palette and `offset`.
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
                    let tint = layer.tile_tints[idx].unwrap_or(layer.tint);
                    cmds.push(RenderCommand::SetColor(
                        r * tint[0],
                        g * tint[1],
                        b * tint[2],
                        tint[3],
                    ));
                    if gid >= 10 {
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
    /// Render world-space highlight points and a grid overlay into an `ImageData` of `img_width × img_height`.
    pub fn draw_with_highlight_to_image(
        &self,
        img_width: u32,
        img_height: u32,
        world_points: &[(f32, f32, u8, u8, u8)],
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(img_width, img_height);
        img.fill(30, 30, 40, 255);
        let mut x = 0u32;
        while x <= img_width {
            img.draw_line(
                x as i32,
                0,
                x as i32,
                img_height as i32 - 1,
                60,
                60,
                80,
                255,
            );
            x += self.tile_width;
        }
        let mut y = 0u32;
        while y <= img_height {
            img.draw_line(0, y as i32, img_width as i32 - 1, y as i32, 60, 60, 80, 255);
            y += self.tile_height;
        }
        for &(wx, wy, r, g, b) in world_points {
            let (tx, ty) = self.world_to_tile(wx, wy);
            let cell_x = tx * self.tile_width;
            let cell_y = ty * self.tile_height;
            img.draw_rect(
                cell_x as i32,
                cell_y as i32,
                self.tile_width,
                self.tile_height,
                r,
                g,
                b,
                128,
            );
            img.draw_circle(wx as i32, wy as i32, 5, r, g, b, 255);
        }
        img
    }
    /// Render all layers side-by-side with colour-coded GIDs into an `ImageData` of `width × height` pixels.
    pub fn draw_layers_to_image(
        &self,
        tile_px: u32,
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(25, 25, 35, 255);
        let margin = 10i32;
        for layer_idx in 0..self.get_layer_count() {
            let dims = self.get_layer_dimensions(layer_idx);
            let (lw, lh) = dims.unwrap_or((0, 0));
            for y in 0..lh {
                for x in 0..lw {
                    let gid = self.get_tile(layer_idx, x, y);
                    if gid == 0 {
                        continue;
                    }
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
                        img.draw_rect(
                            px + 1,
                            py + 1,
                            tile_px.saturating_sub(2),
                            tile_px.saturating_sub(2),
                            r,
                            g,
                            b,
                            255,
                        );
                    }
                }
            }
        }
        let label = format!("{} LAYERS", self.get_layer_count());
        img.draw_label(&label, margin, (height - 20) as i32, 200, 200, 200);
        img.draw_label("TILEMAP LAYERS OK", 80, (height - 20) as i32, 100, 255, 100);
        img
    }
    /// Convert a layer to a boolean walkability grid; `walkable_gids` are treated as passable, GID `0` is always passable.
    pub fn to_nav_grid(&self, layer: usize, walkable_gids: &[u32]) -> Vec<Vec<bool>> {
        let (width, height) = self.get_layer_dimensions(layer).unwrap_or((0, 0));
        let mut grid: Vec<Vec<bool>> = Vec::with_capacity(height as usize);
        for y in 0..height {
            let mut row: Vec<bool> = Vec::with_capacity(width as usize);
            for x in 0..width {
                let gid = self.get_tile(layer, x, y);
                let walkable = gid == 0 || walkable_gids.contains(&gid);
                row.push(walkable);
            }
            grid.push(row);
        }
        grid
    }
}
/// Remove position `(x, y)` from the GID entry in `layer_index`; removes the key entirely when the list becomes empty.
fn remove_pos_from_gid(layer_index: &mut HashMap<u32, Vec<(u32, u32)>>, gid: u32, x: u32, y: u32) {
    if let Some(list) = layer_index.get_mut(&gid) {
        if let Some(pos_idx) = list.iter().position(|&(px, py)| px == x && py == y) {
            list.swap_remove(pos_idx);
        }
        if list.is_empty() {
            layer_index.remove(&gid);
        }
    }
}
/// Swept AABB-vs-AABB narrow-phase test; returns a `SweepResult` when the expanded target is hit in `[0, 1)`, or `None`.
fn sweep_aabb_vs_aabb(
    mover: Rect,
    dx: f32,
    dy: f32,
    target: Rect,
    tile_x: u32,
    tile_y: u32,
) -> Option<SweepResult> {
    let ex = Rect::new(
        target.x - mover.width,
        target.y - mover.height,
        target.width + mover.width,
        target.height + mover.height,
    );
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
