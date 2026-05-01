//! INTERNAL ONLY: Rust-only tests for pipeline scheduler internals that are not directly
//! asserted through `lurek.pipeline.*`.
//!
//! Public pipeline behaviour is covered by `tests/lua/unit/test_pipeline_unit.lua`.
//! The remaining Rust tests keep scheduler state transitions and delay handling.

use lurek2d::pipeline::dag::Pipeline;
use lurek2d::pipeline::scheduler::PipelineScheduler;
use lurek2d::pipeline::step::PipelineStep;

// ── scheduler tests ─────────────────────────────────────────────────────────

mod scheduler_tests {
    use super::*;

    #[test]
    fn new_scheduler_is_stopped() {
        let s = PipelineScheduler::new();
        assert!(!s.is_running);
        assert!((s.elapsed).abs() < f32::EPSILON);
    }

    #[test]
    fn start_marks_running() {
        let mut s = PipelineScheduler::new();
        let p = Pipeline::new("test");
        s.start(&p);
        assert!(s.is_running);
    }

    #[test]
    fn update_advances_elapsed() {
        let mut s = PipelineScheduler::new();
        let p = Pipeline::new("test");
        s.start(&p);
        s.update(0.1, &p);
        assert!((s.elapsed - 0.1).abs() < 1e-5);
    }

    #[test]
    fn update_when_stopped_returns_empty() {
        let mut s = PipelineScheduler::new();
        let p = Pipeline::new("test");
        let ready = s.update(0.1, &p);
        assert!(ready.is_empty());
    }

    #[test]
    fn reset_clears_state() {
        let mut s = PipelineScheduler::new();
        let mut p = Pipeline::new("test");
        p.add_step(PipelineStep::new("a")).unwrap();
        s.start(&p);
        s.update(1.0, &p);
        s.reset();
        assert!(!s.is_running);
        assert!((s.elapsed).abs() < f32::EPSILON);
    }

    #[test]
    fn default_matches_new() {
        let a = PipelineScheduler::new();
        let b = PipelineScheduler::default();
        assert_eq!(a.is_running, b.is_running);
    }

    #[test]
    fn mark_step_waiting_inserts_delay() {
        let mut s = PipelineScheduler::new();
        let mut p = Pipeline::new("test");
        let mut step = PipelineStep::new("a");
        step.delay = 2.0;
        p.add_step(step).unwrap();
        s.start(&p);
        s.mark_step_waiting("a", &p);
        let ready = s.update(1.0, &p);
        assert!(ready.is_empty());
    }
}
