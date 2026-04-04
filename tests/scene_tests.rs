//! Integration tests for the scene module: SceneStack, TransitionType, ActiveTransition, DepthSorter.

use luna2d::scene::{ActiveTransition, DepthSorter, SceneStack, TransitionType};

// ============================================================
// TransitionType
// ============================================================

#[test]
fn test_transition_type_from_lua_str_all_variants() {
    assert_eq!(TransitionType::from_lua_str("fade"), TransitionType::Fade);
    assert_eq!(
        TransitionType::from_lua_str("slideleft"),
        TransitionType::SlideLeft
    );
    assert_eq!(
        TransitionType::from_lua_str("slideright"),
        TransitionType::SlideRight
    );
    assert_eq!(
        TransitionType::from_lua_str("slideup"),
        TransitionType::SlideUp
    );
    assert_eq!(
        TransitionType::from_lua_str("slidedown"),
        TransitionType::SlideDown
    );
    assert_eq!(
        TransitionType::from_lua_str("none"),
        TransitionType::None
    );
}

#[test]
fn test_transition_type_from_lua_str_unknown_returns_none() {
    assert_eq!(
        TransitionType::from_lua_str("wipe"),
        TransitionType::None
    );
    assert_eq!(
        TransitionType::from_lua_str(""),
        TransitionType::None
    );
    assert_eq!(
        TransitionType::from_lua_str("FADE"),
        TransitionType::None
    );
}

// ============================================================
// ActiveTransition
// ============================================================

#[test]
fn test_active_transition_progress_zero_to_one() {
    let mut t = ActiveTransition::new(TransitionType::Fade, 1.0);
    assert!((t.progress() - 0.0).abs() < 1e-5);
    t.update(0.5);
    assert!((t.progress() - 0.5).abs() < 1e-5);
    t.update(0.5);
    assert!((t.progress() - 1.0).abs() < 1e-5);
}

#[test]
fn test_active_transition_zero_duration_instant() {
    let t = ActiveTransition::new(TransitionType::Fade, 0.0);
    assert!((t.progress() - 1.0).abs() < 1e-5);
}

#[test]
fn test_active_transition_is_complete() {
    let mut t = ActiveTransition::new(TransitionType::SlideLeft, 0.5);
    assert!(!t.is_complete());
    t.update(0.25);
    assert!(!t.is_complete());
    t.update(0.25);
    assert!(t.is_complete());
}

#[test]
fn test_active_transition_progress_clamps_at_one() {
    let mut t = ActiveTransition::new(TransitionType::SlideUp, 0.5);
    t.update(2.0);
    assert!((t.progress() - 1.0).abs() < 1e-5);
    assert!(t.progress() <= 1.0);
}

// ============================================================
// SceneStack — basic operations
// ============================================================

#[test]
fn test_scene_stack_new_is_empty() {
    let stack = SceneStack::new();
    assert!(stack.is_empty());
    assert_eq!(stack.get_stack_size(), 0);
    assert_eq!(stack.get_current(), None);
}

#[test]
fn test_scene_stack_push_increments_size() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    let b = stack.next_scene_id();
    let c = stack.next_scene_id();
    stack.push(a, TransitionType::None, 0.0);
    assert_eq!(stack.get_stack_size(), 1);
    stack.push(b, TransitionType::None, 0.0);
    assert_eq!(stack.get_stack_size(), 2);
    stack.push(c, TransitionType::None, 0.0);
    assert_eq!(stack.get_stack_size(), 3);
}

#[test]
fn test_scene_stack_push_returns_previous() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    let b = stack.next_scene_id();

    let prev = stack.push(a, TransitionType::None, 0.0);
    assert_eq!(prev, None);

    let prev = stack.push(b, TransitionType::None, 0.0);
    assert_eq!(prev, Some(a));
}

#[test]
fn test_scene_stack_pop_returns_popped_and_revealed() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    let b = stack.next_scene_id();
    stack.push(a, TransitionType::None, 0.0);
    stack.push(b, TransitionType::None, 0.0);

    let result = stack.pop(TransitionType::None, 0.0);
    assert!(result.is_ok());
    let (popped, revealed) = result.unwrap();
    assert_eq!(popped, b);
    assert_eq!(revealed, Some(a));
}

#[test]
fn test_scene_stack_pop_empty_returns_error() {
    let mut stack = SceneStack::new();
    let result = stack.pop(TransitionType::None, 0.0);
    assert!(result.is_err());
}

#[test]
fn test_scene_stack_pop_last_reveals_none() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    stack.push(a, TransitionType::None, 0.0);

    let (popped, revealed) = stack.pop(TransitionType::None, 0.0).unwrap();
    assert_eq!(popped, a);
    assert_eq!(revealed, None);
}

#[test]
fn test_scene_stack_switch_to_returns_old() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    let b = stack.next_scene_id();
    stack.push(a, TransitionType::None, 0.0);

    let old = stack.switch_to(b, TransitionType::None, 0.0);
    assert_eq!(old, Some(a));
    assert_eq!(stack.get_current(), Some(b));
    assert_eq!(stack.get_stack_size(), 1);
}

