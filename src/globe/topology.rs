use crate::globe::types::{GlobeError, Province, ProvinceId, MAX_PROVINCES};
use crate::pathfind::graph_path::{find_province_path, ProvinceCostFn, ProvincePath};
use std::collections::{HashMap, HashSet};
#[derive(Debug, Clone, Default)]
pub struct ProvinceGraph {
    pub provinces: HashMap<ProvinceId, Province>,
    neighbors: HashMap<u32, Vec<u32>>,
    centroids: HashMap<u32, (f32, f32)>,
    edge_tags: HashMap<(u32, u32), HashSet<String>>,
}
impl ProvinceGraph {
    pub fn new() -> Self {
        Self::default()
    }
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
    pub fn remove(&mut self, id: ProvinceId) -> Option<Province> {
        let p = self.provinces.remove(&id)?;
        self.neighbors.remove(&id);
        self.centroids.remove(&id);
        self.edge_tags.retain(|(a, b), _| *a != id && *b != id);
        Some(p)
    }
    pub fn get(&self, id: ProvinceId) -> Option<&Province> {
        self.provinces.get(&id)
    }
    pub fn get_mut(&mut self, id: ProvinceId) -> Option<&mut Province> {
        self.provinces.get_mut(&id)
    }
    pub fn iter(&self) -> impl Iterator<Item = &Province> {
        self.provinces.values()
    }
    pub fn len(&self) -> usize {
        self.provinces.len()
    }
    pub fn is_empty(&self) -> bool {
        self.provinces.is_empty()
    }
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
    pub fn neighbors_of(&self, id: ProvinceId) -> &[ProvinceId] {
        self.neighbors.get(&id).map(Vec::as_slice).unwrap_or(&[])
    }
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
    pub fn get_attr(&self, id: ProvinceId, key: &str) -> Option<&str> {
        self.provinces.get(&id)?.attrs.get(key).map(String::as_str)
    }
    pub fn find_path_default(&self, from: ProvinceId, to: ProvinceId) -> Option<ProvincePath> {
        let cost_fn = ProvinceCostFn::new();
        self.find_path(from, to, &cost_fn).ok()
    }
    pub fn reachable_default(&self, start: ProvinceId, max_cost: f64) -> HashMap<ProvinceId, f64> {
        let cost_fn = ProvinceCostFn::new();
        self.reachable(start, max_cost, &cost_fn)
    }
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
