//! Integration tests for `lurek2d::graph` — directed graph with item flow simulation.

use lurek2d::graph::*;

// ============================================================
// 1. Graph creation and basic node CRUD
// ============================================================

#[test]
fn test_graph_new_is_empty() {
    let g = Graph::new();
    assert_eq!(g.get_node_count(), 0);
    assert_eq!(g.get_edge_count(), 0);
    assert_eq!(g.get_item_count(), 0);
}

#[test]
fn test_node_add_increments_count_and_returns_unique_ids() {
    let mut g = Graph::new();
    let n1 = g.add_node("warehouse", 10);
    let n2 = g.add_node("factory", 5);
    let n3 = g.add_node("shop", -1);
    assert_eq!(g.get_node_count(), 3);
    assert!(g.has_node(n1));
    assert!(g.has_node(n2));
    assert!(g.has_node(n3));
    // IDs must be distinct
    assert_ne!(n1, n2);
    assert_ne!(n2, n3);
}

#[test]
fn test_node_remove_cleans_connected_edges() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let c = g.add_node("c", -1);
    let e1 = g.add_edge(a, b, None).unwrap();
    let e2 = g.add_edge(b, c, None).unwrap();

    g.remove_node(b);
    assert!(!g.has_node(b));
    assert!(!g.has_edge(e1));
    assert!(!g.has_edge(e2));
    assert_eq!(g.get_edge_count(), 0);
}

#[test]
fn test_node_remove_nonexistent_returns_false() {
    let mut g = Graph::new();
    assert!(!g.remove_node(999));
}

#[test]
fn test_node_get_ids_matches_count() {
    let mut g = Graph::new();
    g.add_node("x", 1);
    g.add_node("y", 2);
    let ids = g.get_node_ids();
    assert_eq!(ids.len(), g.get_node_count());
}

// ============================================================
// 2. Edge CRUD and validation
// ============================================================

#[test]
fn test_edge_add_between_valid_nodes() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, Some("road")).unwrap();
    assert!(g.has_edge(e));
    assert_eq!(g.get_edge_count(), 1);
}

#[test]
fn test_edge_add_invalid_source_returns_error() {
    let mut g = Graph::new();
    let b = g.add_node("b", -1);
    let result = g.add_edge(999, b, None);
    assert!(result.is_err());
}

#[test]
fn test_edge_add_invalid_destination_returns_error() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let result = g.add_edge(a, 999, None);
    assert!(result.is_err());
}

#[test]
fn test_edge_remove_unplaces_transit_items() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, None).unwrap();

    let item = g.create_item("gold", -1.0);
    g.add_item_to_node(item, a).unwrap();
    g.send_item(item, e).unwrap();

    // Item is in transit
    assert!(matches!(
        g.items.get(&item).unwrap().position,
        ItemPosition::InTransit { .. }
    ));

    g.remove_edge(e);
    // Item should be unplaced after edge removal
    assert_eq!(g.items.get(&item).unwrap().position, ItemPosition::Unplaced);
}

// ============================================================
// 3. Item creation, placement, and removal
// ============================================================

#[test]
fn test_item_create_starts_unplaced() {
    let mut g = Graph::new();
    let item = g.create_item("wood", 5.0);
    assert!(g.has_item(item));
    assert_eq!(g.items.get(&item).unwrap().position, ItemPosition::Unplaced);
    assert_eq!(g.get_item_count(), 1);
}

#[test]
fn test_item_place_at_node_updates_position() {
    let mut g = Graph::new();
    let n = g.add_node("storage", 10);
    let item = g.create_item("ore", -1.0);
    let placed = g.add_item_to_node(item, n).unwrap();
    assert!(placed);
    assert_eq!(
        g.items.get(&item).unwrap().position,
        ItemPosition::AtNode(n)
    );
}

#[test]
fn test_item_place_invalid_node_returns_error() {
    let mut g = Graph::new();
    let item = g.create_item("ore", -1.0);
    let result = g.add_item_to_node(item, 999);
    assert!(result.is_err());
}

