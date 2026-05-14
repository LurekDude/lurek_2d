//! Province map mode enum and colour resolver: selects display colour from ProvinceStyle based on active mode.
//! Consumed by the render layer; does not own rendering commands or GPU state.
use crate::province::types::ProvinceStyle;

/// Active map display mode; controls which style field drives the province fill colour.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProvinceMapMode {
    /// Display province political_color directly.
    Political,
    /// Display a hard-coded sea-blue or land-green derived from terrain_type.
    Terrain,
    /// Display a greyscale intensity from visibility_state.
    Visibility,
}

impl ProvinceMapMode {
    /// Return the canonical lowercase string token for this mode.
    pub fn as_str(self) -> &'static str {
        match self {
            ProvinceMapMode::Political => "political",
            ProvinceMapMode::Terrain => "terrain",
            ProvinceMapMode::Visibility => "visibility",
        }
    }

    /// Parse a string token to a variant; return None on unknown input.
    pub fn parse_str(value: &str) -> Option<Self> {
        match value {
            "political" => Some(ProvinceMapMode::Political),
            "terrain" => Some(ProvinceMapMode::Terrain),
            "visibility" => Some(ProvinceMapMode::Visibility),
            _ => None,
        }
    }
}

/// Return the RGBA fill colour for a province style under the given map mode.
pub fn resolve_color(mode: ProvinceMapMode, style: &ProvinceStyle) -> [f32; 4] {
    match mode {
        ProvinceMapMode::Political => style.political_color,
        ProvinceMapMode::Terrain => {
            if style.terrain_type == 0 {
                [35.0 / 255.0, 110.0 / 255.0, 210.0 / 255.0, 1.0]
            } else {
                [65.0 / 255.0, 165.0 / 255.0, 75.0 / 255.0, 1.0]
            }
        }
        ProvinceMapMode::Visibility => {
            let v = (style.visibility_state as f32) / 255.0;
            [v, v, v, 1.0]
        }
    }
}
