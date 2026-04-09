# Implementation Plan

> Concrete file-by-file work breakdown by phase. Each phase is one logical commit or a small commit sequence.
> See [ROADMAP.md](ROADMAP.md) for phased goals and acceptance gates.
> See [RUST-MODULE-DESIGN.md](RUST-MODULE-DESIGN.md) and [LUA-API-DESIGN.md](LUA-API-DESIGN.md) for type and API detail.

---

## Before You Start

1. Re-read `docs/architecture/philosophy.md` and `docs/architecture/engine-architecture.md` — confirm tier rules are current.
2. Run `cargo check --lib` to confirm the repository is clean before touching anything.
3. Confirm branch: `git rev-parse --abbrev-ref HEAD`.
4. Create a session work folder: `work/blocksim-impl/` with the standard 8 subfolders.

---

## Phase 0 — Spike and Migration Audit

**Responsible agent:** Research (read-only, no new source files)

### Tasks

| # | Task | Output |
|---|---|---|
| 0.1 | Read five representative source YAML files | Summary of YAML anchor/merge usage |
| 0.2 | Convert one source YAML to TOML + Lua manually | `work/blocksim-impl/data/example_migration.toml` + `example_migration.lua` |
| 0.3 | Read `src/math/mod.rs` for topological sort | Note: present or action required |
| 0.4 | Check `src/data/mod.rs` for Rust-level TOML API (not just Lua bridge) | Note: suitable for kernel use or action required |
| 0.5 | Write findings memo | `work/blocksim-impl/reports/phase0_findings.md` |

**Commit:** None. Research only.

---

## Phase 1 — Flat Kernel Core

**Responsible agent:** Developer

### New files

| File | What to implement |
|---|---|
| `src/blocksim/mod.rs` | Module doc, `pub use` re-exports, `pub struct SimHandle`, feature-gate doc |
| `src/blocksim/error.rs` | `SimError` enum with all variants listed in RUST-MODULE-DESIGN.md §8 |
| `src/blocksim/spec.rs` | `SimSpec`, `BlockSpec`, `PortSpec`, `EdgeSpec`, `ContainerSpec`, `SimConfig` — all with `Default` trait |
| `src/blocksim/model.rs` | `BlockType` enum, `Mechanic` enum, `PortSide`, `PortKind`, `EdgeKind`, `PortRef`, `ItemPayload` |
| `src/blocksim/queue.rs` | `ItemQueue`: `VecDeque<SimItem>` wrapper with capacity check, stats counters |
| `src/blocksim/value.rs` | `ValueAccumulator`, `ValuePath` — rolling window sum/avg for VALUE edges |
| `src/blocksim/filter.rs` | `FilterChain`, `FilterRule` enum (Pass, Drop, Transform, Reroute, ParamInject) |
| `src/blocksim/compiler.rs` | `compile(spec: &SimSpec) → Result<ExecutionPlan, SimError>` — parse, validate, topological sort, bind ports |
| `src/blocksim/runtime.rs` | `SimRuntime` struct — owns all live state; `new(plan)`, `reset()`, `current_tick()` |
| `src/blocksim/tick.rs` | `tick(runtime: &mut SimRuntime)` — 8-phase pipeline; only phases 1 (clock_advance) + 5 (block_exec) + 7 (value_rollup) for now; stubs for the rest |
| `tests/rust/unit/blocksim_tests.rs` | 15+ unit tests: spec parse, compile, step, edge flow, error cases |

### Modified files

| File | Change |
|---|---|
| `Cargo.toml` | Add `[[test]] name = "blocksim_tests" path = "tests/rust/unit/blocksim_tests.rs"` |
| `src/blocksim/mod.rs` | Add `// SAFETY: no unsafe needed in Phase 1` comment placeholder |

### Implementation sequence

1. `error.rs` first — everything else depends on `SimError`.
2. `spec.rs`, `model.rs` — pure data types, no logic.
3. `queue.rs`, `filter.rs`, `value.rs` — data structure primitives.
4. `compiler.rs` — topological sort + port binding (use `std` BTreeMap, not `src/graph`).
5. `runtime.rs` — struct shell, no logic yet.
6. `tick.rs` — block_exec loop only; 4 block types: Source, Sink, Transform, Gate.
7. `mod.rs` — re-exports and module doc.
8. `tests/rust/unit/blocksim_tests.rs` — write tests before marking phase done.

### Key constraint

Do NOT import `src/graph`, `src/dataframe`, `src/gui`, `src/physics`, or `src/graphics` at any point.

### Commit

```
feat(blocksim): Phase 1 — flat kernel core (spec, compiler, tick, queue)
```

---

## Phase 2 — Lua Bridge + Basic API

**Responsible agent:** Developer (bridge pattern) / Lua-Designer (API review before merging)

