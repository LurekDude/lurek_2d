//! Camera types for 2D viewport control.
//!
//! Provides the original [`Camera`] (used by `SharedState` for the flat
//! `lurek.gfx.setCamera()` API) and the new Phase 24 [`Camera2D`] with
//! smooth follow, dead zone, bounds clamping, and screen-shake.

use crate::math::{Mat3, Rect, Vec2};

// ═════════════════════════════════════════════════════════════════════════
// Existing Camera (kept for backward compatibility)
// ═════════════════════════════════════════════════════════════════════════

/// Basic camera with position, zoom, and rotation.
///
/// Used by `SharedState` for the flat `lurek.gfx.setCamera()` API.
///
/// # Fields
/// - `position` — World-space centre point the camera is looking at.
/// - `zoom` — Uniform scale factor; `1.0` = natural size, `2.0` = 2x zoom in.
/// - `rotation` — Rotation in radians, applied after zoom.
pub struct Camera {
    /// World-space centre point.
    pub position: Vec2,
    /// Uniform zoom factor (`1.0` = no zoom).
    pub zoom: f32,
    /// Rotation in radians (counter-clockwise positive).
    pub rotation: f32,
}

impl Camera {
    /// Creates a new `Camera` with the given position, zoom, and rotation.
    ///
    /// # Parameters
    /// - `position` — `Vec2`.
    /// - `zoom` — `f32`.
    /// - `rotation` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(position: Vec2, zoom: f32, rotation: f32) -> Self {
        Camera {
            position,
            zoom,
            rotation,
        }
    }

    /// Computes the view transformation matrix for this camera.
    ///
    /// # Returns
    /// `Mat3`.
    ///
    /// Combines translation (negate position), rotation, and scale (zoom)
    /// into a single `Mat3`.
    pub fn view_matrix(&self) -> Mat3 {
        let translation = Mat3::from_translation(Vec2::new(-self.position.x, -self.position.y));
        let rotation = Mat3::from_rotation(self.rotation);
        let scale = Mat3::from_scale(Vec2::splat(self.zoom));
        scale * rotation * translation
    }

    /// Moves the camera to `position` in world space.
    ///
    /// # Parameters
    /// - `position` — `Vec2`.
    pub fn set_position(&mut self, position: Vec2) {
        self.position = position;
    }

    /// Sets the camera's zoom level. Replaces the current zoom value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `zoom` — `f32`.
    pub fn set_zoom(&mut self, zoom: f32) {
        self.zoom = zoom;
    }

    /// Sets the camera's rotation in radians. Replaces the current rotation value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `rotation` — `f32`.
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

// ═════════════════════════════════════════════════════════════════════════
// Camera2D — Phase 24
// ═════════════════════════════════════════════════════════════════════════

/// Full-featured 2D camera with smooth follow, dead zone, bounds clamping,
///
/// # Fields
/// - `position` — `Vec2`.
/// - `zoom` — `f32`.
/// - `rotation` — `f32`.
/// - `viewport` — `Rect`.
/// - `bounds` — `Option<Rect>`.
/// - `target` — `Option<Vec2>`.
/// - `follow_smooth` — `f32`.
/// - `dead_zone` — `Option<(f32, f32)>`.
/// - `look_ahead` — `f32`.
/// and screen-shake.
///
/// Create with [`Camera2D::new`], configure follow / bounds / shake, then
/// call [`Camera2D::update`] each frame. Use [`Camera2D::view_matrix`] to
/// obtain the transform for rendering.
pub struct Camera2D {
    /// Camera world-space position (centre of the viewport).
    pub position: Vec2,
    /// Uniform zoom factor (`1.0` = no zoom).
    pub zoom: f32,
    /// Rotation in radians (counter-clockwise positive).
    pub rotation: f32,
    /// Viewport rectangle in screen pixels: `(x, y, width, height)`.
    pub viewport: Rect,
    /// Optional world-space bounds for clamping. When set the visible area
    /// will never extend beyond these bounds.
    pub bounds: Option<Rect>,

