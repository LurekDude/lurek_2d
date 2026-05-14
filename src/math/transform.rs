use crate::math::mat3::Mat3;
use crate::math::vec2::Vec2;

/// Accumulated 2D affine transform stored as a Mat3; mutated in-place by transform operations.
#[derive(Debug, Clone, Copy)]
pub struct Transform {
    /// The underlying 3×3 affine matrix.
    matrix: Mat3,
}

impl Transform {
    /// Return an identity transform.
    pub fn new() -> Self {
        Self {
            matrix: Mat3::identity(),
        }
    }

    /// Construct a transform from position, rotation, scale, origin offset, and shear components.
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

    /// Post-multiply a translation by `(dx, dy)` and return `&mut self` for chaining.
    pub fn translate(&mut self, dx: f32, dy: f32) -> &mut Self {
        self.matrix = self.matrix * Mat3::from_translation(Vec2::new(dx, dy));
        self
    }

    /// Post-multiply a rotation by `angle` radians and return `&mut self` for chaining.
    pub fn rotate(&mut self, angle: f32) -> &mut Self {
        self.matrix = self.matrix * Mat3::from_rotation(angle);
        self
    }

    /// Post-multiply a non-uniform scale by `(sx, sy)` and return `&mut self` for chaining.
    pub fn scale(&mut self, sx: f32, sy: f32) -> &mut Self {
        self.matrix = self.matrix * Mat3::from_scale(Vec2::new(sx, sy));
        self
    }

    /// Post-multiply a shear by `(kx, ky)` and return `&mut self` for chaining.
    pub fn shear(&mut self, kx: f32, ky: f32) -> &mut Self {
        let shear = Mat3 {
            m: [[1.0, kx, 0.0], [ky, 1.0, 0.0], [0.0, 0.0, 1.0]],
        };
        self.matrix = self.matrix * shear;
        self
    }

    /// Reset to identity and return `&mut self` for chaining.
    pub fn reset(&mut self) -> &mut Self {
        self.matrix = Mat3::identity();
        self
    }

    /// Replace this transform with a fresh one built from the given SRT+origin+shear components.
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

    /// Apply this transform to `(x, y)` and return the resulting point.
    pub fn transform_point(&self, x: f32, y: f32) -> (f32, f32) {
        let p = self.matrix.transform_point(Vec2::new(x, y));
        (p.x, p.y)
    }

    /// Apply the inverse of this transform to `(x, y)` and return the resulting point.
    pub fn inverse_transform_point(&self, x: f32, y: f32) -> (f32, f32) {
        let inv = self.inverse();
        let p = inv.matrix.transform_point(Vec2::new(x, y));
        (p.x, p.y)
    }

    /// Return a new transform that is the matrix inverse of this one.
    pub fn inverse(&self) -> Self {
        Self {
            matrix: self.matrix.inverse(),
        }
    }

    /// Return a reference to the underlying Mat3.
    pub fn matrix(&self) -> &Mat3 {
        &self.matrix
    }

    /// Decompose into `(tx, ty, rotation_rad, sx, sy)`; shear is not separated.
    pub fn decompose(&self) -> (f32, f32, f32, f32, f32) {
        let m = &self.matrix.m;
        let tx = m[0][2];
        let ty = m[1][2];
        let sx = (m[0][0] * m[0][0] + m[1][0] * m[1][0]).sqrt();
        let sy = (m[0][1] * m[0][1] + m[1][1] * m[1][1]).sqrt();
        let angle = m[1][0].atan2(m[0][0]);
        (tx, ty, angle, sx, sy)
    }
}

/// Default transform is identity.
impl Default for Transform {
    fn default() -> Self {
        Self::new()
    }
}
