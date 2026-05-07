//! Globe ↔ province adapter (optional coupling layer).
//!
//! Keeps `globe` independent from `province`: this file depends on both modules,
//! but neither core module depends on the other.

use crate::globe::registry::Globe;
use crate::province::registry::ProvinceRegistry;

/// Applies political colors from a province registry onto matching globe provinces.
///
/// Provinces are matched by numeric ID.
pub fn apply_political_colors(globe: &mut Globe, registry: &ProvinceRegistry) {
    for id in registry.province_ids() {
        if let (Some(snap), Some(gp)) = (registry.get_province(id), globe.get_province_mut(id)) {
            gp.base_color = snap.style.political_color;
        }
    }
}

/// Applies fog visibility from province registry to one globe viewer mask.
///
/// Policy:
/// - `visibility_state > 0` => visible,
/// - otherwise hidden.
pub fn apply_visibility_to_viewer(
    globe: &mut Globe,
    registry: &ProvinceRegistry,
    viewer: &str,
) {
    for id in registry.province_ids() {
        if let Some(snap) = registry.get_province(id) {
            if snap.style.visibility_state > 0 {
                globe.fog.reveal(viewer, id);
            } else {
                globe.fog.hide(viewer, id);
            }
        }
    }
}
