//! GPU render-command generation for the minimap overlay.
//!
//! Pure CPU — no wgpu, winit, or mlua imports.  Generates a flat
//! [`Vec<RenderCommand>`] that the GPU renderer can execute to draw the
//! minimap at any screen position.

use super::minimap::Minimap;
use super::types::{ColorMode, FogLevel};
use crate::render::renderer::{DrawMode, RenderCommand};

impl Minimap {
    /// Generate render commands to draw the minimap overlay at the given screen position.
    ///
    /// Emits:
    /// 1. A dark background rectangle (`display_width × display_height`).
    /// 2. Per-cell terrain rectangles coloured by terrain type, respecting fog
    ///    of war (hidden cells use the fog colour; explored cells are drawn at
    ///    40 % alpha).
    /// 3. An optional viewport-rectangle outline (if set and visible).
    /// 4. Ping circles (fading by `remaining / duration`).
    ///
    /// Political colour mode falls back to terrain colours because the minimap
    /// data model does not track a per-cell owner; apply owner colours via the
    /// object layer instead.
    ///
    /// # Parameters
    /// - `screen_x` — `f32`. Screen X of the minimap top-left corner.
    /// - `screen_y` — `f32`. Screen Y of the minimap top-left corner.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self, screen_x: f32, screen_y: f32) -> Vec<RenderCommand> {
        let mut cmds = Vec::new();

        let dw = self.display_width() as f32;
        let dh = self.display_height() as f32;
        if dw <= 0.0 || dh <= 0.0 {
            return cmds;
        }

        // ── Background ──────────────────────────────────────────────────
        cmds.push(RenderCommand::SetColor(0.0, 0.0, 0.0, 0.85));
        cmds.push(RenderCommand::Rectangle {
            mode: DrawMode::Fill,
            x: screen_x,
            y: screen_y,
            w: dw,
            h: dh,
        });

        // ── Compute visible cell range ───────────────────────────────────
        let gw = self.grid_width() as f32;
        let gh = self.grid_height() as f32;
        let zoom = self.zoom();
        let cx = self.center_x();
        let cy = self.center_y();

        let cells_vis_x = gw / zoom;
        let cells_vis_y = gh / zoom;
        let cell_px_w = dw / cells_vis_x;
        let cell_px_h = dh / cells_vis_y;

        let start_gx = ((cx - cells_vis_x / 2.0).floor() as i64).max(0) as u32;
        let start_gy = ((cy - cells_vis_y / 2.0).floor() as i64).max(0) as u32;
        let end_gx = ((cx + cells_vis_x / 2.0).ceil() as u32).min(self.grid_width());
        let end_gy = ((cy + cells_vis_y / 2.0).ceil() as u32).min(self.grid_height());

        // ── Terrain cells ────────────────────────────────────────────────
        let fog_enabled = self.fog_enabled();
        let [fcr, fcg, fcb, fca] = self.fog_color();

