//! Mathematical function graph and chart renderer.
//!
//! [`GraphRenderer`] manages multiple named data series (line, scatter, bar)
//! and provides viewport ↔ world coordinate mapping for rendering charts in
//! a Luna2D game. The renderer stores pure data — actual draw calls are
//! issued by the Lua wrapper in `graphics_api.rs`.

use std::collections::HashMap;

use crate::graphics::Color;

// ── Series types ────────────────────────────────────────────────────────

/// A data series that can be added to a [`GraphRenderer`].
///
/// # Variants
/// - `Line` — Line variant.
/// - `Scatter` — Scatter variant.
/// - `Bar` — Bar variant.
#[derive(Debug, Clone)]
pub enum GraphSeries {
    /// A polyline connecting ordered `(x, y)` data points.
    Line {
        /// Series name (unique within the renderer).
        name: String,
        /// Ordered data points.
        points: Vec<(f64, f64)>,
        /// Line color.
        color: Color,
    },
    /// Individual markers at `(x, y)` positions.
    Scatter {
        /// Series name.
        name: String,
        /// Data points.
        points: Vec<(f64, f64)>,
        /// Marker color.
        color: Color,
        /// Marker radius in pixels.
        size: f32,
    },
    /// Vertical bars whose heights correspond to `values` (indexed 0, 1, …).
    Bar {
        /// Series name.
        name: String,
        /// Bar values (one per category).
        values: Vec<f64>,
        /// Bar fill color.
        color: Color,
    },
}

impl GraphSeries {
    /// Returns the series name regardless of variant.
    ///
    /// # Returns
    /// `&str`.
    pub fn name(&self) -> &str {
        match self {
            GraphSeries::Line { name, .. } => name,
            GraphSeries::Scatter { name, .. } => name,
            GraphSeries::Bar { name, .. } => name,
        }
    }
}

// ── GraphRenderer ───────────────────────────────────────────────────────

/// Mathematical function graph / chart renderer.
///
/// # Fields
/// - `viewport` — `(f32, f32, f32, f32)`.
/// - `range` — `(f64, f64, f64, f64)`.
/// - `show_grid` — `bool`.
/// - `show_axes` — `bool`.
/// - `show_labels` — `bool`.
/// - `grid_color` — `Color`.
/// - `axis_color` — `Color`.
/// - `bg_color` — `Color`.
/// - `title` — `Option<String>`.
/// - `x_label` — `Option<String>`.
/// - `y_label` — `Option<String>`.
/// - `cursor` — `Option<(f64, f64)>`.
///
/// Stores data series and rendering options. Use [`world_to_screen`](Self::world_to_screen)
/// and [`screen_to_world`](Self::screen_to_world) for coordinate mapping.
pub struct GraphRenderer {
    /// Viewport rectangle in screen pixels `(x, y, w, h)`.
    pub viewport: (f32, f32, f32, f32),
    /// World-space data range `(x_min, x_max, y_min, y_max)`.
    pub range: (f64, f64, f64, f64),
    /// Named data series.
    series: HashMap<String, GraphSeries>,
    /// Whether to render a grid behind the data.
    pub show_grid: bool,
    /// Whether to render the x/y axes.
    pub show_axes: bool,
    /// Whether to render axis labels and title.
    pub show_labels: bool,
    /// Grid line color.
    pub grid_color: Color,
    /// Axis line color.
    pub axis_color: Color,
    /// Background fill color.
    pub bg_color: Color,
    /// Optional chart title.
    pub title: Option<String>,
    /// Optional x-axis label.
    pub x_label: Option<String>,
    /// Optional y-axis label.
    pub y_label: Option<String>,
    /// Cursor position in world (data) coordinates for interactive readout.
    pub cursor: Option<(f64, f64)>,
}

