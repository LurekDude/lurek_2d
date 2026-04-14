//! Configurable chart rendering to `ImageData`.
//!
//! Provides line, bar, scatter, pie, and area chart types with a shared
//! [`ChartConfig`] for titles, colours, grid, and axis styling.  Each chart
//! type implements [`draw_to_image`] producing a self-contained PNG-ready
//! `ImageData` with no GPU dependency.

use crate::image::ImageData;
use crate::math::color::Color;

// ── Shared configuration ────────────────────────────────────────────────

/// Common configuration shared by all chart types.
///
/// # Fields
/// - `width` — `u32`. Output image width.
/// - `height` — `u32`. Output image height.
/// - `title` — `Option<String>`. Chart title drawn at top-left.
/// - `bg_color` — `(u8, u8, u8)`. Background fill RGB.
/// - `axis_color` — `(u8, u8, u8)`. Axis line RGB.
/// - `grid_color` — `(u8, u8, u8)`. Grid line RGB.
/// - `label_color` — `(u8, u8, u8)`. Label text RGB.
/// - `show_grid` — `bool`. Whether to draw grid lines.
/// - `margin` — `ChartMargin`. Pixel margins around the plot area.
#[derive(Debug, Clone)]
pub struct ChartConfig {
    /// Output image width in pixels.
    pub width: u32,
    /// Output image height in pixels.
    pub height: u32,
    /// Optional chart title.
    pub title: Option<String>,
    /// Background fill colour.
    pub bg_color: (u8, u8, u8),
    /// Axis line colour.
    pub axis_color: (u8, u8, u8),
    /// Grid line colour.
    pub grid_color: (u8, u8, u8),
    /// Label text colour.
    pub label_color: (u8, u8, u8),
    /// Whether to draw grid lines.
    pub show_grid: bool,
    /// Pixel margins around the plot area.
    pub margin: ChartMargin,
}

/// Pixel margins around the chart plot area.
///
/// # Fields
/// - `left` — `i32`.
/// - `right` — `i32`.
/// - `top` — `i32`.
/// - `bottom` — `i32`.
#[derive(Debug, Clone, Copy)]
pub struct ChartMargin {
    /// Left margin in pixels.
    pub left: i32,
    /// Right margin in pixels.
    pub right: i32,
    /// Top margin in pixels.
    pub top: i32,
    /// Bottom margin in pixels.
    pub bottom: i32,
}

impl Default for ChartMargin {
    fn default() -> Self {
        Self {
            left: 40,
            right: 20,
            top: 30,
            bottom: 40,
        }
    }
}

impl Default for ChartConfig {
    fn default() -> Self {
        Self {
            width: 400,
            height: 300,
            title: None,
            bg_color: (240, 240, 245),
            axis_color: (60, 60, 70),
            grid_color: (200, 200, 210),
            label_color: (80, 80, 80),
            show_grid: true,
            margin: ChartMargin::default(),
        }
    }
}

/// A named data series with colour.
///
/// # Fields
/// - `name` — `String`.
/// - `color` — `Color`.
/// - `values` — `Vec<(f32, f32)>`.
#[derive(Debug, Clone)]
pub struct ChartSeries {
    /// Series name for legend display.
    pub name: String,
    /// Series drawing colour.
    pub color: Color,
    /// Data points as `(x, y)` pairs.
    pub values: Vec<(f32, f32)>,
}

// ── Helper: draw grid + axes ────────────────────────────────────────────

