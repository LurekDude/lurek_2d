//! Chunk-based infinite tile storage for large or procedurally generated maps.
//! Owns `ChunkMap`, which partitions world space into fixed-size chunks allocated on demand.
//! Does not own rendering, tile types, or physics; callers drive chunk load/unload.
//! Depends on `math` and logging.

use crate::log_msg;
use crate::math::Rect;
use crate::runtime::log_messages::{CK01, CK02, CK03};
use std::collections::HashMap;

/// Infinite tile grid partitioned into fixed-size square chunks loaded on demand.
#[derive(Debug, Clone)]
pub struct ChunkMap {
    /// Side length in tiles of each square chunk.
    chunk_size: u32,
    /// Sparse map from chunk coordinates to flattened tile GID arrays.
    chunks: HashMap<(i32, i32), Vec<u32>>,
}
impl ChunkMap {
    /// GID value used for tiles in unloaded or unset chunks.
    pub const DEFAULT_GID: u32 = 0;

    /// Create a `ChunkMap` with the given `chunk_size`; panics when `chunk_size` is zero.
    pub fn new(chunk_size: u32) -> Self {
        assert!(chunk_size >= 1, "chunk_size must be >= 1");
        log_msg!(debug, CK01, "chunk_size={}", chunk_size);
        Self {
            chunk_size,
            chunks: HashMap::new(),
        }
    }
    /// Return the side length in tiles of each chunk.
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }

    /// Return the GID at tile `(x, y)`; returns `DEFAULT_GID` when the chunk is not loaded.
    pub fn get_tile(&self, x: i32, y: i32) -> u32 {
        let (cx, cy, lx, ly) = self.decompose(x, y);
        match self.chunks.get(&(cx, cy)) {
            Some(chunk) => chunk[(ly * self.chunk_size + lx) as usize],
            None => Self::DEFAULT_GID,
        }
    }
    /// Write `gid` to tile `(x, y)`, allocating the chunk if needed.
    pub fn set_tile(&mut self, x: i32, y: i32, gid: u32) {
        let (cx, cy, lx, ly) = self.decompose(x, y);
        let cs = self.chunk_size;
        let chunk = self
            .chunks
            .entry((cx, cy))
            .or_insert_with(|| vec![0u32; (cs * cs) as usize]);
        chunk[(ly * cs + lx) as usize] = gid;
    }
    /// Reset tile `(x, y)` to GID 0, allocating the chunk if needed.
    pub fn clear_tile(&mut self, x: i32, y: i32) {
        self.set_tile(x, y, 0);
    }

    /// Fill all tiles in the rectangle `[x0,x1) × [y0,y1)` with `gid`.
    pub fn fill_rect(&mut self, x0: i32, y0: i32, x1: i32, y1: i32, gid: u32) {
        for y in y0..y1 {
            for x in x0..x1 {
                self.set_tile(x, y, gid);
            }
        }
    }
    /// Ensure the chunk at `(cx, cy)` is allocated; no-op when already loaded.
    pub fn load_chunk(&mut self, cx: i32, cy: i32) {
        log_msg!(debug, CK02, "({}, {})", cx, cy);
        let cs = self.chunk_size;
        self.chunks
            .entry((cx, cy))
            .or_insert_with(|| vec![0u32; (cs * cs) as usize]);
    }
    /// Discard the chunk at `(cx, cy)` and free its memory.
    pub fn unload_chunk(&mut self, cx: i32, cy: i32) {
        log_msg!(debug, CK03, "({}, {})", cx, cy);
        self.chunks.remove(&(cx, cy));
    }
    /// Return the coordinates of all currently loaded chunks.
    pub fn get_loaded_chunks(&self) -> Vec<(i32, i32)> {
        self.chunks.keys().copied().collect()
    }

    /// Return the number of currently loaded chunks.
    pub fn get_loaded_chunk_count(&self) -> usize {
        self.chunks.len()
    }

    /// Return `true` when the chunk at `(cx, cy)` is loaded.
    pub fn is_chunk_loaded(&self, cx: i32, cy: i32) -> bool {
        self.chunks.contains_key(&(cx, cy))
    }

    /// Convert tile coordinates `(x, y)` to their parent chunk coordinates.
    pub fn tile_to_chunk(&self, x: i32, y: i32) -> (i32, i32) {
        let cs = self.chunk_size as i32;
        (x.div_euclid(cs), y.div_euclid(cs))
    }
    /// Return the inclusive tile range `(min_x, min_y, max_x, max_y)` covered by chunk `(cx, cy)`.
    pub fn chunk_tile_range(&self, cx: i32, cy: i32) -> (i32, i32, i32, i32) {
        let cs = self.chunk_size as i32;
        (cx * cs, cy * cs, cx * cs + cs, cy * cs + cs)
    }
    /// Return all chunk coordinates overlapping a view rectangle `(vx,vy,vw,vh)` with tile size `(tw,th)`.
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
    /// Return the world-space `Rect` occupied by chunk `(cx, cy)` given tile dimensions `(tw, th)`.
    pub fn chunk_world_rect(&self, cx: i32, cy: i32, tw: f32, th: f32) -> Rect {
        let cs = self.chunk_size as f32;
        Rect::new(cx as f32 * cs * tw, cy as f32 * cs * th, cs * tw, cs * th)
    }
    /// Return the tile slice of chunk `(cx, cy)`, or `None` when the chunk is not loaded.
    pub fn iter_chunk(&self, cx: i32, cy: i32) -> Option<&[u32]> {
        self.chunks.get(&(cx, cy)).map(|v| v.as_slice())
    }

    /// Decompose world tile `(x, y)` into chunk coordinates `(cx, cy)` and local tile offsets `(lx, ly)`.
    fn decompose(&self, x: i32, y: i32) -> (i32, i32, u32, u32) {
        let cs = self.chunk_size as i32;
        let cx = x.div_euclid(cs);
        let cy = y.div_euclid(cs);
        let lx = x.rem_euclid(cs) as u32;
        let ly = y.rem_euclid(cs) as u32;
        (cx, cy, lx, ly)
    }
}
