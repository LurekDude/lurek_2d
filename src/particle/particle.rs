#[derive(Clone, Debug)]
pub struct Particle {
    pub x: f32,
    pub y: f32,
    pub vx: f32,
    pub vy: f32,
    pub life: f32,
    pub max_life: f32,
    pub rotation: f32,
    pub spin: f32,
    pub radial_accel: f32,
    pub tangential_accel: f32,
    pub linear_damping: f32,
    pub size_variation: f32,
    pub origin_x: f32,
    pub origin_y: f32,
    pub shape_seed: u32,
}
