//! Grid-based raycaster using DDA (Digital Differential Analyzer) traversal.
//!
//! Provides the [`Raycaster2D`] struct for 2D grid-based raycasting used in
//! retro FPS and dungeon-crawler style games. Supports single and multi-ray
//! casting, line-of-sight checks, flat data output, and sprite projection.

use super::ray_hit::RayHit;
use super::sprite_projection::SpriteProjection;
use crate::runtime::log_messages::RC01;
use crate::log_msg;

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
        log_msg!(debug, RC01, "{}x{}", width, height);
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

    // ------------------------------------------------------------------
    // Visualization
    // ------------------------------------------------------------------

    /// Render a top-down map view to an image.
    ///
    /// Each cell is drawn as a `scale × scale` block. Wall cells are colored
    /// by their cell value, empty cells use the dark background color.
    /// The player position is marked with a yellow circle and rays are cast
    /// in all directions to show the line-of-sight fan.
    ///
    /// # Parameters
    /// - `player_x` — `f32`. Player X position in cell coordinates.
    /// - `player_y` — `f32`. Player Y position in cell coordinates.
    /// - `player_angle` — `f32`. Player look direction in radians.
    /// - `scale` — `u32`. Pixel size of each grid cell.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_top_down_to_image(
        &self,
        player_x: f32,
        player_y: f32,
        player_angle: f32,
        scale: u32,
    ) -> crate::image::ImageData {
        let _ = player_angle; // reserved for future directional indicator
        let mut img = crate::image::ImageData::new(self.width * scale, self.height * scale);
        img.fill(40, 40, 50, 255);
        for y in 0..self.height {
            for x in 0..self.width {
                let cell = self.get_cell(x, y);
                if cell > 0 {
                    let (r, g, b) = match cell {
                        1 => (120u8, 120u8, 130u8),
                        2 => (180, 80, 80),
                        3 => (80, 80, 180),
                        _ => (200, 200, 200),
                    };
                    for py in 0..scale {
                        for px in 0..scale {
                            img.set_pixel(x * scale + px, y * scale + py, r, g, b, 255);
                        }
                    }
                }
            }
        }
        // Draw player
        img.draw_circle(
            (player_x * scale as f32) as i32,
            (player_y * scale as f32) as i32,
            4, 255, 255, 0, 255,
        );
        // Cast rays in all directions
        for angle_deg in (0..360).step_by(15) {
            let angle = (angle_deg as f32).to_radians();
            if let Some(hit) = self.cast_ray(player_x, player_y, angle, 20.0) {
                let ex = (hit.hit_x * scale as f32) as i32;
                let ey = (hit.hit_y * scale as f32) as i32;
                img.draw_line(
                    (player_x * scale as f32) as i32,
                    (player_y * scale as f32) as i32,
                    ex, ey, 255, 200, 0, 180,
                );
            }
        }
        img
    }

    /// Render a first-person column view to an image.
    ///
    /// Casts `width` rays across the given FOV from the player position and
    /// draws vertical wall columns with distance-based shading. A sky gradient
    /// fills the top half and a floor gradient fills the bottom half.
    ///
    /// # Parameters
    /// - `player_x` — `f32`. Player X in cell coordinates.
    /// - `player_y` — `f32`. Player Y in cell coordinates.
    /// - `angle` — `f32`. Look direction in radians.
    /// - `fov` — `f32`. Field of view in radians.
    /// - `width` — `u32`. Output image width (one ray per column).
    /// - `height` — `u32`. Output image height.
    /// - `max_dist` — `f32`. Maximum ray distance.
    ///
    /// # Returns
    /// `ImageData`.
    #[allow(clippy::too_many_arguments)]
    pub fn draw_view_to_image(
        &self,
        player_x: f32,
        player_y: f32,
        angle: f32,
        fov: f32,
        width: u32,
        height: u32,
        max_dist: f32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        let half_h = height / 2;
        // Sky gradient
        for y in 0..half_h {
            let t = y as f32 / half_h as f32;
            let r = (20.0 + t * 30.0) as u8;
            let g = (30.0 + t * 40.0) as u8;
            let b = (80.0 + t * 100.0) as u8;
            for x in 0..width {
                img.set_pixel(x, y, r, g, b, 255);
            }
        }
        // Floor gradient
        for y in half_h..height {
            let t = (y - half_h) as f32 / half_h as f32;
            let g = (80.0 - t * 40.0) as u8;
            for x in 0..width {
                img.set_pixel(x, y, g + 30, g + 10, g / 2 + 10, 255);
            }
        }
        // Cast rays and draw wall columns
        let rays = self.cast_rays(player_x, player_y, angle, fov, width, max_dist);
        for (x, hit) in rays.iter().enumerate() {
            if hit.hit {
                let wall_h = (height as f32 / hit.distance.max(0.1)) as i32;
                let top = half_h as i32 - wall_h / 2;
                let bot = half_h as i32 + wall_h / 2;
                let shade = (1.0f32 - hit.distance / max_dist).max(0.15);
                let (cr, cg, cb) = match hit.cell_value {
                    1 => (200u8, 80, 80),
                    2 => (80, 180, 80),
                    3 => (80, 100, 200),
                    4 => (200, 180, 60),
                    5 => (180, 80, 200),
                    _ => (150, 150, 150),
                };
                let r = (cr as f32 * shade) as u8;
                let g = (cg as f32 * shade) as u8;
                let b = (cb as f32 * shade) as u8;
                img.draw_line(
                    x as i32, top.max(0),
                    x as i32, bot.min(height as i32 - 1),
                    r, g, b, 255,
                );
            }
        }
        img
    }

    /// Render a depth-map column view with sky gradient and cell-value coloring.
    ///
    /// Casts `num_rays` across the given FOV and draws shaded wall columns
    /// colored by cell value against a sky gradient background.
    ///
    /// # Parameters
    /// - `player_x` — `f32`. Player X in cell coordinates.
    /// - `player_y` — `f32`. Player Y in cell coordinates.
    /// - `player_angle` — `f32`. Look direction in radians.
    /// - `fov` — `f32`. Field of view in radians.
    /// - `num_rays` — `u32`. Number of columns.
    /// - `width` — `u32`. Output image width.
    /// - `height` — `u32`. Output image height.
    /// - `max_dist` — `f32`. Maximum ray distance.
    ///
    /// # Returns
    /// `ImageData`.
    #[allow(clippy::too_many_arguments)]
    pub fn draw_depth_map_to_image(
        &self,
        player_x: f32,
        player_y: f32,
        player_angle: f32,
        fov: f32,
        num_rays: u32,
        width: u32,
        height: u32,
        max_dist: f32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 20, 30, 255);
        let half = height / 2;
        // Sky gradient
        for y in 0..half {
            let t = y as f32 / half as f32;
            let r = (30.0 + t * 50.0) as u8;
            let g = (50.0 + t * 80.0) as u8;
            let b = (120.0 + t * 80.0) as u8;
            for x in 0..width {
                img.set_pixel(x, y, r, g, b, 255);
            }
        }
        for i in 0..num_rays {
            let ray_angle = player_angle - fov / 2.0 + (i as f32 / num_rays as f32) * fov;
            if let Some(hit) = self.cast_ray(player_x, player_y, ray_angle, max_dist) {
                let dist = hit.distance.max(0.1);
                let wall_h = ((height as f32 / dist) * 2.0).min(height as f32) as u32;
                let top = half.saturating_sub(wall_h / 2);
                let shade = ((1.0 - dist / max_dist).max(0.0) * 255.0) as u8;
                let (r, g, b) = match hit.cell_value {
                    1 => (shade, shade, shade),
                    2 => (shade, shade / 2, shade / 3),
                    3 => (shade / 3, shade / 2, shade),
                    _ => (shade, shade, shade),
                };
                for y in top..(top + wall_h).min(height) {
                    img.set_pixel(i.min(width - 1), y, r, g, b, 255);
                }
            }
        }
        img
    }

    /// Render a line-of-sight test between two points overlaid on the grid.
    ///
    /// Draws walls as filled blocks, performs a LOS check between `(ax,ay)`
    /// and `(bx,by)`, and draws the connecting line green (visible) or red
    /// (blocked) with endpoint markers.
    ///
    /// # Parameters
    /// - `ax` — `f32`. Start X in cell coordinates.
    /// - `ay` — `f32`. Start Y in cell coordinates.
    /// - `bx` — `f32`. End X in cell coordinates.
    /// - `by` — `f32`. End Y in cell coordinates.
    /// - `scale` — `u32`. Pixel size per grid cell.
    ///
    /// # Returns
    /// `ImageData`.
    #[allow(clippy::too_many_arguments)]
    pub fn draw_line_of_sight_to_image(
        &self,
        ax: f32,
        ay: f32,
        bx: f32,
        by: f32,
        scale: u32,
    ) -> crate::image::ImageData {
        let mut img =
            crate::image::ImageData::new(self.width * scale, self.height * scale);
        img.fill(40, 40, 50, 255);
        // Draw walls
        for y in 0..self.height {
            for x in 0..self.width {
                if self.get_cell(x, y) > 0 {
                    for py in 0..scale {
                        for px in 0..scale {
                            img.set_pixel(
                                x * scale + px,
                                y * scale + py,
                                120, 120, 130, 255,
                            );
                        }
                    }
                }
            }
        }
        let can_see = self.line_of_sight(ax, ay, bx, by);
        let color = if can_see { (0u8, 255u8, 0u8) } else { (255u8, 0u8, 0u8) };
        img.draw_line(
            (ax * scale as f32) as i32,
            (ay * scale as f32) as i32,
            (bx * scale as f32) as i32,
            (by * scale as f32) as i32,
            color.0, color.1, color.2, 200,
        );
        img.draw_circle(
            (ax * scale as f32) as i32,
            (ay * scale as f32) as i32,
            4, 0, 255, 255, 255,
        );
        img.draw_circle(
            (bx * scale as f32) as i32,
            (by * scale as f32) as i32,
            4, 255, 255, 0, 255,
        );
        img
    }

    /// Render a mosaic of first-person views from evenly-spaced angles.
    ///
    /// Creates `num_frames` views arranged in a 4-column grid, each
    /// `frame_w × frame_h` pixels, sweeping the camera through a full
    /// rotation around `(x, y)`.
    ///
    /// # Parameters
    /// - `x` — `f32`. Player X in cell coordinates.
    /// - `y` — `f32`. Player Y in cell coordinates.
    /// - `fov` — `f32`. Field of view in radians.
    /// - `max_dist` — `f32`. Maximum ray distance.
    /// - `num_frames` — `u32`. Number of views.
    /// - `frame_w` — `u32`. Width of each view.
    /// - `frame_h` — `u32`. Height of each view.
    ///
    /// # Returns
    /// `ImageData`.
    #[allow(clippy::too_many_arguments)]
    pub fn draw_camera_sweep_to_image(
        &self,
        x: f32,
        y: f32,
        fov: f32,
        max_dist: f32,
        num_frames: u32,
        frame_w: u32,
        frame_h: u32,
    ) -> crate::image::ImageData {
        let cols = 4u32;
        let rows = num_frames.div_ceil(cols);
        let mut img = crate::image::ImageData::new(cols * frame_w, rows * frame_h);
        img.fill(15, 15, 25, 255);
        for frame in 0..num_frames {
            let angle = frame as f32 * std::f32::consts::TAU / num_frames as f32;
            let col = frame % cols;
            let row = frame / cols;
            let ox = col * frame_w;
            let oy = row * frame_h;
            let rays = self.cast_rays(x, y, angle, fov, frame_w, max_dist);
            for (rx, hit) in rays.iter().enumerate() {
                if hit.hit {
                    let wall_h = (frame_h as f32 / hit.distance.max(0.1)) as i32;
                    let mid = frame_h as i32 / 2;
                    let top = mid - wall_h / 2;
                    let bot = mid + wall_h / 2;
                    let shade = (1.0 - hit.distance / max_dist).max(0.1);
                    let r = (180.0 * shade) as u8;
                    let g = (120.0 * shade) as u8;
                    let b = (255.0 * shade) as u8;
                    let px = (ox as i32 + rx as i32).min((ox + frame_w) as i32 - 1);
                    let py_top = (oy as i32 + top).max(oy as i32);
                    let py_bot = (oy as i32 + bot).min((oy + frame_h) as i32 - 1);
                    if py_top < py_bot {
                        img.draw_line(px, py_top, px, py_bot, r, g, b, 255);
                    }
                }
            }
        }
        img
    }


    /// Draw a first-person textured raycaster view with procedural textures.
    ///
    /// Each cell value maps to a procedural texture (brick, stone, wood, metal,
    /// marble, mosaic). Includes sky gradient, stars, and perspective floor.
    ///
    /// # Parameters
    /// - `ox` — `f32`. Camera X position.
    /// - `oy` — `f32`. Camera Y position.
    /// - `angle` — `f32`. Camera facing angle.
    /// - `fov` — `f32`. Field of view in radians.
    /// - `width` — `u32`. Image width.
    /// - `height` — `u32`. Image height.
    /// - `max_dist` — `f32`. Maximum ray distance.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_textured_view_to_image(
        &self,
        ox: f32, oy: f32,
        angle: f32, fov: f32,
        width: u32, height: u32,
        max_dist: f32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        let half_h = height / 2;

        // Sky gradient + stars
        for y in 0..half_h {
            let t = y as f32 / half_h as f32;
            let r = (10.0 + t * 20.0) as u8;
            let g = (15.0 + t * 30.0) as u8;
            let b = (40.0 + t * 80.0) as u8;
            for x in 0..width { img.set_pixel(x, y, r, g, b, 255); }
        }
        let star_positions: [(u32, u32); 10] = [
            (50, 20), (150, 40), (280, 15), (400, 35), (520, 25), (600, 45),
            (100, 60), (350, 55), (500, 70), (80, 90),
        ];
        for &(sx, sy) in &star_positions {
            if sx < width && sy < half_h {
                img.set_pixel(sx, sy, 255, 255, 240, 200);
            }
        }

        // Floor with perspective checker
        for y in half_h..height {
            let t = (y - half_h) as f32 / half_h as f32;
            let base_g = (60.0 - t * 30.0) as u8;
            for x in 0..width {
                let checker = (x / 40 + (y - half_h) / 20).is_multiple_of(2) as u8;
                let r = base_g + 15 + checker * 15;
                let g2 = base_g + 5 + checker * 10;
                let b = base_g / 2 + checker * 8;
                img.set_pixel(x, y, r, g2, b, 255);
            }
        }

        // Cast rays
        let rays = self.cast_rays(ox, oy, angle, fov, width, max_dist);

        for (x, hit) in rays.iter().enumerate() {
            if hit.hit {
                let wall_h = (300.0 / hit.distance.max(0.2)) as i32;
                let top = half_h as i32 - wall_h / 2;
                let bot = half_h as i32 + wall_h / 2;
                let shade = (1.0 - hit.distance / max_dist).max(0.2);

                for y in top.max(0)..bot.min(height as i32) {
                    let frac_y = (y - top) as f32 / (bot - top).max(1) as f32;
                    let frac_x = (hit.distance * 3.7) % 1.0;
                    let (tr, tg, tb) = Self::procedural_texture_color(hit.cell_value, frac_y, frac_x);
                    let r = (tr as f32 * shade) as u8;
                    let g = (tg as f32 * shade) as u8;
                    let b = (tb as f32 * shade) as u8;
                    img.set_pixel(x as u32, y as u32, r, g, b, 255);
                }
            }
        }

        img.draw_label("PROCEDURAL TEXTURED RAYCASTER", (width / 4) as i32, (height - 15) as i32, 100, 255, 100);
        img
    }

    /// Map a cell value plus texture coordinates to a procedural colour.
    fn procedural_texture_color(cell: u32, frac_y: f32, frac_x: f32) -> (u8, u8, u8) {
        match cell {
            1 => {
                // Brick pattern
                let brick_y = (frac_y * 4.0) as u32;
                let offset = if brick_y.is_multiple_of(2) { 0 } else { 4 };
                let is_mortar = frac_y * 4.0 % 1.0 < 0.1
                    || (frac_x * 8.0 + offset as f32) % 1.0 < 0.12;
                if is_mortar { (120, 110, 100) } else { (180, 60, 40) }
            }
            2 => {
                let block_x = (frac_x * 3.0) as u32;
                let block_y = (frac_y * 3.0) as u32;
                let noise = ((block_x * 37 + block_y * 59) % 30) as u8;
                (130 + noise, 130 + noise, 140 + noise)
            }
            3 => {
                let plank = (frac_x * 6.0) as u32;
                let grain = ((frac_y * 20.0).sin() * 15.0) as i32;
                let base = 100 + (plank * 12 % 40) as i32;
                let r = (base + grain).clamp(60, 200) as u8;
                let g = (base - 20 + grain).clamp(40, 150) as u8;
                let b = ((base - 50).max(20) as f32 * 0.5) as u8;
                (r, g, b)
            }
            4 => {
                let panel_y = (frac_y * 4.0) as u32;
                let is_seam = frac_y * 4.0 % 1.0 < 0.08;
                let rivet = frac_x > 0.45 && frac_x < 0.55
                    && frac_y * 4.0 % 1.0 > 0.4 && frac_y * 4.0 % 1.0 < 0.6;
                if rivet { (200, 200, 210) }
                else if is_seam { (60, 65, 75) }
                else {
                    let shade = 100 + (panel_y * 10 % 30) as u8;
                    (shade, (shade as u16 + 10).min(255) as u8, (shade as u16 + 25).min(255) as u8)
                }
            }
            5 => {
                let vein = ((frac_y * 10.0 + frac_x * 5.0).sin() * 20.0) as i32;
                let base = 200 + vein;
                let r = base.clamp(160, 240) as u8;
                let g = (base - 10).clamp(150, 235) as u8;
                let b = (base - 5).clamp(155, 238) as u8;
                (r, g, b)
            }
            6 => {
                let tx = (frac_x * 5.0) as u32;
                let ty = (frac_y * 5.0) as u32;
                let tile_hue = ((tx * 73 + ty * 41) % 6) as f32 * 60.0;
                // Inline HSV→RGB
                let h = tile_hue % 360.0;
                let s = 0.6f32;
                let v = 0.8f32;
                let c = v * s;
                let x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
                let m = v - c;
                let (r, g, b) = match (h / 60.0) as u8 {
                    0 => (c, x, 0.0f32),
                    1 => (x, c, 0.0),
                    2 => (0.0, c, x),
                    3 => (0.0, x, c),
                    4 => (x, 0.0, c),
                    _ => (c, 0.0, x),
                };
                (((r + m) * 255.0) as u8, ((g + m) * 255.0) as u8, ((b + m) * 255.0) as u8)
            }
            _ => (150, 150, 150),
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
