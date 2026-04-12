use lurek2d::tween::{builtin_easing_names, resolve_easing, TweenState};

// ─── TweenState ──────────────────────────────────────────────────────────────

#[test]
fn tween_state_advances_elapsed() {
    let mut s = TweenState::new(2.0, "linear");
    assert!(!s.tick(1.0));
    assert!((s.elapsed - 1.0).abs() < 1e-9);
    assert!(!s.is_complete());
}

#[test]
fn tween_state_completes_at_duration() {
    let mut s = TweenState::new(1.0, "linear");
    let done = s.tick(1.0);
    assert!(done);
    assert!(s.is_complete());
}

#[test]
fn tween_state_completes_after_overshoot() {
    let mut s = TweenState::new(1.0, "linear");
    let done = s.tick(2.0);
    assert!(done);
    assert!((s.t_raw() - 1.0).abs() < 1e-5);
}

#[test]
fn tween_state_t_raw_linear() {
    let mut s = TweenState::new(4.0, "linear");
    s.tick(1.0);
    let t = s.t_raw();
    assert!((t - 0.25).abs() < 1e-5);
}

#[test]
fn tween_state_pause_freezes_elapsed() {
    let mut s = TweenState::new(2.0, "linear");
    s.tick(0.5);
    s.paused = true;
    s.tick(0.5);
    assert!((s.elapsed - 0.5).abs() < 1e-9);
}

#[test]
fn tween_state_reset_restarts() {
    let mut s = TweenState::new(1.0, "linear");
    s.tick(1.0);
    assert!(s.is_complete());
    s.reset();
    assert!(!s.is_complete());
    assert!((s.elapsed).abs() < 1e-9);
}

#[test]
fn tween_state_lerp_linear() {
    let mut s = TweenState::new(2.0, "linear");
    s.tick(1.0); // t = 0.5
    let v = s.lerp(0.0, 100.0);
    assert!((v - 50.0).abs() < 1e-5);
}

#[test]
fn tween_state_lerp_at_start() {
    let s = TweenState::new(2.0, "linear");
    let v = s.lerp(10.0, 20.0);
    assert!((v - 10.0).abs() < 1e-5);
}

#[test]
fn tween_state_zero_duration_completes_immediately() {
    // duration is clamped to 0.0001, so one tick of 0.001 completes it
    let mut s = TweenState::new(0.0, "linear");
    let done = s.tick(0.001);
    assert!(done);
}

#[test]
fn tween_state_cubic_out_easing() {
    let mut s = TweenState::new(1.0, "cubicOut");
    s.tick(0.5); // halfway through
    let t = s.t_eased();
    // cubicOut at 0.5 ≠ 0.5 (it should be above 0.5 — faster at start)
    assert!(t > 0.5);
    // but not wildly out of range
    assert!(t < 1.5);
}

// ─── resolve_easing ──────────────────────────────────────────────────────────

#[test]
fn resolve_easing_recognises_linear() {
    assert!(resolve_easing("linear").is_some());
}

#[test]
fn resolve_easing_case_insensitive() {
    assert!(resolve_easing("LINEAR").is_some());
    assert!(resolve_easing("CubicOut").is_some());
    assert!(resolve_easing("QUADINOUT").is_some());
}

#[test]
fn resolve_easing_unknown_returns_none() {
    assert!(resolve_easing("notAnEasing").is_none());
}

#[test]
fn resolve_easing_all_builtins_resolve() {
    for name in builtin_easing_names() {
        assert!(
            resolve_easing(name).is_some(),
            "builtin easing '{}' did not resolve",
            name
        );
    }
}

// ─── builtin_easing_names ────────────────────────────────────────────────────

#[test]
fn builtin_easing_names_not_empty() {
    assert!(!builtin_easing_names().is_empty());
}

#[test]
fn builtin_easing_names_contains_expected_entries() {
    let names = builtin_easing_names();
    assert!(names.contains(&"linear"));
    assert!(names.contains(&"cubicOut"));
    assert!(names.contains(&"bounceIn"));
    assert!(names.contains(&"sineInOut"));
}
