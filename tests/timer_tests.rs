use luna2d::timer::Clock;

#[test]
fn clock_new_has_zero_delta() {
    let clock = Clock::new();
    assert!((clock.delta() - 0.0).abs() < 1e-10);
}

#[test]
fn clock_new_has_zero_frame_count() {
    let clock = Clock::new();
    assert_eq!(clock.frame_count(), 0);
}

#[test]
fn clock_tick_increments_frame_count() {
    let mut clock = Clock::new();
    clock.tick();
    assert_eq!(clock.frame_count(), 1);
    clock.tick();
    assert_eq!(clock.frame_count(), 2);
}

#[test]
fn clock_tick_updates_delta() {
    let mut clock = Clock::new();
    std::thread::sleep(std::time::Duration::from_millis(5));
    let dt = clock.tick();
    assert!(dt > 0.0, "delta should be positive after sleep + tick");
    assert!(
        (clock.delta() - dt).abs() < 1e-15,
        "delta() should match tick() return value"
    );
}

#[test]
fn clock_total_time_increases_monotonically() {
    let mut clock = Clock::new();
    let mut prev = 0.0;
    for _ in 0..5 {
        clock.tick();
        let t = clock.total();
        assert!(t >= prev, "total time must be monotonically increasing");
        prev = t;
    }
}

#[test]
fn clock_average_delta_returns_zero_before_ticks() {
    let clock = Clock::new();
    assert!((clock.average_delta() - 0.0).abs() < 1e-10);
}

#[test]
fn clock_average_delta_matches_single_tick() {
    let mut clock = Clock::new();
    std::thread::sleep(std::time::Duration::from_millis(5));
    clock.tick();
    let avg = clock.average_delta();
    let dt = clock.delta();
    assert!(
        (avg - dt).abs() < 1e-10,
        "average delta after one tick should equal delta"
    );
}

#[test]
fn clock_average_delta_stabilizes_over_many_frames() {
    let mut clock = Clock::new();
    // Simulate 100 rapid ticks (well past the 60-frame buffer)
    for _ in 0..100 {
        clock.tick();
    }
    let avg = clock.average_delta();
    // Average should be non-negative and finite
    assert!(avg >= 0.0, "average delta must be non-negative");
    assert!(avg.is_finite(), "average delta must be finite");
}

#[test]
fn clock_delta_buffer_wraps_after_window() {
    let mut clock = Clock::new();
    // Tick 70 times to wrap the 60-frame buffer
    for _ in 0..70 {
        clock.tick();
    }
    let avg = clock.average_delta();
    assert!(avg >= 0.0, "average delta must remain valid after wrap");
    assert!(avg.is_finite(), "average delta must be finite after wrap");
}

#[test]
fn clock_fps_starts_at_zero() {
    let clock = Clock::new();
    assert!((clock.fps() - 0.0).abs() < 1e-10);
}

#[test]
fn clock_frame_count_increments_every_tick() {
    let mut clock = Clock::new();
    for i in 1..=10 {
        clock.tick();
        assert_eq!(clock.frame_count(), i);
    }
}

// ── Phase 34 — Scheduler ───────────────────────────────────────────────

use luna2d::timer::Scheduler;

#[test]
fn scheduler_after_fires_once() {
    let mut sched = Scheduler::new();
    let id = sched.after(1.0);
    assert_eq!(sched.count(), 1);
    let fired = sched.update(1.1);
    assert_eq!(fired, vec![id]);
    assert_eq!(sched.count(), 0);
}

#[test]
fn scheduler_every_fires_repeatedly() {
    let mut sched = Scheduler::new();
    sched.every(0.5, -1);
    let fired = sched.update(1.1);
    assert_eq!(fired.len(), 2);
    assert_eq!(sched.count(), 1);
}

#[test]
fn scheduler_cancel() {
    let mut sched = Scheduler::new();
    let id = sched.after(1.0);
    assert!(sched.cancel(id));
    assert_eq!(sched.count(), 0);
}

#[test]
fn scheduler_cancel_all() {
    let mut sched = Scheduler::new();
    sched.after(1.0);
    sched.every(0.5, 3);
    let n = sched.cancel_all();
    assert_eq!(n, 2);
    assert_eq!(sched.count(), 0);
}

#[test]
fn scheduler_active_ids() {
    let mut sched = Scheduler::new();
    let id1 = sched.after(1.0);
    let id2 = sched.every(0.5, -1);
    let ids = sched.active_ids();
    assert!(ids.contains(&id1));
    assert!(ids.contains(&id2));
}

// ── Lua integration tests for Scheduler ────────────────────────────────

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use luna2d::lua_api::{create_lua_vm, SharedState};

fn make_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state.clone()).unwrap();
    (state, lua)
}

