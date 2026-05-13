//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_need_defaults() {
        // Need::new(name, decay_rate, urgency_threshold, urgency_factor); value starts at 1.0
        let n = Need::new("hunger", 0.1, 0.5, 1.5);
        assert_eq!(n.name, "hunger");
        assert!((n.value - 1.0).abs() < 1e-6);
    }

    #[test]
    fn decay_increases_value() {
        let mut n = Need::new("thirst", 0.2, 0.1, 1.5);
        n.update(1.0);
        assert!(n.value > 0.2);
    }

    #[test]
    fn satisfy_increases_value() {
        // satisfy() adds to value; deprive() subtracts
        let mut n = Need::new("rest", 0.1, 0.5, 1.5);
        n.deprive(0.5); // value = 1.0 - 0.5 = 0.5
        n.satisfy(0.2); // value = 0.5 + 0.2 = 0.7
        assert!((n.value - 0.7).abs() < 1e-6);
    }

    #[test]
    fn value_clamped_0_1() {
        let mut n = Need::new("food", 0.9, 10.0, 1.5);
        n.update(10.0);
        assert!(n.value <= 1.0);
        n.satisfy(100.0);
        assert!(n.value >= 0.0);
    }

    #[test]
    fn system_get_set() {
        let mut s = NeedSystem::new();
        s.add_need(Need::new("hunger", 0.0, 0.1, 1.5));
        assert!(s.get("hunger").is_some());
        assert!(s.get("bogus").is_none());
    }

    #[test]
    fn most_urgent_picks_highest() {
        let mut s = NeedSystem::new();
        // Deprive hunger so its urgency_score (factor * (1 - value)) is high
        let mut hunger = Need::new("hunger", 0.1, 0.5, 1.5);
        hunger.deprive(0.9); // value = 0.1, urgency_score = 1.5 * 0.9 = 1.35
        s.add_need(hunger);
        let rest = Need::new("rest", 0.1, 0.5, 1.5); // value = 1.0, urgency_score = 0.0
        s.add_need(rest);
        assert_eq!(s.most_urgent().unwrap(), "hunger");
    }
}