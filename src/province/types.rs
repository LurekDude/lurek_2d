//! Core value types for the province engine.

use std::collections::HashMap;

/// Province identifier used across province/globe/minimap modules.
pub type ProvinceId = u32;

/// Visual/semantic class for borders between two provinces.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum BorderClass {
    /// Land border between two non-water provinces.
    LandLand,
    /// Coastline-like border between land and water provinces.
    Coast,
    /// Border inside water domains (sea zones).
    SeaSea,
    /// Explicitly marked special border (e.g. disputed/custom style).
    Special,
}

impl BorderClass {
    /// Converts this border class to a stable string token for Lua/docs.
    pub fn as_str(self) -> &'static str {
        match self {
            BorderClass::LandLand => "land_land",
            BorderClass::Coast => "coast",
            BorderClass::SeaSea => "sea_sea",
            BorderClass::Special => "special",
        }
    }

    /// Parses a border class token from Lua-facing API strings.
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

/// Mutable style/state attached to one province.
#[derive(Debug, Clone, PartialEq)]
pub struct ProvinceStyle {
    /// Political/ownership color in linear 0..1 RGBA.
    pub political_color: [f32; 4],
    /// Terrain class index used by terrain atlas sampling.
    pub terrain_type: u32,
    /// Border style index interpreted by render pass.
    pub border_style: u32,
    /// Fog state byte (module-specific semantics).
    pub fog_state: u8,
    /// Visibility byte (module-specific semantics).
    pub visibility_state: u8,
}

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

/// Immutable read model consumed by other modules.
#[derive(Debug, Clone, PartialEq)]
pub struct ProvinceSnapshot {
    /// Province unique id.
    pub province_id: ProvinceId,
    /// Copy of style/state values.
    pub style: ProvinceStyle,
    /// Registry revision that produced this snapshot.
    pub revision: u64,
    /// Optional centroid in pixel/map space.
    pub centroid: Option<(f32, f32)>,
    /// Optional freeform attributes.
    pub attrs: HashMap<String, String>,
}
