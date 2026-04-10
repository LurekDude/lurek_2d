//! Visual transition types and active transition state for scene changes.
//!
//! This module is part of Lurek2D's `scene` subsystem and provides the implementation
//! details for transition-related operations and data management.
//! Key types exported from this module: `TransitionType`, `ActiveTransition`.
//! Primary functions: `from_lua_str()`, `new()`, `progress()`, `is_complete()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.
use crate::runtime::log_messages::{TR01, TR02};
use crate::log_msg;

/// Visual transition types between scenes.
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
        log_msg!(debug, TR01);
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
        let done = self.elapsed >= self.duration;
        if done {
            log_msg!(debug, TR02);
        }
        done
    }

    /// Advance the transition timer by `dt` seconds.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    pub fn update(&mut self, dt: f32) {
        self.elapsed += dt;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn new_starts_at_zero_elapsed() {
        let t = ActiveTransition::new(TransitionType::Fade, 1.0);
        assert!((t.elapsed).abs() < 1e-5);
    }

    #[test]
    fn progress_at_start_is_zero() {
        let t = ActiveTransition::new(TransitionType::Fade, 1.0);
        assert!((t.progress()).abs() < 1e-5);
    }

    // ── Progress ─────────────────────────────────────────────────────────────

    #[test]
    fn progress_after_half_duration_is_half() {
        let mut t = ActiveTransition::new(TransitionType::Fade, 2.0);
        t.update(1.0);
        assert!((t.progress() - 0.5).abs() < 1e-5);
    }

    #[test]
    fn progress_clamped_at_one() {
        let mut t = ActiveTransition::new(TransitionType::Fade, 1.0);
        t.update(10.0);
        assert!((t.progress() - 1.0).abs() < 1e-5);
    }

    #[test]
    fn zero_duration_progress_is_one() {
        let t = ActiveTransition::new(TransitionType::None, 0.0);
        assert!((t.progress() - 1.0).abs() < 1e-5);
    }

    // ── Is complete ──────────────────────────────────────────────────────────

    #[test]
    fn is_complete_before_duration_false() {
        let t = ActiveTransition::new(TransitionType::Fade, 1.0);
        assert!(!t.is_complete());
    }

    #[test]
    fn is_complete_after_full_update_true() {
        let mut t = ActiveTransition::new(TransitionType::Fade, 0.5);
        t.update(0.5);
        assert!(t.is_complete());
    }

    // ── Type parsing ──────────────────────────────────────────────────────────

    #[test]
    fn from_lua_str_fade_correct() {
        assert_eq!(TransitionType::from_lua_str("fade"), TransitionType::Fade);
    }

    #[test]
    fn from_lua_str_unknown_returns_none_variant() {
        assert_eq!(TransitionType::from_lua_str("xyz"), TransitionType::None);
    }

    #[test]
    fn from_lua_str_slideleft() {
        assert_eq!(
            TransitionType::from_lua_str("slideleft"),
            TransitionType::SlideLeft
        );
    }
}
