//! Scope: perception model for stimuli storage, sensing, and awareness updates.
//! This file defines stimulus channels, world registry, sensor limits, detection tests, and awareness accumulation.
//! It owns stimulus lifecycle and sensory filtering used by reaction logic in behavior and state machines.
use std::collections::HashMap;

// ---- Type: StimulusType ----

/// The sensory channel of a [`Stimulus`].
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum StimulusType {
    /// Detected via line-of-sight cone; requires sensor facing direction.
    Visual,
    /// Detected in all directions within `hearing_range`; ignores facing.
    Auditory,
    /// Game-defined custom sense type identified by a label string.
    Custom(String),
}

impl StimulusType {
    /// Parses a string into a `StimulusType`.
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Self {
        match s {
            "visual" => Self::Visual,
            "auditory" => Self::Auditory,
            other => Self::Custom(other.to_string()),
        }
    }

    /// Returns the canonical string name of this stimulus type.
    pub fn as_str(&self) -> String {
        match self {
            Self::Visual => "visual".to_string(),
            Self::Auditory => "auditory".to_string(),
            Self::Custom(s) => s.clone(),
        }
    }
}

// ---- Type: Stimulus ----

/// A world-space sensory event that agents can detect.
pub struct Stimulus {
    /// Unique ID assigned by the owning `StimulusWorld`.
    pub id: u64,
    /// Sensory channel.
    pub stimulus_type: StimulusType,
    /// World-space position.
    pub position: (f32, f32),
    /// Current intensity in `[0.0, 1.0]`. Decremented by `decay_rate * dt` each frame.
    pub intensity: f32,
    /// Maximum detection radius in world units.
    pub radius: f32,
    /// Intensity lost per second. `0.0` = permanent (manually removed).
    pub decay_rate: f32,
    /// Optional name of the agent or entity that emitted this stimulus.
    pub source_name: Option<String>,
    /// Arbitrary game-defined label (e.g. `"gunshot"`, `"footstep"`).
    pub tag: Option<String>,
}

// ---- Type: DetectedStimulus ----

/// Result record produced when a sensor successfully detects a stimulus.
pub struct DetectedStimulus {
    /// ID of the originating stimulus in the `StimulusWorld`.
    pub stimulus_id: u64,
    /// Sensory channel used to detect this stimulus.
    pub stimulus_type: StimulusType,
    /// World-space position of the stimulus.
    pub position: (f32, f32),
    /// Intensity at the moment of detection.
    pub intensity: f32,
    /// Distance from the senso's position to the stimulus.
    pub distance: f32,
    /// Source agent/entity name if provided.
    pub source_name: Option<String>,
    /// Arbitrary game tag if provided.
    pub tag: Option<String>,
}

// ---- Type: StimulusWorld ----

/// Scene-level registry of active sensory stimuli.
pub struct StimulusWorld {
    stimuli: Vec<Stimulus>,
    next_id: u64,
}

impl StimulusWorld {
    /// Creates a new empty stimulus world.
    pub fn new() -> Self {
        Self {
            stimuli: Vec::new(),
            next_id: 0,
        }
    }

    /// Registers a new stimulus in the world. Returns its assigned ID.
    pub fn add(&mut self, stimulus: Stimulus) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        let mut s = stimulus;
        s.id = id;
        self.stimuli.push(s);
        id
    }

    /// Convenience method: emits a visual stimulus.
    pub fn add_visual(
        &mut self,
        x: f32,
        y: f32,
        intensity: f32,
        radius: f32,
        tag: Option<String>,
    ) -> u64 {
        self.add(Stimulus {
            id: 0,
            stimulus_type: StimulusType::Visual,
            position: (x, y),
            intensity,
            radius,
            decay_rate: 0.0,
            source_name: None,
            tag,
        })
    }

    /// Convenience method: emits an auditory stimulus.
    pub fn add_auditory(
        &mut self,
        x: f32,
        y: f32,
        intensity: f32,
        radius: f32,
        decay_rate: f32,
        tag: Option<String>,
    ) -> u64 {
        self.add(Stimulus {
            id: 0,
            stimulus_type: StimulusType::Auditory,
            position: (x, y),
            intensity,
            radius,
            decay_rate,
            source_name: None,
            tag,
        })
    }

    /// Convenience method: emits a custom-type stimulus.
    #[allow(clippy::too_many_arguments)]
    pub fn add_custom(
        &mut self,
        sense_type: &str,
        x: f32,
        y: f32,
        intensity: f32,
        radius: f32,
        decay_rate: f32,
        tag: Option<String>,
    ) -> u64 {
        self.add(Stimulus {
            id: 0,
            stimulus_type: StimulusType::Custom(sense_type.to_string()),
            position: (x, y),
            intensity,
            radius,
            decay_rate,
            source_name: None,
            tag,
        })
    }

    /// Removes a stimulus by ID. Returns `true` if it was found and removed.
    pub fn remove(&mut self, id: u64) -> bool {
        let before = self.stimuli.len();
        self.stimuli.retain(|s| s.id != id);
        self.stimuli.len() < before
    }

    /// Decays all stimuli by `dt` and removes those whose intensity has dropped
    pub fn update(&mut self, dt: f32) {
        for s in &mut self.stimuli {
            if s.decay_rate > 0.0 {
                s.intensity -= s.decay_rate * dt;
            }
        }
        self.stimuli.retain(|s| s.intensity > 0.0);
    }

    /// Returns a reference to all currently active stimuli.
    pub fn stimuli(&self) -> &[Stimulus] {
        &self.stimuli
    }

    /// Returns the number of active stimuli.
    pub fn count(&self) -> usize {
        self.stimuli.len()
    }

    /// Removes all stimuli immediately.
    pub fn clear(&mut self) {
        self.stimuli.clear();
    }
}

