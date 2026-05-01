//! INTERNAL ONLY: public `lurek.spine.*` behavior is covered by the Lua-first suites in
//! `tests/lua/unit/test_spine_unit.lua` and `tests/lua/evidence/test_spine_evidence.lua`.
//!
//! The remaining Rust coverage here exercises low-level skeleton data types,
//! IK solving, and timeline interpolation helpers that are more direct and more
//! precise to assert at the Rust layer.

use lurek2d::spine::*;

// ── bone ──────────────────────────────────────────────────────────────

mod bone_tests {
    use super::*;

    #[test]
    fn new_has_identity_transform() {
        let b = Bone::new("root");
        assert_eq!(b.name, "root");
        assert!(b.parent_index.is_none());
        assert_eq!(b.local_x, 0.0);
        assert_eq!(b.local_y, 0.0);
        assert_eq!(b.local_rotation, 0.0);
        assert_eq!(b.local_scale_x, 1.0);
        assert_eq!(b.local_scale_y, 1.0);
    }

    #[test]
    fn with_parent_sets_fields() {
        let b = Bone::with_parent("arm", 0, 10.0, 5.0);
        assert_eq!(b.name, "arm");
        assert_eq!(b.parent_index, Some(0));
        assert_eq!(b.local_x, 10.0);
        assert_eq!(b.local_y, 5.0);
        assert_eq!(b.local_scale_x, 1.0);
    }

    #[test]
    fn world_fields_default_to_zero() {
        let b = Bone::new("test");
        assert_eq!(b.world_x, 0.0);
        assert_eq!(b.world_y, 0.0);
        assert_eq!(b.world_rotation, 0.0);
    }
}

// ── slot ──────────────────────────────────────────────────────────────

mod slot_tests {

    use lurek2d::spine::slot::Slot;

    #[test]
    fn new_defaults_to_white() {
        let s = Slot::new("body", 0);
        assert_eq!(s.name, "body");
        assert_eq!(s.bone_index, 0);
        assert_eq!(s.color_r, 1.0);
        assert_eq!(s.color_g, 1.0);
        assert_eq!(s.color_b, 1.0);
        assert_eq!(s.color_a, 1.0);
    }

    #[test]
    fn new_has_no_attachment() {
        let s = Slot::new("hat", 2);
        assert!(s.attachment_name.is_none());
        assert_eq!(s.draw_order, 0);
    }
}

// ── ik ────────────────────────────────────────────────────────────────

mod ik_tests {
    use super::*;

    #[test]
    fn new_defaults_target_to_origin() {
        let ik = IKConstraint::new("arm_ik", vec![0, 1], true);
        assert_eq!(ik.name, "arm_ik");
        assert_eq!(ik.target_x, 0.0);
        assert_eq!(ik.target_y, 0.0);
        assert!(ik.bend_positive);
    }

    #[test]
    fn set_target_updates_position() {
        let mut ik = IKConstraint::new("leg", vec![0, 1], false);
        ik.set_target(5.0, 10.0);
        assert_eq!(ik.target_x, 5.0);
        assert_eq!(ik.target_y, 10.0);
    }

    #[test]
    fn solve_skips_short_chain() {
        let mut bones = vec![Bone::new("root")];
        let ik = IKConstraint::new("bad", vec![0], true);
        ik.solve(&mut bones);
        assert_eq!(bones[0].local_rotation, 0.0);
    }

    #[test]
    fn solve_skips_out_of_range_indices() {
        let mut bones = vec![Bone::new("root")];
        let ik = IKConstraint::new("bad", vec![0, 99], true);
        ik.solve(&mut bones);
        assert_eq!(bones[0].local_rotation, 0.0);
    }

    #[test]
    fn solve_writes_rotations() {
        let mut bones = vec![Bone::new("root"), Bone::with_parent("elbow", 0, 10.0, 0.0)];
        // Place elbow in world space for the solver
        bones[1].world_x = 10.0;
        bones[1].world_y = 0.0;

        let mut ik = IKConstraint::new("arm", vec![0, 1], true);
        ik.set_target(15.0, 5.0);
        ik.solve(&mut bones);

        // After solving, rotations should have changed from the initial 0.0
        assert!(bones[0].local_rotation != 0.0 || bones[1].local_rotation != 0.0);
    }
}

