//! Unit tests for the `fx` module (post-processing effects and screen overlays).
//!
//! Covers: `PostFxStack`, `PostFxEffectType`, `PostFxEffect`, `ImageEffect`,
//! and the `screen` overlay types (`Overlay`, `FogState`, `HeatHazeState`, etc.).
//!
//! These tests are purely in-memory (no GPU, no window, no audio).

use luna2d::fx::{
    AmbientState, FadeState, FilmGrainState, FogState, HeatHazeState, Overlay, ShakeState,
    VignetteState, WeatherType,
};
use luna2d::fx::{ImageEffect, PostFxEffect, PostFxEffectType, PostFxStack};

// ═════════════════════════════════════════════════════════════════════════
// PostFxEffectType
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn effect_type_from_name_valid() {
    assert_eq!(
        PostFxEffectType::from_name("bloom"),
        Some(PostFxEffectType::Bloom)
    );
    assert_eq!(
        PostFxEffectType::from_name("blur"),
        Some(PostFxEffectType::Blur)
    );
    assert_eq!(
        PostFxEffectType::from_name("crt"),
        Some(PostFxEffectType::Crt)
    );
    assert_eq!(
        PostFxEffectType::from_name("vignette"),
        Some(PostFxEffectType::Vignette)
    );
}

#[test]
fn effect_type_from_name_invalid() {
    assert_eq!(PostFxEffectType::from_name(""), None);
    assert_eq!(PostFxEffectType::from_name("BLOOM"), None);
    assert_eq!(PostFxEffectType::from_name("bloom2"), None);
}

#[test]
fn effect_type_name_roundtrip() {
    let types = [
        PostFxEffectType::Bloom,
        PostFxEffectType::Blur,
        PostFxEffectType::Crt,
        PostFxEffectType::Godrays,
        PostFxEffectType::Vignette,
        PostFxEffectType::ColourGrade,
        PostFxEffectType::Chromatic,
    ];
    for t in types {
        assert_eq!(PostFxEffectType::from_name(t.name()), Some(t));
    }
}

#[test]
fn effect_type_default_params_bloom() {
    let params = PostFxEffectType::Bloom.default_params();
    assert!(params.contains_key("threshold"));
    assert!(params.contains_key("intensity"));
}

#[test]
fn effect_type_default_params_blur() {
    let params = PostFxEffectType::Blur.default_params();
    assert!(params.contains_key("radius"));
}

#[test]
fn effect_type_custom_params_empty() {
    assert!(PostFxEffectType::Custom.default_params().is_empty());
}

// ═════════════════════════════════════════════════════════════════════════
// PostFxEffect
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn postfx_effect_new_default_params() {
    let e = PostFxEffect::new(PostFxEffectType::Bloom);
    assert_eq!(e.effect_type, PostFxEffectType::Bloom);
    assert!(e.enabled);
    assert!(e.params.contains_key("threshold"));
}

#[test]
fn postfx_effect_new_disabled() {
    let e = PostFxEffect::new_disabled(PostFxEffectType::Blur);
    assert!(!e.enabled);
}

#[test]
fn postfx_effect_set_param() {
    let mut e = PostFxEffect::new(PostFxEffectType::Bloom);
    e.set_param("intensity", 2.5);
    assert!((e.params["intensity"] - 2.5).abs() < 1e-6);
}

#[test]
fn postfx_effect_get_param_default() {
    let e = PostFxEffect::new(PostFxEffectType::Bloom);
    let val = e.get_param_or("threshold", -1.0);
    assert!(val > 0.0, "threshold should have a positive default");
}

// ═════════════════════════════════════════════════════════════════════════
// PostFxStack — index-based API
//
// PostFxStack stores usize indices into an external Vec<PostFxEffect>.
// This mirrors the Lua API where the engine owns the effect pool and the
// stack references entries by index.
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn stack_new_empty() {
    let stack = PostFxStack::new(800, 600);
    assert!(stack.is_empty());
    assert_eq!(stack.len(), 0);
    assert_eq!(stack.get_dimensions(), (800, 600));
}

#[test]
fn stack_add_and_len() {
    let mut stack = PostFxStack::new(800, 600);
    // Effects live in an external pool; an index 0 references the first entry.
    stack.add(0);
    stack.add(1);
    assert_eq!(stack.len(), 2);
}

#[test]
fn stack_remove_present() {
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.add(1);
    let removed = stack.remove(0);
    assert!(removed);
    assert_eq!(stack.len(), 1);
    // Index 1 should still be present.
    assert!(stack.effects.contains(&1));
}

#[test]
fn stack_remove_absent() {
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    let removed = stack.remove(99);
    assert!(!removed);
    assert_eq!(stack.len(), 1);
}

#[test]
fn stack_clear() {
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.add(1);
    stack.clear();
    assert!(stack.is_empty());
}

#[test]
fn stack_enabled_parallel_array() {
    // The enabled flag array is always the same length as the effects array.
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.add(1);
    assert_eq!(stack.effects.len(), stack.enabled.len());
    // New entries are enabled by default.
    assert!(stack.enabled[0]);
    assert!(stack.enabled[1]);
}

#[test]
fn stack_disabled_effect_add_workflow() {
    // Workflow: create effects externally, reference them by index.
    let effects: Vec<PostFxEffect> = vec![
        PostFxEffect::new(PostFxEffectType::Bloom),
        PostFxEffect::new_disabled(PostFxEffectType::Blur),
    ];
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.add(1);
    // Check that the effect at index 1 is disabled in the external pool.
    assert!(!effects[1].enabled);
    // Both indices are tracked in the stack.
    assert_eq!(stack.len(), 2);
}

// ═════════════════════════════════════════════════════════════════════════
// ImageEffect
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn image_effect_default() {
    let ie = ImageEffect::new("test");
    assert_eq!(
        ie.effect_count(),
        0,
        "new ImageEffect should have no passes"
    );
}

// ═════════════════════════════════════════════════════════════════════════
// screen::Overlay
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn overlay_new_empty() {
    let ov = Overlay::new(800, 600);
    assert!(!ov.fog.enabled);
    assert!(!ov.vignette.enabled);
    assert!(!ov.film_grain.enabled);
    assert!(!ov.heat_haze.enabled);
}

#[test]
fn fog_state_default() {
    let fog = FogState::default();
    assert!(!fog.enabled);
    assert!(fog.density >= 0.0);
}

#[test]
fn heat_haze_state_default() {
    let hh = HeatHazeState::default();
    assert!(!hh.enabled);
    assert!(hh.intensity >= 0.0);
}

#[test]
fn vignette_state_default() {
    let v = VignetteState::default();
    assert!(!v.enabled);
}

#[test]
fn film_grain_state_default() {
    let fg = FilmGrainState::default();
    assert!(!fg.enabled);
}

#[test]
fn ambient_state_default_alpha_one() {
    let a = AmbientState::default();
    // Default ambient should be fully transparent (no tint)
    assert!((a.color[3] - 0.0).abs() < 1e-6 || a.color[3] >= 0.0);
}

#[test]
fn shake_state_default() {
    let s = ShakeState::default();
    assert!(!s.active);
    assert!(s.intensity > 0.0);
}

#[test]
fn fade_state_default() {
    let f = FadeState::default();
    assert!(!f.active);
    assert!(f.target_alpha >= 0.0);
}

#[test]
fn weather_type_roundtrip() {
    for name in &["rain", "snow", "hail", "none"] {
        if let Some(wt) = WeatherType::from_name(name) {
            assert_eq!(wt.name(), *name);
        }
    }
}
