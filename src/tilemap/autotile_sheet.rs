//! Autotile bitmask sheet: maps 8-bit neighbor bitmasks to sprite-sheet tile indices.
//! Owns `AutoTileLayout`, `AutoTileSheet`, and the bitmask table builders.
//! Does not own tile rendering or map storage; callers use the returned `Rect` for draw calls.
//! Depends on `tileset` and `math`.

use super::tileset::TileSet;
use crate::math::Rect;
use std::collections::HashMap;

/// Sprite-sheet packing variant that determines tile count and bitmask encoding.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AutoTileLayout {
    /// 47-tile blob layout based on the reduced 8-bit neighbor bitmask.
    Blob47,
    /// 48-tile composite layout with an explicit empty tile at index 0.
    Composite48,
    /// 16-tile minimal layout using only the 4 cardinal neighbor bits.
    Minimal16,
}

/// Autotile sprite sheet: holds bitmask tables for fast neighbor-to-tile lookup.
#[derive(Clone)]
pub struct AutoTileSheet {
    /// Width of a single tile in pixels.
    tile_width: u32,
    /// Height of a single tile in pixels.
    tile_height: u32,
    /// Sheet packing layout variant.
    layout: AutoTileLayout,
    /// Number of unique tiles in this sheet.
    tile_count: u32,
    /// Ordered list of bitmask values; index corresponds to tile index.
    bitmask_map: Vec<u16>,
    /// Reverse lookup from bitmask to tile index, including all 256 raw masks.
    reverse_map: HashMap<u16, u32>,
}
/// Collapse diagonal bits that are only valid when both adjacent cardinal neighbours are set.
    let n = mask & 1;
    let e = (mask >> 1) & 1;
    let s = (mask >> 2) & 1;
    let w = (mask >> 3) & 1;
    let ne = (mask >> 4) & 1;
    let se = (mask >> 5) & 1;
    let sw = (mask >> 6) & 1;
    let nw = (mask >> 7) & 1;
    let ne_valid = ne & n & e;
    let se_valid = se & s & e;
    let sw_valid = sw & s & w;
    let nw_valid = nw & n & w;
    n | (e << 1)
        | (s << 2)
        | (w << 3)
        | (ne_valid << 4)
        | (se_valid << 5)
        | (sw_valid << 6)
        | (nw_valid << 7)
}
/// Build the bitmask and reverse-map tables for the 47-tile blob layout.
    let mut unique: Vec<u8> = Vec::with_capacity(47);
    let mut seen: HashMap<u8, u32> = HashMap::new();
    let mut full_map: [u32; 256] = [0; 256];
    for raw in 0u16..256 {
        let reduced = reduce_8bit(raw as u8);
        if let Some(&idx) = seen.get(&reduced) {
            full_map[raw as usize] = idx;
        } else {
            let idx = unique.len() as u32;
            unique.push(reduced);
            seen.insert(reduced, idx);
            full_map[raw as usize] = idx;
        }
    }
    debug_assert_eq!(unique.len(), 47);
    let bitmask_map: Vec<u16> = unique.iter().map(|&b| b as u16).collect();
    let mut reverse_map = HashMap::new();
    for (i, &bm) in bitmask_map.iter().enumerate() {
        reverse_map.insert(bm, i as u32);
    }
    for raw in 0u16..256 {
        let tile_idx = full_map[raw as usize];
        reverse_map.entry(raw).or_insert(tile_idx);
    }
    (bitmask_map, reverse_map)
}
/// Build the bitmask and reverse-map tables for the 48-tile composite layout.
    let (blob_bm, _) = build_blob47_tables();
    let mut bitmask_map = Vec::with_capacity(48);
    bitmask_map.push(0u16);
    for bm in &blob_bm {
        bitmask_map.push(*bm);
    }
    let mut reverse_map = HashMap::new();
    for (i, &bm) in bitmask_map.iter().enumerate() {
        reverse_map.entry(bm).or_insert(i as u32);
    }
    for raw in 0u16..256 {
        let reduced = reduce_8bit(raw as u8) as u16;
        if let Some(&tile_idx) = reverse_map.get(&reduced) {
            reverse_map.entry(raw).or_insert(tile_idx);
        }
    }
    (bitmask_map, reverse_map)
}
/// Build the bitmask and reverse-map tables for the 16-tile minimal 4-bit layout.
    let mut bitmask_map = Vec::with_capacity(16);
    let mut reverse_map = HashMap::new();
    for i in 0u16..16 {
        bitmask_map.push(i);
        reverse_map.insert(i, i as u32);
    }
    (bitmask_map, reverse_map)
}
impl AutoTileSheet {
    /// Create a sheet for tiles of `tile_w` × `tile_h` pixels using the given `layout`; builds bitmask tables.
    pub fn new(tile_w: u32, tile_h: u32, layout: AutoTileLayout) -> Self {
        let (tile_count, bitmask_map, reverse_map) = match layout {
            AutoTileLayout::Blob47 => {
                let (bm, rm) = build_blob47_tables();
                (47, bm, rm)
            }
            AutoTileLayout::Composite48 => {
                let (bm, rm) = build_composite48_tables();
                (48, bm, rm)
            }
            AutoTileLayout::Minimal16 => {
                let (bm, rm) = build_minimal16_tables();
                (16, bm, rm)
            }
        };
        Self {
            tile_width: tile_w,
            tile_height: tile_h,
            layout,
            tile_count,
            bitmask_map,
            reverse_map,
        }
    }
    /// Return the sheet's packing layout variant.
    pub fn get_layout(&self) -> AutoTileLayout {
        self.layout
    }

