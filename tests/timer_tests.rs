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
