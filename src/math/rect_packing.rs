#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PackedRect {
    pub id: Option<String>,
    pub x: u32,
    pub y: u32,
    pub w: u32,
    pub h: u32,
}
#[derive(Debug, Clone)]
struct Shelf {
    y: u32,
    height: u32,
    cursor_x: u32,
}
#[derive(Debug, Clone)]
pub struct RectPacker {
    width: u32,
    height: u32,
    padding: u32,
    shelves: Vec<Shelf>,
    packed: Vec<PackedRect>,
}
impl RectPacker {
    pub fn new(width: u32, height: u32, padding: u32) -> Self {
        Self {
            width,
            height,
            padding,
            shelves: Vec::new(),
            packed: Vec::new(),
        }
    }
    pub fn pack(&mut self, w: u32, h: u32, id: Option<String>) -> Option<PackedRect> {
        if w == 0 || h == 0 {
            return None;
        }
        let pw = w.saturating_add(self.padding);
        let ph = h.saturating_add(self.padding);
        if pw > self.width || ph > self.height {
            return None;
        }
        for shelf in &mut self.shelves {
            if ph <= shelf.height && shelf.cursor_x.saturating_add(pw) <= self.width {
                let placed = PackedRect {
                    id,
                    x: shelf.cursor_x,
                    y: shelf.y,
                    w,
                    h,
                };
                shelf.cursor_x = shelf.cursor_x.saturating_add(pw);
                self.packed.push(placed.clone());
                return Some(placed);
            }
        }
        let next_y = self
            .shelves
            .last()
            .map(|s| s.y.saturating_add(s.height))
            .unwrap_or(0);
        if next_y.saturating_add(ph) > self.height {
            return None;
        }
        let mut shelf = Shelf {
            y: next_y,
            height: ph,
            cursor_x: 0,
        };
        let placed = PackedRect {
            id,
            x: 0,
            y: next_y,
            w,
            h,
        };
        shelf.cursor_x = pw;
        self.shelves.push(shelf);
        self.packed.push(placed.clone());
        Some(placed)
    }
    pub fn clear(&mut self) {
        self.shelves.clear();
        self.packed.clear();
    }
    pub fn packed_rects(&self) -> &[PackedRect] {
        &self.packed
    }
    pub fn occupancy(&self) -> f32 {
        if self.width == 0 || self.height == 0 {
            return 0.0;
        }
        let used: u64 = self
            .packed
            .iter()
            .map(|r| (r.w as u64) * (r.h as u64))
            .sum();
        let total = (self.width as u64) * (self.height as u64);
        (used as f32 / total as f32).clamp(0.0, 1.0)
    }
    pub fn size(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    pub fn padding(&self) -> u32 {
        self.padding
    }
}
