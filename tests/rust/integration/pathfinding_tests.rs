//! Integration tests for the `math::pathfinding` module.

use std::cell::RefCell;
use std::rc::Rc;

use lurek2d::pathfind::{DiagonalMode, FlowField, NavGrid, UnitPathfinder, Waypoint};

// ============================================================
// NavGrid
// ============================================================

#[test]
fn nav_grid_new_dimensions() {
    let grid = NavGrid::new(20, 15);
    assert_eq!(grid.get_width(), 20);
    assert_eq!(grid.get_height(), 15);
    assert_eq!(grid.get_dimensions(), (20, 15));
}

#[test]
fn nav_grid_new_all_walkable() {
    let grid = NavGrid::new(10, 10);
    for y in 0..10 {
        for x in 0..10 {
            assert_eq!(
                grid.get_cost(x, y),
                1,
                "cell ({x},{y}) should default to cost 1"
            );
            assert!(
                !grid.is_blocked(x, y),
                "cell ({x},{y}) should not be blocked"
            );
        }
    }
}

#[test]
fn nav_grid_set_get_cost() {
    let mut grid = NavGrid::new(5, 5);
    grid.set_cost(2, 3, 10);
    assert_eq!(grid.get_cost(2, 3), 10);
    // Other cells untouched
    assert_eq!(grid.get_cost(0, 0), 1);
}

#[test]
fn nav_grid_cost_out_of_bounds() {
    let grid = NavGrid::new(5, 5);
    assert_eq!(grid.get_cost(10, 10), 0, "out-of-bounds cost should be 0");
}

#[test]
fn nav_grid_blocked() {
    let mut grid = NavGrid::new(5, 5);
    assert!(!grid.is_blocked(2, 2));
    grid.set_blocked(2, 2, true);
    assert!(grid.is_blocked(2, 2));
    assert_eq!(grid.get_cost(2, 2), 0);
    // Unblock
    grid.set_blocked(2, 2, false);
    assert!(!grid.is_blocked(2, 2));
    assert_eq!(grid.get_cost(2, 2), 1);
}

#[test]
fn nav_grid_walkable_unit_size() {
    let mut grid = NavGrid::new(10, 10);
    // 1x1 should be walkable on open grid
    assert!(grid.is_walkable(0, 0, 1));
    // 2x2 at (0,0) should be walkable
    assert!(grid.is_walkable(0, 0, 2));
    // Block one cell in the 2x2 footprint
    grid.set_blocked(1, 0, true);
    assert!(
        !grid.is_walkable(0, 0, 2),
        "2x2 should fail when one cell blocked"
    );
    // 1x1 at (0,0) still fine
    assert!(grid.is_walkable(0, 0, 1));
}

#[test]
fn nav_grid_walkable_out_of_bounds() {
    let grid = NavGrid::new(5, 5);
    // 2x2 at edge should fail
    assert!(!grid.is_walkable(4, 4, 2));
    // 1x1 at edge is fine
    assert!(grid.is_walkable(4, 4, 1));
}

#[test]
fn nav_grid_fill() {
    let mut grid = NavGrid::new(5, 5);
    grid.fill(5);
    for y in 0..5 {
        for x in 0..5 {
            assert_eq!(grid.get_cost(x, y), 5);
        }
    }
    // Fill with 0 blocks everything
    grid.fill(0);
    assert!(grid.is_blocked(0, 0));
    assert!(grid.is_blocked(4, 4));
}

#[test]
fn nav_grid_fill_rect() {
    let mut grid = NavGrid::new(10, 10);
    grid.fill_rect(2, 3, 4, 3, 0);
    // Inside rect → blocked
    assert!(grid.is_blocked(2, 3));
    assert!(grid.is_blocked(5, 5));
    // Outside rect → not blocked
    assert!(!grid.is_blocked(1, 3));
    assert!(!grid.is_blocked(6, 3));
    assert!(!grid.is_blocked(2, 2));
    assert!(!grid.is_blocked(2, 6));
}

#[test]
fn nav_grid_save_load_roundtrip() {
    let mut grid = NavGrid::new(4, 4);
    grid.set_cost(0, 0, 10);
    grid.set_cost(3, 3, 200);
    grid.set_blocked(1, 1, true);

    let bytes = grid.save_to_bytes();
    assert_eq!(bytes.len(), 16);

    let mut grid2 = NavGrid::new(4, 4);
    grid2.load_from_bytes(&bytes).expect("load should succeed");

    assert_eq!(grid2.get_cost(0, 0), 10);
    assert_eq!(grid2.get_cost(3, 3), 200);
    assert!(grid2.is_blocked(1, 1));
    assert_eq!(grid2.get_cost(2, 2), 1);
}

