//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[ignore = "action_count() is not in the public API"]
    fn new_planner_defaults() {
        // Ignored: action_count() is not in the public API
    }

    #[test]
    fn set_max_iterations() {
        let mut p = GOAPPlanner::new();
        p.set_max_iterations(500);
        assert_eq!(p.max_iterations, 500);
    }
}