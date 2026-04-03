//! Multi-level isometric tilemap for OpenXcom-style rendering.
//!
//! Each map cell holds four tile parts rendered in painter's algorithm order:
//! `Floor`, `NorthWall`, `WestWall`, `Object`. Z-levels stack vertically with
//! a configurable pixel offset so higher floors appear above lower ones.

// ---------------------------------------------------------------------------
// IsoTilePart
// ---------------------------------------------------------------------------

/// The four sub-slots within each isometric map cell, rendered in this order.
///
/// # Variants
/// - `Floor` — Floor variant.
/// - `NorthWall` — NorthWall variant.
/// - `WestWall` — WestWall variant.
/// - `Object` — Object variant.
///
/// Matching OpenXcom's FLOOR → NORTH_WALL → WEST_WALL → OBJECT sequence
/// ensures correct painter's algorithm occlusion within a single cell.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IsoTilePart {
    /// Ground surface — drawn first, lowest in the cell.
    Floor = 0,
    /// Wall facing north (the top-right edge of the diamond).
    NorthWall = 1,
    /// Wall facing west (the top-left edge of the diamond).
    WestWall = 2,
    /// Object / furniture / unit sitting on top of the floor.
    Object = 3,
}

impl IsoTilePart {
    /// Converts a 0-based index to an [`IsoTilePart`]. Returns `None` for indices ≥ 4.
    ///
    /// # Parameters
    /// - `i` — `u32`.
    ///
    /// # Returns
    /// `Option<Self>`.
    pub fn from_index(i: u32) -> Option<Self> {
        match i {
            0 => Some(Self::Floor),
            1 => Some(Self::NorthWall),
            2 => Some(Self::WestWall),
            3 => Some(Self::Object),
            _ => None,
        }
    }

    /// Returns the 0-based index of this part. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn index(self) -> u32 {
        self as u32
    }
}

// ---------------------------------------------------------------------------
// IsoTile
// ---------------------------------------------------------------------------

/// One map cell containing four GIDs, one per [`IsoTilePart`].
///
/// # Fields
/// - `parts` — `[u32; 4]`.
///
/// A GID of `0` means the slot is empty — `draw_iter` still yields the item
/// so callers can decide whether to skip it.
#[derive(Debug, Clone, Copy, Default)]
pub struct IsoTile {
    /// `parts[0]` = Floor, `parts[1]` = NorthWall, `parts[2]` = WestWall, `parts[3]` = Object.
    pub parts: [u32; 4],
}

// ---------------------------------------------------------------------------
// IsoLevel
// ---------------------------------------------------------------------------

/// One Z-level of the isometric map — a 2-D grid of [`IsoTile`]s.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `visible` — `bool`.
#[derive(Debug, Clone)]
pub struct IsoLevel {
    /// Width of this level in tiles.
    pub width: u32,
    /// Height of this level in tiles.
    pub height: u32,
    /// When `false`, `draw_iter` skips all items from this level.
    pub visible: bool,
    tiles: Vec<IsoTile>,
}

impl IsoLevel {
    /// Creates a new level filled with empty tiles (all GIDs = 0).
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32) -> Self {
        Self {
            width,
            height,
            visible: true,
            tiles: vec![IsoTile::default(); (width * height) as usize],
        }
    }

    fn index(&self, x: u32, y: u32) -> Option<usize> {
        if x < self.width && y < self.height {
            Some((y * self.width + x) as usize)
        } else {
            None
        }
    }

    /// Returns the [`IsoTile`] at `(x, y)`, or `None` if out of bounds.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `Option<&IsoTile>`.
    pub fn get_tile(&self, x: u32, y: u32) -> Option<&IsoTile> {
        self.index(x, y).map(|i| &self.tiles[i])
    }

    /// Returns mutable access to the [`IsoTile`] at `(x, y)`, or `None` if OOB.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `Option<&mut IsoTile>`.
    pub fn get_tile_mut(&mut self, x: u32, y: u32) -> Option<&mut IsoTile> {
        self.index(x, y).map(|i| &mut self.tiles[i])
    }
}

// ---------------------------------------------------------------------------
// IsoDrawItem
// ---------------------------------------------------------------------------

