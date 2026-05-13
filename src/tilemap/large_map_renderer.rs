use std::collections::HashMap;
#[derive(Debug)]
pub struct MapChunk {
    pub cx: i32,
    pub cy: i32,
    pub dirty: bool,
    pub tile_ids: Vec<u32>,
}
pub struct LargeMapRenderer {
    pub tile_width: u32,
    pub tile_height: u32,
    pub map_width: u32,
    pub map_height: u32,
    tile_data: Vec<u32>,
    pub tileset_columns: u32,
    pub chunk_size: u32,
    chunks: HashMap<(i32, i32), MapChunk>,
    pub camera_x: f32,
    pub camera_y: f32,
    pub camera_zoom: f32,
    pub viewport_w: f32,
    pub viewport_h: f32,
    pub lod_enabled: bool,
    pub lod_thresholds: Vec<f32>,
}
impl LargeMapRenderer {
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
    pub fn set_map_data(&mut self, data: Vec<u32>, width: u32, height: u32) {
        self.map_width = width;
        self.map_height = height;
        self.tile_data = data;
        let expected = (width * height) as usize;
        self.tile_data.resize(expected, 0);
        self.rebuild_chunks();
    }
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
    pub fn get_tile(&self, x: u32, y: u32) -> Option<u32> {
        if x >= self.map_width || y >= self.map_height {
            return None;
        }
        let idx = (y * self.map_width + x) as usize;
        self.tile_data.get(idx).copied()
    }
    pub fn get_map_size(&self) -> (u32, u32) {
        (self.map_width, self.map_height)
    }
    pub fn set_chunk_size(&mut self, size: u32) {
        self.chunk_size = size.max(1);
        self.rebuild_chunks();
    }
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }
    pub fn invalidate_chunk(&mut self, cx: i32, cy: i32) {
        if let Some(chunk) = self.chunks.get_mut(&(cx, cy)) {
            chunk.dirty = true;
        }
    }
    pub fn invalidate_all(&mut self) {
        for chunk in self.chunks.values_mut() {
            chunk.dirty = true;
        }
    }
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
    pub fn get_total_chunks(&self) -> usize {
        self.chunks.len()
    }
    pub fn chunks(&self) -> &HashMap<(i32, i32), MapChunk> {
        &self.chunks
    }
    pub fn set_camera(&mut self, x: f32, y: f32, zoom: f32) {
        self.camera_x = x;
        self.camera_y = y;
        self.camera_zoom = zoom;
    }
    pub fn set_viewport(&mut self, w: f32, h: f32) {
        self.viewport_w = w;
        self.viewport_h = h;
    }
    pub fn set_lod_enabled(&mut self, enabled: bool) {
        self.lod_enabled = enabled;
    }
    pub fn is_lod_enabled(&self) -> bool {
        self.lod_enabled
    }
    pub fn set_lod_thresholds(&mut self, levels: Vec<f32>) {
        self.lod_thresholds = levels;
    }
    pub fn set_tileset_columns(&mut self, cols: u32) {
        self.tileset_columns = cols.max(1);
    }
    pub fn get_tileset_columns(&self) -> u32 {
        self.tileset_columns
    }
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
    fn visible_chunk_range(&self) -> (i32, i32, i32, i32) {
        if self.viewport_w <= 0.0 || self.viewport_h <= 0.0 {
            let chunks_x = ((self.map_width as i32 * self.tile_width as i32).max(1)
                + self.chunk_size as i32
                - 1)
                / self.chunk_size as i32;
            let chunks_y = ((self.map_height as i32 * self.tile_height as i32).max(1)
                + self.chunk_size as i32
                - 1)
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
