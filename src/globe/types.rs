use crate::math::Vec2;
use std::collections::{HashMap, HashSet};
pub const MAX_PROVINCES: usize = 8192;
pub type ProvinceId = u32;
#[derive(Debug, Clone)]
pub struct Province {
    pub id: ProvinceId,
    pub vertices: Vec<(f32, f32)>,
    pub centroid: (f32, f32),
    pub neighbors: Vec<ProvinceId>,
    pub attrs: HashMap<String, String>,
    pub edge_tags: HashMap<(ProvinceId, ProvinceId), HashSet<String>>,
    pub texture: Option<String>,
    pub texture_uv_rect: Option<[f32; 4]>,
    pub base_color: [f32; 4],
}
impl Province {
    pub fn new(id: ProvinceId, vertices: Vec<(f32, f32)>) -> Self {
        let (lat_sum, lon_sum) = vertices
            .iter()
            .fold((0.0_f32, 0.0_f32), |(la, lo), (vla, vlo)| {
                (la + vla, lo + vlo)
            });
        let n = vertices.len().max(1) as f32;
        Self {
            id,
            centroid: (lat_sum / n, lon_sum / n),
            vertices,
            neighbors: Vec::new(),
            attrs: HashMap::new(),
            edge_tags: HashMap::new(),
            texture: None,
            texture_uv_rect: None,
            base_color: [0.5, 0.5, 0.5, 1.0],
        }
    }
    pub fn with_data(
        id: ProvinceId,
        centroid: (f32, f32),
        vertices: Vec<(f32, f32)>,
        neighbors: Vec<ProvinceId>,
        base_color: [f32; 4],
    ) -> Self {
        Self {
            id,
            centroid,
            vertices,
            neighbors,
            attrs: HashMap::new(),
            edge_tags: HashMap::new(),
            texture: None,
            texture_uv_rect: None,
            base_color,
        }
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FogState {
    Hidden = 0,
    Explored = 1,
    Visible = 2,
}
#[derive(Debug, Clone)]
pub struct HeatLayer {
    pub name: String,
    pub attr_key: String,
    pub min_value: f32,
    pub max_value: f32,
    pub cold_color: [f32; 4],
    pub hot_color: [f32; 4],
    pub alpha: f32,
    pub visible: bool,
    pub z_order: i32,
}
#[derive(Debug, Clone)]
pub struct GlobeSpec {
    pub radius: f32,
    pub axial_tilt_deg: f32,
    pub rotation_deg: f32,
    pub time_of_day: f32,
    pub render_borders: bool,
    pub border_color: [f32; 4],
    pub border_width: f32,
    pub ambient: f32,
    pub show_atmosphere: bool,
    pub atmosphere_color: [f32; 4],
    pub atmosphere_width: f32,
    pub border_smoothing_passes: u8,
    pub auto_rotation_deg_per_sec: f32,
    pub background_color: [f32; 4],
}
impl Default for GlobeSpec {
    fn default() -> Self {
        Self {
            radius: 300.0,
            axial_tilt_deg: 23.5,
            rotation_deg: 0.0,
            time_of_day: 0.25,
            render_borders: true,
            border_color: [0.0, 0.0, 0.0, 0.6],
            border_width: 1.0,
            ambient: 0.08,
            show_atmosphere: true,
            atmosphere_color: [0.30, 0.55, 0.95, 0.35],
            atmosphere_width: 14.0,
            border_smoothing_passes: 1,
            auto_rotation_deg_per_sec: 0.01,
            background_color: [0.02, 0.02, 0.08, 1.0],
        }
    }
}
#[derive(Debug, Clone)]
pub struct Marker {
    pub id: u32,
    pub marker_type: String,
    pub lat_deg: f32,
    pub lon_deg: f32,
    pub label: Option<String>,
    pub visible: bool,
    pub style: MarkerStyle,
    pub attrs: HashMap<String, String>,
}
#[derive(Debug, Clone)]
pub struct MarkerStyle {
    pub color: [f32; 4],
    pub size: f32,
    pub icon_texture: Option<String>,
    pub shape: MarkerShape,
    pub pulse_hz: f32,
    pub pulse_amplitude: f32,
    pub rotation_deg_per_sec: f32,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MarkerShape {
    Circle,
    Square,
    Diamond,
    Triangle,
    Cross,
}
impl Default for MarkerStyle {
    fn default() -> Self {
        Self {
            color: [1.0, 1.0, 0.0, 1.0],
            size: 8.0,
            icon_texture: None,
            shape: MarkerShape::Circle,
            pulse_hz: 0.0,
            pulse_amplitude: 0.0,
            rotation_deg_per_sec: 0.0,
        }
    }
}
#[derive(Debug, Clone)]
pub struct Label {
    pub id: u32,
    pub label_type: String,
    pub lat_deg: f32,
    pub lon_deg: f32,
    pub text: String,
    pub visible: bool,
    pub style: LabelStyle,
    pub min_lod: u8,
}
#[derive(Debug, Clone)]
pub struct LabelStyle {
    pub color: [f32; 4],
    pub font_size: f32,
    pub font: Option<String>,
}
impl Default for LabelStyle {
    fn default() -> Self {
        Self {
            color: [1.0, 1.0, 1.0, 1.0],
            font_size: 12.0,
            font: None,
        }
    }
}
#[derive(Debug, Clone)]
pub struct Layer {
    pub name: String,
    pub visible: bool,
    pub alpha: f32,
    pub z_order: i32,
    pub kind: String,
    pub province_colors: HashMap<ProvinceId, [f32; 4]>,
}
impl Layer {
    pub fn new(name: impl Into<String>, kind: impl Into<String>, z_order: i32) -> Self {
        Self {
            name: name.into(),
            visible: true,
            alpha: 1.0,
            z_order,
            kind: kind.into(),
            province_colors: HashMap::new(),
        }
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum LodTier {
    Far = 0,
    Mid = 1,
    Near = 2,
}
#[derive(Debug, Clone)]
pub struct ProjectedProvince {
    pub id: ProvinceId,
    pub screen_verts: Vec<Vec2>,
    pub centroid_screen: Vec2,
    pub light_intensity: f32,
    pub visible: bool,
}
#[derive(Debug, Clone)]
pub struct Arc {
    pub id: u32,
    pub arc_type: String,
    pub screen_points: Vec<Vec2>,
    pub color: [f32; 4],
    pub width: f32,
    pub from: (f32, f32),
    pub to: (f32, f32),
    pub steps: u32,
    pub visible: bool,
}
#[derive(Debug)]
pub enum GlobeError {
    ProvinceNotFound(ProvinceId),
    TooManyProvinces,
    LoadError(String),
    GlobeNotFound(String),
    NoPath(ProvinceId, ProvinceId),
}
impl std::fmt::Display for GlobeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            GlobeError::ProvinceNotFound(id) => write!(f, "province {} not found", id),
            GlobeError::TooManyProvinces => write!(
                f,
                "province count exceeds MAX_PROVINCES ({})",
                MAX_PROVINCES
            ),
            GlobeError::LoadError(s) => write!(f, "load error: {}", s),
            GlobeError::GlobeNotFound(s) => write!(f, "globe '{}' not registered", s),
            GlobeError::NoPath(a, b) => write!(f, "no path between {} and {}", a, b),
        }
    }
}
impl std::error::Error for GlobeError {}
