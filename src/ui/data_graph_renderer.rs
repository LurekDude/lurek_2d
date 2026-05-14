//! Data graph renderer for `lurek.ui` — rasterises `GraphSeries` data (line, scatter, bar) into
//! a pixel viewport using a configurable axis range, grid, and cursor overlay.
//! Does not own a widget in the UI tree; callers supply screen viewport coordinates directly.
//! Depends on `crate::math::Color`.

use crate::math::Color;
use std::collections::HashMap;
/// Discriminated data series type for a `GraphRenderer`; each variant holds named, coloured data.
#[derive(Debug, Clone)]
pub enum GraphSeries {
    /// Polyline series drawn through a sequence of `(x, y)` world-space points.
    Line {
        /// Series name used for legend and keyed lookup.
        name: String,
        /// Ordered `(x, y)` world-space points.
        points: Vec<(f64, f64)>,
        /// Line colour.
        color: Color,
    },
    /// Scatter series where each point is drawn as a filled circle.
    Scatter {
        /// Series name used for legend and keyed lookup.
        name: String,
        /// Ordered `(x, y)` world-space points.
        points: Vec<(f64, f64)>,
        /// Point fill colour.
        color: Color,
        /// Pixel radius of each scatter dot.
        size: f32,
    },
    /// Vertical bar series where each entry is an index-keyed `(index, value)` pair.
    Bar {
        /// Series name used for legend and keyed lookup.
        name: String,
        /// Ordered bar heights; bar `i` is drawn at X = i.
        values: Vec<f64>,
        /// Bar fill colour.
        color: Color,
    },
}
impl GraphSeries {
    /// Return the series name shared across all variants.
    pub fn name(&self) -> &str {
        match self {
            GraphSeries::Line { name, .. } => name,
            GraphSeries::Scatter { name, .. } => name,
            GraphSeries::Bar { name, .. } => name,
        }
    }
}
/// Stateful renderer that maps named `GraphSeries` onto a screen viewport using configurable ranges, grid, and annotations.
pub struct GraphRenderer {
    /// Screen-space `(x, y, width, height)` rectangle for the graph area.
    pub viewport: (f32, f32, f32, f32),
    /// World-space `(x_min, x_max, y_min, y_max)` axis ranges.
    pub range: (f64, f64, f64, f64),
    /// Keyed series map; key is the series name.
    series: HashMap<String, GraphSeries>,
    /// Whether to draw grid lines at axis tick positions.
    pub show_grid: bool,
    /// Whether to draw X and Y axis lines.
    pub show_axes: bool,
    /// Whether to draw numeric axis tick labels.
    pub show_labels: bool,
    /// Grid line colour.
    pub grid_color: Color,
    /// Axis line colour.
    pub axis_color: Color,
    /// Background fill colour.
    pub bg_color: Color,
    /// Optional chart title drawn above the viewport.
    pub title: Option<String>,
    /// Optional label drawn below the X axis.
    pub x_label: Option<String>,
    /// Optional label drawn beside the Y axis.
    pub y_label: Option<String>,
    /// Optional hover cursor position in world-space coordinates.
    pub cursor: Option<(f64, f64)>,
}
impl GraphRenderer {
    /// Create a renderer with a 400×300 viewport, range (-10, 10, -10, 10), and dark colour defaults.
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
    /// Set the screen-space viewport rect `(x, y, w, h)` for this renderer.
    pub fn set_viewport(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport = (x, y, w, h);
    }
    /// Return the current viewport as `(x, y, w, h)`.
    pub fn get_viewport(&self) -> (f32, f32, f32, f32) {
        self.viewport
    }
    /// Override the axis range with explicit `(x_min, x_max, y_min, y_max)` values.
    pub fn set_range(&mut self, x_min: f64, x_max: f64, y_min: f64, y_max: f64) {
        self.range = (x_min, x_max, y_min, y_max);
    }
    /// Return the current axis range as `(x_min, x_max, y_min, y_max)`.
    pub fn get_range(&self) -> (f64, f64, f64, f64) {
        self.range
    }
    /// Compute and apply a tight range from all loaded series, padded by 10%; no-ops when series are empty.
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
    /// Insert or replace a line series with the given name, points, and colour.
    pub fn add_line_series(&mut self, name: &str, points: Vec<(f64, f64)>, color: Color) {
        let s = GraphSeries::Line {
            name: name.to_string(),
            points,
            color,
        };
        self.series.insert(name.to_string(), s);
    }
    /// Insert or replace a scatter series with the given name, points, colour, and dot size.
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
    /// Insert or replace a bar series with the given name, bar heights, and colour.
    pub fn add_bar_series(&mut self, name: &str, values: Vec<f64>, color: Color) {
        let s = GraphSeries::Bar {
            name: name.to_string(),
            values,
            color,
        };
        self.series.insert(name.to_string(), s);
    }
    /// Remove the series with the given name; return `false` if not found.
    pub fn remove_series(&mut self, name: &str) -> bool {
        self.series.remove(name).is_some()
    }
    /// Remove all series.
    pub fn clear_series(&mut self) {
        self.series.clear();
    }
    /// Return all current series names in arbitrary order.
    pub fn get_series_names(&self) -> Vec<String> {
        self.series.keys().cloned().collect()
    }
    /// Return a shared reference to the internal series map.
    pub fn series(&self) -> &HashMap<String, GraphSeries> {
        &self.series
    }
    /// Set whether grid lines are drawn.
    pub fn set_show_grid(&mut self, b: bool) {
        self.show_grid = b;
    }
    /// Set whether axis lines are drawn.
    pub fn set_show_axes(&mut self, b: bool) {
        self.show_axes = b;
    }
    /// Set whether numeric axis tick labels are drawn.
    pub fn set_show_labels(&mut self, b: bool) {
        self.show_labels = b;
    }
    /// Set the grid line colour.
    pub fn set_grid_color(&mut self, c: Color) {
        self.grid_color = c;
    }
    /// Set the axis line colour.
    pub fn set_axis_color(&mut self, c: Color) {
        self.axis_color = c;
    }
    /// Set the background fill colour.
    pub fn set_bg_color(&mut self, c: Color) {
        self.bg_color = c;
    }
    /// Set the chart title text.
    pub fn set_title(&mut self, text: &str) {
        self.title = Some(text.to_string());
    }
    /// Set the X and Y axis annotation labels.
    pub fn set_axis_labels(&mut self, x_label: &str, y_label: &str) {
        self.x_label = Some(x_label.to_string());
        self.y_label = Some(y_label.to_string());
    }
    /// Set the hover cursor world-space position shown as a crosshair overlay.
    pub fn set_cursor_position(&mut self, x: f64, y: f64) {
        self.cursor = Some((x, y));
    }
    /// Return the current cursor world-space position, or `None` if unset.
    pub fn get_cursor_value(&self) -> Option<(f64, f64)> {
        self.cursor
    }
    /// Map world-space `(wx, wy)` to screen-space pixel coordinates within the viewport.
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
        let sy = if y_span.abs() > f64::EPSILON {
            vy + vh - ((wy - y_min) / y_span) as f32 * vh
        } else {
            vy + vh * 0.5
        };
        (sx, sy)
    }
    /// Map screen-space pixel coordinates back to world-space `(wx, wy)`.
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
/// Provide a default `GraphRenderer` via `Self::new()`.
impl Default for GraphRenderer {
    fn default() -> Self {
        Self::new()
    }
}
