use crate::image::ProvinceGrid;
use crate::province::events::ProvinceChange;
use crate::province::topology::ProvinceGraph;
use crate::province::types::{BorderClass, ProvinceId, ProvinceSnapshot, ProvinceStyle};
use std::collections::HashMap;
#[derive(Debug, Clone, Default)]
pub struct ProvinceRecord {
    pub style: ProvinceStyle,
    pub centroid: Option<(f32, f32)>,
    pub capital: Option<(f32, f32)>,
    pub label_line: Option<((f32, f32), (f32, f32))>,
    pub label_text: Option<String>,
    pub attrs: HashMap<String, String>,
}
#[derive(Debug, Clone)]
pub struct ProvinceRegistry {
    width: u32,
    height: u32,
    ids: Vec<u32>,
    spans: Vec<(u32, u32, u32, u32)>,
    spans_by_province: HashMap<ProvinceId, Vec<(u32, u32, u32)>>,
    bbox_by_province: HashMap<ProvinceId, (u32, u32, u32, u32)>,
    border_segments: Vec<(u32, u32, u32, u32, u32, u32)>,
    graph: ProvinceGraph,
    provinces: HashMap<ProvinceId, ProvinceRecord>,
    border_classes: HashMap<(ProvinceId, ProvinceId), BorderClass>,
    revision: u64,
    changes: Vec<(u64, ProvinceChange)>,
}
impl ProvinceRegistry {
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
    pub fn from_png(path: &str) -> Result<Self, String> {
        let grid = ProvinceGrid::from_file(path)?;
        Ok(Self::from_grid(&grid))
    }
    pub fn width(&self) -> u32 {
        self.width
    }
    pub fn height(&self) -> u32 {
        self.height
    }
    pub fn get_at(&self, x: u32, y: u32) -> u32 {
        if x >= self.width || y >= self.height {
            return 0;
        }
        self.ids[(y * self.width + x) as usize]
    }
    pub fn revision(&self) -> u64 {
        self.revision
    }
    pub fn province_ids(&self) -> Vec<ProvinceId> {
        let mut ids: Vec<ProvinceId> = self.provinces.keys().copied().collect();
        ids.sort_unstable();
        ids
    }
    pub fn province_count(&self) -> usize {
        self.provinces.len()
    }
    pub fn get_province(&self, id: ProvinceId) -> Option<ProvinceSnapshot> {
        self.provinces.get(&id).map(|rec| ProvinceSnapshot {
            province_id: id,
            style: rec.style.clone(),
            revision: self.revision,
            centroid: rec.centroid,
            attrs: rec.attrs.clone(),
        })
    }
    pub fn get_neighbors(&self, id: ProvinceId) -> Vec<ProvinceId> {
        self.graph.neighbors_of(id).to_vec()
    }
    pub fn adjacency_pairs(&self) -> Vec<(ProvinceId, ProvinceId)> {
        self.graph.adjacency_pairs()
    }
    pub fn spans(&self) -> &[(u32, u32, u32, u32)] {
        &self.spans
    }
    pub fn border_segments(&self) -> &[(u32, u32, u32, u32, u32, u32)] {
        &self.border_segments
    }
    pub fn spans_for(&self, id: ProvinceId) -> Option<&[(u32, u32, u32)]> {
        self.spans_by_province.get(&id).map(Vec::as_slice)
    }
    pub fn bbox_for(&self, id: ProvinceId) -> Option<(u32, u32, u32, u32)> {
        self.bbox_by_province.get(&id).copied()
    }
    pub fn style_for(&self, id: ProvinceId) -> Option<&ProvinceStyle> {
        self.provinces.get(&id).map(|p| &p.style)
    }
    pub fn set_capital(&mut self, id: ProvinceId, x: f32, y: f32) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        rec.capital = Some((x, y));
        true
    }
    pub fn capital_for(&self, id: ProvinceId) -> Option<(f32, f32)> {
        self.provinces.get(&id).and_then(|p| p.capital)
    }
    pub fn set_label_line(&mut self, id: ProvinceId, ax: f32, ay: f32, bx: f32, by: f32) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        rec.label_line = Some(((ax, ay), (bx, by)));
        true
    }
    pub fn label_line_for(&self, id: ProvinceId) -> Option<((f32, f32), (f32, f32))> {
        self.provinces.get(&id).and_then(|p| p.label_line)
    }
    pub fn set_label_text(&mut self, id: ProvinceId, text: String) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        rec.label_text = Some(text);
        true
    }
    pub fn label_text_for(&self, id: ProvinceId) -> Option<&str> {
        self.provinces
            .get(&id)
            .and_then(|p| p.label_text.as_deref())
    }
    fn bump_change(&mut self, change: ProvinceChange) {
        self.revision = self.revision.saturating_add(1);
        self.changes.push((self.revision, change));
    }
    pub fn get_changes_since(&self, since_revision: u64) -> Vec<(u64, ProvinceChange)> {
        self.changes
            .iter()
            .filter(|(rev, _)| *rev > since_revision)
            .cloned()
            .collect()
    }
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
    fn norm_pair(a: ProvinceId, b: ProvinceId) -> (ProvinceId, ProvinceId) {
        if a < b {
            (a, b)
        } else {
            (b, a)
        }
    }
    pub fn set_border_class(&mut self, a: ProvinceId, b: ProvinceId, class: BorderClass) {
        let key = Self::norm_pair(a, b);
        self.border_classes.insert(key, class);
        self.bump_change(ProvinceChange::BorderClass {
            province_a: key.0,
            province_b: key.1,
            class,
        });
    }
    pub fn get_border_class(&self, a: ProvinceId, b: ProvinceId) -> Option<BorderClass> {
        self.border_classes.get(&Self::norm_pair(a, b)).copied()
    }
    pub fn set_attr(&mut self, id: ProvinceId, key: String, value: String) -> bool {
        let Some(rec) = self.provinces.get_mut(&id) else {
            return false;
        };
        rec.attrs.insert(key, value);
        true
    }
}
impl Default for ProvinceRegistry {
    fn default() -> Self {
        Self::new()
    }
}
