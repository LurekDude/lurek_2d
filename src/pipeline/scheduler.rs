use crate::pipeline::dag::Pipeline;
use crate::pipeline::step::StepStatus;
use std::collections::HashMap;
pub struct PipelineScheduler {
    delay_timers: HashMap<String, f32>,
    pub is_running: bool,
    pub elapsed: f32,
}
impl PipelineScheduler {
    pub fn new() -> Self {
        Self {
            delay_timers: HashMap::new(),
            is_running: false,
            elapsed: 0.0,
        }
    }
    pub fn start(&mut self, pipeline: &Pipeline) {
        self.delay_timers.clear();
        self.elapsed = 0.0;
        self.is_running = true;
        for step in pipeline.get_steps() {
            self.delay_timers.insert(step.name.clone(), step.delay);
        }
    }
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
    pub fn mark_step_waiting(&mut self, name: &str, pipeline: &Pipeline) {
        let delay = pipeline.get_step(name).map(|s| s.delay).unwrap_or(0.0);
        self.delay_timers.insert(name.to_owned(), delay);
    }
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
