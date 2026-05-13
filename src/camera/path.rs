#[derive(Clone)]
pub struct CameraPath {
    waypoints: Vec<[f32; 2]>,
    pub duration: f32,
    pub elapsed: f32,
    pub active: bool,
}
impl CameraPath {
    pub fn new(waypoints: Vec<[f32; 2]>, duration: f32) -> Self {
        CameraPath {
            waypoints,
            duration: duration.max(1e-6),
            elapsed: 0.0,
            active: true,
        }
    }
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
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }
    pub fn reset(&mut self) {
        self.elapsed = 0.0;
        self.active = true;
    }
}
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CameraTweenEasing {
    Linear,
    SmoothStep,
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
pub struct CameraZoomTween {
    pub start_zoom: f32,
    pub target_zoom: f32,
    pub duration: f32,
    pub elapsed: f32,
    pub active: bool,
    pub easing: CameraTweenEasing,
}
impl CameraZoomTween {
    pub fn new(start_zoom: f32, target_zoom: f32, duration: f32) -> Self {
        Self::new_with_easing(start_zoom, target_zoom, duration, CameraTweenEasing::Linear)
    }
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
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }
}
pub type ZoomTween = CameraZoomTween;
