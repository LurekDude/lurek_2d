//! Bridge between province map adjacency and the [`crate::graph`] module.
//!
//! Converts a [`ProvinceMap`]'s provinces and adjacency edges into a directed
//! [`Graph`], allowing graph algorithms (Dijkstra, flow, connected components)
//! to operate on the province network.

use std::collections::HashMap;

use crate::graph::Graph;

use super::core::ProvinceMap;

/// Convert province map adjacency into a [`Graph`].
///
/// Each province becomes a node (type `"province"`, capacity 0). Each
/// adjacency edge becomes two directed graph edges (one in each direction)
/// with type `"adjacency"`.
///
/// Returns the graph and a mapping from province ID to graph node ID, so
/// callers can translate between the two ID spaces.
///
/// # Parameters
/// - `ap` — `&ProvinceMap`.
///
/// # Returns
/// `(Graph, HashMap<u32, u64>)`.
pub fn adjacency_to_graph(map: &ProvinceMap) -> (Graph, HashMap<u32, u64>) {
    let mut graph = Graph::new();
    let mut id_map: HashMap<u32, u64> = HashMap::new();

    // Create a node for each province
    for &pid in &map.province_ids() {
        let node_id = graph.add_node("province", 0);
        id_map.insert(pid, node_id);
    }

    // Create edges from adjacency data (bidirectional)
    let ids = map.province_ids();
    let mut seen = std::collections::HashSet::new();

    for &pid in &ids {
        for &neighbor in &map.get_neighbors(pid) {
            let key = if pid <= neighbor {
                (pid, neighbor)
            } else {
                (neighbor, pid)
            };
            if !seen.insert(key) {
                continue;
            }

            if let (Some(&from_node), Some(&to_node)) = (id_map.get(&key.0), id_map.get(&key.1)) {
                // Add edges in both directions
                let _ = graph.add_edge(from_node, to_node, Some("adjacency"));
                let _ = graph.add_edge(to_node, from_node, Some("adjacency"));
            }
        }
    }

    log::info!(
        "Province graph: {} nodes, {} edges",
        id_map.len(),
        graph.get_node_ids().len() // Use available API
    );

    (graph, id_map)
}
