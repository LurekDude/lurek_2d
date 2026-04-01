//! Procedural generation utility functions.
//!
//! Cave generation, Voronoi diagrams, flood fill, Poisson disk sampling,
//! and periodic Perlin noise.

/// Options for cellular automata generation.
///
/// # Fields
/// - `fill` — `f32`.
/// - `iterations` — `u32`.
/// - `birth` — `u32`.
/// - `survive` — `u32`.
/// - `seed` — `u64`.
#[derive(Debug, Clone)]
pub struct CellularOpts {
    /// Fill ratio for initial random placement (0.0 to 1.0).
    pub fill: f32,
    /// Number of smoothing iterations.
    pub iterations: u32,
    /// Minimum neighbor count to birth a new cell.
    pub birth: u32,
    /// Minimum neighbor count to survive.
    pub survive: u32,
    /// Random seed.
    pub seed: u64,
}

impl Default for CellularOpts {
    fn default() -> Self {
        Self {
            fill: 0.45,
            iterations: 5,
            birth: 6,
            survive: 4,
            seed: 12345,
        }
    }
}

/// Options for Voronoi diagram generation.
///
/// # Fields
/// - `warp_scale` — `f32`.
/// - `warp_strength` — `f32`.
/// - `seed` — `u64`.
#[derive(Debug, Clone)]
pub struct VoronoiOpts {
    /// Warp noise scale.
    pub warp_scale: f32,
    /// Warp noise strength.
    pub warp_strength: f32,
    /// Random seed for warp noise.
    pub seed: u64,
}

impl Default for VoronoiOpts {
    fn default() -> Self {
        Self {
            warp_scale: 0.1,
            warp_strength: 0.0,
            seed: 0,
        }
    }
}

/// Simple LCG (Linear Congruential Generator) for deterministic random numbers.
struct Lcg {
    state: u64,
}

impl Lcg {
    fn new(seed: u64) -> Self {
        Self {
            state: seed.wrapping_add(1),
        }
    }

    fn next(&mut self) -> u64 {
        self.state = self
            .state
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        self.state
    }

    fn next_f32(&mut self) -> f32 {
        (self.next() >> 33) as f32 / (1u64 << 31) as f32
    }
}

/// Generates a cave/dungeon map using cellular automata.
///
/// # Parameters
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `opts` — `&CellularOpts`.
///
/// # Returns
/// `Vec<u8>`.
///
/// Returns a flat `Vec<u8>` of size `width * height` where 1 = wall, 0 = open.
pub fn cellular_automata(width: u32, height: u32, opts: &CellularOpts) -> Vec<u8> {
    let size = (width * height) as usize;
    let mut grid = vec![0u8; size];
    let mut rng = Lcg::new(opts.seed);

    // Initialize randomly
    for cell in grid.iter_mut() {
        *cell = if rng.next_f32() < opts.fill { 1 } else { 0 };
    }

    // Smoothing iterations
    let mut next = vec![0u8; size];
    for _ in 0..opts.iterations {
        for y in 0..height {
            for x in 0..width {
                let idx = (y * width + x) as usize;
                let mut neighbors = 0u32;

                for dy in -1i32..=1 {
                    for dx in -1i32..=1 {
                        if dx == 0 && dy == 0 {
                            continue;
                        }
                        let nx = x as i32 + dx;
                        let ny = y as i32 + dy;
                        if nx < 0 || ny < 0 || nx >= width as i32 || ny >= height as i32 {
                            neighbors += 1; // treat out-of-bounds as wall
                        } else {
                            neighbors += grid[(ny as u32 * width + nx as u32) as usize] as u32;
                        }
                    }
                }

                next[idx] = if grid[idx] == 1 {
                    if neighbors >= opts.survive {
                        1
                    } else {
                        0
                    }
                } else if neighbors >= opts.birth {
                    1
                } else {
                    0
                };
            }
        }
        std::mem::swap(&mut grid, &mut next);
    }

    grid
}