#[test]
fn nav_grid_load_from_bytes_wrong_size() {
    let mut grid = NavGrid::new(4, 4);
    let result = grid.load_from_bytes(&[1, 2, 3]);
    assert!(result.is_err());
}

#[test]
fn nav_grid_neighbors_cardinal_only() {
    let mut grid = NavGrid::new(5, 5);
    grid.set_diagonal_mode(DiagonalMode::None);
    // Center cell (2,2) with no walls → 4 cardinal neighbors
    let n = grid.neighbors(2, 2);
    assert_eq!(n.len(), 4);
    assert!(n.contains(&(2, 1))); // up
    assert!(n.contains(&(2, 3))); // down
    assert!(n.contains(&(1, 2))); // left
    assert!(n.contains(&(3, 2))); // right
}

#[test]
fn nav_grid_neighbors_with_diagonals() {
    let mut grid = NavGrid::new(5, 5);
    grid.set_diagonal_mode(DiagonalMode::Always);
    let n = grid.neighbors(2, 2);
    assert_eq!(n.len(), 8);
    // Check one cardinal and one diagonal
    assert!(n.contains(&(2, 1))); // up
    assert!(n.contains(&(1, 1))); // up-left diagonal
    assert!(n.contains(&(3, 3))); // down-right diagonal
}

#[test]
fn nav_grid_neighbors_corner_no_cut() {
    let mut grid = NavGrid::new(5, 5);
    grid.set_diagonal_mode(DiagonalMode::NoCornerCut);
    // Block the cell to the left of center
    grid.set_blocked(1, 2, true);
    let n = grid.neighbors(2, 2);
    // Should have cardinal: up, down, right (not left since blocked)
    // Diagonals: (3,1) and (3,3) allowed, (1,1) and (1,3) blocked (left blocked)
    assert!(n.contains(&(2, 1))); // up
    assert!(n.contains(&(2, 3))); // down
    assert!(n.contains(&(3, 2))); // right
    assert!(!n.contains(&(1, 2))); // left is blocked
    assert!(!n.contains(&(1, 1))); // up-left blocked (left blocked)
    assert!(!n.contains(&(1, 3))); // down-left blocked (left blocked)
    assert!(n.contains(&(3, 1))); // up-right ok
    assert!(n.contains(&(3, 3))); // down-right ok
}

#[test]
fn nav_grid_dirty_rects() {
    let mut grid = NavGrid::new(10, 10);
    assert!(grid.dirty_rects().is_empty());
    grid.set_dirty(0, 0, 5, 5);
    grid.set_dirty(3, 3, 2, 2);
    assert_eq!(grid.dirty_rects().len(), 2);
    grid.clear_dirty();
    assert!(grid.dirty_rects().is_empty());
}

#[test]
fn nav_grid_chunk_size() {
    let mut grid = NavGrid::new(100, 100);
    assert_eq!(grid.get_chunk_size(), 16); // default
    grid.set_chunk_size(8);
    assert_eq!(grid.get_chunk_size(), 8);
    // Clamped to min 2
    grid.set_chunk_size(1);
    assert_eq!(grid.get_chunk_size(), 2);
}

#[test]
fn nav_grid_diagonal_mode_getset() {
    let mut grid = NavGrid::new(5, 5);
    // Default is NoCornerCut
    assert_eq!(grid.get_diagonal_mode(), DiagonalMode::NoCornerCut);
    grid.set_diagonal_mode(DiagonalMode::None);
    assert_eq!(grid.get_diagonal_mode(), DiagonalMode::None);
    grid.set_diagonal_mode(DiagonalMode::Always);
    assert_eq!(grid.get_diagonal_mode(), DiagonalMode::Always);
}

// ============================================================
// DiagonalMode
// ============================================================

#[test]
fn diagonal_mode_from_lua_str() {
    assert_eq!(DiagonalMode::from_lua_str("none"), Some(DiagonalMode::None));
    assert_eq!(
        DiagonalMode::from_lua_str("always"),
        Some(DiagonalMode::Always)
    );
    assert_eq!(
        DiagonalMode::from_lua_str("nocornercut"),
        Some(DiagonalMode::NoCornerCut)
    );
    assert_eq!(
        DiagonalMode::from_lua_str("no_corner_cut"),
        Some(DiagonalMode::NoCornerCut)
    );
    // Case insensitive
    assert_eq!(DiagonalMode::from_lua_str("NONE"), Some(DiagonalMode::None));
    assert_eq!(
        DiagonalMode::from_lua_str("Always"),
        Some(DiagonalMode::Always)
    );
}

