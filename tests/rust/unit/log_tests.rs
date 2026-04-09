//! Tests for the `log` module — log level management and structured log sinks.

use lurek2d::log::sinks::{MemoryEntry, Sink, SinkLevel, SinkRegistry};

// ── SinkLevel ─────────────────────────────────────────────────────────────

#[test]
fn sink_level_from_str_debug() {
    assert_eq!(SinkLevel::from_str("debug"), SinkLevel::Debug);
}

#[test]
fn sink_level_from_str_info() {
    assert_eq!(SinkLevel::from_str("info"), SinkLevel::Info);
}

#[test]
fn sink_level_from_str_warn_variants() {
    assert_eq!(SinkLevel::from_str("warn"), SinkLevel::Warn);
    assert_eq!(SinkLevel::from_str("warning"), SinkLevel::Warn);
}

#[test]
fn sink_level_from_str_error_variants() {
    assert_eq!(SinkLevel::from_str("error"), SinkLevel::Error);
    assert_eq!(SinkLevel::from_str("err"), SinkLevel::Error);
}

#[test]
fn sink_level_from_str_unknown_defaults_to_debug() {
    assert_eq!(SinkLevel::from_str("verbose"), SinkLevel::Debug);
    assert_eq!(SinkLevel::from_str(""), SinkLevel::Debug);
}

#[test]
fn sink_level_from_str_case_insensitive() {
    assert_eq!(SinkLevel::from_str("INFO"), SinkLevel::Info);
    assert_eq!(SinkLevel::from_str("WARN"), SinkLevel::Warn);
    assert_eq!(SinkLevel::from_str("ERROR"), SinkLevel::Error);
}

#[test]
fn sink_level_as_str_returns_uppercase() {
    assert_eq!(SinkLevel::Debug.as_str(), "DEBUG");
    assert_eq!(SinkLevel::Info.as_str(), "INFO");
    assert_eq!(SinkLevel::Warn.as_str(), "WARN");
    assert_eq!(SinkLevel::Error.as_str(), "ERROR");
}

#[test]
fn sink_level_ordering_debug_less_than_error() {
    assert!(SinkLevel::Debug < SinkLevel::Info);
    assert!(SinkLevel::Info < SinkLevel::Warn);
    assert!(SinkLevel::Warn < SinkLevel::Error);
}

// ── MemoryEntry ───────────────────────────────────────────────────────────

#[test]
fn memory_entry_fields_are_stored() {
    let entry = MemoryEntry {
        level: SinkLevel::Info,
        message: "hello world".to_string(),
        tag: "game".to_string(),
    };
    assert_eq!(entry.level, SinkLevel::Info);
    assert_eq!(entry.message, "hello world");
    assert_eq!(entry.tag, "game");
}

#[test]
fn memory_entry_clone_is_independent() {
    let original = MemoryEntry {
        level: SinkLevel::Warn,
        message: "original".to_string(),
        tag: "test".to_string(),
    };
    let mut cloned = original.clone();
    cloned.message = "modified".to_string();
    assert_eq!(original.message, "original");
    assert_eq!(cloned.message, "modified");
}

// ── Sink (memory) ─────────────────────────────────────────────────────────

#[test]
fn sink_memory_write_stores_entry() {
    let sink = Sink::memory(1, 8, SinkLevel::Debug);
    sink.write(SinkLevel::Info, "test tag", "hello");
    let entries = sink.read_memory(false).expect("memory sink has entries");
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].level, SinkLevel::Info);
    assert_eq!(entries[0].tag, "test tag");
    assert_eq!(entries[0].message, "hello");
}

#[test]
fn sink_memory_respects_min_level_filter() {
    let sink = Sink::memory(2, 8, SinkLevel::Warn);
    sink.write(SinkLevel::Debug, "tag", "below threshold");
    sink.write(SinkLevel::Info, "tag", "also below");
    sink.write(SinkLevel::Warn, "tag", "passes through");
    let entries = sink.read_memory(false).expect("memory sink");
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].level, SinkLevel::Warn);
}

#[test]
fn sink_memory_respects_capacity_bound() {
    let capacity = 4usize;
    let sink = Sink::memory(3, capacity, SinkLevel::Debug);
    for i in 0..8 {
        sink.write(SinkLevel::Info, "bench", &format!("msg {i}"));
    }
    let entries = sink.read_memory(false).expect("memory sink");
    assert!(
        entries.len() <= capacity,
        "Expected at most {capacity} entries, got {}",
        entries.len()
    );
}

#[test]
fn sink_memory_drain_clears_buffer() {
    let sink = Sink::memory(4, 16, SinkLevel::Debug);
    sink.write(SinkLevel::Info, "t", "first");
    sink.write(SinkLevel::Info, "t", "second");
    let drained = sink.read_memory(true).expect("memory sink");
    assert_eq!(drained.len(), 2);
    // After drain the buffer should be empty
    let remaining = sink.read_memory(false).expect("memory sink");
    assert_eq!(remaining.len(), 0);
}

#[test]
fn sink_type_name_memory() {
    let sink = Sink::memory(5, 8, SinkLevel::Debug);
    assert_eq!(sink.type_name(), "memory");
}

#[test]
fn sink_path_is_none_for_memory_sink() {
    let sink = Sink::memory(6, 8, SinkLevel::Debug);
    assert!(sink.path().is_none());
}

// ── SinkRegistry ─────────────────────────────────────────────────────────

#[test]
fn sink_registry_starts_empty() {
    let registry = SinkRegistry::new();
    assert!(registry.sinks.is_empty());
}

#[test]
fn sink_registry_add_memory_sink_and_retrieve() {
    let mut registry = SinkRegistry::new();
    let id = registry.add(Sink::memory(0, 16, SinkLevel::Debug));
    assert_eq!(registry.sinks.len(), 1);
    assert!(registry.get(id).is_some());
}

#[test]
fn sink_registry_remove_returns_true_then_false() {
    let mut registry = SinkRegistry::new();
    let id = registry.add(Sink::memory(0, 8, SinkLevel::Debug));
    assert!(registry.remove(id));
    assert!(!registry.remove(id)); // already removed
    assert!(registry.sinks.is_empty());
}

#[test]
fn sink_registry_dispatch_writes_to_memory_sink() {
    let mut registry = SinkRegistry::new();
    let id = registry.add(Sink::memory(0, 8, SinkLevel::Debug));
    registry.dispatch(SinkLevel::Info, "sys", "dispatched msg");
    let sink = registry.get(id).expect("sink present");
    let entries = sink.read_memory(false).expect("memory sink");
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].message, "dispatched msg");
}

#[test]
fn sink_registry_clear_removes_all_sinks() {
    let mut registry = SinkRegistry::new();
    registry.add(Sink::memory(0, 4, SinkLevel::Debug));
    registry.add(Sink::memory(0, 4, SinkLevel::Info));
    registry.clear();
    assert!(registry.sinks.is_empty());
}
