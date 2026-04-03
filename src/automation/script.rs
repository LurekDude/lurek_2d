//! Script container for the automation simulation module.
//!
//! This module provides the [`Script`] struct — a named, time-sorted,
//! capacity-capped collection of [`Step`] objects. Scripts are stored in the
//! [`Simulator`](super::Simulator) by name and selected for playback via
//! [`Simulator::start`](super::Simulator::start).
//!
//! The step cap of [`MAX_STEPS`] guards against unbounded memory allocation
//! from large or adversarially constructed input scripts (CSF-010 allocation
//! guard).

use super::Step;

/// Maximum number of steps permitted per script.
///
/// Steps beyond this limit are silently truncated during [`Script::new`].
/// The cap prevents unbounded memory allocation from oversized or adversarial
/// script files (CSF-010 allocation guard). 100 000 steps at ~120 bytes each
/// is roughly 12 MB per script — a deliberate upper bound.
const MAX_STEPS: usize = 100_000;

/// A named simulation script containing an ordered sequence of timed steps.
///
/// On construction, steps are sorted by their `time` field in ascending order
/// and then truncated to [`MAX_STEPS`]. The original insertion order is
/// discarded — only the time ordering is preserved.
///
/// Scripts are stored in the [`Simulator`](super::Simulator) indexed by their
/// `name`. Loading a new script with an existing name replaces the previous
/// one. A script can be played back multiple times by calling
/// [`Simulator::start`](super::Simulator::start) repeatedly.
///
/// # Fields
/// - `name` — `String`.
/// - `description` — `Option<String>`.
/// - `steps` — `Vec<Step>`.
#[derive(Debug, Clone)]
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
    /// table or TOML file. Not used during playback — purely informational.
    pub description: Option<String>,
    /// Time-sorted sequence of steps (ascending by `time`).
    ///
    /// Sorted during construction; never reordered afterwards. The
    /// [`Simulator`](super::Simulator) scans left-to-right, dispatching each
    /// step when `elapsed >= step.time`.
    pub steps: Vec<Step>,
}

impl Script {
    /// Create a new script with the given name and steps.
    ///
    /// Steps are sorted by `time` in ascending order and then truncated to
    /// [`MAX_STEPS`]. When two steps share the same `time` value their
    /// relative order is preserved (stable sort with `Equal` fallback).
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `steps` — `Vec<Step>`.
    ///
    /// # Returns
    /// `Script`.
    pub fn new(name: impl Into<String>, mut steps: Vec<Step>) -> Self {
        steps.sort_by(|a, b| a.time.partial_cmp(&b.time).unwrap_or(std::cmp::Ordering::Equal));
        steps.truncate(MAX_STEPS);
        Self {
            name: name.into(),
            description: None,
            steps,
        }
    }

    /// Create a script with an explicit description string.
    ///
    /// Behaves identically to [`Script::new`] but additionally sets the
    /// `description` field. Useful when constructing scripts in Rust code
    /// that should carry human-readable metadata.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `description` — `impl Into<String>`.
    /// - `steps` — `Vec<Step>`.
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
}
