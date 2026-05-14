use crate::camera::effects::{CameraBreathing, CameraSway, ZoomPulse};
use crate::math::{Mat3, Rect, Vec2};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
/// Selects easing behavior used by target-follow interpolation.
pub enum CameraFollowEasing {
    /// Uses linear interpolation with constant progression speed.
    Linear,
    /// Uses smooth-step interpolation for eased start and end.
    SmoothStep,
    /// Uses cubic ease-out interpolation for fast start and soft stop.
    EaseOutCubic,
}
impl CameraFollowEasing {
    /// Evaluate follow easing and return clamped interpolation factor.
    fn apply(self, t: f32) -> f32 {
        let clamped = t.clamp(0.0, 1.0);
        match self {
            Self::Linear => clamped,
            Self::SmoothStep => clamped * clamped * (3.0 - 2.0 * clamped),
            Self::EaseOutCubic => 1.0 - (1.0 - clamped).powi(3),
        }
    }
}

/// Stores minimal camera transform state used by render command helpers.
pub struct Camera {
    /// Stores camera world position in scene units.
    pub position: Vec2,
    /// Stores uniform zoom multiplier applied to world coordinates.
    pub zoom: f32,
    /// Stores camera rotation angle in radians.
    pub rotation: f32,
}
impl Camera {
    /// Create camera state and return it with provided transform values.
    pub fn new(position: Vec2, zoom: f32, rotation: f32) -> Self {
        Camera {
            position,
            zoom,
            rotation,
        }
    }
    /// Build camera view matrix and return world-to-view transform.
    pub fn view_matrix(&self) -> Mat3 {
        let translation = Mat3::from_translation(Vec2::new(-self.position.x, -self.position.y));
        let rotation = Mat3::from_rotation(self.rotation);
        let scale = Mat3::from_scale(Vec2::splat(self.zoom));
        scale * rotation * translation
    }
    /// Set camera position and return after replacing previous value.
    pub fn set_position(&mut self, position: Vec2) {
        self.position = position;
    }
    /// Set camera zoom and return after replacing previous value.
    pub fn set_zoom(&mut self, zoom: f32) {
        self.zoom = zoom;
    }
    /// Set camera rotation and return after replacing previous value.
    pub fn set_rotation(&mut self, rotation: f32) {
        self.rotation = rotation;
    }
}
/// Provides default camera transform values for new contexts.
impl Default for Camera {
    /// Create default camera and return identity-like transform values.
    fn default() -> Self {
        Camera {
            position: Vec2::ZERO,
            zoom: 1.0,
            rotation: 0.0,
        }
    }
}

