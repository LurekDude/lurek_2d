use super::easing::bounce_out;
use crate::log_msg;
use crate::runtime::log_messages::{TR01, TR02};
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TransitionType {
    None,
    Fade,
    SlideLeft,
    SlideRight,
    SlideUp,
    SlideDown,
    Wipe,
    Iris,
    Zoom,
    CrossFade,
}
impl TransitionType {
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
#[derive(Debug, Clone, Copy, PartialEq, Default)]
pub enum EasingType {
    #[default]
    Linear,
    EaseIn,
    EaseOut,
    EaseInOut,
    Bounce,
    Back,
}
impl EasingType {
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
pub struct ActiveTransition {
    pub transition_type: TransitionType,
    pub duration: f32,
    pub elapsed: f32,
    pub easing: EasingType,
}
impl ActiveTransition {
    pub fn new(transition_type: TransitionType, duration: f32) -> Self {
        log_msg!(debug, TR01);
        Self {
            transition_type,
            duration,
            elapsed: 0.0,
            easing: EasingType::Linear,
        }
    }
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
    pub fn set_easing(&mut self, easing: EasingType) {
        self.easing = easing;
    }
    pub fn get_easing(&self) -> EasingType {
        self.easing
    }
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).min(1.0)
        }
    }
    pub fn progress_eased(&self) -> f32 {
        self.easing.apply(self.progress())
    }
    pub fn is_complete(&self) -> bool {
        let done = self.elapsed >= self.duration;
        if done {
            log_msg!(debug, TR02);
        }
        done
    }
    pub fn update(&mut self, dt: f32) {
        if dt <= 0.0 {
            return;
        }
        self.elapsed += dt;
    }
}
