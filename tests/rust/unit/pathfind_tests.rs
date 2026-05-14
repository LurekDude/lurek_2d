//! INTERNAL ONLY: Rust-only tests for pathfinding internals that are not asserted through the
//! Lua-facing `lurek.pathfind.*` API.
//!
//! Grid/path behaviour is covered by `tests/lua/unit/test_pathfind_unit.lua`.
//! The remaining Rust coverage here keeps only the thread-pool helper
//! invariant.

use lurek2d::pathfind::NavMesh;
use lurek2d::pathfind::PathThreadPool;

mod async_pool_tests {
    use super::*;

    #[test]
    fn default_thread_count() {
        let pool = PathThreadPool::new(0);
        assert!(pool.get_thread_count() >= 1);
    }
}

mod navmesh_tests {
    use super::*;

    #[test]
    fn navmesh_add_polygon_requires_three_vertices() {
        let mut mesh = NavMesh::new();
        assert!(mesh.add_polygon(vec![(0.0, 0.0), (1.0, 0.0)]).is_none());
        assert_eq!(mesh.polygon_count(), 0);
    }

    #[test]
    fn navmesh_finds_path_through_connected_polygons() {
        let mut mesh = NavMesh::new();
        let a = mesh
            .add_polygon(vec![(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0)])
            .unwrap();
        let b = mesh
            .add_polygon(vec![(10.0, 0.0), (20.0, 0.0), (20.0, 10.0), (10.0, 10.0)])
            .unwrap();
        assert!(mesh.connect(a, b, true));

        let path = mesh.find_path((2.0, 2.0), (18.0, 8.0));
        assert!(path.is_some());
        assert!(path.unwrap().len() >= 2);
    }
}

mod ai_flow_field_tests {
    use lurek2d::pathfind::ai_flow_field::FlowField;

    fn open_grid(w: usize, h: usize) -> Vec<bool> {
        vec![true; w * h]
    }

    #[test]
    fn test_new_field_has_no_goal() {
        let ff = FlowField::new(4, 4, open_grid(4, 4));
        assert!(ff.goal.is_none());
    }

    #[test]
    fn test_set_goal_computes_directions() {
        let mut ff = FlowField::new(4, 4, open_grid(4, 4));
        ff.set_goal(3, 3);
        assert_eq!(ff.goal, Some((3, 3)));
        assert_eq!(ff.get_distance(3, 3), 0.0);
        assert!(ff.get_distance(0, 0) > 0.0);
        assert!(ff.get_distance(0, 0) < f32::INFINITY);
    }

    #[test]
    fn test_blocked_goal_stays_infinity() {
        let mut walkable = open_grid(3, 3);
        walkable[2 * 3 + 2] = false;
        let mut ff = FlowField::new(3, 3, walkable);
        ff.set_goal(2, 2);
        assert_eq!(ff.get_distance(0, 0), f32::INFINITY);
    }

    #[test]
    fn test_direction_points_toward_goal() {
        let mut ff = FlowField::new(5, 1, open_grid(5, 1));
        ff.set_goal(4, 0);
        let (dx, _dy) = ff.get_direction(0, 0);
        assert!(dx > 0.0, "should point right toward goal");
    }

    #[test]
    fn test_out_of_bounds_returns_defaults() {
        let ff = FlowField::new(2, 2, open_grid(2, 2));
        assert_eq!(ff.get_direction(10, 10), (0.0, 0.0));
        assert_eq!(ff.get_distance(10, 10), f32::INFINITY);
    }
}

mod async_pool_extra_tests {
    use lurek2d::pathfind::PathThreadPool;

    #[test]
    fn test_default_thread_count_minimum_one() {
        let pool = PathThreadPool::new(1);
        assert!(pool.get_thread_count() >= 1);
    }

    #[test]
    fn test_set_thread_count_minimum_one() {
        let mut pool = PathThreadPool::new(1);
        pool.set_thread_count(0);
        assert_eq!(pool.get_thread_count(), 1);
        pool.set_thread_count(4);
        assert_eq!(pool.get_thread_count(), 4);
    }
}

mod bidir_tests {
    use lurek2d::pathfind::bidirectional_astar;
    use lurek2d::pathfind::NavGrid;

    #[test]
    fn test_same_cell_returns_trivial_path() {
        let g = NavGrid::new(5, 5);
        let (p, _) = bidirectional_astar(&g, (2, 2), (2, 2), 1, 10000);
        assert!(p.is_some());
    }

