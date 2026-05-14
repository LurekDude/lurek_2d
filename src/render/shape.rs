//! Reusable compound shape type built from a list of `ShapeCommand` draw operations.
//! A `CompoundShape` is stored in the engine shape registry and replayed as part of
//! `RenderCommand::DrawShape`. Contains no GPU state; drawing happens in `GpuRenderer`.

use super::renderer::DrawMode;
/// One drawing operation stored inside a `CompoundShape`.
#[derive(Debug, Clone)]
pub enum ShapeCommand {
    /// Set the active RGBA draw color.
    SetColor(f32, f32, f32, f32),
    /// Set the outline stroke width in pixels.
    SetLineWidth(f32),
    /// Draw a filled or outlined axis-aligned rectangle.
    Rectangle {
        mode: DrawMode,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
    },
    /// Draw a filled or outlined rectangle with rounded corners.
    RoundedRectangle {
        mode: DrawMode,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        rx: f32,
        ry: f32,
    },
    /// Draw a filled or outlined circle.
    Circle {
        mode: DrawMode,
        x: f32,
        y: f32,
        r: f32,
    },
    /// Draw a filled or outlined ellipse.
    Ellipse {
        mode: DrawMode,
        x: f32,
        y: f32,
        rx: f32,
        ry: f32,
    },
    /// Draw a filled or outlined triangle.
    Triangle {
        mode: DrawMode,
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
        x3: f32,
        y3: f32,
    },
    /// Draw a filled or outlined convex polygon from a flat `[x, y, ...]` list.
    Polygon {
        mode: DrawMode,
        vertices: Vec<f32>,
    },
    /// Draw a line segment.
    Line {
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
    },
    /// Draw a polyline from a flat `[x, y, ...]` list.
    Polyline {
        points: Vec<f32>,
    },
    /// Draw a circular arc.
    Arc {
        mode: DrawMode,
        x: f32,
        y: f32,
        radius: f32,
        angle1: f32,
        angle2: f32,
        segments: u32,
    },
}
/// A named, replayable sequence of `ShapeCommand` values stored in the engine shape registry.
#[derive(Clone)]
pub struct CompoundShape {
    /// Ordered list of drawing commands that make up this shape.
    pub commands: Vec<ShapeCommand>,
    /// Most recently set draw color; persisted between replays.
    pub current_color: [f32; 4],
    /// Most recently set line width in pixels.
    pub current_line_width: f32,
}
impl CompoundShape {
    /// Create an empty shape with white color and 1 px line width.
    pub fn new() -> Self {
        Self {
            commands: Vec::new(),
            current_color: [1.0, 1.0, 1.0, 1.0],
            current_line_width: 1.0,
        }
    }
    /// Append a drawing command to this shape.
    pub fn push_command(&mut self, cmd: ShapeCommand) {
        self.commands.push(cmd);
    }
    /// Remove all commands and reset color and line-width to defaults.
    pub fn clear(&mut self) {
        self.commands.clear();
        self.current_color = [1.0, 1.0, 1.0, 1.0];
        self.current_line_width = 1.0;
    }
    /// Return the number of commands in this shape.
    pub fn command_count(&self) -> usize {
        self.commands.len()
    }
}
/// Provide `Default` for `CompoundShape` via `new()`.
impl Default for CompoundShape {
    fn default() -> Self {
        Self::new()
    }
}
