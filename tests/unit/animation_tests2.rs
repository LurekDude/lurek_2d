//! Unit tests for the Luna2D animation module (`luna2d::animation`).

use luna2d::animation::{AnimEvent, Animation};
use luna2d::math::Rect;

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Build an animation with `count` grid-sliced frames and a single named clip.
fn make_clip(count: usize, fps: f32, looping: bool) -> Animation {
    let mut anim = Animation::new();
    anim.add_clip_from_grid("walk", 128, 32, 32, 32, 0, count, fps, looping);
    anim.play("walk");
    anim
}

// ── Default state ─────────────────────────────────────────────────────────────

#[test]
fn animation_new_is_empty() {
    let anim = Animation::new();
    assert_eq!(anim.get_frame_count(), 0);
    assert_eq!(anim.get_clip_count(), 0);
    assert!(!anim.is_playing());
    assert!(anim.current_quad().is_none());
    assert!(anim.get_current_clip().is_none());
}

// ── add_frame ─────────────────────────────────────────────────────────────────

#[test]
fn add_frame_returns_sequential_index() {
    let mut anim = Animation::new();
    let a = anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    let b = anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
    assert_eq!(a, 0);
    assert_eq!(b, 1);
    assert_eq!(anim.get_frame_count(), 2);
}

// ── add_clip ──────────────────────────────────────────────────────────────────

#[test]
fn add_clip_stores_clip_and_increments_count() {
    let mut anim = Animation::new();
    let f0 = anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    let f1 = anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
    anim.add_clip("idle", vec![f0, f1], 8.0, true);
    assert_eq!(anim.get_clip_count(), 1);
}

// ── play / current_quad ───────────────────────────────────────────────────────

#[test]
fn play_existing_clip_sets_playing_and_returns_true() {
    let mut anim = Animation::new();
    anim.add_frames_from_grid(64, 32, 32, 32, 0, 2);
    anim.add_clip("run", vec![0, 1], 10.0, true);
    let ok = anim.play("run");
    assert!(ok);
    assert!(anim.is_playing());
    assert_eq!(anim.get_current_clip(), Some("run"));
}

#[test]
fn play_resets_to_first_frame_and_current_quad_is_correct() {
    let mut anim = Animation::new();
    let idx = anim.add_frame(Rect::new(10.0, 20.0, 32.0, 32.0));
    anim.add_clip("idle", vec![idx], 8.0, false);
    anim.play("idle");
    let q = anim.current_quad().expect("should have a quad");
    assert!((q.x - 10.0).abs() < 1e-5);
    assert!((q.y - 20.0).abs() < 1e-5);
    assert!((q.width - 32.0).abs() < 1e-5);
    assert!((q.height - 32.0).abs() < 1e-5);
}

// ── update / advance ──────────────────────────────────────────────────────────

#[test]
fn update_advances_current_frame() {
    let mut anim = make_clip(4, 10.0, true);
    anim.update(0.15); // 1.5 frames @ 10 fps → frame 1
    assert_eq!(anim.current_frame(), 1);
}

#[test]
fn update_zero_dt_does_not_advance_frame() {
    let mut anim = make_clip(4, 10.0, false);
    anim.update(0.0);
    assert_eq!(anim.current_frame(), 0);
    assert!(anim.is_playing());
}

// ── Speed control ─────────────────────────────────────────────────────────────

#[test]
fn set_speed_doubles_frame_advancement() {
    let mut anim = make_clip(4, 10.0, true);
    anim.set_speed(2.0);
    assert!((anim.get_speed() - 2.0).abs() < 1e-5);
    // 0.1 s * 2× speed * 10 fps = 2 ticks → frame index 2
    anim.update(0.1);
    assert_eq!(anim.current_frame(), 2);
}

#[test]
fn set_speed_negative_value_clamps_to_zero() {
    let mut anim = make_clip(4, 10.0, true);
    anim.set_speed(-3.0);
    assert!((anim.get_speed()).abs() < 1e-5);
    let before = anim.current_frame();
    anim.update(0.5);
    assert_eq!(anim.current_frame(), before, "frozen animation should not advance");
}

// ── Looping vs non-looping ────────────────────────────────────────────────────

#[test]
fn looping_clip_wraps_and_emits_looped_event() {
    let mut anim = make_clip(2, 10.0, true);
    anim.update(0.25); // passes both frames → should wrap
    let events = anim.drain_events();
    assert!(
        events.contains(&AnimEvent::Looped),
        "expected Looped event, got: {events:?}"
    );
    assert!(anim.is_playing());
    assert!(anim.is_looping());
}

#[test]
fn nonlooping_clip_emits_finished_and_stops() {
    let mut anim = make_clip(2, 10.0, false);
    anim.update(0.5); // well past both frames
    let events = anim.drain_events();
    assert!(
        events.contains(&AnimEvent::Finished),
        "expected Finished event, got: {events:?}"
    );
    assert!(!anim.is_playing());
    assert!(!anim.is_looping());
}

// ── drain_events ─────────────────────────────────────────────────────────────

#[test]
fn drain_events_clears_pending_events() {
    let mut anim = make_clip(2, 10.0, true);
    anim.update(0.25); // generates at least one event
    let first = anim.drain_events();
    assert!(!first.is_empty(), "should have produced events");
    let second = anim.drain_events();
    assert!(second.is_empty(), "pending events should be cleared after first drain");
}

// ── Edge case: non-existent clip ──────────────────────────────────────────────

#[test]
fn play_nonexistent_clip_returns_false_and_stays_stopped() {
    let mut anim = Animation::new();
    let ok = anim.play("does_not_exist");
    assert!(!ok);
    assert!(!anim.is_playing());
}

// ── Multiple clips ────────────────────────────────────────────────────────────

#[test]
fn switching_clips_resets_frame_position() {
    let mut anim = Animation::new();
    anim.add_frames_from_grid(128, 64, 32, 32, 0, 8);
    anim.add_clip("walk", vec![0, 1, 2, 3], 10.0, true);
    anim.add_clip("run", vec![4, 5, 6, 7], 10.0, true);
    assert_eq!(anim.get_clip_count(), 2);

    anim.play("walk");
    anim.update(0.15); // advance to frame 1
    assert_eq!(anim.current_frame(), 1);

    anim.play("run"); // switch clip
    assert_eq!(anim.get_current_clip(), Some("run"));
    assert_eq!(anim.current_frame(), 0, "switching clips should reset to frame 0");
}
