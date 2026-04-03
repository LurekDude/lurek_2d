//! Spatial hash for efficient broad-phase AABB collision queries.
//!
//! Items are keyed by a string ID and stored with axis-aligned bounding boxes.
//! The grid partitions space into fixed-size cells for O(1) bucket lookup.

use std::collections::{HashMap, HashSet};

/// Entry in the spatial hash. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `id` — `String`.
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `w` — `f32`.
/// - `h` — `f32`.
#[derive(Debug, Clone)]
pub struct SpatialItem {
    /// Unique identifier.
    pub id: String,
    /// Left edge of the bounding box.
    pub x: f32,
    /// Top edge of the bounding box.
    pub y: f32,
    /// Width of the bounding box.
    pub w: f32,
    /// Height of the bounding box.
    pub h: f32,
}

/// Spatial hash for AABB queries. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Divides the 2D plane into a uniform grid of square cells. Each item is
/// inserted into every cell its bounding box overlaps, enabling fast
/// broad-phase collision queries.
///
/// # Fields
/// - `cell_size` — `f32`.
/// - `items` — `HashMap<String`.
/// - `buckets` — `HashMap<(i32`.
pub struct SpatialHash {
    cell_size: f32,
    items: HashMap<String, SpatialItem>,
    buckets: HashMap<(i32, i32), HashSet<String>>,
}

impl SpatialHash {
    /// Creates an empty spatial hash with the given cell size.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// # Parameters
    /// - `cell_size` — Side length of each grid cell. Larger values mean fewer
    ///   cells but more items per cell.
    pub fn new(cell_size: f32) -> Self {
        Self {
            cell_size,
            items: HashMap::new(),
            buckets: HashMap::new(),
        }
    }

    /// Returns the cell size. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f32`.
    pub fn cell_size(&self) -> f32 {
        self.cell_size
    }

    /// Returns the number of items in the hash.
    ///
    /// # Returns
    /// `usize`.
    pub fn item_count(&self) -> usize {
        self.items.len()
    }

    /// Converts a world coordinate to a cell coordinate.
    #[inline]
    fn cell(&self, v: f32) -> i32 {
        (v / self.cell_size).floor() as i32
    }

    /// Returns the range of cell coordinates covered by an AABB.
    fn cell_range(&self, x: f32, y: f32, w: f32, h: f32) -> (i32, i32, i32, i32) {
        (
            self.cell(x),
            self.cell(y),
            self.cell(x + w),
            self.cell(y + h),
        )
    }

    /// Inserts an item with the given AABB. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id` — `String`.
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `w` — `f32`.
    /// - `h` — `f32`.
    ///
    /// If an item with the same `id` already exists it is replaced.
    pub fn insert(&mut self, id: String, x: f32, y: f32, w: f32, h: f32) {
        // Remove old entry if present
        self.remove_internal(&id);

        let (cx0, cy0, cx1, cy1) = self.cell_range(x, y, w, h);
        for cy in cy0..=cy1 {
            for cx in cx0..=cx1 {
                self.buckets.entry((cx, cy)).or_default().insert(id.clone());
            }
        }
        self.items
            .insert(id.clone(), SpatialItem { id, x, y, w, h });
    }

