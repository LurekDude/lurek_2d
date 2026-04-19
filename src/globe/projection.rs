//! Orthographic sphere projection and orbit camera for the globe module.
//!
//! Converts unit-sphere lat/lon positions to 2D screen-space coordinates using
//! a standard orthographic projection of a rotated unit sphere. No 3D pipeline —
//! only CPU math producing `Vec2` screen positions.
//!
//! Projection pipeline (per frame):
//! 1. Apply planet spin (`rotation_deg`) about Y axis.
//! 2. Apply axial tilt about X axis.
//! 3. Apply camera latitude/longitude orbit (two Y-then-X rotations).
//! 4. Scale by `radius` and map to screen with `(cx, cy)` as globe centre.
//! 5. Cull vertices with Z ≤ 0 (back of sphere).
//!
//! The resulting `Vec2` is in window pixels (top-left origin).

use crate::math::{Vec2, Vec3};
use crate::math::sphere::{lat_lon_to_unit, rot_x, rot_y, axial_tilt_mat, Mat3x3};
use crate::globe::types::{
    GlobeSpec, LodTier, ProjectedProvince, Province,
};

/// Orbit camera controlling the viewpoint onto the globe.
///
/// # Fields
/// - `lat_deg` — Camera latitude orbit `[-90, 90]`. 0 = equator.
/// - `lon_deg` — Camera longitude orbit `[-180, 180]`.
/// - `zoom` — Zoom factor (`1.0` = default). Multiplied against `GlobeSpec::radius`.
/// - `screen_cx` — Screen X of the globe centre in pixels.
/// - `screen_cy` — Screen Y of the globe centre in pixels.
#[derive(Debug, Clone)]
pub struct OrbitCamera {
    /// Camera latitude in degrees (vertical orbit).
    pub lat_deg: f32,
    /// Camera longitude in degrees (horizontal orbit).
    pub lon_deg: f32,
    /// Zoom multiplier (1.0 = default radius).
    pub zoom: f32,
    /// Screen X of the globe centre.
    pub screen_cx: f32,
    /// Screen Y of the globe centre.
    pub screen_cy: f32,
}

impl Default for OrbitCamera {
    fn default() -> Self {
        Self {
            lat_deg: 30.0,
            lon_deg: 0.0,
            zoom: 1.0,
            screen_cx: 640.0,
            screen_cy: 360.0,
        }
    }
}

impl OrbitCamera {
    /// Clamp and normalise camera angles.
    pub fn clamp(&mut self) {
        self.lat_deg = self.lat_deg.clamp(-89.9, 89.9);
        // Wrap longitude to [-180, 180].
        self.lon_deg = ((self.lon_deg + 180.0).rem_euclid(360.0)) - 180.0;
        self.zoom = self.zoom.clamp(0.1, 20.0);
    }

    /// Pan by `delta_lat_deg` and `delta_lon_deg` (unscaled).
    pub fn pan(&mut self, delta_lat: f32, delta_lon: f32) {
        self.lat_deg += delta_lat;
        self.lon_deg += delta_lon;
        self.clamp();
    }

    /// Zoom by `factor` (multiplicative).
    pub fn zoom_by(&mut self, factor: f32) {
        self.zoom *= factor;
        self.clamp();
    }

    /// Select LOD tier based on zoom level.
    pub fn lod(&self) -> LodTier {
        if self.zoom >= 4.0 {
            LodTier::Near
        } else if self.zoom >= 1.5 {
            LodTier::Mid
        } else {
            LodTier::Far
        }
    }
}

/// Build the composite rotation matrix for a frame.
///
/// Order: planet spin (Y) → axial tilt (X) → camera lon orbit (Y) → camera lat orbit (X).
pub fn build_view_matrix(spec: &GlobeSpec, camera: &OrbitCamera) -> Mat3x3 {
    let planet_spin = rot_y(-spec.rotation_deg);
    let tilt = axial_tilt_mat(spec.axial_tilt_deg);
    let cam_lon = rot_y(-camera.lon_deg);
    let cam_lat = rot_x(camera.lat_deg);
    // Combined: M = cam_lat * cam_lon * tilt * planet_spin
    cam_lat.mul_mat(&cam_lon.mul_mat(&tilt.mul_mat(&planet_spin)))
}

