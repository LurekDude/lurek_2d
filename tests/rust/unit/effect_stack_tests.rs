use lurek2d::effect::stack::PostFxStack;

#[test]
fn new_stack_is_empty() {
    let s = PostFxStack::new(800, 600);
    assert!(s.is_empty());
    assert_eq!(s.len(), 0);
    assert!(!s.capturing);
}

#[test]
fn add_and_len() {
    let mut s = PostFxStack::new(800, 600);
    s.add(0);
    s.add(1);
    assert_eq!(s.len(), 2);
    assert!(!s.is_empty());
}

#[test]
fn remove_returns_true_when_present() {
    let mut s = PostFxStack::new(800, 600);
    s.add(5);
    assert!(s.remove(5));
    assert!(s.is_empty());
}

#[test]
fn remove_returns_false_when_absent() {
    let mut s = PostFxStack::new(800, 600);
    assert!(!s.remove(99));
}

#[test]
fn insert_at_front() {
    let mut s = PostFxStack::new(800, 600);
    s.add(10);
    s.insert(1, 20);
    assert_eq!(s.get_effect(1), Some(20));
    assert_eq!(s.get_effect(2), Some(10));
}

#[test]
fn set_enabled_toggles() {
    let mut s = PostFxStack::new(800, 600);
    s.add(0);
    assert!(s.is_enabled(0));
    s.set_enabled(0, false);
    assert!(!s.is_enabled(0));
}

#[test]
fn enabled_effects_filters_disabled() {
    let mut s = PostFxStack::new(800, 600);
    s.add(0);
    s.add(1);
    s.set_enabled(0, false);
    let enabled = s.enabled_effects();
    assert_eq!(enabled, vec![1]);
}

#[test]
fn resize_updates_dimensions() {
    let mut s = PostFxStack::new(800, 600);
    s.resize(1920, 1080);
    assert_eq!(s.get_dimensions(), (1920, 1080));
}

#[test]
fn clear_empties_chain() {
    let mut s = PostFxStack::new(800, 600);
    s.add(0);
    s.add(1);
    s.clear();
    assert!(s.is_empty());
}

#[test]
fn dedup_indices_removes_duplicates() {
    let mut s = PostFxStack::new(800, 600);
    s.add(0);
    s.add(1);
    s.add(0);
    let removed = s.dedup_indices();
    assert_eq!(removed, 1);
    assert_eq!(s.len(), 2);
}

#[test]
fn get_effect_is_one_based() {
    let mut s = PostFxStack::new(800, 600);
    s.add(42);
    assert_eq!(s.get_effect(1), Some(42));
    assert_eq!(s.get_effect(0), None);
}
