//! Core value types for the globe module.
//!
//! All types are pure-data; no rendering, no Lua, no I/O.

use crate::math::Vec2;
use std::collections::{HashMap, HashSet};

// ── Province ──────────────────────────────────────────────────────────────────

/// Maximum number of provinces per globe. Soft cap — may be raised after profiling.
pub const MAX_PROVINCES: usize = 8192;

/// Unique identifier for a province within a single globe instance.
pub type ProvinceId = u32;

/// A convex (or near-convex) polygon on the unit sphere, representing a province or region.
///
/// Vertices are stored as `(lat_deg, lon_deg)` pairs. The polygon is assumed to span
/// less than a hemisphere so backface culling applies coherently.
///
/// # Fields
/// - `id` — Unique province ID (matches the key in [`ProvinceGraph`]).
/// - `vertices` — `(lat_deg, lon_deg)` boundary vertices, in winding order.
/// - `centroid` — `(lat_deg, lon_deg)` centroid, used for label placement and A*.
/// - `neighbors` — Directly adjacent province IDs (shared border).
/// - `attrs` — User-defined key → value attribute store (terrain, climate, resources, owner, …).
/// - `edge_tags` — Tags on edges keyed by `(min(self.id, nbr), max(self.id, nbr))`.
#[derive(Debug, Clone)]
pub struct Province {
    /// Unique province ID.
    pub id: ProvinceId,
    /// Boundary vertices as `(lat_deg, lon_deg)`.
    pub vertices: Vec<(f32, f32)>,
    /// `(lat_deg, lon_deg)` centroid of this province.
    pub centroid: (f32, f32),
    /// Adjacent province IDs.
    pub neighbors: Vec<ProvinceId>,
    /// Freeform attribute store. Values are Lua-serializable strings.
    pub attrs: HashMap<String, String>,
    /// Edge tags. Key is `(min(a,b), max(a,b))`.
    pub edge_tags: HashMap<(ProvinceId, ProvinceId), HashSet<String>>,
    /// Optional texture key string (resolved to a `TextureKey` at draw time).
    pub texture: Option<String>,
    /// Optional atlas UV rectangle `[u0, v0, u1, v1]` in normalized coordinates.
    pub texture_uv_rect: Option<[f32; 4]>,
    /// Base fill color `[r,g,b,a]` used when no texture is assigned.
    pub base_color: [f32; 4],
}

impl Province {
    /// Create a minimal province for unit tests.
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

    /// Create a province with explicit centroid, neighbors, and base color.
    ///
    /// Attribute, edge-tag, and texture fields are initialised to empty/`None`.
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

/// Fog state with partial discovery support.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FogState {
    /// Province is fully hidden.
    Hidden = 0,
    /// Province was explored earlier but is not currently visible.
    Explored = 1,
    /// Province is currently visible.
    Visible = 2,
}

/// Heat-map layer driven by float attributes stored on provinces.
#[derive(Debug, Clone)]
pub struct HeatLayer {
    /// Unique layer name.
    pub name: String,
    /// Province attribute key used as source value.
    pub attr_key: String,
    /// Minimum value mapped to `cold_color`.
    pub min_value: f32,
    /// Maximum value mapped to `hot_color`.
    pub max_value: f32,
    /// Color used at or below `min_value`.
    pub cold_color: [f32; 4],
    /// Color used at or above `max_value`.
    pub hot_color: [f32; 4],
    /// Heat layer opacity multiplier.
    pub alpha: f32,
    /// Render visibility toggle.
    pub visible: bool,
    /// Draw order among heat layers.
    pub z_order: i32,
}

// ── Globe specification ────────────────────────────────────────────────────────