#[test]
fn diagonal_mode_from_lua_str_unknown() {
    assert_eq!(DiagonalMode::from_lua_str("unknown"), Option::None);
    assert_eq!(DiagonalMode::from_lua_str(""), Option::None);
    assert_eq!(DiagonalMode::from_lua_str("diagonal"), Option::None);
}

// ============================================================
// UnitPathfinder
// ============================================================

#[test]
fn pathfinder_finds_simple_path() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut pf = UnitPathfinder::new(grid);
    let path = pf.find_path(0, 0, 9, 9, 1);
    assert!(path.is_some(), "should find path on open grid");
    let path = path.unwrap();
    assert!(!path.is_empty());
}

#[test]
fn pathfinder_returns_none_when_blocked() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    // Block start cell — no expansion possible → None
    {
        let mut g = grid.borrow_mut();
        g.set_blocked(0, 0, true);
    }
    let mut pf = UnitPathfinder::new(grid);
    let path = pf.find_path(0, 0, 9, 9, 1);
    assert!(path.is_none(), "blocked start should return None");
}

#[test]
fn pathfinder_wall_returns_partial_path() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    // Build a wall across column 5
    {
        let mut g = grid.borrow_mut();
        for y in 0..10 {
            g.set_blocked(5, y, true);
        }
    }
    let mut pf = UnitPathfinder::new(grid);
    let path = pf.find_path(0, 0, 9, 9, 1);
    // A* returns a partial path to the closest expanded node when goal is unreachable
    assert!(path.is_some(), "should return partial path");
    let path = path.unwrap();
    let last = path.last().unwrap();
    assert!(last.x < 5, "partial path should not cross the wall");
}

#[test]
fn pathfinder_path_starts_and_ends_correctly() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut pf = UnitPathfinder::new(grid);
    let path = pf.find_path(1, 2, 8, 7, 1).unwrap();
    assert_eq!(path.first().unwrap().x, 1);
    assert_eq!(path.first().unwrap().y, 2);
    assert_eq!(path.last().unwrap().x, 8);
    assert_eq!(path.last().unwrap().y, 7);
}

#[test]
fn pathfinder_smooth_path() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut pf = UnitPathfinder::new(grid);
    let normal = pf.find_path(0, 0, 9, 9, 1).unwrap();
    let smooth = pf.find_path_smooth(0, 0, 9, 9, 1).unwrap();
    // Smooth path should have same or fewer waypoints
    assert!(smooth.len() <= normal.len());
    // Both should start and end at same points
    assert_eq!(smooth.first().unwrap().x, 0);
    assert_eq!(smooth.first().unwrap().y, 0);
    assert_eq!(smooth.last().unwrap().x, 9);
    assert_eq!(smooth.last().unwrap().y, 9);
}

#[test]
fn pathfinder_unit_size_aware() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    // Create a 1-wide gap at column 5, row 5
    {
        let mut g = grid.borrow_mut();
        for y in 0..10 {
            g.set_blocked(5, y, true);
        }
        g.set_blocked(5, 5, false); // open one cell
    }
    let mut pf = UnitPathfinder::new(grid);
    // 1x1 can pass
    let path1 = pf.find_path(0, 0, 9, 9, 1);
    assert!(path1.is_some(), "1x1 should fit through 1-wide gap");
    let last1 = path1.unwrap().last().unwrap().clone();
    assert_eq!((last1.x, last1.y), (9, 9), "1x1 path should reach goal");
    // 2x2 gets a partial path that doesn't reach the goal
    let path2 = pf.find_path(0, 0, 8, 8, 2);
    if let Some(p) = &path2 {
        let last = p.last().unwrap();
        assert!(last.x < 5, "2x2 partial path should not cross the gap");
    }
}

#[test]
fn pathfinder_partial_path() {
    let grid = Rc::new(RefCell::new(NavGrid::new(20, 20)));
    let pf = UnitPathfinder::new(grid);
    // Very few max_nodes on a long path
    let (path, complete) = pf.find_partial_path(0, 0, 19, 19, 5, 1);
    // With only 5 node expansions, unlikely to complete such a long path
    // But we should still get some partial path
    assert!(
        !path.is_empty() || !complete,
        "partial path should return something or indicate incomplete"
    );
}

