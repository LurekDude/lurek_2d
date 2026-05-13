use super::terminal_state::Terminal;
use crate::image::ImageData;
use crate::render::renderer::{DrawMode, RenderCommand};
use crate::runtime::resource_keys::FontKey;
impl Terminal {
    pub fn generate_render_commands(
        &self,
        font_key: FontKey,
        char_w: f32,
        char_h: f32,
        scale: f32,
    ) -> Vec<RenderCommand> {
        let (cols, rows) = self.get_dimensions();
        let mut cmds = Vec::with_capacity(cols * rows * 2);
        for row in 1..=rows {
            for col in 1..=cols {
                let cell = self.get(col, row);
                let x = (col - 1) as f32 * char_w;
                let y = (row - 1) as f32 * char_h;
                let [br, bg_clr, bb, ba] = cell.bg;
                if ba > 0.0 {
                    cmds.push(RenderCommand::SetColor(br, bg_clr, bb, ba));
                    cmds.push(RenderCommand::Rectangle {
                        mode: DrawMode::Fill,
                        x,
                        y,
                        w: char_w,
                        h: char_h,
                    });
                }
                let ch = char::from_u32(cell.ch).unwrap_or(' ');
                if ch != ' ' {
                    let [r, g, b, a] = cell.fg;
                    cmds.push(RenderCommand::SetColor(r, g, b, a));
                    cmds.push(RenderCommand::Print {
                        font_key,
                        text: ch.to_string(),
                        x,
                        y,
                        scale,
                    });
                }
            }
        }
        cmds
    }
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);
        img.fill(18, 18, 28, 255);
        let (cols, rows) = self.get_dimensions();
        if cols == 0 || rows == 0 || width == 0 || height == 0 {
            return img;
        }
        let cell_w = (width / cols as u32).max(1);
        let cell_h = (height / rows as u32).max(1);
        for row in 1..=rows {
            for col in 1..=cols {
                let cell = self.get(col, row);
                let ch = char::from_u32(cell.ch).unwrap_or(' ');
                if ch == ' ' {
                    continue;
                }
                let [r, g, b, _a] = cell.fg;
                let pr = (r * 255.0).min(255.0) as u8;
                let pg = (g * 255.0).min(255.0) as u8;
                let pb = (b * 255.0).min(255.0) as u8;
                let px = ((col - 1) as u32 * cell_w) as i32;
                let py = ((row - 1) as u32 * cell_h) as i32;
                img.draw_rect(px, py, cell_w, cell_h, pr, pg, pb, 255);
            }
        }
        img
    }
}
