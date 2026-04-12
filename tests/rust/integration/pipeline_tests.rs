//! Integration tests for `lurek2d::pipeline` — DAG pipeline orchestrator.

use lurek2d::pipeline::*;

// ── DAG Construction ─────────────────────────────────────────────────────────

#[test]
fn empty_pipeline_validates_ok() {
    let p = Pipeline::new("empty");
    let (valid, errors) = p.validate();
    assert!(valid);
    assert!(errors.is_empty());
}

#[test]
fn single_step_no_deps_validates() {
    let mut p = Pipeline::new("single");
    p.add_step(PipelineStep::new("step_a")).unwrap();
    let (valid, errors) = p.validate();
    assert!(valid);
    assert!(errors.is_empty());
}

// ── Topological Sort ─────────────────────────────────────────────────────────

#[test]
fn toposort_respects_dependency_order() {
    let mut p = Pipeline::new("topo");
    p.add_step(PipelineStep::new("step_a")).unwrap();
    let mut step_b = PipelineStep::new("step_b");
    step_b.deps.push("step_a".to_string());
    p.add_step(step_b).unwrap();

    let order = p.get_execution_order().unwrap();
    let pos_a = order.iter().position(|s| s == "step_a").unwrap();
    let pos_b = order.iter().position(|s| s == "step_b").unwrap();
    assert!(
        pos_a < pos_b,
        "step_a must appear before step_b in execution order"
    );
}

#[test]
fn toposort_single_chain_a_b_c() {
    let mut p = Pipeline::new("chain");
    p.add_step(PipelineStep::new("a")).unwrap();
    let mut b = PipelineStep::new("b");
    b.deps.push("a".to_string());
    p.add_step(b).unwrap();
    let mut c = PipelineStep::new("c");
    c.deps.push("b".to_string());
    p.add_step(c).unwrap();

    let order = p.get_execution_order().unwrap();
    let pa = order.iter().position(|s| s == "a").unwrap();
    let pb = order.iter().position(|s| s == "b").unwrap();
    let pc = order.iter().position(|s| s == "c").unwrap();
    assert!(pa < pb, "a must precede b");
    assert!(pb < pc, "b must precede c");
}

// ── Cycle Detection ──────────────────────────────────────────────────────────

#[test]
fn cycle_two_nodes_validation_fails() {
    let mut p = Pipeline::new("cycle");
    let mut a = PipelineStep::new("a");
    a.deps.push("b".to_string());
    p.add_step(a).unwrap();
    let mut b = PipelineStep::new("b");
    b.deps.push("a".to_string());
    p.add_step(b).unwrap();

    let (valid, errors) = p.validate();
    assert!(!valid);
    assert!(!errors.is_empty());
    let combined = errors.join(" ");
    assert!(
        combined.to_lowercase().contains("cycle"),
        "expected 'cycle' in error message, got: {combined}"
    );
}

#[test]
fn cycle_self_dep_validation_fails() {
    let mut p = Pipeline::new("self_cycle");
    let mut a = PipelineStep::new("a");
    a.deps.push("a".to_string());
    p.add_step(a).unwrap();

    let (valid, errors) = p.validate();
    assert!(!valid);
    assert!(!errors.is_empty());
}

// ── Step Configuration ───────────────────────────────────────────────────────

#[test]
fn step_new_has_pending_status() {
    let step = PipelineStep::new("x");
    assert_eq!(step.status, StepStatus::Pending);
    assert_eq!(step.attempt, 0);
    assert!((step.duration - 0.0).abs() < 1e-5);
    assert!(step.error_msg.is_none());
}

#[test]
fn step_reset_clears_runtime_fields() {
    let mut step = PipelineStep::new("x");
    step.status = StepStatus::Failed;
    step.attempt = 3;
    step.duration = 5.5;
    step.error_msg = Some("oops".to_string());

    step.reset();

    assert_eq!(step.status, StepStatus::Pending);
    assert_eq!(step.attempt, 0);
    assert!((step.duration - 0.0).abs() < 1e-5);
    assert!(step.error_msg.is_none());
}

#[test]
fn step_duplicate_name_rejected() {
    let mut p = Pipeline::new("dups");
    p.add_step(PipelineStep::new("foo")).unwrap();
    let result = p.add_step(PipelineStep::new("foo"));
    assert!(result.is_err());
}

// ── Parallel Groups ──────────────────────────────────────────────────────────

#[test]
fn parallel_groups_independent_steps_at_level_zero() {
    let mut p = Pipeline::new("parallel");
    p.add_step(PipelineStep::new("a")).unwrap();
    p.add_step(PipelineStep::new("b")).unwrap();

    let groups = p.get_parallel_groups().unwrap();
    assert_eq!(
        groups.len(),
        1,
        "both independent steps should be in a single level-0 group"
    );
    let group0 = &groups[0];
    assert!(
        group0.contains(&"a".to_string()),
        "group[0] must contain 'a'"
    );
    assert!(
        group0.contains(&"b".to_string()),
        "group[0] must contain 'b'"
    );
    assert_eq!(group0.len(), 2);
}

