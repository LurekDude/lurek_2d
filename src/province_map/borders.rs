//! Border segment extraction for province rendering.
//!
//! Converts adjacency edge border pixel coordinates into ordered polylines
//! that can be rendered as province borders. Tag-based filtering allows
//! extracting specific border types (e.g. rivers, walls).

use std::collections::HashSet;

use super::core::ProvinceMap;

/// Visual style for a border line. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `width` — `f32`.
/// - `color` — `[f32; 4]`.
/// - `dashed` — `bool`.
#[derive(Debug, Clone)]
pub struct BorderStyle {
    /// Line width in pixels.
    pub width: f32,
    /// RGBA colour for the border line.
    pub color: [f32; 4],
    /// Whether the line should be drawn dashed.
    pub dashed: bool,
}

impl Default for BorderStyle {
    fn default() -> Self {
        Self {
            width: 1.0,
            color: [0.0, 0.0, 0.0, 1.0],
            dashed: false,
        }
    }
}

/// A border segment as a list of pixel coordinates forming a polyline.
///
/// # Fields
/// - `province_a` — `u32`.
/// - `province_b` — `u32`.
/// - `points` — `Vec<(f32`.
/// - `tags` — `HashSet<String>`.
#[derive(Debug, Clone)]
pub struct BorderSegment {
    /// ID of the first province (smaller).
    pub province_a: u32,
    /// ID of the second province (larger).
    pub province_b: u32,
    /// Ordered polyline points forming the border.
    pub points: Vec<(f32, f32)>,
    /// Tags inherited from the adjacency edge (e.g. "river", "wall").
    pub tags: HashSet<String>,
}

/// Convert all adjacency edge border segments into ordered polylines.
///
/// Each adjacency edge with border pixel data produces one [`BorderSegment`].
///
/// # Parameters
/// - `ap` — `&ProvinceMap`.
///
/// # Returns
/// `Vec<BorderSegment>`.
pub fn extract_all_borders(map: &ProvinceMap) -> Vec<BorderSegment> {
    let ids = map.province_ids();
    let mut segments = Vec::new();
    let mut seen = std::collections::HashSet::new();

    for &id in &ids {
        for &neighbor in &map.get_neighbors(id) {
            let key = if id <= neighbor {
                (id, neighbor)
            } else {
                (neighbor, id)
            };
            if !seen.insert(key) {
                continue;
            }
            if let Some(edge) = map.get_adjacency(key.0, key.1) {
                if edge.border_segments.is_empty() {
                    continue;
                }
                let points: Vec<(f32, f32)> = edge
                    .border_segments
                    .iter()
                    .map(|&(x, y)| (x as f32, y as f32))
                    .collect();
                segments.push(BorderSegment {
                    province_a: edge.province_a,
                    province_b: edge.province_b,
                    points,
                    tags: edge.tags.clone(),
                });
            }
        }
    }

    segments
}

/// Extract only borders that have a specific tag.
///
/// Use this to get e.g. all river borders, wall borders, etc.
///
/// # Parameters
/// - `ap` — `&ProvinceMap`.
/// - `ag` — `&str`.
///
/// # Returns
/// `Vec<BorderSegment>`.
pub fn extract_borders_with_tag(map: &ProvinceMap, tag: &str) -> Vec<BorderSegment> {
    extract_all_borders(map)
        .into_iter()
        .filter(|seg| seg.tags.contains(tag))
        .collect()
}

/// Extract borders where the two provinces have different group values.
///
/// The caller supplies a function that maps province ID to an optional grouping
/// value. Borders where the two provinces have different values (or one is
/// `None`) are returned.
///
/// # Parameters
/// - `ap` — `&ProvinceMap`.
/// - `group_fn` — `F`.
///
/// # Returns
/// `Vec<BorderSegment> where     F: Fn(u32) -> Option<String>,`.
pub fn extract_borders_by_property<F>(map: &ProvinceMap, group_fn: F) -> Vec<BorderSegment>
where
    F: Fn(u32) -> Option<String>,
{
    extract_all_borders(map)
        .into_iter()
        .filter(|seg| {
            let val_a = group_fn(seg.province_a);
            let val_b = group_fn(seg.province_b);
            val_a != val_b
        })
        .collect()
}
