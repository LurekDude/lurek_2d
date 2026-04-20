//! Scene builder for textured-quad raycaster rendering.
//!
//! Builds a [`RaycasterScene`] from a [`Raycaster2D`] grid, camera parameters,
//! and lighting data. Every surface is represented as a textured quad with
//! per-polygon lighting — no column-strip rendering.

use crate::math::{Color, Vec2};
use crate::raycaster::dda::Raycaster2D;
use crate::raycaster::lighting::{compute_lighting, PointLight};
use crate::raycaster::projection::{distance_shade, project_column};
use crate::raycaster::scene::{
    BillboardSprite, CeilingQuad, FloorQuad, RaycasterScene, WallQuad,
};
use crate::runtime::resource_keys::TextureKey;

// ── Private helpers ───────────────────────────────────────────────────────────

/// Converts a screen-space rect `(x, y, w, h)` into four corner [`Vec2`] positions.
///
/// Order: top-left, top-right, bottom-right, bottom-left.
fn corners_from_rect(x: f32, y: f32, w: f32, h: f32) -> [Vec2; 4] {
    [
        Vec2::new(x, y),
        Vec2::new(x + w, y),
        Vec2::new(x + w, y + h),
        Vec2::new(x, y + h),
    ]
}

/// Standard `[0,1]` UV rectangle: `(0,0)`, `(1,0)`, `(1,1)`, `(0,1)`.
fn rect_uvs() -> [Vec2; 4] {
    [
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(1.0, 1.0),
        Vec2::new(0.0, 1.0),
    ]
}

/// Column-strip UVs for a wall quad. Both left and right edges share `tex_u`,
/// mapping a single texture column vertically from `v=0` (top) to `v=1` (bottom).
fn wall_uvs(tex_u: f32) -> [Vec2; 4] {
    [
        Vec2::new(tex_u, 0.0), // top-left
        Vec2::new(tex_u, 0.0), // top-right (same column)
        Vec2::new(tex_u, 1.0), // bottom-right
        Vec2::new(tex_u, 1.0), // bottom-left
    ]
}

/// Converts a [`Color`] to an RGBA `[f32; 4]` light array.
fn color_to_light(c: &Color) -> [f32; 4] {
    [c.r, c.g, c.b, c.a]
}


/// Parameters for building a raycaster scene.
///
/// # Fields
/// - `player_x` — `f32`. Player world X position.
/// - `player_y` — `f32`. Player world Y position.
/// - `player_angle` — `f32`. Player facing angle in radians.
/// - `fov` — `f32`. Horizontal field of view in radians.
/// - `ray_count` — `u32`. Number of rays to cast (screen columns).
/// - `max_distance` — `f32`. Maximum ray distance.
/// - `screen_width` — `f32`. Screen width in pixels.
/// - `screen_height` — `f32`. Screen height in pixels.
/// - `ambient_light` — `f32`. Base ambient light level `[0.0, 1.0]`.
/// - `shade_distance` — `f32`. Maximum shading distance.
/// - `floor_color` — `Color`. Fallback floor colour when no texture.
/// - `ceiling_color` — `Color`. Fallback ceiling colour when no texture.
#[derive(Debug, Clone)]
pub struct SceneBuildParams {
    /// Player world X position.
    pub player_x: f32,
    /// Player world Y position.
    pub player_y: f32,
    /// Player facing angle in radians.
    pub player_angle: f32,
    /// Horizontal field of view in radians.
    pub fov: f32,
    /// Number of rays to cast (one per screen column).
    pub ray_count: u32,
    /// Maximum ray casting distance.
    pub max_distance: f32,
    /// Screen width in pixels.
    pub screen_width: f32,
    /// Screen height in pixels.
    pub screen_height: f32,
    /// Base ambient light level `[0.0, 1.0]`.
    pub ambient_light: f32,
    /// Maximum distance for distance-based shading.
    pub shade_distance: f32,
    /// Fallback floor colour when no floor texture is set.
    pub floor_color: Color,
    /// Fallback ceiling colour when no ceiling texture is set.
    pub ceiling_color: Color,
}

