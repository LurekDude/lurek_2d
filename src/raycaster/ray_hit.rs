#[derive(Debug, Clone)]
pub struct RayHit {
    pub distance: f32,
    pub raw_distance: f32,
    pub cell_value: u32,
    pub alpha: f32,
    pub side: u8,
    pub tex_u: f32,
    pub hit_x: f32,
    pub hit_y: f32,
    pub hit: bool,
}
