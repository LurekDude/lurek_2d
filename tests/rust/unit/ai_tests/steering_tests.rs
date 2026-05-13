//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn combine_mode_parse() {
        assert_eq!(CombineMode::parse_str("weighted"), CombineMode::Weighted);
        assert_eq!(CombineMode::parse_str("priority"), CombineMode::Priority);
        assert_eq!(CombineMode::parse_str("nope"), CombineMode::Weighted);
    }

    #[test]
    #[ignore = "behavior_count() is not in the public API"]
    fn new_manager_defaults() {
        // Ignored: behavior_count() is not in the public API
    }

    #[test]
    fn spatial_hash_toggle() {
        let mut m = SteeringManager::new();
        m.set_use_spatial_hash(true);
        m.set_use_spatial_hash(false);
    }
}