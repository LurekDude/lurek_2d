//! DAG container for pipeline steps: topological sort, cycle detection, parallel grouping.
//!
//! Key types: `Pipeline`, `ErrorMode`. Primary functions: `add_step`, `validate`,
//! `get_execution_order`, `get_parallel_groups`.
//! Part of the `pipeline` Tier 2 subsystem.

use std::collections::{HashMap, HashSet, VecDeque};

use crate::runtime::log_messages::{PL01_PIPELINE_INIT, PL02_STEP_ADD};
use crate::log_msg;
use crate::pipeline::result::{PipelineResult, PipelineStatus};
use crate::pipeline::step::{PipelineStep, StepStatus};

/// Determines how the pipeline responds when a step fails.
///
/// # Variants
/// - `Abort` — Abort variant.
/// - `Continue` — Continue variant.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ErrorMode {
    /// Stop pipeline execution on the first failed step.
    Abort,
    /// Skip the failed step and continue executing the remaining steps.
    Continue,
}

impl ErrorMode {
    /// Returns the mode as a lowercase string suitable for Lua.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Abort => "abort",
            Self::Continue => "continue",
        }
    }

    /// Parses a mode string. Returns `Err` with a descriptive message on unknown input.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Result<ErrorMode, String>`.
    pub fn from_str_lua(s: &str) -> Result<Self, String> {
        match s {
            "abort" => Ok(Self::Abort),
            "continue" => Ok(Self::Continue),
            _ => Err(format!(
                "setErrorMode: unknown mode '{}', expected 'abort' or 'continue'",
                s
            )),
        }
    }
}

/// A directed acyclic graph (DAG) container that holds pipeline steps and their dependencies.
///
/// `Pipeline` owns the step definitions and provides validation and scheduling helpers.
/// Runtime countdown state lives in `PipelineScheduler`.
///
/// # Fields
/// - `name` — `String`.
/// - `error_mode` — `ErrorMode`.
#[derive(Debug, Clone)]
pub struct Pipeline {
    /// Human-readable name for this pipeline.
    pub name: String,
    steps: HashMap<String, PipelineStep>,
    /// Global error handling mode applied when a step has no step-level `ErrorPolicy`.
    pub error_mode: ErrorMode,
}

impl Pipeline {
    /// Creates a new empty pipeline with the given name.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Pipeline`.
    pub fn new(name: impl Into<String>) -> Self {
        log_msg!(debug, PL01_PIPELINE_INIT);
        Self {
            name: name.into(),
            steps: HashMap::new(),
            error_mode: ErrorMode::Abort,
        }
    }

