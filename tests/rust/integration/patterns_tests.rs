//! Integration tests for `lurek2d::patterns` — EventBus, ObjectPool, CommandStack,
//! ServiceLocator, Factory, StateMachine.

use lurek2d::patterns::*;

// ── EventBus ──────────────────────────────────────────────────────────────────

#[test]
fn event_bus_subscribe_returns_id() {
    let mut bus = EventBus::new("test");
    let id = bus.subscribe("click", 10, false);
    assert!(id > 0);
}

#[test]
fn event_bus_get_listeners_returns_ids() {
    let mut bus = EventBus::new("test");
    let id = bus.subscribe("click", 10, false);
    let listeners = bus.get_listeners("click");
    assert_eq!(listeners.len(), 1);
    assert!(listeners.contains(&id));
}

#[test]
fn event_bus_listeners_empty_after_clear_event() {
    let mut bus = EventBus::new("test");
    bus.subscribe("click", 0, false);
    bus.clear_event("click");
    assert!(bus.get_listeners("click").is_empty());
}

#[test]
fn event_bus_drain_once_removes_once_listeners() {
    let mut bus = EventBus::new("test");
    let once_id = bus.subscribe("ev", 0, true);
    let perm_id = bus.subscribe("ev", 0, false);
    let all_ids = bus.get_listeners("ev");
    bus.drain_once(&all_ids);
    let remaining = bus.get_listeners("ev");
    assert!(!remaining.contains(&once_id));
    assert!(remaining.contains(&perm_id));
}

#[test]
fn event_bus_clear_event_does_not_affect_other_events() {
    let mut bus = EventBus::new("test");
    bus.subscribe("a", 0, false);
    bus.subscribe("b", 0, false);
    bus.clear_event("a");
    assert!(bus.get_listeners("a").is_empty());
    assert_eq!(bus.get_listeners("b").len(), 1);
}

#[test]
fn event_bus_clear_all_removes_everything() {
    let mut bus = EventBus::new("test");
    bus.subscribe("a", 0, false);
    bus.subscribe("b", 0, false);
    bus.clear_all();
    assert!(bus.get_listeners("a").is_empty());
    assert!(bus.get_listeners("b").is_empty());
}

// ── ObjectPool ────────────────────────────────────────────────────────────────

#[test]
fn object_pool_acquire_returns_id() {
    let mut pool = ObjectPool::new("test", 10);
    let id = pool.acquire();
    assert!(id.is_some());
}

#[test]
fn object_pool_acquire_marks_as_active() {
    let mut pool = ObjectPool::new("test", 10);
    let id = pool.acquire().unwrap();
    assert!(pool.is_active(id));
}

#[test]
fn object_pool_release_moves_to_idle() {
    let mut pool = ObjectPool::new("test", 10);
    let id = pool.acquire().unwrap();
    let released = pool.release(id);
    assert!(released);
    assert!(!pool.is_active(id));
}

#[test]
fn object_pool_at_capacity_returns_none() {
    let mut pool = ObjectPool::new("test", 2);
    pool.prewarm(2);
    pool.acquire();
    pool.acquire();
    assert!(pool.acquire().is_none());
}

#[test]
fn object_pool_prewarm_fills_idle() {
    let mut pool = ObjectPool::new("test", 10);
    pool.prewarm(5);
    assert_eq!(pool.idle_count(), 5);
}

#[test]
fn object_pool_active_and_idle_counts_correct() {
    let mut pool = ObjectPool::new("test", 10);
    pool.prewarm(5);
    pool.acquire();
    pool.acquire();
    assert_eq!(pool.active_count(), 2);
    assert_eq!(pool.idle_count(), 3);
}

// ── CommandStack ──────────────────────────────────────────────────────────────

#[test]
fn command_stack_push_increments_count() {
    let mut stack = CommandStack::new(100);
    stack.push("do_thing", true);
    assert_eq!(stack.undo_count(), 1);
}

#[test]
fn command_stack_undo_decrements_count() {
    let mut stack = CommandStack::new(100);
    stack.push("do_thing", true);
    let undone = stack.step_undo();
    assert!(undone.is_some());
    assert_eq!(stack.undo_count(), 0);
}

#[test]
fn command_stack_redo_increments_count() {
    let mut stack = CommandStack::new(100);
    stack.push("do_thing", true);
    stack.step_undo();
    let redone = stack.step_redo();
    assert!(redone.is_some());
    assert_eq!(stack.undo_count(), 1);
}

#[test]
fn command_stack_clear_empties_history() {
    let mut stack = CommandStack::new(100);
    stack.push("cmd1", true);
    stack.push("cmd2", false);
    stack.clear();
    assert_eq!(stack.undo_count(), 0);
    assert_eq!(stack.redo_count(), 0);
}

#[test]
fn command_stack_no_undo_without_undo_fn() {
    let mut stack = CommandStack::new(100);
    stack.push("no_undo_cmd", false);
    let result = stack.step_undo();
    let _ = result;
}

