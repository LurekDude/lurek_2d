use crate::province::types::ProvinceStyle;
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProvinceMapMode {
    Political,
    Terrain,
    Visibility,
}
impl ProvinceMapMode {
    pub fn as_str(self) -> &'static str {
        match self {
            ProvinceMapMode::Political => "political",
            ProvinceMapMode::Terrain => "terrain",
            ProvinceMapMode::Visibility => "visibility",
        }
    }
    pub fn parse_str(value: &str) -> Option<Self> {
        match value {
            "political" => Some(ProvinceMapMode::Political),
            "terrain" => Some(ProvinceMapMode::Terrain),
            "visibility" => Some(ProvinceMapMode::Visibility),
            _ => None,
        }
    }
}
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
