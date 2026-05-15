//! - Weather particle simulation types and state management.
//! - Supports rain, snow, hail, dust, leaves, ash, and pollen behaviors.
//! - Tracks particle pool, wind parameters, and internal PRNG.

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
/// Enumerates supported weather particle behaviors.
pub enum WeatherType {
    /// Disables weather particle spawning.
    None,
    /// Fast downward streaks representing rain.
    Rain,
    /// Slow drifting flakes representing snow.
    Snow,
    /// Heavy fast-falling hail particles.
    Hail,
    /// Light dusty particles moving close to the ground.
    Dust,
    /// Larger drifting leaf particles.
    Leaves,
    /// Slow floating ash particles.
    Ash,
    /// Very light floating pollen particles.
    Pollen,
}
impl WeatherType {
    /// Resolves a lowercase weather type name into the matching enum entry.
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
    /// Returns the lowercase canonical name for this weather type.
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
#[derive(Debug, Clone)]
/// Stores the current position, velocity, and visual size of one weather particle.
pub struct WeatherParticle {
    /// Horizontal screen position.
    pub x: f32,
    /// Vertical screen position.
    pub y: f32,
    /// Horizontal particle velocity before wind is applied.
    pub vx: f32,
    /// Vertical particle velocity before wind is applied.
    pub vy: f32,
    /// Render size scalar for the particle.
    pub size: f32,
    /// Opacity multiplier for the particle.
    pub alpha: f32,
}
#[derive(Debug, Clone)]
/// Tracks weather mode, particle pool, wind, and random generation state.
pub struct WeatherState {
    /// Enables weather simulation and rendering.
    pub enabled: bool,
    /// Active weather particle behavior.
    pub weather_type: WeatherType,
    /// Spawn density multiplier for particle simulation.
    pub intensity: f32,
    /// Wind direction in radians.
    pub wind_direction: f32,
    /// Wind speed added to particle motion.
    pub wind_speed: f32,
    /// Live weather particles currently on screen.
    pub particles: Vec<WeatherParticle>,
    /// Accumulator used to schedule the next particle spawn.
    pub spawn_timer: f32,
    /// Internal PRNG state for particle placement and variation.
    pub rng_state: u64,
}
impl WeatherState {
    /// Advances the internal PRNG and returns a sample in the `[0, 1)` range.
    pub fn next_unit(&mut self) -> f32 {
        let mut x = self.rng_state;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        self.rng_state = x;
        let out = x.wrapping_mul(0x2545_F491_4F6C_DD1D);
        ((out >> 40) as u32) as f32 / (1u32 << 24) as f32
    }
}
/// Provide default disabled weather state with seeded PRNG.
impl Default for WeatherState {
    /// Build the default disabled weather simulation state.
    fn default() -> Self {
        Self {
            enabled: false,
            weather_type: WeatherType::None,
            intensity: 0.5,
            wind_direction: 0.0,
            wind_speed: 0.0,
            particles: Vec::new(),
            spawn_timer: 0.0,
            rng_state: 0x9E37_79B9_7F4A_7C15,
        }
    }
}