/// Generates a Voronoi diagram.
///
/// # Parameters
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `points` — `&[(f32, f32)]`.
/// - `opts` — `&VoronoiOpts`.
///
/// # Returns
/// `(Vec<u32>, Vec<f32>, Vec<f32>)`.
///
/// Returns `(regions, distances, second_distances)`:
/// - `regions`: flat `Vec<u32>` mapping each pixel to its closest point index
/// - `distances`: distance to closest point
/// - `second_distances`: distance to second-closest point
pub fn voronoi_diagram(
    width: u32,
    height: u32,
    points: &[(f32, f32)],
    opts: &VoronoiOpts,
) -> (Vec<u32>, Vec<f32>, Vec<f32>) {
    let size = (width * height) as usize;
    let mut regions = vec![0u32; size];
    let mut distances = vec![0.0f32; size];
    let mut second_distances = vec![0.0f32; size];

    let use_warp = opts.warp_strength > 0.0;
    let mut rng = Lcg::new(opts.seed);

    for y in 0..height {
        for x in 0..width {
            let idx = (y * width + x) as usize;

            let (px, py) = if use_warp {
                let wx = x as f32
                    + simple_hash_noise(
                        x as f32 * opts.warp_scale,
                        y as f32 * opts.warp_scale,
                        rng.next(),
                    ) * opts.warp_strength;
                let wy = y as f32
                    + simple_hash_noise(
                        y as f32 * opts.warp_scale,
                        x as f32 * opts.warp_scale,
                        rng.next(),
                    ) * opts.warp_strength;
                (wx, wy)
            } else {
                (x as f32, y as f32)
            };

            let mut min_dist = f32::MAX;
            let mut second_dist = f32::MAX;
            let mut closest = 0u32;

            for (i, &(qx, qy)) in points.iter().enumerate() {
                let dx = px - qx;
                let dy = py - qy;
                let d = dx * dx + dy * dy;
                if d < min_dist {
                    second_dist = min_dist;
                    min_dist = d;
                    closest = i as u32;
                } else if d < second_dist {
                    second_dist = d;
                }
            }

            regions[idx] = closest;
            distances[idx] = min_dist.sqrt();
            second_distances[idx] = second_dist.sqrt();
        }
    }

    (regions, distances, second_distances)
}

/// Simple deterministic hash-based noise for warp.
fn simple_hash_noise(x: f32, y: f32, seed: u64) -> f32 {
    let h = (x as u64)
        .wrapping_mul(374761393)
        .wrapping_add((y as u64).wrapping_mul(668265263))
        .wrapping_add(seed);
    let h = h.wrapping_mul(h).wrapping_mul(h).wrapping_mul(60493);
    let h = (h >> 13) ^ h;
    (h & 0xFFFF) as f32 / 65535.0 * 2.0 - 1.0
}

/// BFS flood fill on a grid.
///
/// # Parameters
/// - `data` — `&[u8]`.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `sx` — `u32`.
/// - `sy` — `u32`.
/// - `threshold` — `u8`.
/// - `above` — `bool`.
///
/// # Returns
/// `Vec<u8>`.
///
/// - `data`: flat grid values
/// - `threshold`: fill boundary value
/// - `above`: if true, fill cells >= threshold; if false, fill cells <= threshold
///
/// Returns a `Vec<u8>` mask of same size (1 = filled, 0 = not).
pub fn flood_fill(
    data: &[u8],
    width: u32,
    height: u32,
    sx: u32,
    sy: u32,
    threshold: u8,
    above: bool,
) -> Vec<u8> {
    let size = (width * height) as usize;
    if data.len() != size {
        return vec![0; size];
    }
    let mut result = vec![0u8; size];

    let start_idx = (sy * width + sx) as usize;
    if start_idx >= size {
        return result;
    }

    let matches = |v: u8| -> bool {
        if above {
            v >= threshold
        } else {
            v <= threshold
        }
    };

    if !matches(data[start_idx]) {
        return result;
    }

    let mut queue = std::collections::VecDeque::new();
    queue.push_back((sx, sy));
    result[start_idx] = 1;

    while let Some((x, y)) = queue.pop_front() {
        for &(dx, dy) in &[(-1i32, 0), (1, 0), (0, -1i32), (0, 1)] {
            let nx = x as i32 + dx;
            let ny = y as i32 + dy;
            if nx < 0 || ny < 0 || nx >= width as i32 || ny >= height as i32 {
                continue;
            }
            let nx = nx as u32;
            let ny = ny as u32;
            let ni = (ny * width + nx) as usize;
            if result[ni] == 0 && matches(data[ni]) {
                result[ni] = 1;
                queue.push_back((nx, ny));
            }
        }
    }

    result
}

/// Generates Poisson disk sample points using Bridson's algorithm.
///
/// # Parameters
/// - `width` — `f32`.
/// - `height` — `f32`.
/// - `min_dist` — `f32`.
/// - `max_attempts` — `u32`.
/// - `seed` — `u64`.
///
/// # Returns
/// `Vec<(f32, f32)>`.
///
/// Returns a list of (x, y) points with minimum distance `min_dist` between them.
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

    // Initial point
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

