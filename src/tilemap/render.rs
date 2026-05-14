//! Tilemap-to-RenderCommand conversion helpers.
//! Adds `generate_render_commands` to `TileMap` for camera-culled GID-to-color fallback rendering.
//! Does not own the render pipeline; output is handed to the render layer unchanged.
//! Depends on `tilemap` and `render`.

use super::tilemap::TileMap;
use crate::render::renderer::{DrawMode, RenderCommand};

/// Map a GID to a debug-palette RGB triple for fallback colored tile rendering.
fn gid_to_color(gid: u32) -> (f32, f32, f32) {
    if gid >= 10 {
        match gid {
            10 => (200.0 / 255.0, 50.0 / 255.0, 50.0 / 255.0),
            11 => (50.0 / 255.0, 50.0 / 255.0, 200.0 / 255.0),
            12 => (200.0 / 255.0, 200.0 / 255.0, 50.0 / 255.0),
            _ => (1.0, 1.0, 1.0),
        }
    } else {
        match gid {
            1 => (80.0 / 255.0, 160.0 / 255.0, 80.0 / 255.0),
            2 => (60.0 / 255.0, 120.0 / 255.0, 60.0 / 255.0),
            _ => (40.0 / 255.0, 40.0 / 255.0, 40.0 / 255.0),
        }
    }
}
impl TileMap {
    #[allow(clippy::too_many_arguments)]
    #[allow(clippy::manual_clamp)]
    /// Generate camera-culled `RenderCommand` primitives for all visible layers; returns an empty vec when the map has no layers or zero tile size.
    pub fn generate_render_commands(
        &self,
        offset_x: f32,
        offset_y: f32,
        cam_x: f32,
        cam_y: f32,
        cam_w: f32,
        cam_h: f32,
    ) -> Vec<RenderCommand> {
        let mut cmds = Vec::new();
        if self.get_layer_count() == 0 {
            return cmds;
        }
        let tw = self.get_tile_width() as f32;
        let th = self.get_tile_height() as f32;
        if tw <= 0.0 || th <= 0.0 {
            return cmds;
        }
        let tile_x0 = ((cam_x / tw).floor() as i64).max(0) as u32;
        let tile_y0 = ((cam_y / th).floor() as i64).max(0) as u32;
        let tile_x1_cam = ((cam_x + cam_w) / tw).ceil() as u32;
        let tile_y1_cam = ((cam_y + cam_h) / th).ceil() as u32;
        for layer_idx in 0..self.get_layer_count() {
            if !self.get_layer_visible(layer_idx) {
                continue;
            }
            let Some((lw, lh)) = self.get_layer_dimensions(layer_idx) else {
                continue;
            };
            let [lt_r, lt_g, lt_b, lt_a] = self.get_layer_color(layer_idx);
            let x_end = lw.min(tile_x1_cam);
            let y_end = lh.min(tile_y1_cam);
            for ty in tile_y0.min(lh)..y_end {
                for tx in tile_x0.min(lw)..x_end {
                    let gid = self.get_tile(layer_idx, tx, ty);
                    if gid == 0 {
                        continue;
                    }
                    let (gr, gg, gb) = gid_to_color(gid);
                    let cr = gr * lt_r;
                    let cg = gg * lt_g;
                    let cb = gb * lt_b;
                    let ca = lt_a;
                    let world_x = tx as f32 * tw;
                    let world_y = ty as f32 * th;
                    let sx = offset_x + world_x;
                    let sy = offset_y + world_y;
                    cmds.push(RenderCommand::SetColor(cr, cg, cb, ca));
                    if gid >= 10 {
                        cmds.push(RenderCommand::Circle {
                            mode: DrawMode::Fill,
                            x: sx + tw * 0.5,
                            y: sy + th * 0.5,
                            r: (tw * 0.5).min(6.0).max(3.0),
                        });
                    } else {
                        cmds.push(RenderCommand::Rectangle {
                            mode: DrawMode::Fill,
                            x: sx,
                            y: sy,
                            w: tw,
                            h: th,
                        });
                    }
                }
            }
        }
        cmds
    }
}
