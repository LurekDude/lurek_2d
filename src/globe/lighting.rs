
use crate::globe::types::GlobeSpec;
use crate::math::sphere::{lat_lon_to_unit, rot_y};
use crate::math::Vec3;
/// Compute the sun direction in world space from globe rotation and time of day.
pub fn sun_direction(spec: &GlobeSpec) -> Vec3 {
    let sun_lon_deg = 180.0 - spec.time_of_day * 360.0;
    let sun_lat_deg = spec.axial_tilt_deg * (spec.time_of_day * std::f32::consts::TAU).sin();
    let base = lat_lon_to_unit(sun_lat_deg, sun_lon_deg);
    let spin = rot_y(spec.rotation_deg);
    let sun_world = spin.mul_vec(base);
    let len = sun_world.length().max(1e-12);
    Vec3::new(sun_world.x / len, sun_world.y / len, sun_world.z / len)
}
/// Compute province light intensity from the centroid and sun direction.
pub fn province_intensity(
    centroid_lat_deg: f32,
    centroid_lon_deg: f32,
    sun_dir: &Vec3,
    ambient: f32,
) -> f32 {
    let normal = lat_lon_to_unit(centroid_lat_deg, centroid_lon_deg);
    let dot = normal.x * sun_dir.x + normal.y * sun_dir.y + normal.z * sun_dir.z;
    dot.max(ambient).min(1.0)
}
/// Compute province intensities for a sequence of centroid positions.
#[allow(clippy::extra_unused_lifetimes)]
pub fn compute_intensities<'a>(
    centroids: impl Iterator<Item = (f32, f32)>,
    sun_dir: &Vec3,
    ambient: f32,
) -> Vec<f32> {
    centroids
        .map(|(lat, lon)| province_intensity(lat, lon, sun_dir, ambient))
        .collect()
}
    /// Convert sun alignment into an alpha value around the terminator band.
pub fn terminator_alpha(
    centroid_lat_deg: f32,
    centroid_lon_deg: f32,
    sun_dir: &Vec3,
    transition_deg: f32,
) -> f32 {
    let normal = lat_lon_to_unit(centroid_lat_deg, centroid_lon_deg);
    let dot = normal.x * sun_dir.x + normal.y * sun_dir.y + normal.z * sun_dir.z;
    let half = (transition_deg / 2.0).to_radians().cos();
    let t = (dot + half) / (2.0 * half);
    t.clamp(0.0, 1.0)
}
