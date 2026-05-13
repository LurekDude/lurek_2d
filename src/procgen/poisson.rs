use super::lcg::Lcg;
pub fn poisson_disk(
    width: f32,
    height: f32,
    min_dist: f32,
    max_attempts: u32,
    seed: u64,
) -> Vec<(f32, f32)> {
    use std::f32::consts::PI;
    let mut rng = Lcg::new(seed);
    let cell_size = min_dist / std::f32::consts::SQRT_2;
    let grid_w = (width / cell_size).ceil() as usize + 1;
    let grid_h = (height / cell_size).ceil() as usize + 1;
    let mut grid: Vec<Option<usize>> = vec![None; grid_w * grid_h];
    let mut points: Vec<(f32, f32)> = Vec::new();
    let mut active: Vec<usize> = Vec::new();
    let first = (rng.next_f32() * width, rng.next_f32() * height);
    points.push(first);
    active.push(0);
    let gx = (first.0 / cell_size) as usize;
    let gy = (first.1 / cell_size) as usize;
    if gx < grid_w && gy < grid_h {
        grid[gy * grid_w + gx] = Some(0);
    }
    while !active.is_empty() {
        let idx = (rng.next() as usize) % active.len();
        let point = points[active[idx]];
        let mut found = false;
        for _ in 0..max_attempts {
            let angle = rng.next_f32() * 2.0 * PI;
            let dist = min_dist + rng.next_f32() * min_dist;
            let nx = point.0 + angle.cos() * dist;
            let ny = point.1 + angle.sin() * dist;
            if nx < 0.0 || ny < 0.0 || nx >= width || ny >= height {
                continue;
            }
            let gx = (nx / cell_size) as usize;
            let gy = (ny / cell_size) as usize;
            let mut too_close = false;
            let search_radius = 2usize;
            for dy in 0..=(search_radius * 2) {
                let cy = (gy + dy).wrapping_sub(search_radius);
                if cy >= grid_h {
                    continue;
                }
                for dx_off in 0..=(search_radius * 2) {
                    let cx = (gx + dx_off).wrapping_sub(search_radius);
                    if cx >= grid_w {
                        continue;
                    }
                    if let Some(pi) = grid[cy * grid_w + cx] {
                        let (qx, qy) = points[pi];
                        let ddx = nx - qx;
                        let ddy = ny - qy;
                        if ddx * ddx + ddy * ddy < min_dist * min_dist {
                            too_close = true;
                            break;
                        }
                    }
                }
                if too_close {
                    break;
                }
            }
            if !too_close {
                let new_idx = points.len();
                points.push((nx, ny));
                active.push(new_idx);
                if gx < grid_w && gy < grid_h {
                    grid[gy * grid_w + gx] = Some(new_idx);
                }
                found = true;
                break;
            }
        }
        if !found {
            active.swap_remove(idx);
        }
    }
    points
}
