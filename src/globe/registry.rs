//! Globe registry — per-named-globe container and multi-globe manager.
//!
//! Each `Globe` owns all the domain stores for one simulated globe. The
//! `GlobeRegistry` keeps a named map of globes, matching the multi-scene
//! pattern used elsewhere in Lurek2D.

use std::collections::HashMap;
use crate::globe::types::{
    GlobeSpec, GlobeError, Province, ProvinceId, MAX_PROVINCES,
    Arc as GlobeArc,
};
use crate::globe::projection::OrbitCamera;
use crate::globe::topology::ProvinceGraph;
use crate::globe::fog::FogStore;
use crate::globe::marker::MarkerStore;
use crate::globe::label::LabelStore;
use crate::globe::layer::LayerStore;
use crate::globe::draw::emit_globe_frame;
use crate::globe::picking::{pick, PickResult};
use crate::render::renderer::RenderCommand;
use crate::runtime::resource_keys::FontKey;

/// Owns all domain stores for one named globe simulation.
#[derive(Debug, Default)]
pub struct Globe {
    /// Display name (mirrors the registry key).
    pub name: String,
    /// Globe configuration (radius, tilt, time, rendering flags).
    pub spec: GlobeSpec,
    /// Orbit camera (pan, zoom).
    pub camera: OrbitCamera,
    /// Province topology graph.
    pub graph: ProvinceGraph,
    /// Per-faction fog-of-war masks.
    pub fog: FogStore,
    /// Interactive markers (cities, units, events).
    pub markers: MarkerStore,
    /// Surface text labels.
    pub labels: LabelStore,
    /// Named thematic layers (political, terrain, heat-maps…).
    pub layers: LayerStore,
    /// Rendered arcs (routes, range circles, great-circle paths).
    pub arcs: HashMap<u32, GlobeArc>,
    /// Generator for arc IDs.
    pub arc_next_id: u32,
    /// Which viewer's fog mask is active, if any.
    pub active_viewer: Option<String>,
}

impl Globe {
    /// Create a new globe with the given name and spec.
    pub fn new(name: impl Into<String>, spec: GlobeSpec) -> Self {
        Self {
            name: name.into(),
            spec,
            ..Default::default()
        }
    }

    /// Add a province. Returns `Err(GlobeError::TooManyProvinces)` if at cap.
    pub fn add_province(&mut self, province: Province) -> Result<(), GlobeError> {
        if self.graph.len() >= MAX_PROVINCES {
            return Err(GlobeError::TooManyProvinces);
        }
        self.graph.insert(province);
        Ok(())
    }

    /// Remove a province by ID. Returns the province if it existed.
    pub fn remove_province(&mut self, id: ProvinceId) -> Option<Province> {
        self.graph.remove(id)  // topology::remove now returns Option<Province>
    }

    /// Get a shared reference to a province.
    pub fn get_province(&self, id: ProvinceId) -> Option<&Province> {
        self.graph.get(id)
    }

    /// Get a mutable reference to a province.
    pub fn get_province_mut(&mut self, id: ProvinceId) -> Option<&mut Province> {
        self.graph.get_mut(id)
    }

    /// Number of provinces.
    pub fn province_count(&self) -> usize {
        self.graph.len()
    }

    /// Add an arc (great-circle route). Returns the arc ID.
    pub fn add_arc(&mut self, arc: GlobeArc) -> u32 {
        let id = self.arc_next_id;
        self.arc_next_id += 1;
        self.arcs.insert(id, arc);
        id
    }

    /// Remove an arc.
    pub fn remove_arc(&mut self, id: u32) -> bool {
        self.arcs.remove(&id).is_some()
    }

    /// Advance globe simulation by `dt` seconds (rotates the planet).
    pub fn update(&mut self, dt: f32) {
        let speed = 1.0; // degrees / simulated-hour
        self.spec.time_of_day = (self.spec.time_of_day + dt * speed / 3600.0) % 24.0;
        self.spec.rotation_deg = (self.spec.rotation_deg + dt * 0.01) % 360.0;
    }

    /// Pick the province under a screen coordinate.
    pub fn pick_screen(&self, sx: f32, sy: f32) -> Option<PickResult> {
        pick(sx, sy, &self.spec, &self.camera, &self.graph)
    }

    /// Emit all render commands for this globe frame.
    ///
    /// Pass `default_font` to enable label and marker text rendering;
    /// `None` suppresses all text.
    pub fn emit_frame(&self, default_font: Option<FontKey>) -> Vec<RenderCommand> {
        emit_globe_frame(
            &self.spec,
            &self.camera,
            &self.graph,
            &self.fog,
            &self.markers,
            &self.labels,
            &self.layers,
            &self.arcs,
            self.active_viewer.as_deref(),
            default_font,
        )
    }
}

/// Named multi-globe manager.
///
/// Keeps a `HashMap<String, Globe>` and enforces name-based access.
#[derive(Debug, Default)]
pub struct GlobeRegistry {
    globes: HashMap<String, Globe>,
}

impl GlobeRegistry {
    /// Create an empty registry.
    pub fn new() -> Self {
        Self::default()
    }

    /// Create a new globe and store it. Returns a mutable reference.
    ///
    /// If a globe with this name already exists it is replaced.
    pub fn create(&mut self, name: impl Into<String>, spec: GlobeSpec) -> &mut Globe {
        let name = name.into();
        self.globes.insert(name.clone(), Globe::new(name.clone(), spec));
        self.globes.get_mut(&name).expect("just inserted")
    }

    /// Get an immutable reference to a globe.
    pub fn get(&self, name: &str) -> Option<&Globe> {
        self.globes.get(name)
    }

    /// Get a mutable reference to a globe.
    pub fn get_mut(&mut self, name: &str) -> Option<&mut Globe> {
        self.globes.get_mut(name)
    }

    /// Remove and return a globe.
    pub fn remove(&mut self, name: &str) -> Option<Globe> {
        self.globes.remove(name)
    }

    /// List all globe names.
    pub fn names(&self) -> Vec<String> {
        self.globes.keys().cloned().collect()
    }

    /// Number of globes.
    pub fn len(&self) -> usize {
        self.globes.len()
    }

    /// True if no globes are registered.
    pub fn is_empty(&self) -> bool {
        self.globes.is_empty()
    }
}
