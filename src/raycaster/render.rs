//! Converts a `RaycasterScene` into `RenderCommand` draw calls for the GPU renderer.
//! Emits textured and flat quads for ceilings, floors, walls, and billboard sprites
//! in the correct draw order. Does not own scene construction or GPU state.

use crate::raycaster::scene::RaycasterScene;
use crate::render::renderer::{DrawMode, RenderCommand};
use crate::render::BlendMode;
impl RaycasterScene {
    /// Build a `Vec<RenderCommand>` for the full scene: ceilings, floors, walls, then sprites back-to-front.
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        let mut cmds = Vec::with_capacity(self.quad_count() + 2);
        cmds.push(RenderCommand::SetBlendMode(BlendMode::Alpha));
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
