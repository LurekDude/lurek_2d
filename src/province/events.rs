//! Province runtime events and change records.

use crate::province::types::{BorderClass, ProvinceId};

/// Fine-grained field updates emitted by the province registry.
#[derive(Debug, Clone, PartialEq)]
pub enum ProvinceChange {
    /// Political color changed for one province.
    PoliticalColor {
        /// Province id.
        province_id: ProvinceId,
        /// New RGBA color.
        color: [f32; 4],
    },
    /// Terrain type changed.
    TerrainType {
        /// Province id.
        province_id: ProvinceId,
        /// New terrain class id.
        terrain_type: u32,
    },
    /// Border style changed.
    BorderStyle {
        /// Province id.
        province_id: ProvinceId,
        /// New style id.
        border_style: u32,
    },
    /// Fog state changed.
    FogState {
        /// Province id.
        province_id: ProvinceId,
        /// New fog state byte.
        fog_state: u8,
    },
    /// Visibility state changed.
    VisibilityState {
        /// Province id.
        province_id: ProvinceId,
        /// New visibility byte.
        visibility_state: u8,
    },
    /// Border class changed between two provinces.
    BorderClass {
        /// First province id (order-independent key).
        province_a: ProvinceId,
        /// Second province id (order-independent key).
        province_b: ProvinceId,
        /// New class.
        class: BorderClass,
    },
}

/// High-level province events for subscribers.
#[derive(Debug, Clone, PartialEq)]
pub enum ProvinceEvent {
    /// State/style changed for one or more provinces.
    ProvinceStateChanged,
    /// Active map mode changed.
    MapModeChanged {
        /// Map mode name.
        mode: String,
    },
    /// Terrain palette changed.
    TerrainPaletteChanged,
    /// Border classes or styles changed.
    BorderStyleChanged,
    /// Fog state changed.
    FogStateChanged,
}
