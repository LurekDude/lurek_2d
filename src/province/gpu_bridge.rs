//! GPU data bridge: converts ProvinceRegistry style records into a tightly-packed struct array
//! suitable for upload as a uniform or storage buffer in the province render pass.
//! Does not touch wgpu directly; that is handled by the render pipeline layer.
use crate::province::registry::ProvinceRegistry;

/// Per-province GPU record laid out for direct buffer upload; repr(C) guarantees field order.
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ProvinceGpuRecord {
    /// RGBA political fill colour, matching ProvinceStyle::political_color.
    pub political_color: [f32; 4],
    /// Terrain type index matching ProvinceStyle::terrain_type.
    pub terrain_type: u32,
    /// Border style index matching ProvinceStyle::border_style.
    pub border_style: u32,
    /// Fog state packed as u32 for alignment; matches ProvinceStyle::fog_state.
    pub fog_state: u32,
    /// Visibility state packed as u32 for alignment; matches ProvinceStyle::visibility_state.
    pub visibility_state: u32,
}

/// Build a sorted Vec of ProvinceGpuRecord from registry province ids; result order follows sorted ids.
pub fn build_gpu_records(registry: &ProvinceRegistry) -> Vec<ProvinceGpuRecord> {
    let mut ids = registry.province_ids();
    ids.sort_unstable();
    ids.into_iter()
        .filter_map(|id| registry.get_province(id))
        .map(|snap| ProvinceGpuRecord {
            political_color: snap.style.political_color,
            terrain_type: snap.style.terrain_type,
            border_style: snap.style.border_style,
            fog_state: snap.style.fog_state as u32,
            visibility_state: snap.style.visibility_state as u32,
        })
        .collect()
}
    let mut ids = registry.province_ids();
    ids.sort_unstable();
    ids.into_iter()
        .filter_map(|id| registry.get_province(id))
        .map(|snap| ProvinceGpuRecord {
            political_color: snap.style.political_color,
            terrain_type: snap.style.terrain_type,
            border_style: snap.style.border_style,
            fog_state: snap.style.fog_state as u32,
            visibility_state: snap.style.visibility_state as u32,
        })
        .collect()
}
