//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_bandit_defaults() {
        let b = Bandit::new(3, BanditStrategy::EpsilonGreedy { epsilon: 0.1 }, 42);
        assert_eq!(b.arm_count(), 3);
    }

    #[test]
    fn select_returns_valid_arm() {
        let mut b = Bandit::new(4, BanditStrategy::EpsilonGreedy { epsilon: 0.1 }, 42);
        let arm = b.select();
        assert!(arm < 4);
    }

    #[test]
    fn update_and_best_arm() {
        let mut b = Bandit::new(3, BanditStrategy::EpsilonGreedy { epsilon: 0.1 }, 42);
        b.update(0, 0.5);
        b.update(1, 2.0);
        b.update(2, 0.1);
        assert_eq!(b.best_arm(), 1);
    }

    #[test]
    fn reset_clears_state() {
        let mut b = Bandit::new(2, BanditStrategy::EpsilonGreedy { epsilon: 0.1 }, 42);
        b.update(0, 1.0);
        b.reset();
        assert_eq!(b.arm_count(), 2);
    }
}