impl Default for StimulusWorld {
    fn default() -> Self {
        Self::new()
    }
}

// ---- Type: Sensor ----

/// Agent-level sensing configuration and awareness state.
pub struct Sensor {
    /// Sight range in world units.
    pub sight_range: f32,
    /// Full cone angle in degrees (180 = quarter-circle each side; 360 = omnidirectional).
    pub sight_angle: f32,
    /// Hearing range in world units.
    pub hearing_range: f32,
    /// Current facing direction in radians (0 = right, /2 = up).
    pub facing: f32,
    /// Current awareness level in `[0.0, 1.0]`.
    pub awareness: f32,
    /// Awareness rise per second per detected stimulus count (not multiplied by count).
    pub awareness_rise: f32,
    /// Awareness decay per second when no stimuli are detected.
    pub awareness_decay: f32,
    /// Awareness threshold in `[0.0, 1.0]` above which the sensor is considered alerted.
    pub alert_threshold: f32,
    /// Per-custom-sense detection ranges. Key = type label, value = range.
    pub custom_ranges: HashMap<String, f32>,
}

impl Sensor {
    /// Creates a sensor with default parameters suitable for a typical guard agent.
    pub fn new() -> Self {
        Self {
            sight_range: 200.0,
            sight_angle: 120.0,
            hearing_range: 100.0,
            facing: 0.0,
            awareness: 0.0,
            awareness_rise: 0.5,
            awareness_decay: 0.3,
            alert_threshold: 0.8,
            custom_ranges: HashMap::new(),
        }
    }

    /// Returns `true` if a given world-space target position is inside this
    pub fn can_see(&self, sensor_pos: (f32, f32), target_pos: (f32, f32)) -> bool {
        let dx = target_pos.0 - sensor_pos.0;
        let dy = target_pos.1 - sensor_pos.1;
        let dist_sq = dx * dx + dy * dy;
        if dist_sq > self.sight_range * self.sight_range {
            return false;
        }
        if self.sight_angle >= 360.0 {
            return true;
        }
        let angle_to = dy.atan2(dx);
        let half_cone = (self.sight_angle * 0.5).to_radians();
        let diff = angle_diff(angle_to, self.facing);
        diff.abs() <= half_cone
    }

    /// Returns `true` if an auditory stimulus can be heard from `sensor_pos`.
    pub fn can_hear(&self, sensor_pos: (f32, f32), stimulus: &Stimulus) -> bool {
        if stimulus.stimulus_type != StimulusType::Auditory {
            return false;
        }
        let dx = stimulus.position.0 - sensor_pos.0;
        let dy = stimulus.position.1 - sensor_pos.1;
        let dist = (dx * dx + dy * dy).sqrt();
        dist <= self.hearing_range.min(stimulus.radius)
    }

    /// Queries the `StimulusWorld` for all stimuli detectable from `sensor_pos`
    pub fn detect(&self, sensor_pos: (f32, f32), world: &StimulusWorld) -> Vec<DetectedStimulus> {
        let mut out = Vec::new();
        for stim in world.stimuli() {
            let dx = stim.position.0 - sensor_pos.0;
            let dy = stim.position.1 - sensor_pos.1;
            let distance = (dx * dx + dy * dy).sqrt();
            let detected = match &stim.stimulus_type {
                StimulusType::Visual => self.can_see(sensor_pos, stim.position),
                StimulusType::Auditory => self.can_hear(sensor_pos, stim),
                StimulusType::Custom(label) => {
                    if let Some(&range) = self.custom_ranges.get(label) {
                        distance <= range.min(stim.radius)
                    } else {
                        false
                    }
                }
            };
            if detected {
                out.push(DetectedStimulus {
                    stimulus_id: stim.id,
                    stimulus_type: stim.stimulus_type.clone(),
                    position: stim.position,
                    intensity: stim.intensity,
                    distance,
                    source_name: stim.source_name.clone(),
                    tag: stim.tag.clone(),
                });
            }
        }
        out
    }

    /// Updates the awareness level based on the number of stimuli detected this frame.
    pub fn update_awareness(&mut self, detected_count: usize, dt: f32) {
        if detected_count > 0 {
            self.awareness = (self.awareness + self.awareness_rise * dt).min(1.0);
        } else {
            self.awareness = (self.awareness - self.awareness_decay * dt).max(0.0);
        }
    }

    /// Returns `true` when awareness has reached or exceeded `alert_threshold`.
    pub fn is_alert(&self) -> bool {
        self.awareness >= self.alert_threshold
    }

    /// Registers a detection range for a custom sense channel.
    pub fn add_custom_range(&mut self, type_label: &str, range: f32) {
        self.custom_ranges.insert(type_label.to_string(), range);
    }
}

impl Default for Sensor {
    fn default() -> Self {
        Self::new()
    }
}

// ---- Type: Helper ----

/// Returns the signed angular difference between `a` and `b` in radians,
fn angle_diff(a: f32, b: f32) -> f32 {
    let mut diff = a - b;
    while diff > std::f32::consts::PI {
        diff -= 2.0 * std::f32::consts::PI;
    }
    while diff <= -std::f32::consts::PI {
        diff += 2.0 * std::f32::consts::PI;
    }
    diff
}

