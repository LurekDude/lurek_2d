//! World-simulation screen overlays — `fx::screen` sub-namespace.
//!
//! Provides a rich set of full-screen atmospheric and one-shot screen effects
//! that a Lua script can layer over the rendered scene. Each subsystem is
//! independently enabled and parameterised:
//!
//! - **Weather** — rain, snow, hail, dust, leaves, ash, and pollen particles
//!   driven by intensity, wind direction, and wind speed.
//! - **Ambient** — tints the entire screen with a time-of-day colour that
//!   cycles through night → dawn → day → dusk automatically.
//! - **Flash** — a one-shot full-screen colour burst that fades out linearly.
//! - **Shake** — a screen-space jitter that decays over its duration.
//! - **Fade** — smooth alpha transition between two screen-fill colour states.
//! - **Cloud shadows**, **Fog**, **Heat haze**, **Vignette**, **Film grain**, **Lightning**.
//!
//! This is a **pure CPU data-model module** — it has no GPU dependencies.
//! GPU rendering of effects is handled in `lua_api`.

/// Ambient lighting state with time-of-day colour cycling.
pub mod ambient;
/// Atmospheric environment effects: clouds, fog, heat haze, vignette, film grain, lightning.
pub mod atmosphere;
/// One-shot screen effects: flash, shake, and fade.
pub mod effects;
/// Main Overlay struct combining all subsystems.
pub mod state;
/// Weather types, particles, and simulation state.
pub mod weather;

pub use ambient::AmbientState;
pub use atmosphere::{
    CloudState, FilmGrainState, FogState, HeatHazeState, LightningState, VignetteState,
};
pub use effects::{FadeState, FlashState, ShakeState};
pub use state::Overlay;
pub use weather::{WeatherParticle, WeatherState, WeatherType};
