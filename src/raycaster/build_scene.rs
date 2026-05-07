//! Scene builder for textured-quad raycaster rendering.
//!
//! Builds a [`RaycasterScene`] from a [`Raycaster2D`] grid, camera parameters,
//! and lighting data. Every surface is represented as a textured quad with
//! per-polygon lighting â€” no column-strip rendering.

use crate::math::{Color, Vec2};
use crate::raycaster::dda::Raycaster2D;
use crate::raycaster::lighting::{compute_lighting, PointLight};
use crate::raycaster::projection::distance_shade;
use crate::raycaster::ray_hit::RayHit;
use crate::raycaster::scene::{BillboardSprite, CeilingQuad, FloorQuad, RaycasterScene, WallQuad};
use crate::runtime::resource_keys::TextureKey;

/// Per-cell lowered-floor configuration used for liquids and trenches.
///
/// A lowered floor renders below the normal tile plane and can optionally
/// block movement while exposing side walls against higher neighboring cells.
#[derive(Debug, Clone, Copy)]
pub struct LoweredFloorCell {
    pub texture_key: TextureKey,
    /// Additional drop below the normal floor plane. 0.25 means the liquid top
    /// is rendered 25% lower than a regular floor tile.
    pub depth_offset: f32,
    /// Multiplicative tint applied to the textured top and side faces.
    pub tint: [f32; 3],
    /// Whether movement should treat this cell as blocked.
    pub blocked: bool,
}

// â”€â”€ Private helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

fn frac01(v: f32) -> f32 {
    let f = v - v.floor();
    if f < 0.0 { f + 1.0 } else { f }
}

/// Returns the grid cell (cx, cy) just in front of the wall (on the camera side).
#[allow(dead_code)]
fn floor_cell_before_hit(hit: &RayHit, ray_angle: f32) -> (u32, u32) {
    let wx = (hit.hit_x - ray_angle.cos() * 0.5).max(0.0);
    let wy = (hit.hit_y - ray_angle.sin() * 0.5).max(0.0);
    (wx.floor() as u32, wy.floor() as u32)
}

#[allow(dead_code)]
fn column_uvs_from_world(near_x: f32, near_y: f32, far_x: f32, far_y: f32) -> [Vec2; 4] {
    let nu = frac01(near_x);
    let nv = frac01(near_y);
    let fu = frac01(far_x);
    let fv = frac01(far_y);
    [
        Vec2::new(nu, nv),
        Vec2::new(nu, nv),
        Vec2::new(fu, fv),
        Vec2::new(fu, fv),
    ]
}

const FLOOR_NEAR: f32 = 0.05;
const ROOFED_AMBIENT_FACTOR: f32 = 0.20;

#[inline]
fn camera_depth(wx: f32, wy: f32, px: f32, py: f32, cos_a: f32, sin_a: f32) -> f32 {
    let rx = wx - px;
    let ry = wy - py;
    rx * cos_a + ry * sin_a
}

#[derive(Debug, Clone, Copy)]
struct ProjectedGroundPoint {
    sx: f32,
    floor_y: f32,
    ceil_y: f32,
    cx: f32,
}


#[allow(clippy::too_many_arguments)]
#[inline]
fn project_ground_point(
    wx: f32,
    wy: f32,
    px: f32,
    py: f32,
    cos_a: f32,
    sin_a: f32,
    proj_dist: f32,
    screen_w: f32,
    horizon: f32,
    floor_plane: f32,
    ceiling_plane: f32,
) -> ProjectedGroundPoint {
    let rx = wx - px;
    let ry = wy - py;
    // Clamp to near plane to avoid division by zero and keep w_depth positive.
    // GPU will clip the resulting extreme coordinates.
    let cx = (rx * cos_a + ry * sin_a).max(FLOOR_NEAR);
    let cy = -rx * sin_a + ry * cos_a;
    // Keep near-plane projected corners bounded so partially clipped tiles do not
    // generate oversized background quads.
    let sx = (screen_w * 0.5 + (cy / cx) * proj_dist).clamp(-screen_w * 2.0, screen_w * 3.0);
    let sy_floor = horizon + proj_dist * floor_plane / cx;
    let sy_ceil = horizon + proj_dist * ceiling_plane / cx;
    ProjectedGroundPoint {
        sx: snap_half(sx),
        floor_y: snap_half(sy_floor),
        ceil_y: snap_half(sy_ceil),
        cx,  // raw camera depth â€” shader w_depth = cx for perspective-correct UV
    }
}