/// A world-space sprite for scene building.
///
/// # Fields
/// - `world_x` — `f32`. Sprite world X.
/// - `world_y` — `f32`. Sprite world Y.
/// - `texture_key` — `TextureKey`. Sprite texture.
/// - `size` — `f32`. Sprite size in world units (used for screen projection).
#[derive(Debug, Clone)]
pub struct WorldSprite {
    /// Sprite world X position.
    pub world_x: f32,
    /// Sprite world Y position.
    pub world_y: f32,
    /// Sprite texture.
    pub texture_key: TextureKey,
    /// Sprite size in world units (projected to screen space).
    pub size: f32,
}

/// Texture lookup function type. Given a cell value, returns a texture key.
pub type TextureLookup = dyn Fn(u32) -> Option<TextureKey>;

impl RaycasterScene {
    /// Builds a complete scene from a raycaster grid with per-polygon lighting.
    ///
    /// Casts rays across the player's FOV, projects wall hits to textured quads,
    /// generates floor/ceiling quads for each column, and projects billboard
    /// sprites. All geometry receives per-polygon lighting computed from the
    /// ambient level and active point lights.
    ///
    /// # Parameters
    /// - `raycaster` — `&Raycaster2D`. The grid to raycast against.
    /// - `params` — `&SceneBuildParams`. Camera and rendering parameters.
    /// - `lights` — `&[PointLight]`. Active point lights in the scene.
    /// - `sprites` — `&[WorldSprite]`. World-space sprites to project.
    /// - `wall_texture` — `&dyn Fn(u32) -> Option<TextureKey>`. Maps cell values to textures.
    ///
    /// # Returns
    /// `RaycasterScene`.
    pub fn build(
        raycaster: &Raycaster2D,
        params: &SceneBuildParams,
        lights: &[PointLight],
        sprites: &[WorldSprite],
        wall_texture: &dyn Fn(u32) -> Option<TextureKey>,
    ) -> Self {
        let ray_hits = raycaster.cast_rays(
            params.player_x,
            params.player_y,
            params.player_angle,
            params.fov,
            params.ray_count,
            params.max_distance,
        );

        let col_width = params.screen_width / params.ray_count.max(1) as f32;
        let half_height = params.screen_height / 2.0;

        let mut scene = RaycasterScene::new(params.screen_width, params.screen_height);

        // Pre-allocate rough capacity
        scene.walls.reserve(ray_hits.len());
        scene.floors.reserve(ray_hits.len());
        scene.ceilings.reserve(ray_hits.len());

        for (i, hit) in ray_hits.iter().enumerate() {
            let screen_x = i as f32 * col_width;

            if !hit.hit {
                // No wall hit — draw full-height floor and ceiling
                let floor_light =
                    compute_lighting(params.player_x, params.player_y, params.ambient_light, lights);
                let floor_lc = Color::new(floor_light[0], floor_light[1], floor_light[2], 1.0);

                scene.floors.push(FloorQuad {
                    corners: corners_from_rect(screen_x, half_height, col_width, half_height),
                    uvs: rect_uvs(),
                    texture_key: None,
                    light: color_to_light(&floor_lc),
                    depth: params.max_distance,
                });
                scene.ceilings.push(CeilingQuad {
                    corners: corners_from_rect(screen_x, 0.0, col_width, half_height),
                    uvs: rect_uvs(),
                    texture_key: None,
                    light: color_to_light(&floor_lc),
                    depth: params.max_distance,
                });
                continue;
            }

            // ── Wall quad ──
            let (_wall_height, draw_start, draw_end) =
                project_column(hit.distance, params.fov, params.screen_height);
            let shade = distance_shade(hit.distance, params.shade_distance);
            let wall_light_rgb = compute_lighting(hit.hit_x, hit.hit_y, params.ambient_light, lights);
            let wall_color = Color::new(
                shade * wall_light_rgb[0],
                shade * wall_light_rgb[1],
                shade * wall_light_rgb[2],
                1.0,
            );

            scene.walls.push(WallQuad {
                corners: corners_from_rect(screen_x, draw_start, col_width, draw_end - draw_start),
                uvs: wall_uvs(hit.tex_u),
                texture_key: wall_texture(hit.cell_value),
                light: color_to_light(&wall_color),
                depth: hit.distance,
                cell_value: hit.cell_value,
            });

            // ── Floor quad (below wall) ──
            let floor_y = draw_end;
            let floor_h = params.screen_height - floor_y;
            if floor_h > 0.0 {
                let floor_light =
                    compute_lighting(hit.hit_x, hit.hit_y, params.ambient_light, lights);
                let floor_shade = shade * 0.8; // floors slightly darker
                let floor_color = Color::new(
                    floor_shade * floor_light[0],
                    floor_shade * floor_light[1],
                    floor_shade * floor_light[2],
                    1.0,
                );

                scene.floors.push(FloorQuad {
                    corners: corners_from_rect(screen_x, floor_y, col_width, floor_h),
                    uvs: rect_uvs(),
                    texture_key: None,
                    light: color_to_light(&floor_color),
                    depth: hit.distance,
                });
            }

            // ── Ceiling quad (above wall) ──
            let ceil_h = draw_start;
            if ceil_h > 0.0 {
                let ceil_light =
                    compute_lighting(hit.hit_x, hit.hit_y, params.ambient_light, lights);
                let ceil_shade = shade * 0.7; // ceilings slightly darker than floors
                let ceil_color = Color::new(
                    ceil_shade * ceil_light[0],
                    ceil_shade * ceil_light[1],
                    ceil_shade * ceil_light[2],
                    1.0,
                );

                scene.ceilings.push(CeilingQuad {
                    corners: corners_from_rect(screen_x, 0.0, col_width, ceil_h),
                    uvs: rect_uvs(),
                    texture_key: None,
                    light: color_to_light(&ceil_color),
                    depth: hit.distance,
                });
            }
        }

        // ── Billboard sprites ──
        for ws in sprites {
            let dx = ws.world_x - params.player_x;
            let dy = ws.world_y - params.player_y;
            let dist = (dx * dx + dy * dy).sqrt();

            if dist < 0.1 || dist > params.max_distance {
                continue;
            }

            // Angle from player to sprite
            let sprite_angle = dy.atan2(dx);
            let mut angle_diff = sprite_angle - params.player_angle;
            // Normalise to [-PI, PI]
            while angle_diff > std::f32::consts::PI {
                angle_diff -= 2.0 * std::f32::consts::PI;
            }
            while angle_diff < -std::f32::consts::PI {
                angle_diff += 2.0 * std::f32::consts::PI;
            }

            let half_fov = params.fov / 2.0;
            if angle_diff.abs() > half_fov {
                continue; // outside FOV
            }

            // Project to screen
            let screen_x_center =
                params.screen_width / 2.0 + (angle_diff / half_fov) * (params.screen_width / 2.0);
            let projected_size = (ws.size / dist) * (params.screen_height / params.fov.tan());

            let sprite_light = compute_lighting(ws.world_x, ws.world_y, params.ambient_light, lights);
            let sprite_shade = distance_shade(dist, params.shade_distance);
            let sprite_color = Color::new(
                sprite_shade * sprite_light[0],
                sprite_shade * sprite_light[1],
                sprite_shade * sprite_light[2],
                1.0,
            );

            scene.sprites.push(BillboardSprite {
                corners: corners_from_rect(
                    screen_x_center - projected_size / 2.0,
                    (params.screen_height - projected_size) / 2.0,
                    projected_size,
                    projected_size,
                ),
                uvs: rect_uvs(),
                texture_key: ws.texture_key,
                light: color_to_light(&sprite_color),
                depth: dist,
            });
        }

        // Sort sprites back-to-front
        scene
            .sprites
            .sort_by(|a, b| b.depth.partial_cmp(&a.depth).unwrap_or(std::cmp::Ordering::Equal));

        scene
    }
}
