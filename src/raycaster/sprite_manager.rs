#[derive(Debug, Clone)]
pub struct WorldSprite {
    pub id: u32,
    pub x: f32,
    pub y: f32,
    pub texture: String,
    pub scale: f32,
    pub visible: bool,
}
pub struct SpriteManager {
    sprites: Vec<WorldSprite>,
    next_id: u32,
}
impl SpriteManager {
    pub fn new() -> Self {
        Self {
            sprites: Vec::new(),
            next_id: 1,
        }
    }
    pub fn add(&mut self, x: f32, y: f32, texture: &str, scale: f32) -> u32 {
        let id = self.next_id;
        self.next_id += 1;
        self.sprites.push(WorldSprite {
            id,
            x,
            y,
            texture: texture.to_owned(),
            scale,
            visible: true,
        });
        id
    }
    pub fn remove(&mut self, id: u32) {
        self.sprites.retain(|s| s.id != id);
    }
    pub fn set_position(&mut self, id: u32, x: f32, y: f32) {
        if let Some(s) = self.sprites.iter_mut().find(|s| s.id == id) {
            s.x = x;
            s.y = y;
        }
    }
    pub fn set_visible(&mut self, id: u32, visible: bool) {
        if let Some(s) = self.sprites.iter_mut().find(|s| s.id == id) {
            s.visible = visible;
        }
    }
    pub fn clear(&mut self) {
        self.sprites.clear();
    }
    pub fn sort_by_distance(&self, cam_x: f32, cam_y: f32) -> Vec<&WorldSprite> {
        let mut visible: Vec<&WorldSprite> = self.sprites.iter().filter(|s| s.visible).collect();
        visible.sort_by(|a, b| {
            let da = (a.x - cam_x) * (a.x - cam_x) + (a.y - cam_y) * (a.y - cam_y);
            let db = (b.x - cam_x) * (b.x - cam_x) + (b.y - cam_y) * (b.y - cam_y);
            db.partial_cmp(&da).unwrap_or(std::cmp::Ordering::Equal)
        });
        visible
    }
}
impl Default for SpriteManager {
    fn default() -> Self {
        Self::new()
    }
}
