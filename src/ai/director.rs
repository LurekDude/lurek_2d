//! AI director tension model controlling encounter pacing and spawn pressure.
//! Owns `DirectorPhase`, `DirectorConfig`, and `AIDirector`.
//! Does not own combat spawns; it only computes pacing scalars.
/// Director pacing phase.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DirectorPhase {
    /// Tension is rising toward a peak.
    BuildUp,
    /// Peak pressure phase.
    Peak,
    /// High pressure maintained after a peak.
    Sustain,
    /// Low pressure recovery phase.
    Relief,
}
impl DirectorPhase {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::BuildUp => "build_up",
            Self::Peak => "peak",
            Self::Sustain => "sustain",
            Self::Relief => "relief",
        }
    }
}
/// Tunable thresholds for the AI director.
pub struct DirectorConfig {
    /// Tension decay per second.
    pub tension_decay_rate: f32,
    /// Tension threshold that triggers a peak phase.
    pub peak_threshold: f32,
    /// Tension threshold below which recovery can begin.
    pub relief_threshold: f32,
    /// Minimum sustain time after a peak.
    pub sustain_duration: f32,
    /// Maximum tension added by one event.
    pub max_tension_per_event: f32,
    /// Spawn multiplier used during high pressure.
    pub peak_spawn_factor: f32,
    /// Loot multiplier used during relief.
    pub relief_loot_factor: f32,
}
/// `Default` provides the tuned pacing config used by `AIDirector::new`.
impl Default for DirectorConfig {
    fn default() -> Self {
        Self {
            tension_decay_rate: 0.05,
            peak_threshold: 0.8,
            relief_threshold: 0.3,
            sustain_duration: 15.0,
            max_tension_per_event: 0.25,
            peak_spawn_factor: 2.0,
            relief_loot_factor: 2.5,
        }
    }
}
/// Runtime director state used by pacing systems.
pub struct AIDirector {
    /// Active tuning values.
    pub config: DirectorConfig,
    /// Current tension in `[0, 1]`.
    tension: f32,
    /// Current pacing phase.
    phase: DirectorPhase,
    /// Time spent in sustain phase.
    sustain_timer: f32,
    /// Time since creation or last reset.
    elapsed: f32,
    /// Total number of submitted events.
    total_events: u32,
}
impl AIDirector {
    /// Create a director with default config.
    pub fn new() -> Self {
        Self {
            config: DirectorConfig::default(),
            tension: 0.0,
            phase: DirectorPhase::Relief,
            sustain_timer: 0.0,
            elapsed: 0.0,
            total_events: 0,
        }
    }
    /// Create a director with a custom config.
    pub fn with_config(config: DirectorConfig) -> Self {
        Self {
            config,
            tension: 0.0,
            phase: DirectorPhase::Relief,
            sustain_timer: 0.0,
            elapsed: 0.0,
            total_events: 0,
        }
    }
    /// Return the current tension.
    pub fn tension(&self) -> f32 {
        self.tension
    }
    /// Return the current phase.
    pub fn phase(&self) -> DirectorPhase {
        self.phase
    }
    /// Return the current phase as a string tag.
    pub fn phase_str(&self) -> &'static str {
        self.phase.as_str()
    }
    /// Return elapsed seconds.
    pub fn elapsed(&self) -> f32 {
        self.elapsed
    }
    /// Return total events received.
    pub fn total_events(&self) -> u32 {
        self.total_events
    }
    /// Add one event and clamp the resulting tension to `[0, 1]`.
    pub fn push_event(&mut self, intensity: f32) {
        let clamped = intensity.clamp(0.0, self.config.max_tension_per_event);
        self.tension = (self.tension + clamped).clamp(0.0, 1.0);
        self.total_events += 1;
    }
    /// Advance the director and update phase transitions.
    pub fn update(&mut self, dt: f32) {
        self.elapsed += dt;
        if self.phase != DirectorPhase::Peak && self.phase != DirectorPhase::Sustain {
            self.tension = (self.tension - self.config.tension_decay_rate * dt).max(0.0);
        } else {
            self.tension = (self.tension - self.config.tension_decay_rate * 0.3 * dt).max(0.0);
        }
        match self.phase {
            DirectorPhase::Relief | DirectorPhase::BuildUp => {
                if self.tension >= self.config.peak_threshold {
                    self.phase = DirectorPhase::Peak;
                    self.sustain_timer = 0.0;
                } else if self.tension > self.config.relief_threshold {
                    self.phase = DirectorPhase::BuildUp;
                }
            }
            DirectorPhase::Peak => {
                if self.tension < self.config.peak_threshold {
                    self.phase = DirectorPhase::Sustain;
                    self.sustain_timer = 0.0;
                }
            }
            DirectorPhase::Sustain => {
                self.sustain_timer += dt;
                if self.sustain_timer >= self.config.sustain_duration
                    && self.tension <= self.config.relief_threshold
                {
                    self.phase = DirectorPhase::Relief;
                }
            }
        }
    }
    /// Return the current spawn rate multiplier.
    pub fn spawn_rate_factor(&self) -> f32 {
        match self.phase {
            DirectorPhase::BuildUp => {
                1.0 + self.tension * (self.config.peak_spawn_factor - 1.0) * 0.5
            }
            DirectorPhase::Peak | DirectorPhase::Sustain => self.config.peak_spawn_factor,
            DirectorPhase::Relief => 0.25,
        }
    }
    /// Return the current loot multiplier.
    pub fn loot_factor(&self) -> f32 {
        match self.phase {
            DirectorPhase::Relief => self.config.relief_loot_factor,
            DirectorPhase::BuildUp => 1.0,
            DirectorPhase::Peak | DirectorPhase::Sustain => 0.5,
        }
    }
    /// Return the current ambient intensity scalar.
    pub fn ambient_intensity(&self) -> f32 {
        match self.phase {
            DirectorPhase::Peak => (self.tension * 0.5 + 0.5).clamp(0.0, 1.0),
            DirectorPhase::Sustain => 0.6f32.max(self.tension),
            DirectorPhase::BuildUp => self.tension,
            DirectorPhase::Relief => (self.tension * 0.5).max(0.1),
        }
    }
    /// Set tension directly and clamp it to `[0, 1]`.
    pub fn set_tension(&mut self, value: f32) {
        self.tension = value.clamp(0.0, 1.0);
    }
    /// Reset tension, phase, and timers to their initial state.
    pub fn reset(&mut self) {
        self.tension = 0.0;
        self.phase = DirectorPhase::Relief;
        self.sustain_timer = 0.0;
    }
}
/// `Default` delegates to `AIDirector::new`.
impl Default for AIDirector {
    fn default() -> Self {
        Self::new()
    }
}
