/// Integration tests for the `procgen` module.
///
/// Validates cellular automata, flood fill, Poisson disk, and Voronoi
/// generation functions. All tests are headless with no GPU or audio
/// requirements.
use lurek2d::procgen::{
    cellular_automata, flood_fill, perlin_noise_periodic, poisson_disk, voronoi_diagram,
    CellularOpts, VoronoiOpts,
};

// ── cellular_automata ─────────────────────────────────────────────────────────

#[test]
fn cellular_automata_output_size_matches_dimensions() {
    let opts = CellularOpts {
        fill: 0.45,
        iterations: 3,
        ..Default::default()
    };
    let data = cellular_automata(10, 8, &opts);
    assert_eq!(data.len(), 80);
}

#[test]
fn cellular_automata_values_are_zero_or_one() {
    let opts = CellularOpts::default();
    let data = cellular_automata(16, 16, &opts);
    for &v in &data {
        assert!(v == 0 || v == 1, "unexpected value {v}");
    }
}

#[test]
fn cellular_automata_full_fill_yields_mostly_walls() {
    let opts = CellularOpts {
        fill: 1.0,
        iterations: 0,
        seed: 42,
        ..Default::default()
    };
    let data = cellular_automata(20, 20, &opts);
    let wall_count = data.iter().filter(|&&v| v == 1).count();
    assert!(wall_count > 0, "expected non-zero wall cells at 100% fill");
}

// ── flood_fill ────────────────────────────────────────────────────────────────

#[test]
fn flood_fill_output_same_size_as_input() {
    let w = 6u32;
    let h = 4u32;
    let data = vec![0u8; (w * h) as usize];
    let result = flood_fill(&data, w, h, 0, 0, 128, false);
    assert_eq!(result.len(), data.len());
}

#[test]
fn flood_fill_all_zeros_fills_entire_grid() {
    let w = 5u32;
    let h = 5u32;
    let data = vec![0u8; (w * h) as usize];
    let result = flood_fill(&data, w, h, 2, 2, 128, false);
    assert!(result.iter().all(|&v| v > 0), "all cells should be filled");
}

#[test]
fn flood_fill_blocked_by_walls() {
    let w = 5u32;
    let h = 5u32;
    // Row 2 is a solid wall barrier
    let mut data = vec![0u8; (w * h) as usize];
    for x in 0..w {
        data[(2 * w + x) as usize] = 255;
    }
    let result = flood_fill(&data, w, h, 0, 0, 200, false);
    // Cells in rows 3-4 should not be filled (blocked by wall)
    for y in 3..h {
        for x in 0..w {
            assert_eq!(
                result[(y * w + x) as usize],
                0,
                "cell ({x},{y}) should remain 0"
            );
        }
    }
}

// ── perlin_noise_periodic ─────────────────────────────────────────────────────

#[test]
fn perlin_noise_periodic_output_is_in_range() {
    let v = perlin_noise_periodic(0.5, 0.5, 8.0, 8.0);
    assert!(v >= -1.0 && v <= 1.0, "value {v} out of [-1, 1]");
}

#[test]
fn perlin_noise_periodic_wraps_seamlessly() {
    // f(0,y) should equal f(period,y) when period matches
    let px = 8.0_f64;
    let py = 8.0_f64;
    let v1 = perlin_noise_periodic(0.0, 3.0, px, py);
    let v2 = perlin_noise_periodic(px, 3.0, px, py);
    assert!((v1 - v2).abs() < 1e-6, "noise does not wrap: {v1} vs {v2}");
}

// ── poisson_disk ──────────────────────────────────────────────────────────────

#[test]
fn poisson_disk_returns_points_within_bounds() {
    let (w, h, min_dist) = (100.0_f32, 100.0, 10.0);
    let pts = poisson_disk(w, h, min_dist, 30, 42);
    for (px, py) in &pts {
        assert!(*px >= 0.0 && *px < w, "point x={px} out of bounds");
        assert!(*py >= 0.0 && *py < h, "point y={py} out of bounds");
    }
}

#[test]
fn poisson_disk_respects_minimum_distance() {
    let min_dist = 8.0_f32;
    let pts = poisson_disk(60.0, 60.0, min_dist, 30, 7);
    for i in 0..pts.len() {
        for j in (i + 1)..pts.len() {
            let (ax, ay) = pts[i];
            let (bx, by) = pts[j];
            let dist = ((bx - ax) * (bx - ax) + (by - ay) * (by - ay)).sqrt();
            assert!(
                dist >= min_dist - 1e-3,
                "points {i} and {j} are too close: {dist} < {min_dist}"
            );
        }
    }
}

// ── voronoi_diagram ───────────────────────────────────────────────────────────

#[test]
fn voronoi_output_size_matches_grid() {
    let pts = vec![(10.0_f32, 10.0), (30.0, 30.0), (50.0, 10.0)];
    let opts = VoronoiOpts::default();
    let (regions, dist, dist2) = voronoi_diagram(8, 8, &pts, &opts);
    assert_eq!(regions.len(), 64);
    assert_eq!(dist.len(), 64);
    assert_eq!(dist2.len(), 64);
}

#[test]
fn voronoi_region_indices_within_seed_count() {
    let pts = vec![(5.0_f32, 5.0), (25.0, 5.0)];
    let opts = VoronoiOpts::default();
    let (regions, _, _) = voronoi_diagram(32, 16, &pts, &opts);
    for &r in &regions {
        assert!(
            (r as usize) < pts.len(),
            "region index {r} >= number of seeds {}",
            pts.len()
        );
    }
}
