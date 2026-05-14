//! Globe hit testing against projected provinces.
//!
//! Owns screen-space point-in-polygon checks and best-hit selection.
//! Projection and graph traversal stay in sibling modules.

use crate::globe::projection::{build_view_matrix, OrbitCamera};
use crate::globe::topology::ProvinceGraph;
use crate::globe::types::{GlobeSpec, ProvinceId};
use crate::math::sphere::lat_lon_to_unit;
use crate::math::Vec2;
/// Province selection result returned by globe picking.
#[derive(Debug, Clone)]
pub struct PickResult {
    /// Picked province id.
    pub province_id: ProvinceId,
    /// Screen-space pointer position used for the hit test.
    pub screen_pos: (f32, f32),
    /// Projected screen-space centroid for the picked province.
    pub centroid_screen: Vec2,
}
/// Return true when a point lies inside a polygon.
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
/// Pick the topmost province under a screen-space point or return None when no province matches.
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
        let c_world = lat_lon_to_unit(province.centroid.0, province.centroid.1);
        let c_cam = view.mul_vec(c_world);
        if c_cam.z <= 0.0 {
            continue;
        }
        let centroid_screen = Vec2::new(cx + c_cam.x * r, cy - c_cam.y * r);
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
                best = Some((
                    z,
                    PickResult {
                        province_id: province.id,
                        screen_pos: (sx, sy),
                        centroid_screen,
                    },
                ));
            }
        }
    }
    best.map(|(_, result)| result)
}
