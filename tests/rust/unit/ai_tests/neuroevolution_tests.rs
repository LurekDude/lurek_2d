//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_pool_creates_population() {
        let ne = Neuroevolution::new(vec![(2, 3, "relu"), (3, 1, "sigmoid")], 10, 42);
        assert_eq!(ne.pop_size(), 10);
    }

    #[test]
    fn evaluate_and_evolve_preserves_size() {
        let mut ne = Neuroevolution::new(vec![(2, 1, "sigmoid")], 6, 42);
        for i in 0..6 {
            ne.set_fitness(i, i as f32);
        }
        ne.evolve();
        assert_eq!(ne.pop_size(), 6);
    }
}