#[test]
fn pathfinder_partial_path_complete() {
    let grid = Rc::new(RefCell::new(NavGrid::new(3, 3)));
    let pf = UnitPathfinder::new(grid);
    // Small grid, unlimited nodes (0 = unlimited)
    let (path, complete) = pf.find_partial_path(0, 0, 2, 2, 0, 1);
    assert!(complete, "should complete on small grid");
    assert!(!path.is_empty());
}

#[test]
fn pathfinder_find_nearest_walkable() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    {
        let mut g = grid.borrow_mut();
        g.set_blocked(5, 5, true);
    }
    let pf = UnitPathfinder::new(grid);
    // From a blocked cell, find nearest walkable
    let result = pf.find_nearest_walkable(5, 5, 3, 1);
    assert!(result.is_some(), "should find walkable cell nearby");
    let (rx, ry) = result.unwrap();
    // Should be adjacent to (5,5)
    let dist = ((rx as i32 - 5).abs() + (ry as i32 - 5).abs()) as u32;
    assert!(dist <= 1, "nearest walkable should be adjacent");
}

#[test]
fn pathfinder_find_nearest_walkable_already_walkable() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let pf = UnitPathfinder::new(grid);
    let result = pf.find_nearest_walkable(3, 3, 5, 1);
    assert_eq!(result, Some((3, 3)), "already walkable cell returns itself");
}

#[test]
fn pathfinder_find_nearest_walkable_none() {
    let grid = Rc::new(RefCell::new(NavGrid::new(5, 5)));
    {
        let mut g = grid.borrow_mut();
        g.fill(0); // all blocked
    }
    let pf = UnitPathfinder::new(grid);
    let result = pf.find_nearest_walkable(2, 2, 10, 1);
    assert!(result.is_none(), "all blocked → no walkable cell");
}

#[test]
fn pathfinder_is_reachable() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let pf = UnitPathfinder::new(grid);
    assert!(pf.is_reachable(0, 0, 9, 9, 1), "open grid is reachable");
}

#[test]
fn pathfinder_is_reachable_disconnected() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    {
        let mut g = grid.borrow_mut();
        for y in 0..10 {
            g.set_blocked(5, y, true);
        }
    }
    let pf = UnitPathfinder::new(grid);
    assert!(!pf.is_reachable(0, 0, 9, 9, 1), "wall disconnects regions");
}

#[test]
fn pathfinder_is_reachable_blocked_start() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    {
        let mut g = grid.borrow_mut();
        g.set_blocked(0, 0, true);
    }
    let pf = UnitPathfinder::new(grid);
    assert!(
        !pf.is_reachable(0, 0, 9, 9, 1),
        "blocked start is unreachable"
    );
}

#[test]
fn pathfinder_heuristic_distance() {
    // Same cell
    let d = UnitPathfinder::heuristic_distance(5, 5, 5, 5);
    assert!((d - 0.0).abs() < 1e-5, "same cell distance should be 0");

    // Cardinal move (1 step right)
    let d = UnitPathfinder::heuristic_distance(0, 0, 1, 0);
    assert!((d - 1.0).abs() < 1e-5, "cardinal distance should be 1");

    // Diagonal move (1 step diagonal)
    let d = UnitPathfinder::heuristic_distance(0, 0, 1, 1);
    assert!(
        (d - std::f32::consts::SQRT_2).abs() < 1e-5,
        "diagonal distance should be sqrt(2)"
    );

    // Octile: (0,0) to (3,4) → min=3, max=4 → 3*SQRT_2 + (4-3) = 3*1.4142.. + 1 ≈ 5.2426
    let d = UnitPathfinder::heuristic_distance(0, 0, 3, 4);
    let expected = 3.0 * std::f32::consts::SQRT_2 + 1.0;
    assert!((d - expected).abs() < 1e-4, "octile distance mismatch");
}

#[test]
fn pathfinder_line_of_sight() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let pf = UnitPathfinder::new(grid);
    // Clear grid — LoS everywhere
    assert!(pf.line_of_sight(0, 0, 9, 9, 1));
    assert!(pf.line_of_sight(0, 0, 9, 0, 1));
}

#[test]
fn pathfinder_line_of_sight_blocked() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    {
        let mut g = grid.borrow_mut();
        for y in 0..10 {
            g.set_blocked(5, y, true);
        }
    }
    let pf = UnitPathfinder::new(grid);
    assert!(!pf.line_of_sight(0, 0, 9, 0, 1), "wall should block LoS");
}

