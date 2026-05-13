//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_context_steering_slot_count() {
        let cs = ContextSteering::new(8);
        assert_eq!(cs.slot_count(), 8);
    }

    #[test]
    fn seek_sets_interest() {
        let mut cs = ContextSteering::new(8);
        cs.add_seek_target(1.0, 0.0, 1.0);
        cs.evaluate(0.0, 0.0, 0.0, 0.0);
        assert!(cs.chosen_direction().is_finite());
    }

    #[test]
    fn avoid_does_not_crash() {
        let mut cs = ContextSteering::new(8);
        cs.add_seek_target(1.0, 0.0, 1.0);
        cs.add_avoid_point(0.5, 0.0, 0.5, 5.0);
        cs.evaluate(0.0, 0.0, 0.0, 0.0);
        assert!(cs.chosen_direction().is_finite());
    }

    #[test]
    fn clear_behaviors_resets() {
        let mut cs = ContextSteering::new(8);
        cs.add_seek_target(1.0, 0.0, 1.0);
        cs.clear_behaviors();
        cs.evaluate(0.0, 0.0, 0.0, 0.0);
        assert_eq!(cs.chosen_magnitude(), 0.0);
    }
}