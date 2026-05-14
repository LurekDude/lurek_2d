use crate::math::easing;
use std::collections::HashMap;
/// Easing function used when interpolating between keyframes.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum EasingKind {
    /// No interpolation until the next keyframe.
    Step,
    /// Linear interpolation.
    Linear,
    /// Quadratic ease-in.
    EaseIn,
    /// Quadratic ease-out.
    EaseOut,
    /// Quadratic ease-in-out.
    EaseInOut,
    /// Custom easing callback id.
    Custom { callback_id: u32 },
}
/// Single numeric curve with sorted keyframes.
#[derive(Debug, Clone)]
pub struct AnimCurve {
    /// Sorted keyframes as `(time, value)`.
    pub keyframes: Vec<(f32, f32)>,
    /// Interpolation mode.
    pub easing: EasingKind,
}
impl AnimCurve {
    /// Create an empty curve with linear easing.
    pub fn new() -> Self {
        Self {
            keyframes: Vec::new(),
            easing: EasingKind::Linear,
        }
    }
    /// Create an empty curve with the given easing.
    pub fn with_easing(easing: EasingKind) -> Self {
        Self {
            keyframes: Vec::new(),
            easing,
        }
    }
    /// Insert or replace a keyframe while keeping the list sorted.
    pub fn add_keyframe(&mut self, time: f32, value: f32) {
        match self
            .keyframes
            .binary_search_by(|(t, _)| t.partial_cmp(&time).unwrap_or(std::cmp::Ordering::Equal))
        {
            Ok(pos) => self.keyframes[pos] = (time, value),
            Err(pos) => self.keyframes.insert(pos, (time, value)),
        }
    }
    /// Return the number of keyframes.
    pub fn keyframe_count(&self) -> usize {
        self.keyframes.len()
    }
    /// Remove all keyframes.
    pub fn clear(&mut self) {
        self.keyframes.clear();
    }
    /// Evaluate the curve at time `t`.
    pub fn eval(&self, t: f32) -> f32 {
        match self.keyframes.len() {
            0 => 0.0,
            1 => self.keyframes[0].1,
            _ => {
                let last = self.keyframes.last().unwrap();
                if t <= self.keyframes[0].0 {
                    return self.keyframes[0].1;
                }
                if t >= last.0 {
                    return last.1;
                }
                let pos = self
                    .keyframes
                    .partition_point(|(kf_t, _)| *kf_t <= t)
                    .saturating_sub(1);
                let (t0, v0) = self.keyframes[pos];
                let (t1, v1) = self.keyframes[pos + 1];
                let span = t1 - t0;
                if span <= f32::EPSILON {
                    return v1;
                }
                let alpha = (t - t0) / span;
                let alpha_eased = match self.easing {
                    EasingKind::Step => 0.0,
                    EasingKind::Linear => easing::linear(alpha),
                    EasingKind::EaseIn => easing::ease_in_quad(alpha),
                    EasingKind::EaseOut => easing::ease_out_quad(alpha),
                    EasingKind::EaseInOut => easing::ease_in_out_quad(alpha),
                    EasingKind::Custom { .. } => alpha,
                };
                v0 + (v1 - v0) * alpha_eased
            }
        }
    }
}
/// Sparse multi-property timeline keyed by property name.
#[derive(Debug, Clone)]
pub struct AnimPropertyTimeline {
    /// Sorted keyframe times.
    times: Vec<f32>,
    /// Per-property values aligned with `times`.
    values: HashMap<String, Vec<f32>>,
    /// Interpolation mode.
    pub easing: EasingKind,
}
impl AnimPropertyTimeline {
    /// Create an empty timeline with linear easing.
    pub fn new() -> Self {
        Self {
            times: Vec::new(),
            values: HashMap::new(),
            easing: EasingKind::Linear,
        }
    }
    /// Insert a keyframe with one or more property values.
    pub fn add_keyframe<I, S>(&mut self, time: f32, props: I)
    where
        I: IntoIterator<Item = (S, f32)>,
        S: Into<String>,
    {
        let mut props_vec: Vec<(String, f32)> =
            props.into_iter().map(|(k, v)| (k.into(), v)).collect();
        if props_vec.is_empty() {
            return;
        }
        let insert_pos = match self
            .times
            .binary_search_by(|t| t.partial_cmp(&time).unwrap_or(std::cmp::Ordering::Equal))
        {
            Ok(pos) => pos,
            Err(pos) => {
                self.times.insert(pos, time);
                for values in self.values.values_mut() {
                    let fallback = if pos > 0 { values[pos - 1] } else { 0.0 };
                    values.insert(pos, fallback);
                }
                pos
            }
        };
        for (name, value) in props_vec.drain(..) {
            let values = self
                .values
                .entry(name)
                .or_insert_with(|| vec![0.0; self.times.len()]);
            if values.len() < self.times.len() {
                let fill = *values.last().unwrap_or(&0.0);
                values.resize(self.times.len(), fill);
            }
            values[insert_pos] = value;
        }
    }
    /// Return the list of property names.
    pub fn property_names(&self) -> Vec<String> {
        self.values.keys().cloned().collect()
    }
    /// Return the number of timeline keyframes.
    pub fn keyframe_count(&self) -> usize {
        self.times.len()
    }
    /// Evaluate one property at time `t`.
    pub fn eval_property(&self, name: &str, t: f32) -> Option<f32> {
        let values = self.values.get(name)?;
        if self.times.is_empty() || values.is_empty() {
            return Some(0.0);
        }
        if self.times.len() == 1 {
            return Some(values[0]);
        }
        if t <= self.times[0] {
            return Some(values[0]);
        }
        let last_idx = self.times.len() - 1;
        if t >= self.times[last_idx] {
            return Some(values[last_idx]);
        }
        let pos = self
            .times
            .partition_point(|kf_t| *kf_t <= t)
            .saturating_sub(1);
        let t0 = self.times[pos];
        let t1 = self.times[pos + 1];
        let v0 = values[pos];
        let v1 = values[pos + 1];
        let span = t1 - t0;
        if span <= f32::EPSILON {
            return Some(v1);
        }
        let alpha = (t - t0) / span;
        let alpha_eased = match self.easing {
            EasingKind::Step => 0.0,
            EasingKind::Linear => easing::linear(alpha),
            EasingKind::EaseIn => easing::ease_in_quad(alpha),
            EasingKind::EaseOut => easing::ease_out_quad(alpha),
            EasingKind::EaseInOut => easing::ease_in_out_quad(alpha),
            EasingKind::Custom { .. } => alpha,
        };
        Some(v0 + (v1 - v0) * alpha_eased)
    }
    /// Evaluate all properties at time `t`.
    pub fn eval_all(&self, t: f32) -> HashMap<String, f32> {
        let mut out = HashMap::new();
        for name in self.values.keys() {
            if let Some(v) = self.eval_property(name, t) {
                out.insert(name.clone(), v);
            }
        }
        out
    }
}
/// `Default` delegates to `AnimCurve::new`.
/// `Default` delegates to `AnimCurve::new`.
impl Default for AnimCurve {
    fn default() -> Self {
        Self::new()
    }
}
/// `Default` delegates to `AnimPropertyTimeline::new`.
/// `Default` delegates to `AnimPropertyTimeline::new`.
impl Default for AnimPropertyTimeline {
    fn default() -> Self {
        Self::new()
    }
}
