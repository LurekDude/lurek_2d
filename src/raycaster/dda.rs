//! Grid-based raycaster using DDA (Digital Differential Analyzer) traversal.
//!
//! Provides the [`Raycaster2D`] struct for 2D grid-based raycasting used in
//! retro FPS and dungeon-crawler style games. Supports single and multi-ray
//! casting, line-of-sight checks, flat data output, and sprite projection.

use super::ray_hit::RayHit;
use super::sprite_projection::SpriteProjection;

/// 2D grid-based raycaster using DDA traversal.
///
/// The grid stores wall types as `u32` values: 0 = empty, >0 = wall.
/// Coordinates are 0-based with (0,0) at top-left.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `cells` — `Vec<u32>`.
pub struct Raycaster2D {
    width: u32,
    height: u32,
    cells: Vec<u32>,
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
        Self {
            width,
            height,
            cells: vec![0; (width * height) as usize],
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
            if map_x < 0
                || map_y < 0
                || map_x >= self.width as i32
                || map_y >= self.height as i32
            {
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

                return Some(RayHit {
                    distance: perp_dist,
                    raw_distance,
                    cell_value: cell,
                    side,
                    tex_u,
                    hit_x,
                    hit_y,
                    hit: true,
                });
            }
        }
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

            if map_x < 0
                || map_y < 0
                || map_x >= self.width as i32
                || map_y >= self.height as i32
            {
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
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::f32::consts::PI;

    #[test]
    fn test_new_grid_empty() {
        let rc = Raycaster2D::new(8, 8);
        assert_eq!(rc.width(), 8);
        assert_eq!(rc.height(), 8);
        for y in 0..8 {
            for x in 0..8 {
                assert_eq!(rc.get_cell(x, y), 0);
            }
        }
    }

    #[test]
    fn test_set_get_cell() {
        let mut rc = Raycaster2D::new(4, 4);
        rc.set_cell(2, 3, 5);
        assert_eq!(rc.get_cell(2, 3), 5);
        assert!(rc.is_blocked(2, 3));
        assert!(!rc.is_blocked(0, 0));
    }

    #[test]
    fn test_cast_ray_hits_wall() {
        let mut rc = Raycaster2D::new(8, 8);
        rc.set_cell(4, 2, 1); // wall at (4,2)
                               // Cast from (2.5, 2.5) to the right (angle=0)
        let hit = rc.cast_ray(2.5, 2.5, 0.0, 20.0);
        assert!(hit.is_some());
        let h = hit.unwrap();
        assert!(h.hit);
        assert_eq!(h.cell_value, 1);
        assert!((h.distance - 1.5).abs() < 0.1);
    }

    #[test]
    fn test_cast_ray_misses() {
        let rc = Raycaster2D::new(8, 8);
        // empty grid, ray goes right and exits
        let hit = rc.cast_ray(1.5, 1.5, 0.0, 5.0);
        assert!(hit.is_none());
    }

    #[test]
    fn test_line_of_sight_clear() {
        let rc = Raycaster2D::new(8, 8);
        assert!(rc.line_of_sight(1.5, 1.5, 6.5, 6.5));
    }

    #[test]
    fn test_line_of_sight_blocked() {
        let mut rc = Raycaster2D::new(8, 8);
        rc.set_cell(3, 3, 1);
        assert!(!rc.line_of_sight(1.5, 1.5, 6.5, 6.5));
    }

    #[test]
    fn test_cast_rays_count() {
        let mut rc = Raycaster2D::new(8, 8);
        // Surround with walls
        for i in 0..8 {
            rc.set_cell(i, 0, 1);
            rc.set_cell(i, 7, 1);
            rc.set_cell(0, i, 1);
            rc.set_cell(7, i, 1);
        }
        let rays = rc.cast_rays(4.0, 4.0, 0.0, PI / 3.0, 10, 20.0);
        assert_eq!(rays.len(), 10);
    }

    #[test]
    fn test_cast_rays_flat_layout() {
        let mut rc = Raycaster2D::new(8, 8);
        for i in 0..8 {
            rc.set_cell(i, 0, 1);
            rc.set_cell(i, 7, 1);
            rc.set_cell(0, i, 1);
            rc.set_cell(7, i, 1);
        }
        let flat = rc.cast_rays_flat(4.0, 4.0, 0.0, PI / 3.0, 5, 20.0);
        assert_eq!(flat.len(), 25); // 5 rays * 5 values
    }

    #[test]
    fn test_sprite_projection_behind() {
        let rc = Raycaster2D::new(8, 8);
        let proj = rc.project_sprite(3.0, 3.0, 5.0, 5.0, 0.0, PI / 3.0, 320.0);
        // Sprite is behind or to the side depending on angle
        // At angle 0, sprite at (3,3) from (5,5) has dx=-2, dy=-2,
        // transform_y = -(-2)*sin(0) + (-2)*cos(0) = -2, so not visible
        assert!(!proj.visible);
    }
}
