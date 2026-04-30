//! Tests for the graph module.

use lurek2d::graph::{
    ConversionRule, Edge, FlowMode, Graph, GraphEvent, GraphItem, ItemPosition, Node,
    OverflowPolicy,
};

// ── algorithms ─────────────────────────────────────────────────────────────

mod algorithms_tests {
    use super::*;

    #[test]
    fn components_single() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        g.add_edge(a, b, None).unwrap();
        let comps = g.get_components();
        assert_eq!(comps.len(), 1);
        assert!(comps[0].contains(&a));
        assert!(comps[0].contains(&b));
    }

    #[test]
    fn components_multiple() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        let c = g.add_node("c", -1);
        let d = g.add_node("d", -1);
        g.add_edge(a, b, None).unwrap();
        g.add_edge(c, d, None).unwrap();
        let comps = g.get_components();
        assert_eq!(comps.len(), 2);
    }

    #[test]
    fn components_isolated() {
        let mut g = Graph::new();
        g.add_node("a", -1);
        g.add_node("b", -1);
        g.add_node("c", -1);
        let comps = g.get_components();
        assert_eq!(comps.len(), 3);
    }

    #[test]
    fn no_cycle_linear() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        let c = g.add_node("c", -1);
        g.add_edge(a, b, None).unwrap();
        g.add_edge(b, c, None).unwrap();
        assert!(!g.has_cycle());
    }

    #[test]
    fn has_cycle_simple() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        g.add_edge(a, b, None).unwrap();
        g.add_edge(b, a, None).unwrap();
        assert!(g.has_cycle());
    }

    #[test]
    fn topological_sort_linear() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        let c = g.add_node("c", -1);
        g.add_edge(a, b, None).unwrap();
        g.add_edge(b, c, None).unwrap();
        let order = g.topological_sort().unwrap();
        assert_eq!(order, vec![a, b, c]);
    }

    #[test]
    fn topological_sort_cycle_returns_none() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        g.add_edge(a, b, None).unwrap();
        g.add_edge(b, a, None).unwrap();
        assert!(g.topological_sort().is_none());
    }

    #[test]
    fn empty_graph() {
        let g = Graph::new();
        assert!(g.get_components().is_empty());
        assert!(!g.has_cycle());
        assert_eq!(g.topological_sort(), Some(vec![]));
    }
}

// ── core (Graph CRUD) ─────────────────────────────────────────────────────

mod core_tests {
    use super::*;

    #[test]
    fn outgoing_incoming_edges() {
        let mut g = Graph::new();
        let n1 = g.add_node("a", 5);
        let n2 = g.add_node("b", 5);
        let n3 = g.add_node("c", 5);
        let e1 = g.add_edge(n1, n2, None).unwrap();
        let e2 = g.add_edge(n1, n3, None).unwrap();
        let e3 = g.add_edge(n2, n3, None).unwrap();

        let out = g.get_outgoing_edges(n1);
        assert!(out.contains(&e1));
        assert!(out.contains(&e2));
        assert!(!out.contains(&e3));

        let inc = g.get_incoming_edges(n3);
        assert!(inc.contains(&e2));
        assert!(inc.contains(&e3));
    }
}

// ── edge ───────────────────────────────────────────────────────────────────

mod edge_tests {
    use super::*;

    #[test]
    fn new_edge_defaults() {
        let e = Edge::new(1, 10, 20, "road");
        assert_eq!(e.id, 1);
        assert_eq!(e.from_node, 10);
        assert_eq!(e.to_node, 20);
        assert_eq!(e.get_type(), "road");
        assert!((e.throughput - 1.0).abs() < 1e-9);
        assert!((e.travel_time - 1.0).abs() < 1e-9);
        assert!((e.weight - 1.0).abs() < 1e-9);
        assert!(e.active);
        assert!(!e.bidirectional);
        assert!(!e.is_on_cooldown());
    }

    #[test]
    fn allowed_types() {
        let mut e = Edge::new(1, 0, 1, "pipe");
        // empty = allow all
        assert!(e.is_item_type_allowed("anything"));
        e.add_allowed_type("water");
        assert!(e.is_item_type_allowed("water"));
        assert!(!e.is_item_type_allowed("oil"));
        e.add_allowed_type("oil");
        assert!(e.is_item_type_allowed("oil"));
        e.remove_allowed_type("oil");
        assert!(!e.is_item_type_allowed("oil"));
        e.clear_allowed_types();
        assert!(e.is_item_type_allowed("anything"));
    }

