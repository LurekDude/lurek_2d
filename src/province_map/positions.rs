//! Auto-position calculation for province centers.
//!
//! Provides an algorithm to find a good interior position within a province
//! for use as its center point (e.g. capital placement, label anchor).
//!
//! This module is part of Luna2D's `province_map` subsystem and provides the implementation
//! details for positions-related operations and data management.
//! Primary functions: `calculate_capital()`, `calculate_all_positions()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::math::Vec2;

use super::core::ProvinceMap;

/// Find a good interior position for a province center.
///
/// Uses an approximate distance-from-edge approach: samples points on a grid
/// within the province bounding box, keeps only those inside the province (via
/// `pixel_lookup`), and picks the one farthest from any edge pixel.
/// Falls back to the province centroid if no better candidate is found.
///
/// # Parameters
/// - `ap` — `&ProvinceMap`.
/// - `province_id` — `u32`.
///
/// # Returns
/// `Vec2`.
pub fn calculate_capital(map: &ProvinceMap, province_id: u32) -> Vec2 {
    let province = match map.get_province(province_id) {
        Some(p) => p,
        None => return Vec2::ZERO,
    };

    let bb = &province.bounding_box;
    let cx = province.centroid.x as u32;
    let cy = province.centroid.y as u32;

    let step = ((bb.width.max(bb.height)) / 20.0).max(1.0) as u32;
    let x0 = bb.x as u32;
    let y0 = bb.y as u32;
    let x1 = (bb.x + bb.width) as u32;
    let y1 = (bb.y + bb.height) as u32;

    // Check if the centroid is inside the province
    if map.get_province_at(cx, cy) == Some(province_id) {
        let centroid_dist = min_edge_distance(map, province_id, cx, cy);
        let mut best_pos = province.centroid;
        let mut best_dist = centroid_dist;

        // Sample a grid within the bounding box
        let mut sy = y0;
        while sy <= y1 {
            let mut sx = x0;
            while sx <= x1 {
                if map.get_province_at(sx, sy) == Some(province_id) {
                    let d = min_edge_distance(map, province_id, sx, sy);
                    if d > best_dist {
                        best_dist = d;
                        best_pos = Vec2::new(sx as f32, sy as f32);
                    }
                }
                sx += step;
            }
            sy += step;
        }

        return best_pos;
    }

    // Centroid is outside the province (concave shape) — full grid scan
    let mut best_pos = province.centroid;
    let mut best_dist: u32 = 0;

    let mut sy = y0;
    while sy <= y1 {
        let mut sx = x0;
        while sx <= x1 {
            if map.get_province_at(sx, sy) == Some(province_id) {
                let d = min_edge_distance(map, province_id, sx, sy);
                if d > best_dist {
                    best_dist = d;
                    best_pos = Vec2::new(sx as f32, sy as f32);
                }
            }
            sx += step;
        }
        sy += step;
    }

    best_pos
}

/// Compute and set the `center` field for all provinces.
///
/// Finds the best interior point for each province using [`calculate_capital`]
/// and writes it to `province.center`.
///
/// # Parameters
/// - `ap` — `&mut ProvinceMap`.
pub fn calculate_all_positions(map: &mut ProvinceMap) {
    let ids = map.province_ids();
    let primaries: Vec<(u32, Vec2)> = ids
        .iter()
        .map(|&id| (id, calculate_capital(map, id)))
        .collect();

    for (id, pos) in primaries {
        if let Some(p) = map.get_province_mut(id) {
            p.center = pos;
        }
    }

    log::info!("Calculated center positions for {} provinces", ids.len());
}

/// Compute the minimum distance from `(px, py)` to a non-province edge pixel.
///
/// Checks cardinal neighbours in expanding layers. Returns the layer count at
/// which a different province (or map edge) is first encountered.
fn min_edge_distance(map: &ProvinceMap, province_id: u32, px: u32, py: u32) -> u32 {
    let max_radius = 50u32;
    for r in 1..=max_radius {
        let checks: [(i64, i64); 4] = [
            (px as i64 - r as i64, py as i64),
            (px as i64 + r as i64, py as i64),
            (px as i64, py as i64 - r as i64),
            (px as i64, py as i64 + r as i64),
        ];

        for (cx, cy) in checks {
            if cx < 0 || cy < 0 || cx >= map.width() as i64 || cy >= map.height() as i64 {
                return r;
            }
            if map.get_province_at(cx as u32, cy as u32) != Some(province_id) {
                return r;
            }
        }
    }
    max_radius
}
