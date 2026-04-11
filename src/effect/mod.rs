//! Composable visual effects layer — Tier 2 Engine Extension.
//!
//! The `fx` module provides two families of visual effects as pure CPU data models.
//! GPU application is handled in `lua_api`. All files are flat in this folder.
//!
//! ## Post-processing effects (image-space pipeline)
//!
//! | File | Types |
//! |---|---|
//! | `effect_type` | `PostFxEffectType` — enum of all built-in effect kinds |
//! | `effect` | `PostFxEffect` — per-effect parameter bag |
//! | `stack` | `PostFxStack` — ordered pipeline of post-processing passes |
//! | `image_effect` | `ImageEffect` — lightweight per-image effect chain |
//!
//! ## Screen overlays (world-simulation effects)
//!
//! | File | Types |
//! |---|---|
//! | `ambient` | `AmbientState` — time-of-day colour cycling |
//! | `atmosphere` | `CloudState`, `FogState`, `HeatHazeState`, `VignetteState`, `FilmGrainState`, `LightningState` |
//! | `screen_effects` | `FlashState`, `ShakeState`, `FadeState` — one-shot screen effects |
//! | `overlay` | `Overlay` — main struct combining all screen subsystems |
//! | `weather` | `WeatherState`, `WeatherParticle`, `WeatherType` — weather simulation |
//!
//! ## Tier
//!
//! `fx` is a **Tier 2 — Engine Extension** module. It may import `math`,
//! `engine`, and any Tier 1 module. It must not import other Tier 2 modules.

// ── Post-processing effects ──────────────────────────────────────────────────

/// Per-effect parameter bag with builder helpers.
pub mod effect;
/// Enum of all built-in post-processing effect kinds (bloom, blur, CRT, colour grading, …).
pub mod effect_type;
/// Lightweight per-image effect chain (subset of the full pipeline).
pub mod image_effect;
/// Render-command generation for post-processing effects.
pub mod render;
/// CPU software-rendering fallback for headless draw-to-image.
pub mod draw;
/// Ordered pipeline of post-processing passes applied to the rendered scene.
pub mod stack;

// ── Screen overlays ──────────────────────────────────────────────────────────

/// Ambient lighting state with time-of-day colour cycling (night → dawn → day → dusk).
pub mod ambient;
/// Atmospheric effects: clouds, fog, heat haze, vignette, film grain, lightning.
pub mod atmosphere;
/// Main `Overlay` struct combining all screen-effect subsystems into one per-frame controller.
pub mod overlay;
/// One-shot screen effects: flash (colour burst), shake (jitter), fade (alpha transition).
pub mod screen_effects;
/// Weather simulation: rain, snow, hail, dust, leaves, ash, pollen particles.
pub mod weather;

// ── Re-exports ───────────────────────────────────────────────────────────────

pub use effect::PostFxEffect;
pub use effect_type::PostFxEffectType;
pub use image_effect::ImageEffect;
pub use stack::PostFxStack;

pub use ambient::AmbientState;
pub use atmosphere::{
    CloudState, FilmGrainState, FogState, HeatHazeState, LightningState, VignetteState,
};
pub use overlay::Overlay;
pub use screen_effects::{FadeState, FlashState, ShakeState};
pub use weather::{WeatherParticle, WeatherState, WeatherType};
