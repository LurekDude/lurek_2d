//! INTERNAL ONLY: Rust-only tests for animation internals that are not observable via Lua.

use lurek2d::animation::render::{quad_to_draw_command, AnimRenderParams};
use lurek2d::animation::sync_group::AnimSyncGroup;
use lurek2d::animation::{
    load_aseprite_json, AnimPropertyTimeline, AnimStateMachine, Animation, ClipPlaybackMode,
    SpineAnimBridge,
};
use lurek2d::math::Rect;
use lurek2d::render::renderer::RenderCommand;
use lurek2d::runtime::resource_keys::TextureKey;
use lurek2d::spine::{Skeleton, SkeletonAnimation};
use slotmap::{DefaultKey, KeyData, SlotMap};

fn dummy_texture_key() -> TextureKey {
    TextureKey::from(KeyData::from_ffi(1))
}

fn dummy_slotmap_key() -> DefaultKey {
    let mut sm: SlotMap<DefaultKey, ()> = SlotMap::new();
    sm.insert(())
}

// ── render (Rust-only helper) ────────────────────────────────────────────────

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
    fn quad_to_draw_preserves_all_fields() {
        let quad = Rect::new(64.0, 32.0, 16.0, 16.0);
        let params = make_params();
        let cmd = quad_to_draw_command(&quad, &params);
        if let RenderCommand::DrawQuad {
            quad_x,
            quad_y,
            tex_w,
            tex_h,
            ..
        } = cmd
        {
            assert!((quad_x - 64.0).abs() < 1e-5);
            assert!((quad_y - 32.0).abs() < 1e-5);
            assert!((tex_w - 256.0).abs() < 1e-5);
            assert!((tex_h - 256.0).abs() < 1e-5);
        } else {
            panic!("Expected DrawQuad");
        }
    }
}

// ── sync_group ────────────────────────────────────────────────────────────────

mod sync_group_tests {
    use super::*;

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

mod aseprite_and_playback_tests {
    use super::*;

    #[test]
    fn load_from_aseprite_sets_reverse_mode() {
        let json = r#"{
            "frames": [
                { "frame": { "x": 0, "y": 0, "w": 16, "h": 16 }, "duration": 100 },
                { "frame": { "x": 16, "y": 0, "w": 16, "h": 16 }, "duration": 100 }
            ],
            "meta": {
                "size": { "w": 32, "h": 16 },
                "frameTags": [
                    { "name": "run_back", "from": 0, "to": 1, "direction": "reverse" }
                ]
            }
        }"#;

        let parsed = load_aseprite_json(json).expect("parse failed");
        let anim = Animation::load_from_aseprite(&parsed);
        let clip = anim.get_clip("run_back").expect("clip missing");
        assert_eq!(clip.mode, ClipPlaybackMode::Reverse);
    }

    #[test]
    fn load_from_aseprite_skips_invalid_and_empty_ranges() {
        let json = r#"{
            "frames": [
                { "frame": { "x": 0, "y": 0, "w": 16, "h": 16 }, "duration": 100 }
            ],
            "meta": {
                "size": { "w": 16, "h": 16 },
                "frameTags": [
                    { "name": "bad_range", "from": 2, "to": 1, "direction": "forward" },
                    { "name": "bad_oob", "from": 0, "to": 10, "direction": "forward" }
                ]
            }
        }"#;

