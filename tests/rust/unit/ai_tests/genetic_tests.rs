//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn population_initialised() {
        let ga = GeneticAlgorithm::new(10, 5, 42);
        assert_eq!(ga.pop_size(), 10);
    }

    #[test]
    fn evolve_step_preserves_size() {
        let mut ga = GeneticAlgorithm::new(8, 4, 42);
        ga.evolve();
        assert_eq!(ga.pop_size(), 8);
    }

    #[test]
    fn best_returns_chromosome() {
        let mut ga = GeneticAlgorithm::new(4, 3, 42);
        ga.evolve();
        assert!(ga.best().is_some());
    }

    #[test]
    fn multiple_evolve_steps() {
        let mut ga = GeneticAlgorithm::new(4, 2, 42);
        ga.evolve();
        ga.evolve();
        assert_eq!(ga.pop_size(), 4);
    }
}