//! Chunk-based tilemap storage for large and infinite maps.
//!
//! [`ChunkMap`] stores tiles in fixed-size square chunks using a [`HashMap`].
//! Only chunks that have been written to are allocated, allowing sparse, large,
//! or infinite maps without up-front memory commitment.
//!
//! Tile coordinates use `i32` to support negative positions (e.g., a map centred
//! at the origin where negative X/Y are valid map space).

use std::collections::HashMap;

use crate::runtime::log_messages::{CK01, CK02, CK03};
use crate::log_msg;
use crate::math::Rect;

/// A chunk-based tilemap that supports large and infinite maps through sparse storage.
///
/// Tiles are stored in square chunks of `chunk_size × chunk_size` tiles.  Chunks are
/// allocated on first write and can be individually unloaded to reclaim memory.
/// Reads from unloaded chunks return [`ChunkMap::DEFAULT_GID`] (0).
///
/// # Fields
/// - `chunk_size` — `u32`.
/// - `chunks` — `HashMap<(i32`.
#[derive(Debug, Clone)]
pub struct ChunkMap {
    chunk_size: u32,
    chunks: HashMap<(i32, i32), Vec<u32>>,
}

impl ChunkMap {
    /// Default GID returned for tiles in non-loaded chunks.
    pub const DEFAULT_GID: u32 = 0;

    /// Creates a new empty chunk map. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `chunk_size` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// `chunk_size` is the number of tiles along each side of a chunk.
    /// Typical values are 16, 32, or 64. Must be ≥ 1.
    pub fn new(chunk_size: u32) -> Self {
        assert!(chunk_size >= 1, "chunk_size must be >= 1");
        log_msg!(debug, CK01, "chunk_size={}", chunk_size);
        Self {
            chunk_size,
            chunks: HashMap::new(),
        }
    }

