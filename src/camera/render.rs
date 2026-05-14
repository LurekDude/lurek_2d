use crate::camera::types::{Camera, Camera2D};
use crate::render::renderer::RenderCommand;
impl Camera {
    /// Append camera begin-transform commands and return after extending output.
    pub fn append_begin_render_commands(&self, out: &mut Vec<RenderCommand>) {
        out.push(RenderCommand::PushTransform);
        out.push(RenderCommand::Translate {
            x: -self.position.x,
            y: -self.position.y,
        });
        if self.rotation.abs() > f32::EPSILON {
            out.push(RenderCommand::Rotate {
                angle: self.rotation,
            });
        }
        if (self.zoom - 1.0).abs() > f32::EPSILON {
            out.push(RenderCommand::Scale {
                sx: self.zoom,
                sy: self.zoom,
            });
        }
    }
    /// Build begin-transform command list and return it for immediate submission.
    pub fn begin_render_commands(&self) -> Vec<RenderCommand> {
        let mut cmds = Vec::with_capacity(4);
        self.append_begin_render_commands(&mut cmds);
        cmds
    }
    /// Return render command that restores transform stack after camera pass.
    pub fn end_render_command() -> RenderCommand {
        RenderCommand::PopTransform
    }
    /// Wrap scene commands with camera begin/end transforms and return combined list.
    pub fn generate_render_commands(
        &self,
        scene_commands: Vec<RenderCommand>,
    ) -> Vec<RenderCommand> {
        let mut cmds = self.begin_render_commands();
        cmds.extend(scene_commands);
        cmds.push(RenderCommand::PopTransform);
        cmds
    }
}
impl Camera2D {
    /// Append 2D camera begin-transform commands and return after extending output.
    pub fn append_begin_render_commands(&self, out: &mut Vec<RenderCommand>) {
        out.push(RenderCommand::PushTransform);
        let (offset_x, offset_y) = self.render_offset();
        out.push(RenderCommand::Translate {
            x: -self.position.x - offset_x,
            y: -self.position.y - offset_y,
        });
        if self.rotation.abs() > f32::EPSILON {
            out.push(RenderCommand::Rotate {
                angle: self.rotation,
            });
        }
        let eff_zoom = self.effective_zoom();
        if (eff_zoom - 1.0).abs() > f32::EPSILON {
            out.push(RenderCommand::Scale {
                sx: eff_zoom,
                sy: eff_zoom,
            });
        }
    }
    /// Build 2D begin-transform command list and return it for submission.
    pub fn begin_render_commands(&self) -> Vec<RenderCommand> {
        let mut cmds = Vec::with_capacity(4);
        self.append_begin_render_commands(&mut cmds);
        cmds
    }
    /// Return render command that restores transform stack after 2D camera pass.
    pub fn end_render_command() -> RenderCommand {
        RenderCommand::PopTransform
    }
    /// Wrap scene commands with 2D camera transforms and return combined list.
    pub fn generate_render_commands(
        &self,
        scene_commands: Vec<RenderCommand>,
    ) -> Vec<RenderCommand> {
        let mut cmds = self.begin_render_commands();
        cmds.extend(scene_commands);
        cmds.push(RenderCommand::PopTransform);
        cmds
    }
}