impl GraphRenderer {
    /// Creates a new `GraphRenderer` with sensible defaults.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Viewport: `(0, 0, 400, 300)`, range: `(-10, 10, -10, 10)`,
    /// grid and axes enabled, white axis/grid on dark background.
    pub fn new() -> Self {
        Self {
            viewport: (0.0, 0.0, 400.0, 300.0),
            range: (-10.0, 10.0, -10.0, 10.0),
            series: HashMap::new(),
            show_grid: true,
            show_axes: true,
            show_labels: true,
            grid_color: Color::new(0.3, 0.3, 0.3, 1.0),
            axis_color: Color::WHITE,
            bg_color: Color::new(0.1, 0.1, 0.1, 1.0),
            title: None,
            x_label: None,
            y_label: None,
            cursor: None,
        }
    }

    // ── Viewport / range ────────────────────────────────────────────────

    /// Sets the screen-pixel viewport for chart rendering.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `w` — `f32`.
    /// - `h` — `f32`.
    pub fn set_viewport(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport = (x, y, w, h);
    }

    /// Returns the current viewport as `(x, y, w, h)`.
    ///
    /// # Returns
    /// `(f32, f32, f32, f32)`.
    pub fn get_viewport(&self) -> (f32, f32, f32, f32) {
        self.viewport
    }

    /// Sets the world (data) coordinate range. Replaces the current range value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `x_min` — `f64`.
    /// - `x_max` — `f64`.
    /// - `y_min` — `f64`.
    /// - `y_max` — `f64`.
    pub fn set_range(&mut self, x_min: f64, x_max: f64, y_min: f64, y_max: f64) {
        self.range = (x_min, x_max, y_min, y_max);
    }

    /// Returns the current data range as `(x_min, x_max, y_min, y_max)`.
    ///
    /// # Returns
    /// `(f64, f64, f64, f64)`.
    pub fn get_range(&self) -> (f64, f64, f64, f64) {
        self.range
    }

    /// Computes the data range from all series data points with 10 % padding.
    ///
    /// Does nothing if there are no data points.
    pub fn auto_range(&mut self) {
        let mut x_min = f64::MAX;
        let mut x_max = f64::MIN;
        let mut y_min = f64::MAX;
        let mut y_max = f64::MIN;
        let mut has_data = false;

        for s in self.series.values() {
            match s {
                GraphSeries::Line { points, .. } | GraphSeries::Scatter { points, .. } => {
                    for &(x, y) in points {
                        x_min = x_min.min(x);
                        x_max = x_max.max(x);
                        y_min = y_min.min(y);
                        y_max = y_max.max(y);
                        has_data = true;
                    }
                }
                GraphSeries::Bar { values, .. } => {
                    for (i, &v) in values.iter().enumerate() {
                        let x = i as f64;
                        x_min = x_min.min(x);
                        x_max = x_max.max(x);
                        y_min = y_min.min(0.0_f64.min(v));
                        y_max = y_max.max(v);
                        has_data = true;
                    }
                }
            }
        }

        if !has_data {
            return;
        }

        let pad_x = ((x_max - x_min) * 0.1).max(1.0);
        let pad_y = ((y_max - y_min) * 0.1).max(1.0);
        self.range = (x_min - pad_x, x_max + pad_x, y_min - pad_y, y_max + pad_y);
    }

    // ── Series management ───────────────────────────────────────────────

    /// Adds a line series with the given name, data points, and color.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `points` — `Vec<(f64, f64)>`.
    /// - `color` — `Color`.
    pub fn add_line_series(&mut self, name: &str, points: Vec<(f64, f64)>, color: Color) {
        let s = GraphSeries::Line {
            name: name.to_string(),
            points,
            color,
        };
        self.series.insert(name.to_string(), s);
    }

    /// Adds a scatter series. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `points` — `Vec<(f64, f64)>`.
    /// - `color` — `Color`.
    /// - `size` — `f32`.
    pub fn add_scatter_series(
        &mut self,
        name: &str,
        points: Vec<(f64, f64)>,
        color: Color,
        size: f32,
    ) {
        let s = GraphSeries::Scatter {
            name: name.to_string(),
            points,
            color,
            size,
        };
        self.series.insert(name.to_string(), s);
    }

