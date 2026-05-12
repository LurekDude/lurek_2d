//! INTERNAL ONLY: Rust-only tests for the graph module.
//!
//! Public graph behavior reachable through \lurek.graph.*\ is covered in
//! \	ests/lua/unit/test_graph_unit.lua\. The remaining Rust-only coverage here
//! keeps render helpers and simulation edge-cases that are easier to assert in Rust.

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

// ── simulation ────────────────────────────────────────────────────────────

mod simulation_tests {
    use super::*;

    fn build_decay_graph() -> Graph {
        let mut g = Graph::new();
        let n = g.add_node("source", 8);
        let i = g.create_item("ore", 1.0);
        g.add_item_to_node(i, n)
            .expect("item should be placed on source node");
        g
    }

    #[test]
    fn update_parallel_matches_update_for_decay_path() {
        let mut a = build_decay_graph();
        let data = a.serialize();
        let mut b = Graph::deserialize(&data).expect("graph deserialize should succeed");

        let events_a = a.update(1.5);
        let events_b = b.update_parallel(1.5);

        assert!(
            events_a
                .iter()
                .any(|e| matches!(e, lurek2d::graph::simulation::GraphEvent::ItemDecay { .. }))
                || !events_a.is_empty()
        );
        let _ = events_b; // direct coverage: ensure update_parallel executes in tests

        let stats_a = a.get_stats();
        let stats_b = b.get_stats();
        assert_eq!(stats_a.items_on_nodes, stats_b.items_on_nodes);
        assert_eq!(stats_a.items_in_transit, stats_b.items_in_transit);
    }

    #[test]
    fn edge_cooldown_expires_precisely_and_allows_send_again() {
        let mut g = Graph::new();
        let from = g.add_node("source", 8);
        let to = g.add_node("sink", 8);
        let edge = g
            .add_edge(from, to, Some("belt"))
            .expect("edge should be created");

        {
            let e = g.edges.get_mut(&edge).expect("edge should exist");
            e.cooldown = 1.0;
        }

        let item_a = g.create_item("ore", -1.0);
        let item_b = g.create_item("ore", -1.0);
        g.add_item_to_node(item_a, from)
            .expect("item_a should be placed");
        g.add_item_to_node(item_b, from)
            .expect("item_b should be placed");

        assert!(g
            .send_item(item_a, edge)
            .expect("send item_a should succeed"));
        assert!(!g
            .send_item(item_b, edge)
            .expect("cooldown should block immediate send"));

        g.update(0.5);
        assert!(!g
            .send_item(item_b, edge)
            .expect("cooldown still active at half-time"));

        g.update(0.5);
        assert!(g
            .send_item(item_b, edge)
            .expect("cooldown expired, send should work"));
    }

    #[test]
    fn adjacency_indexes_stay_consistent_after_edge_and_node_removal() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        let c = g.add_node("c", -1);
        let e1 = g.add_edge(a, b, Some("road")).expect("edge a->b");
        let _e2 = g.add_edge(b, c, Some("road")).expect("edge b->c");

        assert_eq!(g.get_outgoing_edges(a), vec![e1]);
        assert_eq!(g.get_incoming_edges(b), vec![e1]);

        assert!(g.remove_edge(e1));
        assert!(g.get_outgoing_edges(a).is_empty());
        assert!(g.get_incoming_edges(b).is_empty());

        assert!(g.remove_node(b));
        assert!(g.get_outgoing_edges(b).is_empty());
        assert!(g.get_incoming_edges(b).is_empty());
    }

    #[test]
    fn subgraph_keeps_only_selected_nodes_edges_and_items() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        let c = g.add_node("c", -1);
        let ab = g.add_edge(a, b, Some("road")).expect("edge a->b");
        let _bc = g.add_edge(b, c, Some("road")).expect("edge b->c");

        let item_on_b = g.create_item("ore", -1.0);
        g.add_item_to_node(item_on_b, b).expect("item on b");

        let item_on_ab = g.create_item("ore", -1.0);
        g.add_item_to_node(item_on_ab, a).expect("item on a");
        assert!(g.send_item(item_on_ab, ab).expect("send on ab"));

        let sub = g.subgraph(&[a, b]);
        assert_eq!(sub.get_node_count(), 2);
        assert_eq!(sub.get_edge_count(), 1);
        assert_eq!(sub.get_item_count(), 2);

        let only_edge = sub
            .get_edge_ids()
            .into_iter()
            .next()
            .expect("subgraph edge expected");
        let edge = sub.edges.get(&only_edge).expect("subgraph edge lookup");
        assert_eq!(edge.items_in_transit.len(), 1);
    }
}
