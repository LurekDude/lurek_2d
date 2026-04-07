//! Vec2 implementation for the `math` subsystem.
//!
//! This module is part of Luna2D's `math` subsystem and provides the implementation
//! details for vec2-related operations and data management.
//! Key types exported from this module: `Vec2`.
//! Primary functions: `new()`, `zero()`, `splat()`, `dot()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use std::ops::{Add, AddAssign, Div, Mul, MulAssign, Neg, Sub, SubAssign};

/// A 2D floating-point vector used throughout the engine for positions, velocities, and directions.
///
/// Implements standard arithmetic operators (`+`, `-`, `*`, `/`, negation) and common
/// geometric helpers. All operations are `Copy` — no references needed.
///
/// # Fields
/// - `x` — Horizontal component.
/// - `y` — Vertical component.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Vec2 {
    pub x: f32,
    pub y: f32,
}

impl Vec2 {
    /// The zero vector `(0.0, 0.0)`. Consult the module-level documentation for the broader usage context and preconditions.
    pub const ZERO: Vec2 = Vec2 { x: 0.0, y: 0.0 };
    /// The unit vector `(1.0, 1.0)`. Consult the module-level documentation for the broader usage context and preconditions.
    pub const ONE: Vec2 = Vec2 { x: 1.0, y: 1.0 };
    /// Unit vector pointing up `(0.0, -1.0)` — screen space where Y increases downward.
    pub const UP: Vec2 = Vec2 { x: 0.0, y: -1.0 };
    /// Unit vector pointing down `(0.0, 1.0)`. Consult the module-level documentation for the broader usage context and preconditions.
    pub const DOWN: Vec2 = Vec2 { x: 0.0, y: 1.0 };
    /// Unit vector pointing left `(-1.0, 0.0)`.
    pub const LEFT: Vec2 = Vec2 { x: -1.0, y: 0.0 };
    /// Unit vector pointing right `(1.0, 0.0)`.
    pub const RIGHT: Vec2 = Vec2 { x: 1.0, y: 0.0 };

    /// Creates a new vector from `x` and `y` components.
    ///
    /// # Parameters
    /// - `x` — Horizontal component.
    /// - `y` — Vertical component.
    ///
    /// # Returns
    /// A new `Vec2`.
    pub fn new(x: f32, y: f32) -> Self {
        Vec2 { x, y }
    }

    /// Returns the zero vector `(0.0, 0.0)`. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// Equivalent to `Vec2::ZERO`; provided for ergonomics.
    ///
    /// # Returns
    /// `Vec2::ZERO`.
    pub fn zero() -> Self {
        Vec2::ZERO
    }

    /// Creates a vector with both components set to `v`.
    ///
    /// # Parameters
    /// - `v` — Value for both `x` and `y`.
    ///
    /// # Returns
    /// `Vec2 { x: v, y: v }`.
    pub fn splat(v: f32) -> Self {
        Vec2 { x: v, y: v }
    }

    /// Returns the dot product of this vector and `other`.
    ///
    /// # Parameters
    /// - `other` — The second vector.
    ///
    /// # Returns
    /// `f32` — The scalar dot product.
    pub fn dot(self, other: Vec2) -> f32 {
        self.x * other.x + self.y * other.y
    }

    /// Returns the Euclidean length (magnitude) of the vector.
    ///
    /// # Returns
    /// `f32` — `√(x² + y²)`.
    pub fn length(self) -> f32 {
        (self.x * self.x + self.y * self.y).sqrt()
    }

    /// Returns the squared Euclidean length of the vector.
    ///
    /// Cheaper than `length` when only comparing magnitudes.
    ///
    /// # Returns
    /// `f32` — `x² + y²`.
    pub fn length_squared(self) -> f32 {
        self.x * self.x + self.y * self.y
    }

    /// Returns a unit vector in the same direction, or the original vector if its length is zero.
    ///
    /// # Returns
    /// `Vec2` — Normalized vector with length 1, or `self` if `length() == 0`.
    pub fn normalize(self) -> Vec2 {
        let len = self.length();
        if len > 0.0 {
            Vec2 {
                x: self.x / len,
                y: self.y / len,
            }
        } else {
            self
        }
    }

