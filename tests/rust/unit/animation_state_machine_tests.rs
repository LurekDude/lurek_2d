use lurek2d::animation::controller::Animation;
use lurek2d::animation::state_machine::{
    compare_nums, parse_condition, AnimStateMachine, ConditionOp,
};
use lurek2d::math::Rect;

fn make_anim() -> Animation {
    let mut anim = Animation::new();
    anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
    anim.add_clip("idle", vec![0], 1.0, true);
    anim.add_clip("walk", vec![0, 1], 10.0, true);
    anim
}

#[test]
fn test_initial_state_after_constructor() {
    let sm = AnimStateMachine::new(make_anim(), "idle".to_string());
    assert_eq!(sm.get_state(), "idle");
}

#[test]
fn test_force_state_existing_target() {
    let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
    sm.add_state("idle", "idle", true);
    sm.add_state("walk", "walk", true);
    assert!(sm.force_state("walk"));
    assert_eq!(sm.get_state(), "walk");
}

#[test]
fn test_force_state_missing_target() {
    let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
    sm.add_state("idle", "idle", true);
    assert!(!sm.force_state("flying"));
}

#[test]
fn test_transition_speed_above_threshold() {
    let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
    sm.add_state("idle", "idle", true);
    sm.add_state("walk", "walk", true);
    sm.add_transition("idle", "walk", "speed > 0.1");
    sm.set_param_float("speed", 0.5);
    sm.update(0.016);
    assert_eq!(sm.get_state(), "walk");
}

#[test]
fn test_transition_speed_below_threshold() {
    let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
    sm.add_state("idle", "idle", true);
    sm.add_state("walk", "walk", true);
    sm.add_transition("idle", "walk", "speed > 0.1");
    sm.set_param_float("speed", 0.05);
    sm.update(0.016);
    assert_eq!(sm.get_state(), "idle");
}

#[test]
fn test_transition_boolean_condition_true() {
    let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
    sm.add_state("idle", "idle", true);
    sm.add_state("walk", "walk", true);
    sm.add_transition("idle", "walk", "moving == true");
    sm.set_param_bool("moving", true);
    sm.update(0.016);
    assert_eq!(sm.get_state(), "walk");
}

#[test]
fn test_parse_condition_gt_expression() {
    let c = parse_condition("speed > 5.0").expect("condition should parse");
    assert_eq!(c.param, "speed");
    assert_eq!(c.op, ConditionOp::Gt);
}

#[test]
fn test_parse_condition_invalid_expression() {
    assert!(parse_condition("noop").is_err());
}

#[test]
fn test_compare_nums_relational_checks() {
    assert!(compare_nums(2.0, 1.0, &ConditionOp::Gt));
    assert!(!compare_nums(1.0, 2.0, &ConditionOp::Gt));
    assert!(compare_nums(1.0, 1.0, &ConditionOp::Eq));
    assert!(compare_nums(1.0, 2.0, &ConditionOp::Neq));
}
