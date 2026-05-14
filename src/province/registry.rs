//! Province registry: the authoritative store of per-province style, geometry, labels, and change history.
//! Built from a ProvinceGrid pixel scan; mutation methods append to a change log keyed by revision.
//! Consumed by render, gpu_bridge, cache, import, and Lua bindings; does not own rendering commands.
use crate::image::ProvinceGrid;
use crate::province::events::ProvinceChange;
use crate::province::topology::ProvinceGraph;
use crate::province::types::{BorderClass, ProvinceId, ProvinceSnapshot, ProvinceStyle};
use std::collections::HashMap;

/// Full mutable record for a single province stored inside ProvinceRegistry.
#[derive(Debug, Clone, Default)]
pub struct ProvinceRecord {
    /// Visual and gameplay style for this province.
    pub style: ProvinceStyle,
    /// Pixel-weighted centroid position; None until computed from spans.
    pub centroid: Option<(f32, f32)>,
    /// Capital marker position set by import; None if not yet assigned.
    pub capital: Option<(f32, f32)>,
    /// Label anchor line from marker import: ((x0,y0),(x1,y1)); None if not set.
    pub label_line: Option<((f32, f32), (f32, f32))>,
    /// Display name string for UI labels; None if not imported.
    pub label_text: Option<String>,
    /// Arbitrary key-value metadata set via set_attr.
    pub attrs: HashMap<String, String>,
}

/// Central authoritative store for all province state: geometry, style, labels, adjacency, and change log.
#[derive(Debug, Clone)]
pub struct ProvinceRegistry {
    /// Width of the source map in pixels.
    width: u32,
    /// Height of the source map in pixels.
    height: u32,
    /// Flat row-major array of province ids matching the source pixel grid.
    ids: Vec<u32>,
    /// Province span runs extracted from the pixel grid: (id, row_y, x_start, x_end_exclusive).
    spans: Vec<(u32, u32, u32, u32)>,
    /// Span runs indexed by province id for fast per-province iteration.
    spans_by_province: HashMap<ProvinceId, Vec<(u32, u32, u32)>>,
    /// Axis-aligned bounding box per province: (min_x, min_y, max_x, max_y).
    bbox_by_province: HashMap<ProvinceId, (u32, u32, u32, u32)>,
    /// Border segments between adjacent provinces: (id_a, id_b, x0, y0, x1, y1).
    border_segments: Vec<(u32, u32, u32, u32, u32, u32)>,
    /// Undirected adjacency graph derived from the pixel scan.
    graph: ProvinceGraph,
    /// Per-province mutable records keyed by ProvinceId.
    provinces: HashMap<ProvinceId, ProvinceRecord>,
    /// Manually overridden border classes keyed by normalised (lo, hi) pair.
    border_classes: HashMap<(ProvinceId, ProvinceId), BorderClass>,
    /// Monotonically increasing change counter; incremented on every mutation.
    revision: u64,
    /// Ordered change log entries as (revision, change) pairs.
    changes: Vec<(u64, ProvinceChange)>,
}

impl ProvinceRegistry {
    /// Return a new empty registry with zero dimensions and no provinces.
    pub fn new() -> Self {
        Self {
            width: 0,
            height: 0,
            ids: Vec::new(),
            spans: Vec::new(),
            spans_by_province: HashMap::new(),
            bbox_by_province: HashMap::new(),
            border_segments: Vec::new(),
            graph: ProvinceGraph::new(),
            provinces: HashMap::new(),
            border_classes: HashMap::new(),
            revision: 0,
            changes: Vec::new(),
        }
    }

