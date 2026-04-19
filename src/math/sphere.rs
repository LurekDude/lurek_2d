//! Spherical math helpers used by `src/globe/`.
//!
//! Pure-math functions on the unit sphere â€” no rendering, no allocation, no globals.
//!
//! Conventions:
//!   - Latitude in degrees, range `[-90, 90]`. +90 = north pole, -90 = south pole.
//!   - Longitude in degrees, range `[-180, 180]`. 0 = prime meridian, +90 = east.
//!   - Unit vectors are right-handed: `+X` â†’ `(0, 0)` lat/lon, `+Y` â†’ north pole, `+Z` â†’ `(0, 90)` lat/lon.
//!
//! `Mat3x3` here is a column-major 3D rotation matrix, distinct from the 2D-affine
//! `crate::math::Mat3` which is row-major and dedicated to 2D draw transforms.

use crate::math::Vec3;

/// Column-major 3Ã—3 rotation matrix, used for camera orbit and axial tilt.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Mat3x3 {
    /// Three column vectors `[c0, c1, c2]`.
    pub cols: [[f32; 3]; 3],
}

impl Mat3x3 {
    /// 3Ã—3 identity.
    pub fn identity() -> Self {
        Self { cols: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]] }
    }

    /// Construct from three column vectors.
    pub fn from_cols(c0: [f32; 3], c1: [f32; 3], c2: [f32; 3]) -> Self {
        Self { cols: [c0, c1, c2] }
    }

    /// Apply this rotation to a `Vec3`: returns `M * v`.
    pub fn mul_vec(&self, v: Vec3) -> Vec3 {
        let c = &self.cols;
        Vec3::new(
            c[0][0] * v.x + c[1][0] * v.y + c[2][0] * v.z,
            c[0][1] * v.x + c[1][1] * v.y + c[2][1] * v.z,
            c[0][2] * v.x + c[1][2] * v.y + c[2][2] * v.z,
        )
    }

    /// Matrix product `self * other`.
    pub fn mul_mat(&self, other: &Mat3x3) -> Mat3x3 {
        let oc = &other.cols;
        let c0 = self.mul_vec(Vec3::new(oc[0][0], oc[0][1], oc[0][2]));
        let c1 = self.mul_vec(Vec3::new(oc[1][0], oc[1][1], oc[1][2]));
        let c2 = self.mul_vec(Vec3::new(oc[2][0], oc[2][1], oc[2][2]));
        Mat3x3::from_cols([c0.x, c0.y, c0.z], [c1.x, c1.y, c1.z], [c2.x, c2.y, c2.z])
    }
}

/// Convert (latitude_deg, longitude_deg) on the unit sphere to a 3D unit vector.
pub fn lat_lon_to_unit(lat_deg: f32, lon_deg: f32) -> Vec3 {
    let lat = lat_deg.clamp(-90.0, 90.0).to_radians();
    let lon = lon_deg.to_radians();
    let cos_lat = lat.cos();
    Vec3::new(cos_lat * lon.cos(), lat.sin(), cos_lat * lon.sin())
}

/// Inverse of `lat_lon_to_unit`. Returns `(lat_deg, lon_deg)`.
/// Longitude wrapped to `[-180, 180]`.
pub fn unit_to_lat_lon(v: Vec3) -> (f32, f32) {
    let len = v.length().max(1e-12);
    let n = Vec3::new(v.x / len, v.y / len, v.z / len);
    let lat = n.y.clamp(-1.0, 1.0).asin().to_degrees();
    let lon = n.z.atan2(n.x).to_degrees();
    (lat, lon)
}

/// Great-circle distance in radians between two lat/lon points on a unit sphere.
/// Uses the haversine formula for numerical stability at small distances.
pub fn great_circle_distance(lat1_deg: f32, lon1_deg: f32, lat2_deg: f32, lon2_deg: f32) -> f32 {
    let lat1 = lat1_deg.to_radians();
    let lat2 = lat2_deg.to_radians();
    let dlat = (lat2_deg - lat1_deg).to_radians();
    let dlon = (lon2_deg - lon1_deg).to_radians();
    let a = (dlat * 0.5).sin().powi(2)
        + lat1.cos() * lat2.cos() * (dlon * 0.5).sin().powi(2);
    2.0 * a.sqrt().clamp(0.0, 1.0).asin()
}

/// Sample `n` points along the great circle between two lat/lon endpoints.
/// Inclusive of both endpoints. `n` is clamped to `>= 2`.
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
            Vec3::new(p1.x * a + p2.x * b, p1.y * a + p2.y * b, p1.z * a + p2.z * b)
        };
        out.push(unit_to_lat_lon(v));
    }
    out
}

/// Rayâ€“sphere intersection. Returns the nearest non-negative `t` such that
/// `origin + t * dir` lies on the sphere of radius `radius` centred at the origin.
/// `dir` does not need to be normalised; the returned `t` is in the same units.
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

/// Rotation matrix around the X axis (axial-tilt convention). `angle_deg > 0`
/// tilts +Y toward +Z (north pole leans toward viewer at lon=90Â°).
pub fn axial_tilt_mat(angle_deg: f32) -> Mat3x3 {
    rot_x(angle_deg)
}

/// Rotation about the X axis by `angle_deg` degrees.
pub fn rot_x(angle_deg: f32) -> Mat3x3 {
    let r = angle_deg.to_radians();
    let (c, s) = (r.cos(), r.sin());
    Mat3x3::from_cols([1.0, 0.0, 0.0], [0.0, c, s], [0.0, -s, c])
}

/// Rotation about the Y axis (longitude / orbit yaw) by `angle_deg` degrees.
pub fn rot_y(angle_deg: f32) -> Mat3x3 {
    let r = angle_deg.to_radians();
    let (c, s) = (r.cos(), r.sin());
    Mat3x3::from_cols([c, 0.0, -s], [0.0, 1.0, 0.0], [s, 0.0, c])
}

/// Rotation about the Z axis by `angle_deg` degrees.
pub fn rot_z(angle_deg: f32) -> Mat3x3 {
    let r = angle_deg.to_radians();
    let (c, s) = (r.cos(), r.sin());
    Mat3x3::from_cols([c, s, 0.0], [-s, c, 0.0], [0.0, 0.0, 1.0])
}
