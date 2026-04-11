//! GPU render-command generation for skeletal animation skeletons.
//!
//! Pure CPU — no wgpu, winit, or mlua imports.  Visualises a [`Skeleton`]
//! as bone-position circles and slot-tinted rectangles so the rig can be
//! inspected as a debug overlay without a texture atlas.

use super::skeleton::Skeleton;
use crate::render::renderer::{DrawMode, RenderCommand};

impl Skeleton {
    /// Generate debug render commands for the skeleton at the given world position.
    ///
    /// For each bone:
    /// - A small `Circle` is drawn at the bone's world-space position
    ///   (`x + bone.world_x`, `y + bone.world_y`), scaled by the skeleton's
    ///   root scale.  The circle colour comes from the first slot that
    ///   references the bone (white if no matching slot exists).
    ///
    /// For each slot with an attachment name:
    /// - A small `Rectangle` is drawn at the owning bone's world position as a
    ///   placeholder for the attachment bounds.
    ///
    /// Call [`Skeleton::update_world_transforms`] before this method so that
    /// world-space bone positions are up-to-date.
    ///
    /// # Parameters
    /// - `x` — `f32`. World X offset applied to all bone positions.
    /// - `y` — `f32`. World Y offset applied to all bone positions.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self, x: f32, y: f32) -> Vec<RenderCommand> {
        let mut cmds = Vec::new();
        if self.bones.is_empty() {
            return cmds;
        }

        let radius = 4.0 * self.scale_x.abs().max(self.scale_y.abs()).max(1.0);

        // Build a quick per-bone colour lookup from slots.
        let mut bone_colors: Vec<Option<[f32; 4]>> = vec![None; self.bones.len()];
        for slot in &self.slots {
            if slot.bone_index < self.bones.len() && bone_colors[slot.bone_index].is_none() {
                bone_colors[slot.bone_index] =
                    Some([slot.color_r, slot.color_g, slot.color_b, slot.color_a]);
            }
        }

        // ── Bone circles ─────────────────────────────────────────────────
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

        // ── Slot attachment placeholders ──────────────────────────────────
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

#[cfg(test)]
mod tests {
    use crate::render::renderer::{DrawMode, RenderCommand};
    use crate::spine::bone::Bone;
    use crate::spine::skeleton::Skeleton;

    fn make_skeleton_with_bone() -> Skeleton {
        let mut skel = Skeleton::new("test");
        let mut bone = Bone::new("root");
        // Set world transform directly (update_world_transforms would normally compute these).
        bone.world_x = 10.0;
        bone.world_y = 20.0;
        skel.bones.push(bone);
        skel
    }

    #[test]
    fn empty_skeleton_gives_no_commands() {
        let skel = Skeleton::new("empty");
        let cmds = skel.generate_render_commands(0.0, 0.0);
        assert!(cmds.is_empty(), "empty skeleton should produce no commands");
    }

    #[test]
    fn skeleton_with_bone_produces_circle() {
        let skel = make_skeleton_with_bone();
        let cmds = skel.generate_render_commands(0.0, 0.0);
        assert!(
            cmds.iter().any(|c| matches!(
                c,
                RenderCommand::Circle {
                    mode: DrawMode::Fill,
                    ..
                }
            )),
            "expected a Fill circle for the bone"
        );
    }

    #[test]
    fn world_offset_shifts_bone_position() {
        let skel = make_skeleton_with_bone();
        let cmds_zero = skel.generate_render_commands(0.0, 0.0);
        let cmds_offset = skel.generate_render_commands(100.0, 0.0);

        let extract_circle_x = |cmds: &[RenderCommand]| -> f32 {
            cmds.iter()
                .find_map(|c| {
                    if let RenderCommand::Circle { x, .. } = c {
                        Some(*x)
                    } else {
                        None
                    }
                })
                .unwrap_or(0.0)
        };

        let x0 = extract_circle_x(&cmds_zero);
        let x1 = extract_circle_x(&cmds_offset);
        assert!(
            (x1 - x0 - 100.0).abs() < 0.01,
            "offset x should shift circle x by 100, got {x0} → {x1}"
        );
    }
}