#[allow(clippy::too_many_arguments)]
#[inline]
fn project_horizontal_plane(
    wx: f32,
    wy: f32,
    px: f32,
    py: f32,
    cos_a: f32,
    sin_a: f32,
    proj_dist: f32,
    screen_w: f32,
    horizon: f32,
    plane_offset: f32,
) -> (f32, f32, f32) {
    let rx = wx - px;
    let ry = wy - py;
    // Clamp to near plane to avoid division by zero and keep w_depth positive.
    // GPU will clip the resulting extreme coordinates.
    let cx = (rx * cos_a + ry * sin_a).max(FLOOR_NEAR);
    let cy = -rx * sin_a + ry * cos_a;
    // Keep near-plane projected corners bounded so partially clipped tiles do not
    // generate oversized background quads.
    let sx = (screen_w * 0.5 + (cy / cx) * proj_dist).clamp(-screen_w * 2.0, screen_w * 3.0);
    let sy = horizon + proj_dist * plane_offset / cx;
    (snap_half(sx), snap_half(sy), cx)
}

/// Snap a screen coordinate to the nearest half-pixel grid.
/// Adjacent tiles that share a world corner project to the same
/// floating-point value, so after snapping they land on the same
/// rasterised pixel â€” eliminating sub-pixel seams.
#[inline]
fn snap_half(v: f32) -> f32 {
    (v * 2.0).round() * 0.5
}