#[test]
fn test_item_remove_cleans_from_node() {
    let mut g = Graph::new();
    let n = g.add_node("bin", 10);
    let item = g.create_item("trash", -1.0);
    g.add_item_to_node(item, n).unwrap();
    assert!(g.remove_item(item));
    assert!(!g.has_item(item));
    assert_eq!(g.get_item_count(), 0);
    // Node should no longer reference the item
    assert!(g.nodes.get(&n).unwrap().items.is_empty());
}

// ============================================================
// 4. Overflow policies
// ============================================================

#[test]
fn test_overflow_reject_refuses_item() {
    let mut g = Graph::new();
    let n = g.add_node("small", 1);
    // Default overflow is Reject
    assert_eq!(
        g.nodes.get(&n).unwrap().overflow_policy,
        OverflowPolicy::Reject
    );

    let i1 = g.create_item("a", -1.0);
    let i2 = g.create_item("b", -1.0);
    assert!(g.add_item_to_node(i1, n).unwrap()); // fills capacity
    let placed = g.add_item_to_node(i2, n).unwrap();
    assert!(!placed); // rejected
                      // i2 is still alive and in the graph
    assert!(g.has_item(i2));
}

#[test]
fn test_overflow_destroy_kills_item() {
    let mut g = Graph::new();
    let n = g.add_node("furnace", 1);
    g.nodes.get_mut(&n).unwrap().overflow_policy = OverflowPolicy::Destroy;

    let i1 = g.create_item("a", -1.0);
    let i2 = g.create_item("b", -1.0);
    g.add_item_to_node(i1, n).unwrap();
    let placed = g.add_item_to_node(i2, n).unwrap();
    assert!(!placed);
    // i2 should be marked dead
    assert!(!g.items.get(&i2).unwrap().is_alive());
}

#[test]
fn test_overflow_queue_enqueues_item() {
    let mut g = Graph::new();
    let n = g.add_node("queue_node", 1);
    {
        let node = g.nodes.get_mut(&n).unwrap();
        node.overflow_policy = OverflowPolicy::Queue;
        node.queue_enabled = true;
    }

    let i1 = g.create_item("a", -1.0);
    let i2 = g.create_item("b", -1.0);
    g.add_item_to_node(i1, n).unwrap();
    let queued = g.add_item_to_node(i2, n).unwrap();
    assert!(queued);
    // i2 should be in the queue
    assert!(g.nodes.get(&n).unwrap().queue.contains(&i2));
    // Position should still be AtNode since it's queued at the node
    assert_eq!(g.items.get(&i2).unwrap().position, ItemPosition::AtNode(n));
}

// ============================================================
// 5. Send item along edge; transit and arrival
// ============================================================

#[test]
fn test_send_item_starts_transit() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, None).unwrap();

    let item = g.create_item("package", -1.0);
    g.add_item_to_node(item, a).unwrap();
    let sent = g.send_item(item, e).unwrap();
    assert!(sent);

    match g.items.get(&item).unwrap().position {
        ItemPosition::InTransit { edge_id, progress } => {
            assert_eq!(edge_id, e);
            assert!((progress - 0.0).abs() < 1e-5);
        }
        _ => panic!("expected InTransit after send_item"),
    }
}

#[test]
fn test_send_item_inactive_edge_returns_false() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, None).unwrap();
    g.edges.get_mut(&e).unwrap().active = false;

    let item = g.create_item("x", -1.0);
    g.add_item_to_node(item, a).unwrap();
    let sent = g.send_item(item, e).unwrap();
    assert!(!sent);
}

#[test]
fn test_transit_item_arrives_after_sufficient_update() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, None).unwrap();
    // Default travel_time is 1.0s

    let item = g.create_item("cargo", -1.0);
    g.add_item_to_node(item, a).unwrap();
    g.send_item(item, e).unwrap();

    // Advance enough to complete transit
    let events = g.update(1.5);

    // Item should have arrived at node b
    assert_eq!(
        g.items.get(&item).unwrap().position,
        ItemPosition::AtNode(b)
    );
    // Should have generated an EdgeLeave event
    assert!(events
        .iter()
        .any(|ev| matches!(ev, GraphEvent::EdgeLeave { item_id, .. } if *item_id == item)));
}

// ============================================================
// 6. Pathfinding
// ============================================================

