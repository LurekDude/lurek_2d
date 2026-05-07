//! Static and dynamic point lighting for raycaster worlds.
//!
//! Provides simple ambient + point-light illumination suitable for retro FPS
//! and dungeon-crawler style environments.

/// Point light source in the raycaster world.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `radius` — `f32`.
/// - `intensity` — `f32`.
/// - `color` — `[f32; 3]`.
#[derive(Debug, Clone)]
pub struct PointLight {
    /// World-space X position.
    pub x: f32,
    /// World-space Y position.
    pub y: f32,
    /// Maximum illumination radius.
    pub radius: f32,
    /// Light intensity multiplier.
    pub intensity: f32,
    /// RGB color components, each in [0, 1].
    pub color: [f32; 3],
}

/// Checks line-of-sight between two tile positions using Bresenham traversal.
///
/// Returns `true` if there is no wall between `(x0,y0)` and `(x1,y1)`.
/// The source and destination tiles themselves are not treated as blockers.
fn has_line_of_sight(
    x0: i32, y0: i32,
    x1: i32, y1: i32,
    wall_at: &dyn Fn(i32, i32) -> bool,
) -> bool {
    let mut x = x0;
    let mut y = y0;
    let dx = (x1 - x0).abs();
    let dy = (y1 - y0).abs();
    let sx = if x0 < x1 { 1i32 } else { -1 };
    let sy = if y0 < y1 { 1i32 } else { -1 };
    let mut err = dx - dy;
    loop {
        if x == x1 && y == y1 { break; }
        let e2 = 2 * err;
        if e2 > -dy { err -= dy; x += sx; }
        if e2 <  dx { err += dx; y += sy; }
        // Only intermediate tiles block light (skip source and destination).
        if (x != x1 || y != y1) && wall_at(x, y) { return false; }
    }
    true
}

/// Computes ambient + point-light illumination at a world position.
///
/// Uses integer-tile distance steps (XCOM-style): a light with `radius = N`
/// illuminates tiles within N tiles, falling off by 1 step per tile.
/// `intensity` is on a **0–16 scale** where 16 equals full daylight (1.0 RGB).
/// Walls block light via Bresenham line-of-sight.
///
/// # Parameters
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `ambient` — `f32`.
/// - `lights` — `&[PointLight]`.
/// - `wall_at` — wall check closure `(tile_x, tile_y) -> bool`.
///
/// # Returns
/// `[f32; 3]`.
pub fn compute_lighting(
    x: f32,
    y: f32,
    ambient: f32,
    lights: &[PointLight],
    wall_at: &dyn Fn(i32, i32) -> bool,
) -> [f32; 3] {
    let mut r = ambient;
    let mut g = ambient;
    let mut b = ambient;

    let tx = x.floor() as i32;
    let ty = y.floor() as i32;

    for light in lights {
        let dx = x - light.x;
        let dy = y - light.y;
        // Integer-tile distance (XCOM-style step falloff).
        let tile_dist = (dx * dx + dy * dy).sqrt().floor();

        if tile_dist >= light.radius {
            continue;
        }

        // Line-of-sight wall blocking (tile level).
        let lx = light.x.floor() as i32;
        let ly = light.y.floor() as i32;
        if !has_line_of_sight(tx, ty, lx, ly, wall_at) {
            continue;
        }

        // Linear falloff per tile: full at dist 0, zero at dist == radius.
        let attenuation = (light.radius - tile_dist) / light.radius * (light.intensity / 16.0);
        r += light.color[0] * attenuation;
        g += light.color[1] * attenuation;
        b += light.color[2] * attenuation;
    }

    [r.clamp(0.0, 1.0), g.clamp(0.0, 1.0), b.clamp(0.0, 1.0)]
}

/// Applies lighting to a distance-shaded base brightness.
///
/// Multiplies the base shade value by each channel of the light color,
/// producing a final lit RGB value.
///
/// # Parameters
/// - `base_shade` — `f32`.
/// - `light_color` — `[f32; 3]`.
///
/// # Returns
/// `[f32; 3]`.
pub fn apply_lit_shade(base_shade: f32, light_color: [f32; 3]) -> [f32; 3] {
    [
        (base_shade * light_color[0]).clamp(0.0, 1.0),
        (base_shade * light_color[1]).clamp(0.0, 1.0),
        (base_shade * light_color[2]).clamp(0.0, 1.0),
    ]
}
