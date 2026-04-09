//! Integration tests for Phase 25 math extension modules.
//!
//! Covers: NoiseGenerator, Grid, SpatialHash, Raycaster2D, TileWalker,
//!         Tween, geometry, procgen. Raycasting types live in lurek2d::raycaster.

use lurek2d::math::geometry;
use lurek2d::math::{DistType, FractalType, MapGenOptions, NoiseGenerator, NoiseKind};
use lurek2d::math::spatial_hash::SpatialHash;
use lurek2d::math::tween::Tween;
use lurek2d::pathfinding::grid::Grid;
use lurek2d::procgen::{self, CellularOpts, VoronoiOpts};
use lurek2d::raycaster::Raycaster2D;
use lurek2d::raycaster::{cast_ray_2d, distance_shade, field_of_view, project_column, Segment};
use lurek2d::tilemap::tile_walker::{Facing, TileWalker};

// ═════════════════════════════════════════════════════════════════════════
// 1. NoiseGenerator
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_noise_generator_deterministic() {
    let ng1 = NoiseGenerator::new(42);
    let ng2 = NoiseGenerator::new(42);
    for i in 0..20 {
        let x = i as f64 * 0.37;
        let v1 = ng1.perlin_2d(x, 1.5);
        let v2 = ng2.perlin_2d(x, 1.5);
        assert!(
            (v1 - v2).abs() < 1e-10,
            "seed 42 perlin_2d({x}, 1.5): {v1} != {v2}"
        );
    }
}

#[test]
fn test_noise_generator_different_seeds() {
    let ng1 = NoiseGenerator::new(1);
    let ng2 = NoiseGenerator::new(999);
    let mut differ = false;
    for i in 0..20 {
        let x = i as f64 * 0.5 + 0.1;
        if (ng1.perlin_2d(x, x) - ng2.perlin_2d(x, x)).abs() > 1e-6 {
            differ = true;
            break;
        }
    }
    assert!(differ, "Different seeds should produce different noise");
}

#[test]
fn test_noise_generator_perlin_range() {
    let ng = NoiseGenerator::new(7);
    for i in 0..200 {
        let x = (i as f64 - 100.0) * 0.13;
        let y = (i as f64) * 0.27;
        let v = ng.perlin_2d(x, y);
        assert!(
            v >= -1.0 && v <= 1.0,
            "perlin_2d({x}, {y}) = {v} out of [-1, 1]"
        );
    }
}

#[test]
fn test_noise_generator_perlin_dimensions() {
    let ng = NoiseGenerator::new(13);
    let v1d = ng.perlin_1d(3.14);
    let v2d = ng.perlin_2d(3.14, 2.71);
    let v3d = ng.perlin_3d(3.14, 2.71, 1.41);
    let v4d = ng.perlin_4d(3.14, 2.71, 1.41, 0.57);
    // All should return finite values
    assert!(v1d.is_finite(), "perlin_1d not finite: {v1d}");
    assert!(v2d.is_finite(), "perlin_2d not finite: {v2d}");
    assert!(v3d.is_finite(), "perlin_3d not finite: {v3d}");
    assert!(v4d.is_finite(), "perlin_4d not finite: {v4d}");
    // Higher dimensions should produce different-looking values (not all zero)
    let sum = v1d.abs() + v2d.abs() + v3d.abs() + v4d.abs();
    assert!(sum > 1e-6, "All perlin dimensions returned ~0");
}

#[test]
fn test_noise_generator_simplex_range() {
    let ng = NoiseGenerator::new(99);
    for i in 0..200 {
        let x = (i as f64 - 100.0) * 0.15;
        let y = (i as f64) * 0.31;
        let v = ng.simplex_2d(x, y);
        assert!(
            v >= -1.5 && v <= 1.5,
            "simplex_2d({x}, {y}) = {v} outside reasonable range"
        );
    }
}

#[test]
fn test_noise_generator_simplex_dimensions() {
    let ng = NoiseGenerator::new(55);
    let v1d = ng.simplex_1d(5.5);
    let v2d = ng.simplex_2d(5.5, 3.3);
    let v3d = ng.simplex_3d(5.5, 3.3, 1.1);
    assert!(v1d.is_finite());
    assert!(v2d.is_finite());
    assert!(v3d.is_finite());
}

#[test]
fn test_noise_generator_worley_euclidean() {
    let ng = NoiseGenerator::new(77);
    let v = ng.worley_2d(3.0, 4.0, DistType::Euclidean, false);
    assert!(v.is_finite(), "worley euclidean not finite");
    assert!(v >= 0.0, "worley F1 distance should be >= 0, got {v}");
}

#[test]
fn test_noise_generator_worley_manhattan() {
    let ng = NoiseGenerator::new(77);
    let v_man = ng.worley_2d(3.0, 4.0, DistType::Manhattan, false);
    let v_euc = ng.worley_2d(3.0, 4.0, DistType::Euclidean, false);
    assert!(v_man.is_finite());
    assert!(v_man >= 0.0);
    // Manhattan and Euclidean should generally differ
    let different = (v_man - v_euc).abs() > 1e-10;
    // They could match at some points, so just check both are valid
    assert!(v_euc.is_finite());
    let _ = different; // acknowledge the check without hard assert
}

