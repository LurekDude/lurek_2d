use std::ops::{Add, AddAssign, Div, Mul, MulAssign, Neg, Sub, SubAssign};
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Vec2 {
    pub x: f32,
    pub y: f32,
}
impl Vec2 {
    pub const ZERO: Vec2 = Vec2 { x: 0.0, y: 0.0 };
    pub const ONE: Vec2 = Vec2 { x: 1.0, y: 1.0 };
    pub const UP: Vec2 = Vec2 { x: 0.0, y: -1.0 };
    pub const DOWN: Vec2 = Vec2 { x: 0.0, y: 1.0 };
    pub const LEFT: Vec2 = Vec2 { x: -1.0, y: 0.0 };
    pub const RIGHT: Vec2 = Vec2 { x: 1.0, y: 0.0 };
    pub fn new(x: f32, y: f32) -> Self {
        Vec2 { x, y }
    }
    pub fn zero() -> Self {
        Vec2::ZERO
    }
    pub fn splat(v: f32) -> Self {
        Vec2 { x: v, y: v }
    }
    pub fn dot(self, other: Vec2) -> f32 {
        self.x * other.x + self.y * other.y
    }
    pub fn length(self) -> f32 {
        (self.x * self.x + self.y * self.y).sqrt()
    }
    pub fn length_squared(self) -> f32 {
        self.x * self.x + self.y * self.y
    }
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
    pub fn distance(self, other: Vec2) -> f32 {
        (self - other).length()
    }
    pub fn lerp(self, other: Vec2, t: f32) -> Vec2 {
        self + (other - self) * t
    }
    pub fn angle(self) -> f32 {
        self.y.atan2(self.x)
    }
    pub fn rotate(self, angle: f32) -> Vec2 {
        let (sin, cos) = angle.sin_cos();
        Vec2 {
            x: self.x * cos - self.y * sin,
            y: self.x * sin + self.y * cos,
        }
    }
    pub fn perpendicular(self) -> Vec2 {
        Vec2 {
            x: -self.y,
            y: self.x,
        }
    }
    pub fn cross(self, other: Vec2) -> f32 {
        self.x * other.y - self.y * other.x
    }
    pub fn from_angle(radians: f32) -> Vec2 {
        let (sin, cos) = radians.sin_cos();
        Vec2 { x: cos, y: sin }
    }
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
