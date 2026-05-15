//! - Multi-step key-press combo detection with per-step and total-sequence timeouts.
//! - Stateful detector that advances, breaks, or completes on each key feed or timer tick.
//! - Used by the `lurek.input` combo API to recognize fighting-game-style input sequences.

/// One required key press in a combo sequence with its maximum inter-step gap.
#[derive(Clone, Debug, PartialEq)]
pub struct ComboStep {
    /// Logical key name that must be pressed to advance this step.
    pub key: String,
    /// Maximum milliseconds allowed between the previous step and this one.
    pub max_gap_ms: u64,
}

/// Result returned by `ComboDetector::feed` and `ComboDetector::tick` on every call.
#[derive(Clone, Debug, PartialEq)]
pub enum ComboProgress {
    /// All steps were pressed within their gap limits; detector has been reset.
    Completed,
    /// A step was matched; `step` is the next required step index, `total` is sequence length.
    Advanced { step: usize, total: usize },
    /// A key did not match or a gap expired; detector has been reset.
    Broken,
    /// No combo is in progress and no relevant key was pressed.
    Idle,
}

/// Stateful multi-step key-press detector used by `lurek.input` combo API.
pub struct ComboDetector {
    /// Ordered list of steps that must be pressed in sequence.
    pub steps: Vec<ComboStep>,
    /// Index of the next step that must be matched.
    pub current_step: usize,
    /// Milliseconds elapsed since the last matched step.
    pub last_step_time_ms: u64,
    /// Milliseconds elapsed since the first step was matched.
    pub total_elapsed_ms: u64,
    /// Hard cap on total elapsed time across the whole sequence.
    pub max_total_gap_ms: u64,
    /// When false, `feed` always returns `Idle` without advancing.
    pub enabled: bool,
}

impl ComboDetector {
    /// Create detector with the given step list and total-sequence timeout.
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

    /// Advance the sequence with `key`; returns `Completed`, `Advanced`, `Broken`, or `Idle`.
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

    /// Advance internal timers by `elapsed_ms`; returns `Broken` if any gap expired, else `Advanced` or `Idle`.
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

    /// Reset all step counters and timers to the initial state.
    pub fn reset(&mut self) {
        self.current_step = 0;
        self.last_step_time_ms = 0;
        self.total_elapsed_ms = 0;
    }

    /// Return true when at least one step has been matched and the sequence is ongoing.
    pub fn is_in_progress(&self) -> bool {
        self.current_step > 0
    }

    /// Return the index of the next required step (0 when idle).
    pub fn progress(&self) -> usize {
        self.current_step
    }

    /// Return the total number of steps in the sequence.
    pub fn len(&self) -> usize {
        self.steps.len()
    }

    /// Return true when the step list is empty.
    pub fn is_empty(&self) -> bool {
        self.steps.is_empty()
    }
}
