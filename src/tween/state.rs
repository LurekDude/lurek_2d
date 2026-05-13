use crate::math::easing;
pub struct TweenState {
    pub duration: f64,
    pub elapsed: f64,
    easing_fn: fn(f32) -> f32,
    pub paused: bool,
}
impl TweenState {
    pub fn new(duration: f64, easing_name: &str) -> Self {
        Self {
            duration: duration.max(0.0001),
            elapsed: 0.0,
            easing_fn: resolve_easing(easing_name).unwrap_or(easing::linear),
            paused: false,
        }
    }
    pub fn tick(&mut self, dt: f64) -> bool {
        if self.paused {
            return false;
        }
        self.elapsed += dt;
        self.elapsed >= self.duration
    }
    pub fn reset(&mut self) {
        self.elapsed = 0.0;
    }
    pub fn t_raw(&self) -> f32 {
        if self.duration <= 0.0 {
            return 1.0;
        }
        (self.elapsed / self.duration).clamp(0.0, 1.0) as f32
    }
    pub fn t_eased(&self) -> f64 {
        (self.easing_fn)(self.t_raw()) as f64
    }
    pub fn lerp(&self, start: f64, end: f64) -> f64 {
        start + (end - start) * self.t_eased()
    }
    pub fn is_complete(&self) -> bool {
        self.elapsed >= self.duration
    }
}
pub fn resolve_easing(name: &str) -> Option<fn(f32) -> f32> {
    easing::resolve_easing_fn(name).or_else(|| match name.to_lowercase().as_str() {
        "quadin" | "easeinquad" => Some(easing::ease_in_quad),
        "quadout" | "easeoutquad" => Some(easing::ease_out_quad),
        "quadinout" | "easeinoutquad" => Some(easing::ease_in_out_quad),
        "cubicin" | "easeincubic" => Some(easing::ease_in_cubic),
        "cubicout" | "easeoutcubic" => Some(easing::ease_out_cubic),
        "cubicinout" | "easeinoutcubic" => Some(easing::ease_in_out_cubic),
        "quartin" | "easeinquart" => Some(easing::ease_in_quart),
        "quartout" | "easeoutquart" => Some(easing::ease_out_quart),
        "quartinout" | "easeinoutquart" => Some(easing::ease_in_out_quart),
        "sinein" | "easeinsine" => Some(easing::ease_in_sine),
        "sineout" | "easeoutsine" => Some(easing::ease_out_sine),
        "sineinout" | "easeinoutsine" => Some(easing::ease_in_out_sine),
        "expoin" | "easeinexpo" => Some(easing::ease_in_expo),
        "expoout" | "easeoutexpo" => Some(easing::ease_out_expo),
        "expoinout" | "easeinoutexpo" => Some(easing::ease_in_out_expo),
        "elasticin" | "easeinelastic" => Some(easing::ease_in_elastic),
        "elasticout" | "easeoutelastic" => Some(easing::ease_out_elastic),
        "bouncein" | "easeinbounce" => Some(easing::ease_in_bounce),
        "bounceout" | "easeoutbounce" => Some(easing::ease_out_bounce),
        "backin" | "easeinback" => Some(easing::ease_in_back),
        "backout" | "easeoutback" => Some(easing::ease_out_back),
        _ => None,
    })
}
pub fn builtin_easing_names() -> &'static [&'static str] {
    &[
        "linear",
        "quadIn",
        "quadOut",
        "quadInOut",
        "cubicIn",
        "cubicOut",
        "cubicInOut",
        "quartIn",
        "quartOut",
        "quartInOut",
        "sineIn",
        "sineOut",
        "sineInOut",
        "expoIn",
        "expoOut",
        "expoInOut",
        "elasticIn",
        "elasticOut",
        "bounceIn",
        "bounceOut",
        "backIn",
        "backOut",
    ]
}
