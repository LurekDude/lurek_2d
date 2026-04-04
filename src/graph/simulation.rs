//! Simulation engine — update(dt) and step() for item flow, decay, transit, and conversions.

use super::core::Graph;
use super::item::ItemPosition;
use super::node::FlowMode;

/// Events generated during simulation for the Lua callback layer to dispatch.
#[derive(Debug, Clone)]
pub enum GraphEvent {
    /// An item arrived at a node.
    ItemEnter {
        /// Item that entered.
        item_id: u64,
        /// Node it entered.
        node_id: u64,
    },
    /// An item left a node (onto an edge).
    ItemLeave {
        /// Item that left.
        item_id: u64,
        /// Node it left.
        node_id: u64,
    },
    /// An item decayed (remaining_life reached zero).
    ItemDecay {
        /// Item that decayed.
        item_id: u64,
    },
    /// Items were consumed and new items produced by a conversion rule.
    ItemConvert {
        /// Node where conversion happened.
        node_id: u64,
        /// Items consumed.
        consumed: Vec<u64>,
        /// Items produced.
        produced: Vec<u64>,
    },
    /// An item was lost (destroyed by overflow policy).
    ItemLost {
        /// Item that was destroyed.
        item_id: u64,
        /// Node that rejected it.
        node_id: u64,
    },
    /// An item entered an edge (started transit).
    EdgeEnter {
        /// Item that entered transit.
        item_id: u64,
        /// Edge it entered.
        edge_id: u64,
    },
    /// An item left an edge (arrived at destination).
    EdgeLeave {
        /// Item that left the edge.
        item_id: u64,
        /// Edge it left.
        edge_id: u64,
    },
    /// A demand was fulfilled by a supply.
    DemandFulfilled {
        /// Node that had the demand.
        demand_node: u64,
        /// Node that supplied.
        supply_node: u64,
        /// Item type transferred.
        item_type: String,
        /// Number of items.
        count: u32,
    },
    /// A supply was depleted.
    SupplyDepleted {
        /// Node whose supply was exhausted.
        node_id: u64,
        /// Item type that ran out.
        item_type: String,
    },
    /// An item was placed in a queue.
    ItemQueued {
        /// Item that was queued.
        item_id: u64,
        /// Node where it was queued.
        node_id: u64,
    },
    /// An item was dequeued from a queue.
    ItemDequeued {
        /// Item that was dequeued.
        item_id: u64,
        /// Node where it was dequeued.
        node_id: u64,
    },
}

impl Graph {
    /// Advance the simulation by `dt` seconds. Returns events for callback dispatch.
    pub fn update(&mut self, dt: f64) -> Vec<GraphEvent> {
        let mut events = Vec::new();
        self.process_decay(dt, &mut events);
        self.process_transit(dt, &mut events);
        self.process_cooldowns(dt);
        self.process_push_flow(dt, &mut events);
        self.process_pull_flow(dt, &mut events);
        self.process_conversions(&mut events);
        self.process_queues(dt, &mut events);
        events
    }

    /// One discrete simulation step (equivalent to `update(1.0)`).
    pub fn step(&mut self) -> Vec<GraphEvent> {
        self.update(1.0)
    }

    /// Phase 1: Decay — decrement remaining_life, kill expired items.
    fn process_decay(&mut self, dt: f64, events: &mut Vec<GraphEvent>) {
        let mut dead_ids = Vec::new();
        for item in self.items.values_mut() {
            if !item.alive || item.decay_time < 0.0 {
                continue;
            }
            item.remaining_life -= dt;
            if item.remaining_life <= 0.0 {
                item.kill();
                dead_ids.push(item.id);
            }
        }
        for id in dead_ids {
            events.push(GraphEvent::ItemDecay { item_id: id });
            // Remove from containers
            for node in self.nodes.values_mut() {
                node.items.retain(|&iid| iid != id);
                node.queue.retain(|&iid| iid != id);
            }
            for edge in self.edges.values_mut() {
                edge.items_in_transit.retain(|&iid| iid != id);
            }
        }
    }

