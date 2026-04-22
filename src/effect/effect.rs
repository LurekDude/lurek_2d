//! Post-processing effect data model.
//!
//! Defines [`PostFxEffect`] — a single named effect with typed parameters
//! for the post-processing pipeline.

use std::collections::HashMap;

use super::effect_type::PostFxEffectType;
use crate::runtime::log_messages::{FE01, FE02, FE03};
use crate::log_msg;

/// A single post-processing effect with named float parameters.
///
/// Acts as a parameter bag describing one shader pass — it does NOT
/// hold any GPU resource. Parameters are stored in a `HashMap<String, f32>`
/// so that new shader uniforms can be added without changing the struct
/// layout. Use `PostFxEffectType::default_params` to pre-populate sensible
/// defaults, then call `set_parameter` to override individual values.
/// The `enabled` flag lets you temporarily skip the pass within the stack
/// without removing it.
///
/// # Fields
/// - `effect_type` — `PostFxEffectType` — Which shader pass to run.
/// - `params` — Named float parameters controlling the shader (e.g., `"threshold"`, `"intensity"`).
/// - `enabled` — Whether this effect is active within its parent stack.
/// - `shader_id` — Optional custom shader handle; only used for `Custom` effects.
/// - `auto_uniforms` — When `true`, the engine injects time/frame/resolution into `p[3]` each frame.
#[derive(Clone, Debug)]
pub struct PostFxEffect {
    /// The type of this effect.
    pub effect_type: PostFxEffectType,
    /// Named float parameters (e.g., `"threshold"`, `"intensity"`).
    pub params: HashMap<String, f32>,
    /// Whether this effect is active within its parent stack.
    pub enabled: bool,
    /// Optional custom shader ID (used only for `Custom` effects).
    pub shader_id: Option<usize>,
    /// When `true`, the engine injects `(time, frame, width, height)` into `p[3]` each frame.
    ///
    /// Slot layout: `p[3].x` = total_time (s), `p[3].y` = frame_count (f32), `p[3].z` = width, `p[3].w` = height.
    /// Slots `p[0]..p[2]` remain free for user parameters set via `set_parameter`.
    pub auto_uniforms: bool,
}