    /// Returns the Euclidean distance between this point and `other`.
    ///
    /// # Parameters
    /// - `other` — The target point.
    ///
    /// # Returns
    /// `f32` — Distance between the two points.
    pub fn distance(self, other: Vec2) -> f32 {
        (self - other).length()
    }

    /// Linearly interpolates between `self` and `other` by factor `t`.
    ///
    /// `t = 0.0` returns `self`; `t = 1.0` returns `other`; values outside `[0, 1]` extrapolate.
    ///
    /// # Parameters
    /// - `other` — Target vector.
    /// - `t` — Interpolation factor.
    ///
    /// # Returns
    /// `Vec2` — Interpolated vector.
    pub fn lerp(self, other: Vec2, t: f32) -> Vec2 {
        self + (other - self) * t
    }

    /// Returns the angle of the vector in radians, measured from the positive X axis.
    ///
    /// # Returns
    /// `f32` — Angle in radians using `atan2(y, x)`.
    pub fn angle(self) -> f32 {
        self.y.atan2(self.x)
    }

    /// Returns a copy of this vector rotated by `angle` radians around the origin.
    ///
    /// # Parameters
    /// - `angle` — Rotation angle in radians.
    ///
    /// # Returns
    /// `Vec2` — The rotated vector.
    pub fn rotate(self, angle: f32) -> Vec2 {
        let (sin, cos) = angle.sin_cos();
        Vec2 {
            x: self.x * cos - self.y * sin,
            y: self.x * sin + self.y * cos,
        }
    }

    /// Returns the perpendicular (normal) vector, rotated 90° counter-clockwise.
    ///
    /// # Returns
    /// `Vec2` — `(-y, x)`.
    pub fn perpendicular(self) -> Vec2 {
        Vec2 {
            x: -self.y,
            y: self.x,
        }
    }

    /// Returns the 2D cross product (perpendicular dot product) with `other`.
    ///
    /// This is the z-component of the 3D cross product when z=0.
    /// Positive if `other` is counter-clockwise from `self`, negative if clockwise.
    ///
    /// # Parameters
    /// - `other` — The second vector.
    ///
    /// # Returns
    /// `f32` — `self.x * other.y - self.y * other.x`.
    pub fn cross(self, other: Vec2) -> f32 {
        self.x * other.y - self.y * other.x
    }
}

impl Add for Vec2 {
    type Output = Vec2;
    fn add(self, rhs: Vec2) -> Vec2 {
        Vec2 {
            x: self.x + rhs.x,
            y: self.y + rhs.y,
        }
    }
}

impl Sub for Vec2 {
    type Output = Vec2;
    fn sub(self, rhs: Vec2) -> Vec2 {
        Vec2 {
            x: self.x - rhs.x,
            y: self.y - rhs.y,
        }
    }
}

impl Mul<f32> for Vec2 {
    type Output = Vec2;
    fn mul(self, rhs: f32) -> Vec2 {
        Vec2 {
            x: self.x * rhs,
            y: self.y * rhs,
        }
    }
}

impl Div<f32> for Vec2 {
    type Output = Vec2;
    fn div(self, rhs: f32) -> Vec2 {
        Vec2 {
            x: self.x / rhs,
            y: self.y / rhs,
        }
    }
}

impl AddAssign for Vec2 {
    fn add_assign(&mut self, rhs: Vec2) {
        self.x += rhs.x;
        self.y += rhs.y;
    }
}

impl SubAssign for Vec2 {
    fn sub_assign(&mut self, rhs: Vec2) {
        self.x -= rhs.x;
        self.y -= rhs.y;
    }
}

impl MulAssign<f32> for Vec2 {
    fn mul_assign(&mut self, rhs: f32) {
        self.x *= rhs;
        self.y *= rhs;
    }
}

