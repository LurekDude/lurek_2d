//! INTERNAL ONLY: public postfx effect names, parameters, enabled flags, and built-in/custom
//! behavior are covered by `tests/lua/unit/test_effect_core_unit.lua`.
//!
//! The remaining Rust coverage keeps constructor details that are not exposed through Lua, such as
//! the raw custom `shader_id` field and the disabled constructor path.

use lurek2d::effect::effect::PostFxEffect;
use lurek2d::effect::effect_type::PostFxEffectType;

#[test]
fn new_custom_has_shader_id() {
    let e = PostFxEffect::new_custom(42);
    assert_eq!(e.shader_id, Some(42));
    assert_eq!(e.effect_type, PostFxEffectType::Custom);
    assert!(e.params.is_empty());
}

#[test]
fn new_disabled_starts_off() {
    let e = PostFxEffect::new_disabled(PostFxEffectType::Bloom);
    assert!(!e.enabled);
}