/// Periodic Perlin noise that tiles over period (px, py).
///
/// # Parameters
/// - `x` — `f64`.
/// - `y` — `f64`.
/// - `px` — `f64`.
/// - `py` — `f64`.
///
/// # Returns
/// `f64`.
///
/// Returns a value roughly in [-1, 1].
pub fn perlin_noise_periodic(x: f64, y: f64, px: f64, py: f64) -> f64 {
    let px = px.max(1.0) as i64;
    let py = py.max(1.0) as i64;

    let xi = x.floor() as i64;
    let yi = y.floor() as i64;
    let xf = x - x.floor();
    let yf = y - y.floor();

    let fade = |t: f64| t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    let u = fade(xf);
    let v = fade(yf);

    let wrap_x = |i: i64| ((i % px) + px) % px;
    let wrap_y = |i: i64| ((i % py) + py) % py;

    let grad = |hash: i64, x: f64, y: f64| -> f64 {
        match hash & 3 {
            0 => x + y,
            1 => -x + y,
            2 => x - y,
            3 => -x - y,
            _ => 0.0,
        }
    };

    let perm_hash = |ix: i64, iy: i64| -> i64 {
        // Simple hash combining wrapped coordinates
        let h = (wrap_x(ix).wrapping_mul(374761393) as u64)
            .wrapping_add(wrap_y(iy).wrapping_mul(668265263) as u64);
        let h = h.wrapping_mul(h).wrapping_mul(h).wrapping_mul(60493);
        (h >> 13) as i64
    };

    let n00 = grad(perm_hash(xi, yi), xf, yf);
    let n10 = grad(perm_hash(xi + 1, yi), xf - 1.0, yf);
    let n01 = grad(perm_hash(xi, yi + 1), xf, yf - 1.0);
    let n11 = grad(perm_hash(xi + 1, yi + 1), xf - 1.0, yf - 1.0);

    let lerp = |t: f64, a: f64, b: f64| a + t * (b - a);
    let x1 = lerp(u, n00, n10);
    let x2 = lerp(u, n01, n11);
    lerp(v, x1, x2)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cellular_automata_size() {
        let grid = cellular_automata(20, 15, &CellularOpts::default());
        assert_eq!(grid.len(), 300);
        // Should contain both 0s and 1s
        assert!(grid.contains(&0));
        assert!(grid.contains(&1));
    }

    #[test]
    fn test_cellular_automata_deterministic() {
        let g1 = cellular_automata(
            10,
            10,
            &CellularOpts {
                seed: 42,
                ..Default::default()
            },
        );
        let g2 = cellular_automata(
            10,
            10,
            &CellularOpts {
                seed: 42,
                ..Default::default()
            },
        );
        assert_eq!(g1, g2);
    }

    #[test]
    fn test_voronoi_diagram() {
        let points = vec![(5.0, 5.0), (15.0, 15.0)];
        let (regions, dist, dist2) = voronoi_diagram(20, 20, &points, &VoronoiOpts::default());
        assert_eq!(regions.len(), 400);
        assert_eq!(dist.len(), 400);
        assert_eq!(dist2.len(), 400);
        // Corner (0,0) should be closest to point 0
        assert_eq!(regions[0], 0);
        // Corner (19,19) should be closest to point 1
        assert_eq!(regions[19 * 20 + 19], 1);
    }

    #[test]
    fn test_flood_fill() {
        let data = vec![1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1];
        let result = flood_fill(&data, 4, 4, 0, 0, 1, true);
        assert_eq!(result[0], 1); // (0,0)
        assert_eq!(result[1], 1); // (1,0)
        assert_eq!(result[4], 1); // (0,1)
        assert_eq!(result[5], 1); // (1,1)
        assert_eq!(result[2], 0); // (2,0) is 0, not >= 1
    }

    #[test]
    fn test_poisson_disk_spacing() {
        let points = poisson_disk(50.0, 50.0, 5.0, 30, 42);
        assert!(!points.is_empty());
        // Check all points are within bounds
        for &(x, y) in &points {
            assert!(x >= 0.0 && x < 50.0);
            assert!(y >= 0.0 && y < 50.0);
        }
        // Check minimum distance constraint
        for i in 0..points.len() {
            for j in (i + 1)..points.len() {
                let dx = points[i].0 - points[j].0;
                let dy = points[i].1 - points[j].1;
                let dist = (dx * dx + dy * dy).sqrt();
                assert!(dist >= 4.9, "Points too close: {dist}"); // small tolerance
            }
        }
    }

    #[test]
    fn test_perlin_noise_periodic() {
        // Value at x should equal value at x + period
        let v1 = perlin_noise_periodic(1.5, 2.3, 4.0, 4.0);
        let v2 = perlin_noise_periodic(5.5, 2.3, 4.0, 4.0);
        assert!(
            (v1 - v2).abs() < 1e-10,
            "Periodic noise not tiling: {v1} vs {v2}"
        );

        let v3 = perlin_noise_periodic(1.5, 6.3, 4.0, 4.0);
        assert!(
            (v1 - v3).abs() < 1e-10,
            "Periodic noise not tiling Y: {v1} vs {v3}"
        );
    }
}
