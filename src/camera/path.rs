//! - Waypoint-based camera path interpolation for scripted camera movement.
//! - CameraZoomTween provides eased transitions between zoom levels over time.
//! - CameraTweenEasing selects interpolation curve: linear, smooth-step, or ease-out-cubic.
//! - CameraPath segments multi-point paths with linear interpolation and progress tracking.
//! - ZoomTween is a type alias preserving backwards compatibility.

#[derive(Clone)]
/// Stores waypoint interpolation state for camera positional movement.
pub struct CameraPath {
    /// Stores path waypoints in world-space x/y pairs.
    waypoints: Vec<[f32; 2]>,
    /// Stores total path duration in seconds.
    pub duration: f32,
    /// Stores elapsed time in seconds since path start.
    pub elapsed: f32,
    /// Indicates whether path progression is still active.
    pub active: bool,
}
impl CameraPath {
    /// Create path state and return it with elapsed time reset to zero.
    pub fn new(waypoints: Vec<[f32; 2]>, duration: f32) -> Self {
        CameraPath {
            waypoints,
            duration: duration.max(1e-6),
            elapsed: 0.0,
            active: true,
        }
    }
    /// Advance elapsed time and return interpolated waypoint coordinates while active.
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
    /// Read normalized path progress and return value clamped to [0, 1].
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }
    /// Reset path timer and return after re-enabling active progression.
    pub fn reset(&mut self) {
        self.elapsed = 0.0;
        self.active = true;
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
/// Selects easing profile used by camera tween interpolation.
pub enum CameraTweenEasing {
    /// Uses linear interpolation with constant speed.
    Linear,
    /// Uses smooth-step interpolation for eased in/out motion.
    SmoothStep,
    /// Uses cubic ease-out interpolation for fast start and slow end.
    EaseOutCubic,
}
impl CameraTweenEasing {
    /// Evaluate easing curve and return eased factor in [0, 1].
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
/// Stores zoom tween state used by camera zoom transition flows.
pub struct CameraZoomTween {
    /// Stores zoom value used at tween start.
    pub start_zoom: f32,
    /// Stores zoom value targeted at tween completion.
    pub target_zoom: f32,
    /// Stores total tween duration in seconds.
    pub duration: f32,
    /// Stores elapsed tween time in seconds.
    pub elapsed: f32,
    /// Indicates whether tween is currently active.
    pub active: bool,
    /// Stores interpolation profile applied to tween progress.
    pub easing: CameraTweenEasing,
}
impl CameraZoomTween {
    /// Create linear zoom tween and return initialized state.
    pub fn new(start_zoom: f32, target_zoom: f32, duration: f32) -> Self {
        Self::new_with_easing(start_zoom, target_zoom, duration, CameraTweenEasing::Linear)
    }
    /// Create zoom tween with explicit easing and return initialized state.
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
    /// Advance tween time and return current zoom value while active.
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
    /// Read normalized tween progress and return value clamped to [0, 1].
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }
}

/// Re-exports camera zoom tween under the legacy zoom tween type name.
pub type ZoomTween = CameraZoomTween;
