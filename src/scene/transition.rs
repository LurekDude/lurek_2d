//! Scene transition types, easing curves, and active transition state.
//! Owns TransitionType, EasingType, and ActiveTransition; drives progress tracking used by SceneStack.
//! Does not own stack push/pop logic or rendering — callers read progress() to apply visual effects.
//! Key dependencies: easing::bounce_out for the Bounce curve.

use super::easing::bounce_out;
use crate::log_msg;
use crate::runtime::log_messages::{TR01, TR02};
/// Visual effect style applied during a scene switch.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TransitionType {
    /// No transition effect; scene switches instantly.
    None,
    /// Alpha fade between scenes.
    Fade,
    /// Slide incoming scene in from the right, outgoing scene exits left.
    SlideLeft,
    /// Slide incoming scene in from the left, outgoing scene exits right.
    SlideRight,
    /// Slide incoming scene in from the bottom, outgoing scene exits up.
    SlideUp,
    /// Slide incoming scene in from the top, outgoing scene exits down.
    SlideDown,
    /// Horizontal wipe from left to right revealing the incoming scene.
    Wipe,
    /// Circular iris-wipe centred on screen.
    Iris,
    /// Scale-zoom transition expanding the incoming scene from the centre.
    Zoom,
    /// Cross-dissolve alpha blend between outgoing and incoming scene.
    CrossFade,
}
/// Parse methods for TransitionType used by Lua API bindings.
impl TransitionType {
    /// Parse a Lua string to TransitionType; unrecognised values return None.
    pub fn from_lua_str(s: &str) -> Self {
        match s {
            "fade" => Self::Fade,
            "slideleft" => Self::SlideLeft,
            "slideright" => Self::SlideRight,
            "slideup" => Self::SlideUp,
            "slidedown" => Self::SlideDown,
            "wipe" => Self::Wipe,
            "iris" => Self::Iris,
            "zoom" => Self::Zoom,
            "crossfade" => Self::CrossFade,
            _ => Self::None,
        }
    }
}
/// Easing curve applied to the transition progress value.
#[derive(Debug, Clone, Copy, PartialEq, Default)]
pub enum EasingType {
    /// Linear interpolation — default.
    #[default]
    Linear,
    /// Quadratic acceleration from zero.
    EaseIn,
    /// Quadratic deceleration to zero.
    EaseOut,
    /// Smooth cubic S-curve.
    EaseInOut,
    /// Overshoot-bounce finishing at 1.0.
    Bounce,
    /// Cubic back-overshoot that briefly exceeds 1.0 before settling.
    Back,
}
/// Parse and evaluation methods for EasingType.
impl EasingType {
    /// Parse a Lua string to EasingType; unrecognised values return Linear.
    pub fn from_lua_str(s: &str) -> Self {
        match s {
            "linear" => Self::Linear,
            "ease_in" => Self::EaseIn,
            "ease_out" => Self::EaseOut,
            "ease_in_out" => Self::EaseInOut,
            "bounce" => Self::Bounce,
            "back" => Self::Back,
            _ => Self::Linear,
        }
    }
    /// Evaluate this easing curve for t in [0, 1]; clamps input and returns value in approximately [0, 1].
    pub fn apply(self, t: f32) -> f32 {
        let t = t.clamp(0.0, 1.0);
        match self {
            Self::Linear => t,
            Self::EaseIn => t * t,
            Self::EaseOut => 1.0 - (1.0 - t) * (1.0 - t),
            Self::EaseInOut => t * t * (3.0 - 2.0 * t),
            Self::Bounce => {
                let t2 = 1.0 - t;
                1.0 - bounce_out(t2)
            }
            Self::Back => {
                const C1: f32 = 1.701_58;
                const C3: f32 = C1 + 1.0;
                C3 * t * t * t - C1 * t * t
            }
        }
    }
}
/// Running transition with elapsed time tracking, used by SceneStack to drive transition progress.
pub struct ActiveTransition {
    /// Visual effect type for this transition.
    pub transition_type: TransitionType,
    /// Total transition duration in seconds.
    pub duration: f32,
    /// Accumulated elapsed time in seconds since transition started.
    pub elapsed: f32,
    /// Easing curve applied when computing progress_eased.
    pub easing: EasingType,
}
/// Constructor and progress tracking methods for ActiveTransition.
impl ActiveTransition {
    /// Create an ActiveTransition with Linear easing and elapsed=0.
    pub fn new(transition_type: TransitionType, duration: f32) -> Self {
        log_msg!(debug, TR01);
        Self {
            transition_type,
            duration,
            elapsed: 0.0,
            easing: EasingType::Linear,
        }
    }
    /// Create an ActiveTransition with explicit easing and elapsed=0.
    pub fn new_with_easing(
        transition_type: TransitionType,
        duration: f32,
        easing: EasingType,
    ) -> Self {
        log_msg!(debug, TR01);
        Self {
            transition_type,
            duration,
            elapsed: 0.0,
            easing,
        }
    }
    /// Replace the easing curve without resetting elapsed.
    pub fn set_easing(&mut self, easing: EasingType) {
        self.easing = easing;
    }
    /// Return the current easing curve.
    pub fn get_easing(&self) -> EasingType {
        self.easing
    }
    /// Return linear progress in [0, 1]; returns 1.0 when duration <= 0.
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).min(1.0)
        }
    }
    /// Return eased progress by applying self.easing to linear progress.
    pub fn progress_eased(&self) -> f32 {
        self.easing.apply(self.progress())
    }
    /// Return true when elapsed >= duration; logs TR02 on first completion check.
    pub fn is_complete(&self) -> bool {
        let done = self.elapsed >= self.duration;
        if done {
            log_msg!(debug, TR02);
        }
        done
    }
    /// Advance elapsed by dt seconds; ignores non-positive dt.
    pub fn update(&mut self, dt: f32) {
        if dt <= 0.0 {
            return;
        }
        self.elapsed += dt;
    }
}