// ── timeline ──────────────────────────────────────────────────────────

mod timeline_tests {

    use lurek2d::spine::timeline::{
        BoneProperty, BoneTimeline, EasingType, EventKeyframe, SkeletonAnimation,
    };

    // ── EasingType ────────────────────────────────────────────────────

    #[test]
    fn linear_easing_passthrough() {
        assert_eq!(EasingType::Linear.apply(0.0), 0.0);
        assert_eq!(EasingType::Linear.apply(0.5), 0.5);
        assert_eq!(EasingType::Linear.apply(1.0), 1.0);
    }

    #[test]
    fn ease_in_starts_slow() {
        let mid = EasingType::EaseIn.apply(0.5);
        assert!(mid < 0.5, "EaseIn(0.5) = {mid}, expected < 0.5");
    }

    #[test]
    fn ease_out_ends_slow() {
        let mid = EasingType::EaseOut.apply(0.5);
        assert!(mid > 0.5, "EaseOut(0.5) = {mid}, expected > 0.5");
    }

    #[test]
    fn ease_in_out_symmetric() {
        let v = EasingType::EaseInOut.apply(0.5);
        assert!(
            (v - 0.5).abs() < 0.01,
            "EaseInOut(0.5) = {v}, expected ~0.5"
        );
    }

    #[test]
    fn step_returns_zero() {
        assert_eq!(EasingType::Step.apply(0.5), 0.0);
    }

    #[test]
    fn easing_clamps_input() {
        assert_eq!(EasingType::Linear.apply(-1.0), 0.0);
        assert_eq!(EasingType::Linear.apply(2.0), 1.0);
    }

    // ── BoneTimeline ──────────────────────────────────────────────────

    #[test]
    fn empty_timeline_evaluates_to_zero() {
        let tl = BoneTimeline::new(0, BoneProperty::X);
        assert_eq!(tl.evaluate(1.0), 0.0);
    }

    #[test]
    fn single_keyframe_returns_value() {
        let mut tl = BoneTimeline::new(0, BoneProperty::X);
        tl.add_key(0.0, 5.0, EasingType::Linear);
        assert_eq!(tl.evaluate(0.0), 5.0);
        assert_eq!(tl.evaluate(10.0), 5.0);
    }

    #[test]
    fn linear_interpolation() {
        let mut tl = BoneTimeline::new(0, BoneProperty::Y);
        tl.add_key(0.0, 0.0, EasingType::Linear);
        tl.add_key(1.0, 10.0, EasingType::Linear);
        let v = tl.evaluate(0.5);
        assert!((v - 5.0).abs() < 0.01, "expected ~5.0, got {v}");
    }

    #[test]
    fn before_first_key_returns_first_value() {
        let mut tl = BoneTimeline::new(0, BoneProperty::X);
        tl.add_key(1.0, 3.0, EasingType::Linear);
        tl.add_key(2.0, 6.0, EasingType::Linear);
        assert_eq!(tl.evaluate(0.0), 3.0);
    }

    #[test]
    fn after_last_key_returns_last_value() {
        let mut tl = BoneTimeline::new(0, BoneProperty::X);
        tl.add_key(0.0, 1.0, EasingType::Linear);
        tl.add_key(1.0, 9.0, EasingType::Linear);
        assert_eq!(tl.evaluate(5.0), 9.0);
    }

    #[test]
    fn step_easing_holds_previous() {
        let mut tl = BoneTimeline::new(0, BoneProperty::Rotation);
        tl.add_key(0.0, 0.0, EasingType::Step);
        tl.add_key(1.0, 90.0, EasingType::Linear);
        assert_eq!(tl.evaluate(0.5), 0.0); // step holds at 0
    }

