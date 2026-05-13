use super::emitter::ParticleSystem;
use super::trail::Trail;
use crate::render::renderer::RenderCommand;
impl ParticleSystem {
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        self.build_render_commands(0.0, 0.0)
    }
}
impl Trail {
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        self.build_render_commands()
    }
}
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
