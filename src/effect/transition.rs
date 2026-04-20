//! Screen-transition effect data model for [`super::PostFxStack`].
//!
//! Provides a frame-by-frame state machine that the Lua API uses to drive
//! smooth cross-fade, wipe, iris-wipe, and dissolve transitions between
//! scenes or states.  The struct lives inside the `LuaScreenTransition`
//! wrapper — not in a GPU resource — so no render commands are generated here.

// ---------------------------------------------------------------------------
// TransitionKind
// ---------------------------------------------------------------------------

/// The visual style of a screen transition.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TransitionKind {
    /// Smoothly blends to a solid fill color.
    Fade,
    /// Sweeps a solid fill across the screen left-to-right.
    Wipe,
    /// A circular iris closes/opens from the centre.
    IrisWipe,
    /// Random pixel dithering toward the fill color.
    Dissolve,
}

impl TransitionKind {
    /// Parses the kind from a Lua string.  Falls back to `Fade` on unknown input.
    pub fn from_str(s: &str) -> Self {
        match s {
            "wipe" => TransitionKind::Wipe,
            "iris" | "iris_wipe" | "iriswipe" => TransitionKind::IrisWipe,
            "dissolve" => TransitionKind::Dissolve,
            _ => TransitionKind::Fade,
        }
    }

    /// Returns the canonical lower-case name of this kind.
    pub fn name(self) -> &'static str {
        match self {
            TransitionKind::Fade => "fade",
            TransitionKind::Wipe => "wipe",
            TransitionKind::IrisWipe => "iris_wipe",
            TransitionKind::Dissolve => "dissolve",
        }
    }
}

// ---------------------------------------------------------------------------
// ScreenTransition
// ---------------------------------------------------------------------------

/// Frame-by-frame state machine for a screen transition.
///
/// Call [`ScreenTransition::update`] every frame to advance the transition;
/// [`ScreenTransition::progress`] returns a `[0, 1]` value the renderer can
/// use to alpha-blend a solid fill color over the scene.
#[derive(Clone)]
pub struct ScreenTransition {
    /// Visual style of the transition.
    pub kind: TransitionKind,
    /// Solid fill color used during the transition (`r, g, b, a` in `0..1`).
    pub color: [f32; 4],
    /// Total duration in seconds.
    pub duration: f32,
    /// Elapsed time since the transition started.
    pub elapsed: f32,
    /// `true` while the transition is running.
    pub active: bool,
    /// If `true` the transition is playing in reverse (reveals instead of hides).
    pub reversed: bool,
}

impl ScreenTransition {
    /// Creates a new `ScreenTransition`.
    ///
    /// # Parameters
    /// - `kind`     — visual style (see [`TransitionKind`]).
    /// - `duration` — length of the transition in seconds.
    /// - `color`    — fill color as `[r, g, b, a]` (default black opaque).
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

    /// Starts the transition playing forward (hides the scene).
    pub fn play(&mut self) {
        self.elapsed = 0.0;
        self.reversed = false;
        self.active = true;
    }

    /// Starts the transition playing in reverse (reveals the scene).
    pub fn reverse(&mut self) {
        self.elapsed = 0.0;
        self.reversed = true;
        self.active = true;
    }

    /// Advances the transition by `dt` seconds.  Returns `false` when done.
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

    /// Returns the fractional progress `[0, 1]` of the transition.
    ///
    /// A renderer should use this value to overlay `color` with this alpha
    /// (accounting for `reversed`).
    pub fn progress(&self) -> f32 {
        let t = if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        };
        if self.reversed { 1.0 - t } else { t }
    }

    /// Returns `true` if the transition is currently running.
    pub fn is_active(&self) -> bool {
        self.active
    }

    /// Returns `true` if the transition has completed.
    pub fn is_done(&self) -> bool {
        !self.active && self.elapsed >= self.duration
    }
}