    #[test]
    fn add_key_maintains_sorted_order() {
        let mut tl = BoneTimeline::new(0, BoneProperty::X);
        tl.add_key(2.0, 20.0, EasingType::Linear);
        tl.add_key(0.0, 0.0, EasingType::Linear);
        tl.add_key(1.0, 10.0, EasingType::Linear);
        assert_eq!(tl.keys[0].time, 0.0);
        assert_eq!(tl.keys[1].time, 1.0);
        assert_eq!(tl.keys[2].time, 2.0);
    }

    // ── EventKeyframe ─────────────────────────────────────────────────

    #[test]
    fn event_keyframe_new() {
        let e = EventKeyframe::new(0.5, "footstep", 1.0);
        assert_eq!(e.time, 0.5);
        assert_eq!(e.name, "footstep");
        assert_eq!(e.value, 1.0);
    }

    // ── SkeletonAnimation ─────────────────────────────────────────────

    #[test]
    fn collect_events_in_range() {
        let mut anim = SkeletonAnimation::new("walk", 2.0);
        anim.add_event_key(0.5, "step_left", 0.0);
        anim.add_event_key(1.0, "step_right", 0.0);
        anim.add_event_key(1.5, "step_left", 0.0);

        let events = anim.collect_events(0.3, 1.0);
        assert_eq!(events.len(), 2);
        assert_eq!(events[0].0, "step_left");
        assert_eq!(events[1].0, "step_right");
    }

    #[test]
    fn collect_events_empty_range() {
        let mut anim = SkeletonAnimation::new("idle", 1.0);
        anim.add_event_key(0.5, "blink", 0.0);
        let events = anim.collect_events(0.6, 1.0);
        assert!(events.is_empty());
    }
}

// ── skeleton ──────────────────────────────────────────────────────────

mod skeleton_tests {
    use super::*;
    use lurek2d::spine::slot::Slot;
    use lurek2d::spine::timeline::{BoneProperty, BoneTimeline, EasingType, SkeletonAnimation};

    #[test]
    fn new_skeleton_is_empty() {
        let skel = Skeleton::new("hero");
        assert_eq!(skel.name, "hero");
        assert!(skel.bones.is_empty());
        assert!(skel.slots.is_empty());
        assert_eq!(skel.x, 0.0);
        assert_eq!(skel.y, 0.0);
        assert_eq!(skel.scale_x, 1.0);
        assert_eq!(skel.scale_y, 1.0);
    }

    #[test]
    fn add_bone_returns_incrementing_index() {
        let mut skel = Skeleton::new("test");
        assert_eq!(skel.add_bone(Bone::new("root")), 0);
        assert_eq!(skel.add_bone(Bone::with_parent("arm", 0, 5.0, 0.0)), 1);
        assert_eq!(skel.bone_count(), 2);
    }

