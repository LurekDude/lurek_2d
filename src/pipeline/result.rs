//! Pipeline execution result types for `src/pipeline`.
//! Owns `PipelineStatus` (lifecycle enum) and `PipelineResult` (final outcome after
//! a pipeline run). Does not own scheduling, step definitions, or DAG logic.
//! Consumed by `PipelineScheduler` and Lua bindings in `lua_api/pipeline_api.rs`.

/// Lifecycle state of a pipeline run.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PipelineStatus {
    /// Not yet started.
    Pending,
    /// Actively executing steps.
    Running,
    /// All steps resolved without unrecovered failures.
    Completed,
    /// At least one non-optional step failed and error mode was Abort.
    Failed,
    /// Execution was cancelled before all steps ran.
    Cancelled,
}

/// Aggregated outcome produced after a pipeline finishes or aborts.
#[derive(Debug, Clone)]
pub struct PipelineResult {
    /// Overall lifecycle state of this run.
    pub status: PipelineStatus,
    /// Names of steps that reached `StepStatus::Completed`.
    pub completed: Vec<String>,
    /// Names of steps that reached `StepStatus::Failed`.
    pub failed: Vec<String>,
    /// Names of steps that were skipped due to failed non-optional dependencies.
    pub skipped: Vec<String>,
    /// Names of steps cancelled when the pipeline aborted early.
    pub cancelled: Vec<String>,
    /// Wall-clock seconds from pipeline start to finish.
    pub total_duration: f32,
    /// Per-step error messages: `(step_name, error_text)` pairs.
    pub errors: Vec<(String, String)>,
}

impl PipelineResult {
    /// Create a blank result in `Pending` state with no recorded steps.
    pub fn new() -> Self {
        Self {
            status: PipelineStatus::Pending,
            completed: Vec::new(),
            failed: Vec::new(),
            skipped: Vec::new(),
            cancelled: Vec::new(),
            total_duration: 0.0,
            errors: Vec::new(),
        }
    }

    /// Return `true` if no steps failed (skipped and cancelled do not count as failure).
    pub fn is_success(&self) -> bool {
        self.failed.is_empty()
    }

    /// Return a single-line human-readable summary of counts and duration.
    pub fn summary(&self) -> String {
        format!(
            "status={:?} completed={} failed={} skipped={} cancelled={} duration={:.3}s",
            self.status,
            self.completed.len(),
            self.failed.len(),
            self.skipped.len(),
            self.cancelled.len(),
            self.total_duration,
        )
    }
}

/// Delegate to `PipelineResult::new`.
impl Default for PipelineResult {
    fn default() -> Self {
        Self::new()
    }
}
