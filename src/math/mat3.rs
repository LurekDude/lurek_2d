use super::vec2::Vec2;
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Mat3 {
    pub m: [[f32; 3]; 3],
}
impl Mat3 {
    pub fn identity() -> Self {
        Mat3 {
            m: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
        }
    }
    pub fn from_row_major(data: &[f32; 9]) -> Self {
        Mat3 {
            m: [
                [data[0], data[1], data[2]],
                [data[3], data[4], data[5]],
                [data[6], data[7], data[8]],
            ],
        }
    }
    pub fn from_translation(t: Vec2) -> Self {
        Mat3 {
            m: [[1.0, 0.0, t.x], [0.0, 1.0, t.y], [0.0, 0.0, 1.0]],
        }
    }
    pub fn from_rotation(angle: f32) -> Self {
        let c = angle.cos();
        let s = angle.sin();
        Mat3 {
            m: [[c, -s, 0.0], [s, c, 0.0], [0.0, 0.0, 1.0]],
        }
    }
    pub fn from_shear(kx: f32, ky: f32) -> Self {
        Mat3 {
            m: [[1.0, ky, 0.0], [kx, 1.0, 0.0], [0.0, 0.0, 1.0]],
        }
    }
    pub fn from_scale(scale: Vec2) -> Self {
        Mat3 {
            m: [[scale.x, 0.0, 0.0], [0.0, scale.y, 0.0], [0.0, 0.0, 1.0]],
        }
    }
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
