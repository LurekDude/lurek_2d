# Architecture — Block Simulation Library

> See also: [FEASIBILITY-STUDY.md](FEASIBILITY-STUDY.md) · [RUST-MODULE-DESIGN.md](RUST-MODULE-DESIGN.md) · [LUA-API-DESIGN.md](LUA-API-DESIGN.md)

---

## 1. Layer Overview

The simulation library occupies four distinct layers inside the Lurek2D stack. Each layer has a strict ownership boundary and a clear direction of dependency.

```
┌─────────────────────────────────────────────────────┐
│  External frontend / wrapper                         │
│  (web dashboard, REST adapter, third-party tool)     │
│  No engine dependency; consumes exported data only   │
└────────────────────┬────────────────────────────────┘
                     │ file export / JSON / CSV
┌────────────────────▼────────────────────────────────┐
│  Tier 3 — library/blocksim/                          │
│  Pure Lua. Reusable scenario DSL, blueprint loader,  │
│  multi-run orchestration, monitor/report helpers,    │
│  optional ui glue (lurek.ui, lurek.terminal).          │
│  Composes across all public lurek.* APIs.             │
└────────────────────┬────────────────────────────────┘
                     │ calls lurek.sim.*
┌────────────────────▼────────────────────────────────┐
│  Bridge — src/lua_api/blocksim_api.rs                │
│  Thin. Exposes lurek.sim.create / step / run /        │
│  inject / approve / snapshot / drain_monitors.       │
│  All calls are synchronous from Lua's perspective.   │
└────────────────────┬────────────────────────────────┘
                     │ Rust function calls
┌────────────────────▼────────────────────────────────┐
│  Tier 2 — src/blocksim/                              │
│  Rust simulation kernel.                             │
│  Owns the tick loop, block registry, queue state,    │
│  composite flattening, typed port schema,            │
│  resource ledger, anomaly engine, monitor stream,    │
│  approval queue, DLQ, replay, checkpoint.            │
│  No GPU, no audio, no UI, completely headless.       │
│  Depends on: src/engine (errors, config),            │
│              src/data  (TOML → Rust types),          │
│              src/compute (dense value arrays).       │
└─────────────────────────────────────────────────────┘
```

---

## 2. Lurek2D Tier Placement

| Component | Lurek2D location | Tier | Depends on |
|---|---|---|---|
| Simulation kernel | `src/blocksim/` | Tier 2 | Baseline + Tier 1 (`data`, `compute`) |
| Lua bridge | `src/lua_api/blocksim_api.rs` | Bridge | `src/blocksim/` + engine |
| Lua helper library | `library/blocksim/` | Tier 3 (Lunasome) | Public `lurek.*` only |
| Tests (Rust) | `tests/rust/unit/blocksim_tests.rs` | Test | `src/blocksim/` |
| Tests (Lua) | `tests/lua/unit/test_blocksim.lua` | Test | `lurek.sim.*` |
| Tests (library) | `tests/lua/library/test_blocksim_lib.lua` | Test | `library/blocksim/` |

### Why Tier 2 and not Tier 1

Tier 1 modules may only import from `math` and `engine`. The simulation kernel needs:
- `src/data` for TOML-to-struct conversion → `data` is Tier 1
- `src/compute` for dense numeric value arrays → `compute` is Tier 1

Both are Tier 1, so the kernel can use them. But because the kernel _also_ needs them as named imports at Rust compile time (not just at runtime through Lua), the kernel itself must live at Tier 2.

### Why not extending `src/graph`

The existing `src/graph` module is already Tier 2. Another Tier 2 module cannot depend on it. More importantly, `src/graph` models a general-purpose directed weighted graph with flow simulation. The block simulation needs typed port schemas, composite hierarchies, anomaly injection, approval queues, and dedicated monitor streams — none of which belong in a general graph module. Use `src/graph` only as a conceptual reference.

---

## 3. Internal Module Structure

```
src/blocksim/
├── mod.rs             — public API re-exports, module doc
├── spec.rs            — SimSpec: parsed, validated simulation descriptor
├── model.rs           — Block, Port, Edge, Composite, Filter, Container types
├── compiler.rs        — spec → ExecutionPlan (flattened, ordered, validated)
├── runtime.rs         — SimRuntime: owns all live simulation state
├── tick.rs            — per-tick execution pipeline (8 phases)
├── queue.rs           — typed item queues with capacity, backpressure
├── resource.rs        — resource ledger (named pools, locks, releases)
├── value.rs           — typed value flows (numeric, tagged, composite)
├── filter.rs          — gate, route, transform, param-inject filter types
├── script.rs          — per-block script table with step evaluation
├── composite.rs       — composite block flattening and boundary port mapping
├── anomaly.rs         — AnomalyEngine: inactive/active/expired lifecycle
├── monitor.rs         — MonitorEngine: end-of-tick sampling, alert evaluation
├── approval.rs        — approval request queue, resolution, timeout
├── dlq.rs             — dead-letter queue: capture, inspect, replay
├── replay.rs          — checkpoint save/restore, deterministic replay
├── clock.rs           — SimClock: tick counter, real-time calendar, fast-forward
├── circuit_breaker.rs — per-block circuit breaker state machine
├── event_log.rs       — structured simulation event stream (not monitor stream)
└── error.rs           — SimError variants
```

---

## 4. Dependency Rules

