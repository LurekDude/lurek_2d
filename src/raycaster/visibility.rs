//! Angular FOV polygon calculation using segment endpoint sampling.
//! Casts rays at each segment endpoint angle (± epsilon) and collects hit
//! positions to build a visibility polygon around `(ox, oy)`. Used by the
//! segment-based 2D raycaster path; does not depend on DDA or the grid.

use super::segment::{cast_ray_2d, Segment};
/// Cast radial rays at all segment-endpoint angles from `(ox, oy)` and return
/// an interleaved `[x0, y0, x1, y1, ...]` visibility polygon sorted by angle.
pub fn field_of_view(ox: f32, oy: f32, segments: &[Segment], radius: f32) -> Vec<f32> {
    let mut angles: Vec<f32> = Vec::new();
    let epsilon = 1e-4;
    for seg in segments {
        for &(px, py) in &[(seg.x1, seg.y1), (seg.x2, seg.y2)] {
            let dx = px - ox;
            let dy = py - oy;
            if dx * dx + dy * dy > radius * radius {
                continue;
            }
            let angle = dy.atan2(dx);
            angles.push(angle - epsilon);
            angles.push(angle);
            angles.push(angle + epsilon);
        }
    }
    angles.sort_by(|a, b| a.partial_cmp(b).unwrap());
    angles.dedup_by(|a, b| (*a - *b).abs() < epsilon * 0.1);
    let mut polygon = Vec::new();
    for &angle in &angles {
        let rdx = angle.cos();
        let rdy = angle.sin();
        if let Some((hx, hy, _)) = cast_ray_2d(ox, oy, rdx, rdy, radius, segments) {
            polygon.push((angle, hx, hy));
        } else {
            polygon.push((angle, ox + rdx * radius, oy + rdy * radius));
        }
    }
    polygon.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap());
    let mut result = Vec::with_capacity(polygon.len() * 2);
    for (_, x, y) in polygon {
        result.push(x);
        result.push(y);
    }
    result
}