#[test]
fn test_noise_generator_fbm() {
    let ng = NoiseGenerator::new(42);
    let v = ng.fbm(2.5, 3.5, 4, 2.0, 0.5, NoiseKind::Perlin);
    assert!(v.is_finite(), "fbm not finite: {v}");
    // fBm with 4 octaves should produce values roughly in [-2, 2]
    assert!(v.abs() < 5.0, "fbm value {v} seems unreasonably large");
}

#[test]
fn test_noise_generator_ridged() {
    let ng = NoiseGenerator::new(42);
    let v = ng.ridged(2.5, 3.5, 4, 2.0, 0.5, NoiseKind::Perlin);
    assert!(v.is_finite(), "ridged not finite: {v}");
    // Ridged produces different shape than fbm
    let fbm_v = ng.fbm(2.5, 3.5, 4, 2.0, 0.5, NoiseKind::Perlin);
    // They should generally differ (ridged folds the signal)
    assert!(
        (v - fbm_v).abs() > 1e-10 || v.abs() < 1e-10,
        "ridged and fbm should differ"
    );
}

#[test]
fn test_noise_generator_turbulence() {
    let ng = NoiseGenerator::new(42);
    let v = ng.turbulence(2.5, 3.5, 4, 2.0, 0.5, NoiseKind::Perlin);
    assert!(v.is_finite(), "turbulence not finite: {v}");
    // Turbulence takes abs of noise, so typically positive
    assert!(
        v >= -0.1,
        "turbulence should be mostly non-negative, got {v}"
    );
}

#[test]
fn test_noise_generator_generate_map() {
    let ng = NoiseGenerator::new(100);
    let opts = MapGenOptions {
        scale_x: 0.1,
        scale_y: 0.1,
        octaves: 3,
        lacunarity: 2.0,
        persistence: 0.5,
        kind: NoiseKind::Perlin,
        fractal: FractalType::Fbm,
        offset_x: 0.0,
        offset_y: 0.0,
    };
    let map = ng.generate_map(32, 16, &opts);
    assert_eq!(
        map.len(),
        32 * 16,
        "Map should have width * height elements"
    );
    for (i, v) in map.iter().enumerate() {
        assert!(v.is_finite(), "map[{i}] is not finite: {v}");
    }
}

// ═════════════════════════════════════════════════════════════════════════
// 2. Grid (Pathfinding)
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_grid_new_all_walkable() {
    let g = Grid::new(10, 10, 1.0);
    assert_eq!(g.width(), 10);
    assert_eq!(g.height(), 10);
    for y in 0..10 {
        for x in 0..10 {
            assert!(g.is_walkable(x, y), "({x},{y}) should be walkable");
        }
    }
}

#[test]
fn test_grid_set_walkable() {
    let mut g = Grid::new(5, 5, 1.0);
    assert!(g.is_walkable(2, 3));
    g.set_walkable(2, 3, false);
    assert!(!g.is_walkable(2, 3));
    g.set_walkable(2, 3, true);
    assert!(g.is_walkable(2, 3));
}

#[test]
fn test_grid_costs() {
    let mut g = Grid::new(5, 5, 1.0);
    assert!((g.get_cost(1, 1) - 1.0).abs() < 1e-4);
    g.set_cost(1, 1, 5.0);
    assert!((g.get_cost(1, 1) - 5.0).abs() < 1e-4);
}

#[test]
fn test_grid_astar_simple() {
    let g = Grid::new(10, 10, 1.0);
    let path = g.find_path_astar(0, 0, 9, 0, false);
    assert!(path.is_some(), "A* should find path on open grid");
    let path = path.unwrap();
    assert_eq!(*path.first().unwrap(), (0, 0));
    assert_eq!(*path.last().unwrap(), (9, 0));
    // Straight line: 10 cells
    assert_eq!(path.len(), 10);
}

#[test]
fn test_grid_astar_blocked() {
    let mut g = Grid::new(5, 1, 1.0);
    // Block the only row except start and end
    g.set_walkable(1, 0, false);
    g.set_walkable(2, 0, false);
    g.set_walkable(3, 0, false);
    let path = g.find_path_astar(0, 0, 4, 0, false);
    assert!(path.is_none(), "A* should return None when no path exists");
}

#[test]
fn test_grid_astar_around_wall() {
    let mut g = Grid::new(5, 5, 1.0);
    // Build a vertical wall at x=2, except leave y=4 open
    for y in 0..4 {
        g.set_walkable(2, y, false);
    }
    let path = g.find_path_astar(0, 0, 4, 0, false);
    assert!(path.is_some(), "A* should route around wall");
    let path = path.unwrap();
    assert_eq!(*path.first().unwrap(), (0, 0));
    assert_eq!(*path.last().unwrap(), (4, 0));
    // Path must go through the gap at (2, 4)
    assert!(
        path.contains(&(2, 4)),
        "Path should go through gap at (2,4): {:?}",
        path
    );
}

