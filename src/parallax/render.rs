//! Converts `ParallaxLayer` and `ParallaxDrawBatch` into `RenderCommand` streams.
//! Owns the translation from parallax draw data to renderer API calls; does not own camera maths.
//! Key dependencies: `parallax::layer`, `render::renderer::RenderCommand`.

use crate::parallax::layer::{ParallaxDrawBatch, ParallaxLayer};
use crate::render::renderer::RenderCommand;
impl ParallaxLayer {
/// Generate a `Vec<RenderCommand>` for this layer at the given camera position and screen size.
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
/// Convert a `ParallaxDrawBatch` into a flat list of `RenderCommand` values ready for submission.
pub fn batch_to_render_commands(batch: &ParallaxDrawBatch) -> Vec<RenderCommand> {
    let [r, g, b, a] = batch.color;
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
