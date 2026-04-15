//! Batch sprite manager with depth-sorted projection for raycaster scenes.
//!
//! Manages a list of world-space sprites, supports add/remove/move, and
//! produces a back-to-front sorted view through [`SpriteManager::sort_by_distance`].

/// A named, positionable sprite living in world space.
///
/// # Fields
/// - `id` — `u32`. Unique handle assigned by [`SpriteManager::add`].
/// - `x` — `f32`. World X position.
/// - `y` — `f32`. World Y position.
/// - `texture` — `String`. Texture path or name.
/// - `scale` — `f32`. Uniform display scale.
/// - `visible` — `bool`. When `false` the sprite is excluded from projection.
#[derive(Debug, Clone)]
pub struct WorldSprite {
    /// Unique sprite id assigned by the manager.
    pub id: u32,
    /// World-space X position.
    pub x: f32,
    /// World-space Y position.
    pub y: f32,
    /// Texture identifier (path or asset name).
    pub texture: String,
    /// Uniform scale applied when rendering.
    pub scale: f32,
    /// When `false` the sprite is excluded from [`SpriteManager::sort_by_distance`].
    pub visible: bool,
}

/// Manages a collection of [`WorldSprite`] objects with depth-sorted projection.
///
/// Sprites are stored by value and can be added, removed, repositioned, and
/// toggled. [`sort_by_distance`] returns references sorted back-to-front so the
/// renderer can draw them in painter-order.
///
/// # Fields
/// - `sprites` — `Vec<WorldSprite>`.
/// - `next_id` — `u32`.
pub struct SpriteManager {
    sprites: Vec<WorldSprite>,
    next_id: u32,
}

impl SpriteManager {
    /// Creates an empty sprite manager.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            sprites: Vec::new(),
            next_id: 1,
        }
    }

    /// Adds a sprite at the given world position and returns its unique id.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `texture` — `&str`.
    /// - `scale` — `f32`.
    ///
    /// # Returns
    /// `u32` — Sprite id.
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

    /// Removes the sprite with the given id. No-op if not found.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    pub fn remove(&mut self, id: u32) {
        self.sprites.retain(|s| s.id != id);
    }

    /// Moves the sprite with the given id to a new world position.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn set_position(&mut self, id: u32, x: f32, y: f32) {
        if let Some(s) = self.sprites.iter_mut().find(|s| s.id == id) {
            s.x = x;
            s.y = y;
        }
    }

    /// Sets visibility for the sprite with the given id.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `visible` — `bool`.
    pub fn set_visible(&mut self, id: u32, visible: bool) {
        if let Some(s) = self.sprites.iter_mut().find(|s| s.id == id) {
            s.visible = visible;
        }
    }

    /// Removes all sprites from the manager.
    pub fn clear(&mut self) {
        self.sprites.clear();
    }

    /// Returns references to visible sprites sorted back-to-front (farthest first).
    ///
    /// The sort is stable within equal distances. Invisible sprites are excluded.
    ///
    /// # Parameters
    /// - `cam_x` — `f32`. Camera world X.
    /// - `cam_y` — `f32`. Camera world Y.
    ///
    /// # Returns
    /// `Vec<&WorldSprite>`.
    pub fn sort_by_distance(&self, cam_x: f32, cam_y: f32) -> Vec<&WorldSprite> {
        let mut visible: Vec<&WorldSprite> =
            self.sprites.iter().filter(|s| s.visible).collect();
        visible.sort_by(|a, b| {
            let da = (a.x - cam_x) * (a.x - cam_x) + (a.y - cam_y) * (a.y - cam_y);
            let db = (b.x - cam_x) * (b.x - cam_x) + (b.y - cam_y) * (b.y - cam_y);
            // Farthest first (back-to-front painter order)
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