#[test]
fn test_find_path_linear_chain() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let c = g.add_node("c", -1);
    let e1 = g.add_edge(a, b, None).unwrap();
    let e2 = g.add_edge(b, c, None).unwrap();

    let path = g.find_path(a, c).unwrap();
    assert_eq!(path.nodes, vec![a, b, c]);
    assert_eq!(path.edges, vec![e1, e2]);
    assert!((path.cost - 2.0).abs() < 1e-5);
}

#[test]
fn test_find_path_no_route_returns_none() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    // No edge between a and b
    assert!(g.find_path(a, b).is_none());
}

#[test]
fn test_find_path_same_node_returns_trivial_path() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let path = g.find_path(a, a).unwrap();
    assert_eq!(path.nodes, vec![a]);
    assert!(path.edges.is_empty());
    assert!((path.cost - 0.0).abs() < 1e-5);
}

#[test]
fn test_get_distance_matches_path_cost() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let c = g.add_node("c", -1);
    g.add_edge(a, b, None).unwrap();
    g.add_edge(b, c, None).unwrap();

    let dist = g.get_distance(a, c).unwrap();
    assert!((dist - 2.0).abs() < 1e-5);
    assert!(g.get_distance(c, a).is_none()); // directed — no reverse path
}

#[test]
fn test_get_neighbors_returns_outgoing_targets() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let c = g.add_node("c", -1);
    g.add_edge(a, b, None).unwrap();
    g.add_edge(a, c, None).unwrap();

    let mut neighbors = g.get_neighbors(a);
    neighbors.sort();
    assert_eq!(neighbors, vec![b, c]);
    // b has no outgoing edges
    assert!(g.get_neighbors(b).is_empty());
}

#[test]
fn test_get_reachable_respects_max_distance() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let c = g.add_node("c", -1);
    let d = g.add_node("d", -1);
    // a -> b (1.0) -> c (1.0) -> d (1.0)
    g.add_edge(a, b, None).unwrap();
    g.add_edge(b, c, None).unwrap();
    g.add_edge(c, d, None).unwrap();

    // All reachable from a
    let mut all = g.get_reachable(a, None);
    all.sort();
    assert_eq!(all, vec![b, c, d]);

    // Only within distance 1.5
    let mut near = g.get_reachable(a, Some(1.5));
    near.sort();
    assert_eq!(near, vec![b]);
}

// ============================================================
// 7. Graph algorithms
// ============================================================

#[test]
fn test_has_cycle_detects_cycle() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let c = g.add_node("c", -1);
    g.add_edge(a, b, None).unwrap();
    g.add_edge(b, c, None).unwrap();
    assert!(!g.has_cycle());

    g.add_edge(c, a, None).unwrap();
    assert!(g.has_cycle());
}

#[test]
fn test_topological_sort_dag() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let c = g.add_node("c", -1);
    g.add_edge(a, b, None).unwrap();
    g.add_edge(a, c, None).unwrap();
    g.add_edge(b, c, None).unwrap();

    let order = g.topological_sort().unwrap();
    // a must come before b and c; b must come before c
    let pos_a = order.iter().position(|&x| x == a).unwrap();
    let pos_b = order.iter().position(|&x| x == b).unwrap();
    let pos_c = order.iter().position(|&x| x == c).unwrap();
    assert!(pos_a < pos_b);
    assert!(pos_a < pos_c);
    assert!(pos_b < pos_c);
}

#[test]
fn test_topological_sort_cycle_returns_none() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    g.add_edge(a, b, None).unwrap();
    g.add_edge(b, a, None).unwrap();
    assert!(g.topological_sort().is_none());
}

#[test]
fn test_get_components_disconnected_graph() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let c = g.add_node("c", -1);
    g.add_edge(a, b, None).unwrap();
    // c is isolated

    let mut components = g.get_components();
    components.sort_by_key(|c| c[0]);
    assert_eq!(components.len(), 2);
    // One component has a and b, another has c
    let ab_component = components.iter().find(|comp| comp.contains(&a)).unwrap();
    assert!(ab_component.contains(&b));
    let c_component = components.iter().find(|comp| comp.contains(&c)).unwrap();
    assert_eq!(c_component.len(), 1);
}

// ============================================================
// 8. Simulation: decay and transit progress
// ============================================================

