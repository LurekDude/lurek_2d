//! Trail renderer for fading ribbon effects.
//!
//! Stores a series of timestamped points that age out over a configurable
//! lifetime, producing a tapered ribbon from head to tail.
//!
//! This module is part of Lurek2D's `graphics` subsystem and provides the implementation
//! details for trail-related operations and data management.
//! Key types exported from this module: `TrailPoint`, `Trail`.
//! Primary functions: `new()`, `push_point()`, `update()`, `set_width()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::math::Color;
use crate::render::renderer::{DrawMode, RenderCommand};

/// A point in a trail with age tracking.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `age` — `f32`.
#[derive(Debug, Clone)]
pub struct TrailPoint {
    /// X position in world space.
    pub x: f32,
    /// Y position in world space.
    pub y: f32,
    /// How long this point has existed (seconds).
    pub age: f32,
}

/// Fading textured ribbon renderer.
///
/// # Fields
/// - `points` — `Vec<TrailPoint>`.
/// - `lifetime` — `f32`.
/// - `start_width` — `f32`.
/// - `end_width` — `f32`.
/// - `head_color` — `Color`.
/// - `tail_color` — `Color`.
/// - `min_distance` — `f32`.
///
/// Points are pushed at the head and automatically removed once their
/// age exceeds the configured lifetime. Width tapers linearly from
/// `start_width` at the head to `end_width` at the tail.
pub struct Trail {
    /// Ordered list of trail points (newest first).
    pub points: Vec<TrailPoint>,
    /// Maximum age (seconds) before a point is removed.
    pub lifetime: f32,
    /// Width of the ribbon at the head (newest point).
    pub start_width: f32,
    /// Width of the ribbon at the tail (oldest point).
    pub end_width: f32,
    /// Color at the head of the trail.
    pub head_color: Color,
    /// Color at the tail of the trail.
    pub tail_color: Color,
    /// Minimum distance a new point must be from the last point to be added.
    pub min_distance: f32,
}

impl Trail {
    /// Creates a new trail with the given lifetime and starting width.
    ///
    /// # Parameters
    /// - `lifetime` — `f32`.
    /// - `start_width` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Defaults: end_width = 0.0, colors = white, min_distance = 1.0.
    pub fn new(lifetime: f32, start_width: f32) -> Self {
        Self {
            points: Vec::new(),
            lifetime,
            start_width,
            end_width: 0.0,
            head_color: Color::WHITE,
            tail_color: Color::WHITE,
            min_distance: 1.0,
        }
    }

    /// Pushes a new point at the head of the trail.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    ///
    /// The point is only added if the distance from the last point is at
    /// least `min_distance`, or if the trail is empty.
    pub fn push_point(&mut self, x: f32, y: f32) {
        if let Some(last) = self.points.first() {
            let dx = x - last.x;
            let dy = y - last.y;
            if (dx * dx + dy * dy) < self.min_distance * self.min_distance {
                return;
            }
        }
        self.points.insert(0, TrailPoint { x, y, age: 0.0 });
    }