#[test]
fn parallel_groups_diamond_shape() {
    // A → B, A → C, {B, C} → D  (diamond)
    let mut p = Pipeline::new("diamond");
    p.add_step(PipelineStep::new("A")).unwrap();
    let mut b = PipelineStep::new("B");
    b.deps.push("A".to_string());
    p.add_step(b).unwrap();
    let mut c = PipelineStep::new("C");
    c.deps.push("A".to_string());
    p.add_step(c).unwrap();
    let mut d = PipelineStep::new("D");
    d.deps.push("B".to_string());
    d.deps.push("C".to_string());
    p.add_step(d).unwrap();

    let groups = p.get_parallel_groups().unwrap();
    assert_eq!(
        groups.len(),
        3,
        "diamond should yield 3 levels: [A], [B,C], [D]"
    );

    // Level 0: only A
    assert_eq!(groups[0], vec!["A".to_string()], "level 0 must be [A]");

    // Level 1: B and C (order within the group is by topo position, which is non-deterministic
    //          from the HashMap, so check membership only)
    assert!(
        groups[1].contains(&"B".to_string()),
        "level 1 must contain B"
    );
    assert!(
        groups[1].contains(&"C".to_string()),
        "level 1 must contain C"
    );
    assert_eq!(groups[1].len(), 2, "level 1 must have exactly 2 steps");

    // Level 2: only D
    assert_eq!(groups[2], vec!["D".to_string()], "level 2 must be [D]");
}

// ── Step Removal ─────────────────────────────────────────────────────────────

#[test]
fn remove_step_cleans_dep_references() {
    let mut p = Pipeline::new("removal");
    p.add_step(PipelineStep::new("a")).unwrap();
    let mut b = PipelineStep::new("b");
    b.deps.push("a".to_string());
    p.add_step(b).unwrap();

    let removed = p.remove_step("a");
    assert!(
        removed,
        "remove_step should return true for an existing step"
    );

    let b_step = p.get_step("b").unwrap();
    assert!(
        b_step.deps.is_empty(),
        "dep reference to 'a' should be cleaned from 'b'"
    );
}

#[test]
fn remove_nonexistent_step_returns_false() {
    let mut p = Pipeline::new("removal");
    assert!(!p.remove_step("ghost"));
}

// ── Missing Dependency ───────────────────────────────────────────────────────

#[test]
fn missing_dependency_validation_error() {
    let mut p = Pipeline::new("missing_dep");
    let mut b = PipelineStep::new("b");
    b.deps.push("ghost".to_string());
    p.add_step(b).unwrap();

    let (valid, errors) = p.validate();
    assert!(!valid);
    let combined = errors.join(" ");
    assert!(
        combined.contains("ghost"),
        "error message should mention the missing dep 'ghost', got: {combined}"
    );
}

// ── Scheduler Timers ─────────────────────────────────────────────────────────

#[test]
fn scheduler_zero_delay_ready_immediately() {
    let mut p = Pipeline::new("sched_zero");
    // PipelineStep::new defaults delay to 0.0
    p.add_step(PipelineStep::new("s")).unwrap();

    let mut sched = PipelineScheduler::new();
    sched.start(&p); // timer[s] = 0.0

    // Transition step to Waiting — scheduler fires steps that are in Waiting state
    p.get_step_mut("s").unwrap().status = StepStatus::Waiting;

    let ready = sched.update(0.0, &p); // 0.0 - 0.0 = 0.0 ≤ 0.0  → ready
    assert!(
        ready.contains(&"s".to_string()),
        "zero-delay step should be ready after update(0.0)"
    );
}

#[test]
fn scheduler_step_fires_after_delay_elapses() {
    let mut p = Pipeline::new("sched_delay");
    let mut step = PipelineStep::new("s");
    step.delay = 1.0;
    p.add_step(step).unwrap();

    let mut sched = PipelineScheduler::new();
    sched.start(&p); // timer[s] = 1.0

    // Mark step as Waiting so the scheduler counts it
    p.get_step_mut("s").unwrap().status = StepStatus::Waiting;

    // First tick: 1.0 - 0.5 = 0.5   → NOT ready
    let not_ready = sched.update(0.5, &p);
    assert!(
        !not_ready.contains(&"s".to_string()),
        "step with 0.5s remaining should not be ready yet"
    );

    // Second tick: 0.5 - 0.6 = -0.1 → ready
    let ready = sched.update(0.6, &p);
    assert!(
        ready.contains(&"s".to_string()),
        "step should be ready once delay has elapsed"
    );
}

// ── Pipeline Result ──────────────────────────────────────────────────────────

#[test]
fn pipeline_result_is_success_when_no_failures() {
    let mut result = PipelineResult::new();
    result.completed.push("step_a".to_string());
    assert!(
        result.is_success(),
        "result with no failures should be a success"
    );
}

#[test]
fn pipeline_result_not_success_when_failed() {
    let mut result = PipelineResult::new();
    result.failed.push("step_a".to_string());
    assert!(
        !result.is_success(),
        "result with a failed step should not be a success"
    );
}
