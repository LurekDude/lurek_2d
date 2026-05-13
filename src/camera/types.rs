//! Define core camera state objects used by renderer and runtime state.
//! Keep both flat `Camera` and feature-rich `Camera2D` in one domain file.
//! Own follow, bounds, shake, damping, and effect composition math.

use crate::camera::effects::{CameraBreathing, CameraSway, ZoomPulse};
use crate::math::{Mat3, Rect, Vec2};

/// Easing mode used by camera follow interpolation.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CameraFollowEasing {
    /// Linear interpolation.
    Linear,
    /// Smoothstep interpolation (`t*t*(3-2*t)`).
    SmoothStep,
    /// Ease-out cubic interpolation.
    EaseOutCubic,
}

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

/// Store flat camera transform used by shared render state.
pub struct Camera {
    /// World-space centre point.
    pub position: Vec2,
    /// Uniform zoom factor (`1.0` = no zoom).
    pub zoom: f32,
    /// Rotation in radians (counter-clockwise positive).
    pub rotation: f32,
}

impl Camera {
    /// Create a new `Camera` with the given position, zoom, and rotation.
    pub fn new(position: Vec2, zoom: f32, rotation: f32) -> Self {
        Camera {
            position,
            zoom,
            rotation,
        }
    }

    /// Compute camera view matrix and return combined translation, rotation, and zoom scale.
    pub fn view_matrix(&self) -> Mat3 {
        let translation = Mat3::from_translation(Vec2::new(-self.position.x, -self.position.y));
        let rotation = Mat3::from_rotation(self.rotation);
        let scale = Mat3::from_scale(Vec2::splat(self.zoom));
        scale * rotation * translation
    }

    /// Move the camera to `position` in world space.
    pub fn set_position(&mut self, position: Vec2) {
        self.position = position;
    }

    /// Set camera zoom.
    pub fn set_zoom(&mut self, zoom: f32) {
        self.zoom = zoom;
    }

    /// Set camera rotation in radians.
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

/// Store advanced 2D camera state with follow, bounds, shake, and effects.
pub struct Camera2D {
    /// Camera world-space position (centre of the viewport).
    pub position: Vec2,
    /// Uniform zoom factor (`1.0` = no zoom).
    pub zoom: f32,
    /// Rotation in radians (counter-clockwise positive).
    pub rotation: f32,
    /// Viewport rectangle in screen pixels: `(x, y, width, height)`.
    pub viewport: Rect,
    /// Store optional world bounds used to clamp visible camera area.
    pub bounds: Option<Rect>,
    /// Target world position the camera tries to follow.
    pub target: Option<Vec2>,
    /// Interpolation speed for smooth following. `0.0` = instant snap.
    pub follow_smooth: f32,
    /// Store follow dead-zone half extents `(half_w, half_h)` around camera center.
    pub dead_zone: Option<(f32, f32)>,
    /// Store look-ahead multiplier applied to estimated target velocity.
    pub look_ahead: f32,
    /// Follow interpolation easing mode.
    pub follow_easing: CameraFollowEasing,
    /// Current shake intensity (pixels).
    shake_intensity: f32,
    /// Total shake duration in seconds.
    shake_duration: f32,
    /// Remaining shake time.
    shake_timer: f32,
    /// Current frame's shake offset (applied in [`view_matrix`](Self::view_matrix)).
    shake_offset: Vec2,
    /// Previous target for velocity estimation (look-ahead).
    prev_target: Option<Vec2>,
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
    /// Zoom pulse: brief zoom-in with sine envelope decay.
    pub zoom_pulse: ZoomPulse,
    /// Camera sway: sinusoidal x/y offset oscillation.
    pub sway: CameraSway,
    /// Camera breathing: subtle periodic zoom oscillation.
    pub breathing: CameraBreathing,
}

impl Camera2D {
    /// Create a `Camera2D` at origin for provided viewport dimensions and return it.
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

    /// Set the camera position in world space.
    pub fn set_position(&mut self, x: f32, y: f32) {
        self.position = Vec2::new(x, y);
    }

    /// Return the camera position as `(x, y)`.
    pub fn get_position(&self) -> (f32, f32) {
        (self.position.x, self.position.y)
    }

    /// Set zoom target and update live zoom immediately when damping is disabled.
    pub fn set_zoom(&mut self, z: f32) {
        self.zoom_target = z;
        if self.zoom_damping <= f32::EPSILON {
            self.zoom = z;
        }
    }
    /// Return current zoom factor and preserve damping state.
    pub fn get_zoom(&self) -> f32 {
        self.zoom
    }

    /// Set rotation target and update live rotation immediately when damping is disabled.
    pub fn set_rotation(&mut self, r: f32) {
        self.rotation_target = r;
        if self.rotation_damping <= f32::EPSILON {
            self.rotation = r;
        }
    }

