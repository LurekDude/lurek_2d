//! Tileset definition: per-tile quad lookup, solid flags, frame animations, and autotile rule tables.
//! Owns `TileSet` and `TileAnimFrame`; used by `TileMap` to resolve GIDs to UV rects and collision flags.
//! Does not own rendering or the tileset image; callers use quads from `get_quad` for draw calls.
//! Depends on `math`, `log`, and `runtime::log_messages`.

use crate::log_msg;
use crate::math::Rect;
use crate::runtime::log_messages::{TS01, TS02, TS03};
use std::collections::HashMap;

/// A single frame in a tile sprite-sheet animation.
#[derive(Debug, Clone)]
pub struct TileAnimFrame {
    /// Local tile ID this frame displays.
    pub tile_id: u32,
    /// How long this frame is shown in milliseconds.
    pub duration_ms: f32,
}

/// A tileset slice of a sprite-sheet texture with collision, animation, and autotile data.
#[derive(Debug, Clone)]
pub struct TileSet {
    /// First global GID owned by this tileset; used to map GIDs to local IDs.
    first_gid: u32,
    /// Total number of tiles in the tileset.
    tile_count: u32,
    /// Number of tile columns in the source image.
    columns: u32,
    /// Width of each tile in pixels.
    tile_width: u32,
    /// Height of each tile in pixels.
    tile_height: u32,
    /// Pixel gap between tiles in the source image.
    spacing: u32,
    /// Pixel margin around the edge of the source image.
    margin: u32,
    /// Solid flag per local tile ID; indexed by local ID, absent entries are `false`.
    solids: Vec<bool>,
    /// Frame animation sequences keyed by local tile ID.
    animations: HashMap<u32, Vec<TileAnimFrame>>,
    /// 4-bit autotile rules: `(type_name, bitmask) -> local_tile_id`.
    auto_rules_4: HashMap<(String, u8), u32>,
    /// 8-bit autotile rules: `(type_name, bitmask) -> local_tile_id`.
    auto_rules_8: HashMap<(String, u16), u32>,
}
impl TileSet {
    /// Create a `TileSet` with the given layout parameters and empty solid, animation, and autotile tables.
    pub fn new(
        first_gid: u32,
        tile_count: u32,
        columns: u32,
        tile_width: u32,
        tile_height: u32,
        spacing: u32,
        margin: u32,
    ) -> Self {
        log_msg!(debug, TS01, "first_gid={} tiles={}", first_gid, tile_count);
        Self {
            first_gid,
            tile_count,
            columns,
            tile_width,
            tile_height,
            spacing,
            margin,
            solids: Vec::new(),
            animations: HashMap::new(),
            auto_rules_4: HashMap::new(),
            auto_rules_8: HashMap::new(),
        }
    }
    /// Return the first global GID owned by this tileset.
    pub fn get_first_gid(&self) -> u32 {
        self.first_gid
    }
    /// Return the total tile count.
    pub fn get_tile_count(&self) -> u32 {
        self.tile_count
    }
    /// Return the number of tile columns in the source image.
    pub fn get_columns(&self) -> u32 {
        self.columns
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
    /// Return pixel spacing between tiles in the source image.
    pub fn get_spacing(&self) -> u32 {
        self.spacing
    }
    /// Return pixel margin around the source image edge.
    pub fn get_margin(&self) -> u32 {
        self.margin
    }
    /// Return the source-image `Rect` (in pixels) for `local_tile_id`.
    pub fn get_quad(&self, local_tile_id: u32) -> Rect {
        let col = local_tile_id % self.columns;
        let row = local_tile_id / self.columns;
        let x = self.margin + col * (self.tile_width + self.spacing);
        let y = self.margin + row * (self.tile_height + self.spacing);
        Rect::new(
            x as f32,
            y as f32,
            self.tile_width as f32,
            self.tile_height as f32,
        )
    }
    /// Register or replace the animation frame sequence for `local_tile_id`.
    pub fn set_animation(&mut self, local_tile_id: u32, frames: Vec<TileAnimFrame>) {
        log_msg!(
            debug,
            TS02,
            "tile={} frames={}",
            local_tile_id,
            frames.len()
        );
        self.animations.insert(local_tile_id, frames);
    }
    /// Return the animation frames for `local_tile_id`, or `None` when not animated.
    pub fn get_animation(&self, local_tile_id: u32) -> Option<&Vec<TileAnimFrame>> {
        self.animations.get(&local_tile_id)
    }
    /// Set or clear the solid flag for `local_tile_id`; grows the solids vec as needed.
    pub fn set_solid(&mut self, local_tile_id: u32, solid: bool) {
        log_msg!(trace, TS03, "tile={} solid={}", local_tile_id, solid);
        let idx = local_tile_id as usize;
        if idx >= self.solids.len() {
            self.solids.resize(idx + 1, false);
        }
        self.solids[idx] = solid;
    }
    /// Return `true` when `local_tile_id` is marked solid; returns `false` for IDs beyond the solids vec.
    pub fn is_solid(&self, local_tile_id: u32) -> bool {
        let idx = local_tile_id as usize;
        if idx < self.solids.len() {
            self.solids[idx]
        } else {
            false
        }
    }
    /// Register a 4-bit autotile rule mapping `(type_name, bitmask)` to `local_tile_id`.
    pub fn set_auto_tile_rule(&mut self, type_name: &str, bitmask: u8, local_tile_id: u32) {
        self.auto_rules_4
            .insert((type_name.to_string(), bitmask), local_tile_id);
    }
    /// Look up the 4-bit autotile local ID for `(type_name, bitmask)`, or `None` when no rule matches.
    pub fn get_auto_tile_id(&self, type_name: &str, bitmask: u8) -> Option<u32> {
        self.auto_rules_4
            .get(&(type_name.to_string(), bitmask))
            .copied()
    }
    /// Register an 8-bit autotile rule mapping `(type_name, bitmask)` to `local_tile_id`.
    pub fn set_auto_tile_rule_8(&mut self, type_name: &str, bitmask: u16, local_tile_id: u32) {
        self.auto_rules_8
            .insert((type_name.to_string(), bitmask), local_tile_id);
    }
    /// Look up the 8-bit autotile local ID for `(type_name, bitmask)`, or `None` when no rule matches.
    pub fn get_auto_tile_id_8(&self, type_name: &str, bitmask: u16) -> Option<u32> {
        self.auto_rules_8
            .get(&(type_name.to_string(), bitmask))
            .copied()
    }
}
