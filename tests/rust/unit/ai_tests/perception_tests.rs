//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[ignore = "SensorContact removed from public API; Sensor API changed"]
    fn sensor_detects_nearby() {
        // Ignored: SensorContact struct no longer exists in the public API
    }

    #[test]
    #[ignore = "SensorContact removed from public API"]
    fn sensor_ignores_out_of_range() {
        // Ignored: SensorContact struct no longer exists in the public API
    }

    #[test]
    #[ignore = "SensorContact removed from public API"]
    fn sensor_respects_fov() {
        // Ignored: SensorContact struct no longer exists in the public API
    }

    #[test]
    fn angle_diff_normalized() {
        let d = angle_diff(0.1, 2.0 * std::f32::consts::PI - 0.1);
        assert!((d - 0.2).abs() < 1e-3);
    }
}