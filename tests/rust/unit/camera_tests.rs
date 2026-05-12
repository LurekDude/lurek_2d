//! INTERNAL ONLY: Rust-only tests for camera helpers that are not directly asserted through
//! `lurek.camera.*`.
//!
//! Public camera lifecycle, follow logic, effects, and path/zoom helpers are
//! covered by `tests/lua/unit/test_camera_unit.lua`. The remaining Rust tests
//! keep render-command emission and viewport helper invariants.

use lurek2d::camera::types::{Camera, Camera2D, CameraFollowEasing};
use lurek2d::camera::viewport::{ScaleMode, Viewport};
use lurek2d::camera::viewport_scale::ViewportScale;
use lurek2d::camera::CameraRig2D;
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

// ── constraints tests ───────────────────────────────────────────────────────

mod constraints_tests {
    use super::*;

    #[test]
    fn zoom_constraints_clamp_zoom() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_zoom_constraints(Some(0.5), Some(3.0));

        // Try to set zoom outside constraints
        cam.set_zoom(5.0);
        cam.update(0.016);

        // Should be clamped to max
        assert!(cam.get_zoom() <= 3.0);
    }

    #[test]
    fn zoom_constraints_get_returns_set_values() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_zoom_constraints(Some(0.5), Some(3.0));

        let (min_z, max_z) = cam.get_zoom_constraints();
        assert_eq!(min_z, Some(0.5));
        assert_eq!(max_z, Some(3.0));
    }

    #[test]
    fn rotation_constraints_clamp_rotation() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_rotation_constraints(Some(0.0), Some(std::f32::consts::PI));

        // Try to set rotation outside constraints
        cam.set_rotation(std::f32::consts::PI * 2.0);
        cam.update(0.016);

        // Should be clamped to max
        assert!(cam.get_rotation() <= std::f32::consts::PI);
    }

    #[test]
    fn rotation_constraints_get_returns_set_values() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_rotation_constraints(Some(-0.5), Some(0.5));

        let (min_r, max_r) = cam.get_rotation_constraints();
        assert_eq!(min_r, Some(-0.5));
        assert_eq!(max_r, Some(0.5));
    }

    #[test]
    fn effective_zoom_includes_pulse_and_breathing() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_zoom(1.0);

        // Trigger zoom pulse
        cam.zoom_pulse.trigger(0.5, 0.5);
        cam.update(0.1);

        let eff_zoom = cam.effective_zoom();
        // Effective zoom should be > 1.0 due to pulse
        assert!(eff_zoom > 1.0);
    }
}

// ── preset tests ────────────────────────────────────────────────────────────

mod preset_tests {
    use super::*;

    #[test]
    fn preset_tight_follow_has_correct_values() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.preset_tight_follow();

        assert!((cam.get_follow_smooth() - 0.9).abs() < 1e-5);
        let dead_zone = cam.get_dead_zone();
        assert!(dead_zone.is_some());
        let (dz_w, dz_h) = dead_zone.unwrap();
        assert!((dz_w - 20.0).abs() < 1e-5);
        assert!((dz_h - 20.0).abs() < 1e-5);
        assert!((cam.get_look_ahead() - 0.5).abs() < 1e-5);
    }

    #[test]
    fn preset_cinematic_follow_has_correct_values() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.preset_cinematic_follow();

        assert!((cam.get_follow_smooth() - 0.3).abs() < 1e-5);
        let dead_zone = cam.get_dead_zone();
        assert!(dead_zone.is_some());
        let (dz_w, dz_h) = dead_zone.unwrap();
        assert!((dz_w - 100.0).abs() < 1e-5);
        assert!((dz_h - 100.0).abs() < 1e-5);
        assert!((cam.get_look_ahead()).abs() < 1e-5);
    }

    #[test]
    fn preset_balanced_follow_has_correct_values() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.preset_balanced_follow();

        assert!((cam.get_follow_smooth() - 0.6).abs() < 1e-5);
        let dead_zone = cam.get_dead_zone();
        assert!(dead_zone.is_some());
        let (dz_w, dz_h) = dead_zone.unwrap();
        assert!((dz_w - 40.0).abs() < 1e-5);
        assert!((dz_h - 40.0).abs() < 1e-5);
        assert!((cam.get_look_ahead() - 0.3).abs() < 1e-5);
    }

    #[test]
    fn preset_aggressive_follow_has_correct_values() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.preset_aggressive_follow();

        assert!((cam.get_follow_smooth() - 0.99).abs() < 1e-5);
        let dead_zone = cam.get_dead_zone();
        assert!(dead_zone.is_some());
        let (dz_w, dz_h) = dead_zone.unwrap();
        assert!((dz_w - 5.0).abs() < 1e-5);
        assert!((dz_h - 5.0).abs() < 1e-5);
        assert!((cam.get_look_ahead() - 1.0).abs() < 1e-5);
    }
}

