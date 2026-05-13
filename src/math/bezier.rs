use crate::math::vec2::Vec2;
pub struct BezierCurve {
    control_points: Vec<Vec2>,
}
impl BezierCurve {
    pub fn new(points: Vec<Vec2>) -> Self {
        assert!(
            points.len() >= 2,
            "BezierCurve needs at least 2 control points"
        );
        Self {
            control_points: points,
        }
    }
    pub fn evaluate(&self, t: f32) -> Vec2 {
        let n = self.control_points.len();
        if n == 2 {
            return self.control_points[0].lerp(self.control_points[1], t);
        }
        let tc = t.clamp(0.0, 1.0);
        let omt = 1.0 - tc;
        let mut point = Vec2::ZERO;
        let mut coeff = 1.0f32;
        let degree = (n - 1) as f32;
        for (i, cp) in self.control_points.iter().enumerate() {
            let i_f = i as f32;
            let basis = coeff * omt.powf(degree - i_f) * tc.powf(i_f);
            point.x += cp.x * basis;
            point.y += cp.y * basis;
            if i + 1 < n {
                coeff = coeff * (degree - i_f) / (i_f + 1.0);
            }
        }
        point
    }
    pub fn render(&self, segments: usize) -> Vec<Vec2> {
        let segments = segments.max(1);
        let mut result = Vec::with_capacity(segments + 1);
        for i in 0..=segments {
            let t = i as f32 / segments as f32;
            result.push(self.evaluate(t));
        }
        result
    }
    pub fn render_segment(&self, t_start: f32, t_end: f32, segments: usize) -> Vec<Vec2> {
        let segments = segments.max(1);
        let mut result = Vec::with_capacity(segments + 1);
        for i in 0..=segments {
            let t = t_start + (t_end - t_start) * (i as f32 / segments as f32);
            result.push(self.evaluate(t));
        }
        result
    }
    pub fn get_derivative(&self) -> BezierCurve {
        let n = self.control_points.len();
        if n < 2 {
            return BezierCurve {
                control_points: vec![Vec2::ZERO, Vec2::ZERO],
            };
        }
        let degree = (n - 1) as f32;
        let mut derivative_points = Vec::with_capacity(n - 1);
        for i in 0..(n - 1) {
            derivative_points.push(Vec2::new(
                degree * (self.control_points[i + 1].x - self.control_points[i].x),
                degree * (self.control_points[i + 1].y - self.control_points[i].y),
            ));
        }
        if derivative_points.len() < 2 {
            derivative_points.push(derivative_points[0]);
        }
        BezierCurve {
            control_points: derivative_points,
        }
    }
    pub fn get_control_point(&self, index: usize) -> Option<Vec2> {
        self.control_points.get(index).copied()
    }
    pub fn set_control_point(&mut self, index: usize, point: Vec2) -> bool {
        if index < self.control_points.len() {
            self.control_points[index] = point;
            true
        } else {
            false
        }
    }
    pub fn insert_control_point(&mut self, point: Vec2, index: Option<usize>) {
        match index {
            Some(i) if i <= self.control_points.len() => {
                self.control_points.insert(i, point);
            }
            _ => self.control_points.push(point),
        }
    }
    pub fn remove_control_point(&mut self, index: usize) -> bool {
        if self.control_points.len() <= 2 || index >= self.control_points.len() {
            return false;
        }
        self.control_points.remove(index);
        true
    }
    pub fn get_control_point_count(&self) -> usize {
        self.control_points.len()
    }
    pub fn translate(&mut self, dx: f32, dy: f32) {
        for p in &mut self.control_points {
            p.x += dx;
            p.y += dy;
        }
    }
    pub fn rotate(&mut self, angle: f32, ox: f32, oy: f32) {
        let cos_a = angle.cos();
        let sin_a = angle.sin();
        for p in &mut self.control_points {
            let dx = p.x - ox;
            let dy = p.y - oy;
            p.x = ox + dx * cos_a - dy * sin_a;
            p.y = oy + dx * sin_a + dy * cos_a;
        }
    }
    pub fn scale(&mut self, s: f32, ox: f32, oy: f32) {
        for p in &mut self.control_points {
            p.x = ox + (p.x - ox) * s;
            p.y = oy + (p.y - oy) * s;
        }
    }
    pub fn length(&self) -> f32 {
        const SAMPLES: usize = 100;
        let mut total = 0.0f32;
        let mut prev = self.evaluate(0.0);
        for i in 1..=SAMPLES {
            let t = i as f32 / SAMPLES as f32;
            let curr = self.evaluate(t);
            let dx = curr.x - prev.x;
            let dy = curr.y - prev.y;
            total += (dx * dx + dy * dy).sqrt();
            prev = curr;
        }
        total
    }
    pub fn get_interpolated_position(&self, t: f32) -> (f32, f32) {
        let p = self.evaluate(t);
        (p.x, p.y)
    }
    pub fn evaluate_at_distance(&self, distance: f32, samples: usize) -> Vec2 {
        let samples = samples.max(8);
        if distance <= 0.0 {
            return self.evaluate(0.0);
        }
        let mut prev = self.evaluate(0.0);
        let mut walked = 0.0f32;
        for i in 1..=samples {
            let t = i as f32 / samples as f32;
            let curr = self.evaluate(t);
            let seg_len = prev.distance(curr);
            let next_walked = walked + seg_len;
            if distance <= next_walked {
                if seg_len <= f32::EPSILON {
                    return curr;
                }
                let local = (distance - walked) / seg_len;
                return prev.lerp(curr, local);
            }
            walked = next_walked;
            prev = curr;
        }
        self.evaluate(1.0)
    }
    pub fn get_interpolated_angle(&self, t: f32) -> f32 {
        let deriv = self.get_derivative();
        let tangent = deriv.evaluate(t);
        tangent.y.atan2(tangent.x)
    }
}
impl Clone for BezierCurve {
    fn clone(&self) -> Self {
        Self {
            control_points: self.control_points.clone(),
        }
    }
}
