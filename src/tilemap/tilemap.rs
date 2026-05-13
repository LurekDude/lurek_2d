use super::mapgen::MapOrientation;
use super::tileset::TileSet;
use crate::log_msg;
use crate::math::{Rect, Vec2};
use crate::runtime::log_messages::{TM01_TILEMAP_INIT, TM02_TILESET_ADD, TM03_LAYER_ADD};
use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct TileLayer {
    pub name: String,
    pub width: u32,
    pub height: u32,
    pub visible: bool,
    pub tint: [f32; 4],
    pub offset: Vec2,
    pub parallax: Vec2,
    tiles: Vec<u32>,
    tile_tints: Vec<Option<[f32; 4]>>,
}
impl TileLayer {
    fn new(name: &str, width: u32, height: u32) -> Self {
        let cap = (width * height) as usize;
        Self {
            name: name.to_string(),
            width,
            height,
            visible: true,
            tint: [1.0, 1.0, 1.0, 1.0],
            offset: Vec2::ZERO,
            parallax: Vec2::new(1.0, 1.0),
            tiles: vec![0u32; cap],
            tile_tints: vec![None; cap],
        }
    }
    fn index(&self, x: u32, y: u32) -> Option<usize> {
        if x < self.width && y < self.height {
            Some((y * self.width + x) as usize)
        } else {
            None
        }
    }
}
#[derive(Debug, Clone, Copy)]
pub struct SweepResult {
    pub contact_point: Vec2,
    pub normal: Vec2,
    pub tile_x: u32,
    pub tile_y: u32,
    pub t: f32,
}
#[derive(Debug, Clone)]
pub struct TileMap {
    tile_width: u32,
    tile_height: u32,
    chunk_size: u32,
    orientation: MapOrientation,
    tilesets: Vec<TileSet>,
    layers: Vec<TileLayer>,
    tile_type_index_cache: Vec<HashMap<u32, Vec<(u32, u32)>>>,
    viewport: Option<Rect>,
    anim_timers: HashMap<u32, (usize, f32)>,
}
impl TileMap {
    pub fn new(tile_width: u32, tile_height: u32, chunk_size: u32) -> Self {
        log_msg!(
            debug,
            TM01_TILEMAP_INIT,
            "{}x{} tiles, chunk={}",
            tile_width,
            tile_height,
            chunk_size
        );
        Self {
            tile_width,
            tile_height,
            chunk_size,
            orientation: MapOrientation::TopDown,
            tilesets: Vec::new(),
            layers: Vec::new(),
            tile_type_index_cache: Vec::new(),
            viewport: None,
            anim_timers: HashMap::new(),
        }
    }
    pub fn add_tileset(&mut self, ts: TileSet) {
        log_msg!(debug, TM02_TILESET_ADD);
        self.tilesets.push(ts);
    }
    pub fn get_tileset(&self, index: usize) -> Option<&TileSet> {
        self.tilesets.get(index)
    }
    pub fn get_tileset_count(&self) -> usize {
        self.tilesets.len()
    }
    pub fn add_layer(&mut self, name: &str, width: u32, height: u32) -> usize {
        log_msg!(debug, TM03_LAYER_ADD, "{}", name);
        self.layers.push(TileLayer::new(name, width, height));
        self.tile_type_index_cache.push(HashMap::new());
        self.layers.len() - 1
    }
    pub fn get_layer_count(&self) -> usize {
        self.layers.len()
    }
    pub fn get_layer_name(&self, idx: usize) -> Option<&str> {
        self.layers.get(idx).map(|l| l.name.as_str())
    }
    pub fn set_layer_visible(&mut self, idx: usize, visible: bool) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.visible = visible;
        }
    }
    pub fn get_layer_visible(&self, idx: usize) -> bool {
        self.layers.get(idx).is_some_and(|l| l.visible)
    }
    pub fn set_layer_color(&mut self, idx: usize, r: f32, g: f32, b: f32, a: f32) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.tint = [r, g, b, a];
        }
    }
    pub fn get_layer_color(&self, idx: usize) -> [f32; 4] {
        self.layers.get(idx).map_or([0.0; 4], |l| l.tint)
    }
    pub fn set_layer_offset(&mut self, idx: usize, ox: f32, oy: f32) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.offset = Vec2::new(ox, oy);
        }
    }
    pub fn get_layer_offset(&self, idx: usize) -> Vec2 {
        self.layers.get(idx).map_or(Vec2::ZERO, |l| l.offset)
    }
    pub fn set_layer_parallax(&mut self, idx: usize, px: f32, py: f32) {
        if let Some(layer) = self.layers.get_mut(idx) {
            layer.parallax = Vec2::new(px, py);
        }
    }
    pub fn get_layer_parallax(&self, idx: usize) -> Vec2 {
        self.layers
            .get(idx)
            .map_or(Vec2::new(1.0, 1.0), |l| l.parallax)
    }
    pub fn get_layer_dimensions(&self, idx: usize) -> Option<(u32, u32)> {
        self.layers.get(idx).map(|l| (l.width, l.height))
    }
    pub fn set_tile(&mut self, layer: usize, x: u32, y: u32, gid: u32) {
        if let Some(l) = self.layers.get_mut(layer) {
            if let Some(idx) = l.index(x, y) {
                let old_gid = l.tiles[idx];
                l.tiles[idx] = gid;
                if let Some(layer_index) = self.tile_type_index_cache.get_mut(layer) {
                    if old_gid != 0 {
                        remove_pos_from_gid(layer_index, old_gid, x, y);
                    }
                    if gid != 0 {
                        layer_index.entry(gid).or_default().push((x, y));
                    }
                }
            }
        }
    }
    pub fn get_tile(&self, layer: usize, x: u32, y: u32) -> u32 {
        if let Some(l) = self.layers.get(layer) {
            if let Some(idx) = l.index(x, y) {
                return l.tiles[idx];
            }
        }
        0
    }
    #[allow(clippy::too_many_arguments)]
    pub fn set_tile_tint(&mut self, layer: usize, x: u32, y: u32, r: f32, g: f32, b: f32, a: f32) {
        if let Some(l) = self.layers.get_mut(layer) {
            if let Some(idx) = l.index(x, y) {
                l.tile_tints[idx] = Some([r, g, b, a]);
            }
        }
    }
    pub fn clear_tile(&mut self, layer: usize, x: u32, y: u32) {
        self.set_tile(layer, x, y, 0);
    }
    pub fn fill(&mut self, layer: usize, gid: u32) {
        if let Some(l) = self.layers.get_mut(layer) {
            for tile in l.tiles.iter_mut() {
                *tile = gid;
            }
            if let Some(layer_index) = self.tile_type_index_cache.get_mut(layer) {
                layer_index.clear();
                if gid != 0 {
                    let mut positions = Vec::with_capacity((l.width * l.height) as usize);
                    for y in 0..l.height {
                        for x in 0..l.width {
                            positions.push((x, y));
                        }
                    }
                    layer_index.insert(gid, positions);
                }
            }
        }
    }
    pub fn tile_type_index(&self, layer: usize) -> HashMap<u32, Vec<(u32, u32)>> {
        self.tile_type_index_cache
            .get(layer)
            .cloned()
            .unwrap_or_default()
    }
    pub fn find_tiles_by_gid(&self, layer: usize, gid: u32) -> Vec<(u32, u32)> {
        self.tile_type_index_cache
            .get(layer)
            .and_then(|idx| idx.get(&gid).cloned())
            .unwrap_or_default()
    }
    pub fn set_viewport(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport = Some(Rect::new(x, y, w, h));
    }
    pub fn get_viewport(&self) -> Option<(f32, f32, f32, f32)> {
        self.viewport.map(|v| (v.x, v.y, v.width, v.height))
    }
    pub fn update(&mut self, dt: f32) {
        let dt_ms = dt * 1000.0;
        for ts in &self.tilesets {
            let first_gid = ts.get_first_gid();
            let count = ts.get_tile_count();
            for local_id in 0..count {
                if let Some(frames) = ts.get_animation(local_id) {
                    if frames.is_empty() {
                        continue;
                    }
                    let gid = first_gid + local_id;
                    let (frame_idx, elapsed) = self.anim_timers.entry(gid).or_insert((0, 0.0));
                    *elapsed += dt_ms;
                    while *elapsed >= frames[*frame_idx].duration_ms {
                        *elapsed -= frames[*frame_idx].duration_ms;
                        *frame_idx = (*frame_idx + 1) % frames.len();
                    }
                }
            }
        }
    }
    pub fn world_to_tile(&self, wx: f32, wy: f32) -> (u32, u32) {
        let tx = if wx < 0.0 {
            0
        } else {
            (wx / self.tile_width as f32) as u32
        };
        let ty = if wy < 0.0 {
            0
        } else {
            (wy / self.tile_height as f32) as u32
        };
        (tx, ty)
    }
    pub fn tile_to_world(&self, tx: u32, ty: u32) -> (f32, f32) {
        (
            tx as f32 * self.tile_width as f32,
            ty as f32 * self.tile_height as f32,
        )
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
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }
    pub fn get_orientation(&self) -> MapOrientation {
        self.orientation
    }
    pub fn set_orientation(&mut self, orientation: MapOrientation) {
        self.orientation = orientation;
    }
    fn resolve_gid(&self, gid: u32) -> Option<(usize, u32)> {
        if gid == 0 {
            return None;
        }
        for (i, ts) in self.tilesets.iter().enumerate() {
            let first = ts.get_first_gid();
            if gid >= first && gid < first + ts.get_tile_count() {
                return Some((i, gid - first));
            }
        }
        None
    }
    pub fn is_solid(&self, layer: usize, x: u32, y: u32) -> bool {
        let gid = self.get_tile(layer, x, y);
        if let Some((ts_idx, local_id)) = self.resolve_gid(gid) {
            self.tilesets[ts_idx].is_solid(local_id)
        } else {
            false
        }
    }
    pub fn rect_overlaps_solid(&self, layer: usize, rect: Rect) -> bool {
        let (tx0, ty0) = self.world_to_tile(rect.x, rect.y);
        let (tx1, ty1) =
            self.world_to_tile(rect.x + rect.width - 0.001, rect.y + rect.height - 0.001);
        for ty in ty0..=ty1 {
            for tx in tx0..=tx1 {
                if self.is_solid(layer, tx, ty) {
                    return true;
                }
            }
        }
        false
    }
    pub fn sweep_rect(&self, layer: usize, rect: Rect, dx: f32, dy: f32) -> Option<SweepResult> {
        if dx == 0.0 && dy == 0.0 {
            return None;
        }
        let min_x = rect.x.min(rect.x + dx);
        let min_y = rect.y.min(rect.y + dy);
        let max_x = (rect.x + rect.width).max(rect.x + rect.width + dx);
        let max_y = (rect.y + rect.height).max(rect.y + rect.height + dy);
        let (tx0, ty0) = self.world_to_tile(min_x, min_y);
        let (tx1, ty1) = self.world_to_tile(max_x, max_y);
        let tw = self.tile_width as f32;
        let th = self.tile_height as f32;
        let mut best: Option<SweepResult> = None;
        for ty in ty0..=ty1 {
            for tx in tx0..=tx1 {
                if !self.is_solid(layer, tx, ty) {
                    continue;
                }
                let tile_rect = Rect::new(tx as f32 * tw, ty as f32 * th, tw, th);
                if let Some(result) = sweep_aabb_vs_aabb(rect, dx, dy, tile_rect, tx, ty) {
                    if best.is_none()
                        || result.t < best.as_ref().expect("best is Some when not is_none").t
                    {
                        best = Some(result);
                    }
                }
            }
        }
        best
    }
    pub fn apply_autotile(&mut self, layer: usize, type_name: &str) {
        let (width, height) = match self.layers.get(layer) {
            Some(l) => (l.width, l.height),
            None => return,
        };
        let mut replacements = Vec::new();
        for y in 0..height {
            for x in 0..width {
                if self.get_tile(layer, x, y) == 0 {
                    continue;
                }
                let mask = self.compute_bitmask_4(layer, x, y, width, height);
                if let Some(new_gid) = self.lookup_autotile_4(type_name, mask) {
                    replacements.push((x, y, new_gid));
                }
            }
        }
        for (x, y, gid) in replacements {
            self.set_tile(layer, x, y, gid);
        }
    }
    pub fn apply_autotile_at(&mut self, layer: usize, x: u32, y: u32, type_name: &str) {
        let (width, height) = match self.layers.get(layer) {
            Some(l) => (l.width, l.height),
            None => return,
        };
        let mut replacements = Vec::new();
        let x_start = x.saturating_sub(1);
        let y_start = y.saturating_sub(1);
        let x_end = (x + 1).min(width - 1);
        let y_end = (y + 1).min(height - 1);
        for ny in y_start..=y_end {
            for nx in x_start..=x_end {
                if self.get_tile(layer, nx, ny) == 0 {
                    continue;
                }
                let mask = self.compute_bitmask_4(layer, nx, ny, width, height);
                if let Some(new_gid) = self.lookup_autotile_4(type_name, mask) {
                    replacements.push((nx, ny, new_gid));
                }
            }
        }
        for (x, y, gid) in replacements {
            self.set_tile(layer, x, y, gid);
        }
    }
    pub fn apply_autotile_8(&mut self, layer: usize, type_name: &str) {
        let (width, height) = match self.layers.get(layer) {
            Some(l) => (l.width, l.height),
            None => return,
        };
        let mut replacements = Vec::new();
        for y in 0..height {
            for x in 0..width {
                if self.get_tile(layer, x, y) == 0 {
                    continue;
                }
                let mask = self.compute_bitmask_8(layer, x, y, width, height);
                if let Some(new_gid) = self.lookup_autotile_8(type_name, mask) {
                    replacements.push((x, y, new_gid));
                }
            }
        }
        for (x, y, gid) in replacements {
            self.set_tile(layer, x, y, gid);
        }
    }
    pub fn apply_autotile_8_at(&mut self, layer: usize, x: u32, y: u32, type_name: &str) {
        let (width, height) = match self.layers.get(layer) {
            Some(l) => (l.width, l.height),
            None => return,
        };
        let mut replacements = Vec::new();
        let x_start = x.saturating_sub(1);
        let y_start = y.saturating_sub(1);
        let x_end = (x + 1).min(width - 1);
        let y_end = (y + 1).min(height - 1);
        for ny in y_start..=y_end {
            for nx in x_start..=x_end {
                if self.get_tile(layer, nx, ny) == 0 {
                    continue;
                }
                let mask = self.compute_bitmask_8(layer, nx, ny, width, height);
                if let Some(new_gid) = self.lookup_autotile_8(type_name, mask) {
                    replacements.push((nx, ny, new_gid));
                }
            }
        }
        for (x, y, gid) in replacements {
            self.set_tile(layer, x, y, gid);
        }
    }
    fn compute_bitmask_4(&self, layer: usize, x: u32, y: u32, width: u32, height: u32) -> u8 {
        let mut mask = 0u8;
        if y > 0 && self.get_tile(layer, x, y - 1) != 0 {
            mask |= 1;
        }
        if x + 1 < width && self.get_tile(layer, x + 1, y) != 0 {
            mask |= 2;
        }
        if y + 1 < height && self.get_tile(layer, x, y + 1) != 0 {
            mask |= 4;
        }
        if x > 0 && self.get_tile(layer, x - 1, y) != 0 {
            mask |= 8;
        }
        mask
    }
    fn compute_bitmask_8(&self, layer: usize, x: u32, y: u32, width: u32, height: u32) -> u16 {
        let n = y > 0 && self.get_tile(layer, x, y - 1) != 0;
        let e = x + 1 < width && self.get_tile(layer, x + 1, y) != 0;
        let s = y + 1 < height && self.get_tile(layer, x, y + 1) != 0;
        let w = x > 0 && self.get_tile(layer, x - 1, y) != 0;
        let mut mask: u16 = 0;
        if n {
            mask |= 1;
        }
        if e {
            mask |= 2;
        }
        if s {
            mask |= 4;
        }
        if w {
            mask |= 8;
        }
        if n && e && y > 0 && x + 1 < width && self.get_tile(layer, x + 1, y - 1) != 0 {
            mask |= 16;
        }
        if s && e && y + 1 < height && x + 1 < width && self.get_tile(layer, x + 1, y + 1) != 0 {
            mask |= 32;
        }
        if s && w && y + 1 < height && x > 0 && self.get_tile(layer, x - 1, y + 1) != 0 {
            mask |= 64;
        }
        if n && w && y > 0 && x > 0 && self.get_tile(layer, x - 1, y - 1) != 0 {
            mask |= 128;
        }
        mask
    }
    fn lookup_autotile_4(&self, type_name: &str, bitmask: u8) -> Option<u32> {
        for ts in &self.tilesets {
            if let Some(local_id) = ts.get_auto_tile_id(type_name, bitmask) {
                return Some(ts.get_first_gid() + local_id);
            }
        }
        None
    }
    fn lookup_autotile_8(&self, type_name: &str, bitmask: u16) -> Option<u32> {
        for ts in &self.tilesets {
            if let Some(local_id) = ts.get_auto_tile_id_8(type_name, bitmask) {
                return Some(ts.get_first_gid() + local_id);
            }
        }
        None
    }
    pub fn draw_to_image(&self, tile_size: u32) -> crate::image::ImageData {
        if self.layers.is_empty() {
            return crate::image::ImageData::new(1, 1);
        }
        let lw = self.layers[0].width;
        let lh = self.layers[0].height;
        let mut img = crate::image::ImageData::new(lw * tile_size, lh * tile_size);
        img.fill(20, 20, 30, 255);
        for (li, layer) in self.layers.iter().enumerate() {
            let w = layer.width.min(lw);
            let h = layer.height.min(lh);
            for y in 0..h {
                for x in 0..w {
                    let idx = layer.index(x, y).unwrap_or(0);
                    let gid = layer.tiles[idx];
                    if gid == 0 && li > 0 {
                        continue;
                    }
                    if gid >= 10 {
                        let (r, g, b) = match gid {
                            10 => (200u8, 50, 50),
                            11 => (50, 50, 200),
                            12 => (200, 200, 50),
                            _ => (255, 255, 255),
                        };
                        let cx = (x * tile_size + tile_size / 2) as i32;
                        let cy = (y * tile_size + tile_size / 2) as i32;
                        img.draw_circle(cx, cy, 6, r, g, b, 255);
                    } else {
                        let (r, g, b) = match gid {
                            1 => (80u8, 160, 80),
                            2 => (60, 120, 60),
                            _ => (40, 40, 40),
                        };
                        for py in 0..tile_size {
                            for px in 0..tile_size {
                                img.set_pixel(x * tile_size + px, y * tile_size + py, r, g, b, 255);
                            }
                        }
                        if li == 0 {
                            for px in 0..tile_size {
                                img.set_pixel(x * tile_size + px, y * tile_size, 30, 30, 50, 255);
                            }
                            for py in 0..tile_size {
                                img.set_pixel(x * tile_size, y * tile_size + py, 30, 30, 50, 255);
                            }
                        }
                    }
                }
            }
        }
        img
    }
    pub fn build_render_commands(
        &self,
        offset_x: f32,
        offset_y: f32,
    ) -> Vec<crate::render::renderer::RenderCommand> {
        use crate::render::renderer::{DrawMode, RenderCommand};
        let mut cmds: Vec<RenderCommand> = Vec::new();
        if self.layers.is_empty() {
            return cmds;
        }
        let lw = self.layers[0].width;
        let lh = self.layers[0].height;
        let tw = self.tile_width as f32;
        let th = self.tile_height as f32;
        for (li, layer) in self.layers.iter().enumerate() {
            if !layer.visible {
                continue;
            }
            let w = layer.width.min(lw);
            let h = layer.height.min(lh);
            for y in 0..h {
                for x in 0..w {
                    let idx = layer.index(x, y).unwrap_or(0);
                    let gid = layer.tiles[idx];
                    if gid == 0 && li > 0 {
                        continue;
                    }
                    let (r, g, b): (f32, f32, f32) = if gid >= 10 {
                        match gid {
                            10 => (200.0 / 255.0, 50.0 / 255.0, 50.0 / 255.0),
                            11 => (50.0 / 255.0, 50.0 / 255.0, 200.0 / 255.0),
                            12 => (200.0 / 255.0, 200.0 / 255.0, 50.0 / 255.0),
                            _ => (1.0, 1.0, 1.0),
                        }
                    } else {
                        match gid {
                            1 => (80.0 / 255.0, 160.0 / 255.0, 80.0 / 255.0),
                            2 => (60.0 / 255.0, 120.0 / 255.0, 60.0 / 255.0),
                            _ => (40.0 / 255.0, 40.0 / 255.0, 40.0 / 255.0),
                        }
                    };
                    let tint = layer.tile_tints[idx].unwrap_or(layer.tint);
                    cmds.push(RenderCommand::SetColor(
                        r * tint[0],
                        g * tint[1],
                        b * tint[2],
                        tint[3],
                    ));
                    if gid >= 10 {
                        let cx = offset_x + x as f32 * tw + tw * 0.5;
                        let cy = offset_y + y as f32 * th + th * 0.5;
                        cmds.push(RenderCommand::Circle {
                            mode: DrawMode::Fill,
                            x: cx,
                            y: cy,
                            r: 6.0,
                        });
                    } else {
                        cmds.push(RenderCommand::Rectangle {
                            mode: DrawMode::Fill,
                            x: offset_x + x as f32 * tw,
                            y: offset_y + y as f32 * th,
                            w: tw,
                            h: th,
                        });
                    }
                }
            }
        }
        cmds
    }
    pub fn draw_with_highlight_to_image(
        &self,
        img_width: u32,
        img_height: u32,
        world_points: &[(f32, f32, u8, u8, u8)],
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(img_width, img_height);
        img.fill(30, 30, 40, 255);
        let mut x = 0u32;
        while x <= img_width {
            img.draw_line(
                x as i32,
                0,
                x as i32,
                img_height as i32 - 1,
                60,
                60,
                80,
                255,
            );
            x += self.tile_width;
        }
        let mut y = 0u32;
        while y <= img_height {
            img.draw_line(0, y as i32, img_width as i32 - 1, y as i32, 60, 60, 80, 255);
            y += self.tile_height;
        }
        for &(wx, wy, r, g, b) in world_points {
            let (tx, ty) = self.world_to_tile(wx, wy);
            let cell_x = tx * self.tile_width;
            let cell_y = ty * self.tile_height;
            img.draw_rect(
                cell_x as i32,
                cell_y as i32,
                self.tile_width,
                self.tile_height,
                r,
                g,
                b,
                128,
            );
            img.draw_circle(wx as i32, wy as i32, 5, r, g, b, 255);
        }
        img
    }
    pub fn draw_layers_to_image(
        &self,
        tile_px: u32,
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(25, 25, 35, 255);
        let margin = 10i32;
        for layer_idx in 0..self.get_layer_count() {
            let dims = self.get_layer_dimensions(layer_idx);
            let (lw, lh) = dims.unwrap_or((0, 0));
            for y in 0..lh {
                for x in 0..lw {
                    let gid = self.get_tile(layer_idx, x, y);
                    if gid == 0 {
                        continue;
                    }
                    let px = x as i32 * tile_px as i32 + margin;
                    let py = y as i32 * tile_px as i32 + margin;
                    let (r, g, b) = match (layer_idx, gid) {
                        (0, 1) => (40u8, 80, 40),
                        (_, 2) => (120, 80, 60),
                        (_, 3) => (100, 70, 50),
                        (_, 4) => (80, 60, 40),
                        _ => (100, 100, 100),
                    };
                    if layer_idx == 0 {
                        img.draw_rect(px, py, tile_px, tile_px, r, g, b, 255);
                    } else {
                        img.draw_rect(
                            px + 1,
                            py + 1,
                            tile_px.saturating_sub(2),
                            tile_px.saturating_sub(2),
                            r,
                            g,
                            b,
                            255,
                        );
                    }
                }
            }
        }
        let label = format!("{} LAYERS", self.get_layer_count());
        img.draw_label(&label, margin, (height - 20) as i32, 200, 200, 200);
        img.draw_label("TILEMAP LAYERS OK", 80, (height - 20) as i32, 100, 255, 100);
        img
    }
    pub fn to_nav_grid(&self, layer: usize, walkable_gids: &[u32]) -> Vec<Vec<bool>> {
        let (width, height) = self.get_layer_dimensions(layer).unwrap_or((0, 0));
        let mut grid: Vec<Vec<bool>> = Vec::with_capacity(height as usize);
        for y in 0..height {
            let mut row: Vec<bool> = Vec::with_capacity(width as usize);
            for x in 0..width {
                let gid = self.get_tile(layer, x, y);
                let walkable = gid == 0 || walkable_gids.contains(&gid);
                row.push(walkable);
            }
            grid.push(row);
        }
        grid
    }
}
fn remove_pos_from_gid(layer_index: &mut HashMap<u32, Vec<(u32, u32)>>, gid: u32, x: u32, y: u32) {
    if let Some(list) = layer_index.get_mut(&gid) {
        if let Some(pos_idx) = list.iter().position(|&(px, py)| px == x && py == y) {
            list.swap_remove(pos_idx);
        }
        if list.is_empty() {
            layer_index.remove(&gid);
        }
    }
}
fn sweep_aabb_vs_aabb(
    mover: Rect,
    dx: f32,
    dy: f32,
    target: Rect,
    tile_x: u32,
    tile_y: u32,
) -> Option<SweepResult> {
    let ex = Rect::new(
        target.x - mover.width,
        target.y - mover.height,
        target.width + mover.width,
        target.height + mover.height,
    );
    let origin_x = mover.x;
    let origin_y = mover.y;
    let (t_near_x, t_far_x) = if dx != 0.0 {
        let inv = 1.0 / dx;
        let t1 = (ex.x - origin_x) * inv;
        let t2 = (ex.x + ex.width - origin_x) * inv;
        if t1 < t2 {
            (t1, t2)
        } else {
            (t2, t1)
        }
    } else {
        if origin_x < ex.x || origin_x >= ex.x + ex.width {
            return None;
        }
        (f32::NEG_INFINITY, f32::INFINITY)
    };
    let (t_near_y, t_far_y) = if dy != 0.0 {
        let inv = 1.0 / dy;
        let t1 = (ex.y - origin_y) * inv;
        let t2 = (ex.y + ex.height - origin_y) * inv;
        if t1 < t2 {
            (t1, t2)
        } else {
            (t2, t1)
        }
    } else {
        if origin_y < ex.y || origin_y >= ex.y + ex.height {
            return None;
        }
        (f32::NEG_INFINITY, f32::INFINITY)
    };
    let t_near = t_near_x.max(t_near_y);
    let t_far = t_far_x.min(t_far_y);
    if t_near >= t_far || t_far <= 0.0 || t_near >= 1.0 {
        return None;
    }
    let t = t_near.max(0.0);
    let normal = if t_near_x > t_near_y {
        Vec2::new(if dx > 0.0 { -1.0 } else { 1.0 }, 0.0)
    } else {
        Vec2::new(0.0, if dy > 0.0 { -1.0 } else { 1.0 })
    };
    let contact = Vec2::new(origin_x + dx * t, origin_y + dy * t);
    Some(SweepResult {
        contact_point: contact,
        normal,
        tile_x,
        tile_y,
        t,
    })
}
