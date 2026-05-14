use crate::globe::types::{GlobeSpec, LodTier, ProjectedProvince, Province};
use crate::math::sphere::{axial_tilt_mat, lat_lon_to_unit, rot_x, rot_y, Mat3x3};
use crate::math::{Vec2, Vec3};
/// Orbit camera state used to project globe geometry into screen space.
#[derive(Debug, Clone)]
pub struct OrbitCamera {
    /// Camera latitude in degrees.
    pub lat_deg: f32,
    /// Camera longitude in degrees.
    pub lon_deg: f32,
    /// Zoom multiplier applied to projected coordinates.
    pub zoom: f32,
    /// Screen center x coordinate.
    pub screen_cx: f32,
    /// Screen center y coordinate.
    pub screen_cy: f32,
}
/// Default orbit camera pointing at the globe center with a mid-screen pivot.
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
    /// Clamp camera latitude, longitude, and zoom into the supported range.
    pub fn clamp(&mut self) {
        self.lat_deg = self.lat_deg.clamp(-89.9, 89.9);
        self.lon_deg = ((self.lon_deg + 180.0).rem_euclid(360.0)) - 180.0;
        self.zoom = self.zoom.clamp(0.1, 20.0);
    }
    /// Pan the camera by latitude and longitude deltas.
    pub fn pan(&mut self, delta_lat: f32, delta_lon: f32) {
        self.lat_deg += delta_lat;
        self.lon_deg += delta_lon;
        self.clamp();
    }
    /// Multiply zoom by a factor and clamp the result.
    pub fn zoom_by(&mut self, factor: f32) {
        self.zoom *= factor;
        self.clamp();
    }
    /// Return the current level-of-detail tier for the zoom level.
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
/// Build the view matrix from globe rotation, tilt, and orbit camera angles.
pub fn build_view_matrix(spec: &GlobeSpec, camera: &OrbitCamera) -> Mat3x3 {
    let planet_spin = rot_y(-spec.rotation_deg);
    let tilt = axial_tilt_mat(spec.axial_tilt_deg);
    let cam_lon = rot_y(-camera.lon_deg);
    let cam_lat = rot_x(camera.lat_deg);
    cam_lat.mul_mat(&cam_lon.mul_mat(&tilt.mul_mat(&planet_spin)))
}
/// Project a globe point to screen space or return None when it is behind the camera.
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
/// Project a province polygon into screen space or return None when any vertex is hidden.
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
    let c_world = lat_lon_to_unit(province.centroid.0, province.centroid.1);
    let c_cam = view.mul_vec(c_world);
    if c_cam.z <= 0.0 {
        return None;
    }
    let centroid_screen = Vec2::new(cx + c_cam.x * r, cy - c_cam.y * r);
    let mut screen_verts = Vec::with_capacity(province.vertices.len());
    for &(lat, lon) in &province.vertices {
        let w = lat_lon_to_unit(lat, lon);
        let v = view.mul_vec(w);
        if v.z <= 0.0 {
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
/// Project a globe point and return the screen position with depth or None when hidden.
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
/// Convert a screen-space drag delta into latitude and longitude pan deltas.
pub fn screen_delta_to_pan(dx: f32, dy: f32, spec: &GlobeSpec, camera: &OrbitCamera) -> (f32, f32) {
    let r = (spec.radius * camera.zoom).max(1.0);
    let deg_per_px = 180.0 / (std::f32::consts::PI * r);
    (-dy * deg_per_px * 60.0, -dx * deg_per_px * 60.0)
}
/// Normalize a vector and return zero when its length is near zero.
#[inline]
pub fn normalize_v3(v: Vec3) -> Vec3 {
    let len = v.length();
    if len < 1e-12 {
        Vec3::new(0.0, 0.0, 0.0)
    } else {
        Vec3::new(v.x / len, v.y / len, v.z / len)
    }
}
