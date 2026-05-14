//! Polygon-region zone map for area-based game maps.
//! Owns `PolygonRegion` and `PolygonMap`, supporting point-in-polygon queries, labels,
//! outline/highlight rendering state, and bounding-box queries.
//! Does not own rendering; callers read vertices and colors for draw calls.
//! Depends on `math`.

use crate::math::Color;
use std::collections::HashMap;

/// A named convex or concave polygon zone with a fill color and optional text label.
pub struct PolygonRegion {
    /// Region identifier, matches its key in the parent `PolygonMap`.
    pub name: String,
    /// Flat `[x0, y0, x1, y1, ...]` vertex list.
    pub vertices: Vec<f32>,
    /// Fill color for this region.
    pub color: Color,
    /// Optional text label shown at the region centroid.
    pub label: Option<String>,
    /// Font size for the text label in pixels.
    pub font_size: f32,
}

/// A collection of named polygon regions with shared outline and highlight state.
pub struct PolygonMap {
    /// All registered regions keyed by name.
    regions: HashMap<String, PolygonRegion>,
    /// Outline stroke color applied to all region borders.
    pub outline_color: Color,
    /// Outline stroke width in pixels.
    pub outline_width: f32,
    /// Fill color used for the currently highlighted region.
    pub highlight_color: Color,
    /// Name of the currently highlighted region, if any.
    pub highlighted: Option<String>,
}
impl PolygonMap {
    /// Create an empty `PolygonMap` with white outline and yellow highlight.
    pub fn new() -> Self {
        Self {
            regions: HashMap::new(),
            outline_color: Color::WHITE,
            outline_width: 1.0,
            highlight_color: Color {
                r: 1.0,
                g: 1.0,
                b: 0.0,
                a: 1.0,
            },
            highlighted: None,
        }
    }
    /// Add a region with the given `name`, vertex list, and fill `color`; overwrites any existing region with the same name.
    pub fn add_region(&mut self, name: impl Into<String>, vertices: Vec<f32>, color: Color) {
        let name = name.into();
        self.regions.insert(
            name.clone(),
            PolygonRegion {
                name,
                vertices,
                color,
                label: None,
                font_size: 14.0,
            },
        );
    }
    /// Remove the region named `name`; clears highlight if that region was highlighted; returns `true` when found.
    pub fn remove_region(&mut self, name: &str) -> bool {
        if self.highlighted.as_deref() == Some(name) {
            self.highlighted = None;
        }
        self.regions.remove(name).is_some()
    }
    /// Set the fill color of region `name`; returns `true` when found.
    pub fn set_region_color(&mut self, name: &str, color: Color) -> bool {
        if let Some(r) = self.regions.get_mut(name) {
            r.color = color;
            true
        } else {
            false
        }
    }
    /// Return the fill color of region `name`, or `None` when not found.
    pub fn get_region_color(&self, name: &str) -> Option<Color> {
        self.regions.get(name).map(|r| r.color)
    }

    /// Set the label text and font size for region `name`; returns `true` when found.
    pub fn set_region_label(
        &mut self,
        name: &str,
        text: impl Into<String>,
        font_size: f32,
    ) -> bool {
        if let Some(r) = self.regions.get_mut(name) {
            r.label = Some(text.into());
            r.font_size = font_size;
            true
        } else {
            false
        }
    }
    /// Return the name of the topmost region that contains `(x, y)`, or `None` when no region matches.
    pub fn get_region_at(&self, x: f32, y: f32) -> Option<&str> {
        for region in self.regions.values() {
            if point_in_polygon(x, y, &region.vertices) {
                return Some(&region.name);
            }
        }
        None
    }
    /// Return the names of all registered regions.
    pub fn get_region_names(&self) -> Vec<String> {
        self.regions.keys().cloned().collect()
    }

    /// Return the vertex slice for region `name`, or `None` when not found.
    pub fn get_region_vertices(&self, name: &str) -> Option<&[f32]> {
        self.regions.get(name).map(|r| r.vertices.as_slice())
    }

    /// Return the centroid `(cx, cy)` of region `name`, or `None` when empty or missing.
    pub fn get_region_center(&self, name: &str) -> Option<(f32, f32)> {
        let region = self.regions.get(name)?;
        let n = region.vertices.len() / 2;
        if n == 0 {
            return None;
        }
        let mut cx = 0.0_f32;
        let mut cy = 0.0_f32;
        for i in 0..n {
            cx += region.vertices[i * 2];
            cy += region.vertices[i * 2 + 1];
        }
        Some((cx / n as f32, cy / n as f32))
    }
    /// Return the bounding box `(min_x, min_y, width, height)` of all regions, or `None` when empty.
    pub fn get_bounding_box(&self) -> Option<(f32, f32, f32, f32)> {
        let mut min_x = f32::MAX;
        let mut min_y = f32::MAX;
        let mut max_x = f32::MIN;
        let mut max_y = f32::MIN;
        let mut any = false;
        for region in self.regions.values() {
            let n = region.vertices.len() / 2;
            for i in 0..n {
                let x = region.vertices[i * 2];
                let y = region.vertices[i * 2 + 1];
                if x < min_x {
                    min_x = x;
                }
                if y < min_y {
                    min_y = y;
                }
                if x > max_x {
                    max_x = x;
                }
                if y > max_y {
                    max_y = y;
                }
                any = true;
            }
        }
        if any {
            Some((min_x, min_y, max_x - min_x, max_y - min_y))
        } else {
            None
        }
    }
    /// Set the global outline stroke color.
    pub fn set_outline_color(&mut self, color: Color) {
        self.outline_color = color;
    }

    /// Set the global outline stroke width in pixels.
    pub fn set_outline_width(&mut self, width: f32) {
        self.outline_width = width;
    }

    /// Set the fill color used for the highlighted region.
    pub fn set_highlight_color(&mut self, color: Color) {
        self.highlight_color = color;
    }

    /// Mark region `name` as highlighted.
    pub fn highlight(&mut self, name: impl Into<String>) {
        self.highlighted = Some(name.into());
    }

    /// Clear the current highlight.
    pub fn clear_highlight(&mut self) {
        self.highlighted = None;
    }

    /// Remove all regions and clear the highlight.
    pub fn clear(&mut self) {
        self.regions.clear();
        self.highlighted = None;
    }
}

/// Default `PolygonMap` with white outline and yellow highlight.
impl Default for PolygonMap {
    fn default() -> Self {
        Self::new()
    }
}

/// Ray-casting point-in-polygon test; returns `true` when `(px, py)` is inside `vertices`.
fn point_in_polygon(px: f32, py: f32, vertices: &[f32]) -> bool {
    let n = vertices.len() / 2;
    if n < 3 {
        return false;
    }
    let mut inside = false;
    let mut j = n - 1;
    for i in 0..n {
        let xi = vertices[i * 2];
        let yi = vertices[i * 2 + 1];
        let xj = vertices[j * 2];
        let yj = vertices[j * 2 + 1];
        if ((yi > py) != (yj > py)) && (px < (xj - xi) * (py - yi) / (yj - yi) + xi) {
            inside = !inside;
        }
        j = i;
    }
    inside
}
