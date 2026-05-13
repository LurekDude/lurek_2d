use crate::log_msg;
use crate::math::Rect;
use crate::runtime::log_messages::{CK01, CK02, CK03};
use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct ChunkMap {
    chunk_size: u32,
    chunks: HashMap<(i32, i32), Vec<u32>>,
}
impl ChunkMap {
    pub const DEFAULT_GID: u32 = 0;
    pub fn new(chunk_size: u32) -> Self {
        assert!(chunk_size >= 1, "chunk_size must be >= 1");
        log_msg!(debug, CK01, "chunk_size={}", chunk_size);
        Self {
            chunk_size,
            chunks: HashMap::new(),
        }
    }
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }
    pub fn get_tile(&self, x: i32, y: i32) -> u32 {
        let (cx, cy, lx, ly) = self.decompose(x, y);
        match self.chunks.get(&(cx, cy)) {
            Some(chunk) => chunk[(ly * self.chunk_size + lx) as usize],
            None => Self::DEFAULT_GID,
        }
    }
    pub fn set_tile(&mut self, x: i32, y: i32, gid: u32) {
        let (cx, cy, lx, ly) = self.decompose(x, y);
        let cs = self.chunk_size;
        let chunk = self
            .chunks
            .entry((cx, cy))
            .or_insert_with(|| vec![0u32; (cs * cs) as usize]);
        chunk[(ly * cs + lx) as usize] = gid;
    }
    pub fn clear_tile(&mut self, x: i32, y: i32) {
        self.set_tile(x, y, 0);
    }
    pub fn fill_rect(&mut self, x0: i32, y0: i32, x1: i32, y1: i32, gid: u32) {
        for y in y0..y1 {
            for x in x0..x1 {
                self.set_tile(x, y, gid);
            }
        }
    }
    pub fn load_chunk(&mut self, cx: i32, cy: i32) {
        log_msg!(debug, CK02, "({}, {})", cx, cy);
        let cs = self.chunk_size;
        self.chunks
            .entry((cx, cy))
            .or_insert_with(|| vec![0u32; (cs * cs) as usize]);
    }
    pub fn unload_chunk(&mut self, cx: i32, cy: i32) {
        log_msg!(debug, CK03, "({}, {})", cx, cy);
        self.chunks.remove(&(cx, cy));
    }
    pub fn get_loaded_chunks(&self) -> Vec<(i32, i32)> {
        self.chunks.keys().copied().collect()
    }
    pub fn get_loaded_chunk_count(&self) -> usize {
        self.chunks.len()
    }
    pub fn is_chunk_loaded(&self, cx: i32, cy: i32) -> bool {
        self.chunks.contains_key(&(cx, cy))
    }
    pub fn tile_to_chunk(&self, x: i32, y: i32) -> (i32, i32) {
        let cs = self.chunk_size as i32;
        (x.div_euclid(cs), y.div_euclid(cs))
    }
    pub fn chunk_tile_range(&self, cx: i32, cy: i32) -> (i32, i32, i32, i32) {
        let cs = self.chunk_size as i32;
        (cx * cs, cy * cs, cx * cs + cs, cy * cs + cs)
    }
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
    pub fn chunk_world_rect(&self, cx: i32, cy: i32, tw: f32, th: f32) -> Rect {
        let cs = self.chunk_size as f32;
        Rect::new(cx as f32 * cs * tw, cy as f32 * cs * th, cs * tw, cs * th)
    }
    pub fn iter_chunk(&self, cx: i32, cy: i32) -> Option<&[u32]> {
        self.chunks.get(&(cx, cy)).map(|v| v.as_slice())
    }
    fn decompose(&self, x: i32, y: i32) -> (i32, i32, u32, u32) {
        let cs = self.chunk_size as i32;
        let cx = x.div_euclid(cs);
        let cy = y.div_euclid(cs);
        let lx = x.rem_euclid(cs) as u32;
        let ly = y.rem_euclid(cs) as u32;
        (cx, cy, lx, ly)
    }
}
