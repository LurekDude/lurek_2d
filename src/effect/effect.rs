use super::effect_type::PostFxEffectType;
use crate::log_msg;
use crate::runtime::log_messages::{FE01, FE02, FE03};
use std::collections::HashMap;
#[derive(Clone, Debug)]
pub struct PostFxEffect {
    pub effect_type: PostFxEffectType,
    pub params: HashMap<String, f32>,
    pub enabled: bool,
    pub shader_id: Option<usize>,
    pub auto_uniforms: bool,
}
impl PostFxEffect {
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
    pub fn set_parameter(&mut self, name: impl Into<String>, value: f32) {
        let name = name.into();
        log_msg!(trace, FE03, "{}={}", name, value);
        self.params.insert(name, value);
    }
    pub fn get_parameter(&self, name: &str, default: f32) -> f32 {
        self.params.get(name).copied().unwrap_or(default)
    }
    pub fn has_parameter(&self, name: &str) -> bool {
        self.params.contains_key(name)
    }
    pub fn get_parameter_names(&self) -> Vec<String> {
        let mut names: Vec<String> = self.params.keys().cloned().collect();
        names.sort();
        names
    }
    pub fn get_type_name(&self) -> &'static str {
        self.effect_type.name()
    }
    pub fn is_built_in(&self) -> bool {
        self.effect_type != PostFxEffectType::Custom
    }
    pub fn new_disabled(effect_type: PostFxEffectType) -> Self {
        let mut e = Self::new(effect_type);
        e.enabled = false;
        e
    }
    pub fn set_param(&mut self, name: impl Into<String>, value: f32) {
        self.set_parameter(name, value);
    }
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
