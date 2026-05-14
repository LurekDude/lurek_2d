
/// Multi-point Catmull-Rom spline with dynamic control-point list.
pub struct CatmullRomSpline {
    /// Ordered (x, y) control points; at least 2 are required for sampling.
    control_points: Vec<(f32, f32)>,
}
impl CatmullRomSpline {
    /// Construct a spline from a Vec of `(x, y)` control points.
    pub fn new(points: Vec<(f32, f32)>) -> Self {
        Self {
            control_points: points,
        }
    }
    /// Sample the full spline at normalized parameter `t` in `[0,1]`, mapping to the appropriate segment.
    pub fn sample(&self, t: f32) -> (f32, f32) {
        let n = self.control_points.len();
        if n < 2 {
            return self.control_points.first().copied().unwrap_or((0.0, 0.0));
        }
        let segs = (n - 1).max(1) as f32;
        let scaled = (t * segs).clamp(0.0, segs);
        let seg = (scaled.floor() as usize).min(n - 2);
        let local_t = scaled - seg as f32;
        self.sample_segment(seg, local_t)
    }
    /// Sample segment `seg` at local parameter `t` in `[0,1]` using 4-point Catmull-Rom weights.
    pub fn sample_segment(&self, seg: usize, t: f32) -> (f32, f32) {
        let n = self.control_points.len();
        if n == 0 {
            return (0.0, 0.0);
        }
        let p = |i: i64| -> (f32, f32) {
            let idx = i.clamp(0, (n as i64) - 1) as usize;
            self.control_points[idx]
        };
        let seg_i = seg.min(n.saturating_sub(2)) as i64;
        let (p0, p1, p2, p3) = (p(seg_i - 1), p(seg_i), p(seg_i + 1), p(seg_i + 2));
        let t2 = t * t;
        let t3 = t2 * t;
        let h0 = -0.5 * t3 + t2 - 0.5 * t;
        let h1 = 1.5 * t3 - 2.5 * t2 + 1.0;
        let h2 = -1.5 * t3 + 2.0 * t2 + 0.5 * t;
        let h3 = 0.5 * t3 - 0.5 * t2;
        (
            h0 * p0.0 + h1 * p1.0 + h2 * p2.0 + h3 * p3.0,
            h0 * p0.1 + h1 * p1.1 + h2 * p2.1 + h3 * p3.1,
        )
    }
    /// Return the number of control points.
    pub fn len(&self) -> usize {
        self.control_points.len()
    }
    /// Return true when the spline has no control points.
    pub fn is_empty(&self) -> bool {
        self.control_points.is_empty()
    }
    /// Append a control point to the end of the spline.
    pub fn add_point(&mut self, point: (f32, f32)) {
        self.control_points.push(point);
    }
    /// Remove and return the control point at `index`, or `None` when out of range.
    pub fn remove_point(&mut self, index: usize) -> Option<(f32, f32)> {
        if index < self.control_points.len() {
            Some(self.control_points.remove(index))
        } else {
            None
        }
    }
}

/// Single Hermite cubic spline segment defined by two endpoints and their tangents.
pub struct HermiteSpline {
    /// Start point.
    p0: (f32, f32),
    /// End point.
    p1: (f32, f32),
    /// Start tangent.
    m0: (f32, f32),
    /// End tangent.
    m1: (f32, f32),
}
impl HermiteSpline {
    /// Construct a Hermite segment from endpoints `p0`, `p1` and tangents `m0`, `m1`.
    pub fn new(p0: (f32, f32), p1: (f32, f32), m0: (f32, f32), m1: (f32, f32)) -> Self {
        Self { p0, p1, m0, m1 }
    }
    /// Sample the segment at `t` in `[0,1]` using Hermite basis polynomials.
    pub fn sample(&self, t: f32) -> (f32, f32) {
        let t2 = t * t;
        let t3 = t2 * t;
        let h00 = 2.0 * t3 - 3.0 * t2 + 1.0;
        let h10 = t3 - 2.0 * t2 + t;
        let h01 = -2.0 * t3 + 3.0 * t2;
        let h11 = t3 - t2;
        (
            h00 * self.p0.0 + h10 * self.m0.0 + h01 * self.p1.0 + h11 * self.m1.0,
            h00 * self.p0.1 + h10 * self.m0.1 + h01 * self.p1.1 + h11 * self.m1.1,
        )
    }
}
