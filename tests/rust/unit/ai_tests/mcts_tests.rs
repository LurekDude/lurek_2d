//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_engine_has_config() {
        let cfg = MCTSConfig {
            iterations: 50,
            uct_c: 1.414,
            rollout_depth: 5,
            seed: 42,
        };
        let e = MCTSEngine::new(cfg);
        assert_eq!(e.config().iterations, 50);
    }
}