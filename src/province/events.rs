use crate::province::types::{BorderClass, ProvinceId};
#[derive(Debug, Clone, PartialEq)]
pub enum ProvinceChange {
    PoliticalColor {
        province_id: ProvinceId,
        color: [f32; 4],
    },
    TerrainType {
        province_id: ProvinceId,
        terrain_type: u32,
    },
    BorderStyle {
        province_id: ProvinceId,
        border_style: u32,
    },
    FogState {
        province_id: ProvinceId,
        fog_state: u8,
    },
    VisibilityState {
        province_id: ProvinceId,
        visibility_state: u8,
    },
    BorderClass {
        province_a: ProvinceId,
        province_b: ProvinceId,
        class: BorderClass,
    },
}
#[derive(Debug, Clone, PartialEq)]
pub enum ProvinceEvent {
    ProvinceStateChanged,
    MapModeChanged { mode: String },
    TerrainPaletteChanged,
    BorderStyleChanged,
    FogStateChanged,
}