        let parsed = load_aseprite_json(json).expect("parse failed");
        let anim = Animation::load_from_aseprite(&parsed);
        assert_eq!(anim.get_clip_count(), 0);
        assert_eq!(anim.get_frame_count(), 1);
    }

    #[test]
    fn pingpong_clip_bounces_between_ends() {
        let mut anim = Animation::new();
        anim.add_frame(Rect::new(0.0, 0.0, 16.0, 16.0));
        anim.add_frame(Rect::new(16.0, 0.0, 16.0, 16.0));
        anim.add_frame(Rect::new(32.0, 0.0, 16.0, 16.0));
        anim.add_clip_with_mode("walk", vec![0, 1, 2], 10.0, true, ClipPlaybackMode::PingPong);
        assert!(anim.play("walk"));

        anim.update(0.11);
        assert_eq!(anim.current_frame(), 1);
        anim.update(0.11);
        assert_eq!(anim.current_frame(), 2);
        anim.update(0.11);
        assert_eq!(anim.current_frame(), 1);
        anim.update(0.11);
        assert_eq!(anim.current_frame(), 0);
    }

    #[test]
    fn load_aseprite_json_random_payloads_do_not_panic() {
        fn pseudo_random_string(seed: u32) -> String {
            let mut s = String::new();
            let mut x = seed;
            for _ in 0..64 {
                x = x.wrapping_mul(1664525).wrapping_add(1013904223);
                let byte = (x & 0x7f) as u8;
                let c = if (32..=126).contains(&byte) {
                    byte as char
                } else {
                    'x'
                };
                s.push(c);
            }
            s
        }

        for seed in 0..256u32 {
            let payload = pseudo_random_string(seed);
            let _ = load_aseprite_json(&payload);
        }
    }

    #[test]
    fn load_aseprite_json_structured_malformed_inputs_do_not_panic() {
        let cases: &[&str] = &[
            // empty
            "",
            // valid JSON but wrong schema
            "{}",
            r#"{"frames": null, "meta": null}"#,
            // partial frames array
            r#"{"frames": [{"frame": {"x": 0}}], "meta": {"size": {}, "frameTags": []}}"#,
            // duration 0
            r#"{"frames": [{"frame": {"x":0,"y":0,"w":16,"h":16},"duration":0}],"meta":{"size":{"w":16,"h":16},"frameTags":[]}}"#,
            // duration very large
            r#"{"frames": [{"frame": {"x":0,"y":0,"w":16,"h":16},"duration":999999999}],"meta":{"size":{"w":16,"h":16},"frameTags":[]}}"#,
            // negative frame coords
            r#"{"frames": [{"frame": {"x":-5,"y":-3,"w":16,"h":16},"duration":100}],"meta":{"size":{"w":16,"h":16},"frameTags":[]}}"#,
            // tag from > to (inverted range)
            r#"{"frames": [{"frame": {"x":0,"y":0,"w":16,"h":16},"duration":100}],"meta":{"size":{"w":16,"h":16},"frameTags":[{"name":"bad","from":5,"to":1,"direction":"forward"}]}}"#,
            // tag referencing out-of-bounds indices
            r#"{"frames": [{"frame": {"x":0,"y":0,"w":16,"h":16},"duration":100}],"meta":{"size":{"w":16,"h":16},"frameTags":[{"name":"oob","from":0,"to":999,"direction":"forward"}]}}"#,
            // unknown direction string
            r#"{"frames": [{"frame": {"x":0,"y":0,"w":16,"h":16},"duration":100}],"meta":{"size":{"w":16,"h":16},"frameTags":[{"name":"t","from":0,"to":0,"direction":"diagonal"}]}}"#,
            // very long name
            &format!(r#"{{"frames":[{{"frame":{{"x":0,"y":0,"w":16,"h":16}},"duration":100}}],"meta":{{"size":{{"w":16,"h":16}},"frameTags":[{{"name":"{name}","from":0,"to":0,"direction":"forward"}}]}}}}"#, name = "x".repeat(4096)),
            // zero size texture
            r#"{"frames": [{"frame": {"x":0,"y":0,"w":0,"h":0},"duration":100}],"meta":{"size":{"w":0,"h":0},"frameTags":[]}}"#,
            // unicode in names
            r#"{"frames":[{"frame":{"x":0,"y":0,"w":16,"h":16},"duration":100}],"meta":{"size":{"w":16,"h":16},"frameTags":[{"name":"🦀 walk","from":0,"to":0,"direction":"forward"}]}}"#,
            // deeply nested junk
            r#"{"frames":[],"meta":{"size":{"w":16,"h":16},"frameTags":[],"deeply":{"nested":{"value":42}}}}"#,
            // truncated at various points
            r#"{"frames":[{"frame""#,
            r#"{"frames":[{"frame":{"x":0"#,
        ];

        for (i, case) in cases.iter().enumerate() {
            let result = std::panic::catch_unwind(|| {
                let _ = load_aseprite_json(case);
            });
            assert!(result.is_ok(), "case #{i} panicked: {case:.80}");
        }
    }

    #[test]
    fn add_frames_from_rects_appends_correct_quads() {
        let mut anim = Animation::new();
        let quads = vec![
            Rect::new(0.0, 0.0, 16.0, 16.0),
            Rect::new(16.0, 0.0, 16.0, 16.0),
            Rect::new(32.0, 0.0, 16.0, 16.0),
        ];
        let added = anim.add_frames_from_rects(&quads);
        assert_eq!(added, 3);
        assert_eq!(anim.get_frame_count(), 3);
        // Verify quads were preserved correctly
        let quad = anim.get_frame_quad(1).expect("frame 1 missing");
        assert_eq!(quad.x, 16.0);
        assert_eq!(quad.y, 0.0);
    }
}

