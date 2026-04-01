//! Debug overlay for displaying FPS and draw call statistics.
//!
//! Renders green text on a semi-transparent background in the top-right corner
//! of the screen. Can be toggled at runtime via F12 or `luna.system.setDebugOverlay()`.

use crate::graphics::renderer::{DrawCommand, DrawMode};

/// Debug overlay showing FPS and render statistics.
///
/// # Fields
/// - `enabled` — `bool`.
///
/// Generates `DrawCommand` sequences for rendering performance info in the
/// top-right corner of the screen.
pub struct DebugOverlay {
    /// Whether the overlay is currently visible.
    pub enabled: bool,
}

impl DebugOverlay {
    /// Creates a new disabled debug overlay.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self { enabled: false }
    }

    /// Generates draw commands for the overlay.
    ///
    /// Shows FPS and draw call count as green text on a dark semi-transparent background.
    ///
    /// # Parameters
    /// - `screen_w` — Screen width in pixels.
    /// - `fps` — Current frames per second.
    /// - `draw_calls` — Number of draw calls in the last frame.
    ///
    /// # Returns
    /// A `Vec<DrawCommand>` to append after the main game rendering.
    pub fn draw_commands(&self, screen_w: u32, fps: f64, draw_calls: u32) -> Vec<DrawCommand> {
        if !self.enabled {
            return Vec::new();
        }

        let scale = 2.0_f32;
        let glyph_w = 8.0_f32 * scale;
        let line_h = 14.0_f32 * scale;
        let padding = 8.0_f32;

        let fps_text = format!("FPS: {:.0}", fps);
        let dc_text = format!("Draw calls: {}", draw_calls);

        let max_len = fps_text.len().max(dc_text.len());
        let box_w = max_len as f32 * glyph_w + padding * 2.0;
        let box_h = line_h * 2.0 + padding * 2.0;
        let box_x = screen_w as f32 - box_w - 10.0;
        let box_y = 10.0_f32;

        vec![
            // Semi-transparent dark background
            DrawCommand::SetColor(0.0, 0.0, 0.0, 0.6),
            DrawCommand::Rectangle {
                mode: DrawMode::Fill,
                x: box_x,
                y: box_y,
                w: box_w,
                h: box_h,
            },
            // Green text
            DrawCommand::SetColor(0.2, 1.0, 0.2, 1.0),
            DrawCommand::Print {
                text: fps_text,
                x: box_x + padding,
                y: box_y + padding,
                scale,
            },
            DrawCommand::Print {
                text: dc_text,
                x: box_x + padding,
                y: box_y + padding + line_h,
                scale,
            },
        ]
    }
}

impl Default for DebugOverlay {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_disabled_returns_empty() {
        let overlay = DebugOverlay::new();
        assert!(!overlay.enabled);
        let cmds = overlay.draw_commands(800, 60.0, 10);
        assert!(cmds.is_empty());
    }

    #[test]
    fn test_enabled_returns_commands() {
        let mut overlay = DebugOverlay::new();
        overlay.enabled = true;
        let cmds = overlay.draw_commands(800, 60.0, 10);
        assert!(!cmds.is_empty());
    }
}
