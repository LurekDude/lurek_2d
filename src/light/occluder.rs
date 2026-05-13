use crate::math::Vec2;
pub struct Occluder {
    pub vertices: Vec<Vec2>,
    pub position: Vec2,
    pub opacity: f32,
    pub light_mask: u16,
    pub enabled: bool,
}
impl Occluder {
    pub fn new(vertices: Vec<Vec2>) -> Self {
        assert!(
            vertices.len() >= 3 && vertices.len() <= 512,
            "Occluder vertex count must be 3..=512, got {}",
            vertices.len()
        );
        Self {
            vertices,
            position: Vec2::ZERO,
            opacity: 1.0,
            light_mask: 0xFFFF,
            enabled: true,
        }
    }
    pub fn set_vertices(&mut self, vertices: Vec<Vec2>) {
        assert!(
            vertices.len() >= 3 && vertices.len() <= 512,
            "Occluder vertex count must be 3..=512, got {}",
            vertices.len()
        );
        self.vertices = vertices;
    }
    pub fn from_flat_coords(flat: &[f32]) -> Result<Self, String> {
        if flat.len() < 6 || flat.len() > 1024 || !flat.len().is_multiple_of(2) {
            return Err(format!(
                "vertex array must have 6..=1024 coordinates (3..=512 vertices), got {}",
                flat.len()
            ));
        }
        let verts: Vec<Vec2> = flat.chunks(2).map(|c| Vec2::new(c[0], c[1])).collect();
        Ok(Self::new(verts))
    }
    pub fn get_vertices(&self) -> &[Vec2] {
        &self.vertices
    }
    pub fn set_position(&mut self, position: Vec2) {
        self.position = position;
    }
    pub fn get_position(&self) -> Vec2 {
        self.position
    }
    pub fn set_opacity(&mut self, opacity: f32) {
        self.opacity = opacity;
    }
    pub fn get_opacity(&self) -> f32 {
        self.opacity
    }
    pub fn set_light_mask(&mut self, mask: u16) {
        self.light_mask = mask;
    }
    pub fn get_light_mask(&self) -> u16 {
        self.light_mask
    }
    pub fn set_enabled(&mut self, enabled: bool) {
        self.enabled = enabled;
    }
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }
}