### New files

| File | What to implement |
|---|---|
| `src/lua_api/blocksim_api.rs` | `pub fn register(lua, luna, state)` — registers `lurek.sim.*` table; all lifecycle functions |
| `tests/lua/unit/test_blocksim.lua` | BDD test file with `describe`/`it`; min 10 tests for basic lifecycle |

### Modified files

| File | Change |
|---|---|
| `src/lua_api/mod.rs` | Add `blocksim_api::register(...)` call gated on `config.modules.blocksim` |
| `src/engine/config.rs` | Add `blocksim: bool = false` to the `Modules` struct |
| `src/engine/app.rs` | Pass config flag to `create_lua_vm` (already done for other modules; follow existing pattern) |
| `tests/lua/harness.rs` | Add `#[test] fn lua_test_unit_blocksim()` entry |
| `Cargo.toml` | No change needed if `lua_tests` harness already covers `tests/lua/` |

### Bridge implementation rules

Follow `src/lua_api/timer_api.rs` as the gold standard:
- Flat body: `let s = state.clone(); tbl.set(...)` — never wrapped in `{ }` blocks.
- `/// @param` and `/// @return` doc annotations only — no `# Parameters` / `# Returns` sections.
- `SimRuntime` stored as `mlua::UserData` (follow `src/lua_api/physics_api.rs` pattern for `UserData` implementation).

### Key functions to implement this phase

- `lurek.sim.create(spec_table)` → SimHandle userdata
- `lurek.sim.destroy(sim)`
- `lurek.sim.step(sim, n)` → stats table
- `lurek.sim.run(sim)` → stats table
- `lurek.sim.reset(sim)`
- `lurek.sim.snapshot(sim)` → table
- `lurek.sim.tick(sim)` → int
- `lurek.sim.validate_spec(spec_table)` → ok, err_table
- `lurek.sim.load_toml(str)` → SimHandle, err

### Commit

```
feat(blocksim): Phase 2 — Lua bridge + basic lurek.sim API
```

---

## Phase 3 — Monitor and Event Log

**Responsible agent:** Developer

### New files

| File | What to implement |
|---|---|
| `src/blocksim/monitor.rs` | `MonitorEngine`, `MonitorSpec`, `MonitorProbe`, `MonitorSample`, ring buffer, 21 probe types, alert evaluation |
| `src/blocksim/event_log.rs` | `EventLog`, `SimEvent` enum, bounded `VecDeque<SimEvent>` buffer |

### Modified files

| File | Change |
|---|---|
| `src/blocksim/tick.rs` | Add phase 8 (monitor_sample) call after block_exec |
| `src/blocksim/runtime.rs` | Add MonitorEngine and EventLog fields |
| `src/blocksim/spec.rs` | Add `monitors: Vec<MonitorSpec>` to `SimSpec` |
| `src/lua_api/blocksim_api.rs` | Add `drain_monitors`, `peek_monitors`, `drain_events` functions |
| `tests/lua/unit/test_blocksim.lua` | Add monitor tests (10+ new assertions) |
| `tests/rust/unit/blocksim_tests.rs` | Add monitor unit tests |

### Notes

- Ring buffer max-samples: configurable via `SimConfig.monitor_buffer_size`; default `10_000`.
- `drain_monitors()` clears the ring buffer; `peek_monitors()` does not.
- Build `SampleValue` enum (`Count(u64)`, `Rate(f64)`, `State(String)`, `Pair(f64, f64)`) before attempting each monitor type.

### Commit

```
feat(blocksim): Phase 3 — monitor engine + event log + drain API
```

---

## Phase 4 — Anomaly Engine

**Responsible agent:** Developer

### New files

| File | What to implement |
|---|---|
| `src/blocksim/anomaly.rs` | `AnomalyEngine`, `AnomalySpec`, `AnomalyState` (enum), `AnomalyEffect` (enum 8 variants), trigger evaluation, cascade |

### Modified files

| File | Change |
|---|---|
| `src/blocksim/tick.rs` | Add phase 2 (anomaly_eval) |
| `src/blocksim/runtime.rs` | Add `AnomalyEngine` field |
| `src/blocksim/spec.rs` | Add `anomalies: Vec<AnomalySpec>` |
| `src/lua_api/blocksim_api.rs` | Add `inject_anomaly`, `expire_anomaly`, `anomaly_status` |
| `tests/rust/unit/blocksim_tests.rs` | Add `SimTestBuilder` helper; anomaly tests |
| `tests/lua/unit/test_blocksim.lua` | Add anomaly section |

### `SimTestBuilder` pattern

