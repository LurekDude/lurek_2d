//! INTERNAL ONLY: public `lurek.devtools.*` logging, profiler, frame-stats,
//! and file-watcher behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_devtools_core_unit.lua`.
//!
//! The remaining Rust coverage keeps the single-sample frame-stats case, which
//! cannot be isolated through the module-level Lua singleton because the public
//! API exposes no reset or fresh-constructor path for CPU frame history.

use lurek2d::devtools::FrameStats;

#[test]
fn test_frame_stats_single_sample() {
    let mut stats = FrameStats::new(10);
    stats.record(0.016);
    let snap = stats.snapshot();
    assert_eq!(snap.samples, 1);
    assert_eq!(snap.min, 0.016);
    assert_eq!(snap.max, 0.016);
    assert_eq!(snap.avg, 0.016);
    assert_eq!(snap.p50, 0.016);
    assert_eq!(snap.p95, 0.016);
    assert_eq!(snap.p99, 0.016);
}