/// One renderable item produced by [`IsoMap::draw_iter`] in painter's order.
///
/// # Fields
/// - `level` — `u32`.
/// - `tile_x` — `u32`.
/// - `tile_y` — `u32`.
/// - `part` — `u32`.
/// - `gid` — `u32`.
/// - `screen_x` — `f32`.
/// - `screen_y` — `f32`.
///
/// `level`, `tile_x`, `tile_y`, and `part` are all **0-based** Rust values.
/// The Lua API converts them to 1-based before passing them to scripts.
#[derive(Debug, Clone)]
pub struct IsoDrawItem {
    /// Z-level index (0-based).
    pub level: u32,
    /// Tile column (0-based).
    pub tile_x: u32,
    /// Tile row (0-based).
    pub tile_y: u32,
    /// Part index (0 = Floor … 3 = Object).
    pub part: u32,
    /// Tile GID. `0` means the slot is empty.
    pub gid: u32,
    /// Screen X position (top-left of the tile sprite).
    pub screen_x: f32,
    /// Screen Y position (top-left of the tile sprite).
    pub screen_y: f32,
}

// ---------------------------------------------------------------------------
// IsoMap
// ---------------------------------------------------------------------------

/// Multi-level isometric tilemap with painter's-algorithm draw iteration.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `tile_w` — `u32`.
/// - `tile_h` — `u32`.
/// - `level_height` — `u32`.
/// - `origin_x` — `f32`.
/// - `origin_y` — `f32`.
///
/// # Coordinate system
///
/// ```text
/// screen_x = origin_x + (tx - ty) * tile_w / 2
/// screen_y = origin_y + (tx + ty) * tile_h / 2 - tz * level_height
/// ```
///
/// # Draw order
///
/// [`draw_iter`](IsoMap::draw_iter) yields items in the correct painter's
/// algorithm order for a standard isometric view with the camera positioned at
/// the top-left corner:
///
/// 1. Diagonal `d = tx + ty` increases from `0` to `(W-1) + (H-1)`.
/// 2. For each diagonal, tiles iterate in ascending `tx` order.
/// 3. For each tile, Z-levels iterate from bottom (`0`) to `active_z`.
/// 4. For each Z-level, parts iterate Floor → NorthWall → WestWall → Object.
#[derive(Debug, Clone)]
pub struct IsoMap {
    /// Map width in tiles (same for every level).
    pub width: u32,
    /// Map height in tiles (same for every level).
    pub height: u32,
    /// Tile footprint width in pixels (the full diamond width).
    pub tile_w: u32,
    /// Tile footprint height in pixels (the full diamond height, typically tile_w / 2).
    pub tile_h: u32,
    /// Vertical pixel offset between consecutive Z-levels.
    pub level_height: u32,
    /// Screen X origin (pixel position of tile (0, 0) at level 0).
    pub origin_x: f32,
    /// Screen Y origin (pixel position of tile (0, 0) at level 0).
    pub origin_y: f32,
    levels: Vec<IsoLevel>,
}

impl IsoMap {
    /// Creates an [`IsoMap`] with no levels. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `tile_w` — `u32`.
    /// - `tile_h` — `u32`.
    /// - `level_height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Add levels with [`add_level`](Self::add_level) before placing tiles.
    pub fn new(width: u32, height: u32, tile_w: u32, tile_h: u32, level_height: u32) -> Self {
        Self {
            width,
            height,
            tile_w,
            tile_h,
            level_height,
            origin_x: 0.0,
            origin_y: 0.0,
            levels: Vec::new(),
        }
    }

    // -----------------------------------------------------------------------
    // Level management
    // -----------------------------------------------------------------------

