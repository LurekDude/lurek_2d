//! Individual step definition types for `src/pipeline`.
//! Owns `StepStatus`, `ErrorPolicy`, and `PipelineStep`. Does not own DAG topology,
//! scheduling timers, or execution logic — those live in `dag.rs` and `scheduler.rs`.
//! `PipelineStep` instances are created by Lua via `pipeline_api.rs` and stored in `Pipeline`.

use std::collections::HashMap;

/// Execution lifecycle state of a single pipeline step.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StepStatus {
    /// Created but not yet enqueued for execution.
    Pending,
    /// Enqueued; waiting for its delay timer to expire.
    Waiting,
    /// Currently executing.
    Running,
    /// Finished successfully.
    Completed,
    /// Execution ended with an error.
    Failed,
    /// Not executed because a required dependency failed.
    Skipped,
    /// Cancelled when the pipeline aborted before this step ran.
    Cancelled,
}

impl StepStatus {
    /// Return the canonical lowercase token string for this status.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Pending => "pending",
            Self::Waiting => "waiting",
            Self::Running => "running",
            Self::Completed => "completed",
            Self::Failed => "failed",
            Self::Skipped => "skipped",
            Self::Cancelled => "cancelled",
        }
    }
}

/// Per-step failure response, overriding the pipeline-level `ErrorMode`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ErrorPolicy {
    /// Abort the entire pipeline on failure.
    Abort,
    /// Mark this step failed and continue scheduling other steps.
    Continue,
    /// Re-queue this step up to `retry_count` times before failing.
    Retry,
}

/// Single named unit of work in a `Pipeline`, carrying dependency, timing, and retry configuration.
#[derive(Debug, Clone)]
pub struct PipelineStep {
    /// Unique name within the owning `Pipeline`.
    pub name: String,
    /// Names of steps that must complete before this one can run.
    pub deps: Vec<String>,
    /// Seconds to wait after deps satisfy before transitioning from `Waiting` to `Running`.
    pub delay: f32,
    /// When `true`, downstream steps are not blocked if this step fails.
    pub optional: bool,
    /// Maximum number of automatic retries on failure; 0 means no retries.
    pub retry_count: u32,
    /// Seconds to wait between retry attempts.
    pub retry_delay: f32,
    /// Per-step policy that overrides the pipeline `ErrorMode` on failure.
    pub on_error: ErrorPolicy,
    /// Optional grouping tag used for filtering or reporting.
    pub tag: Option<String>,
    /// Arbitrary key-value metadata stored for Lua consumption.
    pub metadata: HashMap<String, String>,
    /// Current execution lifecycle state.
    pub status: StepStatus,
    /// Number of execution attempts made so far, including retries.
    pub attempt: u32,
    /// Wall-clock seconds the most recent execution attempt took.
    pub duration: f32,
    /// Error message from the most recent failure, if any.
    pub error_msg: Option<String>,
}

impl PipelineStep {
    /// Create a step with default settings: no deps, no delay, no retries, `ErrorPolicy::Abort`.
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

    /// Reset runtime state to `Pending`; clears attempt count, duration, and error message.
    pub fn reset(&mut self) {
        self.status = StepStatus::Pending;
        self.attempt = 0;
        self.duration = 0.0;
        self.error_msg = None;
    }
}
