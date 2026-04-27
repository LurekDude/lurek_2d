//! GPU render-command generation for TileMap layers.
//!
//! Pure CPU — no wgpu, winit, or mlua imports.  Emits one `SetColor +
//! Rectangle` (or `Circle` for object tiles ≥ 10) per visible non-empty tile
//! across all layers, using the same fallback colour table as
//! [`TileMap::draw_to_image`](super::tilemap::TileMap::draw_to_image).

use super::tilemap::TileMap;
use crate::render::renderer::{DrawMode, RenderCommand};

/// Map a GID to a fallback RGB colour triple (0.0–1.0), matching the
/// colour table used by [`TileMap::draw_to_image`].
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
    /// Generate render commands for the tile map at the given screen offset.
    ///
    /// Iterates all visible layers bottom-to-top.  Each non-empty tile is
    /// emitted as `SetColor + Rectangle(Fill)`, using the same fallback colour
    /// table as [`draw_to_image`](Self::draw_to_image) when no tileset texture
    /// is available.  Object tiles (GID ≥ 10) are drawn as `Circle` commands
    /// to distinguish them from terrain tiles.  The layer tint is multiplied
    /// into each tile colour.
    ///
    /// Pass `cam_x / cam_y / cam_w / cam_h` to cull tiles outside the camera
    /// viewport (pass `0, 0, f32::MAX, f32::MAX` to disable culling).
    ///
    /// # Parameters
    /// - `offset_x` — `f32`. World-to-screen X offset in pixels.
    /// - `offset_y` — `f32`. World-to-screen Y offset in pixels.
    /// - `cam_x` — `f32`. Left edge of the camera viewport in world pixels.
    /// - `cam_y` — `f32`. Top edge of the camera viewport in world pixels.
    /// - `cam_w` — `f32`. Width of the camera viewport in world pixels.
    /// - `cam_h` — `f32`. Height of the camera viewport in world pixels.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    #[allow(clippy::too_many_arguments)]
    #[allow(clippy::manual_clamp)]
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

        // Camera-space tile range (conservative).
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
                        // Object tile — circle centred on the tile cell.
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
