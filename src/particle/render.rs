//! Consolidated render-command interface for the particle module.
//!
//! Pure CPU — no wgpu, winit, or mlua imports.  Provides the standard
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

#[cfg(test)]
mod tests {
    use crate::particle::config::ParticleConfig;
    use crate::particle::emitter::ParticleSystem;
    use crate::particle::trail::Trail;
    use crate::render::renderer::RenderCommand;

    #[test]
    fn empty_system_gives_empty_commands() {
        let sys = ParticleSystem::new(ParticleConfig::default());
        let cmds = sys.generate_render_commands();
        assert!(
            cmds.is_empty(),
            "a new emitter with no particles should produce no commands"
        );
    }

    #[test]
    fn generate_render_commands_matches_build() {
        let sys = ParticleSystem::new(ParticleConfig::default());
        let a = sys.generate_render_commands();
        let b = sys.build_render_commands(0.0, 0.0);
        assert_eq!(
            a.len(),
            b.len(),
            "generate_render_commands must produce the same commands as build_render_commands(0, 0)"
        );
    }

    #[test]
    fn empty_trail_gives_empty_commands() {
        let trail = Trail::new(2.0, 4.0);
        let cmds: Vec<RenderCommand> = trail.generate_render_commands();
        assert!(cmds.is_empty(), "an empty trail should produce no commands");
    }
}