    /// Phase 2: Transit — advance items along edges, deliver arrived items.
    fn process_transit(&mut self, dt: f64, events: &mut Vec<GraphEvent>) {
        // Collect arrivals: (item_id, edge_id, dest_node_id)
        let mut arrivals: Vec<(u64, u64, u64)> = Vec::new();

        // Collect edge transit info for processing
        let edge_info: Vec<(u64, u64, f64, f64, Vec<u64>)> = self
            .edges
            .values()
            .filter(|e| e.active)
            .map(|e| {
                let effective_travel = e.travel_time / e.speed_modifier.max(0.001);
                let progress_delta = if effective_travel > 0.0 {
                    dt / effective_travel
                } else {
                    1.0
                };
                (
                    e.id,
                    e.to_node,
                    progress_delta,
                    e.travel_time,
                    e.items_in_transit.clone(),
                )
            })
            .collect();

        for (edge_id, dest_node, progress_delta, _travel_time, transit_items) in &edge_info {
            for &iid in transit_items {
                if let Some(item) = self.items.get_mut(&iid) {
                    if let ItemPosition::InTransit {
                        edge_id: eid,
                        ref mut progress,
                    } = item.position
                    {
                        if eid == *edge_id {
                            *progress += progress_delta;
                            if *progress >= 1.0 {
                                arrivals.push((iid, *edge_id, *dest_node));
                            }
                        }
                    }
                }
            }
        }

        // Process arrivals
        for (item_id, edge_id, dest_node) in arrivals {
            events.push(GraphEvent::EdgeLeave { item_id, edge_id });

            // Remove from edge transit
            if let Some(edge) = self.edges.get_mut(&edge_id) {
                edge.items_in_transit.retain(|&id| id != item_id);
            }

            // Try placing at dest node
            if let Some(node) = self.nodes.get(&dest_node) {
                if node.is_full() {
                    match node.overflow_policy {
                        super::node::OverflowPolicy::Reject => {
                            if let Some(item) = self.items.get_mut(&item_id) {
                                item.position = ItemPosition::Unplaced;
                            }
                        }
                        super::node::OverflowPolicy::Destroy => {
                            if let Some(item) = self.items.get_mut(&item_id) {
                                item.kill();
                            }
                            events.push(GraphEvent::ItemLost {
                                item_id,
                                node_id: dest_node,
                            });
                            continue;
                        }
                        super::node::OverflowPolicy::Queue => {
                            if let Some(node) = self.nodes.get_mut(&dest_node) {
                                if node.enqueue(item_id) {
                                    if let Some(item) = self.items.get_mut(&item_id) {
                                        item.position = ItemPosition::AtNode(dest_node);
                                    }
                                    events.push(GraphEvent::ItemQueued {
                                        item_id,
                                        node_id: dest_node,
                                    });
                                } else if let Some(item) = self.items.get_mut(&item_id) {
                                    item.position = ItemPosition::Unplaced;
                                }
                            }
                            continue;
                        }
                    }
                } else {
                    // Place normally
                    if let Some(node) = self.nodes.get_mut(&dest_node) {
                        node.items.push(item_id);
                    }
                    if let Some(item) = self.items.get_mut(&item_id) {
                        item.position = ItemPosition::AtNode(dest_node);
                    }
                    events.push(GraphEvent::ItemEnter {
                        item_id,
                        node_id: dest_node,
                    });
                }
            }
        }
    }

    /// Phase 3: Cooldowns — decrement edge cooldown timers.
    fn process_cooldowns(&mut self, dt: f64) {
        for edge in self.edges.values_mut() {
            if edge.cooldown_timer > 0.0 {
                edge.cooldown_timer = (edge.cooldown_timer - dt).max(0.0);
            }
        }
    }