    #[test]
    fn add_slot_returns_incrementing_index() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        assert_eq!(skel.add_slot(Slot::new("body", 0)), 0);
        assert_eq!(skel.add_slot(Slot::new("hat", 0)), 1);
        assert_eq!(skel.slot_count(), 2);
    }

    #[test]
    fn find_bone_by_name() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        skel.add_bone(Bone::with_parent("arm", 0, 5.0, 0.0));
        assert_eq!(skel.find_bone("arm"), Some(1));
        assert_eq!(skel.find_bone("missing"), None);
    }

    #[test]
    fn find_slot_by_name() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        skel.add_slot(Slot::new("body", 0));
        assert_eq!(skel.find_slot("body"), Some(0));
        assert_eq!(skel.find_slot("missing"), None);
    }

    #[test]
    fn add_bone_full_with_params() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        let idx = skel.add_bone_full(BoneParams {
            name: "leg".to_string(),
            parent_index: Some(0),
            x: 3.0,
            y: -5.0,
            rotation: 0.1,
            scale_x: 1.0,
            scale_y: 1.0,
        });
        assert_eq!(idx, 1);
        assert_eq!(skel.bones[idx].local_x, 3.0);
        assert_eq!(skel.bones[idx].local_y, -5.0);
        assert_eq!(skel.bones[idx].local_rotation, 0.1);
    }

    #[test]
    fn bone_world_transform_in_range() {
        let mut skel = Skeleton::new("test");
        let mut b = Bone::new("root");
        b.world_x = 10.0;
        b.world_y = 20.0;
        b.world_rotation = 0.5;
        b.world_scale_x = 2.0;
        b.world_scale_y = 3.0;
        skel.add_bone(b);
        let t = skel.bone_world_transform(0).unwrap();
        assert_eq!(t, (10.0, 20.0, 0.5, 2.0, 3.0));
    }

    #[test]
    fn bone_world_transform_out_of_range() {
        let skel = Skeleton::new("test");
        assert!(skel.bone_world_transform(0).is_none());
    }

    #[test]
    fn update_world_transforms_root_bone() {
        let mut skel = Skeleton::new("test");
        skel.x = 100.0;
        skel.y = 200.0;
        let mut root = Bone::new("root");
        root.local_x = 10.0;
        root.local_y = 20.0;
        skel.add_bone(root);
        skel.update_world_transforms();
        let b = &skel.bones[0];
        assert_eq!(b.world_x, 110.0);
        assert_eq!(b.world_y, 220.0);
    }

    #[test]
    fn update_world_transforms_child_bone() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        skel.add_bone(Bone::with_parent("child", 0, 10.0, 0.0));
        skel.update_world_transforms();
        let child = &skel.bones[1];
        assert_eq!(child.world_x, 10.0);
        assert_eq!(child.world_y, 0.0);
    }

    #[test]
    fn set_root_position_propagates() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        skel.add_bone(Bone::with_parent("child", 0, 5.0, 0.0));
        skel.set_root_position(50.0, 60.0);
        assert_eq!(skel.bones[0].world_x, 50.0);
        assert_eq!(skel.bones[0].world_y, 60.0);
    }

    #[test]
    fn play_animation_unknown_returns_false() {
        let mut skel = Skeleton::new("test");
        assert!(!skel.play_animation("missing", false));
    }

    #[test]
    fn play_and_stop_animation() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        let anim = SkeletonAnimation::new("walk", 1.0);
        skel.add_animation(anim);
        assert!(skel.play_animation("walk", true));
        assert!(skel.anim_playing);
        skel.stop_animation();
        assert!(!skel.anim_playing);
    }

    #[test]
    fn update_animation_advances_time() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        let mut anim = SkeletonAnimation::new("idle", 2.0);
        let mut tl = BoneTimeline::new(0, BoneProperty::X);
        tl.add_key(0.0, 0.0, EasingType::Linear);
        tl.add_key(2.0, 10.0, EasingType::Linear);
        anim.add_timeline(tl);
        skel.add_animation(anim);
        skel.play_animation("idle", false);
        skel.update_animation(0.5);
        assert!((skel.get_animation_time() - 0.5).abs() < 0.01);
    }

    #[test]
    fn animation_loops_wraps_time() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        let anim = SkeletonAnimation::new("run", 1.0);
        skel.add_animation(anim);
        skel.play_animation("run", true);
        skel.update_animation(1.5);
        assert!(skel.get_animation_time() < 1.0);
        assert!(skel.anim_playing);
    }

    #[test]
    fn animation_non_loop_stops_at_end() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        let anim = SkeletonAnimation::new("die", 1.0);
        skel.add_animation(anim);
        skel.play_animation("die", false);
        skel.update_animation(2.0);
        assert!(!skel.anim_playing);
        assert!((skel.get_animation_time() - 1.0).abs() < 0.01);
    }

    #[test]
    fn add_ik_constraint_returns_index() {
        let mut skel = Skeleton::new("test");
        let ik = IKConstraint::new("arm_ik", vec![0, 1], true);
        assert_eq!(skel.add_ik_constraint(ik), 0);
    }

    #[test]
    fn set_ik_target_found() {
        let mut skel = Skeleton::new("test");
        skel.add_ik_constraint(IKConstraint::new("arm", vec![0, 1], true));
        assert!(skel.set_ik_target("arm", 10.0, 20.0));
    }

    #[test]
    fn set_ik_target_not_found() {
        let mut skel = Skeleton::new("test");
        assert!(!skel.set_ik_target("missing", 0.0, 0.0));
    }

    #[test]
    fn skin_management() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        skel.add_slot(Slot::new("body", 0));
        skel.add_skin("default");
        skel.set_skin_mapping("default", "body", "body_normal");
        assert!(skel.set_skin("default"));
        assert_eq!(skel.get_skin(), Some("default"));
        assert!(!skel.set_skin("nonexistent"));
    }

    #[test]
    fn get_slot_attachment_with_skin_override() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        let mut slot = Slot::new("body", 0);
        slot.attachment_name = Some("default_body".to_string());
        skel.add_slot(slot);

        // Without skin, returns slot's own attachment
        assert_eq!(skel.get_slot_attachment(0), Some("default_body"));

        // With skin override
        skel.add_skin("armored");
        skel.set_skin_mapping("armored", "body", "armored_body");
        skel.set_skin("armored");
        assert_eq!(skel.get_slot_attachment(0), Some("armored_body"));
    }

    #[test]
    fn get_slot_attachment_out_of_range() {
        let skel = Skeleton::new("test");
        assert!(skel.get_slot_attachment(99).is_none());
    }

    #[test]
    fn add_slot_full_sets_attachment() {
        let mut skel = Skeleton::new("test");
        skel.add_bone(Bone::new("root"));
        let idx = skel.add_slot_full("hat", 0, Some("wizard_hat".to_string()));
        assert_eq!(
            skel.slots[idx].attachment_name.as_deref(),
            Some("wizard_hat")
        );
    }

    #[test]
    fn find_animation_by_name() {
        let mut skel = Skeleton::new("test");
        skel.add_animation(SkeletonAnimation::new("walk", 1.0));
        skel.add_animation(SkeletonAnimation::new("run", 0.5));
        assert_eq!(skel.find_animation("run"), Some(1));
        assert_eq!(skel.find_animation("missing"), None);
    }
}