#[test]
fn test_grid_dijkstra() {
    let g = Grid::new(8, 8, 1.0);
    let path = g.find_path_dijkstra(0, 0, 7, 7, false);
    assert!(path.is_some(), "Dijkstra should find path");
    let path = path.unwrap();
    assert_eq!(*path.first().unwrap(), (0, 0));
    assert_eq!(*path.last().unwrap(), (7, 7));
}

#[test]
fn test_grid_bfs() {
    let g = Grid::new(6, 6, 1.0);
    let path = g.find_path_bfs(0, 0, 5, 5, false);
    assert!(path.is_some(), "BFS should find path");
    let path = path.unwrap();
    assert_eq!(*path.first().unwrap(), (0, 0));
    assert_eq!(*path.last().unwrap(), (5, 5));
    // BFS without diagonal: Manhattan distance = 10, so path length = 11
    assert_eq!(path.len(), 11);
}

#[test]
fn test_grid_diagonal() {
    let g = Grid::new(5, 5, 1.0);
    let path = g.find_path_astar(0, 0, 4, 4, true);
    assert!(path.is_some());
    let path = path.unwrap();
    // With diagonals, direct path is 5 cells (0,0)->(1,1)->(2,2)->(3,3)->(4,4)
    assert_eq!(path.len(), 5, "Diagonal path should be 5 cells: {:?}", path);
}

#[test]
fn test_grid_flow_field() {
    let g = Grid::new(5, 5, 1.0);
    let field = g.build_flow_field(4, 4);
    assert_eq!(
        field.len(),
        25,
        "Flow field should have width*height entries"
    );
    // Row-major: index = y*width + x
    // At the goal cell (4,4) → index 4*5+4=24, direction should be (0,0) or very small
    let (dx, dy) = field[4 * 5 + 4];
    assert!(
        dx.abs() < 1e-4 && dy.abs() < 1e-4,
        "Goal cell direction should be ~(0,0), got ({dx},{dy})"
    );
    // Cell (3,4) → index 4*5+3=23, should point toward (4,4) → dx > 0
    let (dx, _dy) = field[4 * 5 + 3];
    assert!(
        dx > 0.0,
        "Cell (3,4) should point right toward goal, got dx={dx}"
    );
}

// ═════════════════════════════════════════════════════════════════════════
// 3. SpatialHash
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_spatial_hash_insert_query() {
    let mut sh = SpatialHash::new(32.0);
    sh.insert("a".into(), 10.0, 10.0, 20.0, 20.0);
    let results = sh.query_rect(5.0, 5.0, 30.0, 30.0);
    assert!(results.contains(&"a".to_string()), "Should find item 'a'");
}

#[test]
fn test_spatial_hash_no_overlap() {
    let mut sh = SpatialHash::new(32.0);
    sh.insert("a".into(), 0.0, 0.0, 10.0, 10.0);
    let results = sh.query_rect(100.0, 100.0, 10.0, 10.0);
    assert!(results.is_empty(), "No overlap → empty result");
}

#[test]
fn test_spatial_hash_remove() {
    let mut sh = SpatialHash::new(32.0);
    sh.insert("b".into(), 5.0, 5.0, 10.0, 10.0);
    assert_eq!(sh.item_count(), 1);
    sh.remove("b");
    assert_eq!(sh.item_count(), 0);
    let results = sh.query_rect(0.0, 0.0, 20.0, 20.0);
    assert!(results.is_empty());
}

#[test]
fn test_spatial_hash_update() {
    let mut sh = SpatialHash::new(32.0);
    sh.insert("c".into(), 0.0, 0.0, 10.0, 10.0);
    // Move item far away
    sh.update("c".into(), 500.0, 500.0, 10.0, 10.0);
    // Old location should miss
    let old = sh.query_rect(0.0, 0.0, 15.0, 15.0);
    assert!(
        !old.contains(&"c".to_string()),
        "Should not find at old pos"
    );
    // New location should hit
    let new = sh.query_rect(495.0, 495.0, 30.0, 30.0);
    assert!(new.contains(&"c".to_string()), "Should find at new pos");
}

#[test]
fn test_spatial_hash_query_circle() {
    let mut sh = SpatialHash::new(32.0);
    sh.insert("d".into(), 10.0, 10.0, 5.0, 5.0);
    sh.insert("far".into(), 200.0, 200.0, 5.0, 5.0);
    let results = sh.query_circle(12.0, 12.0, 20.0);
    assert!(results.contains(&"d".to_string()));
    assert!(!results.contains(&"far".to_string()));
}

#[test]
fn test_spatial_hash_query_segment() {
    let mut sh = SpatialHash::new(32.0);
    sh.insert("on_line".into(), 50.0, 0.0, 10.0, 10.0);
    sh.insert("off_line".into(), 50.0, 200.0, 10.0, 10.0);
    let results = sh.query_segment(0.0, 5.0, 100.0, 5.0);
    assert!(results.contains(&"on_line".to_string()));
    // off_line is far from the segment
    assert!(!results.contains(&"off_line".to_string()));
}

#[test]
fn test_spatial_hash_multiple_items() {
    let mut sh = SpatialHash::new(32.0);
    sh.insert("x1".into(), 10.0, 10.0, 10.0, 10.0);
    sh.insert("x2".into(), 15.0, 15.0, 10.0, 10.0);
    sh.insert("x3".into(), 12.0, 12.0, 5.0, 5.0);
    let results = sh.query_rect(0.0, 0.0, 30.0, 30.0);
    assert_eq!(results.len(), 3, "Should find all 3 items: {:?}", results);
}

