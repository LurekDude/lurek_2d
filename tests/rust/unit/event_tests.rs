//! Integration tests for the event queue and signal modules.

use lurek2d::signal::{Event, EventArg, EventQueue, Signal};

#[test]
fn event_queue_push_poll() {
    let mut queue = EventQueue::new();
    queue.push(Event {
        name: "keypressed".to_string(),
        args: vec![EventArg::Str("space".to_string())],
    });
    let event = queue.poll().unwrap();
    assert_eq!(event.name, "keypressed");
    assert!(queue.poll().is_none());
}

#[test]
fn event_queue_fifo() {
    let mut queue = EventQueue::new();
    queue.push_event("first", vec![]);
    queue.push_event("second", vec![]);
    queue.push_event("third", vec![]);
    assert_eq!(queue.poll().unwrap().name, "first");
    assert_eq!(queue.poll().unwrap().name, "second");
    assert_eq!(queue.poll().unwrap().name, "third");
    assert!(queue.is_empty());
}

#[test]
fn event_queue_clear() {
    let mut queue = EventQueue::new();
    queue.push_event("test", vec![]);
    queue.push_event("test", vec![]);
    assert_eq!(queue.len(), 2);
    queue.clear();
    assert!(queue.is_empty());
}

#[test]
fn event_queue_args() {
    let mut queue = EventQueue::new();
    queue.push(Event {
        name: "custom".to_string(),
        args: vec![
            EventArg::Str("hello".to_string()),
            EventArg::Num(42.0),
            EventArg::Bool(true),
            EventArg::Nil,
        ],
    });
    let event = queue.poll().unwrap();
    assert_eq!(event.args.len(), 4);
}

// ---------------------------------------------------------------------------
// Signal tests
// ---------------------------------------------------------------------------

#[test]
fn signal_subscribe_returns_monotonic_handles() {
    let mut sig = Signal::new();
    let h1 = sig.subscribe("click");
    let h2 = sig.subscribe("click");
    let h3 = sig.subscribe("hover");
    assert_eq!(h1, 1);
    assert_eq!(h2, 2);
    assert_eq!(h3, 3);
}

#[test]
fn signal_get_count() {
    let mut sig = Signal::new();
    sig.subscribe("click");
    sig.subscribe("click");
    sig.subscribe("hover");
    assert_eq!(sig.get_count("click"), 2);
    assert_eq!(sig.get_count("hover"), 1);
    assert_eq!(sig.get_count("nonexistent"), 0);
    assert_eq!(sig.get_total_count(), 3);
}

#[test]
fn signal_remove_existing() {
    let mut sig = Signal::new();
    let h1 = sig.subscribe("click");
    let h2 = sig.subscribe("click");
    assert!(sig.remove(h1));
    assert_eq!(sig.get_count("click"), 1);
    assert_eq!(sig.get_handles("click"), vec![h2]);
}

#[test]
fn signal_remove_nonexistent() {
    let mut sig = Signal::new();
    assert!(!sig.remove(999));
}

#[test]
fn signal_clear_name() {
    let mut sig = Signal::new();
    sig.subscribe("click");
    sig.subscribe("click");
    sig.subscribe("hover");
    let removed = sig.clear("click");
    assert_eq!(removed, 2);
    assert_eq!(sig.get_count("click"), 0);
    assert_eq!(sig.get_count("hover"), 1);
    assert_eq!(sig.get_total_count(), 1);
}

#[test]
fn signal_clear_nonexistent() {
    let mut sig = Signal::new();
    assert_eq!(sig.clear("nope"), 0);
}

#[test]
fn signal_clear_all() {
    let mut sig = Signal::new();
    sig.subscribe("click");
    sig.subscribe("hover");
    sig.subscribe("hover");
    let removed = sig.clear_all();
    assert_eq!(removed, 3);
    assert_eq!(sig.get_total_count(), 0);
}

#[test]
fn signal_get_handles_preserves_order() {
    let mut sig = Signal::new();
    let h1 = sig.subscribe("click");
    let h2 = sig.subscribe("click");
    let h3 = sig.subscribe("click");
    assert_eq!(sig.get_handles("click"), vec![h1, h2, h3]);
}

#[test]
fn signal_default_trait() {
    let sig = Signal::default();
    assert_eq!(sig.get_total_count(), 0);
}

// ---------------------------------------------------------------------------
// EventQueue::pump and EventQueue::wait tests
// ---------------------------------------------------------------------------

#[test]
fn event_pump_does_not_panic() {
    let queue = EventQueue::new();
    queue.pump(); // no-op, must not panic
}

#[test]
fn event_wait_returns_none_on_empty_with_zero_timeout() {
    let mut queue = EventQueue::new();
    let result = queue.wait(Some(0));
    assert!(result.is_none());
}

#[test]
fn event_wait_returns_event_if_available_immediately() {
    let mut queue = EventQueue::new();
    queue.push(Event {
        name: "test".to_string(),
        args: vec![],
    });
    let result = queue.wait(Some(0));
    assert!(result.is_some());
    assert_eq!(result.unwrap().name, "test");
}

#[test]
fn event_wait_drains_in_order() {
    let mut queue = EventQueue::new();
    queue.push_event("first", vec![]);
    queue.push_event("second", vec![]);
    let a = queue.wait(Some(0)).unwrap();
    let b = queue.wait(Some(0)).unwrap();
    assert_eq!(a.name, "first");
    assert_eq!(b.name, "second");
}

#[test]
fn event_restart_requested_defaults_false() {
    use lurek2d::lua_api::SharedState;
    use std::path::PathBuf;
    let state = SharedState::new(800, 600, "Test", PathBuf::from("."));
    assert!(!state.restart_requested);
}

#[test]
fn event_restart_requested_can_be_set() {
    use lurek2d::lua_api::SharedState;
    use std::path::PathBuf;
    let mut state = SharedState::new(800, 600, "Test", PathBuf::from("."));
    state.restart_requested = true;
    assert!(state.restart_requested);
}
