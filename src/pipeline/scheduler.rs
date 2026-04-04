//! Delay countdown and dispatch state for pipeline execution.
//!
//! Key types: `PipelineScheduler`. Primary functions: `start`, `update`, `mark_step_waiting`.
//! Part of the `pipeline` Tier 2 subsystem.

use std::collections::HashMap;

use crate::pipeline::dag::Pipeline;
use crate::pipeline::step::StepStatus;

/// Tracks per-step delay timers and overall wall-clock time for a pipeline run.
///
/// # Fields
/// - `delay_timers` — `HashMap<String, f32>`.
/// - `is_running` — `bool`.
/// - `elapsed` — `f32`.
pub struct PipelineScheduler {
    /// Remaining delay seconds for each step that is in `Waiting` state.
    delay_timers: HashMap<String, f32>,
    /// `true` while the pipeline is actively running.
    pub is_running: bool,
    /// Total wall-clock seconds since `start()` was called.
    pub elapsed: f32,
}

impl PipelineScheduler {
    /// Creates a new scheduler in a stopped, empty state.
    ///
    /// # Returns
    /// `PipelineScheduler`.
    pub fn new() -> Self {
        Self {
            delay_timers: HashMap::new(),
            is_running: false,
            elapsed: 0.0,
        }
    }

    /// Initialises the scheduler for a new pipeline run.
    ///
    /// Clears any previous state, marks the scheduler as running, and pre-populates
    /// the delay timer map with each step's configured delay.
    ///
    /// # Parameters
    /// - `pipeline` — `&Pipeline`.
    pub fn start(&mut self, pipeline: &Pipeline) {
        self.delay_timers.clear();
        self.elapsed = 0.0;
        self.is_running = true;

        for step in pipeline.get_steps() {
            self.delay_timers.insert(step.name.clone(), step.delay);
        }
    }

    /// Advances all Waiting step timers by `dt` seconds and returns the names of steps
    /// whose delay has elapsed and that are ready to execute.
    ///
    /// A step is "ready" when its status is `Waiting` and its remaining timer is ≤ 0.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    /// - `pipeline` — `&Pipeline`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn update(&mut self, dt: f32, pipeline: &Pipeline) -> Vec<String> {
        if !self.is_running {
            return Vec::new();
        }

        self.elapsed += dt;

        let mut ready: Vec<String> = Vec::new();

        for step in pipeline.get_steps() {
            if step.status != StepStatus::Waiting {
                continue;
            }

            let timer = self.delay_timers.entry(step.name.clone()).or_insert(0.0);
            *timer -= dt;

            if *timer <= 0.0 {
                ready.push(step.name.clone());
            }
        }

        ready
    }

    /// Called when all dependencies of a step are done; starts its delay countdown.
    ///
    /// If the step has no entry in the timer map (e.g. it was added after `start()`),
    /// its delay is fetched from the pipeline definition.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `pipeline` — `&Pipeline`.
    pub fn mark_step_waiting(&mut self, name: &str, pipeline: &Pipeline) {
        let delay = pipeline
            .get_step(name)
            .map(|s| s.delay)
            .unwrap_or(0.0);

        self.delay_timers.insert(name.to_owned(), delay);
    }

    /// Stops the scheduler and clears all timers.
    pub fn reset(&mut self) {
        self.delay_timers.clear();
        self.is_running = false;
        self.elapsed = 0.0;
    }
}

impl Default for PipelineScheduler {
    fn default() -> Self {
        Self::new()
    }
}
