//! Unit tests for the Luna2D camera module (`luna2d::camera`).

use luna2d::camera::{Camera, Camera2D, ScaleMode, Viewport, ViewportScale};
use luna2d::math::Vec2;

// ── Camera::default ───────────────────────────────────────────────────────────

#[test]
fn camera_default_position_is_zero() {
    let cam = Camera::default();
    assert!((cam.position.x).abs() < 1e-5);
    assert!((cam.position.y).abs() < 1e-5);
}

#[test]
fn camera_default_zoom_is_one_and_rotation_is_zero() {
    let cam = Camera::default();
    assert!((cam.zoom - 1.0).abs() < 1e-5);
    assert!((cam.rotation).abs() < 1e-5);
}

// ── Camera::view_matrix ───────────────────────────────────────────────────────

#[test]
fn camera_default_view_matrix_acts_as_identity() {
    let cam = Camera::default();
    let m = cam.view_matrix();
    let p = m.transform_point(Vec2::new(10.0, 20.0));
    assert!((p.x - 10.0).abs() < 1e-5);
    assert!((p.y - 20.0).abs() < 1e-5);
}

#[test]
fn camera_offset_position_shifts_view_by_negative_position() {
    let cam = Camera::new(Vec2::new(100.0, 50.0), 1.0, 0.0);
    let m = cam.view_matrix();
    // World origin in view space should be at (-100, -50)
    let p = m.transform_point(Vec2::new(0.0, 0.0));
    assert!((p.x - (-100.0)).abs() < 1e-5);
    assert!((p.y - (-50.0)).abs() < 1e-5);
}

#[test]
fn camera_zoom_two_doubles_view_space_coordinates() {
    let cam = Camera::new(Vec2::ZERO, 2.0, 0.0);
    let m = cam.view_matrix();
    let p = m.transform_point(Vec2::new(5.0, 5.0));
    assert!((p.x - 10.0).abs() < 1e-5);
    assert!((p.y - 10.0).abs() < 1e-5);
}

// ── Camera2D defaults ─────────────────────────────────────────────────────────

#[test]
fn camera2d_new_starts_at_origin_with_zoom_one() {
    let cam = Camera2D::new(800.0, 600.0);
    let (x, y) = cam.get_position();
    assert!((x).abs() < 1e-5);
    assert!((y).abs() < 1e-5);
    assert!((cam.get_zoom() - 1.0).abs() < 1e-5);
    assert!((cam.get_rotation()).abs() < 1e-5);
}

// ── Camera2D smooth follow ────────────────────────────────────────────────────

#[test]
fn camera2d_smooth_follow_advances_toward_target() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_follow_smooth(5.0);
    cam.set_target(200.0, 0.0);
    cam.update(0.1); // t = (5.0 * 0.1).min(1.0) = 0.5 → moves to 100
    let (px, _) = cam.get_position();
    assert!(px > 0.0, "camera should have moved toward target");
    assert!(px < 200.0, "camera should not have fully arrived in one step");
}

#[test]
fn camera2d_instant_snap_when_follow_smooth_is_zero() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_follow_smooth(0.0);
    cam.set_target(300.0, 150.0);
    cam.update(0.016);
    let (px, py) = cam.get_position();
    assert!((px - 300.0).abs() < 1e-3);
    assert!((py - 150.0).abs() < 1e-3);
}

// ── Camera2D dead zone ────────────────────────────────────────────────────────

#[test]
fn camera2d_dead_zone_prevents_movement_within_threshold() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_dead_zone(100.0, 100.0); // half-extents become (50, 50)
    cam.set_follow_smooth(0.0);
    cam.set_target(10.0, 10.0); // inside dead zone radius
    cam.update(0.016);
    let (px, py) = cam.get_position();
    assert!((px).abs() < 1e-5, "camera should not move inside dead zone");
    assert!((py).abs() < 1e-5, "camera should not move inside dead zone");
}

#[test]
fn camera2d_dead_zone_allows_movement_outside_threshold() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_dead_zone(10.0, 10.0); // small dead zone
    cam.set_follow_smooth(0.0);
    cam.set_target(200.0, 0.0); // far outside dead zone
    cam.update(0.016);
    let (px, _) = cam.get_position();
    assert!((px - 200.0).abs() < 1e-3, "camera should snap to target outside dead zone");
}

// ── Camera2D screen shake ─────────────────────────────────────────────────────

#[test]
fn camera2d_shake_expires_after_duration_and_coords_return_to_baseline() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.shake(20.0, 0.3);
    cam.update(0.4); // past shake duration

    // After shake ends, world↔screen round-trip should match a fresh camera
    let fresh = Camera2D::new(800.0, 600.0);
    let (sx1, sy1) = cam.to_screen_coords(100.0, 100.0);
    let (sx2, sy2) = fresh.to_screen_coords(100.0, 100.0);
    assert!((sx1 - sx2).abs() < 1e-5, "shake should not affect coords after expiry");
    assert!((sy1 - sy2).abs() < 1e-5, "shake should not affect coords after expiry");
}

// ── Viewport coordinate round-trip ────────────────────────────────────────────

#[test]
fn viewport_to_game_and_to_screen_are_inverse() {
    let mut vp = Viewport::new(320.0, 240.0, ScaleMode::Letterbox);
    vp.resize(1280.0, 960.0); // exactly 4× — no black bars

    // Window centre (640, 480) should map to game centre (160, 120)
    let (gx, gy) = vp.to_game(640.0, 480.0);
    assert!((gx - 160.0).abs() < 1e-3);
    assert!((gy - 120.0).abs() < 1e-3);

    // Round-trip back to screen
    let (sx, sy) = vp.to_screen(gx, gy);
    assert!((sx - 640.0).abs() < 1e-3);
    assert!((sy - 480.0).abs() < 1e-3);
}

// ── ViewportScale scale-factor computation ────────────────────────────────────

#[test]
fn viewport_scale_letterbox_computes_uniform_scale() {
    let mut vs = ViewportScale::new(320.0, 240.0, ScaleMode::Letterbox);
    vs.resize(640.0, 480.0); // exact 2×
    let (sx, sy) = vs.get_scale();
    assert!((sx - 2.0).abs() < 1e-5);
    assert!((sy - 2.0).abs() < 1e-5);
}

#[test]
fn viewport_scale_pixel_perfect_uses_integer_scale() {
    let mut vs = ViewportScale::new(320.0, 240.0, ScaleMode::PixelPerfect);
    vs.resize(700.0, 530.0); // ~2.18× and ~2.20× → should floor to 2
    let (sx, sy) = vs.get_scale();
    assert!((sx - 2.0).abs() < 1e-5);
    assert!((sy - 2.0).abs() < 1e-5);
}

// ── ScaleMode::Stretch via Viewport ───────────────────────────────────────────

#[test]
fn viewport_stretch_fills_window_non_uniformly() {
    let mut vp = Viewport::new(100.0, 100.0, ScaleMode::Stretch);
    vp.resize(200.0, 400.0); // 2× wide, 4× tall
    assert!((vp.scale_x - 2.0).abs() < 1e-5);
    assert!((vp.scale_y - 4.0).abs() < 1e-5);
    // Stretch mode has no black bars, so offset should be zero
    assert!((vp.offset_x).abs() < 1e-5);
    assert!((vp.offset_y).abs() < 1e-5);
}