#[test]
fn test_update_item_decay_kills_after_lifetime() {
    let mut g = Graph::new();
    let n = g.add_node("n", -1);
    let item = g.create_item("perishable", 2.0);
    g.add_item_to_node(item, n).unwrap();

    // After 1 second — still alive
    let events = g.update(1.0);
    assert!(g.items.get(&item).unwrap().is_alive());
    assert!(!events
        .iter()
        .any(|ev| matches!(ev, GraphEvent::ItemDecay { .. })));

    // After another 1.5 seconds — should be dead
    let events = g.update(1.5);
    assert!(!g.items.get(&item).unwrap().is_alive());
    assert!(events
        .iter()
        .any(|ev| matches!(ev, GraphEvent::ItemDecay { item_id } if *item_id == item)));
}

#[test]
fn test_update_no_decay_for_negative_decay_time() {
    let mut g = Graph::new();
    let n = g.add_node("n", -1);
    let item = g.create_item("eternal", -1.0);
    g.add_item_to_node(item, n).unwrap();

    g.update(1000.0);
    assert!(g.items.get(&item).unwrap().is_alive());
}

#[test]
fn test_step_equals_update_one_second() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, None).unwrap();
    // travel_time defaults to 1.0

    let item = g.create_item("pkg", -1.0);
    g.add_item_to_node(item, a).unwrap();
    g.send_item(item, e).unwrap();

    let events = g.step();
    // After 1.0s with travel_time 1.0, item should arrive
    assert_eq!(
        g.items.get(&item).unwrap().position,
        ItemPosition::AtNode(b)
    );
    assert!(events
        .iter()
        .any(|ev| matches!(ev, GraphEvent::EdgeLeave { .. })));
}

// ============================================================
// 9. Stats
// ============================================================

#[test]
fn test_get_stats_reflects_graph_state() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, None).unwrap();
    let i1 = g.create_item("x", -1.0);
    let i2 = g.create_item("y", -1.0);
    g.add_item_to_node(i1, a).unwrap();
    g.add_item_to_node(i2, a).unwrap();

    // Send one item into transit
    g.send_item(i1, e).unwrap();

    let stats = g.get_stats();
    assert_eq!(stats.nodes, 2);
    assert_eq!(stats.edges, 1);
    assert_eq!(stats.items, 2);
    assert_eq!(stats.items_in_transit, 1);
    assert_eq!(stats.items_on_nodes, 1); // i2 still on node a
    assert_eq!(stats.active_nodes, 2);
    assert_eq!(stats.active_edges, 1);
}

// ============================================================
// 10. Edge queries: get_edge_between, outgoing/incoming
// ============================================================

#[test]
fn test_get_edge_between_finds_directed_edge() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, None).unwrap();

    assert_eq!(g.get_edge_between(a, b), Some(e));
    assert_eq!(g.get_edge_between(b, a), None); // directed
}

#[test]
fn test_outgoing_and_incoming_edges() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let c = g.add_node("c", -1);
    let e1 = g.add_edge(a, b, None).unwrap();
    let e2 = g.add_edge(a, c, None).unwrap();
    let e3 = g.add_edge(c, a, None).unwrap();

    let mut out_a = g.get_outgoing_edges(a);
    out_a.sort();
    let mut expected_out = vec![e1, e2];
    expected_out.sort();
    assert_eq!(out_a, expected_out);

    let inc_a = g.get_incoming_edges(a);
    assert_eq!(inc_a, vec![e3]);

    assert!(g.get_outgoing_edges(b).is_empty());
}

// ============================================================
// 11. Edge type and allowed-type filtering
// ============================================================

#[test]
fn test_edge_get_set_type() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, Some("road")).unwrap();

    assert_eq!(g.edges.get(&e).unwrap().get_type(), "road");
    g.edges.get_mut(&e).unwrap().set_type("rail");
    assert_eq!(g.edges.get(&e).unwrap().get_type(), "rail");
}

