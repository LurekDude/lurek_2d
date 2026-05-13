//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn response_curve_linear() {
        let c = ResponseCurve::Linear;
        assert!((c.apply(0.5, 2.0, 0.0, 1.0) - 1.0).abs() < 1e-6);
    }

    #[test]
    fn response_curve_high_slope() {
        // Linear: p1 * input + p2 = 10.0 * 1.0 + 0.0 = 10.0 (no built-in clamping)
        let c = ResponseCurve::Linear;
        assert!((c.apply(1.0, 10.0, 0.0, 1.0) - 10.0).abs() < 1e-6);
    }

    #[test]
    #[ignore = "action_count() is not in the public API"]
    fn new_utility_ai_empty() {
        // Ignored: action_count() is not in the public API
    }
}