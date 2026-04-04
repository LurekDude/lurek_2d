//! Wall column projection and distance-based shading.
//!
//! Provides functions for projecting wall distances to screen-space drawing
//! parameters and computing distance-based brightness attenuation.

/// Projects a wall column distance to screen-space drawing parameters.
///
/// # Parameters
/// - `distance` — `f32`.
/// - `fov` — `f32`.
/// - `screen_height` — `f32`.
///
/// # Returns
/// `(f32, f32, f32)`.
///
/// Returns (wall_height, draw_start, draw_end).
pub fn project_column(distance: f32, fov: f32, screen_height: f32) -> (f32, f32, f32) {
    if distance <= 0.0 {
        return (screen_height, 0.0, screen_height);
    }
    let wall_height = screen_height / (distance * (fov / 2.0).tan());
    let draw_start = (screen_height - wall_height) / 2.0;
    let draw_end = draw_start + wall_height;
    (
        wall_height,
        draw_start.max(0.0),
        draw_end.min(screen_height),
    )
}

/// Distance-based shading. Returns brightness in [0, 1].
///
/// # Parameters
/// - `distance` — `f32`.
/// - `max_distance` — `f32`.
///
/// # Returns
/// `f32`.
///
/// `(1 - distance / max_distance)` clamped to [0, 1].
pub fn distance_shade(distance: f32, max_distance: f32) -> f32 {
    if max_distance <= 0.0 {
        return 0.0;
    }
    (1.0 - distance / max_distance).clamp(0.0, 1.0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::f32::consts::PI;

    #[test]
    fn test_project_column() {
        let (h, start, end) = project_column(2.0, PI / 3.0, 200.0);
        assert!(h > 0.0);
        assert!(start >= 0.0);
        assert!(end <= 200.0);
    }

    #[test]
    fn test_distance_shade() {
        assert!((distance_shade(0.0, 10.0) - 1.0).abs() < 1e-5);
        assert!((distance_shade(10.0, 10.0) - 0.0).abs() < 1e-5);
        assert!((distance_shade(5.0, 10.0) - 0.5).abs() < 1e-5);
        assert!((distance_shade(15.0, 10.0) - 0.0).abs() < 1e-5);
    }
}