    /// Return the current rotation in radians.
    pub fn get_rotation(&self) -> f32 {
        self.rotation
    }

    /// Set the follow interpolation easing mode.
    pub fn set_follow_easing(&mut self, easing: CameraFollowEasing) {
        self.follow_easing = easing;
    }

    /// Return the current follow interpolation easing mode.
    pub fn get_follow_easing(&self) -> CameraFollowEasing {
        self.follow_easing
    }

    /// Set optional min and max zoom constraints and clamp current targets.
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

    /// Return zoom constraints as `(min_zoom, max_zoom)` with `None` for unconstrained sides.
    pub fn get_zoom_constraints(&self) -> (Option<f32>, Option<f32>) {
        (self.zoom_min, self.zoom_max)
    }

    /// Set zoom damping in `[0.0, 1.0]` and snap to target when damping is zero.
    pub fn set_zoom_damping(&mut self, damping: f32) {
        self.zoom_damping = damping.clamp(0.0, 1.0);
        if self.zoom_damping <= f32::EPSILON {
            self.zoom = self.zoom_target;
        }
    }

    /// Return the current zoom damping factor.
    pub fn get_zoom_damping(&self) -> f32 {
        self.zoom_damping
    }

    /// Set optional min and max rotation constraints and clamp current targets.
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

    /// Return rotation constraints as `(min_rot, max_rot)` with `None` for unconstrained sides.
    pub fn get_rotation_constraints(&self) -> (Option<f32>, Option<f32>) {
        (self.rotation_min, self.rotation_max)
    }

    /// Set rotation damping in `[0.0, 1.0]` and snap to target when damping is zero.
    pub fn set_rotation_damping(&mut self, damping: f32) {
        self.rotation_damping = damping.clamp(0.0, 1.0);
        if self.rotation_damping <= f32::EPSILON {
            self.rotation = self.rotation_target;
        }
    }

    /// Return the current rotation damping factor.
    pub fn get_rotation_damping(&self) -> f32 {
        self.rotation_damping
    }

    /// Set preset values for a tight follow profile.
    pub fn preset_tight_follow(&mut self) {
        self.set_follow_smooth(0.9);
        self.set_dead_zone(20.0, 20.0);
        self.set_look_ahead(0.5);
    }

    /// Set preset values for a cinematic follow profile.
    pub fn preset_cinematic_follow(&mut self) {
        self.set_follow_smooth(0.3);
        self.set_dead_zone(100.0, 100.0);
        self.set_look_ahead(0.0);
    }

    /// Set preset values for a balanced follow profile.
    pub fn preset_balanced_follow(&mut self) {
        self.set_follow_smooth(0.6);
        self.set_dead_zone(40.0, 40.0);
        self.set_look_ahead(0.3);
    }

    /// Set preset values for an aggressive follow profile.
    pub fn preset_aggressive_follow(&mut self) {
        self.set_follow_smooth(0.99);
        self.set_dead_zone(5.0, 5.0);
        self.set_look_ahead(1.0);
    }

    /// Set viewport to full window rectangle for raw window resize values.
    pub fn on_window_resize(&mut self, window_width: f32, window_height: f32) {
        self.set_viewport(0.0, 0.0, window_width.max(1.0), window_height.max(1.0));
    }

    /// Recompute viewport from logical game size, window size, and selected scale mode.
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

    /// Set the viewport rectangle in screen pixels.
    pub fn set_viewport(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport = Rect::new(x, y, w, h);
    }

    /// Return the viewport as `(x, y, w, h)`.
    pub fn get_viewport(&self) -> (f32, f32, f32, f32) {
        (
            self.viewport.x,
            self.viewport.y,
            self.viewport.width,
            self.viewport.height,
        )
    }

    /// Set world-space bounds for camera clamping.
    pub fn set_bounds(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.bounds = Some(Rect::new(x, y, w, h));
    }
    /// Return world bounds tuple when bounds are set.
    pub fn get_bounds(&self) -> Option<(f32, f32, f32, f32)> {
        self.bounds.map(|b| (b.x, b.y, b.width, b.height))
    }

    /// Clear world bounds and return without changing other camera state.
    pub fn remove_bounds(&mut self) {
        self.bounds = None;
    }

    /// Return `true` if world-space bounds are set.
    pub fn has_bounds(&self) -> bool {
        self.bounds.is_some()
    }

    /// Move camera by world-space delta `(dx, dy)`.
    pub fn move_by(&mut self, dx: f32, dy: f32) {
        self.position.x += dx;
        self.position.y += dy;
    }

    /// Set camera position directly from world coordinates.
    pub fn look_at(&mut self, x: f32, y: f32) {
        self.position = Vec2::new(x, y);
    }

    /// Convert screen coordinates to world coordinates using zoom, viewport center, and shake offset.
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

