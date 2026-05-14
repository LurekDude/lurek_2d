//! 2D float vector used throughout the engine for positions, directions, velocities, and sizes.
//! Provides arithmetic operators, geometric queries (dot, cross, reflect, rotate), and angle
//! helpers. Does not own matrix math — see `mat3` for transforms. Used by physics, rendering,
//! input, particles, and UI layout.

use std::ops::{Add, AddAssign, Div, Mul, MulAssign, Neg, Sub, SubAssign};

/// 2D float vector; backbone of all position and direction math in the engine.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Vec2 {
    /// Horizontal component.
    pub x: f32,
    /// Vertical component.
    pub y: f32,
}

impl Vec2 {
    /// Zero vector (0, 0).
    pub const ZERO: Vec2 = Vec2 { x: 0.0, y: 0.0 };
    /// Unit vector (1, 1).
    pub const ONE: Vec2 = Vec2 { x: 1.0, y: 1.0 };
    /// Screen-up direction (0, -1) in screen-space y-down convention.
    pub const UP: Vec2 = Vec2 { x: 0.0, y: -1.0 };
    /// Screen-down direction (0, 1).
    pub const DOWN: Vec2 = Vec2 { x: 0.0, y: 1.0 };
    /// Screen-left direction (-1, 0).
    pub const LEFT: Vec2 = Vec2 { x: -1.0, y: 0.0 };
    /// Screen-right direction (1, 0).
    pub const RIGHT: Vec2 = Vec2 { x: 1.0, y: 0.0 };

    /// Construct a new Vec2 from `x` and `y` components.
    pub fn new(x: f32, y: f32) -> Self {
        Vec2 { x, y }
    }

    /// Return the zero vector; alias for `Vec2::ZERO`.
    pub fn zero() -> Self {
        Vec2::ZERO
    }

    /// Construct a Vec2 with both components set to `v`.
    pub fn splat(v: f32) -> Self {
        Vec2 { x: v, y: v }
    }

    /// Return the dot product of `self` and `other`.
    pub fn dot(self, other: Vec2) -> f32 {
        self.x * other.x + self.y * other.y
    }

    /// Return the Euclidean length of this vector.
    pub fn length(self) -> f32 {
        (self.x * self.x + self.y * self.y).sqrt()
    }

    /// Return the squared length; cheaper than `length()` when only comparison is needed.
    pub fn length_squared(self) -> f32 {
        self.x * self.x + self.y * self.y
    }

    /// Return a unit-length copy; returns self unchanged when length is zero.
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

    /// Return the Euclidean distance from `self` to `other`.
    pub fn distance(self, other: Vec2) -> f32 {
        (self - other).length()
    }

    /// Linearly interpolate from `self` to `other` by scalar `t`.
    pub fn lerp(self, other: Vec2, t: f32) -> Vec2 {
        self + (other - self) * t
    }

    /// Return the angle of this vector in radians (atan2 of y over x).
    pub fn angle(self) -> f32 {
        self.y.atan2(self.x)
    }

    /// Return this vector rotated by `angle` radians counter-clockwise.
    pub fn rotate(self, angle: f32) -> Vec2 {
        let (sin, cos) = angle.sin_cos();
        Vec2 {
            x: self.x * cos - self.y * sin,
            y: self.x * sin + self.y * cos,
        }
    }

    /// Return the left-perpendicular vector (-y, x).
    pub fn perpendicular(self) -> Vec2 {
        Vec2 {
            x: -self.y,
            y: self.x,
        }
    }

    /// Return the 2D cross product (scalar z-component of the 3D cross product).
    pub fn cross(self, other: Vec2) -> f32 {
        self.x * other.y - self.y * other.x
    }

    /// Return a unit direction vector for the given angle in radians.
    pub fn from_angle(radians: f32) -> Vec2 {
        let (sin, cos) = radians.sin_cos();
        Vec2 { x: cos, y: sin }
    }

    /// Return this vector reflected across a surface with the given unit `normal`.
    pub fn reflect(self, normal: Vec2) -> Vec2 {
        self - normal * (2.0 * self.dot(normal))
    }
}

/// Add two Vec2 component-wise.
impl Add for Vec2 {
    type Output = Vec2;
    fn add(self, rhs: Vec2) -> Vec2 {
        Vec2 {
            x: self.x + rhs.x,
            y: self.y + rhs.y,
        }
    }
}

/// Subtract two Vec2 component-wise.
impl Sub for Vec2 {
    type Output = Vec2;
    fn sub(self, rhs: Vec2) -> Vec2 {
        Vec2 {
            x: self.x - rhs.x,
            y: self.y - rhs.y,
        }
    }
}

/// Scale Vec2 by a scalar float.
impl Mul<f32> for Vec2 {
    type Output = Vec2;
    fn mul(self, rhs: f32) -> Vec2 {
        Vec2 {
            x: self.x * rhs,
            y: self.y * rhs,
        }
    }
}

/// Divide Vec2 by a scalar float.
impl Div<f32> for Vec2 {
    type Output = Vec2;
    fn div(self, rhs: f32) -> Vec2 {
        Vec2 {
            x: self.x / rhs,
            y: self.y / rhs,
        }
    }
}

/// Add-assign another Vec2 component-wise.
impl AddAssign for Vec2 {
    fn add_assign(&mut self, rhs: Vec2) {
        self.x += rhs.x;
        self.y += rhs.y;
    }
}

/// Subtract-assign another Vec2 component-wise.
impl SubAssign for Vec2 {
    fn sub_assign(&mut self, rhs: Vec2) {
        self.x -= rhs.x;
        self.y -= rhs.y;
    }
}

/// Multiply-assign by a scalar float.
impl MulAssign<f32> for Vec2 {
    fn mul_assign(&mut self, rhs: f32) {
        self.x *= rhs;
        self.y *= rhs;
    }
}

/// Negate both components.
impl Neg for Vec2 {
    type Output = Vec2;
    fn neg(self) -> Vec2 {
        Vec2 {
            x: -self.x,
            y: -self.y,
        }
    }
}
