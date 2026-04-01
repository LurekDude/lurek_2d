//! Polygon map renderer with region management and hit detection.
//!
//! Manages a collection of named polygon regions with colors, labels,
//! highlighting, and point-in-polygon queries.

use std::collections::HashMap;

use crate::graphics::Color;

/// A named polygon region.
///
/// # Fields
/// - `name` — `String`.
/// - `vertices` — `Vec<f32>`.
/// - `color` — `Color`.
/// - `label` — `Option<String>`.
/// - `font_size` — `f32`.
pub struct PolygonRegion {
    /// Unique name identifying this region.
    pub name: String,
    /// Flat vertex array `[x1, y1, x2, y2, …]`.
    pub vertices: Vec<f32>,
    /// Fill color of the region.
    pub color: Color,
    /// Optional text label displayed at the centroid.
    pub label: Option<String>,
    /// Font size for the label text.
    pub font_size: f32,
}

/// Polygon map renderer with region management and hit detection.
///
/// # Fields
/// - `outline_color` — `Color`.
/// - `outline_width` — `f32`.
/// - `highlight_color` — `Color`.
/// - `highlighted` — `Option<String>`.
///
/// Stores named polygon regions and supports point-in-polygon queries,
/// highlighting, and bounding-box computation. Regions are keyed by name.
pub struct PolygonMap {
    /// All regions keyed by name.
    regions: HashMap<String, PolygonRegion>,
    /// Outline color drawn around each region.
    pub outline_color: Color,
    /// Outline stroke width.
    pub outline_width: f32,
    /// Color used for the highlighted region.
    pub highlight_color: Color,
    /// Name of the currently highlighted region, if any.
    pub highlighted: Option<String>,
}

impl PolygonMap {
    /// Create an empty polygon map with default styling.
    ///
    /// # Returns
    /// `Self`.
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

    /// Add a named polygon region with the given flat vertex data and color.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `vertices` — `Vec<f32>`.
    /// - `color` — `Color`.
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

    /// Remove a region by name. Returns `true` if it existed.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_region(&mut self, name: &str) -> bool {
        if self.highlighted.as_deref() == Some(name) {
            self.highlighted = None;
        }
        self.regions.remove(name).is_some()
    }

    /// Set the fill color of a region. Returns `false` if the region doesn't exist.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `color` — `Color`.
    ///
    /// # Returns
    /// `bool`.
    pub fn set_region_color(&mut self, name: &str, color: Color) -> bool {
        if let Some(r) = self.regions.get_mut(name) {
            r.color = color;
            true
        } else {
            false
        }
    }

    /// Get the fill color of a region.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<Color>`.
    pub fn get_region_color(&self, name: &str) -> Option<Color> {
        self.regions.get(name).map(|r| r.color)
    }

    /// Set the label text and font size for a region.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `text` — `impl Into<String>`.
    /// - `font_size` — `f32`.
    ///
    /// # Returns
    /// `bool`.
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

    /// Return the name of the first region containing the point `(x, y)`.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_region_at(&self, x: f32, y: f32) -> Option<&str> {
        for region in self.regions.values() {
            if point_in_polygon(x, y, &region.vertices) {
                return Some(&region.name);
            }
        }
        None
    }

    /// Names of all regions.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_region_names(&self) -> Vec<String> {
        self.regions.keys().cloned().collect()
    }

    /// Flat vertex slice for a region.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&[f32]>`.
    pub fn get_region_vertices(&self, name: &str) -> Option<&[f32]> {
        self.regions.get(name).map(|r| r.vertices.as_slice())
    }

    /// Centroid of a region (average of its vertices).
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<(f32, f32)>`.
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

    /// Axis-aligned bounding box of all regions: `(min_x, min_y, width, height)`.
    ///
    /// # Returns
    /// `Option<(f32, f32, f32, f32)>`.
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

    /// Set the outline color for all regions.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_outline_color(&mut self, color: Color) {
        self.outline_color = color;
    }

    /// Set the outline stroke width.
    ///
    /// # Parameters
    /// - `width` — `f32`.
    pub fn set_outline_width(&mut self, width: f32) {
        self.outline_width = width;
    }

    /// Set the highlight color.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_highlight_color(&mut self, color: Color) {
        self.highlight_color = color;
    }

    /// Highlight a region by name.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    pub fn highlight(&mut self, name: impl Into<String>) {
        self.highlighted = Some(name.into());
    }

    /// Clear any active highlight.
    pub fn clear_highlight(&mut self) {
        self.highlighted = None;
    }

    /// Remove all regions and clear the highlight.
    pub fn clear(&mut self) {
        self.regions.clear();
        self.highlighted = None;
    }
}

impl Default for PolygonMap {
    fn default() -> Self {
        Self::new()
    }
}

/// Ray-casting point-in-polygon test.
///
/// Casts a horizontal ray to the right from `(px, py)` and counts
/// edge crossings. An odd count means the point is inside.
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