    /// Appends a new empty Z-level and returns its 0-based index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_level(&mut self) -> usize {
        let idx = self.levels.len();
        self.levels.push(IsoLevel::new(self.width, self.height));
        idx
    }

    /// Returns the number of Z-levels currently in the map.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_level_count(&self) -> usize {
        self.levels.len()
    }

    /// Sets the visibility of level `z`. Invisible levels are skipped in [`draw_iter`](Self::draw_iter).
    ///
    /// # Parameters
    /// - `z` — `usize`.
    /// - `visible` — `bool`.
    ///
    /// Does nothing if `z` is out of range.
    pub fn set_level_visible(&mut self, z: usize, visible: bool) {
        if let Some(level) = self.levels.get_mut(z) {
            level.visible = visible;
        }
    }

    /// Returns the visibility of level `z`, or `true` if `z` is out of range.
    ///
    /// # Parameters
    /// - `z` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn get_level_visible(&self, z: usize) -> bool {
        self.levels.get(z).is_none_or(|l| l.visible)
    }

    // -----------------------------------------------------------------------
    // Tile access
    // -----------------------------------------------------------------------

    /// Writes `gid` into the `part` slot of tile `(x, y)` on level `z`.
    ///
    /// # Parameters
    /// - `z` — `usize`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `part` — `u32`.
    /// - `gid` — `u32`.
    ///
    /// Out-of-bounds coordinates or invalid `part` values (>= 4) are ignored.
    pub fn set_tile_part(&mut self, z: usize, x: u32, y: u32, part: u32, gid: u32) {
        if part >= 4 {
            return;
        }
        if let Some(level) = self.levels.get_mut(z) {
            if let Some(tile) = level.get_tile_mut(x, y) {
                tile.parts[part as usize] = gid;
            }
        }
    }

    /// Reads the GID in the `part` slot of tile `(x, y)` on level `z`.
    ///
    /// # Parameters
    /// - `z` — `usize`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `part` — `u32`.
    ///
    /// # Returns
    /// `u32`.
    ///
    /// Returns `0` for any out-of-bounds access or invalid `part`.
    pub fn get_tile_part(&self, z: usize, x: u32, y: u32, part: u32) -> u32 {
        if part >= 4 {
            return 0;
        }
        self.levels
            .get(z)
            .and_then(|l| l.get_tile(x, y))
            .map_or(0, |t| t.parts[part as usize])
    }

    /// Fills every cell in level `z` with `gid` for the given `part`.
    ///
    /// # Parameters
    /// - `z` — `usize`.
    /// - `part` — `u32`.
    /// - `gid` — `u32`.
    ///
    /// Does nothing if `z` is out of range or `part` >= 4.
    pub fn fill_level(&mut self, z: usize, part: u32, gid: u32) {
        if part >= 4 {
            return;
        }
        if let Some(level) = self.levels.get_mut(z) {
            for tile in level.tiles.iter_mut() {
                tile.parts[part as usize] = gid;
            }
        }
    }

    // -----------------------------------------------------------------------
    // Origin
    // -----------------------------------------------------------------------

    /// Sets the screen pixel origin — the position where tile `(0, 0)` at level `0` projects.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn set_origin(&mut self, x: f32, y: f32) {
        self.origin_x = x;
        self.origin_y = y;
    }

    // -----------------------------------------------------------------------
    // Coordinate conversion
    // -----------------------------------------------------------------------

    /// Projects isometric tile coordinates `(tx, ty, tz)` to screen pixels.
    ///
    /// # Parameters
    /// - `tx` — `f32`.
    /// - `ty` — `f32`.
    /// - `tz` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    ///
    /// All inputs are 0-based floats; `tz` may be fractional for interpolation.
    ///
    /// Returns `(screen_x, screen_y)`.
    pub fn tile_to_screen(&self, tx: f32, ty: f32, tz: f32) -> (f32, f32) {
        let hw = self.tile_w as f32 / 2.0;
        let hh = self.tile_h as f32 / 2.0;
        let sx = self.origin_x + (tx - ty) * hw;
        let sy = self.origin_y + (tx + ty) * hh - tz * self.level_height as f32;
        (sx, sy)
    }

    /// Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
    ///
    /// # Parameters
    /// - `sx` — `f32`.
    /// - `sy` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    ///
    /// Returns `(tx, ty)` as 0-based floats. Use `floor()` for integer cell lookup.
    pub fn screen_to_tile(&self, sx: f32, sy: f32) -> (f32, f32) {
        let rel_x = sx - self.origin_x;
        let rel_y = sy - self.origin_y;
        let hw = self.tile_w as f32 / 2.0;
        let hh = self.tile_h as f32 / 2.0;
        // Inverse of: sx = (tx - ty) * hw,  sy = (tx + ty) * hh
        let tx = (rel_x / hw + rel_y / hh) / 2.0;
        let ty = (rel_y / hh - rel_x / hw) / 2.0;
        (tx, ty)
    }

    // -----------------------------------------------------------------------
    // Draw iteration
    // -----------------------------------------------------------------------

    /// Returns all draw items in painter's algorithm order for rendering up to
    ///
    /// # Parameters
    /// - `active_z` — `usize`.
    ///
    /// # Returns
    /// `Vec<IsoDrawItem>`.
    /// and including level `active_z`.
    ///
    /// If `active_z` >= the number of levels, it is clamped to the last level.
    ///
    /// **Every** tile part is yielded, including those with `gid == 0`. Lua can
    /// skip drawing when `gid == 0` to keep the Rust side simple.
    ///
    /// # Order
    /// For each diagonal `d` (0 … W+H-2), for each `(tx, ty)` in that diagonal
    /// with ascending `tx`, for each `z` in `0..=active_z` (if the level is
    /// visible), for each part in Floor, NorthWall, WestWall, Object order.
    pub fn draw_iter(&self, active_z: usize) -> Vec<IsoDrawItem> {
        if self.levels.is_empty() || self.width == 0 || self.height == 0 {
            return Vec::new();
        }

        let max_z = active_z.min(self.levels.len() - 1);
        let w = self.width as usize;
        let h = self.height as usize;

        // Estimate capacity: W * H * (max_z+1) * 4 parts
        let mut items = Vec::with_capacity(w * h * (max_z + 1) * 4);

        let max_d = (w + h).saturating_sub(2);

        for d in 0..=max_d {
            // tx ranges from max(0, d - (h-1)) to min(w-1, d)
            let tx_min = d.saturating_sub(h - 1);
            let tx_max = d.min(w - 1);

            for tx in tx_min..=tx_max {
                let ty = d - tx;

                for z in 0..=max_z {
                    let level = &self.levels[z];
                    if !level.visible {
                        continue;
                    }

                    let tile = match level.get_tile(tx as u32, ty as u32) {
                        Some(t) => t,
                        None => continue,
                    };

                    let (sx, sy) = self.tile_to_screen(tx as f32, ty as f32, z as f32);

                    for part in 0u32..4 {
                        items.push(IsoDrawItem {
                            level: z as u32,
                            tile_x: tx as u32,
                            tile_y: ty as u32,
                            part,
                            gid: tile.parts[part as usize],
                            screen_x: sx,
                            screen_y: sy,
                        });
                    }
                }
            }
        }

        items
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    fn make_map() -> IsoMap {
        IsoMap::new(4, 4, 64, 32, 24)
    }

    #[test]
    fn test_isomap_add_level_returns_index() {
        let mut m = make_map();
        assert_eq!(m.add_level(), 0);
        assert_eq!(m.add_level(), 1);
        assert_eq!(m.get_level_count(), 2);
    }

    #[test]
    fn test_isomap_tile_part_round_trip() {
        let mut m = make_map();
        m.add_level();
        m.set_tile_part(0, 1, 2, 0, 42);
        assert_eq!(m.get_tile_part(0, 1, 2, 0), 42);
        assert_eq!(m.get_tile_part(0, 1, 2, 1), 0); // other parts untouched
    }

    #[test]
    fn test_isomap_tile_part_oob_returns_zero() {
        let mut m = make_map();
        m.add_level();
        // x/y out of bounds
        assert_eq!(m.get_tile_part(0, 99, 99, 0), 0);
        // level OOB
        assert_eq!(m.get_tile_part(5, 0, 0, 0), 0);
        // part OOB
        assert_eq!(m.get_tile_part(0, 0, 0, 4), 0);
    }

    #[test]
    fn test_isomap_fill_level() {
        let mut m = make_map();
        m.add_level();
        m.fill_level(0, 0, 7);
        for y in 0..4 {
            for x in 0..4 {
                assert_eq!(m.get_tile_part(0, x, y, 0), 7);
                assert_eq!(m.get_tile_part(0, x, y, 1), 0); // other parts untouched
            }
        }
    }

    #[test]
    fn test_isomap_tile_to_screen() {
        let mut m = IsoMap::new(10, 10, 64, 32, 24);
        m.origin_x = 400.0;
        m.origin_y = 50.0;
        // tile (0, 0) Z=0: sx = 400, sy = 50
        let (sx, sy) = m.tile_to_screen(0.0, 0.0, 0.0);
        assert!((sx - 400.0).abs() < 1e-4, "sx={}", sx);
        assert!((sy - 50.0).abs() < 1e-4, "sy={}", sy);
        // tile (1, 0) Z=0: sx = 400 + 32 = 432, sy = 50 + 16 = 66
        let (sx, sy) = m.tile_to_screen(1.0, 0.0, 0.0);
        assert!((sx - 432.0).abs() < 1e-4, "sx={}", sx);
        assert!((sy - 66.0).abs() < 1e-4, "sy={}", sy);
        // Z-offset: Z=1 adds -24 to sy
        let (_, sy2) = m.tile_to_screen(1.0, 0.0, 1.0);
        assert!((sy2 - (66.0 - 24.0)).abs() < 1e-4, "sy2={}", sy2);
    }

    #[test]
    fn test_isomap_screen_to_tile_inverse() {
        let mut m = IsoMap::new(10, 10, 64, 32, 24);
        m.origin_x = 200.0;
        m.origin_y = 100.0;
        let (sx, sy) = m.tile_to_screen(3.0, 2.0, 0.0);
        let (tx, ty) = m.screen_to_tile(sx, sy);
        assert!((tx - 3.0).abs() < 1e-4, "tx={}", tx);
        assert!((ty - 2.0).abs() < 1e-4, "ty={}", ty);
    }

    #[test]
    fn test_isomap_draw_iter_order() {
        // 2x2 map, 1 level: draw_iter should yield 4 cells * 4 parts = 16 items
        // Diagonal 0: (0,0); diagonal 1: (0,1),(1,0); diagonal 2: (1,1)
        let mut m = IsoMap::new(2, 2, 64, 32, 24);
        m.add_level();
        let items = m.draw_iter(0);
        assert_eq!(items.len(), 16); // 4 cells * 4 parts

        // First 4 items: diagonal 0, cell (0,0), parts 0-3
        let first = &items[0];
        assert_eq!((first.tile_x, first.tile_y, first.part), (0, 0, 0));

        // Items 4..8: diagonal 1, first tile should be (0,1)
        let second_group = &items[4];
        assert_eq!((second_group.tile_x, second_group.tile_y), (0, 1));

        // Items 8..12: diagonal 1, second tile (1,0)
        let third_group = &items[8];
        assert_eq!((third_group.tile_x, third_group.tile_y), (1, 0));

        // Items 12..16: diagonal 2, cell (1,1)
        let last = &items[12];
        assert_eq!((last.tile_x, last.tile_y), (1, 1));
    }

    #[test]
    fn test_isomap_draw_iter_multi_z_order() {
        // 1x1 map with 2 levels: items should be z=0 then z=1 for the same tile
        let mut m = IsoMap::new(1, 1, 64, 32, 24);
        m.add_level();
        m.add_level();
        m.set_tile_part(0, 0, 0, 0, 10); // level 0 floor = 10
        m.set_tile_part(1, 0, 0, 0, 20); // level 1 floor = 20

        let items = m.draw_iter(1);
        assert_eq!(items.len(), 8); // 1 cell * 2 levels * 4 parts

        // First 4 items: level 0
        assert_eq!(items[0].level, 0);
        assert_eq!(items[0].gid, 10);
        // Next 4 items: level 1
        assert_eq!(items[4].level, 1);
        assert_eq!(items[4].gid, 20);
    }

    #[test]
    fn test_isomap_level_visible_skip() {
        let mut m = IsoMap::new(1, 1, 64, 32, 24);
        m.add_level();
        m.add_level();
        m.set_level_visible(0, false); // hide level 0

        let items = m.draw_iter(1);
        // Only level 1 items should appear
        assert_eq!(items.len(), 4);
        assert_eq!(items[0].level, 1);
    }

    #[test]
    fn test_isomap_active_z_clamped() {
        let mut m = IsoMap::new(1, 1, 64, 32, 24);
        m.add_level(); // only level 0
                       // Requesting active_z=10 should clamp to 0 (last level)
        let items = m.draw_iter(10);
        assert_eq!(items.len(), 4); // level 0 × 4 parts, no panic
    }

    #[test]
    fn test_isomap_draw_iter_empty() {
        let m = IsoMap::new(4, 4, 64, 32, 24); // no levels added
        assert!(m.draw_iter(0).is_empty());
    }
}
