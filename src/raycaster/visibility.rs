//! Visibility polygon via endpoint raycasting.
//!
//! Computes a visibility polygon from a point by casting rays at segment
//! endpoints with small angular offsets, producing a sorted polygon outline.

use super::segment::{cast_ray_2d, Segment};

/// Computes a visibility polygon by casting rays at segment endpoints.
///
/// # Parameters
/// - `ox` — `f32`.
/// - `oy` — `f32`.
/// - `segments` — `&[Segment]`.
/// - `radius` — `f32`.
///
/// # Returns
/// `Vec<f32>`.
///
/// Casts rays towards each segment endpoint (plus small angular offsets) within `radius`,
/// sorts the hit points by angle, and returns a flat polygon `[x0, y0, x1, y1, ...]`.
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_field_of_view_produces_polygon() {
        let segs = vec![
            Segment {
                x1: -5.0,
                y1: 5.0,
                x2: 5.0,
                y2: 5.0,
            },
            Segment {
                x1: 5.0,
                y1: 5.0,
                x2: 5.0,
                y2: -5.0,
            },
            Segment {
                x1: 5.0,
                y1: -5.0,
                x2: -5.0,
                y2: -5.0,
            },
            Segment {
                x1: -5.0,
                y1: -5.0,
                x2: -5.0,
                y2: 5.0,
            },
        ];
        let poly = field_of_view(0.0, 0.0, &segs, 20.0);
        assert!(poly.len() >= 8); // at least 4 points (8 floats)
    }
}