impl PostFxEffect {
    /// Creates a new built-in effect with default parameters.
    ///
    /// Initialises `params` via `effect_type.default_params()`, sets
    /// `enabled = true`, and `shader_id = None`. The effect is ready to
    /// add to a `PostFxStack` without further configuration, though callers
    /// typically call `set_parameter` to tune it first.
    ///
    /// # Parameters
    /// - `effect_type` — `PostFxEffectType` — The built-in shader to use.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(effect_type: PostFxEffectType) -> Self {
        log_msg!(debug, FE01);
        Self {
            params: effect_type.default_params(),
            effect_type,
            enabled: true,
            shader_id: None,
            auto_uniforms: false,
        }
    }

    /// Creates a custom shader pass effect.
    ///
    /// Sets `effect_type` to `PostFxEffectType::Custom`, leaves `params`
    /// empty (custom shaders define their own uniform interface), and
    /// records `shader_id` for the GPU layer to look up the correct shader.
    /// The `enabled` flag is set to `true`.
    ///
    /// # Parameters
    /// - `shader_id` — `usize` — Handle to the custom shader resource.
    ///
    /// # Returns
    /// `Self`.
    pub fn new_custom(shader_id: usize) -> Self {
        log_msg!(debug, FE02, "shader={}", shader_id);
        Self {
            effect_type: PostFxEffectType::Custom,
            params: HashMap::new(),
            enabled: true,
            shader_id: Some(shader_id),
            auto_uniforms: false,
        }
    }

    /// Sets a named float parameter, inserting it if it does not yet exist.
    ///
    /// If a parameter with the same name already exists, its value is
    /// replaced. Parameters that do not correspond to any actual shader
    /// uniform are silently ignored by the GPU layer — they are retained
    /// in the map for round-trip serialisation purposes.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>` — Parameter key (e.g., `"threshold"`).
    /// - `value` — `f32` — New value for the parameter.
    pub fn set_parameter(&mut self, name: impl Into<String>, value: f32) {
        let name = name.into();
        log_msg!(trace, FE03, "{}={}", name, value);
        self.params.insert(name, value);
    }

    /// Gets a named float parameter, returning `default` if not set.
    ///
    /// Safe to call even if `name` does not exist — the `default` value is
    /// returned rather than an error. Useful for the GPU layer to read
    /// shader uniforms without needing to check with `has_parameter` first.
    ///
    /// # Parameters
    /// - `name` — `&str` — Parameter key to look up.
    /// - `default` — `f32` — Fallback value returned when the key is absent.
    ///
    /// # Returns
    /// `f32` — The stored value, or `default` if not found.
    pub fn get_parameter(&self, name: &str, default: f32) -> f32 {
        self.params.get(name).copied().unwrap_or(default)
    }

    /// Returns `true` if the named parameter key exists in this effect's map.
    ///
    /// Does not distinguish between a key that was set explicitly and one
    /// that was populated by `default_params`. Use this to guard optional
    /// parameters before reading them, or to test whether a user has
    /// overridden a built-in default.
    ///
    /// # Parameters
    /// - `name` — `&str` — Parameter key to test.
    ///
    /// # Returns
    /// `bool` — `true` if the key is present in the params map.
    pub fn has_parameter(&self, name: &str) -> bool {
        self.params.contains_key(name)
    }

    /// Returns a sorted alphabetical list of all parameter names.
    ///
    /// Useful for serialisation, round-trip save/load, and building
    /// parameter-editor UIs that need a deterministic display order.
    /// The list includes both default and user-overridden parameters.
    ///
    /// # Returns
    /// `Vec<String>` — Alphabetically sorted parameter keys.
    pub fn get_parameter_names(&self) -> Vec<String> {
        let mut names: Vec<String> = self.params.keys().cloned().collect();
        names.sort();
        names
    }

    /// Returns the canonical string name of this effect's type.
    ///
    /// Delegates to `PostFxEffectType::name()`. The returned string matches
    /// the name accepted by `PostFxEffectType::from_name` and by
    /// `lurek.effect.newEffect` in Lua, making it suitable for serialisation.
    ///
    /// # Returns
    /// `&'static str` — One of the built-in effect type names, or `"custom"`.
    pub fn get_type_name(&self) -> &'static str {
        self.effect_type.name()
    }

    /// Returns `true` if this is a built-in effect (not a custom shader pass).
    ///
    /// Built-in effects have well-known parameter maps and are dispatched by
    /// name in the GPU layer. Custom effects (created via `new_custom` or
    /// `lurek.effect.newPass`) return `false` and must carry a valid
    /// `shader_id` for the GPU layer to dispatch the correct shader.
    ///
    /// # Returns
    /// `bool` — `false` only for `PostFxEffectType::Custom` effects.
    pub fn is_built_in(&self) -> bool {
        self.effect_type != PostFxEffectType::Custom
    }

    /// Creates a new built-in effect that starts disabled.
    ///
    /// Equivalent to `PostFxEffect::new(effect_type)` followed by
    /// `effect.enabled = false`. Use when you want to add a shader pass to
    /// a stack but keep it inactive until needed.
    ///
    /// # Parameters
    /// - `effect_type` — `PostFxEffectType` — The built-in shader to use.
    ///
    /// # Returns
    /// `Self`.
    pub fn new_disabled(effect_type: PostFxEffectType) -> Self {
        let mut e = Self::new(effect_type);
        e.enabled = false;
        e
    }

    /// Alias for [`set_parameter`].
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>` — Parameter key.
    /// - `value` — `f32` — New value.
    pub fn set_param(&mut self, name: impl Into<String>, value: f32) {
        self.set_parameter(name, value);
    }

    /// Alias for [`get_parameter`].
    ///
    /// # Parameters
    /// - `name` — `&str` — Parameter key.
    /// - `default` — `f32` — Fallback if not set.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_param_or(&self, name: &str, default: f32) -> f32 {
        self.get_parameter(name, default)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_bloom_has_default_params() {
        let e = PostFxEffect::new(PostFxEffectType::Bloom);
        assert!(e.enabled);
        assert!(e.has_parameter("threshold"));
        assert!(e.has_parameter("intensity"));
        assert!(e.shader_id.is_none());
    }

    #[test]
    fn new_custom_has_shader_id() {
        let e = PostFxEffect::new_custom(42);
        assert_eq!(e.shader_id, Some(42));
        assert_eq!(e.effect_type, PostFxEffectType::Custom);
        assert!(e.params.is_empty());
    }

    #[test]
    fn set_parameter_inserts_and_overwrites() {
        let mut e = PostFxEffect::new(PostFxEffectType::Blur);
        e.set_parameter("radius", 5.0);
        assert!((e.get_parameter("radius", 0.0) - 5.0).abs() < 1e-6);
    }

    #[test]
    fn get_parameter_returns_default_when_missing() {
        let e = PostFxEffect::new(PostFxEffectType::Bloom);
        assert!((e.get_parameter("nonexistent", 99.0) - 99.0).abs() < 1e-6);
    }

    #[test]
    fn get_type_name_matches_effect() {
        let e = PostFxEffect::new(PostFxEffectType::Crt);
        assert_eq!(e.get_type_name(), "crt");
    }

    #[test]
    fn is_built_in_true_for_named_types() {
        let e = PostFxEffect::new(PostFxEffectType::Sepia);
        assert!(e.is_built_in());
    }

    #[test]
    fn is_built_in_false_for_custom() {
        let e = PostFxEffect::new_custom(0);
        assert!(!e.is_built_in());
    }

    #[test]
    fn new_disabled_starts_off() {
        let e = PostFxEffect::new_disabled(PostFxEffectType::Bloom);
        assert!(!e.enabled);
    }

    #[test]
    fn get_parameter_names_sorted() {
        let e = PostFxEffect::new(PostFxEffectType::ColourGrade);
        let names = e.get_parameter_names();
        let mut sorted = names.clone();
        sorted.sort();
        assert_eq!(names, sorted);
    }
}
