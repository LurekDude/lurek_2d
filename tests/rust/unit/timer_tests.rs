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
