#[derive(Clone, Debug, PartialEq)]
pub struct ComboStep {
    pub key: String,
    pub max_gap_ms: u64,
}
#[derive(Clone, Debug, PartialEq)]
pub enum ComboProgress {
    Completed,
    Advanced { step: usize, total: usize },
    Broken,
    Idle,
}
pub struct ComboDetector {
    pub steps: Vec<ComboStep>,
    pub current_step: usize,
    pub last_step_time_ms: u64,
    pub total_elapsed_ms: u64,
    pub max_total_gap_ms: u64,
    pub enabled: bool,
}
impl ComboDetector {
    pub fn new(steps: Vec<ComboStep>, max_total_gap_ms: u64) -> Self {
        Self {
            steps,
            current_step: 0,
            last_step_time_ms: 0,
            total_elapsed_ms: 0,
            max_total_gap_ms,
            enabled: true,
        }
    }
    pub fn feed(&mut self, key: &str, elapsed_ms: u64) -> ComboProgress {
        if !self.enabled || self.steps.is_empty() {
            return ComboProgress::Idle;
        }
        self.last_step_time_ms += elapsed_ms;
        if self.current_step > 0 {
            self.total_elapsed_ms += elapsed_ms;
        }
        if self.current_step > 0 && self.total_elapsed_ms > self.max_total_gap_ms {
            self.reset();
            return ComboProgress::Broken;
        }
        if self.current_step > 0 {
            let gap_limit = self.steps[self.current_step].max_gap_ms;
            if self.last_step_time_ms > gap_limit {
                self.reset();
                return ComboProgress::Broken;
            }
        }
        if self.steps[self.current_step].key == key {
            self.current_step += 1;
            self.last_step_time_ms = 0;
            if self.current_step == 0 {
                self.total_elapsed_ms = 0;
            }
            if self.current_step >= self.steps.len() {
                self.reset();
                return ComboProgress::Completed;
            }
            let total = self.steps.len();
            return ComboProgress::Advanced {
                step: self.current_step,
                total,
            };
        }
        if self.current_step > 0 {
            self.reset();
            return ComboProgress::Broken;
        }
        ComboProgress::Idle
    }
    pub fn tick(&mut self, elapsed_ms: u64) -> ComboProgress {
        if !self.enabled || self.current_step == 0 {
            return ComboProgress::Idle;
        }
        self.last_step_time_ms += elapsed_ms;
        self.total_elapsed_ms += elapsed_ms;
        let per_step_expired = {
            let gap_limit = self.steps[self.current_step].max_gap_ms;
            self.last_step_time_ms > gap_limit
        };
        let total_expired = self.total_elapsed_ms > self.max_total_gap_ms;
        if per_step_expired || total_expired {
            self.reset();
            return ComboProgress::Broken;
        }
        ComboProgress::Advanced {
            step: self.current_step,
            total: self.steps.len(),
        }
    }
    pub fn reset(&mut self) {
        self.current_step = 0;
        self.last_step_time_ms = 0;
        self.total_elapsed_ms = 0;
    }
    pub fn is_in_progress(&self) -> bool {
        self.current_step > 0
    }
    pub fn progress(&self) -> usize {
        self.current_step
    }
    pub fn len(&self) -> usize {
        self.steps.len()
    }
    pub fn is_empty(&self) -> bool {
        self.steps.is_empty()
    }
}