#[test]
fn pathfinder_cache_operations() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut pf = UnitPathfinder::new(grid);
    assert!(pf.is_cache_enabled(), "cache enabled by default");
    assert_eq!(pf.get_cache_size(), 0);

    // Finding a path populates cache
    pf.find_path(0, 0, 5, 5, 1);
    assert!(
        pf.get_cache_size() > 0,
        "cache should have entries after find_path"
    );

    // Clear cache
    pf.clear_cache();
    assert_eq!(pf.get_cache_size(), 0);

    // Disable cache
    pf.set_cache_enabled(false);
    assert!(!pf.is_cache_enabled());
    pf.find_path(0, 0, 5, 5, 1);
    assert_eq!(pf.get_cache_size(), 0, "disabled cache should not store");

    // Re-enable
    pf.set_cache_enabled(true);
    assert!(pf.is_cache_enabled());
}

#[test]
fn pathfinder_cache_max_size() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut pf = UnitPathfinder::new(grid);
    pf.set_cache_max_size(2);
    // Fill cache with 3 entries → only 2 should remain
    pf.find_path(0, 0, 1, 1, 1);
    pf.find_path(0, 0, 2, 2, 1);
    pf.find_path(0, 0, 3, 3, 1);
    assert!(pf.get_cache_size() <= 2, "cache should respect max size");
}

#[test]
fn pathfinder_path_length() {
    // Straight horizontal path
    let path = vec![
        Waypoint { x: 0, y: 0 },
        Waypoint { x: 1, y: 0 },
        Waypoint { x: 2, y: 0 },
        Waypoint { x: 3, y: 0 },
    ];
    let len = UnitPathfinder::get_path_length(&path);
    assert!((len - 3.0).abs() < 1e-5, "3 cardinal steps = length 3");
}

#[test]
fn pathfinder_path_length_diagonal() {
    let path = vec![Waypoint { x: 0, y: 0 }, Waypoint { x: 1, y: 1 }];
    let len = UnitPathfinder::get_path_length(&path);
    assert!((len - std::f32::consts::SQRT_2).abs() < 1e-5);
}

#[test]
fn pathfinder_path_length_empty() {
    let len = UnitPathfinder::get_path_length(&[]);
    assert!((len - 0.0).abs() < 1e-5);
}

#[test]
fn pathfinder_path_cost() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    {
        let mut g = grid.borrow_mut();
        g.set_cost(1, 0, 5);
        g.set_cost(2, 0, 10);
    }
    let pf = UnitPathfinder::new(grid);
    let path = vec![
        Waypoint { x: 0, y: 0 },
        Waypoint { x: 1, y: 0 },
        Waypoint { x: 2, y: 0 },
    ];
    let cost = pf.get_path_cost(&path);
    // cost(0,0)=1 + cost(1,0)=5 + cost(2,0)=10 = 16
    assert!((cost - 16.0).abs() < 1e-5);
}

// ============================================================
// FlowField
// ============================================================

#[test]
fn flow_field_new_not_calculated() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let ff = FlowField::new(grid);
    assert!(!ff.is_calculated());
    assert!(ff.get_targets().is_empty());
}

#[test]
fn flow_field_calculate_single_target() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut ff = FlowField::new(grid);
    ff.calculate(9, 9, 1);
    assert!(ff.is_calculated());

    // Direction at (0,0) should point toward (9,9) — positive dx, positive dy
    let (dx, dy) = ff.get_direction(0, 0);
    assert!(dx > 0.0, "dx at (0,0) should be positive toward (9,9)");
    assert!(dy > 0.0, "dy at (0,0) should be positive toward (9,9)");

    // Direction should be normalized
    let len = (dx * dx + dy * dy).sqrt();
    assert!((len - 1.0).abs() < 1e-5, "direction should be normalized");
}

#[test]
fn flow_field_target_cell_direction() {
    let grid = Rc::new(RefCell::new(NavGrid::new(5, 5)));
    let mut ff = FlowField::new(grid);
    ff.calculate(2, 2, 1);
    // Target cell itself has cost 0, direction (0,0)
    let (dx, dy) = ff.get_direction(2, 2);
    assert!(
        (dx - 0.0).abs() < 1e-5,
        "target cell direction should be (0,0)"
    );
    assert!((dy - 0.0).abs() < 1e-5);
}

