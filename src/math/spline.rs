pub struct CatmullRomSpline {
    control_points: Vec<(f32, f32)>,
}
impl CatmullRomSpline {
    pub fn new(points: Vec<(f32, f32)>) -> Self {
        Self {
            control_points: points,
        }
    }
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
    pub fn len(&self) -> usize {
        self.control_points.len()
    }
    pub fn is_empty(&self) -> bool {
        self.control_points.is_empty()
    }
    pub fn add_point(&mut self, point: (f32, f32)) {
        self.control_points.push(point);
    }
    pub fn remove_point(&mut self, index: usize) -> Option<(f32, f32)> {
        if index < self.control_points.len() {
            Some(self.control_points.remove(index))
        } else {
            None
        }
    }
}
pub struct HermiteSpline {
    p0: (f32, f32),
    p1: (f32, f32),
    m0: (f32, f32),
    m1: (f32, f32),
}
impl HermiteSpline {
    pub fn new(p0: (f32, f32), p1: (f32, f32), m0: (f32, f32), m1: (f32, f32)) -> Self {
        Self { p0, p1, m0, m1 }
    }
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
