//! Sprite screen-space projection for billboard rendering.
//!
//! Contains the [`SpriteProjection`] struct returned by
//! [`super::Raycaster2D::project_sprite()`].

/// Sprite projection result.
///
/// Describes where and how large to draw a billboard sprite on screen,
/// as computed by the raycaster's camera transform.
///
/// # Fields
/// - `screen_x` — `f32`.
/// - `scale` — `f32`.
/// - `distance` — `f32`.
/// - `visible` — `bool`.
#[derive(Debug, Clone)]
pub struct SpriteProjection {
    /// Screen-space X position of the sprite center.
    pub screen_x: f32,
    /// Scale factor for rendering.
    pub scale: f32,
    /// Distance from camera to sprite.
    pub distance: f32,
    /// Whether the sprite is visible (in front of camera).
    pub visible: bool,
}