    /// Build a registry from a pre-parsed ProvinceGrid, computing spans, adjacency, and centroids.
    pub fn from_grid(grid: &ProvinceGrid) -> Self {
        let width = grid.width();
        let height = grid.height();
        let mut ids = Vec::with_capacity((width * height) as usize);
        for y in 0..height {
            for x in 0..width {
                ids.push(grid.get_at(x, y));
            }
        }
        let pairs: Vec<(u32, u32)> = grid
            .adjacencies()
            .iter()
            .map(|(a, b, _)| (*a, *b))
            .collect();
        let mut graph = ProvinceGraph::new();
        graph.rebuild_from_pairs(&pairs);
        let mut provinces = HashMap::new();
        for id in 1..=grid.province_count() {
            provinces.entry(id).or_insert_with(ProvinceRecord::default);
        }
        let spans = grid.province_spans();
        let mut spans_by_province: HashMap<ProvinceId, Vec<(u32, u32, u32)>> = HashMap::new();
        let mut bbox_by_province: HashMap<ProvinceId, (u32, u32, u32, u32)> = HashMap::new();
        for (id, y, x0, x1) in &spans {
            if *id == 0 || *x1 <= *x0 {
                continue;
            }
            spans_by_province
                .entry(*id)
                .or_default()
                .push((*y, *x0, *x1));
            let x1i = x1.saturating_sub(1);
            bbox_by_province
                .entry(*id)
                .and_modify(|bb| {
                    bb.0 = bb.0.min(*x0);
                    bb.1 = bb.1.min(*y);
                    bb.2 = bb.2.max(x1i);
                    bb.3 = bb.3.max(*y);
                })
                .or_insert((*x0, *y, x1i, *y));
        }
        let border_segments = grid.border_segments();
        let mut sum_x: HashMap<u32, f64> = HashMap::new();
        let mut sum_y: HashMap<u32, f64> = HashMap::new();
        let mut sum_n: HashMap<u32, f64> = HashMap::new();
        for (id, y, x0, x1) in &spans {
            if *id == 0 || *x1 <= *x0 {
                continue;
            }
            let n = (*x1 - *x0) as f64;
            let center_x = ((*x0 + *x1 - 1) as f64) * 0.5;
            *sum_x.entry(*id).or_insert(0.0) += center_x * n;
            *sum_y.entry(*id).or_insert(0.0) += (*y as f64) * n;
            *sum_n.entry(*id).or_insert(0.0) += n;
        }
        for (id, rec) in provinces.iter_mut() {
            if let Some(n) = sum_n.get(id).copied() {
                if n > 0.0 {
                    let cx = (sum_x[id] / n) as f32;
                    let cy = (sum_y[id] / n) as f32;
                    rec.centroid = Some((cx, cy));
                }
            }
        }
        Self {
            width,
            height,
            ids,
            spans,
            spans_by_province,
            bbox_by_province,
            border_segments,
            graph,
            provinces,
            border_classes: HashMap::new(),
            revision: 0,
            changes: Vec::new(),
        }
    }
    /// Build a registry by loading a province colour-map PNG from path; return error on I/O or decode failure.
    pub fn from_png(path: &str) -> Result<Self, String> {
        let grid = ProvinceGrid::from_file(path)?;
        Ok(Self::from_grid(&grid))
    }
    /// Return the width of the source map in pixels.
    pub fn width(&self) -> u32 {
        self.width
    }

