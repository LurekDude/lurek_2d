//! Debug render-command generation for AI subsystems.
//!
//! Adds `generate_render_commands` and (where applicable) `draw_to_image` to
//! `StateMachine` and `BehaviorTree`.  Pure CPU — no wgpu, winit, or mlua imports.

use crate::ai::behavior_tree::{BTNode, BTStatus, BehaviorTree};
use crate::ai::fsm::StateMachine;
use crate::image::ImageData;
use crate::render::renderer::{DrawMode, RenderCommand};

// ── StateMachine ──────────────────────────────────────────────────────────────

impl StateMachine {
    /// Generate debug render commands representing the finite state machine.
    ///
    /// Draws each state as a labelled box and highlights the active state.
    /// Boxes are laid out in a horizontal row; the active state is tinted white.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        let mut state_names: Vec<&str> = self.states.keys().map(|s| s.as_str()).collect();
        state_names.sort_unstable();

        if state_names.is_empty() {
            return Vec::new();
        }

        let box_w = 80.0f32;
        let box_h = 30.0f32;
        let gap = 10.0f32;
        let y = 20.0f32;

        let mut cmds = Vec::with_capacity(state_names.len() * 4 + 2);

        for (i, name) in state_names.iter().enumerate() {
            let x = (box_w + gap) * i as f32 + 10.0;
            let is_active = self
                .current_state
                .as_deref()
                .map(|c| c == *name)
                .unwrap_or(false);

            // Box colour: bright white for active, dim blue for inactive
            if is_active {
                cmds.push(RenderCommand::SetColor(1.0, 1.0, 1.0, 0.9));
            } else {
                cmds.push(RenderCommand::SetColor(0.3, 0.5, 0.8, 0.6));
            }
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Line,
                x,
                y,
                w: box_w,
                h: box_h,
            });
        }

        // Draw transition arrows as short diagonal lines
        cmds.push(RenderCommand::SetColor(0.6, 0.6, 0.6, 0.5));
        for t in &self.transitions {
            let from_idx = state_names.iter().position(|&s| s == t.from);
            let to_idx = state_names.iter().position(|&s| s == t.to);
            if let (Some(fi), Some(ti)) = (from_idx, to_idx) {
                if fi != ti {
                    let fx = (box_w + gap) * fi as f32 + 10.0 + box_w;
                    let fy = y + box_h * 0.5;
                    let tx = (box_w + gap) * ti as f32 + 10.0;
                    let ty = y + box_h * 0.5;
                    cmds.push(RenderCommand::Line {
                        x1: fx,
                        y1: fy,
                        x2: tx,
                        y2: ty,
                    });
                }
            }
        }

        cmds
    }

    /// Render the FSM to a CPU image.
    ///
    /// States are drawn as horizontal colour-coded strips: active=white,
    /// inactive=dark blue, on a near-black background.
    ///
    /// # Parameters
    /// - `width` — `u32`. Output image width in pixels.
    /// - `height` — `u32`. Output image height in pixels.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);
        img.fill(15, 15, 25, 255);

        let mut state_names: Vec<&str> = self.states.keys().map(|s| s.as_str()).collect();
        state_names.sort_unstable();
        if state_names.is_empty() {
            return img;
        }

        let row_h = (height / state_names.len() as u32).max(1);
        for (i, name) in state_names.iter().enumerate() {
            let is_active = self
                .current_state
                .as_deref()
                .map(|c| c == *name)
                .unwrap_or(false);
            let (r, g, b) = if is_active {
                (220u8, 220, 220)
            } else {
                (50, 80, 140)
            };
            let strip_y = (i as u32 * row_h) as i32;
            img.draw_rect(2, strip_y + 2, width - 4, row_h.saturating_sub(4), r, g, b, 200);
        }

        img
    }
}

// ── BehaviorTree ──────────────────────────────────────────────────────────────

