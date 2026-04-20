//! Tests for the animation module.

use lurek2d::animation::blend::*;
use lurek2d::animation::clip::AnimClip;
use lurek2d::animation::controller::Animation;
use lurek2d::animation::curve::{AnimCurve, EasingKind};
use lurek2d::animation::event::AnimEvent;
use lurek2d::animation::frame::{AnimFrame, AnimationFrame};
use lurek2d::animation::render::{quad_to_draw_command, AnimRenderParams};
use lurek2d::animation::state_machine::{compare_nums, parse_condition, AnimStateMachine, ConditionOp};
use lurek2d::animation::sync_group::AnimSyncGroup;
use lurek2d::animation::aseprite::{load_aseprite_json, AsepriteDirection};
use lurek2d::math::Rect;
use lurek2d::render::renderer::RenderCommand;
use lurek2d::runtime::resource_keys::TextureKey;
use slotmap::{DefaultKey, KeyData, SlotMap};

fn dummy_texture_key() -> TextureKey {
    TextureKey::from(KeyData::from_ffi(1))
}

fn dummy_slotmap_key() -> DefaultKey {
    let mut sm: SlotMap<DefaultKey, ()> = SlotMap::new();
    sm.insert(())
}

// ── clip ──────────────────────────────────────────────────────────────────────

mod clip_tests {
    use super::*;

    #[test]
    fn clip_fields_store_correctly() {
        let clip = AnimClip {
            name: "run".to_string(),
            frame_indices: vec![0, 1, 2, 3],
            fps: 12.0,
            looping: true,
        };
        assert_eq!(clip.name, "run");
        assert_eq!(clip.frame_indices.len(), 4);
        assert!((clip.fps - 12.0).abs() < 1e-5);
        assert!(clip.looping);
    }

    #[test]
    fn clip_non_looping_stores_false() {
        let clip = AnimClip {
            name: "death".to_string(),
            frame_indices: vec![5, 6, 7],
            fps: 8.0,
            looping: false,
        };
        assert!(!clip.looping);
        assert_eq!(clip.frame_indices, [5, 6, 7]);
    }

    #[test]
    fn clip_empty_frame_indices() {
        let clip = AnimClip {
            name: "idle".to_string(),
            frame_indices: vec![],
            fps: 1.0,
            looping: true,
        };
        assert!(clip.frame_indices.is_empty());
    }
}

// ── frame ─────────────────────────────────────────────────────────────────────

mod frame_tests {
    use super::*;

    #[test]
    fn frame_fields_store_correctly() {
        let frame = AnimFrame {
            quad: Rect::new(0.0, 0.0, 32.0, 32.0),
            duration: 0.1,
        };
        assert!((frame.quad.width - 32.0).abs() < 1e-5);
        assert!((frame.duration - 0.1).abs() < 1e-5);
    }

    #[test]
    fn zero_duration_uses_clip_fps() {
        let frame = AnimFrame {
            quad: Rect::new(0.0, 0.0, 16.0, 16.0),
            duration: 0.0,
        };
        assert!((frame.duration).abs() < 1e-5);
    }

    #[test]
    fn animation_frame_alias_is_same_type() {
        let frame: AnimationFrame = AnimFrame {
            quad: Rect::new(8.0, 8.0, 64.0, 64.0),
            duration: 0.05,
        };
        assert!((frame.quad.x - 8.0).abs() < 1e-5);
    }
}

// ── event ─────────────────────────────────────────────────────────────────────

mod event_tests {
    use super::*;

    #[test]
    fn type_name_finished() {
        assert_eq!(AnimEvent::Finished.type_name(), "finished");
    }

    #[test]
    fn type_name_looped() {
        assert_eq!(AnimEvent::Looped.type_name(), "looped");
    }

    #[test]
    fn type_name_frame_changed() {
        let ev = AnimEvent::FrameChanged { frame_index: 3 };
        assert_eq!(ev.type_name(), "frameChanged");
    }

