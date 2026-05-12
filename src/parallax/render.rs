//! Render-command generation for parallax layers.
//!
//! Converts [`ParallaxDrawBatch`] output into [`RenderCommand`] sequences
//! ready for the GPU renderer queue.  Pure CPU — no wgpu, winit, or mlua.

use crate::parallax::layer::{ParallaxDrawBatch, ParallaxLayer};
use crate::render::renderer::RenderCommand;

impl ParallaxLayer {
    /// Produces render commands for this layer given the current camera and screen.
    ///
    /// Calls [`ParallaxLayer::build_draw_calls`] internally, then converts
    /// the resulting [`ParallaxDrawBatch`] into a `Vec<RenderCommand>`.
    /// Returns an empty vec when the layer is invisible or degenerate.
    ///
    /// # Parameters
    /// - `cam_x` — `f32`. Camera world X in game-logical pixels.
    /// - `cam_y` — `f32`. Camera world Y in game-logical pixels.
    /// - `screen_w` — `f32`. Logical screen width in pixels.
    /// - `screen_h` — `f32`. Logical screen height in pixels.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(
        &self,
        cam_x: f32,
        cam_y: f32,
        screen_w: f32,
        screen_h: f32,
    ) -> Vec<RenderCommand> {
        let batch = match self.build_draw_calls(cam_x, cam_y, screen_w, screen_h) {
            Some(b) => b,
            None => return Vec::new(),
        };

        batch_to_render_commands(&batch)
    }
}

/// Converts a pre-computed [`ParallaxDrawBatch`] into render commands.
///
/// Each tile in the batch becomes a `SetColor` + `SetBlendMode` + `DrawImageEx`
/// triple.  Blend-mode and color are set once at the start, then each tile
/// emits a single `DrawImageEx`.
///
/// # Parameters
/// - `batch` — `&ParallaxDrawBatch`. The draw batch to convert.
///
/// # Returns
/// `Vec<RenderCommand>`.
pub fn batch_to_render_commands(batch: &ParallaxDrawBatch) -> Vec<RenderCommand> {
    let [r, g, b, a] = batch.color;
    // 2 setup commands + 1 per tile
    let mut cmds = Vec::with_capacity(2 + batch.tiles.len());

    cmds.push(RenderCommand::SetColor(r, g, b, a));
    cmds.push(RenderCommand::SetBlendMode(batch.blend_mode));

    for &(x, y) in &batch.tiles {
        cmds.push(RenderCommand::DrawImageEx {
            texture_key: batch.texture_key,
            x,
            y,
            rotation: 0.0,
            sx: batch.sx,
            sy: batch.sy,
            ox: 0.0,
            oy: 0.0,
            effect: batch.effect.clone(),
        });
    }

    cmds
}

// ── Tests ────────────────────────────────────────────────────────────────────