    /// Adds a bar series. Each value maps to category index 0, 1, 2, ….
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `values` — `Vec<f64>`.
    /// - `color` — `Color`.
    pub fn add_bar_series(&mut self, name: &str, values: Vec<f64>, color: Color) {
        let s = GraphSeries::Bar {
            name: name.to_string(),
            values,
            color,
        };
        self.series.insert(name.to_string(), s);
    }

    /// Removes a series by name. Returns `true` if it existed.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_series(&mut self, name: &str) -> bool {
        self.series.remove(name).is_some()
    }

    /// Removes all series. After this call the container is in the same state as immediately after construction.
    pub fn clear_series(&mut self) {
        self.series.clear();
    }

    /// Returns the names of all registered series.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_series_names(&self) -> Vec<String> {
        self.series.keys().cloned().collect()
    }

    /// Returns a reference to the underlying series map.
    ///
    /// # Returns
    /// `&HashMap<String, GraphSeries>`.
    pub fn series(&self) -> &HashMap<String, GraphSeries> {
        &self.series
    }

    // ── Display options ─────────────────────────────────────────────────

    /// Enables or disables the background grid.
    ///
    /// # Parameters
    /// - `b` — `bool`.
    pub fn set_show_grid(&mut self, b: bool) {
        self.show_grid = b;
    }

    /// Enables or disables the x/y axes. Replaces the current show axes value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `b` — `bool`.
    pub fn set_show_axes(&mut self, b: bool) {
        self.show_axes = b;
    }

    /// Enables or disables axis labels and chart title.
    ///
    /// # Parameters
    /// - `b` — `bool`.
    pub fn set_show_labels(&mut self, b: bool) {
        self.show_labels = b;
    }

    /// Sets the grid line color. Replaces the current grid color value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `c` — `Color`.
    pub fn set_grid_color(&mut self, c: Color) {
        self.grid_color = c;
    }

    /// Sets the axis line color. Replaces the current axis color value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `c` — `Color`.
    pub fn set_axis_color(&mut self, c: Color) {
        self.axis_color = c;
    }

    /// Sets the chart background color. Replaces the current bg color value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `c` — `Color`.
    pub fn set_bg_color(&mut self, c: Color) {
        self.bg_color = c;
    }

    /// Sets the chart title. Replaces the current title value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `text` — `&str`.
    pub fn set_title(&mut self, text: &str) {
        self.title = Some(text.to_string());
    }

    /// Sets the x-axis and y-axis labels. Replaces the current axis labels value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `x_label` — `&str`.
    /// - `y_label` — `&str`.
    pub fn set_axis_labels(&mut self, x_label: &str, y_label: &str) {
        self.x_label = Some(x_label.to_string());
        self.y_label = Some(y_label.to_string());
    }

    // ── Cursor ──────────────────────────────────────────────────────────

    /// Sets the cursor position in data (world) coordinates.
    ///
    /// # Parameters
    /// - `x` — `f64`.
    /// - `y` — `f64`.
    pub fn set_cursor_position(&mut self, x: f64, y: f64) {
        self.cursor = Some((x, y));
    }

    /// Returns the current cursor position in data coordinates.
    ///
    /// # Returns
    /// `Option<(f64, f64)>`.
    pub fn get_cursor_value(&self) -> Option<(f64, f64)> {
        self.cursor
    }

    // ── Coordinate mapping ──────────────────────────────────────────────

    /// Maps world (data) coordinates to viewport screen-pixel coordinates.
    ///
    /// # Parameters
    /// - `wx` — `f64`.
    /// - `wy` — `f64`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn world_to_screen(&self, wx: f64, wy: f64) -> (f32, f32) {
        let (vx, vy, vw, vh) = self.viewport;
        let (x_min, x_max, y_min, y_max) = self.range;
        let x_span = x_max - x_min;
        let y_span = y_max - y_min;

        let sx = if x_span.abs() > f64::EPSILON {
            vx + ((wx - x_min) / x_span) as f32 * vw
        } else {
            vx + vw * 0.5
        };
        // Flip Y: data-space Y increases upward, screen Y increases downward.
        let sy = if y_span.abs() > f64::EPSILON {
            vy + vh - ((wy - y_min) / y_span) as f32 * vh
        } else {
            vy + vh * 0.5
        };
        (sx, sy)
    }

    /// Maps viewport screen-pixel coordinates back to world (data) coordinates.
    ///
    /// # Parameters
    /// - `sx` — `f32`.
    /// - `sy` — `f32`.
    ///
    /// # Returns
    /// `(f64, f64)`.
    pub fn screen_to_world(&self, sx: f32, sy: f32) -> (f64, f64) {
        let (vx, vy, vw, vh) = self.viewport;
        let (x_min, x_max, y_min, y_max) = self.range;
        let x_span = x_max - x_min;
        let y_span = y_max - y_min;

        let wx = if vw.abs() > f32::EPSILON {
            x_min + ((sx - vx) / vw) as f64 * x_span
        } else {
            (x_min + x_max) * 0.5
        };
        let wy = if vh.abs() > f32::EPSILON {
            y_min + ((vy + vh - sy) / vh) as f64 * y_span
        } else {
            (y_min + y_max) * 0.5
        };
        (wx, wy)
    }
}