mod rig_tests {
    use super::*;

    #[test]
    fn split_screen_layout_builds_left_and_right_cameras() {
        let mut rig = CameraRig2D::new();
        rig.apply_split_screen_layout(1280.0, 720.0);

        assert!(rig.has_camera("left"));
        assert!(rig.has_camera("right"));

        let left = rig.viewport_of("left").unwrap();
        let right = rig.viewport_of("right").unwrap();
        assert!((left.2 - 640.0).abs() < 1e-5);
        assert!((right.0 - 640.0).abs() < 1e-5);
    }

    #[test]
    fn minimap_layout_builds_main_and_minimap_cameras() {
        let mut rig = CameraRig2D::new();
        rig.apply_minimap_layout(1000.0, 800.0, 0.25);

        assert!(rig.has_camera("main"));
        assert!(rig.has_camera("minimap"));

        let minimap = rig.viewport_of("minimap").unwrap();
        assert!((minimap.2 - 250.0).abs() < 1e-5);
        assert!((minimap.3 - 200.0).abs() < 1e-5);
    }
}

mod easing_and_resize_tests {
    use super::*;

    #[test]
    fn follow_easing_is_configurable() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_follow_easing(CameraFollowEasing::SmoothStep);
        assert_eq!(cam.get_follow_easing(), CameraFollowEasing::SmoothStep);
    }

    #[test]
    fn zoom_tween_uses_non_linear_easing() {
        use lurek2d::camera::{CameraTweenEasing, CameraZoomTween};

        let mut tween =
            CameraZoomTween::new_with_easing(1.0, 2.0, 1.0, CameraTweenEasing::EaseOutCubic);
        let z = tween.update(0.5).unwrap();
        // ease-out should be ahead of linear midpoint at t=0.5
        assert!(z > 1.5);
    }

    #[test]
    fn on_window_resize_scaled_applies_letterbox_viewport() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.on_window_resize_scaled(800.0, 600.0, 1200.0, 600.0, ScaleMode::Letterbox);
        let (x, _y, w, h) = cam.get_viewport();
        assert!((x - 200.0).abs() < 1e-5);
        assert!((w - 800.0).abs() < 1e-5);
        assert!((h - 600.0).abs() < 1e-5);
    }

    #[test]
    fn camera_update_fuzz_extreme_inputs_stays_finite() {
        let mut seed: u64 = 0xD0E5_1234_ABCD_7788;
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_zoom_constraints(Some(0.01), Some(20.0));
        cam.set_rotation_constraints(Some(-10.0), Some(10.0));

        for _ in 0..10_000 {
            seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
            let a = ((seed >> 32) as u32) as f32 / u32::MAX as f32;
            seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
            let b = ((seed >> 32) as u32) as f32 / u32::MAX as f32;
            seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
            let c = ((seed >> 32) as u32) as f32 / u32::MAX as f32;

            let dt = a * 5.0;
            let x = (b - 0.5) * 1_000_000.0;
            let y = (c - 0.5) * 1_000_000.0;
            cam.set_target(x, y);
            cam.set_zoom(0.01 + a * 50.0);
            cam.set_rotation(-20.0 + b * 40.0);
            cam.update(dt);

            let (cx, cy) = cam.get_position();
            assert!(cx.is_finite());
            assert!(cy.is_finite());
            assert!(cam.get_zoom().is_finite());
            assert!(cam.get_rotation().is_finite());
        }
    }
}

mod coverage_gap_tests {
    use super::*;
    use lurek2d::camera::{CameraBreathing, CameraSway, ZoomPulse};