    /// Returns the chunk size (tiles per side).
    ///
    /// # Returns
    /// `u32`.
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }

    // ------------------------------------------------------------------
    // Tile access
    // ------------------------------------------------------------------

    /// Returns the GID at tile coordinate `(x, y)`.
    ///
    /// # Parameters
    /// - `x` — `i32`.
    /// - `y` — `i32`.
    ///
    /// # Returns
    /// `u32`.
    ///
    /// Returns [`Self::DEFAULT_GID`] if the chunk containing `(x, y)` is not loaded.
    pub fn get_tile(&self, x: i32, y: i32) -> u32 {
        let (cx, cy, lx, ly) = self.decompose(x, y);
        match self.chunks.get(&(cx, cy)) {
            Some(chunk) => chunk[(ly * self.chunk_size + lx) as usize],
            None => Self::DEFAULT_GID,
        }
    }

    /// Sets the GID at tile coordinate `(x, y)`.
    ///
    /// # Parameters
    /// - `x` — `i32`.
    /// - `y` — `i32`.
    /// - `gid` — `u32`.
    ///
    /// Allocates the chunk if it does not yet exist.
    pub fn set_tile(&mut self, x: i32, y: i32, gid: u32) {
        let (cx, cy, lx, ly) = self.decompose(x, y);
        let cs = self.chunk_size;
        let chunk = self
            .chunks
            .entry((cx, cy))
            .or_insert_with(|| vec![0u32; (cs * cs) as usize]);
        chunk[(ly * cs + lx) as usize] = gid;
    }

    /// Clears the tile at `(x, y)` by setting its GID to 0.
    ///
    /// # Parameters
    /// - `x` — `i32`.
    /// - `y` — `i32`.
    pub fn clear_tile(&mut self, x: i32, y: i32) {
        self.set_tile(x, y, 0);
    }

    /// Fills the rectangular tile region `[x0, x1) × [y0, y1)` with `gid`.
    ///
    /// # Parameters
    /// - `x0` — `i32`.
    /// - `y0` — `i32`.
    /// - `x1` — `i32`.
    /// - `y1` — `i32`.
    /// - `gid` — `u32`.
    pub fn fill_rect(&mut self, x0: i32, y0: i32, x1: i32, y1: i32, gid: u32) {
        for y in y0..y1 {
            for x in x0..x1 {
                self.set_tile(x, y, gid);
            }
        }
    }

    // ------------------------------------------------------------------
    // Chunk lifecycle
    // ------------------------------------------------------------------

    /// Pre-allocates the chunk at chunk coordinates `(cx, cy)`.
    ///
    /// # Parameters
    /// - `cx` — `i32`.
    /// - `cy` — `i32`.
    ///
    /// Does nothing if the chunk is already loaded.
    pub fn load_chunk(&mut self, cx: i32, cy: i32) {
        log_msg!(debug, CK02, "({}, {})", cx, cy);
        let cs = self.chunk_size;
        self.chunks
            .entry((cx, cy))
            .or_insert_with(|| vec![0u32; (cs * cs) as usize]);
    }

    /// Removes the chunk at chunk coordinates `(cx, cy)` from memory.
    ///
    /// # Parameters
    /// - `cx` — `i32`.
    /// - `cy` — `i32`.
    ///
    /// Subsequent reads from tiles in this chunk return [`Self::DEFAULT_GID`].
    pub fn unload_chunk(&mut self, cx: i32, cy: i32) {
        log_msg!(debug, CK03, "({}, {})", cx, cy);
        self.chunks.remove(&(cx, cy));
    }

    /// Returns a list of all currently loaded chunk coordinates.
    ///
    /// # Returns
    /// `Vec<(i32, i32)>`.
    pub fn get_loaded_chunks(&self) -> Vec<(i32, i32)> {
        self.chunks.keys().copied().collect()
    }

    /// Returns the number of currently loaded chunks.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_loaded_chunk_count(&self) -> usize {
        self.chunks.len()
    }

    /// Returns whether the chunk at `(cx, cy)` is currently loaded.
    ///
    /// # Parameters
    /// - `cx` — `i32`.
    /// - `cy` — `i32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_chunk_loaded(&self, cx: i32, cy: i32) -> bool {
        self.chunks.contains_key(&(cx, cy))
    }

    // ------------------------------------------------------------------
    // Coordinate helpers
    // ------------------------------------------------------------------

    /// Converts tile `(x, y)` to chunk coordinates `(cx, cy)`.
    ///
    /// # Parameters
    /// - `x` — `i32`.
    /// - `y` — `i32`.
    ///
    /// # Returns
    /// `(i32, i32)`.
    pub fn tile_to_chunk(&self, x: i32, y: i32) -> (i32, i32) {
        let cs = self.chunk_size as i32;
        (x.div_euclid(cs), y.div_euclid(cs))
    }

    /// Returns the inclusive tile coordinate range for chunk `(cx, cy)` as `(x0, y0, x1, y1)`.
    ///
    /// # Parameters
    /// - `cx` — `i32`.
    /// - `cy` — `i32`.
    ///
    /// # Returns
    /// `(i32, i32, i32, i32)`.
    ///
    /// `x1` and `y1` are **exclusive** (one past the last tile in the chunk).
    pub fn chunk_tile_range(&self, cx: i32, cy: i32) -> (i32, i32, i32, i32) {
        let cs = self.chunk_size as i32;
        (cx * cs, cy * cs, cx * cs + cs, cy * cs + cs)
    }

    /// Returns chunk coordinates whose world-pixel footprint overlaps the given viewport.
    ///
    /// # Parameters
    /// - `vx` — `f32`.
    /// - `vy` — `f32`.
    /// - `vw` — `f32`.
    /// - `vh` — `f32`.
    /// - `tw` — `f32`.
    /// - `th` — `f32`.
    ///
    /// # Returns
    /// `Vec<(i32, i32)>`.
    ///
    /// - `vx, vy` — top-left corner of the viewport in world pixels.
    /// - `vw, vh` — viewport dimensions in world pixels.
    /// - `tw, th` — tile dimensions in pixels.
    pub fn get_chunks_in_view(
        &self,
        vx: f32,
        vy: f32,
        vw: f32,
        vh: f32,
        tw: f32,
        th: f32,
    ) -> Vec<(i32, i32)> {
        let cs = self.chunk_size as f32;
        let cpw = cs * tw;
        let cph = cs * th;
        let cx_min = (vx / cpw).floor() as i32;
        let cy_min = (vy / cph).floor() as i32;
        let cx_max = ((vx + vw) / cpw).ceil() as i32;
        let cy_max = ((vy + vh) / cph).ceil() as i32;

        let mut result = Vec::new();
        for cy in cy_min..=cy_max {
            for cx in cx_min..=cx_max {
                result.push((cx, cy));
            }
        }
        result
    }

    /// Returns the world-pixel bounding rectangle of chunk `(cx, cy)`.
    ///
    /// # Parameters
    /// - `cx` — `i32`.
    /// - `cy` — `i32`.
    /// - `tw` — `f32`.
    /// - `th` — `f32`.
    ///
    /// # Returns
    /// `Rect`.
    ///
    /// `tw` and `th` are the tile dimensions in pixels.
    pub fn chunk_world_rect(&self, cx: i32, cy: i32, tw: f32, th: f32) -> Rect {
        let cs = self.chunk_size as f32;
        Rect::new(cx as f32 * cs * tw, cy as f32 * cs * th, cs * tw, cs * th)
    }

    /// Provides read-only access to the raw GID slice for chunk `(cx, cy)`.
    ///
    /// # Parameters
    /// - `cx` — `i32`.
    /// - `cy` — `i32`.
    ///
    /// # Returns
    /// `Option<&[u32]>`.
    ///
    /// Returns `None` if the chunk is not loaded.
    /// The slice is row-major: index `= local_y * chunk_size + local_x`.
    pub fn iter_chunk(&self, cx: i32, cy: i32) -> Option<&[u32]> {
        self.chunks.get(&(cx, cy)).map(|v| v.as_slice())
    }

    // ------------------------------------------------------------------
    // Internal
    // ------------------------------------------------------------------

    /// Decomposes tile `(x, y)` into `(chunk_cx, chunk_cy, local_x, local_y)`.
    fn decompose(&self, x: i32, y: i32) -> (i32, i32, u32, u32) {
        let cs = self.chunk_size as i32;
        let cx = x.div_euclid(cs);
        let cy = y.div_euclid(cs);
        let lx = x.rem_euclid(cs) as u32;
        let ly = y.rem_euclid(cs) as u32;
        (cx, cy, lx, ly)
    }
}
