//! `Script` — an ordered, time-sorted sequence of automation `Step` values.
//! Parses TOML input, expands repeat entries, enforces the step-count cap, and
//! exposes limit controls used by `Simulator`. Does not own event dispatch or playback.

use super::{Action, Step};
pub(crate) const MAX_STEPS: usize = 100_000;
#[derive(Debug, Clone)]
/// A time-sorted sequence of `Step` values that `Simulator` plays back deterministically.
pub struct Script {
    /// Human-readable identifier used as the registry key in `Simulator`.
    pub name: String,
    /// Optional human-readable summary loaded from `[meta] description` in TOML.
    pub description: Option<String>,
    /// Sorted, capped list of steps ready for playback; at most `step_limit` entries.
    pub steps: Vec<Step>,
    /// Maximum number of steps retained; defaults to `MAX_STEPS`, adjustable via `set_step_limit`.
    step_limit: usize,
}
impl Script {
    /// Expand repeat steps: clone each step with `repeat` N times at `repeat_interval` offsets.
    fn expand_repeats(steps: Vec<Step>) -> Vec<Step> {
        let mut out = Vec::new();
        for step in steps {
            let repeat_count = step.repeat.unwrap_or(0);
            let interval = step.repeat_interval.unwrap_or(0.0);
            let mut base = step.clone();
            base.repeat = None;
            base.repeat_interval = None;
            out.push(base);
            for i in 1..=repeat_count {
                let mut clone = step.clone();
                clone.time = step.time + (i as f32 * interval);
                clone.repeat = None;
                clone.repeat_interval = None;
                out.push(clone);
            }
        }
        out
    }
    /// Create a `Script` from a name and raw steps: expands repeats, sorts by time, caps to `MAX_STEPS`.
    pub fn new(name: impl Into<String>, steps: Vec<Step>) -> Self {
        let mut steps = Self::expand_repeats(steps);
        steps.sort_by(|a, b| {
            a.time
                .partial_cmp(&b.time)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        steps.truncate(MAX_STEPS);
        Self {
            name: name.into(),
            description: None,
            steps,
            step_limit: MAX_STEPS,
        }
    }
    /// Create a `Script` identical to `new` but also sets the human-readable `description` field.
    pub fn with_description(
        name: impl Into<String>,
        description: impl Into<String>,
        steps: Vec<Step>,
    ) -> Self {
        let mut script = Self::new(name, steps);
        script.description = Some(description.into());
        script
    }
    /// Return the total number of steps in this script.
    pub fn step_count(&self) -> usize {
        self.steps.len()
    }
    /// Clamp and apply a new step limit, truncating the step list if it exceeds `limit`; range 1..=MAX_STEPS.
    pub fn set_step_limit(&mut self, limit: usize) {
        self.step_limit = limit.clamp(1, MAX_STEPS);
        self.steps.truncate(self.step_limit);
    }
    /// Return the current step limit for this script.
    pub fn get_step_limit(&self) -> usize {
        self.step_limit
    }
    /// Parse a TOML string and construct a `Script`; returns an error string on invalid TOML or unknown action.
    pub fn from_toml(name: impl Into<String>, toml_str: &str) -> Result<Self, String> {
        let doc: toml::Value =
            toml::from_str(toml_str).map_err(|e| format!("invalid TOML: {e}"))?;
        let description = doc
            .get("meta")
            .and_then(|m| m.get("description"))
            .and_then(|d| d.as_str())
            .map(|s| s.to_string());
        let steps_values = doc
            .get("steps")
            .and_then(|s| s.as_array())
            .cloned()
            .unwrap_or_default();
        let mut steps = Vec::with_capacity(steps_values.len());
        for sv in &steps_values {
            let action_str = sv
                .get("action")
                .and_then(|a| a.as_str())
                .ok_or_else(|| "each step needs 'action'".to_string())?;
            let action = Action::parse_action(action_str)
                .ok_or_else(|| format!("unknown action '{action_str}'"))?;
            let time = sv.get("time").and_then(|t| t.as_float()).unwrap_or(0.0) as f32;
            let mut step = Step::new(time, action);
            step.key = sv.get("key").and_then(|v| v.as_str()).map(str::to_string);
            step.scancode = sv
                .get("scancode")
                .and_then(|v| v.as_str())
                .map(str::to_string);
            step.x = sv.get("x").and_then(|v| v.as_float());
            step.y = sv.get("y").and_then(|v| v.as_float());
            step.dx = sv.get("dx").and_then(|v| v.as_float());
            step.dy = sv.get("dy").and_then(|v| v.as_float());
            step.button = sv
                .get("button")
                .and_then(|v| v.as_integer())
                .map(|n| n as u32);
            step.text = sv.get("text").and_then(|v| v.as_str()).map(str::to_string);
            step.is_repeat = sv
                .get("isRepeat")
                .and_then(|v| v.as_bool())
                .unwrap_or(false);
            step.clicks = sv
                .get("clicks")
                .and_then(|v| v.as_integer())
                .map(|n| n as u32);
            step.repeat = sv
                .get("repeat")
                .and_then(|v| v.as_integer())
                .map(|n| n as u32);
            step.repeat_interval = sv
                .get("repeatInterval")
                .and_then(|v| v.as_float())
                .map(|v| v as f32);
            step.macro_name = sv.get("macro").and_then(|v| v.as_str()).map(str::to_string);
            step.when = sv.get("when").and_then(|v| v.as_str()).map(str::to_string);
            step.assert = sv
                .get("assert")
                .and_then(|v| v.as_str())
                .map(str::to_string);
            step.baseline = sv
                .get("baseline")
                .and_then(|v| v.as_str())
                .map(str::to_string);
            step.actual = sv
                .get("actual")
                .and_then(|v| v.as_str())
                .map(str::to_string);
            step.max_diff = sv
                .get("maxDiff")
                .and_then(|v| v.as_integer())
                .map(|n| n as u32);
            steps.push(step);
        }
        Ok(match description {
            Some(desc) => Self::with_description(name, desc, steps),
            None => Self::new(name, steps),
        })
    }
}