        for gy in start_gy..end_gy {
            for gx in start_gx..end_gx {
                let (sx, sy) = self.grid_to_screen(gx as f32, gy as f32, screen_x, screen_y);

                let (cr, cg, cb, ca) = if fog_enabled {
                    match self.get_fog_level(gx, gy) {
                        FogLevel::Hidden => (fcr, fcg, fcb, fca),
                        FogLevel::Explored => {
                            let terrain = self.get_terrain(gx, gy);
                            let [r, g, b, a] = self.resolve_cell_color(terrain);
                            (r, g, b, a * 0.4)
                        }
                        FogLevel::Visible => {
                            let terrain = self.get_terrain(gx, gy);
                            let [r, g, b, a] = self.resolve_cell_color(terrain);
                            (r, g, b, a)
                        }
                    }
                } else {
                    let terrain = self.get_terrain(gx, gy);
                    let [r, g, b, a] = self.resolve_cell_color(terrain);
                    (r, g, b, a)
                };

                cmds.push(RenderCommand::SetColor(cr, cg, cb, ca));
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: sx,
                    y: sy,
                    w: cell_px_w,
                    h: cell_px_h,
                });
            }
        }

        // ── Viewport rectangle overlay ───────────────────────────────────
        if self.viewport_visible() {
            if let Some((vx, vy, vw, vh)) = self.viewport_rect() {
                let [vr, vg, vb, va] = self.viewport_color();
                let (sx, sy) = self.grid_to_screen(vx, vy, screen_x, screen_y);
                let (ex, ey) = self.grid_to_screen(vx + vw, vy + vh, screen_x, screen_y);
                cmds.push(RenderCommand::SetColor(vr, vg, vb, va));
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Line,
                    x: sx,
                    y: sy,
                    w: (ex - sx).abs(),
                    h: (ey - sy).abs(),
                });
            }
        }

        // ── Ping circles ─────────────────────────────────────────────────
        let ping_radius = (cell_px_w * 1.5).max(4.0);
        for ping in self.pings() {
            let [pr, pg, pb, pa] = ping.color;
            let fade = if ping.duration > 0.0 {
                ping.remaining / ping.duration
            } else {
                1.0
            };
            let (sx, sy) = self.grid_to_screen(ping.x, ping.y, screen_x, screen_y);
            cmds.push(RenderCommand::SetColor(pr, pg, pb, pa * fade));
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Line,
                x: sx,
                y: sy,
                r: ping_radius,
            });
        }

        cmds
    }

    /// Resolve the display colour for a cell based on the current color mode.
    ///
    /// Political colour mode falls back to the terrain colour because the
    /// Minimap data model does not store a per-cell owner map.
    ///
    /// # Parameters
    /// - `terrain_type` — `u32`.
    ///
    /// # Returns
    /// `[f32; 4]`.
    fn resolve_cell_color(&self, terrain_type: u32) -> [f32; 4] {
        match self.color_mode() {
            ColorMode::Terrain | ColorMode::Political => self.get_terrain_color(terrain_type),
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::minimap::minimap::Minimap;
    use crate::render::renderer::{DrawMode, RenderCommand};

    #[test]
    fn empty_minimap_emits_background() {
        let map = Minimap::new(10, 10, 100, 100);
        let cmds = map.generate_render_commands(0.0, 0.0);
        assert!(!cmds.is_empty(), "expected at least a background rectangle");
        assert!(
            cmds.iter().any(|c| matches!(
                c,
                RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    ..
                }
            )),
            "expected a Fill rectangle for background"
        );
    }

    #[test]
    fn no_pings_no_circle_commands() {
        let map = Minimap::new(8, 8, 80, 80);
        let cmds = map.generate_render_commands(0.0, 0.0);
        assert!(
            !cmds
                .iter()
                .any(|c| matches!(c, RenderCommand::Circle { .. })),
            "expected no Circle commands when there are no pings"
        );
    }

    #[test]
    fn ping_produces_circle_command() {
        let mut map = Minimap::new(8, 8, 80, 80);
        map.add_ping(4.0, 4.0, 1.0, [1.0, 0.0, 0.0, 1.0]);
        let cmds = map.generate_render_commands(0.0, 0.0);
        assert!(
            cmds.iter()
                .any(|c| matches!(c, RenderCommand::Circle { .. })),
            "expected a Circle command for the ping"
        );
    }

    #[test]
    fn viewport_rect_produces_line_rectangle() {
        let mut map = Minimap::new(10, 10, 100, 100);
        map.set_viewport_rect(2.0, 2.0, 4.0, 4.0);
        let cmds = map.generate_render_commands(0.0, 0.0);
        assert!(
            cmds.iter().any(|c| matches!(
                c,
                RenderCommand::Rectangle {
                    mode: DrawMode::Line,
                    ..
                }
            )),
            "expected a Line rectangle for the viewport overlay"
        );
    }
}
