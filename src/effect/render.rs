//! Render-command generation for post-processing effects.
//!
//! Converts a [`PostFxStack`] into the `BeginPostFx` / `EndPostFx` /
//! `ApplyPostFx` render commands that bracket scene capture and shader
//! application.  Pure CPU — no wgpu, winit, or mlua.

use crate::effect::stack::PostFxStack;
use crate::render::renderer::RenderCommand;

impl PostFxStack {
    /// Returns the `BeginPostFx` command that starts scene capture.
    ///
    /// After this command, all subsequent draw calls are redirected to
    /// the post-processing capture canvas until [`end_capture_command`]
    /// is emitted.
    ///
    /// # Parameters
    /// - `stack_id` — `u64`. Identifier for the stack in GPU state.
    ///
    /// # Returns
    /// `RenderCommand`.
    pub fn begin_capture_command(&self, stack_id: u64) -> RenderCommand {
        RenderCommand::BeginPostFx { stack_id }
    }

    /// Returns the `EndPostFx` command that stops scene capture.
    ///
    /// # Parameters
    /// - `stack_id` — `u64`. Identifier for the stack in GPU state.
    ///
    /// # Returns
    /// `RenderCommand`.
    pub fn end_capture_command(&self, stack_id: u64) -> RenderCommand {
        RenderCommand::EndPostFx { stack_id }
    }

    /// Returns the `ApplyPostFx` command that applies all enabled effects.
    ///
    /// The GPU renderer will iterate enabled effects in the stack and run
    /// each shader pass through the ping-pong canvas chain.
    ///
    /// # Parameters
    /// - `stack_id` — `u64`. Identifier for the stack in GPU state.
    ///
    /// # Returns
    /// `RenderCommand`.
    pub fn apply_command(&self, stack_id: u64) -> RenderCommand {
        RenderCommand::ApplyPostFx {
            stack_id,
            passes: Vec::new(),
            width: self.width,
            height: self.height,
        }
    }

    /// Returns the full sequence of render commands for the effect stack.
    ///
    /// The returned vec is `[BeginPostFx, EndPostFx, ApplyPostFx]`.
    /// The caller inserts scene draw commands between index 0 and 1.
    ///
    /// # Parameters
    /// - `stack_id` — `u64`. Identifier for the stack in GPU state.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self, stack_id: u64) -> Vec<RenderCommand> {
        if self.effects.is_empty() {
            return Vec::new();
        }

        let has_enabled = self.enabled.iter().any(|&e| e);
        if !has_enabled {
            return Vec::new();
        }

        vec![
            self.begin_capture_command(stack_id),
            self.end_capture_command(stack_id),
            self.apply_command(stack_id),
        ]
    }
}

// ── Tests ────────────────────────────────────────────────────────────────────
