//! Build render commands from current animation frame data.

use crate::animation::controller::Animation;
use crate::math::Rect;
use crate::render::renderer::RenderCommand;
use crate::runtime::resource_keys::TextureKey;

// ---- Type: AnimRenderParams ----

/// Parameters for rendering an animated sprite.
#[derive(Debug, Clone)]
pub struct AnimRenderParams {
    /// Handle to the sprite-sheet texture.
    pub texture_key: TextureKey,
    /// Full texture width in pixels (for UV normalisation).
    pub tex_w: f32,
    /// Full texture height in pixels (for UV normalisation).
    pub tex_h: f32,
    /// World X position.
    pub x: f32,
    /// World Y position.
    pub y: f32,
    /// Rotation in radians.
    pub rotation: f32,
    /// Horizontal scale.
    pub sx: f32,
    /// Vertical scale.
    pub sy: f32,
    /// Origin X offset.
    pub ox: f32,
    /// Origin Y offset.
    pub oy: f32,
}

impl Animation {
    // ---- Implementation: Animation Render Helpers ----
    /// Produces a single `DrawQuad` render command for the current frame.
    pub fn generate_render_command(&self, params: &AnimRenderParams) -> Option<RenderCommand> {
        let quad = self.current_quad()?;
        Some(quad_to_draw_command(&quad, params))
    }
}

// ---- Helper Functions: Render Command Conversion ----

/// Converts a source quad and render parameters into a `DrawQuad` command.
pub fn quad_to_draw_command(quad: &Rect, params: &AnimRenderParams) -> RenderCommand {
    RenderCommand::DrawQuad {
        texture_key: params.texture_key,
        quad_x: quad.x,
        quad_y: quad.y,
        quad_w: quad.width,
        quad_h: quad.height,
        tex_w: params.tex_w,
        tex_h: params.tex_h,
        x: params.x,
        y: params.y,
        rotation: params.rotation,
        sx: params.sx,
        sy: params.sy,
        ox: params.ox,
        oy: params.oy,
        effect: None,
    }
}
