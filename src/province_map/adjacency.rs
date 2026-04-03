//! Adjacency detection between provinces from the pixel grid.
//!
//! Scans the province map's pixel-lookup buffer in a single O(W*H) pass,
//! checking right and bottom neighbours to discover shared borders.
//!
//! This module is part of Luna2D's `province_map` subsystem and provides the implementation
//! details for adjacency-related operations and data management.
//! Primary functions: `detect_adjacency()`, `detect_adjacency_with_tags()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::{HashMap, HashSet};

use super::core::{AdjacencyEdge, ProvinceMap};

/// Detect province adjacencies from the pixel grid using a single-pass scan.
///
/// For every pixel, the right `(x+1, y)` and bottom `(x, y+1)` neighbours are
/// checked. When two different non-zero province IDs are found, an adjacency
/// edge is recorded (or an existing one is updated with the new border pixel).
///
/// # Parameters
/// - `ap` — `&mut ProvinceMap`.
pub fn detect_adjacency(map: &mut ProvinceMap) {
    detect_adjacency_with_tags(map, &HashMap::new());
}

/// Detect province adjacencies with optional tagged-pixel detection.
///
/// Operates identically to [`detect_adjacency`], but when `tag_pixel_colors`
/// is non-empty, pixels whose province IDs match a key in the map are treated
/// as tag markers. If a tag pixel borders two distinct provinces, the
/// adjacency edge between those provinces receives the corresponding tag
/// string.
///
/// # Parameters
/// - `ap` — `&mut ProvinceMap`.
/// - `ag_pixel_colors` — `&HashMap<u32`.
pub fn detect_adjacency_with_tags(
    map: &mut ProvinceMap,
    tag_pixel_colors: &HashMap<u32, String>,
) {
    let width = map.width();
    let height = map.height();
    let lookup = map.pixel_lookup().to_vec();

    let is_tag_pixel = |id: u32| -> bool { tag_pixel_colors.contains_key(&id) };

    // Pass 1: normal adjacency — two non-tag, non-zero, distinct IDs side by side.
    for y in 0..height {
        for x in 0..width {
            let idx = (y as usize) * (width as usize) + (x as usize);
            let a = lookup[idx];

            if a == 0 || is_tag_pixel(a) {
                continue;
            }

            // Right neighbour
            if x + 1 < width {
                let b = lookup[idx + 1];
                if b != 0 && b != a && !is_tag_pixel(b) {
                    record_edge(map, a, b, x, y, None);
                }
            }

            // Bottom neighbour
            if y + 1 < height {
                let b = lookup[idx + (width as usize)];
                if b != 0 && b != a && !is_tag_pixel(b) {
                    record_edge(map, a, b, x, y, None);
                }
            }
        }
    }

    // Pass 2: tag adjacency — check pixels adjacent to tag pixels.
    if !tag_pixel_colors.is_empty() {
        for y in 0..height {
            for x in 0..width {
                let idx = (y as usize) * (width as usize) + (x as usize);
                let pixel_id = lookup[idx];
                let tag = match tag_pixel_colors.get(&pixel_id) {
                    Some(t) => t.clone(),
                    None => continue,
                };

                let mut neighbours = Vec::new();
                if x > 0 {
                    let id = lookup[idx - 1];
                    if id != 0 && !is_tag_pixel(id) && !neighbours.contains(&id) {
                        neighbours.push(id);
                    }
                }
                if x + 1 < width {
                    let id = lookup[idx + 1];
                    if id != 0 && !is_tag_pixel(id) && !neighbours.contains(&id) {
                        neighbours.push(id);
                    }
                }
                if y > 0 {
                    let id = lookup[idx - (width as usize)];
                    if id != 0 && !is_tag_pixel(id) && !neighbours.contains(&id) {
                        neighbours.push(id);
                    }
                }
                if y + 1 < height {
                    let id = lookup[idx + (width as usize)];
                    if id != 0 && !is_tag_pixel(id) && !neighbours.contains(&id) {
                        neighbours.push(id);
                    }
                }

                for i in 0..neighbours.len() {
                    for j in (i + 1)..neighbours.len() {
                        record_edge(map, neighbours[i], neighbours[j], x, y, Some(tag.clone()));
                    }
                }
            }
        }
    }

    log::info!("Detected {} adjacency edges", map.adjacency_count());
}

/// Record (or update) an adjacency edge between two provinces.
fn record_edge(map: &mut ProvinceMap, a: u32, b: u32, x: u32, y: u32, tag: Option<String>) {
    let (lo, hi) = if a <= b { (a, b) } else { (b, a) };

    if let Some(existing) = map.get_adjacency_mut(lo, hi) {
        existing.border_length += 1;
        if let Some(t) = tag {
            existing.tags.insert(t);
        }
        existing
            .border_segments
            .push((x.min(u16::MAX as u32) as u16, y.min(u16::MAX as u32) as u16));
    } else {
        let mut tags = HashSet::new();
        if let Some(t) = tag {
            tags.insert(t);
        }
        let edge = AdjacencyEdge {
            province_a: lo,
            province_b: hi,
            border_length: 1,
            border_segments: vec![(x.min(u16::MAX as u32) as u16, y.min(u16::MAX as u32) as u16)],
            tags,
        };
        map.insert_adjacency(edge);
    }
}