    // ── Follow system ───────────────────────────────────────────────────
    /// Target world position the camera tries to follow.
    pub target: Option<Vec2>,
    /// Interpolation speed for smooth following. `0.0` = instant snap.
    pub follow_smooth: f32,
    /// Dead zone half-extents `(half_w, half_h)`. The camera does not move
    /// while the target stays inside this rectangle centred on the camera.
    pub dead_zone: Option<(f32, f32)>,
    /// Look-ahead multiplier. Estimated target velocity is scaled by this
    /// value and added to the desired position.
    pub look_ahead: f32,

    // ── Shake ───────────────────────────────────────────────────────────
    /// Current shake intensity (pixels).
    shake_intensity: f32,
    /// Total shake duration in seconds.
    shake_duration: f32,
    /// Remaining shake time.
    shake_timer: f32,
    /// Current frame's shake offset (applied in [`view_matrix`](Self::view_matrix)).
    shake_offset: Vec2,

    // ── Internal ────────────────────────────────────────────────────────
    /// Previous target for velocity estimation (look-ahead).
    prev_target: Option<Vec2>,
}

impl Camera2D {
    /// Creates a new `Camera2D` centred at the origin with the given viewport
    ///
    /// # Parameters
    /// - `viewport_w` — `f32`.
    /// - `viewport_h` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    /// dimensions.
    pub fn new(viewport_w: f32, viewport_h: f32) -> Self {
        Self {
            position: Vec2::ZERO,
            zoom: 1.0,
            rotation: 0.0,
            viewport: Rect::new(0.0, 0.0, viewport_w, viewport_h),
            bounds: None,
            target: None,
            follow_smooth: 0.0,
            dead_zone: None,
            look_ahead: 0.0,
            shake_intensity: 0.0,
            shake_duration: 0.0,
            shake_timer: 0.0,
            shake_offset: Vec2::ZERO,
            prev_target: None,
        }
    }

    // ── Position / zoom / rotation ──────────────────────────────────────

