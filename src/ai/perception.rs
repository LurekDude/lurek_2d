
use std::collections::HashMap;
/// Stimulus classification used by the sensor world.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum StimulusType {
    /// Visual stimulus.
    Visual,
    /// Audible stimulus.
    Auditory,
    /// Custom stimulus label.
    Custom(String),
}
impl StimulusType {
    #[allow(clippy::should_implement_trait)]
    /// Parse a stimulus type name; unknown strings become `Custom`.
    pub fn from_str(s: &str) -> Self {
        match s {
            "visual" => Self::Visual,
            "auditory" => Self::Auditory,
            other => Self::Custom(other.to_string()),
        }
    }
    /// Return a display string for the stimulus type.
    pub fn as_str(&self) -> String {
        match self {
            Self::Visual => "visual".to_string(),
            Self::Auditory => "auditory".to_string(),
            Self::Custom(s) => s.clone(),
        }
    }
}
/// Source stimulus stored in the world.
pub struct Stimulus {
    /// Stable world id.
    pub id: u64,
    /// Stimulus kind.
    pub stimulus_type: StimulusType,
    /// World position.
    pub position: (f32, f32),
    /// Intensity in `[0, 1]`.
    pub intensity: f32,
    /// Effective range.
    pub radius: f32,
    /// Intensity decay per second.
    pub decay_rate: f32,
    /// Optional source name.
    pub source_name: Option<String>,
    /// Optional gameplay tag.
    pub tag: Option<String>,
}
/// Stimulus result returned by `Sensor::detect`.
pub struct DetectedStimulus {
    /// Id of the matched source stimulus.
    pub stimulus_id: u64,
    /// Matched stimulus type.
    pub stimulus_type: StimulusType,
    /// Source position.
    pub position: (f32, f32),
    /// Source intensity.
    pub intensity: f32,
    /// Distance from the sensor.
    pub distance: f32,
    /// Optional source name.
    pub source_name: Option<String>,
    /// Optional gameplay tag.
    pub tag: Option<String>,
}
/// Container for all stimuli available to sensors.
pub struct StimulusWorld {
    /// Stored stimuli.
    stimuli: Vec<Stimulus>,
    /// Next allocated stimulus id.
    next_id: u64,
}
impl StimulusWorld {
    /// Create an empty stimulus world.
    pub fn new() -> Self {
        Self {
            stimuli: Vec::new(),
            next_id: 0,
        }
    }
    /// Insert a stimulus and return its assigned id.
    pub fn add(&mut self, stimulus: Stimulus) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        let mut s = stimulus;
        s.id = id;
        self.stimuli.push(s);
        id
    }
    /// Add a visual stimulus.
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
    /// Add an auditory stimulus.
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
    #[allow(clippy::too_many_arguments)]
    /// Add a custom stimulus type.
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
    /// Remove a stimulus by id and return `true` when one was removed.
    pub fn remove(&mut self, id: u64) -> bool {
        let before = self.stimuli.len();
        self.stimuli.retain(|s| s.id != id);
        self.stimuli.len() < before
    }
    /// Decay all stimuli and drop exhausted entries.
    pub fn update(&mut self, dt: f32) {
        for s in &mut self.stimuli {
            if s.decay_rate > 0.0 {
                s.intensity -= s.decay_rate * dt;
            }
        }
        self.stimuli.retain(|s| s.intensity > 0.0);
    }
    /// Return the active stimuli slice.
    pub fn stimuli(&self) -> &[Stimulus] {
        &self.stimuli
    }
    /// Return the number of active stimuli.
    pub fn count(&self) -> usize {
        self.stimuli.len()
    }
    /// Remove all stimuli.
    pub fn clear(&mut self) {
        self.stimuli.clear();
    }
}
/// `Default` delegates to `StimulusWorld::new`.
/// `Default` delegates to `StimulusWorld::new`.
impl Default for StimulusWorld {
    fn default() -> Self {
        Self::new()
    }
}
/// Perception configuration and transient awareness state.
pub struct Sensor {
    /// Sight radius.
    pub sight_range: f32,
    /// Sight cone width in degrees.
    pub sight_angle: f32,
    /// Hearing radius.
    pub hearing_range: f32,
    /// Facing angle in radians.
    pub facing: f32,
    /// Current awareness in `[0, 1]`.
    pub awareness: f32,
    /// Awareness rise rate.
    pub awareness_rise: f32,
    /// Awareness decay rate.
    pub awareness_decay: f32,
    /// Threshold used for alert state.
    pub alert_threshold: f32,
    /// Custom detection ranges per label.
    pub custom_ranges: HashMap<String, f32>,
}
impl Sensor {
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
    pub fn can_hear(&self, sensor_pos: (f32, f32), stimulus: &Stimulus) -> bool {
        if stimulus.stimulus_type != StimulusType::Auditory {
            return false;
        }
        let dx = stimulus.position.0 - sensor_pos.0;
        let dy = stimulus.position.1 - sensor_pos.1;
        let dist = (dx * dx + dy * dy).sqrt();
        dist <= self.hearing_range.min(stimulus.radius)
    }
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
    pub fn update_awareness(&mut self, detected_count: usize, dt: f32) {
        if detected_count > 0 {
            self.awareness = (self.awareness + self.awareness_rise * dt).min(1.0);
        } else {
            self.awareness = (self.awareness - self.awareness_decay * dt).max(0.0);
        }
    }
    pub fn is_alert(&self) -> bool {
        self.awareness >= self.alert_threshold
    }
    pub fn add_custom_range(&mut self, type_label: &str, range: f32) {
        self.custom_ranges.insert(type_label.to_string(), range);
    }
}
/// `Default` delegates to `Sensor::new`.
impl Default for Sensor {
    fn default() -> Self {
        Self::new()
    }
}
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
