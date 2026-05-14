//! Time-based step scheduler for `src/pipeline`.
//! Owns per-step countdown timers and tracks pipeline elapsed time. Does not own
//! step definitions, DAG topology, or execution logic — those live in `dag.rs`.
//! Consumed by Lua bindings in `lua_api/pipeline_api.rs` to drive frame-by-frame updates.

use crate::pipeline::dag::Pipeline;
use crate::pipeline::step::StepStatus;
use std::collections::HashMap;

/// Drives step-delay countdowns and reports which steps become ready each frame.
pub struct PipelineScheduler {
    /// Remaining delay seconds per step name; decremented each `update` call.
    delay_timers: HashMap<String, f32>,
    /// Whether the pipeline is currently executing.
    pub is_running: bool,
    /// Total wall-clock seconds since `start` was called.
    pub elapsed: f32,
}

impl PipelineScheduler {
    /// Create a stopped scheduler with no active timers.
    pub fn new() -> Self {
        Self {
            delay_timers: HashMap::new(),
            is_running: false,
            elapsed: 0.0,
        }
    }

    /// Initialize delay timers from `pipeline` step definitions and begin execution.
    pub fn start(&mut self, pipeline: &Pipeline) {
        self.delay_timers.clear();
        self.elapsed = 0.0;
        self.is_running = true;
        for step in pipeline.get_steps() {
            self.delay_timers.insert(step.name.clone(), step.delay);
        }
    }

    /// Advance timers by `dt` seconds and return names of steps whose delay has expired and are still `Waiting`.
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

    /// Reset and arm the delay timer for `name` using its configured delay from `pipeline`.
    pub fn mark_step_waiting(&mut self, name: &str, pipeline: &Pipeline) {
        let delay = pipeline.get_step(name).map(|s| s.delay).unwrap_or(0.0);
        self.delay_timers.insert(name.to_owned(), delay);
    }

    /// Clear all timers and stop execution; does not reset step statuses in the pipeline.
    pub fn reset(&mut self) {
        self.delay_timers.clear();
        self.is_running = false;
        self.elapsed = 0.0;
    }
}

/// Delegate to `PipelineScheduler::new`.
impl Default for PipelineScheduler {
    fn default() -> Self {
        Self::new()
    }
}
