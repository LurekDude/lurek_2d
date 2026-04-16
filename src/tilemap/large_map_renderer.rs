//! Optimized renderer for large tile-based maps with chunking and LOD.
//!
//! [`LargeMapRenderer`] stores a flat tile array and divides it into
//! [`MapChunk`]s for efficient culling. Dirty flags allow incremental
//! rebuilds when individual tiles change. The renderer tracks camera
//! position, zoom, and viewport to compute which chunks are visible.

use std::collections::HashMap;

// ── Chunk ───────────────────────────────────────────────────────────────

/// A chunk of tiles pre-batched for fast culling and rendering.
///
/// # Fields
/// - `cx` — `i32`.
/// - `cy` — `i32`.
/// - `dirty` — `bool`.
/// - `tile_ids` — `Vec<u32>`.
///
/// Each chunk covers a `chunk_size × chunk_size` region of tiles.
#[derive(Debug)]
pub struct MapChunk {
    /// Chunk column index (may be negative for offset maps).
    pub cx: i32,
    /// Chunk row index.
    pub cy: i32,
    /// Whether this chunk's tile data needs rebuilding.
    pub dirty: bool,
    /// Tile IDs within this chunk (row-major, length ≤ `chunk_size²`).
    pub tile_ids: Vec<u32>,
}

// ── LargeMapRenderer ────────────────────────────────────────────────────

/// Optimized large tile-map renderer with chunked culling.
///
/// # Fields
/// - `tile_width` — `u32`.
/// - `tile_height` — `u32`.
/// - `map_width` — `u32`.
/// - `map_height` — `u32`.
/// - `tileset_columns` — `u32`.
/// - `chunk_size` — `u32`.
/// - `camera_x` — `f32`.
/// - `camera_y` — `f32`.
/// - `camera_zoom` — `f32`.
/// - `viewport_w` — `f32`.
/// - `viewport_h` — `f32`.
/// - `lod_enabled` — `bool`.
/// - `lod_thresholds` — `Vec<f32>`.
///
/// Tiles are stored in a flat `Vec<u32>` (row-major). The renderer splits
/// them into square chunks and exposes helpers to determine which chunks
/// are visible for a given camera position, zoom, and viewport.
pub struct LargeMapRenderer {
    /// Width of a single tile in pixels.
    pub tile_width: u32,
    /// Height of a single tile in pixels.
    pub tile_height: u32,
    /// Map width in tiles.
    pub map_width: u32,
    /// Map height in tiles.
    pub map_height: u32,
    /// Flat tile ID array (row-major, `map_width × map_height`).
    tile_data: Vec<u32>,
    /// Number of columns in the tileset image.
    pub tileset_columns: u32,
    /// Tiles per chunk side (default `16`).
    pub chunk_size: u32,
    /// Chunk cache keyed by `(cx, cy)`.
    chunks: HashMap<(i32, i32), MapChunk>,
    /// Camera X position in world pixels.
    pub camera_x: f32,
    /// Camera Y position in world pixels.
    pub camera_y: f32,
    /// Camera zoom factor.
    pub camera_zoom: f32,
    /// Viewport width in screen pixels.
    pub viewport_w: f32,
    /// Viewport height in screen pixels.
    pub viewport_h: f32,
    /// Whether level-of-detail is enabled.
    pub lod_enabled: bool,
    /// Zoom thresholds at which LOD levels change (ascending).
    pub lod_thresholds: Vec<f32>,
}

impl LargeMapRenderer {
    /// Creates a new `LargeMapRenderer` with the given tile dimensions.
    ///
    /// # Parameters
    /// - `tile_w` — `u32`.
    /// - `tile_h` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// The map starts empty (0×0). Call [`set_map_data`](Self::set_map_data) to
    /// populate it.
    pub fn new(tile_w: u32, tile_h: u32) -> Self {
        Self {
            tile_width: tile_w,
            tile_height: tile_h,
            map_width: 0,
            map_height: 0,
            tile_data: Vec::new(),
            tileset_columns: 1,
            chunk_size: 16,
            chunks: HashMap::new(),
            camera_x: 0.0,
            camera_y: 0.0,
            camera_zoom: 1.0,
            viewport_w: 0.0,
            viewport_h: 0.0,
            lod_enabled: false,
            lod_thresholds: Vec::new(),
        }
    }