#[allow(clippy::too_many_arguments)]
fn build_floor_tiles(
    raycaster: &Raycaster2D,
    params: &SceneBuildParams,
    proj_dist: f32,
    lights: &[PointLight],
    wall_at: &dyn Fn(i32, i32) -> bool,
    floor_texture_at: &dyn Fn(u32, u32) -> Option<TextureKey>,
    ceiling_texture_at: &dyn Fn(u32, u32) -> Option<TextureKey>,
    lowered_floor_at: &dyn Fn(u32, u32) -> Option<LoweredFloorCell>,
    walls: &mut Vec<WallQuad>,
    floors: &mut Vec<FloorQuad>,
    ceilings: &mut Vec<CeilingQuad>,
) {
    let horizon = params.screen_height * 0.5 - params.horizon_offset;
    let eye = params.camera_height.clamp(0.1, 0.9);
    let floor_plane = eye;
    let ceiling_plane = -(1.0 - eye);
    let cos_a = params.player_angle.cos();
    let sin_a = params.player_angle.sin();
    let px = params.player_x;
    let py = params.player_y;
    let sw = params.screen_width;
    let md = params.max_distance;

    let map_w = raycaster.width() as i32;
    let map_h = raycaster.height() as i32;

    let tx0 = (px - md - 1.0).floor() as i32;
    let tx1 = (px + md + 1.0).ceil() as i32;
    let ty0 = (py - md - 1.0).floor() as i32;
    let ty1 = (py + md + 1.0).ceil() as i32;

    let tx0 = tx0.max(0);
    let ty0 = ty0.max(0);
    let tx1 = tx1.min(map_w - 1);
    let ty1 = ty1.min(map_h - 1);

    // Pre-project every world grid corner once. All adjacent tiles then share the
    // exact same screen-space edge endpoints, which removes cracks.
    let vx0 = tx0.max(0);
    let vy0 = ty0.max(0);
    let vx1 = (tx1 + 1).min(map_w);
    let vy1 = (ty1 + 1).min(map_h);
    let proj_w = (vx1 - vx0 + 1).max(0) as usize;
    let proj_h = (vy1 - vy0 + 1).max(0) as usize;
    let mut proj: Vec<ProjectedGroundPoint> = Vec::with_capacity(proj_w * proj_h);
    let proj_idx = |gx: i32, gy: i32| -> usize { ((gy - vy0) as usize) * proj_w + (gx - vx0) as usize };

    for gy in vy0..=vy1 {
        for gx in vx0..=vx1 {
            proj.push(project_ground_point(
                gx as f32,
                gy as f32,
                px,
                py,
                cos_a,
                sin_a,
                proj_dist,
                sw,
                horizon,
                floor_plane,
                ceiling_plane,
            ));
        }
    }

    for ty in ty0..=ty1 {
        for tx in tx0..=tx1 {
            // Only render open (non-wall) cells.
            if raycaster.get_cell(tx as u32, ty as u32) != 0 {
                continue;
            }

            // Cull tiles beyond max distance.
            let dist = {
                let dx = tx as f32 + 0.5 - px;
                let dy = ty as f32 + 0.5 - py;
                (dx * dx + dy * dy).sqrt()
            };
            if dist > md + 1.5 {
                continue;
            }

            if tx < vx0 || ty < vy0 || tx + 1 > vx1 || ty + 1 > vy1 {
                continue;
            }
            let p0 = proj[proj_idx(tx, ty)];
            let p1 = proj[proj_idx(tx + 1, ty)];
            let p2 = proj[proj_idx(tx + 1, ty + 1)];
            let p3 = proj[proj_idx(tx, ty + 1)];

            // Cull only tiles that are fully behind the near plane. Partially
            // visible tiles must survive, otherwise indoor ceilings get a top
            // strip hole near the camera.
            let c0 = camera_depth(tx as f32, ty as f32, px, py, cos_a, sin_a);
            let c1 = camera_depth(tx as f32 + 1.0, ty as f32, px, py, cos_a, sin_a);
            let c2 = camera_depth(tx as f32 + 1.0, ty as f32 + 1.0, px, py, cos_a, sin_a);
            let c3 = camera_depth(tx as f32, ty as f32 + 1.0, px, py, cos_a, sin_a);
            if c0 <= FLOOR_NEAR && c1 <= FLOOR_NEAR && c2 <= FLOOR_NEAR && c3 <= FLOOR_NEAR {
                continue;
            }

            let lowered = lowered_floor_at(tx as u32, ty as u32);
            let top_plane = floor_plane + lowered.map(|c| c.depth_offset).unwrap_or(0.0);

            // Per-tile lighting (at center, XCOM-style).
            let tile_cx = tx as f32 + 0.5;
            let tile_cy = ty as f32 + 0.5;
            let ceil_tex = ceiling_texture_at(tx as u32, ty as u32);
            let tile_ambient = if ceil_tex.is_some() {
                params.ambient_light * ROOFED_AMBIENT_FACTOR
            } else {
                params.ambient_light
            };
            let light_rgb = compute_lighting(tile_cx, tile_cy, tile_ambient, lights, wall_at);
            let floor_base = if let Some(cell) = lowered {
                Color::new(cell.tint[0], cell.tint[1], cell.tint[2], 1.0)
            } else {
                params.floor_color
            };
            let floor_light = {
                let c = lit_surface_color(&floor_base, light_rgb, 1.0);
                color_to_light(&c)
            };
            let default_ceil_light = {
                let c = lit_surface_color(&params.ceiling_color, light_rgb, 1.0);
                color_to_light(&c)
            };

            let base_floor_tex = floor_texture_at(tx as u32, ty as u32);
            let floor_tex = lowered.map(|c| c.texture_key).or(base_floor_tex);

            let tp0 = project_horizontal_plane(tx as f32,       ty as f32,       px, py, cos_a, sin_a, proj_dist, sw, horizon, top_plane);
            let tp1 = project_horizontal_plane(tx as f32 + 1.0, ty as f32,       px, py, cos_a, sin_a, proj_dist, sw, horizon, top_plane);
            let tp2 = project_horizontal_plane(tx as f32 + 1.0, ty as f32 + 1.0, px, py, cos_a, sin_a, proj_dist, sw, horizon, top_plane);
            let tp3 = project_horizontal_plane(tx as f32,       ty as f32 + 1.0, px, py, cos_a, sin_a, proj_dist, sw, horizon, top_plane);

            let floor_corners = [
                Vec2::new(tp0.0, tp0.1),
                Vec2::new(tp1.0, tp1.1),
                Vec2::new(tp2.0, tp2.1),
                Vec2::new(tp3.0, tp3.1),
            ];
            let ceil_corners = [
                Vec2::new(p0.sx, p0.ceil_y),
                Vec2::new(p1.sx, p1.ceil_y),
                Vec2::new(p2.sx, p2.ceil_y),
                Vec2::new(p3.sx, p3.ceil_y),
            ];

            floors.push(FloorQuad {
                corners: floor_corners,
                uvs: rect_uvs(),
                texture_key: floor_tex,
                light: floor_light,
                depth: dist,
                corner_w: [tp0.2, tp1.2, tp2.2, tp3.2],
            });

            // Roof tiles (textured ceiling) should be lit identically to the floor.
            let ceil_light = if ceil_tex.is_some() {
                floor_light
            } else {
                default_ceil_light
            };

            ceilings.push(CeilingQuad {
                corners: ceil_corners,
                uvs: rect_uvs(),
                texture_key: ceil_tex,
                light: ceil_light,
                depth: dist,
                corner_w: [p0.cx, p1.cx, p2.cx, p3.cx],
            });

            // Lowered cells expose side faces where a neighbour is higher.
            if let Some(cell) = lowered {
                let top = floor_plane;
                let bottom = floor_plane + cell.depth_offset;
                let side_color = color_to_light(&lit_surface_color(
                    &Color::new(cell.tint[0] * 0.75, cell.tint[1] * 0.75, cell.tint[2] * 0.75, 1.0),
                    light_rgb,
                    1.0,
                ));
                let side_tex = base_floor_tex;
                let neighbour_drop = |nx: i32, ny: i32| lowered_floor_at(nx as u32, ny as u32).map(|c| c.depth_offset).unwrap_or(0.0);
                let render_side = |walls: &mut Vec<WallQuad>,
                                   ax: f32, ay: f32, bx: f32, by: f32,
                                   nx: i32, ny: i32| {
                    let should_render = if nx < 0 || ny < 0 || nx >= map_w || ny >= map_h {
                        true
                    } else if raycaster.get_cell(nx as u32, ny as u32) != 0 {
                        false
                    } else {
                        neighbour_drop(nx, ny) + 1e-4 < cell.depth_offset
                    };
                    if should_render {
                        let ca = camera_depth(ax, ay, px, py, cos_a, sin_a);
                        let cb = camera_depth(bx, by, px, py, cos_a, sin_a);
                        if ca <= FLOOR_NEAR || cb <= FLOOR_NEAR {
                            return;
                        }

                        let pta = project_horizontal_plane(ax, ay, px, py, cos_a, sin_a, proj_dist, sw, horizon, top);
                        let ptb = project_horizontal_plane(bx, by, px, py, cos_a, sin_a, proj_dist, sw, horizon, top);
                        let pba = project_horizontal_plane(ax, ay, px, py, cos_a, sin_a, proj_dist, sw, horizon, bottom);
                        let pbb = project_horizontal_plane(bx, by, px, py, cos_a, sin_a, proj_dist, sw, horizon, bottom);
                        walls.push(WallQuad {
                            corners: [
                                Vec2::new(pta.0, pta.1),
                                Vec2::new(ptb.0, ptb.1),
                                Vec2::new(pbb.0, pbb.1),
                                Vec2::new(pba.0, pba.1),
                            ],
                            uvs: rect_uvs(),
                            texture_key: side_tex,
                            light: side_color,
                            depth: dist + 0.001,
                            corner_w: [pta.2, ptb.2, pbb.2, pba.2],
                            cell_value: 0,
                        });
                    }
                };

                render_side(walls, tx as f32, ty as f32, tx as f32 + 1.0, ty as f32, tx, ty - 1);
                render_side(walls, tx as f32 + 1.0, ty as f32 + 1.0, tx as f32, ty as f32 + 1.0, tx, ty + 1);
                render_side(walls, tx as f32, ty as f32 + 1.0, tx as f32, ty as f32, tx - 1, ty);
                render_side(walls, tx as f32 + 1.0, ty as f32, tx as f32 + 1.0, ty as f32 + 1.0, tx + 1, ty);
            }

            // Roof thickness: draw downward side faces on roof edges so roof
            // appears as a thick slab, analogous to lowered floor thickness.
            if let Some(roof_tex) = ceil_tex {
                let roof_bottom = ceiling_plane;
                let roof_thickness = lowered.map(|c| c.depth_offset).unwrap_or(0.25).clamp(0.05, 0.5);
                let roof_top = roof_bottom - roof_thickness;
                let roof_side_light = floor_light;

                let neighbour_roof_thickness = |nx: i32, ny: i32| -> Option<f32> {
                    if nx < 0 || ny < 0 || nx >= map_w || ny >= map_h {
                        return None;
                    }
                    ceiling_texture_at(nx as u32, ny as u32)
                        .map(|_| lowered_floor_at(nx as u32, ny as u32).map(|c| c.depth_offset).unwrap_or(0.25).clamp(0.05, 0.5))
                };

                let render_roof_side = |walls: &mut Vec<WallQuad>,
                                        ax: f32, ay: f32, bx: f32, by: f32,
                                        nx: i32, ny: i32| {
                    let should_render = match neighbour_roof_thickness(nx, ny) {
                        None => true,
                        Some(t) => t + 1e-4 < roof_thickness,
                    };

                    if should_render {
                        let ca = camera_depth(ax, ay, px, py, cos_a, sin_a);
                        let cb = camera_depth(bx, by, px, py, cos_a, sin_a);
                        if ca <= FLOOR_NEAR || cb <= FLOOR_NEAR {
                            return;
                        }

                        let pta = project_horizontal_plane(ax, ay, px, py, cos_a, sin_a, proj_dist, sw, horizon, roof_top);
                        let ptb = project_horizontal_plane(bx, by, px, py, cos_a, sin_a, proj_dist, sw, horizon, roof_top);
                        let pba = project_horizontal_plane(ax, ay, px, py, cos_a, sin_a, proj_dist, sw, horizon, roof_bottom);
                        let pbb = project_horizontal_plane(bx, by, px, py, cos_a, sin_a, proj_dist, sw, horizon, roof_bottom);

                        walls.push(WallQuad {
                            corners: [
                                Vec2::new(pta.0, pta.1),
                                Vec2::new(ptb.0, ptb.1),
                                Vec2::new(pbb.0, pbb.1),
                                Vec2::new(pba.0, pba.1),
                            ],
                            uvs: rect_uvs(),
                            texture_key: Some(roof_tex),
                            light: roof_side_light,
                            depth: (dist - 0.02).max(0.0),
                            corner_w: [pta.2, ptb.2, pbb.2, pba.2],
                            cell_value: 0,
                        });
                    }
                };

                render_roof_side(walls, tx as f32, ty as f32, tx as f32 + 1.0, ty as f32, tx, ty - 1);
                render_roof_side(walls, tx as f32 + 1.0, ty as f32 + 1.0, tx as f32, ty as f32 + 1.0, tx, ty + 1);
                render_roof_side(walls, tx as f32, ty as f32 + 1.0, tx as f32, ty as f32, tx - 1, ty);
                render_roof_side(walls, tx as f32 + 1.0, ty as f32, tx as f32 + 1.0, ty as f32 + 1.0, tx + 1, ty);
            }
        }
    }
}

