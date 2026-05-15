//! - Mutable globe state combining topology, fog, markers, labels, layers, and arcs.
//! - Province add/remove/get and sector grouping operations.
//! - Heat-layer and arc overlay management with add/replace/remove.
//! - Orbit camera integration and screen-space province picking.
//! - Frame emission producing render commands for the full globe state.
//! - Named globe registry for storing and retrieving multiple globes by name.
//! - Reachability caching per faction for path-cost queries.

use crate::globe::draw::emit_globe_frame;
use crate::globe::fog::FogStore;
use crate::globe::label::LabelStore;
use crate::globe::layer::LayerStore;
use crate::globe::marker::MarkerStore;
use crate::globe::picking::{pick, PickResult};
use crate::globe::projection::OrbitCamera;
use crate::globe::topology::ProvinceGraph;
use crate::globe::types::{
    Arc as GlobeArc, GlobeError, GlobeSpec, HeatLayer, Province, ProvinceId, MAX_PROVINCES,
};
use crate::render::renderer::RenderCommand;
use crate::runtime::resource_keys::FontKey;
use std::collections::{HashMap, HashSet};
/// Mutable globe state used by the renderer and sync layers.
#[derive(Debug, Default)]
pub struct Globe {
    /// Globe name used for lookup.
    pub name: String,
    /// Shared render and simulation parameters.
    pub spec: GlobeSpec,
    /// Orbit camera used for projection.
    pub camera: OrbitCamera,
    /// Province topology and cached adjacency.
    pub graph: ProvinceGraph,
    /// Fog state per viewer.
    pub fog: FogStore,
    /// Marker collection for the globe.
    pub markers: MarkerStore,
    /// Label collection for the globe.
    pub labels: LabelStore,
    /// Overlay layer collection.
    pub layers: LayerStore,
    /// Arc render data keyed by id.
    pub arcs: HashMap<u32, GlobeArc>,
    /// Next arc id to assign.
    pub arc_next_id: u32,
    /// Active viewer name used for fog lookups.
    pub active_viewer: Option<String>,
    /// Heat overlays currently applied to the globe.
    pub heat_layers: Vec<HeatLayer>,
    /// Province ids grouped by sector name.
    pub sectors: HashMap<String, HashSet<ProvinceId>>,
    /// Cached reachability per faction name.
    pub reachability_cache: HashMap<String, HashMap<ProvinceId, f64>>,
    /// Simulation time in seconds.
    pub sim_time_sec: f32,
}
impl Globe {
    /// Create a globe with the supplied name and spec.
    pub fn new(name: impl Into<String>, spec: GlobeSpec) -> Self {
        Self {
            name: name.into(),
            spec,
            ..Default::default()
        }
    }
    /// Insert a province or return TooManyProvinces when the graph is full.
    pub fn add_province(&mut self, province: Province) -> Result<(), GlobeError> {
        if self.graph.len() >= MAX_PROVINCES {
            return Err(GlobeError::TooManyProvinces);
        }
        self.graph.insert(province)?;
        Ok(())
    }
    /// Remove a province by id and return it when present.
    pub fn remove_province(&mut self, id: ProvinceId) -> Option<Province> {
        self.graph.remove(id)
    }
    /// Return a shared province reference when the id exists.
    pub fn get_province(&self, id: ProvinceId) -> Option<&Province> {
        self.graph.get(id)
    }
    /// Return a mutable province reference when the id exists.
    pub fn get_province_mut(&mut self, id: ProvinceId) -> Option<&mut Province> {
        self.graph.get_mut(id)
    }
    /// Return the number of stored provinces.
    pub fn province_count(&self) -> usize {
        self.graph.len()
    }
    /// Insert an arc and return its assigned id.
    pub fn add_arc(&mut self, arc: GlobeArc) -> u32 {
        let id = self.arc_next_id;
        self.arc_next_id += 1;
        self.arcs.insert(id, arc);
        id
    }
    /// Remove an arc by id and return true when it existed.
    pub fn remove_arc(&mut self, id: u32) -> bool {
        self.arcs.remove(&id).is_some()
    }
    /// Advance simulation time and update the globe clock and rotation.
    pub fn update(&mut self, dt: f32) {
        let speed = 1.0;
        self.spec.time_of_day = (self.spec.time_of_day + dt * speed / 3600.0) % 24.0;
        self.spec.rotation_deg =
            (self.spec.rotation_deg + dt * self.spec.auto_rotation_deg_per_sec) % 360.0;
        self.sim_time_sec += dt.max(0.0);
    }
    /// Pick a province at screen coordinates or return None when no province matches.
    pub fn pick_screen(&self, sx: f32, sy: f32) -> Option<PickResult> {
        pick(sx, sy, &self.spec, &self.camera, &self.graph)
    }
    /// Emit render commands for the current globe state.
    pub fn emit_frame(&self, default_font: Option<FontKey>) -> Vec<RenderCommand> {
        emit_globe_frame(
            &self.spec,
            &self.camera,
            &self.graph,
            &self.fog,
            &self.markers,
            &self.labels,
            &self.layers,
            &self.heat_layers,
            &self.arcs,
            self.active_viewer.as_deref(),
            default_font,
            self.sim_time_sec,
        )
    }
    /// Add or replace a heat layer by name.
    pub fn set_heat_layer(&mut self, layer: HeatLayer) {
        if let Some(existing) = self.heat_layers.iter_mut().find(|l| l.name == layer.name) {
            *existing = layer;
            return;
        }
        self.heat_layers.push(layer);
    }
    /// Remove a heat layer by name and return true when one was removed.
    pub fn remove_heat_layer(&mut self, name: &str) -> bool {
        let before = self.heat_layers.len();
        self.heat_layers.retain(|l| l.name != name);
        self.heat_layers.len() != before
    }
    /// Assign a province to a named sector.
    pub fn set_province_sector(&mut self, id: ProvinceId, sector: impl Into<String>) {
        let sector = sector.into();
        for ids in self.sectors.values_mut() {
            ids.remove(&id);
        }
        self.sectors.entry(sector).or_default().insert(id);
    }
    /// Return the sector name that contains a province when one exists.
    pub fn province_sector(&self, id: ProvinceId) -> Option<&str> {
        self.sectors.iter().find_map(|(name, ids)| {
            if ids.contains(&id) {
                Some(name.as_str())
            } else {
                None
            }
        })
    }
    /// Return all province ids for a named sector.
    pub fn sector_provinces(&self, sector: &str) -> Vec<ProvinceId> {
        self.sectors
            .get(sector)
            .map(|set| set.iter().copied().collect())
            .unwrap_or_default()
    }
    /// Cache default reachability for a faction name.
    pub fn cache_reachability_default(
        &mut self,
        faction: impl Into<String>,
        start: ProvinceId,
        max_cost: f64,
    ) {
        let map = self.graph.reachable_default(start, max_cost);
        self.reachability_cache.insert(faction.into(), map);
    }
    /// Return cached reachability for a faction when present.
    pub fn cached_reachability(&self, faction: &str) -> Option<&HashMap<ProvinceId, f64>> {
        self.reachability_cache.get(faction)
    }
}
/// Named globe registry keyed by globe name.
#[derive(Debug, Default)]
pub struct GlobeRegistry {
    /// Stored globes by name.
    globes: HashMap<String, Globe>,
}
impl GlobeRegistry {
    /// Create an empty globe registry.
    pub fn new() -> Self {
        Self::default()
    }
    /// Create or replace a globe and return a mutable reference to it.
    pub fn create(&mut self, name: impl Into<String>, spec: GlobeSpec) -> &mut Globe {
        let name = name.into();
        self.globes
            .insert(name.clone(), Globe::new(name.clone(), spec));
        self.globes.get_mut(&name).expect("just inserted")
    }
    /// Return a shared globe reference when the name exists.
    pub fn get(&self, name: &str) -> Option<&Globe> {
        self.globes.get(name)
    }
    /// Return a mutable globe reference when the name exists.
    pub fn get_mut(&mut self, name: &str) -> Option<&mut Globe> {
        self.globes.get_mut(name)
    }
    /// Remove a globe by name and return it when found.
    pub fn remove(&mut self, name: &str) -> Option<Globe> {
        self.globes.remove(name)
    }
    /// Return all globe names in arbitrary order.
    pub fn names(&self) -> Vec<String> {
        self.globes.keys().cloned().collect()
    }
    /// Return the number of stored globes.
    pub fn len(&self) -> usize {
        self.globes.len()
    }
    /// Return true when no globes are stored.
    pub fn is_empty(&self) -> bool {
        self.globes.is_empty()
    }
}