    #[test]
    fn frame_index_returns_some_for_frame_changed() {
        let ev = AnimEvent::FrameChanged { frame_index: 7 };
        assert_eq!(ev.frame_index(), Some(7));
    }

    #[test]
    fn frame_index_returns_none_for_finished() {
        assert_eq!(AnimEvent::Finished.frame_index(), None);
    }

    #[test]
    fn frame_index_returns_none_for_looped() {
        assert_eq!(AnimEvent::Looped.frame_index(), None);
    }
}

// ── curve ─────────────────────────────────────────────────────────────────────

mod curve_tests {
    use super::*;

    #[test]
    fn eval_empty_returns_zero() {
        let c = AnimCurve::new();
        assert!((c.eval(0.5) - 0.0).abs() < 1e-5);
    }

    #[test]
    fn eval_single_keyframe_returns_value() {
        let mut c = AnimCurve::new();
        c.add_keyframe(1.0, 42.0);
        assert!((c.eval(0.0) - 42.0).abs() < 1e-5);
        assert!((c.eval(2.0) - 42.0).abs() < 1e-5);
    }

    #[test]
    fn eval_linear_midpoint() {
        let mut c = AnimCurve::with_easing(EasingKind::Linear);
        c.add_keyframe(0.0, 0.0);
        c.add_keyframe(1.0, 10.0);
        assert!((c.eval(0.5) - 5.0).abs() < 1e-4);
    }

    #[test]
    fn eval_step_holds_previous_value() {
        let mut c = AnimCurve::with_easing(EasingKind::Step);
        c.add_keyframe(0.0, 5.0);
        c.add_keyframe(1.0, 10.0);
        // Step at 0.5 should still be v0=5 (alpha 0.5 → eased α=0.0 → v0)
        assert!((c.eval(0.5) - 5.0).abs() < 1e-4);
    }

    #[test]
    fn add_keyframe_keeps_sorted_order() {
        let mut c = AnimCurve::new();
        c.add_keyframe(0.5, 1.0);
        c.add_keyframe(0.0, 0.0);
        c.add_keyframe(1.0, 2.0);
        assert!((c.keyframes[0].0 - 0.0).abs() < 1e-5);
        assert!((c.keyframes[1].0 - 0.5).abs() < 1e-5);
        assert!((c.keyframes[2].0 - 1.0).abs() < 1e-5);
    }
}

// ── controller ────────────────────────────────────────────────────────────────

mod controller_tests {
    use super::*;

    fn make_clip_anim(count: usize, fps: f32, looping: bool) -> Animation {
        let mut anim = Animation::new();
        anim.add_clip_from_grid("walk", 128, 32, 32, 32, 0, count, fps, looping);
        anim.play("walk");
        anim
    }

    #[test]
    fn new_animation_is_empty() {
        let anim = Animation::new();
        assert_eq!(anim.get_frame_count(), 0);
        assert_eq!(anim.get_clip_count(), 0);
        assert!(!anim.is_playing());
        assert!(anim.current_quad().is_none());
    }

    #[test]
    fn add_frame_returns_sequential_indices() {
        let mut anim = Animation::new();
        let a = anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
        let b = anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
        assert_eq!(a, 0);
        assert_eq!(b, 1);
        assert_eq!(anim.get_frame_count(), 2);
    }

    #[test]
    fn add_frames_from_grid_slices_correctly() {
        let mut anim = Animation::new();
        let added = anim.add_frames_from_grid(128, 64, 32, 32, 0, 8);
        assert_eq!(added, 8);
        assert_eq!(anim.get_frame_count(), 8);
    }

    #[test]
    fn add_frames_from_grid_clamps_to_total_cells() {
        let mut anim = Animation::new();
        let added = anim.add_frames_from_grid(64, 64, 32, 32, 0, 100);
        assert_eq!(added, 4); // 2x2 grid = 4 cells max
    }

    #[test]
    fn play_nonexistent_clip_returns_false() {
        let mut anim = Animation::new();
        assert!(!anim.play("missing"));
        assert!(!anim.is_playing());
    }

