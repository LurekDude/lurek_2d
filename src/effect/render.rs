//! - Render-command integration for the post-effects stack.
//! - Emits begin/end/apply command sequences consumed by the renderer.
//! - Skips command generation when no effects are enabled.

use crate::effect::stack::PostFxStack;
use crate::render::renderer::RenderCommand;

/// Render-command generation for post-effect capture and application.
impl PostFxStack {
    /// Builds the command that starts post-effect capture for a stack id.
    pub fn begin_capture_command(&self, stack_id: u64) -> RenderCommand {
        RenderCommand::BeginPostFx { stack_id }
    }
    /// Builds the command that ends post-effect capture for a stack id.
    pub fn end_capture_command(&self, stack_id: u64) -> RenderCommand {
        RenderCommand::EndPostFx { stack_id }
    }
    /// Builds the command that applies the captured stack output at the stack dimensions.
    pub fn apply_command(&self, stack_id: u64) -> RenderCommand {
        RenderCommand::ApplyPostFx {
            stack_id,
            passes: Vec::new(),
            width: self.width,
            height: self.height,
        }
    }
    /// Emits the capture and apply command sequence when the stack has enabled effects.
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