impl Neg for Vec2 {
    type Output = Vec2;
    fn neg(self) -> Vec2 {
        Vec2 {
            x: -self.x,
            y: -self.y,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn new_fields_correct() {
        let v = Vec2::new(3.0, 4.0);
        assert!((v.x - 3.0).abs() < 1e-5);
        assert!((v.y - 4.0).abs() < 1e-5);
    }

    #[test]
    fn zero_constant_both_zero() {
        assert!((Vec2::ZERO.x).abs() < 1e-5);
        assert!((Vec2::ZERO.y).abs() < 1e-5);
    }

    #[test]
    fn splat_components_equal() {
        let v = Vec2::splat(5.0);
        assert!((v.x - 5.0).abs() < 1e-5);
        assert!((v.y - 5.0).abs() < 1e-5);
    }

    // ── Dot product ───────────────────────────────────────────────────────────

    #[test]
    fn dot_perpendicular_is_zero() {
        assert!((Vec2::RIGHT.dot(Vec2::UP)).abs() < 1e-5);
    }

    #[test]
    fn dot_parallel_is_one() {
        assert!((Vec2::RIGHT.dot(Vec2::RIGHT) - 1.0).abs() < 1e-5);
    }

    // ── Length / normalize ────────────────────────────────────────────────────

    #[test]
    fn length_three_four_five() {
        let v = Vec2::new(3.0, 4.0);
        assert!((v.length() - 5.0).abs() < 1e-5);
    }

    #[test]
    fn length_squared_correct() {
        let v = Vec2::new(3.0, 4.0);
        assert!((v.length_squared() - 25.0).abs() < 1e-5);
    }

    #[test]
    fn normalize_gives_unit_length() {
        let v = Vec2::new(3.0, 4.0).normalize();
        assert!((v.length() - 1.0).abs() < 1e-5);
    }

    #[test]
    fn normalize_zero_vector_returns_zero() {
        let v = Vec2::ZERO.normalize();
        assert!((v.x).abs() < 1e-5);
        assert!((v.y).abs() < 1e-5);
    }

    // ── Lerp / distance ───────────────────────────────────────────────────────

    #[test]
    fn lerp_midpoint_is_half() {
        let v = Vec2::ZERO.lerp(Vec2::ONE, 0.5);
        assert!((v.x - 0.5).abs() < 1e-5);
        assert!((v.y - 0.5).abs() < 1e-5);
    }

    #[test]
    fn distance_three_four_five() {
        let d = Vec2::ZERO.distance(Vec2::new(3.0, 4.0));
        assert!((d - 5.0).abs() < 1e-5);
    }

    // ── Arithmetic ────────────────────────────────────────────────────────────

    #[test]
    fn add_components() {
        let r = Vec2::new(1.0, 2.0) + Vec2::new(3.0, 4.0);
        assert!((r.x - 4.0).abs() < 1e-5);
        assert!((r.y - 6.0).abs() < 1e-5);
    }

    #[test]
    fn sub_components() {
        let r = Vec2::new(5.0, 3.0) - Vec2::new(2.0, 1.0);
        assert!((r.x - 3.0).abs() < 1e-5);
        assert!((r.y - 2.0).abs() < 1e-5);
    }

    #[test]
    fn neg_flips_sign() {
        let r = -Vec2::new(1.0, -1.0);
        assert!((r.x - (-1.0)).abs() < 1e-5);
        assert!((r.y - 1.0).abs() < 1e-5);
    }

    #[test]
    fn mul_scalar() {
        let r = Vec2::new(2.0, 3.0) * 4.0;
        assert!((r.x - 8.0).abs() < 1e-5);
        assert!((r.y - 12.0).abs() < 1e-5);
    }

    // ── Perpendicular / cross ─────────────────────────────────────────────────

    #[test]
    fn perpendicular_rotates_ccw() {
        let v = Vec2::new(1.0, 0.0).perpendicular();
        assert!((v.x - 0.0).abs() < 1e-5);
        assert!((v.y - 1.0).abs() < 1e-5);
    }

    #[test]
    fn cross_known_value() {
        let a = Vec2::new(1.0, 0.0);
        let b = Vec2::new(0.0, 1.0);
        assert!((a.cross(b) - 1.0).abs() < 1e-5);
    }
}
