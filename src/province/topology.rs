//! Province topology graph and adjacency helpers.

use std::collections::{HashMap, HashSet};

use crate::province::types::ProvinceId;

/// Undirected adjacency graph between provinces.
#[derive(Debug, Clone, Default)]
pub struct ProvinceGraph {
    neighbors: HashMap<ProvinceId, Vec<ProvinceId>>,
}

impl ProvinceGraph {
    /// Creates an empty province graph.
    pub fn new() -> Self {
        Self::default()
    }

    /// Rebuilds graph from sorted/unsorted adjacency pairs.
    pub fn rebuild_from_pairs(&mut self, pairs: &[(ProvinceId, ProvinceId)]) {
        self.neighbors.clear();
        for &(a, b) in pairs {
            if a == 0 || b == 0 || a == b {
                continue;
            }
            self.neighbors.entry(a).or_default().push(b);
            self.neighbors.entry(b).or_default().push(a);
        }
        for list in self.neighbors.values_mut() {
            list.sort_unstable();
            list.dedup();
        }
    }

    /// Returns neighbor ids for one province.
    pub fn neighbors_of(&self, id: ProvinceId) -> &[ProvinceId] {
        static EMPTY: [ProvinceId; 0] = [];
        self.neighbors.get(&id).map_or(&EMPTY, Vec::as_slice)
    }

    /// Returns true if two provinces share an adjacency edge.
    pub fn is_adjacent(&self, a: ProvinceId, b: ProvinceId) -> bool {
        self.neighbors_of(a).binary_search(&b).is_ok()
    }

    /// Returns sorted province ids present in topology.
    pub fn province_ids(&self) -> Vec<ProvinceId> {
        let mut ids: Vec<ProvinceId> = self.neighbors.keys().copied().collect();
        ids.sort_unstable();
        ids
    }

    /// Returns normalized unique adjacency pairs (a<b).
    pub fn adjacency_pairs(&self) -> Vec<(ProvinceId, ProvinceId)> {
        let mut out = Vec::new();
        let mut seen = HashSet::new();
        for (&a, list) in &self.neighbors {
            for &b in list {
                let (x, y) = if a < b { (a, b) } else { (b, a) };
                if seen.insert((x, y)) {
                    out.push((x, y));
                }
            }
        }
        out.sort_unstable();
        out
    }
}
