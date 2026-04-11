//! Debug render-command generation for pathfinding data structures.
//!
//! Adds `generate_render_commands` to `NavGrid`, `FlowField`, and `InfluenceMap`.
//! Pure CPU — no wgpu, winit, or mlua imports.

use crate::pathfind::flow_field::FlowField;
use crate::pathfind::influence_map::InfluenceMap;
use crate::pathfind::nav_grid::NavGrid;
use crate::render::renderer::{DrawMode, RenderCommand};

// ── NavGrid ───────────────────────────────────────────────────────────────────

impl NavGrid {
    /// Generate debug render commands visualising the navigation grid.
    ///
    /// Each cell is drawn as a solid rectangle:
    /// - dark grey — walkable  
    /// - red — blocked
    ///
    /// # Parameters
    /// - `cell_size` — `f32`. Screen-space size of one cell in pixels.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self, cell_size: f32) -> Vec<RenderCommand> {
        let w = self.get_width();
        let h = self.get_height();
        let total = (w * h) as usize;
        if total == 0 {
            return Vec::new();
        }

        let mut cmds = Vec::with_capacity(total * 2);

        for y in 0..h {
            for x in 0..w {
                let blocked = self.is_blocked(x, y);
                if blocked {
                    cmds.push(RenderCommand::SetColor(0.75, 0.1, 0.1, 0.8));
                } else {
                    cmds.push(RenderCommand::SetColor(0.15, 0.15, 0.2, 0.6));
                }
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: x as f32 * cell_size,
                    y: y as f32 * cell_size,
                    w: cell_size - 1.0,
                    h: cell_size - 1.0,
                });
            }
        }

        cmds
    }
}

// ── FlowField ─────────────────────────────────────────────────────────────────

impl FlowField {
    /// Generate debug render commands visualising flow directions.
    ///
    /// Each cell is drawn as a short directional line (arrow stub) using
    /// the precomputed flow vector.  Unreachable cells emit a tiny centred dot.
    ///
    /// # Parameters
    /// - `cell_size` — `f32`. Screen-space size of one cell in pixels.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self, cell_size: f32) -> Vec<RenderCommand> {
        let w = self.get_width();
        let h = self.get_height();
        let total = (w * h) as usize;
        if total == 0 || !self.is_calculated() {
            return Vec::new();
        }

        let half = cell_size * 0.5;
        let arrow_len = half * 0.8;
        let mut cmds = Vec::with_capacity(total * 3);

        for y in 0..h {
            for x in 0..w {
                let cx = x as f32 * cell_size + half;
                let cy = y as f32 * cell_size + half;

                let (dx, dy) = self.get_direction(x, y);
                if dx == 0.0 && dy == 0.0 {
                    // Unreachable — draw a dim dot
                    cmds.push(RenderCommand::SetColor(0.3, 0.1, 0.1, 0.5));
                    cmds.push(RenderCommand::Circle {
                        mode: DrawMode::Fill,
                        x: cx,
                        y: cy,
                        r: 1.0,
                    });
                } else {
                    // Colour by cost (cool=low, warm=high, capped at 255)
                    let cost = self.get_cost_to_target(x, y);
                    let t = (cost / 64.0).clamp(0.0, 1.0);
                    cmds.push(RenderCommand::SetColor(t, 1.0 - t, 0.5, 0.9));
                    cmds.push(RenderCommand::Line {
                        x1: cx,
                        y1: cy,
                        x2: cx + dx * arrow_len,
                        y2: cy + dy * arrow_len,
                    });
                }
            }
        }

        cmds
    }
}

// ── InfluenceMap ──────────────────────────────────────────────────────────────

impl InfluenceMap {
    /// Generate debug render commands visualising one influence layer as a heatmap.
    ///
    /// Positive influence is green; negative is red; zero is transparent.
    /// Intensity maps to the alpha channel.
    ///
    /// # Parameters
    /// - `layer` — `&str`. Name of the layer to visualise.
    /// - `cell_size` — `f32`. Screen-space size of one cell in pixels.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self, layer: &str, cell_size: f32) -> Vec<RenderCommand> {
        let w = self.get_width();
        let h = self.get_height();
        if w == 0 || h == 0 {
            return Vec::new();
        }

        let mut cmds = Vec::with_capacity(w * h * 2);

        for y in 0..h {
            for x in 0..w {
                let inf = self.get_influence(layer, x, y);
                if inf.abs() < 1e-4 {
                    continue;
                }
                let alpha = inf.abs().clamp(0.0, 1.0);
                if inf > 0.0 {
                    cmds.push(RenderCommand::SetColor(0.1, 0.9, 0.2, alpha));
                } else {
                    cmds.push(RenderCommand::SetColor(0.9, 0.1, 0.1, alpha));
                }
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: x as f32 * cell_size,
                    y: y as f32 * cell_size,
                    w: cell_size,
                    h: cell_size,
                });
            }
        }

        cmds
    }
}

// ── Tests ──────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;
    use std::rc::Rc;

    fn make_grid(w: u32, h: u32) -> NavGrid {
        NavGrid::new(w, h)
    }

    #[test]
    fn nav_grid_render_commands_empty_grid_returns_empty() {
        let g = make_grid(0, 0);
        assert!(g.generate_render_commands(8.0).is_empty());
    }

    #[test]
    fn nav_grid_render_commands_count() {
        let g = make_grid(4, 4);
        // 16 cells × 2 commands each
        assert_eq!(g.generate_render_commands(8.0).len(), 32);
    }

    #[test]
    fn flow_field_uncalculated_returns_empty() {
        let g = Rc::new(RefCell::new(NavGrid::new(4, 4)));
        let ff = FlowField::new(g);
        assert!(ff.generate_render_commands(8.0).is_empty());
    }

    #[test]
    fn influence_map_empty_layer_returns_no_commands() {
        let im = InfluenceMap::new(4, 4, 1.0);
        assert!(im.generate_render_commands("nonexistent", 8.0).is_empty());
    }
}
