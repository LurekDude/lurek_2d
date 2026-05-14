
use crate::pathfind::flow_field::FlowField;
use crate::pathfind::influence_map::InfluenceMap;
use crate::pathfind::nav_grid::NavGrid;
use crate::render::renderer::{DrawMode, RenderCommand};
/// Debug render for `NavGrid` as coloured filled tiles.
impl NavGrid {
    /// Return `RenderCommand`s that draw each cell as a red (blocked) or dark-blue (walkable) tile.
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
/// Debug render for `FlowField` as directional arrows.
impl FlowField {
    /// Return `RenderCommand`s drawing flow arrows coloured by cost-to-target; dots for impassable cells.
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
                    cmds.push(RenderCommand::SetColor(0.3, 0.1, 0.1, 0.5));
                    cmds.push(RenderCommand::Circle {
                        mode: DrawMode::Fill,
                        x: cx,
                        y: cy,
                        r: 1.0,
                    });
                } else {
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
/// Debug render for `InfluenceMap` layers.
impl InfluenceMap {
    /// Return `RenderCommand`s drawing influence values as green (positive) or red (negative) tiles.
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
