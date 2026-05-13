//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_strategy_empty_goals() {
        let s = StrategyAI::new(1.0);
        assert_eq!(s.goal_count(), 0);
    }

    #[test]
    fn add_goal_increases_count() {
        let mut s = StrategyAI::new(1.0);
        s.add_goal(StrategicGoal::new("attack"));
        assert_eq!(s.goal_count(), 1);
    }

    #[test]
    fn time_until_next_starts_at_interval() {
        let s = StrategyAI::new(2.0);
        assert!((s.time_until_next() - 2.0).abs() < 1e-6);
    }
}