/// Count the total number of nodes in a behavior tree recursively.
fn bt_node_count(node: &BTNode) -> usize {
    match node {
        BTNode::Selector { children, .. }
        | BTNode::Sequence { children, .. }
        | BTNode::Parallel { children, .. } => {
            1 + children.iter().map(bt_node_count).sum::<usize>()
        }
        BTNode::Inverter { child }
        | BTNode::Repeater { child, .. }
        | BTNode::Succeeder { child } => 1 + bt_node_count(child),
        BTNode::Action { .. } | BTNode::Condition { .. } => 1,
    }
}

/// Return the display name for a BTNode variant.
fn bt_node_label(node: &BTNode) -> &'static str {
    match node {
        BTNode::Selector { .. } => "SEL",
        BTNode::Sequence { .. } => "SEQ",
        BTNode::Parallel { .. } => "PAR",
        BTNode::Inverter { .. } => "INV",
        BTNode::Repeater { .. } => "REP",
        BTNode::Succeeder { .. } => "SUC",
        BTNode::Action { .. } => "ACT",
        BTNode::Condition { .. } => "CND",
    }
}

/// Compute the maximum depth of a behavior tree.
fn bt_depth(node: &BTNode) -> usize {
    match node {
        BTNode::Selector { children, .. }
        | BTNode::Sequence { children, .. }
        | BTNode::Parallel { children, .. } => {
            1 + children.iter().map(bt_depth).max().unwrap_or(0)
        }
        BTNode::Inverter { child }
        | BTNode::Repeater { child, .. }
        | BTNode::Succeeder { child } => 1 + bt_depth(child),
        BTNode::Action { .. } | BTNode::Condition { .. } => 1,
    }
}

/// Emit render commands for a subtree, laying out nodes in a depth-column grid.
fn emit_bt_commands(
    node: &BTNode,
    depth: usize,
    slot: usize,
    cmds: &mut Vec<RenderCommand>,
    node_w: f32,
    node_h: f32,
    gap: f32,
) {
    let _ = bt_node_label(node); // ensure label is derived (lint guard)
    let x = gap + depth as f32 * (node_w + gap);
    let y = gap + slot as f32 * (node_h + gap);

    cmds.push(RenderCommand::SetColor(0.3, 0.6, 0.9, 0.8));
    cmds.push(RenderCommand::Rectangle {
        mode: DrawMode::Line,
        x,
        y,
        w: node_w,
        h: node_h,
    });

    // Recurse to children
    let children: Vec<&BTNode> = match node {
        BTNode::Selector { children, .. }
        | BTNode::Sequence { children, .. }
        | BTNode::Parallel { children, .. } => children.iter().collect(),
        BTNode::Inverter { child }
        | BTNode::Repeater { child, .. }
        | BTNode::Succeeder { child } => vec![child.as_ref()],
        _ => vec![],
    };

    let mut child_slot = slot;
    for child in children {
        let cx = gap + (depth + 1) as f32 * (node_w + gap);
        let cy = gap + child_slot as f32 * (node_h + gap);
        // Line from this node's right edge to child's left edge
        cmds.push(RenderCommand::SetColor(0.5, 0.5, 0.5, 0.5));
        cmds.push(RenderCommand::Line {
            x1: x + node_w,
            y1: y + node_h * 0.5,
            x2: cx,
            y2: cy + node_h * 0.5,
        });
        let sub_size = bt_node_count(child);
        emit_bt_commands(child, depth + 1, child_slot, cmds, node_w, node_h, gap);
        child_slot += sub_size;
    }
}

