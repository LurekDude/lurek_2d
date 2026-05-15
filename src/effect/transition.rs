//! - Full-screen transition effects: fade, wipe, iris wipe, and dissolve.
//! - String-based kind parsing with canonical name round-tripping.
//! - Time-based playback lifecycle with forward and reverse modes.
//! - Normalized progress query for renderer consumption.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
/// Enumerates supported full-screen transition styles.
pub enum TransitionKind {
    /// Uniform alpha fade across the screen.
    Fade,
    /// Directional wipe transition.
    Wipe,
    /// Circular iris wipe transition.
    IrisWipe,
    /// Noise-like dissolve transition.
    Dissolve,
}
impl TransitionKind {
    #[allow(clippy::should_implement_trait)]
    /// Parses a user-facing transition name, defaulting to fade for unknown values.
    pub fn from_str(s: &str) -> Self {
        match s {
            "wipe" => TransitionKind::Wipe,
            "iris" | "iris_wipe" | "iriswipe" => TransitionKind::IrisWipe,
            "dissolve" => TransitionKind::Dissolve,
            _ => TransitionKind::Fade,
        }
    }
    /// Returns the lowercase canonical name for this transition kind.
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
/// Stores runtime state for a time-based screen transition.
pub struct ScreenTransition {
    /// Transition algorithm to evaluate.
    pub kind: TransitionKind,
    /// RGBA color used by the transition renderer.
    pub color: [f32; 4],
    /// Total transition duration in seconds.
    pub duration: f32,
    /// Time already elapsed since playback started.
    pub elapsed: f32,
    /// Indicates whether the transition is currently playing.
    pub active: bool,
    /// Plays the transition in reverse when set.
    pub reversed: bool,
}
impl ScreenTransition {
    /// Creates an inactive transition with clamped nonzero duration.
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
    /// Starts forward playback from the beginning.
    pub fn play(&mut self) {
        self.elapsed = 0.0;
        self.reversed = false;
        self.active = true;
    }
    /// Starts reverse playback from the beginning.
    pub fn reverse(&mut self) {
        self.elapsed = 0.0;
        self.reversed = true;
        self.active = true;
    }
    /// Advances playback by `dt` seconds and returns whether the transition was active.
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
    /// Returns normalized transition progress after applying reverse playback.
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
    /// Returns whether the transition is currently playing.
    pub fn is_active(&self) -> bool {
        self.active
    }
    /// Returns whether playback has reached the end of the transition.
    pub fn is_done(&self) -> bool {
        !self.active && self.elapsed >= self.duration
    }
}
