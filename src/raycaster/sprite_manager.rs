//! World-space sprite registry for the raycaster. Tracks billboards by unique ID,
//! supports add/remove/move/visibility, and produces a back-to-front sorted list
//! for depth-correct rendering. Does not own projection math or GPU calls.

/// A billboard sprite placed in world space with an associated texture and uniform scale.
#[derive(Debug, Clone)]
pub struct WorldSprite {
    /// Unique sprite ID assigned at `SpriteManager::add` time.
    pub id: u32,
    /// World X position of the sprite's center.
    pub x: f32,
    /// World Y position of the sprite's center.
    pub y: f32,
    /// Asset path of the texture to draw.
    pub texture: String,
    /// Uniform scale applied to the billboard quad; 1.0 = native tile size.
    pub scale: f32,
    /// When false, the sprite is skipped during sorting and rendering.
    pub visible: bool,
}
/// Tracks all world-space billboard sprites; owned by `RaycasterState`.
pub struct SpriteManager {
    /// All registered sprites in insertion order.
    sprites: Vec<WorldSprite>,
    /// Monotonically incrementing ID counter; starts at 1.
    next_id: u32,
}
impl SpriteManager {
    /// Create an empty `SpriteManager` with ID counter starting at 1.
    pub fn new() -> Self {
        Self {
            sprites: Vec::new(),
            next_id: 1,
        }
    }
    /// Register a sprite at `(x, y)` with the given `texture` path and `scale`; return its new ID.
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
    /// Remove the sprite with the given `id`; silently does nothing if not found.
    pub fn remove(&mut self, id: u32) {
        self.sprites.retain(|s| s.id != id);
    }
    /// Move the sprite with `id` to world position `(x, y)`; silently does nothing if not found.
    pub fn set_position(&mut self, id: u32, x: f32, y: f32) {
        if let Some(s) = self.sprites.iter_mut().find(|s| s.id == id) {
            s.x = x;
            s.y = y;
        }
    }
    /// Set the visibility flag for sprite `id`; silently does nothing if not found.
    pub fn set_visible(&mut self, id: u32, visible: bool) {
        if let Some(s) = self.sprites.iter_mut().find(|s| s.id == id) {
            s.visible = visible;
        }
    }
    /// Remove all sprites from the registry.
    pub fn clear(&mut self) {
        self.sprites.clear();
    }
    /// Return visible sprites sorted farthest-to-nearest from `(cam_x, cam_y)`.
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
/// Delegate `Default` to `SpriteManager::new`.
impl Default for SpriteManager {
    fn default() -> Self {
        Self::new()
    }
}