fn draw_grid_and_axes(
    img: &mut ImageData,
    cfg: &ChartConfig,
    x_divisions: u32,
    y_divisions: u32,
) -> (i32, i32, i32, i32) {
    let left = cfg.margin.left;
    let right = cfg.width as i32 - cfg.margin.right;
    let top = cfg.margin.top;
    let bottom = cfg.height as i32 - cfg.margin.bottom;
    let (gr, gg, gb) = cfg.grid_color;
    let (ar, ag, ab) = cfg.axis_color;

    if cfg.show_grid {
        let chart_w = (right - left) as f32;
        let chart_h = (bottom - top) as f32;
        for i in 0..=y_divisions {
            let y = top + (i as f32 * chart_h / y_divisions as f32) as i32;
            img.draw_line(left, y, right, y, gr, gg, gb, 255);
        }
        for i in 0..=x_divisions {
            let x = left + (i as f32 * chart_w / x_divisions as f32) as i32;
            img.draw_line(x, top, x, bottom, gr, gg, gb, 255);
        }
    }

    // Axes
    img.draw_line(left, top, left, bottom, ar, ag, ab, 255);
    img.draw_line(left, bottom, right, bottom, ar, ag, ab, 255);

    (left, right, top, bottom)
}

/// Helper to draw a filled circle safely (no out-of-bounds panics).
fn safe_circle(img: &mut ImageData, cx: i32, cy: i32, r: i32, red: u8, g: u8, b: u8, a: u8) {
    let w = img.width() as i32;
    let h = img.height() as i32;
    let y0 = (cy - r).max(0);
    let y1 = (cy + r + 1).min(h);
    let x0 = (cx - r).max(0);
    let x1 = (cx + r + 1).min(w);
    let r2 = (r * r) as i64;
    for py in y0..y1 {
        let dy = (py - cy) as i64;
        for px in x0..x1 {
            let dx = (px - cx) as i64;
            if dx * dx + dy * dy <= r2 {
                img.set_pixel(px as u32, py as u32, red, g, b, a);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════
// ██  LINE CHART
// ═══════════════════════════════════════════════════════════════════════

/// A configurable line chart renderer.
///
/// # Fields
/// - `config` — `ChartConfig`.
/// - `series` — `Vec<ChartSeries>`.
/// - `y_max` — `f32`.
/// - `x_max` — `f32`.
#[derive(Debug, Clone)]
pub struct LineChart {
    /// Chart configuration.
    pub config: ChartConfig,
    /// Data series to plot.
    pub series: Vec<ChartSeries>,
    /// Maximum Y value for scaling.
    pub y_max: f32,
    /// Maximum X value for scaling.
    pub x_max: f32,
}

impl LineChart {
    /// Creates a new line chart with the given configuration.
    ///
    /// # Parameters
    /// - `config` — `ChartConfig`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(config: ChartConfig) -> Self {
        Self {
            config,
            series: Vec::new(),
            y_max: 100.0,
            x_max: 6.0,
        }
    }

    /// Adds a named data series to the chart.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `points` — `&[(f32, f32)]`.
    /// - `color` — `Color`.
    pub fn add_series(&mut self, name: &str, points: &[(f32, f32)], color: Color) {
        self.series.push(ChartSeries {
            name: name.to_string(),
            color,
            values: points.to_vec(),
        });
    }

    /// Renders the line chart to an `ImageData`.
    ///
    /// # Parameters
    /// - `img` — `&mut crate::image::ImageData`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, mut img: &mut crate::image::ImageData) {
        let cfg = &self.config;
        let (bgr, bgg, bgb) = cfg.bg_color;
        img.fill(bgr, bgg, bgb, 255);

        let x_div = self.x_max.ceil() as u32;
        let (left, right, top, bottom) = draw_grid_and_axes(img, cfg, x_div.max(1), 5);

        let chart_w = (right - left) as f32;
        let chart_h = (bottom - top) as f32;

        // Draw title
        if let Some(ref title) = cfg.title {
            let (lr, lg, lb) = cfg.label_color;
            img.draw_label(title, left + 10, 10, lr, lg, lb);
        }

        // Plot each series
        for s in &self.series {
            let cr = (s.color.r * 255.0) as u8;
            let cg = (s.color.g * 255.0) as u8;
            let cb = (s.color.b * 255.0) as u8;

            for i in 1..s.values.len() {
                let x0 = left + (s.values[i - 1].0 / self.x_max * chart_w) as i32;
                let y0 = bottom - (s.values[i - 1].1 / self.y_max * chart_h) as i32;
                let x1 = left + (s.values[i].0 / self.x_max * chart_w) as i32;
                let y1 = bottom - (s.values[i].1 / self.y_max * chart_h) as i32;
                img.draw_line(x0, y0, x1, y1, cr, cg, cb, 255);
                img.draw_line(x0, y0 + 1, x1, y1 + 1, cr, cg, cb, 255);
            }
            // Data point markers
            for pt in &s.values {
                let x = left + (pt.0 / self.x_max * chart_w) as i32;
                let y = bottom - (pt.1 / self.y_max * chart_h) as i32;
                safe_circle(img, x, y, 3, cr, cg, cb, 255);
            }
        }

    }
}

// ═══════════════════════════════════════════════════════════════════════
// ██  BAR CHART
// ═══════════════════════════════════════════════════════════════════════

/// A single category group in a bar chart.
///
/// # Fields
/// - `label` — `String`.
/// - `values` — `Vec<f32>`.
#[derive(Debug, Clone)]
pub struct BarCategory {
    /// Category label.
    pub label: String,
    /// One value per bar series.
    pub values: Vec<f32>,
}

/// A configurable grouped bar chart renderer.
///
/// # Fields
/// - `config` — `ChartConfig`.
/// - `categories` — `Vec<BarCategory>`.
/// - `series_colors` — `Vec<Color>`.
/// - `series_names` — `Vec<String>`.
/// - `y_max` — `f32`.
#[derive(Debug, Clone)]
pub struct BarChart {
    /// Chart configuration.
    pub config: ChartConfig,
    /// Category groups.
    pub categories: Vec<BarCategory>,
    /// Colour for each bar series.
    pub series_colors: Vec<Color>,
    /// Names for each bar series.
    pub series_names: Vec<String>,
    /// Maximum Y value for scaling.
    pub y_max: f32,
}

impl BarChart {
    /// Creates a new bar chart with the given configuration.
    ///
    /// # Parameters
    /// - `config` — `ChartConfig`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(config: ChartConfig) -> Self {
        Self {
            config,
            categories: Vec::new(),
            series_colors: Vec::new(),
            series_names: Vec::new(),
            y_max: 100.0,
        }
    }

    /// Adds a bar series with a name and colour.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `color` — `Color`.
    pub fn add_series(&mut self, name: &str, color: Color) {
        self.series_names.push(name.to_string());
        self.series_colors.push(color);
    }

    /// Adds a category group with its per-series values.
    ///
    /// # Parameters
    /// - `label` — `&str`.
    /// - `values` — `&[f32]`.
    pub fn add_category(&mut self, label: &str, values: &[f32]) {
        self.categories.push(BarCategory {
            label: label.to_string(),
            values: values.to_vec(),
        });
    }

    /// Renders the bar chart to an `ImageData`.
    ///
    /// # Parameters
    /// - `img` — `&mut crate::image::ImageData`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, mut img: &mut crate::image::ImageData) {
        let cfg = &self.config;
        let (bgr, bgg, bgb) = cfg.bg_color;
        img.fill(bgr, bgg, bgb, 255);

        let (left, right, top, bottom) = draw_grid_and_axes(img, cfg, self.categories.len() as u32, 5);
        let chart_h = (bottom - top) as f32;
        let (lr, lg, lb) = cfg.label_color;

        if let Some(ref title) = cfg.title {
            img.draw_label(title, left + 10, 10, lr, lg, lb);
        }

        let n_series = self.series_colors.len().max(1);
        let n_cats = self.categories.len().max(1);
        let group_w = (right - left) / n_cats as i32;
        let bar_w = (group_w / (n_series as i32 + 1)).max(4);

        for (ci, cat) in self.categories.iter().enumerate() {
            let group_x = left + ci as i32 * group_w;
            for (si, &val) in cat.values.iter().enumerate() {
                let c = self.series_colors.get(si).copied().unwrap_or(Color::WHITE);
                let cr = (c.r * 255.0) as u8;
                let cg = (c.g * 255.0) as u8;
                let cb = (c.b * 255.0) as u8;
                let bh = (val / self.y_max * chart_h) as i32;
                let bx = group_x + 10 + si as i32 * (bar_w + 2);
                img.draw_rect(bx, bottom - bh, bar_w as u32, bh as u32, cr, cg, cb, 255);
                img.draw_label(&format!("{}", val as i32), bx + 2, bottom - bh - 8, lr, lg, lb);
            }
            img.draw_label(&cat.label, group_x + 8, bottom + 6, lr, lg, lb);
        }

    }
}

