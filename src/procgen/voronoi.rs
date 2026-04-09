//! Voronoi diagram generation with optional warp.
//!
//! Assigns each pixel in a grid to its nearest seed point, returning region IDs,
//! distances, and second-closest distances.

use mlua::prelude::*;
use super::lcg::Lcg;
use crate::engine::log_messages::{VR01, VR02};
use crate::log_msg;

/// Options for Voronoi diagram generation. Controls seed points, grid dimensions,
/// and optional domain-warp parameters for organic region shapes.
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

impl VoronoiOpts {
    /// Constructs `VoronoiOpts` from a Lua table, using defaults for missing keys.
    ///
    /// # Parameters
    /// - `t` -- `&LuaTable`.
    ///
    /// # Returns
    /// `LuaResult<Self>`.
    pub fn from_lua_table(t: &LuaTable) -> LuaResult<Self> {
        let mut opts = Self::default();
        if let Ok(v) = t.get::<_, f32>("warp_scale") { opts.warp_scale = v; }
        if let Ok(v) = t.get::<_, f32>("warp_strength") { opts.warp_strength = v; }
        if let Ok(v) = t.get::<_, u64>("seed") { opts.seed = v; }
        Ok(opts)
    }
}

/// Generates a Voronoi diagram over a `width × height` grid for the given seed points.
/// Returns region IDs, nearest-point distances, and second-closest distances for each cell.
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
    log_msg!(debug, VR01, "{}x{} {} pts", width, height, points.len());
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

    log_msg!(debug, VR02);
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

#[cfg(test)]
mod tests {
    use super::*;

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
}
