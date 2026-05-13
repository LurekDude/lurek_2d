#[non_exhaustive]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IsoTilePart {
    Floor = 0,
    NorthWall = 1,
    WestWall = 2,
    Object = 3,
}
impl IsoTilePart {
    pub fn from_index(i: u32) -> Option<Self> {
        match i {
            0 => Some(Self::Floor),
            1 => Some(Self::NorthWall),
            2 => Some(Self::WestWall),
            3 => Some(Self::Object),
            _ => None,
        }
    }
    pub fn index(self) -> u32 {
        self as u32
    }
}
#[derive(Debug, Clone)]
pub struct IsoTile {
    pub parts: Vec<u32>,
}
#[derive(Debug, Clone)]
pub struct IsoLevel {
    pub width: u32,
    pub height: u32,
    pub visible: bool,
    tiles: Vec<IsoTile>,
}
impl IsoLevel {
    pub fn new(width: u32, height: u32, part_count: u32) -> Self {
        let pc = part_count as usize;
        Self {
            width,
            height,
            visible: true,
            tiles: (0..(width * height) as usize)
                .map(|_| IsoTile {
                    parts: vec![0u32; pc],
                })
                .collect(),
        }
    }
    fn index(&self, x: u32, y: u32) -> Option<usize> {
        if x < self.width && y < self.height {
            Some((y * self.width + x) as usize)
        } else {
            None
        }
    }
    pub fn get_tile(&self, x: u32, y: u32) -> Option<&IsoTile> {
        self.index(x, y).map(|i| &self.tiles[i])
    }
    pub fn get_tile_mut(&mut self, x: u32, y: u32) -> Option<&mut IsoTile> {
        self.index(x, y).map(|i| &mut self.tiles[i])
    }
}
#[derive(Debug, Clone)]
pub struct IsoDrawItem {
    pub level: u32,
    pub tile_x: u32,
    pub tile_y: u32,
    pub part: u32,
    pub gid: u32,
    pub screen_x: f32,
    pub screen_y: f32,
}
#[derive(Debug, Clone)]
pub struct IsoMap {
    pub width: u32,
    pub height: u32,
    pub tile_w: u32,
    pub tile_h: u32,
    pub level_height: u32,
    pub origin_x: f32,
    pub origin_y: f32,
    pub part_count: u32,
    pub part_order: Vec<u32>,
    levels: Vec<IsoLevel>,
}
impl IsoMap {
    pub fn new(
        width: u32,
        height: u32,
        tile_w: u32,
        tile_h: u32,
        level_height: u32,
        part_count: u32,
    ) -> Self {
        let part_count = part_count.max(1);
        Self {
            width,
            height,
            tile_w,
            tile_h,
            level_height,
            origin_x: 0.0,
            origin_y: 0.0,
            part_count,
            part_order: (0..part_count).collect(),
            levels: Vec::new(),
        }
    }
    pub fn add_level(&mut self) -> usize {
        let idx = self.levels.len();
        self.levels
            .push(IsoLevel::new(self.width, self.height, self.part_count));
        idx
    }
    pub fn get_level_count(&self) -> usize {
        self.levels.len()
    }
    pub fn set_level_visible(&mut self, z: usize, visible: bool) {
        if let Some(level) = self.levels.get_mut(z) {
            level.visible = visible;
        }
    }
    pub fn get_level_visible(&self, z: usize) -> bool {
        self.levels.get(z).is_none_or(|l| l.visible)
    }
    pub fn set_tile_part(&mut self, z: usize, x: u32, y: u32, part: u32, gid: u32) {
        if part >= self.part_count {
            return;
        }
        if let Some(level) = self.levels.get_mut(z) {
            if let Some(tile) = level.get_tile_mut(x, y) {
                if let Some(slot) = tile.parts.get_mut(part as usize) {
                    *slot = gid;
                }
            }
        }
    }
    pub fn get_tile_part(&self, z: usize, x: u32, y: u32, part: u32) -> u32 {
        if part >= self.part_count {
            return 0;
        }
        self.levels
            .get(z)
            .and_then(|l| l.get_tile(x, y))
            .map_or(0, |t| t.parts.get(part as usize).copied().unwrap_or(0))
    }
    pub fn fill_level(&mut self, z: usize, part: u32, gid: u32) {
        if part >= self.part_count {
            return;
        }
        if let Some(level) = self.levels.get_mut(z) {
            for tile in level.tiles.iter_mut() {
                if let Some(slot) = tile.parts.get_mut(part as usize) {
                    *slot = gid;
                }
            }
        }
    }
    pub fn set_origin(&mut self, x: f32, y: f32) {
        self.origin_x = x;
        self.origin_y = y;
    }
    pub fn tile_to_screen(&self, tx: f32, ty: f32, tz: f32) -> (f32, f32) {
        let hw = self.tile_w as f32 / 2.0;
        let hh = self.tile_h as f32 / 2.0;
        let sx = self.origin_x + (tx - ty) * hw;
        let sy = self.origin_y + (tx + ty) * hh - tz * self.level_height as f32;
        (sx, sy)
    }
    pub fn screen_to_tile(&self, sx: f32, sy: f32) -> (f32, f32) {
        let rel_x = sx - self.origin_x;
        let rel_y = sy - self.origin_y;
        let hw = self.tile_w as f32 / 2.0;
        let hh = self.tile_h as f32 / 2.0;
        let tx = (rel_x / hw + rel_y / hh) / 2.0;
        let ty = (rel_y / hh - rel_x / hw) / 2.0;
        (tx, ty)
    }
    pub fn draw_iter(&self, active_z: usize) -> Vec<IsoDrawItem> {
        if self.levels.is_empty() || self.width == 0 || self.height == 0 {
            return Vec::new();
        }
        let max_z = active_z.min(self.levels.len() - 1);
        let w = self.width as usize;
        let h = self.height as usize;
        let pc = self.part_count as usize;
        let mut items = Vec::with_capacity(w * h * (max_z + 1) * pc);
        let max_d = (w + h).saturating_sub(2);
        for d in 0..=max_d {
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
                    for &part in &self.part_order {
                        let gid = tile.parts.get(part as usize).copied().unwrap_or(0);
                        items.push(IsoDrawItem {
                            level: z as u32,
                            tile_x: tx as u32,
                            tile_y: ty as u32,
                            part,
                            gid,
                            screen_x: sx,
                            screen_y: sy,
                        });
                    }
                }
            }
        }
        items
    }
    pub fn get_part_count(&self) -> u32 {
        self.part_count
    }
    pub fn get_part_order(&self) -> &[u32] {
        &self.part_order
    }
    pub fn set_part_order(&mut self, order: Vec<u32>) -> Result<(), String> {
        if order.len() != self.part_count as usize {
            return Err(format!(
                "setPartOrder: expected {} indices, got {}",
                self.part_count,
                order.len()
            ));
        }
        for &idx in &order {
            if idx >= self.part_count {
                return Err(format!(
                    "setPartOrder: index {} out of range (part_count = {})",
                    idx, self.part_count
                ));
            }
        }
        self.part_order = order;
        Ok(())
    }
}
