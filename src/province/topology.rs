//! Province adjacency graph built from pixel-scan output in ProvinceGrid.
//! Stores neighbour lists indexed by ProvinceId and exposes adjacency queries.
//! Does not own geometry, styles, or rendering data.
use crate::province::types::ProvinceId;
use std::collections::{HashMap, HashSet};

/// Undirected adjacency graph over provinces; neighbours stored sorted for binary search.
#[derive(Debug, Clone, Default)]
pub struct ProvinceGraph {
    /// Sorted neighbour lists keyed by province id.
    neighbors: HashMap<ProvinceId, Vec<ProvinceId>>,
}

impl ProvinceGraph {
    /// Return a new empty graph.
    pub fn new() -> Self {
        Self::default()
    }

    /// Rebuild the graph from a slice of adjacent id pairs; clears previous data.
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

    /// Return the sorted neighbour slice for id; returns an empty slice if id has no entry.
    pub fn neighbors_of(&self, id: ProvinceId) -> &[ProvinceId] {
        static EMPTY: [ProvinceId; 0] = [];
        self.neighbors.get(&id).map_or(&EMPTY, Vec::as_slice)
    }

    /// Return true if a and b share a border in the graph.
    pub fn is_adjacent(&self, a: ProvinceId, b: ProvinceId) -> bool {
        self.neighbors_of(a).binary_search(&b).is_ok()
    }

    /// Return all province ids present in the graph, sorted ascending.
    pub fn province_ids(&self) -> Vec<ProvinceId> {
        let mut ids: Vec<ProvinceId> = self.neighbors.keys().copied().collect();
        ids.sort_unstable();
        ids
    }

    /// Return all unique adjacency pairs (a < b) sorted ascending.
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