    /// Phase 4: Push flow — active Push/Both nodes send items along outgoing edges.
    fn process_push_flow(&mut self, dt: f64, events: &mut Vec<GraphEvent>) {
        let push_nodes: Vec<u64> = self
            .nodes
            .values()
            .filter(|n| {
                n.active && (n.flow_mode == FlowMode::Push || n.flow_mode == FlowMode::Both)
            })
            .map(|n| n.id)
            .collect();

        for nid in push_nodes {
            let (push_rate, push_filter, items_snapshot) = {
                let node = match self.nodes.get_mut(&nid) {
                    Some(n) => n,
                    None => continue,
                };
                node.push_timer += dt;
                let slots = (node.push_timer * node.push_rate).floor() as usize;
                if slots == 0 {
                    continue;
                }
                node.push_timer -= slots as f64 / node.push_rate;
                (slots, node.push_filter.clone(), node.items.clone())
            };

            let outgoing: Vec<u64> = self.get_outgoing_edges(nid);
            let mut sent = 0;

            for &iid in &items_snapshot {
                if sent >= push_rate {
                    break;
                }
                let item_type = match self.items.get(&iid) {
                    Some(item) if item.alive => item.item_type.clone(),
                    _ => continue,
                };

                // Check push filter
                if let Some(ref filter) = push_filter {
                    if &item_type != filter {
                        continue;
                    }
                }

                // Find a suitable outgoing edge
                for &eid in &outgoing {
                    let can_send = {
                        let edge = match self.edges.get(&eid) {
                            Some(e) => e,
                            None => continue,
                        };
                        edge.active
                            && !edge.is_on_cooldown()
                            && edge.is_item_type_allowed(&item_type)
                            && !edge.is_transit_full()
                    };
                    if can_send {
                        events.push(GraphEvent::ItemLeave {
                            item_id: iid,
                            node_id: nid,
                        });
                        events.push(GraphEvent::EdgeEnter {
                            item_id: iid,
                            edge_id: eid,
                        });
                        // Remove from node
                        if let Some(node) = self.nodes.get_mut(&nid) {
                            node.items.retain(|&id| id != iid);
                        }
                        // Place on edge
                        if let Some(edge) = self.edges.get_mut(&eid) {
                            edge.items_in_transit.push(iid);
                            edge.cooldown_timer = edge.cooldown;
                        }
                        if let Some(item) = self.items.get_mut(&iid) {
                            item.position = ItemPosition::InTransit {
                                edge_id: eid,
                                progress: 0.0,
                            };
                        }
                        sent += 1;
                        break;
                    }
                }
            }
        }
    }

    /// Phase 5: Pull flow — active Pull/Both nodes pull items from source nodes.
    fn process_pull_flow(&mut self, dt: f64, events: &mut Vec<GraphEvent>) {
        let pull_nodes: Vec<u64> = self
            .nodes
            .values()
            .filter(|n| {
                n.active && (n.flow_mode == FlowMode::Pull || n.flow_mode == FlowMode::Both)
            })
            .map(|n| n.id)
            .collect();

        for nid in pull_nodes {
            let (pull_slots, pull_filter) = {
                let node = match self.nodes.get_mut(&nid) {
                    Some(n) => n,
                    None => continue,
                };
                node.pull_timer += dt;
                let slots = (node.pull_timer * node.pull_rate).floor() as usize;
                if slots == 0 {
                    continue;
                }
                node.pull_timer -= slots as f64 / node.pull_rate;
                (slots, node.pull_filter.clone())
            };

            let incoming: Vec<u64> = self.get_incoming_edges(nid);
            let mut pulled = 0;

            for &eid in &incoming {
                if pulled >= pull_slots {
                    break;
                }
                let (source_node_id, edge_active) = match self.edges.get(&eid) {
                    Some(e) => (e.from_node, e.active),
                    None => continue,
                };

                if !edge_active {
                    continue;
                }

                // Check if dest node is full
                if let Some(node) = self.nodes.get(&nid) {
                    if node.is_full() {
                        break;
                    }
                }

                // Find an item at the source node
                let source_items: Vec<u64> = match self.nodes.get(&source_node_id) {
                    Some(n) => n.items.clone(),
                    None => continue,
                };

                for &iid in &source_items {
                    if pulled >= pull_slots {
                        break;
                    }
                    let item_type = match self.items.get(&iid) {
                        Some(item) if item.alive => item.item_type.clone(),
                        _ => continue,
                    };

                    // Check pull filter
                    if let Some(ref filter) = pull_filter {
                        if &item_type != filter {
                            continue;
                        }
                    }

                    // Check edge allows this type
                    let allowed = match self.edges.get(&eid) {
                        Some(e) => e.is_item_type_allowed(&item_type) && !e.is_transit_full(),
                        None => false,
                    };
                    if !allowed {
                        continue;
                    }

                    // Transfer: remove from source, place on edge
                    events.push(GraphEvent::ItemLeave {
                        item_id: iid,
                        node_id: source_node_id,
                    });
                    events.push(GraphEvent::EdgeEnter {
                        item_id: iid,
                        edge_id: eid,
                    });

                    if let Some(src) = self.nodes.get_mut(&source_node_id) {
                        src.items.retain(|&id| id != iid);
                    }
                    if let Some(edge) = self.edges.get_mut(&eid) {
                        edge.items_in_transit.push(iid);
                        edge.cooldown_timer = edge.cooldown;
                    }
                    if let Some(item) = self.items.get_mut(&iid) {
                        item.position = ItemPosition::InTransit {
                            edge_id: eid,
                            progress: 0.0,
                        };
                    }
                    pulled += 1;
                    break; // one item per edge per cycle
                }
            }
        }
    }

