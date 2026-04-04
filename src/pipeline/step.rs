//! Pipeline step definition: `PipelineStep`, `StepStatus`, and `ErrorPolicy`.
//!
//! Key types: `PipelineStep`, `StepStatus`, `ErrorPolicy`.
//! Part of the `pipeline` Tier 2 subsystem.

use std::collections::HashMap;

/// Execution status of a single pipeline step.
///
/// Steps transition through this lifecycle: `Pending` → `Waiting` → `Running`
/// → `Completed` (or `Failed` / `Skipped` / `Cancelled`).
///
/// # Variants
/// - `Pending` — Pending variant.
/// - `Waiting` — Waiting variant.
/// - `Running` — Running variant.
/// - `Completed` — Completed variant.
/// - `Failed` — Failed variant.
/// - `Skipped` — Skipped variant.
/// - `Cancelled` — Cancelled variant.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StepStatus {
    /// The step has not yet been evaluated.
    Pending,
    /// All dependencies are satisfied; the step is waiting for its delay timer.
    Waiting,
    /// The step is actively executing.
    Running,
    /// The step finished successfully.
    Completed,
    /// The step ended with an error.
    Failed,
    /// The step was skipped (e.g. a required dependency failed and on_error = Continue).
    Skipped,
    /// The pipeline was cancelled before this step ran.
    Cancelled,
}

/// Determines how the pipeline reacts when this step fails.
///
/// # Variants
/// - `Abort` — Abort variant.
/// - `Continue` — Continue variant.
/// - `Retry` — Retry variant.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ErrorPolicy {
    /// Abort the entire pipeline on failure.
    Abort,
    /// Skip this step and continue executing the remaining pipeline.
    Continue,
    /// Retry this step up to `retry_count` times before applying `Abort` or `Continue`.
    Retry,
}

/// A single node in a pipeline DAG representing one unit of work.
///
/// Steps are identified by a unique `name` within their parent `Pipeline`.
/// Runtime fields (`status`, `attempt`, `duration`, `error_msg`) are reset
/// by `PipelineStep::reset()` or `Pipeline::reset()`.
///
/// # Fields
/// - `name` — `String`.
/// - `deps` — `Vec<String>`.
/// - `delay` — `f32`.
/// - `optional` — `bool`.
/// - `retry_count` — `u32`.
/// - `retry_delay` — `f32`.
/// - `on_error` — `ErrorPolicy`.
/// - `tag` — `Option<String>`.
/// - `metadata` — `HashMap<String, String>`.
/// - `status` — `StepStatus`.
/// - `attempt` — `u32`.
/// - `duration` — `f32`.
/// - `error_msg` — `Option<String>`.
#[derive(Debug, Clone)]
pub struct PipelineStep {
    /// Unique name of this step within its pipeline.
    pub name: String,
    /// Names of steps that must complete before this step can begin.
    pub deps: Vec<String>,
    /// Seconds to wait after all dependencies are satisfied, before executing.
    pub delay: f32,
    /// If `true`, downstream steps proceed even if this step is skipped or fails.
    pub optional: bool,
    /// Maximum number of retries on failure (used when `on_error == ErrorPolicy::Retry`).
    pub retry_count: u32,
    /// Seconds to wait between retry attempts.
    pub retry_delay: f32,
    /// How the pipeline should react if this step fails.
    pub on_error: ErrorPolicy,
    /// Optional tag for grouping or filtering steps.
    pub tag: Option<String>,
    /// Arbitrary string key/value metadata attached to this step.
    pub metadata: HashMap<String, String>,
    /// Current execution status. Reset by `reset()`.
    pub status: StepStatus,
    /// Number of execution attempts so far. Reset by `reset()`.
    pub attempt: u32,
    /// Total seconds spent executing this step (last successful or failed run). Reset by `reset()`.
    pub duration: f32,
    /// Error message from the last failed attempt, if any. Reset by `reset()`.
    pub error_msg: Option<String>,
}

impl PipelineStep {
    /// Creates a new step with the given name and all default values.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `PipelineStep`.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            deps: Vec::new(),
            delay: 0.0,
            optional: false,
            retry_count: 0,
            retry_delay: 0.0,
            on_error: ErrorPolicy::Abort,
            tag: None,
            metadata: HashMap::new(),
            status: StepStatus::Pending,
            attempt: 0,
            duration: 0.0,
            error_msg: None,
        }
    }

    /// Resets all runtime state: status → `Pending`, attempt → 0, duration → 0.0, error_msg → None.
    pub fn reset(&mut self) {
        self.status = StepStatus::Pending;
        self.attempt = 0;
        self.duration = 0.0;
        self.error_msg = None;
    }
}
