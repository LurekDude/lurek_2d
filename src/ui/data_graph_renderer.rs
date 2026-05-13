use crate::math::Color;
use std::collections::HashMap;
#[derive(Debug, Clone)]
pub enum GraphSeries {
    Line {
        name: String,
        points: Vec<(f64, f64)>,
        color: Color,
    },
    Scatter {
        name: String,
        points: Vec<(f64, f64)>,
        color: Color,
        size: f32,
    },
    Bar {
        name: String,
        values: Vec<f64>,
        color: Color,
    },
}
impl GraphSeries {
    pub fn name(&self) -> &str {
        match self {
            GraphSeries::Line { name, .. } => name,
            GraphSeries::Scatter { name, .. } => name,
            GraphSeries::Bar { name, .. } => name,
        }
    }
}
pub struct GraphRenderer {
    pub viewport: (f32, f32, f32, f32),
    pub range: (f64, f64, f64, f64),
    series: HashMap<String, GraphSeries>,
    pub show_grid: bool,
    pub show_axes: bool,
    pub show_labels: bool,
    pub grid_color: Color,
    pub axis_color: Color,
    pub bg_color: Color,
    pub title: Option<String>,
    pub x_label: Option<String>,
    pub y_label: Option<String>,
    pub cursor: Option<(f64, f64)>,
}
impl GraphRenderer {
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
    pub fn set_viewport(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport = (x, y, w, h);
    }
    pub fn get_viewport(&self) -> (f32, f32, f32, f32) {
        self.viewport
    }
    pub fn set_range(&mut self, x_min: f64, x_max: f64, y_min: f64, y_max: f64) {
        self.range = (x_min, x_max, y_min, y_max);
    }
    pub fn get_range(&self) -> (f64, f64, f64, f64) {
        self.range
    }
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
    pub fn add_line_series(&mut self, name: &str, points: Vec<(f64, f64)>, color: Color) {
        let s = GraphSeries::Line {
            name: name.to_string(),
            points,
            color,
        };
        self.series.insert(name.to_string(), s);
    }
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
    pub fn add_bar_series(&mut self, name: &str, values: Vec<f64>, color: Color) {
        let s = GraphSeries::Bar {
            name: name.to_string(),
            values,
            color,
        };
        self.series.insert(name.to_string(), s);
    }
    pub fn remove_series(&mut self, name: &str) -> bool {
        self.series.remove(name).is_some()
    }
    pub fn clear_series(&mut self) {
        self.series.clear();
    }
    pub fn get_series_names(&self) -> Vec<String> {
        self.series.keys().cloned().collect()
    }
    pub fn series(&self) -> &HashMap<String, GraphSeries> {
        &self.series
    }
    pub fn set_show_grid(&mut self, b: bool) {
        self.show_grid = b;
    }
    pub fn set_show_axes(&mut self, b: bool) {
        self.show_axes = b;
    }
    pub fn set_show_labels(&mut self, b: bool) {
        self.show_labels = b;
    }
    pub fn set_grid_color(&mut self, c: Color) {
        self.grid_color = c;
    }
    pub fn set_axis_color(&mut self, c: Color) {
        self.axis_color = c;
    }
    pub fn set_bg_color(&mut self, c: Color) {
        self.bg_color = c;
    }
    pub fn set_title(&mut self, text: &str) {
        self.title = Some(text.to_string());
    }
    pub fn set_axis_labels(&mut self, x_label: &str, y_label: &str) {
        self.x_label = Some(x_label.to_string());
        self.y_label = Some(y_label.to_string());
    }
    pub fn set_cursor_position(&mut self, x: f64, y: f64) {
        self.cursor = Some((x, y));
    }
    pub fn get_cursor_value(&self) -> Option<(f64, f64)> {
        self.cursor
    }
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