#[allow(clippy::too_many_arguments)]
fn build_wall_faces(
    raycaster: &Raycaster2D,
    params: &SceneBuildParams,
    proj_dist: f32,
    lights: &[PointLight],
    wall_at: &dyn Fn(i32, i32) -> bool,
    wall_texture: &dyn Fn(u32) -> Option<TextureKey>,
    ceiling_texture_at: &dyn Fn(u32, u32) -> Option<TextureKey>,
    lowered_floor_at: &dyn Fn(u32, u32) -> Option<LoweredFloorCell>,
    walls: &mut Vec<WallQuad>,
) {
    let horizon = params.screen_height * 0.5 - params.horizon_offset;
    let eye = params.camera_height.clamp(0.1, 0.9);
    let floor_plane = eye;
    let ceiling_plane = -(1.0 - eye);
    let cos_a = params.player_angle.cos();
    let sin_a = params.player_angle.sin();
    let px = params.player_x;
    let py = params.player_y;
    let sw = params.screen_width;
    let md = params.max_distance;
    let map_w = raycaster.width() as i32;
    let map_h = raycaster.height() as i32;

    let vx0 = ((px - md - 2.0).floor() as i32).max(0);
    let vy0 = ((py - md - 2.0).floor() as i32).max(0);
    let vx1 = ((px + md + 2.0).ceil() as i32).min(map_w);
    let vy1 = ((py + md + 2.0).ceil() as i32).min(map_h);
    let proj_w = (vx1 - vx0 + 1).max(0) as usize;
    let proj_h = (vy1 - vy0 + 1).max(0) as usize;
    let mut proj: Vec<ProjectedGroundPoint> = Vec::with_capacity(proj_w * proj_h);
    let proj_idx = |gx: i32, gy: i32| -> usize { ((gy - vy0) as usize) * proj_w + (gx - vx0) as usize };
    for gy in vy0..=vy1 {
        for gx in vx0..=vx1 {
            proj.push(project_ground_point(
                gx as f32,
                gy as f32,
                px,
                py,
                cos_a,
                sin_a,
                proj_dist,
                sw,
                horizon,
                floor_plane,
                ceiling_plane,
            ));
        }
    }

    let maybe_face = |ax: i32, ay: i32, bx: i32, by: i32, cell_value: u32, face_cx: f32, face_cy: f32| -> Option<WallQuad> {
        if ax < vx0 || ay < vy0 || bx < vx0 || by < vy0 || ax > vx1 || ay > vy1 || bx > vx1 || by > vy1 {
            return None;
        }
        let ca = camera_depth(ax as f32, ay as f32, px, py, cos_a, sin_a);
        let cb = camera_depth(bx as f32, by as f32, px, py, cos_a, sin_a);
        if ca <= FLOOR_NEAR || cb <= FLOOR_NEAR {
            return None;
        }

        let pa = proj[proj_idx(ax, ay)];
        let pb = proj[proj_idx(bx, by)];
        let dx = face_cx - px;
        let dy = face_cy - py;
        let depth = (dx * dx + dy * dy).sqrt();
        if depth > md + 2.0 {
            return None;
        }
        let gx = face_cx.floor().clamp(0.0, (map_w - 1) as f32) as u32;
        let gy = face_cy.floor().clamp(0.0, (map_h - 1) as f32) as u32;
        let face_ambient = if ceiling_texture_at(gx, gy).is_some() {
            params.ambient_light * ROOFED_AMBIENT_FACTOR
        } else {
            params.ambient_light
        };
        let light_rgb = compute_lighting(face_cx, face_cy, face_ambient, lights, wall_at);
        let wall_color = lit_surface_color(&Color::WHITE, light_rgb, 1.0);
        Some(WallQuad {
            corners: [
                Vec2::new(pa.sx, pa.ceil_y),
                Vec2::new(pb.sx, pb.ceil_y),
                Vec2::new(pb.sx, pb.floor_y),
                Vec2::new(pa.sx, pa.floor_y),
            ],
            uvs: rect_uvs(),
            texture_key: wall_texture(cell_value),
            light: color_to_light(&wall_color),
            depth,
            corner_w: [pa.cx, pb.cx, pb.cx, pa.cx],
            cell_value,
        })
    };

    for ty in 0..map_h {
        for tx in 0..map_w {
            let cell_value = raycaster.get_cell(tx as u32, ty as u32);
            if cell_value == 0 {
                continue;
            }
            let center_x = tx as f32 + 0.5;
            let center_y = ty as f32 + 0.5;
            let dx = center_x - px;
            let dy = center_y - py;
            if (dx * dx + dy * dy).sqrt() > md + 2.0 {
                continue;
            }

            // North face
            if ty == 0 || raycaster.get_cell(tx as u32, (ty - 1) as u32) == 0 {
                if let Some(face) = maybe_face(tx, ty, tx + 1, ty, cell_value, center_x, ty as f32) {
                    walls.push(face);
                }
            }
            // South face
            if ty == map_h - 1 || raycaster.get_cell(tx as u32, (ty + 1) as u32) == 0 {
                if let Some(face) = maybe_face(tx + 1, ty + 1, tx, ty + 1, cell_value, center_x, ty as f32 + 1.0) {
                    walls.push(face);
                }
            }
            // West face
            if tx == 0 || raycaster.get_cell((tx - 1) as u32, ty as u32) == 0 {
                if let Some(face) = maybe_face(tx, ty + 1, tx, ty, cell_value, tx as f32, center_y) {
                    walls.push(face);
                }
            }
            // East face
            if tx == map_w - 1 || raycaster.get_cell((tx + 1) as u32, ty as u32) == 0 {
                if let Some(face) = maybe_face(tx + 1, ty, tx + 1, ty + 1, cell_value, tx as f32 + 1.0, center_y) {
                    walls.push(face);
                }
            }

            // Roof over wall blocks: render only upward thickness side faces on
            // exposed edges. Do NOT render the flat top cap here â€” the cap is a
            // horizontal quad that projects above open terrain (river, fields)
            // and appears as a "floating block" artefact in the painter sort.
            // The top surface is already covered by the open-floor tile caps
            // rendered in build_floor_tiles.
            if let Some(roof_tex) = ceiling_texture_at(tx as u32, ty as u32) {
                let roof_thickness = lowered_floor_at(tx as u32, ty as u32)
                    .map(|c| c.depth_offset)
                    .unwrap_or(0.25)
                    .clamp(0.05, 0.5);
                let roof_bottom = ceiling_plane;
                let roof_top = roof_bottom - roof_thickness;

                {
                    let wall_ambient = if ceiling_texture_at(tx as u32, ty as u32).is_some() {
                        params.ambient_light * ROOFED_AMBIENT_FACTOR
                    } else {
                        params.ambient_light
                    };
                    let light_rgb = compute_lighting(center_x, center_y, wall_ambient, lights, wall_at);
                    let roof_light = color_to_light(&lit_surface_color(&Color::WHITE, light_rgb, 1.0));

                    let neigh_roof = |nx: i32, ny: i32| -> Option<f32> {
                        if nx < 0 || ny < 0 || nx >= map_w || ny >= map_h {
                            return None;
                        }
                        ceiling_texture_at(nx as u32, ny as u32).map(|_| {
                            lowered_floor_at(nx as u32, ny as u32)
                                .map(|c| c.depth_offset)
                                .unwrap_or(0.25)
                                .clamp(0.05, 0.5)
                        })
                    };

                    let mut render_roof_side = |ax: f32, ay: f32, bx: f32, by: f32, nx: i32, ny: i32| {
                        let should_render = match neigh_roof(nx, ny) {
                            None => true,
                            Some(t) => t + 1e-4 < roof_thickness,
                        };
                        if !should_render {
                            return;
                        }

                        let ca = camera_depth(ax, ay, px, py, cos_a, sin_a);
                        let cb = camera_depth(bx, by, px, py, cos_a, sin_a);
                        if ca <= FLOOR_NEAR || cb <= FLOOR_NEAR {
                            return;
                        }

                        let pta = project_horizontal_plane(ax, ay, px, py, cos_a, sin_a, proj_dist, sw, horizon, roof_top);
                        let ptb = project_horizontal_plane(bx, by, px, py, cos_a, sin_a, proj_dist, sw, horizon, roof_top);
                        let pba = project_horizontal_plane(ax, ay, px, py, cos_a, sin_a, proj_dist, sw, horizon, roof_bottom);
                        let pbb = project_horizontal_plane(bx, by, px, py, cos_a, sin_a, proj_dist, sw, horizon, roof_bottom);
                        walls.push(WallQuad {
                            corners: [
                                Vec2::new(pta.0, pta.1),
                                Vec2::new(ptb.0, ptb.1),
                                Vec2::new(pbb.0, pbb.1),
                                Vec2::new(pba.0, pba.1),
                            ],
                            uvs: rect_uvs(),
                            texture_key: Some(roof_tex),
                            light: roof_light,
                            depth: ((dx * dx + dy * dy).sqrt() - 0.02).max(0.0),
                            corner_w: [pta.2, ptb.2, pbb.2, pba.2],
                            cell_value: 0,
                        });
                    };

                    render_roof_side(tx as f32, ty as f32, tx as f32 + 1.0, ty as f32, tx, ty - 1);
                    render_roof_side(tx as f32 + 1.0, ty as f32 + 1.0, tx as f32, ty as f32 + 1.0, tx, ty + 1);
                    render_roof_side(tx as f32, ty as f32 + 1.0, tx as f32, ty as f32, tx - 1, ty);
                    render_roof_side(tx as f32 + 1.0, ty as f32, tx as f32 + 1.0, ty as f32 + 1.0, tx + 1, ty);
                }
            }
        }
    }
}

