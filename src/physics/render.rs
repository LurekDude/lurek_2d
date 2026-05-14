//! Debug rendering helpers for `World`: `RenderCommand` list generation and CPU image rasterisation.
//! These methods extend `World` for debug visualisation only; not used in release builds.

use crate::image::ImageData;
use crate::physics::body::{BodyShape, BodyType};
use crate::physics::world::World;
use crate::render::renderer::{DrawMode, RenderCommand};

/// Debug render and image-rasterisation helpers added to `World`.
impl World {
    /// Build a list of `RenderCommand`s drawing outlines and velocity arrows for all bodies.
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        let ids = self.get_body_ids();
        if ids.is_empty() {
            return Vec::new();
        }
        let mut cmds = Vec::with_capacity(ids.len() * 3);
        for id in ids {
            let body = match self.get_body(id) {
                Some(b) => b,
                None => continue,
            };
            let (r, g, b) = match body.body_type {
                BodyType::Dynamic => (0.1f32, 0.9, 0.2),
                BodyType::Static => (0.3, 0.6, 1.0),
                BodyType::Kinematic => (0.2, 0.9, 1.0),
                BodyType::Sensor => (1.0, 1.0, 0.0),
            };
            cmds.push(RenderCommand::SetColor(r, g, b, 0.85));
            let px = body.position.x;
            let py = body.position.y;
            match body.shape {
                BodyShape::Rect { width, height } => {
                    cmds.push(RenderCommand::Rectangle {
                        mode: DrawMode::Line,
                        x: px - width * 0.5,
                        y: py - height * 0.5,
                        w: width,
                        h: height,
                    });
                }
                BodyShape::Circle { radius } => {
                    cmds.push(RenderCommand::Circle {
                        mode: DrawMode::Line,
                        x: px,
                        y: py,
                        r: radius,
                    });
                }
            }
            if matches!(body.body_type, BodyType::Dynamic) {
                let vx = body.velocity.x;
                let vy = body.velocity.y;
                if vx.abs() + vy.abs() > 0.01 {
                    cmds.push(RenderCommand::SetColor(1.0, 0.3, 0.1, 0.9));
                    cmds.push(RenderCommand::Line {
                        x1: px,
                        y1: py,
                        x2: px + vx * 0.1,
                        y2: py + vy * 0.1,
                    });
                }
            }
        }
        cmds
    }
    /// Rasterise all bodies onto a `width`×`height` `ImageData` centered at the origin.
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);
        img.fill(20, 20, 30, 255);
        let scale = width as f32 / 200.0;
        let cx = width as i32 / 2;
        let cy = height as i32 / 2;
        for id in self.get_body_ids() {
            let body = match self.get_body(id) {
                Some(b) => b,
                None => continue,
            };
            let (r, g, b) = match body.body_type {
                BodyType::Dynamic => (80u8, 220, 80),
                BodyType::Static => (80, 150, 220),
                BodyType::Kinematic => (80, 220, 220),
                BodyType::Sensor => (220, 220, 80),
            };
            let bx = cx + (body.position.x * scale) as i32;
            let by = cy + (body.position.y * scale) as i32;
            match body.shape {
                BodyShape::Rect {
                    width: bw,
                    height: bh,
                } => {
                    let hw = ((bw * scale * 0.5) as u32).max(1);
                    let hh = ((bh * scale * 0.5) as u32).max(1);
                    img.draw_rect(bx - hw as i32, by - hh as i32, hw * 2, hh * 2, r, g, b, 200);
                }
                BodyShape::Circle { radius } => {
                    let rad = ((radius * scale) as u32).max(1);
                    img.draw_circle(bx, by, rad, r, g, b, 200);
                }
            }
        }
        img
    }
}
