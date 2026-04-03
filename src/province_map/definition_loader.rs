//! Province definition loader — build a [`ProvinceMap`] from structured data.
//!
//! Instead of parsing a colour-coded PNG, this module creates a province map
//! from a list of [`ProvinceDefinition`] records (e.g. loaded from TOML or a
//! Lua table). Useful for games that define provinces declaratively.

use crate::math::{Rect, Vec2};

use super::core::{AdjacencyEdge, ProvinceMap, Province};

/// A single province definition with metadata and neighbour list.
///
/// # Fields
/// - `id` — `u32`.
/// - `color` — `[u8; 3]`.
/// - `center` — `(f32`.
/// - `neighbors` — `Vec<u32>`.
/// - `name` — `Option<String>`.
#[derive(Debug, Clone)]
pub struct ProvinceDefinition {
    /// Unique province ID (must be non-zero).
    pub id: u32,
    /// Display colour in RGB.
    pub color: [u8; 3],
    /// Province center position (x, y) in map coordinates.
    pub center: (f32, f32),
    /// List of neighbour province IDs.
    pub neighbors: Vec<u32>,
    /// Optional province name.
    pub name: Option<String>,
}

/// Build a [`ProvinceMap`] from a list of province definitions.
///
/// Creates a logical-only province map (no pixel data) from structured
/// definitions. The pixel grid is left empty — this map is meant for
/// graph-based gameplay, not pixel-level rendering.
///
/// Adjacency edges are created from the `neighbors` lists. Each pair is
/// stored once with `border_length = 0` (no pixel data).
///
/// # Parameters
/// - `defs` — `&[ProvinceDefinition]`.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ProvinceMap`.
pub fn load_from_definitions(
    defs: &[ProvinceDefinition],
    width: u32,
    height: u32,
) -> ProvinceMap {
    let mut map = ProvinceMap::new(width, height);

    for def in defs {
        if def.id == 0 {
            continue; // Skip invalid zero IDs
        }

        let mut province = Province::new(def.id, def.color);
        province.center = Vec2::new(def.center.0, def.center.1);
        province.centroid = province.center;
        province.area = 1; // Logical province, no pixel area
        province.bounding_box = Rect::new(def.center.0, def.center.1, 0.0, 0.0);

        if let Some(ref name) = def.name {
            province.name = Some(name.clone());
        }

        map.insert_province(province);
    }

    // Build adjacency from neighbour lists
    let mut seen = std::collections::HashSet::new();
    for def in defs {
        for &neighbor_id in &def.neighbors {
            let (lo, hi) = if def.id <= neighbor_id {
                (def.id, neighbor_id)
            } else {
                (neighbor_id, def.id)
            };

            if lo == 0 || !seen.insert((lo, hi)) {
                continue;
            }

            // Only add if both provinces exist
            if map.get_province(lo).is_some() && map.get_province(hi).is_some() {
                let edge = AdjacencyEdge {
                    province_a: lo,
                    province_b: hi,
                    border_length: 0,
                    border_segments: Vec::new(),
                    tags: std::collections::HashSet::new(),
                };
                map.insert_adjacency(edge);
            }
        }
    }

    log::info!(
        "Loaded {} provinces from definitions ({} adjacencies)",
        map.province_count(),
        map.adjacency_count()
    );

    map
}