fn lit_surface_color(base: &Color, light_rgb: [f32; 3], shade: f32) -> Color {
    Color::new(
        base.r * light_rgb[0] * shade,
        base.g * light_rgb[1] * shade,
        base.b * light_rgb[2] * shade,
        base.a,
    )
}

/// Converts a [`Color`] to an RGBA `[f32; 4]` light array.
fn color_to_light(c: &Color) -> [f32; 4] {
    [c.r, c.g, c.b, c.a]
}

/// Parameters for building a raycaster scene.
///
/// # Fields
/// - `player_x` â€” `f32`. Player world X position.
/// - `player_y` â€” `f32`. Player world Y position.
/// - `player_angle` â€” `f32`. Player facing angle in radians.
/// - `fov` â€” `f32`. Horizontal field of view in radians.
/// - `ray_count` â€” `u32`. Number of rays to cast (screen columns).
/// - `max_distance` â€” `f32`. Maximum ray distance.
/// - `screen_width` â€” `f32`. Screen width in pixels.
/// - `screen_height` â€” `f32`. Screen height in pixels.
/// - `ambient_light` â€” `f32`. Base ambient light level `[0.0, 1.0]`.
/// - `shade_distance` â€” `f32`. Maximum shading distance.
/// - `floor_color` â€” `Color`. Fallback floor colour when no texture.
/// - `ceiling_color` â€” `Color`. Fallback ceiling colour when no texture.
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
    /// Camera eye height in tile units from the floor plane. Typical values:
    /// 2/3 for standing, 1/3 for crouch.
    pub camera_height: f32,
    /// Vertical horizon shift in pixels.  Positive = horizon moves down (tilt up).
    /// Negative = horizon moves up (tilt down / crouch view).
    pub horizon_offset: f32,
}

