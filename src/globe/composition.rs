//! Multi-globe split composition helpers.

use crate::globe::registry::GlobeRegistry;
use crate::globe::draw::emit_globe_frame;
use crate::render::renderer::RenderCommand;
use crate::runtime::resource_keys::FontKey;

/// One split-screen viewport description.
#[derive(Debug, Clone, Copy)]
pub struct SplitViewport {
    /// Center X in pixels.
    pub cx: f32,
    /// Center Y in pixels.
    pub cy: f32,
}

/// Emit merged frame commands from multiple globes for tactical/strategic split views.
pub fn emit_split_frame(
    reg: &GlobeRegistry,
    entries: &[(&str, SplitViewport)],
    font: Option<FontKey>,
) -> Vec<RenderCommand> {
    let mut out = Vec::new();
    for (name, vp) in entries {
        if let Some(globe) = reg.get(name) {
            let mut clone = globe.camera.clone();
            clone.screen_cx = vp.cx;
            clone.screen_cy = vp.cy;
            let mut g = emit_globe_frame(
                &globe.spec,
                &clone,
                &globe.graph,
                &globe.fog,
                &globe.markers,
                &globe.labels,
                &globe.layers,
                &globe.heat_layers,
                &globe.arcs,
                globe.active_viewer.as_deref(),
                font,
                globe.sim_time_sec,
            );
            out.append(&mut g);
        }
    }
    out
}
