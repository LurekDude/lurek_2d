//! - Convert a Skeleton's bone and slot state into a flat list of RenderCommands.
//! - Draw bones as filled circles at world positions with slot-derived colors.
//! - Draw slot attachments as outline rectangles around their parent bone.

use super::skeleton::Skeleton;
use crate::render::renderer::{DrawMode, RenderCommand};

/// Render methods added to Skeleton by this file.
impl Skeleton {
    /// Build a RenderCommand list for all bones (filled circles) and slot attachments (outline rectangles).
    /// at world offset (x, y); returns empty vec when no bones exist.
    pub fn generate_render_commands(&self, x: f32, y: f32) -> Vec<RenderCommand> {
        let mut cmds = Vec::new();
        if self.bones.is_empty() {
            return cmds;
        }
        let radius = 4.0 * self.scale_x.abs().max(self.scale_y.abs()).max(1.0);
        let mut bone_colors: Vec<Option<[f32; 4]>> = vec![None; self.bones.len()];
        for slot in &self.slots {
            if slot.bone_index < self.bones.len() && bone_colors[slot.bone_index].is_none() {
                bone_colors[slot.bone_index] =
                    Some([slot.color_r, slot.color_g, slot.color_b, slot.color_a]);
            }
        }
        for (i, bone) in self.bones.iter().enumerate() {
            let bx = x + bone.world_x;
            let by = y + bone.world_y;
            let [cr, cg, cb, ca] = bone_colors[i].unwrap_or([1.0, 1.0, 1.0, 1.0]);
            cmds.push(RenderCommand::SetColor(cr, cg, cb, ca));
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Fill,
                x: bx,
                y: by,
                r: radius,
            });
        }
        for slot in &self.slots {
            if slot.attachment_name.is_none() {
                continue;
            }
            if slot.bone_index >= self.bones.len() {
                continue;
            }
            let bone = &self.bones[slot.bone_index];
            let bx = x + bone.world_x;
            let by = y + bone.world_y;
            let half = radius;
            cmds.push(RenderCommand::SetColor(
                slot.color_r,
                slot.color_g,
                slot.color_b,
                slot.color_a * 0.5,
            ));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Line,
                x: bx - half,
                y: by - half,
                w: half * 2.0,
                h: half * 2.0,
            });
        }
        cmds
    }
}