```rust
let mut rt = SimTestBuilder::new()
    .source("src", 2)
    .transform("t1")
    .sink("snk")
    .connect("src.out", "t1.in")
    .connect("t1.out", "snk.in")
    .anomaly("jam", block_state_pause("t1"), after_tick(50), after_ticks(20))
    .build();
rt.step(70);
assert!(rt.events().iter().any(|e| e.kind == "ANOMALY_ACTIVATED"));
```

### Commit

```
feat(blocksim): Phase 4 — anomaly engine + force-inject API
```

---

## Phase 5 — Operational Mechanics

**Responsible agent:** Developer

### New files

| File | Implements |
|---|---|
| `src/blocksim/approval.rs` | `ApprovalQueue`, `ApprovalRequest`, hold logic, timeout tracking |
| `src/blocksim/dlq.rs` | `DeadLetterQueue`, `DlqEntry`, `DlqReason`, bounded insert |
| `src/blocksim/replay.rs` | `ReplayEngine`, checkpoint save/restore, determinism invariant |
| `src/blocksim/circuit_breaker.rs` | `CircuitBreakerState` machine: CLOSED/OPEN/HALF_OPEN transitions |

### Modified files

| File | Change |
|---|---|
| `src/blocksim/tick.rs` | Add phase 3 (circuit_check) |
| `src/blocksim/runtime.rs` | Add ApprovalQueue, DLQ, CircuitBreakers, ReplayEngine |
| `src/lua_api/blocksim_api.rs` | Add all approval, DLQ, checkpoint, replay API functions |
| `tests/rust/unit/blocksim_tests.rs` | Circuit breaker state transitions; DLQ capture; approval hold; checkpoint determinism |

### Determinism test pattern

```rust
let ckpt = rt.save_checkpoint();
rt.step(100);
let snap_a = rt.snapshot();

rt.restore_checkpoint(&ckpt).unwrap();
rt.step(100);
let snap_b = rt.snapshot();

assert_eq!(snap_a.items_sinked, snap_b.items_sinked);
assert_eq!(snap_a.monitor_samples, snap_b.monitor_samples);
```

### Commit

```
feat(blocksim): Phase 5 — approval, DLQ, circuit breaker, checkpoint
```

---

## Phase 6 — Composite Support

**Responsible agent:** Developer

### New files

| File | Implements |
|---|---|
| `src/blocksim/composite.rs` | Composite flattening, scope boundary port mapping, nested id resolution |
| `library/blocksim/composite.lua` | Lua helpers: `blocksim.composite(...)`, port wiring utilities |

### Modified files

| File | Change |
|---|---|
| `src/blocksim/compiler.rs` | Pre-pass to flatten composites before topological sort |
| `src/blocksim/spec.rs` | Add `CompositeBlockSpec`, `CompositeScope`, `BoundaryPortSpec` |
| `tests/rust/unit/blocksim_tests.rs` | Single-level, two-level, three-level composite tests |
| `tests/rust/golden/` | New golden snapshot test for a 3-level composite factory scenario |

### Flattening algorithm outline

1. Walk all blocks. For each `CompositeIn` / `CompositeOut` pair, collect the inner scope.
2. Reparent all inner block ids to `<composite_id>/<inner_id>`.
3. Remap edges that cross composite boundaries to the outer port ids.
4. Repeat for nested composites (depth-first).
5. After flattening, the plan contains no Composite markers — only primitive block types.
6. Detect id collision after reparenting; return `SimError::ValidationError` if collision found.

### Commit

```
feat(blocksim): Phase 6 — composite flattening + Lua composite helpers
```

---

## Phase 7 — Advanced Mechanics

**Responsible agent:** Developer

### New files

| File | Implements |
|---|---|
| `src/blocksim/script.rs` | `ScriptSpec` resolution to `ScriptTable` enum; per-block param evaluation |
| `src/blocksim/clock.rs` | `SimClock`: tick counter, calendar events, fast-forward acceleration |

### Modified files

| File | Change |
|---|---|
| `src/blocksim/tick.rs` | Add phase 1 full impl (calendar events); phase 4 (rate_limit) full impl |
| `src/blocksim/model.rs` | `Mechanic` enum — all variants with their inner config types |
| `src/blocksim/tick.rs` | Apply `Mechanic` stack in `block_exec` phase |
| `tests/rust/unit/blocksim_tests.rs` | One isolation test per mechanic variant |

### Commit

```
feat(blocksim): Phase 7 — advanced mechanics (batch, time window, warmup, energy, rate limit)
```

---

## Phase 8 — Lua Helper Library

**Responsible agent:** Developer + Lua-Designer (API review)

### New files

