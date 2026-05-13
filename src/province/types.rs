use std::collections::HashMap;
pub type ProvinceId = u32;
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum BorderClass {
    LandLand,
    Coast,
    SeaSea,
    Special,
}
impl BorderClass {
    pub fn as_str(self) -> &'static str {
        match self {
            BorderClass::LandLand => "land_land",
            BorderClass::Coast => "coast",
            BorderClass::SeaSea => "sea_sea",
            BorderClass::Special => "special",
        }
    }
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
#[derive(Debug, Clone, PartialEq)]
pub struct ProvinceStyle {
    pub political_color: [f32; 4],
    pub terrain_type: u32,
    pub border_style: u32,
    pub fog_state: u8,
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
#[derive(Debug, Clone, PartialEq)]
pub struct ProvinceSnapshot {
    pub province_id: ProvinceId,
    pub style: ProvinceStyle,
    pub revision: u64,
    pub centroid: Option<(f32, f32)>,
    pub attrs: HashMap<String, String>,
}
