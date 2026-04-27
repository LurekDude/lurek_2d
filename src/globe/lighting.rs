//! Day/night lighting for the globe module.
//!
//! Computes a per-province light intensity based on:
//! - Sun direction derived from `time_of_day` and `axial_tilt_deg`.
//! - Per-province centroid cosine with the sun direction.
//!
//! Lighting is constant per province (no per-vertex gradient), which is both
//! visually appropriate for a geoscape-style map and efficient for 8k provinces.

use crate::globe::types::GlobeSpec;
use crate::math::sphere::{lat_lon_to_unit, rot_y};
use crate::math::Vec3;

/// Compute the sun direction as a world-space unit vector.
///
/// At `time_of_day = 0.0` the sun is at longitude 0°. As `time_of_day` increases,
/// the sun travels eastward. Axial tilt rotates the sun above/below the equatorial plane.
pub fn sun_direction(spec: &GlobeSpec) -> Vec3 {
    // Sun longitude: at 0.0 it is at lon=180 (noon at prime meridian), advances east.
    let sun_lon_deg = 180.0 - spec.time_of_day * 360.0;
    // Sun latitude offset from axial tilt: approximate sun declination.
    let sun_lat_deg = spec.axial_tilt_deg * (spec.time_of_day * std::f32::consts::TAU).sin();

    // Sun in world space before planet spin.
    let base = lat_lon_to_unit(sun_lat_deg, sun_lon_deg);

    // Apply planet spin offset.
    let spin = rot_y(spec.rotation_deg);
    let sun_world = spin.mul_vec(base);

    // Normalise (should already be unit, but guard against floating point).
    let len = sun_world.length().max(1e-12);
    Vec3::new(sun_world.x / len, sun_world.y / len, sun_world.z / len)
}

/// Compute the lighting intensity for a province centroid.
///
/// Returns a value in `[ambient, 1.0]` where:
/// - `ambient` is the `GlobeSpec::ambient` floor (night-side minimum brightness).
/// - `1.0` is full daylight.
///
/// Formula: `intensity = max(ambient, dot(province_normal, sun_dir))`
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

/// Batch-compute light intensities for all provinces.
///
/// Accepts an iterator of `(lat_deg, lon_deg)` centroid pairs and returns a `Vec<f32>`
/// of intensities in the same order.
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

/// Compute a day/night terminator alpha for a province for a soft edge.
///
/// Returns `0.0` on the night side, `1.0` on the full day side, with a smooth
/// transition zone of `±transition_deg` around the terminator.
pub fn terminator_alpha(
    centroid_lat_deg: f32,
    centroid_lon_deg: f32,
    sun_dir: &Vec3,
    transition_deg: f32,
) -> f32 {
    let normal = lat_lon_to_unit(centroid_lat_deg, centroid_lon_deg);
    let dot = normal.x * sun_dir.x + normal.y * sun_dir.y + normal.z * sun_dir.z;
    // Map from cos(90° ± half_zone) to [0, 1].
    let half = (transition_deg / 2.0).to_radians().cos();
    let t = (dot + half) / (2.0 * half);
    t.clamp(0.0, 1.0)
}
