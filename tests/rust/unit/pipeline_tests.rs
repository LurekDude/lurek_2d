//! Tests for the pipeline module.

use std::collections::HashMap;

use lurek2d::pipeline::dag::{ErrorMode, Pipeline};
use lurek2d::pipeline::result::PipelineStatus;
use lurek2d::pipeline::scheduler::PipelineScheduler;
use lurek2d::pipeline::step::{ErrorPolicy, PipelineStep, StepStatus};

// ── step tests ──────────────────────────────────────────────────────────────

mod step_tests {
    use super::*;

    #[test]
    fn new_step_has_pending_status() {
        let s = PipelineStep::new("test");
        assert_eq!(s.name, "test");
        assert_eq!(s.status, StepStatus::Pending);
        assert_eq!(s.attempt, 0);
        assert!(s.deps.is_empty());
    }

    #[test]
    fn reset_clears_runtime_state() {
        let mut s = PipelineStep::new("test");
        s.status = StepStatus::Completed;
        s.attempt = 5;
        s.duration = 2.0;
        s.error_msg = Some("err".into());
        s.reset();
        assert_eq!(s.status, StepStatus::Pending);
        assert_eq!(s.attempt, 0);
        assert!((s.duration).abs() < f32::EPSILON);
        assert!(s.error_msg.is_none());
    }

    #[test]
    fn step_status_as_str_covers_all_variants() {
        assert_eq!(StepStatus::Pending.as_str(), "pending");
        assert_eq!(StepStatus::Waiting.as_str(), "waiting");
        assert_eq!(StepStatus::Running.as_str(), "running");
        assert_eq!(StepStatus::Completed.as_str(), "completed");
        assert_eq!(StepStatus::Failed.as_str(), "failed");
        assert_eq!(StepStatus::Skipped.as_str(), "skipped");
        assert_eq!(StepStatus::Cancelled.as_str(), "cancelled");
    }

    #[test]
    fn new_step_default_error_policy_is_abort() {
        let s = PipelineStep::new("x");
        assert_eq!(s.on_error, ErrorPolicy::Abort);
    }

    #[test]
    fn step_metadata_is_initially_empty() {
        let s = PipelineStep::new("x");
        assert!(s.metadata.is_empty());
        assert!(s.tag.is_none());
    }
}

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

// ── dag tests ───────────────────────────────────────────────────────────────

mod dag_tests {
    use super::*;

    #[test]
    fn new_pipeline_has_zero_steps() {
        let p = Pipeline::new("test");
        assert_eq!(p.get_step_count(), 0);
        assert_eq!(p.name, "test");
    }

    #[test]
    fn add_step_increases_count() {
        let mut p = Pipeline::new("test");
        p.add_step(PipelineStep::new("a")).unwrap();
        assert_eq!(p.get_step_count(), 1);
    }

    #[test]
    fn add_duplicate_step_returns_error() {
        let mut p = Pipeline::new("test");
        p.add_step(PipelineStep::new("a")).unwrap();
        assert!(p.add_step(PipelineStep::new("a")).is_err());
    }

    #[test]
    fn remove_step_strips_dep_references() {
        let mut p = Pipeline::new("test");
        p.add_step(PipelineStep::new("a")).unwrap();
        let mut b = PipelineStep::new("b");
        b.deps.push("a".into());
        p.add_step(b).unwrap();
        p.remove_step("a");
        let b_step = p.get_step("b").unwrap();
        assert!(b_step.deps.is_empty());
    }

    #[test]
    fn validate_catches_missing_dep() {
        let mut p = Pipeline::new("test");
        let mut a = PipelineStep::new("a");
        a.deps.push("nonexistent".into());
        p.add_step(a).unwrap();
        let (valid, errors) = p.validate();
        assert!(!valid);
        assert!(!errors.is_empty());
    }

    #[test]
    fn validate_catches_cycle() {
        let mut p = Pipeline::new("test");
        let mut a = PipelineStep::new("a");
        a.deps.push("b".into());
        let mut b = PipelineStep::new("b");
        b.deps.push("a".into());
        p.add_step(a).unwrap();
        p.add_step(b).unwrap();
        let (valid, errors) = p.validate();
        assert!(!valid);
        assert!(errors.iter().any(|e| e.contains("cycle")));
    }

    #[test]
    fn execution_order_respects_deps() {
        let mut p = Pipeline::new("test");
        p.add_step(PipelineStep::new("a")).unwrap();
        let mut b = PipelineStep::new("b");
        b.deps.push("a".into());
        p.add_step(b).unwrap();
        let order = p.get_execution_order().unwrap();
        let pos_a = order.iter().position(|n| n == "a").unwrap();
        let pos_b = order.iter().position(|n| n == "b").unwrap();
        assert!(pos_a < pos_b);
    }

