use crate::math::Color;
use crate::render::renderer::{DrawMode, RenderCommand};
#[derive(Debug, Clone)]
pub struct TrailPoint {
    pub x: f32,
    pub y: f32,
    pub age: f32,
}
pub struct Trail {
    pub points: Vec<TrailPoint>,
    pub lifetime: f32,
    pub start_width: f32,
    pub end_width: f32,
    pub head_color: Color,
    pub tail_color: Color,
    pub min_distance: f32,
}
impl Trail {
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
    pub fn update(&mut self, dt: f32) {
        for point in &mut self.points {
            point.age += dt;
        }
        self.points.retain(|p| p.age < self.lifetime);
    }
    pub fn set_width(&mut self, start: f32, end: Option<f32>) {
        self.start_width = start;
        if let Some(e) = end {
            self.end_width = e;
        }
    }
    pub fn set_lifetime(&mut self, lifetime: f32) {
        self.lifetime = lifetime;
    }
    pub fn get_lifetime(&self) -> f32 {
        self.lifetime
    }
    pub fn set_min_distance(&mut self, distance: f32) {
        self.min_distance = distance;
    }
    pub fn clear(&mut self) {
        self.points.clear();
    }
    pub fn get_point_count(&self) -> usize {
        self.points.len()
    }
    pub fn get_width(&self) -> (f32, f32) {
        (self.start_width, self.end_width)
    }
    pub fn set_head_color(&mut self, color: Color) {
        self.head_color = color;
    }
    pub fn set_tail_color(&mut self, color: Color) {
        self.tail_color = color;
    }
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
            let w_a = self.start_width + (self.end_width - self.start_width) * t_a;
            let w_b = self.start_width + (self.end_width - self.start_width) * t_b;
            let t_mid = (t_a + t_b) * 0.5;
            let cr = self.head_color.r + (self.tail_color.r - self.head_color.r) * t_mid;
            let cg = self.head_color.g + (self.tail_color.g - self.head_color.g) * t_mid;
            let cb = self.head_color.b + (self.tail_color.b - self.head_color.b) * t_mid;
            let ca = self.head_color.a + (self.tail_color.a - self.head_color.a) * t_mid;
            let dx = b.x - a.x;
            let dy = b.y - a.y;
            let len = (dx * dx + dy * dy).sqrt().max(0.001);
            let nx = -dy / len;
            let ny = dx / len;
            let hw_a = w_a * 0.5;
            let hw_b = w_b * 0.5;
            let ax1 = a.x + nx * hw_a;
            let ay1 = a.y + ny * hw_a;
            let ax2 = a.x - nx * hw_a;
            let ay2 = a.y - ny * hw_a;
            let bx1 = b.x + nx * hw_b;
            let by1 = b.y + ny * hw_b;
            let bx2 = b.x - nx * hw_b;
            let by2 = b.y - ny * hw_b;
            commands.push(RenderCommand::SetColor(cr, cg, cb, ca));
            commands.push(RenderCommand::Triangle {
                mode: DrawMode::Fill,
                x1: ax1,
                y1: ay1,
                x2: ax2,
                y2: ay2,
                x3: bx1,
                y3: by1,
            });
            commands.push(RenderCommand::Triangle {
                mode: DrawMode::Fill,
                x1: ax2,
                y1: ay2,
                x2: bx2,
                y2: by2,
                x3: bx1,
                y3: by1,
            });
        }
        commands
    }
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
                a.x as i32, a.y as i32, b.x as i32, b.y as i32, r, g, blue, alpha,
            );
        }
        img
    }
}
