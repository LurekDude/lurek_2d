//! Lightweight per-image shader-effect pass data — Tier 1 graphics layer.
//!
//! [`ImageEffectPass`] describes one shader pass in a per-image effect chain.
//! This type lives in Tier 1 and has **no imports from `src/postfx/`**.
//!
//! The bridge layer (`lua_api`) creates `Vec<ImageEffectPass>` values (via
//! `ImageEffect::to_passes()`) and embeds them into `DrawCommand` variants
//! before the frame is submitted to the GPU renderer.

use std::collections::HashMap;

/// One shader pass in a per-image effect chain.
///
/// Carries the built-in effect name, a flat float-parameter map, and an
/// enabled flag. The GPU renderer matches `effect_name` against known
/// built-in effect names to select the correct shader pass. Passes with
/// `enabled = false` are skipped during rendering.
///
/// # Fields
/// - `effect_name` — `String` — Built-in effect name (e.g. `"blur"`, `"vignette"`).
/// - `params` — `HashMap<String, f32>` — Named float parameters for the shader.
/// - `enabled` — `bool` — When `false` this pass is skipped by the renderer.
#[derive(Debug, Clone)]
pub struct ImageEffectPass {
    /// Built-in effect name (e.g. `"blur"`, `"vignette"`).
    pub effect_name: String,
    /// Named float parameters controlling this shader pass.
    pub params: HashMap<String, f32>,
    /// When `false` this pass is skipped by the renderer.
    pub enabled: bool,
}

impl ImageEffectPass {
    /// Creates a new enabled pass with the given effect name and an empty parameter map.
    ///
    /// # Parameters
    /// - `effect_name` — `impl Into<String>` — Built-in effect name.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(effect_name: impl Into<String>) -> Self {
        Self {
            effect_name: effect_name.into(),
            params: HashMap::new(),
            enabled: true,
        }
    }
}
