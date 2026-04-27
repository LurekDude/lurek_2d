//! Grid-based raycaster using DDA (Digital Differential Analyzer) traversal.
//!
//! Provides the [`Raycaster2D`] struct for 2D grid-based raycasting used in
//! retro FPS and dungeon-crawler style games. Supports single and multi-ray
//! casting, line-of-sight checks, flat data output, and sprite projection.

use std::collections::HashMap;

use super::ray_hit::RayHit;
use super::sprite_projection::SpriteProjection;
use crate::log_msg;
use crate::runtime::log_messages::RC01;

/// 2D grid-based raycaster using DDA traversal.
///
/// The grid stores wall types as `u32` values: 0 = empty, >0 = wall.
/// Coordinates are 0-based with (0,0) at top-left.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `cells` — `Vec<u32>`.
/// - `wall_alphas` — `HashMap<u8, f32>`. Per-tile alpha override for translucent walls.
pub struct Raycaster2D {
    width: u32,
    height: u32,
    cells: Vec<u32>,
    /// Per-tile opacity map. Keys are tile type values (as `u8`); values are
    /// alpha in `[0.0, 1.0]`. Tiles absent from the map default to `1.0` (opaque).
    wall_alphas: HashMap<u8, f32>,
}

impl Raycaster2D {
    /// Creates a new raycaster grid with all cells empty.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32) -> Self {
        log_msg!(debug, RC01, "{}x{}", width, height);
        Self {
            width,
            height,
            cells: vec![0; (width * height) as usize],
            wall_alphas: HashMap::new(),
        }
    }

    /// Sets the value of a cell at (x, y). 0-based coordinates.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `value` — `u32`.
    pub fn set_cell(&mut self, x: u32, y: u32, value: u32) {
        if x < self.width && y < self.height {
            self.cells[(y * self.width + x) as usize] = value;
        }
    }

    /// Gets the value of a cell at (x, y). Returns 0 for out-of-bounds.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_cell(&self, x: u32, y: u32) -> u32 {
        if x < self.width && y < self.height {
            self.cells[(y * self.width + x) as usize]
        } else {
            0
        }
    }

    /// Bulk-sets all cells from a flat vector. Length must match width*height.
    ///
    /// # Parameters
    /// - `data` — `Vec<u32>`.
    pub fn set_cells(&mut self, data: Vec<u32>) {
        if data.len() == (self.width * self.height) as usize {
            self.cells = data;
        }
    }

    /// Returns true if the cell at (x, y) is blocked (value > 0).
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_blocked(&self, x: u32, y: u32) -> bool {
        self.get_cell(x, y) > 0
    }

    /// Returns the grid width.
    ///
    /// # Returns
    /// `u32`.
    pub fn width(&self) -> u32 {
        self.width
    }

    /// Returns the grid height.
    ///
    /// # Returns
    /// `u32`.
    pub fn height(&self) -> u32 {
        self.height
    }

    /// Returns a reference to the internal cell data.
    ///
    /// # Returns
    /// `&[u32]`.
    pub fn cells(&self) -> &[u32] {
        &self.cells
    }

    /// Sets the opacity for a wall tile type. Alpha is clamped to `[0.0, 1.0]`.
    ///
    /// A tile with alpha < 1.0 is treated as translucent: rays continue through
    /// it when [`cast_ray_multi`] is used, collecting up to `max_hits` layers.
    ///
    /// # Parameters
    /// - `tile_type` — `u8`. Wall type value stored in the cell grid.
    /// - `alpha` — `f32`. Opacity in `[0.0, 1.0]`.
    pub fn set_wall_alpha(&mut self, tile_type: u8, alpha: f32) {
        self.wall_alphas.insert(tile_type, alpha.clamp(0.0, 1.0));
    }

    /// Returns the opacity for a wall tile type.
    ///
    /// Returns `1.0` (fully opaque) for tile types not registered via
    /// [`set_wall_alpha`].
    ///
    /// # Parameters
    /// - `tile_type` — `u8`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_wall_alpha(&self, tile_type: u8) -> f32 {
        self.wall_alphas.get(&tile_type).copied().unwrap_or(1.0)
    }

    /// Casts a single ray from (ox, oy) at the given angle using the DDA algorithm.
    ///
    /// # Parameters
    /// - `ox` — `f32`.
    /// - `oy` — `f32`.
    /// - `angle` — `f32`.
    /// - `max_dist` — `f32`.
    ///
    /// # Returns
    /// `Option<RayHit>`.
    ///
    /// Returns `Some(RayHit)` if a wall is hit within `max_dist`, otherwise `None`.
    pub fn cast_ray(&self, ox: f32, oy: f32, angle: f32, max_dist: f32) -> Option<RayHit> {
        let dir_x = angle.cos();
        let dir_y = angle.sin();

        // Current map cell
        let mut map_x = ox.floor() as i32;
        let mut map_y = oy.floor() as i32;

        // Length of ray from one x/y side to next
        let delta_dist_x = if dir_x.abs() < 1e-10 {
            f32::MAX
        } else {
            (1.0 / dir_x).abs()
        };
        let delta_dist_y = if dir_y.abs() < 1e-10 {
            f32::MAX
        } else {
            (1.0 / dir_y).abs()
        };

        // Step direction and initial side distances
        let (step_x, mut side_dist_x) = if dir_x < 0.0 {
            (-1, (ox - map_x as f32) * delta_dist_x)
        } else {
            (1, (map_x as f32 + 1.0 - ox) * delta_dist_x)
        };
        let (step_y, mut side_dist_y) = if dir_y < 0.0 {
            (-1, (oy - map_y as f32) * delta_dist_y)
        } else {
            (1, (map_y as f32 + 1.0 - oy) * delta_dist_y)
        };

        let mut side: u8;

        loop {
            // Step to next cell boundary
            if side_dist_x < side_dist_y {
                side_dist_x += delta_dist_x;
                map_x += step_x;
                side = 0;
            } else {
                side_dist_y += delta_dist_y;
                map_y += step_y;
                side = 1;
            }

            // Compute perpendicular distance
            let perp_dist = if side == 0 {
                side_dist_x - delta_dist_x
            } else {
                side_dist_y - delta_dist_y
            };

            if perp_dist > max_dist {
                return None;
            }

            // Check bounds
            if map_x < 0 || map_y < 0 || map_x >= self.width as i32 || map_y >= self.height as i32 {
                return None;
            }

            let cell = self.cells[(map_y as u32 * self.width + map_x as u32) as usize];
            if cell > 0 {
                let hit_x = ox + dir_x * perp_dist;
                let hit_y = oy + dir_y * perp_dist;

                let tex_u = if side == 0 {
                    (hit_y - hit_y.floor()).abs()
                } else {
                    (hit_x - hit_x.floor()).abs()
                };

                let raw_distance = perp_dist; // same when single ray
                let alpha = self.wall_alphas.get(&(cell as u8)).copied().unwrap_or(1.0);

                return Some(RayHit {
                    distance: perp_dist,
                    raw_distance,
                    cell_value: cell,
                    alpha,
                    side,
                    tex_u,
                    hit_x,
                    hit_y,
                    hit: true,
                });
            }
        }
    }

    /// Casts a ray and collects up to `max_hits` wall hits, continuing through
    /// translucent walls (alpha < 1.0) registered via [`set_wall_alpha`].
    ///
    /// Opaque walls (alpha == 1.0) stop the ray immediately. Translucent walls
    /// are recorded and the ray continues. The returned vector is ordered nearest
    /// to farthest.
    ///
    /// # Parameters
    /// - `ox` — `f32`.
    /// - `oy` — `f32`.
    /// - `angle` — `f32`.
    /// - `max_dist` — `f32`.
    /// - `max_hits` — `u32`. Maximum wall layers to collect (capped at 8).
    ///
    /// # Returns
    /// `Vec<RayHit>`.
    pub fn cast_ray_multi(
        &self,
        ox: f32,
        oy: f32,
        angle: f32,
        max_dist: f32,
        max_hits: u32,
    ) -> Vec<RayHit> {
        let cap = (max_hits as usize).min(8);
        let mut hits: Vec<RayHit> = Vec::with_capacity(cap);

        let dir_x = angle.cos();
        let dir_y = angle.sin();

        let mut map_x = ox.floor() as i32;
        let mut map_y = oy.floor() as i32;

        let delta_dist_x = if dir_x.abs() < 1e-10 {
            f32::MAX
        } else {
            (1.0 / dir_x).abs()
        };
        let delta_dist_y = if dir_y.abs() < 1e-10 {
            f32::MAX
        } else {
            (1.0 / dir_y).abs()
        };

        let (step_x, mut side_dist_x) = if dir_x < 0.0 {
            (-1, (ox - map_x as f32) * delta_dist_x)
        } else {
            (1, (map_x as f32 + 1.0 - ox) * delta_dist_x)
        };
        let (step_y, mut side_dist_y) = if dir_y < 0.0 {
            (-1, (oy - map_y as f32) * delta_dist_y)
        } else {
            (1, (map_y as f32 + 1.0 - oy) * delta_dist_y)
        };

        loop {
            if side_dist_x < side_dist_y {
                side_dist_x += delta_dist_x;
                map_x += step_x;
                let perp_dist = side_dist_x - delta_dist_x;
                if perp_dist > max_dist {
                    break;
                }
                if map_x < 0
                    || map_x >= self.width as i32
                    || map_y < 0
                    || map_y >= self.height as i32
                {
                    break;
                }
                let cell = self.cells[(map_y as u32 * self.width + map_x as u32) as usize];
                if cell > 0 {
                    let alpha = self.wall_alphas.get(&(cell as u8)).copied().unwrap_or(1.0);
                    let hit_x = ox + dir_x * perp_dist;
                    let hit_y = oy + dir_y * perp_dist;
                    let tex_u = (hit_y - hit_y.floor()).abs();
                    hits.push(RayHit {
                        distance: perp_dist,
                        raw_distance: perp_dist,
                        cell_value: cell,
                        alpha,
                        side: 0,
                        tex_u,
                        hit_x,
                        hit_y,
                        hit: true,
                    });
                    if alpha >= 1.0 || hits.len() >= cap {
                        break;
                    }
                }
            } else {
                side_dist_y += delta_dist_y;
                map_y += step_y;
                let perp_dist = side_dist_y - delta_dist_y;
                if perp_dist > max_dist {
                    break;
                }
                if map_y < 0
                    || map_y >= self.height as i32
                    || map_x < 0
                    || map_x >= self.width as i32
                {
                    break;
                }
                let cell = self.cells[(map_y as u32 * self.width + map_x as u32) as usize];
                if cell > 0 {
                    let alpha = self.wall_alphas.get(&(cell as u8)).copied().unwrap_or(1.0);
                    let hit_x = ox + dir_x * perp_dist;
                    let hit_y = oy + dir_y * perp_dist;
                    let tex_u = (hit_x - hit_x.floor()).abs();
                    hits.push(RayHit {
                        distance: perp_dist,
                        raw_distance: perp_dist,
                        cell_value: cell,
                        alpha,
                        side: 1,
                        tex_u,
                        hit_x,
                        hit_y,
                        hit: true,
                    });
                    if alpha >= 1.0 || hits.len() >= cap {
                        break;
                    }
                }
            }
        }

        hits
    }

    /// Casts multiple rays spread across a field of view.
    ///
    /// # Parameters
    /// - `ox` — `f32`.
    /// - `oy` — `f32`.
    /// - `angle` — `f32`.
    /// - `fov` — `f32`.
    /// - `count` — `u32`.
    /// - `max_dist` — `f32`.
    ///
    /// # Returns
    /// `Vec<RayHit>`.
    ///
    /// Returns a `Vec<RayHit>` with `count` entries (misses have `hit = false`).
    /// Applies fisheye correction (perpendicular distance).
    pub fn cast_rays(
        &self,
        ox: f32,
        oy: f32,
        angle: f32,
        fov: f32,
        count: u32,
        max_dist: f32,
    ) -> Vec<RayHit> {
        let mut results = Vec::with_capacity(count as usize);
        let half_fov = fov / 2.0;

        for i in 0..count {
            let ray_angle = if count > 1 {
                angle - half_fov + fov * (i as f32) / (count - 1) as f32
            } else {
                angle
            };

            let angle_diff = ray_angle - angle;

            match self.cast_ray(ox, oy, ray_angle, max_dist) {
                Some(mut hit) => {
                    hit.raw_distance = hit.distance;
                    hit.distance *= angle_diff.cos(); // fisheye correction
                    results.push(hit);
                }
                None => {
                    results.push(RayHit {
                        distance: max_dist,
                        raw_distance: max_dist,
                        cell_value: 0,
                        alpha: 1.0,
                        side: 0,
                        tex_u: 0.0,
                        hit_x: ox + ray_angle.cos() * max_dist,
                        hit_y: oy + ray_angle.sin() * max_dist,
                        hit: false,
                    });
                }
            }
        }

        results
    }

    /// Casts multiple rays and returns a flat `Vec<f32>` with 5 values per ray.
    ///
    /// # Parameters
    /// - `ox` — `f32`.
    /// - `oy` — `f32`.
    /// - `angle` — `f32`.
    /// - `fov` — `f32`.
    /// - `count` — `u32`.
    /// - `max_dist` — `f32`.
    ///
    /// # Returns
    /// `Vec<f32>`.
    ///
    /// Per-ray layout: `[distance, cell_value, side, tex_u, hit(0/1)]`.
    pub fn cast_rays_flat(
        &self,
        ox: f32,
        oy: f32,
        angle: f32,
        fov: f32,
        count: u32,
        max_dist: f32,
    ) -> Vec<f32> {
        let hits = self.cast_rays(ox, oy, angle, fov, count, max_dist);
        let mut flat = Vec::with_capacity(hits.len() * 5);
        for h in &hits {
            flat.push(h.distance);
            flat.push(h.cell_value as f32);
            flat.push(h.side as f32);
            flat.push(h.tex_u);
            flat.push(if h.hit { 1.0 } else { 0.0 });
        }
        flat
    }

    /// Checks line of sight between two points using DDA traversal.
    ///
    /// # Parameters
    /// - `x1` — `f32`.
    /// - `y1` — `f32`.
    /// - `x2` — `f32`.
    /// - `y2` — `f32`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `true` if no walls block the path.
    pub fn line_of_sight(&self, x1: f32, y1: f32, x2: f32, y2: f32) -> bool {
        let dx = x2 - x1;
        let dy = y2 - y1;
        let dist = (dx * dx + dy * dy).sqrt();
        if dist < 1e-6 {
            return true;
        }

        let dir_x = dx / dist;
        let dir_y = dy / dist;

        let mut map_x = x1.floor() as i32;
        let mut map_y = y1.floor() as i32;
        let end_x = x2.floor() as i32;
        let end_y = y2.floor() as i32;

        let delta_dist_x = if dir_x.abs() < 1e-10 {
            f32::MAX
        } else {
            (1.0 / dir_x).abs()
        };
        let delta_dist_y = if dir_y.abs() < 1e-10 {
            f32::MAX
        } else {
            (1.0 / dir_y).abs()
        };

        let (step_x, mut side_dist_x) = if dir_x < 0.0 {
            (-1, (x1 - map_x as f32) * delta_dist_x)
        } else {
            (1, (map_x as f32 + 1.0 - x1) * delta_dist_x)
        };
        let (step_y, mut side_dist_y) = if dir_y < 0.0 {
            (-1, (y1 - map_y as f32) * delta_dist_y)
        } else {
            (1, (map_y as f32 + 1.0 - y1) * delta_dist_y)
        };

        loop {
            if map_x == end_x && map_y == end_y {
                return true;
            }

            if side_dist_x < side_dist_y {
                side_dist_x += delta_dist_x;
                map_x += step_x;
            } else {
                side_dist_y += delta_dist_y;
                map_y += step_y;
            }

            if map_x < 0 || map_y < 0 || map_x >= self.width as i32 || map_y >= self.height as i32 {
                return true; // left grid = no wall hit
            }

            if self.cells[(map_y as u32 * self.width + map_x as u32) as usize] > 0 {
                // Check if we've passed the endpoint
                let perp = if side_dist_x - delta_dist_x < side_dist_y - delta_dist_y {
                    side_dist_x - delta_dist_x
                } else {
                    side_dist_y - delta_dist_y
                };
                if perp >= dist {
                    return true;
                }
                return false;
            }
        }
    }

    /// Projects a world-space sprite onto screen space.
    ///
    /// # Parameters
    /// - `sx` — `f32`.
    /// - `sy` — `f32`.
    /// - `px` — `f32`.
    /// - `py` — `f32`.
    /// - `pa` — `f32`.
    /// - `fov` — `f32`.
    /// - `screen_w` — `f32`.
    ///
    /// # Returns
    /// `SpriteProjection`.
    ///
    /// Returns a `SpriteProjection` indicating where and how large to draw the sprite.
    #[allow(clippy::too_many_arguments)]
    pub fn project_sprite(
        &self,
        sx: f32,
        sy: f32,
        px: f32,
        py: f32,
        pa: f32,
        fov: f32,
        screen_w: f32,
    ) -> SpriteProjection {
        let dx = sx - px;
        let dy = sy - py;

        let cos_a = pa.cos();
        let sin_a = pa.sin();

        // Transform sprite relative to camera
        let transform_x = dx * cos_a + dy * sin_a;
        let transform_y = -dx * sin_a + dy * cos_a;

        if transform_y <= 0.0 {
            return SpriteProjection {
                screen_x: 0.0,
                scale: 0.0,
                distance: (dx * dx + dy * dy).sqrt(),
                visible: false,
            };
        }

        let half_fov_tan = (fov / 2.0).tan();
        let screen_x = (screen_w / 2.0) * (1.0 + transform_x / (transform_y * half_fov_tan));
        let scale = 1.0 / transform_y;

        SpriteProjection {
            screen_x,
            scale,
            distance: transform_y,
            visible: true,
        }
    }

    /// Computes floor (or ceiling) texture coordinates for one horizontal screen row.
    ///
    /// Uses the Lode Vermeers floor-casting formula.  For every pixel column in
    /// `row`, the function returns the corresponding `(tex_u, tex_v)` pair in
    /// normalised texture space `[0.0, 1.0)`.  Callers can multiply by their
    /// texture width/height to obtain texel indices.
    ///
    /// Rows below the screen centre are floor rows; rows above are ceiling rows.
    /// Passing `row = self.height() as i32 / 2` returns zeros for every column
    /// (the exact horizon line).
    ///
    /// # Parameters
    /// - `cam_x` — `f32` — camera X position in cell coordinates.
    /// - `cam_y` — `f32` — camera Y position in cell coordinates.
    /// - `dir_x` — `f32` — camera direction X (normalised).
    /// - `dir_y` — `f32` — camera direction Y (normalised).
    /// - `plane_x` — `f32` — camera plane X (half-FOV vector).
    /// - `plane_y` — `f32` — camera plane Y (half-FOV vector).
    /// - `row` — `i32` — screen row to generate (0 = top of screen).
    ///
    /// # Returns
    /// `Vec<(f32, f32)>` — one `(tex_u, tex_v)` per pixel column;
    /// length equals `self.width()`.
    #[allow(clippy::too_many_arguments)]
    pub fn cast_floor_row(
        &self,
        cam_x: f32,
        cam_y: f32,
        dir_x: f32,
        dir_y: f32,
        plane_x: f32,
        plane_y: f32,
        row: i32,
    ) -> Vec<(f32, f32)> {
        let w = self.width as i32;
        let h = self.height as i32;
        let half_h = h / 2;
        let p = row - half_h; // pixels below (positive) or above (negative) the horizon

        // At the exact horizon there is no perspective depth — return zeros.
        if p == 0 {
            return vec![(0.0, 0.0); w as usize];
        }

        // Perpendicular distance to the floor plane from the camera (height = 0.5).
        let row_distance = 0.5 * h as f32 / p.abs() as f32;

        // Step in world-space per screen pixel column.
        let floor_step_x = row_distance * (dir_x + plane_x - (dir_x - plane_x)) / w as f32;
        let floor_step_y = row_distance * (dir_y + plane_y - (dir_y - plane_y)) / w as f32;

        // World-space position of the leftmost pixel in this row.
        let mut floor_x = cam_x + row_distance * (dir_x - plane_x);
        let mut floor_y = cam_y + row_distance * (dir_y - plane_y);

        let mut result = Vec::with_capacity(w as usize);
        for _ in 0..w {
            // Fractional part = normalised texture coordinate in [0, 1).
            let tx = floor_x - floor_x.floor();
            let ty = floor_y - floor_y.floor();
            floor_x += floor_step_x;
            floor_y += floor_step_y;
            result.push((tx, ty));
        }
        log::debug!(
            "raycaster: cast_floor_row row={row} → {} samples",
            result.len()
        );
        result
    }
}