    /// Advances point ages by `dt` seconds and removes expired points.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    pub fn update(&mut self, dt: f32) {
        for point in &mut self.points {
            point.age += dt;
        }
        self.points.retain(|p| p.age < self.lifetime);
    }

    /// Sets the ribbon width. If `end` is `None`, the tail width is unchanged.
    ///
    /// # Parameters
    /// - `start` — `f32`.
    /// - `end` — `Option<f32>`.
    pub fn set_width(&mut self, start: f32, end: Option<f32>) {
        self.start_width = start;
        if let Some(e) = end {
            self.end_width = e;
        }
    }

    /// Sets the maximum point lifetime in seconds.
    ///
    /// # Parameters
    /// - `lifetime` — `f32`.
    pub fn set_lifetime(&mut self, lifetime: f32) {
        self.lifetime = lifetime;
    }

    /// Returns the maximum point lifetime in seconds.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_lifetime(&self) -> f32 {
        self.lifetime
    }

    /// Sets the minimum distance a new point must be from the last one.
    ///
    /// # Parameters
    /// - `distance` — `f32`.
    pub fn set_min_distance(&mut self, distance: f32) {
        self.min_distance = distance;
    }

    /// Removes all trail points. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.points.clear();
    }

    /// Returns the current number of trail points.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_point_count(&self) -> usize {
        self.points.len()
    }

    /// Returns the ribbon width as `(start_width, end_width)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_width(&self) -> (f32, f32) {
        (self.start_width, self.end_width)
    }

    /// Sets the color at the head (newest) end of the trail.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_head_color(&mut self, color: Color) {
        self.head_color = color;
    }

    /// Sets the color at the tail (oldest) end of the trail.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_tail_color(&mut self, color: Color) {
        self.tail_color = color;
    }

    /// Generates render commands to draw the trail as a tapered quad strip.
    ///
    /// Each segment between consecutive points is rendered as two filled
    /// triangles forming a quad. Width tapers from `start_width` at the
    /// head to `end_width` at the tail. Color interpolates from
    /// `head_color` to `tail_color` based on point age.
    ///
    /// # Returns
    /// `Vec<RenderCommand>` — empty if fewer than 2 points.
    pub fn build_render_commands(&self) -> Vec<RenderCommand> {
        if self.points.len() < 2 {
            return Vec::new();
        }
        let max_age = self.lifetime.max(0.001);
        let mut commands = Vec::with_capacity(self.points.len() * 3);
        for i in 0..self.points.len() - 1 {
            let a = &self.points[i];
            let b = &self.points[i + 1];
            let t_a = (a.age / max_age).clamp(0.0, 1.0);
            let t_b = (b.age / max_age).clamp(0.0, 1.0);
            // Interpolate width
            let w_a = self.start_width + (self.end_width - self.start_width) * t_a;
            let w_b = self.start_width + (self.end_width - self.start_width) * t_b;
            // Interpolate color (use midpoint of segment)
            let t_mid = (t_a + t_b) * 0.5;
            let cr = self.head_color.r + (self.tail_color.r - self.head_color.r) * t_mid;
            let cg = self.head_color.g + (self.tail_color.g - self.head_color.g) * t_mid;
            let cb = self.head_color.b + (self.tail_color.b - self.head_color.b) * t_mid;
            let ca = self.head_color.a + (self.tail_color.a - self.head_color.a) * t_mid;
            // Perpendicular direction for width offset
            let dx = b.x - a.x;
            let dy = b.y - a.y;
            let len = (dx * dx + dy * dy).sqrt().max(0.001);
            let nx = -dy / len;
            let ny = dx / len;
            let hw_a = w_a * 0.5;
            let hw_b = w_b * 0.5;
            // Quad corners
            let ax1 = a.x + nx * hw_a;
            let ay1 = a.y + ny * hw_a;
            let ax2 = a.x - nx * hw_a;
            let ay2 = a.y - ny * hw_a;
            let bx1 = b.x + nx * hw_b;
            let by1 = b.y + ny * hw_b;
            let bx2 = b.x - nx * hw_b;
            let by2 = b.y - ny * hw_b;
            // Emit color + two triangles
            commands.push(RenderCommand::SetColor(cr, cg, cb, ca));
            commands.push(RenderCommand::Triangle {
                mode: DrawMode::Fill,
                x1: ax1, y1: ay1,
                x2: ax2, y2: ay2,
                x3: bx1, y3: by1,
            });
            commands.push(RenderCommand::Triangle {
                mode: DrawMode::Fill,
                x1: ax2, y1: ay2,
                x2: bx2, y2: by2,
                x3: bx1, y3: by1,
            });
        }
        commands
    }

    /// Render the trail ribbon to an image with color interpolation.
    ///
    /// Draws line segments between consecutive points, interpolating
    /// color from `head_color` to `tail_color` based on relative age.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(10, 8, 15, 255);
        if self.points.len() < 2 {
            return img;
        }
        let max_age = self.lifetime.max(0.001);
        for i in 0..self.points.len() - 1 {
            let a = &self.points[i];
            let b = &self.points[i + 1];
            let t = a.age / max_age;
            let hr = self.head_color.r;
            let hg = self.head_color.g;
            let hb = self.head_color.b;
            let tr = self.tail_color.r;
            let tg = self.tail_color.g;
            let tb = self.tail_color.b;
            let r = (hr + (tr - hr) * t) as u8;
            let g = (hg + (tg - hg) * t) as u8;
            let blue = (hb + (tb - hb) * t) as u8;
            let alpha = ((1.0 - t) * 255.0) as u8;
            img.draw_line(
                a.x as i32, a.y as i32,
                b.x as i32, b.y as i32,
                r, g, blue, alpha,
            );
        }
        img
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_trail_no_commands() {
        let trail = Trail::new(1.0, 4.0);
        let cmds = trail.build_render_commands();
        assert!(cmds.is_empty());
    }

    #[test]
    fn single_point_no_commands() {
        let mut trail = Trail::new(1.0, 4.0);
        trail.min_distance = 0.0;
        trail.points.push(TrailPoint { x: 0.0, y: 0.0, age: 0.0 });
        let cmds = trail.build_render_commands();
        assert!(cmds.is_empty());
    }

    #[test]
    fn two_points_produce_three_commands() {
        let mut trail = Trail::new(1.0, 4.0);
        trail.min_distance = 0.0;
        trail.points.push(TrailPoint { x: 0.0, y: 0.0, age: 0.0 });
        trail.points.push(TrailPoint { x: 10.0, y: 0.0, age: 0.5 });
        let cmds = trail.build_render_commands();
        // 1 segment = SetColor + 2 triangles = 3 commands
        assert_eq!(cmds.len(), 3);
        assert!(matches!(cmds[0], RenderCommand::SetColor(..)));
        assert!(matches!(cmds[1], RenderCommand::Triangle { mode: DrawMode::Fill, .. }));
        assert!(matches!(cmds[2], RenderCommand::Triangle { mode: DrawMode::Fill, .. }));
    }

    #[test]
    fn color_interpolation_midpoint() {
        let mut trail = Trail::new(2.0, 4.0);
        trail.head_color = Color::new(1.0, 0.0, 0.0, 1.0);
        trail.tail_color = Color::new(0.0, 1.0, 0.0, 1.0);
        trail.min_distance = 0.0;
        trail.points.push(TrailPoint { x: 0.0, y: 0.0, age: 0.0 });
        trail.points.push(TrailPoint { x: 10.0, y: 0.0, age: 2.0 });
        let cmds = trail.build_render_commands();
        match &cmds[0] {
            RenderCommand::SetColor(r, g, _b, _a) => {
                // Midpoint t=0.5: head(1,0,0) + 0.5*(tail-head) = (0.5, 0.5, 0)
                assert!((r - 0.5).abs() < 1e-5);
                assert!((g - 0.5).abs() < 1e-5);
            }
            other => panic!("Expected SetColor, got {:?}", other),
        }
    }

    #[test]
    fn width_tapering_at_tail() {
        let mut trail = Trail::new(1.0, 10.0);
        trail.end_width = 2.0;
        trail.min_distance = 0.0;
        // Head (age=0) → width 10, tail (age=1) → width 2
        trail.points.push(TrailPoint { x: 0.0, y: 0.0, age: 0.0 });
        trail.points.push(TrailPoint { x: 20.0, y: 0.0, age: 1.0 });
        let cmds = trail.build_render_commands();
        // The triangles should have different y-offsets at head vs tail
        match &cmds[1] {
            RenderCommand::Triangle { y1, y2, .. } => {
                // Head side should be wider (hw=5) than tail side (hw=1)
                assert!((y1.abs() - 5.0).abs() < 1e-5);
                assert!((y2.abs() - 5.0).abs() < 1e-5);
            }
            other => panic!("Expected Triangle, got {:?}", other),
        }
    }
}
