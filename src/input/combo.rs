//! Combo and input-sequence detection for ordered key/button input chains.
//!
//! Pure Rust — no Lua or engine-context dependencies. A [`ComboDetector`]
//! tracks a sequence of named inputs and reports progress after each
//! [`ComboDetector::feed`] or [`ComboDetector::tick`] call.
//!
//! ## Example (conceptual)
//! ```text
//! // Hadoken: Down → Down-Right → Right → A, each step within 500 ms
//! let steps = vec![
//!     ComboStep { key: "down".into(),       max_gap_ms: 500 },
//!     ComboStep { key: "down_right".into(), max_gap_ms: 500 },
//!     ComboStep { key: "right".into(),      max_gap_ms: 500 },
//!     ComboStep { key: "a".into(),          max_gap_ms: 500 },
//! ];
//! let mut detector = ComboDetector::new(steps, 2000);
//! ```
//!
//! Lua bridge: `src/lua_api/input_api.rs` — `lurek.input.newCombo()`.

// -------------------------------------------------------------------------------
// ComboStep
// -------------------------------------------------------------------------------

/// A single step in an input combo sequence.
#[derive(Clone, Debug, PartialEq)]
pub struct ComboStep {
    /// Key or button name (e.g. `"a"`, `"space"`, `"gamepad_a"`).
    pub key: String,
    /// Maximum milliseconds allowed between this step being matched and the next.
    pub max_gap_ms: u64,
}

// -------------------------------------------------------------------------------
// ComboProgress
// -------------------------------------------------------------------------------

/// Result returned after advancing a [`ComboDetector`].
#[derive(Clone, Debug, PartialEq)]
pub enum ComboProgress {
    /// The full combo sequence was matched — fire the action.
    Completed,
    /// One or more steps have been matched; the detector is waiting for the next.
    Advanced {
        /// Number of steps matched so far (0-based: first match sets this to 1).
        step: usize,
        /// Total number of steps in the combo.
        total: usize,
    },
    /// An incorrect key was pressed or a time window expired, breaking the combo.
    Broken,
    /// The detector is idle — no steps have been matched yet.
    Idle,
}

// -------------------------------------------------------------------------------
// ComboDetector
// -------------------------------------------------------------------------------

/// A combo detector that tracks an ordered sequence of named inputs within time windows.
///
/// ## Usage
/// 1. Construct with [`ComboDetector::new`], providing the ordered [`ComboStep`] list
///    and a total-combo time budget in milliseconds.
/// 2. Each frame, call [`ComboDetector::tick`] with the elapsed time so that silent
///    timeouts are detected even when no input fires.
/// 3. When a key/button press event occurs, call [`ComboDetector::feed`] with the key
///    name and the elapsed time since the previous call.
/// 4. When [`ComboProgress::Completed`] is returned, trigger the combo action and the
///    detector resets itself automatically.
pub struct ComboDetector {
    /// The ordered list of steps that constitute the combo.
    pub steps: Vec<ComboStep>,
    /// Index of the *next* step to be matched (0-based).
    pub current_step: usize,
    /// Milliseconds accumulated since the last step was successfully matched.
    pub last_step_time_ms: u64,
    /// Milliseconds accumulated since the first step of the combo was matched.
    pub total_elapsed_ms: u64,
    /// If the total elapsed time exceeds this budget, the combo resets automatically.
    pub max_total_gap_ms: u64,
    /// When `false`, [`ComboDetector::feed`] is a no-op and always returns [`ComboProgress::Idle`].
    pub enabled: bool,
}

impl ComboDetector {
    /// Creates a new combo detector from a list of [`ComboStep`] values.
    ///
    /// `max_total_gap_ms` is the wall-clock budget for completing the entire
    /// sequence from the first matched step. If the combo is not finished
    /// within this many milliseconds it resets automatically.
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

    /// Feed a new input event (a key that was just pressed) and advance time.
    ///
    /// `elapsed_ms` is the number of milliseconds that have passed since the
    /// last call to `feed` or [`ComboDetector::tick`]. Passing `0` is valid
    /// (instantaneous inputs within the same frame).
    ///
    /// Returns the updated [`ComboProgress`]:
    /// - [`ComboProgress::Completed`] — the full sequence was just matched.
    /// - [`ComboProgress::Advanced`]  — one more step was matched; keep watching.
    /// - [`ComboProgress::Broken`]    — wrong key or timeout; detector reset.
    /// - [`ComboProgress::Idle`]      — no progress (disabled or wrong first key).
    pub fn feed(&mut self, key: &str, elapsed_ms: u64) -> ComboProgress {
        if !self.enabled || self.steps.is_empty() {
            return ComboProgress::Idle;
        }

        // Advance clocks before doing any comparison.
        self.last_step_time_ms += elapsed_ms;
        if self.current_step > 0 {
            self.total_elapsed_ms += elapsed_ms;
        }

        // Check total-combo timeout while mid-sequence.
        if self.current_step > 0 && self.total_elapsed_ms > self.max_total_gap_ms {
            self.reset();
            return ComboProgress::Broken;
        }

        // Check per-step gap timeout while mid-sequence.
        if self.current_step > 0 {
            let gap_limit = self.steps[self.current_step].max_gap_ms;
            if self.last_step_time_ms > gap_limit {
                self.reset();
                return ComboProgress::Broken;
            }
        }

        // Test whether this input matches the expected next step.
        if self.steps[self.current_step].key == key {
            self.current_step += 1;
            self.last_step_time_ms = 0;

            if self.current_step == 0 {
                // Began a new sequence — start the total clock.
                self.total_elapsed_ms = 0;
            }

            if self.current_step >= self.steps.len() {
                // All steps matched — combo complete.
                self.reset();
                return ComboProgress::Completed;
            }

            let total = self.steps.len();
            return ComboProgress::Advanced {
                step: self.current_step,
                total,
            };
        }

        // Wrong key while mid-sequence → break.
        if self.current_step > 0 {
            self.reset();
            return ComboProgress::Broken;
        }

        // Not started yet and wrong first key — stay idle.
        ComboProgress::Idle
    }

    /// Advance time without feeding an input event.
    ///
    /// Call once per frame with the frame delta so that timed-out combos are
    /// detected even when no input key was pressed that frame.
    ///
    /// Returns:
    /// - [`ComboProgress::Broken`]   — a running combo just timed out and reset.
    /// - [`ComboProgress::Advanced`] — still in progress, no timeout yet.
    /// - [`ComboProgress::Idle`]     — no combo was in progress.
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

    /// Reset the detector to its initial idle state.
    ///
    /// Called automatically when a combo completes or breaks. Can also be
    /// called from Lua to cancel an in-progress combo.
    pub fn reset(&mut self) {
        self.current_step = 0;
        self.last_step_time_ms = 0;
        self.total_elapsed_ms = 0;
    }

    /// Returns `true` if the combo is currently partway through a sequence.
    pub fn is_in_progress(&self) -> bool {
        self.current_step > 0
    }

    /// Returns how many steps have been successfully matched so far (0 when idle).
    pub fn progress(&self) -> usize {
        self.current_step
    }

    /// Returns the total number of steps in the combo sequence.
    pub fn len(&self) -> usize {
        self.steps.len()
    }

    /// Returns `true` if the combo has no steps.
    pub fn is_empty(&self) -> bool {
        self.steps.is_empty()
    }
}