/// A world-space sprite for scene building.
///
/// # Fields
/// - `world_x` â€” `f32`. Sprite world X.
/// - `world_y` â€” `f32`. Sprite world Y.
/// - `texture_key` â€” `TextureKey`. Sprite texture.
/// - `size` â€” `f32`. Sprite size in world units (used for screen projection).
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

/// Per-cell texture lookup function type. Given `(cell_x, cell_y)`, returns a texture key.
pub type CellTextureLookup = dyn Fn(u32, u32) -> Option<TextureKey>;

impl RaycasterScene {
    /// Builds a complete scene from a raycaster grid with per-polygon lighting.
    ///
    /// Casts rays across the player's FOV, projects wall hits to textured quads,
    /// generates floor/ceiling quads for each column, and projects billboard
    /// sprites. All geometry receives per-polygon lighting computed from the
    /// ambient level and active point lights.
    ///
    /// # Parameters
    /// - `raycaster` â€” `&Raycaster2D`. The grid to raycast against.
    /// - `params` â€” `&SceneBuildParams`. Camera and rendering parameters.
    /// - `lights` â€” `&[PointLight]`. Active point lights in the scene.
    /// - `sprites` â€” `&[WorldSprite]`. World-space sprites to project.
    /// - `wall_texture` â€” `&dyn Fn(u32) -> Option<TextureKey>`. Maps cell values to textures.
    /// - `floor_texture_at` â€” `&dyn Fn(u32, u32) -> Option<TextureKey>`. Maps floor cell coordinates to textures.
    /// - `ceiling_texture_at` â€” `&dyn Fn(u32, u32) -> Option<TextureKey>`. Maps ceiling cell coordinates to textures.
    ///
    /// # Returns
    /// `RaycasterScene`.
    #[allow(clippy::too_many_arguments)]
    pub fn build(
        raycaster: &Raycaster2D,
        params: &SceneBuildParams,
        lights: &[PointLight],
        sprites: &[WorldSprite],
        wall_texture: &dyn Fn(u32) -> Option<TextureKey>,
        floor_texture_at: &dyn Fn(u32, u32) -> Option<TextureKey>,
        ceiling_texture_at: &dyn Fn(u32, u32) -> Option<TextureKey>,
        lowered_floor_at: &dyn Fn(u32, u32) -> Option<LoweredFloorCell>,
    ) -> Self {
        // proj_dist: (screen_width/2) / tan(fov/2) â€” square-tile projection.
        let proj_dist = (params.screen_width * 0.5) / (params.fov * 0.5).tan();

        let mut scene = RaycasterScene::new(params.screen_width, params.screen_height);

        // â”€â”€ Floor and ceiling: per-tile projection (Minecraft-style) â”€â”€â”€â”€â”€â”€â”€â”€â”€
        let wall_at = |x: i32, y: i32| -> bool {
            x < 0 || y < 0 || raycaster.is_blocked(x as u32, y as u32)
        };
        build_floor_tiles(
            raycaster,
            params,
            proj_dist,
            lights,
            &wall_at,
            floor_texture_at,
            ceiling_texture_at,
            lowered_floor_at,
            &mut scene.walls,
            &mut scene.floors,
            &mut scene.ceilings,
        );

        // â”€â”€ Wall quads: exposed block faces (Minecraft-style) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        build_wall_faces(
            raycaster,
            params,
            proj_dist,
            lights,
            &wall_at,
            wall_texture,
            ceiling_texture_at,
            lowered_floor_at,
            &mut scene.walls,
        );

