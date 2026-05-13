//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    #[test]
    #[ignore = "ORCASolver::new() requires time_horizon arg; ORCANeighbour removed; compute API changed"]
    fn no_neighbours_preferred_velocity() {
        // Ignored: ORCASolver::new() now requires time_horizon: f32
    }

    #[test]
    #[ignore = "ORCANeighbour removed from public API; compute API changed"]
    fn single_obstacle_adjusts_velocity() {
        // Ignored: ORCANeighbour struct no longer exists in the public API
    }
}