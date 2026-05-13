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
#[derive(Debug, Default)]
pub struct Globe {
    pub name: String,
    pub spec: GlobeSpec,
    pub camera: OrbitCamera,
    pub graph: ProvinceGraph,
    pub fog: FogStore,
    pub markers: MarkerStore,
    pub labels: LabelStore,
    pub layers: LayerStore,
    pub arcs: HashMap<u32, GlobeArc>,
    pub arc_next_id: u32,
    pub active_viewer: Option<String>,
    pub heat_layers: Vec<HeatLayer>,
    pub sectors: HashMap<String, HashSet<ProvinceId>>,
    pub reachability_cache: HashMap<String, HashMap<ProvinceId, f64>>,
    pub sim_time_sec: f32,
}
impl Globe {
    pub fn new(name: impl Into<String>, spec: GlobeSpec) -> Self {
        Self {
            name: name.into(),
            spec,
            ..Default::default()
        }
    }
    pub fn add_province(&mut self, province: Province) -> Result<(), GlobeError> {
        if self.graph.len() >= MAX_PROVINCES {
            return Err(GlobeError::TooManyProvinces);
        }
        self.graph.insert(province)?;
        Ok(())
    }
    pub fn remove_province(&mut self, id: ProvinceId) -> Option<Province> {
        self.graph.remove(id)
    }
    pub fn get_province(&self, id: ProvinceId) -> Option<&Province> {
        self.graph.get(id)
    }
    pub fn get_province_mut(&mut self, id: ProvinceId) -> Option<&mut Province> {
        self.graph.get_mut(id)
    }
    pub fn province_count(&self) -> usize {
        self.graph.len()
    }
    pub fn add_arc(&mut self, arc: GlobeArc) -> u32 {
        let id = self.arc_next_id;
        self.arc_next_id += 1;
        self.arcs.insert(id, arc);
        id
    }
    pub fn remove_arc(&mut self, id: u32) -> bool {
        self.arcs.remove(&id).is_some()
    }
    pub fn update(&mut self, dt: f32) {
        let speed = 1.0;
        self.spec.time_of_day = (self.spec.time_of_day + dt * speed / 3600.0) % 24.0;
        self.spec.rotation_deg =
            (self.spec.rotation_deg + dt * self.spec.auto_rotation_deg_per_sec) % 360.0;
        self.sim_time_sec += dt.max(0.0);
    }
    pub fn pick_screen(&self, sx: f32, sy: f32) -> Option<PickResult> {
        pick(sx, sy, &self.spec, &self.camera, &self.graph)
    }
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
    pub fn set_heat_layer(&mut self, layer: HeatLayer) {
        if let Some(existing) = self.heat_layers.iter_mut().find(|l| l.name == layer.name) {
            *existing = layer;
            return;
        }
        self.heat_layers.push(layer);
    }
    pub fn remove_heat_layer(&mut self, name: &str) -> bool {
        let before = self.heat_layers.len();
        self.heat_layers.retain(|l| l.name != name);
        self.heat_layers.len() != before
    }
    pub fn set_province_sector(&mut self, id: ProvinceId, sector: impl Into<String>) {
        let sector = sector.into();
        for ids in self.sectors.values_mut() {
            ids.remove(&id);
        }
        self.sectors.entry(sector).or_default().insert(id);
    }
    pub fn province_sector(&self, id: ProvinceId) -> Option<&str> {
        self.sectors.iter().find_map(|(name, ids)| {
            if ids.contains(&id) {
                Some(name.as_str())
            } else {
                None
            }
        })
    }
    pub fn sector_provinces(&self, sector: &str) -> Vec<ProvinceId> {
        self.sectors
            .get(sector)
            .map(|set| set.iter().copied().collect())
            .unwrap_or_default()
    }
    pub fn cache_reachability_default(
        &mut self,
        faction: impl Into<String>,
        start: ProvinceId,
        max_cost: f64,
    ) {
        let map = self.graph.reachable_default(start, max_cost);
        self.reachability_cache.insert(faction.into(), map);
    }
    pub fn cached_reachability(&self, faction: &str) -> Option<&HashMap<ProvinceId, f64>> {
        self.reachability_cache.get(faction)
    }
}
#[derive(Debug, Default)]
pub struct GlobeRegistry {
    globes: HashMap<String, Globe>,
}
impl GlobeRegistry {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn create(&mut self, name: impl Into<String>, spec: GlobeSpec) -> &mut Globe {
        let name = name.into();
        self.globes
            .insert(name.clone(), Globe::new(name.clone(), spec));
        self.globes.get_mut(&name).expect("just inserted")
    }
    pub fn get(&self, name: &str) -> Option<&Globe> {
        self.globes.get(name)
    }
    pub fn get_mut(&mut self, name: &str) -> Option<&mut Globe> {
        self.globes.get_mut(name)
    }
    pub fn remove(&mut self, name: &str) -> Option<Globe> {
        self.globes.remove(name)
    }
    pub fn names(&self) -> Vec<String> {
        self.globes.keys().cloned().collect()
    }
    pub fn len(&self) -> usize {
        self.globes.len()
    }
    pub fn is_empty(&self) -> bool {
        self.globes.is_empty()
    }
}
