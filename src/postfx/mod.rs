//! Post-processing effects data model (Tier 1).
//!
//! Provides a stackable post-processing pipeline with built-in effects
//! (bloom, blur, CRT, vignette, chromatic aberration, colour grading,
//! godrays) and custom shader passes. Effects are organized into a
//! `PostFxStack` that captures the scene via ping-pong canvases,
//! applies all enabled effects in order, and outputs the final result.
//!
//! This is a **pure CPU data-model module** — it has no GPU dependencies.
//! GPU application of the stack is handled in `lua_api`. Extracted from
//! `graphics` so that other modules can reference postfx types without
//! pulling in the full rendering pipeline.

use std::collections::HashMap;

/// Built-in effect types for the post-processing pipeline.
///
/// Each variant produces a different full-screen shader pass.
///
/// # Variants
/// - `R` — R variant.
/// - `Bloom` — Bloom variant.
/// - `Gaussian` — Gaussian variant.
/// - `Blur` — Blur variant.
/// - `T` — T variant.
/// - `Crt` — Crt variant.
/// - `Light` — Light variant.
/// - `Godrays` — Godrays variant.
/// - `Screen` — Screen variant.
/// - `Vignette` — Vignette variant.
/// - `Colour` — Colour variant.
/// - `ColourGrade` — ColourGrade variant.
/// - `Chromatic` — Chromatic variant.
/// - `Pass` — Pass variant.
/// - `Custom` — Custom variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PostFxEffectType {
    /// HDR bloom with threshold + intensity parameters.
    Bloom,
    /// Gaussian blur with radius parameter.
    Blur,
    /// CRT monitor simulation with scanline strength.
    Crt,
    /// Light ray / god ray effect with intensity.
    Godrays,
    /// Screen edge darkening with strength.
    Vignette,
    /// Colour grading / tone mapping.
    ColourGrade,
    /// Chromatic aberration with offset.
    Chromatic,
    /// Custom shader pass (created via `newPass()`).
    Custom,
}

impl PostFxEffectType {
    /// Parses a string name into an effect type.
    ///
    /// # Parameters
    /// - `name` — `&str` — One of `"bloom"`, `"blur"`, `"crt"`, `"godrays"`,
    ///   `"vignette"`, `"colourgrade"`, `"chromatic"`.
    ///
    /// # Returns
    /// `Option<Self>` — `None` if the name is unrecognised.
    pub fn from_name(name: &str) -> Option<Self> {
        match name {
            "bloom" => Some(Self::Bloom),
            "blur" => Some(Self::Blur),
            "crt" => Some(Self::Crt),
            "godrays" => Some(Self::Godrays),
            "vignette" => Some(Self::Vignette),
            "colourgrade" => Some(Self::ColourGrade),
            "chromatic" => Some(Self::Chromatic),
            _ => None,
        }
    }

    /// Returns the string name of this effect type.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn name(&self) -> &'static str {
        match self {
            Self::Bloom => "bloom",
            Self::Blur => "blur",
            Self::Crt => "crt",
            Self::Godrays => "godrays",
            Self::Vignette => "vignette",
            Self::ColourGrade => "colourgrade",
            Self::Chromatic => "chromatic",
            Self::Custom => "custom",
        }
    }

    /// Returns the default parameters for this built-in effect type.
    ///
    /// # Returns
    /// `HashMap<String, f32>`.
    pub fn default_params(&self) -> HashMap<String, f32> {
        let mut m = HashMap::new();
        match self {
            Self::Bloom => {
                m.insert("threshold".into(), 0.7);
                m.insert("intensity".into(), 1.0);
            }
            Self::Blur => {
                m.insert("radius".into(), 2.0);
                m.insert("strength".into(), 1.0);
            }
            Self::Crt => {
                m.insert("scanline_strength".into(), 0.3);
            }
            Self::Godrays => {
                m.insert("intensity".into(), 1.0);
            }
            Self::Vignette => {
                m.insert("strength".into(), 0.5);
            }
            Self::ColourGrade => {
                m.insert("brightness".into(), 1.0);
                m.insert("contrast".into(), 1.0);
                m.insert("saturation".into(), 1.0);
            }
            Self::Chromatic => {
                m.insert("offset".into(), 2.0);
            }
            Self::Custom => {}
        }
        m
    }
}

/// A single post-processing effect with named float parameters.
///
/// # Fields
/// - `effect_type` — `PostFxEffectType` — The kind of effect.
/// - `params` — Named float parameters controlling the effect.
/// - `enabled` — Whether this effect is active in its stack.
/// - `shader_id` — Optional custom shader handle (for `Custom` type).
pub struct PostFxEffect {
    /// The type of this effect.
    pub effect_type: PostFxEffectType,
    /// Named float parameters (e.g., `"threshold"`, `"intensity"`).
    pub params: HashMap<String, f32>,
    /// Whether this effect is active within its parent stack.
    pub enabled: bool,
    /// Optional custom shader ID (used only for `Custom` effects).
    pub shader_id: Option<usize>,
}

