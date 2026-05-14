//! `RaycasterScene` and its constituent quad/sprite/mesh types. Built each frame
//! by `build_scene` from DDA cast results, then consumed by `render` to produce
//! `RenderCommand` calls. Does not own DDA traversal or GPU state.

use crate::math::Vec2;
use crate::render::mesh::Mesh;
use crate::runtime::resource_keys::TextureKey;
/// A textured or flat-shaded wall slice quad emitted for one raycaster column or face.
#[derive(Debug, Clone)]
pub struct WallQuad {
    /// Screen-space corner positions; order: top-left, top-right, bottom-right, bottom-left.
    pub corners: [Vec2; 4],
    /// UV coordinates matching `corners`.
    pub uvs: [Vec2; 4],
    /// Optional texture; `None` draws a flat `light`-colored rectangle.
    pub texture_key: Option<TextureKey>,
    /// Premultiplied RGBA light and tint applied at draw time.
    pub light: [f32; 4],
    /// Perpendicular camera-plane depth used for sprite occlusion sorting.
    pub depth: f32,
    /// Homogeneous W values per corner for perspective-correct texture sampling.
    pub corner_w: [f32; 4],
    /// Tile value of the wall cell that produced this quad.
    pub cell_value: u32,
}
/// A perspective-correct floor quad covering one screen column strip.
#[derive(Debug, Clone)]
pub struct FloorQuad {
    /// Screen-space corner positions.
    pub corners: [Vec2; 4],
    /// UV coordinates matching `corners`.
    pub uvs: [Vec2; 4],
    /// Optional texture; `None` draws a flat-colored rectangle.
    pub texture_key: Option<TextureKey>,
    /// Premultiplied RGBA light tint.
    pub light: [f32; 4],
    /// Depth for back-to-front sorting.
    pub depth: f32,
    /// Homogeneous W values for perspective-correct UV interpolation.
    pub corner_w: [f32; 4],
}
/// A perspective-correct ceiling quad covering one screen column strip.
#[derive(Debug, Clone)]
pub struct CeilingQuad {
    /// Screen-space corner positions.
    pub corners: [Vec2; 4],
    /// UV coordinates matching `corners`.
    pub uvs: [Vec2; 4],
    /// Optional texture; `None` draws a flat-colored rectangle.
    pub texture_key: Option<TextureKey>,
    /// Premultiplied RGBA light tint.
    pub light: [f32; 4],
    /// Depth for back-to-front sorting.
    pub depth: f32,
    /// Homogeneous W values for perspective-correct UV interpolation.
    pub corner_w: [f32; 4],
}
/// An axis-aligned billboard sprite quad, sorted by depth relative to walls.
#[derive(Debug, Clone)]
pub struct BillboardSprite {
    /// Screen-space corner positions.
    pub corners: [Vec2; 4],
    /// UV coordinates matching `corners`.
    pub uvs: [Vec2; 4],
    /// Texture used to draw this sprite.
    pub texture_key: TextureKey,
    /// Premultiplied RGBA light tint.
    pub light: [f32; 4],
    /// Perpendicular depth for depth-buffer occlusion testing.
    pub depth: f32,
}
/// A static mesh injected into the raycaster scene with an associated depth.
#[derive(Debug, Clone)]
pub struct ModelMesh {
    /// Mesh geometry and texture to draw.
    pub mesh: Mesh,
    /// Depth used for sorting alongside sprites and walls.
    pub depth: f32,
}
/// Full frame scene produced by `RaycasterScene::build`; consumed by `render::generate_render_commands`.
#[derive(Debug, Clone, Default)]
pub struct RaycasterScene {
    /// Wall quads sorted front-to-back by depth.
    pub walls: Vec<WallQuad>,
    /// Floor quads sorted front-to-back.
    pub floors: Vec<FloorQuad>,
    /// Ceiling quads sorted front-to-back.
    pub ceilings: Vec<CeilingQuad>,
    /// Billboard sprites sorted back-to-front for alpha blending.
    pub sprites: Vec<BillboardSprite>,
    /// Static model meshes sorted back-to-front.
    pub models: Vec<ModelMesh>,
    /// Framebuffer width in pixels used when building this scene.
    pub screen_width: f32,
    /// Framebuffer height in pixels used when building this scene.
    pub screen_height: f32,
}
impl RaycasterScene {
    /// Create an empty scene sized to `screen_width` × `screen_height` pixels.
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
    /// Return the total number of quads, sprites, and models in this scene.
    pub fn quad_count(&self) -> usize {
        self.walls.len()
            + self.floors.len()
            + self.ceilings.len()
            + self.sprites.len()
            + self.models.len()
    }
    /// Return true when no geometry has been added to this scene.
    pub fn is_empty(&self) -> bool {
        self.quad_count() == 0
    }
}
