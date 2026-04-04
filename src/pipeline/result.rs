//! Pipeline execution result: `PipelineResult` and `PipelineStatus`.
//!
//! Key types: `PipelineResult`, `PipelineStatus`.
//! Part of the `pipeline` Tier 2 subsystem.

/// Overall status of a pipeline execution.
///
/// # Variants
/// - `Pending` — Pending variant.
/// - `Running` — Running variant.
/// - `Completed` — Completed variant.
/// - `Failed` — Failed variant.
/// - `Cancelled` — Cancelled variant.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PipelineStatus {
    /// The pipeline has not started yet.
    Pending,
    /// The pipeline is currently executing.
    Running,
    /// All steps completed (possibly with skips in Continue mode).
    Completed,
    /// At least one step failed and the pipeline is in Abort mode.
    Failed,
    /// The pipeline was stopped before all steps finished.
    Cancelled,
}

/// Aggregated outcome of a complete pipeline run.
///
/// # Fields
/// - `status` — `PipelineStatus`.
/// - `completed` — `Vec<String>`.
/// - `failed` — `Vec<String>`.
/// - `skipped` — `Vec<String>`.
/// - `cancelled` — `Vec<String>`.
/// - `total_duration` — `f32`.
/// - `errors` — `Vec<(String, String)>`.
#[derive(Debug, Clone)]
pub struct PipelineResult {
    /// Overall status of the pipeline run.
    pub status: PipelineStatus,
    /// Names of steps that completed successfully.
    pub completed: Vec<String>,
    /// Names of steps that failed.
    pub failed: Vec<String>,
    /// Names of steps that were skipped.
    pub skipped: Vec<String>,
    /// Names of steps that were cancelled.
    pub cancelled: Vec<String>,
    /// Wall-clock seconds from pipeline start to finish.
    pub total_duration: f32,
    /// Each entry is `(step_name, error_message)` for every failed step.
    pub errors: Vec<(String, String)>,
}

impl PipelineResult {
    /// Creates a new `PipelineResult` in the `Pending` state with all counters zeroed.
    ///
    /// # Returns
    /// `PipelineResult`.
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

    /// Returns `true` if no steps failed.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_success(&self) -> bool {
        self.failed.is_empty()
    }

    /// Returns a human-readable one-line summary of this result.
    ///
    /// # Returns
    /// `String`.
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

impl Default for PipelineResult {
    fn default() -> Self {
        Self::new()
    }
}
