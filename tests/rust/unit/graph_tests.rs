//! INTERNAL ONLY: Rust-only tests for the graph module.
//!
//! Public graph behavior reachable through `lurek.graph.*` is covered in
//! `tests/lua/unit/test_graph_unit.lua`. The remaining Rust-only coverage here
//! keeps render helpers that are not directly observable through the Lua API.

use lurek2d::graph::Graph;

// ── render ─────────────────────────────────────────────────────────────────

mod render_tests {
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
