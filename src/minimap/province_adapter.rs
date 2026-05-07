//! Minimap ↔ province adapter (optional coupling layer).
//!
//! Keeps `minimap` independent from `province`: this file is the only place
//! where both data models are translated.

use crate::minimap::minimap::Minimap;
use crate::minimap::types::FogLevel;
use crate::province::registry::ProvinceRegistry;

/// Projects province terrain IDs into minimap terrain grid.
///
/// The projection is direct map-space sampling with clamped overlap.
pub fn apply_terrain(minimap: &mut Minimap, registry: &ProvinceRegistry) {
    let w = minimap.grid_width().min(registry.width());
    let h = minimap.grid_height().min(registry.height());
    for y in 0..h {
        for x in 0..w {
            let pid = registry.get_at(x, y);
            if pid == 0 {
                continue;
            }
            if let Some(snap) = registry.get_province(pid) {
                minimap.set_terrain(x, y, snap.style.terrain_type);
            }
        }
    }
}

/// Projects province visibility state into minimap fog cells.
///
/// Mapping:
/// - visibility = 0 => hidden,
/// - visibility in [1, 127] => explored,
/// - visibility in [128, 255] => visible.
pub fn apply_visibility(minimap: &mut Minimap, registry: &ProvinceRegistry) {
    let w = minimap.grid_width().min(registry.width());
    let h = minimap.grid_height().min(registry.height());
    for y in 0..h {
        for x in 0..w {
            let pid = registry.get_at(x, y);
            if pid == 0 {
                continue;
            }
            if let Some(snap) = registry.get_province(pid) {
                let level = if snap.style.visibility_state == 0 {
                    FogLevel::Hidden
                } else if snap.style.visibility_state < 128 {
                    FogLevel::Explored
                } else {
                    FogLevel::Visible
                };
                minimap.set_fog_level(x, y, level);
            }
        }
    }
}

/// Pushes terrain-type color palette inferred from province styles.
pub fn apply_terrain_palette(minimap: &mut Minimap, registry: &ProvinceRegistry) {
    for id in registry.province_ids() {
        if let Some(snap) = registry.get_province(id) {
            minimap.set_terrain_color(snap.style.terrain_type, snap.style.political_color);
        }
    }
}
