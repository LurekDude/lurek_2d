//! - Wall-column projection from ray distance to screen-pixel height and vertical bounds.
//! - Distance-based shading for depth fog attenuation.

/// Project a wall column at `distance` using `fov` and `screen_height`;.
/// return `(wall_height, draw_start_y, draw_end_y)` in screen pixels.
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
/// Return a brightness multiplier 0.0..1.0 based on `distance` relative to `max_distance`.
pub fn distance_shade(distance: f32, max_distance: f32) -> f32 {
    if max_distance <= 0.0 {
        return 0.0;
    }
    (1.0 - distance / max_distance).clamp(0.0, 1.0)
}
