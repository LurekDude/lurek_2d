//! Chart rendering helpers for `lurek.ui` — rasterises line, bar, scatter, pie, and area
//! charts into `ImageData` pixels. Does not own the UI layout tree or rendering pipeline;
//! callers request a rendered `ImageData` and hand it to the sprite system.
//! Feature-gated behind `ui-charts`; depends on `crate::image::ImageData` and `crate::math::color`.

use crate::image::ImageData;
use crate::math::color::Color;

/// Global configuration shared by all chart types; controls dimensions, colours, title, and margins.
#[derive(Debug, Clone)]
pub struct ChartConfig {
    /// Pixel width of the rendered image.
    pub width: u32,
    /// Pixel height of the rendered image.
    pub height: u32,
    /// Optional title string drawn at the top of the chart.
    pub title: Option<String>,
    /// Background fill colour as (R, G, B).
    pub bg_color: (u8, u8, u8),
    /// Axis line colour as (R, G, B).
    pub axis_color: (u8, u8, u8),
    /// Grid line colour as (R, G, B).
    pub grid_color: (u8, u8, u8),
    /// Axis label text colour as (R, G, B).
    pub label_color: (u8, u8, u8),
    /// Whether to draw grid lines behind the chart data.
    pub show_grid: bool,
    /// Pixel margins between the chart border and the drawable area.
    pub margin: ChartMargin,
}
/// Pixel margins inset from each edge of the image to the chart drawing area.
#[derive(Debug, Clone, Copy)]
pub struct ChartMargin {
    /// Pixels reserved on the left edge for Y-axis labels.
    pub left: i32,
    /// Pixels reserved on the right edge.
    pub right: i32,
    /// Pixels reserved at the top for the chart title.
    pub top: i32,
    /// Pixels reserved at the bottom for X-axis labels.
    pub bottom: i32,
}
/// Provide sensible default margins (left=40, right=20, top=30, bottom=40).
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
/// Provide a 400×300 chart config with neutral colours and grid enabled.
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
/// A named (x, y) data series with an associated colour for line/scatter charts.
#[derive(Debug, Clone)]
pub struct ChartSeries {
    /// Display name used in the chart legend.
    pub name: String,
    /// Series line/point colour.
    pub color: Color,
    /// Ordered (x, y) data points.
    pub values: Vec<(f32, f32)>,
}
/// Draw grid lines and axis borders; return `(left, right, top, bottom)` pixel boundaries of the chart area.
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
    img.draw_line(left, top, left, bottom, ar, ag, ab, 255);
    img.draw_line(left, bottom, right, bottom, ar, ag, ab, 255);
    (left, right, top, bottom)
}
/// Convert a `Color` (float components [0,1]) to an `(R, G, B)` u8 tuple.
fn to_rgb(color: Color) -> (u8, u8, u8) {
    (
        (color.r * 255.0) as u8,
        (color.g * 255.0) as u8,
        (color.b * 255.0) as u8,
    )
}
/// Draw tick marks and numeric labels on both axes using the supplied value ranges.
#[allow(clippy::too_many_arguments)]
fn draw_numeric_axes(
    img: &mut ImageData,
    cfg: &ChartConfig,
    left: i32,
    right: i32,
    top: i32,
    bottom: i32,
    x_ticks: u32,
    y_ticks: u32,
    x_min: f32,
    x_max: f32,
    y_min: f32,
    y_max: f32,
) {
    let x_ticks = x_ticks.max(1);
    let y_ticks = y_ticks.max(1);
    let chart_w = (right - left) as f32;
    let chart_h = (bottom - top) as f32;
    let (lr, lg, lb) = cfg.label_color;
    for i in 0..=x_ticks {
        let x = left + (i as f32 * chart_w / x_ticks as f32) as i32;
        let v = x_min + (x_max - x_min) * (i as f32 / x_ticks as f32);
        img.draw_line(x, bottom, x, bottom + 4, lr, lg, lb, 255);
        img.draw_label(&format!("{v:.1}"), x - 10, bottom + 8, lr, lg, lb);
    }
    for i in 0..=y_ticks {
        let y = bottom - (i as f32 * chart_h / y_ticks as f32) as i32;
        let v = y_min + (y_max - y_min) * (i as f32 / y_ticks as f32);
        img.draw_line(left - 4, y, left, y, lr, lg, lb, 255);
        img.draw_label(&format!("{v:.1}"), 4, y - 3, lr, lg, lb);
    }
    img.draw_label("X", right + 6, bottom - 4, lr, lg, lb);
    img.draw_label("Y", left - 12, top - 14, lr, lg, lb);
}
/// Draw a floating colour-swatch legend box inside the chart area near the top-right corner.
fn draw_series_legend(
    img: &mut ImageData,
    cfg: &ChartConfig,
    right: i32,
    top: i32,
    entries: &[(&str, Color)],
) {
    if entries.is_empty() {
        return;
    }
    let panel_w = 116i32;
    let panel_h = (entries.len() as i32 * 14 + 10).max(22);
    let panel_x = right - panel_w;
    let panel_y = top + 6;
    img.draw_rect(
        panel_x,
        panel_y,
        panel_w as u32,
        panel_h as u32,
        250,
        250,
        252,
        230,
    );
    img.draw_rect(panel_x, panel_y, panel_w as u32, 1, 170, 176, 188, 255);
    img.draw_rect(
        panel_x,
        panel_y + panel_h - 1,
        panel_w as u32,
        1,
        170,
        176,
        188,
        255,
    );
    img.draw_rect(panel_x, panel_y, 1, panel_h as u32, 170, 176, 188, 255);
    img.draw_rect(
        panel_x + panel_w - 1,
        panel_y,
        1,
        panel_h as u32,
        170,
        176,
        188,
        255,
    );
    let (lr, lg, lb) = cfg.label_color;
    for (idx, (name, color)) in entries.iter().enumerate() {
        let y = panel_y + 6 + idx as i32 * 14;
        let (cr, cg, cb) = to_rgb(*color);
        img.draw_rect(panel_x + 6, y, 10, 8, cr, cg, cb, 255);
        img.draw_label(name, panel_x + 20, y + 1, lr, lg, lb);
    }
}
/// Draw the chart title string at pixel position `(x, y)` if one is set in `cfg`.
fn draw_chart_title(img: &mut ImageData, cfg: &ChartConfig, x: i32, y: i32) {
    if let Some(ref title) = cfg.title {
        let (lr, lg, lb) = cfg.label_color;
        img.draw_label(title, x, y, lr, lg, lb);
    }
}
/// Build legend `(name, color)` pairs from a slice of `ChartSeries`.
fn legend_entries_from_series(series: &[ChartSeries]) -> Vec<(&str, Color)> {
    series.iter().map(|s| (s.name.as_str(), s.color)).collect()
}
/// Build legend `(name, color)` pairs by zipping name strings and colour slices.
fn legend_entries_from_names<'a>(names: &'a [String], colors: &[Color]) -> Vec<(&'a str, Color)> {
    names
        .iter()
        .zip(colors.iter().copied())
        .map(|(name, c)| (name.as_str(), c))
        .collect()
}
/// Build legend `(name, color)` pairs from a slice of `AreaLayer` entries.
fn legend_entries_from_layers(layers: &[AreaLayer]) -> Vec<(&str, Color)> {
    layers.iter().map(|l| (l.name.as_str(), l.color)).collect()
}
/// Build legend `(label, color)` pairs from a slice of `PieSegment` entries.
fn legend_entries_from_segments(segments: &[PieSegment]) -> Vec<(&str, Color)> {
    segments
        .iter()
        .map(|seg| (seg.label.as_str(), seg.color))
        .collect()
}
/// Draw a filled circle of radius `r` centred at `(cx, cy)`, clamped to image bounds.
#[allow(clippy::too_many_arguments)]
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
/// Cartesian line chart that draws one or more `ChartSeries` as polylines with data-point dots.
#[derive(Debug, Clone)]
pub struct LineChart {
    /// Shared configuration (dimensions, colours, title, margins).
    pub config: ChartConfig,
    /// All data series to render.
    pub series: Vec<ChartSeries>,
    /// Maximum Y value; used to normalise series values into the chart area.
    pub y_max: f32,
    /// Maximum X value; used to normalise series values into the chart area.
    pub x_max: f32,
}
impl LineChart {
    /// Create a new line chart with the given config and default Y/X range of 100.0/6.0.
    pub fn new(config: ChartConfig) -> Self {
        Self {
            config,
            series: Vec::new(),
            y_max: 100.0,
            x_max: 6.0,
        }
    }
    /// Append a named data series of `(x, y)` points with the given colour.
    pub fn add_series(&mut self, name: &str, points: &[(f32, f32)], color: Color) {
        self.series.push(ChartSeries {
            name: name.to_string(),
            color,
            values: points.to_vec(),
        });
    }
    /// Rasterise the line chart into `img`, overwriting its contents.
    pub fn draw_to_image(&self, img: &mut crate::image::ImageData) {
        let cfg = &self.config;
        let (bgr, bgg, bgb) = cfg.bg_color;
        img.fill(bgr, bgg, bgb, 255);
        let x_div = self.x_max.ceil() as u32;
        let (left, right, top, bottom) = draw_grid_and_axes(img, cfg, x_div.max(1), 5);
        let chart_w = (right - left) as f32;
        let chart_h = (bottom - top) as f32;
        draw_numeric_axes(
            img,
            cfg,
            left,
            right,
            top,
            bottom,
            x_div.max(1),
            5,
            0.0,
            self.x_max,
            0.0,
            self.y_max,
        );
        draw_chart_title(img, cfg, left + 10, 10);
        let legend_entries = legend_entries_from_series(&self.series);
        draw_series_legend(img, cfg, right, top, &legend_entries);
        for s in &self.series {
            let (cr, cg, cb) = to_rgb(s.color);
            for i in 1..s.values.len() {
                let x0 = left + (s.values[i - 1].0 / self.x_max * chart_w) as i32;
                let y0 = bottom - (s.values[i - 1].1 / self.y_max * chart_h) as i32;
                let x1 = left + (s.values[i].0 / self.x_max * chart_w) as i32;
                let y1 = bottom - (s.values[i].1 / self.y_max * chart_h) as i32;
                img.draw_line(x0, y0, x1, y1, cr, cg, cb, 255);
                img.draw_line(x0, y0 + 1, x1, y1 + 1, cr, cg, cb, 255);
            }
            for pt in &s.values {
                let x = left + (pt.0 / self.x_max * chart_w) as i32;
                let y = bottom - (pt.1 / self.y_max * chart_h) as i32;
                safe_circle(img, x, y, 3, cr, cg, cb, 255);
            }
        }
    }
}
/// One labelled category (group of bars) in a `BarChart`.
#[derive(Debug, Clone)]
pub struct BarCategory {
    /// X-axis label displayed below this group.
    pub label: String,
    /// One value per series in this category; parallel to `BarChart::series_colors`.
    pub values: Vec<f32>,
}
/// Grouped bar chart with named series and labelled categories.
#[derive(Debug, Clone)]
pub struct BarChart {
    /// Shared configuration.
    pub config: ChartConfig,
    /// All category groups, each containing one value per series.
    pub categories: Vec<BarCategory>,
    /// Colours for each series; parallel to `series_names`.
    pub series_colors: Vec<Color>,
    /// Display names for each series; parallel to `series_colors`.
    pub series_names: Vec<String>,
    /// Maximum Y value used to normalise bar heights.
    pub y_max: f32,
}
impl BarChart {
    /// Create an empty bar chart with the given config and default Y max of 100.0.
    pub fn new(config: ChartConfig) -> Self {
        Self {
            config,
            categories: Vec::new(),
            series_colors: Vec::new(),
            series_names: Vec::new(),
            y_max: 100.0,
        }
    }
    /// Register a named series with the given colour; call before `add_category`.
    pub fn add_series(&mut self, name: &str, color: Color) {
        self.series_names.push(name.to_string());
        self.series_colors.push(color);
    }
    /// Add a labelled category group with one value per series.
    pub fn add_category(&mut self, label: &str, values: &[f32]) {
        self.categories.push(BarCategory {
            label: label.to_string(),
            values: values.to_vec(),
        });
    }
    /// Rasterise the bar chart into `img`, overwriting its contents.
    pub fn draw_to_image(&self, img: &mut crate::image::ImageData) {
        let cfg = &self.config;
        let (bgr, bgg, bgb) = cfg.bg_color;
        img.fill(bgr, bgg, bgb, 255);
        let (left, right, top, bottom) =
            draw_grid_and_axes(img, cfg, self.categories.len() as u32, 5);
        let chart_h = (bottom - top) as f32;
        let (lr, lg, lb) = cfg.label_color;
        draw_numeric_axes(
            img,
            cfg,
            left,
            right,
            top,
            bottom,
            self.categories.len() as u32,
            5,
            0.0,
            self.categories.len().max(1) as f32,
            0.0,
            self.y_max,
        );
        draw_chart_title(img, cfg, left + 10, 10);
        let legend_entries = legend_entries_from_names(&self.series_names, &self.series_colors);
        draw_series_legend(img, cfg, right, top, &legend_entries);
        let n_series = self.series_colors.len().max(1);
        let n_cats = self.categories.len().max(1);
        let group_w = (right - left) / n_cats as i32;
        let bar_w = (group_w / (n_series as i32 + 1)).max(4);
        for (ci, cat) in self.categories.iter().enumerate() {
            let group_x = left + ci as i32 * group_w;
            for (si, &val) in cat.values.iter().enumerate() {
                let c = self.series_colors.get(si).copied().unwrap_or(Color::WHITE);
                let (cr, cg, cb) = to_rgb(c);
                let bh = (val / self.y_max * chart_h) as i32;
                let bx = group_x + 10 + si as i32 * (bar_w + 2);
                img.draw_rect(bx, bottom - bh, bar_w as u32, bh as u32, cr, cg, cb, 255);
                img.draw_label(
                    &format!("{}", val as i32),
                    bx + 2,
                    bottom - bh - 8,
                    lr,
                    lg,
                    lb,
                );
            }
            img.draw_label(&cat.label, group_x + 8, bottom + 6, lr, lg, lb);
        }
    }
}
/// Cartesian scatter plot that renders each data point as a filled circle.
#[derive(Debug, Clone)]
pub struct ScatterPlot {
    /// Shared configuration.
    pub config: ChartConfig,
    /// All data series to render.
    pub series: Vec<ChartSeries>,
    /// Visible (min, max) range on the X axis.
    pub x_range: (f32, f32),
    /// Visible (min, max) range on the Y axis.
    pub y_range: (f32, f32),
}
impl ScatterPlot {
    /// Create an empty scatter plot with the given config and default axis ranges of (0.0, 1.0).
    pub fn new(config: ChartConfig) -> Self {
        Self {
            config,
            series: Vec::new(),
            x_range: (0.0, 1.0),
            y_range: (0.0, 1.0),
        }
    }
    /// Append a named series of `(x, y)` scatter points with the given colour.
    pub fn add_series(&mut self, name: &str, points: &[(f32, f32)], color: Color) {
        self.series.push(ChartSeries {
            name: name.to_string(),
            color,
            values: points.to_vec(),
        });
    }
    /// Rasterise the scatter plot into `img`, overwriting its contents.
    pub fn draw_to_image(&self, img: &mut crate::image::ImageData) {
        let cfg = &self.config;
        let (bgr, bgg, bgb) = cfg.bg_color;
        img.fill(bgr, bgg, bgb, 255);
        let (left, right, top, bottom) = draw_grid_and_axes(img, cfg, 5, 5);
        let chart_w = (right - left) as f32;
        let chart_h = (bottom - top) as f32;
        draw_numeric_axes(
            img,
            cfg,
            left,
            right,
            top,
            bottom,
            5,
            5,
            self.x_range.0,
            self.x_range.1,
            self.y_range.0,
            self.y_range.1,
        );
        draw_chart_title(img, cfg, left + 10, 10);
        let legend_entries = legend_entries_from_series(&self.series);
        draw_series_legend(img, cfg, right, top, &legend_entries);
        let x_span = (self.x_range.1 - self.x_range.0).max(f32::EPSILON);
        let y_span = (self.y_range.1 - self.y_range.0).max(f32::EPSILON);
        for s in &self.series {
            let (cr, cg, cb) = to_rgb(s.color);
            for &(x, y) in &s.values {
                let px = left + ((x - self.x_range.0) / x_span * chart_w) as i32;
                let py = bottom - ((y - self.y_range.0) / y_span * chart_h) as i32;
                safe_circle(img, px, py, 4, cr, cg, cb, 180);
            }
        }
    }
}
/// One labelled segment of a `PieChart`.
#[derive(Debug, Clone)]
pub struct PieSegment {
    /// Legend label for this segment.
    pub label: String,
    /// Numerical value; the fraction rendered is `value / total`.
    pub value: f32,
    /// Fill colour for this segment.
    pub color: Color,
}
/// Pie chart that rasterises coloured wedge segments into a pixel image.
#[derive(Debug, Clone)]
pub struct PieChart {
    /// Shared configuration (dimensions, colours, title).
    pub config: ChartConfig,
    /// Ordered segments; rendered clockwise starting from the top.
    pub segments: Vec<PieSegment>,
}
impl PieChart {
    /// Create an empty pie chart with the given config.
    pub fn new(config: ChartConfig) -> Self {
        Self {
            config,
            segments: Vec::new(),
        }
    }
    /// Append a labelled segment with the given value and fill colour.
    pub fn add_segment(&mut self, label: &str, value: f32, color: Color) {
        self.segments.push(PieSegment {
            label: label.to_string(),
            value,
            color,
        });
    }
    /// Rasterise the pie chart into `img`, overwriting its contents; no-ops when total value <= 0.
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
        angle = -std::f32::consts::FRAC_PI_2;
        for seg in &self.segments {
            let sweep = seg.value / total * 2.0 * std::f32::consts::PI;
            let lx = cx + angle.cos() * radius;
            let ly = cy + angle.sin() * radius;
            img.draw_line(
                cx as i32, cy as i32, lx as i32, ly as i32, 255, 255, 255, 255,
            );
            angle += sweep;
        }
        let (lr, lg, lb) = cfg.label_color;
        let legend_entries = legend_entries_from_segments(&self.segments);
        draw_series_legend(img, cfg, w as i32 - 10, 40, &legend_entries);
        let mut label_y = 44i32;
        let legend_x = (w as f32 * 0.72) as i32;
        for seg in &self.segments {
            let pct = seg.value / total * 100.0;
            img.draw_label(&format!("{pct:.1}%"), legend_x + 76, label_y, lr, lg, lb);
            label_y += 14;
        }
        draw_chart_title(img, cfg, 10, 10);
    }
}
/// Stacked area chart where each layer fills from its own cumulative base upward.
#[derive(Debug, Clone)]
pub struct AreaChart {
    /// Shared configuration.
    pub config: ChartConfig,
    /// Ordered area layers drawn from bottom to top; stacked cumulatively.
    pub layers: Vec<AreaLayer>,
    /// Total Y axis maximum used to normalise layer values.
    pub y_max: f32,
}
/// One named value series rendered as a filled area in an `AreaChart`.
#[derive(Debug, Clone)]
pub struct AreaLayer {
    /// Display name used in the chart legend.
    pub name: String,
    /// Y values sampled at uniform X intervals.
    pub values: Vec<f32>,
    /// Fill colour for the area region.
    pub color: Color,
}
impl AreaChart {
    /// Create an empty area chart with the given config and Y max of 100.0.
    pub fn new(config: ChartConfig) -> Self {
        Self {
            config,
            layers: Vec::new(),
            y_max: 100.0,
        }
    }
    /// Append a named area layer; `values` are sampled at uniform X intervals across the chart width.
    pub fn add_layer(&mut self, name: &str, values: &[f32], color: Color) {
        self.layers.push(AreaLayer {
            name: name.to_string(),
            values: values.to_vec(),
            color,
        });
    }
    /// Rasterise the stacked area chart into `img`, overwriting its contents.
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
        draw_numeric_axes(
            img,
            cfg,
            left,
            right,
            top,
            bottom,
            (n as u32).min(8),
            4,
            0.0,
            (n - 1) as f32,
            0.0,
            self.y_max,
        );
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
        let legend_entries = legend_entries_from_layers(&self.layers);
        draw_series_legend(img, cfg, right, top, &legend_entries);
        draw_chart_title(img, cfg, left + 10, 10);
    }
}
