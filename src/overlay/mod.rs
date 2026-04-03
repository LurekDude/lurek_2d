//! Composable per-frame screen-effect overlay (Tier 2).
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
//! - **Shake** — a screen-space jitter that decays over its duration using
//!   an xorshift PRNG for deterministic-ish movement.
//! - **Fade** — smooth alpha transition between two screen-fill colour states.
//! - **Cloud shadows** — a scrolling set of soft shadow blobs.
//! - **Fog** — a uniform atmospheric colour overlay with configurable density.
//! - **Heat haze** — distortion intensity for shimmer effects.
//! - **Vignette** — screen-edge darkening controlled by a strength value.
//! - **Film grain** — randomised per-frame noise overlay.
//! - **Lightning** — a hard white flash used as a single-frame lightning bolt.
//!
//! This is a **pure CPU data-model module** — it has no GPU dependencies.
//! GPU rendering of effects is handled in `lua_api`. Extracted from
//! `graphics` so that other modules can reference overlay types without
//! pulling in the full rendering pipeline.
//!
//! Call `Overlay::update(dt)` every frame to advance all active subsystems,
//! then read state fields (or use the Lua API methods) to drive GPU draw calls.

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
