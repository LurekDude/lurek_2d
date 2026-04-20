//! Supply/demand processing — match demands to supplies and route items.
//!
//! This module is part of Lurek2D's `graph` subsystem and provides the implementation
//! details for supply demand-related operations and data management.
//! Primary functions: `process_demand()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use super::core::Graph;
use super::item::ItemPosition;
use super::simulation::GraphEvent;

impl Graph {
    /// Processes all demand/supply declarations, routing items from supply nodes to demand nodes.
    ///
    /// # Returns
    /// `Vec<GraphEvent>`.
    ///
    /// Iterates demand nodes in priority order (highest first), finds matching
    /// supply nodes via pathfinding, creates items at the supply and routes them.
    /// Returns events for callback dispatch.
    pub fn process_demand(&mut self) -> Vec<GraphEvent> {
        let mut events = Vec::new();

        // Collect all demands: (demand_node_id, item_type, quantity, priority)
        let mut all_demands: Vec<(u64, String, i32, i32)> = Vec::new();
        for node in self.nodes.values() {
            for d in &node.demands {
                all_demands.push((node.id, d.item_type.clone(), d.quantity, d.priority));
            }
        }

        // Sort by priority descending
        all_demands.sort_by(|a, b| b.3.cmp(&a.3));

        for (demand_node_id, item_type, quantity, _priority) in all_demands {
            let mut remaining = quantity;

            // Find supply nodes that have this item type
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

                // Check path exists
                let path = match self.find_path(supply_node_id, demand_node_id) {
                    Some(p) => p,
                    None => continue,
                };

                // Determine how many items to send
                let available = self
                    .nodes
                    .get(&supply_node_id)
                    .map(|n| n.get_available_supply(&item_type))
                    .unwrap_or(0);

                let to_send = if available < 0 {
                    // unlimited
                    remaining
                } else {
                    remaining.min(available)
                };

                if to_send <= 0 {
                    continue;
                }

                let mut sent = 0;
                for _ in 0..to_send {
                    // Create item at supply node
                    let item_id = self.create_item(&item_type, -1.0);

                    // Place at supply node
                    if let Some(item) = self.items.get_mut(&item_id) {
                        item.position = ItemPosition::AtNode(supply_node_id);
                    }
                    if let Some(node) = self.nodes.get_mut(&supply_node_id) {
                        node.items.push(item_id);
                    }

                    // Route along the first edge of the path
                    if let Some(&first_edge) = path.edges.first() {
                        match self.send_item(item_id, first_edge) {
                            Ok(true) => {
                                sent += 1;
                            }
                            _ => {
                                // Failed to send — remove the item
                                self.remove_item(item_id);
                                break;
                            }
                        }
                    } else {
                        // No edges means supply_node == demand_node (shouldn't happen)
                        sent += 1;
                    }
                }

                if sent > 0 {
                    remaining -= sent;

                    // Decrement supply
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