    #[test]
    fn test_straight_line_path() {
        let g = NavGrid::new(10, 1);
        let (p, _) = bidirectional_astar(&g, (0, 0), (9, 0), 1, 10000);
        assert!(p.is_some());
        let path = p.unwrap();
        assert_eq!(*path.first().unwrap(), (0, 0));
        assert_eq!(*path.last().unwrap(), (9, 0));
    }

    #[test]
    fn test_wall_blocks_path() {
        let mut g = NavGrid::new(5, 5);
        for y in 0..5 {
            g.set_blocked(2, y, true);
        }
        let (p, _) = bidirectional_astar(&g, (0, 2), (4, 2), 1, 10000);
        assert!(p.is_none());
    }

    #[test]
    fn test_iteration_limit_triggers_flag() {
        let g = NavGrid::new(50, 50);
        let (_, is_complete) = bidirectional_astar(&g, (0, 0), (49, 49), 1, 5);
        assert!(!is_complete);
    }
}

mod flow_field_tests {
    use lurek2d::pathfind::NavGrid;
    use lurek2d::pathfind::FlowField;
    use std::cell::RefCell;
    use std::rc::Rc;

    fn open_grid(w: u32, h: u32) -> Rc<RefCell<NavGrid>> {
        Rc::new(RefCell::new(NavGrid::new(w, h)))
    }

    #[test]
    fn test_new_field_not_calculated() {
        let g = open_grid(5, 5);
        let ff = FlowField::new(g);
        assert!(!ff.is_calculated());
    }

    #[test]
    fn test_calculate_and_get_direction() {
        let g = open_grid(5, 5);
        let mut ff = FlowField::new(g);
        ff.calculate(4, 4, 1);
        let (dx, dy) = ff.get_direction(0, 0);
        assert!(dx.is_finite() && dy.is_finite());
    }
}

#[cfg(feature = "graph")]
mod graph_nav_tests {
    use lurek2d::graph::core::Graph;
    use lurek2d::pathfind::{graph_astar, graph_range};

    fn simple_graph() -> (Graph, u64, u64, u64) {
        let mut g = Graph::new();
        let n1 = g.add_node("room", 10);
        let n2 = g.add_node("room", 10);
        let n3 = g.add_node("room", 10);
        let _ = g.add_edge(n1, n2, None);
        let _ = g.add_edge(n2, n3, None);
        (g, n1, n2, n3)
    }

    #[test]
    fn test_same_node_path() {
        let (g, n1, _, _) = simple_graph();
        let p = graph_astar(&g, n1, n1, None).unwrap();
        assert_eq!(p, vec![n1]);
    }

    #[test]
    fn test_linear_path() {
        let (g, n1, n2, n3) = simple_graph();
        let p = graph_astar(&g, n1, n3, None).unwrap();
        assert_eq!(p, vec![n1, n2, n3]);
    }

    #[test]
    fn test_no_path_missing_node() {
        let (g, n1, _, _) = simple_graph();
        assert!(graph_astar(&g, n1, 9999, None).is_none());
    }

    #[test]
    fn test_range_query() {
        let (g, n1, n2, n3) = simple_graph();
        let r = graph_range(&g, n1, 1.5);
        let ids: Vec<u64> = r.iter().map(|(id, _)| *id).collect();
        assert!(ids.contains(&n1));
        assert!(ids.contains(&n2));
        let _ = n3;
    }
}

mod iso_grid_tests {
    use lurek2d::pathfind::IsoGrid;

    #[test]
    fn test_new_grid_defaults_unblocked() {
        let g = IsoGrid::new(5, 5);
        assert_eq!(g.width, 5);
        assert_eq!(g.height, 5);
    }

    #[test]
    fn test_blocked_column_no_path() {
        let mut g = IsoGrid::new(3, 3);
        g.set_blocked(1, 0, true);
        g.set_blocked(1, 1, true);
        g.set_blocked(1, 2, true);
        assert!(g.find_path((0, 0), (2, 0)).is_none());
    }

    #[test]
    fn test_trivial_same_cell_returns_single() {
        let g = IsoGrid::new(3, 3);
        let path = g.find_path((1, 1), (1, 1)).unwrap();
        assert_eq!(path, vec![(1, 1)]);
    }

    #[test]
    fn test_simple_path_connects_corners() {
        let g = IsoGrid::new(5, 5);
        let path = g.find_path((0, 0), (4, 4));
        assert!(path.is_some());
        let p = path.unwrap();
        assert_eq!(*p.first().unwrap(), (0, 0));
        assert_eq!(*p.last().unwrap(), (4, 4));
    }