/// Project a single unit-sphere point through the view matrix to screen space.
///
/// Returns `None` if the point is on the back hemisphere (z ≤ 0 in camera space).
pub fn project_point(
    lat_deg: f32,
    lon_deg: f32,
    view: &Mat3x3,
    radius: f32,
    zoom: f32,
    cx: f32,
    cy: f32,
) -> Option<Vec2> {
    let world = lat_lon_to_unit(lat_deg, lon_deg);
    let cam = view.mul_vec(world);
    if cam.z <= 0.0 {
        return None;
    }
    let r = radius * zoom;
    Some(Vec2::new(cx + cam.x * r, cy - cam.y * r))
}

/// Project a province's boundary vertices. Returns `None` if the province is
/// entirely on the back hemisphere.
///
/// A province is considered visible if its centroid has `z > 0` in camera space.
/// Individual vertices may be clamped to the silhouette circle for edge-straddling
/// provinces (simplified: fully-visible or fully-culled per centroid test).
pub fn project_province(
    province: &Province,
    view: &Mat3x3,
    spec: &GlobeSpec,
    camera: &OrbitCamera,
    light_intensity: f32,
) -> Option<ProjectedProvince> {
    let r = spec.radius * camera.zoom;
    let cx = camera.screen_cx;
    let cy = camera.screen_cy;

    // Cull by centroid.
    let c_world = lat_lon_to_unit(province.centroid.0, province.centroid.1);
    let c_cam = view.mul_vec(c_world);
    if c_cam.z <= 0.0 {
        return None;
    }
    let centroid_screen = Vec2::new(cx + c_cam.x * r, cy - c_cam.y * r);

    // Project all vertices. If any vertex is behind the sphere, cull the whole province.
    let mut screen_verts = Vec::with_capacity(province.vertices.len());
    for &(lat, lon) in &province.vertices {
        let w = lat_lon_to_unit(lat, lon);
        let v = view.mul_vec(w);
        if v.z <= 0.0 {
            // Vertex behind globe — cull the entire province for simplicity.
            return None;
        }
        screen_verts.push(Vec2::new(cx + v.x * r, cy - v.y * r));
    }
    if screen_verts.is_empty() {
        return None;
    }

    Some(ProjectedProvince {
        id: province.id,
        screen_verts,
        centroid_screen,
        light_intensity,
        visible: true,
    })
}

/// Project a lat/lon point to screen and also return the camera-space Z (for picking).
pub fn project_point_with_z(
    lat_deg: f32,
    lon_deg: f32,
    view: &Mat3x3,
    spec: &GlobeSpec,
    camera: &OrbitCamera,
) -> Option<(Vec2, f32)> {
    let r = spec.radius * camera.zoom;
    let world = lat_lon_to_unit(lat_deg, lon_deg);
    let cam = view.mul_vec(world);
    if cam.z <= 0.0 {
        return None;
    }
    let screen = Vec2::new(camera.screen_cx + cam.x * r, camera.screen_cy - cam.y * r);
    Some((screen, cam.z))
}

/// Convert a screen delta `(dx, dy)` in pixels to a globe pan `(delta_lat, delta_lon)`.
///
/// Approximation: 1 pixel = `pan_sensitivity / (radius * zoom)` degrees.
pub fn screen_delta_to_pan(
    dx: f32,
    dy: f32,
    spec: &GlobeSpec,
    camera: &OrbitCamera,
) -> (f32, f32) {
    let r = (spec.radius * camera.zoom).max(1.0);
    let deg_per_px = 180.0 / (std::f32::consts::PI * r);
    // dx maps to longitude change, dy to latitude change (inverted Y).
    (-dy * deg_per_px * 60.0, -dx * deg_per_px * 60.0)
}

/// Normalize a `Vec3` (returns zero vector if near-zero length).
#[inline]
pub fn normalize_v3(v: Vec3) -> Vec3 {
    let len = v.length();
    if len < 1e-12 {
        Vec3::new(0.0, 0.0, 0.0)
    } else {
        Vec3::new(v.x / len, v.y / len, v.z / len)
    }
}