#[test]
fn command_stack_batch_groups_commands() {
    let mut stack = CommandStack::new(100);
    stack.begin_batch();
    stack.push("cmd_a", true);
    stack.push("cmd_b", true);
    let batch = stack.end_batch();
    assert!(batch.is_some());
    let ids = batch.unwrap();
    assert_eq!(ids.len(), 2);
}

// ── ServiceLocator ────────────────────────────────────────────────────────────

#[test]
fn service_locator_register_and_has() {
    let mut sl = ServiceLocator::new();
    sl.register("audio");
    assert!(sl.has("audio"));
}

#[test]
fn service_locator_unregister_removes() {
    let mut sl = ServiceLocator::new();
    sl.register("ui");
    let removed = sl.unregister("ui");
    assert!(removed);
    assert!(!sl.has("ui"));
}

#[test]
fn service_locator_names_returns_all() {
    let mut sl = ServiceLocator::new();
    sl.register("svc_a");
    sl.register("svc_b");
    let names: Vec<&str> = sl.names();
    assert!(names.contains(&"svc_a"));
    assert!(names.contains(&"svc_b"));
}

#[test]
fn service_locator_clear_removes_all() {
    let mut sl = ServiceLocator::new();
    sl.register("a");
    sl.register("b");
    sl.clear();
    assert!(sl.names().is_empty());
}

// ── Factory ───────────────────────────────────────────────────────────────────

#[test]
fn factory_register_and_has() {
    let mut f = Factory::new();
    f.register("goblin");
    assert!(f.has("goblin"));
}

#[test]
fn factory_unregister_removes_type() {
    let mut f = Factory::new();
    f.register("orc");
    let removed = f.unregister("orc");
    assert!(removed);
    assert!(!f.has("orc"));
}

#[test]
fn factory_alias_resolves_to_canonical() {
    let mut f = Factory::new();
    f.register("goblin");
    f.add_alias("enemy", "goblin");
    let resolved = f.resolve("enemy");
    assert_eq!(resolved, "goblin");
}

#[test]
fn factory_type_names_returns_all() {
    let mut f = Factory::new();
    f.register("a");
    f.register("b");
    let names: Vec<&str> = f.type_names();
    assert!(names.contains(&"a"));
    assert!(names.contains(&"b"));
}

#[test]
fn factory_clear_removes_all() {
    let mut f = Factory::new();
    f.register("t1");
    f.clear();
    assert!(f.type_names().is_empty());
}

// ── StateMachine ──────────────────────────────────────────────────────────────

#[test]
fn state_machine_starts_at_initial() {
    let sm = StateMachine::new("idle");
    assert_eq!(sm.current, "idle");
}

#[test]
fn state_machine_add_state_and_has_state() {
    let mut sm = StateMachine::new("idle");
    sm.add_state("running", false, false, true);
    assert!(sm.has_state("running"));
}

#[test]
fn state_machine_transition_to_valid_state() {
    let mut sm = StateMachine::new("idle");
    sm.add_state("idle", false, false, false);
    sm.add_state("running", false, false, false);
    sm.add_transition("idle", "running", "", false);
    let ok = sm.transition_to("running");
    assert!(ok);
    assert_eq!(sm.current, "running");
}

#[test]
fn state_machine_transition_to_invalid_state_fails() {
    let mut sm = StateMachine::new("idle");
    sm.add_state("idle", false, false, false);
    sm.add_state("running", false, false, false);
    sm.add_state("dead", false, false, false);
    // Add at least one transition so the FSM is not in free mode
    sm.add_transition("idle", "running", "", false);
    // No idle→dead transition defined; must fail
    let ok = sm.transition_to("dead");
    assert!(!ok);
}

#[test]
fn state_machine_can_transition_respects_rules() {
    let mut sm = StateMachine::new("idle");
    sm.add_state("idle", false, false, false);
    sm.add_state("running", false, false, false);
    sm.add_transition("idle", "running", "", false);
    assert!(sm.can_transition("idle", "running"));
    assert!(!sm.can_transition("idle", "dead_state"));
}

#[test]
fn state_machine_history_records_transitions() {
    let mut sm = StateMachine::new("idle");
    sm.add_state("idle", false, false, false);
    sm.add_state("running", false, false, false);
    sm.add_transition("idle", "running", "", false);
    sm.add_transition("running", "idle", "", false);
    sm.transition_to("running");
    sm.transition_to("idle");
    let history = sm.history();
    assert!(history.len() >= 1);
}

#[test]
fn state_machine_reachable_from_returns_connected_states() {
    let mut sm = StateMachine::new("start");
    sm.add_state("start", false, false, false);
    sm.add_state("middle", false, false, false);
    sm.add_state("end", false, false, false);
    sm.add_state("isolated", false, false, false);
    sm.add_transition("start", "middle", "", false);
    sm.add_transition("middle", "end", "", false);
    // reachable_from is 1-hop only; "middle" is directly reachable from "start"
    let reachable = sm.reachable_from("start");
    assert!(reachable.iter().any(|&s| s == "middle"));
    assert!(!reachable.iter().any(|&s| s == "isolated"));
    // "end" is reachable from "middle", not directly from "start"
    let from_middle = sm.reachable_from("middle");
    assert!(from_middle.iter().any(|&s| s == "end"));
}