    // ── Map data ────────────────────────────────────────────────────────

    /// Sets the entire map tile data and rebuilds all chunks.
    ///
    /// # Parameters
    /// - `data` — Flat tile IDs (row-major). Length must equal `width × height`.
    /// - `width` — Map width in tiles.
    /// - `height` — Map height in tiles.
    pub fn set_map_data(&mut self, data: Vec<u32>, width: u32, height: u32) {
        self.map_width = width;
        self.map_height = height;
        self.tile_data = data;
        // Pad / truncate to exact size.
        let expected = (width * height) as usize;
        self.tile_data.resize(expected, 0);
        self.rebuild_chunks();
    }

    /// Sets a single tile at `(x, y)` (0-based) and marks the enclosing chunk dirty.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `tile_id` — `u32`.
    ///
    /// Does nothing if `(x, y)` is out of bounds.
    pub fn set_tile(&mut self, x: u32, y: u32, tile_id: u32) {
        if x >= self.map_width || y >= self.map_height {
            return;
        }
        let idx = (y * self.map_width + x) as usize;
        if idx < self.tile_data.len() {
            self.tile_data[idx] = tile_id;
            let cx = (x / self.chunk_size) as i32;
            let cy = (y / self.chunk_size) as i32;
            self.invalidate_chunk(cx, cy);
        }
    }

    /// Returns the tile ID at `(x, y)` (0-based), or `None` if out of bounds.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `Option<u32>`.
    pub fn get_tile(&self, x: u32, y: u32) -> Option<u32> {
        if x >= self.map_width || y >= self.map_height {
            return None;
        }
        let idx = (y * self.map_width + x) as usize;
        self.tile_data.get(idx).copied()
    }

