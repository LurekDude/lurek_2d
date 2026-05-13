//! Camera types for 2D viewport control.
//!
//! Provides the original [`Camera`] (used by `SharedState` for the flat
//! `lurek.render.setCamera()` API) and the new Phase 24 [`Camera2D`] with
//! smooth follow, dead zone, bounds clamping, and screen-shake.

use crate::camera::effects::{CameraBreathing, CameraSway, ZoomPulse};
use crate::math::{Mat3, Rect, Vec2};

// ---- Type: CameraFollowEasing ----

/// Easing mode used by camera follow interpolation.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
/// Easing mode used by camera follow interpolation.
pub enum CameraFollowEasing {
    /// Linear interpolation.
    Linear,
    /// Smoothstep interpolation (`t*t*(3-2*t)`).
    SmoothStep,
    /// Ease-out cubic interpolation.
    EaseOutCubic,
}

// ---- Implementation: CameraFollowEasing ----

impl CameraFollowEasing {
    fn apply(self, t: f32) -> f32 {
        let clamped = t.clamp(0.0, 1.0);
        match self {
            Self::Linear => clamped,
            Self::SmoothStep => clamped * clamped * (3.0 - 2.0 * clamped),
            Self::EaseOutCubic => 1.0 - (1.0 - clamped).powi(3),
        }
    }
}

// ---- Type: Camera ----

/// Basic camera with position, zoom, and rotation.
///
/// Used by `SharedState` for the flat `lurek.render.setCamera()` API.
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

// ---- Implementation: Camera ----

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

// ---- Default Implementation ----

impl Default for Camera {
    fn default() -> Self {
        Camera {
            position: Vec2::ZERO,
            zoom: 1.0,
            rotation: 0.0,
        }
    }
}

// ---- Type: Camera2D ----

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

    // ---- Helper Functions: Follow System ----
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
    /// Follow interpolation easing mode.
    pub follow_easing: CameraFollowEasing,

    // ---- Helper Functions: Shake ----
    /// Current shake intensity (pixels).
    shake_intensity: f32,
    /// Total shake duration in seconds.
    shake_duration: f32,
    /// Remaining shake time.
    shake_timer: f32,
    /// Current frame's shake offset (applied in [`view_matrix`](Self::view_matrix)).
    shake_offset: Vec2,

    // ---- Helper Functions: Internal State ----
    /// Previous target for velocity estimation (look-ahead).
    prev_target: Option<Vec2>,

    // ---- Helper Functions: Constraints ----
    /// Minimum zoom level constraint (`0.1` = 10% zoom, optional).
    zoom_min: Option<f32>,
    /// Maximum zoom level constraint (`10.0` = 1000% zoom, optional).
    zoom_max: Option<f32>,
    /// Zoom damping factor for smooth transitions (`0.0` = instant, `1.0` = no damping).
    zoom_damping: f32,
    /// Minimum rotation in radians (optional).
    rotation_min: Option<f32>,
    /// Maximum rotation in radians (optional).
    rotation_max: Option<f32>,
    /// Rotation damping factor for smooth transitions (`0.0` = instant, `1.0` = no damping).
    rotation_damping: f32,
    /// Target zoom used when damping is active.
    zoom_target: f32,
    /// Target rotation used when damping is active.
    rotation_target: f32,

    // ---- Helper Functions: Effects ----
    /// Zoom pulse: brief zoom-in with sine envelope decay.
    pub zoom_pulse: ZoomPulse,
    /// Camera sway: sinusoidal x/y offset oscillation.
    pub sway: CameraSway,
    /// Camera breathing: subtle periodic zoom oscillation.
    pub breathing: CameraBreathing,
}