    /// Sets the camera position in world space.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn set_position(&mut self, x: f32, y: f32) {
        self.position = Vec2::new(x, y);
    }

    /// Returns the camera position as `(x, y)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_position(&self) -> (f32, f32) {
        (self.position.x, self.position.y)
    }

    /// Sets the uniform zoom factor. Replaces the current zoom value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `z` — `f32`.
    pub fn set_zoom(&mut self, z: f32) {
        self.zoom = z;
    }

    /// Returns the current zoom factor. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_zoom(&self) -> f32 {
        self.zoom
    }

    /// Sets the rotation in radians. Replaces the current rotation value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `r` — `f32`.
    pub fn set_rotation(&mut self, r: f32) {
        self.rotation = r;
    }

    /// Returns the current rotation in radians.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_rotation(&self) -> f32 {
        self.rotation
    }

    // ── Viewport ────────────────────────────────────────────────────────

    /// Sets the viewport rectangle in screen pixels.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `w` — `f32`.
    /// - `h` — `f32`.
    pub fn set_viewport(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport = Rect::new(x, y, w, h);
    }

    /// Returns the viewport as `(x, y, w, h)`.
    ///
    /// # Returns
    /// `(f32, f32, f32, f32)`.
    pub fn get_viewport(&self) -> (f32, f32, f32, f32) {
        (
            self.viewport.x,
            self.viewport.y,
            self.viewport.width,
            self.viewport.height,
        )
    }

    // ── Bounds ──────────────────────────────────────────────────────────

    /// Sets world-space bounds for camera clamping.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `w` — `f32`.
    /// - `h` — `f32`.
    pub fn set_bounds(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.bounds = Some(Rect::new(x, y, w, h));
    }

    /// Returns the world-space bounds, if set. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Option<(f32, f32, f32, f32)>`.
    pub fn get_bounds(&self) -> Option<(f32, f32, f32, f32)> {
        self.bounds.map(|b| (b.x, b.y, b.width, b.height))
    }

    /// Removes previously set bounds. Returns the removed value if present, or `None` when the key did not exist.
    pub fn remove_bounds(&mut self) {
        self.bounds = None;
    }

    /// Returns `true` if world-space bounds are set.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_bounds(&self) -> bool {
        self.bounds.is_some()
    }

    // ── Movement helpers ────────────────────────────────────────────────

    /// Translates the camera by `(dx, dy)` in world space.
    ///
    /// # Parameters
    /// - `dx` — `f32`.
    /// - `dy` — `f32`.
    pub fn move_by(&mut self, dx: f32, dy: f32) {
        self.position.x += dx;
        self.position.y += dy;
    }

    /// Sets the camera position directly (shorthand for [`set_position`](Self::set_position)).
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn look_at(&mut self, x: f32, y: f32) {
        self.position = Vec2::new(x, y);
    }

    // ── Coordinate conversion ───────────────────────────────────────────

    /// Converts screen coordinates to world coordinates.
    ///
    /// # Parameters
    /// - `screen_x` — `f32`.
    /// - `screen_y` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    ///
    /// This is the inverse of the view transform (ignoring rotation for
    /// the simple 2D case).
    pub fn to_world_coords(&self, screen_x: f32, screen_y: f32) -> (f32, f32) {
        let z = if self.zoom.abs() > f32::EPSILON {
            self.zoom
        } else {
            1.0
        };
        let wx = (screen_x - self.viewport.width * 0.5) / z + self.position.x + self.shake_offset.x;
        let wy =
            (screen_y - self.viewport.height * 0.5) / z + self.position.y + self.shake_offset.y;
        (wx, wy)
    }

    /// Converts world coordinates to screen coordinates.
    ///
    /// # Parameters
    /// - `world_x` — `f32`.
    /// - `world_y` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn to_screen_coords(&self, world_x: f32, world_y: f32) -> (f32, f32) {
        let sx = (world_x - self.position.x - self.shake_offset.x) * self.zoom
            + self.viewport.width * 0.5;
        let sy = (world_y - self.position.y - self.shake_offset.y) * self.zoom
            + self.viewport.height * 0.5;
        (sx, sy)
    }

    /// Returns the world-space axis-aligned bounding box of the visible area
    ///
    /// # Returns
    /// `(f32, f32, f32, f32)`.
    /// as `(x, y, w, h)`.
    pub fn get_visible_area(&self) -> (f32, f32, f32, f32) {
        let z = if self.zoom.abs() > f32::EPSILON {
            self.zoom
        } else {
            1.0
        };
        let half_w = self.viewport.width * 0.5 / z;
        let half_h = self.viewport.height * 0.5 / z;
        let cx = self.position.x + self.shake_offset.x;
        let cy = self.position.y + self.shake_offset.y;
        (cx - half_w, cy - half_h, half_w * 2.0, half_h * 2.0)
    }

    // ── Follow / dead zone / look-ahead ─────────────────────────────────

    /// Sets the dead zone half-extents. Pass `(0, 0)` for no dead zone.
    ///
    /// # Parameters
    /// - `w` — `f32`.
    /// - `h` — `f32`.
    pub fn set_dead_zone(&mut self, w: f32, h: f32) {
        self.dead_zone = Some((w * 0.5, h * 0.5));
    }

    /// Returns the dead zone as `(width, height)` (full extents), if set.
    ///
    /// # Returns
    /// `Option<(f32, f32)>`.
    pub fn get_dead_zone(&self) -> Option<(f32, f32)> {
        self.dead_zone.map(|(hw, hh)| (hw * 2.0, hh * 2.0))
    }

    /// Sets the follow target position. Replaces the current target value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn set_target(&mut self, x: f32, y: f32) {
        self.target = Some(Vec2::new(x, y));
    }

    /// Returns the current follow target, if any.
    ///
    /// # Returns
    /// `Option<(f32, f32)>`.
    pub fn get_target(&self) -> Option<(f32, f32)> {
        self.target.map(|t| (t.x, t.y))
    }

    /// Clears the follow target so the camera stops tracking.
    pub fn clear_target(&mut self) {
        self.target = None;
    }

    /// Sets the smooth follow interpolation speed.
    ///
    /// # Parameters
    /// - `speed` — `f32`.
    ///
    /// `0.0` means instant snap, higher values give smoother following.
    pub fn set_follow_smooth(&mut self, speed: f32) {
        self.follow_smooth = speed.max(0.0);
    }

    /// Returns the smooth follow speed. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_follow_smooth(&self) -> f32 {
        self.follow_smooth
    }

    /// Sets the look-ahead multiplier. Replaces the current look ahead value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `mul` — `f32`.
    pub fn set_look_ahead(&mut self, mul: f32) {
        self.look_ahead = mul;
    }

    /// Returns the look-ahead multiplier. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_look_ahead(&self) -> f32 {
        self.look_ahead
    }

    // ── Shake ───────────────────────────────────────────────────────────

    /// Starts a camera shake effect.
    ///
    /// # Parameters
    /// - `intensity` — Maximum pixel offset.
    /// - `duration` — How long the shake lasts in seconds.
    pub fn shake(&mut self, intensity: f32, duration: f32) {
        self.shake_intensity = intensity;
        self.shake_duration = duration;
        self.shake_timer = duration;
    }

    // ── Update ──────────────────────────────────────────────────────────

    /// Processes smooth follow, camera shake, and bounds clamping.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    ///
    /// Call once per frame with the delta time in seconds.
    pub fn update(&mut self, dt: f32) {
        // ── 1. Follow target ────────────────────────────────────────────
        if let Some(target) = self.target {
            let mut desired = target;

            // ── 2. Dead zone ────────────────────────────────────────────
            if let Some((hw, hh)) = self.dead_zone {
                let dx = target.x - self.position.x;
                let dy = target.y - self.position.y;
                if dx.abs() <= hw && dy.abs() <= hh {
                    // Target inside dead zone — keep current position as desired.
                    desired = self.position;
                }
            }

            // ── 3. Look-ahead ───────────────────────────────────────────
            if self.look_ahead > 0.0 {
                if let Some(prev) = self.prev_target {
                    let vx = target.x - prev.x;
                    let vy = target.y - prev.y;
                    desired.x += vx * self.look_ahead;
                    desired.y += vy * self.look_ahead;
                }
            }

            // ── 4. Smooth interpolation ─────────────────────────────────
            if self.follow_smooth > 0.0 {
                let t = (self.follow_smooth * dt).min(1.0);
                self.position.x += (desired.x - self.position.x) * t;
                self.position.y += (desired.y - self.position.y) * t;
            } else {
                self.position = desired;
            }

            self.prev_target = Some(target);
        }

        // ── 5. Bounds clamping ──────────────────────────────────────────
        if let Some(bounds) = self.bounds {
            let z = if self.zoom.abs() > f32::EPSILON {
                self.zoom
            } else {
                1.0
            };
            let half_w = self.viewport.width * 0.5 / z;
            let half_h = self.viewport.height * 0.5 / z;

            let min_x = bounds.x + half_w;
            let max_x = bounds.x + bounds.width - half_w;
            let min_y = bounds.y + half_h;
            let max_y = bounds.y + bounds.height - half_h;

            if min_x <= max_x {
                self.position.x = self.position.x.clamp(min_x, max_x);
            } else {
                self.position.x = bounds.x + bounds.width * 0.5;
            }
            if min_y <= max_y {
                self.position.y = self.position.y.clamp(min_y, max_y);
            } else {
                self.position.y = bounds.y + bounds.height * 0.5;
            }
        }

        // ── 6. Shake ────────────────────────────────────────────────────
        if self.shake_timer > 0.0 {
            self.shake_timer -= dt;
            if self.shake_timer <= 0.0 {
                self.shake_timer = 0.0;
                self.shake_offset = Vec2::ZERO;
            } else {
                let ratio = self.shake_timer / self.shake_duration;
                let t = self.shake_timer;
                // Deterministic pseudo-random from timer value.
                let ox = (t * 53.0).sin() * self.shake_intensity * ratio;
                let oy = (t * 97.0).sin() * self.shake_intensity * ratio;
                self.shake_offset = Vec2::new(ox, oy);
            }
        }
    }

    /// Computes the view matrix including the shake offset.
    ///
    /// # Returns
    /// `Mat3`.
    ///
    /// Order: translate(-(position + shake_offset)), scale(zoom), rotate(rotation).
    pub fn view_matrix(&self) -> Mat3 {
        let pos = Vec2::new(
            self.position.x + self.shake_offset.x,
            self.position.y + self.shake_offset.y,
        );
        let translation = Mat3::from_translation(Vec2::new(-pos.x, -pos.y));
        let rotation = Mat3::from_rotation(self.rotation);
        let scale = Mat3::from_scale(Vec2::splat(self.zoom));
        scale * rotation * translation
    }
}