        let eye = params.camera_height.clamp(0.1, 0.9);
        let floor_plane = eye;

        // â”€â”€ Billboard sprites â”€â”€
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
            let horizon = params.screen_height * 0.5 - params.horizon_offset;
            let proj_dist = (params.screen_width * 0.5) / (params.fov * 0.5).tan();
            let base = project_horizontal_plane(
                ws.world_x,
                ws.world_y,
                params.player_x,
                params.player_y,
                params.player_angle.cos(),
                params.player_angle.sin(),
                proj_dist,
                params.screen_width,
                horizon,
                floor_plane,
            );
            let top = project_horizontal_plane(
                ws.world_x,
                ws.world_y,
                params.player_x,
                params.player_y,
                params.player_angle.cos(),
                params.player_angle.sin(),
                proj_dist,
                params.screen_width,
                horizon,
                floor_plane - ws.size,
            );
            let (_, base_y, _) = base;
            let (_, top_y, _) = top;
            let projected_size = (base_y - top_y).abs().max(1.0);

            let gx = ws.world_x.floor().clamp(0.0, (raycaster.width().saturating_sub(1)) as f32) as u32;
            let gy = ws.world_y.floor().clamp(0.0, (raycaster.height().saturating_sub(1)) as f32) as u32;
            let sprite_ambient = if ceiling_texture_at(gx, gy).is_some() {
                params.ambient_light * 0.5
            } else {
                params.ambient_light
            };
            let sprite_light =
                compute_lighting(ws.world_x, ws.world_y, sprite_ambient, lights, &wall_at);
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
                    base_y - projected_size,
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
        scene.sprites.sort_by(|a, b| {
            b.depth
                .partial_cmp(&a.depth)
                .unwrap_or(std::cmp::Ordering::Equal)
        });

        scene
    }
}