/// Stores full 2D camera runtime state used by follow and effect systems.
pub struct Camera2D {
    /// Stores camera world position in scene units.
    pub position: Vec2,
    /// Stores current zoom value applied to rendering.
    pub zoom: f32,
    /// Stores current camera rotation in radians.
    pub rotation: f32,
    /// Stores viewport rectangle in screen-space units.
    pub viewport: Rect,
    /// Stores optional world bounds constraining camera center.
    pub bounds: Option<Rect>,
    /// Stores optional follow target in world-space coordinates.
    pub target: Option<Vec2>,
    /// Stores follow smoothing strength scalar.
    pub follow_smooth: f32,
    /// Stores optional dead-zone half-extents in world units.
    pub dead_zone: Option<(f32, f32)>,
    /// Stores look-ahead multiplier applied to target velocity.
    pub look_ahead: f32,
    /// Stores easing mode used by follow smoothing.
    pub follow_easing: CameraFollowEasing,
    /// Stores configured shake amplitude in world units.
    shake_intensity: f32,
    /// Stores total shake duration in seconds.
    shake_duration: f32,
    /// Stores remaining shake time in seconds.
    shake_timer: f32,
    /// Stores current procedural shake offset in world units.
    shake_offset: Vec2,
    /// Stores previous follow target sample for velocity estimation.
    prev_target: Option<Vec2>,
    /// Stores optional minimum zoom constraint.
    zoom_min: Option<f32>,
    /// Stores optional maximum zoom constraint.
    zoom_max: Option<f32>,
    /// Stores zoom damping coefficient for smoothing.
    zoom_damping: f32,
    /// Stores optional minimum rotation constraint in radians.
    rotation_min: Option<f32>,
    /// Stores optional maximum rotation constraint in radians.
    rotation_max: Option<f32>,
    /// Stores rotation damping coefficient for smoothing.
    rotation_damping: f32,
    /// Stores target zoom value used by damping updates.
    zoom_target: f32,
    /// Stores target rotation value used by damping updates.
    rotation_target: f32,
    /// Stores zoom pulse effect state composed into effective zoom.
    pub zoom_pulse: ZoomPulse,
    /// Stores positional sway effect state composed into render offset.
    pub sway: CameraSway,
    /// Stores breathing effect state composed into effective zoom.
    pub breathing: CameraBreathing,
}
impl Camera2D {
    /// Create 2D camera state and return it for the provided viewport size.
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
    /// Set camera position from x/y values and return after update.
    pub fn set_position(&mut self, x: f32, y: f32) {
        self.position = Vec2::new(x, y);
    }
    /// Read camera position and return (x, y).
    pub fn get_position(&self) -> (f32, f32) {
        (self.position.x, self.position.y)
    }
    /// Set zoom target and return after applying immediate mode when undamped.
    pub fn set_zoom(&mut self, z: f32) {
        self.zoom_target = z;
        if self.zoom_damping <= f32::EPSILON {
            self.zoom = z;
        }
    }
    /// Read current zoom value and return scalar zoom.
    pub fn get_zoom(&self) -> f32 {
        self.zoom
    }
    /// Set rotation target and return after applying immediate mode when undamped.
    pub fn set_rotation(&mut self, r: f32) {
        self.rotation_target = r;
        if self.rotation_damping <= f32::EPSILON {
            self.rotation = r;
        }
    }
    /// Read current rotation value and return radians.
    pub fn get_rotation(&self) -> f32 {
        self.rotation
    }
    /// Set follow easing mode and return after replacing previous mode.
    pub fn set_follow_easing(&mut self, easing: CameraFollowEasing) {
        self.follow_easing = easing;
    }
    /// Read follow easing mode and return selected easing enum.
    pub fn get_follow_easing(&self) -> CameraFollowEasing {
        self.follow_easing
    }
    /// Set zoom constraints and return after clamping current and target zoom.
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
    /// Read zoom constraints and return (min, max) options.
    pub fn get_zoom_constraints(&self) -> (Option<f32>, Option<f32>) {
        (self.zoom_min, self.zoom_max)
    }
    /// Set zoom damping coefficient and return after sync when damping is zero.
    pub fn set_zoom_damping(&mut self, damping: f32) {
        self.zoom_damping = damping.clamp(0.0, 1.0);
        if self.zoom_damping <= f32::EPSILON {
            self.zoom = self.zoom_target;
        }
    }
    /// Read zoom damping coefficient and return normalized damping value.
    pub fn get_zoom_damping(&self) -> f32 {
        self.zoom_damping
    }
    /// Set rotation constraints and return after clamping current and target rotation.
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
    /// Read rotation constraints and return (min, max) options.
    pub fn get_rotation_constraints(&self) -> (Option<f32>, Option<f32>) {
        (self.rotation_min, self.rotation_max)
    }
    /// Set rotation damping coefficient and return after sync when damping is zero.
    pub fn set_rotation_damping(&mut self, damping: f32) {
        self.rotation_damping = damping.clamp(0.0, 1.0);
        if self.rotation_damping <= f32::EPSILON {
            self.rotation = self.rotation_target;
        }
    }
    /// Read rotation damping coefficient and return normalized damping value.
    pub fn get_rotation_damping(&self) -> f32 {
        self.rotation_damping
    }
    /// Apply tight-follow preset and return after updating follow parameters.
    pub fn preset_tight_follow(&mut self) {
        self.set_follow_smooth(0.9);
        self.set_dead_zone(20.0, 20.0);
        self.set_look_ahead(0.5);
    }
    /// Apply cinematic-follow preset and return after updating follow parameters.
    pub fn preset_cinematic_follow(&mut self) {
        self.set_follow_smooth(0.3);
        self.set_dead_zone(100.0, 100.0);
        self.set_look_ahead(0.0);
    }
    /// Apply balanced-follow preset and return after updating follow parameters.
    pub fn preset_balanced_follow(&mut self) {
        self.set_follow_smooth(0.6);
        self.set_dead_zone(40.0, 40.0);
        self.set_look_ahead(0.3);
    }
    /// Apply aggressive-follow preset and return after updating follow parameters.
    pub fn preset_aggressive_follow(&mut self) {
        self.set_follow_smooth(0.99);
        self.set_dead_zone(5.0, 5.0);
        self.set_look_ahead(1.0);
    }
    /// Resize viewport to window dimensions and return after clamping minimum size.
    pub fn on_window_resize(&mut self, window_width: f32, window_height: f32) {
        self.set_viewport(0.0, 0.0, window_width.max(1.0), window_height.max(1.0));
    }
    /// Resize viewport using scale mode and return after applying computed transform.
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
    /// Set viewport rectangle and return after replacing previous viewport.
    pub fn set_viewport(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport = Rect::new(x, y, w, h);
    }
    /// Read viewport rectangle and return (x, y, w, h).
    pub fn get_viewport(&self) -> (f32, f32, f32, f32) {
        (
            self.viewport.x,
            self.viewport.y,
            self.viewport.width,
            self.viewport.height,
        )
    }
    /// Set camera bounds rectangle and return after enabling bounds.
    pub fn set_bounds(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.bounds = Some(Rect::new(x, y, w, h));
    }
    /// Read camera bounds and return rectangle tuple when bounds exist.
    pub fn get_bounds(&self) -> Option<(f32, f32, f32, f32)> {
        self.bounds.map(|b| (b.x, b.y, b.width, b.height))
    }
    /// Disable bounds constraint and return after clearing bounds.
    pub fn remove_bounds(&mut self) {
        self.bounds = None;
    }
    /// Check bounds presence and return true when bounds are enabled.
    pub fn has_bounds(&self) -> bool {
        self.bounds.is_some()
    }
    /// Move camera by delta vector and return after updating position.
    pub fn move_by(&mut self, dx: f32, dy: f32) {
        self.position.x += dx;
        self.position.y += dy;
    }
    /// Set camera position directly to target coordinates and return.
    pub fn look_at(&mut self, x: f32, y: f32) {
        self.position = Vec2::new(x, y);
    }
    /// Convert screen coordinates to world coordinates and return mapped pair.
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
    /// Convert world coordinates to screen coordinates and return mapped pair.
    pub fn to_screen_coords(&self, world_x: f32, world_y: f32) -> (f32, f32) {
        let sx = (world_x - self.position.x - self.shake_offset.x) * self.zoom
            + self.viewport.width * 0.5;
        let sy = (world_y - self.position.y - self.shake_offset.y) * self.zoom
            + self.viewport.height * 0.5;
        (sx, sy)
    }
    /// Compute visible world rectangle and return (x, y, w, h).
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
    /// Set dead-zone size and return after storing half-extents.
    pub fn set_dead_zone(&mut self, w: f32, h: f32) {
        self.dead_zone = Some((w * 0.5, h * 0.5));
    }
    /// Read dead-zone size and return full extents when configured.
    pub fn get_dead_zone(&self) -> Option<(f32, f32)> {
        self.dead_zone.map(|(hw, hh)| (hw * 2.0, hh * 2.0))
    }
    /// Set follow target and return after enabling target tracking.
    pub fn set_target(&mut self, x: f32, y: f32) {
        self.target = Some(Vec2::new(x, y));
    }
    /// Read follow target and return (x, y) when target exists.
    pub fn get_target(&self) -> Option<(f32, f32)> {
        self.target.map(|t| (t.x, t.y))
    }
    /// Disable target tracking and return after clearing target state.
    pub fn clear_target(&mut self) {
        self.target = None;
    }
    /// Set follow smoothing scalar and return after clamping to non-negative.
    pub fn set_follow_smooth(&mut self, speed: f32) {
        self.follow_smooth = speed.max(0.0);
    }
    /// Read follow smoothing scalar and return configured value.
    pub fn get_follow_smooth(&self) -> f32 {
        self.follow_smooth
    }
    /// Set look-ahead multiplier and return after replacing previous value.
    pub fn set_look_ahead(&mut self, mul: f32) {
        self.look_ahead = mul;
    }
    /// Read look-ahead multiplier and return configured value.
    pub fn get_look_ahead(&self) -> f32 {
        self.look_ahead
    }
    /// Start shake effect and return after configuring timer and intensity.
    pub fn shake(&mut self, intensity: f32, duration: f32) {
        self.shake_intensity = intensity;
        self.shake_duration = duration;
        self.shake_timer = duration;
    }
    /// Read current shake offset and return (x, y).
    pub fn get_shake_offset(&self) -> (f32, f32) {
        (self.shake_offset.x, self.shake_offset.y)
    }
    /// Advance camera simulation and return after follow, bounds, shake, and damping updates.
    pub fn update(&mut self, dt: f32) {
        if let Some(target) = self.target {
            let mut desired = target;
            if let Some((hw, hh)) = self.dead_zone {
                let dx = target.x - self.position.x;
                let dy = target.y - self.position.y;
                if dx.abs() <= hw && dy.abs() <= hh {
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
    /// Read zoom including active effects and return effective zoom value.
    pub fn effective_zoom(&self) -> f32 {
        self.zoom + self.zoom_pulse.current_delta() + self.breathing.current_delta()
    }
    /// Read active effect offset and return sway contribution tuple.
    pub fn effect_offset(&self) -> (f32, f32) {
        self.sway.current_offset()
    }
    /// Read render offset and return sum of sway and shake offsets.
    pub fn render_offset(&self) -> (f32, f32) {
        let (sx, sy) = self.sway.current_offset();
        (sx + self.shake_offset.x, sy + self.shake_offset.y)
    }
    /// Build view matrix from camera state and return world-to-view transform.
    pub fn view_matrix(&self) -> Mat3 {
        let (ox, oy) = self.render_offset();
        let pos = Vec2::new(self.position.x + ox, self.position.y + oy);
        let translation = Mat3::from_translation(Vec2::new(-pos.x, -pos.y));
        let rotation = Mat3::from_rotation(self.rotation);
        let scale = Mat3::from_scale(Vec2::splat(self.effective_zoom()));
        scale * rotation * translation
    }
}
/// Provides default 2D camera configured for 800x600 viewport.
impl Default for Camera2D {
    /// Create default 2D camera and return state sized for 800x600 viewport.
    fn default() -> Self {
        Self::new(800.0, 600.0)
    }
}