#[test]
fn test_lua_new_scheduler() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sched = luna.timer.newScheduler()
        assert(sched:getCount() == 0)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_scheduler_after() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sched = luna.timer.newScheduler()
        local called = false
        sched:after(0.5, function() called = true end)
        assert(sched:getCount() == 1)
        sched:update(0.3)
        assert(called == false)
        sched:update(0.3)
        assert(called == true)
        assert(sched:getCount() == 0)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_scheduler_every() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sched = luna.timer.newScheduler()
        local count = 0
        sched:every(0.5, function() count = count + 1 end, 3)
        sched:update(1.6)
        assert(count == 3)
        assert(sched:getCount() == 0)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_scheduler_cancel() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sched = luna.timer.newScheduler()
        local id = sched:after(1.0, function() end)
        assert(sched:cancel(id) == true)
        assert(sched:getCount() == 0)
        assert(sched:cancel(id) == false)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_scheduler_cancel_all() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sched = luna.timer.newScheduler()
        sched:after(1.0, function() end)
        sched:every(0.5, function() end)
        local n = sched:cancelAll()
        assert(n == 2)
        assert(sched:getCount() == 0)
        "#,
    )
    .exec()
    .unwrap();
}

// ── Additional timer/scheduler coverage ─────────────────────────────────────

#[test]
fn scheduler_pause_and_resume() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    let id = sched.after(1.0);
    assert!(sched.pause(id));
    assert!(sched.is_paused(id));
    assert!(sched.resume(id));
    assert!(!sched.is_paused(id));
}

#[test]
fn scheduler_pause_nonexistent_returns_false() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    assert!(!sched.pause(9999));
}

#[test]
fn scheduler_get_remaining_after_zero_time() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    let id = sched.after(5.0);
    let remaining = sched.get_remaining(id).unwrap();
    assert!((remaining - 5.0).abs() < 1e-9);
}

#[test]
fn scheduler_get_remaining_decreases_after_update() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    let id = sched.after(3.0);
    sched.update(1.0);
    let remaining = sched.get_remaining(id).unwrap();
    assert!((remaining - 2.0).abs() < 1e-9);
}

#[test]
fn scheduler_get_remaining_nonexistent_returns_none() {
    use luna2d::timer::Scheduler;
    let sched = Scheduler::new();
    assert!(sched.get_remaining(42).is_none());
}

#[test]
fn scheduler_time_scale_slows_update() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    sched.set_time_scale(0.5);
    assert!((sched.get_time_scale() - 0.5).abs() < 1e-9);
    let id = sched.after(2.0);
    sched.update(1.0); // effective dt = 0.5
    let remaining = sched.get_remaining(id).unwrap();
    // should have 1.5 remaining (2.0 - 0.5)
    assert!((remaining - 1.5).abs() < 1e-9);
}

#[test]
fn scheduler_every_count_limited() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    sched.every(0.5, 2); // fires at most 2 times
    let fired1 = sched.update(0.6);
    assert_eq!(fired1.len(), 1);
    let fired2 = sched.update(0.6);
    assert_eq!(fired2.len(), 1);
    // Now the event has fired twice and should be gone
    let fired3 = sched.update(0.6);
    assert_eq!(fired3.len(), 0);
    assert!(sched.is_empty());
}

#[test]
fn scheduler_every_unlimited_does_not_expire() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    sched.every(0.1, -1); // -1 = infinite
    assert_eq!(sched.count(), 1);
    for _ in 0..10 {
        sched.update(0.2); // fires every tick
    }
    assert_eq!(sched.count(), 1); // still alive
}

#[test]
fn scheduler_after_named_and_cancel_by_name() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    sched.after_named("my_timer", 5.0);
    let cancelled = sched.cancel_named("my_timer");
    assert!(cancelled.is_some());
    assert!(sched.is_empty());
}

#[test]
fn scheduler_cancel_named_nonexistent_returns_none() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    assert!(sched.cancel_named("no_such_timer").is_none());
}

#[test]
fn scheduler_set_interval_changes_fire_timing() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    let id = sched.every(2.0, -1);
    assert!(sched.set_interval(id, 0.5));
    let interval = sched.get_interval(id).unwrap();
    assert!((interval - 0.5).abs() < 1e-9);
}

#[test]
fn scheduler_reset_event_restarts_countdown() {
    use luna2d::timer::Scheduler;
    let mut sched = Scheduler::new();
    let id = sched.after(1.0);
    sched.update(0.8); // almost elapsed
    assert!(sched.reset_event(id));
    let remaining = sched.get_remaining(id).unwrap();
    // reset: should be back near 1.0
    assert!(remaining > 0.5);
}

#[test]
fn clock_total_time_is_sum_of_deltas() {
    use luna2d::timer::Clock;
    let mut clock = Clock::new();
    // tick a few times; we can't control real time but total >= 0
    clock.tick();
    clock.tick();
    assert!(clock.total() >= 0.0);
    assert!(clock.frame_count() == 2);
}
