//! Screen-to-province hit-test for the globe module.
//!
//! Given a screen coordinate `(sx, sy)`, `pick` returns the topmost visible
//! province whose projected 2D polygon contains the point.

use crate::globe::types::{GlobeSpec, ProvinceId};
use crate::globe::projection::{build_view_matrix, OrbitCamera};
use crate::globe::topology::ProvinceGraph;
use crate::math::Vec2;
use crate::math::sphere::lat_lon_to_unit;

/// Result of a successful province pick operation.
///
/// # Fields
/// - `province_id` — The ID of the province that was hit.
/// - `screen_pos` — The screen coordinate `(sx, sy)` that was tested.
/// - `centroid_screen` — Projected screen position of the province centroid.
#[derive(Debug, Clone)]
pub struct PickResult {
    /// The province that was hit.
    pub province_id: ProvinceId,
    /// The screen coordinate that was tested.
    pub screen_pos: (f32, f32),
    /// Projected centroid of the picked province.
    pub centroid_screen: Vec2,
}

/// Test whether a 2D screen point lies inside a convex (or near-convex) polygon
/// using the ray-casting algorithm.
fn point_in_polygon(pt: Vec2, verts: &[Vec2]) -> bool {
    if verts.len() < 3 {
        return false;
    }
    let mut inside = false;
    let n = verts.len();
    let mut j = n - 1;
    for i in 0..n {
        let vi = verts[i];
        let vj = verts[j];
        if ((vi.y > pt.y) != (vj.y > pt.y))
            && (pt.x < (vj.x - vi.x) * (pt.y - vi.y) / (vj.y - vi.y) + vi.x)
        {
            inside = !inside;
        }
        j = i;
    }
    inside
}

/// Pick the province at screen coordinate `(sx, sy)`.
///
/// Projects each visible province's boundary polygon and performs a 2D point-in-polygon
/// test. Returns the first match with the highest camera-space Z (frontmost province).
///
/// # Parameters
/// - `sx` — Screen X coordinate in pixels.
/// - `sy` — Screen Y coordinate in pixels.
/// - `spec` — Globe configuration.
/// - `camera` — Current orbit camera.
/// - `graph` — Province topology graph.
///
/// # Returns
/// `Option<PickResult>` — `None` if no province contains the point.
pub fn pick(
    sx: f32,
    sy: f32,
    spec: &GlobeSpec,
    camera: &OrbitCamera,
    graph: &ProvinceGraph,
) -> Option<PickResult> {
    let view = build_view_matrix(spec, camera);
    let r = spec.radius * camera.zoom;
    let cx = camera.screen_cx;
    let cy = camera.screen_cy;
    let pt = Vec2::new(sx, sy);

    let mut best: Option<(f32, PickResult)> = None;

    for province in graph.provinces.values() {
        // Cull by centroid first.
        let c_world = lat_lon_to_unit(province.centroid.0, province.centroid.1);
        let c_cam = view.mul_vec(c_world);
        if c_cam.z <= 0.0 {
            continue;
        }
        let centroid_screen = Vec2::new(cx + c_cam.x * r, cy - c_cam.y * r);

        // Project all vertices; skip if any is behind the sphere.
        let mut screen_verts = Vec::with_capacity(province.vertices.len());
        let mut all_visible = true;
        for &(lat, lon) in &province.vertices {
            let w = lat_lon_to_unit(lat, lon);
            let v = view.mul_vec(w);
            if v.z <= 0.0 {
                all_visible = false;
                break;
            }
            screen_verts.push(Vec2::new(cx + v.x * r, cy - v.y * r));
        }
        if !all_visible || screen_verts.len() < 3 {
            continue;
        }

        if point_in_polygon(pt, &screen_verts) {
            let z = c_cam.z;
            if best.as_ref().is_none_or(|(prev_z, _)| z > *prev_z) {
                best = Some((z, PickResult {
                    province_id: province.id,
                    screen_pos: (sx, sy),
                    centroid_screen,
                }));
            }
        }
    }

    best.map(|(_, result)| result)
}
