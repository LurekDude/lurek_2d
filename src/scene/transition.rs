//! Visual transition types and active transition state for scene changes.
//!
//! This module is part of Luna2D's `scene` subsystem and provides the implementation
//! details for transition-related operations and data management.
//! Key types exported from this module: `TransitionType`, `ActiveTransition`.
//! Primary functions: `from_lua_str()`, `new()`, `progress()`, `is_complete()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Visual transition types between scenes. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `None` — None variant.
/// - `Fade` — Fade variant.
/// - `SlideLeft` — SlideLeft variant.
/// - `SlideRight` — SlideRight variant.
/// - `SlideUp` — SlideUp variant.
/// - `SlideDown` — SlideDown variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TransitionType {
    /// Instant switch, no animation.
    None,
    /// Crossfade between outgoing and incoming scenes.
    Fade,
    /// New scene slides in from the right.
    SlideLeft,
    /// New scene slides in from the left.
    SlideRight,
    /// New scene slides in from the bottom.
    SlideUp,
    /// New scene slides in from the top.
    SlideDown,
}

impl TransitionType {
    /// Parse a transition type from a Lua string.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_lua_str(s: &str) -> Self {
        match s {
            "fade" => Self::Fade,
            "slideleft" => Self::SlideLeft,
            "slideright" => Self::SlideRight,
            "slideup" => Self::SlideUp,
            "slidedown" => Self::SlideDown,
            _ => Self::None,
        }
    }
}

/// Active transition state tracking progress between two scenes.
///
/// # Fields
/// - `transition_type` — `TransitionType`.
/// - `duration` — `f32`.
/// - `elapsed` — `f32`.
pub struct ActiveTransition {
    /// The type of visual transition.
    pub transition_type: TransitionType,
    /// Total duration of the transition in seconds.
    pub duration: f32,
    /// Elapsed time since the transition started.
    pub elapsed: f32,
}

impl ActiveTransition {
    /// Create a new active transition. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `transition_type` — `TransitionType`.
    /// - `duration` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(transition_type: TransitionType, duration: f32) -> Self {
        Self {
            transition_type,
            duration,
            elapsed: 0.0,
        }
    }

    /// Normalized progress of the transition, clamped to [0, 1].
    ///
    /// # Returns
    /// `f32`.
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).min(1.0)
        }
    }

    /// Whether the transition has completed. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_complete(&self) -> bool {
        self.elapsed >= self.duration
    }

    /// Advance the transition timer by `dt` seconds.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    pub fn update(&mut self, dt: f32) {
        self.elapsed += dt;
    }
}
