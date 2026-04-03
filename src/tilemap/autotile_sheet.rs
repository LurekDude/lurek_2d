//! AutoTileSheet — loads a pre-arranged autotile image and generates TileSet tiles + bitmask rules.
//!
//! ## 48-tile quarter-tile format
//!
//! For high-quality composite autotile rendering, [`AutoTileSheet`] supports a 48-tile
//! sub-tile format where each full tile is assembled from **four quarter-tile pieces** (TL, TR,
//! BL, BR).  The source image must be **`3*tile_w` × `4*tile_h` pixels** — a 6-column ×
//! 8-row grid of `(tile_w/2 × tile_h/2)` quarter pieces.
//!
//! Call [`AutoTileSheet::get_quarter_rects`] with the raw 8-bit neighbour bitmask to obtain the
//! four [`Rect`]s to blit.  Use [`AutoTileSheet::get_composite48_grid_quad`] when the source atlas
//! stores the 48 pre-composed tile variants in a 6 × 8 full-tile grid instead.
//!
//! ### Bitmask bit layout (raw 8-bit)
//!
//! ```text
//! bit 0 = N   bit 4 = NE
//! bit 1 = E   bit 5 = SE
//! bit 2 = S   bit 6 = SW
//! bit 3 = W   bit 7 = NW
//! ```

use std::collections::HashMap;

use crate::math::Rect;

use super::tileset::TileSet;

/// Predefined autotile sheet layout variants.
///
/// # Variants
/// - `Blob47` — Blob47 variant.
/// - `Composite48` — 48-tile composite variant.
/// - `Minimal16` — Minimal16 variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AutoTileLayout {
    /// 47-tile blob autotile (full 8-bit reduction).
    Blob47,
    /// 48-tile composite layout (6×8 = 48 tiles).
    Composite48,
    /// standard 3×3 minimal (4×4 = 16-tile, 4-bit cardinal only).
    Minimal16,
}

/// An autotile sheet that maps layout conventions to bitmask-based tile selection.
///
/// Stores the bitmask↔tile-index mapping tables for a given [`AutoTileLayout`] and
/// can apply the resulting rules to a [`TileSet`].
///
/// # Fields
/// - `tile_width` — `u32`.
/// - `tile_height` — `u32`.
/// - `layout` — `AutoTileLayout`.
/// - `tile_count` — `u32`.
/// - `bitmask_map` — `Vec<u16>`.
/// - `reverse_map` — `HashMap<u16`.
#[derive(Clone)]
pub struct AutoTileSheet {
    tile_width: u32,
    tile_height: u32,
    layout: AutoTileLayout,
    tile_count: u32,
    /// tile index → bitmask value
    bitmask_map: Vec<u16>,
    /// bitmask → tile index
    reverse_map: HashMap<u16, u32>,
}