#[test]
fn flow_field_cost_to_target() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut ff = FlowField::new(grid);
    ff.calculate(5, 5, 1);
    // Target cell cost is 0
    let cost_target = ff.get_cost_to_target(5, 5);
    assert!(
        (cost_target - 0.0).abs() < 1e-5,
        "target should have cost 0"
    );
    // Adjacent cell cost > 0
    let cost_adj = ff.get_cost_to_target(5, 4);
    assert!(cost_adj > 0.0, "adjacent cell should have positive cost");
    assert!(
        cost_adj < f32::INFINITY,
        "adjacent cell should be reachable"
    );
    // Far cell has higher cost
    let cost_far = ff.get_cost_to_target(0, 0);
    assert!(cost_far > cost_adj, "farther cell should have higher cost");
}

#[test]
fn flow_field_direction_angle() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut ff = FlowField::new(grid);
    ff.calculate(9, 9, 1);
    let angle = ff.get_direction_angle(0, 0);
    // Should point toward (9,9) → angle ≈ π/4 (45°)
    assert!(
        angle > 0.0,
        "angle should be positive for down-right direction"
    );
    assert!(
        angle < std::f64::consts::PI as f32,
        "angle should be in valid range"
    );
}

#[test]
fn nav_grid_from_costs() {
    let costs = vec![1, 0, 1, 1, 1, 0, 0, 1, 1];
    let grid = NavGrid::from_costs(3, 3, costs);
    assert_eq!(grid.get_width(), 3);
    assert_eq!(grid.get_height(), 3);
    assert_eq!(grid.get_cost(0, 0), 1);
    assert_eq!(grid.get_cost(1, 0), 0); // blocked
    assert_eq!(grid.get_cost(2, 0), 1);
    assert_eq!(grid.get_cost(2, 1), 0); // blocked
}

#[test]
fn flow_field_steer() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut ff = FlowField::new(grid);
    ff.calculate(9, 9, 1);

    let speed = 100.0;
    let (vx, vy) = ff.steer(0.5, 0.5, speed, 1.0, 1.0);
    // Velocity should point toward target, scaled by speed
    assert!(
        vx > 0.0 || vy > 0.0,
        "steer velocity should point toward target"
    );
}

#[test]
fn flow_field_steer_zero_tile_size() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut ff = FlowField::new(grid);
    ff.calculate(9, 9, 1);
    let (vx, vy) = ff.steer(5.0, 5.0, 100.0, 0.0, 0.0);
    assert!((vx - 0.0).abs() < 1e-5, "zero tile size → zero velocity");
    assert!((vy - 0.0).abs() < 1e-5);
}

#[test]
fn flow_field_blocked_cell_unreachable() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    {
        let mut g = grid.borrow_mut();
        g.set_blocked(3, 3, true);
    }
    let mut ff = FlowField::new(grid);
    ff.calculate(9, 9, 1);
    let cost = ff.get_cost_to_target(3, 3);
    assert!(
        cost == f32::INFINITY,
        "blocked cell should have infinite cost"
    );
}

#[test]
fn flow_field_multi_target() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut ff = FlowField::new(grid);
    let targets = vec![(0, 0), (9, 9)];
    ff.calculate_multi(&targets, 1);
    assert!(ff.is_calculated());
    assert_eq!(ff.get_targets().len(), 2);

    // Both targets should have cost 0
    let cost_a = ff.get_cost_to_target(0, 0);
    let cost_b = ff.get_cost_to_target(9, 9);
    assert!((cost_a - 0.0).abs() < 1e-5);
    assert!((cost_b - 0.0).abs() < 1e-5);

    // Middle cell should be reachable and closer to one target
    let cost_mid = ff.get_cost_to_target(5, 5);
    assert!(cost_mid > 0.0 && cost_mid < f32::INFINITY);
}

#[test]
fn flow_field_out_of_bounds() {
    let grid = Rc::new(RefCell::new(NavGrid::new(5, 5)));
    let mut ff = FlowField::new(grid);
    ff.calculate(2, 2, 1);
    let (dx, dy) = ff.get_direction(100, 100);
    assert!((dx - 0.0).abs() < 1e-5);
    assert!((dy - 0.0).abs() < 1e-5);
    assert!(ff.get_cost_to_target(100, 100) == f32::INFINITY);
}

#[test]
fn flow_field_get_targets() {
    let grid = Rc::new(RefCell::new(NavGrid::new(10, 10)));
    let mut ff = FlowField::new(grid);
    ff.calculate(3, 7, 1);
    let targets = ff.get_targets();
    assert_eq!(targets.len(), 1);
    assert_eq!(targets[0], (3, 7));
}
