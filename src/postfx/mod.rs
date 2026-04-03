//! Post-processing effects data model (Tier 1).
//!
//! Provides a stackable post-processing pipeline with built-in effects
//! (bloom, blur, CRT, vignette, chromatic aberration, colour grading,
//! godrays, pixelate, sepia, grayscale, invert, scanlines, edge-detect,
//! hue-shift, noise) and custom shader passes. Effects are organised into
//! a `PostFxStack` that captures the rendered scene via ping-pong canvases,
//! applies all enabled effects in insertion order, and outputs the final
//! composited result.
//!
//! This is a **pure CPU data-model module** -- it has no GPU dependencies.
//! GPU application of the stack is handled in `lua_api`. Extracted from
//! `graphics` so that other modules can reference postfx types without
//! pulling in the full rendering pipeline.

/// Built-in and custom effect type enum.
pub mod effect_type;
/// Per-effect parameter bag and helper methods.
pub mod effect;
/// Ordered chain of effects for full-screen post-processing.
pub mod stack;
/// Ordered per-image effect chain with lightweight pass conversion.
pub mod image_effect;

pub use effect_type::PostFxEffectType;
pub use effect::PostFxEffect;
pub use stack::PostFxStack;
pub use image_effect::ImageEffect;
