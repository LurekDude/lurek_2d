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
            effect: None,
        });
    }

    cmds
}

// ── Tests ────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use crate::parallax::layer::ParallaxLayer;
    use crate::runtime::resource_keys::TextureKey;
    use crate::render::BlendMode;
    use slotmap::KeyData;

    fn dummy_key() -> TextureKey {
        TextureKey::from(KeyData::from_ffi(1))
    }

    #[test]
    fn invisible_layer_produces_empty_commands() {
        let mut layer = ParallaxLayer::new(dummy_key(), 256.0, 256.0);
        layer.visible = false;
        let cmds = layer.generate_render_commands(0.0, 0.0, 800.0, 600.0);
        assert!(cmds.is_empty());
    }

    #[test]
    fn visible_layer_produces_draw_image_ex_commands() {
        let layer = ParallaxLayer::new(dummy_key(), 256.0, 256.0);
        let cmds = layer.generate_render_commands(0.0, 0.0, 800.0, 600.0);
        // Should have: SetColor + SetBlendMode + N DrawImageEx tiles
        assert!(cmds.len() >= 3, "Expected at least 3 commands, got {}", cmds.len());
        // First is SetColor
        assert!(matches!(cmds[0], RenderCommand::SetColor(..)));
        // Second is SetBlendMode
        assert!(matches!(cmds[1], RenderCommand::SetBlendMode(_)));
        // Rest are DrawImageEx
        for cmd in &cmds[2..] {
            assert!(matches!(cmd, RenderCommand::DrawImageEx { .. }));
        }
    }

    #[test]
    fn batch_to_commands_preserves_tile_positions() {
        let batch = ParallaxDrawBatch {
            texture_key: dummy_key(),
            tiles: vec![(10.0, 20.0), (266.0, 20.0)],
            sx: 1.0,
            sy: 1.0,
            color: [1.0, 1.0, 1.0, 1.0],
            blend_mode: BlendMode::Alpha,
        };
        let cmds = batch_to_render_commands(&batch);
        assert_eq!(cmds.len(), 4); // SetColor + SetBlendMode + 2 tiles
        if let RenderCommand::DrawImageEx { x, y, .. } = &cmds[2] {
            assert!((*x - 10.0).abs() < 1e-5);
            assert!((*y - 20.0).abs() < 1e-5);
        } else {
            panic!("Expected DrawImageEx");
        }
    }
}