    #[test]
    fn effect_current_delta_accessors_are_callable() {
        let mut pulse = ZoomPulse::new();
        pulse.trigger(0.2, 0.5);
        pulse.update(0.1);
        let p = pulse.current_delta();
        assert!(p.is_finite());

        let mut sway = CameraSway::new();
        sway.start(2.0, 1.0, 0.5, 1.0);
        sway.update(0.1);
        let (sx, sy) = sway.current_offset();
        assert!(sx.is_finite());
        assert!(sy.is_finite());

        let mut breathing = CameraBreathing::new();
        breathing.start(0.01, 0.5);
        breathing.update(0.1);
        let b = breathing.current_delta();
        assert!(b.is_finite());
    }

    #[test]
    fn rig_helpers_cover_remove_mut_pip_update_and_names() {
        let mut rig = CameraRig2D::new();
        let cam = rig.ensure_camera("custom", 640.0, 360.0);
        cam.set_position(1.0, 2.0);
        assert!(rig.has_camera("custom"));

        if let Some(c) = rig.camera_mut("custom") {
            c.set_zoom(1.25);
        } else {
            panic!("expected mutable camera reference");
        }

        rig.apply_picture_in_picture_layout(1280.0, 720.0, 300.0, 200.0);
        assert!(rig.has_camera("pip"));

        rig.update_all(0.016);

        let names = rig.camera_names();
        assert!(!names.is_empty());

        assert!(rig.remove_camera("custom"));
        assert!(!rig.has_camera("custom"));
    }

    #[test]
    fn append_begin_render_commands_are_exercised() {
        let cam = Camera::new(Vec2::new(12.0, 34.0), 1.2, 0.4);
        let mut out = Vec::new();
        cam.append_begin_render_commands(&mut out);
        assert!(matches!(out.first(), Some(RenderCommand::PushTransform)));
        assert!(out
            .iter()
            .any(|c| matches!(c, RenderCommand::Translate { .. })));

        let mut cam2 = Camera2D::new(800.0, 600.0);
        cam2.set_position(10.0, 20.0);
        cam2.shake(5.0, 0.4);
        cam2.update(0.1);
        let mut out2 = Vec::new();
        cam2.append_begin_render_commands(&mut out2);
        assert!(matches!(out2.first(), Some(RenderCommand::PushTransform)));
        assert!(out2
            .iter()
            .any(|c| matches!(c, RenderCommand::Translate { .. })));
    }

    #[test]
    fn damping_accessors_and_misc_getters_are_exercised() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_zoom_damping(0.25);
        cam.set_rotation_damping(0.35);
        assert!((cam.get_zoom_damping() - 0.25).abs() < 1e-6);
        assert!((cam.get_rotation_damping() - 0.35).abs() < 1e-6);

        cam.set_bounds(1.0, 2.0, 3.0, 4.0);
        let b = cam.get_bounds();
        assert!(b.is_some());

        cam.set_target(10.0, 20.0);
        cam.clear_target();
        assert!(cam.get_target().is_none());

        cam.set_follow_smooth(2.0);
        cam.set_look_ahead(0.5);
        cam.shake(3.0, 0.4);
        cam.update(0.1);
        let (sx, sy) = cam.get_shake_offset();
        assert!(sx.is_finite());
        assert!(sy.is_finite());

        let (ex, ey) = cam.effect_offset();
        let (rx, ry) = cam.render_offset();
        assert!(ex.is_finite());
        assert!(ey.is_finite());
        assert!(rx.is_finite());
        assert!(ry.is_finite());
    }

    #[test]
    fn scale_mode_compute_transforms_is_exercised() {
        let (sx_l, sy_l, ox_l, oy_l) =
            ScaleMode::Letterbox.compute_transforms(800.0, 600.0, 1200.0, 600.0);
        assert!((sx_l - sy_l).abs() < 1e-6);
        assert!(ox_l > 0.0);
        assert!(oy_l.abs() < 1e-6);

        let (sx_s, sy_s, ox_s, oy_s) =
            ScaleMode::Stretch.compute_transforms(800.0, 600.0, 1200.0, 600.0);
        assert!((sx_s - 1.5).abs() < 1e-6);
        assert!((sy_s - 1.0).abs() < 1e-6);
        assert!(ox_s.abs() < 1e-6);
        assert!(oy_s.abs() < 1e-6);

        let (sx_p, sy_p, _ox_p, _oy_p) =
            ScaleMode::PixelPerfect.compute_transforms(320.0, 240.0, 700.0, 600.0);
        assert!((sx_p - sy_p).abs() < 1e-6);
        assert_eq!(sx_p.fract(), 0.0);
    }
}