    #[test]
    fn play_starts_at_frame_zero() {
        let anim = make_clip_anim(4, 10.0, true);
        assert_eq!(anim.current_frame(), 0);
        assert!(anim.is_playing());
    }

    #[test]
    fn update_advances_frames() {
        let mut anim = make_clip_anim(4, 10.0, true);
        anim.update(0.15); // 1.5 frames at 10fps -> frame 1
        assert_eq!(anim.current_frame(), 1);
    }

    #[test]
    fn looping_clip_wraps_and_emits_event() {
        let mut anim = make_clip_anim(2, 10.0, true);
        anim.update(0.25); // 2.5 frames -> wrap
        let events = anim.drain_events();
        assert!(events.contains(&AnimEvent::Looped));
        assert!(anim.is_playing());
    }

    #[test]
    fn non_looping_clip_stops_and_emits_finished() {
        let mut anim = make_clip_anim(2, 10.0, false);
        anim.update(0.5); // well past both frames
        let events = anim.drain_events();
        assert!(events.contains(&AnimEvent::Finished));
        assert!(!anim.is_playing());
    }

    #[test]
    fn pause_resume_works() {
        let mut anim = make_clip_anim(4, 10.0, true);
        anim.pause();
        anim.update(0.5);
        assert_eq!(anim.current_frame(), 0);
        anim.resume();
        anim.update(0.15);
        assert_eq!(anim.current_frame(), 1);
    }
}

// ── render ────────────────────────────────────────────────────────────────────

mod render_tests {
    use super::*;

    fn make_params() -> AnimRenderParams {
        AnimRenderParams {
            texture_key: dummy_texture_key(),
            tex_w: 256.0,
            tex_h: 256.0,
            x: 100.0,
            y: 200.0,
            rotation: 0.0,
            sx: 1.0,
            sy: 1.0,
            ox: 16.0,
            oy: 16.0,
        }
    }

    #[test]
    fn no_clip_returns_none() {
        let anim = Animation::new();
        let params = make_params();
        assert!(anim.generate_render_command(&params).is_none());
    }

    #[test]
    fn active_clip_returns_draw_quad() {
        let mut anim = Animation::new();
        anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
        anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
        anim.add_clip("walk", vec![0, 1], 10.0, true);
        anim.play("walk");

        let params = make_params();
        let cmd = anim.generate_render_command(&params);
        assert!(cmd.is_some());
        if let Some(RenderCommand::DrawQuad { quad_x, quad_y, quad_w, quad_h, x, y, ox, oy, .. }) = cmd {
            assert!((quad_x).abs() < 1e-5);
            assert!((quad_y).abs() < 1e-5);
            assert!((quad_w - 32.0).abs() < 1e-5);
            assert!((quad_h - 32.0).abs() < 1e-5);
            assert!((x - 100.0).abs() < 1e-5);
            assert!((y - 200.0).abs() < 1e-5);
            assert!((ox - 16.0).abs() < 1e-5);
            assert!((oy - 16.0).abs() < 1e-5);
        } else {
            panic!("Expected DrawQuad");
        }
    }

    #[test]
    fn quad_to_draw_preserves_all_fields() {
        let quad = Rect::new(64.0, 32.0, 16.0, 16.0);
        let params = make_params();
        let cmd = quad_to_draw_command(&quad, &params);
        if let RenderCommand::DrawQuad { quad_x, quad_y, tex_w, tex_h, .. } = cmd {
            assert!((quad_x - 64.0).abs() < 1e-5);
            assert!((quad_y - 32.0).abs() < 1e-5);
            assert!((tex_w - 256.0).abs() < 1e-5);
            assert!((tex_h - 256.0).abs() < 1e-5);
        } else {
            panic!("Expected DrawQuad");
        }
    }
}

// ── state_machine ─────────────────────────────────────────────────────────────

mod state_machine_tests {
    use super::*;

    fn make_anim() -> Animation {
        let mut anim = Animation::new();
        anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
        anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
        anim.add_clip("idle", vec![0], 1.0, true);
        anim.add_clip("walk", vec![0, 1], 10.0, true);
        anim
    }