impl PostFxEffect {
    /// Creates a new built-in effect with default parameters.
    ///
    /// # Parameters
    /// - `effect_type` — `PostFxEffectType`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(effect_type: PostFxEffectType) -> Self {
        Self {
            params: effect_type.default_params(),
            effect_type,
            enabled: true,
            shader_id: None,
        }
    }

    /// Creates a custom shader pass effect. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `shader_id` — `usize` — Handle to the custom shader.
    ///
    /// # Returns
    /// `Self`.
    pub fn new_custom(shader_id: usize) -> Self {
        Self {
            effect_type: PostFxEffectType::Custom,
            params: HashMap::new(),
            enabled: true,
            shader_id: Some(shader_id),
        }
    }

    /// Sets a named float parameter. Replaces the current parameter value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `value` — `f32`.
    pub fn set_parameter(&mut self, name: impl Into<String>, value: f32) {
        self.params.insert(name.into(), value);
    }

    /// Gets a named float parameter, returning a default if not set.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `default` — `f32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_parameter(&self, name: &str, default: f32) -> f32 {
        self.params.get(name).copied().unwrap_or(default)
    }

    /// Checks whether a named parameter exists.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_parameter(&self, name: &str) -> bool {
        self.params.contains_key(name)
    }

    /// Returns a sorted list of all parameter names.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_parameter_names(&self) -> Vec<String> {
        let mut names: Vec<String> = self.params.keys().cloned().collect();
        names.sort();
        names
    }

    /// Returns the string name of this effect's type.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn get_type_name(&self) -> &'static str {
        self.effect_type.name()
    }

    /// Returns whether this is a built-in effect (not custom).
    ///
    /// # Returns
    /// `bool`.
    pub fn is_built_in(&self) -> bool {
        self.effect_type != PostFxEffectType::Custom
    }
}

/// An ordered chain of effects that captures and processes the rendered scene.
///
/// # Fields
/// - `effects` — Ordered list of effect indices.
/// - `enabled` — Per-effect enable state (parallel to `effects`).
/// - `width` — Canvas width in pixels.
/// - `height` — Canvas height in pixels.
///
/// The stack manages ping-pong canvases internally for multi-pass rendering.
/// During `luna.draw`, the user calls `beginCapture()` → draws scene →
/// `endCapture()` → `apply()` to render the post-processed result.
pub struct PostFxStack {
    /// Ordered effect indices referencing external effect storage.
    pub effects: Vec<usize>,
    /// Per-effect enabled state (same length as `effects`).
    pub enabled: Vec<bool>,
    /// Width of the internal canvases in pixels.
    pub width: u32,
    /// Height of the internal canvases in pixels.
    pub height: u32,
    /// Whether the stack is currently capturing.
    pub capturing: bool,
}

impl PostFxStack {
    /// Creates a new post-processing stack with the given canvas dimensions.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32) -> Self {
        Self {
            effects: Vec::new(),
            enabled: Vec::new(),
            width,
            height,
            capturing: false,
        }
    }

    /// Appends an effect index to the end of the chain.
    ///
    /// # Parameters
    /// - `effect_idx` — `usize`.
    pub fn add(&mut self, effect_idx: usize) {
        self.effects.push(effect_idx);
        self.enabled.push(true);
    }

    /// Removes an effect index from the chain. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `effect_idx` — `usize`.
    ///
    /// # Returns
    /// `bool` — `true` if the effect was found and removed.
    pub fn remove(&mut self, effect_idx: usize) -> bool {
        if let Some(pos) = self.effects.iter().position(|&e| e == effect_idx) {
            self.effects.remove(pos);
            self.enabled.remove(pos);
            true
        } else {
            false
        }
    }

    /// Inserts an effect at a specific 1-based position.
    ///
    /// # Parameters
    /// - `position` — `usize` — 1-based index.
    /// - `effect_idx` — `usize`.
    pub fn insert(&mut self, position: usize, effect_idx: usize) {
        let idx = (position.saturating_sub(1)).min(self.effects.len());
        self.effects.insert(idx, effect_idx);
        self.enabled.insert(idx, true);
    }

    /// Sets the enabled state for an effect in the chain.
    ///
    /// # Parameters
    /// - `effect_idx` — `usize`.
    /// - `is_enabled` — `bool`.
    pub fn set_enabled(&mut self, effect_idx: usize, is_enabled: bool) {
        if let Some(pos) = self.effects.iter().position(|&e| e == effect_idx) {
            self.enabled[pos] = is_enabled;
        }
    }

    /// Gets the enabled state for an effect in the chain.
    ///
    /// # Parameters
    /// - `effect_idx` — `usize`.
    ///
    /// # Returns
    /// `bool` — `false` if the effect is not in the chain.
    pub fn is_enabled(&self, effect_idx: usize) -> bool {
        self.effects
            .iter()
            .position(|&e| e == effect_idx)
            .map(|pos| self.enabled[pos])
            .unwrap_or(false)
    }

    /// Returns the number of effects in the chain.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_effect_count(&self) -> usize {
        self.effects.len()
    }

    /// Returns the effect index at a 1-based position.
    ///
    /// # Parameters
    /// - `index` — `usize` — 1-based.
    ///
    /// # Returns
    /// `Option<usize>`.
    pub fn get_effect(&self, index: usize) -> Option<usize> {
        if index >= 1 && index <= self.effects.len() {
            Some(self.effects[index - 1])
        } else {
            None
        }
    }

    /// Returns the indices of all enabled effects in order.
    ///
    /// # Returns
    /// `Vec<usize>`.
    pub fn enabled_effects(&self) -> Vec<usize> {
        self.effects
            .iter()
            .zip(self.enabled.iter())
            .filter(|(_, &en)| en)
            .map(|(&idx, _)| idx)
            .collect()
    }

    /// Resizes the internal canvas dimensions. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    pub fn resize(&mut self, width: u32, height: u32) {
        self.width = width;
        self.height = height;
    }

    /// Returns the canvas width. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_width(&self) -> u32 {
        self.width
    }

    /// Returns the canvas height. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_height(&self) -> u32 {
        self.height
    }

    /// Returns both canvas dimensions. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
}
