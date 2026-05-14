
//! - Defines the per-agent emotion state used by the AI module to track named
//!   feelings as clamped scalar values that move toward resting levels over time.
//! - Owns the single-emotion rules for activation thresholds, direct setting,
//!   triggering, and decay back toward each emotion's baseline.
//! - Keeps the model-level operations that add or replace emotions, query current
//!   and dominant states, list active names, update all tracked values, and reset them.

/// One named emotion tracked by `EmotionModel`.
pub struct Emotion {
    /// Emotion name.
    pub name: String,
    /// Current emotion value in `[0, 1]`.
    pub value: f32,
    /// Target value the emotion decays toward.
    pub resting_level: f32,
    /// Rate used to approach the resting level.
    pub decay_rate: f32,
    /// Minimum visible value used by `is_active`.
    pub min_visible: f32,
}
impl Emotion {
    /// Create a new emotion with clamped resting and visibility levels.
    pub fn new(name: &str, resting_level: f32, decay_rate: f32, min_visible: f32) -> Self {
        Self {
            name: name.to_string(),
            value: resting_level,
            resting_level: resting_level.clamp(0.0, 1.0),
            decay_rate,
            min_visible: min_visible.clamp(0.0, 1.0),
        }
    }
    /// Return `true` when the emotion is above the visible threshold.
    pub fn is_active(&self) -> bool {
        self.value >= self.min_visible
    }
    /// Increase the emotion value and clamp it to `[0, 1]`.
    pub fn trigger(&mut self, amount: f32) {
        self.value = (self.value + amount).clamp(0.0, 1.0);
    }
    /// Set the emotion value directly and clamp it to `[0, 1]`.
    pub fn set(&mut self, value: f32) {
        self.value = value.clamp(0.0, 1.0);
    }
    /// Move the emotion toward its resting level over `dt` seconds.
    pub fn update(&mut self, dt: f32) {
        if self.value > self.resting_level {
            self.value = (self.value - self.decay_rate * dt).max(self.resting_level);
        } else if self.value < self.resting_level {
            self.value = (self.value + self.decay_rate * dt).min(self.resting_level);
        }
    }
}
/// Collection of named emotions for one agent.
#[derive(Default)]
pub struct EmotionModel {
    /// Stored emotions.
    emotions: Vec<Emotion>,
}
impl EmotionModel {
    /// Create an empty emotion model.
    pub fn new() -> Self {
        Self::default()
    }
    /// Add or replace an emotion by name.
    pub fn add(&mut self, emotion: Emotion) {
        if let Some(e) = self.emotions.iter_mut().find(|e| e.name == emotion.name) {
            *e = emotion;
        } else {
            self.emotions.push(emotion);
        }
    }
    /// Return the current value for `name`, or 0.0 if missing.
    pub fn get(&self, name: &str) -> f32 {
        self.emotions
            .iter()
            .find(|e| e.name == name)
            .map(|e| e.value)
            .unwrap_or(0.0)
    }
    /// Increase the value of the named emotion when present.
    pub fn trigger(&mut self, name: &str, amount: f32) {
        if let Some(e) = self.emotions.iter_mut().find(|e| e.name == name) {
            e.trigger(amount);
        }
    }
    /// Set the value of the named emotion when present.
    pub fn set(&mut self, name: &str, value: f32) {
        if let Some(e) = self.emotions.iter_mut().find(|e| e.name == name) {
            e.set(value);
        }
    }
    /// Advance all emotions toward their resting levels.
    pub fn update(&mut self, dt: f32) {
        for e in &mut self.emotions {
            e.update(dt);
        }
    }
    /// Return the name of the highest active emotion, or `None` when none are active.
    pub fn dominant(&self) -> Option<&str> {
        self.emotions
            .iter()
            .filter(|e| e.is_active())
            .max_by(|a, b| a.value.partial_cmp(&b.value).unwrap())
            .map(|e| e.name.as_str())
    }
    /// Return `true` when the named emotion exists and is active.
    pub fn is_active(&self, name: &str) -> bool {
        self.emotions
            .iter()
            .find(|e| e.name == name)
            .map(|e| e.is_active())
            .unwrap_or(false)
    }
    /// Return the names of all active emotions.
    pub fn active_names(&self) -> Vec<&str> {
        self.emotions
            .iter()
            .filter(|e| e.is_active())
            .map(|e| e.name.as_str())
            .collect()
    }
    /// Return the number of tracked emotions.
    pub fn count(&self) -> usize {
        self.emotions.len()
    }
    /// Reset all emotions to their resting levels.
    pub fn reset(&mut self) {
        for e in &mut self.emotions {
            e.value = e.resting_level;
        }
    }
}