// ── render ────────────────────────────────────────────────────────────

mod render_tests {
    use super::*;
    use lurek2d::render::renderer::{DrawMode, RenderCommand};

    fn make_skeleton_with_bone() -> Skeleton {
        let mut skel = Skeleton::new("test");
        let mut bone = Bone::new("root");
        // Set world transform directly (update_world_transforms would normally compute these).
        bone.world_x = 10.0;
        bone.world_y = 20.0;
        skel.bones.push(bone);
        skel
    }

    #[test]
    fn empty_skeleton_gives_no_commands() {
        let skel = Skeleton::new("empty");
        let cmds = skel.generate_render_commands(0.0, 0.0);
        assert!(cmds.is_empty(), "empty skeleton should produce no commands");
    }

    #[test]
    fn skeleton_with_bone_produces_circle() {
        let skel = make_skeleton_with_bone();
        let cmds = skel.generate_render_commands(0.0, 0.0);
        assert!(
            cmds.iter().any(|c| matches!(
                c,
                RenderCommand::Circle {
                    mode: DrawMode::Fill,
                    ..
                }
            )),
            "expected a Fill circle for the bone"
        );
    }

    #[test]
    fn world_offset_shifts_bone_position() {
        let skel = make_skeleton_with_bone();
        let cmds_zero = skel.generate_render_commands(0.0, 0.0);
        let cmds_offset = skel.generate_render_commands(100.0, 0.0);

        let extract_circle_x = |cmds: &[RenderCommand]| -> f32 {
            cmds.iter()
                .find_map(|c| {
                    if let RenderCommand::Circle { x, .. } = c {
                        Some(*x)
                    } else {
                        None
                    }
                })
                .unwrap_or(0.0)
        };

        let x0 = extract_circle_x(&cmds_zero);
        let x1 = extract_circle_x(&cmds_offset);
        assert!(
            (x1 - x0 - 100.0).abs() < 0.01,
            "offset x should shift circle x by 100, got {x0} → {x1}"
        );
    }
}
