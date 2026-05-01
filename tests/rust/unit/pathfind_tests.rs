//! INTERNAL ONLY: Rust-only tests for pathfinding internals that are not asserted through the
//! Lua-facing `lurek.pathfind.*` API.
//!
//! Grid/path behaviour is covered by `tests/lua/unit/test_pathfind_unit.lua`.
//! The remaining Rust coverage here keeps only the thread-pool helper
//! invariant.

use lurek2d::pathfind::PathThreadPool;

mod async_pool_tests {
    use super::*;

    #[test]
    fn default_thread_count() {
        let pool = PathThreadPool::new(0);
        assert!(pool.get_thread_count() >= 1);
    }
}
