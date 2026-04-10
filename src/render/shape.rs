//! Compound shape builder for multi-primitive vector drawing.
//!
//! This module provides [`CompoundShape`] and [`ShapeCommand`], which together
//! implement an object-space command buffer for vector primitives.  A Lua script
//! builds up a [`CompoundShape`] once, then replays it any number of times via
//! [`crate::render::RenderCommand::DrawShape`] with a per-call affine transform.
//!
//! **Tier position**: Tier 1 (`graphics`).
//! Imports only from within the `graphics` crate-module (`super::renderer`).
//! No imports from Tier 2–3 modules or from `lua_api`.

use super::renderer::DrawMode;

/// A single drawing command stored inside a [`CompoundShape`] command queue.
///
/// This is a restricted subset of [`crate::render::RenderCommand`] — only
/// primitive draw commands and rendering-state setters are included.
/// Transform commands (`PushTransform`, `Translate`, etc.) are intentionally
/// excluded: the shape's transform is applied once at draw time by the
/// `RenderCommand::DrawShape` wrapper.
///
/// # Variants
/// - `SetColor` — changes the active color for following commands.
/// - `SetLineWidth` — changes the line width for following outlined commands.
/// - `Rectangle` — draws an axis-aligned rectangle, filled or outlined.
/// - `RoundedRectangle` — draws a rectangle with per-axis corner radii.
/// - `Circle` — draws a circle at centre `(x, y)` with radius `r`.
/// - `Ellipse` — draws an ellipse with semi-axes `rx`, `ry`.
/// - `Triangle` — draws a triangle with three explicit vertices.
/// - `Polygon` — draws an arbitrary polygon from a flat vertex list.
/// - `Line` — draws a single line segment.
/// - `Polyline` — draws a connected sequence of line segments.
/// - `Arc` — draws an arc (sector or outline) of a circle.
#[derive(Debug, Clone)]
pub enum ShapeCommand {
    /// Change the active draw color.
    SetColor(f32, f32, f32, f32),
    /// Change the stroke width for subsequently outlined primitives.
    SetLineWidth(f32),
    /// Axis-aligned rectangle.
    Rectangle {
        /// Fill or outline mode.
        mode: DrawMode,
        /// Left edge X in object space.
        x: f32,
        /// Top edge Y in object space.
        y: f32,
        /// Width in pixels.
        w: f32,
        /// Height in pixels.
        h: f32,
    },
    /// Rectangle with rounded corners.
    RoundedRectangle {
        /// Fill or outline mode.
        mode: DrawMode,
        /// Left edge X in object space.
        x: f32,
        /// Top edge Y in object space.
        y: f32,
        /// Width in pixels.
        w: f32,
        /// Height in pixels.
        h: f32,
        /// Horizontal corner radius in pixels.
        rx: f32,
        /// Vertical corner radius in pixels.
        ry: f32,
    },
    /// Circle defined by centre and radius.
    Circle {
        /// Fill or outline mode.
        mode: DrawMode,
        /// Centre X in object space.
        x: f32,
        /// Centre Y in object space.
        y: f32,
        /// Radius in pixels.
        r: f32,
    },
    /// Ellipse defined by centre and semi-axes.
    Ellipse {
        /// Fill or outline mode.
        mode: DrawMode,
        /// Centre X in object space.
        x: f32,
        /// Centre Y in object space.
        y: f32,
        /// Horizontal semi-axis in pixels.
        rx: f32,
        /// Vertical semi-axis in pixels.
        ry: f32,
    },
    /// Triangle with three explicit vertices.
    Triangle {
        /// Fill or outline mode.
        mode: DrawMode,
        /// First vertex X.
        x1: f32,
        /// First vertex Y.
        y1: f32,
        /// Second vertex X.
        x2: f32,
        /// Second vertex Y.
        y2: f32,
        /// Third vertex X.
        x3: f32,
        /// Third vertex Y.
        y3: f32,
    },
    /// Arbitrary polygon from a flat `[x0, y0, x1, y1, …]` vertex list.
    Polygon {
        /// Fill or outline mode.
        mode: DrawMode,
        /// Flat list of `(x, y)` pairs; must contain at least 6 values (3 vertices).
        vertices: Vec<f32>,
    },
    /// Single line segment.
    Line {
        /// Start X in object space.
        x1: f32,
        /// Start Y in object space.
        y1: f32,
        /// End X in object space.
        x2: f32,
        /// End Y in object space.
        y2: f32,
    },
    /// Connected sequence of line segments from a flat `[x0, y0, x1, y1, …]` point list.
    Polyline {
        /// Flat list of `(x, y)` pairs; must contain at least 4 values (2 points).
        points: Vec<f32>,
    },
    /// Arc (sector or outline) of a circle.
    Arc {
        /// Fill or outline mode.
        mode: DrawMode,
        /// Centre X in object space.
        x: f32,
        /// Centre Y in object space.
        y: f32,
        /// Radius in pixels.
        radius: f32,
        /// Start angle in radians.
        angle1: f32,
        /// End angle in radians.
        angle2: f32,
        /// Number of line segments used to approximate the arc curve.
        segments: u32,
    },
}

/// A compound shape that accumulates draw primitives in local (object-space)
/// coordinates and replays them as a unified entity via [`crate::render::RenderCommand::DrawShape`].
///
/// Build up commands with [`push_command`](CompoundShape::push_command), then submit
/// a [`crate::render::RenderCommand::DrawShape`] each frame to draw with an affine transform.
///
/// # Fields
/// - `commands` — `Vec<ShapeCommand>`. The ordered list of drawing commands.
/// - `current_color` — `[f32; 4]`. Last color set via a `SetColor` command (retained for reference).
/// - `current_line_width` — `f32`. Last line width set via a `SetLineWidth` command.
#[derive(Clone)]
pub struct CompoundShape {
    /// Ordered list of drawing commands making up this shape.
    pub commands: Vec<ShapeCommand>,
    /// Most recently recorded color state (informational; used as default at creation).
    pub current_color: [f32; 4],
    /// Most recently recorded line-width state (informational; used as default at creation).
    pub current_line_width: f32,
}

impl CompoundShape {
    /// Creates a new empty compound shape with default color (white) and line width (1.0).
    ///
    /// # Returns
    /// A new empty `CompoundShape`.
    pub fn new() -> Self {
        Self {
            commands: Vec::new(),
            current_color: [1.0, 1.0, 1.0, 1.0],
            current_line_width: 1.0,
        }
    }

    /// Appends a drawing command to the shape's command queue.
    ///
    /// # Parameters
    /// - `cmd` — `ShapeCommand`. The command to append.
    pub fn push_command(&mut self, cmd: ShapeCommand) {
        self.commands.push(cmd);
    }

    /// Empties the command queue and resets color and line-width state to defaults.
    pub fn clear(&mut self) {
        self.commands.clear();
        self.current_color = [1.0, 1.0, 1.0, 1.0];
        self.current_line_width = 1.0;
    }

    /// Returns the number of commands currently in the queue.
    ///
    /// # Returns
    /// `usize` — command count.
    pub fn command_count(&self) -> usize {
        self.commands.len()
    }
}

impl Default for CompoundShape {
    fn default() -> Self {
        Self::new()
    }
}
