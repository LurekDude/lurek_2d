/// Weather particle types supported by the overlay system.
///
/// Each variant changes the visual character of spawned particles: their
/// fall speed, size, and opacity are all tuned per type inside
/// `Overlay::spawn_particle`. The `None` variant disables the spawner
/// without clearing existing particles — call `Overlay::clear` to purge
/// everything at once.
///
/// # Variants
/// - `None` — No weather active; spawner is disabled.
/// - `Rain` — Fast, narrow, semi-transparent streaks.
/// - `Snow` — Slow, large, high-opacity dots with gentle drift.
/// - `Hail` — Very fast, opaque, medium-sized pellets.
/// - `Dust` — Very slow, small, low-opacity motes.
/// - `Leaves` — Medium speed, large, high-opacity irregular blobs.
/// - `Ash` — Slow, small, medium-opacity flakes.
/// - `Pollen` — Extremely slow, tiny, low-opacity specks.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum WeatherType {
    /// No weather active.
    None,
    /// Rain particles.
    Rain,
    /// Snow particles.
    Snow,
    /// Hail particles.
    Hail,
    /// Dust/sand particles.
    Dust,
    /// Falling leaves.
    Leaves,
    /// Volcanic ash particles.
    Ash,
    /// Pollen/floating particles.
    Pollen,
}

impl WeatherType {
    /// Parses a string name into a weather type.
    ///
    /// # Parameters
    /// - `name` — `&str` — One of `"none"`, `"rain"`, `"snow"`, `"hail"`,
    ///   `"dust"`, `"leaves"`, `"ash"`, `"pollen"`.
    ///
    /// # Returns
    /// `Option<Self>` — `None` if the name is unrecognised.
    pub fn from_name(name: &str) -> Option<Self> {
        match name {
            "none" => Some(Self::None),
            "rain" => Some(Self::Rain),
            "snow" => Some(Self::Snow),
            "hail" => Some(Self::Hail),
            "dust" => Some(Self::Dust),
            "leaves" => Some(Self::Leaves),
            "ash" => Some(Self::Ash),
            "pollen" => Some(Self::Pollen),
            _ => None,
        }
    }

    /// Returns the string name of this weather type.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn name(&self) -> &'static str {
        match self {
            Self::None => "none",
            Self::Rain => "rain",
            Self::Snow => "snow",
            Self::Hail => "hail",
            Self::Dust => "dust",
            Self::Leaves => "leaves",
            Self::Ash => "ash",
            Self::Pollen => "pollen",
        }
    }
}

/// A single weather particle in the overlay's weather system.
///
/// Particles are created by `Overlay::spawn_particle` and stored in
/// `WeatherState::particles`. Each frame `Overlay::update_weather` moves
/// every particle by its velocity plus the current wind contribution, then
/// removes any that have scrolled off the screen bounds. Particles are
/// never explicitly recycled — they are simply dropped and re-spawned at
/// the top edge.
///
/// # Fields
/// - `x` — `f32` — Horizontal position in screen pixels.
/// - `y` — `f32` — Vertical position in screen pixels.
/// - `vx` — `f32` — Horizontal velocity in pixels per second (base, before wind).
/// - `vy` — `f32` — Vertical velocity in pixels per second (base, before wind).
/// - `size` — `f32` — Particle radius/size in pixels.
/// - `alpha` — `f32` — Particle opacity (0.0–1.0).
#[derive(Debug, Clone)]
pub struct WeatherParticle {
    /// Horizontal position.
    pub x: f32,
    /// Vertical position.
    pub y: f32,
    /// Horizontal velocity.
    pub vx: f32,
    /// Vertical velocity.
    pub vy: f32,
    /// Particle size.
    pub size: f32,
    /// Particle opacity (0.0–1.0).
    pub alpha: f32,
}

/// Weather subsystem state.
///
/// Controls the full particle simulation for the current weather. The
/// `intensity` value (0.0–1.0) scales both the maximum live particle count
/// (up to 200) and the spawn rate. `spawn_timer` is an internal accumulator
/// that should not be written to from outside the module — it is managed
/// entirely by `Overlay::update_weather`. Wind affects all particles equally
/// by adding a global velocity offset each frame.
///
/// # Fields
/// - `enabled` — `bool` — Whether the weather spawner is active.
/// - `weather_type` — `WeatherType` — Determines particle appearance and base velocity.
/// - `intensity` — `f32` — Particle density (0.0–1.0); scales max count and spawn rate.
/// - `wind_direction` — `f32` — Wind angle in radians; 0 = right, π/2 = down.
/// - `wind_speed` — `f32` — Wind speed in pixels per second.
/// - `particles` — `Vec<WeatherParticle>` — Currently live particles.
#[derive(Debug, Clone)]
pub struct WeatherState {
    /// Whether weather is active.
    pub enabled: bool,
    /// Current weather type.
    pub weather_type: WeatherType,
    /// Particle density/intensity (0.0–1.0).
    pub intensity: f32,
    /// Wind angle in radians.
    pub wind_direction: f32,
    /// Wind speed.
    pub wind_speed: f32,
    /// Active particles.
    pub particles: Vec<WeatherParticle>,
    /// Internal timer for particle spawning.
    pub spawn_timer: f32,
}

impl Default for WeatherState {
    fn default() -> Self {
        Self {
            enabled: false,
            weather_type: WeatherType::None,
            intensity: 0.5,
            wind_direction: 0.0,
            wind_speed: 0.0,
            particles: Vec::new(),
            spawn_timer: 0.0,
        }
    }
}
