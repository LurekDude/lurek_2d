use lurek2d::effect::effect::PostFxEffect;
use lurek2d::effect::effect_type::PostFxEffectType;

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
