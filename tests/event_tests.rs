//! Integration tests for the event queue and signal modules.

use luna2d::event::{Event, EventArg, EventQueue, Signal};

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

// ── Additional EventQueue edge cases ────────────────────────────────────────

#[test]
fn event_queue_new_is_empty() {
    let queue = EventQueue::new();
    assert!(queue.is_empty());
    assert_eq!(queue.len(), 0);
}

#[test]
fn event_queue_poll_empty_returns_none() {
    let mut queue = EventQueue::new();
    assert!(queue.poll().is_none());
}

#[test]
fn event_queue_len_grows_with_push() {
    let mut queue = EventQueue::new();
    queue.push_event("a", vec![]);
    assert_eq!(queue.len(), 1);
    queue.push_event("b", vec![]);
    assert_eq!(queue.len(), 2);
}

#[test]
fn event_queue_len_shrinks_with_poll() {
    let mut queue = EventQueue::new();
    queue.push_event("x", vec![]);
    queue.push_event("y", vec![]);
    let _ = queue.poll();
    assert_eq!(queue.len(), 1);
    assert!(!queue.is_empty());
}

#[test]
fn event_queue_args_num_variant() {
    let mut queue = EventQueue::new();
    queue.push(Event {
        name: "score".to_string(),
        args: vec![EventArg::Num(99.5)],
    });
    let ev = queue.poll().unwrap();
    match &ev.args[0] {
        EventArg::Num(n) => assert!((*n - 99.5).abs() < 1e-9),
        other => panic!("unexpected arg: {other:?}"),
    }
}

#[test]
fn event_queue_args_bool_variant() {
    let mut queue = EventQueue::new();
    queue.push(Event {
        name: "flag".to_string(),
        args: vec![EventArg::Bool(true), EventArg::Bool(false)],
    });
    let ev = queue.poll().unwrap();
    assert!(matches!(&ev.args[0], EventArg::Bool(true)));
    assert!(matches!(&ev.args[1], EventArg::Bool(false)));
}

#[test]
fn event_queue_args_nil_variant() {
    let mut queue = EventQueue::new();
    queue.push(Event {
        name: "empty_arg".to_string(),
        args: vec![EventArg::Nil],
    });
    let ev = queue.poll().unwrap();
    assert!(matches!(&ev.args[0], EventArg::Nil));
}

#[test]
fn event_queue_preserves_event_name_exactly() {
    let mut queue = EventQueue::new();
    queue.push_event("keypressed:space", vec![]);
    assert_eq!(queue.poll().unwrap().name, "keypressed:space");
}

#[test]
fn event_queue_clear_makes_empty() {
    let mut queue = EventQueue::new();
    for _ in 0..10 {
        queue.push_event("ev", vec![]);
    }
    queue.clear();
    assert!(queue.is_empty());
    assert_eq!(queue.len(), 0);
}

// ── Signal edge cases ────────────────────────────────────────────────────────

#[test]
fn signal_subscribe_different_names_tracked_independently() {
    let mut sig = Signal::new();
    sig.subscribe("alpha");
    sig.subscribe("beta");
    sig.subscribe("alpha");
    assert_eq!(sig.get_count("alpha"), 2);
    assert_eq!(sig.get_count("beta"), 1);
    assert_eq!(sig.get_total_count(), 3);
}

#[test]
fn signal_remove_all_handles_for_name() {
    let mut sig = Signal::new();
    let h1 = sig.subscribe("ev");
    let h2 = sig.subscribe("ev");
    assert!(sig.remove(h1));
    assert!(sig.remove(h2));
    assert_eq!(sig.get_count("ev"), 0);
    assert!(sig.get_handles("ev").is_empty());
}

#[test]
fn signal_handles_are_unique_across_names() {
    let mut sig = Signal::new();
    let h1 = sig.subscribe("click");
    let h2 = sig.subscribe("hover");
    assert_ne!(h1, h2);
}
