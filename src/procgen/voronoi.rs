//! Voronoi diagram generator for `src/procgen`.
//! Owns `VoronoiOpts`, `voronoi_diagram`, and the `simple_hash_noise` warp helper.
//! Does not own Poisson sampling or world-graph construction — those live in
//! `poisson.rs` and `world_graph.rs`.

use super::lcg::Lcg;

/// Options controlling domain warp applied before Voronoi distance computation.
#[derive(Debug, Clone)]
pub struct VoronoiOpts {
    /// Frequency of the warp noise; smaller = broader distortion.
    pub warp_scale: f32,
    /// Displacement magnitude in pixels; 0.0 = no warp.
    pub warp_strength: f32,
    /// Seed for the internal `Lcg` used when warp is active.
    pub seed: u64,
}

/// Provide defaults with no domain warp (strength = 0).
impl Default for VoronoiOpts {
    fn default() -> Self {
        Self {
            warp_scale: 0.1,
            warp_strength: 0.0,
            seed: 0,
        }
    }
}

/// Compute a Voronoi diagram for `points` on a `width × height` grid.
///
/// Returns `(region_indices, f1_distances, f2_distances)` where each element
/// is a flat row-major buffer; `f1` is distance to closest point, `f2` to second closest.
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
/// Hash `(x, y)` and `seed` to a [-1, 1) float for domain-warp displacement.
fn simple_hash_noise(x: f32, y: f32, seed: u64) -> f32 {
    let h = (x as u64)
        .wrapping_mul(374761393)
        .wrapping_add((y as u64).wrapping_mul(668265263))
        .wrapping_add(seed);
    let h = h.wrapping_mul(h).wrapping_mul(h).wrapping_mul(60493);
    let h = (h >> 13) ^ h;
    (h & 0xFFFF) as f32 / 65535.0 * 2.0 - 1.0
}
