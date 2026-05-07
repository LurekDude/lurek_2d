//! Render-command generation for raycaster scenes.
//!
//! Converts a [`RaycasterScene`] into [`RenderCommand`] sequences.
//! Each surface (wall, floor, ceiling, sprite) emits a single
//! [`RenderCommand::DrawTexturedQuad`] with perspective-correct UV corners
//! and a per-polygon RGBA light tint. Untextured quads fall back to a
//! coloured [`RenderCommand::Rectangle`]. Pure CPU — no wgpu, winit, or mlua.

use crate::raycaster::scene::RaycasterScene;
use crate::render::renderer::{DrawMode, RenderCommand};
use crate::render::BlendMode;

impl RaycasterScene {
    /// Converts the entire scene into render commands.
    ///
    /// Draw order: ceilings → floors → walls (column order) → sprites (back-to-front).
    /// Textured quads emit [`RenderCommand::DrawTexturedQuad`] with perspective-correct
    /// UV corners and the pre-computed per-polygon RGBA light tint as the colour
    /// multiplier. Quads without a texture fall back to a coloured
    /// [`RenderCommand::Rectangle`].
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        // One command per quad (DrawTexturedQuad or Rectangle).
        // Untextured quads need an extra SetColor, so capacity is a slight over-estimate.
        let mut cmds = Vec::with_capacity(self.quad_count() + 2);

        cmds.push(RenderCommand::SetBlendMode(BlendMode::Alpha));

        // ── Ceilings ──
        for ceil in &self.ceilings {
            match ceil.texture_key {
                Some(tex) => {
                    cmds.push(RenderCommand::DrawTexturedQuad {
                        corners: ceil.corners,
                        uvs: ceil.uvs,
                        corner_w: ceil.corner_w,
                        texture_key: tex,
                        color: ceil.light,
                    });
                }
                None => {
                    let [r, g, b, a] = ceil.light;
                    cmds.push(RenderCommand::SetColor(r, g, b, a));
                    cmds.push(RenderCommand::Rectangle {
                        mode: DrawMode::Fill,
                        x: ceil.corners[0].x,
                        y: ceil.corners[0].y,
                        w: ceil.corners[1].x - ceil.corners[0].x,
                        h: ceil.corners[3].y - ceil.corners[0].y,
                    });
                }
            }
        }

        // ── Floors ──
        for floor in &self.floors {
            match floor.texture_key {
                Some(tex) => {
                    cmds.push(RenderCommand::DrawTexturedQuad {
                        corners: floor.corners,
                        uvs: floor.uvs,
                        corner_w: floor.corner_w,
                        texture_key: tex,
                        color: floor.light,
                    });
                }
                None => {
                    let [r, g, b, a] = floor.light;
                    cmds.push(RenderCommand::SetColor(r, g, b, a));
                    cmds.push(RenderCommand::Rectangle {
                        mode: DrawMode::Fill,
                        x: floor.corners[0].x,
                        y: floor.corners[0].y,
                        w: floor.corners[1].x - floor.corners[0].x,
                        h: floor.corners[3].y - floor.corners[0].y,
                    });
                }
            }
        }

        // ── Walls (column order; depth sorting handled by scene builder) ──
        for wall in &self.walls {
            match wall.texture_key {
                Some(tex) => {
                    cmds.push(RenderCommand::DrawTexturedQuad {
                        corners: wall.corners,
                        uvs: wall.uvs,
                        corner_w: wall.corner_w,
                        texture_key: tex,
                        color: wall.light,
                    });
                }
                None => {
                    let [r, g, b, a] = wall.light;
                    cmds.push(RenderCommand::SetColor(r, g, b, a));
                    cmds.push(RenderCommand::Rectangle {
                        mode: DrawMode::Fill,
                        x: wall.corners[0].x,
                        y: wall.corners[0].y,
                        w: wall.corners[1].x - wall.corners[0].x,
                        h: wall.corners[3].y - wall.corners[0].y,
                    });
                }
            }
        }

        // ── Sprites (already sorted back-to-front by build_scene) ──
        for sprite in &self.sprites {
            cmds.push(RenderCommand::DrawTexturedQuad {
                corners: sprite.corners,
                uvs: sprite.uvs,
                corner_w: [1.0, 1.0, 1.0, 1.0],
                texture_key: sprite.texture_key,
                color: sprite.light,
            });
        }

        cmds
    }
}