// ═══════════════════════════════════════════════════════════════════════
// ██  SCATTER PLOT
// ═══════════════════════════════════════════════════════════════════════

/// A configurable scatter plot renderer.
///
/// # Fields
/// - `config` — `ChartConfig`.
/// - `series` — `Vec<ChartSeries>`.
/// - `x_range` — `(f32, f32)`.
/// - `y_range` — `(f32, f32)`.
#[derive(Debug, Clone)]
pub struct ScatterPlot {
    /// Chart configuration.
    pub config: ChartConfig,
    /// Data series to plot.
    pub series: Vec<ChartSeries>,
    /// X axis range `(min, max)`.
    pub x_range: (f32, f32),
    /// Y axis range `(min, max)`.
    pub y_range: (f32, f32),
}

impl ScatterPlot {
    /// Creates a new scatter plot with the given configuration.
    ///
    /// # Parameters
    /// - `config` — `ChartConfig`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(config: ChartConfig) -> Self {
        Self {
            config,
            series: Vec::new(),
            x_range: (0.0, 1.0),
            y_range: (0.0, 1.0),
        }
    }

    /// Adds a named data series to the scatter plot.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `points` — `&[(f32, f32)]`.
    /// - `color` — `Color`.
    pub fn add_series(&mut self, name: &str, points: &[(f32, f32)], color: Color) {
        self.series.push(ChartSeries {
            name: name.to_string(),
            color,
            values: points.to_vec(),
        });
    }

    /// Renders the scatter plot to an `ImageData`.
    ///
    /// # Parameters
    /// - `img` — `&mut crate::image::ImageData`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, mut img: &mut crate::image::ImageData) {
        let cfg = &self.config;
        let (bgr, bgg, bgb) = cfg.bg_color;
        img.fill(bgr, bgg, bgb, 255);

        let (left, right, top, bottom) = draw_grid_and_axes(img, cfg, 5, 5);
        let chart_w = (right - left) as f32;
        let chart_h = (bottom - top) as f32;
        let (lr, lg, lb) = cfg.label_color;

        if let Some(ref title) = cfg.title {
            img.draw_label(title, left + 10, 10, lr, lg, lb);
        }

        let x_span = (self.x_range.1 - self.x_range.0).max(f32::EPSILON);
        let y_span = (self.y_range.1 - self.y_range.0).max(f32::EPSILON);

        for s in &self.series {
            let cr = (s.color.r * 255.0) as u8;
            let cg = (s.color.g * 255.0) as u8;
            let cb = (s.color.b * 255.0) as u8;
            for &(x, y) in &s.values {
                let px = left + ((x - self.x_range.0) / x_span * chart_w) as i32;
                let py = bottom - ((y - self.y_range.0) / y_span * chart_h) as i32;
                safe_circle(img, px, py, 4, cr, cg, cb, 180);
            }
        }

    }
}