    #[test]
    fn cooldown() {
        let mut e = Edge::new(1, 0, 1, "x");
        assert!(!e.is_on_cooldown());
        e.cooldown_timer = 0.5;
        assert!(e.is_on_cooldown());
    }

    #[test]
    fn transit_capacity() {
        let mut e = Edge::new(1, 0, 1, "x");
        assert!(!e.is_transit_full()); // unlimited
        e.capacity = 1;
        assert!(!e.is_transit_full());
        e.items_in_transit.push(100);
        assert!(e.is_transit_full());
    }
}

// ── item ───────────────────────────────────────────────────────────────────

mod item_tests {
    use super::*;

    #[test]
    fn new_item_defaults() {
        let item = GraphItem::new(1, "wood", 10.0);
        assert_eq!(item.id, 1);
        assert_eq!(item.get_type(), "wood");
        assert!((item.get_decay_time() - 10.0).abs() < 1e-9);
        assert!((item.get_remaining_life() - 10.0).abs() < 1e-9);
        assert!(item.is_alive());
        assert_eq!(item.get_priority(), 0);
        assert_eq!(*item.get_position(), ItemPosition::Unplaced);
    }

    #[test]
    fn kill_item() {
        let mut item = GraphItem::new(2, "gold", -1.0);
        assert!(item.is_alive());
        item.kill();
        assert!(!item.is_alive());
    }

    #[test]
    fn set_type_and_priority() {
        let mut item = GraphItem::new(3, "stone", 5.0);
        item.set_type("iron");
        assert_eq!(item.get_type(), "iron");
        item.set_priority(10);
        assert_eq!(item.get_priority(), 10);
    }

    #[test]
    fn set_position() {
        let mut item = GraphItem::new(4, "x", -1.0);
        item.set_position(ItemPosition::AtNode(42));
        assert_eq!(*item.get_position(), ItemPosition::AtNode(42));
        item.set_position(ItemPosition::InTransit {
            edge_id: 7,
            progress: 0.5,
        });
        assert_eq!(
            *item.get_position(),
            ItemPosition::InTransit {
                edge_id: 7,
                progress: 0.5
            }
        );
    }

    #[test]
    fn no_decay() {
        let item = GraphItem::new(5, "eternal", -1.0);
        assert!((item.get_decay_time() - (-1.0)).abs() < 1e-9);
        assert!((item.get_remaining_life() - (-1.0)).abs() < 1e-9);
    }
}

// ── node ───────────────────────────────────────────────────────────────────

mod node_tests {
    use super::*;
    use std::str::FromStr;

    #[test]
    fn new_node_defaults() {
        let n = Node::new(1, "factory", 10);
        assert_eq!(n.id, 1);
        assert_eq!(n.get_type(), "factory");
        assert_eq!(n.get_capacity(), 10);
        assert!(n.active);
        assert!(!n.is_full());
        assert_eq!(n.item_count(), 0);
        assert_eq!(n.overflow_policy, OverflowPolicy::Reject);
        assert_eq!(n.flow_mode, FlowMode::Passive);
    }

    #[test]
    fn unlimited_capacity_never_full() {
        let n = Node::new(1, "sink", -1);
        assert!(!n.is_full());
    }

    #[test]
    fn is_full_check() {
        let mut n = Node::new(1, "bin", 2);
        n.items.push(100);
        assert!(!n.is_full());
        n.items.push(101);
        assert!(n.is_full());
    }

    #[test]
    fn tags_crud() {
        let mut n = Node::new(1, "t", 5);
        n.add_tag("hot");
        n.add_tag("red");
        assert!(n.has_tag("hot"));
        assert!(!n.has_tag("cold"));
        assert_eq!(n.get_tags(), vec!["hot", "red"]);
        n.remove_tag("hot");
        assert!(!n.has_tag("hot"));
        n.clear_tags();
        assert!(n.get_tags().is_empty());
    }

    #[test]
    fn supply_demand() {
        let mut n = Node::new(1, "mine", -1);
        n.add_supply("ore", 100);
        assert_eq!(n.get_available_supply("ore"), 100);
        assert_eq!(n.get_available_supply("gold"), 0);
        n.add_demand("food", 10, 5);
        assert!(n.get_demand("food").is_some());
        assert_eq!(n.get_demand("food").unwrap().priority, 5);
        n.remove_supply("ore");
        assert_eq!(n.get_available_supply("ore"), 0);
        n.remove_demand("food");
        assert!(n.get_demand("food").is_none());
    }

