//! Tile set backed by a texture atlas with animation, solid flags, and autotile rules.
//!
//! This module is part of Luna2D's `tilemap` subsystem and provides the implementation
//! details for tileset-related operations and data management.
//! Key types exported from this module: `TileAnimFrame`, `TileSet`.
//! Primary functions: `new()`, `get_first_gid()`, `get_tile_count()`, `get_columns()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

use crate::math::Rect;

/// A single frame in a tile animation sequence.
///
/// # Fields
/// - `tile_id` — `u32`.
/// - `duration_ms` — `f32`.
#[derive(Debug, Clone)]
pub struct TileAnimFrame {
    /// 0-based local tile ID within the tileset.
    pub tile_id: u32,
    /// Duration of this frame in milliseconds.
    pub duration_ms: f32,
}

/// A tile set that maps local tile IDs to atlas regions, animations, and collision flags.
///
/// Tile IDs are 0-based within the set. The `first_gid` maps this set into the global
/// GID space used by [`super::TileMap`].
///
/// # Fields
/// - `first_gid` — `u32`.
/// - `tile_count` — `u32`.
/// - `columns` — `u32`.
/// - `tile_width` — `u32`.
/// - `tile_height` — `u32`.
/// - `spacing` — `u32`.
/// - `margin` — `u32`.
/// - `solids` — `Vec<bool>`.
/// - `animations` — `HashMap<u32`.
/// - `auto_rules_4` — `HashMap<(String`.
/// - `auto_rules_8` — `HashMap<(String`.
#[derive(Debug, Clone)]
pub struct TileSet {
    first_gid: u32,
    tile_count: u32,
    columns: u32,
    tile_width: u32,
    tile_height: u32,
    spacing: u32,
    margin: u32,
    solids: Vec<bool>,
    animations: HashMap<u32, Vec<TileAnimFrame>>,
    auto_rules_4: HashMap<(String, u8), u32>,
    auto_rules_8: HashMap<(String, u16), u32>,
}

impl TileSet {
    /// Creates a new tile set with the given atlas layout parameters.
    ///
    /// # Parameters
    /// - `first_gid` — `u32`.
    /// - `tile_count` — `u32`.
    /// - `columns` — `u32`.
    /// - `tile_width` — `u32`.
    /// - `tile_height` — `u32`.
    /// - `spacing` — `u32`.
    /// - `margin` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// All tile IDs start at `first_gid` in the global GID namespace.
    pub fn new(
        first_gid: u32,
        tile_count: u32,
        columns: u32,
        tile_width: u32,
        tile_height: u32,
        spacing: u32,
        margin: u32,
    ) -> Self {
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

    /// Returns the first global ID assigned to this tileset.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_first_gid(&self) -> u32 {
        self.first_gid
    }

