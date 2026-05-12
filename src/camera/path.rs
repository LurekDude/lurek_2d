//! Camera path follower and smooth-zoom tween for [`super::Camera2D`].
//!
//! Both types are designed to live inside the Lua API wrapper (`LuaCamera2D`)
//! rather than inside the domain `Camera2D`, keeping the domain free of
//! animation state.

// ---------------------------------------------------------------------------
// CameraPath
// ---------------------------------------------------------------------------

/// Animates a camera along a series of world-space waypoints over a fixed
/// duration using linear interpolation between consecutive points.
///
/// Call [`CameraPath::update`] every frame with the delta-time; it returns the
/// interpolated `(x, y)` position while the path is active and `None` once it
/// has finished.
#[derive(Clone)]
pub struct CameraPath {
    waypoints: Vec<[f32; 2]>,
    /// Total animation duration in seconds.
    pub duration: f32,
    /// Time elapsed since the path was started.
    pub elapsed: f32,
    /// `true` while the path is playing.
    pub active: bool,
}

impl CameraPath {
    /// Creates a new `CameraPath`.
    ///
    /// `waypoints` must contain at least two points; if fewer are provided
    /// the path is considered immediately done.
    pub fn new(waypoints: Vec<[f32; 2]>, duration: f32) -> Self {
        CameraPath {
            waypoints,
            duration: duration.max(1e-6),
            elapsed: 0.0,
            active: true,
        }
    }

    /// Advances the path by `dt` seconds and returns the current position, or
    /// `None` when the path has completed.
    pub fn update(&mut self, dt: f32) -> Option<(f32, f32)> {
        if !self.active || self.waypoints.len() < 2 {
            return None;
        }
        self.elapsed += dt;
        if self.elapsed >= self.duration {
            self.active = false;
            let last = self.waypoints.last().copied().unwrap_or([0.0, 0.0]);
            return Some((last[0], last[1]));
        }
        // Progress across all segments.
        let t = (self.elapsed / self.duration).clamp(0.0, 1.0);
        let num_segs = (self.waypoints.len() - 1) as f32;
        let seg_t = t * num_segs;
        let seg_idx = seg_t.floor() as usize;
        let seg_idx = seg_idx.min(self.waypoints.len() - 2);
        let local_t = seg_t - seg_idx as f32;
        let a = self.waypoints[seg_idx];
        let b = self.waypoints[seg_idx + 1];
        Some((
            a[0] + (b[0] - a[0]) * local_t,
            a[1] + (b[1] - a[1]) * local_t,
        ))
    }

    /// Returns the fractional progress `[0, 1]` of the path.
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }

    /// Resets the path back to the beginning.
    pub fn reset(&mut self) {
        self.elapsed = 0.0;
        self.active = true;
    }
}

// ---------------------------------------------------------------------------
// ZoomTween
// ---------------------------------------------------------------------------

/// Easing mode for camera-local tweens.
///
/// This type is intentionally camera-scoped and should be used when animating
/// camera-only state (`CameraPath`, `CameraZoomTween`). For generic gameplay
/// tweening, use the shared tween module.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CameraTweenEasing {
    /// Linear interpolation.
    Linear,
    /// Smoothstep interpolation (`t*t*(3-2*t)`).
    SmoothStep,
    /// Ease-out cubic interpolation.
    EaseOutCubic,
}

impl CameraTweenEasing {
    fn apply(self, t: f32) -> f32 {
        let clamped = t.clamp(0.0, 1.0);
        match self {
            Self::Linear => clamped,
            Self::SmoothStep => clamped * clamped * (3.0 - 2.0 * clamped),
            Self::EaseOutCubic => 1.0 - (1.0 - clamped).powi(3),
        }
    }
}

/// Smoothly transitions a camera zoom level from a start value to a target
/// value over a fixed duration.
///
/// Call [`ZoomTween::update`] every frame; it returns the current zoom while
/// active and `None` once it has finished.
#[derive(Clone)]
pub struct CameraZoomTween {
    /// Zoom level at the start of the tween.
    pub start_zoom: f32,
    /// Desired final zoom level.
    pub target_zoom: f32,
    /// Total duration in seconds.
    pub duration: f32,
    /// Time elapsed since the tween was started.
    pub elapsed: f32,
    /// `true` while the tween is running.
    pub active: bool,
    /// Easing mode used for interpolation.
    pub easing: CameraTweenEasing,
}

impl CameraZoomTween {
    /// Creates a new `CameraZoomTween` with linear easing.
    pub fn new(start_zoom: f32, target_zoom: f32, duration: f32) -> Self {
        Self::new_with_easing(start_zoom, target_zoom, duration, CameraTweenEasing::Linear)
    }

    /// Creates a new `CameraZoomTween` with explicit easing.
    pub fn new_with_easing(
        start_zoom: f32,
        target_zoom: f32,
        duration: f32,
        easing: CameraTweenEasing,
    ) -> Self {
        CameraZoomTween {
            start_zoom,
            target_zoom,
            duration: duration.max(1e-6),
            elapsed: 0.0,
            active: true,
            easing,
        }
    }

    /// Advances the tween by `dt` seconds and returns the current zoom, or
    /// `None` when the tween has completed.
    pub fn update(&mut self, dt: f32) -> Option<f32> {
        if !self.active {
            return None;
        }
        self.elapsed += dt;
        if self.elapsed >= self.duration {
            self.active = false;
            return Some(self.target_zoom);
        }
        let t = self.easing.apply(self.elapsed / self.duration);
        Some(self.start_zoom + (self.target_zoom - self.start_zoom) * t)
    }

    /// Returns the fractional progress `[0, 1]` of the tween.
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }
}

/// Backward-compatible alias for camera-local zoom tween.
pub type ZoomTween = CameraZoomTween;
