# Roadmap — Block Simulation Library

> See also: [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md) · [RISKS-AND-ASSUMPTIONS.md](RISKS-AND-ASSUMPTIONS.md)

---

## Phases Overview

| Phase | Name | Scope | Done-when |
|---|---|---|---|
| 0 | Spike & Migration Audit | No engine code; research only | YAML→TOML feasibility confirmed; algorithm gaps in math identified |
| 1 | Flat Kernel Core | Rust types + spec + compiler + basic tick | A flat graph of 3+ blocks runs headlessly end-to-end with Rust tests |
| 2 | Lua Bridge + Basic API | Bridge + lifecycle + step + inspect | `lurek.sim.create/step/run/snapshot/destroy` all work; Lua BDD tests pass |
| 3 | Monitor & Event Log | Monitor engine + event log + drain API | All 21 monitor types sample correctly; alert thresholds fire; Lua drain works |
| 4 | Anomaly Engine | Full anomaly lifecycle + all 8 effect types | Anomaly inject/expire, cascade, block-effect, and event log work; headless tests green |
| 5 | Operational Mechanics | DLQ, approval, circuit breaker, replay, checkpoint | All operational lifecycle tests pass; poll-step approval pattern documented |
| 6 | Composite Support | Composite flattening, scoped ports, composite boundary monitors | 3-level nested composites work; golden snapshots are stable |
| 7 | Advanced Mechanics | Batch, time window, warmup, energy, rate limit, resource | All `Mechanic` variants pass isolation tests; domain blueprint Lua tests pass |
| 8 | Lua Helper Library | `library/blocksim/` DSL, blueprints, multi-run, analytics helpers | At least 3 domain blueprint demos run end-to-end from TOML+Lua |
| 9 | Integration + Examples | End-to-end demos, examples/, integration tests | Full scenario (200 blocks, 5 anomalies, post-run analytics) runs correctly |
| 10 | Performance + Polish | Benchmark, optimize hot path, docs, spec validation UX | Benchmark passes 10k ticks/s; full Lua API documented |

---

## Phase 0 — Spike and Migration Audit

**Scope:** No new engine code. Pure research output.

**Goal:** Confirm two things that the feasibility study identifies as medium-risk:
1. YAML→TOML migration is feasible for representative source files.
2. Topological sort and cycle detection are available or easily added to `src/math/`.

**Tasks:**

- Read five representative YAML scenario files from source project.
- Check whether YAML anchors, merge keys, or multi-document files are present.
- Convert one representative file to TOML+Lua manually and identify gaps.
- Read `src/math/mod.rs` and confirm or enumerate missing graph algorithm utilities.
- Write a migration note in `work/block-sim-feasibility/reports/` with findings.

**Done-when:**
- Written confirmation that TOML authoring covers all source constructs (possibly with added Lua glue for anchor-like reuse).
- Topological sort is either already in `src/math` or a plan exists to add it.

**Risk addressed:** R-01, R-04, R-08.

**Effort estimate:** 0.5–1 day. Research only; no implementation.

---

## Phase 1 — Flat Kernel Core

**Scope:** `src/blocksim/` created with all structural files. Core types implemented. Compiler works for flat (non-composite) graphs. Tick pipeline phases 1–7 implemented for the basic block types (Source, Sink, Transform, Gate, Router, Buffer).

**New files:**
`src/blocksim/mod.rs` `spec.rs` `model.rs` `compiler.rs` `runtime.rs` `tick.rs` `queue.rs` `value.rs` `filter.rs` `error.rs`

**New test file:**
`tests/rust/unit/blocksim_tests.rs`

**Acceptance gates:**
- [ ] `cargo check --lib` passes with the new module
- [ ] A flat 3-block graph (Source → Transform → Sink) compiles, steps 100 ticks, and produces expected item counts in Rust tests
- [ ] `tests/rust/unit/blocksim_tests.rs` has at minimum: 1 spec-parse test, 1 compile test, 1 tick test, 1 edge-flow test
- [ ] No `#[allow(dead_code)]` suppressions for public types
- [ ] `cargo test --test blocksim_tests` is green

**Depends on:** Phase 0 (algorithm gaps identified).

**Risk addressed:** R-05, R-06 (flat-only, composites deferred).

**Effort estimate:** 3–4 days.

---

## Phase 2 — Lua Bridge + Basic API

**Scope:** `src/lua_api/blocksim_api.rs` created. Registered in `src/lua_api/mod.rs` behind `modules.blocksim` flag. `lurek.sim.create`, `lurek.sim.step`, `lurek.sim.run`, `lurek.sim.snapshot`, `lurek.sim.destroy`, `lurek.sim.validate_spec`, `lurek.sim.load_toml` implemented.

