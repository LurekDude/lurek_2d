//! 2D line-segment definition and analytic ray-segment intersection for the
//! raycaster. Used by the BSP/polygon raycaster path and visibility queries.
//! Does not share state with the DDA grid raycaster.

/// An infinite-precision 2D line segment from `(x1, y1)` to `(x2, y2)`.
#[derive(Debug, Clone)]
pub struct Segment {
    /// X coordinate of the first endpoint.
    pub x1: f32,
    /// Y coordinate of the first endpoint.
    pub y1: f32,
    /// X coordinate of the second endpoint.
    pub x2: f32,
    /// Y coordinate of the second endpoint.
    pub y2: f32,
}
/// Cast a ray from `(ox, oy)` in direction `(dx, dy)` and return the nearest hit `(x, y, segment_index)`, or `None`.
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