    /// Phase 6: Conversions — consume input items and produce output items.
    fn process_conversions(&mut self, events: &mut Vec<GraphEvent>) {
        let node_ids: Vec<u64> = self.nodes.keys().copied().collect();

        for nid in node_ids {
            let conversions: Vec<(String, String, u32, u32)> = match self.nodes.get(&nid) {
                Some(node) if node.active && !node.conversions.is_empty() => node
                    .conversions
                    .values()
                    .map(|r| {
                        (
                            r.in_type.clone(),
                            r.out_type.clone(),
                            r.in_count,
                            r.out_count,
                        )
                    })
                    .collect(),
                _ => continue,
            };

            for (in_type, out_type, in_count, out_count) in conversions {
                loop {
                    // Find matching items at this node
                    let matching: Vec<u64> = {
                        let node = match self.nodes.get(&nid) {
                            Some(n) => n,
                            None => break,
                        };
                        node.items
                            .iter()
                            .filter(|&&iid| {
                                self.items
                                    .get(&iid)
                                    .map(|i| i.alive && i.item_type == in_type)
                                    .unwrap_or(false)
                            })
                            .copied()
                            .take(in_count as usize)
                            .collect()
                    };

                    if matching.len() < in_count as usize {
                        break;
                    }

                    // Consume input items
                    let consumed = matching;
                    for &iid in &consumed {
                        if let Some(item) = self.items.get_mut(&iid) {
                            item.kill();
                        }
                        if let Some(node) = self.nodes.get_mut(&nid) {
                            node.items.retain(|&id| id != iid);
                        }
                    }

                    // Produce output items
                    let mut produced = Vec::new();
                    for _ in 0..out_count {
                        let new_id = self.create_item(&out_type, -1.0);
                        if let Some(item) = self.items.get_mut(&new_id) {
                            item.position = ItemPosition::AtNode(nid);
                        }
                        if let Some(node) = self.nodes.get_mut(&nid) {
                            node.items.push(new_id);
                        }
                        produced.push(new_id);
                    }

                    events.push(GraphEvent::ItemConvert {
                        node_id: nid,
                        consumed: consumed.clone(),
                        produced,
                    });
                }
            }
        }
    }

    /// Phase 7: Queue processing — dequeue items when capacity and process_time allow.
    fn process_queues(&mut self, dt: f64, events: &mut Vec<GraphEvent>) {
        let node_ids: Vec<u64> = self.nodes.keys().copied().collect();

        for nid in node_ids {
            let should_dequeue = {
                let node = match self.nodes.get_mut(&nid) {
                    Some(n) => n,
                    None => continue,
                };
                if !node.queue_enabled || node.queue.is_empty() {
                    continue;
                }
                node.process_accumulator += dt;
                if node.process_time > 0.0 && node.process_accumulator < node.process_time {
                    continue;
                }
                if node.is_full() {
                    continue;
                }
                node.process_accumulator = 0.0;
                true
            };

            if should_dequeue {
                let item_id = {
                    let node = self.nodes.get_mut(&nid).unwrap();
                    match node.dequeue() {
                        Some(id) => id,
                        None => continue,
                    }
                };

                // Place into node items
                if let Some(node) = self.nodes.get_mut(&nid) {
                    node.items.push(item_id);
                }
                if let Some(item) = self.items.get_mut(&item_id) {
                    item.position = ItemPosition::AtNode(nid);
                }
                events.push(GraphEvent::ItemDequeued {
                    item_id,
                    node_id: nid,
                });
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::graph::node::{ConversionRule, FlowMode, OverflowPolicy};

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
        assert!(events.iter().any(|e| matches!(e, GraphEvent::ItemDecay { item_id } if *item_id == i)));
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
