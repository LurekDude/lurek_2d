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
    assert_eq!(
        EasingType::from_lua_str("ease_in_out"),
        EasingType::EaseInOut
    );
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
    assert_eq!(
        TransitionType::from_lua_str("crossfade"),
        TransitionType::CrossFade
    );
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

// ── stack (migrated from src/scene/stack.rs) ──────────────────────────────────

mod stack_tests {
    use lurek2d::scene::stack::SceneStack;
    use lurek2d::scene::transition::{EasingType, TransitionType};

    // ── Scene IDs ─────────────────────────────────────────────────────────────

    #[test]
    fn next_scene_id_increments() {
        let mut s = SceneStack::new();
        let id1 = s.next_scene_id();
        let id2 = s.next_scene_id();
        assert!(id2 > id1);
    }

    // ── Push / Pop ────────────────────────────────────────────────────────────

    #[test]
    fn pop_returns_pushed_id() {
        let mut s = SceneStack::new();
        let id = s.next_scene_id();
        s.push(id, TransitionType::None, 0.0, EasingType::Linear);
        let (popped, _) = s
            .pop(TransitionType::None, 0.0, EasingType::Linear)
            .unwrap();
        assert_eq!(popped, id);
    }

    #[test]
    fn pop_empty_stack_returns_err() {
        let mut s = SceneStack::new();
        assert!(s
            .pop(TransitionType::None, 0.0, EasingType::Linear)
            .is_err());
    }

    // ── Overlay ───────────────────────────────────────────────────────────────

    // ── Registry ───────────────────────────────────────────────────────────────

    #[test]
    fn register_and_lookup_scene() {
        let mut s = SceneStack::new();
        let id = s.next_scene_id();
        s.register_scene("main_menu".to_string(), id);
        assert_eq!(s.get_registered("main_menu"), Some(id));
    }

    #[test]
    fn unregistered_name_returns_none() {
        let s = SceneStack::new();
        assert!(s.get_registered("missing").is_none());
    }
}

// ── render (migrated from src/scene/render.rs) ────────────────────────────────

mod render_tests {
    use lurek2d::scene::stack::SceneStack;

    #[test]
    fn generate_render_commands_always_empty() {
        let mut stack = SceneStack::new();
        let _ = stack.next_scene_id();
        let cmds = stack.generate_render_commands();
        assert!(
            cmds.is_empty(),
            "scene stack should return no render commands"
        );
    }

    #[test]
    fn draw_to_image_correct_dimensions() {
        let stack = SceneStack::new();
        let img = stack.draw_to_image(320, 240);
        assert_eq!(img.width(), 320);
        assert_eq!(img.height(), 240);
    }

    #[test]
    fn draw_to_image_returns_dark_background() {
        let stack = SceneStack::new();
        let img = stack.draw_to_image(16, 16);
        if let Some((r, _, _, _)) = img.get_pixel(0, 0) {
            assert!(r < 30, "expected dark background pixel");
        }
    }
}

//  depth_sorter (migrated from src/scene/depth_sorter.rs per TST-02)
//
// NOTE: dropped 5 internal-only tests from src/scene/depth_sorter.rs
// (dirty_flag_set_on_add, dirty_flag_set_on_add_object, dirty_flag_cleared_after_sort,
//  sorted_entries_no_op_when_not_dirty, clear_resets_dirty_flag)  the `dirty`
// field is a private implementation detail; its behaviour is indirectly covered
// by the sort-correctness tests below and by tests/lua/unit/test_scene.lua.

mod depth_sorter_tests {
    use lurek2d::scene::depth_sorter::DepthSorter;

    const RADIX_THRESHOLD: usize = 256;

    //  Sorting (comparison path)

    #[test]
    fn sort_ascending_depth_order() {
        let mut ds = DepthSorter::new();
        ds.add(0, 3.0);
        ds.add(1, 1.0);
        ds.sort();
        let entries = ds.sorted_entries();
        assert!((entries[0].depth - 1.0).abs() < 1e-5);
        assert!((entries[1].depth - 3.0).abs() < 1e-5);
    }

    #[test]
    fn equal_depths_no_panic() {
        let mut ds = DepthSorter::new();
        ds.add(0, 1.0);
        ds.add(1, 1.0);
        ds.sort();
        assert_eq!(ds.get_count(), 2);
    }

    //  Stable sort

