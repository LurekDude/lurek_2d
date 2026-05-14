//! Core province data types: identifiers, border classification, per-province style, and snapshot views.
//! Owned by the province subsystem; consumed by registry, render, gpu_bridge, and Lua bindings.
//! Does not contain layout data, geometry, or rendering logic.
use std::collections::HashMap;

/// Numeric identifier for a province; 0 is reserved for "no province" / ocean pixels.
pub type ProvinceId = u32;

/// Classification of the terrain relationship across a shared border.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum BorderClass {
    /// Border between two land provinces.
    LandLand,
    /// Border between a land and a sea province.
    Coast,
    /// Border between two sea provinces.
    SeaSea,
    /// Manually flagged border; renderer applies a distinct colour.
    Special,
}

impl BorderClass {
    /// Return the canonical string token used in TOML and CSV exports.
    pub fn as_str(self) -> &'static str {
        match self {
            BorderClass::LandLand => "land_land",
            BorderClass::Coast => "coast",
            BorderClass::SeaSea => "sea_sea",
            BorderClass::Special => "special",
        }
    }

    /// Parse a string token back to a variant; return None on unknown input.
    pub fn parse_str(value: &str) -> Option<Self> {
        match value {
            "land_land" => Some(BorderClass::LandLand),
            "coast" => Some(BorderClass::Coast),
            "sea_sea" => Some(BorderClass::SeaSea),
            "special" => Some(BorderClass::Special),
            _ => None,
        }
    }
}

/// Visual and gameplay state attached to a single province, stored in ProvinceRegistry.
#[derive(Debug, Clone, PartialEq)]
pub struct ProvinceStyle {
    /// RGBA fill colour used in political map mode; default grey [0.5, 0.5, 0.5, 1.0].
    pub political_color: [f32; 4],
    /// Terrain index: 0 = water/sea, non-zero = land class.
    pub terrain_type: u32,
    /// Border style index forwarded to the renderer for line variant selection.
    pub border_style: u32,
    /// Fog-of-war state byte; 0 = fully fogged.
    pub fog_state: u8,
    /// Visibility state byte; 1 = visible (default).
    pub visibility_state: u8,
}

/// Default ProvinceStyle: grey political color, water terrain, no fog, visible.
impl Default for ProvinceStyle {
    fn default() -> Self {
        Self {
            political_color: [0.5, 0.5, 0.5, 1.0],
            terrain_type: 0,
            border_style: 0,
            fog_state: 0,
            visibility_state: 1,
        }
    }
}

/// Immutable point-in-time view of a province returned by ProvinceRegistry::get_province.
#[derive(Debug, Clone, PartialEq)]
pub struct ProvinceSnapshot {
    /// Identifier of the province this snapshot describes.
    pub province_id: ProvinceId,
    /// Visual and gameplay style at snapshot time.
    pub style: ProvinceStyle,
    /// Registry revision counter at the time of snapshot creation.
    pub revision: u64,
    /// Weighted pixel centroid; None if province has no spans.
    pub centroid: Option<(f32, f32)>,
    /// Arbitrary key-value metadata set via set_attr.
    pub attrs: HashMap<String, String>,
}
