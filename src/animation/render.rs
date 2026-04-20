//! Render-command generation for sprite animations.
//!
//! Provides a helper to convert the current animation frame into a
//! [`RenderCommand::DrawQuad`].  Pure CPU â€” no wgpu, winit, or mlua.

use crate::animation::controller::Animation;
use crate::math::Rect;
use crate::render::renderer::RenderCommand;
use crate::runtime::resource_keys::TextureKey;

/// Parameters for rendering an animated sprite.
///
/// Since [`Animation`] is a pure frame/clip controller and does not store
/// position, texture, or transform, the caller supplies those via this struct.
///
/// # Fields
/// - `texture_key` â€” `TextureKey`. Handle to the sprite-sheet texture.
/// - `tex_w` â€” `f32`. Full texture width in pixels (for UV normalisation).
/// - `tex_h` â€” `f32`. Full texture height in pixels (for UV normalisation).
/// - `x` â€” `f32`. World X position.
/// - `y` â€” `f32`. World Y position.
/// - `rotation` â€” `f32`. Rotation in radians.
/// - `sx` â€” `f32`. Horizontal scale.
/// - `sy` â€” `f32`. Vertical scale.
/// - `ox` â€” `f32`. Origin X offset.
/// - `oy` â€” `f32`. Origin Y offset.
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
    /// Produces a single `DrawQuad` render command for the current frame.
    ///
    /// Returns `None` if no clip is active or the animation has no frames.
    /// The caller supplies the texture and transform via [`AnimRenderParams`].
    ///
    /// # Parameters
    /// - `params` â€” `&AnimRenderParams`. Texture and transform info.
    ///
    /// # Returns
    /// `Option<RenderCommand>`.
    pub fn generate_render_command(&self, params: &AnimRenderParams) -> Option<RenderCommand> {
        let quad = self.current_quad()?;
        Some(quad_to_draw_command(&quad, params))
    }
}

/// Converts a source quad and render parameters into a `DrawQuad` command.
///
/// # Parameters
/// - `quad` â€” `&Rect`. Source rectangle within the sprite-sheet.
/// - `params` â€” `&AnimRenderParams`. Texture and transform info.
///
/// # Returns
/// `RenderCommand`.
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

// â”€â”€ Tests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
