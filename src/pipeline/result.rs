#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PipelineStatus {
    Pending,
    Running,
    Completed,
    Failed,
    Cancelled,
}
#[derive(Debug, Clone)]
pub struct PipelineResult {
    pub status: PipelineStatus,
    pub completed: Vec<String>,
    pub failed: Vec<String>,
    pub skipped: Vec<String>,
    pub cancelled: Vec<String>,
    pub total_duration: f32,
    pub errors: Vec<(String, String)>,
}
impl PipelineResult {
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
    pub fn is_success(&self) -> bool {
        self.failed.is_empty()
    }
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