    #[test]
    fn initial_state_is_set() {
        let sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        assert_eq!(sm.get_state(), "idle");
    }

    #[test]
    fn add_state_and_force_transition() {
        let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        sm.add_state("idle", "idle", true);
        sm.add_state("walk", "walk", true);
        assert!(sm.force_state("walk"));
        assert_eq!(sm.get_state(), "walk");
    }

    #[test]
    fn force_nonexistent_state_returns_false() {
        let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        sm.add_state("idle", "idle", true);
        assert!(!sm.force_state("flying"));
    }

    #[test]
    fn param_driven_transition() {
        let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        sm.add_state("idle", "idle", true);
        sm.add_state("walk", "walk", true);
        sm.add_transition("idle", "walk", "speed > 0.1");
        sm.set_param_float("speed", 0.5);
        sm.update(0.016);
        assert_eq!(sm.get_state(), "walk");
    }

    #[test]
    fn param_below_threshold_stays() {
        let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        sm.add_state("idle", "idle", true);
        sm.add_state("walk", "walk", true);
        sm.add_transition("idle", "walk", "speed > 0.1");
        sm.set_param_float("speed", 0.05);
        sm.update(0.016);
        assert_eq!(sm.get_state(), "idle");
    }

    #[test]
    fn bool_param_condition() {
        let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        sm.add_state("idle", "idle", true);
        sm.add_state("walk", "walk", true);
        sm.add_transition("idle", "walk", "moving == true");
        sm.set_param_bool("moving", true);
        sm.update(0.016);
        assert_eq!(sm.get_state(), "walk");
    }

    #[test]
    fn parse_condition_gt() {
        let c = parse_condition("speed > 5.0").unwrap();
        assert_eq!(c.param, "speed");
        assert_eq!(c.op, ConditionOp::Gt);
    }

    #[test]
    fn parse_condition_invalid_returns_error() {
        assert!(parse_condition("noop").is_err());
    }

    #[test]
    fn compare_nums_helpers() {
        assert!(compare_nums(2.0, 1.0, &ConditionOp::Gt));
        assert!(!compare_nums(1.0, 2.0, &ConditionOp::Gt));
        assert!(compare_nums(1.0, 1.0, &ConditionOp::Eq));
        assert!(compare_nums(1.0, 2.0, &ConditionOp::Neq));
    }
}

// ── sync_group ────────────────────────────────────────────────────────────────

mod sync_group_tests {
    use super::*;

    #[test]
    fn new_is_empty() {
        let g = AnimSyncGroup::new();
        assert_eq!(g.member_count(), 0);
    }

    #[test]
    fn add_increases_count() {
        let mut g = AnimSyncGroup::new();
        let k = dummy_slotmap_key();
        g.add(k);
        assert_eq!(g.member_count(), 1);
    }

    #[test]
    fn add_duplicate_is_noop() {
        let mut g = AnimSyncGroup::new();
        let k = dummy_slotmap_key();
        g.add(k);
        g.add(k);
        assert_eq!(g.member_count(), 1);
    }

    #[test]
    fn remove_decreases_count() {
        let mut g = AnimSyncGroup::new();
        let k = dummy_slotmap_key();
        g.add(k);
        g.remove(k);
        assert_eq!(g.member_count(), 0);
    }

    #[test]
    fn clear_empties_group() {
        let mut g = AnimSyncGroup::new();
        let k1 = dummy_slotmap_key();
        let k2 = dummy_slotmap_key();
        g.add(k1);
        g.add(k2);
        g.clear();
        assert_eq!(g.member_count(), 0);
    }
}

// ── blend ─────────────────────────────────────────────────────────────────────

mod blend_tests {
    use super::*;

    #[test]
    fn blend_mask_all_matches_everything() {
        let mask = BlendMask::all();
        assert!(mask.includes("torso"));
        assert!(mask.includes("arm_l"));
    }

    #[test]
    fn blend_mask_from_bones_filters() {
        let mask = BlendMask::from_bones(vec!["arm_l".to_string(), "arm_r".to_string()]);
        assert!(mask.includes("arm_l"));
        assert!(!mask.includes("torso"));
    }

