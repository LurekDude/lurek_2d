//! INTERNAL ONLY: public animation state-machine construction, force-state behavior, and transition
//! evaluation are covered by the Lua-first suite in `tests/lua/unit/test_animation_core_unit.lua`.
//!
//! The remaining Rust coverage keeps pure helper parsing and relational comparison paths that are
//! not exposed one-to-one through the Lua API surface.

use lurek2d::animation::state_machine::{compare_nums, parse_condition, ConditionOp};

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
