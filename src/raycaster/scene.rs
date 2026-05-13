use crate::math::Vec2;
use crate::render::mesh::Mesh;
use crate::runtime::resource_keys::TextureKey;
#[derive(Debug, Clone)]
pub struct WallQuad {
    pub corners: [Vec2; 4],
    pub uvs: [Vec2; 4],
    pub texture_key: Option<TextureKey>,
    pub light: [f32; 4],
    pub depth: f32,
    pub corner_w: [f32; 4],
    pub cell_value: u32,
}
#[derive(Debug, Clone)]
pub struct FloorQuad {
    pub corners: [Vec2; 4],
    pub uvs: [Vec2; 4],
    pub texture_key: Option<TextureKey>,
    pub light: [f32; 4],
    pub depth: f32,
    pub corner_w: [f32; 4],
}
#[derive(Debug, Clone)]
pub struct CeilingQuad {
    pub corners: [Vec2; 4],
    pub uvs: [Vec2; 4],
    pub texture_key: Option<TextureKey>,
    pub light: [f32; 4],
    pub depth: f32,
    pub corner_w: [f32; 4],
}
#[derive(Debug, Clone)]
pub struct BillboardSprite {
    pub corners: [Vec2; 4],
    pub uvs: [Vec2; 4],
    pub texture_key: TextureKey,
    pub light: [f32; 4],
    pub depth: f32,
}
#[derive(Debug, Clone)]
pub struct ModelMesh {
    pub mesh: Mesh,
    pub depth: f32,
}
#[derive(Debug, Clone, Default)]
pub struct RaycasterScene {
    pub walls: Vec<WallQuad>,
    pub floors: Vec<FloorQuad>,
    pub ceilings: Vec<CeilingQuad>,
    pub sprites: Vec<BillboardSprite>,
    pub models: Vec<ModelMesh>,
    pub screen_width: f32,
    pub screen_height: f32,
}
impl RaycasterScene {
    pub fn new(screen_width: f32, screen_height: f32) -> Self {
        Self {
            walls: Vec::new(),
            floors: Vec::new(),
            ceilings: Vec::new(),
            sprites: Vec::new(),
            models: Vec::new(),
            screen_width,
            screen_height,
        }
    }
    pub fn quad_count(&self) -> usize {
        self.walls.len()
            + self.floors.len()
            + self.ceilings.len()
            + self.sprites.len()
            + self.models.len()
    }
    pub fn is_empty(&self) -> bool {
        self.quad_count() == 0
    }
}
