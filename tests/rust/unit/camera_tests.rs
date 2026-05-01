//! INTERNAL ONLY: Rust-only tests for camera helpers that are not directly asserted through
//! `lurek.camera.*`.
//!
//! Public camera lifecycle, follow logic, effects, and path/zoom helpers are
//! covered by `tests/lua/unit/test_camera_unit.lua`. The remaining Rust tests
//! keep render-command emission and viewport helper invariants.

use lurek2d::camera::types::{Camera, Camera2D};
use lurek2d::camera::viewport::{ScaleMode, Viewport};
use lurek2d::camera::viewport_scale::ViewportScale;
use lurek2d::math::Vec2;
use lurek2d::render::renderer::RenderCommand;

// ── render tests ────────────────────────────────────────────────────────────

mod render_tests {
    use super::*;

    #[test]
    fn camera_default_emits_push_and_translate_only() {
        let cam = Camera::default();
        let cmds = cam.begin_render_commands();
        assert_eq!(cmds.len(), 2);
        assert!(matches!(cmds[0], RenderCommand::PushTransform));
        assert!(matches!(cmds[1], RenderCommand::Translate { .. }));
    }

    #[test]
    fn camera_with_zoom_emits_scale() {
        let cam = Camera::new(Vec2::ZERO, 2.0, 0.0);
        let cmds = cam.begin_render_commands();
        assert!(cmds
            .iter()
            .any(|c| matches!(c, RenderCommand::Scale { .. })));
    }

    #[test]
    fn camera_with_rotation_emits_rotate() {
        let cam = Camera::new(Vec2::ZERO, 1.0, 0.5);
        let cmds = cam.begin_render_commands();
        assert!(cmds
            .iter()
            .any(|c| matches!(c, RenderCommand::Rotate { .. })));
    }

    #[test]
    fn camera2d_emits_transform_stack() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_position(100.0, 200.0);
        cam.set_zoom(1.5);
        cam.set_rotation(0.3);

        let cmds = cam.begin_render_commands();
        assert!(matches!(cmds[0], RenderCommand::PushTransform));
        if let RenderCommand::Translate { x, y } = cmds[1] {
            assert!((x - (-100.0)).abs() < 1e-5);
            assert!((y - (-200.0)).abs() < 1e-5);
        } else {
            panic!("Expected Translate");
        }
        assert!(cmds
            .iter()
            .any(|c| matches!(c, RenderCommand::Rotate { .. })));
        assert!(cmds
            .iter()
            .any(|c| matches!(c, RenderCommand::Scale { .. })));
    }

    #[test]
    fn end_returns_pop_transform() {
        let cmd = Camera::end_render_command();
        assert!(matches!(cmd, RenderCommand::PopTransform));
    }
}

// ── types tests ─────────────────────────────────────────────────────────────

mod types_tests {
    use super::*;

    #[test]
    fn camera_view_matrix_identity_at_default() {
        let cam = Camera::default();
        let m = cam.view_matrix();
        let p = m.transform_point(Vec2::new(10.0, 20.0));
        assert!((p.x - 10.0).abs() < 1e-5);
        assert!((p.y - 20.0).abs() < 1e-5);
    }
}

// ── viewport tests ──────────────────────────────────────────────────────────

mod viewport_tests {
    use super::*;

    #[test]
    fn new_default_scale_one_no_offset() {
        let vp = Viewport::new(800.0, 600.0, ScaleMode::Letterbox);
        let (sx, sy) = vp.get_scale();
        assert!((sx - 1.0).abs() < 1e-5);
        assert!((sy - 1.0).abs() < 1e-5);
        let (ox, oy) = vp.get_offset();
        assert!((ox).abs() < 1e-5);
        assert!((oy).abs() < 1e-5);
    }

    #[test]
    fn stretch_resize_fills_window() {
        let mut vp = Viewport::new(400.0, 300.0, ScaleMode::Stretch);
        vp.resize(800.0, 600.0);
        let (sx, sy) = vp.get_scale();
        assert!((sx - 2.0).abs() < 1e-5);
        assert!((sy - 2.0).abs() < 1e-5);
    }

