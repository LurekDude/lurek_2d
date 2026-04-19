//! 3D floating-point vector with arithmetic operators and common helpers.
//!
//! Provides `Vec3` — a 3-component `f32` vector for 3D math operations such as
//! cross products, projections, reflections, and distance calculations.
//! Used by noise generators (3D/4D coordinates), lighting direction vectors,
//! and any subsystem that needs a compact 3D value type.
//!
//! All operations are `Copy` — no heap allocations.

use std::fmt;
use std::ops::{Add, Div, Mul, Neg, Sub};

/// A 3D floating-point vector.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `z` — `f32`.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Vec3 {
    /// X component.
    pub x: f32,
    /// Y component.
    pub y: f32,
    /// Z component.
    pub z: f32,
}

impl Vec3 {
    /// Create a new vector with the given components.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `z` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(x: f32, y: f32, z: f32) -> Self {
        Self { x, y, z }
    }

    /// The zero vector (0, 0, 0).
    ///
    /// # Returns
    /// `Self`.
    pub fn zero() -> Self {
        Self::new(0.0, 0.0, 0.0)
    }

    /// The unit vector (1, 1, 1).
    ///
    /// # Returns
    /// `Self`.
    pub fn one() -> Self {
        Self::new(1.0, 1.0, 1.0)
    }

    /// Creates a vector with all three components set to `v`.
    ///
    /// # Parameters
    /// - `v` — Value for `x`, `y`, and `z`.
    ///
    /// # Returns
    /// `Vec3 { x: v, y: v, z: v }`.
    pub fn splat(v: f32) -> Self {
        Self::new(v, v, v)
    }

    /// Dot product of this vector and `other`.
    ///
    /// # Parameters
    /// - `other` — `Vec3`.
    ///
    /// # Returns
    /// `f32`.
    pub fn dot(&self, other: Vec3) -> f32 {
        self.x * other.x + self.y * other.y + self.z * other.z
    }

    /// Cross product of this vector and `other`.
    ///
    /// # Parameters
    /// - `other` — `Vec3`.
    ///
    /// # Returns
    /// `Vec3`.
    pub fn cross(&self, other: Vec3) -> Vec3 {
        Vec3::new(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x,
        )
    }

    /// Euclidean length (magnitude) of this vector.
    ///
    /// # Returns
    /// `f32`.
    pub fn length(&self) -> f32 {
        self.length_squared().sqrt()
    }

    /// Squared Euclidean length. Avoid the sqrt when only relative comparison is needed.
    ///
    /// # Returns
    /// `f32`.
    pub fn length_squared(&self) -> f32 {
        self.x * self.x + self.y * self.y + self.z * self.z
    }

    /// Returns a unit-length version of this vector, or the zero vector if length is zero.
    ///
    /// # Returns
    /// `Vec3`.
    pub fn normalize(&self) -> Vec3 {
        let len = self.length();
        if len < 1e-7 {
            Vec3::zero()
        } else {
            Vec3::new(self.x / len, self.y / len, self.z / len)
        }
    }

    /// Linear interpolation between this vector and `other` by factor `t` in [0, 1].
    ///
    /// # Parameters
    /// - `other` — `Vec3`.
    /// - `t` — `f32`.
    ///
    /// # Returns
    /// `Vec3`.
    pub fn lerp(&self, other: Vec3, t: f32) -> Vec3 {
        Vec3::new(
            self.x + t * (other.x - self.x),
            self.y + t * (other.y - self.y),
            self.z + t * (other.z - self.z),
        )
    }

    /// Euclidean distance to `other`.
    ///
    /// # Parameters
    /// - `other` — `Vec3`.
    ///
    /// # Returns
    /// `f32`.
    pub fn distance(&self, other: Vec3) -> f32 {
        (*self - other).length()
    }

    /// Project this vector onto `onto`.
    ///
    /// # Parameters
    /// - `onto` — `Vec3`.
    ///
    /// # Returns
    /// `Vec3`.
    pub fn project(&self, onto: Vec3) -> Vec3 {
        let d = onto.dot(onto);
        if d < 1e-14 {
            Vec3::zero()
        } else {
            onto * (self.dot(onto) / d)
        }
    }

    /// Reflect this vector about `normal` (normal must be unit length).
    ///
    /// # Parameters
    /// - `normal` — `Vec3`.
    ///
    /// # Returns
    /// `Vec3`.
    pub fn reflect(&self, normal: Vec3) -> Vec3 {
        *self - normal * (2.0 * self.dot(normal))
    }
}

impl Add for Vec3 {
    type Output = Vec3;
    fn add(self, rhs: Vec3) -> Vec3 {
        Vec3::new(self.x + rhs.x, self.y + rhs.y, self.z + rhs.z)
    }
}

impl Sub for Vec3 {
    type Output = Vec3;
    fn sub(self, rhs: Vec3) -> Vec3 {
        Vec3::new(self.x - rhs.x, self.y - rhs.y, self.z - rhs.z)
    }
}

impl Mul<f32> for Vec3 {
    type Output = Vec3;
    fn mul(self, s: f32) -> Vec3 {
        Vec3::new(self.x * s, self.y * s, self.z * s)
    }
}

impl Div<f32> for Vec3 {
    type Output = Vec3;
    fn div(self, s: f32) -> Vec3 {
        Vec3::new(self.x / s, self.y / s, self.z / s)
    }
}

impl Neg for Vec3 {
    type Output = Vec3;
    fn neg(self) -> Vec3 {
        Vec3::new(-self.x, -self.y, -self.z)
    }
}

impl fmt::Display for Vec3 {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "({}, {}, {})", self.x, self.y, self.z)
    }
}
