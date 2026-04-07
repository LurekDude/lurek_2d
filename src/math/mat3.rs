//! Mat3 implementation for the `math` subsystem.
//!
//! This module is part of Luna2D's `math` subsystem and provides the implementation
//! details for mat3-related operations and data management.
//! Key types exported from this module: `Mat3`.
//! Primary functions: `identity()`, `from_row_major()`, `from_translation()`, `from_rotation()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use super::vec2::Vec2;

/// A 3×3 column-major matrix used for 2D affine transforms (translation, rotation, scale).
///
/// Used by `Camera::view_matrix` to combine position, rotation, and zoom into a single
/// transform that maps world coordinates to screen coordinates.
///
/// # Fields
/// - `m` — 3×3 array of `f32` in row-major layout (`m[row][col]`).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Mat3 {
    pub m: [[f32; 3]; 3],
}

impl Mat3 {
    /// Returns the 3×3 identity matrix. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `Mat3` — Identity: no translation, no rotation, scale 1.
    pub fn identity() -> Self {
        Mat3 {
            m: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
        }
    }

    /// Creates a `Mat3` from a flat 9-element array in row-major order.
    ///
    /// # Parameters
    /// - `data` — `&[f32; 9]`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_row_major(data: &[f32; 9]) -> Self {
        Mat3 {
            m: [
                [data[0], data[1], data[2]],
                [data[3], data[4], data[5]],
                [data[6], data[7], data[8]],
            ],
        }
    }

    /// Creates a translation matrix that moves points by `(t.x, t.y)`.
    ///
    /// # Parameters
    /// - `t` — Translation vector.
    ///
    /// # Returns
    /// `Mat3` — A pure translation matrix.
    pub fn from_translation(t: Vec2) -> Self {
        Mat3 {
            m: [[1.0, 0.0, t.x], [0.0, 1.0, t.y], [0.0, 0.0, 1.0]],
        }
    }

    /// Creates a rotation matrix for a counter-clockwise rotation of `angle` radians.
    ///
    /// # Parameters
    /// - `angle` — Rotation in radians.
    ///
    /// # Returns
    /// `Mat3` — A pure rotation matrix.
    pub fn from_rotation(angle: f32) -> Self {
        let c = angle.cos();
        let s = angle.sin();
        Mat3 {
            m: [[c, -s, 0.0], [s, c, 0.0], [0.0, 0.0, 1.0]],
        }
    }

    /// Creates a shear (skew) matrix. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `kx` — Shear factor along the X axis.
    /// - `ky` — Shear factor along the Y axis.
    ///
    /// # Returns
    /// `Mat3` — A pure shear matrix.
    pub fn from_shear(kx: f32, ky: f32) -> Self {
        Mat3 {
            m: [[1.0, ky, 0.0], [kx, 1.0, 0.0], [0.0, 0.0, 1.0]],
        }
    }

    /// Creates a non-uniform scale matrix with the given per-axis factors.
    ///
    /// # Parameters
    /// - `scale` — `Vec2` where `x` scales the X axis and `y` scales the Y axis.
    ///
    /// # Returns
    /// `Mat3` — A pure scale matrix.
    pub fn from_scale(scale: Vec2) -> Self {
        Mat3 {
            m: [[scale.x, 0.0, 0.0], [0.0, scale.y, 0.0], [0.0, 0.0, 1.0]],
        }
    }

    /// Compute the inverse of this 3×3 matrix. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// The inverse matrix, or the identity matrix if the determinant is ≈ 0.
    pub fn inverse(&self) -> Self {
        let m = &self.m;
        let det = m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
            - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
            + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);

        if det.abs() < 1e-10 {
            return Self::identity();
        }

        let inv_det = 1.0 / det;
        Self {
            m: [
                [
                    (m[1][1] * m[2][2] - m[1][2] * m[2][1]) * inv_det,
                    (m[0][2] * m[2][1] - m[0][1] * m[2][2]) * inv_det,
                    (m[0][1] * m[1][2] - m[0][2] * m[1][1]) * inv_det,
                ],
                [
                    (m[1][2] * m[2][0] - m[1][0] * m[2][2]) * inv_det,
                    (m[0][0] * m[2][2] - m[0][2] * m[2][0]) * inv_det,
                    (m[0][2] * m[1][0] - m[0][0] * m[1][2]) * inv_det,
                ],
                [
                    (m[1][0] * m[2][1] - m[1][1] * m[2][0]) * inv_det,
                    (m[0][1] * m[2][0] - m[0][0] * m[2][1]) * inv_det,
                    (m[0][0] * m[1][1] - m[0][1] * m[1][0]) * inv_det,
                ],
            ],
        }
    }

    /// Applies the matrix transform to a 2D point using homogeneous coordinates.
    ///
    /// # Parameters
    /// - `p` — Input point in 2D space.
    ///
    /// # Returns
    /// `Vec2` — The transformed point.
    pub fn transform_point(&self, p: Vec2) -> Vec2 {
        Vec2 {
            x: self.m[0][0] * p.x + self.m[0][1] * p.y + self.m[0][2],
            y: self.m[1][0] * p.x + self.m[1][1] * p.y + self.m[1][2],
        }
    }
}

