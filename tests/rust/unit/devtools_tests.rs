//! Integration tests for `lurek2d::devtools` — structured logger, profiler, frame stats, file watcher.

use lurek2d::devtools::*;

// ── Logger ────────────────────────────────────────────────────────────────────

#[test]
fn logger_new_is_empty() {
    let log = Logger::new();
    assert!(log.history.is_empty());
}

#[test]
fn logger_push_appends_entry() {
    let mut log = Logger::new();
    log.push("info", "hello", "test.lua", 1, None);
    assert_eq!(log.history.len(), 1);
    assert_eq!(log.history[0].message, "hello");
    assert_eq!(log.history[0].level, "info");
}

#[test]
fn logger_min_level_filters_entries() {
    let mut log = Logger::new();
    log.min_level = LogLevel::Warn;
    log.push("debug", "debug msg", "test.lua", 1, None);
    log.push("warn", "warn msg", "test.lua", 2, None);
    assert_eq!(log.history.len(), 1);
    assert_eq!(log.history[0].message, "warn msg");
}

#[test]
fn logger_tail_returns_last_n() {
    let mut log = Logger::new();
    for i in 0..5 {
        log.push("info", &format!("msg {i}"), "f.lua", i as u32, None);
    }
    let tail = log.tail(Some(3));
    assert_eq!(tail.len(), 3);
    assert_eq!(tail[0].message, "msg 2");
    assert_eq!(tail[2].message, "msg 4");
}

#[test]
fn logger_filter_category_returns_matching() {
    let mut log = Logger::new();
    log.push("info", "boot message", "main.lua", 1, Some("boot"));
    log.push("info", "other message", "main.lua", 2, None);
    log.push("warn", "boot detail", "main.lua", 3, Some("boot"));
    let filtered = log.filter_category("boot");
    assert_eq!(filtered.len(), 2);
}

#[test]
fn logger_clear_empties_history() {
    let mut log = Logger::new();
    log.push("error", "err", "f.lua", 1, None);
    log.clear();
    assert!(log.history.is_empty());
}

#[test]
fn logger_max_history_respected() {
    let mut log = Logger::new();
    log.max_history = 3;
    for i in 0..10 {
        log.push("info", &format!("m{i}"), "f.lua", i as u32, None);
    }
    assert!(log.history.len() <= 3);
}

// ── LogLevel ordering ─────────────────────────────────────────────────────────

#[test]
fn log_level_ordering_trace_less_than_error() {
    assert!(LogLevel::Trace < LogLevel::Error);
    assert!(LogLevel::Debug < LogLevel::Warn);
}

#[test]
fn log_level_from_str_round_trips() {
    let s = LogLevel::Warn.as_str();
    assert_eq!(LogLevel::from_str(s), Some(LogLevel::Warn));
}

// ── Profiler ──────────────────────────────────────────────────────────────────

#[test]
fn profiler_new_has_no_frames() {
    let prof = Profiler::new();
    assert!(prof.frames.is_empty());
}

#[test]
fn profiler_push_pop_end_frame_records_frame() {
    let mut prof = Profiler::new();
    prof.enabled = true;
    prof.push("render");
    prof.pop();
    prof.end_frame();
    assert_eq!(prof.frames.len(), 1);
}

#[test]
fn profiler_get_frame_negative_one_is_last() {
    let mut prof = Profiler::new();
    prof.enabled = true;
    prof.push("a");
    prof.pop();
    prof.end_frame();
    prof.push("b");
    prof.pop();
    prof.end_frame();
    let _frame = prof.get_frame(-1);
}

#[test]
fn profiler_reset_clears_frames() {
    let mut prof = Profiler::new();
    prof.enabled = true;
    prof.push("x");
    prof.pop();
    prof.end_frame();
    prof.reset();
    assert!(prof.frames.is_empty());
}

#[test]
fn profiler_zone_total_time_non_negative() {
    let mut prof = Profiler::new();
    prof.enabled = true;
    prof.push("zone_a");
    prof.pop();
    prof.end_frame();
    let frame = &prof.frames[0];
    for zone in frame {
        assert!(zone.total_time() >= 0.0);
    }
}

// ── FrameStats ────────────────────────────────────────────────────────────────

#[test]
fn frame_stats_empty_snapshot_safe() {
    let stats = FrameStats::new(120);
    let snap = stats.snapshot();
    assert_eq!(snap.samples, 0);
    assert!((snap.fps - 0.0).abs() < f64::EPSILON);
}

#[test]
fn frame_stats_record_updates_sample_count() {
    let mut stats = FrameStats::new(120);
    stats.record(0.016);
    stats.record(0.017);
    let snap = stats.snapshot();
    assert_eq!(snap.samples, 2);
}

#[test]
fn frame_stats_fps_computed_from_dt() {
    let mut stats = FrameStats::new(120);
    for _ in 0..60 {
        stats.record(1.0 / 60.0);
    }
    let snap = stats.snapshot();
    assert!((snap.fps - 60.0).abs() < 1.0, "fps should be ~60, got {}", snap.fps);
}

#[test]
fn frame_stats_capacity_limits_samples() {
    let mut stats = FrameStats::new(120);
    stats.set_capacity(15); // minimum clamp is 10, 15 is above that
    for i in 0..50 {
        stats.record(i as f64 * 0.001 + 0.01);
    }
    assert!(stats.snapshot().samples <= 15);
}

#[test]
fn frame_stats_percentiles_ordered() {
    let mut stats = FrameStats::new(120);
    for i in 1..=100 {
        stats.record(i as f64 * 0.001);
    }
    let snap = stats.snapshot();
    assert!(snap.p50 <= snap.p95, "p50 should be <= p95");
    assert!(snap.p95 <= snap.p99, "p95 should be <= p99");
    assert!(snap.min <= snap.avg, "min should be <= avg");
    assert!(snap.avg <= snap.max, "avg should be <= max");
}

// ── FileWatcher ───────────────────────────────────────────────────────────────

#[test]
fn watcher_new_has_no_paths() {
    let w = FileWatcher::new();
    assert!(w.paths.is_empty());
}

#[test]
fn watcher_watch_adds_path() {
    let mut w = FileWatcher::new();
    w.watch("nonexistent_test_file.txt");
    assert_eq!(w.paths.len(), 1);
}

#[test]
fn watcher_unwatch_removes_path() {
    let mut w = FileWatcher::new();
    w.watch("test_file.txt");
    let removed = w.unwatch("test_file.txt");
    assert!(removed);
    assert!(w.paths.is_empty());
}

#[test]
fn watcher_clear_removes_all_paths() {
    let mut w = FileWatcher::new();
    w.watch("a.txt");
    w.watch("b.txt");
    w.clear();
    assert!(w.paths.is_empty());
}

#[test]
fn watcher_watched_paths_returns_all() {
    let mut w = FileWatcher::new();
    w.watch("x.lua");
    w.watch("y.lua");
    let paths = w.watched_paths();
    assert_eq!(paths.len(), 2);
}

#[test]
fn watcher_poll_does_not_crash_for_nonexistent_paths() {
    let mut w = FileWatcher::new();
    w.watch("does_not_exist_12345.txt");
    let _changed = w.poll();
    // Just verify it doesn't panic
}
