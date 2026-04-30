//! Smoke tests for the pathfind module against the current public API.

use lurek2d::pathfind::{
    ai_flow_field::FlowField, astar, bidirectional_astar, NavGrid, PathThreadPool,
};

mod flow_field_tests {
    use super::*;

    fn open_grid(w: usize, h: usize) -> Vec<bool> {
        vec![true; w * h]
    }

    #[test]
    fn set_goal_computes_directions() {
        let mut ff = FlowField::new(4, 4, open_grid(4, 4));
        ff.set_goal(3, 3);
        assert_eq!(ff.goal, Some((3, 3)));
        assert_eq!(ff.get_distance(3, 3), 0.0);
        assert!(ff.get_distance(0, 0).is_finite());
    }
}

mod astar_tests {
    use super::*;

    #[test]
    fn astar_finds_path_on_open_grid() {
        let grid = NavGrid::new(5, 5);
        let (path, complete) = astar(&grid, (0, 0), (4, 4), 1, 10_000);
        assert!(complete);
        let p = path.unwrap();
        assert_eq!(p.first(), Some(&(0, 0)));
        assert_eq!(p.last(), Some(&(4, 4)));
    }

    #[test]
    fn bidirectional_astar_finds_path() {
        let grid = NavGrid::new(5, 5);
        let (path, complete) = bidirectional_astar(&grid, (0, 0), (4, 4), 1, 10_000);
        assert!(complete);
        let p = path.unwrap();
        assert_eq!(p.first(), Some(&(0, 0)));
        assert_eq!(p.last(), Some(&(4, 4)));
    }
}

mod async_pool_tests {
    use super::*;

    #[test]
    fn default_thread_count() {
        let pool = PathThreadPool::new(0);
        assert!(pool.get_thread_count() >= 1);
    }
}
