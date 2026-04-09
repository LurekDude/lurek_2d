# Risks and Assumptions

> See also: [FEASIBILITY-STUDY.md](FEASIBILITY-STUDY.md) · [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 1. Design Assumptions

These statements must be true for the architecture described in the other files to hold. If any assumption is invalidated, the corresponding component may need a design revision.

| # | Assumption | Why it matters | How to verify |
|---|---|---|---|
| A-01 | Lurek2D's tier DAG rules remain stable (Tier 2 cannot import other Tier 2) | If relaxed, `src/blocksim` could import `src/graph` and `src/dataframe` directly, changing the architecture significantly | Read `docs/architecture/philosophy.md` before starting implementation |
| A-02 | `src/data` exposes TOML parse/encode as public Rust types (not only through the Lua API) | The Rust kernel needs to call TOML conversion internally without going through Lua | Check `specs/data.md` and `src/data/mod.rs` for public Rust-level TOML API |
| A-03 | `lurek.thread` channel can transport enough data for monitor batch export | Worker threads need to receive monitor samples for background export | Confirm `src/thread/channel.rs` supports table/array serialization or at least JSON strings |
| A-04 | `lurek.dataframe` can handle the scale of monitor logs expected (1M+ samples for long runs) | If the dataframe hits memory limits, a file-export path is needed for analytics | Benchmark `lurek.dataframe` with 500k rows before committing to in-memory analytics |
| A-05 | A headless `SimRuntime` can be tested by `cargo test` without linking GPU/audio subsystems | If blocksim accidentally gets a transitive dep on wgpu or rodio, the test build becomes complex | Check `Cargo.toml` feature flags and confirm `src/data` and `src/compute` are truly headless |
| A-06 | The Lua bridge can hold `SimRuntime` as a `UserData` object in the Lua registry | Lurek2D already does this for physics worlds, graph nodes, etc. | Confirm pattern in `src/lua_api/physics_api.rs` or `src/lua_api/graph_api.rs` |
| A-07 | YAML-authored content from the source project can be faithfully converted to TOML without information loss | If the source has YAML features with no TOML equivalent (typed strings, multi-line blocks with anchors, merge keys), migration will require schema redesign | Audit a representative set of source YAML files before committing to TOML-first authoring |
| A-08 | The domain examples in `DOMAIN-BLUEPRINTS.md` can be expressed with left-to-right flow semantics only | If some blueprints require bidirectional flow or cycles, the kernel's DAG assumption breaks | Review the saga and compensation flow examples; identify any backward edges |
| A-09 | Approval workflows can model human-in-the-loop processes synchronously from Lua (poll-then-step) | If a use case requires interrupting a long run mid-tick to get approval, the synchronous step API may need iteration | Survey the approval examples to determine if polling is sufficient |
| A-10 | The simulation is intended to be single-instance-per-`SimRuntime` | If multiple simultaneous simulations sharing global state are required, the resource ledger and anomaly engine must be redesigned | Check whether the source project supports multiple concurrent runs with shared resources |

---

## 2. Technical Risks

### R-01 — Tier composition is tighter than expected

**Risk:** Partway through implementation, a necessary algorithm in `src/blocksim` requires functionality from `src/graph` (e.g., topological sort, cycle detection) or `src/dataframe` (e.g., in-tick aggregation), both of which are Tier 2 and cannot be imported.

**Likelihood:** Medium

**Impact:** Medium — Would require either duplicating the algorithm locally in `src/blocksim` or promoting the logic to Tier 1 as a `math` utility.

**Mitigation:** Identify all required algorithms at compiler/spec-design time (Phase 1). Add topological sort and DAG cycle detection to `src/math/` if not already present. Keep any needed aggregation as local rolling-window counters in `monitor.rs` rather than external queries.

---

### R-02 — Per-tick Lua overhead bleeds in

**Risk:** A planned feature requires a Lua callback on every tick (e.g., a "custom monitor" probe that calls a user-supplied Lua function). This breaks the no-Lua-in-tick-loop design constraint and creates serious performance risk for long runs.

**Likelihood:** Medium-High (users will ask for it)

**Impact:** High — Could undermine the performance rationale for putting the kernel in Rust at all.

**Mitigation:** Custom monitor probes in V1 must be registered at compile time as one of a finite set of typed probe selectors, not arbitrary Lua closures. If truly arbitrary callbacks are needed, defer to V2 and design a batched-callback interface: Rust accumulates a query result set per N ticks, Lua processes the batch between step calls.

---

### R-03 — Monitor buffer overflow for very long runs

**Risk:** A run of 100k+ ticks with 20+ monitors generates more samples than the in-memory `Vec<MonitorSample>` can hold efficiently.

**Likelihood:** Medium (simulation users often run long scenarios)

**Impact:** Medium — Memory pressure; possible OOM in extreme cases.

**Mitigation:** Design the monitor buffer as a configurable ring buffer from day one. Default cap: 10k samples. Offer a `lurek.sim.export_monitors(sim, path)` flush-to-JSONL API so Lua can periodically drain samples to disk during a long run without waiting until the end.

---

### R-04 — YAML migration is non-trivial for complex graphs

**Risk:** The source project has large nested YAML graphs with YAML anchors, merge keys, and complex composite structures. Converting these algorithmically to TOML + Lua is not a one-liner translation.

**Likelihood:** High (YAML anchors and merge keys are commonly used in the source)

**Impact:** Medium — Migration tooling is needed; pure hand-porting of many scenario files is slow.

**Mitigation:** Write a migration utility (Python or Lua) that expands YAML anchors and flattens merge keys before outputting TOML equivalents. The complex wiring becomes Lua code with iteration patterns rather than nested YAML structures. Treat migration as a dedicated Phase 0 spike before committing to the authoring model.

---

### R-05 — DLQ replay is not deterministic

**Risk:** DLQ replay re-injects items that were rejected for non-deterministic reasons (resource contention, timing). Replayed items interleave with in-flight items in unpredictable ways, breaking checkpoint-based determinism.

**Likelihood:** Medium

**Impact:** Medium — Determinism guarantee is a hard design goal.

**Mitigation:** Replay always targets a specific input queue at a specific position (FIFO head or FIFO tail, configurable). Document that DLQ replay breaks the determinism invariant and is therefore a manual operator action, not an automatic recovery. Checkpoints taken after a DLQ replay can themselves be replayed deterministically forward from that point.

---

### R-06 — Composite flattening is complex for deeply nested structures

**Risk:** Domain blueprints use three or four levels of composite nesting. The flattening algorithm in `compiler.rs` needs to handle scope-local port id collisions, value edge rollup through multiple composite levels, and anomaly targeting of inner blocks by their scoped ids.

**Likelihood:** High (the blueprints file shows 3-level nesting)

**Impact:** High — Compiler correctness failures would produce silently wrong simulation results.

**Mitigation:** Build the compiler test suite first and in isolation. Start with flat graphs (0 composites), then single-level composites, then two-level, then three-level. Use golden snapshot tests in `tests/rust/golden/` where the output is a deterministic run trace. Do not integrate composites until the flat kernel is green.

---

### R-07 — Approval workflow requires a non-blocking wait model

**Risk:** If approval is required mid-tick, the entire simulation blocks waiting for Lua to call `lurek.sim.approve()`. For long step counts (`lurek.sim.run()`), this means the simulation stops invisibly until Lua polls.

**Likelihood:** High

**Impact:** Medium — Not a correctness issue, but significantly complicates user experience.

**Mitigation:** Design the pending approval as a tick-level hold. When `lurek.sim.step(n)` encounters a pending approval, it stops that block and continues running other blocks. The step returns a `stats` table with `approvals_pending > 0`. The Lua script can then call `lurek.sim.pending_approvals()` and resolve before calling `lurek.sim.step()` again. This is the poll-step pattern. Document it prominently.

---

### R-08 — Backend reuse outside Lurek2D is harder than expected

**Risk:** `src/blocksim` compiles fine as a library, but it has transitive dependencies on `src/engine`'s `EngineError` type and config struct, which embed Lurek2D-specific assumptions. A caller outside Lurek2D would need to stub those types.

**Likelihood:** Medium

**Impact:** Low for V1 (the user wants it inside Lurek2D for now), but a future concern if the backend is later extracted as a standalone crate.

**Mitigation:** Keep `src/engine` dependency in `blocksim` minimal. Only use `EngineError` at the boundary in the Lua bridge (`blocksim_api.rs`), not inside the kernel itself. The kernel should use its own `SimError` type and only convert to `EngineError` at the bridge layer. This makes future extraction cleaner.

---

### R-09 — Test coverage for the anomaly system is hard to write

**Risk:** Anomaly trigger conditions depend on tick state, which changes per step. Writing deterministic tests for "anomaly activates at tick 300, causes cascade at tick 305" requires carefully constructed deterministic scenarios and is time-consuming.

**Likelihood:** High

**Impact:** Medium — Undertested anomaly code means silent failures in production scenarios.

**Mitigation:** Build a `SimTestBuilder` helper in the Rust test utilities that lets tests construct minimal specs, inject anomalies, step to a specific tick, and assert on events/state in a few lines. The pattern already exists in Lurek2D's `tests/rust/unit/` files. Make the anomaly test suite a first-class citizen, not an afterthought.

---

### R-10 — Performance at scale is unknown

**Risk:** A complex manufacturing scenario with 200 blocks, 400 edges, 20 monitors, and 5 anomalies may run significantly slower than 1k ticks/second, making long simulation runs impractical from Lua.

**Likelihood:** Unknown — no benchmark baseline yet.

**Impact:** High for the use case of running many scenario variants in comparison mode.

**Mitigation:** After Phase 2 (basic flat kernel), run a micro-benchmark before implementing the full mechanic stack. Define a performance target: at minimum, 10k ticks/second for a 50-block flat graph on a mid-range CPU. If the baseline misses the target by more than 5×, profile before adding more mechanics.

---

## 3. Non-Technical Risks

### R-11 — Scope expansion pulls in the dashboard layer too early

If a reviewer or maintainer adds `lurek.gui` references into the `src/blocksim` kernel (e.g., "just for a debug panel"), the headless guarantee breaks immediately.

**Mitigation:** The `mod.rs` doc for `src/blocksim` must explicitly state "NO graphics, audio, or UI imports in this module." Add a CI lint or at minimum a clippy.toml deny rule for wgpu imports inside `src/blocksim/`.

---

### R-12 — Analytics scope creep: DuckDB envy

The source project's analytics layer uses DuckDB for cross-run queries. There may be pressure to bring DuckDB or an equivalent SQL engine into Lurek2D rather than using `lurek.dataframe`.

**Mitigation:** `lurek.dataframe` is sufficient for V1 analytics. If it proves insufficient at scale, the correct path is improving `lurek.dataframe`, not adding a new dependency. DuckDB would be an external tool, not part of the engine.
