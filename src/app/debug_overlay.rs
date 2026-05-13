//! Overlay displaying frame-rate and render-statistics diagnostics.
//! DebugOverlay: builds draw commands for FPS and draw-call counters.

use crate::render::renderer::{DrawMode, RenderCommand};
use crate::runtime::resource_keys::FontKey;

// ---- Type: DebugOverlay ----

/// Toggleable performance overlay; toggleable via F12.
pub struct DebugOverlay {
    /// Whether the overlay is currently visible.
    pub enabled: bool,
}

impl DebugOverlay {
    // ---- Implementation: DebugOverlay ----

    /// Create new disabled overlay.
    pub fn new() -> Self {
        Self { enabled: false }
    }

    /// Build draw commands for FPS and draw-call count overlay.
    pub fn build_render_commands(
        &self,
        screen_w: u32,
        fps: f64,
        draw_calls: u32,
        font_key: Option<FontKey>,
    ) -> Vec<RenderCommand> {
        if !self.enabled {
            return Vec::new();
        }
        let font_key = match font_key {
            Some(fk) => fk,
            None => return Vec::new(),
        };

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
            RenderCommand::SetColor(0.0, 0.0, 0.0, 0.6),
            RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x: box_x,
                y: box_y,
                w: box_w,
                h: box_h,
            },
            // Green text
            RenderCommand::SetColor(0.2, 1.0, 0.2, 1.0),
            RenderCommand::Print {
                font_key,
                text: fps_text,
                x: box_x + padding,
                y: box_y + padding,
                scale,
            },
            RenderCommand::Print {
                font_key,
                text: dc_text,
                x: box_x + padding,
                y: box_y + padding + line_h,
                scale,
            },
        ]
    }
}

impl Default for DebugOverlay {
    // ---- Default Implementation ----

    fn default() -> Self {
        Self::new()
    }
}

// Tests migrated to tests/rust/unit/app_tests.rs