    /// Return the height of the source map in pixels.
    pub fn height(&self) -> u32 {
        self.height
    }
    /// Return the province id at pixel (x, y); returns 0 if coordinates are out of bounds.
    pub fn get_at(&self, x: u32, y: u32) -> u32 {
        if x >= self.width || y >= self.height {
            return 0;
        }
        self.ids[(y * self.width + x) as usize]
    }
    /// Return the current revision counter; increases by one on each mutation.
    pub fn revision(&self) -> u64 {
        self.revision
    }
    /// Return all known province ids sorted ascending.
    pub fn province_ids(&self) -> Vec<ProvinceId> {
        let mut ids: Vec<ProvinceId> = self.provinces.keys().copied().collect();
        ids.sort_unstable();
        ids
    }
    /// Return the number of provinces currently in the registry.
    pub fn province_count(&self) -> usize {
        self.provinces.len()
    }
    /// Return a snapshot of the province's style and metadata, or None if id is unknown.
    pub fn get_province(&self, id: ProvinceId) -> Option<ProvinceSnapshot> {
        self.provinces.get(&id).map(|rec| ProvinceSnapshot {
            province_id: id,
            style: rec.style.clone(),
            revision: self.revision,
            centroid: rec.centroid,
            attrs: rec.attrs.clone(),
        })
    }
    /// Return the sorted neighbour list for id as a Vec; returns empty Vec if id has no adjacencies.
    pub fn get_neighbors(&self, id: ProvinceId) -> Vec<ProvinceId> {
        self.graph.neighbors_of(id).to_vec()
    }
    /// Return all unique adjacency pairs (a < b) sorted ascending.
    pub fn adjacency_pairs(&self) -> Vec<(ProvinceId, ProvinceId)> {
        self.graph.adjacency_pairs()
    }
    /// Return all span runs as a slice: (id, row_y, x_start, x_end_exclusive).
    pub fn spans(&self) -> &[(u32, u32, u32, u32)] {
        &self.spans
    }
    /// Return all border segments as a slice: (id_a, id_b, x0, y0, x1, y1).
    pub fn border_segments(&self) -> &[(u32, u32, u32, u32, u32, u32)] {
        &self.border_segments
    }
    /// Return the span runs for a single province as (row_y, x_start, x_end_exclusive), or None if unknown.
    pub fn spans_for(&self, id: ProvinceId) -> Option<&[(u32, u32, u32)]> {
        self.spans_by_province.get(&id).map(Vec::as_slice)
    }
    /// Return the axis-aligned bounding box (min_x, min_y, max_x, max_y) for id, or None if unknown.
    pub fn bbox_for(&self, id: ProvinceId) -> Option<(u32, u32, u32, u32)> {
        self.bbox_by_province.get(&id).copied()
    }
    /// Return a reference to the style for id, or None if id is unknown.
    pub fn style_for(&self, id: ProvinceId) -> Option<&ProvinceStyle> {
        self.provinces.get(&id).map(|p| &p.style)
    }
    /// Set the capital position for id; return false if id is unknown.
    pub fn set_capital(&mut self, id: ProvinceId, x: f32, y: f32) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        rec.capital = Some((x, y));
        true
    }
    /// Return the capital position for id, or None if not set or id is unknown.
    pub fn capital_for(&self, id: ProvinceId) -> Option<(f32, f32)> {
        self.provinces.get(&id).and_then(|p| p.capital)
    }
    /// Set the label anchor line for id from (ax, ay) to (bx, by); return false if id is unknown.
    pub fn set_label_line(&mut self, id: ProvinceId, ax: f32, ay: f32, bx: f32, by: f32) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        rec.label_line = Some(((ax, ay), (bx, by)));
        true
    }
    /// Return the label line for id as ((x0,y0),(x1,y1)), or None if not set or id is unknown.
    pub fn label_line_for(&self, id: ProvinceId) -> Option<((f32, f32), (f32, f32))> {
        self.provinces.get(&id).and_then(|p| p.label_line)
    }
    /// Set the display label text for id; return false if id is unknown.
    pub fn set_label_text(&mut self, id: ProvinceId, text: String) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        rec.label_text = Some(text);
        true
    }
    /// Return the label text for id as a str slice, or None if not set or id is unknown.
    pub fn label_text_for(&self, id: ProvinceId) -> Option<&str> {
        self.provinces
            .get(&id)
            .and_then(|p| p.label_text.as_deref())
    }
    /// Increment revision and append the change to the change log.
    fn bump_change(&mut self, change: ProvinceChange) {
        self.revision = self.revision.saturating_add(1);
        self.changes.push((self.revision, change));
    }
    /// Return all change log entries with revision > since_revision.
    pub fn get_changes_since(&self, since_revision: u64) -> Vec<(u64, ProvinceChange)> {
        self.changes
            .iter()
            .filter(|(rev, _)| *rev > since_revision)
            .cloned()
            .collect()
    }
    /// Set the political fill colour for id and record a PoliticalColor change; return false if id is unknown.
    pub fn set_political_color(&mut self, id: ProvinceId, color: [f32; 4]) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        if rec.style.political_color == color {
            return true;
        }
        rec.style.political_color = color;
        self.bump_change(ProvinceChange::PoliticalColor {
            province_id: id,
            color,
        });
        true
    }
    /// Set the terrain type index for id and record a TerrainType change; return false if id is unknown.
    pub fn set_terrain_type(&mut self, id: ProvinceId, terrain_type: u32) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        if rec.style.terrain_type == terrain_type {
            return true;
        }
        rec.style.terrain_type = terrain_type;
        self.bump_change(ProvinceChange::TerrainType {
            province_id: id,
            terrain_type,
        });
        true
    }
    /// Set the border style index for id and record a BorderStyle change; return false if id is unknown.
    pub fn set_border_style(&mut self, id: ProvinceId, border_style: u32) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        if rec.style.border_style == border_style {
            return true;
        }
        rec.style.border_style = border_style;
        self.bump_change(ProvinceChange::BorderStyle {
            province_id: id,
            border_style,
        });
        true
    }
    /// Set the fog state byte for id and record a FogState change; return false if id is unknown.
    pub fn set_fog_state(&mut self, id: ProvinceId, fog_state: u8) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        if rec.style.fog_state == fog_state {
            return true;
        }
        rec.style.fog_state = fog_state;
        self.bump_change(ProvinceChange::FogState {
            province_id: id,
            fog_state,
        });
        true
    }
    /// Set the visibility state byte for id and record a VisibilityState change; return false if id is unknown.
    pub fn set_visibility_state(&mut self, id: ProvinceId, visibility_state: u8) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        if rec.style.visibility_state == visibility_state {
            return true;
        }
        rec.style.visibility_state = visibility_state;
        self.bump_change(ProvinceChange::VisibilityState {
            province_id: id,
            visibility_state,
        });
        true
    }
    /// Return the canonical (lo, hi) ordered pair for use as a border class map key.
    fn norm_pair(a: ProvinceId, b: ProvinceId) -> (ProvinceId, ProvinceId) {
        if a < b {
            (a, b)
        } else {
            (b, a)
        }
    }
    /// Set the border class for the (a, b) pair and record a BorderClass change.
    pub fn set_border_class(&mut self, a: ProvinceId, b: ProvinceId, class: BorderClass) {
        let key = Self::norm_pair(a, b);
        self.border_classes.insert(key, class);
        self.bump_change(ProvinceChange::BorderClass {
            province_a: key.0,
            province_b: key.1,
            class,
        });
    }
    /// Return the stored border class for the (a, b) pair, or None if not explicitly set.
    pub fn get_border_class(&self, a: ProvinceId, b: ProvinceId) -> Option<BorderClass> {
        self.border_classes.get(&Self::norm_pair(a, b)).copied()
    }
    /// Insert a key-value string attribute for id; return false if id is unknown.
    pub fn set_attr(&mut self, id: ProvinceId, key: String, value: String) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        rec.attrs.insert(key, value);
        true
    }
}
/// Default ProvinceRegistry delegates to Self::new().
impl Default for ProvinceRegistry {
    fn default() -> Self {
        Self::new()
    }
}
