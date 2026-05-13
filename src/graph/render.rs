use crate::graph::core::Graph;
use crate::render::renderer::{DrawMode, RenderCommand};
impl Graph {
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