    #[test]
    fn stable_sort_preserves_insertion_order_for_equal_depths() {
        let mut ds = DepthSorter::new();
        ds.set_stable(true);
        ds.add(0, 5.0);
        ds.add(1, 5.0);
        ds.add(2, 5.0);
        let entries = ds.sorted_entries();
        assert_eq!(entries[0].callback_index, 0);
        assert_eq!(entries[1].callback_index, 1);
        assert_eq!(entries[2].callback_index, 2);
    }

    #[test]
    fn set_stable_is_stable_round_trip() {
        let mut ds = DepthSorter::new();
        assert!(!ds.is_stable());
        ds.set_stable(true);
        assert!(ds.is_stable());
        ds.set_stable(false);
        assert!(!ds.is_stable());
    }

    //  Radix sort

    #[test]
    fn sort_radix_gives_ascending_order() {
        let mut ds = DepthSorter::new();
        for i in (0..RADIX_THRESHOLD).rev() {
            ds.add(i, i as f32);
        }
        let took_radix = ds.sort_radix();
        assert!(
            took_radix,
            "radix path should be taken for 256 integral-depth entries"
        );
        let entries = ds.sorted_entries();
        for (i, e) in entries.iter().enumerate() {
            assert!((e.depth - i as f32).abs() < 1e-4, "entry {i} out of order");
        }
    }

    #[test]
    fn sort_radix_handles_negative_depths() {
        let mut ds = DepthSorter::new();
        for i in (0..RADIX_THRESHOLD).rev() {
            let depth = i as f32 - (RADIX_THRESHOLD / 2) as f32;
            ds.add(i, depth);
        }
        let took_radix = ds.sort_radix();
        assert!(took_radix);
        let entries = ds.sorted_entries();
        for i in 1..entries.len() {
            assert!(
                entries[i - 1].depth <= entries[i].depth,
                "depth order violated at index {i}"
            );
        }
    }

    #[test]
    fn sort_radix_fallback_for_small_input() {
        let mut ds = DepthSorter::new();
        for i in 0..10 {
            ds.add(i, (10 - i) as f32);
        }
        let took_radix = ds.sort_radix();
        assert!(!took_radix);
        let entries = ds.sorted_entries();
        for i in 1..entries.len() {
            assert!(entries[i - 1].depth <= entries[i].depth);
        }
    }

    //  Mixed add / add_object

    #[test]
    fn add_object_marks_is_object_true() {
        let mut ds = DepthSorter::new();
        ds.add_object(42, 2.0);
        let entries = ds.sorted_entries();
        assert!(entries[0].is_object);
        assert_eq!(entries[0].callback_index, 42);
    }

    #[test]
    fn add_marks_is_object_false() {
        let mut ds = DepthSorter::new();
        ds.add(7, 1.0);
        let entries = ds.sorted_entries();
        assert!(!entries[0].is_object);
    }

    //  Clear

    #[test]
    fn clear_after_sort_empties() {
        let mut ds = DepthSorter::new();
        ds.add(0, 1.0);
        ds.sort();
        ds.clear();
        assert_eq!(ds.get_count(), 0);
    }
}

//  transition (additional tests migrated from src/scene/transition.rs)
//
// The `progress_eased` behavioural tests were previously migrated to
// tests/lua/unit/test_scene.lua (observable via lurek.scene.getTransitionProgressEased()).
// These tests cover the remaining public-API behaviour on ActiveTransition that
// was still inline in src/scene/transition.rs.

mod active_transition_tests {
    use lurek2d::scene::transition::{ActiveTransition, EasingType, TransitionType};

    #[test]
    fn new_starts_at_zero_elapsed() {
        let t = ActiveTransition::new(TransitionType::Fade, 1.0);
        assert!(t.elapsed.abs() < 1e-5);
    }

    #[test]
    fn set_easing_updates_field() {
        let mut t = ActiveTransition::new(TransitionType::Fade, 1.0);
        t.set_easing(EasingType::Bounce);
        assert_eq!(t.get_easing(), EasingType::Bounce);
    }

    #[test]
    fn transition_type_from_lua_str_fade() {
        assert_eq!(TransitionType::from_lua_str("fade"), TransitionType::Fade);
    }

    #[test]
    fn transition_type_from_lua_str_unknown_returns_none_variant() {
        assert_eq!(TransitionType::from_lua_str("xyz"), TransitionType::None);
    }
}