**New files:**
`src/lua_api/blocksim_api.rs`

**Modified files:**
`src/lua_api/mod.rs` `src/engine/config.rs` `src/engine/app.rs`

**New test file:**
`tests/lua/unit/test_blocksim.lua` (+ entry in `tests/lua/harness.rs`)

**Acceptance gates:**
- [ ] `lurek.sim.create(spec)` accepts a Lua table, returns a sim userdata
- [ ] `lurek.sim.step(sim, 10)` returns a stats table
- [ ] `lurek.sim.run(sim)` runs to natural end
- [ ] `lurek.sim.snapshot(sim)` returns a Lua table with `tick`, `blocks` subtable
- [ ] `lurek.sim.destroy(sim)` does not panic or leak
- [ ] `lurek.sim.validate_spec(bad_spec)` returns `nil, err_table` with field names
- [ ] `modules.blocksim = false` in config → `lurek.sim` is nil; logs clear warning
- [ ] Lua BDD test file has ≥ 10 passing tests
- [ ] `cargo test --test lua_tests lua_test_unit_blocksim` green

**Risk addressed:** R-02 (bridge stays thin; no arbitrary Lua callbacks in tick loop).

**Effort estimate:** 2–3 days.

---

## Phase 3 — Monitor and Event Log

**Scope:** `monitor.rs` implemented with phase-8 sampling. `event_log.rs` implemented. `lurek.sim.drain_monitors`, `lurek.sim.peek_monitors`, `lurek.sim.drain_events` added to bridge.

**New files:** `src/blocksim/monitor.rs` `src/blocksim/event_log.rs`

**Acceptance gates:**
- [ ] All 21 monitor types can be declared and return samples
- [ ] Alert threshold rules (`gt`, `lt`, `eq`, `ne`, `between`) fire correctly
- [ ] Monitor buffer is a ring buffer; exceeding max-samples does not panic
- [ ] `lurek.sim.drain_monitors()` returns correctly shaped Lua tables
- [ ] Rust test: monitor values match hand-calculated expected values for a known spec
- [ ] Lua BDD: monitor declared, sim run 100 ticks, drain returns at least one sample per monitor

**Risk addressed:** R-03 (ring buffer overflow).

**Effort estimate:** 2 days.

---

## Phase 4 — Anomaly Engine

**Scope:** `anomaly.rs` implemented with all lifecycle states (`Inactive/Active/Expired/Blocked/Cascade`). All 8 effect types implemented. `lurek.sim.inject_anomaly`, `lurek.sim.expire_anomaly`, `lurek.sim.anomaly_status` added.

**New files:** `src/blocksim/anomaly.rs`

**Acceptance gates:**
- [ ] Anomaly activates at the correct tick when trigger condition fires
- [ ] All 8 effect types (`block_state`, `script_param`, `data`, `signal`, `value`, `filter`, `container`, `port`) produce verifiable state changes in Rust tests
- [ ] Cascade triggers a secondary anomaly correctly
- [ ] `ANOMALY_ACTIVATED` and `ANOMALY_EXPIRED` events appear in the event log
- [ ] Lua BDD: inject anomaly, run 10 ticks, assert block paused during anomaly window

**Risk addressed:** R-09 (test builder for anomaly scenarios).

**Effort estimate:** 3 days.

---

## Phase 5 — Operational Mechanics

**Scope:** `approval.rs`, `dlq.rs`, `replay.rs`, `circuit_breaker.rs` implemented. Full set of Lua API functions for these systems added.

**New files:** `src/blocksim/approval.rs` `dlq.rs` `replay.rs` `circuit_breaker.rs`

**Acceptance gates:**
- [ ] Approval hold stops item at block; other blocks continue processing
- [ ] `lurek.sim.pending_approvals()` returns held items; `lurek.sim.approve()` releases them
- [ ] `lurek.sim.reject()` sends item to DLQ
- [ ] DLQ captures overflow items; `lurek.sim.replay_dlq()` re-injects correctly
- [ ] Circuit breaker transitions: CLOSED → OPEN on consecutive failures; HALF_OPEN on probe; CLOSED on recovery
- [ ] Checkpoint save + restore: two runs from the same checkpoint produce identical monitor samples (determinism test)

**Risk addressed:** R-05, R-07.

**Effort estimate:** 4 days.

---

## Phase 6 — Composite Support

**Scope:** `composite.rs` implemented. Compiler flattens composites before execution. Scoped port id resolution. Composite boundary monitors. Lua helpers in `library/blocksim/composite.lua`.