    #[test]
    fn test_line_of_sight_clear_diagonal() {
        let g = IsoGrid::new(5, 5);
        assert!(g.line_of_sight((0, 0), (4, 4)));
    }

    #[test]
    fn test_line_of_sight_blocked_by_cell() {
        let mut g = IsoGrid::new(5, 5);
        g.set_blocked(2, 2, true);
        assert!(!g.line_of_sight((0, 0), (4, 4)));
    }

    #[test]
    fn test_neighbors_center_cell_has_four() {
        let g = IsoGrid::new(5, 5);
        let n = g.neighbors(2, 2);
        assert_eq!(n.len(), 4);
    }
}

mod jps_tests {
    use lurek2d::pathfind::JpsGrid;

    #[test]
    fn test_trivial_path_same_cell_returns_one() {
        let g = JpsGrid::new(5, 5);
        let p = g.find_path((2, 2), (2, 2));
        assert!(p.is_some());
        assert_eq!(p.unwrap().len(), 1);
    }

    #[test]
    fn test_straight_line_path_connects_ends() {
        let g = JpsGrid::new(10, 1);
        let p = g.find_path((0, 0), (9, 0));
        assert!(p.is_some());
        let path = p.unwrap();
        assert_eq!(*path.first().unwrap(), (0, 0));
        assert_eq!(*path.last().unwrap(), (9, 0));
    }

    #[test]
    fn test_solid_wall_blocks_path() {
        let mut g = JpsGrid::new(5, 5);
        for y in 0..5 {
            g.set_blocked(2, y, true);
        }
        let p = g.find_path((0, 2), (4, 2));
        assert!(p.is_none());
    }

    #[test]
    fn test_partial_wall_allows_detour() {
        let mut g = JpsGrid::new(5, 5);
        g.set_blocked(2, 1, true);
        g.set_blocked(2, 2, true);
        g.set_blocked(2, 3, true);
        let p = g.find_path((0, 2), (4, 2));
        assert!(p.is_some());
    }
}

mod nav_grid_tests {
    use lurek2d::pathfind::{DiagonalMode, NavGrid};

    #[test]
    fn test_new_grid_all_walkable() {
        let g = NavGrid::new(10, 10);
        assert_eq!(g.get_width(), 10);
        assert_eq!(g.get_height(), 10);
        assert_eq!(g.get_dimensions(), (10, 10));
        for y in 0..10 {
            for x in 0..10 {
                assert!(!g.is_blocked(x, y));
                assert_eq!(g.get_cost(x, y), 1);
            }
        }
    }

    #[test]
    fn test_set_cost_and_blocked_round_trip() {
        let mut g = NavGrid::new(5, 5);
        g.set_cost(2, 3, 0);
        assert!(g.is_blocked(2, 3));
        g.set_blocked(1, 1, true);
        assert!(g.is_blocked(1, 1));
        g.set_blocked(1, 1, false);
        assert!(!g.is_blocked(1, 1));
    }

    #[test]
    fn test_out_of_bounds_returns_blocked() {
        let g = NavGrid::new(3, 3);
        assert_eq!(g.get_cost(5, 5), 0);
        assert!(g.is_blocked(3, 0));
    }

    #[test]
    fn test_is_walkable_unit_size_clears_on_block() {
        let mut g = NavGrid::new(5, 5);
        assert!(g.is_walkable(0, 0, 2));
        g.set_blocked(1, 0, true);
        assert!(!g.is_walkable(0, 0, 2));
    }

    #[test]
    fn test_from_costs_matches_dimensions() {
        let costs = vec![1u8; 9];
        let g = NavGrid::from_costs(3, 3, costs);
        assert_eq!(g.get_dimensions(), (3, 3));
        assert!(!g.is_blocked(0, 0));
    }

    #[test]
    fn test_fill_and_fill_rect_set_costs() {
        let mut g = NavGrid::new(4, 4);
        g.fill(0);
        assert!(g.is_blocked(2, 2));
        g.fill(1);
        g.fill_rect(1, 1, 2, 2, 0);
        assert!(g.is_blocked(1, 1));
        assert!(g.is_blocked(2, 2));
        assert!(!g.is_blocked(0, 0));
    }

