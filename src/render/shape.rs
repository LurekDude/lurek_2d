use super::renderer::DrawMode;
#[derive(Debug, Clone)]
pub enum ShapeCommand {
    SetColor(f32, f32, f32, f32),
    SetLineWidth(f32),
    Rectangle {
        mode: DrawMode,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
    },
    RoundedRectangle {
        mode: DrawMode,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        rx: f32,
        ry: f32,
    },
    Circle {
        mode: DrawMode,
        x: f32,
        y: f32,
        r: f32,
    },
    Ellipse {
        mode: DrawMode,
        x: f32,
        y: f32,
        rx: f32,
        ry: f32,
    },
    Triangle {
        mode: DrawMode,
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
        x3: f32,
        y3: f32,
    },
    Polygon {
        mode: DrawMode,
        vertices: Vec<f32>,
    },
    Line {
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
    },
    Polyline {
        points: Vec<f32>,
    },
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
#[derive(Clone)]
pub struct CompoundShape {
    pub commands: Vec<ShapeCommand>,
    pub current_color: [f32; 4],
    pub current_line_width: f32,
}
impl CompoundShape {
    pub fn new() -> Self {
        Self {
            commands: Vec::new(),
            current_color: [1.0, 1.0, 1.0, 1.0],
            current_line_width: 1.0,
        }
    }
    pub fn push_command(&mut self, cmd: ShapeCommand) {
        self.commands.push(cmd);
    }
    pub fn clear(&mut self) {
        self.commands.clear();
        self.current_color = [1.0, 1.0, 1.0, 1.0];
        self.current_line_width = 1.0;
    }
    pub fn command_count(&self) -> usize {
        self.commands.len()
    }
}
impl Default for CompoundShape {
    fn default() -> Self {
        Self::new()
    }
}