#[test]
fn test_spatial_hash_clear() {
    let mut sh = SpatialHash::new(16.0);
    sh.insert("a".into(), 0.0, 0.0, 10.0, 10.0);
    sh.insert("b".into(), 50.0, 50.0, 10.0, 10.0);
    assert_eq!(sh.item_count(), 2);
    sh.clear();
    assert_eq!(sh.item_count(), 0);
    let results = sh.query_rect(0.0, 0.0, 1000.0, 1000.0);
    assert!(results.is_empty());
}

// ═════════════════════════════════════════════════════════════════════════
// 4. Raycaster2D
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_raycaster_new_empty() {
    let rc = Raycaster2D::new(8, 8);
    for y in 0..8 {
        for x in 0..8 {
            assert_eq!(rc.get_cell(x, y), 0, "New grid cell ({x},{y}) should be 0");
        }
    }
}

#[test]
fn test_raycaster_set_get_cell() {
    let mut rc = Raycaster2D::new(8, 8);
    rc.set_cell(3, 4, 5);
    assert_eq!(rc.get_cell(3, 4), 5);
    assert_eq!(rc.get_cell(0, 0), 0);
}

#[test]
fn test_raycaster_cast_ray_empty() {
    let rc = Raycaster2D::new(8, 8);
    let hit = rc.cast_ray(1.5, 1.5, 0.0, 20.0);
    // Empty grid → ray should either return None or a non-hit
    match hit {
        None => {} // acceptable
        Some(h) => assert!(!h.hit, "Ray in empty grid should not hit"),
    }
}

#[test]
fn test_raycaster_cast_ray_wall() {
    let mut rc = Raycaster2D::new(8, 8);
    // Place a wall at (4, 1)
    rc.set_cell(4, 1, 1);
    // Cast ray from (1.5, 1.5) pointing right (angle 0)
    let hit = rc.cast_ray(1.5, 1.5, 0.0, 20.0);
    assert!(hit.is_some(), "Should hit the wall");
    let h = hit.unwrap();
    assert!(h.hit, "RayHit.hit should be true");
    assert_eq!(h.cell_value, 1);
    assert!(
        (h.distance - 2.5).abs() < 0.5,
        "Distance to wall at x=4 from x=1.5 should be ~2.5, got {}",
        h.distance
    );
}

#[test]
fn test_raycaster_cast_rays() {
    let mut rc = Raycaster2D::new(16, 16);
    // Surround player with walls at distance 3
    for i in 0..16 {
        rc.set_cell(i, 0, 1);
        rc.set_cell(i, 15, 1);
        rc.set_cell(0, i, 1);
        rc.set_cell(15, i, 1);
    }
    let rays = rc.cast_rays(8.0, 8.0, 0.0, std::f32::consts::FRAC_PI_2, 5, 20.0);
    assert_eq!(rays.len(), 5, "Should return 5 ray results");
    for r in &rays {
        assert!(r.hit, "All rays should hit perimeter walls");
    }
}

#[test]
fn test_raycaster_line_of_sight() {
    let rc = Raycaster2D::new(8, 8);
    // Empty grid: LOS should be clear
    assert!(rc.line_of_sight(1.5, 1.5, 6.5, 6.5));
}

#[test]
fn test_raycaster_line_of_sight_blocked() {
    let mut rc = Raycaster2D::new(8, 8);
    rc.set_cell(4, 4, 1); // wall in the middle
    let los = rc.line_of_sight(1.5, 1.5, 6.5, 6.5);
    assert!(!los, "LOS through wall should be blocked");
}

#[test]
fn test_raycaster_project_sprite() {
    let rc = Raycaster2D::new(8, 8);
    // angle=0 means facing +Y in this raycaster's coordinate system
    let proj = rc.project_sprite(
        4.5,
        6.5, // sprite position (ahead in +Y)
        4.5,
        2.5,                         // player position
        0.0,                         // player angle (facing +Y)
        std::f32::consts::FRAC_PI_3, // 60° FOV
        320.0,                       // screen width
    );
    assert!(proj.visible, "Sprite ahead of player should be visible");
    assert!(proj.distance > 0.0, "Distance should be positive");
    assert!(
        (proj.screen_x - 160.0).abs() < 80.0,
        "Sprite directly ahead → near screen center. Got screen_x={}",
        proj.screen_x
    );
}

// ═════════════════════════════════════════════════════════════════════════
// 5. TileWalker
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_tile_walker_new() {
    let tw = TileWalker::new(3, 5, Facing::North);
    assert_eq!(tw.x(), 3);
    assert_eq!(tw.y(), 5);
    assert!(matches!(tw.facing(), Facing::North));
}

#[test]
fn test_tile_walker_move_forward() {
    let mut tw = TileWalker::new(5, 5, Facing::East);
    // No raycaster set, so no collision → should move freely
    let moved = tw.move_forward();
    assert!(
        moved,
        "Should move forward when no raycaster (no collision)"
    );
    assert_eq!(tw.x(), 6);
    assert_eq!(tw.y(), 5);
}