    #[test]
    fn test_diagonal_mode_round_trip_strings() {
        assert_eq!(DiagonalMode::from_lua_str("always"), Some(DiagonalMode::Always));
        assert_eq!(DiagonalMode::from_lua_str("none"), Some(DiagonalMode::None));
        assert_eq!(DiagonalMode::from_lua_str("nocornercut"), Some(DiagonalMode::NoCornerCut));
        assert_eq!(DiagonalMode::from_lua_str("bogus"), None);
        assert_eq!(DiagonalMode::Always.to_lua_str(), "always");
    }

    #[test]
    fn test_load_save_bytes_round_trip() {
        let mut g = NavGrid::new(3, 3);
        g.set_cost(1, 1, 5);
        let bytes = g.save_to_bytes();
        let mut g2 = NavGrid::new(3, 3);
        g2.load_from_bytes(&bytes).unwrap();
        assert_eq!(g2.get_cost(1, 1), 5);
    }

    #[test]
    fn test_load_from_bytes_wrong_len_errors() {
        let mut g = NavGrid::new(3, 3);
        assert!(g.load_from_bytes(&[0u8; 5]).is_err());
    }
}

mod range_map_tests {
    use lurek2d::pathfind::RangeMap;

    #[test]
    fn test_origin_always_reachable() {
        let costs = vec![1.0f32; 9];
        let blocked = vec![false; 9];
        let rm = RangeMap::from_grid(3, 3, &costs, &blocked, 1, 1, 10.0, false);
        assert!(rm.reachable(1, 1));
        assert_eq!(rm.cost_to(1, 1), Some(0.0));
    }

    #[test]
    fn test_budget_limits_reach() {
        let costs = vec![1.0f32; 25];
        let blocked = vec![false; 25];
        let rm = RangeMap::from_grid(5, 5, &costs, &blocked, 0, 0, 2.0, false);
        assert!(rm.reachable(0, 0));
        assert!(rm.reachable(2, 0));
        assert!(!rm.reachable(4, 4));
    }

    #[test]
    fn test_blocked_origin_returns_empty() {
        let costs = vec![1.0; 4];
        let blocked = vec![true; 4];
        let rm = RangeMap::from_grid(2, 2, &costs, &blocked, 0, 0, 10.0, false);
        assert!(!rm.reachable(0, 0));
    }

    #[test]
    fn test_diagonal_extends_reach_over_cardinal() {
        let costs = vec![1.0f32; 9];
        let blocked = vec![false; 9];
        let rm_4 = RangeMap::from_grid(3, 3, &costs, &blocked, 0, 0, 1.5, false);
        let rm_8 = RangeMap::from_grid(3, 3, &costs, &blocked, 0, 0, 1.5, true);
        assert!(rm_8.reachable_cells().len() >= rm_4.reachable_cells().len());
    }

    #[test]
    fn test_reachable_cells_with_cost_includes_origin() {
        let costs = vec![1.0; 4];
        let blocked = vec![false; 4];
        let rm = RangeMap::from_grid(2, 2, &costs, &blocked, 0, 0, 5.0, false);
        let cells = rm.reachable_cells_with_cost();
        assert!(cells.iter().any(|(x, y, c)| *x == 0 && *y == 0 && *c == 0.0));
    }
}

mod unit_pathfinder_tests {
    use lurek2d::pathfind::{NavGrid, UnitPathfinder};
    use std::cell::RefCell;
    use std::rc::Rc;

    fn open_grid(w: u32, h: u32) -> Rc<RefCell<NavGrid>> {
        Rc::new(RefCell::new(NavGrid::new(w, h)))
    }

    #[test]
    fn test_find_path_open_grid_returns_some() {
        let g = open_grid(5, 5);
        let mut up = UnitPathfinder::new(g);
        assert!(up.find_path(0, 0, 4, 4, 1).is_some());
    }

    #[test]
    fn test_cache_hit_returns_same_path() {
        let g = open_grid(5, 5);
        let mut up = UnitPathfinder::new(g);
        let p1 = up.find_path(0, 0, 4, 4, 1).unwrap();
        let p2 = up.find_path(0, 0, 4, 4, 1).unwrap();
        assert_eq!(p1, p2);
    }

    #[test]
    fn test_path_through_blocked_returns_none() {
        let g_inner = NavGrid::new(3, 1);
        let g = Rc::new(RefCell::new(g_inner));
        g.borrow_mut().set_blocked(1, 0, true);
        let mut up = UnitPathfinder::new(g);
        assert!(up.find_path(0, 0, 2, 0, 1).is_none());
    }
}
