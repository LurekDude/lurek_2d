//! 2D affine transform wrapping Mat3 with chainable methods.
//!
//! Compatible with standard 2D transform API for translate, rotate, scale,
//! shear, and point transformation.
//!
//! This module is part of Luna2D's `math` subsystem and provides the implementation
//! details for transform-related operations and data management.
//! Key types exported from this module: `Transform`.
//! Primary functions: `new()`, `from_components()`, `translate()`, `rotate()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::math::mat3::Mat3;
use crate::math::vec2::Vec2;

/// 2D affine transform exposed as a Lua object.
///
/// Wraps `Mat3` with chainable transformation methods matching
/// the standard 2D transform API.
///
/// # Fields
/// - `matrix` — `Mat3`.
#[derive(Debug, Clone, Copy)]
pub struct Transform {
    /// Internal 3×3 matrix.
    matrix: Mat3,
}

impl Transform {
    /// Create an identity transform (no translation, rotation, or scale).
    ///
    /// # Returns
    /// A `Transform` with identity matrix.
    pub fn new() -> Self {
        Self {
            matrix: Mat3::identity(),
        }
    }

    /// Create from full transformation parameters (standard parameter order).
    ///
    /// Equivalent to: `translate(x, y) → rotate(angle) → scale(sx, sy) → shear(kx, ky) → translate(-ox, -oy)`
    ///
    /// # Parameters
    /// - `x`, `y` — world position
    /// - `angle` — rotation in radians
    /// - `sx`, `sy` — scale factors
    /// - `ox`, `oy` — local origin offset subtracted before other transforms
    /// - `kx`, `ky` — shear factors
    ///
    /// # Returns
    /// A new `Transform` with all components applied.
    #[allow(clippy::too_many_arguments)]
    pub fn from_components(
        x: f32,
        y: f32,
        angle: f32,
        sx: f32,
        sy: f32,
        ox: f32,
        oy: f32,
        kx: f32,
        ky: f32,
    ) -> Self {
        let mut t = Self::new();
        t.translate(x, y);
        t.rotate(angle);
        t.scale(sx, sy);
        t.shear(kx, ky);
        t.translate(-ox, -oy);
        t
    }

    /// Apply translation to the transform. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `dx` — horizontal offset
    /// - `dy` — vertical offset
    ///
    /// # Returns
    /// `&mut Self` for method chaining.
    pub fn translate(&mut self, dx: f32, dy: f32) -> &mut Self {
        self.matrix = self.matrix * Mat3::from_translation(Vec2::new(dx, dy));
        self
    }

    /// Apply a rotation to the transform. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `angle` — rotation angle in radians
    ///
    /// # Returns
    /// `&mut Self` for method chaining.
    pub fn rotate(&mut self, angle: f32) -> &mut Self {
        self.matrix = self.matrix * Mat3::from_rotation(angle);
        self
    }

    /// Apply non-uniform scaling to the transform.
    ///
    /// # Parameters
    /// - `sx` — horizontal scale factor
    /// - `sy` — vertical scale factor
    ///
    /// # Returns
    /// `&mut Self` for method chaining.
    pub fn scale(&mut self, sx: f32, sy: f32) -> &mut Self {
        self.matrix = self.matrix * Mat3::from_scale(Vec2::new(sx, sy));
        self
    }

    /// Apply shear to the transform (standard convention).
    ///
    /// # Parameters
    /// - `kx` — horizontal shear factor
    /// - `ky` — vertical shear factor
    ///
    /// # Returns
    /// `&mut Self` for method chaining.
    pub fn shear(&mut self, kx: f32, ky: f32) -> &mut Self {
        let shear = Mat3 {
            m: [[1.0, kx, 0.0], [ky, 1.0, 0.0], [0.0, 0.0, 1.0]],
        };
        self.matrix = self.matrix * shear;
        self
    }

    /// Reset the transform to the identity matrix.
    ///
    /// # Returns
    /// `&mut Self` for method chaining.
    pub fn reset(&mut self) -> &mut Self {
        self.matrix = Mat3::identity();
        self
    }