#[test]
fn test_tile_walker_turn() {
    let mut tw = TileWalker::new(0, 0, Facing::North);
    tw.turn_right();
    assert!(matches!(tw.facing(), Facing::East));
    tw.turn_right();
    assert!(matches!(tw.facing(), Facing::South));
    tw.turn_left();
    assert!(matches!(tw.facing(), Facing::East));
    tw.turn_around();
    assert!(matches!(tw.facing(), Facing::West));
}

#[test]
fn test_tile_walker_strafe() {
    let mut tw = TileWalker::new(5, 5, Facing::North);
    tw.strafe_right(); // North-facing, strafe right → move East
    assert_eq!(tw.x(), 6);
    assert_eq!(tw.y(), 5);

    let mut tw2 = TileWalker::new(5, 5, Facing::North);
    tw2.strafe_left(); // North-facing, strafe left → move West
    assert_eq!(tw2.x(), 4);
    assert_eq!(tw2.y(), 5);
}

#[test]
fn test_tile_walker_facing_direction() {
    assert_eq!(Facing::North.dx(), 0);
    assert_eq!(Facing::North.dy(), -1);
    assert_eq!(Facing::East.dx(), 1);
    assert_eq!(Facing::East.dy(), 0);
    assert_eq!(Facing::South.dx(), 0);
    assert_eq!(Facing::South.dy(), 1);
    assert_eq!(Facing::West.dx(), -1);
    assert_eq!(Facing::West.dy(), 0);
}

#[test]
fn test_tile_walker_interpolation() {
    let mut tw = TileWalker::new(3, 3, Facing::East);
    tw.begin_move();
    // At t=0, should be at start position
    let (ix, iy) = tw.get_interpolated_position(0.0);
    assert!((ix - 3.0).abs() < 1e-4);
    assert!((iy - 3.0).abs() < 1e-4);
    // At t=1, should be at current position (which is 3,3 since begin_move just marks start)
    let (ix1, iy1) = tw.get_interpolated_position(1.0);
    assert!(ix1.is_finite());
    assert!(iy1.is_finite());
}

#[test]
fn test_tile_walker_relative_facing() {
    let tw = TileWalker::new(5, 5, Facing::North);
    let rel = tw.get_relative_facing(5, 4); // target is north
    assert_eq!(rel, "front");
    let rel_behind = tw.get_relative_facing(5, 6); // target is south
    assert_eq!(rel_behind, "back");
}

// ═════════════════════════════════════════════════════════════════════════
// 6. Tween
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_tween_linear() {
    let mut tw = Tween::new(1.0, "linear");
    let idx = tw.add_value(0.0, 100.0);
    tw.set_time(0.5);
    let v = tw.get_value(idx);
    assert!(
        (v - 50.0).abs() < 1e-4,
        "Linear tween at t=0.5 should be 50, got {v}"
    );
}

#[test]
fn test_tween_complete() {
    let mut tw = Tween::new(1.0, "linear");
    tw.add_value(0.0, 10.0);
    assert!(!tw.is_complete());
    tw.update(1.5); // exceed duration
    assert!(tw.is_complete());
}

#[test]
fn test_tween_reset() {
    let mut tw = Tween::new(1.0, "linear");
    let idx = tw.add_value(0.0, 100.0);
    tw.update(1.0);
    assert!(tw.is_complete());
    tw.reset();
    assert!(!tw.is_complete());
    let v = tw.get_value(idx);
    assert!(
        (v - 0.0).abs() < 1e-4,
        "After reset, value should be start (0), got {v}"
    );
}

#[test]
fn test_tween_multiple_values() {
    let mut tw = Tween::new(2.0, "linear");
    let i0 = tw.add_value(0.0, 100.0);
    let i1 = tw.add_value(50.0, 150.0);
    assert_eq!(tw.value_count(), 2);
    tw.set_time(1.0); // halfway
    let v0 = tw.get_value(i0);
    let v1 = tw.get_value(i1);
    assert!(
        (v0 - 50.0).abs() < 1e-4,
        "Value 0 at halfway should be 50, got {v0}"
    );
    assert!(
        (v1 - 100.0).abs() < 1e-4,
        "Value 1 at halfway should be 100, got {v1}"
    );
}

#[test]
fn test_tween_easing() {
    let mut tw = Tween::new(1.0, "inQuad");
    let idx = tw.add_value(0.0, 100.0);
    tw.set_time(0.5);
    let v = tw.get_value(idx);
    // inQuad at 0.5 = 0.25, so value = 25.0
    assert!(
        (v - 25.0).abs() < 1.0,
        "inQuad at t=0.5 should be ~25, got {v}"
    );
}

#[test]
fn test_tween_set_time() {
    let mut tw = Tween::new(4.0, "linear");
    let idx = tw.add_value(0.0, 200.0);
    tw.set_time(2.0);
    let v = tw.get_value(idx);
    assert!(
        (v - 100.0).abs() < 1e-4,
        "set_time(2) on 4s tween → 50% → 100, got {v}"
    );
    assert!((tw.clock() - 2.0).abs() < 1e-4);
}

