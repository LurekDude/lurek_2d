//! Render-command generation for camera transforms.
//!
//! Converts a [`Camera`] or [`Camera2D`] into transform-stack
//! [`RenderCommand`]s (push/translate/scale/rotate/pop).
//! Pure CPU — no wgpu, winit, or mlua.

use crate::camera::types::{Camera, Camera2D};
use crate::render::renderer::RenderCommand;

impl Camera {
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
        cmds.push(RenderCommand::PushTransform);
        cmds.push(RenderCommand::Translate {
            x: -self.position.x,
            y: -self.position.y,
        });
        if self.rotation.abs() > f32::EPSILON {
            cmds.push(RenderCommand::Rotate {
                angle: self.rotation,
            });
        }
        if (self.zoom - 1.0).abs() > f32::EPSILON {
            cmds.push(RenderCommand::Scale {
                sx: self.zoom,
                sy: self.zoom,
            });
        }
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
    /// Produces transform-stack render commands for this camera.
    ///
    /// Returns a `PushTransform`, then `Translate` (negate position + shake),
    /// `Rotate`, `Scale` (zoom), ready for the caller to append draw
    /// commands and finish with `PopTransform`.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn begin_render_commands(&self) -> Vec<RenderCommand> {
        let mut cmds = Vec::with_capacity(4);
        cmds.push(RenderCommand::PushTransform);
        cmds.push(RenderCommand::Translate {
            x: -self.position.x,
            y: -self.position.y,
        });
        if self.rotation.abs() > f32::EPSILON {
            cmds.push(RenderCommand::Rotate {
                angle: self.rotation,
            });
        }
        if (self.zoom - 1.0).abs() > f32::EPSILON {
            cmds.push(RenderCommand::Scale {
                sx: self.zoom,
                sy: self.zoom,
            });
        }
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

// ── Tests ────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use crate::camera::types::{Camera, Camera2D};
    use crate::math::Vec2;

    #[test]
    fn camera_default_emits_push_and_translate_only() {
        let cam = Camera::default();
        let cmds = cam.begin_render_commands();
        assert_eq!(cmds.len(), 2); // PushTransform + Translate(0,0)
        assert!(matches!(cmds[0], RenderCommand::PushTransform));
        assert!(matches!(cmds[1], RenderCommand::Translate { .. }));
    }

    #[test]
    fn camera_with_zoom_emits_scale() {
        let cam = Camera::new(Vec2::ZERO, 2.0, 0.0);
        let cmds = cam.begin_render_commands();
        assert!(cmds.iter().any(|c| matches!(c, RenderCommand::Scale { .. })));
    }

    #[test]
    fn camera_with_rotation_emits_rotate() {
        let cam = Camera::new(Vec2::ZERO, 1.0, 0.5);
        let cmds = cam.begin_render_commands();
        assert!(cmds.iter().any(|c| matches!(c, RenderCommand::Rotate { .. })));
    }

    #[test]
    fn camera2d_emits_transform_stack() {
        let mut cam = Camera2D::new(800.0, 600.0);
        cam.set_position(100.0, 200.0);
        cam.set_zoom(1.5);
        cam.set_rotation(0.3);

        let cmds = cam.begin_render_commands();
        assert!(matches!(cmds[0], RenderCommand::PushTransform));
        if let RenderCommand::Translate { x, y } = cmds[1] {
            assert!((x - (-100.0)).abs() < 1e-5);
            assert!((y - (-200.0)).abs() < 1e-5);
        } else {
            panic!("Expected Translate");
        }
        assert!(cmds.iter().any(|c| matches!(c, RenderCommand::Rotate { .. })));
        assert!(cmds.iter().any(|c| matches!(c, RenderCommand::Scale { .. })));
    }

    #[test]
    fn end_returns_pop_transform() {
        let cmd = Camera::end_render_command();
        assert!(matches!(cmd, RenderCommand::PopTransform));
    }
}
