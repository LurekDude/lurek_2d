//! Raycaster scene types for textured-quad rendering.
//!
//! Defines the scene representation produced by [`build_scene`](RaycasterScene::build)
//! for dungeon-crawler and retro FPS games. Every surface (wall, floor, ceiling,
//! sprite) is a textured quad with per-polygon lighting — no column-strip rendering.

use crate::math::Vec2;
use crate::render::mesh::Mesh;
use crate::runtime::resource_keys::TextureKey;

// ── WallQuad ─────────────────────────────────────────────────────────────────

/// A single wall segment projected onto the screen as a perspective-correct textured quad.
///
/// Each wall quad represents one grid-cell face visible to the camera.
/// The texture is mapped with perspective-correct UV coordinates at each corner.
///
/// # Fields
/// - `corners` — `[Vec2; 4]`. Screen-space corner positions: top-left, top-right, bottom-right, bottom-left.
/// - `uvs` — `[Vec2; 4]`. Normalized UV coordinates `[0.0, 1.0]` for each corner (same order as `corners`).
/// - `texture_key` — `Option<TextureKey>`. Wall texture (solid colour fallback when `None`).
/// - `light` — `[f32; 4]`. Per-face RGBA light multiplier (`[r, g, b, 1.0]`).
/// - `depth` — `f32`. Distance from camera for depth sorting.
/// - `cell_value` — `u32`. Map cell value for multi-texture lookup.
#[derive(Debug, Clone)]
pub struct WallQuad {
    /// Screen-space corners: top-left, top-right, bottom-right, bottom-left.
    pub corners: [Vec2; 4],
    /// Normalized UV coordinates `[0.0, 1.0]` for each corner in the same order as `corners`.
    pub uvs: [Vec2; 4],
    /// Wall texture (solid colour fallback when `None`).
    pub texture_key: Option<TextureKey>,
    /// Per-face RGBA light multiplier (`[r, g, b, 1.0]`).
    pub light: [f32; 4],
    /// Distance from camera for depth sorting.
    pub depth: f32,
    /// Per-corner perspective depth for perspective-correct UV (matches corners order).
    pub corner_w: [f32; 4],
    /// Map cell value for multi-texture lookup.
    pub cell_value: u32,
}

// ── FloorQuad ────────────────────────────────────────────────────────────────

/// A single floor tile projected onto the screen as a textured quad.
///
/// # Fields
/// - `corners` — `[Vec2; 4]`. Screen-space corners: top-left, top-right, bottom-right, bottom-left.
/// - `uvs` — `[Vec2; 4]`. Normalized UV coordinates for each corner.
/// - `texture_key` — `Option<TextureKey>`. Floor texture (solid colour fallback when `None`).
/// - `light` — `[f32; 4]`. Per-face RGBA light multiplier.
/// - `depth` — `f32`. Distance from camera.
#[derive(Debug, Clone)]
pub struct FloorQuad {
    /// Screen-space corners: top-left, top-right, bottom-right, bottom-left.
    pub corners: [Vec2; 4],
    /// Normalized UV coordinates for each corner.
    pub uvs: [Vec2; 4],
    /// Floor texture (solid colour fallback when `None`).
    pub texture_key: Option<TextureKey>,
    /// Per-face RGBA light multiplier.
    pub light: [f32; 4],
    /// Distance from camera for depth sorting.
    pub depth: f32,
    /// Per-corner perspective depth for perspective-correct UV.
    pub corner_w: [f32; 4],
}

// ── CeilingQuad ──────────────────────────────────────────────────────────────

/// A single ceiling tile projected onto the screen as a textured quad.
///
/// Mirrors [`FloorQuad`] but drawn above the wall segments.
///
/// # Fields
/// - `corners` — `[Vec2; 4]`. Screen-space corners: top-left, top-right, bottom-right, bottom-left.
/// - `uvs` — `[Vec2; 4]`. Normalized UV coordinates for each corner.
/// - `texture_key` — `Option<TextureKey>`. Ceiling texture (solid colour fallback when `None`).
/// - `light` — `[f32; 4]`. Per-face RGBA light multiplier.
/// - `depth` — `f32`. Distance from camera.
#[derive(Debug, Clone)]
pub struct CeilingQuad {
    /// Screen-space corners: top-left, top-right, bottom-right, bottom-left.
    pub corners: [Vec2; 4],
    /// Normalized UV coordinates for each corner.
    pub uvs: [Vec2; 4],
    /// Ceiling texture (solid colour fallback when `None`).
    pub texture_key: Option<TextureKey>,
    /// Per-face RGBA light multiplier.
    pub light: [f32; 4],
    /// Distance from camera for depth sorting.
    pub depth: f32,
    /// Per-corner perspective depth for perspective-correct UV.
    pub corner_w: [f32; 4],
}

