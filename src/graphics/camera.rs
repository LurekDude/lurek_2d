use crate::math::{Vec2, Mat3};

/// 2D camera with world-space position, uniform zoom, and rotation; produces a view `Mat3`.
///
/// The camera is used to transform world coordinates into screen space before rendering.
/// Attach it to a `Renderer` or pass the view matrix to draw calls via `luna.graphics.camera`.
///
/// # Fields
/// - `position` — World-space centre point the camera is looking at.
/// - `zoom` — Uniform scale factor; `1.0` = natural size, `2.0` = 2× zoom in.
/// - `rotation` — Rotation in radians, applied after zoom.
pub struct Camera {
    pub position: Vec2,
    pub zoom: f32,
    pub rotation: f32,
}

impl Camera {
    /// Creates a new `Camera` with the given position, zoom, and rotation.
    ///
    /// # Parameters
    /// - `position` — Initial world-space centre point.
    /// - `zoom` — Initial zoom level (`1.0` for no zoom).
    /// - `rotation` — Initial rotation in radians.
    ///
    /// # Returns
    /// A new `Camera` instance.
    pub fn new(position: Vec2, zoom: f32, rotation: f32) -> Self {
        Camera { position, zoom, rotation }
    }

    /// Computes the view transformation matrix for this camera.
    ///
    /// Combines translation (negate position), rotation, and scale (zoom) into a single `Mat3`.
    /// Apply this to world-space points to obtain screen-space coordinates.
    ///
    /// # Returns
    /// `Mat3` — The combined scale × rotation × translation view matrix.
    pub fn view_matrix(&self) -> Mat3 {
        let translation = Mat3::from_translation(Vec2::new(-self.position.x, -self.position.y));
        let rotation = Mat3::from_rotation(self.rotation);
        let scale = Mat3::from_scale(Vec2::splat(self.zoom));
        scale * rotation * translation
    }

    /// Moves the camera to `position` in world space.
    ///
    /// # Parameters
    /// - `position` — New world-space centre point.
    pub fn set_position(&mut self, position: Vec2) {
        self.position = position;
    }

    /// Sets the camera's zoom level.
    ///
    /// # Parameters
    /// - `zoom` — New zoom factor. Values > 1.0 zoom in; values < 1.0 zoom out.
    pub fn set_zoom(&mut self, zoom: f32) {
        self.zoom = zoom;
    }

    /// Sets the camera's rotation.
    ///
    /// # Parameters
    /// - `rotation` — New rotation in radians, counter-clockwise positive.
    pub fn set_rotation(&mut self, rotation: f32) {
        self.rotation = rotation;
    }
}

impl Default for Camera {
    fn default() -> Self {
        Camera {
            position: Vec2::ZERO,
            zoom: 1.0,
            rotation: 0.0,
        }
    }
}