**New files:** `src/blocksim/composite.rs` `library/blocksim/composite.lua`

**Acceptance gates:**
- [ ] Single-level composite compiles and runs correctly
- [ ] Two-level composite compiles and runs correctly
- [ ] Three-level composite (golden snapshot test) produces stable output across 3 runs
- [ ] Port id collision across composite scopes is detected at compile time with a clear error
- [ ] Composite boundary monitor samples crossing-items-per-tick correctly
- [ ] Golden snapshot test in `tests/rust/golden/`

**Risk addressed:** R-06.

**Effort estimate:** 4–5 days.

---

## Phase 7 — Advanced Mechanics

**Scope:** All `Mechanic` enum variants implemented: Batch, TimeWindow, Warmup, Energy, RateLimit, ConcurrencyLimit, Yield, ShadowMode, CanaryMode, Priority, Bulkhead, SchemaVersion, MaintenanceWindow.

**New files:** `src/blocksim/script.rs` `clock.rs` (if not already present) `resource.rs`

**Acceptance gates:**
- [ ] Each mechanic variant has at least one Rust unit test
- [ ] Batch mechanic: does not emit until batch_size reached; emits correctly
- [ ] TimeWindow: blocks outside time window hold items; passes inside window
- [ ] Warmup: emits nothing during warmup period; resumes normally after
- [ ] Energy: block goes offline when budget exhausted
- [ ] RateLimit: throughput is capped per tick window
- [ ] Priority mechanic: highest-priority items dequeued first

**Effort estimate:** 5 days.

---

## Phase 8 — Lua Helper Library

**Scope:** `library/blocksim/` Lua library: graph DSL builder, scenario loader, blueprint patterns, multi-run orchestration, analytics helpers.

**New files:** `library/blocksim/init.lua` `graph.lua` `blueprints.lua` `scenario.lua` `analytics.lua` `reports.lua`

**New test file:** `tests/lua/library/test_blocksim_lib.lua`

**Acceptance gates:**
- [ ] At least 3 domain blueprint implementations (e.g., factory, approval_saga, monitoring_canary)
- [ ] `scenario.run_pair(base_spec, anomaly_spec)` orchestrates baseline + anomaly run and returns both monitor sets
- [ ] `analytics.compare(base_samples, variant_samples)` returns a KPI comparison table
- [ ] All library tests pass headlessly

**Effort estimate:** 4–5 days.

---

## Phase 9 — Integration and Examples

**Scope:** End-to-end integration tests. `examples/blocksim.lua` single-file example. Integration test across `blocksim` + `dataframe` + `thread`. Demo app using `lurek.sim` + `lurek.terminal` as a text-mode dashboard.

**New files:** `examples/blocksim.lua` `tests/lua/integration/test_blocksim_dataframe.lua` `demos/block_sim_demo/` (optional)

**Acceptance gates:**
- [ ] Integration test: create sim, run, drain monitors, load into dataframe, compute stats → all pass headlessly
- [ ] Example file runs without errors (`cargo run -- examples/blocksim.lua` equivalent)
- [ ] Optional demo: text-mode simulation dashboard visible on screen

**Effort estimate:** 2–3 days.

---

## Phase 10 — Performance and Polish

**Scope:** Benchmark the hot tick path. Profile if below 10k ticks/second for a 50-block graph. Document full `lurek.sim.*` API. Spec validation error messages improved. AGENT.md and specs/blocksim.md written.

**Acceptance gates:**
- [ ] Benchmark result ≥ 10k ticks/s (50-block flat graph, 5 monitors, no anomalies)
- [ ] `python tools/docs/collect_docs.py --report-missing` passes with zero missing items for `src/blocksim/`
- [ ] `src/blocksim/AGENT.md` created
- [ ] `specs/blocksim.md` created
- [ ] `docs/CHANGELOG.md` updated for this feature
- [ ] Full quality gate: `cargo test && cargo clippy -- -D warnings`

**Effort estimate:** 2–3 days.

---

## Dependency Graph

```
Phase 0 ──▶ Phase 1 ──▶ Phase 2 ──▶ Phase 3
                    │                      │
                    ▼                      ▼
               Phase 4              Phase 5
                    │                      │
                    └──────────┬───────────┘
                               ▼
                          Phase 6
                               │
                               ▼
                          Phase 7
                               │
                               ▼
                          Phase 8
                               │
                               ▼
                          Phase 9 ──▶ Phase 10
```

Phases 3 and 4 can be developed in parallel after Phase 2 is green. Phase 5 requires Phase 4.
