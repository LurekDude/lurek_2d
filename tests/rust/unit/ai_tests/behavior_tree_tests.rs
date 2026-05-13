//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bt_status_conversions() {
        assert_eq!(BTStatus::Success.as_str(), "success");
        assert_eq!(BTStatus::Failure.as_str(), "failure");
        assert_eq!(BTStatus::Running.as_str(), "running");
    }

    #[test]
    fn parallel_policy_parse() {
        assert_eq!(
            ParallelPolicy::parse_str("requireAll"),
            ParallelPolicy::RequireAll
        );
        assert_eq!(
            ParallelPolicy::parse_str("requireOne"),
            ParallelPolicy::RequireOne
        );
        assert_eq!(
            ParallelPolicy::parse_str("unknown"),
            ParallelPolicy::RequireOne
        );
    }

    #[test]
    fn new_tree_has_no_root() {
        let bt = BehaviorTree::new();
        assert!(bt.root.is_none());
        let state = bt.debug_state();
        assert_eq!(state.node_count, 0);
    }
}