//! INTERNAL ONLY: public agent defaults and decision-model round-trips are covered by the Lua-first
//! suite in `tests/lua/unit/test_ai_core_unit.lua`.
//!
//! The remaining Rust coverage keeps the exact `DecisionModel::parse_str` failure helper, which is
//! only indirectly observable from Lua through ignored invalid setter input.

use lurek2d::ai::DecisionModel;

#[test]
fn decision_model_unknown_returns_none() {
    assert!(DecisionModel::parse_str("bogus").is_none());
}