    #[test]
    fn letterbox_preserves_aspect_ratio() {
        let mut vp = Viewport::new(400.0, 300.0, ScaleMode::Letterbox);
        vp.resize(800.0, 300.0);
        let (sx, sy) = vp.get_scale();
        assert!((sx - sy).abs() < 1e-5);
    }

    #[test]
    fn to_game_to_screen_roundtrip() {
        let mut vp = Viewport::new(800.0, 600.0, ScaleMode::Stretch);
        vp.resize(1600.0, 1200.0);
        let (gx, gy) = vp.to_game(400.0, 300.0);
        let (sx, sy) = vp.to_screen(gx, gy);
        assert!((sx - 400.0).abs() < 1e-5);
        assert!((sy - 300.0).abs() < 1e-5);
    }

    #[test]
    fn pixel_perfect_gives_integer_scale() {
        let mut vp = Viewport::new(200.0, 150.0, ScaleMode::PixelPerfect);
        vp.resize(700.0, 600.0);
        let (sx, _) = vp.get_scale();
        assert_eq!(sx.fract(), 0.0);
    }
}

// ── viewport_scale tests ────────────────────────────────────────────────────

mod viewport_scale_tests {
    use super::*;

    #[test]
    fn new_defaults_to_unit_scale() {
        let vs = ViewportScale::new(800.0, 600.0, ScaleMode::Letterbox);
        let (sx, sy) = vs.get_scale();
        assert!((sx - 1.0).abs() < 1e-5);
        assert!((sy - 1.0).abs() < 1e-5);
    }

    #[test]
    fn stretch_resize_fills_window() {
        let mut vs = ViewportScale::new(400.0, 300.0, ScaleMode::Stretch);
        vs.resize(800.0, 600.0);
        let (sx, sy) = vs.get_scale();
        assert!((sx - 2.0).abs() < 1e-5);
        assert!((sy - 2.0).abs() < 1e-5);
    }

    #[test]
    fn scaled_dimensions_track_resize() {
        let mut vs = ViewportScale::new(400.0, 300.0, ScaleMode::Stretch);
        vs.resize(800.0, 600.0);
        let (sw, sh) = vs.get_scaled_dimensions();
        assert!((sw - 800.0).abs() < 1e-3);
        assert!((sh - 600.0).abs() < 1e-3);
    }

    #[test]
    fn to_game_to_screen_roundtrip() {
        let mut vs = ViewportScale::new(800.0, 600.0, ScaleMode::Stretch);
        vs.resize(1600.0, 1200.0);
        let (gx, gy) = vs.to_game_coords(400.0, 300.0);
        let (sx, sy) = vs.to_screen_coords(gx, gy);
        assert!((sx - 400.0).abs() < 1e-3);
        assert!((sy - 300.0).abs() < 1e-3);
    }

    #[test]
    fn pixel_perfect_gives_integer_scale() {
        let mut vs = ViewportScale::new(200.0, 150.0, ScaleMode::PixelPerfect);
        vs.resize(700.0, 600.0);
        let (sx, _) = vs.get_scale();
        assert_eq!(sx.fract(), 0.0);
    }

    #[test]
    fn letterbox_preserves_aspect_ratio() {
        let mut vs = ViewportScale::new(400.0, 300.0, ScaleMode::Letterbox);
        vs.resize(800.0, 300.0);
        let (sx, sy) = vs.get_scale();
        assert!((sx - sy).abs() < 1e-5);
    }

    #[test]
    fn game_dimensions_match_construction() {
        let vs = ViewportScale::new(320.0, 240.0, ScaleMode::Letterbox);
        let (gw, gh) = vs.get_game_dimensions();
        assert!((gw - 320.0).abs() < f32::EPSILON);
        assert!((gh - 240.0).abs() < f32::EPSILON);
    }

    #[test]
    fn get_offset_zero_at_construction() {
        let vs = ViewportScale::new(800.0, 600.0, ScaleMode::Stretch);
        let (ox, oy) = vs.get_offset();
        assert!((ox).abs() < f32::EPSILON);
        assert!((oy).abs() < f32::EPSILON);
    }
}