#[test]
fn test_scene_stack_switch_to_empty_pushes() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();

    let old = stack.switch_to(a, TransitionType::None, 0.0);
    assert_eq!(old, None);
    assert_eq!(stack.get_current(), Some(a));
    assert_eq!(stack.get_stack_size(), 1);
}

#[test]
fn test_scene_stack_clear_returns_all_and_empties() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    let b = stack.next_scene_id();
    let c = stack.next_scene_id();
    stack.push(a, TransitionType::None, 0.0);
    stack.push(b, TransitionType::None, 0.0);
    stack.push(c, TransitionType::None, 0.0);

    let removed = stack.clear();
    assert_eq!(removed, vec![a, b, c]);
    assert!(stack.is_empty());
    assert_eq!(stack.get_stack_size(), 0);
}

#[test]
fn test_scene_stack_get_current() {
    let mut stack = SceneStack::new();
    assert_eq!(stack.get_current(), None);

    let a = stack.next_scene_id();
    stack.push(a, TransitionType::None, 0.0);
    assert_eq!(stack.get_current(), Some(a));

    let b = stack.next_scene_id();
    stack.push(b, TransitionType::None, 0.0);
    assert_eq!(stack.get_current(), Some(b));
}

#[test]
fn test_scene_stack_get_all_bottom_to_top() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    let b = stack.next_scene_id();
    let c = stack.next_scene_id();
    stack.push(a, TransitionType::None, 0.0);
    stack.push(b, TransitionType::None, 0.0);
    stack.push(c, TransitionType::None, 0.0);

    let all = stack.get_all();
    assert_eq!(all, &[a, b, c]);
}

// ============================================================
// SceneStack — registry
// ============================================================

#[test]
fn test_scene_stack_registry_crud() {
    let mut stack = SceneStack::new();
    let menu_id = stack.next_scene_id();
    let game_id = stack.next_scene_id();

    // Register
    stack.register_scene("menu".to_string(), menu_id);
    stack.register_scene("game".to_string(), game_id);

    // has_registered
    assert!(stack.has_registered("menu"));
    assert!(stack.has_registered("game"));
    assert!(!stack.has_registered("settings"));

    // get_registered
    assert_eq!(stack.get_registered("menu"), Some(menu_id));
    assert_eq!(stack.get_registered("game"), Some(game_id));
    assert_eq!(stack.get_registered("settings"), None);

    // get_registered_names
    let mut names = stack.get_registered_names();
    names.sort();
    assert_eq!(names, vec!["game", "menu"]);

    // Unregister
    stack.unregister_scene("menu");
    assert!(!stack.has_registered("menu"));
    assert_eq!(stack.get_registered("menu"), None);
}

// ============================================================
// SceneStack — data store
// ============================================================

#[test]
fn test_scene_stack_data_crud() {
    let mut stack = SceneStack::new();

    // set & get
    stack.set_data("score".to_string(), 42);
    assert!(stack.has_data("score"));
    assert_eq!(stack.get_data("score"), Some(42));

    // overwrite
    stack.set_data("score".to_string(), 100);
    assert_eq!(stack.get_data("score"), Some(100));

    // missing key
    assert!(!stack.has_data("lives"));
    assert_eq!(stack.get_data("lives"), None);

    // remove
    stack.remove_data("score");
    assert!(!stack.has_data("score"));
    assert_eq!(stack.get_data("score"), None);
}

// ============================================================
// SceneStack — transitions
// ============================================================

#[test]
fn test_scene_stack_transition_lifecycle() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();

    // Push with fade transition
    stack.push(a, TransitionType::Fade, 1.0);
    assert!(stack.is_transitioning());
    assert!((stack.get_transition_progress() - 0.0).abs() < 1e-5);

    // Progress halfway
    let completed = stack.update_transition(0.5);
    assert!(!completed);
    assert!(stack.is_transitioning());
    assert!((stack.get_transition_progress() - 0.5).abs() < 1e-5);

    // Complete
    let completed = stack.update_transition(0.5);
    assert!(completed);
    assert!(!stack.is_transitioning());
    assert!((stack.get_transition_progress() - 0.0).abs() < 1e-5); // no transition → 0
}

#[test]
fn test_scene_stack_no_transition_when_none_type() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();

    stack.push(a, TransitionType::None, 1.0);
    assert!(!stack.is_transitioning());
    assert!((stack.get_transition_progress() - 0.0).abs() < 1e-5);
}

#[test]
fn test_scene_stack_no_transition_when_zero_duration() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();

    stack.push(a, TransitionType::Fade, 0.0);
    assert!(!stack.is_transitioning());
}

// ============================================================
// SceneStack — pop_to / pop_until
// ============================================================