    #[test]
    fn parallel_groups_separates_independent_steps() {
        let mut p = Pipeline::new("test");
        p.add_step(PipelineStep::new("a")).unwrap();
        p.add_step(PipelineStep::new("b")).unwrap();
        let groups = p.get_parallel_groups().unwrap();
        assert_eq!(groups.len(), 1);
        assert_eq!(groups[0].len(), 2);
    }

    #[test]
    fn parallel_groups_creates_levels_for_deps() {
        let mut p = Pipeline::new("test");
        p.add_step(PipelineStep::new("a")).unwrap();
        let mut b = PipelineStep::new("b");
        b.deps.push("a".into());
        p.add_step(b).unwrap();
        let groups = p.get_parallel_groups().unwrap();
        assert_eq!(groups.len(), 2);
    }

    #[test]
    fn clear_removes_all_steps() {
        let mut p = Pipeline::new("test");
        p.add_step(PipelineStep::new("a")).unwrap();
        p.add_step(PipelineStep::new("b")).unwrap();
        p.clear();
        assert_eq!(p.get_step_count(), 0);
    }

    #[test]
    fn error_mode_roundtrip() {
        assert_eq!(ErrorMode::from_str_lua("abort").unwrap(), ErrorMode::Abort);
        assert_eq!(
            ErrorMode::from_str_lua("continue").unwrap(),
            ErrorMode::Continue
        );
        assert!(ErrorMode::from_str_lua("unknown").is_err());
        assert_eq!(ErrorMode::Abort.as_str(), "abort");
        assert_eq!(ErrorMode::Continue.as_str(), "continue");
    }

    #[test]
    fn reset_resets_all_step_states() {
        let mut p = Pipeline::new("test");
        let mut a = PipelineStep::new("a");
        a.status = StepStatus::Completed;
        a.attempt = 3;
        p.add_step(a).unwrap();
        p.reset();
        let step = p.get_step("a").unwrap();
        assert_eq!(step.status, StepStatus::Pending);
        assert_eq!(step.attempt, 0);
    }

    #[test]
    fn to_ascii_diagram_contains_pipeline_name() {
        let mut p = Pipeline::new("my_pipeline");
        p.add_step(PipelineStep::new("init")).unwrap();
        let diagram = p.to_ascii_diagram();
        assert!(diagram.contains("my_pipeline"));
        assert!(diagram.contains("[init]"));
    }

    #[test]
    fn add_sub_pipeline_prefixes_step_names() {
        let mut main = Pipeline::new("main");
        main.add_step(PipelineStep::new("setup")).unwrap();

        let mut sub = Pipeline::new("sub");
        sub.add_step(PipelineStep::new("s1")).unwrap();
        sub.add_step(PipelineStep::new("s2")).unwrap();

        main.add_sub_pipeline(sub, "child", vec!["setup".into()])
            .unwrap();
        assert!(main.get_step("child/s1").is_some());
        assert!(main.get_step("child/s2").is_some());
    }

    #[test]
    fn collect_result_aggregates_statuses() {
        let p = Pipeline::new("test");
        let mut statuses = HashMap::new();
        statuses.insert("a".to_string(), (StepStatus::Completed, None));
        statuses.insert("b".to_string(), (StepStatus::Failed, Some("oops".into())));
        let result = p.collect_result(&statuses, 1.5);
        assert_eq!(result.completed.len(), 1);
        assert_eq!(result.failed.len(), 1);
        assert_eq!(result.errors.len(), 1);
        assert!((result.total_duration - 1.5).abs() < f32::EPSILON);
        assert_eq!(result.status, PipelineStatus::Failed);
    }

    #[test]
    fn are_deps_satisfied_all_completed() {
        let mut p = Pipeline::new("test");
        p.add_step(PipelineStep::new("a")).unwrap();
        let mut b = PipelineStep::new("b");
        b.deps.push("a".into());
        p.add_step(b).unwrap();
        let mut statuses = HashMap::new();
        statuses.insert("a".to_string(), StepStatus::Completed);
        assert!(p.are_deps_satisfied("b", &statuses).unwrap());
    }

    #[test]
    fn are_deps_satisfied_required_dep_failed() {
        let mut p = Pipeline::new("test");
        p.add_step(PipelineStep::new("a")).unwrap();
        let mut b = PipelineStep::new("b");
        b.deps.push("a".into());
        p.add_step(b).unwrap();
        let mut statuses = HashMap::new();
        statuses.insert("a".to_string(), StepStatus::Failed);
        assert!(!p.are_deps_satisfied("b", &statuses).unwrap());
    }
}
