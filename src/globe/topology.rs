//! Province graph topology and cached pathfinding data for globe routing.
//!
//! Owns province storage, adjacency caches, and path query helpers.
//! Path cost policy lives in the pathfinding module.

use crate::globe::types::{GlobeError, Province, ProvinceId, MAX_PROVINCES};
use crate::pathfind::graph_path::{find_province_path, ProvinceCostFn, ProvincePath};
use std::collections::{HashMap, HashSet};
/// Province graph with cached adjacency, centroids, and edge tags.
#[derive(Debug, Clone, Default)]
pub struct ProvinceGraph {
    /// Stored provinces by id.
    pub provinces: HashMap<ProvinceId, Province>,
    /// Cached neighbor lists by province id.
    neighbors: HashMap<u32, Vec<u32>>,
    /// Cached province centroids by id.
    centroids: HashMap<u32, (f32, f32)>,
    /// Cached edge tags keyed by ordered province id pairs.
    edge_tags: HashMap<(u32, u32), HashSet<String>>,
}
impl ProvinceGraph {
    /// Create an empty province graph.
    pub fn new() -> Self {
        Self::default()
    }
    /// Insert a province and update the cached adjacency data.
    pub fn insert(&mut self, p: Province) -> Result<(), GlobeError> {
        if self.provinces.len() >= MAX_PROVINCES {
            return Err(GlobeError::TooManyProvinces);
        }
        let id = p.id;
        let nbrs: Vec<u32> = p.neighbors.clone();
        for (key, tags) in &p.edge_tags {
            self.edge_tags.insert(*key, tags.clone());
        }
        self.neighbors.insert(id, nbrs);
        self.centroids.insert(id, p.centroid);
        self.provinces.insert(id, p);
        Ok(())
    }
    /// Remove a province and its cached data, returning the removed province when present.
    pub fn remove(&mut self, id: ProvinceId) -> Option<Province> {
        let p = self.provinces.remove(&id)?;
        self.neighbors.remove(&id);
        self.centroids.remove(&id);
        self.edge_tags.retain(|(a, b), _| *a != id && *b != id);
        Some(p)
    }
    /// Return a shared province reference when the id exists.
    pub fn get(&self, id: ProvinceId) -> Option<&Province> {
        self.provinces.get(&id)
    }
    /// Return a mutable province reference when the id exists.
    pub fn get_mut(&mut self, id: ProvinceId) -> Option<&mut Province> {
        self.provinces.get_mut(&id)
    }
    /// Iterate over all stored provinces.
    pub fn iter(&self) -> impl Iterator<Item = &Province> {
        self.provinces.values()
    }
    /// Return the number of stored provinces.
    pub fn len(&self) -> usize {
        self.provinces.len()
    }
    /// Return true when no provinces are stored.
    pub fn is_empty(&self) -> bool {
        self.provinces.is_empty()
    }
    /// Find a province path or return NoPath when no route exists.
    pub fn find_path(
        &self,
        from: ProvinceId,
        to: ProvinceId,
        cost_fn: &ProvinceCostFn,
    ) -> Result<ProvincePath, GlobeError> {
        find_province_path(
            &self.neighbors,
            &self.centroids,
            &self.edge_tags,
            from,
            to,
            cost_fn,
        )
        .ok_or(GlobeError::NoPath(from, to))
    }
    /// Return provinces reachable within the supplied maximum cost.
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
    /// Return the cached neighbor slice for a province or an empty slice when missing.
    pub fn neighbors_of(&self, id: ProvinceId) -> &[ProvinceId] {
        self.neighbors.get(&id).map(Vec::as_slice).unwrap_or(&[])
    }
    /// Set a province attribute or return ProvinceNotFound when the id is missing.
    pub fn set_attr(
        &mut self,
        id: ProvinceId,
        key: String,
        value: String,
    ) -> Result<(), GlobeError> {
        let p = self
            .provinces
            .get_mut(&id)
            .ok_or(GlobeError::ProvinceNotFound(id))?;
        p.attrs.insert(key, value);
        Ok(())
    }
    /// Return a province attribute as a string slice when it exists.
    pub fn get_attr(&self, id: ProvinceId, key: &str) -> Option<&str> {
        self.provinces.get(&id)?.attrs.get(key).map(String::as_str)
    }
    /// Find a province path with the default cost function.
    pub fn find_path_default(&self, from: ProvinceId, to: ProvinceId) -> Option<ProvincePath> {
        let cost_fn = ProvinceCostFn::new();
        self.find_path(from, to, &cost_fn).ok()
    }
    /// Return reachable provinces with the default cost function.
    pub fn reachable_default(&self, start: ProvinceId, max_cost: f64) -> HashMap<ProvinceId, f64> {
        let cost_fn = ProvinceCostFn::new();
        self.reachable(start, max_cost, &cost_fn)
    }
    /// Rebuild all cached adjacency and edge-tag data from the stored provinces.
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