```
src/blocksim/* may import:
  ✅ src/math/*    (Vec2, Rect, Color — if port payloads need spatial types)
  ✅ src/engine/*  (EngineError, Config)
  ✅ src/data/*    (TOML conversion, binary encoding helpers)
  ✅ src/compute/* (NdArray for batch value operations)

src/blocksim/* must NOT import:
  ❌ src/graphics/*   (headless requirement)
  ❌ src/audio/*
  ❌ src/physics/*
  ❌ src/input/*
  ❌ src/gui/*
  ❌ src/terminal/*
  ❌ src/graph/*       (same-tier rule)
  ❌ src/dataframe/*   (same-tier rule)
  ❌ src/scene/*       (same-tier rule)
  ❌ src/lua_api/*     (bridge must not be imported by domain module)

src/lua_api/blocksim_api.rs may import:
  ✅ src/blocksim/*
  ✅ mlua types
  ✅ src/engine/* (SharedState etc.)
```

---

## 5. Responsibility Boundaries

### 5.1 Rust kernel owns

- Parsing and validating a `SimSpec` from a Lua table or TOML string
- Compiling the spec into an `ExecutionPlan` (composite flattening, topological ordering, port binding)
- All per-tick simulation: dequeue, filter evaluation, capacity checks, resource acquisition, block execution, value accumulation, circuit breaker state, backpressure, re-queue
- Anomaly lifecycle: trigger evaluation, effect application, expiry conditions, cascade, event logging
- Monitor collection at end-of-tick: snapshot sampled state into a `MonitorSample` buffer
- Alert threshold evaluation on monitor samples
- Approval request generation and hold-until-approved blocking
- DLQ capture and replay injection
- Checkpoint serialization and restore (deterministic replay)
- Clock and calendar handling, fast-forward acceleration, warmup phase

### 5.2 Lua bridge owns

- Converting Lua table spec → `SimSpec` struct
- Constructing, stepping, running, pausing, and destroying simulation instances
- Injecting anomalies and resolving approvals from Lua
- Draining the monitor sample buffer and returning Lua tables
- Accessing named block state snapshots from Lua
- Importing/exporting checkpoint data (as opaque Lua strings or file paths)

### 5.3 Lua helper library owns

- Ergonomic graph DSL (chain, branch, composite builders)
- TOML scenario file loading via `lurek.data.parseToml`
- Blueprint pattern implementations (saga, watchdog, canary, bulkhead)
- Multi-run orchestration (base + variant, parallel runs via `lurek.thread`)
- Monitor log export to files via `lurek.fs`
- Post-run report generation via `lurek.dataframe`
- Optional live dashboard via `lurek.ui` or `lurek.terminal`

### 5.4 Analytics (post-run, outside kernel)

- KPI computation over exported monitor logs
- Paired run comparison (baseline vs anomaly-enabled)
- Statistical significance against thresholds
- Detection correlation with anomaly activation windows
- Structured report export as JSON/CSV

This must not happen inside the tick loop. It runs after `lurek.sim.run()` completes and reads the final monitor stream buffer or a written JSONL/CSV file.

### 5.5 Visualization (separate consumer)

- Graph layout: DAG positioning, block shapes, port positions
- State rendering: queue fill animations, block state color, edge flow particles
- Anomaly and monitor overlays
- Composite drill-in UX
- Dashboard panel layout

This is always a separate concern. A Lurek2D frontend can use `lurek.gfx`, `lurek.ui`, or `lurek.scene`. An external frontend can consume exported JSON. Neither is part of the simulation kernel.

---

## 6. Cross-Module Data Flow at Runtime

```
                          ┌─────────────┐
TOML file ──parse──▶      │  SimSpec    │
Lua table ──build──▶      │  (model.rs) │
                          └──────┬──────┘
                                 │ compile()
                          ┌──────▼──────┐
                          │ Execution   │
                          │ Plan        │
                          │(compiler.rs)│
                          └──────┬──────┘
                                 │ run(plan) → SimRuntime
                          ┌──────▼──────────────────────────────────┐
                          │  SimRuntime (runtime.rs)                 │
                          │  ┌──────────┐ ┌─────────┐ ┌──────────┐  │
                          │  │ queue.rs │ │resource │ │anomaly   │  │
                          │  │ per-block│ │ledger   │ │engine    │  │
                          │  └──────────┘ └─────────┘ └──────────┘  │
                          │  ┌──────────┐ ┌─────────┐ ┌──────────┐  │
                          │  │ approval │ │dlq.rs   │ │clock.rs  │  │
                          │  │queue     │ │         │ │          │  │
                          │  └──────────┘ └─────────┘ └──────────┘  │
                          └──────┬────────────────────────────────────┘
                                 │ end of each tick
                          ┌──────▼──────┐      ┌──────────────────┐
                          │ monitor.rs  │─────▶│ MonitorSample    │
                          │ (read-only) │      │ buffer           │
                          └─────────────┘      └────────┬─────────┘
                                                        │
                                        drain after run or per-tick
                                                        │
                               ┌────────────────────────▼──────┐
                               │  Lua: lurek.sim.drain_monitors()│
                               │  → Lua table of samples        │
                               └──────────────┬─────────────────┘
                                              │
                                  ┌───────────▼─────────┐
                                  │ lurek.dataframe      │
                                  │ analytics + reports │
                                  └─────────────────────┘
```

---

## 7. Engine Config Integration

The module will be guarded by a `modules.blocksim` flag in `src/engine/config.rs`, consistent with how `modules.gui`, `modules.terminal`, `modules.graph`, etc. are handled.

```toml
# conf.toml
[modules]
blocksim = true   # enables lurek.sim.* namespace
gui      = true   # optional: enables dashboard surface
terminal = true   # optional: enables text mode inspector
```

The bridge only calls `register_blocksim_api(lua, luna, state)` when the flag is enabled. Tests must work with the flag off (checking for graceful nil) and on (full API).