| File | Implements |
|---|---|
| `library/blocksim/init.lua` | Entry point; `require("library.blocksim")` exports all sub-modules |
| `library/blocksim/graph.lua` | Declarative chain/branch/dag builders for blocks and edges |
| `library/blocksim/blueprints.lua` | saga, canary, bulkhead, watchdog, approval_flow, dlq_recovery patterns |
| `library/blocksim/scenario.lua` | `scenario.load(path)`, `scenario.run_pair(base, variant)`, `scenario.multi_run(fn, n)` |
| `library/blocksim/analytics.lua` | `analytics.compare(base, variant)`, `analytics.kpi(samples, rules)`, detection helpers |
| `library/blocksim/reports.lua` | `reports.text(result)`, `reports.json(result)`, file export via `lurek.fs` |
| `tests/lua/library/test_blocksim_lib.lua` | BDD tests for all library helpers |

### Modified files

| File | Change |
|---|---|
| `tests/lua/harness.rs` | Add `#[test] fn lua_test_library_blocksim_lib()` |
| `library/README.md` | Add `blocksim` to module list |

### Commit

```
feat(library/blocksim): Phase 8 — Lua helper library: DSL, blueprints, analytics
```

---

## Phase 9 — Integration and Examples

**Responsible agent:** Developer + Tester

### New files

| File | What it demonstrates |
|---|---|
| `examples/blocksim.lua` | Minimal single-file walkthrough: create, run, monitor, report |
| `tests/lua/integration/test_blocksim_dataframe.lua` | Create sim → run → drain monitors → load into dataframe → compute KPIs |
| `demos/block_sim_demo/main.lua` | Optional: text-mode dashboard using `lurek.terminal` |
| `demos/block_sim_demo/conf.lua` | Optional demo config |

### Modified files

| File | Change |
|---|---|
| `tests/lua/harness.rs` | Add integration test entry |
| `demos/README.md` | Add entry if demo created |

### Commit

```
feat(blocksim): Phase 9 — integration tests, example, optional demo
```

---

## Phase 10 — Performance, Docs, Polish

**Responsible agent:** Optimizer (benchmark) → Developer (fix) → Doc-Writer (docs)

### Tasks

| # | Task | File |
|---|---|---|
| 10.1 | Run benchmark: 50-block flat graph, 10k ticks, measure ns/tick | `work/blocksim-impl/reports/phase10_benchmark.md` |
| 10.2 | If below target: profile hot path using RUST_LOG trace + timing spans | patch tick.rs |
| 10.3 | Create `src/blocksim/AGENT.md` | `src/blocksim/AGENT.md` |
| 10.4 | Create `specs/blocksim.md` | `specs/blocksim.md` |
| 10.5 | `python tools/docs/collect_docs.py --report-missing` — fix all missing `///` | various `.rs` files |
| 10.6 | `python tools/gen_all_docs.py` — regenerate lua-api.md | `docs/API/lua-api.md` |
| 10.7 | `docs/CHANGELOG.md` entry for the new module | `docs/CHANGELOG.md` |
| 10.8 | Cargo.toml version bump (MINOR — new feature) | `Cargo.toml` |
| 10.9 | Full quality gate: `cargo test && cargo clippy -- -D warnings` | CI |

### Commit sequence

```
docs(blocksim): AGENT.md + specs/blocksim.md
docs: regenerate lua-api.md
chore: bump version x.y+1.0, update CHANGELOG
```

---

## Cross-Cutting Constraints (All Phases)

| Constraint | How to enforce |
|---|---|
| No `println!` in engine code | Lint rule; use `log::debug!` / `log::info!` |
| No GPU/audio imports in `src/blocksim/` | Reviewer check; add a `clippy.toml` deny entry for wgpu imports inside this path |
| Per-frame rule: no heap alloc in hot tick | Grow queues at compile time; use pre-allocated `Vec` capacities from `SimSpec` |
| Float comparisons in tests | `assert!((a - b).abs() < 1e-5)` — never `assert_eq!` on floats |
| No test_ prefix on Rust test names | `items_flow_through_gate_correctly`, not `test_gate_flow` |
| Every pub Rust item gets `///` | Enforced by `collect_docs.py --report-missing` in Phase 10 |
| Lua API files: only `@param` / `@return` annotations | No `# Parameters` / `# Returns` sections in blocksim_api.rs |

---

## Agent Assignments Summary

| Phase | Primary agent | Review agent |
|---|---|---|
| 0 | Research | Manager |
| 1 | Developer | Reviewer + Tester |
| 2 | Developer | Lua-Designer + Tester |
| 3 | Developer | Tester |
| 4 | Developer | Tester |
| 5 | Developer | Reviewer + Tester |
| 6 | Developer | Reviewer |
| 7 | Developer | Reviewer |
| 8 | Developer | Lua-Designer + Tester |
| 9 | Developer | Tester |
| 10 | Optimizer → Developer | Doc-Writer + Reviewer |