#[test]
fn test_edge_allowed_types() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, None).unwrap();

    let edge = g.edges.get_mut(&e).unwrap();
    // No filter → all allowed
    assert!(edge.is_item_type_allowed("gold"));
    // Add a filter → only listed types allowed
    edge.add_allowed_type("gold");
    assert!(edge.is_item_type_allowed("gold"));
    assert!(!edge.is_item_type_allowed("silver"));
    // Add another
    edge.add_allowed_type("silver");
    assert!(edge.is_item_type_allowed("silver"));
    // Remove
    assert!(edge.remove_allowed_type("gold"));
    assert!(!edge.is_item_type_allowed("gold"));
    assert!(!edge.remove_allowed_type("gold")); // already gone
                                                // Clear
    edge.clear_allowed_types();
    // After clearing, all types allowed again (empty = no filter)
    assert!(edge.is_item_type_allowed("anything"));
}

#[test]
fn test_edge_cooldown_initially_false() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, None).unwrap();
    assert!(!g.edges.get(&e).unwrap().is_on_cooldown());
}

#[test]
fn test_edge_transit_full() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let e = g.add_edge(a, b, None).unwrap();

    // Default capacity is 0 (unlimited) — never full
    assert!(!g.edges.get(&e).unwrap().is_transit_full());

    // Set capacity to 1
    g.edges.get_mut(&e).unwrap().capacity = 1;
    assert!(!g.edges.get(&e).unwrap().is_transit_full()); // 0 items

    // Add an item in transit
    let i = g.create_item("cargo", 0.0);
    g.add_item_to_node(i, a).unwrap();
    g.edges.get_mut(&e).unwrap().travel_time = 100.0; // long travel
    g.send_item(i, e).unwrap();
    assert!(g.edges.get(&e).unwrap().is_transit_full()); // 1/1
}

// ============================================================
// 12. Node type, capacity, tags
// ============================================================

#[test]
fn test_node_get_set_type() {
    let mut g = Graph::new();
    let n = g.add_node("warehouse", 10);

    assert_eq!(g.nodes.get(&n).unwrap().get_type(), "warehouse");
    g.nodes.get_mut(&n).unwrap().set_type("factory");
    assert_eq!(g.nodes.get(&n).unwrap().get_type(), "factory");
}

#[test]
fn test_node_capacity_and_fullness() {
    let mut g = Graph::new();
    let n = g.add_node("bin", 2);

    assert_eq!(g.nodes.get(&n).unwrap().get_capacity(), 2);
    assert!(!g.nodes.get(&n).unwrap().is_full());
    assert_eq!(g.nodes.get(&n).unwrap().item_count(), 0);

    let i1 = g.create_item("x", 0.0);
    let i2 = g.create_item("x", 0.0);
    g.add_item_to_node(i1, n).unwrap();
    assert_eq!(g.nodes.get(&n).unwrap().item_count(), 1);
    assert!(!g.nodes.get(&n).unwrap().is_full());

    g.add_item_to_node(i2, n).unwrap();
    assert_eq!(g.nodes.get(&n).unwrap().item_count(), 2);
    assert!(g.nodes.get(&n).unwrap().is_full());

    // Change capacity
    g.nodes.get_mut(&n).unwrap().set_capacity(5);
    assert_eq!(g.nodes.get(&n).unwrap().get_capacity(), 5);
    assert!(!g.nodes.get(&n).unwrap().is_full());
}

#[test]
fn test_node_tags() {
    let mut g = Graph::new();
    let n = g.add_node("city", -1);

    let node = g.nodes.get_mut(&n).unwrap();
    assert!(node.get_tags().is_empty());
    assert!(!node.has_tag("capital"));

    node.add_tag("capital");
    assert!(node.has_tag("capital"));
    assert_eq!(node.get_tags().len(), 1);

    node.add_tag("port");
    assert_eq!(node.get_tags().len(), 2);

    assert!(node.remove_tag("capital"));
    assert!(!node.has_tag("capital"));
    assert!(!node.remove_tag("capital")); // already removed

    node.add_tag("inland");
    node.clear_tags();
    assert!(node.get_tags().is_empty());
}

// ============================================================
// 13. Node supply and demand
// ============================================================

