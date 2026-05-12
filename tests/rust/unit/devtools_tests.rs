use lurek2d::devtools::{FileWatcher, FrameStats, Logger, Profiler};
use std::fs;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

fn unique_temp_path(prefix: &str) -> std::path::PathBuf {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();
    std::env::temp_dir().join(format!("{}_{}.tmp", prefix, nanos))
}

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

#[test]
fn test_frame_stats_all_equal_samples() {
    let mut stats = FrameStats::new(10);
    for _ in 0..10 {
        stats.record(0.02);
    }
    let snap = stats.snapshot();
    assert_eq!(snap.samples, 10);
    assert_eq!(snap.min, 0.02);
    assert_eq!(snap.max, 0.02);
    assert_eq!(snap.avg, 0.02);
    assert_eq!(snap.p50, 0.02);
    assert_eq!(snap.p95, 0.02);
    assert_eq!(snap.p99, 0.02);
}

#[test]
fn test_logger_writes_to_file() {
    let path = unique_temp_path("lurek_devtools_logger");
    let mut logger = Logger::new();
    logger.console_enabled = false;
    logger.log_file = path.to_string_lossy().to_string();

    logger.push("info", "file-output-check", "test", 1, None);

    let text = fs::read_to_string(&path).unwrap();
    assert!(text.contains("file-output-check"));

    let _ = fs::remove_file(path);
}

#[test]
fn test_profiler_get_frame_negative_index_behavior() {
    let mut profiler = Profiler::new();
    profiler.enabled = true;

    profiler.push("f0");
    profiler.pop();
    profiler.end_frame();

    profiler.push("f1");
    profiler.pop();
    profiler.end_frame();

    profiler.push("f2");
    profiler.pop();
    profiler.end_frame();

    let latest = profiler.get_frame(0).unwrap();
    assert_eq!(latest[0].name, "f2");

    let prev = profiler.get_frame(-1).unwrap();
    assert_eq!(prev[0].name, "f1");
}

#[test]
fn test_watcher_detects_mtime_change_on_real_file() {
    let path = unique_temp_path("lurek_devtools_watch");
    fs::write(&path, "v1").unwrap();

    let mut watcher = FileWatcher::new();
    watcher.watch(path.to_string_lossy().as_ref());

    // Baseline poll does not report first-seen path.
    assert!(watcher.poll().is_empty());

    std::thread::sleep(Duration::from_millis(15));
    fs::write(&path, "v2").unwrap();

    let changed = watcher.poll();
    assert_eq!(changed.len(), 1);

    let _ = fs::remove_file(path);
}