    /// Returns the map size as `(width, height)` in tiles.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_map_size(&self) -> (u32, u32) {
        (self.map_width, self.map_height)
    }

    // ── Chunk management ────────────────────────────────────────────────

    /// Changes the chunk size (tiles per side) and rebuilds all chunks.
    ///
    /// # Parameters
    /// - `size` — `u32`.
    pub fn set_chunk_size(&mut self, size: u32) {
        self.chunk_size = size.max(1);
        self.rebuild_chunks();
    }

    /// Returns the current chunk size (tiles per side).
    ///
    /// # Returns
    /// `u32`.
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }

    /// Marks a specific chunk as dirty (needs rebuild).
    ///
    /// # Parameters
    /// - `cx` — `i32`.
    /// - `cy` — `i32`.
    pub fn invalidate_chunk(&mut self, cx: i32, cy: i32) {
        if let Some(chunk) = self.chunks.get_mut(&(cx, cy)) {
            chunk.dirty = true;
        }
    }

    /// Marks all chunks as dirty. Consult the module-level documentation for the broader usage context and preconditions.
    pub fn invalidate_all(&mut self) {
        for chunk in self.chunks.values_mut() {
            chunk.dirty = true;
        }
    }

    /// Returns the number of chunks currently visible given the camera
    ///
    /// # Returns
    /// `usize`.
    /// position, zoom, and viewport.
    pub fn get_visible_chunks(&self) -> usize {
        if self.chunk_size == 0 {
            return 0;
        }
        let (min_cx, max_cx, min_cy, max_cy) = self.visible_chunk_range();
        let mut count = 0;
        for cy in min_cy..=max_cy {
            for cx in min_cx..=max_cx {
                if self.chunks.contains_key(&(cx, cy)) {
                    count += 1;
                }
            }
        }
        count
    }

    /// Returns the total number of chunks. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_total_chunks(&self) -> usize {
        self.chunks.len()
    }

    /// Returns a reference to the chunk map for rendering.
    ///
    /// # Returns
    /// `&HashMap<(i32, i32), MapChunk>`.
    pub fn chunks(&self) -> &HashMap<(i32, i32), MapChunk> {
        &self.chunks
    }

    // ── Camera / viewport ───────────────────────────────────────────────

    /// Sets the camera position and zoom. Replaces the current camera value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `zoom` — `f32`.
    pub fn set_camera(&mut self, x: f32, y: f32, zoom: f32) {
        self.camera_x = x;
        self.camera_y = y;
        self.camera_zoom = zoom;
    }

    /// Sets the viewport size in screen pixels.
    ///
    /// # Parameters
    /// - `w` — `f32`.
    /// - `h` — `f32`.
    pub fn set_viewport(&mut self, w: f32, h: f32) {
        self.viewport_w = w;
        self.viewport_h = h;
    }

    // ── LOD ─────────────────────────────────────────────────────────────

    /// Enables or disables level-of-detail rendering.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_lod_enabled(&mut self, enabled: bool) {
        self.lod_enabled = enabled;
    }

    /// Returns whether LOD is enabled. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_lod_enabled(&self) -> bool {
        self.lod_enabled
    }

    /// Sets the zoom thresholds at which LOD levels change.
    ///
    /// # Parameters
    /// - `levels` — `Vec<f32>`.
    pub fn set_lod_thresholds(&mut self, levels: Vec<f32>) {
        self.lod_thresholds = levels;
    }

    // ── Tileset ─────────────────────────────────────────────────────────

    /// Sets the number of columns in the tileset image.
    ///
    /// # Parameters
    /// - `cols` — `u32`.
    pub fn set_tileset_columns(&mut self, cols: u32) {
        self.tileset_columns = cols.max(1);
    }

    /// Returns the number of tileset columns. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tileset_columns(&self) -> u32 {
        self.tileset_columns
    }

    // ── Internal ────────────────────────────────────────────────────────

    /// Rebuilds all chunks from the current tile data.
    fn rebuild_chunks(&mut self) {
        self.chunks.clear();
        if self.chunk_size == 0 || self.map_width == 0 || self.map_height == 0 {
            return;
        }
        let cols_chunks = self.map_width.div_ceil(self.chunk_size) as i32;
        let rows_chunks = self.map_height.div_ceil(self.chunk_size) as i32;

        for cy in 0..rows_chunks {
            for cx in 0..cols_chunks {
                let mut tile_ids = Vec::new();
                let start_x = cx as u32 * self.chunk_size;
                let start_y = cy as u32 * self.chunk_size;
                let end_x = (start_x + self.chunk_size).min(self.map_width);
                let end_y = (start_y + self.chunk_size).min(self.map_height);

                for ty in start_y..end_y {
                    for tx in start_x..end_x {
                        let idx = (ty * self.map_width + tx) as usize;
                        tile_ids.push(self.tile_data.get(idx).copied().unwrap_or(0));
                    }
                }

                self.chunks.insert(
                    (cx, cy),
                    MapChunk {
                        cx,
                        cy,
                        dirty: false,
                        tile_ids,
                    },
                );
            }
        }
    }

    /// Computes the range of chunk indices visible given the current camera
    /// state. Returns `(min_cx, max_cx, min_cy, max_cy)`.
    fn visible_chunk_range(&self) -> (i32, i32, i32, i32) {
        // Zero viewport means no culling — return the full map extent.
        if self.viewport_w <= 0.0 || self.viewport_h <= 0.0 {
            let chunks_x = ((self.map_width as i32 * self.tile_width as i32)
                .max(1) + self.chunk_size as i32 - 1)
                / self.chunk_size as i32;
            let chunks_y = ((self.map_height as i32 * self.tile_height as i32)
                .max(1) + self.chunk_size as i32 - 1)
                / self.chunk_size as i32;
            return (-1, chunks_x, -1, chunks_y);
        }
        let zoom = if self.camera_zoom.abs() > f32::EPSILON {
            self.camera_zoom
        } else {
            1.0
        };
        let half_w = self.viewport_w * 0.5 / zoom;
        let half_h = self.viewport_h * 0.5 / zoom;

        let world_left = self.camera_x - half_w;
        let world_right = self.camera_x + half_w;
        let world_top = self.camera_y - half_h;
        let world_bottom = self.camera_y + half_h;

        let chunk_w = self.chunk_size as f32 * self.tile_width as f32;
        let chunk_h = self.chunk_size as f32 * self.tile_height as f32;

        let min_cx = if chunk_w > 0.0 {
            (world_left / chunk_w).floor() as i32
        } else {
            0
        };
        let max_cx = if chunk_w > 0.0 {
            (world_right / chunk_w).floor() as i32
        } else {
            0
        };
        let min_cy = if chunk_h > 0.0 {
            (world_top / chunk_h).floor() as i32
        } else {
            0
        };
        let max_cy = if chunk_h > 0.0 {
            (world_bottom / chunk_h).floor() as i32
        } else {
            0
        };

        (min_cx, max_cx, min_cy, max_cy)
    }
}