#[test]
fn test_scene_stack_pop_to_finds_registered() {
    let mut stack = SceneStack::new();
    let menu_id = stack.next_scene_id();
    stack.register_scene("menu".to_string(), menu_id);

    assert_eq!(stack.pop_to("menu"), Some(menu_id));
}

#[test]
fn test_scene_stack_pop_to_missing_returns_none() {
    let stack = SceneStack::new();
    assert_eq!(stack.pop_to("nonexistent"), None);
}

#[test]
fn test_scene_stack_pop_until() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    let b = stack.next_scene_id();
    let c = stack.next_scene_id();
    let d = stack.next_scene_id();

    stack.push(a, TransitionType::None, 0.0);
    stack.push(b, TransitionType::None, 0.0);
    stack.push(c, TransitionType::None, 0.0);
    stack.push(d, TransitionType::None, 0.0);

    // Pop until b is on top: should remove d and c
    let popped = stack.pop_until(b);
    assert_eq!(popped, vec![d, c]);
    assert_eq!(stack.get_current(), Some(b));
    assert_eq!(stack.get_stack_size(), 2);
}

#[test]
fn test_scene_stack_pop_until_target_already_on_top() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    stack.push(a, TransitionType::None, 0.0);

    let popped = stack.pop_until(a);
    assert!(popped.is_empty());
    assert_eq!(stack.get_current(), Some(a));
}

#[test]
fn test_scene_stack_pop_until_target_not_found_empties() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    let b = stack.next_scene_id();
    stack.push(a, TransitionType::None, 0.0);
    stack.push(b, TransitionType::None, 0.0);

    // Target not in stack — pops everything
    let popped = stack.pop_until(999);
    assert_eq!(popped, vec![b, a]);
    assert!(stack.is_empty());
}

// ============================================================
// SceneStack — next_scene_id is monotonic
// ============================================================

#[test]
fn test_scene_stack_next_scene_id_monotonic() {
    let mut stack = SceneStack::new();
    let id1 = stack.next_scene_id();
    let id2 = stack.next_scene_id();
    let id3 = stack.next_scene_id();
    assert!(id1 < id2);
    assert!(id2 < id3);
}

// ============================================================
// SceneStack — clear also clears transition
// ============================================================

#[test]
fn test_scene_stack_clear_clears_transition() {
    let mut stack = SceneStack::new();
    let a = stack.next_scene_id();
    stack.push(a, TransitionType::Fade, 1.0);
    assert!(stack.is_transitioning());

    stack.clear();
    assert!(!stack.is_transitioning());
}

// ============================================================
// DepthSorter
// ============================================================

#[test]
fn test_depth_sorter_new_empty() {
    let sorter = DepthSorter::new();
    assert_eq!(sorter.get_count(), 0);
}

#[test]
fn test_depth_sorter_add_increments_count() {
    let mut sorter = DepthSorter::new();
    sorter.add(0, 1.0);
    sorter.add(1, 2.0);
    sorter.add(2, 3.0);
    assert_eq!(sorter.get_count(), 3);
}

#[test]
fn test_depth_sorter_sort_ascending_depth() {
    let mut sorter = DepthSorter::new();
    sorter.add(0, 10.0);
    sorter.add(1, 0.0);
    sorter.add(2, 5.0);

    sorter.sort();
    let entries = sorter.sorted_entries();

    assert!((entries[0].depth - 0.0).abs() < 1e-5);
    assert_eq!(entries[0].callback_index, 1);
    assert!((entries[1].depth - 5.0).abs() < 1e-5);
    assert_eq!(entries[1].callback_index, 2);
    assert!((entries[2].depth - 10.0).abs() < 1e-5);
    assert_eq!(entries[2].callback_index, 0);
}

#[test]
fn test_depth_sorter_clear_resets_count() {
    let mut sorter = DepthSorter::new();
    sorter.add(0, 1.0);
    sorter.add(1, 2.0);
    assert_eq!(sorter.get_count(), 2);

    sorter.clear();
    assert_eq!(sorter.get_count(), 0);
}

#[test]
fn test_depth_sorter_sorted_entries_returns_sorted() {
    let mut sorter = DepthSorter::new();
    sorter.add(10, 99.0);
    sorter.add(20, -5.0);
    sorter.add(30, 50.0);

    let entries = sorter.sorted_entries();
    assert_eq!(entries.len(), 3);
    assert!((entries[0].depth - (-5.0)).abs() < 1e-5);
    assert!((entries[1].depth - 50.0).abs() < 1e-5);
    assert!((entries[2].depth - 99.0).abs() < 1e-5);
}

#[test]
fn test_depth_sorter_add_object_sets_is_object() {
    let mut sorter = DepthSorter::new();
    sorter.add(0, 1.0);
    sorter.add_object(1, 2.0);

    let entries = sorter.sorted_entries();
    assert!(!entries[0].is_object);
    assert!(entries[1].is_object);
}

#[test]
fn test_depth_sorter_default_trait() {
    let sorter = DepthSorter::default();
    assert_eq!(sorter.get_count(), 0);
}
