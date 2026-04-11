//! Debug render-command generation for the `Graph` flow-simulation structure.
//!
//! Adds `generate_render_commands` to `Graph` using the same circular node
//! layout as the existing `draw_to_image`.  Pure CPU — no wgpu, winit, or mlua imports.

use crate::graph::core::Graph;
use crate::render::renderer::{DrawMode, RenderCommand};

impl Graph {
    /// Generate debug render commands for the graph using a circular node layout.
    ///
    /// Nodes are positioned on a circle whose radius is 35 % of the smaller
    /// canvas dimension.  Edges are drawn as lines; city-typed nodes use a
    /// red circle, all others use green.
    ///
    /// Returns an empty `Vec` when the graph has no nodes.
    ///
    /// # Parameters
    /// - `width` — `f32`. Canvas width in world pixels used for layout.
    /// - `height` — `f32`. Canvas height in world pixels used for layout.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self, width: f32, height: f32) -> Vec<RenderCommand> {
        let mut node_ids: Vec<u64> = self.nodes.keys().copied().collect();
        node_ids.sort_unstable();
        let n = node_ids.len();
        if n == 0 {
            return Vec::new();
        }

        let cx = width * 0.5;
        let cy = height * 0.5;
        let radius = width.min(height) * 0.35;
        let node_r = 6.0f32;

        let positions: Vec<(f32, f32)> = (0..n)
            .map(|i| {
                let angle =
                    i as f32 * std::f32::consts::PI * 2.0 / n as f32 - std::f32::consts::FRAC_PI_2;
                (cx + radius * angle.cos(), cy + radius * angle.sin())
            })
            .collect();

        let id_to_idx: std::collections::HashMap<u64, usize> = node_ids
            .iter()
            .enumerate()
            .map(|(i, &id)| (id, i))
            .collect();

        let edge_count = self.edges.len();
        let mut cmds = Vec::with_capacity(edge_count * 2 + n * 2 + 2);

        // Edges
        cmds.push(RenderCommand::SetColor(0.3, 0.5, 0.7, 0.7));
        for edge in self.edges.values() {
            if let (Some(&ai), Some(&bi)) =
                (id_to_idx.get(&edge.from_node), id_to_idx.get(&edge.to_node))
            {
                let (ax, ay) = positions[ai];
                let (bx, by) = positions[bi];
                cmds.push(RenderCommand::Line {
                    x1: ax,
                    y1: ay,
                    x2: bx,
                    y2: by,
                });
            }
        }

        // Nodes
        for (i, &nid) in node_ids.iter().enumerate() {
            let (px, py) = positions[i];
            let is_city = self.nodes[&nid].node_type == "city";
            if is_city {
                cmds.push(RenderCommand::SetColor(0.85, 0.25, 0.25, 1.0));
            } else {
                cmds.push(RenderCommand::SetColor(0.25, 0.85, 0.35, 1.0));
            }
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Fill,
                x: px,
                y: py,
                r: node_r,
            });
        }

        cmds
    }
}

// ── Tests ──────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_graph_returns_no_commands() {
        let g = Graph::new();
        assert!(g.generate_render_commands(400.0, 300.0).is_empty());
    }

    #[test]
    fn single_node_emits_commands() {
        let mut g = Graph::new();
        g.add_node("settlement", 10);
        let cmds = g.generate_render_commands(400.0, 300.0);
        assert!(!cmds.is_empty());
    }

    #[test]
    fn draw_to_image_unchanged_dimensions() {
        let g = Graph::new();
        let img = g.draw_to_image(64, 64);
        assert_eq!(img.width(), 64);
        assert_eq!(img.height(), 64);
    }
}
