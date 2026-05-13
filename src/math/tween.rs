use crate::math::easing;
#[derive(Debug, Clone)]
pub struct TweenValue {
    pub start: f64,
    pub target: f64,
}
pub struct Tween {
    duration: f64,
    easing_fn: fn(f32) -> f32,
    easing_name: String,
    clock: f64,
    values: Vec<TweenValue>,
}
fn resolve_easing(name: &str) -> Option<fn(f32) -> f32> {
    easing::resolve_easing_fn(name).or_else(|| match name.to_lowercase().as_str() {
        "easeinquad" => Some(easing::ease_in_quad),
        "easeoutquad" => Some(easing::ease_out_quad),
        "easeinoutquad" => Some(easing::ease_in_out_quad),
        "easeincubic" => Some(easing::ease_in_cubic),
        "easeoutcubic" => Some(easing::ease_out_cubic),
        "easeinoutcubic" => Some(easing::ease_in_out_cubic),
        "easeinquart" => Some(easing::ease_in_quart),
        "easeoutquart" => Some(easing::ease_out_quart),
        "easeinoutquart" => Some(easing::ease_in_out_quart),
        "easeinsine" => Some(easing::ease_in_sine),
        "easeoutsine" => Some(easing::ease_out_sine),
        "easeinoutsine" => Some(easing::ease_in_out_sine),
        "easeinexpo" => Some(easing::ease_in_expo),
        "easeoutexpo" => Some(easing::ease_out_expo),
        "easeinoutexpo" => Some(easing::ease_in_out_expo),
        "easeinelastic" => Some(easing::ease_in_elastic),
        "easeoutelastic" => Some(easing::ease_out_elastic),
        "easeoutbounce" => Some(easing::ease_out_bounce),
        "easeinbounce" => Some(easing::ease_in_bounce),
        "easeinback" => Some(easing::ease_in_back),
        "easeoutback" => Some(easing::ease_out_back),
        _ => None,
    })
}
impl Tween {
    pub fn new(duration: f64, easing_name: &str) -> Self {
        let easing_fn = resolve_easing(easing_name).unwrap_or(easing::linear);
        Self {
            duration: duration.max(0.0),
            easing_fn,
            easing_name: easing_name.to_string(),
            clock: 0.0,
            values: Vec::new(),
        }
    }
    pub fn add_value(&mut self, start: f64, target: f64) -> usize {
        let idx = self.values.len();
        self.values.push(TweenValue { start, target });
        idx
    }
    pub fn update(&mut self, dt: f64) -> bool {
        self.clock += dt;
        self.clock >= self.duration
    }
    pub fn get_value(&self, index: usize) -> f64 {
        if index >= self.values.len() {
            return 0.0;
        }
        let t = if self.duration <= 0.0 {
            1.0
        } else {
            (self.clock / self.duration).clamp(0.0, 1.0) as f32
        };
        let eased = (self.easing_fn)(t) as f64;
        let v = &self.values[index];
        v.start + (v.target - v.start) * eased
    }
    pub fn get_all_values(&self) -> Vec<f64> {
        (0..self.values.len()).map(|i| self.get_value(i)).collect()
    }
    pub fn reset(&mut self) {
        self.clock = 0.0;
    }
    pub fn set_time(&mut self, t: f64) {
        self.clock = t.clamp(0.0, self.duration);
    }
    pub fn is_complete(&self) -> bool {
        self.clock >= self.duration
    }
    pub fn value_count(&self) -> usize {
        self.values.len()
    }
    pub fn easing_name(&self) -> &str {
        &self.easing_name
    }
    pub fn duration(&self) -> f64 {
        self.duration
    }
    pub fn clock(&self) -> f64 {
        self.clock
    }
}
