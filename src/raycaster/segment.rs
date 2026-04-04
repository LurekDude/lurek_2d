//! Line segment definition and ray-segment intersection testing.
//!
//! Provides the [`Segment`] type and [`cast_ray_2d()`] free function for
//! casting rays against a list of line segments in 2D space.

/// A line segment for raycasting.
///
/// Defines a line from `(x1, y1)` to `(x2, y2)` in world space.
///
/// # Fields
/// - `x1` — `f32`.
/// - `y1` — `f32`.
/// - `x2` — `f32`.
/// - `y2` — `f32`.
#[derive(Debug, Clone)]
pub struct Segment {
    /// Segment start X.
    pub x1: f32,
    /// Segment start Y.
    pub y1: f32,
    /// Segment end X.
    pub x2: f32,
    /// Segment end Y.
    pub y2: f32,
}

/// Casts a ray from (ox, oy) in direction (dx, dy) against a list of segments.
///
/// # Parameters
/// - `ox` — `f32`.
/// - `oy` — `f32`.
/// - `dx` — `f32`.
/// - `dy` — `f32`.
/// - `max_dist` — `f32`.
/// - `segments` — `&[Segment]`.
///
/// # Returns
/// `Option<(f32, f32, usize)>`.
///
/// Returns `Some((hit_x, hit_y, segment_index))` for the nearest hit within `max_dist`,
/// or `None` if no segment is hit.
pub fn cast_ray_2d(
    ox: f32,
    oy: f32,
    dx: f32,
    dy: f32,
    max_dist: f32,
    segments: &[Segment],
) -> Option<(f32, f32, usize)> {
    let mut best_t = max_dist;
    let mut best_hit: Option<(f32, f32, usize)> = None;

    let ray_len = (dx * dx + dy * dy).sqrt();
    if ray_len < 1e-10 {
        return None;
    }
    let rdx = dx / ray_len;
    let rdy = dy / ray_len;

    for (i, seg) in segments.iter().enumerate() {
        let sx = seg.x2 - seg.x1;
        let sy = seg.y2 - seg.y1;

        let denom = rdx * sy - rdy * sx;
        if denom.abs() < 1e-10 {
            continue;
        }

        let t = ((seg.x1 - ox) * sy - (seg.y1 - oy) * sx) / denom;
        let u = ((seg.x1 - ox) * rdy - (seg.y1 - oy) * rdx) / denom;

        if t >= 0.0 && t < best_t && (0.0..=1.0).contains(&u) {
            best_t = t;
            best_hit = Some((ox + rdx * t, oy + rdy * t, i));
        }
    }

    best_hit
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_segments() -> Vec<Segment> {
        vec![
            Segment {
                x1: 5.0,
                y1: -2.0,
                x2: 5.0,
                y2: 2.0,
            }, // vertical wall at x=5
        ]
    }

    #[test]
    fn test_cast_ray_hit() {
        let segs = make_segments();
        let result = cast_ray_2d(0.0, 0.0, 1.0, 0.0, 100.0, &segs);
        assert!(result.is_some());
        let (hx, hy, idx) = result.unwrap();
        assert!((hx - 5.0).abs() < 1e-3);
        assert!((hy - 0.0).abs() < 1e-3);
        assert_eq!(idx, 0);
    }

    #[test]
    fn test_cast_ray_miss() {
        let segs = make_segments();
        // Ray going away from wall
        let result = cast_ray_2d(0.0, 0.0, -1.0, 0.0, 100.0, &segs);
        assert!(result.is_none());
    }
}
