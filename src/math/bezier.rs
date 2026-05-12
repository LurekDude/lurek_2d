//! Bézier curve evaluation using De Casteljau's algorithm.
//!
//! Supports arbitrary-degree curves with control point manipulation,
//! rendering to polylines, derivative computation, and geometric transforms.
//! Script code accesses this through `lurek.math.newBezierCurve()`.
//!
//! Key type: [`BezierCurve`].

use crate::math::vec2::Vec2;

/// A Bezier curve defined by control points.
///
/// Uses De Casteljau's algorithm for evaluation. Minimum 2 control points required.
///
/// # Fields
/// - `control_points` — `Vec<Vec2>`.
pub struct BezierCurve {
    /// Control points defining the curve.
    control_points: Vec<Vec2>,
}

impl BezierCurve {
    /// Create a new Bezier curve from control points.
    ///
    /// # Parameters
    /// - `points` — at least 2 `Vec2` control points defining the curve
    ///
    /// # Returns
    /// A `BezierCurve` with the given control points.
    ///
    /// # Panics
    /// Panics if fewer than 2 control points are provided.
    pub fn new(points: Vec<Vec2>) -> Self {
        assert!(
            points.len() >= 2,
            "BezierCurve needs at least 2 control points"
        );
        Self {
            control_points: points,
        }
    }

    /// Evaluate the curve at parameter `t` using De Casteljau's algorithm.
    ///
    /// # Parameters
    /// - `t` — curve parameter in `[0.0, 1.0]`; 0 returns the first control point, 1 the last
    ///
    /// # Returns
    /// The point on the curve at `t`.
    pub fn evaluate(&self, t: f32) -> Vec2 {
        let n = self.control_points.len();
        if n == 2 {
            return self.control_points[0].lerp(self.control_points[1], t);
        }
        let tc = t.clamp(0.0, 1.0);
        let omt = 1.0 - tc;

        // Bernstein polynomial form (no temporary Vec allocations).
        let mut point = Vec2::ZERO;
        let mut coeff = 1.0f32; // C(n-1, 0)
        let degree = (n - 1) as f32;

        for (i, cp) in self.control_points.iter().enumerate() {
            let i_f = i as f32;
            let basis = coeff * omt.powf(degree - i_f) * tc.powf(i_f);
            point.x += cp.x * basis;
            point.y += cp.y * basis;

            // Next binomial coefficient C(n-1, i+1)
            if i + 1 < n {
                coeff = coeff * (degree - i_f) / (i_f + 1.0);
            }
        }

        point
    }

    /// Render the curve as a polyline with the given number of segments.
    ///
    /// # Parameters
    /// - `segments` — number of line segments; clamped to at least 1
    ///
    /// # Returns
    /// `segments + 1` evenly-spaced `Vec2` points along the curve.
    pub fn render(&self, segments: usize) -> Vec<Vec2> {
        let segments = segments.max(1);
        let mut result = Vec::with_capacity(segments + 1);
        for i in 0..=segments {
            let t = i as f32 / segments as f32;
            result.push(self.evaluate(t));
        }
        result
    }

    /// Render a portion of the curve between `t_start` and `t_end`.
    ///
    /// # Parameters
    /// - `t_start` — start of the sub-curve parameter in `[0.0, 1.0]`
    /// - `t_end` — end of the sub-curve parameter in `[0.0, 1.0]`
    /// - `segments` — number of line segments; clamped to at least 1
    ///
    /// # Returns
    /// `segments + 1` `Vec2` points between `t_start` and `t_end`.
    pub fn render_segment(&self, t_start: f32, t_end: f32, segments: usize) -> Vec<Vec2> {
        let segments = segments.max(1);
        let mut result = Vec::with_capacity(segments + 1);
        for i in 0..=segments {
            let t = t_start + (t_end - t_start) * (i as f32 / segments as f32);
            result.push(self.evaluate(t));
        }
        result
    }