    #[test]
    fn conversion_rule() {
        let mut n = Node::new(1, "smelter", 5);
        n.set_conversion(ConversionRule {
            in_type: "ore".into(),
            out_type: "ingot".into(),
            in_count: 2,
            out_count: 1,
        });
        assert!(n.conversions.contains_key("ore"));
        n.clear_conversion("ore");
        assert!(!n.conversions.contains_key("ore"));
    }

    #[test]
    fn queue_operations() {
        let mut n = Node::new(1, "q", 5);
        n.queue_capacity = 2;
        assert!(n.enqueue(10));
        assert!(n.enqueue(11));
        assert!(!n.enqueue(12)); // full
        assert_eq!(n.dequeue(), Some(10));
        assert_eq!(n.dequeue(), Some(11));
        assert_eq!(n.dequeue(), None);
    }

    #[test]
    fn overflow_policy_parse() {
        assert_eq!(
            OverflowPolicy::from_str("reject").unwrap(),
            OverflowPolicy::Reject
        );
        assert_eq!(
            OverflowPolicy::from_str("destroy").unwrap(),
            OverflowPolicy::Destroy
        );
        assert_eq!(
            OverflowPolicy::from_str("queue").unwrap(),
            OverflowPolicy::Queue
        );
        assert!(OverflowPolicy::from_str("bad").is_err());
        assert_eq!(OverflowPolicy::Reject.to_str(), "reject");
    }

    #[test]
    fn flow_mode_parse() {
        assert_eq!(FlowMode::from_str("passive").unwrap(), FlowMode::Passive);
        assert_eq!(FlowMode::from_str("push").unwrap(), FlowMode::Push);
        assert_eq!(FlowMode::from_str("pull").unwrap(), FlowMode::Pull);
        assert_eq!(FlowMode::from_str("both").unwrap(), FlowMode::Both);
        assert!(FlowMode::from_str("bad").is_err());
        assert_eq!(FlowMode::Both.to_str(), "both");
    }
}

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

// ── simulation ─────────────────────────────────────────────────────────────

mod simulation_tests {
    use super::*;

    #[test]
    fn decay_kills_items() {
        let mut g = Graph::new();
        let n = g.add_node("bin", -1);
        let i = g.create_item("perishable", 1.0);
        g.add_item_to_node(i, n).unwrap();

        // Advance 0.5s — still alive
        let events = g.update(0.5);
        assert!(g.items[&i].is_alive());
        assert!(events.is_empty());

        // Advance 0.6s — should decay
        let events = g.update(0.6);
        assert!(!g.items[&i].is_alive());
        assert!(events
            .iter()
            .any(|e| matches!(e, GraphEvent::ItemDecay { item_id } if *item_id == i)));
    }

    #[test]
    fn transit_delivers_item() {
        let mut g = Graph::new();
        let n1 = g.add_node("src", 5);
        let n2 = g.add_node("dst", 5);
        let e = g.add_edge(n1, n2, None).unwrap();
        if let Some(edge) = g.edges.get_mut(&e) {
            edge.travel_time = 1.0;
        }
        let i = g.create_item("cargo", -1.0);
        g.add_item_to_node(i, n1).unwrap();
        g.send_item(i, e).unwrap();

        // Advance 1.5s — should arrive
        let events = g.update(1.5);
        assert!(events
            .iter()
            .any(|ev| matches!(ev, GraphEvent::ItemEnter { item_id, node_id } if *item_id == i && *node_id == n2)));
        assert_eq!(g.items[&i].position, ItemPosition::AtNode(n2));
    }

    #[test]
    fn push_flow_sends_items() {
        let mut g = Graph::new();
        let n1 = g.add_node("src", -1);
        let n2 = g.add_node("dst", -1);
        let _e = g.add_edge(n1, n2, None).unwrap();
        g.nodes.get_mut(&n1).unwrap().flow_mode = FlowMode::Push;
        g.nodes.get_mut(&n1).unwrap().push_rate = 1.0;

        let i = g.create_item("x", -1.0);
        g.add_item_to_node(i, n1).unwrap();

        let events = g.update(1.0);
        assert!(events
            .iter()
            .any(|ev| matches!(ev, GraphEvent::ItemLeave { item_id, .. } if *item_id == i)));
    }

