#[derive(Debug, Clone)]
pub struct Slot {
    pub name: String,
    pub bone_index: usize,
    pub color_r: f32,
    pub color_g: f32,
    pub color_b: f32,
    pub color_a: f32,
    pub attachment_name: Option<String>,
    pub draw_order: i32,
}
impl Slot {
    pub fn new(name: impl Into<String>, bone_index: usize) -> Self {
        Self {
            name: name.into(),
            bone_index,
            color_r: 1.0,
            color_g: 1.0,
            color_b: 1.0,
            color_a: 1.0,
            attachment_name: None,
            draw_order: 0,
        }
    }
}