impl Default for LargeMapRenderer {
    fn default() -> Self {
        Self::new(32, 32)
    }
}

// ── Unit tests ──────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_renderer_is_empty() {
        let r = LargeMapRenderer::new(32, 32);
        assert_eq!(r.get_map_size(), (0, 0));
        assert_eq!(r.get_total_chunks(), 0);
    }

    #[test]
    fn set_map_data_creates_chunks() {
        let mut r = LargeMapRenderer::new(16, 16);
        r.set_chunk_size(4);
        // 8x8 map with chunk_size=4 → 2x2 = 4 chunks
        let data = vec![1u32; 64];
        r.set_map_data(data, 8, 8);
        assert_eq!(r.get_total_chunks(), 4);
    }

    #[test]
    fn set_and_get_tile() {
        let mut r = LargeMapRenderer::new(16, 16);
        r.set_map_data(vec![0; 25], 5, 5);
        r.set_tile(2, 3, 42);
        assert_eq!(r.get_tile(2, 3), Some(42));
        assert_eq!(r.get_tile(0, 0), Some(0));
        assert_eq!(r.get_tile(99, 99), None);
    }

    #[test]
    fn set_tile_marks_chunk_dirty() {
        let mut r = LargeMapRenderer::new(16, 16);
        r.set_chunk_size(4);
        r.set_map_data(vec![0; 64], 8, 8);
        // All start clean after rebuild.
        assert!(!r.chunks[&(0, 0)].dirty);
        r.set_tile(1, 1, 5);
        assert!(r.chunks[&(0, 0)].dirty);
    }

    #[test]
    fn visible_chunks_with_centered_camera() {
        let mut r = LargeMapRenderer::new(16, 16);
        r.set_chunk_size(4);
        r.set_map_data(vec![0; 256], 16, 16); // 16x16 tiles → 4x4 chunks
        r.set_camera(128.0, 128.0, 1.0);
        r.set_viewport(256.0, 256.0);
        let vis = r.get_visible_chunks();
        // Camera at centre of a 256x256 world with 256x256 viewport → all 16 chunks visible
        assert!(vis > 0);
        assert!(vis <= 16);
    }

    #[test]
    fn invalidate_all_marks_every_chunk() {
        let mut r = LargeMapRenderer::new(16, 16);
        r.set_chunk_size(4);
        r.set_map_data(vec![0; 64], 8, 8);
        r.invalidate_all();
        for chunk in r.chunks.values() {
            assert!(chunk.dirty);
        }
    }

    #[test]
    fn chunk_size_change_rebuilds() {
        let mut r = LargeMapRenderer::new(16, 16);
        r.set_map_data(vec![0; 64], 8, 8);
        let total_before = r.get_total_chunks();
        r.set_chunk_size(2);
        let total_after = r.get_total_chunks();
        assert!(total_after > total_before); // smaller chunks → more of them
    }

    #[test]
    fn tileset_columns_clamp_to_one() {
        let mut r = LargeMapRenderer::new(16, 16);
        r.set_tileset_columns(0);
        assert_eq!(r.get_tileset_columns(), 1);
    }
}