// ── BillboardSprite ──────────────────────────────────────────────────────────

/// A world-space sprite rendered as a camera-facing quad (billboard).
///
/// Used for objects, monsters, items, etc. The entire texture is drawn
/// on a single square quad — dungeon-crawler style (beholder, monsters).
///
/// # Fields
/// - `corners` — `[Vec2; 4]`. Screen-space corners: top-left, top-right, bottom-right, bottom-left.
/// - `uvs` — `[Vec2; 4]`. Normalized UV coordinates for each corner.
/// - `texture_key` — `TextureKey`. Sprite texture.
/// - `light` — `[f32; 4]`. Per-face RGBA light multiplier.
/// - `depth` — `f32`. Distance from camera (for depth sorting / occlusion).
#[derive(Debug, Clone)]
pub struct BillboardSprite {
    /// Screen-space corners: top-left, top-right, bottom-right, bottom-left.
    pub corners: [Vec2; 4],
    /// Normalized UV coordinates for each corner.
    pub uvs: [Vec2; 4],
    /// Sprite texture.
    pub texture_key: TextureKey,
    /// Per-face RGBA light multiplier.
    pub light: [f32; 4],
    /// Distance from camera for depth sorting.
    pub depth: f32,
}

/// A projected 3D model instance stored as a screen-space mesh.
#[derive(Debug, Clone)]
pub struct ModelMesh {
    /// Screen-space mesh vertices (typically triangles).
    pub mesh: Mesh,
    /// Distance from camera for depth sorting.
    pub depth: f32,
}

// ── RaycasterScene ───────────────────────────────────────────────────────────

/// Complete raycaster scene ready for rendering as textured quads.
///
/// Built by [`RaycasterScene::build`] from a [`Raycaster2D`](super::Raycaster2D)
/// grid and camera parameters. Contains all visible wall, floor, ceiling,
/// and sprite quads with per-polygon lighting pre-computed.
///
/// # Fields
/// - `walls` — `Vec<WallQuad>`. Visible wall segments.
/// - `floors` — `Vec<FloorQuad>`. Visible floor tiles.
/// - `ceilings` — `Vec<CeilingQuad>`. Visible ceiling tiles.
/// - `sprites` — `Vec<BillboardSprite>`. Billboard sprites sorted back-to-front.
/// - `screen_width` — `f32`. Screen width used for projection.
/// - `screen_height` — `f32`. Screen height used for projection.
#[derive(Debug, Clone, Default)]
pub struct RaycasterScene {
    /// Visible wall segments as textured quads.
    pub walls: Vec<WallQuad>,
    /// Visible floor tiles as textured quads.
    pub floors: Vec<FloorQuad>,
    /// Visible ceiling tiles as textured quads.
    pub ceilings: Vec<CeilingQuad>,
    /// Billboard sprites sorted back-to-front by depth.
    pub sprites: Vec<BillboardSprite>,
    /// Screen-space model meshes sorted with the scene.
    pub models: Vec<ModelMesh>,
    /// Screen width used for projection.
    pub screen_width: f32,
    /// Screen height used for projection.
    pub screen_height: f32,
}

impl RaycasterScene {
    /// Creates an empty scene.
    ///
    /// # Parameters
    /// - `screen_width` — `f32`.
    /// - `screen_height` — `f32`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Returns the total number of quads in the scene.
    ///
    /// # Returns
    /// `usize`.
    pub fn quad_count(&self) -> usize {
        self.walls.len()
            + self.floors.len()
            + self.ceilings.len()
            + self.sprites.len()
            + self.models.len()
    }

    /// Returns `true` when the scene has no visible geometry.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.quad_count() == 0
    }
}
