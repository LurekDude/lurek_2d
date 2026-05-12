//! GPU render-command generation for the minimap overlay.
//!
//! Pure CPU — no wgpu, winit, or mlua imports.  Generates a flat
//! [`Vec<RenderCommand>`] that the GPU renderer can execute to draw the
//! minimap at any screen position.

use super::minimap::Minimap;
use super::types::{FogLevel, OverlayShape};
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
        let owner_colors = self.owner_colors_by_cell();

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
                let terrain = self.get_terrain(gx, gy);
                let [r, g, b, a] = self.resolve_cell_color(gx, gy, terrain, &owner_colors);

                let (cr, cg, cb, ca) = if fog_enabled {
                    match self.get_fog_level(gx, gy) {
                        FogLevel::Hidden => (fcr, fcg, fcb, fca),
                        FogLevel::Explored => (r, g, b, a * 0.4),
                        FogLevel::Visible => (r, g, b, a),
                    }
                } else {
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

        // ── Overlay geometry ──────────────────────────────────────────────
        for shape in self.overlay_shapes() {
            match shape {
                OverlayShape::Line {
                    x1,
                    y1,
                    x2,
                    y2,
                    color,
                } => {
                    let (sx1, sy1) = self.grid_to_screen(*x1, *y1, screen_x, screen_y);
                    let (sx2, sy2) = self.grid_to_screen(*x2, *y2, screen_x, screen_y);
                    cmds.push(RenderCommand::SetColor(
                        color[0] as f32 / 255.0,
                        color[1] as f32 / 255.0,
                        color[2] as f32 / 255.0,
                        color[3] as f32 / 255.0,
                    ));
                    cmds.push(RenderCommand::Line {
                        x1: sx1,
                        y1: sy1,
                        x2: sx2,
                        y2: sy2,
                    });
                }
                OverlayShape::Rect { x, y, w, h, color } => {
                    let (sx, sy) = self.grid_to_screen(*x, *y, screen_x, screen_y);
                    let (ex, ey) = self.grid_to_screen(*x + *w, *y + *h, screen_x, screen_y);
                    cmds.push(RenderCommand::SetColor(
                        color[0] as f32 / 255.0,
                        color[1] as f32 / 255.0,
                        color[2] as f32 / 255.0,
                        color[3] as f32 / 255.0,
                    ));
                    cmds.push(RenderCommand::Rectangle {
                        mode: DrawMode::Line,
                        x: sx,
                        y: sy,
                        w: (ex - sx).abs(),
                        h: (ey - sy).abs(),
                    });
                }
            }
        }

        // ── Paths ─────────────────────────────────────────────────────────
        for path in self.paths() {
            if path.points.len() < 2 {
                continue;
            }

            cmds.push(RenderCommand::SetColor(
                path.color[0] as f32 / 255.0,
                path.color[1] as f32 / 255.0,
                path.color[2] as f32 / 255.0,
                path.color[3] as f32 / 255.0,
            ));

            for window in path.points.windows(2) {
                let (sx1, sy1) = self.grid_to_screen(window[0].0, window[0].1, screen_x, screen_y);
                let (sx2, sy2) = self.grid_to_screen(window[1].0, window[1].1, screen_x, screen_y);
                cmds.push(RenderCommand::Line {
                    x1: sx1,
                    y1: sy1,
                    x2: sx2,
                    y2: sy2,
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

        // ── Objects ───────────────────────────────────────────────────────
        for object in self.objects_iter() {
            let Some(object_type) = self.object_type(object.type_index) else {
                continue;
            };
            if !object_type.visible {
                continue;
            }

            let (sx, sy) = self.grid_to_screen(object.x, object.y, screen_x, screen_y);
            if let Some(icon) = self.object_type_icon(object.type_index) {
                cmds.push(RenderCommand::DrawImageEx {
                    texture_key: icon.texture_key,
                    x: sx,
                    y: sy,
                    rotation: 0.0,
                    sx: icon.display_width / icon.texture_width,
                    sy: icon.display_height / icon.texture_height,
                    ox: icon.texture_width * 0.5,
                    oy: icon.texture_height * 0.5,
                    effect: None,
                });
                continue;
            }

            cmds.push(RenderCommand::SetColor(
                object_type.color[0],
                object_type.color[1],
                object_type.color[2],
                object_type.color[3],
            ));
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Fill,
                x: sx,
                y: sy,
                r: (cell_px_w.min(cell_px_h) * 0.35).max(3.0),
            });
        }

        // ── Markers ───────────────────────────────────────────────────────
        for (marker_id, marker) in self.markers_with_ids() {
            let (sx, sy) = self.grid_to_screen(marker.x, marker.y, screen_x, screen_y);
            if let Some(icon) = self.marker_icon(*marker_id) {
                cmds.push(RenderCommand::DrawImageEx {
                    texture_key: icon.texture_key,
                    x: sx,
                    y: sy,
                    rotation: 0.0,
                    sx: icon.display_width / icon.texture_width,
                    sy: icon.display_height / icon.texture_height,
                    ox: icon.texture_width * 0.5,
                    oy: icon.texture_height * 0.5,
                    effect: None,
                });
                continue;
            }

            cmds.push(RenderCommand::SetColor(
                marker.color[0],
                marker.color[1],
                marker.color[2],
                marker.color[3],
            ));
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Fill,
                x: sx,
                y: sy,
                r: (cell_px_w.min(cell_px_h) * 0.3).max(3.0),
            });
            cmds.push(RenderCommand::Line {
                x1: sx - 4.0,
                y1: sy,
                x2: sx + 4.0,
                y2: sy,
            });
            cmds.push(RenderCommand::Line {
                x1: sx,
                y1: sy - 4.0,
                x2: sx,
                y2: sy + 4.0,
            });
        }

        cmds
    }
}