    /// Removes an item by its ID. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    pub fn remove(&mut self, id: &str) {
        self.remove_internal(id);
        self.items.remove(id);
    }

    /// Internal helper — removes from buckets only (does not touch `items`).
    fn remove_internal(&mut self, id: &str) {
        if let Some(item) = self.items.get(id) {
            let (cx0, cy0, cx1, cy1) = self.cell_range(item.x, item.y, item.w, item.h);
            for cy in cy0..=cy1 {
                for cx in cx0..=cx1 {
                    if let Some(bucket) = self.buckets.get_mut(&(cx, cy)) {
                        bucket.remove(id);
                        // Leave empty buckets — they are harmless and cheaper than cleaning up
                    }
                }
            }
        }
    }

    /// Updates an existing item's AABB. Equivalent to remove + insert.
    ///
    /// # Parameters
    /// - `id` — `String`.
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `w` — `f32`.
    /// - `h` — `f32`.
    pub fn update(&mut self, id: String, x: f32, y: f32, w: f32, h: f32) {
        self.insert(id, x, y, w, h);
    }

    /// Removes all items and clears all buckets.
    pub fn clear(&mut self) {
        self.items.clear();
        self.buckets.clear();
    }

    /// Returns the IDs of all items whose AABBs overlap the query rectangle.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `w` — `f32`.
    /// - `h` — `f32`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn query_rect(&self, x: f32, y: f32, w: f32, h: f32) -> Vec<String> {
        let (cx0, cy0, cx1, cy1) = self.cell_range(x, y, w, h);
        let mut seen = HashSet::new();
        let mut result = Vec::new();

        for cy in cy0..=cy1 {
            for cx in cx0..=cx1 {
                if let Some(bucket) = self.buckets.get(&(cx, cy)) {
                    for id in bucket {
                        if seen.contains(id) {
                            continue;
                        }
                        if let Some(item) = self.items.get(id) {
                            // Actual AABB overlap test
                            if item.x < x + w
                                && item.x + item.w > x
                                && item.y < y + h
                                && item.y + item.h > y
                            {
                                seen.insert(id.clone());
                                result.push(id.clone());
                            }
                        }
                    }
                }
            }
        }
        result
    }

    /// Returns the IDs of all items whose AABBs overlap the query circle.
    ///
    /// # Parameters
    /// - `cx` — `f32`.
    /// - `cy` — `f32`.
    /// - `radius` — `f32`.
    ///
    /// # Returns
    /// `Vec<String>`.
    ///
    /// First queries the bounding rect, then filters by distance from the
    /// circle centre to the nearest point on each item's AABB.
    pub fn query_circle(&self, cx: f32, cy: f32, radius: f32) -> Vec<String> {
        // Bounding rect of the circle
        let rx = cx - radius;
        let ry = cy - radius;
        let rw = radius * 2.0;
        let rh = radius * 2.0;

        let candidates = self.query_rect(rx, ry, rw, rh);
        let r2 = radius * radius;
        candidates
            .into_iter()
            .filter(|id| {
                if let Some(item) = self.items.get(id) {
                    // Nearest point on AABB to circle centre
                    let nearest_x = cx.max(item.x).min(item.x + item.w);
                    let nearest_y = cy.max(item.y).min(item.y + item.h);
                    let dx = cx - nearest_x;
                    let dy = cy - nearest_y;
                    dx * dx + dy * dy <= r2
                } else {
                    false
                }
            })
            .collect()
    }

    /// Returns the IDs of all items whose AABBs are intersected by a line
    ///
    /// # Parameters
    /// - `x1` — `f32`.
    /// - `y1` — `f32`.
    /// - `x2` — `f32`.
    /// - `y2` — `f32`.
    ///
    /// # Returns
    /// `Vec<String>`.
    /// segment from `(x1, y1)` to `(x2, y2)`.
    ///
    /// Traverses cells along the segment and performs AABB–segment overlap
    /// tests on each candidate.
    pub fn query_segment(&self, x1: f32, y1: f32, x2: f32, y2: f32) -> Vec<String> {
        // Compute bounding rect of segment
        let min_x = x1.min(x2);
        let min_y = y1.min(y2);
        let max_x = x1.max(x2);
        let max_y = y1.max(y2);
        let (cx0, cy0, cx1, cy1) = self.cell_range(min_x, min_y, max_x - min_x, max_y - min_y);

        let mut seen = HashSet::new();
        let mut result = Vec::new();

        for cy in cy0..=cy1 {
            for cx in cx0..=cx1 {
                if let Some(bucket) = self.buckets.get(&(cx, cy)) {
                    for id in bucket {
                        if seen.contains(id) {
                            continue;
                        }
                        if let Some(item) = self.items.get(id) {
                            if Self::segment_aabb(x1, y1, x2, y2, item.x, item.y, item.w, item.h) {
                                seen.insert(id.clone());
                                result.push(id.clone());
                            }
                        }
                    }
                }
            }
        }
        result
    }

    /// Tests whether a line segment intersects an AABB using the slab method.
    #[allow(clippy::too_many_arguments)]
    fn segment_aabb(
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
        ax: f32,
        ay: f32,
        aw: f32,
        ah: f32,
    ) -> bool {
        let dx = x2 - x1;
        let dy = y2 - y1;
        let mut tmin = 0.0f32;
        let mut tmax = 1.0f32;

        // X slab
        if dx.abs() < 1e-12 {
            if x1 < ax || x1 > ax + aw {
                return false;
            }
        } else {
            let inv = 1.0 / dx;
            let mut t1 = (ax - x1) * inv;
            let mut t2 = (ax + aw - x1) * inv;
            if t1 > t2 {
                std::mem::swap(&mut t1, &mut t2);
            }
            tmin = tmin.max(t1);
            tmax = tmax.min(t2);
            if tmin > tmax {
                return false;
            }
        }

        // Y slab
        if dy.abs() < 1e-12 {
            if y1 < ay || y1 > ay + ah {
                return false;
            }
        } else {
            let inv = 1.0 / dy;
            let mut t1 = (ay - y1) * inv;
            let mut t2 = (ay + ah - y1) * inv;
            if t1 > t2 {
                std::mem::swap(&mut t1, &mut t2);
            }
            tmin = tmin.max(t1);
            tmax = tmax.min(t2);
            if tmin > tmax {
                return false;
            }
        }

        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn insert_and_query_rect() {
        let mut sh = SpatialHash::new(64.0);
        sh.insert("a".into(), 10.0, 10.0, 20.0, 20.0);
        let hits = sh.query_rect(5.0, 5.0, 30.0, 30.0);
        assert!(hits.contains(&"a".to_string()));
    }

    #[test]
    fn query_misses_non_overlapping() {
        let mut sh = SpatialHash::new(64.0);
        sh.insert("a".into(), 10.0, 10.0, 20.0, 20.0);
        let hits = sh.query_rect(100.0, 100.0, 10.0, 10.0);
        assert!(hits.is_empty());
    }

    #[test]
    fn remove_then_query_empty() {
        let mut sh = SpatialHash::new(64.0);
        sh.insert("a".into(), 10.0, 10.0, 20.0, 20.0);
        sh.remove("a");
        let hits = sh.query_rect(5.0, 5.0, 30.0, 30.0);
        assert!(hits.is_empty());
        assert_eq!(sh.item_count(), 0);
    }

    #[test]
    fn query_circle_filters_by_distance() {
        let mut sh = SpatialHash::new(64.0);
        // Item at corner — just outside the circle
        sh.insert("far".into(), 90.0, 90.0, 10.0, 10.0);
        // Item near centre
        sh.insert("near".into(), 48.0, 48.0, 4.0, 4.0);
        let hits = sh.query_circle(50.0, 50.0, 10.0);
        assert!(hits.contains(&"near".to_string()));
        assert!(!hits.contains(&"far".to_string()));
    }

    #[test]
    fn multiple_items_same_cell() {
        let mut sh = SpatialHash::new(100.0);
        sh.insert("a".into(), 1.0, 1.0, 5.0, 5.0);
        sh.insert("b".into(), 2.0, 2.0, 5.0, 5.0);
        sh.insert("c".into(), 3.0, 3.0, 5.0, 5.0);
        assert_eq!(sh.item_count(), 3);
        let hits = sh.query_rect(0.0, 0.0, 10.0, 10.0);
        assert_eq!(hits.len(), 3);
    }

    #[test]
    fn update_moves_item() {
        let mut sh = SpatialHash::new(64.0);
        sh.insert("a".into(), 10.0, 10.0, 5.0, 5.0);
        sh.update("a".into(), 200.0, 200.0, 5.0, 5.0);
        // Old location should miss
        assert!(sh.query_rect(5.0, 5.0, 20.0, 20.0).is_empty());
        // New location should hit
        assert!(sh
            .query_rect(195.0, 195.0, 20.0, 20.0)
            .contains(&"a".to_string()));
    }

    #[test]
    fn query_segment_hits() {
        let mut sh = SpatialHash::new(64.0);
        sh.insert("a".into(), 50.0, 50.0, 10.0, 10.0);
        let hits = sh.query_segment(0.0, 55.0, 100.0, 55.0);
        assert!(hits.contains(&"a".to_string()));
    }
}
