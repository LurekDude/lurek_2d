#[derive(Debug, Clone)]
pub struct Bone {
    pub name: String,
    pub parent_index: Option<usize>,
    pub local_x: f32,
    pub local_y: f32,
    pub local_rotation: f32,
    pub local_scale_x: f32,
    pub local_scale_y: f32,
    pub world_x: f32,
    pub world_y: f32,
    pub world_rotation: f32,
    pub world_scale_x: f32,
    pub world_scale_y: f32,
}
impl Bone {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            parent_index: None,
            local_x: 0.0,
            local_y: 0.0,
            local_rotation: 0.0,
            local_scale_x: 1.0,
            local_scale_y: 1.0,
            world_x: 0.0,
            world_y: 0.0,
            world_rotation: 0.0,
            world_scale_x: 1.0,
            world_scale_y: 1.0,
        }
    }
    pub fn with_parent(name: impl Into<String>, parent: usize, x: f32, y: f32) -> Self {
        Self {
            name: name.into(),
            parent_index: Some(parent),
            local_x: x,
            local_y: y,
            local_rotation: 0.0,
            local_scale_x: 1.0,
            local_scale_y: 1.0,
            world_x: 0.0,
            world_y: 0.0,
            world_rotation: 0.0,
            world_scale_x: 1.0,
            world_scale_y: 1.0,
        }
    }
}