// ---- Implementation: Camera2D ----

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
            follow_easing: CameraFollowEasing::Linear,
            shake_intensity: 0.0,
            shake_duration: 0.0,
            shake_timer: 0.0,
            shake_offset: Vec2::ZERO,
            prev_target: None,
            zoom_min: None,
            zoom_max: None,
            zoom_damping: 0.0,
            rotation_min: None,
            rotation_max: None,
            rotation_damping: 0.0,
            zoom_target: 1.0,
            rotation_target: 0.0,
            zoom_pulse: ZoomPulse::new(),
            sway: CameraSway::new(),
            breathing: CameraBreathing::new(),
        }
    }

    // ---- Helper Functions: Position Zoom Rotation ----

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
        self.zoom_target = z;
        if self.zoom_damping <= f32::EPSILON {
            self.zoom = z;
        }
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
        self.rotation_target = r;
        if self.rotation_damping <= f32::EPSILON {
            self.rotation = r;
        }
    }

    /// Returns the current rotation in radians.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_rotation(&self) -> f32 {
        self.rotation
    }

    /// Sets the follow interpolation easing mode.
    pub fn set_follow_easing(&mut self, easing: CameraFollowEasing) {
        self.follow_easing = easing;
    }

    /// Returns the current follow interpolation easing mode.
    pub fn get_follow_easing(&self) -> CameraFollowEasing {
        self.follow_easing
    }

    // ---- Helper Functions: Zoom Constraints ----

    /// Sets minimum and maximum zoom level constraints.
    ///
    /// # Parameters
    /// - `min_zoom` — `Option<f32>`.
    /// - `max_zoom` — `Option<f32>`.
    ///
    /// Pass `None` to remove a constraint. Zoom is clamped to the valid range
    /// during `update()`.
    pub fn set_zoom_constraints(&mut self, min_zoom: Option<f32>, max_zoom: Option<f32>) {
        self.zoom_min = min_zoom;
        self.zoom_max = max_zoom;
        if let Some(min_z) = self.zoom_min {
            self.zoom_target = self.zoom_target.max(min_z);
            self.zoom = self.zoom.max(min_z);
        }
        if let Some(max_z) = self.zoom_max {
            self.zoom_target = self.zoom_target.min(max_z);
            self.zoom = self.zoom.min(max_z);
        }
    }

    /// Returns the current zoom constraints as `(min_zoom, max_zoom)`, with `None` for unconstrained directions.
    ///
    /// # Returns
    /// `(Option<f32>, Option<f32>)`.
    pub fn get_zoom_constraints(&self) -> (Option<f32>, Option<f32>) {
        (self.zoom_min, self.zoom_max)
    }

    /// Sets the zoom damping factor for smooth zoom transitions.
    ///
    /// # Parameters
    /// - `damping` — `f32`.
    ///
    /// `0.0` = instant zoom changes, `1.0` = no damping (maximum smoothing).
    /// Typical values: `0.0` to `1.0`.
    pub fn set_zoom_damping(&mut self, damping: f32) {
        self.zoom_damping = damping.clamp(0.0, 1.0);
        if self.zoom_damping <= f32::EPSILON {
            self.zoom = self.zoom_target;
        }
    }

    /// Returns the current zoom damping factor.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_zoom_damping(&self) -> f32 {
        self.zoom_damping
    }

    // ---- Helper Functions: Rotation Constraints ----

    /// Sets minimum and maximum rotation constraints in radians.
    ///
    /// # Parameters
    /// - `min_rot` — `Option<f32>`.
    /// - `max_rot` — `Option<f32>`.
    ///
    /// Pass `None` to remove a constraint. Rotation is clamped to the valid range
    /// during `update()`.
    pub fn set_rotation_constraints(&mut self, min_rot: Option<f32>, max_rot: Option<f32>) {
        self.rotation_min = min_rot;
        self.rotation_max = max_rot;
        if let Some(min_r) = self.rotation_min {
            self.rotation_target = self.rotation_target.max(min_r);
            self.rotation = self.rotation.max(min_r);
        }
        if let Some(max_r) = self.rotation_max {
            self.rotation_target = self.rotation_target.min(max_r);
            self.rotation = self.rotation.min(max_r);
        }
    }

    /// Returns the current rotation constraints as `(min_rot, max_rot)`, with `None` for unconstrained directions.
    ///
    /// # Returns
    /// `(Option<f32>, Option<f32>)`.
    pub fn get_rotation_constraints(&self) -> (Option<f32>, Option<f32>) {
        (self.rotation_min, self.rotation_max)
    }

    /// Sets the rotation damping factor for smooth rotation transitions.
    ///
    /// # Parameters
    /// - `damping` — `f32`.
    ///
    /// `0.0` = instant rotation changes, `1.0` = no damping (maximum smoothing).
    /// Typical values: `0.0` to `1.0`.
    pub fn set_rotation_damping(&mut self, damping: f32) {
        self.rotation_damping = damping.clamp(0.0, 1.0);
        if self.rotation_damping <= f32::EPSILON {
            self.rotation = self.rotation_target;
        }
    }

    /// Returns the current rotation damping factor.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_rotation_damping(&self) -> f32 {
        self.rotation_damping
    }

    // ---- Helper Functions: Follow Presets ----

    /// Sets up a tight follow configuration: fast response, small dead zone, look-ahead.
    ///
    /// Suitable for action games and precise control. Parameters:
    /// - `follow_smooth` = 0.9
    /// - `dead_zone` = (20, 20)
    /// - `look_ahead` = 0.5
    pub fn preset_tight_follow(&mut self) {
        self.set_follow_smooth(0.9);
        self.set_dead_zone(20.0, 20.0);
        self.set_look_ahead(0.5);
    }

    /// Sets up a cinematic follow configuration: slow response, large dead zone, no look-ahead.
    ///
    /// Suitable for story-driven games and cutscenes. Parameters:
    /// - `follow_smooth` = 0.3
    /// - `dead_zone` = (100, 100)
    /// - `look_ahead` = 0.0
    pub fn preset_cinematic_follow(&mut self) {
        self.set_follow_smooth(0.3);
        self.set_dead_zone(100.0, 100.0);
        self.set_look_ahead(0.0);
    }

    /// Sets up a balanced follow configuration: moderate response, medium dead zone.
    ///
    /// Suitable for RPGs and exploration games. Parameters:
    /// - `follow_smooth` = 0.6
    /// - `dead_zone` = (40, 40)
    /// - `look_ahead` = 0.3
    pub fn preset_balanced_follow(&mut self) {
        self.set_follow_smooth(0.6);
        self.set_dead_zone(40.0, 40.0);
        self.set_look_ahead(0.3);
    }

    /// Sets up an aggressive follow configuration: maximum response, minimal dead zone, strong look-ahead.
    ///
    /// Suitable for fast-paced games and sports simulations. Parameters:
    /// - `follow_smooth` = 0.99
    /// - `dead_zone` = (5, 5)
    /// - `look_ahead` = 1.0
    pub fn preset_aggressive_follow(&mut self) {
        self.set_follow_smooth(0.99);
        self.set_dead_zone(5.0, 5.0);
        self.set_look_ahead(1.0);
    }

    /// Auto-wires viewport updates to a raw window resize event.
    ///
    /// This helper sets the camera viewport to the full window rectangle.
    pub fn on_window_resize(&mut self, window_width: f32, window_height: f32) {
        self.set_viewport(0.0, 0.0, window_width.max(1.0), window_height.max(1.0));
    }

    /// Auto-wires viewport updates to a window resize with scale-mode mapping.
    ///
    /// Uses logical game dimensions and a scale mode to compute letterbox/stretch
    /// placement before writing the camera viewport rectangle.
    pub fn on_window_resize_scaled(
        &mut self,
        game_width: f32,
        game_height: f32,
        window_width: f32,
        window_height: f32,
        scale_mode: crate::camera::viewport::ScaleMode,
    ) {
        let (scale_x, scale_y, offset_x, offset_y) = scale_mode.compute_transforms(
            game_width.max(1.0),
            game_height.max(1.0),
            window_width.max(1.0),
            window_height.max(1.0),
        );
        self.set_viewport(
            offset_x,
            offset_y,
            game_width.max(1.0) * scale_x,
            game_height.max(1.0) * scale_y,
        );
    }

    // ---- Helper Functions: Viewport ----

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

    // ---- Helper Functions: Bounds ----

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

    // ---- Helper Functions: Movement ----

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

    // ---- Helper Functions: Coordinate Conversion ----

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

    // ---- Helper Functions: Follow Dead Zone Look Ahead ----

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

    // ---- Helper Functions: Shake Control ----

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

    /// Returns the current shake offset as `(dx, dy)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_shake_offset(&self) -> (f32, f32) {
        (self.shake_offset.x, self.shake_offset.y)
    }

    /// Processes smooth follow, camera shake, bounds clamping, and constraint application.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    ///
    /// Call once per frame with the delta time in seconds.
    pub fn update(&mut self, dt: f32) {
        // ---- Helper Functions: Update Stage 1 Follow Target ----
        if let Some(target) = self.target {
            let mut desired = target;

            // ---- Helper Functions: Update Stage 2 Dead Zone ----
            if let Some((hw, hh)) = self.dead_zone {
                let dx = target.x - self.position.x;
                let dy = target.y - self.position.y;
                if dx.abs() <= hw && dy.abs() <= hh {
                    // Target inside dead zone — keep current position as desired.
                    desired = self.position;
                }
            }

            // ---- Helper Functions: Update Stage 3 Look Ahead ----
            if self.look_ahead > 0.0 {
                if let Some(prev) = self.prev_target {
                    let vx = target.x - prev.x;
                    let vy = target.y - prev.y;
                    desired.x += vx * self.look_ahead;
                    desired.y += vy * self.look_ahead;
                }
            }

            // ---- Helper Functions: Update Stage 4 Smooth Interpolation ----
            if self.follow_smooth > 0.0 {
                let t = self.follow_easing.apply((self.follow_smooth * dt).min(1.0));
                self.position.x += (desired.x - self.position.x) * t;
                self.position.y += (desired.y - self.position.y) * t;
            } else {
                self.position = desired;
            }

            self.prev_target = Some(target);
        }

        // ---- Helper Functions: Update Stage 5 Bounds Clamping ----
        if let Some(bounds) = self.bounds {
            let z = if self.zoom_target.abs() > f32::EPSILON {
                self.zoom_target
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

        // ---- Helper Functions: Update Stage 6 Shake ----
        if self.shake_timer > 0.0 {
            self.shake_timer -= dt;
            if self.shake_timer <= 0.0 {
                self.shake_timer = 0.0;
                self.shake_offset = Vec2::ZERO;
            } else {
                let ratio = self.shake_timer / self.shake_duration;
                let t = self.shake_timer;
                // Deterministic pseudo-random shake using sin() of scaled timer values.
                // Different frequency multipliers (53, 97) ensure x and y offsets are uncorrelated.
                let ox = (t * 53.0).sin() * self.shake_intensity * ratio;
                let oy = (t * 97.0).sin() * self.shake_intensity * ratio;
                self.shake_offset = Vec2::new(ox, oy);
            }
        }

        // ---- Helper Functions: Update Stage 7 Zoom Damping And Constraints ----
        if let Some(min_z) = self.zoom_min {
            self.zoom_target = self.zoom_target.max(min_z);
        }
        if let Some(max_z) = self.zoom_max {
            self.zoom_target = self.zoom_target.min(max_z);
        }

        if self.zoom_damping <= f32::EPSILON {
            self.zoom = self.zoom_target;
        } else {
            let alpha = (dt.max(0.0) / (dt.max(0.0) + self.zoom_damping.max(1e-4))).clamp(0.0, 1.0);
            self.zoom += (self.zoom_target - self.zoom) * alpha;
        }

        // ---- Helper Functions: Update Stage 8 Rotation Damping And Constraints ----
        if let Some(min_r) = self.rotation_min {
            self.rotation_target = self.rotation_target.max(min_r);
        }
        if let Some(max_r) = self.rotation_max {
            self.rotation_target = self.rotation_target.min(max_r);
        }

        if self.rotation_damping <= f32::EPSILON {
            self.rotation = self.rotation_target;
        } else {
            let alpha =
                (dt.max(0.0) / (dt.max(0.0) + self.rotation_damping.max(1e-4))).clamp(0.0, 1.0);
            self.rotation += (self.rotation_target - self.rotation) * alpha;
        }

        // ---- Helper Functions: Update Stage 9 Camera Effects ----
        self.zoom_pulse.update(dt);
        self.sway.update(dt);
        self.breathing.update(dt);
    }

    /// Returns the effective zoom level, combining the base zoom with active
    /// zoom pulse and breathing effect deltas.
    ///
    /// Use this instead of [`Self::zoom`] when generating the view transform
    /// so that effects are reflected in the rendered output.
    ///
    /// # Returns
    /// `f32`
    pub fn effective_zoom(&self) -> f32 {
        self.zoom + self.zoom_pulse.current_delta() + self.breathing.current_delta()
    }

    /// Returns the current world-space position offset contributed by the
    /// active sway effect as `(dx, dy)`.
    ///
    /// Add this to the camera position when building the view transform to
    /// include sway in the rendered output.
    ///
    /// # Returns
    /// `(f32, f32)`
    pub fn effect_offset(&self) -> (f32, f32) {
        self.sway.current_offset()
    }

    /// Returns the canonical combined render offset (sway + shake).
    pub fn render_offset(&self) -> (f32, f32) {
        let (sx, sy) = self.sway.current_offset();
        (sx + self.shake_offset.x, sy + self.shake_offset.y)
    }

    /// Computes the view matrix including sway and shake offsets.
    ///
    /// # Returns
    /// `Mat3`.
    ///
    /// Order: translate(-(position + render_offset)), scale(effective_zoom), rotate(rotation).
    pub fn view_matrix(&self) -> Mat3 {
        let (ox, oy) = self.render_offset();
        let pos = Vec2::new(self.position.x + ox, self.position.y + oy);
        let translation = Mat3::from_translation(Vec2::new(-pos.x, -pos.y));
        let rotation = Mat3::from_rotation(self.rotation);
        let scale = Mat3::from_scale(Vec2::splat(self.effective_zoom()));
        scale * rotation * translation
    }
}

impl Default for Camera2D {
    fn default() -> Self {
        Self::new(800.0, 600.0)
    }
}
