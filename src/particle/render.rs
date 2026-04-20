//! Consolidated render-command interface for the particle module.
//!
//! Pure CPU â€” no wgpu, winit, or mlua imports.  Provides the standard
//! `generate_render_commands()` wrapper on [`ParticleSystem`] and
//! [`Trail`] that delegates to the existing `build_render_commands()`
//! methods with a zero world offset.

use super::emitter::ParticleSystem;
use super::trail::Trail;
use crate::render::renderer::RenderCommand;

impl ParticleSystem {
    /// Generate render commands for all live particles at world origin.
    ///
    /// Convenience wrapper around
    /// [`build_render_commands(0.0, 0.0)`](Self::build_render_commands)
    /// that satisfies the standard `generate_render_commands()` contract
    /// used across engine modules.  The returned
    /// [`RenderCommand::DrawParticleSystem`] batches all live particle
    /// instances into a single GPU draw call.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        self.build_render_commands(0.0, 0.0)
    }
}

impl Trail {
    /// Generate render commands for the trail ribbon.
    ///
    /// Convenience alias for [`build_render_commands`](Self::build_render_commands)
    /// that satisfies the standard `generate_render_commands()` contract
    /// used across engine modules.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        self.build_render_commands()
    }
}

