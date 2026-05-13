//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decision_model_parse_round_trip() {
        for &s in &["fsm", "bt", "steering", "fsm+steering", "bt+steering"] {
            let dm = DecisionModel::parse_str(s).unwrap();
            assert_eq!(dm.as_str(), s);
        }
    }

    #[test]
    fn decision_model_unknown_returns_none() {
        assert!(DecisionModel::parse_str("bogus").is_none());
    }

    #[test]
    fn agent_new_defaults() {
        let a = Agent::new("test");
        assert_eq!(a.name, "test");
        assert_eq!(a.position, (0.0, 0.0));
        assert_eq!(a.velocity, (0.0, 0.0));
        assert_eq!(a.decision_model, DecisionModel::Fsm);
    }
}