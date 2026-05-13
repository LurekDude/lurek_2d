use std::collections::HashMap;
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StepStatus {
    Pending,
    Waiting,
    Running,
    Completed,
    Failed,
    Skipped,
    Cancelled,
}
impl StepStatus {
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
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ErrorPolicy {
    Abort,
    Continue,
    Retry,
}
#[derive(Debug, Clone)]
pub struct PipelineStep {
    pub name: String,
    pub deps: Vec<String>,
    pub delay: f32,
    pub optional: bool,
    pub retry_count: u32,
    pub retry_delay: f32,
    pub on_error: ErrorPolicy,
    pub tag: Option<String>,
    pub metadata: HashMap<String, String>,
    pub status: StepStatus,
    pub attempt: u32,
    pub duration: f32,
    pub error_msg: Option<String>,
}
impl PipelineStep {
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
    pub fn reset(&mut self) {
        self.status = StepStatus::Pending;
        self.attempt = 0;
        self.duration = 0.0;
        self.error_msg = None;
    }
}