    /// Returns the total number of tiles in this tileset.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tile_count(&self) -> u32 {
        self.tile_count
    }

    /// Returns the number of tile columns in the atlas texture.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_columns(&self) -> u32 {
        self.columns
    }

    /// Returns the width of a single tile in pixels.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tile_width(&self) -> u32 {
        self.tile_width
    }

    /// Returns the height of a single tile in pixels.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tile_height(&self) -> u32 {
        self.tile_height
    }

    /// Returns the tile dimensions as `(width, height)`.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_tile_dimensions(&self) -> (u32, u32) {
        (self.tile_width, self.tile_height)
    }

    /// Returns the spacing in pixels between tiles in the atlas.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_spacing(&self) -> u32 {
        self.spacing
    }

    /// Returns the margin in pixels around the edges of the atlas.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_margin(&self) -> u32 {
        self.margin
    }

    /// Computes the atlas source rectangle for a 0-based local tile ID.
    ///
    /// # Parameters
    /// - `local_tile_id` — `u32`.
    ///
    /// # Returns
    /// `Rect`.
    ///
    /// Layout: column = tile_id % columns, row = tile_id / columns.
    /// Position accounts for margin and spacing.
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

    /// Sets the animation frames for a local tile ID.
    ///
    /// # Parameters
    /// - `local_tile_id` — `u32`.
    /// - `frames` — `Vec<TileAnimFrame>`.
    pub fn set_animation(&mut self, local_tile_id: u32, frames: Vec<TileAnimFrame>) {
        self.animations.insert(local_tile_id, frames);
    }

    /// Returns the animation frames for a local tile ID, if any.
    ///
    /// # Parameters
    /// - `local_tile_id` — `u32`.
    ///
    /// # Returns
    /// `Option<&Vec<TileAnimFrame>>`.
    pub fn get_animation(&self, local_tile_id: u32) -> Option<&Vec<TileAnimFrame>> {
        self.animations.get(&local_tile_id)
    }

    /// Sets whether a local tile ID is solid for collision purposes.
    ///
    /// # Parameters
    /// - `local_tile_id` — `u32`.
    /// - `solid` — `bool`.
    ///
    /// Automatically expands the internal solids vector if needed.
    pub fn set_solid(&mut self, local_tile_id: u32, solid: bool) {
        let idx = local_tile_id as usize;
        if idx >= self.solids.len() {
            self.solids.resize(idx + 1, false);
        }
        self.solids[idx] = solid;
    }

    /// Returns whether a local tile ID is solid. Out-of-bounds IDs return `false`.
    ///
    /// # Parameters
    /// - `local_tile_id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_solid(&self, local_tile_id: u32) -> bool {
        let idx = local_tile_id as usize;
        if idx < self.solids.len() {
            self.solids[idx]
        } else {
            false
        }
    }

    /// Registers a 4-bit cardinal autotile rule mapping a bitmask to a local tile ID.
    ///
    /// # Parameters
    /// - `type_name` — `&str`.
    /// - `bitmask` — `u8`.
    /// - `local_tile_id` — `u32`.
    ///
    /// Bitmask bits: N=1, E=2, S=4, W=8.
    pub fn set_auto_tile_rule(&mut self, type_name: &str, bitmask: u8, local_tile_id: u32) {
        self.auto_rules_4
            .insert((type_name.to_string(), bitmask), local_tile_id);
    }

    /// Looks up the local tile ID for a 4-bit cardinal autotile bitmask.
    ///
    /// # Parameters
    /// - `type_name` — `&str`.
    /// - `bitmask` — `u8`.
    ///
    /// # Returns
    /// `Option<u32>`.
    pub fn get_auto_tile_id(&self, type_name: &str, bitmask: u8) -> Option<u32> {
        self.auto_rules_4
            .get(&(type_name.to_string(), bitmask))
            .copied()
    }

    /// Registers an 8-bit directional autotile rule mapping a bitmask to a local tile ID.
    ///
    /// # Parameters
    /// - `type_name` — `&str`.
    /// - `bitmask` — `u16`.
    /// - `local_tile_id` — `u32`.
    ///
    /// Bitmask bits: N=1, E=2, S=4, W=8, NE=16, SE=32, SW=64, NW=128.
    pub fn set_auto_tile_rule_8(&mut self, type_name: &str, bitmask: u16, local_tile_id: u32) {
        self.auto_rules_8
            .insert((type_name.to_string(), bitmask), local_tile_id);
    }

    /// Looks up the local tile ID for an 8-bit directional autotile bitmask.
    ///
    /// # Parameters
    /// - `type_name` — `&str`.
    /// - `bitmask` — `u16`.
    ///
    /// # Returns
    /// `Option<u32>`.
    pub fn get_auto_tile_id_8(&self, type_name: &str, bitmask: u16) -> Option<u32> {
        self.auto_rules_8
            .get(&(type_name.to_string(), bitmask))
            .copied()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn quad_no_spacing_no_margin() {
        let ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
        let q = ts.get_quad(0);
        assert!((q.x - 0.0).abs() < 1e-5);
        assert!((q.y - 0.0).abs() < 1e-5);
        assert!((q.width - 32.0).abs() < 1e-5);
        assert!((q.height - 32.0).abs() < 1e-5);

        let q5 = ts.get_quad(5); // col=1, row=1
        assert!((q5.x - 32.0).abs() < 1e-5);
        assert!((q5.y - 32.0).abs() < 1e-5);
    }

    #[test]
    fn quad_with_spacing_and_margin() {
        let ts = TileSet::new(1, 16, 4, 32, 32, 2, 4);
        // tile 0: x = 4, y = 4
        let q0 = ts.get_quad(0);
        assert!((q0.x - 4.0).abs() < 1e-5);
        assert!((q0.y - 4.0).abs() < 1e-5);

        // tile 1: col=1, row=0 → x = 4 + 1*(32+2) = 38
        let q1 = ts.get_quad(1);
        assert!((q1.x - 38.0).abs() < 1e-5);
        assert!((q1.y - 4.0).abs() < 1e-5);

        // tile 4: col=0, row=1 → y = 4 + 1*(32+2) = 38
        let q4 = ts.get_quad(4);
        assert!((q4.x - 4.0).abs() < 1e-5);
        assert!((q4.y - 38.0).abs() < 1e-5);
    }

    #[test]
    fn solid_flag_get_set() {
        let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
        assert!(!ts.is_solid(0));
        assert!(!ts.is_solid(100)); // out of bounds

        ts.set_solid(5, true);
        assert!(ts.is_solid(5));
        assert!(!ts.is_solid(4));

        ts.set_solid(5, false);
        assert!(!ts.is_solid(5));
    }

    #[test]
    fn animation_get_set() {
        let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
        assert!(ts.get_animation(0).is_none());

        let frames = vec![
            TileAnimFrame {
                tile_id: 0,
                duration_ms: 100.0,
            },
            TileAnimFrame {
                tile_id: 1,
                duration_ms: 200.0,
            },
        ];
        ts.set_animation(0, frames);
        let anim = ts.get_animation(0).unwrap();
        assert_eq!(anim.len(), 2);
        assert_eq!(anim[0].tile_id, 0);
        assert!((anim[1].duration_ms - 200.0).abs() < 1e-5);
    }

    #[test]
    fn autotile_rule_4bit() {
        let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
        ts.set_auto_tile_rule("wall", 0b0101, 3);
        assert_eq!(ts.get_auto_tile_id("wall", 0b0101), Some(3));
        assert_eq!(ts.get_auto_tile_id("wall", 0b0000), None);
        assert_eq!(ts.get_auto_tile_id("floor", 0b0101), None);
    }

    #[test]
    fn autotile_rule_8bit() {
        let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
        ts.set_auto_tile_rule_8("wall", 0b10101010, 7);
        assert_eq!(ts.get_auto_tile_id_8("wall", 0b10101010), Some(7));
        assert_eq!(ts.get_auto_tile_id_8("wall", 0b00000000), None);
    }

    #[test]
    fn getters() {
        let ts = TileSet::new(10, 64, 8, 16, 16, 1, 2);
        assert_eq!(ts.get_first_gid(), 10);
        assert_eq!(ts.get_tile_count(), 64);
        assert_eq!(ts.get_columns(), 8);
        assert_eq!(ts.get_tile_width(), 16);
        assert_eq!(ts.get_tile_height(), 16);
        assert_eq!(ts.get_tile_dimensions(), (16, 16));
        assert_eq!(ts.get_spacing(), 1);
        assert_eq!(ts.get_margin(), 2);
    }
}