// ═══════════════════════════════════════════════════════════════════════
// ██  PIE CHART
// ═══════════════════════════════════════════════════════════════════════

/// A segment in a pie chart.
///
/// # Fields
/// - `label` — `String`.
/// - `value` — `f32`.
/// - `color` — `Color`.
#[derive(Debug, Clone)]
pub struct PieSegment {
    /// Segment label.
    pub label: String,
    /// Segment value (proportion computed automatically).
    pub value: f32,
    /// Segment fill colour.
    pub color: Color,
}

/// A configurable pie chart renderer.
///
/// # Fields
/// - `config` — `ChartConfig`.
/// - `segments` — `Vec<PieSegment>`.
#[derive(Debug, Clone)]
pub struct PieChart {
    /// Chart configuration.
    pub config: ChartConfig,
    /// Pie segments.
    pub segments: Vec<PieSegment>,
}

impl PieChart {
    /// Creates a new pie chart with the given configuration.
    ///
    /// # Parameters
    /// - `config` — `ChartConfig`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(config: ChartConfig) -> Self {
        Self {
            config,
            segments: Vec::new(),
        }
    }

    /// Adds a labelled segment to the pie chart.
    ///
    /// # Parameters
    /// - `label` — `&str`.
    /// - `value` — `f32`.
    /// - `color` — `Color`.
    pub fn add_segment(&mut self, label: &str, value: f32, color: Color) {
        self.segments.push(PieSegment {
            label: label.to_string(),
            value,
            color,
        });
    }

    /// Renders the pie chart to an `ImageData`.
    ///
    /// # Parameters
    /// - `img` — `&mut crate::image::ImageData`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, img: &mut crate::image::ImageData) {
        let cfg = &self.config;
        let w = cfg.width;
        let h = cfg.height;
        let (bgr, bgg, bgb) = cfg.bg_color;
        img.fill(bgr, bgg, bgb, 255);

        let total: f32 = self.segments.iter().map(|s| s.value).sum();
        if total <= 0.0 {
            return;
        }

        let cx = (w as f32) * 0.45;
        let cy = (h as f32) * 0.5;
        let radius = (w.min(h) as f32) * 0.325;

        let mut angle = -std::f32::consts::FRAC_PI_2;

        for seg in &self.segments {
            let pct = seg.value / total;
            let sweep = pct * 2.0 * std::f32::consts::PI;
            let end_angle = angle + sweep;

            let cr = (seg.color.r * 255.0) as u8;
            let cg = (seg.color.g * 255.0) as u8;
            let cb = (seg.color.b * 255.0) as u8;

            // Fill segment pixel by pixel
            for py in 0..h {
                for px in 0..w {
                    let dx = px as f32 - cx;
                    let dy = py as f32 - cy;
                    let dist = (dx * dx + dy * dy).sqrt();
                    if dist > radius {
                        continue;
                    }
                    let mut a = dy.atan2(dx);
                    if a < -std::f32::consts::FRAC_PI_2 {
                        a += 2.0 * std::f32::consts::PI;
                    }
                    let mut check_a = a;
                    if check_a < angle {
                        check_a += 2.0 * std::f32::consts::PI;
                    }
                    let mut check_end = end_angle;
                    if check_end < angle {
                        check_end += 2.0 * std::f32::consts::PI;
                    }
                    if check_a >= angle && check_a < check_end {
                        let edge_factor = if dist > radius - 3.0 { 0.7f32 } else { 1.0 };
                        img.set_pixel(
                            px,
                            py,
                            (cr as f32 * edge_factor) as u8,
                            (cg as f32 * edge_factor) as u8,
                            (cb as f32 * edge_factor) as u8,
                            255,
                        );
                    }
                }
            }
            angle = end_angle;
        }

        // Divider lines
        angle = -std::f32::consts::FRAC_PI_2;
        for seg in &self.segments {
            let sweep = seg.value / total * 2.0 * std::f32::consts::PI;
            let lx = cx + angle.cos() * radius;
            let ly = cy + angle.sin() * radius;
            img.draw_line(cx as i32, cy as i32, lx as i32, ly as i32, 255, 255, 255, 255);
            angle += sweep;
        }

        // Legend on the right
        let mut label_y = 60i32;
        let (lr, lg, lb) = cfg.label_color;
        for seg in &self.segments {
            let cr = (seg.color.r * 255.0) as u8;
            let cg = (seg.color.g * 255.0) as u8;
            let cb = (seg.color.b * 255.0) as u8;
            let legend_x = (w as f32 * 0.8) as i32;
            img.draw_rect(legend_x, label_y, 12, 8, cr, cg, cb, 255);
            img.draw_label(&seg.label, legend_x + 16, label_y + 2, lr, lg, lb);
            label_y += 14;
        }

        if let Some(ref title) = cfg.title {
            img.draw_label(title, 10, 10, lr, lg, lb);
        }

    }
}

