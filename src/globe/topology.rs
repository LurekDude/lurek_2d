//! Province adjacency graph for the globe module.
//!
//! `ProvinceGraph` owns the full province set for one globe and exposes:
//! - O(1) province lookup
//! - Neighbour iteration
//! - Shortest-path queries via `crate::pathfind::graph_path::find_province_path`
//! - Reach queries via `crate::pathfind::graph_path::province_reachable`
//!
//! This module contains no rendering code and no Lua imports.

use std::collections::{HashMap, HashSet};
use crate::globe::types::{GlobeError, Province, ProvinceId, MAX_PROVINCES};
use crate::pathfind::graph_path::{find_province_path, ProvinceCostFn, ProvincePath};

/// Complete province topology for one globe instance.
///
/// # Fields
/// - `provinces` — All provinces keyed by ID.
/// - `neighbors` — Adjacency list (pre-extracted for fast pathfinding).
/// - `centroids` — Flat `(x, y)` centroid cache for heuristic distance.
#[derive(Debug, Clone, Default)]
pub struct ProvinceGraph {
    /// All provinces by ID.
    pub provinces: HashMap<ProvinceId, Province>,
    /// Adjacency list. Derived from `Province::neighbors` at insert time.
    neighbors: HashMap<u32, Vec<u32>>,
    /// Centroid cache for A* heuristic.
    centroids: HashMap<u32, (f32, f32)>,
    /// Edge tag cache for cost functions.
    edge_tags: HashMap<(u32, u32), HashSet<String>>,
}

impl ProvinceGraph {
    /// Create an empty graph.
    pub fn new() -> Self {
        Self::default()
    }

    /// Insert a province. Returns `GlobeError::TooManyProvinces` if the cap is exceeded.
    pub fn insert(&mut self, p: Province) -> Result<(), GlobeError> {
        if self.provinces.len() >= MAX_PROVINCES {
            return Err(GlobeError::TooManyProvinces);
        }
        let id = p.id;
        // Build adjacency list entry.
        let nbrs: Vec<u32> = p.neighbors.clone();
        // Build edge_tags entries from province's own edge_tags map.
        for (key, tags) in &p.edge_tags {
            self.edge_tags.insert(*key, tags.clone());
        }
        self.neighbors.insert(id, nbrs);
        self.centroids.insert(id, p.centroid);
        self.provinces.insert(id, p);
        Ok(())
    }

    /// Remove a province by ID. Returns `None` if the province does not exist.
    pub fn remove(&mut self, id: ProvinceId) -> Option<Province> {
        let p = self.provinces.remove(&id)?;
        self.neighbors.remove(&id);
        self.centroids.remove(&id);
        // Remove edge_tags entries involving this id.
        self.edge_tags.retain(|(a, b), _| *a != id && *b != id);
        Some(p)
    }

    /// Get an immutable reference to a province.
    pub fn get(&self, id: ProvinceId) -> Option<&Province> {
        self.provinces.get(&id)
    }

    /// Get a mutable reference to a province.
    pub fn get_mut(&mut self, id: ProvinceId) -> Option<&mut Province> {
        self.provinces.get_mut(&id)
    }

    /// Iterate over all provinces.
    pub fn iter(&self) -> impl Iterator<Item = &Province> {
        self.provinces.values()
    }

    /// Number of provinces.
    pub fn len(&self) -> usize {
        self.provinces.len()
    }

    /// True if the graph is empty.
    pub fn is_empty(&self) -> bool {
        self.provinces.is_empty()
    }

    /// Find the shortest path between two provinces. Returns `GlobeError::NoPath` if unreachable.
    pub fn find_path(
        &self,
        from: ProvinceId,
        to: ProvinceId,
        cost_fn: &ProvinceCostFn,
    ) -> Result<ProvincePath, GlobeError> {
        find_province_path(&self.neighbors, &self.centroids, &self.edge_tags, from, to, cost_fn)
            .ok_or(GlobeError::NoPath(from, to))
    }

    /// Find all provinces reachable from `start` within `max_cost`.
    /// Returns a map of `ProvinceId → accumulated_cost`.
    pub fn reachable(
        &self,
        start: ProvinceId,
        max_cost: f64,
        cost_fn: &ProvinceCostFn,
    ) -> HashMap<ProvinceId, f64> {
        crate::pathfind::graph_path::province_reachable(
            &self.neighbors,
            &self.edge_tags,
            start,
            max_cost,
            cost_fn,
        )
    }

    /// Return the direct neighbors of a province.
    pub fn neighbors_of(&self, id: ProvinceId) -> &[ProvinceId] {
        self.neighbors.get(&id).map(Vec::as_slice).unwrap_or(&[])
    }

    /// Set a user attribute on a province.
    pub fn set_attr(&mut self, id: ProvinceId, key: String, value: String) -> Result<(), GlobeError> {
        let p = self.provinces.get_mut(&id).ok_or(GlobeError::ProvinceNotFound(id))?;
        p.attrs.insert(key, value);
        Ok(())
    }

    /// Get a user attribute from a province.
    pub fn get_attr(&self, id: ProvinceId, key: &str) -> Option<&str> {
        self.provinces.get(&id)?.attrs.get(key).map(String::as_str)
    }

    /// Convenience: find path using the default cost function (uniform cost 1.0).
    pub fn find_path_default(&self, from: ProvinceId, to: ProvinceId) -> Option<ProvincePath> {
        let cost_fn = ProvinceCostFn::new();
        self.find_path(from, to, &cost_fn).ok()
    }

    /// Convenience: find reachable provinces using the default cost function.
    pub fn reachable_default(&self, start: ProvinceId, max_cost: f64) -> HashMap<ProvinceId, f64> {
        let cost_fn = ProvinceCostFn::new();
        self.reachable(start, max_cost, &cost_fn)
    }

    /// Rebuild the neighbor + centroid caches from the current province set.
    /// Call after bulk-loading from a file if the Province::neighbors fields are already set.
    pub fn rebuild_caches(&mut self) {
        self.neighbors.clear();
        self.centroids.clear();
        self.edge_tags.clear();
        for (id, p) in &self.provinces {
            self.neighbors.insert(*id, p.neighbors.clone());
            self.centroids.insert(*id, p.centroid);
            for (k, v) in &p.edge_tags {
                self.edge_tags.insert(*k, v.clone());
            }
        }
    }
}
