//! Render-command generation and CPU drawing for the terminal module.
//!
//! Converts a [`Terminal`] grid into [`RenderCommand`] sequences for GPU
//! rendering, and into an [`ImageData`] for headless CPU rendering.
//! Pure CPU — no wgpu, winit, or mlua imports.

use crate::image::ImageData;
use crate::render::renderer::{DrawMode, RenderCommand};
use crate::runtime::resource_keys::FontKey;

use super::terminal_state::Terminal;

impl Terminal {
    /// Generate GPU render commands for this terminal grid.
    ///
    /// Emits one `SetColor` + `Print` pair per non-space cell in the grid,
    /// preceded by an optional background `Rectangle` fill when the cell's
    /// background alpha is non-zero.
    ///
    /// # Parameters
    /// - `font_key` — `FontKey`. Bitmap font to use for character rendering.
    /// - `char_w` — `f32`. Cell width in pixels.
    /// - `char_h` — `f32`. Cell height in pixels.
    /// - `scale` — `f32`. Glyph scale factor passed to `RenderCommand::Print`.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
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

                // Background rectangle (only when non-transparent)
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

                // Character glyph (skip spaces)
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

    /// Render the terminal grid to a CPU image for headless testing.
    ///
    /// Fills the image with a dark background, then draws each non-space
    /// cell as a coloured pixel block proportional to the cell dimensions.
    ///
    /// # Parameters
    /// - `width` — `u32`. Output image width in pixels.
    /// - `height` — `u32`. Output image height in pixels.
    ///
    /// # Returns
    /// `ImageData`.
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

// ── Tests ────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use slotmap::KeyData;

    fn dummy_font() -> FontKey {
        FontKey::from(KeyData::from_ffi(1))
    }

    #[test]
    fn generate_render_commands_empty_terminal_returns_empty() {
        let t = Terminal::new(4, 2);
        let cmds = t.generate_render_commands(dummy_font(), 8.0, 16.0, 1.0);
        assert!(cmds.is_empty(), "blank terminal should emit no commands");
    }

    #[test]
    fn generate_render_commands_single_char_emits_color_and_print() {
        let mut t = Terminal::new(4, 2);
        t.set(
            1,
            1,
            b'A' as u32,
            [1.0, 1.0, 1.0, 1.0],
            [0.0, 0.0, 0.0, 0.0],
        );
        let cmds = t.generate_render_commands(dummy_font(), 8.0, 16.0, 1.0);
        assert_eq!(cmds.len(), 2, "SetColor + Print for one non-space cell");
        assert!(matches!(cmds[0], RenderCommand::SetColor(_, _, _, _)));
        assert!(matches!(cmds[1], RenderCommand::Print { .. }));
    }

    #[test]
    fn draw_to_image_correct_dimensions() {
        let t = Terminal::new(8, 4);
        let img = t.draw_to_image(160, 80);
        assert_eq!(img.width(), 160);
        assert_eq!(img.height(), 80);
    }

    #[test]
    fn draw_to_image_non_space_cell_writes_pixels() {
        let mut t = Terminal::new(2, 2);
        t.set(
            1,
            1,
            b'X' as u32,
            [1.0, 0.0, 0.0, 1.0],
            [0.0, 0.0, 0.0, 0.0],
        );
        let img = t.draw_to_image(64, 32);
        if let Some((r, g, b, _)) = img.get_pixel(0, 0) {
            assert!(r > 100 && g < 50 && b < 50, "expected red cell pixel");
        }
    }
}
