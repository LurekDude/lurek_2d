//! Supply and demand processing that spawns and routes items between nodes.
//!
//! Owns one demand-resolution pass over graph nodes.
//! It does not update transit timers or decay.

use super::core::Graph;
use super::item::ItemPosition;
use super::simulation::GraphEvent;
impl Graph {
    /// Process node demands and return the resulting graph events.
    pub fn process_demand(&mut self) -> Vec<GraphEvent> {
        let mut events = Vec::new();
        let mut all_demands: Vec<(u64, String, i32, i32)> = Vec::new();
        for node in self.nodes.values() {
            for d in &node.demands {
                all_demands.push((node.id, d.item_type.clone(), d.quantity, d.priority));
            }
        }
        all_demands.sort_by(|a, b| b.3.cmp(&a.3));
        for (demand_node_id, item_type, quantity, _priority) in all_demands {
            let mut remaining = quantity;
            let supply_nodes: Vec<u64> = self
                .nodes
                .values()
                .filter(|n| {
                    n.id != demand_node_id
                        && n.supplies
                            .iter()
                            .any(|s| s.item_type == item_type && s.quantity != 0)
                })
                .map(|n| n.id)
                .collect();
            for supply_node_id in supply_nodes {
                if remaining <= 0 {
                    break;
                }
                let path = match self.find_path(supply_node_id, demand_node_id) {
                    Some(p) => p,
                    None => continue,
                };
                let available = self
                    .nodes
                    .get(&supply_node_id)
                    .map(|n| n.get_available_supply(&item_type))
                    .unwrap_or(0);
                let to_send = if available < 0 {
                    remaining
                } else {
                    remaining.min(available)
                };
                if to_send <= 0 {
                    continue;
                }
                let mut sent = 0;
                for _ in 0..to_send {
                    let item_id = self.create_item(&item_type, -1.0);
                    if let Some(item) = self.items.get_mut(&item_id) {
                        item.position = ItemPosition::AtNode(supply_node_id);
                    }
                    if let Some(node) = self.nodes.get_mut(&supply_node_id) {
                        node.items.push(item_id);
                    }
                    if let Some(&first_edge) = path.edges.first() {
                        match self.send_item(item_id, first_edge) {
                            Ok(true) => {
                                sent += 1;
                            }
                            _ => {
                                self.remove_item(item_id);
                                break;
                            }
                        }
                    } else {
                        sent += 1;
                    }
                }
                if sent > 0 {
                    remaining -= sent;
                    if let Some(node) = self.nodes.get_mut(&supply_node_id) {
                        for s in &mut node.supplies {
                            if s.item_type == item_type && s.quantity > 0 {
                                s.quantity -= sent;
                                if s.quantity <= 0 {
                                    events.push(GraphEvent::SupplyDepleted {
                                        node_id: supply_node_id,
                                        item_type: item_type.clone(),
                                    });
                                }
                                break;
                            }
                        }
                    }
                    events.push(GraphEvent::DemandFulfilled {
                        demand_node: demand_node_id,
                        supply_node: supply_node_id,
                        item_type: item_type.clone(),
                        count: sent as u32,
                    });
                }
            }
        }
        events
    }
}