    #[test]
    fn conversion_works() {
        let mut g = Graph::new();
        let n = g.add_node("smelter", -1);
        g.nodes.get_mut(&n).unwrap().set_conversion(ConversionRule {
            in_type: "ore".into(),
            out_type: "ingot".into(),
            in_count: 2,
            out_count: 1,
        });

        let i1 = g.create_item("ore", -1.0);
        let i2 = g.create_item("ore", -1.0);
        g.add_item_to_node(i1, n).unwrap();
        g.add_item_to_node(i2, n).unwrap();

        let events = g.update(0.1);
        assert!(events
            .iter()
            .any(|ev| matches!(ev, GraphEvent::ItemConvert { .. })));
        // 2 ore consumed, 1 ingot produced
        let node = &g.nodes[&n];
        assert_eq!(node.items.len(), 1);
        let remaining_id = node.items[0];
        assert_eq!(g.items[&remaining_id].item_type, "ingot");
    }

    #[test]
    fn overflow_destroy() {
        let mut g = Graph::new();
        let n1 = g.add_node("src", -1);
        let n2 = g.add_node("dst", 0);
        g.nodes.get_mut(&n2).unwrap().overflow_policy = OverflowPolicy::Destroy;
        let e = g.add_edge(n1, n2, None).unwrap();
        if let Some(edge) = g.edges.get_mut(&e) {
            edge.travel_time = 0.1;
        }
        let i = g.create_item("x", -1.0);
        g.add_item_to_node(i, n1).unwrap();
        g.send_item(i, e).unwrap();

        let events = g.update(0.2);
        assert!(events
            .iter()
            .any(|ev| matches!(ev, GraphEvent::ItemLost { item_id, .. } if *item_id == i)));
    }

    #[test]
    fn step_is_update_one() {
        let mut g = Graph::new();
        let _ = g.add_node("a", 5);
        let events = g.step();
        assert!(events.is_empty());
    }
}

// ── supply_demand ──────────────────────────────────────────────────────────

mod supply_demand_tests {
    use super::*;

    #[test]
    fn basic_supply_demand() {
        let mut g = Graph::new();
        let supply = g.add_node("mine", -1);
        let demand = g.add_node("factory", -1);
        g.add_edge(supply, demand, None).unwrap();

        g.nodes.get_mut(&supply).unwrap().add_supply("ore", 5);
        g.nodes.get_mut(&demand).unwrap().add_demand("ore", 3, 10);

        let events = g.process_demand();
        assert!(events.iter().any(
            |e| matches!(e, GraphEvent::DemandFulfilled { demand_node, supply_node, item_type, count }
                if *demand_node == demand && *supply_node == supply && item_type == "ore" && *count == 3)
        ));
    }

    #[test]
    fn no_path_no_fulfillment() {
        let mut g = Graph::new();
        let supply = g.add_node("mine", -1);
        let demand = g.add_node("factory", -1);
        // No edge connecting them

        g.nodes.get_mut(&supply).unwrap().add_supply("ore", 5);
        g.nodes.get_mut(&demand).unwrap().add_demand("ore", 3, 10);

        let events = g.process_demand();
        assert!(!events
            .iter()
            .any(|e| matches!(e, GraphEvent::DemandFulfilled { .. })));
    }

    #[test]
    fn supply_depletion() {
        let mut g = Graph::new();
        let supply = g.add_node("mine", -1);
        let demand = g.add_node("factory", -1);
        g.add_edge(supply, demand, None).unwrap();

        g.nodes.get_mut(&supply).unwrap().add_supply("ore", 2);
        g.nodes.get_mut(&demand).unwrap().add_demand("ore", 5, 10);

        let events = g.process_demand();
        assert!(events.iter().any(
            |e| matches!(e, GraphEvent::SupplyDepleted { node_id, item_type }
                if *node_id == supply && item_type == "ore")
        ));
    }

    #[test]
    fn unlimited_supply() {
        let mut g = Graph::new();
        let supply = g.add_node("infinite", -1);
        let demand = g.add_node("consumer", -1);
        g.add_edge(supply, demand, None).unwrap();

        g.nodes.get_mut(&supply).unwrap().add_supply("magic", -1);
        g.nodes.get_mut(&demand).unwrap().add_demand("magic", 10, 5);

        let events = g.process_demand();
        assert!(events
            .iter()
            .any(|e| matches!(e, GraphEvent::DemandFulfilled { count, .. } if *count == 10)));
    }
}

// ── graph (duplicate of core — from graph.rs) ──────────────────────────────
