//! 2D floating-point vector — the primary math currency for positions,
//! velocities, directions, and interpolation throughout the engine.
//!
//! [`Vec2`] implements standard arithmetic operators (`+`, `-`, `*`, `/`,
//! negation, `+=`, `-=`, `*=`) and geometric helpers: `dot`, `cross`,
//! `length`, `normalize`, `distance`, `lerp`, `angle`, `rotate`, `perpendicular`.
//!
//! All operations are `Copy` — no references or allocations needed.
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

    /// Creates a unit vector from an angle in radians, measured from the positive X axis.
    ///
    /// # Parameters
    /// - `radians` — Angle in radians.
    ///
    /// # Returns
    /// `Vec2` — Unit vector `(cos(radians), sin(radians))`.
    pub fn from_angle(radians: f32) -> Vec2 {
        let (sin, cos) = radians.sin_cos();
        Vec2 { x: cos, y: sin }
    }

    /// Reflects this vector about a surface normal (normal must be unit length).
    ///
    /// # Parameters
    /// - `normal` — Unit-length surface normal.
    ///
    /// # Returns
    /// `Vec2` — Reflected vector.
    pub fn reflect(self, normal: Vec2) -> Vec2 {
        self - normal * (2.0 * self.dot(normal))
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