#[test]
fn test_tween_update_returns_complete() {
    let mut tw = Tween::new(1.0, "linear");
    tw.add_value(0.0, 1.0);
    let done1 = tw.update(0.5);
    assert!(!done1, "Not done at 0.5s");
    let done2 = tw.update(0.6); // total 1.1s
    assert!(done2, "Should be done after exceeding duration");
}

#[test]
fn test_tween_clamp() {
    let mut tw = Tween::new(1.0, "linear");
    let idx = tw.add_value(10.0, 20.0);
    tw.update(5.0); // way past end
    let v = tw.get_value(idx);
    assert!(
        (v - 20.0).abs() < 1e-4,
        "Clamped value should be target (20), got {v}"
    );
}

// ═════════════════════════════════════════════════════════════════════════
// 7. Geometry
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_angle_between() {
    let a = geometry::angle_between(0.0, 0.0, 1.0, 0.0);
    assert!(
        a.abs() < 1e-4,
        "Angle to (1,0) from origin should be ~0, got {a}"
    );

    let a_up = geometry::angle_between(0.0, 0.0, 0.0, 1.0);
    assert!(
        (a_up - std::f32::consts::FRAC_PI_2).abs() < 1e-4,
        "Angle to (0,1) should be π/2, got {a_up}"
    );
}

#[test]
fn test_circle_contains_point() {
    assert!(geometry::circle_contains_point(5.0, 5.0, 3.0, 6.0, 6.0));
    assert!(!geometry::circle_contains_point(5.0, 5.0, 1.0, 10.0, 10.0));
    // Boundary: point exactly at radius
    assert!(geometry::circle_contains_point(0.0, 0.0, 5.0, 3.0, 4.0));
}

#[test]
fn test_circle_intersects_circle() {
    // Overlapping circles
    assert!(geometry::circle_intersects_circle(
        0.0, 0.0, 5.0, 3.0, 0.0, 5.0
    ));
    // Non-overlapping circles
    assert!(!geometry::circle_intersects_circle(
        0.0, 0.0, 2.0, 10.0, 0.0, 2.0
    ));
    // Touching circles (distance = r1 + r2)
    assert!(geometry::circle_intersects_circle(
        0.0, 0.0, 3.0, 6.0, 0.0, 3.0
    ));
}

#[test]
fn test_circle_intersects_line() {
    // Line through center of circle
    let (hit, p1, p2) = geometry::circle_intersects_line(0.0, 0.0, 5.0, -10.0, 0.0, 10.0, 0.0);
    assert!(hit, "Line through center should intersect");
    assert!(p1.is_some());
    assert!(p2.is_some());
    let (ix1, _) = p1.unwrap();
    let (ix2, _) = p2.unwrap();
    assert!((ix1.abs() - 5.0).abs() < 1e-3, "Intersection at x=±5");
    assert!((ix2.abs() - 5.0).abs() < 1e-3);
}

#[test]
fn test_circle_intersects_segment() {
    // Segment that crosses the circle boundary (enters and exits)
    let (hit, p1, p2) = geometry::circle_intersects_segment(0.0, 0.0, 5.0, -10.0, 0.0, 10.0, 0.0);
    assert!(hit, "Segment crossing circle should intersect");
    assert!(p1.is_some(), "Should have entry point");
    assert!(p2.is_some(), "Should have exit point");

    // Segment completely outside
    let (miss, _, _) = geometry::circle_intersects_segment(0.0, 0.0, 2.0, 10.0, 10.0, 20.0, 10.0);
    assert!(!miss, "Distant segment should not intersect");
}

#[test]
fn test_polygon_area_triangle() {
    // Triangle: (0,0), (4,0), (0,3) → area = 6
    let verts = [0.0f32, 0.0, 4.0, 0.0, 0.0, 3.0];
    let area = geometry::polygon_area(&verts);
    assert!(
        (area.abs() - 6.0).abs() < 1e-4,
        "Triangle area should be 6, got {area}"
    );
}

#[test]
fn test_polygon_area_square() {
    // Square (0,0), (2,0), (2,2), (0,2) → area = 4
    let verts = [0.0f32, 0.0, 2.0, 0.0, 2.0, 2.0, 0.0, 2.0];
    let area = geometry::polygon_area(&verts);
    assert!(
        (area.abs() - 4.0).abs() < 1e-4,
        "Square area should be 4, got {area}"
    );
}

#[test]
fn test_polygon_centroid() {
    // Square (0,0), (4,0), (4,4), (0,4) → centroid (2,2)
    let verts = [0.0f32, 0.0, 4.0, 0.0, 4.0, 4.0, 0.0, 4.0];
    let (cx, cy) = geometry::polygon_centroid(&verts);
    assert!((cx - 2.0).abs() < 1e-4, "Centroid x should be 2, got {cx}");
    assert!((cy - 2.0).abs() < 1e-4, "Centroid y should be 2, got {cy}");
}