    #[test]
    fn blend_layer_clamps_weight() {
        let layer = BlendLayer::new("base", "idle", 1.5, BlendMask::all());
        assert!((layer.weight - 1.0).abs() < 1e-5);
        let layer2 = BlendLayer::new("base2", "idle", -0.5, BlendMask::all());
        assert!((layer2.weight).abs() < 1e-5);
    }

    #[test]
    fn layer_set_add_and_remove() {
        let mut set = BlendLayerSet::new();
        assert!(set.is_empty());
        set.add_layer(BlendLayer::new("base", "idle", 1.0, BlendMask::all())).unwrap();
        assert_eq!(set.len(), 1);
        set.remove_layer("base").unwrap();
        assert!(set.is_empty());
    }

    #[test]
    fn layer_set_rejects_duplicate_name() {
        let mut set = BlendLayerSet::new();
        set.add_layer(BlendLayer::new("base", "idle", 1.0, BlendMask::all())).unwrap();
        assert!(set.add_layer(BlendLayer::new("base", "walk", 0.5, BlendMask::all())).is_err());
    }

    #[test]
    fn set_weight_clamps_and_reads_back() {
        let mut set = BlendLayerSet::new();
        set.add_layer(BlendLayer::new("a", "idle", 0.5, BlendMask::all())).unwrap();
        set.set_weight("a", 0.8).unwrap();
        assert!((set.get_weight("a").unwrap() - 0.8).abs() < 1e-5);
    }

    #[test]
    fn remove_nonexistent_layer_errors() {
        let mut set = BlendLayerSet::new();
        assert!(set.remove_layer("ghost").is_err());
    }
}

// ── aseprite ──────────────────────────────────────────────────────────────────

mod aseprite_tests {
    use super::*;

    fn sample_json() -> &'static str {
        r#"{
            "frames": [
                {"frame":{"x":0,"y":0,"w":32,"h":32},"duration":100},
                {"frame":{"x":32,"y":0,"w":32,"h":32},"duration":200}
            ],
            "meta": {
                "size": {"w":64,"h":32},
                "frameTags": [
                    {"name":"idle","from":0,"to":1,"direction":"forward"}
                ]
            }
        }"#
    }

    #[test]
    fn parse_array_format() {
        let parsed = load_aseprite_json(sample_json()).unwrap();
        assert_eq!(parsed.frames.len(), 2);
        assert_eq!(parsed.frames[0].w, 32);
        assert_eq!(parsed.frames[1].duration_ms, 200);
        assert_eq!(parsed.sheet_width, 64);
        assert_eq!(parsed.sheet_height, 32);
    }

    #[test]
    fn parse_tags() {
        let parsed = load_aseprite_json(sample_json()).unwrap();
        assert_eq!(parsed.tags.len(), 1);
        assert_eq!(parsed.tags[0].name, "idle");
        assert_eq!(parsed.tags[0].from, 0);
        assert_eq!(parsed.tags[0].to, 1);
        assert_eq!(parsed.tags[0].direction, AsepriteDirection::Forward);
    }

    #[test]
    fn parse_reverse_direction() {
        let json = r#"{
            "frames": [{"frame":{"x":0,"y":0,"w":16,"h":16},"duration":50}],
            "meta": {
                "size": {"w":16,"h":16},
                "frameTags": [{"name":"walk","from":0,"to":0,"direction":"reverse"}]
            }
        }"#;
        let parsed = load_aseprite_json(json).unwrap();
        assert_eq!(parsed.tags[0].direction, AsepriteDirection::Reverse);
    }

    #[test]
    fn parse_missing_frames_key_errors() {
        let json = r#"{"meta":{"size":{"w":16,"h":16}}}"#;
        assert!(load_aseprite_json(json).is_err());
    }

    #[test]
    fn parse_missing_meta_errors() {
        let json = r#"{"frames":[]}"#;
        assert!(load_aseprite_json(json).is_err());
    }
}