// ═══════════════════════════════════════════════════════════════════════
// ██  AREA CHART
// ═══════════════════════════════════════════════════════════════════════

/// A configurable stacked area chart renderer.
///
/// # Fields
/// - `config` — `ChartConfig`.
/// - `layers` — `Vec<AreaLayer>`.
/// - `y_max` — `f32`.
#[derive(Debug, Clone)]
pub struct AreaChart {
    /// Chart configuration.
    pub config: ChartConfig,
    /// Stacked layers (rendered bottom-to-top).
    pub layers: Vec<AreaLayer>,
    /// Maximum Y value for scaling.
    pub y_max: f32,
}

/// A single layer in an area chart.
///
/// # Fields
/// - `name` — `String`.
/// - `values` — `Vec<f32>`.
/// - `color` — `Color`.
#[derive(Debug, Clone)]
pub struct AreaLayer {
    /// Layer name for legend display.
    pub name: String,
    /// Data values (one per X sample).
    pub values: Vec<f32>,
    /// Fill colour.
    pub color: Color,
}

impl AreaChart {
    /// Creates a new area chart with the given configuration.
    ///
    /// # Parameters
    /// - `config` — `ChartConfig`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(config: ChartConfig) -> Self {
        Self {
            config,
            layers: Vec::new(),
            y_max: 100.0,
        }
    }

    /// Adds a stacked layer to the area chart.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `values` — `&[f32]`.
    /// - `color` — `Color`.
    pub fn add_layer(&mut self, name: &str, values: &[f32], color: Color) {
        self.layers.push(AreaLayer {
            name: name.to_string(),
            values: values.to_vec(),
            color,
        });
    }

    /// Renders the stacked area chart to an `ImageData`.
    ///
    /// # Parameters
    /// - `img` — `&mut crate::image::ImageData`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, img: &mut crate::image::ImageData) {
        let cfg = &self.config;
        let (bgr, bgg, bgb) = cfg.bg_color;
        img.fill(bgr, bgg, bgb, 255);

        let (left, right, top, bottom) = draw_grid_and_axes(img, cfg, 6, 4);
        let chart_w = (right - left) as f32;
        let chart_h = (bottom - top) as f32;

        if self.layers.is_empty() {
            return;
        }

        let n = self.layers[0].values.len().max(2);

        // For each x pixel, compute cumulative stack
        for x_px in left..right {
            let t = (x_px - left) as f32 / chart_w;
            let idx_f = t * (n - 1) as f32;
            let idx0 = (idx_f as usize).min(n.saturating_sub(2));
            let frac = idx_f - idx0 as f32;

            let mut cumulative = 0.0f32;
            let mut prev_y = bottom;

            for layer in &self.layers {
                let v0 = layer.values.get(idx0).copied().unwrap_or(0.0);
                let v1 = layer.values.get(idx0 + 1).copied().unwrap_or(v0);
                let val = v0 + (v1 - v0) * frac;
                cumulative += val;

                let cur_y = bottom - (cumulative / self.y_max * chart_h) as i32;
                let cr = (layer.color.r * 255.0) as u8;
                let cg = (layer.color.g * 255.0) as u8;
                let cb = (layer.color.b * 255.0) as u8;

                for y_px in cur_y.max(top)..prev_y {
                    img.set_pixel(x_px as u32, y_px as u32, cr, cg, cb, 220);
                }
                prev_y = cur_y;
            }
        }

        // Legend
        let (lr, lg, lb) = cfg.label_color;
        for (i, layer) in self.layers.iter().enumerate() {
            let ly = 10 + i as i32 * 10;
            let cr = (layer.color.r * 255.0) as u8;
            let cg = (layer.color.g * 255.0) as u8;
            let cb = (layer.color.b * 255.0) as u8;
            img.draw_rect(right - 90, ly, 10, 6, cr, cg, cb, 255);
            img.draw_label(&layer.name, right - 76, ly + 1, lr, lg, lb);
        }

        if let Some(ref title) = cfg.title {
            img.draw_label(title, left + 10, 10, lr, lg, lb);
        }

    }
}
