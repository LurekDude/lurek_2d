//! Render-command generation for camera transforms.
//!
//! Converts a [`Camera`] or [`Camera2D`] into transform-stack
//! [`RenderCommand`]s (push/translate/scale/rotate/pop).
//! Pure CPU — no wgpu, winit, or mlua.

use crate::camera::types::{Camera, Camera2D};
use crate::render::renderer::RenderCommand;

impl Camera {
    /// Appends begin-transform camera commands into an existing command buffer.
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

    /// Produces transform-stack render commands for this camera.
    ///
    /// Returns a `PushTransform`, then `Translate` (negate position),
    /// `Rotate`, `Scale` (zoom), ready for the caller to append draw
    /// commands and finish with `PopTransform`.
    ///
    /// The returned vec does **not** include `PopTransform` — the caller
    /// must pair each `begin_render_commands()` with a `PopTransform`
    /// after all scene draw calls.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn begin_render_commands(&self) -> Vec<RenderCommand> {
        let mut cmds = Vec::with_capacity(4);
        self.append_begin_render_commands(&mut cmds);
        cmds
    }

    /// Returns the `PopTransform` command that closes the camera scope.
    ///
    /// # Returns
    /// `RenderCommand`.
    pub fn end_render_command() -> RenderCommand {
        RenderCommand::PopTransform
    }

    /// Wrap `scene_commands` in the camera's transform scope.
    ///
    /// Produces `[PushTransform, Translate, (Rotate)?, (Scale)?, ...scene_commands..., PopTransform]`.
    /// Convenience wrapper around `begin_render_commands()` / `end_render_command()`.
    ///
    /// # Parameters
    /// - `scene_commands` — `Vec<RenderCommand>`. Draw calls to wrap.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
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
    /// Appends begin-transform camera commands into an existing command buffer.
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

    /// Produces transform-stack render commands for this camera.
    ///
    /// Includes the effective zoom (with pulse and breathing effects) and
    /// position offsets (including sway and shake).
    ///
    /// Returns a `PushTransform`, then `Translate` (negate position + sway + shake),
    /// `Rotate`, `Scale` (effective zoom), ready for the caller to append draw
    /// commands and finish with `PopTransform`.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn begin_render_commands(&self) -> Vec<RenderCommand> {
        let mut cmds = Vec::with_capacity(4);
        self.append_begin_render_commands(&mut cmds);
        cmds
    }

    /// Returns the `PopTransform` command that closes the camera scope.
    ///
    /// # Returns
    /// `RenderCommand`.
    pub fn end_render_command() -> RenderCommand {
        RenderCommand::PopTransform
    }

    /// Wrap `scene_commands` in the camera's transform scope.
    ///
    /// Produces `[PushTransform, Translate, (Rotate)?, (Scale)?, ...scene_commands..., PopTransform]`.
    /// Convenience wrapper around `begin_render_commands()` / `end_render_command()`.
    ///
    /// # Parameters
    /// - `scene_commands` — `Vec<RenderCommand>`. Draw calls to wrap.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
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