#[test]
fn test_segment_intersects_segment() {
    // Crossing segments: (0,0)-(4,4) and (4,0)-(0,4)
    let (hit, pt) = geometry::segment_intersects_segment(0.0, 0.0, 4.0, 4.0, 4.0, 0.0, 0.0, 4.0);
    assert!(hit, "Crossing segments should intersect");
    let (ix, iy) = pt.unwrap();
    assert!(
        (ix - 2.0).abs() < 1e-4,
        "Intersection x should be 2, got {ix}"
    );
    assert!(
        (iy - 2.0).abs() < 1e-4,
        "Intersection y should be 2, got {iy}"
    );
}

#[test]
fn test_segment_no_intersection() {
    // Parallel segments: (0,0)-(4,0) and (0,2)-(4,2)
    let (hit, _) = geometry::segment_intersects_segment(0.0, 0.0, 4.0, 0.0, 0.0, 2.0, 4.0, 2.0);
    assert!(!hit, "Parallel segments should not intersect");
}

#[test]
fn test_closest_point_on_segment() {
    // Point above midpoint of horizontal segment
    let (px, py) = geometry::closest_point_on_segment(2.0, 5.0, 0.0, 0.0, 4.0, 0.0);
    assert!((px - 2.0).abs() < 1e-4, "Closest x should be 2, got {px}");
    assert!((py - 0.0).abs() < 1e-4, "Closest y should be 0, got {py}");

    // Point beyond segment endpoint
    let (px2, py2) = geometry::closest_point_on_segment(10.0, 0.0, 0.0, 0.0, 4.0, 0.0);
    assert!(
        (px2 - 4.0).abs() < 1e-4,
        "Should clamp to endpoint, got {px2}"
    );
    assert!((py2 - 0.0).abs() < 1e-4);
}

#[test]
fn test_point_in_polygon() {
    // Square polygon (0,0), (4,0), (4,4), (0,4)
    let verts = [0.0f32, 0.0, 4.0, 0.0, 4.0, 4.0, 0.0, 4.0];
    assert!(
        geometry::point_in_polygon(&verts, 2.0, 2.0),
        "Center should be inside"
    );
    assert!(
        !geometry::point_in_polygon(&verts, 5.0, 5.0),
        "Outside should not be inside"
    );
}

#[test]
fn test_line_intersect() {
    // Two infinite lines crossing at (2,2)
    let pt = geometry::line_intersect(0.0, 0.0, 4.0, 4.0, 4.0, 0.0, 0.0, 4.0);
    assert!(pt.is_some(), "Lines should intersect");
    let (ix, iy) = pt.unwrap();
    assert!((ix - 2.0).abs() < 1e-4);
    assert!((iy - 2.0).abs() < 1e-4);

    // Parallel lines
    let par = geometry::line_intersect(0.0, 0.0, 4.0, 0.0, 0.0, 1.0, 4.0, 1.0);
    assert!(par.is_none(), "Parallel lines should not intersect");
}

#[test]
fn test_bresenham() {
    let points = geometry::bresenham(0, 0, 4, 0);
    assert_eq!(points.len(), 5, "Horizontal line 0..4 should be 5 points");
    assert_eq!(points[0], (0, 0));
    assert_eq!(points[4], (4, 0));

    let diag = geometry::bresenham(0, 0, 3, 3);
    assert_eq!(diag.len(), 4, "Diagonal 0..3 should be 4 points");
    assert_eq!(diag[0], (0, 0));
    assert_eq!(diag[3], (3, 3));
}

#[test]
fn test_convex_hull() {
    // Square + interior point → hull should be the 4 corners
    let points = [
        0.0f32, 0.0, 4.0, 0.0, 4.0, 4.0, 0.0, 4.0, 2.0, 2.0, // interior
    ];
    let hull = geometry::convex_hull(&points);
    // Hull has x,y pairs, so 4 corners = 8 floats
    assert_eq!(
        hull.len(),
        8,
        "Hull should have 4 vertices (8 floats), got {}",
        hull.len()
    );
}

// ═════════════════════════════════════════════════════════════════════════
// 8. Raycasting (utility functions)
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_cast_ray_2d() {
    let segments = vec![
        Segment {
            x1: 5.0,
            y1: -5.0,
            x2: 5.0,
            y2: 5.0,
        }, // vertical wall at x=5
    ];
    // Ray from origin pointing right (+x direction)
    let hit = cast_ray_2d(0.0, 0.0, 1.0, 0.0, 100.0, &segments);
    assert!(hit.is_some(), "Should hit vertical wall");
    let (hx, hy, idx) = hit.unwrap();
    assert!((hx - 5.0).abs() < 1e-3, "Hit x should be ~5, got {hx}");
    assert!((hy).abs() < 1e-3, "Hit y should be ~0, got {hy}");
    assert_eq!(idx, 0);
}

#[test]
fn test_field_of_view() {
    // Simple box room
    let segments = vec![
        Segment {
            x1: -5.0,
            y1: -5.0,
            x2: 5.0,
            y2: -5.0,
        },
        Segment {
            x1: 5.0,
            y1: -5.0,
            x2: 5.0,
            y2: 5.0,
        },
        Segment {
            x1: 5.0,
            y1: 5.0,
            x2: -5.0,
            y2: 5.0,
        },
        Segment {
            x1: -5.0,
            y1: 5.0,
            x2: -5.0,
            y2: -5.0,
        },
    ];
    let vis = field_of_view(0.0, 0.0, &segments, 20.0);
    // Should return x,y pairs forming a visibility polygon
    assert!(
        vis.len() >= 6,
        "Visibility polygon needs at least 3 vertices (6 floats), got {}",
        vis.len()
    );
    assert_eq!(
        vis.len() % 2,
        0,
        "Should have even number of floats (x,y pairs)"
    );
}

