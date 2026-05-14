//! 3D float vector used for raycasting directions, 3D noise coordinates, lighting normals,
//! and volume intersection queries. Provides cross product, projection, reflect, and lerp.
//! Does not own 4×4 matrix math — 2D engine uses Mat3; Vec3 covers only the cases where
//! a third component is genuinely needed.

use std::fmt;
use std::ops::{Add, Div, Mul, Neg, Sub};

/// 3D float vector; used for cross-product normals, raycasting, and 3D noise inputs.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Vec3 {
    /// X component.
    pub x: f32,
    /// Y component.
    pub y: f32,
    /// Z component (depth / forward axis depending on context).
    pub z: f32,
}

impl Vec3 {
    /// Construct a Vec3 from `x`, `y`, `z`.
    pub fn new(x: f32, y: f32, z: f32) -> Self {
        Self { x, y, z }
    }

    /// Return the zero vector (0, 0, 0).
    pub fn zero() -> Self {
        Self::new(0.0, 0.0, 0.0)
    }

    /// Return the unit vector (1, 1, 1).
    pub fn one() -> Self {
        Self::new(1.0, 1.0, 1.0)
    }

    /// Construct a Vec3 with all components set to `v`.
    pub fn splat(v: f32) -> Self {
        Self::new(v, v, v)
    }

    /// Return the dot product of `self` and `other`.
    pub fn dot(&self, other: Vec3) -> f32 {
        self.x * other.x + self.y * other.y + self.z * other.z
    }

    /// Return the cross product of `self` × `other`.
    pub fn cross(&self, other: Vec3) -> Vec3 {
        Vec3::new(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x,
        )
    }

    /// Return the Euclidean length of this vector.
    pub fn length(&self) -> f32 {
        self.length_squared().sqrt()
    }

    /// Return the squared length; avoids a sqrt when only comparison is needed.
    pub fn length_squared(&self) -> f32 {
        self.x * self.x + self.y * self.y + self.z * self.z
    }

    /// Return a unit-length copy; returns zero vector when length is below 1e-7.
    pub fn normalize(&self) -> Vec3 {
        let len = self.length();
        if len < 1e-7 {
            Vec3::zero()
        } else {
            Vec3::new(self.x / len, self.y / len, self.z / len)
        }
    }

    /// Linearly interpolate from `self` to `other` by factor `t`.
    pub fn lerp(&self, other: Vec3, t: f32) -> Vec3 {
        Vec3::new(
            self.x + t * (other.x - self.x),
            self.y + t * (other.y - self.y),
            self.z + t * (other.z - self.z),
        )
    }

    /// Return the Euclidean distance from `self` to `other`.
    pub fn distance(&self, other: Vec3) -> f32 {
        (*self - other).length()
    }

    /// Return the projection of `self` onto `onto`; returns zero vector when `onto` is near-zero.
    pub fn project(&self, onto: Vec3) -> Vec3 {
        let d = onto.dot(onto);
        if d < 1e-14 {
            Vec3::zero()
        } else {
            onto * (self.dot(onto) / d)
        }
    }

    /// Return this vector reflected across a surface with the given unit `normal`.
    pub fn reflect(&self, normal: Vec3) -> Vec3 {
        *self - normal * (2.0 * self.dot(normal))
    }
}

/// Add two Vec3 component-wise.
impl Add for Vec3 {
    type Output = Vec3;
    fn add(self, rhs: Vec3) -> Vec3 {
        Vec3::new(self.x + rhs.x, self.y + rhs.y, self.z + rhs.z)
    }
}

/// Subtract two Vec3 component-wise.
impl Sub for Vec3 {
    type Output = Vec3;
    fn sub(self, rhs: Vec3) -> Vec3 {
        Vec3::new(self.x - rhs.x, self.y - rhs.y, self.z - rhs.z)
    }
}

/// Scale Vec3 by a scalar float.
impl Mul<f32> for Vec3 {
    type Output = Vec3;
    fn mul(self, s: f32) -> Vec3 {
        Vec3::new(self.x * s, self.y * s, self.z * s)
    }
}

/// Divide Vec3 by a scalar float.
impl Div<f32> for Vec3 {
    type Output = Vec3;
    fn div(self, s: f32) -> Vec3 {
        Vec3::new(self.x / s, self.y / s, self.z / s)
    }
}

/// Negate all three components.
impl Neg for Vec3 {
    type Output = Vec3;
    fn neg(self) -> Vec3 {
        Vec3::new(-self.x, -self.y, -self.z)
    }
}

/// Format Vec3 as `(x, y, z)`.
impl fmt::Display for Vec3 {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "({}, {}, {})", self.x, self.y, self.z)
    }
}