impl std::ops::Mul for Mat3 {
    type Output = Mat3;
    fn mul(self, rhs: Mat3) -> Mat3 {
        let mut result = Mat3 { m: [[0.0; 3]; 3] };
        for i in 0..3 {
            for j in 0..3 {
                for k in 0..3 {
                    result.m[i][j] += self.m[i][k] * rhs.m[k][j];
                }
            }
        }
        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::math::vec2::Vec2;

    // ── Identity ─────────────────────────────────────────────────────────────

    #[test]
    fn identity_diagonal_ones() {
        let m = Mat3::identity();
        assert!((m.m[0][0] - 1.0).abs() < 1e-5);
        assert!((m.m[1][1] - 1.0).abs() < 1e-5);
        assert!((m.m[2][2] - 1.0).abs() < 1e-5);
        assert!((m.m[0][1]).abs() < 1e-5);
        assert!((m.m[1][0]).abs() < 1e-5);
    }

    #[test]
    fn identity_transforms_point_unchanged() {
        let m = Mat3::identity();
        let p = m.transform_point(Vec2::new(3.0, 7.0));
        assert!((p.x - 3.0).abs() < 1e-5);
        assert!((p.y - 7.0).abs() < 1e-5);
    }

    // ── Translation ─────────────────────────────────────────────────────────

    #[test]
    fn from_translation_offsets_point() {
        let m = Mat3::from_translation(Vec2::new(5.0, 3.0));
        let p = m.transform_point(Vec2::new(1.0, 2.0));
        assert!((p.x - 6.0).abs() < 1e-5);
        assert!((p.y - 5.0).abs() < 1e-5);
    }

    // ── Scale ─────────────────────────────────────────────────────────────────

    #[test]
    fn from_scale_scales_point() {
        let m = Mat3::from_scale(Vec2::new(2.0, 3.0));
        let p = m.transform_point(Vec2::new(4.0, 5.0));
        assert!((p.x - 8.0).abs() < 1e-5);
        assert!((p.y - 15.0).abs() < 1e-5);
    }

    // ── Rotation ───────────────────────────────────────────────────────────────

    #[test]
    fn from_rotation_90deg_right_becomes_down() {
        let m = Mat3::from_rotation(std::f32::consts::FRAC_PI_2);
        let p = m.transform_point(Vec2::new(1.0, 0.0));
        assert!((p.x).abs() < 1e-5);
        assert!((p.y - 1.0).abs() < 1e-5);
    }

    // ── Multiplication ───────────────────────────────────────────────────────────

    #[test]
    fn multiply_by_identity_unchanged() {
        let m = Mat3::from_translation(Vec2::new(5.0, 3.0));
        let result = m * Mat3::identity();
        let p = result.transform_point(Vec2::new(1.0, 2.0));
        assert!((p.x - 6.0).abs() < 1e-5);
        assert!((p.y - 5.0).abs() < 1e-5);
    }

    // ── Inverse ────────────────────────────────────────────────────────────────

    #[test]
    fn inverse_of_identity_is_identity() {
        let inv = Mat3::identity().inverse();
        let p = inv.transform_point(Vec2::new(3.0, 4.0));
        assert!((p.x - 3.0).abs() < 1e-5);
        assert!((p.y - 4.0).abs() < 1e-5);
    }

    #[test]
    fn inverse_undoes_translation() {
        let m = Mat3::from_translation(Vec2::new(10.0, 5.0));
        let inv = m.inverse();
        let p = inv.transform_point(Vec2::new(15.0, 8.0));
        assert!((p.x - 5.0).abs() < 1e-5);
        assert!((p.y - 3.0).abs() < 1e-5);
    }
}
