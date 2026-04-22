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

/// Expand particle render commands for textured particles.
///
/// Walks a list of [`RenderCommand`]s produced by
/// [`ParticleSystem::build_render_commands`].  Each
/// [`DrawParticleSystem`](RenderCommand::DrawParticleSystem) batch is split:
///
/// * **Textured particles** are expanded into individual
///   [`DrawQuad`](RenderCommand::DrawQuad) or
///   [`DrawImageEx`](RenderCommand::DrawImageEx) commands so that per-sprite
///   texture regions are respected.
/// * **Untextured particles** remain batched in a single
///   `DrawParticleSystem` for efficient GPU tessellation.
///
/// Non-particle commands are forwarded unchanged.
///
/// # Parameters
/// - `cmds` — `Vec<RenderCommand>`. The raw commands from the particle system.
///
/// # Returns
/// `Vec<RenderCommand>` — the expanded command list ready for the GPU queue.
pub fn expand_particle_commands(cmds: Vec<RenderCommand>) -> Vec<RenderCommand> {
    let mut out = Vec::with_capacity(cmds.len());
    for cmd in cmds {
        if let RenderCommand::DrawParticleSystem { particles } = cmd {
            let mut untextured = Vec::new();
            for p in &particles {
                if let Some(tex_key) = p.texture_key {
                    if let Some([qx, qy, qw, qh]) = p.quad {
                        let (tex_w, tex_h) = p.quad_tex_dims.unwrap_or((qw, qh));
                        let scale = if qw > 0.0 { p.size / qw } else { 1.0 };
                        out.push(RenderCommand::DrawQuad {
                            texture_key: tex_key,
                            quad_x: qx,
                            quad_y: qy,
                            quad_w: qw,
                            quad_h: qh,
                            tex_w,
                            tex_h,
                            x: p.x,
                            y: p.y,
                            rotation: p.rotation,
                            sx: scale,
                            sy: scale,
                            ox: p.size * 0.5,
                            oy: p.size * 0.5,
                            effect: None,
                        });
                    } else {
                        out.push(RenderCommand::DrawImageEx {
                            texture_key: tex_key,
                            x: p.x,
                            y: p.y,
                            rotation: p.rotation,
                            sx: 1.0,
                            sy: 1.0,
                            ox: p.size * 0.5,
                            oy: p.size * 0.5,
                            effect: None,
                        });
                    }
                } else {
                    untextured.push(p.clone());
                }
            }
            if !untextured.is_empty() {
                out.push(RenderCommand::DrawParticleSystem {
                    particles: untextured,
                });
            }
        } else {
            out.push(cmd);
        }
    }
    out
}
