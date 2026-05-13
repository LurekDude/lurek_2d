//! Scope: pacing director that maps gameplay pressure to AI phase decisions.
//! This file defines tension metrics, phase thresholds, and runtime update rules for adaptive encounter control.
//! It owns director state transitions and emitted pacing signals consumed by spawn, behavior, and event systems.
// ---- Type: DirectorPhase ----

/// Current pacing phase of the AI Director state machine.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DirectorPhase {
    /// Tension is rising; enemies begin massing.
    BuildUp,
    /// Tension at maximum; peak aggression spawn rates.
    Peak,
    /// Post-peak high-tension window before relief.
    Sustain,
    /// Tension fell below relief threshold; loot/safety period.
    Relief,
}

impl DirectorPhase {
    /// Returns the canonical string label for this phase.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::BuildUp => "build_up",
            Self::Peak => "peak",
            Self::Sustain => "sustain",
            Self::Relief => "relief",
        }
    }
}

// ---- Type: DirectorConfig ----

/// Configuration thresholds and decay rates for [`AIDirector`].
pub struct DirectorConfig {
    /// Tension lost per second when no events arrive.
    pub tension_decay_rate: f32,
    /// Tension level `[0, 1]` at which the director enters `Peak` phase.
    pub peak_threshold: f32,
    /// Tension level `[0, 1]` below which relief is triggered after sustain.
    pub relief_threshold: f32,
    /// How many seconds the director spends in `Sustain` before allowing relief.
    pub sustain_duration: f32,
    /// Maximum tension delta added from a single event, regardless of pushed intensity.
    pub max_tension_per_event: f32,
    /// Multiplier applied to game's spawn rate during peak/sustain phases.
    pub peak_spawn_factor: f32,
    /// Multiplier applied to game's loot rate during relief phase.
    pub relief_loot_factor: f32,
}

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

// ---- Type: AIDirector ----

/// Dynamic pacing and difficulty director.
pub struct AIDirector {
    /// Pacing configuration.
    pub config: DirectorConfig,
    tension: f32,
    phase: DirectorPhase,
    sustain_timer: f32,
    /// Total elapsed time in seconds since director was created.
    elapsed: f32,
    /// Total number of events pushed since creation.
    total_events: u32,
}

impl AIDirector {
    /// Creates a new director with default configuration starting in `Relief` phase.
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

    /// Creates a director with a custom configuration.
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

    /// Returns the current tension level in `[0.0, 1.0]`.
    pub fn tension(&self) -> f32 {
        self.tension
    }

    /// Returns the current pacing phase.
    pub fn phase(&self) -> DirectorPhase {
        self.phase
    }

    /// Returns the current phase as a string label.
    pub fn phase_str(&self) -> &'static str {
        self.phase.as_str()
    }

    /// Returns the total elapsed time in seconds.
    pub fn elapsed(&self) -> f32 {
        self.elapsed
    }

    /// Returns the total number of events pushed to this director.
    pub fn total_events(&self) -> u32 {
        self.total_events
    }

    /// Pushes a stress event that raises tension. `intensity` is clamped to `max_tension_per_event` before being added to the current tension level.
    pub fn push_event(&mut self, intensity: f32) {
        let clamped = intensity.clamp(0.0, self.config.max_tension_per_event);
        self.tension = (self.tension + clamped).clamp(0.0, 1.0);
        self.total_events += 1;
    }

    /// Advances the director by `dt` seconds. Decays tension, transitions between pacing phases, and advances the sustain timer.
    pub fn update(&mut self, dt: f32) {
        self.elapsed += dt;

        // Decay tension
        if self.phase != DirectorPhase::Peak && self.phase != DirectorPhase::Sustain {
            self.tension = (self.tension - self.config.tension_decay_rate * dt).max(0.0);
        } else {
            // Slower decay during high phases
            self.tension = (self.tension - self.config.tension_decay_rate * 0.3 * dt).max(0.0);
        }

        // Phase transitions
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

    /// Returns a spawn rate multiplier for game systems.
    pub fn spawn_rate_factor(&self) -> f32 {
        match self.phase {
            DirectorPhase::BuildUp => {
                1.0 + self.tension * (self.config.peak_spawn_factor - 1.0) * 0.5
            }
            DirectorPhase::Peak | DirectorPhase::Sustain => self.config.peak_spawn_factor,
            DirectorPhase::Relief => 0.25,
        }
    }

    /// Returns a loot drop multiplier for game systems (highest during relief).
    pub fn loot_factor(&self) -> f32 {
        match self.phase {
            DirectorPhase::Relief => self.config.relief_loot_factor,
            DirectorPhase::BuildUp => 1.0,
            DirectorPhase::Peak | DirectorPhase::Sustain => 0.5,
        }
    }

    /// Returns an ambient intensity value `[0.0, 1.0]` for music and atmosphere.
    pub fn ambient_intensity(&self) -> f32 {
        match self.phase {
            DirectorPhase::Peak => (self.tension * 0.5 + 0.5).clamp(0.0, 1.0),
            DirectorPhase::Sustain => 0.6f32.max(self.tension),
            DirectorPhase::BuildUp => self.tension,
            DirectorPhase::Relief => (self.tension * 0.5).max(0.1),
        }
    }

    /// Manually overrides the tension to a specific value (for scripted sequences).
    pub fn set_tension(&mut self, value: f32) {
        self.tension = value.clamp(0.0, 1.0);
    }

    /// Resets tension to zero and transitions to Relief phase.
    pub fn reset(&mut self) {
        self.tension = 0.0;
        self.phase = DirectorPhase::Relief;
        self.sustain_timer = 0.0;
    }
}

impl Default for AIDirector {
    fn default() -> Self {
        Self::new()
    }
}