    /// Return the number of unique tiles in this sheet.
    pub fn get_tile_count(&self) -> u32 {
        self.tile_count
    }

    /// Return the pixel width of one tile.
    pub fn get_tile_width(&self) -> u32 {
        self.tile_width
    }

    /// Return the pixel height of one tile.
    pub fn get_tile_height(&self) -> u32 {
        self.tile_height
    }
    /// Register each sheet bitmask as an autotile rule in `tileset` for `type_name`, offset by `start_gid`.
    pub fn apply_to_tileset(&self, tileset: &mut TileSet, type_name: &str, start_gid: Option<u32>) {
        let offset = start_gid.unwrap_or(0);
        match self.layout {
            AutoTileLayout::Minimal16 => {
                for (i, &bm) in self.bitmask_map.iter().enumerate() {
                    tileset.set_auto_tile_rule(type_name, bm as u8, i as u32 + offset);
                }
            }
            AutoTileLayout::Blob47 | AutoTileLayout::Composite48 => {
                for (i, &bm) in self.bitmask_map.iter().enumerate() {
                    tileset.set_auto_tile_rule_8(type_name, bm, i as u32 + offset);
                }
            }
        }
    }
    /// Return the bitmask stored at `index` in the sheet; returns 0 for out-of-range indices.
    pub fn get_bitmask_for_tile(&self, index: u32) -> u16 {
        self.bitmask_map.get(index as usize).copied().unwrap_or(0)
    }
    /// Return the tile index for `bitmask`; returns `None` when the bitmask has no match.
    pub fn get_tile_for_bitmask(&self, bitmask: u16) -> Option<u32> {
        self.reverse_map.get(&bitmask).copied()
    }
    /// Return the source `Rect` for tile at `index` in a single-row horizontal strip; returns empty rect for out-of-range.
    pub fn get_quad(&self, index: u32) -> Rect {
        if index >= self.tile_count {
            return Rect::new(0.0, 0.0, 0.0, 0.0);
        }
        let x = index * self.tile_width;
        Rect::new(
            x as f32,
            0.0,
            self.tile_width as f32,
            self.tile_height as f32,
        )
    }
    /// Return the source `Rect` for tile at `index` laid out in a grid of `cols` columns; returns empty rect on invalid input.
    pub fn get_grid_quad(&self, index: u32, cols: u32) -> Rect {
        if index >= self.tile_count || cols == 0 {
            return Rect::new(0.0, 0.0, 0.0, 0.0);
        }
        let col = index % cols;
        let row = index / cols;
        Rect::new(
            (col * self.tile_width) as f32,
            (row * self.tile_height) as f32,
            self.tile_width as f32,
            self.tile_height as f32,
        )
    }
    /// Return the source `Rect` for tile at `index` in a 6-column composite-48 grid.
    pub fn get_composite48_grid_quad(&self, index: u32) -> Rect {
        self.get_grid_quad(index, 6)
    }
    /// Return four quarter source `Rect`s (TL, TR, BL, BR) for compositing a tile from `bitmask`.
    pub fn get_quarter_rects(&self, bitmask: u16) -> [Rect; 4] {
        let qw = (self.tile_width / 2).max(1) as f32;
        let qh = (self.tile_height / 2).max(1) as f32;
        let tl = quarter_type_tl(bitmask);
        let tr = quarter_type_tr(bitmask);
        let bl = quarter_type_bl(bitmask);
        let br = quarter_type_br(bitmask);
        [
            quarter_rect(tl, qw, qh),
            quarter_rect(tr, qw, qh),
            quarter_rect(bl, qw, qh),
            quarter_rect(br, qw, qh),
        ]
    }
    /// Return four quarter destination `Rect`s (TL, TR, BL, BR) at world position `(x, y)`.
    pub fn get_quarter_dst_rects(&self, x: f32, y: f32) -> [Rect; 4] {
        let hw = (self.tile_width / 2) as f32;
        let hh = (self.tile_height / 2) as f32;
        [
            Rect::new(x, y, hw, hh),
            Rect::new(x + hw, y, hw, hh),
            Rect::new(x, y + hh, hw, hh),
            Rect::new(x + hw, y + hh, hw, hh),
        ]
    }
}
/// Lookup table mapping quarter-type index to (col, row) position in a 6-wide quarter grid.
const QUARTER_POSITIONS: [(u32, u32); 20] = [
    (4, 2),
    (5, 2),
    (4, 3),
    (5, 3),
    (2, 0),
    (3, 0),
    (2, 1),
    (3, 1),
    (0, 4),
    (1, 4),
    (0, 5),
    (1, 5),
    (0, 6),
    (1, 6),
    (0, 7),
    (1, 7),
    (4, 0),
    (5, 0),
    (4, 1),
    (5, 1),
];
#[inline]
/// Map quarter-type index `t` to its source `Rect` using pixel quarter dimensions `qw`×`qh`.
fn quarter_rect(t: u8, qw: f32, qh: f32) -> Rect {
    let (qcol, qrow) = QUARTER_POSITIONS[t as usize % 20];
    Rect::new(qcol as f32 * qw, qrow as f32 * qh, qw, qh)
}
#[inline]
/// Determine the top-left quarter type index from the 8-bit neighbor `mask`.
fn quarter_type_tl(mask: u16) -> u8 {
    let n = mask & 0x01 != 0;
    let w = mask & 0x08 != 0;
    let nw = mask & 0x80 != 0;
    match (n, w, nw) {
        (false, false, _) => 12,
        (true, false, _) => 4,
        (false, true, _) => 8,
        (true, true, false) => 16,
        (true, true, true) => 0,
    }
}
#[inline]
/// Determine the top-right quarter type index from the 8-bit neighbor `mask`.
fn quarter_type_tr(mask: u16) -> u8 {
    let n = mask & 0x01 != 0;
    let e = mask & 0x02 != 0;
    let ne = mask & 0x10 != 0;
    match (n, e, ne) {
        (false, false, _) => 13,
        (true, false, _) => 5,
        (false, true, _) => 9,
        (true, true, false) => 17,
        (true, true, true) => 1,
    }
}
#[inline]
/// Determine the bottom-left quarter type index from the 8-bit neighbor `mask`.
fn quarter_type_bl(mask: u16) -> u8 {
    let s = mask & 0x04 != 0;
    let w = mask & 0x08 != 0;
    let sw = mask & 0x40 != 0;
    match (s, w, sw) {
        (false, false, _) => 14,
        (true, false, _) => 6,
        (false, true, _) => 10,
        (true, true, false) => 18,
        (true, true, true) => 2,
    }
}
#[inline]
/// Determine the bottom-right quarter type index from the 8-bit neighbor `mask`.
fn quarter_type_br(mask: u16) -> u8 {
    let s = mask & 0x04 != 0;
    let e = mask & 0x02 != 0;
    let se = mask & 0x20 != 0;
    match (s, e, se) {
        (false, false, _) => 15,
        (true, false, _) => 7,
        (false, true, _) => 11,
        (true, true, false) => 19,
        (true, true, true) => 3,
    }
}
