//! Post-processing state, overlay effects, and effect stack helpers.

/// Ambient color state derived from time-of-day settings.
pub mod ambient;
/// Atmospheric overlay states such as clouds, fog, and lightning.
pub mod atmosphere;
/// Debug image rendering for post-effect stacks.
pub mod draw;
#[allow(clippy::module_inception)]
/// Post-effect instance state and parameter accessors.
pub mod effect;
/// Built-in post-effect type identifiers and default parameter maps.
pub mod effect_type;
/// Image-scoped collections of post effects.
pub mod image_effect;
/// Screen overlay controller for weather, flashes, fades, and haze.
pub mod overlay;
/// Named post-effect preset builders.
pub mod presets;
/// Render-command generation for post-effect capture and apply passes.
pub mod render;
/// Screen-space flash, shake, and fade state types.
pub mod screen_effects;
/// Ordered post-effect stack management utilities.
pub mod stack;
/// Water distortion overlay state and update helpers.
pub mod water_overlay;
/// Weather particle types and simulation state.
pub mod weather;
pub use ambient::AmbientState;
pub use atmosphere::{
    CloudState, FilmGrainState, FogState, HeatHazeState, LightningState, VignetteState,
};
pub use effect::PostFxEffect;
pub use effect_type::PostFxEffectType;
pub use image_effect::ImageEffect;
pub use overlay::Overlay;
pub use presets::{build_preset, preset_names, EffectPreset};
pub use screen_effects::{FadeState, FlashState, ShakeState};
pub use stack::PostFxStack;
pub use water_overlay::WaterOverlayState;
pub use weather::{WeatherParticle, WeatherState, WeatherType};
/// Screen transition types and playback state.
pub mod transition;
pub use transition::{ScreenTransition, TransitionKind};
