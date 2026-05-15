//! - Sphere-surface coordinate helpers: latitude/longitude ↔ unit-sphere Vec3 conversion.
//! - Great-circle distance (Haversine) and arc interpolation between two geo-points.
//! - Ray-sphere intersection returning the nearest positive hit distance.
//! - Column-major 3×3 rotation matrices (axis-aligned X/Y/Z plus axial-tilt convenience).
//! - Matrix-vector and matrix-matrix multiplication for globe-view transforms.

use crate::math::Vec3;

/// Column-major 3×3 float matrix used for sphere rotation in globe view transforms.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Mat3x3 {
    /// Three column vectors stored as `cols[column][row]`.
    pub cols: [[f32; 3]; 3],
}
/// Core rotation and projection operations for `Mat3x3`.
impl Mat3x3 {
    /// Return the identity matrix. This function is part of the public API.
    pub fn identity() -> Self {
        Self {
            cols: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
        }
    }
    /// Construct a matrix from three column arrays.
    pub fn from_cols(c0: [f32; 3], c1: [f32; 3], c2: [f32; 3]) -> Self {
        Self { cols: [c0, c1, c2] }
    }
    /// Multiply this matrix by column vector `v`.
    pub fn mul_vec(&self, v: Vec3) -> Vec3 {
        let c = &self.cols;
        Vec3::new(
            c[0][0] * v.x + c[1][0] * v.y + c[2][0] * v.z,
            c[0][1] * v.x + c[1][1] * v.y + c[2][1] * v.z,
            c[0][2] * v.x + c[1][2] * v.y + c[2][2] * v.z,
        )
    }
    /// Return the product of this matrix and `other`.
    pub fn mul_mat(&self, other: &Mat3x3) -> Mat3x3 {
        let oc = &other.cols;
        let c0 = self.mul_vec(Vec3::new(oc[0][0], oc[0][1], oc[0][2]));
        let c1 = self.mul_vec(Vec3::new(oc[1][0], oc[1][1], oc[1][2]));
        let c2 = self.mul_vec(Vec3::new(oc[2][0], oc[2][1], oc[2][2]));
        Mat3x3::from_cols([c0.x, c0.y, c0.z], [c1.x, c1.y, c1.z], [c2.x, c2.y, c2.z])
    }
}

/// Convert latitude/longitude in degrees to a unit sphere Vec3 (Y-up, Z-east convention).
pub fn lat_lon_to_unit(lat_deg: f32, lon_deg: f32) -> Vec3 {
    let lat = lat_deg.clamp(-90.0, 90.0).to_radians();
    let lon = lon_deg.to_radians();
    let cos_lat = lat.cos();
    Vec3::new(cos_lat * lon.cos(), lat.sin(), cos_lat * lon.sin())
}

/// Convert a unit Vec3 back to latitude/longitude in degrees; normalises the input.
pub fn unit_to_lat_lon(v: Vec3) -> (f32, f32) {
    let len = v.length().max(1e-12);
    let n = Vec3::new(v.x / len, v.y / len, v.z / len);
    let lat = n.y.clamp(-1.0, 1.0).asin().to_degrees();
    let lon = n.z.atan2(n.x).to_degrees();
    (lat, lon)
}

/// Return the great-circle angular distance in radians between two lat/lon points via Haversine.
pub fn great_circle_distance(lat1_deg: f32, lon1_deg: f32, lat2_deg: f32, lon2_deg: f32) -> f32 {
    let lat1 = lat1_deg.to_radians();
    let lat2 = lat2_deg.to_radians();
    let dlat = (lat2_deg - lat1_deg).to_radians();
    let dlon = (lon2_deg - lon1_deg).to_radians();
    let a = (dlat * 0.5).sin().powi(2) + lat1.cos() * lat2.cos() * (dlon * 0.5).sin().powi(2);
    2.0 * a.sqrt().clamp(0.0, 1.0).asin()
}

/// Return `n` evenly spaced lat/lon points along the great-circle arc from point 1 to point 2.
pub fn great_circle_path(
    lat1_deg: f32,
    lon1_deg: f32,
    lat2_deg: f32,
    lon2_deg: f32,
    n: u32,
) -> Vec<(f32, f32)> {
    let n = n.max(2);
    let p1 = lat_lon_to_unit(lat1_deg, lon1_deg);
    let p2 = lat_lon_to_unit(lat2_deg, lon2_deg);
    let dot = p1.dot(p2).clamp(-1.0, 1.0);
    let omega = dot.acos();
    let sin_omega = omega.sin();
    let mut out = Vec::with_capacity(n as usize);
    for i in 0..n {
        let t = i as f32 / (n - 1) as f32;
        let v = if sin_omega.abs() < 1e-6 {
            let x = p1.x * (1.0 - t) + p2.x * t;
            let y = p1.y * (1.0 - t) + p2.y * t;
            let z = p1.z * (1.0 - t) + p2.z * t;
            let v = Vec3::new(x, y, z);
            let l = v.length().max(1e-12);
            Vec3::new(v.x / l, v.y / l, v.z / l)
        } else {
            let a = ((1.0 - t) * omega).sin() / sin_omega;
            let b = (t * omega).sin() / sin_omega;
            Vec3::new(
                p1.x * a + p2.x * b,
                p1.y * a + p2.y * b,
                p1.z * a + p2.z * b,
            )
        };
        out.push(unit_to_lat_lon(v));
    }
    out
}

/// Return the smallest positive intersection `t` for a ray from `origin` in `dir` with sphere of `radius`.
pub fn ray_sphere_intersect(origin: Vec3, dir: Vec3, radius: f32) -> Option<f32> {
    let a = dir.dot(dir);
    if a <= 1e-20 {
        return None;
    }
    let b = 2.0 * origin.dot(dir);
    let c = origin.dot(origin) - radius * radius;
    let disc = b * b - 4.0 * a * c;
    if disc < 0.0 {
        return None;
    }
    let sd = disc.sqrt();
    let t0 = (-b - sd) / (2.0 * a);
    let t1 = (-b + sd) / (2.0 * a);
    if t0 >= 0.0 {
        Some(t0)
    } else if t1 >= 0.0 {
        Some(t1)
    } else {
        None
    }
}

/// Return a rotation matrix representing axial tilt (alias for `rot_x`).
pub fn axial_tilt_mat(angle_deg: f32) -> Mat3x3 {
    rot_x(angle_deg)
}

/// Return a rotation matrix for `angle_deg` degrees around the X axis.
pub fn rot_x(angle_deg: f32) -> Mat3x3 {
    let r = angle_deg.to_radians();
    let (c, s) = (r.cos(), r.sin());
    Mat3x3::from_cols([1.0, 0.0, 0.0], [0.0, c, s], [0.0, -s, c])
}

/// Return a rotation matrix for `angle_deg` degrees around the Y axis.
pub fn rot_y(angle_deg: f32) -> Mat3x3 {
    let r = angle_deg.to_radians();
    let (c, s) = (r.cos(), r.sin());
    Mat3x3::from_cols([c, 0.0, -s], [0.0, 1.0, 0.0], [s, 0.0, c])
}

/// Return a rotation matrix for `angle_deg` degrees around the Z axis.
pub fn rot_z(angle_deg: f32) -> Mat3x3 {
    let r = angle_deg.to_radians();
    let (c, s) = (r.cos(), r.sin());
    Mat3x3::from_cols([c, s, 0.0], [-s, c, 0.0], [0.0, 0.0, 1.0])
}
