//! affective state model with decay and event-driven modulation.

// ---- Type: Emotion ----

/// A single named affective dimension.
pub struct Emotion {
    /// Unique name of this emotion (e.g. `"anger"`, `"fear"`, `"joy"`).
    pub name: String,
    /// Current arousal level in `[0.0, 1.0]`.
    pub value: f32,
    /// Resting/baseline level - the value decays toward this, not toward zero.
    pub resting_level: f32,
    /// Arousal lost per second decaying toward `resting_level`.
    pub decay_rate: f32,
    /// Minimum value for this emotion to be considered "active" for `dominant()`.
    pub min_visible: f32,
}

// ---- Implementation: Emotion ----

impl Emotion {
    /// Create a new emotion starting at its resting level.
    pub fn new(name: &str, resting_level: f32, decay_rate: f32, min_visible: f32) -> Self {
        Self {
            name: name.to_string(),
            value: resting_level,
            resting_level: resting_level.clamp(0.0, 1.0),
            decay_rate,
            min_visible: min_visible.clamp(0.0, 1.0),
        }
    }

    /// Return `true` when this emotion's value is at or above `min_visible`.
    pub fn is_active(&self) -> bool {
        self.value >= self.min_visible
    }

    /// Bumps the emotion up by `amount`, clamped to `[0.0, 1.0]`.
    pub fn trigger(&mut self, amount: f32) {
        self.value = (self.value + amount).clamp(0.0, 1.0);
    }

    /// Set the emotion to an exact value, clamped to `[0.0, 1.0]`.
    pub fn set(&mut self, value: f32) {
        self.value = value.clamp(0.0, 1.0);
    }

    /// Advances decay by `dt` seconds, moving toward `resting_level`.
    pub fn update(&mut self, dt: f32) {
        if self.value > self.resting_level {
            self.value = (self.value - self.decay_rate * dt).max(self.resting_level);
        } else if self.value < self.resting_level {
            self.value = (self.value + self.decay_rate * dt).min(self.resting_level);
        }
    }
}

// ---- Type: EmotionModel ----

/// Affective state model for an AI agent.
#[derive(Default)]
pub struct EmotionModel {
    emotions: Vec<Emotion>,
}

// ---- Implementation: EmotionModel ----

impl EmotionModel {
    /// Create an empty emotion model.
    pub fn new() -> Self {
        Self::default()
    }

    /// Add or replaces an emotion by name.
    pub fn add(&mut self, emotion: Emotion) {
        if let Some(e) = self.emotions.iter_mut().find(|e| e.name == emotion.name) {
            *e = emotion;
        } else {
            self.emotions.push(emotion);
        }
    }

    /// Return the current value of a named emotion, or `0.0` if not found.
    pub fn get(&self, name: &str) -> f32 {
        self.emotions
            .iter()
            .find(|e| e.name == name)
            .map(|e| e.value)
            .unwrap_or(0.0)
    }

    /// Triggers a named emotion by adding `amount` to its current value.
    pub fn trigger(&mut self, name: &str, amount: f32) {
        if let Some(e) = self.emotions.iter_mut().find(|e| e.name == name) {
            e.trigger(amount);
        }
    }

    /// Set a named emotion to an exact value. Silently ignores unknown emotions.
    pub fn set(&mut self, name: &str, value: f32) {
        if let Some(e) = self.emotions.iter_mut().find(|e| e.name == name) {
            e.set(value);
        }
    }

    /// Advances all emotions' decay by `dt` seconds.
    pub fn update(&mut self, dt: f32) {
        for e in &mut self.emotions {
            e.update(dt);
        }
    }

    /// Return the name of the dominant (highest active) emotion, or `None` if no emotion is currently active.
    pub fn dominant(&self) -> Option<&str> {
        self.emotions
            .iter()
            .filter(|e| e.is_active())
            .max_by(|a, b| a.value.partial_cmp(&b.value).unwrap())
            .map(|e| e.name.as_str())
    }

    /// Return `true` when a named emotion is at or above its `min_visible` threshold.
    pub fn is_active(&self, name: &str) -> bool {
        self.emotions
            .iter()
            .find(|e| e.name == name)
            .map(|e| e.is_active())
            .unwrap_or(false)
    }

    /// Return the names of all emotions currently active (above `min_visible`).
    pub fn active_names(&self) -> Vec<&str> {
        self.emotions
            .iter()
            .filter(|e| e.is_active())
            .map(|e| e.name.as_str())
            .collect()
    }

    /// Return the number of emotions registered in this model.
    pub fn count(&self) -> usize {
        self.emotions.len()
    }

    /// Resets all emotions to their resting levels.
    pub fn reset(&mut self) {
        for e in &mut self.emotions {
            e.value = e.resting_level;
        }
    }
}