    /// Adds a step to the pipeline.
    ///
    /// Returns `Err` if a step with the same name already exists.
    ///
    /// # Parameters
    /// - `step` — `PipelineStep`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn add_step(&mut self, step: PipelineStep) -> Result<(), String> {
        if self.steps.contains_key(&step.name) {
            return Err(format!(
                "step '{}' already exists in pipeline '{}'",
                step.name, self.name
            ));
        }
        self.steps.insert(step.name.clone(), step);
        log_msg!(debug, PL02_STEP_ADD);
        Ok(())
    }

    /// Removes a step by name and strips any dependency references to it from other steps.
    ///
    /// Returns `true` if the step was found and removed, `false` if it did not exist.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_step(&mut self, name: &str) -> bool {
        if self.steps.remove(name).is_none() {
            return false;
        }
        for step in self.steps.values_mut() {
            step.deps.retain(|d| d != name);
        }
        true
    }

    /// Returns a shared reference to the step with the given name, if it exists.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&PipelineStep>`.
    pub fn get_step(&self, name: &str) -> Option<&PipelineStep> {
        self.steps.get(name)
    }

    /// Returns a mutable reference to the step with the given name, if it exists.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut PipelineStep>`.
    pub fn get_step_mut(&mut self, name: &str) -> Option<&mut PipelineStep> {
        self.steps.get_mut(name)
    }

    /// Returns an iterator over all steps in unspecified order.
    ///
    /// # Returns
    /// `impl Iterator<Item = &PipelineStep>`.
    pub fn get_steps(&self) -> impl Iterator<Item = &PipelineStep> {
        self.steps.values()
    }

    /// Returns the total number of steps in the pipeline.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_step_count(&self) -> usize {
        self.steps.len()
    }

    /// Removes all steps from the pipeline.
    pub fn clear(&mut self) {
        self.steps.clear();
    }

    /// Validates the pipeline and returns `(is_valid, list_of_error_messages)`.
    ///
    /// Checks performed:
    /// - All dependency names exist as steps in this pipeline.
    /// - No dependency cycles (Kahn's algorithm).
    ///
    /// # Returns
    /// `(bool, Vec<String>)`.
    pub fn validate(&self) -> (bool, Vec<String>) {
        let mut errors: Vec<String> = Vec::new();

        // Check all dep names exist
        for step in self.steps.values() {
            for dep in &step.deps {
                if !self.steps.contains_key(dep.as_str()) {
                    errors.push(format!(
                        "step '{}' depends on '{}' which does not exist",
                        step.name, dep
                    ));
                }
            }
        }

        // Check for cycles
        if errors.is_empty() {
            if let Err(cycle_msg) = self.get_execution_order() {
                errors.push(cycle_msg);
            }
        }

        let is_valid = errors.is_empty();
        (is_valid, errors)
    }

    /// Returns a topological ordering of step names using Kahn's algorithm.
    ///
    /// Returns `Err` if a cycle is detected, naming the steps involved where possible.
    ///
    /// # Returns
    /// `Result<Vec<String>, String>`.
    pub fn get_execution_order(&self) -> Result<Vec<String>, String> {
        // Build in-degree map and adjacency list (dep → dependents)
        let mut in_degree: HashMap<&str, usize> = HashMap::new();
        let mut dependents: HashMap<&str, Vec<&str>> = HashMap::new();

        for name in self.steps.keys() {
            in_degree.entry(name.as_str()).or_insert(0);
            dependents.entry(name.as_str()).or_default();
        }

        for step in self.steps.values() {
            for dep in &step.deps {
                // Only count valid deps (validate() separately catches unknown deps)
                if self.steps.contains_key(dep.as_str()) {
                    *in_degree.entry(step.name.as_str()).or_insert(0) += 1;
                    dependents
                        .entry(dep.as_str())
                        .or_default()
                        .push(step.name.as_str());
                }
            }
        }

        let mut queue: VecDeque<&str> = in_degree
            .iter()
            .filter(|(_, &deg)| deg == 0)
            .map(|(&name, _)| name)
            .collect();

        let mut order: Vec<String> = Vec::with_capacity(self.steps.len());

        while let Some(current) = queue.pop_front() {
            order.push(current.to_owned());
            if let Some(deps_of) = dependents.get(current) {
                for &dependent in deps_of {
                    // SAFETY: `dependent` was seeded from `self.steps.keys()` above, so it
                    // is always present in `in_degree`.
                    let deg = in_degree
                        .get_mut(dependent)
                        .unwrap_or_else(|| unreachable!("dependent key missing from in_degree"));
                    *deg -= 1;
                    if *deg == 0 {
                        queue.push_back(dependent);
                    }
                }
            }
        }

        if order.len() < self.steps.len() {
            // Collect names of steps still in a non-zero degree (they form the cycle)
            let remaining: Vec<&str> = in_degree
                .iter()
                .filter(|(_, &deg)| deg > 0)
                .map(|(&name, _)| name)
                .collect();
            return Err(format!(
                "cycle detected involving: {}",
                remaining.join(", ")
            ));
        }

        Ok(order)
    }

    /// Groups steps into parallel execution levels.
    ///
    /// All steps at level 0 (no dependencies) can run concurrently. Steps at
    /// level N depend only on steps at levels 0..N-1 and can run concurrently
    /// with each other.
    ///
    /// Returns `Err` if there is a dependency cycle.
    ///
    /// # Returns
    /// `Result<Vec<Vec<String>>, String>`.
    pub fn get_parallel_groups(&self) -> Result<Vec<Vec<String>>, String> {
        // Compute level for each step: max(level of deps) + 1, 0 for no deps
        let topo = self.get_execution_order()?;
        let mut levels: HashMap<&str, usize> = HashMap::new();

        for name in &topo {
            // SAFETY: `name` comes from `topo`, which is built from `self.steps.keys()`.
            let step = self
                .steps
                .get(name.as_str())
                .unwrap_or_else(|| unreachable!("step name from topo order not found in steps"));
            let level = step
                .deps
                .iter()
                .filter(|dep| self.steps.contains_key(dep.as_str()))
                .map(|dep| levels.get(dep.as_str()).copied().unwrap_or(0) + 1)
                .max()
                .unwrap_or(0);
            levels.insert(name.as_str(), level);
        }

        let max_level = levels.values().copied().max().unwrap_or(0);
        let mut groups: Vec<Vec<String>> = vec![Vec::new(); max_level + 1];

        for (name, &level) in &levels {
            groups[level].push((*name).to_owned());
        }

        // Keep each group's order stable (sort by topo position)
        let topo_index: HashMap<&str, usize> = topo
            .iter()
            .enumerate()
            .map(|(i, n)| (n.as_str(), i))
            .collect();

        for group in &mut groups {
            group.sort_by_key(|n| topo_index.get(n.as_str()).copied().unwrap_or(0));
        }

        // Remove empty groups (can occur if levels are sparse — they won't be, but guard anyway)
        groups.retain(|g| !g.is_empty());

        Ok(groups)
    }

    /// Resets the runtime state of every step in the pipeline.
    pub fn reset(&mut self) {
        for step in self.steps.values_mut() {
            step.reset();
        }
    }

    /// Checks whether all declared dependencies of `step_name` have reached a terminal-success state.
    ///
    /// Returns `Ok(true)` when all deps are satisfied, `Ok(false)` when a required dep failed/skipped,
    /// and `Err` when a required dep is still mid-flight (caller should skip or defer the step).
    ///
    /// # Parameters
    /// - `step_name` — `&str`. The step whose deps to evaluate.
    /// - `statuses` — `&HashMap<String, StepStatus>`. Current status of every step in the pipeline.
    ///
    /// # Returns
    /// `Result<bool, String>`.
    pub fn are_deps_satisfied(
        &self,
        step_name: &str,
        statuses: &HashMap<String, StepStatus>,
    ) -> Result<bool, String> {
        let step = match self.get_step(step_name) {
            Some(s) => s,
            None => return Err(format!("step '{}' not found", step_name)),
        };
        for dep_name in &step.deps {
            let dep_status = match statuses.get(dep_name) {
                Some(s) => s.clone(),
                None => return Ok(false),
            };
            match dep_status {
                StepStatus::Completed => {}
                StepStatus::Skipped | StepStatus::Failed => {
                    let is_optional = self
                        .get_step(dep_name)
                        .map(|s| s.optional)
                        .unwrap_or(false);
                    if !is_optional {
                        return Ok(false);
                    }
                }
                _ => {
                    return Err(format!(
                        "dep '{}' of '{}' is still in state {:?}",
                        dep_name, step_name, dep_status
                    ));
                }
            }
        }
        Ok(true)
    }

    /// Aggregates per-step runtime data into a `PipelineResult` summary.
    ///
    /// # Parameters
    /// - `step_statuses` — `&HashMap<String, (StepStatus, Option<String>)>`. Each entry is
    ///   `(name, (status, error_message))`.
    /// - `duration` — `f32`. Total wall-clock execution time in seconds.
    ///
    /// # Returns
    /// `PipelineResult`.
    pub fn collect_result(
        &self,
        step_statuses: &HashMap<String, (StepStatus, Option<String>)>,
        duration: f32,
    ) -> PipelineResult {
        let mut result = PipelineResult::new();
        result.total_duration = duration;
        for (name, (status, error_msg)) in step_statuses {
            match status {
                StepStatus::Completed => result.completed.push(name.clone()),
                StepStatus::Failed => {
                    result.failed.push(name.clone());
                    if let Some(msg) = error_msg {
                        result.errors.push((name.clone(), msg.clone()));
                    }
                }
                StepStatus::Skipped => result.skipped.push(name.clone()),
                StepStatus::Cancelled => result.cancelled.push(name.clone()),
                _ => {}
            }
        }
        result.status = if result.failed.is_empty() {
            PipelineStatus::Completed
        } else {
            PipelineStatus::Failed
        };
        result
    }

    /// Returns a multi-line ASCII string that visualises the pipeline DAG.
    ///
    /// Each parallel group is printed on its own level. Steps are shown as
    /// `[name]` with upstream dependencies listed inline: `[name <-- dep1,dep2]`.
    /// Steps in the same group are separated by `" || "`.
    ///
    /// If the graph contains a cycle the string contains a single error line
    /// describing the detected cycle rather than a level listing.
    ///
    /// # Returns
    /// `String`.
    pub fn to_ascii_diagram(&self) -> String {
        let mut lines = Vec::new();
        lines.push(format!("Pipeline: \"{}\"", self.name));
        match self.get_parallel_groups() {
            Ok(groups) => {
                for (level, group) in groups.iter().enumerate() {
                    let slots: Vec<String> = group
                        .iter()
                        .map(|n| {
                            let deps = self
                                .steps
                                .get(n)
                                .map(|s| s.deps.join(","))
                                .unwrap_or_default();
                            if deps.is_empty() {
                                format!("[{}]", n)
                            } else {
                                format!("[{} <-- {}]", n, deps)
                            }
                        })
                        .collect();
                    lines.push(format!("  L{}: {}", level, slots.join(" || ")));
                }
                if groups.is_empty() {
                    lines.push("  (empty pipeline)".to_string());
                }
            }
            Err(e) => lines.push(format!("  (cycle detected: {})", e)),
        }
        lines.join("\n")
    }

    /// Merges all steps from a sub-pipeline into this pipeline with a name prefix.
    ///
    /// Every step name in `sub` is prefixed with `"{alias}/"` to avoid conflicts.
    /// Steps in `sub` that have no dependencies become dependent on every step
    /// listed in `outer_deps` (which must already exist in `self`).
    ///
    /// This lets you express a multi-phase init pipeline as a composition of
    /// smaller named pipelines without manually cross-wiring each step.
    ///
    /// Returns `Err` if any name in `outer_deps` does not exist in `self`, or
    /// if the resulting pipeline would contain a cycle.
    ///
    /// # Parameters
    /// - `sub` — `Pipeline`. The pipeline to inline.
    /// - `alias` — `&str`. Prefix applied to every step name from `sub`.
    /// - `outer_deps` — `Vec<String>`. Steps in `self` that the sub-pipeline's
    ///   entry points should depend on.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn add_sub_pipeline(
        &mut self,
        sub: Pipeline,
        alias: &str,
        outer_deps: Vec<String>,
    ) -> Result<(), String> {
        // Validate outer_deps all exist in self.
        for dep in &outer_deps {
            if !self.steps.contains_key(dep.as_str()) {
                return Err(format!(
                    "add_sub_pipeline: outer dependency '{}' does not exist in pipeline '{}'",
                    dep, self.name
                ));
            }
        }
        // Determine entry points of the sub-pipeline (steps with no sub-pipeline-internal deps).
        let sub_entry_points: HashSet<String> = sub
            .steps
            .values()
            .filter(|s| s.deps.is_empty())
            .map(|s| s.name.clone())
            .collect();
        // Import every step from sub with prefixed names.
        for mut step in sub.steps.into_values() {
            let prefixed_name = format!("{}/{}", alias, step.name);
            // Prefix all dep references.
            step.deps = step
                .deps
                .into_iter()
                .map(|d| format!("{}/{}", alias, d))
                .collect();
            // For entry points, also add outer_deps.
            if sub_entry_points.contains(&step.name) {
                step.deps.extend(outer_deps.clone());
            }
            step.name = prefixed_name;
            self.add_step(step)?;
        }
        Ok(())
    }

    // ---------------------------------------------------------------------------
    // Internal helpers
    // ---------------------------------------------------------------------------

    /// Returns the set of step names that directly or transitively depend on `root`.
    ///
    /// Used internally; not exposed as `pub` since callers can reconstruct this
    /// via `get_execution_order` if needed.
    #[allow(dead_code)]
    fn dependents_of(&self, root: &str) -> HashSet<String> {
        let mut result = HashSet::new();
        for step in self.steps.values() {
            if step.deps.iter().any(|d| d == root) {
                result.insert(step.name.clone());
            }
        }
        result
    }
}