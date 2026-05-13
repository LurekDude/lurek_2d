//! Own camera-local path and zoom tweens used by the Lua wrapper layer.
//! Keep animation state outside `Camera2D` domain state.

#[derive(Clone)]
/// Animate waypoints over fixed duration and return interpolated world positions.
pub struct CameraPath {
    waypoints: Vec<[f32; 2]>,
    /// Store total animation duration in seconds.
    pub duration: f32,
    /// Store elapsed animation time in seconds.
    pub elapsed: f32,
    /// Mark whether the path is active.
    pub active: bool,
}

impl CameraPath {
    /// Create a path from waypoints and return it with clamped positive duration.
    pub fn new(waypoints: Vec<[f32; 2]>, duration: f32) -> Self {
        CameraPath {
            waypoints,
            duration: duration.max(1e-6),
            elapsed: 0.0,
            active: true,
        }
    }

    /// Advance the path by `dt` and return current position; return `None` when inactive or invalid.
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

    /// Return normalized path progress in `[0, 1]`, or `1` when duration is non-positive.
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }

    /// Reset elapsed time to zero and reactivate the path.
    pub fn reset(&mut self) {
        self.elapsed = 0.0;
        self.active = true;
    }
}

/// Select easing curve used by camera-local tweens.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CameraTweenEasing {
    /// Apply linear interpolation.
    Linear,
    /// Apply smoothstep interpolation.
    SmoothStep,
    /// Apply cubic ease-out interpolation.
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

#[derive(Clone)]
/// Animate zoom from start value to target value over fixed duration.
pub struct CameraZoomTween {
    /// Store zoom at tween start.
    pub start_zoom: f32,
    /// Store target zoom reached at completion.
    pub target_zoom: f32,
    /// Store total tween duration in seconds.
    pub duration: f32,
    /// Store elapsed tween time in seconds.
    pub elapsed: f32,
    /// Mark whether the tween is active.
    pub active: bool,
    /// Store easing function selection.
    pub easing: CameraTweenEasing,
}

impl CameraZoomTween {
    /// Create a linear zoom tween and return it.
    pub fn new(start_zoom: f32, target_zoom: f32, duration: f32) -> Self {
        Self::new_with_easing(start_zoom, target_zoom, duration, CameraTweenEasing::Linear)
    }

    /// Create a zoom tween with explicit easing and return it.
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

    /// Advance tween by `dt` and return zoom sample; return target once on completion.
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

    /// Return normalized tween progress in `[0, 1]`, or `1` when duration is non-positive.
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }
}

/// Alias `CameraZoomTween` for backward compatibility.
pub type ZoomTween = CameraZoomTween;

