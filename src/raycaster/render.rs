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
                texture_key: sprite.texture_key,
                color: sprite.light,
            });
        }

        cmds
    }
}

// ── Tests ────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use crate::math::Vec2;
    use crate::raycaster::scene::{CeilingQuad, FloorQuad, RaycasterScene, WallQuad};

    fn make_corners(x: f32, y: f32, w: f32, h: f32) -> [Vec2; 4] {
        [
            Vec2::new(x, y),
            Vec2::new(x + w, y),
            Vec2::new(x + w, y + h),
            Vec2::new(x, y + h),
        ]
    }

    fn unit_uvs() -> [Vec2; 4] {
        [
            Vec2::new(0.0, 0.0),
            Vec2::new(1.0, 0.0),
            Vec2::new(1.0, 1.0),
            Vec2::new(0.0, 1.0),
        ]
    }

    #[test]
    fn raycaster_scene_empty_gives_empty_commands() {
        // Default scene has no quads — only SetBlendMode is emitted
        let scene = RaycasterScene::default();
        let cmds = scene.generate_render_commands();
        // Only the SetBlendMode preamble, no geometry commands
        assert!(
            cmds.iter()
                .all(|c| matches!(c, RenderCommand::SetBlendMode(_))),
            "Empty scene should have no geometry commands"
        );
    }

    #[test]
    fn empty_scene_produces_minimal_commands() {
        let scene = RaycasterScene::new(320.0, 200.0);
        let cmds = scene.generate_render_commands();
        // Just SetBlendMode
        assert_eq!(cmds.len(), 1);
    }

    #[test]
    fn raycaster_scene_with_wall_gives_draw_textured_quad() {
        use crate::runtime::resource_keys::TextureKey;
        use slotmap::KeyData;
        let tk = TextureKey::from(KeyData::from_ffi(1));

        let mut scene = RaycasterScene::new(320.0, 200.0);
        scene.walls.push(WallQuad {
            corners: make_corners(10.0, 50.0, 1.0, 100.0),
            uvs: unit_uvs(),
            texture_key: Some(tk),
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 3.0,
            cell_value: 1,
        });
        let cmds = scene.generate_render_commands();
        assert!(
            cmds.iter()
                .any(|c| matches!(c, RenderCommand::DrawTexturedQuad { .. })),
            "Expected a DrawTexturedQuad command"
        );
    }

    #[test]
    fn wall_quad_untextured_emits_set_color_and_rectangle() {
        let mut scene = RaycasterScene::new(320.0, 200.0);
        scene.walls.push(WallQuad {
            corners: make_corners(10.0, 50.0, 32.0, 100.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [0.8, 0.6, 0.4, 1.0],
            depth: 3.0,
            cell_value: 1,
        });
        let cmds = scene.generate_render_commands();
        // SetBlendMode + SetColor + Rectangle = 3
        assert_eq!(cmds.len(), 3);
        assert!(matches!(cmds[1], RenderCommand::SetColor(..)));
        assert!(matches!(cmds[2], RenderCommand::Rectangle { .. }));
    }

    #[test]
    fn floor_emits_draw_command() {
        let mut scene = RaycasterScene::new(320.0, 200.0);
        scene.floors.push(FloorQuad {
            corners: make_corners(0.0, 100.0, 32.0, 100.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 3.0,
        });
        let cmds = scene.generate_render_commands();
        assert!(cmds.len() >= 2);
    }

    #[test]
    fn ceiling_drawn_before_walls() {
        let mut scene = RaycasterScene::new(320.0, 200.0);
        scene.ceilings.push(CeilingQuad {
            corners: make_corners(0.0, 0.0, 32.0, 50.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 3.0,
        });
        scene.walls.push(WallQuad {
            corners: make_corners(0.0, 50.0, 32.0, 100.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 3.0,
            cell_value: 1,
        });
        let cmds = scene.generate_render_commands();
        // Find first Rectangle after SetBlendMode — should be the ceiling
        let first_rect_idx = cmds
            .iter()
            .position(|c| matches!(c, RenderCommand::Rectangle { .. }))
            .unwrap();
        // Ceiling rect has y=0 (top-left corner of ceiling quad)
        if let RenderCommand::Rectangle { y, .. } = &cmds[first_rect_idx] {
            assert!((*y).abs() < 1e-5, "First rectangle should be ceiling (y=0)");
        }
    }

    #[test]
    fn draw_to_image_returns_correct_dimensions() {
        let scene = RaycasterScene::default();
        let img = scene.draw_to_image(320, 200);
        assert_eq!(img.width(), 320);
        assert_eq!(img.height(), 200);
    }
}
