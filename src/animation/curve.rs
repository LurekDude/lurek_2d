//! Keyframe-based animation curves with per-segment easing.
//!
//! An [`AnimCurve`] holds a list of `(time, value)` keyframes in ascending time
//! order and evaluates the interpolated value at any time `t` using the selected
//! [`EasingKind`].
//!
//! # Design boundary vs `tween`
//!
//! | Concept | Module | Scope | Lifecycle |
//! |---|---|---|---|
//! | [`AnimCurve`] | `animation::curve` | One named property driven by keyframes within an animation context | Driven by the animation controller — resets or loops with the clip |
//! | [`AnimPropertyTimeline`] | `animation::curve` | Multiple named properties on one shared time axis | Same as `AnimCurve` — animation-scoped |
//! | `TweenState` | `tween::state` | One numeric property interpolated from A to B over a fixed duration | Driven independently of any animation; managed by the tween engine |
//!
//! Use `AnimCurve` / `AnimPropertyTimeline` when the curve is permanently attached
//! to an animation clip (e.g. scaling a sprite's alpha over its play duration).
//! Use `TweenState` for one-shot or explicitly triggered interpolations that are
//! independent of the animation state (e.g. a UI fade, a camera zoom).
//!
//! Both live in Tier 1 and depend only on `crate::math::easing`.  They intentionally
//! share no Rust types so that either subsystem can change its easing or keyframe
//! representation without coupling to the other.

use std::collections::HashMap;

use crate::math::easing;

// â”€â”€ EasingKind â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Interpolation mode applied between each pair of consecutive keyframes.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum EasingKind {
    /// Constant hold â€” output equals the value of the preceding keyframe.
    Step,
    /// Linear interpolation.
    Linear,
    /// Smooth ease-in.
    EaseIn,
    /// Smooth ease-out.
    EaseOut,
    /// Smooth ease-in-out.
    EaseInOut,
    /// A Lua callback computes the interpolation factor.
    /// `callback_id` is an opaque key resolved by the Lua API layer.
    Custom { callback_id: u32 },
}

// â”€â”€ AnimCurve â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// A keyframe-based animation curve.
///
/// Each `keyframe` entry is a `(time: f32, value: f32)` pair.  Keyframes must
/// be kept in ascending time order â€” [`AnimCurve::add_keyframe`] inserts them
/// in sorted position automatically.  [`AnimCurve::eval`] evaluates the curve
/// at any time by locating the surrounding pair and applying the chosen
/// [`EasingKind`].
#[derive(Debug, Clone)]
pub struct AnimCurve {
    /// Sorted (time, value) keyframe pairs.
    pub keyframes: Vec<(f32, f32)>,
    /// Default easing applied between keyframes when not otherwise overridden.
    pub easing: EasingKind,
}

impl AnimCurve {
    /// Creates an empty `AnimCurve` with [`EasingKind::Linear`] interpolation.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            keyframes: Vec::new(),
            easing: EasingKind::Linear,
        }
    }

    /// Creates an empty `AnimCurve` with the given easing kind.
    ///
    /// # Parameters
    /// - `easing` â€” [`EasingKind`].
    ///
    /// # Returns
    /// `Self`.
    pub fn with_easing(easing: EasingKind) -> Self {
        Self {
            keyframes: Vec::new(),
            easing,
        }
    }

    /// Adds a keyframe, keeping the internal list sorted by time.
    ///
    /// If a keyframe at the exact same time already exists it is replaced.
    ///
    /// # Parameters
    /// - `time` â€” `f32`.
    /// - `value` â€” `f32`.
    pub fn add_keyframe(&mut self, time: f32, value: f32) {
        match self
            .keyframes
            .binary_search_by(|(t, _)| t.partial_cmp(&time).unwrap_or(std::cmp::Ordering::Equal))
        {
            Ok(pos) => self.keyframes[pos] = (time, value),
            Err(pos) => self.keyframes.insert(pos, (time, value)),
        }
    }

    /// Returns the number of keyframes.
    pub fn keyframe_count(&self) -> usize {
        self.keyframes.len()
    }

    /// Removes all keyframes.
    pub fn clear(&mut self) {
        self.keyframes.clear();
    }

    /// Evaluates the curve at the given time.
    ///
    /// - Returns `0.0` if there are no keyframes.
    /// - Returns the first keyframe value if `t` precedes all keyframes.
    /// - Returns the last keyframe value if `t` follows all keyframes.
    /// - Interpolates between the surrounding pair otherwise.
    ///
    /// # Parameters
    /// - `t` â€” evaluation time in the same units as the keyframes.
    ///
    /// # Returns
    /// `f32` â€” interpolated value.
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
                // Find the segment: keyframes[i].0 <= t < keyframes[i+1].0
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
                    // Domain code cannot call Lua; return linear interpolation as fallback.
                    // The Lua API layer overrides this by calling the callback directly.
                    EasingKind::Custom { .. } => alpha,
                };
                v0 + (v1 - v0) * alpha_eased
            }
        }
    }
}

/// One shared timeline that can drive multiple named properties in parallel.
#[derive(Debug, Clone)]
pub struct AnimPropertyTimeline {
    /// Shared timeline keyframes (time only).
    times: Vec<f32>,
    /// Per-property values aligned with `times`.
    values: HashMap<String, Vec<f32>>,
    /// Interpolation mode shared by all properties.
    pub easing: EasingKind,
}

impl AnimPropertyTimeline {
    /// Creates an empty property timeline with linear easing.
    pub fn new() -> Self {
        Self {
            times: Vec::new(),
            values: HashMap::new(),
            easing: EasingKind::Linear,
        }
    }

    /// Adds a keyframe for one or more named properties at the same time.
    ///
    /// Properties not provided in this keyframe keep their previous value.
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

    /// Returns all property names tracked by this timeline.
    pub fn property_names(&self) -> Vec<String> {
        self.values.keys().cloned().collect()
    }

    /// Number of timeline keyframes.
    pub fn keyframe_count(&self) -> usize {
        self.times.len()
    }

    /// Evaluates one property at time `t`.
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

    /// Evaluates all properties at time `t`.
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

impl Default for AnimCurve {
    fn default() -> Self {
        Self::new()
    }
}

impl Default for AnimPropertyTimeline {
    fn default() -> Self {
        Self::new()
    }
}