    /// Compute the derivative curve (one degree lower than the current curve).
    ///
    /// # Returns
    /// A new `BezierCurve` representing the first derivative; useful for tangent direction queries.
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
        // Derivative of a degree-1 curve (2 points) is a single point; pad to 2 for safety
        if derivative_points.len() < 2 {
            derivative_points.push(derivative_points[0]);
        }
        BezierCurve {
            control_points: derivative_points,
        }
    }

    /// Get a control point by 0-based index. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `index` — 0-based control point index
    ///
    /// # Returns
    /// `Some(Vec2)` if the index is in range, or `None` if out of bounds.
    pub fn get_control_point(&self, index: usize) -> Option<Vec2> {
        self.control_points.get(index).copied()
    }

    /// Set a control point by 0-based index. Replaces the current control point value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `index` — 0-based control point index
    /// - `point` — new position for the control point
    ///
    /// # Returns
    /// `true` if the index was in range and the point was updated; `false` otherwise.
    pub fn set_control_point(&mut self, index: usize, point: Vec2) -> bool {
        if index < self.control_points.len() {
            self.control_points[index] = point;
            true
        } else {
            false
        }
    }

    /// Insert a control point at a given index, or append if `index` is `None`.
    ///
    /// # Parameters
    /// - `point` — position of the new control point
    /// - `index` — 0-based insertion index; `None` appends at the end
    pub fn insert_control_point(&mut self, point: Vec2, index: Option<usize>) {
        match index {
            Some(i) if i <= self.control_points.len() => {
                self.control_points.insert(i, point);
            }
            _ => self.control_points.push(point),
        }
    }

    /// Remove a control point by 0-based index.
    ///
    /// # Parameters
    /// - `index` — 0-based index of the control point to remove
    ///
    /// # Returns
    /// `false` if removal would leave fewer than 2 points, or if `index` is out of range.
    pub fn remove_control_point(&mut self, index: usize) -> bool {
        if self.control_points.len() <= 2 || index >= self.control_points.len() {
            return false;
        }
        self.control_points.remove(index);
        true
    }

    /// Get the number of control points. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// Number of control points; always ≥ 2.
    pub fn get_control_point_count(&self) -> usize {
        self.control_points.len()
    }

    /// Translate all control points by `(dx, dy)`.
    ///
    /// # Parameters
    /// - `dx` — horizontal offset
    /// - `dy` — vertical offset
    pub fn translate(&mut self, dx: f32, dy: f32) {
        for p in &mut self.control_points {
            p.x += dx;
            p.y += dy;
        }
    }

    /// Rotate all control points around a pivot `(ox, oy)` by `angle` radians.
    ///
    /// # Parameters
    /// - `angle` — rotation in radians
    /// - `ox` — pivot x coordinate
    /// - `oy` — pivot y coordinate
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

    /// Scale all control points around a pivot `(ox, oy)` by factor `s`.
    ///
    /// # Parameters
    /// - `s` — uniform scale factor
    /// - `ox` — pivot x coordinate
    /// - `oy` — pivot y coordinate
    pub fn scale(&mut self, s: f32, ox: f32, oy: f32) {
        for p in &mut self.control_points {
            p.x = ox + (p.x - ox) * s;
            p.y = oy + (p.y - oy) * s;
        }
    }

    /// Approximate the total arc length of the curve.
    ///
    /// Samples the curve at `100` equidistant parameter values and sums segment lengths.
    /// Accuracy improves with more control points that are closer together.
    ///
    /// # Returns
    /// Approximate arc length in the same units as the control points.
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

    /// Evaluate the curve position at parameter `t` and return it as an `(x, y)` tuple.
    ///
    /// Equivalent to `evaluate(t)` but returns a plain tuple for ergonomic Lua binding.
    ///
    /// # Parameters
    /// - `t` — curve parameter in `[0.0, 1.0]`
    ///
    /// # Returns
    /// `(x, y)` position on the curve.
    pub fn get_interpolated_position(&self, t: f32) -> (f32, f32) {
        let p = self.evaluate(t);
        (p.x, p.y)
    }

    /// Evaluate a point by travelled arc distance along the curve.
    ///
    /// This approximates constant-speed parameterization by sampling the curve,
    /// accumulating arc-length, then interpolating within the segment where the
    /// requested distance falls.
    ///
    /// # Parameters
    /// - `distance` — travelled arc-length from the start of the curve
    /// - `samples` — number of samples used for approximation (clamped to ≥ 8)
    ///
    /// # Returns
    /// Point on the curve at the requested distance, clamped to start/end.
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

    /// Return the angle of the curve tangent at parameter `t` in radians.
    ///
    /// Uses the first derivative curve to compute the tangent direction.
    /// Returns `0.0` when the tangent length is zero (degenerate curve section).
    ///
    /// # Parameters
    /// - `t` — curve parameter in `[0.0, 1.0]`
    ///
    /// # Returns
    /// Tangent angle in radians (`atan2(dy, dx)`).
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
