use crate::province::registry::ProvinceRegistry;
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ProvinceGpuRecord {
    pub political_color: [f32; 4],
    pub terrain_type: u32,
    pub border_style: u32,
    pub fog_state: u32,
    pub visibility_state: u32,
}
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