impl Default for GraphRenderer {
    fn default() -> Self {
        Self::new()
    }
}

// ── Unit tests ──────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_renderer_has_sensible_defaults() {
        let gr = GraphRenderer::new();
        assert!(gr.show_grid);
        assert!(gr.show_axes);
        assert_eq!(gr.series.len(), 0);
    }

    #[test]
    fn add_and_remove_series() {
        let mut gr = GraphRenderer::new();
        gr.add_line_series("sin", vec![(0.0, 0.0), (1.0, 1.0)], Color::RED);
        gr.add_scatter_series("pts", vec![(2.0, 3.0)], Color::WHITE, 4.0);
        assert_eq!(gr.get_series_names().len(), 2);
        assert!(gr.remove_series("sin"));
        assert!(!gr.remove_series("sin"));
        assert_eq!(gr.get_series_names().len(), 1);
    }

    #[test]
    fn world_to_screen_and_back() {
        let mut gr = GraphRenderer::new();
        gr.set_viewport(0.0, 0.0, 400.0, 300.0);
        gr.set_range(0.0, 10.0, 0.0, 10.0);

        let (sx, sy) = gr.world_to_screen(5.0, 5.0);
        assert!((sx - 200.0).abs() < 1e-3);
        assert!((sy - 150.0).abs() < 1e-3);

        let (wx, wy) = gr.screen_to_world(sx, sy);
        assert!((wx - 5.0).abs() < 1e-3);
        assert!((wy - 5.0).abs() < 1e-3);
    }

    #[test]
    fn auto_range_with_padding() {
        let mut gr = GraphRenderer::new();
        gr.add_line_series("f", vec![(0.0, 0.0), (10.0, 10.0)], Color::WHITE);
        gr.auto_range();
        let (x_min, x_max, y_min, y_max) = gr.get_range();
        assert!(x_min < 0.0);
        assert!(x_max > 10.0);
        assert!(y_min < 0.0);
        assert!(y_max > 10.0);
    }

    #[test]
    fn bar_series_auto_range_includes_zero() {
        let mut gr = GraphRenderer::new();
        gr.add_bar_series("bars", vec![5.0, 10.0, 3.0], Color::RED);
        gr.auto_range();
        let (_, _, y_min, _) = gr.get_range();
        assert!(y_min <= 0.0);
    }

    #[test]
    fn clear_series_empties_all() {
        let mut gr = GraphRenderer::new();
        gr.add_line_series("a", vec![], Color::WHITE);
        gr.add_line_series("b", vec![], Color::RED);
        gr.clear_series();
        assert_eq!(gr.get_series_names().len(), 0);
    }

    #[test]
    fn cursor_round_trip() {
        let mut gr = GraphRenderer::new();
        assert!(gr.get_cursor_value().is_none());
        gr.set_cursor_position(3.14, 2.71);
        let (cx, cy) = gr.get_cursor_value().unwrap();
        assert!((cx - 3.14).abs() < 1e-10);
        assert!((cy - 2.71).abs() < 1e-10);
    }
}
