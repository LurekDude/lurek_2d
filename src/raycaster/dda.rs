use super::ray_hit::RayHit;
use super::sprite_projection::SpriteProjection;
use crate::log_msg;
use crate::runtime::log_messages::RC01;
use std::collections::HashMap;
pub struct Raycaster2D {
    width: u32,
    height: u32,
    cells: Vec<u32>,
    wall_alphas: HashMap<u8, f32>,
}
impl Raycaster2D {
    pub fn new(width: u32, height: u32) -> Self {
        log_msg!(debug, RC01, "{}x{}", width, height);
        Self {
            width,
            height,
            cells: vec![0; (width * height) as usize],
            wall_alphas: HashMap::new(),
        }
    }
    pub fn set_cell(&mut self, x: u32, y: u32, value: u32) {
        if x < self.width && y < self.height {
            self.cells[(y * self.width + x) as usize] = value;
        }
    }
    pub fn get_cell(&self, x: u32, y: u32) -> u32 {
        if x < self.width && y < self.height {
            self.cells[(y * self.width + x) as usize]
        } else {
            0
        }
    }
    pub fn set_cells(&mut self, data: Vec<u32>) {
        if data.len() == (self.width * self.height) as usize {
            self.cells = data;
        }
    }
    pub fn is_blocked(&self, x: u32, y: u32) -> bool {
        self.get_cell(x, y) > 0
    }
    pub fn width(&self) -> u32 {
        self.width
    }
    pub fn height(&self) -> u32 {
        self.height
    }
    pub fn cells(&self) -> &[u32] {
        &self.cells
    }
    pub fn set_wall_alpha(&mut self, tile_type: u8, alpha: f32) {
        self.wall_alphas.insert(tile_type, alpha.clamp(0.0, 1.0));
    }
    pub fn get_wall_alpha(&self, tile_type: u8) -> f32 {
        self.wall_alphas.get(&tile_type).copied().unwrap_or(1.0)
    }
    pub fn cast_ray(&self, ox: f32, oy: f32, angle: f32, max_dist: f32) -> Option<RayHit> {
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
        let mut side: u8;
        loop {
            if side_dist_x < side_dist_y {
                side_dist_x += delta_dist_x;
                map_x += step_x;
                side = 0;
            } else {
                side_dist_y += delta_dist_y;
                map_y += step_y;
                side = 1;
            }
            let perp_dist = if side == 0 {
                side_dist_x - delta_dist_x
            } else {
                side_dist_y - delta_dist_y
            };
            if perp_dist > max_dist {
                return None;
            }
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
                let raw_distance = perp_dist;
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
                    hit.distance *= angle_diff.cos();
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
                return true;
            }
            if self.cells[(map_y as u32 * self.width + map_x as u32) as usize] > 0 {
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
        let p = row - half_h;
        if p == 0 {
            return vec![(0.0, 0.0); w as usize];
        }
        let row_distance = 0.5 * h as f32 / p.abs() as f32;
        let floor_step_x = row_distance * (dir_x + plane_x - (dir_x - plane_x)) / w as f32;
        let floor_step_y = row_distance * (dir_y + plane_y - (dir_y - plane_y)) / w as f32;
        let mut floor_x = cam_x + row_distance * (dir_x - plane_x);
        let mut floor_y = cam_y + row_distance * (dir_y - plane_y);
        let mut result = Vec::with_capacity(w as usize);
        for _ in 0..w {
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
