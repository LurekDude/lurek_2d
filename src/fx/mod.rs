//! Composable visual effects layer — Tier 2 Engine Extension.
//!
//! The `fx` module consolidates two families of screen and image effects:
//!
//! ## Sub-namespaces
//!
//! | Sub-module | Replaces | Responsibility |
//! |---|---|---|
//! | `post` | `postfx` | Image-space post-processing pipeline: bloom, blur, CRT, vignette, chromatic aberration, color grading, godrays, pixelate, sepia, grayscale, invert, scanlines, edge-detect, hue-shift, noise |
//! | `screen` | `overlay` | World-simulation screen overlays: weather, ambient lighting, flash, shake, fade, fog, heat haze, vignette, film grain, lightning |
//!
//! Both sub-namespaces are **pure CPU data models** — no GPU dependencies.
//! GPU application of each effect family is handled in `lua_api`.
//!
//! ## Tier
//!
//! `fx` is a **Tier 2 — Engine Extension** module. It may import `math`,
//! `engine`, and any Tier 1 module. It must not import other Tier 2 modules.

/// Image-space post-processing pipeline (bloom, blur, CRT, color grading, …).
pub mod post;
/// World-simulation screen overlays (weather, ambient, shake, fog, lightning, …).
pub mod screen;

/// Re-exports from `post` for convenient top-level access.
pub use post::{ImageEffect, PostFxEffect, PostFxEffectType, PostFxStack};
/// Re-exports from `screen` for convenient top-level access.
pub use screen::{
    AmbientState, CloudState, FadeState, FilmGrainState, FlashState, FogState, HeatHazeState,
    LightningState, Overlay, ShakeState, VignetteState, WeatherParticle, WeatherState, WeatherType,
};