mod state_machine_chain_tests {
    use super::*;

    #[test]
    fn update_can_apply_multi_hop_transition_chain() {
        let mut anim = Animation::new();
        anim.add_frame(Rect::new(0.0, 0.0, 16.0, 16.0));
        anim.add_frame(Rect::new(16.0, 0.0, 16.0, 16.0));
        anim.add_frame(Rect::new(32.0, 0.0, 16.0, 16.0));
        anim.add_clip("idle", vec![0], 8.0, true);
        anim.add_clip("walk", vec![1], 8.0, true);
        anim.add_clip("run", vec![2], 8.0, true);

        let mut sm = AnimStateMachine::new(anim, "idle".to_string());
        sm.add_state("idle", "idle", true);
        sm.add_state("walk", "walk", true);
        sm.add_state("run", "run", true);
        sm.add_transition("idle", "walk", "speed > 0.1");
        sm.add_transition("walk", "run", "speed > 0.8");
        sm.set_param_float("speed", 1.0);

        sm.update(0.016);
        assert_eq!(sm.get_state(), "run");
    }
}

mod property_timeline_tests {
    use super::*;

    #[test]
    fn one_timeline_drives_multiple_properties() {
        let mut timeline = AnimPropertyTimeline::new();
        timeline.add_keyframe(0.0, [("x", 0.0), ("y", 10.0)]);
        timeline.add_keyframe(1.0, [("x", 20.0), ("y", 30.0)]);

        let values = timeline.eval_all(0.5);
        let x = values.get("x").copied().unwrap_or_default();
        let y = values.get("y").copied().unwrap_or_default();
        assert!(x > 0.0 && x < 20.0);
        assert!(y > 10.0 && y < 30.0);
    }
}

mod spine_bridge_tests {
    use super::*;

    fn make_fsm() -> AnimStateMachine {
        let mut anim = Animation::new();
        anim.add_frame(Rect::new(0.0, 0.0, 16.0, 16.0));
        anim.add_frame(Rect::new(16.0, 0.0, 16.0, 16.0));
        anim.add_clip("idle", vec![0], 8.0, true);
        anim.add_clip("run", vec![1], 8.0, true);

        let mut sm = AnimStateMachine::new(anim, "idle".to_string());
        sm.add_state("idle", "idle", true);
        sm.add_state("run", "run", true);
        sm.add_transition("idle", "run", "speed > 0.5");
        sm
    }

    fn make_skeleton_with_anims() -> Skeleton {
        let mut skeleton = Skeleton::new("test");
        skeleton.add_animation(SkeletonAnimation::new("skel_idle", 1.0));
        skeleton.add_animation(SkeletonAnimation::new("skel_run", 1.0));
        skeleton
    }

    #[test]
    fn bridge_applies_mapped_clip_on_state_change() {
        let mut sm = make_fsm();
        sm.set_param_float("speed", 1.0);

        let mut bridge = SpineAnimBridge::new(make_skeleton_with_anims());
        bridge.map("idle", "skel_idle");
        bridge.map("run", "skel_run");

        bridge.update(0.016, &mut sm);

        assert_eq!(sm.get_state(), "run");
        assert_eq!(bridge.last_applied_state(), "run");
        assert_eq!(bridge.get_mapped_clip("run"), Some("skel_run"));
        assert_eq!(bridge.skeleton().current_animation.as_deref(), Some("skel_run"));
    }

    #[test]
    fn bridge_handles_unmapped_state_without_panic() {
        let mut sm = make_fsm();
        sm.set_param_float("speed", 1.0);

        let mut bridge = SpineAnimBridge::new(make_skeleton_with_anims());
        bridge.map("idle", "skel_idle");
        // intentionally no mapping for "run"

        bridge.update(0.016, &mut sm);

        assert_eq!(sm.get_state(), "run");
        assert_eq!(bridge.last_applied_state(), "run");
        assert_eq!(bridge.skeleton().current_animation, None);
    }
}