    /// Replace the current state with full transformation parameters.
    ///
    /// # Parameters
    /// - `x`, `y` — world position
    /// - `angle` — rotation in radians
    /// - `sx`, `sy` — scale factors
    /// - `ox`, `oy` — local origin offset
    /// - `kx`, `ky` — shear factors
    ///
    /// # Returns
    /// `&mut Self` for method chaining.
    #[allow(clippy::too_many_arguments)]
    pub fn set_transformation(
        &mut self,
        x: f32,
        y: f32,
        angle: f32,
        sx: f32,
        sy: f32,
        ox: f32,
        oy: f32,
        kx: f32,
        ky: f32,
    ) -> &mut Self {
        *self = Self::from_components(x, y, angle, sx, sy, ox, oy, kx, ky);
        self
    }

    /// Transform a point from local space to world space.
    ///
    /// # Parameters
    /// - `x` — local x coordinate
    /// - `y` — local y coordinate
    ///
    /// # Returns
    /// `(world_x, world_y)` after applying this transform.
    pub fn transform_point(&self, x: f32, y: f32) -> (f32, f32) {
        let p = self.matrix.transform_point(Vec2::new(x, y));
        (p.x, p.y)
    }

    /// Transform a point from world space back to local space.
    ///
    /// # Parameters
    /// - `x` — world x coordinate
    /// - `y` — world y coordinate
    ///
    /// # Returns
    /// `(local_x, local_y)` after applying the inverse transform.
    pub fn inverse_transform_point(&self, x: f32, y: f32) -> (f32, f32) {
        let inv = self.inverse();
        let p = inv.matrix.transform_point(Vec2::new(x, y));
        (p.x, p.y)
    }

    /// Compute the inverse of this transform. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// A `Transform` that undoes this transform; composing them gives identity.
    pub fn inverse(&self) -> Self {
        Self {
            matrix: self.matrix.inverse(),
        }
    }

    /// Get the internal matrix (for renderer integration).
    ///
    /// # Returns
    /// A reference to the underlying `Mat3`.
    pub fn matrix(&self) -> &Mat3 {
        &self.matrix
    }
}

impl Default for Transform {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Identity ─────────────────────────────────────────────────────────────

    #[test]
    fn new_is_identity_transform() {
        let t = Transform::new();
        let (x, y) = t.transform_point(3.0, 5.0);
        assert!((x - 3.0).abs() < 1e-5);
        assert!((y - 5.0).abs() < 1e-5);
    }

    #[test]
    fn default_is_identity_transform() {
        let t = Transform::default();
        let (x, y) = t.transform_point(1.0, 2.0);
        assert!((x - 1.0).abs() < 1e-5);
        assert!((y - 2.0).abs() < 1e-5);
    }

    // ── Translate ────────────────────────────────────────────────────────────

    #[test]
    fn translate_offsets_point() {
        let mut t = Transform::new();
        t.translate(10.0, 5.0);
        let (x, y) = t.transform_point(1.0, 2.0);
        assert!((x - 11.0).abs() < 1e-5);
        assert!((y - 7.0).abs() < 1e-5);
    }

    // ── Scale ─────────────────────────────────────────────────────────────────

    #[test]
    fn scale_scales_point() {
        let mut t = Transform::new();
        t.scale(2.0, 3.0);
        let (x, y) = t.transform_point(4.0, 5.0);
        assert!((x - 8.0).abs() < 1e-5);
        assert!((y - 15.0).abs() < 1e-5);
    }

    // ── Rotate ────────────────────────────────────────────────────────────────

    #[test]
    fn rotate_90deg_right_becomes_down() {
        let mut t = Transform::new();
        t.rotate(std::f32::consts::FRAC_PI_2);
        let (x, y) = t.transform_point(1.0, 0.0);
        assert!((x).abs() < 1e-5);
        assert!((y - 1.0).abs() < 1e-5);
    }

    // ── Reset ─────────────────────────────────────────────────────────────────

    #[test]
    fn reset_returns_to_identity() {
        let mut t = Transform::new();
        t.translate(100.0, 100.0);
        t.reset();
        let (x, y) = t.transform_point(1.0, 2.0);
        assert!((x - 1.0).abs() < 1e-5);
        assert!((y - 2.0).abs() < 1e-5);
    }

    // ── Round-trip ────────────────────────────────────────────────────────────

    #[test]
    fn inverse_undoes_translation() {
        let mut t = Transform::new();
        t.translate(7.0, 3.0);
        let (tx, ty) = t.transform_point(2.0, 1.0);
        let (rx, ry) = t.inverse_transform_point(tx, ty);
        assert!((rx - 2.0).abs() < 1e-4);
        assert!((ry - 1.0).abs() < 1e-4);
    }
}
