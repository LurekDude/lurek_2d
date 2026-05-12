//! INTERNAL ONLY: Rust-only tests for ai internals not directly asserted via Lua.

use lurek2d::ai::{DialogueAI, SteeringManager};

#[test]
fn steering_path_follow_advances_progress() {
    let mut sm = SteeringManager::new();
    sm.set_path(vec![(0.0, 0.0), (10.0, 0.0)], 1.0, 1.0);

    let _ = sm.calculate((0.0, 0.0), (0.0, 0.0), 20.0, 100.0, 1.0 / 60.0);
    let (idx, total) = sm.path_progress();

    assert_eq!(total, 2);
    assert_eq!(idx, 1);
}

#[test]
fn steering_path_follow_completes_after_last_waypoint() {
    let mut sm = SteeringManager::new();
    sm.set_path(vec![(0.0, 0.0), (1.0, 0.0)], 1.5, 1.0);

    let _ = sm.calculate((0.0, 0.0), (0.0, 0.0), 20.0, 100.0, 1.0 / 60.0);
    let _ = sm.calculate((1.0, 0.0), (0.0, 0.0), 20.0, 100.0, 1.0 / 60.0);

    assert!(!sm.has_active_path());
}

#[test]
fn dialogue_ai_uses_fsm_bt_and_utility_for_topic_selection() {
    let mut d = DialogueAI::new();
    d.add_topic(
        "smalltalk".to_string(),
        0.2,
        None,
        None,
        Some("smalltalk_score".to_string()),
    );
    d.add_topic(
        "combat_bark".to_string(),
        0.1,
        Some("combat".to_string()),
        Some("success".to_string()),
        Some("combat_score".to_string()),
    );

    d.set_fsm_state(Some("combat".to_string()));
    d.set_bt_status(Some("success".to_string()));
    d.set_utility_score("smalltalk_score".to_string(), 0.3);
    d.set_utility_score("combat_score".to_string(), 0.9);

    assert_eq!(d.select_topic().as_deref(), Some("combat_bark"));
}

#[test]
fn dialogue_ai_branch_selection_respects_gates() {
    let mut d = DialogueAI::new();
    d.add_topic("quest".to_string(), 1.0, None, None, None);
    assert!(d.add_branch(
        "quest",
        "offer_quest".to_string(),
        0.5,
        Some("idle".to_string()),
        None,
        Some("offer_score".to_string()),
    ));
    assert!(d.add_branch(
        "quest",
        "warn_enemy".to_string(),
        0.2,
        Some("combat".to_string()),
        None,
        Some("warn_score".to_string()),
    ));

    d.set_fsm_state(Some("idle".to_string()));
    d.set_utility_score("offer_score".to_string(), 0.4);
    d.set_utility_score("warn_score".to_string(), 1.0);

    assert_eq!(d.select_branch("quest").as_deref(), Some("offer_quest"));
}