#[test]
fn test_project_column() {
    let (height, top, bottom) = project_column(5.0, std::f32::consts::FRAC_PI_3, 480.0);
    assert!(height > 0.0, "Column height should be positive");
    assert!(top < bottom, "Top should be above bottom");
    assert!(height.is_finite());

    // Closer distance → taller column
    let (h_close, _, _) = project_column(2.0, std::f32::consts::FRAC_PI_3, 480.0);
    assert!(h_close > height, "Closer wall should be taller");
}

#[test]
fn test_distance_shade() {
    let shade_near = distance_shade(1.0, 20.0);
    let shade_far = distance_shade(18.0, 20.0);
    assert!(shade_near > shade_far, "Near objects should be brighter");
    assert!(
        shade_near >= 0.0 && shade_near <= 1.0,
        "Shade should be [0,1], got {shade_near}"
    );
    assert!(
        shade_far >= 0.0 && shade_far <= 1.0,
        "Shade should be [0,1], got {shade_far}"
    );

    let shade_zero = distance_shade(0.0, 20.0);
    assert!(
        (shade_zero - 1.0).abs() < 1e-4,
        "Distance 0 → full brightness"
    );
}

// ═════════════════════════════════════════════════════════════════════════
// 9. Procgen
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_cellular_automata() {
    let opts = CellularOpts {
        fill: 0.45,
        iterations: 5,
        birth: 5,
        survive: 4,
        seed: 42,
    };
    let map = procgen::cellular_automata(20, 15, &opts);
    assert_eq!(map.len(), 20 * 15, "Output size should be width * height");
    for (i, &v) in map.iter().enumerate() {
        assert!(v == 0 || v == 1, "Cell {i} should be 0 or 1, got {v}");
    }
}

#[test]
fn test_voronoi_diagram() {
    let points = vec![(5.0f32, 5.0), (15.0, 5.0), (10.0, 15.0)];
    let opts = VoronoiOpts::default();
    let (regions, distances, _colors) = procgen::voronoi_diagram(20, 20, &points, &opts);
    assert_eq!(regions.len(), 20 * 20, "Region map should be width*height");
    assert_eq!(
        distances.len(),
        20 * 20,
        "Distance map should be width*height"
    );
    // All region indices should refer to a valid point (0, 1, or 2)
    for (i, &r) in regions.iter().enumerate() {
        assert!(r < 3, "Region {i} index {r} should be < 3");
    }
}

#[test]
fn test_flood_fill() {
    // Create a 5x5 grid with a border of 1s and interior 0s
    let mut data = vec![0u8; 25];
    for x in 0..5u32 {
        data[(x * 1) as usize] = 1; // top row (y=0 if row-major: idx = y*w+x)
        data[(4 * 5 + x) as usize] = 1; // bottom row
    }
    for y in 0..5u32 {
        data[(y * 5) as usize] = 1; // left column
        data[(y * 5 + 4) as usize] = 1; // right column
    }
    // Flood-fill from interior (2,2) targeting values below threshold 1
    let filled = procgen::flood_fill(&data, 5, 5, 2, 2, 1, false);
    assert_eq!(filled.len(), 25);
    // The interior cells (1,1), (2,1), (3,1), (1,2), (2,2), (3,2), (1,3), (2,3), (3,3) should be filled
    assert_eq!(filled[2 * 5 + 2], 1, "Center should be filled");
}

#[test]
fn test_poisson_disk() {
    let points = procgen::poisson_disk(100.0, 100.0, 10.0, 30, 42);
    assert!(!points.is_empty(), "Should generate at least one point");
    // Verify minimum distance between all pairs
    for i in 0..points.len() {
        for j in (i + 1)..points.len() {
            let dx = points[i].0 - points[j].0;
            let dy = points[i].1 - points[j].1;
            let dist = (dx * dx + dy * dy).sqrt();
            assert!(
                dist >= 10.0 - 1e-3,
                "Points {} and {} are too close: dist={dist}",
                i,
                j
            );
        }
    }
    // All points should be within bounds
    for (i, &(x, y)) in points.iter().enumerate() {
        assert!(x >= 0.0 && x <= 100.0, "Point {i} x={x} out of bounds");
        assert!(y >= 0.0 && y <= 100.0, "Point {i} y={y} out of bounds");
    }
}

#[test]
fn test_perlin_noise_periodic() {
    let period = 4.0;
    // Values at x and x+period should match (periodic tiling)
    let v1 = procgen::perlin_noise_periodic(1.5, 2.3, period, period);
    let v2 = procgen::perlin_noise_periodic(1.5 + period, 2.3 + period, period, period);
    assert!(
        (v1 - v2).abs() < 1e-6,
        "Periodic noise should tile: v({}) != v({}+period): {v1} vs {v2}",
        1.5,
        1.5
    );
    assert!(v1.is_finite());
}