#[test]
fn test_node_supply_operations() {
    let mut g = Graph::new();
    let n = g.add_node("mine", -1);

    let node = g.nodes.get_mut(&n).unwrap();
    assert!(node.get_supply("iron").is_none());
    assert_eq!(node.get_available_supply("iron"), 0);

    node.add_supply("iron", 100);
    assert!(node.get_supply("iron").is_some());
    assert_eq!(node.get_available_supply("iron"), 100);

    node.add_supply("gold", 50);
    assert_eq!(node.get_available_supply("gold"), 50);

    assert!(node.remove_supply("iron"));
    assert!(node.get_supply("iron").is_none());
    assert!(!node.remove_supply("iron")); // already gone

    node.clear_supplies();
    assert!(node.get_supply("gold").is_none());
}

#[test]
fn test_node_demand_operations() {
    let mut g = Graph::new();
    let n = g.add_node("factory", -1);

    let node = g.nodes.get_mut(&n).unwrap();
    assert!(node.get_demand("iron").is_none());

    node.add_demand("iron", 50, 1);
    let d = node.get_demand("iron").unwrap();
    assert_eq!(d.quantity, 50);
    assert_eq!(d.priority, 1);

    node.add_demand("coal", 20, 2);
    assert!(node.get_demand("coal").is_some());

    assert!(node.remove_demand("iron"));
    assert!(node.get_demand("iron").is_none());
    assert!(!node.remove_demand("iron")); // already gone

    node.clear_demands();
    assert!(node.get_demand("coal").is_none());
}

// ============================================================
// 14. Node conversions
// ============================================================

#[test]
fn test_node_conversion_set_and_clear() {
    let mut g = Graph::new();
    let n = g.add_node("smelter", -1);

    let node = g.nodes.get_mut(&n).unwrap();
    let rule = ConversionRule {
        in_type: "ore".into(),
        in_count: 2,
        out_type: "ingot".into(),
        out_count: 1,
    };
    node.set_conversion(rule);
    assert!(!node.conversions.is_empty());

    assert!(node.clear_conversion("ore"));
    assert!(node.conversions.is_empty());
    assert!(!node.clear_conversion("ore")); // already cleared

    node.set_conversion(ConversionRule {
        in_type: "wood".into(),
        in_count: 3,
        out_type: "charcoal".into(),
        out_count: 1,
    });
    node.set_conversion(ConversionRule {
        in_type: "stone".into(),
        in_count: 5,
        out_type: "gravel".into(),
        out_count: 3,
    });
    node.clear_all_conversions();
    assert!(node.conversions.is_empty());
}

// ============================================================
// 15. Node queue operations
// ============================================================

#[test]
fn test_node_enqueue_dequeue() {
    let mut g = Graph::new();
    let n = g.add_node("queue_node", -1);

    let node = g.nodes.get_mut(&n).unwrap();
    node.queue_enabled = true;
    node.queue_capacity = 3;

    assert_eq!(node.dequeue(), None);
    assert!(node.enqueue(100));
    assert!(node.enqueue(200));
    assert!(node.enqueue(300));
    assert!(!node.enqueue(400)); // full

    assert_eq!(node.dequeue(), Some(100));
    assert_eq!(node.dequeue(), Some(200));
    assert_eq!(node.dequeue(), Some(300));
    assert_eq!(node.dequeue(), None);
}

// ============================================================
// 16. Graph get_edge_ids and get_item_ids
// ============================================================

#[test]
fn test_get_edge_ids() {
    let mut g = Graph::new();
    let a = g.add_node("a", -1);
    let b = g.add_node("b", -1);
    let c = g.add_node("c", -1);

    let e1 = g.add_edge(a, b, None).unwrap();
    let e2 = g.add_edge(b, c, None).unwrap();

    let mut ids = g.get_edge_ids();
    ids.sort();
    let mut expected = vec![e1, e2];
    expected.sort();
    assert_eq!(ids, expected);
}

#[test]
fn test_get_item_ids() {
    let mut g = Graph::new();
    let n = g.add_node("storage", -1);

    let i1 = g.create_item("a", 0.0);
    let i2 = g.create_item("b", 0.0);
    g.add_item_to_node(i1, n).unwrap();
    g.add_item_to_node(i2, n).unwrap();

    let mut ids = g.get_item_ids();
    ids.sort();
    let mut expected = vec![i1, i2];
    expected.sort();
    assert_eq!(ids, expected);
}
