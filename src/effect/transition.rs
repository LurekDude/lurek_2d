#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TransitionKind {
    Fade,
    Wipe,
    IrisWipe,
    Dissolve,
}
impl TransitionKind {
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Self {
        match s {
            "wipe" => TransitionKind::Wipe,
            "iris" | "iris_wipe" | "iriswipe" => TransitionKind::IrisWipe,
            "dissolve" => TransitionKind::Dissolve,
            _ => TransitionKind::Fade,
        }
    }
    pub fn name(self) -> &'static str {
        match self {
            TransitionKind::Fade => "fade",
            TransitionKind::Wipe => "wipe",
            TransitionKind::IrisWipe => "iris_wipe",
            TransitionKind::Dissolve => "dissolve",
        }
    }
}
#[derive(Clone)]
pub struct ScreenTransition {
    pub kind: TransitionKind,
    pub color: [f32; 4],
    pub duration: f32,
    pub elapsed: f32,
    pub active: bool,
    pub reversed: bool,
}
impl ScreenTransition {
    pub fn new(kind: TransitionKind, duration: f32, color: [f32; 4]) -> Self {
        ScreenTransition {
            kind,
            color,
            duration: duration.max(1e-6),
            elapsed: 0.0,
            active: false,
            reversed: false,
        }
    }
    pub fn play(&mut self) {
        self.elapsed = 0.0;
        self.reversed = false;
        self.active = true;
    }
    pub fn reverse(&mut self) {
        self.elapsed = 0.0;
        self.reversed = true;
        self.active = true;
    }
    pub fn update(&mut self, dt: f32) -> bool {
        if !self.active {
            return false;
        }
        self.elapsed += dt;
        if self.elapsed >= self.duration {
            self.elapsed = self.duration;
            self.active = false;
        }
        true
    }
    pub fn progress(&self) -> f32 {
        let t = if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        };
        if self.reversed {
            1.0 - t
        } else {
            t
        }
    }
    pub fn is_active(&self) -> bool {
        self.active
    }
    pub fn is_done(&self) -> bool {
        !self.active && self.elapsed >= self.duration
    }
}
