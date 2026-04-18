//! Rust unit tests for the `scene` module — private internals not reachable
//! from the `lurek.*` Lua API.
//!
//! Only tests that cannot be expressed via `lurek.*` live here:
//! - `EasingType::apply(t)` — pure curve math with no Lua namespace
//! - `EasingType::from_lua_str` / `TransitionType::from_lua_str` — enum-variant
//!   equality that is unobservable from Lua
//! - `ActiveTransition::get_easing()` — internal field access unavailable in Lua
//!
//! Tests observable via `lurek.scene.getTransitionProgress()` and
//! `lurek.scene.getTransitionProgressEased()` live in
//! `tests/lua/unit/test_scene.lua`.
//!
//! Naming: `<subject>_<scenario>_<expected>` — no `test_` prefix.

use lurek2d::scene::transition::{ActiveTransition, EasingType, TransitionType};

// ── EasingType ────────────────────────────────────────────────────────────────

#[test]
fn easing_linear_identity() {
    for i in 0..=10 {
        let t = i as f32 / 10.0;
        assert!((EasingType::Linear.apply(t) - t).abs() < 1e-5);
    }
}

#[test]
fn easing_ease_in_quadratic_at_half() {
    // EaseIn = t² → at t=0.5 ⇒ 0.25
    assert!((EasingType::EaseIn.apply(0.5) - 0.25).abs() < 1e-5);
}

#[test]
fn easing_ease_out_quadratic_at_half() {
    // EaseOut = 1-(1-t)² → at t=0.5 ⇒ 0.75
    assert!((EasingType::EaseOut.apply(0.5) - 0.75).abs() < 1e-5);
}

#[test]
fn easing_ease_in_out_symmetric_midpoint() {
    // Hermite S-curve is symmetric: f(0.5) = 0.5
    assert!((EasingType::EaseInOut.apply(0.5) - 0.5).abs() < 1e-5);
}

#[test]
fn easing_bounce_at_one_equals_one() {
    assert!((EasingType::Bounce.apply(1.0) - 1.0).abs() < 1e-4);
}

#[test]
fn easing_back_at_zero_equals_zero() {
    assert!((EasingType::Back.apply(0.0)).abs() < 1e-5);
}

#[test]
fn easing_back_at_one_equals_one() {
    assert!((EasingType::Back.apply(1.0) - 1.0).abs() < 1e-4);
}

#[test]
fn easing_all_start_at_zero_end_at_one() {
    let all = [
        EasingType::Linear,
        EasingType::EaseIn,
        EasingType::EaseOut,
        EasingType::EaseInOut,
        EasingType::Bounce,
    ];
    for e in &all {
        assert!(e.apply(0.0).abs() < 1e-4, "{e:?} at 0 is not 0");
        assert!((e.apply(1.0) - 1.0).abs() < 1e-4, "{e:?} at 1 is not 1");
    }
}

#[test]
fn easing_from_lua_str_roundtrip() {
    assert_eq!(EasingType::from_lua_str("linear"), EasingType::Linear);
    assert_eq!(EasingType::from_lua_str("ease_in"), EasingType::EaseIn);
    assert_eq!(EasingType::from_lua_str("ease_out"), EasingType::EaseOut);
    assert_eq!(EasingType::from_lua_str("ease_in_out"), EasingType::EaseInOut);
    assert_eq!(EasingType::from_lua_str("bounce"), EasingType::Bounce);
    assert_eq!(EasingType::from_lua_str("back"), EasingType::Back);
    assert_eq!(EasingType::from_lua_str("unknown"), EasingType::Linear);
}

// ── TransitionType ────────────────────────────────────────────────────────────

#[test]
fn transition_type_new_variants_parse() {
    assert_eq!(TransitionType::from_lua_str("wipe"), TransitionType::Wipe);
    assert_eq!(TransitionType::from_lua_str("iris"), TransitionType::Iris);
    assert_eq!(TransitionType::from_lua_str("zoom"), TransitionType::Zoom);
    assert_eq!(TransitionType::from_lua_str("crossfade"), TransitionType::CrossFade);
}

// ── ActiveTransition ──────────────────────────────────────────────────────────

#[test]
fn active_transition_new_defaults_linear() {
    let t = ActiveTransition::new(TransitionType::Fade, 1.0);
    assert_eq!(t.get_easing(), EasingType::Linear);
}

#[test]
fn active_transition_new_with_easing_stores_curve() {
    let t = ActiveTransition::new_with_easing(TransitionType::Wipe, 0.5, EasingType::EaseOut);
    assert_eq!(t.get_easing(), EasingType::EaseOut);
    assert_eq!(t.transition_type, TransitionType::Wipe);
}

// active_transition_progress_eased_linear_matches_progress,
// active_transition_progress_eased_ease_in_less_before_midpoint, and
// scene_stack_get_transition_progress_eased_linear_matches were migrated to
// tests/lua/unit/test_scene.lua — they are observable via
// lurek.scene.getTransitionProgress() and lurek.scene.getTransitionProgressEased().
