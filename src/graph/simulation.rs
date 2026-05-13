use super::core::Graph;
use super::item::ItemPosition;
use super::node::FlowMode;
use crate::log_msg;
use crate::runtime::log_messages::{GR01, GR02};
#[derive(Debug, Clone)]
pub enum GraphEvent {
    ItemEnter {
        item_id: u64,
        node_id: u64,
    },
    ItemLeave {
        item_id: u64,
        node_id: u64,
    },
    ItemDecay {
        item_id: u64,
    },
    ItemConvert {
        node_id: u64,
        consumed: Vec<u64>,
        produced: Vec<u64>,
    },
    ItemLost {
        item_id: u64,
        node_id: u64,
    },
    EdgeEnter {
        item_id: u64,
        edge_id: u64,
    },
    EdgeLeave {
        item_id: u64,
        edge_id: u64,
    },
    DemandFulfilled {
        demand_node: u64,
        supply_node: u64,
        item_type: String,
        count: u32,
    },
    SupplyDepleted {
        node_id: u64,
        item_type: String,
    },
    ItemQueued {
        item_id: u64,
        node_id: u64,
    },
    ItemDequeued {
        item_id: u64,
        node_id: u64,
    },
}
impl Graph {
    pub fn update(&mut self, dt: f64) -> Vec<GraphEvent> {
        log_msg!(debug, GR01);
        let mut events = Vec::new();
        self.process_decay(dt, &mut events);
        self.process_transit(dt, &mut events);
        self.process_cooldowns(dt);
        self.process_push_flow(dt, &mut events);
        self.process_pull_flow(dt, &mut events);
        self.process_conversions(&mut events);
        self.process_queues(dt, &mut events);
        log_msg!(debug, GR02, "{}", events.len());
        events
    }
    pub fn step(&mut self) -> Vec<GraphEvent> {
        self.update(1.0)
    }
    #[cfg(feature = "graph-parallel")]
    pub fn update_parallel(&mut self, dt: f64) -> Vec<GraphEvent> {
        use rayon::prelude::*;
        log_msg!(debug, GR01);
        let mut events = Vec::new();
        self.items.par_iter_mut().for_each(|(_, item)| {
            if item.alive && item.decay_time >= 0.0 {
                item.remaining_life -= dt;
            }
        });
        let dead_ids: Vec<u64> = self
            .items
            .iter()
            .filter_map(|(id, item)| {
                if item.alive && item.decay_time >= 0.0 && item.remaining_life <= 0.0 {
                    Some(*id)
                } else {
                    None
                }
            })
            .collect();
        for id in dead_ids {
            if let Some(item) = self.items.get_mut(&id) {
                item.kill();
            }
            events.push(GraphEvent::ItemDecay { item_id: id });
            for node in self.nodes.values_mut() {
                node.items.retain(|&iid| iid != id);
                node.queue.retain(|&iid| iid != id);
            }
            for edge in self.edges.values_mut() {
                edge.items_in_transit.retain(|&iid| iid != id);
            }
        }
        self.process_transit(dt, &mut events);
        self.process_cooldowns(dt);
        self.process_push_flow(dt, &mut events);
        self.process_pull_flow(dt, &mut events);
        self.process_conversions(&mut events);
        self.process_queues(dt, &mut events);
        log_msg!(debug, GR02, "{}", events.len());
        events
    }
    #[cfg(not(feature = "graph-parallel"))]
    pub fn update_parallel(&mut self, dt: f64) -> Vec<GraphEvent> {
        self.update(dt)
    }
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
            for node in self.nodes.values_mut() {
                node.items.retain(|&iid| iid != id);
                node.queue.retain(|&iid| iid != id);
            }
            for edge in self.edges.values_mut() {
                edge.items_in_transit.retain(|&iid| iid != id);
            }
        }
    }
    fn process_transit(&mut self, dt: f64, events: &mut Vec<GraphEvent>) {
        let mut arrivals: Vec<(u64, u64, u64)> = Vec::new();
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
        for (item_id, edge_id, dest_node) in arrivals {
            events.push(GraphEvent::EdgeLeave { item_id, edge_id });
            if let Some(edge) = self.edges.get_mut(&edge_id) {
                edge.items_in_transit.retain(|&id| id != item_id);
            }
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
    fn process_cooldowns(&mut self, dt: f64) {
        for edge in self.edges.values_mut() {
            if edge.cooldown_timer > 0.0 {
                edge.cooldown_timer = (edge.cooldown_timer - dt).max(0.0);
            }
        }
    }
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
                if let Some(ref filter) = push_filter {
                    if &item_type != filter {
                        continue;
                    }
                }
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
                        if let Some(node) = self.nodes.get_mut(&nid) {
                            node.items.retain(|&id| id != iid);
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
                        sent += 1;
                        break;
                    }
                }
            }
        }
    }
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
                if let Some(node) = self.nodes.get(&nid) {
                    if node.is_full() {
                        break;
                    }
                }
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
                    if let Some(ref filter) = pull_filter {
                        if &item_type != filter {
                            continue;
                        }
                    }
                    let allowed = match self.edges.get(&eid) {
                        Some(e) => e.is_item_type_allowed(&item_type) && !e.is_transit_full(),
                        None => false,
                    };
                    if !allowed {
                        continue;
                    }
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
                    break;
                }
            }
        }
    }
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
                    let consumed = matching;
                    for &iid in &consumed {
                        if let Some(item) = self.items.get_mut(&iid) {
                            item.kill();
                        }
                        if let Some(node) = self.nodes.get_mut(&nid) {
                            node.items.retain(|&id| id != iid);
                        }
                    }
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