/// Top-level configuration for one globe instance.
///
/// # Fields
/// - `radius` — Visual radius in world units (default 300.0).
/// - `axial_tilt_deg` — Planet axial tilt in degrees (default 23.5).
/// - `rotation_deg` — Current longitude-rotation of the planet (0–360).
/// - `time_of_day` — Fraction of a day elapsed `[0, 1)`. 0 = midnight on prime meridian.
/// - `render_borders` — Whether to draw province borders.
/// - `border_color` — Border line color `[r,g,b,a]`.
/// - `border_width` — Border stroke width in pixels.
/// - `ambient` — Minimum per-province light intensity `[0, 1]`.
/// - `show_atmosphere` — Draw a subtle atmospheric rim glow.
/// - `background_color` — Color of the space background behind the globe.
#[derive(Debug, Clone)]
pub struct GlobeSpec {
    /// Visual radius in world units.
    pub radius: f32,
    /// Axial tilt in degrees.
    pub axial_tilt_deg: f32,
    /// Longitude rotation offset in degrees (planet spin).
    pub rotation_deg: f32,
    /// Fraction of a day `[0, 1)`. 0 = midnight, 0.5 = noon on prime meridian.
    pub time_of_day: f32,
    /// Draw province borders.
    pub render_borders: bool,
    /// Border line color.
    pub border_color: [f32; 4],
    /// Border stroke width in pixels.
    pub border_width: f32,
    /// Ambient light minimum (night-side brightness).
    pub ambient: f32,
    /// Draw atmospheric rim glow.
    pub show_atmosphere: bool,
    /// Atmosphere color tint.
    pub atmosphere_color: [f32; 4],
    /// Atmosphere halo width in pixels.
    pub atmosphere_width: f32,
    /// Number of Chaikin smoothing passes for borders.
    pub border_smoothing_passes: u8,
    /// Automatic spin speed in degrees per second.
    pub auto_rotation_deg_per_sec: f32,
    /// Background color behind the globe.
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

// ── Marker ────────────────────────────────────────────────────────────────────

/// A point of interest placed on the globe at a specific latitude/longitude.
///
/// # Fields
/// - `id` — Unique identifier for this marker within the globe.
/// - `marker_type` — User-defined type tag (e.g. `"city"`, `"base"`, `"ufo"`). Nothing is hardcoded.
/// - `lat_deg` / `lon_deg` — Position on the unit sphere.
/// - `label` — Optional display text.
/// - `visible` — Whether the marker is currently rendered.
/// - `style` — Visual style configuration.
/// - `attrs` — User-defined attribute store.
#[derive(Debug, Clone)]
pub struct Marker {
    /// Unique marker ID within this globe.
    pub id: u32,
    /// User-defined type tag. Semantics are fully Lua-defined.
    pub marker_type: String,
    /// Latitude in degrees.
    pub lat_deg: f32,
    /// Longitude in degrees.
    pub lon_deg: f32,
    /// Optional display label.
    pub label: Option<String>,
    /// Whether the marker renders this frame.
    pub visible: bool,
    /// Visual configuration for this marker.
    pub style: MarkerStyle,
    /// User-defined freeform attributes.
    pub attrs: HashMap<String, String>,
}

/// Visual style for a [`Marker`].
///
/// # Fields
/// - `color` — RGBA tint.
/// - `size` — Screen-space size in pixels.
/// - `icon_texture` — Optional texture key string for a sprite icon.
/// - `shape` — Fallback shape if no icon texture is set.
#[derive(Debug, Clone)]
pub struct MarkerStyle {
    /// RGBA color.
    pub color: [f32; 4],
    /// Screen-space size in pixels.
    pub size: f32,
    /// Optional texture key string for an icon sprite.
    pub icon_texture: Option<String>,
    /// Fallback primitive shape if no icon is set.
    pub shape: MarkerShape,
    /// Pulse speed in Hz (0 disables pulsing).
    pub pulse_hz: f32,
    /// Relative pulse amplitude in [0, 1].
    pub pulse_amplitude: f32,
    /// Icon rotation speed in degrees per second.
    pub rotation_deg_per_sec: f32,
}

/// Primitive fallback shape for an icon-less marker.
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

// ── Label ─────────────────────────────────────────────────────────────────────

/// A text annotation placed on the globe.
///
/// # Fields
/// - `id` — Unique label ID within the globe.
/// - `label_type` — User-defined type tag (`"country"`, `"region"`, `"capital"`, …).
/// - `lat_deg` / `lon_deg` — Anchor position on the sphere.
/// - `text` — Display text.
/// - `visible` — Whether the label renders this frame.
/// - `style` — Visual style.
/// - `min_lod` — Minimum LOD tier at which this label appears.
#[derive(Debug, Clone)]
pub struct Label {
    /// Unique label ID within this globe.
    pub id: u32,
    /// User-defined type tag.
    pub label_type: String,
    /// Latitude in degrees.
    pub lat_deg: f32,
    /// Longitude in degrees.
    pub lon_deg: f32,
    /// Text content.
    pub text: String,
    /// Rendering visibility flag.
    pub visible: bool,
    /// Visual style.
    pub style: LabelStyle,
    /// Minimum LOD tier for visibility (0 = always, higher = only when zoomed in).
    pub min_lod: u8,
}

/// Visual style for a [`Label`].
#[derive(Debug, Clone)]
pub struct LabelStyle {
    /// RGBA color.
    pub color: [f32; 4],
    /// Font size in pixels.
    pub font_size: f32,
    /// Optional font key string (resolved at draw time).
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

// ── Layer ─────────────────────────────────────────────────────────────────────

/// A named rendering layer that sits above the base province map.
///
/// Layers are rendered in z-order. Each layer has a visibility flag and an
/// optional opacity so callers can blend overlays (political, climate, resources,
/// fog-of-war fill, etc.) without touching province base colors.
///
/// # Fields
/// - `name` — Unique layer name.
/// - `visible` — Render this layer.
/// - `alpha` — Layer opacity `[0, 1]`.
/// - `z_order` — Render priority (lower = rendered first / beneath).
/// - `kind` — Semantic type; user-defined.
/// - `province_colors` — Per-province color override for this layer.
#[derive(Debug, Clone)]
pub struct Layer {
    /// Unique layer name.
    pub name: String,
    /// Render this layer.
    pub visible: bool,
    /// Layer opacity.
    pub alpha: f32,
    /// Render priority.
    pub z_order: i32,
    /// Semantic kind tag (fully user-defined).
    pub kind: String,
    /// Per-province RGBA color override for this layer.
    pub province_colors: HashMap<ProvinceId, [f32; 4]>,
}

impl Layer {
    /// Construct a visible layer with full opacity.
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

// ── LOD ───────────────────────────────────────────────────────────────────────

/// Level-of-detail tier, selected based on camera zoom.
///
/// Higher = more detail (closer zoom).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum LodTier {
    /// Far view: silhouette shapes only, no borders, no labels.
    Far = 0,
    /// Mid view: borders and country labels.
    Mid = 1,
    /// Near view: full province detail, all labels, markers, textures.
    Near = 2,
}

// ── Screen-space projected province ──────────────────────────────────────────

/// A province projected to screen space, ready for draw calls.
///
/// # Fields
/// - `id` — Source province ID.
/// - `screen_verts` — Projected screen-space vertices.
/// - `centroid_screen` — Screen-space centroid for label anchor.
/// - `light_intensity` — Per-province cosine lighting `[0, 1]`.
/// - `visible` — False if entirely behind the globe or in the fog.
#[derive(Debug, Clone)]
pub struct ProjectedProvince {
    /// Source province ID.
    pub id: ProvinceId,
    /// Screen-space vertices.
    pub screen_verts: Vec<Vec2>,
    /// Screen-space centroid.
    pub centroid_screen: Vec2,
    /// Lighting intensity `[ambient, 1]`.
    pub light_intensity: f32,
    /// True if this province should be rendered.
    pub visible: bool,
}

// ── Great-circle arc ──────────────────────────────────────────────────────────

/// A great-circle travel arc, projected to screen space.
///
/// Used for trade routes, flight paths, ballistic trajectories, etc.
#[derive(Debug, Clone)]
pub struct Arc {
    /// Unique arc ID.
    pub id: u32,
    /// Arc style tag.
    pub arc_type: String,
    /// Screen-space polyline points (pre-projected each frame).
    pub screen_points: Vec<Vec2>,
    /// Color `[r,g,b,a]`.
    pub color: [f32; 4],
    /// Stroke width in pixels.
    pub width: f32,
    /// Source position `(lat_deg, lon_deg)`.
    pub from: (f32, f32),
    /// Destination position `(lat_deg, lon_deg)`.
    pub to: (f32, f32),
    /// Number of interpolation steps.
    pub steps: u32,
    /// Visibility flag.
    pub visible: bool,
}

// ── Error ─────────────────────────────────────────────────────────────────────

/// Errors returned by globe operations.
#[derive(Debug)]
pub enum GlobeError {
    /// Province ID not found.
    ProvinceNotFound(ProvinceId),
    /// Province count exceeds [`MAX_PROVINCES`].
    TooManyProvinces,
    /// I/O or parse error loading province data.
    LoadError(String),
    /// Globe instance name not registered.
    GlobeNotFound(String),
    /// No path exists between two provinces.
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
