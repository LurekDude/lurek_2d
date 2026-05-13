use super::body::{Body, BodyShape, BodyType};
use super::world::World;
use std::collections::{HashMap, HashSet};
const CHUNK_SIZE: u32 = 16;
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct ChunkId {
    pub cx: u32,
    pub cy: u32,
}
pub struct TerrainMap {
    pub width: u32,
    pub height: u32,
    pub cell_size: f32,
    pub offset_x: f32,
    pub offset_y: f32,
    cells: Vec<bool>,
    chunk_body_ids: HashMap<ChunkId, Vec<usize>>,
    dirty_chunks: HashSet<ChunkId>,
}
impl TerrainMap {
    pub fn new(width: u32, height: u32, cell_size: f32) -> Self {
        let total = (width * height) as usize;
        Self {
            width,
            height,
            cell_size,
            offset_x: 0.0,
            offset_y: 0.0,
            cells: vec![false; total],
            chunk_body_ids: HashMap::new(),
            dirty_chunks: HashSet::new(),
        }
    }
    pub fn set_cell(&mut self, cx: u32, cy: u32, solid: bool) {
        if cx >= self.width || cy >= self.height {
            return;
        }
        let idx = (cy * self.width + cx) as usize;
        if self.cells[idx] != solid {
            self.cells[idx] = solid;
            self.mark_dirty(cx, cy);
        }
    }
    pub fn get_cell(&self, cx: u32, cy: u32) -> bool {
        if cx >= self.width || cy >= self.height {
            return false;
        }
        self.cells[(cy * self.width + cx) as usize]
    }
    pub fn fill_circle(&mut self, wx: f32, wy: f32, radius: f32, solid: bool) {
        let cell_cx = ((wx - self.offset_x) / self.cell_size) as i64;
        let cell_cy = ((wy - self.offset_y) / self.cell_size) as i64;
        let cell_r = (radius / self.cell_size).ceil() as i64 + 1;
        let r2 = radius * radius;
        for dy in -cell_r..=cell_r {
            for dx in -cell_r..=cell_r {
                let cx = cell_cx + dx;
                let cy = cell_cy + dy;
                if cx < 0 || cy < 0 || cx >= self.width as i64 || cy >= self.height as i64 {
                    continue;
                }
                let world_x = self.offset_x + (cx as f32 + 0.5) * self.cell_size;
                let world_y = self.offset_y + (cy as f32 + 0.5) * self.cell_size;
                let ddx = world_x - wx;
                let ddy = world_y - wy;
                if ddx * ddx + ddy * ddy <= r2 {
                    self.set_cell(cx as u32, cy as u32, solid);
                }
            }
        }
    }
    pub fn fill_rect(&mut self, wx: f32, wy: f32, w: f32, h: f32, solid: bool) {
        let x0 = ((wx - self.offset_x) / self.cell_size).floor() as i64;
        let y0 = ((wy - self.offset_y) / self.cell_size).floor() as i64;
        let x1 = ((wx + w - self.offset_x) / self.cell_size).ceil() as i64;
        let y1 = ((wy + h - self.offset_y) / self.cell_size).ceil() as i64;
        for cy in y0..y1 {
            for cx in x0..x1 {
                if cx >= 0 && cy >= 0 && cx < self.width as i64 && cy < self.height as i64 {
                    self.set_cell(cx as u32, cy as u32, solid);
                }
            }
        }
    }
    pub fn fill_all(&mut self, solid: bool) {
        for v in self.cells.iter_mut() {
            *v = solid;
        }
        let chunk_cols = self.width.div_ceil(CHUNK_SIZE);
        let chunk_rows = self.height.div_ceil(CHUNK_SIZE);
        for cy in 0..chunk_rows {
            for cx in 0..chunk_cols {
                self.dirty_chunks.insert(ChunkId { cx, cy });
            }
        }
    }
    pub fn is_dirty(&self) -> bool {
        !self.dirty_chunks.is_empty()
    }
    fn mark_dirty(&mut self, cx: u32, cy: u32) {
        self.dirty_chunks.insert(ChunkId {
            cx: cx / CHUNK_SIZE,
            cy: cy / CHUNK_SIZE,
        });
    }
    pub fn flush(&mut self, world: &mut World) {
        let dirty: Vec<ChunkId> = self.dirty_chunks.drain().collect();
        for chunk in dirty {
            if let Some(old_ids) = self.chunk_body_ids.remove(&chunk) {
                for id in old_ids {
                    world.destroy_body(id);
                }
            }
            let cell_x0 = chunk.cx * CHUNK_SIZE;
            let cell_y0 = chunk.cy * CHUNK_SIZE;
            let cell_x1 = (cell_x0 + CHUNK_SIZE).min(self.width);
            let cell_y1 = (cell_y0 + CHUNK_SIZE).min(self.height);
            let mut new_ids: Vec<usize> = Vec::new();
            for cy in cell_y0..cell_y1 {
                let mut run_start: Option<u32> = None;
                for cx in cell_x0..=cell_x1 {
                    let solid = if cx < cell_x1 {
                        self.cells[(cy * self.width + cx) as usize]
                    } else {
                        false
                    };
                    match (solid, run_start) {
                        (true, None) => run_start = Some(cx),
                        (false, Some(start)) => {
                            let run_len = cx - start;
                            let bx = self.offset_x
                                + (start as f32 + run_len as f32 * 0.5) * self.cell_size;
                            let by = self.offset_y + (cy as f32 + 0.5) * self.cell_size;
                            let bw = run_len as f32 * self.cell_size;
                            let bh = self.cell_size;
                            let mut body = Body::new(bx, by, BodyType::Static);
                            body.shape = BodyShape::Rect {
                                width: bw,
                                height: bh,
                            };
                            body.width = bw;
                            body.height = bh;
                            body.restitution = 0.0;
                            body.friction = 0.8;
                            new_ids.push(world.add_body(body));
                            run_start = None;
                        }
                        _ => {}
                    }
                }
            }
            if !new_ids.is_empty() {
                self.chunk_body_ids.insert(chunk, new_ids);
            }
        }
    }
    pub fn collapse_columns(&mut self) -> u32 {
        let mut count = 0u32;
        for cy in (0..self.height.saturating_sub(1)).rev() {
            for cx in 0..self.width {
                let idx = (cy * self.width + cx) as usize;
                if !self.cells[idx] {
                    continue;
                }
                let below = self.cells[((cy + 1) * self.width + cx) as usize];
                if !below {
                    let left = cx > 0 && self.cells[(cy * self.width + cx - 1) as usize];
                    let right =
                        cx + 1 < self.width && self.cells[(cy * self.width + cx + 1) as usize];
                    if !left && !right {
                        self.cells[idx] = false;
                        self.mark_dirty(cx, cy);
                        count += 1;
                    }
                }
            }
        }
        count
    }
    pub fn solid_cell_positions(&self) -> Vec<(f32, f32)> {
        let mut out = Vec::new();
        for cy in 0..self.height {
            for cx in 0..self.width {
                if self.cells[(cy * self.width + cx) as usize] {
                    let wx = self.offset_x + (cx as f32 + 0.5) * self.cell_size;
                    let wy = self.offset_y + (cy as f32 + 0.5) * self.cell_size;
                    out.push((wx, wy));
                }
            }
        }
        out
    }
    pub fn spawn_debris_at(
        &self,
        world: &mut World,
        positions: &[(f32, f32)],
        cell_mass: f32,
        restitution: f32,
    ) -> Vec<usize> {
        positions
            .iter()
            .map(|&(wx, wy)| {
                let mut b = Body::new(wx, wy, BodyType::Dynamic);
                b.shape = BodyShape::Rect {
                    width: self.cell_size,
                    height: self.cell_size,
                };
                b.width = self.cell_size;
                b.height = self.cell_size;
                b.mass = cell_mass;
                b.restitution = restitution;
                world.add_body(b)
            })
            .collect()
    }
    pub fn to_image_data(&self, solid_rgba: [u8; 4], empty_rgba: [u8; 4]) -> Vec<u8> {
        let mut buf = Vec::with_capacity((self.width * self.height * 4) as usize);
        for &solid in &self.cells {
            let c = if solid { solid_rgba } else { empty_rgba };
            buf.extend_from_slice(&c);
        }
        buf
    }
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut buf = Vec::new();
        buf.extend_from_slice(&self.width.to_le_bytes());
        buf.extend_from_slice(&self.height.to_le_bytes());
        buf.extend_from_slice(&self.cell_size.to_bits().to_le_bytes());
        let mut bit_byte = 0u8;
        let mut bit_pos = 7i32;
        for &solid in &self.cells {
            if solid {
                bit_byte |= 1 << bit_pos;
            }
            bit_pos -= 1;
            if bit_pos < 0 {
                buf.push(bit_byte);
                bit_byte = 0;
                bit_pos = 7;
            }
        }
        if bit_pos < 7 {
            buf.push(bit_byte);
        }
        buf
    }
    #[allow(clippy::needless_range_loop)]
    pub fn from_bytes(bytes: &[u8]) -> Option<Self> {
        if bytes.len() < 12 {
            return None;
        }
        let width = u32::from_le_bytes(bytes[0..4].try_into().ok()?);
        let height = u32::from_le_bytes(bytes[4..8].try_into().ok()?);
        let cell_size_bits = u32::from_le_bytes(bytes[8..12].try_into().ok()?);
        let cell_size = f32::from_bits(cell_size_bits);
        let total = (width * height) as usize;
        let mut cells = vec![false; total];
        let bit_buf = &bytes[12..];
        for i in 0..total {
            let byte_idx = i / 8;
            let bit_idx = 7 - (i % 8);
            if let Some(&byte) = bit_buf.get(byte_idx) {
                cells[i] = (byte >> bit_idx) & 1 == 1;
            }
        }
        let chunk_cols = width.div_ceil(CHUNK_SIZE);
        let chunk_rows = height.div_ceil(CHUNK_SIZE);
        let mut dirty_chunks = HashSet::new();
        for cy in 0..chunk_rows {
            for cx in 0..chunk_cols {
                dirty_chunks.insert(ChunkId { cx, cy });
            }
        }
        Some(Self {
            width,
            height,
            cell_size,
            offset_x: 0.0,
            offset_y: 0.0,
            cells,
            chunk_body_ids: HashMap::new(),
            dirty_chunks,
        })
    }
    pub fn load_from_bytes(&mut self, bytes: &[u8]) -> bool {
        match TerrainMap::from_bytes(bytes) {
            Some(loaded) if loaded.width == self.width && loaded.height == self.height => {
                self.cells = loaded.cells;
                self.dirty_chunks = loaded.dirty_chunks;
                true
            }
            Some(_) => false,
            None => false,
        }
    }
}
