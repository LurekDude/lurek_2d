//! Post-effect instances with typed kind selection and parameter storage.

use super::effect_type::PostFxEffectType;
use crate::log_msg;
use crate::runtime::log_messages::{FE01, FE02, FE03};
use std::collections::HashMap;
#[derive(Clone, Debug)]
/// Stores one post-processing effect instance and its runtime parameters.
pub struct PostFxEffect {
    /// Built-in or custom effect type driving shader selection.
    pub effect_type: PostFxEffectType,
    /// Scalar parameter map passed to the effect implementation.
    pub params: HashMap<String, f32>,
    /// Enables or disables this effect without removing it from a stack.
    pub enabled: bool,
    /// Renderer shader identifier used by custom effects.
    pub shader_id: Option<usize>,
    /// Requests automatic uniform population for this effect.
    pub auto_uniforms: bool,
}
impl PostFxEffect {
    /// Creates an enabled built-in effect with its default parameter set.
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
    /// Creates an enabled custom effect bound to an explicit shader id.
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
    /// Inserts or replaces one scalar effect parameter.
    pub fn set_parameter(&mut self, name: impl Into<String>, value: f32) {
        let name = name.into();
        log_msg!(trace, FE03, "{}={}", name, value);
        self.params.insert(name, value);
    }
    /// Returns a scalar effect parameter or the caller-provided fallback.
    pub fn get_parameter(&self, name: &str, default: f32) -> f32 {
        self.params.get(name).copied().unwrap_or(default)
    }
    /// Returns whether a named scalar parameter is present.
    pub fn has_parameter(&self, name: &str) -> bool {
        self.params.contains_key(name)
    }
    /// Returns the sorted list of parameter names defined on this effect.
    pub fn get_parameter_names(&self) -> Vec<String> {
        let mut names: Vec<String> = self.params.keys().cloned().collect();
        names.sort();
        names
    }
    /// Returns the lowercase effect type name used by renderer-facing code.
    pub fn get_type_name(&self) -> &'static str {
        self.effect_type.name()
    }
    /// Returns whether this effect uses a built-in effect type.
    pub fn is_built_in(&self) -> bool {
        self.effect_type != PostFxEffectType::Custom
    }
    /// Creates a built-in effect in the disabled state.
    pub fn new_disabled(effect_type: PostFxEffectType) -> Self {
        let mut e = Self::new(effect_type);
        e.enabled = false;
        e
    }
    /// Convenience alias for setting one scalar effect parameter.
    pub fn set_param(&mut self, name: impl Into<String>, value: f32) {
        self.set_parameter(name, value);
    }
    /// Convenience alias for fetching one scalar effect parameter with a fallback.
    pub fn get_param_or(&self, name: &str, default: f32) -> f32 {
        self.get_parameter(name, default)
    }
}
