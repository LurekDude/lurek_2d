use crate::math::mat3::Mat3;
use crate::math::vec2::Vec2;
#[derive(Debug, Clone, Copy)]
pub struct Transform {
    matrix: Mat3,
}
impl Transform {
    pub fn new() -> Self {
        Self {
            matrix: Mat3::identity(),
        }
    }
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
    pub fn translate(&mut self, dx: f32, dy: f32) -> &mut Self {
        self.matrix = self.matrix * Mat3::from_translation(Vec2::new(dx, dy));
        self
    }
    pub fn rotate(&mut self, angle: f32) -> &mut Self {
        self.matrix = self.matrix * Mat3::from_rotation(angle);
        self
    }
    pub fn scale(&mut self, sx: f32, sy: f32) -> &mut Self {
        self.matrix = self.matrix * Mat3::from_scale(Vec2::new(sx, sy));
        self
    }
    pub fn shear(&mut self, kx: f32, ky: f32) -> &mut Self {
        let shear = Mat3 {
            m: [[1.0, kx, 0.0], [ky, 1.0, 0.0], [0.0, 0.0, 1.0]],
        };
        self.matrix = self.matrix * shear;
        self
    }
    pub fn reset(&mut self) -> &mut Self {
        self.matrix = Mat3::identity();
        self
    }
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
    pub fn transform_point(&self, x: f32, y: f32) -> (f32, f32) {
        let p = self.matrix.transform_point(Vec2::new(x, y));
        (p.x, p.y)
    }
    pub fn inverse_transform_point(&self, x: f32, y: f32) -> (f32, f32) {
        let inv = self.inverse();
        let p = inv.matrix.transform_point(Vec2::new(x, y));
        (p.x, p.y)
    }
    pub fn inverse(&self) -> Self {
        Self {
            matrix: self.matrix.inverse(),
        }
    }
    pub fn matrix(&self) -> &Mat3 {
        &self.matrix
    }
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
impl Default for Transform {
    fn default() -> Self {
        Self::new()
    }
}
