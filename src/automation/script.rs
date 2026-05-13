//! Scope: Script storage and parsing for automation playback.
//! This file defines Script and constants used to cap, sort, and parse timed steps.
//! It owns repeat expansion, step-limit enforcement, and TOML-to-script conversion.

use super::{Action, Step};

/// Hard upper bound on [`Script`] steps. See also [`Script::step_limit`].
///
/// Steps beyond this limit are silently truncated during [`Script::new`].
/// The cap prevents unbounded memory allocation from oversized or adversarial
/// script files (CSF-010 allocation guard). 100 000 steps at ~120 bytes each
/// is roughly 12 MB per script - a deliberate upper bound.
pub(crate) const MAX_STEPS: usize = 100_000;

// ---- Type: Script ----

/// A named simulation script containing an ordered sequence of timed steps.
///
/// On construction, steps are sorted by their `time` field in ascending order
/// and then truncated to [`MAX_STEPS`]. The original insertion order is
/// discarded - only the time ordering is preserved.
///
/// Scripts are stored in the [`Simulator`](super::Simulator) indexed by their
/// `name`. Loading a new script with an existing name replaces the previous
/// one. A script can be played back multiple times by calling
/// [`Simulator::start`](super::Simulator::start) repeatedly.
///
/// # Fields
/// - `name` - `String`.
/// - `description` - `Option<String>`.
/// - `steps` - `Vec<Step>`.
/// - `step_limit` - `usize`. Per-instance step cap (default [`MAX_STEPS`]).
#[derive(Debug, Clone)]
/// A named simulation script containing an ordered sequence of timed steps.
pub struct Script {
    /// Script name used for lookup in the [`Simulator`](super::Simulator).
    ///
    /// Names must be unique within a simulator instance; loading a script
    /// with an already-registered name overwrites the previous one. The name
    /// is also used as the fallback when `meta.name` is absent in a TOML file.
    pub name: String,
    /// Optional human-readable description of what the script does.
    ///
    /// Populated from the `meta.description` field when loading from a Lua
    /// table or TOML file. Not used during playback - purely informational.
    pub description: Option<String>,
    /// Time-sorted sequence of steps (ascending by `time`).
    ///
    /// Sorted during construction; never reordered afterwards. The
    /// [`Simulator`](super::Simulator) scans left-to-right, dispatching each
    /// step when `elapsed >= step.time`.
    pub steps: Vec<Step>,
    /// Maximum number of steps this script accepts (default [`MAX_STEPS`], max [`MAX_STEPS`]).
    ///
    /// Set via [`Script::set_step_limit`]. Clamped to `1..=MAX_STEPS`.
    step_limit: usize,
}

// ---- Implementation: Script ----

impl Script {
    // ---- Helper Functions: Repeat Expansion ----

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

    /// Create a new script with the given name and steps.
    ///
    /// Steps are sorted by `time` in ascending order and then truncated to
    /// [`MAX_STEPS`]. When two steps share the same `time` value their
    /// relative order is preserved (stable sort with `Equal` fallback).
    ///
    /// # Parameters
    /// - `name` - `impl Into<String>`.
    /// - `steps` - `Vec<Step>`.
    ///
    /// # Returns
    /// `Script`.
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

    /// Create a script with an explicit description string.
    ///
    /// Behaves identically to [`Script::new`] but additionally sets the
    /// `description` field. Useful when constructing scripts in Rust code
    /// that should carry human-readable metadata.
    ///
    /// # Parameters
    /// - `name` - `impl Into<String>`.
    /// - `description` - `impl Into<String>`.
    /// - `steps` - `Vec<Step>`.
    ///
    /// # Returns
    /// `Script`.
    pub fn with_description(
        name: impl Into<String>,
        description: impl Into<String>,
        steps: Vec<Step>,
    ) -> Self {
        let mut script = Self::new(name, steps);
        script.description = Some(description.into());
        script
    }

    /// Return the number of steps in this script.
    ///
    /// Always `<= MAX_STEPS` because construction truncates longer inputs.
    /// Returns `0` for an empty script.
    ///
    /// # Returns
    /// `usize`.
    pub fn step_count(&self) -> usize {
        self.steps.len()
    }

    /// Sets the maximum step count for this script (clamped to `1..=MAX_STEPS`).
    ///
    /// Immediately truncates `steps` if the new limit is lower than the
    /// current step count.
    ///
    /// # Parameters
    /// - `limit` - New maximum step count (1 to MAX_STEPS inclusive).
    pub fn set_step_limit(&mut self, limit: usize) {
        self.step_limit = limit.clamp(1, MAX_STEPS);
        self.steps.truncate(self.step_limit);
    }

    /// Returns the active step limit for this script.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_step_limit(&self) -> usize {
        self.step_limit
    }

    /// Parse a Script from a TOML string.
    ///
    /// Expects a top-level `[meta]` table with an optional `description` key,
    /// and a `[[steps]]` array where each step has at minimum an `action`
    /// string field. Recognised step fields: `action`, `time`, `key`,
    /// `scancode`, `x`, `y`, `dx`, `dy`, `button`, `text`, `isRepeat`,
    /// `clicks`, `repeat`, `repeatInterval`, `macro`, `when`, `assert`,
    /// `baseline`, `actual`, and `maxDiff`.
    ///
    /// `when` and `assert` accept boolean expressions using condition names,
    /// `true`/`false`, `!`, `&&`, `||`, and parentheses.
    ///
    /// Returns `Err(String)` if the TOML is malformed, if any `action` value
    /// is unrecognised, or if a step is missing the required `action` field.
    ///
    /// # Parameters
    /// - `name` - `impl Into<String>`.
    /// - `toml_str` - `&str`.
    ///
    /// # Returns
    /// `Result<Script, String>`.
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

// Tests migrated to tests/rust/unit/automation_tests.rs
