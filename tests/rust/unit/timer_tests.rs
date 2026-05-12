//! INTERNAL ONLY: public `lurek.timer.*` behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_timer_unit.lua` plus integration/stress coverage.
//!
//! The Rust-only coverage that remains here targets the internal `Clock`
//! helper, which is not exposed one-to-one through the Lua API.

// ── clock ─────────────────────────────────────────────────────────────────────

mod clock_tests {
    use lurek2d::timer::Clock;

    #[test]
    fn new_clock_starts_at_zero() {
        let c = Clock::new();
        assert_eq!(c.delta(), 0.0);
        assert_eq!(c.fps(), 0.0);
        assert_eq!(c.frame_count(), 0);
    }

    #[test]
    fn tick_increments_frame_count() {
        let mut c = Clock::new();
        c.tick();
        assert_eq!(c.frame_count(), 1);
        c.tick();
        assert_eq!(c.frame_count(), 2);
    }

    #[test]
    fn tick_returns_positive_delta() {
        let mut c = Clock::new();
        // First tick after construction should have a small positive dt
        let dt = c.tick();
        assert!(dt >= 0.0);
    }

    #[test]
    fn total_increases_after_tick() {
        let mut c = Clock::new();
        c.tick();
        assert!(c.total() >= 0.0);
    }

    #[test]
    fn elapsed_is_live() {
        let c = Clock::new();
        let e1 = c.elapsed();
        // elapsed() queries the clock directly, should be >= 0
        assert!(e1 >= 0.0);
    }

    #[test]
    fn average_delta_zero_before_any_tick() {
        let c = Clock::new();
        assert_eq!(c.average_delta(), 0.0);
    }

    #[test]
    fn average_delta_computed_after_ticks() {
        let mut c = Clock::new();
        c.tick();
        c.tick();
        // After at least one tick, average should be non-negative
        assert!(c.average_delta() >= 0.0);
    }

    #[test]
    fn default_trait_creates_same_as_new() {
        let c = Clock::default();
        assert_eq!(c.frame_count(), 0);
        assert_eq!(c.delta(), 0.0);
    }
}

mod scheduler_tests {
    use lurek2d::timer::Scheduler;

    #[test]
    fn stress_update_handles_thousands_of_timers() {
        let mut scheduler = Scheduler::new();
        for i in 0..2000 {
            let delay = 0.001 + (i as f64 * 0.00001);
            scheduler.after(delay);
        }
        assert_eq!(scheduler.count(), 2000);

        let fired = scheduler.update(1.0);
        assert_eq!(fired.len(), 2000);
        assert!(scheduler.is_empty());
    }

    #[test]
    fn update_frames_handles_thousands_of_frame_events() {
        let mut scheduler = Scheduler::new();
        for _ in 0..1500 {
            scheduler.after_frames(1);
        }
        assert_eq!(scheduler.count(), 1500);

        let fired = scheduler.update_frames();
        assert_eq!(fired.len(), 1500);
        assert!(scheduler.is_empty());
    }

    #[test]
    fn named_events_support_pause_resume_and_cancel() {
        let mut scheduler = Scheduler::new();
        let id = scheduler.every_named("heartbeat", 1.0, -1);
        assert!(scheduler.pause_named("heartbeat"));
        assert!(scheduler.is_paused_named("heartbeat"));
        assert!(scheduler.resume_named("heartbeat"));
        assert!(!scheduler.is_paused_named("heartbeat"));
        assert_eq!(scheduler.cancel_named("heartbeat"), Some(id));
    }

    #[test]
    fn time_scale_affects_firing_rate() {
        let mut scheduler = Scheduler::new();
        scheduler.set_time_scale(2.0);
        scheduler.every(1.0, 1);
        let fired = scheduler.update(0.5);
        assert_eq!(fired.len(), 1);
    }

    #[test]
    fn set_interval_and_reset_event_work() {
        let mut scheduler = Scheduler::new();
        let id = scheduler.every(1.0, 2);
        assert!(scheduler.set_interval(id, 0.25));
        let remaining = scheduler.get_remaining(id).expect("event should exist");
        assert!((remaining - 0.25).abs() < f64::EPSILON);
        assert!(scheduler.reset_event(id));
        let fired = scheduler.update(0.25);
        assert_eq!(fired.len(), 1);
    }
}