impl Default for Camera2D {
    fn default() -> Self {
        Self::new(800.0, 600.0)
    }
}

// ── Unit tests ──────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn camera_default_identity() {
        let cam = Camera::default();
        assert!((cam.position.x).abs() < f32::EPSILON);
        assert!((cam.position.y).abs() < f32::EPSILON);
        assert!((cam.zoom - 1.0).abs() < f32::EPSILON);
        assert!((cam.rotation).abs() < f32::EPSILON);
    }

    #[test]
    fn camera_view_matrix_identity_at_default() {
        let cam = Camera::default();
        let m = cam.view_matrix();
        let p = m.transform_point(Vec2::new(10.0, 20.0));
        assert!((p.x - 10.0).abs() < 1e-5);
        assert!((p.y - 20.0).abs() < 1e-5);
    }

    #[test]
    fn camera2d_new_centered() {
        let cam = Camera2D::new(800.0, 600.0);
        assert!((cam.position.x).abs() < f32::EPSILON);
        assert!((cam.position.y).abs() < f32::EPSILON);
        assert!((cam.zoom - 1.0).abs() < f32::EPSILON);
    }

    #[test]
    fn camera2d_to_screen_and_back() {
        let cam = Camera2D::new(800.0, 600.0);
        let (sx, sy) = cam.to_screen_coords(100.0, 200.0);
        let (wx, wy) = cam.to_world_coords(sx, sy);
        assert!((wx - 100.0).abs() < 1e-3);
        assert!((wy - 200.0).abs() < 1e-3);
    }

    #[test]
    fn camera2d_bounds_clamping() {
        let mut cam = Camera2D::new(100.0, 100.0);
        cam.set_bounds(0.0, 0.0, 500.0, 500.0);
        cam.set_position(-1000.0, -1000.0);
        cam.update(0.016);
        // Camera should be clamped so visible area is inside bounds.
        let (px, py) = cam.get_position();
        assert!(px >= 0.0);
        assert!(py >= 0.0);
    }

    #[test]
    fn camera2d_follow_instant_snap() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_follow_smooth(0.0);
        cam.set_target(200.0, 300.0);
        cam.update(0.016);
        let (px, py) = cam.get_position();
        assert!((px - 200.0).abs() < 1e-3);
        assert!((py - 300.0).abs() < 1e-3);
    }

    #[test]
    fn camera2d_follow_smooth_moves_toward_target() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_follow_smooth(5.0);
        cam.set_target(200.0, 0.0);
        cam.update(0.1);
        let (px, _) = cam.get_position();
        // Should have moved toward 200 but not arrived yet.
        assert!(px > 0.0);
        assert!(px < 200.0);
    }

    #[test]
    fn camera2d_shake_decays() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.shake(10.0, 0.5);
        cam.update(0.6); // past duration
                         // Shake offset should be zero after duration expires.
        assert!((cam.shake_offset.x).abs() < f32::EPSILON);
        assert!((cam.shake_offset.y).abs() < f32::EPSILON);
    }

    #[test]
    fn camera2d_visible_area_scales_with_zoom() {
        let cam1 = Camera2D::new(800.0, 600.0);
        let (_, _, w1, h1) = cam1.get_visible_area();

        let mut cam2 = Camera2D::new(800.0, 600.0);
        cam2.set_zoom(2.0);
        let (_, _, w2, h2) = cam2.get_visible_area();

        assert!((w2 - w1 / 2.0).abs() < 1e-3);
        assert!((h2 - h1 / 2.0).abs() < 1e-3);
    }

    #[test]
    fn camera2d_dead_zone_prevents_small_movements() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_dead_zone(100.0, 100.0);
        cam.set_follow_smooth(0.0);
        cam.set_target(10.0, 10.0); // inside dead zone
        cam.update(0.016);
        let (px, py) = cam.get_position();
        // Camera should not have moved.
        assert!((px).abs() < f32::EPSILON);
        assert!((py).abs() < f32::EPSILON);
    }
}