    /// Convert world coordinates to screen coordinates.
    pub fn to_screen_coords(&self, world_x: f32, world_y: f32) -> (f32, f32) {
        let sx = (world_x - self.position.x - self.shake_offset.x) * self.zoom
            + self.viewport.width * 0.5;
        let sy = (world_y - self.position.y - self.shake_offset.y) * self.zoom
            + self.viewport.height * 0.5;
        (sx, sy)
    }

    /// Return visible world-space AABB as `(x, y, w, h)`.
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

    /// Set dead-zone extents from full width and height values.
    pub fn set_dead_zone(&mut self, w: f32, h: f32) {
        self.dead_zone = Some((w * 0.5, h * 0.5));
    }

    /// Return dead-zone full extents `(width, height)` when configured.
    pub fn get_dead_zone(&self) -> Option<(f32, f32)> {
        self.dead_zone.map(|(hw, hh)| (hw * 2.0, hh * 2.0))
    }

    /// Set follow target position.
    pub fn set_target(&mut self, x: f32, y: f32) {
        self.target = Some(Vec2::new(x, y));
    }

    /// Return the current follow target, if any.
    pub fn get_target(&self) -> Option<(f32, f32)> {
        self.target.map(|t| (t.x, t.y))
    }

    /// Clear the follow target so the camera stops tracking.
    pub fn clear_target(&mut self) {
        self.target = None;
    }

    /// Set smooth-follow speed where `0.0` snaps instantly and higher values smooth motion.
    pub fn set_follow_smooth(&mut self, speed: f32) {
        self.follow_smooth = speed.max(0.0);
    }
    /// Return smooth-follow speed.
    pub fn get_follow_smooth(&self) -> f32 {
        self.follow_smooth
    }

    /// Set look-ahead multiplier.
    pub fn set_look_ahead(&mut self, mul: f32) {
        self.look_ahead = mul;
    }
    /// Return look-ahead multiplier.
    pub fn get_look_ahead(&self) -> f32 {
        self.look_ahead
    }

    /// Start a camera shake effect.
    pub fn shake(&mut self, intensity: f32, duration: f32) {
        self.shake_intensity = intensity;
        self.shake_duration = duration;
        self.shake_timer = duration;
    }

    /// Return the current shake offset as `(dx, dy)`.
    pub fn get_shake_offset(&self) -> (f32, f32) {
        (self.shake_offset.x, self.shake_offset.y)
    }

    /// Update follow, shake, bounds, damping, and effect state for frame delta `dt`.
    pub fn update(&mut self, dt: f32) {
        if let Some(target) = self.target {
            let mut desired = target;
            if let Some((hw, hh)) = self.dead_zone {
                let dx = target.x - self.position.x;
                let dy = target.y - self.position.y;
                if dx.abs() <= hw && dy.abs() <= hh {
                    // Keep camera static while target remains inside dead-zone extents.
                    desired = self.position;
                }
            }
            if self.look_ahead > 0.0 {
                if let Some(prev) = self.prev_target {
                    let vx = target.x - prev.x;
                    let vy = target.y - prev.y;
                    desired.x += vx * self.look_ahead;
                    desired.y += vy * self.look_ahead;
                }
            }
            if self.follow_smooth > 0.0 {
                let t = self.follow_easing.apply((self.follow_smooth * dt).min(1.0));
                self.position.x += (desired.x - self.position.x) * t;
                self.position.y += (desired.y - self.position.y) * t;
            } else {
                self.position = desired;
            }

            self.prev_target = Some(target);
        }
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
        if self.shake_timer > 0.0 {
            self.shake_timer -= dt;
            if self.shake_timer <= 0.0 {
                self.shake_timer = 0.0;
                self.shake_offset = Vec2::ZERO;
            } else {
                let ratio = self.shake_timer / self.shake_duration;
                let t = self.shake_timer;
                // Use fixed sinusoid frequencies for deterministic shake offsets.
                let ox = (t * 53.0).sin() * self.shake_intensity * ratio;
                let oy = (t * 97.0).sin() * self.shake_intensity * ratio;
                self.shake_offset = Vec2::new(ox, oy);
            }
        }
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
        self.zoom_pulse.update(dt);
        self.sway.update(dt);
        self.breathing.update(dt);
    }

    /// Return effective zoom computed from base zoom plus pulse and breathing deltas.
    pub fn effective_zoom(&self) -> f32 {
        self.zoom + self.zoom_pulse.current_delta() + self.breathing.current_delta()
    }

    /// Return current sway offset contribution as world-space `(dx, dy)`.
    pub fn effect_offset(&self) -> (f32, f32) {
        self.sway.current_offset()
    }

    /// Return the canonical combined render offset (sway + shake).
    pub fn render_offset(&self) -> (f32, f32) {
        let (sx, sy) = self.sway.current_offset();
        (sx + self.shake_offset.x, sy + self.shake_offset.y)
    }

    /// Compute view matrix from translated render offset, effective zoom, and rotation.
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



