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
