use crate::log_msg;
use crate::math::Rect;
use crate::runtime::log_messages::{TS01, TS02, TS03};
use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct TileAnimFrame {
    pub tile_id: u32,
    pub duration_ms: f32,
}
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
    pub fn get_first_gid(&self) -> u32 {
        self.first_gid
    }
    pub fn get_tile_count(&self) -> u32 {
        self.tile_count
    }
    pub fn get_columns(&self) -> u32 {
        self.columns
    }
    pub fn get_tile_width(&self) -> u32 {
        self.tile_width
    }
    pub fn get_tile_height(&self) -> u32 {
        self.tile_height
    }
    pub fn get_tile_dimensions(&self) -> (u32, u32) {
        (self.tile_width, self.tile_height)
    }
    pub fn get_spacing(&self) -> u32 {
        self.spacing
    }
    pub fn get_margin(&self) -> u32 {
        self.margin
    }
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
    pub fn get_animation(&self, local_tile_id: u32) -> Option<&Vec<TileAnimFrame>> {
        self.animations.get(&local_tile_id)
    }
    pub fn set_solid(&mut self, local_tile_id: u32, solid: bool) {
        log_msg!(trace, TS03, "tile={} solid={}", local_tile_id, solid);
        let idx = local_tile_id as usize;
        if idx >= self.solids.len() {
            self.solids.resize(idx + 1, false);
        }
        self.solids[idx] = solid;
    }
    pub fn is_solid(&self, local_tile_id: u32) -> bool {
        let idx = local_tile_id as usize;
        if idx < self.solids.len() {
            self.solids[idx]
        } else {
            false
        }
    }
    pub fn set_auto_tile_rule(&mut self, type_name: &str, bitmask: u8, local_tile_id: u32) {
        self.auto_rules_4
            .insert((type_name.to_string(), bitmask), local_tile_id);
    }
    pub fn get_auto_tile_id(&self, type_name: &str, bitmask: u8) -> Option<u32> {
        self.auto_rules_4
            .get(&(type_name.to_string(), bitmask))
            .copied()
    }
    pub fn set_auto_tile_rule_8(&mut self, type_name: &str, bitmask: u16, local_tile_id: u32) {
        self.auto_rules_8
            .insert((type_name.to_string(), bitmask), local_tile_id);
    }
    pub fn get_auto_tile_id_8(&self, type_name: &str, bitmask: u16) -> Option<u32> {
        self.auto_rules_8
            .get(&(type_name.to_string(), bitmask))
            .copied()
    }
}