/// Reduce an 8-bit bitmask by masking out diagonal bits whose adjacent cardinals are absent.
///
/// Bit layout: N=0, E=1, S=2, W=3, NE=4, SE=5, SW=6, NW=7.
fn reduce_8bit(mask: u8) -> u8 {
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

/// Build the 47-tile blob bitmask tables.
///
/// Returns `(bitmask_map, reverse_map)` where `bitmask_map[tile_index] = reduced_bitmask`
/// and `reverse_map[reduced_bitmask] = tile_index`.
fn build_blob47_tables() -> (Vec<u16>, HashMap<u16, u32>) {
    // Collect all unique reduced bitmasks in order of first appearance (0..255).
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
    // There should be exactly 47 unique reduced bitmasks.
    debug_assert_eq!(unique.len(), 47);

    let bitmask_map: Vec<u16> = unique.iter().map(|&b| b as u16).collect();
    let mut reverse_map = HashMap::new();
    for (i, &bm) in bitmask_map.iter().enumerate() {
        reverse_map.insert(bm, i as u32);
    }
    // Also insert all 256 raw→tile mappings so lookup works for non-reduced bitmasks.
    for raw in 0u16..256 {
        let tile_idx = full_map[raw as usize];
        reverse_map.entry(raw).or_insert(tile_idx);
    }

    (bitmask_map, reverse_map)
}

/// Build the 48-tile composite tables.
///
/// Tile 0 = isolated (bitmask 0 cardinal-reduced), tiles 1..47 = the 47 blob tiles.
fn build_composite48_tables() -> (Vec<u16>, HashMap<u16, u32>) {
    let (blob_bm, _) = build_blob47_tables();

    let mut bitmask_map = Vec::with_capacity(48);
    // Tile 0: isolated tile with bitmask 0
    bitmask_map.push(0u16);
    // Tiles 1-47: blob tiles (shift indices by 1)
    for bm in &blob_bm {
        bitmask_map.push(*bm);
    }

    let mut reverse_map = HashMap::new();
    for (i, &bm) in bitmask_map.iter().enumerate() {
        reverse_map.entry(bm).or_insert(i as u32);
    }
    // Also map all 256 raw bitmasks
    for raw in 0u16..256 {
        let reduced = reduce_8bit(raw as u8) as u16;
        if let Some(&tile_idx) = reverse_map.get(&reduced) {
            reverse_map.entry(raw).or_insert(tile_idx);
        }
    }

    (bitmask_map, reverse_map)
}

/// Build the Minimal16 tables (4-bit cardinal: N=1, E=2, S=4, W=8).
fn build_minimal16_tables() -> (Vec<u16>, HashMap<u16, u32>) {
    let mut bitmask_map = Vec::with_capacity(16);
    let mut reverse_map = HashMap::new();
    for i in 0u16..16 {
        bitmask_map.push(i);
        reverse_map.insert(i, i as u32);
    }
    (bitmask_map, reverse_map)
}

impl AutoTileSheet {
    /// Creates a new autotile sheet with the given tile dimensions and layout.
    ///
    /// # Parameters
    /// - `tile_w` — `u32`.
    /// - `tile_h` — `u32`.
    /// - `layout` — `AutoTileLayout`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Internally builds the bitmask mapping tables for the chosen layout.
    /// Tile counts: Blob47 = 47, Composite48 = 48, Minimal16 = 16.
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

    /// Returns the layout variant. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `AutoTileLayout`.
    pub fn get_layout(&self) -> AutoTileLayout {
        self.layout
    }

    /// Returns the number of tiles in this sheet.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tile_count(&self) -> u32 {
        self.tile_count
    }

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

    /// Applies autotile rules from this sheet to a [`TileSet`].
    ///
    /// # Parameters
    /// - `tileset` — `&mut TileSet`.
    /// - `type_name` — `&str`.
    /// - `start_gid` — `Option<u32>`.
    ///
    /// For [`AutoTileLayout::Minimal16`], uses 4-bit cardinal rules.
    /// For [`AutoTileLayout::Blob47`] and [`AutoTileLayout::Composite48`], uses 8-bit rules.
    ///
    /// `start_gid` offsets the local tile IDs written into the tileset (defaults to 0).
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

    /// Returns the bitmask value associated with a tile index, or 0 if out of bounds.
    ///
    /// # Parameters
    /// - `index` — `u32`.
    ///
    /// # Returns
    /// `u16`.
    pub fn get_bitmask_for_tile(&self, index: u32) -> u16 {
        self.bitmask_map.get(index as usize).copied().unwrap_or(0)
    }

    /// Returns the tile index for a given bitmask, if one exists.
    ///
    /// # Parameters
    /// - `bitmask` — `u16`.
    ///
    /// # Returns
    /// `Option<u32>`.
    pub fn get_tile_for_bitmask(&self, bitmask: u16) -> Option<u32> {
        self.reverse_map.get(&bitmask).copied()
    }

    /// Returns the atlas region rectangle for the tile at the given index.
    ///
    /// # Parameters
    /// - `index` — `u32`.
    ///
    /// # Returns
    /// `Rect`.
    ///
    /// Tiles are laid out left-to-right in a single row. Returns a zero-size rect
    /// if the index is out of bounds.
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

    // ------------------------------------------------------------------
    // 48-tile composite support
    // ------------------------------------------------------------------

    /// Returns the atlas region for a tile stored in a **grid-layout** atlas.
    ///
    /// # Parameters
    /// - `index` — `u32`.
    /// - `cols` — `u32`.
    ///
    /// # Returns
    /// `Rect`.
    ///
    /// Unlike [`Self::get_quad`] (single row), this method assumes the tiles are
    /// arranged in a grid with `cols` columns, matching the pre-composed 48-tile
    /// 6-column × 8-row layout (`cols = 6`).
    ///
    /// Returns a zero-size rect if `index >= tile_count`.
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

    /// Returns the atlas region for a pre-composed 48-tile layout using the
    ///
    /// # Parameters
    /// - `index` — `u32`.
    ///
    /// # Returns
    /// `Rect`.
    /// standard **6-column** grid layout (48 tiles in 6 × 8 arrangement).
    ///
    /// Equivalent to `get_grid_quad(index, 6)`.
    pub fn get_composite48_grid_quad(&self, index: u32) -> Rect {
        self.get_grid_quad(index, 6)
    }

    /// Returns the four quarter-tile source [`Rect`]s for the given raw 8-bit neighbour bitmask.
    ///
    /// # Parameters
    /// - `bitmask` — `u16`.
    ///
    /// # Returns
    /// `[Rect; 4]`.
    ///
    /// The output array is `[TL, TR, BL, BR]`. Each rect addresses a `(tile_w/2 × tile_h/2)`
    /// area inside a **48-tile composite source image**, which must be exactly
    /// `3*tile_w × 4*tile_h` pixels in size.
    ///
    /// ## Source image layout (6 q-columns × 8 q-rows)
    ///
    /// | qcol | 0 | 1 | 2 | 3 | 4 | 5 |
    /// |---|---|---|---|---|---|---|
    /// | **qrow 0** | IC-TL | IC-TR | N-edge TL | N-edge TR | Ctr-TL | (unused) |
    /// | **qrow 1** | IC-BL | IC-BR | S-edge BL | S-edge BR | Ctr-BL | (unused) |
    /// | **qrow 2** | (unused) | (unused) | (unused) | (unused) | Ctr-TL(f) | Ctr-TR(f) |
    /// | **qrow 3** | (unused) | (unused) | (unused) | (unused) | Ctr-BL(f) | Ctr-BR(f) |
    /// | **qrow 4** | W-edge TL | E-edge TR | (unused) | (unused) | (unused) | (unused) |
    /// | **qrow 5** | W-edge BL | E-edge BR | (unused) | (unused) | (unused) | (unused) |
    /// | **qrow 6** | OC-TL | OC-TR | (unused) | (unused) | (unused) | (unused) |
    /// | **qrow 7** | OC-BL | OC-BR | (unused) | (unused) | (unused) | (unused) |
    ///
    /// **IC** = inner corner (N+W present but NW absent), **Ctr** = center (all present),
    /// **N/S/W/E-edge** = one side open, **OC** = outer corner (two adjacent sides open).
    ///
    /// ## Bitmask bits
    /// `bit0=N, bit1=E, bit2=S, bit3=W, bit4=NE, bit5=SE, bit6=SW, bit7=NW`
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

    /// Returns the four **destination** sub-rects within a tile at world position `(x, y)`.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    ///
    /// # Returns
    /// `[Rect; 4]`.
    ///
    /// The output array is `[TL, TR, BL, BR]`. Useful for rendering composite quarter tiles
    /// using four small blit calls instead of one full-tile blit.
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

// ---------------------------------------------------------------------------
// Quarter-tile type selection (internal)
// ---------------------------------------------------------------------------

/// Quarter-tile type IDs used internally.
///
/// 20 unique types cover all combinations needed by the 47-blob system.
///
/// | ID | (qcol, qrow) | Meaning |
/// |---|---|---|
/// |  0 | (4,2) | TL, center (all connected) |
/// |  1 | (5,2) | TR, center |
/// |  2 | (4,3) | BL, center |
/// |  3 | (5,3) | BR, center |
/// |  4 | (2,0) | TL, N-edge (N absent) |
/// |  5 | (3,0) | TR, N-edge |
/// |  6 | (2,1) | BL, S-edge |
/// |  7 | (3,1) | BR, S-edge |
/// |  8 | (0,4) | TL, W-edge (W absent) |
/// |  9 | (1,4) | TR, E-edge |
/// | 10 | (0,5) | BL, W-edge |
/// | 11 | (1,5) | BR, E-edge |
/// | 12 | (0,6) | TL, outer corner (N+W absent) |
/// | 13 | (1,6) | TR, outer corner |
/// | 14 | (0,7) | BL, outer corner |
/// | 15 | (1,7) | BR, outer corner |
/// | 16 | (4,0) | TL, inner corner (N+W+!NW) |
/// | 17 | (5,0) | TR, inner corner |
/// | 18 | (4,1) | BL, inner corner |
/// | 19 | (5,1) | BR, inner corner |
const QUARTER_POSITIONS: [(u32, u32); 20] = [
    // center
    (4, 2),
    (5, 2),
    (4, 3),
    (5, 3),
    // N-edge (TL,TR), S-edge (BL,BR)
    (2, 0),
    (3, 0),
    (2, 1),
    (3, 1),
    // W-edge (TL,BL), E-edge (TR,BR)
    (0, 4),
    (1, 4),
    (0, 5),
    (1, 5),
    // outer corners
    (0, 6),
    (1, 6),
    (0, 7),
    (1, 7),
    // inner corners
    (4, 0),
    (5, 0),
    (4, 1),
    (5, 1),
];

/// Returns the source pixel [`Rect`] for quarter-piece type `t` in a 6q×8q image.
#[inline]
fn quarter_rect(t: u8, qw: f32, qh: f32) -> Rect {
    let (qcol, qrow) = QUARTER_POSITIONS[t as usize % 20];
    Rect::new(qcol as f32 * qw, qrow as f32 * qh, qw, qh)
}

/// Quarter type for the **top-left** corner.
/// Looks at N (bit 0), W (bit 3), NW (bit 7).
#[inline]
fn quarter_type_tl(mask: u16) -> u8 {
    let n = mask & 0x01 != 0;
    let w = mask & 0x08 != 0;
    let nw = mask & 0x80 != 0;
    match (n, w, nw) {
        (false, false, _) => 12,   // outer corner
        (true, false, _) => 4,     // N-edge
        (false, true, _) => 8,     // W-edge
        (true, true, false) => 16, // inner corner
        (true, true, true) => 0,   // center
    }
}

/// Quarter type for the **top-right** corner.
/// Looks at N (bit 0), E (bit 1), NE (bit 4).
#[inline]
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

/// Quarter type for the **bottom-left** corner.
/// Looks at S (bit 2), W (bit 3), SW (bit 6).
#[inline]
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

/// Quarter type for the **bottom-right** corner.
/// Looks at S (bit 2), E (bit 1), SE (bit 5).
#[inline]
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creation_blob47() {
        let sheet = AutoTileSheet::new(32, 32, AutoTileLayout::Blob47);
        assert_eq!(sheet.get_layout(), AutoTileLayout::Blob47);
        assert_eq!(sheet.get_tile_count(), 47);
        assert_eq!(sheet.get_tile_width(), 32);
        assert_eq!(sheet.get_tile_height(), 32);
    }

    #[test]
    fn creation_composite48() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Composite48);
        assert_eq!(sheet.get_layout(), AutoTileLayout::Composite48);
        assert_eq!(sheet.get_tile_count(), 48);
    }

    #[test]
    fn creation_minimal16() {
        let sheet = AutoTileSheet::new(24, 24, AutoTileLayout::Minimal16);
        assert_eq!(sheet.get_layout(), AutoTileLayout::Minimal16);
        assert_eq!(sheet.get_tile_count(), 16);
    }

    #[test]
    fn tile_count_per_layout() {
        assert_eq!(
            AutoTileSheet::new(16, 16, AutoTileLayout::Blob47).get_tile_count(),
            47
        );
        assert_eq!(
            AutoTileSheet::new(16, 16, AutoTileLayout::Composite48).get_tile_count(),
            48
        );
        assert_eq!(
            AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16).get_tile_count(),
            16
        );
    }

    #[test]
    fn get_quad_bounds() {
        let sheet = AutoTileSheet::new(32, 32, AutoTileLayout::Blob47);
        let q0 = sheet.get_quad(0);
        assert!((q0.x - 0.0).abs() < 1e-5);
        assert!((q0.y - 0.0).abs() < 1e-5);
        assert!((q0.width - 32.0).abs() < 1e-5);
        assert!((q0.height - 32.0).abs() < 1e-5);

        let q5 = sheet.get_quad(5);
        assert!((q5.x - 160.0).abs() < 1e-5);
        assert!((q5.y - 0.0).abs() < 1e-5);
    }

    #[test]
    fn get_quad_out_of_bounds() {
        let sheet = AutoTileSheet::new(32, 32, AutoTileLayout::Minimal16);
        let q = sheet.get_quad(100);
        assert!((q.width - 0.0).abs() < 1e-5);
        assert!((q.height - 0.0).abs() < 1e-5);
    }

    #[test]
    fn bitmask_roundtrip_minimal16() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16);
        for i in 0u32..16 {
            let bm = sheet.get_bitmask_for_tile(i);
            assert_eq!(bm, i as u16);
            let tile = sheet.get_tile_for_bitmask(bm);
            assert_eq!(tile, Some(i));
        }
    }

    #[test]
    fn bitmask_roundtrip_blob47() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Blob47);
        // Each of the 47 tiles should have a unique bitmask
        for i in 0u32..47 {
            let bm = sheet.get_bitmask_for_tile(i);
            let tile = sheet.get_tile_for_bitmask(bm);
            assert_eq!(tile, Some(i));
        }
    }

    #[test]
    fn bitmask_out_of_bounds() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Blob47);
        assert_eq!(sheet.get_bitmask_for_tile(100), 0);
    }

    #[test]
    fn apply_to_tileset_minimal16() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16);
        let mut ts = TileSet::new(1, 16, 4, 16, 16, 0, 0);
        sheet.apply_to_tileset(&mut ts, "grass", None);
        // Bitmask 0 → tile 0
        assert_eq!(ts.get_auto_tile_id("grass", 0), Some(0));
        // Bitmask 15 → tile 15
        assert_eq!(ts.get_auto_tile_id("grass", 15), Some(15));
    }

    #[test]
    fn apply_to_tileset_with_offset() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16);
        let mut ts = TileSet::new(1, 32, 4, 16, 16, 0, 0);
        sheet.apply_to_tileset(&mut ts, "wall", Some(10));
        // Bitmask 0 → tile 10 (0 + offset)
        assert_eq!(ts.get_auto_tile_id("wall", 0), Some(10));
    }

    #[test]
    fn apply_to_tileset_blob47() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Blob47);
        let mut ts = TileSet::new(1, 64, 8, 16, 16, 0, 0);
        sheet.apply_to_tileset(&mut ts, "stone", None);
        // At least tile index 0's bitmask should be registered
        let bm0 = sheet.get_bitmask_for_tile(0);
        assert_eq!(ts.get_auto_tile_id_8("stone", bm0), Some(0));
    }

    #[test]
    fn layout_equality() {
        assert_ne!(AutoTileLayout::Blob47, AutoTileLayout::Composite48);
        assert_ne!(AutoTileLayout::Composite48, AutoTileLayout::Minimal16);
        assert_eq!(AutoTileLayout::Blob47, AutoTileLayout::Blob47);
    }

    #[test]
    fn reduce_8bit_masks_out_irrelevant_diagonals() {
        // NE bit set but N and E not set → NE should be masked out
        let raw = 0b0001_0000; // only NE
        let reduced = reduce_8bit(raw);
        assert_eq!(reduced, 0); // no cardinals, so no diagonals

        // N + E + NE → all valid
        let raw2 = 0b0001_0011; // N=1, E=1, NE=1
        let reduced2 = reduce_8bit(raw2);
        assert_eq!(reduced2, 0b0001_0011); // N + E + NE kept
    }
}