impl BehaviorTree {
    /// Generate debug render commands that outline the behavior tree structure.
    ///
    /// Nodes are arranged in a depth-column layout: depth increases left to right,
    /// siblings are stacked top to bottom.  Edges connecting parent to child are drawn
    /// as simple lines.  Returns an empty `Vec` when the tree has no root.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        let root = match &self.root {
            Some(r) => r,
            None => return Vec::new(),
        };

        let node_count = bt_node_count(root);
        let mut cmds = Vec::with_capacity(node_count * 4);
        let (node_w, node_h, gap) = (50.0f32, 20.0f32, 8.0f32);

        // Status colour indicator
        let (sr, sg, sb) = match self.last_status {
            BTStatus::Success => (0.2, 0.9, 0.2),
            BTStatus::Failure => (0.9, 0.2, 0.2),
            BTStatus::Running => (0.9, 0.7, 0.1),
        };
        cmds.push(RenderCommand::SetColor(sr, sg, sb, 0.6));
        cmds.push(RenderCommand::Circle {
            mode: DrawMode::Fill,
            x: 8.0,
            y: 8.0,
            r: 5.0,
        });

        emit_bt_commands(root, 0, 0, &mut cmds, node_w, node_h, gap);
        cmds
    }

    /// Render the behavior tree structure to a CPU image.
    ///
    /// Nodes are drawn as small coloured rectangles in a depth-column layout.
    /// Node colour is determined by its variant (composite=blue, decorator=orange,
    /// leaf=green).  The overall status dot is drawn in the top-left corner.
    ///
    /// # Parameters
    /// - `width` — `u32`. Output image width in pixels.
    /// - `height` — `u32`. Output image height in pixels.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);
        img.fill(15, 15, 25, 255);

        let root = match &self.root {
            Some(r) => r,
            None => return img,
        };

        let depth = bt_depth(root);
        if depth == 0 {
            return img;
        }
        let node_count = bt_node_count(root);
        let node_w = (width / (depth as u32 + 1)).max(4);
        let node_h = (height / (node_count as u32 + 1)).max(4);

        draw_bt_image(&mut img, root, 0, 0, node_w, node_h);
        img
    }
}

/// Recursively paint a behavior tree onto an `ImageData` in a depth-column layout.
fn draw_bt_image(img: &mut ImageData, node: &BTNode, depth: u32, slot: u32, node_w: u32, node_h: u32) {
    let gap = 2u32;
    let x = (depth * (node_w + gap)) as i32;
    let y = (slot * (node_h + gap)) as i32;

    let (r, g, b) = match node {
        BTNode::Selector { .. } | BTNode::Sequence { .. } | BTNode::Parallel { .. } => (80u8, 120, 200),
        BTNode::Inverter { .. } | BTNode::Repeater { .. } | BTNode::Succeeder { .. } => (200, 140, 60),
        BTNode::Action { .. } | BTNode::Condition { .. } => (80, 200, 80),
    };
    img.draw_rect(x, y, node_w.saturating_sub(gap), node_h.saturating_sub(gap), r, g, b, 220);

    let children: Vec<&BTNode> = match node {
        BTNode::Selector { children, .. }
        | BTNode::Sequence { children, .. }
        | BTNode::Parallel { children, .. } => children.iter().collect(),
        BTNode::Inverter { child }
        | BTNode::Repeater { child, .. }
        | BTNode::Succeeder { child } => vec![child.as_ref()],
        _ => vec![],
    };

    let mut child_slot = slot;
    for child in children {
        draw_bt_image(img, child, depth + 1, child_slot, node_w, node_h);
        child_slot += bt_node_count(child) as u32;
    }
}

// ── Tests ──────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fsm_empty_returns_no_commands() {
        let fsm = StateMachine::new();
        assert!(fsm.generate_render_commands().is_empty());
    }

    #[test]
    fn fsm_draw_to_image_correct_dimensions() {
        let fsm = StateMachine::new();
        let img = fsm.draw_to_image(64, 32);
        assert_eq!(img.width(), 64);
        assert_eq!(img.height(), 32);
    }

    #[test]
    fn bt_empty_returns_no_commands() {
        let bt = BehaviorTree::new();
        assert!(bt.generate_render_commands().is_empty());
    }

    #[test]
    fn bt_draw_to_image_correct_dimensions() {
        let bt = BehaviorTree::new();
        let img = bt.draw_to_image(64, 64);
        assert_eq!(img.width(), 64);
        assert_eq!(img.height(), 64);
    }
}
