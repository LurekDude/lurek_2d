# Feasibility Study — Block Simulation Library for Lurek2D

> **Date:** 2026-04-08
> **Authored by:** Manager + Solver + Architect agents
> **Source:** Analysis of nine `block-sim-flask` documentation files
> **Session artifacts:** `work/block-sim-feasibility/`

---

## 1. Executive Summary

**Verdict: Conditionally feasible.**

The block-sim platform can be implemented as a reusable library inside Lurek2D, but the correct shape is a new self-contained Rust simulation kernel (`src/blocksim/`) with a thin Lua bridge and an optional Lua helper library (`library/blocksim/`). A pure Lua-only port is too slow and not backend-neutral. A direct Python/Flask translation would import the wrong architecture entirely.

The conditions are:

1. The Rust kernel must be authored as a standalone module — it cannot inline-import other Tier 2 modules like `src/graph` or `src/dataframe`.
2. The per-tick loop must stay in Rust. The Lua bridge calls in and out of it; Lua must never be called on every item movement.
3. Post-run analytics must stay outside the tick loop. Lua plus `lurek.dataframe` is the right post-run layer.
4. Visualization and dashboards must remain separate consumers, not embedded in the simulation kernel.
5. Human-authored config must migrate from YAML to TOML for static data and Lua for behavioral graph assembly.

---

## 2. Source System Analysis

### 2.1 What the source project is

The source project is a **declarative graph-based process-flow simulator**. A graph of typed blocks is loaded, compiled, and then stepped tick by tick. Items (typed tokens of work) flow left to right through the blocks. Each block applies a mechanic — transform, gate, route, split, compose, record, accumulate — and dequeues or enqueues items based on capacity, filter rules, and resource availability.

The design is not game logic. It is a general simulation platform for process modelling: manufacturing lines, healthcare workflows, financial pipelines, logistics networks, software delivery chains, approval flows, or any domain that can be expressed as a directed acyclic or compositional graph of typed work stages.

### 2.2 Layers of the system

The source docs describe four distinct layers:

| Layer | Responsibility | Reusability requirement |
|---|---|---|
| **Simulation kernel** | Deterministic tick loop, typed blocks, queues, flow, composites, anomalies, monitor stream | Must be headless, reusable, swap-backend-friendly |
| **Operational controls** | Approval workflows, DLQ/replay, speed control, circuit breakers, maintenance, energy | Part of kernel API surface |
| **Monitoring and analytics** | End-of-tick sampling, KPI comparison, detection, reports | Separate from tick loop; reads only committed state |
| **Visualization** | Graph layout, animation, dashboard, drill-in | Pure consumer of exported data |

### 2.3 Authoring model

The source project uses YAML as its human-readable authoring format. When porting:

- **TOML** replaces YAML for static authored data: block catalogs, resource tables, schedule templates, anomaly profiles, threshold configs, maintenance windows.
- **Lua** replaces Python orchestration: graph assembly DSL, composite wiring, scenario selection, multi-run loops, post-run analysis.
- **YAML is not used in Lurek2D at all.** The migration is total, not partial.

### 2.4 Backend surface

The source project exposes a Flask REST API for start, stop, state inspection, repair, DLQ drain, approval resolution, and speed control. The Lurek2D equivalent exposes `lurek.sim.*`: a synchronous Lua API that wraps the Rust kernel for all the same operations. A separate web/external wrapper can sit above the Lua API if REST is still needed for a particular deployment.

---

## 3. Lurek2D Capability Evidence

### 3.1 What Lurek2D already has that helps

| Capability | Lurek2D source | Benefit |
|---|---|---|
| TOML parse/encode | `lurek.data.parseToml`, `lurek.data.encodeToml` | Direct config import; no external parser needed |
| Graph flow simulation | `src/graph/`, `lurek.graph.*` | Conceptual reference for flow, queue, capacity patterns |
| Dense arrays | `src/compute/`, `lurek.compute.*` | Substrate for numeric value fields in block state |
| Tabular analytics | `src/dataframe/`, `lurek.dataframe.*` | Post-run KPI, aggregation, comparison, CSV/JSON export |
| Background workers | `src/thread/`, `lurek.thread.*` | Off-main-thread bulk runs and monitor export |
| Charts and widgets | `src/gui/`, `lurek.ui.*` | In-engine monitoring dashboard surface |
| Character cell UI | `src/terminal/`, `lurek.terminal.*` | Text-mode inspector and debug REPL |
| Headless test VM | `tests/lua/harness.rs` | Full test coverage without GPU, window, or audio |
| Config gate on module | `src/engine/config.rs` | `modules.blocksim = true/false` flag same as other Tier 2 modules |

### 3.2 What Lurek2D's tier rules require

| Rule | Implication |
|---|---|
| Tier 1 imports Baseline only | If kernel needs `data` or `thread`, it must be Tier 2, not Tier 1 |
| Tier 2 imports Baseline + Tier 1 | Kernel can use `data`, `compute`, `thread` — all Tier 1 |
| No same-tier cross-imports | Kernel cannot call `src/graph`, `src/dataframe`, or `src/gui` from Rust |
| `lua_api` is the bridge layer | Peer composition across Tier 2 modules happens by calling `lurek.graph`, `lurek.dataframe`, `lurek.ui` from Lua |
| `library/` is pure Lua | A Lua helper library can compose across the full public `lurek.*` surface |

---

## 4. Alternatives Evaluated

### 4.1 Alternative A — Pure Tier 3 Lua library only

Build everything in `library/blocksim.lua` on top of `lurek.graph`, `lurek.thread`, `lurek.data`, and `lurek.dataframe`.

| | |
|---|---|
| **Pros** | Fastest to prototype; matches Lunasome pattern; composable across full public API |
| **Cons** | Per-tick Lua overhead is unacceptable for deep stateful mechanic stacks; determinism is hard to guarantee through Lua callbacks; cannot expose a stable backend API without re-implementing the kernel later |
| **Verdict** | **Ruled out for the production path.** Acceptable for a prototype spike only. |

### 4.2 Alternative B — Extend the existing `src/graph` module

Fold new simulation mechanics into `src/graph/` as additional node types, port schemas, and phase handlers.

| | |
|---|---|
| **Pros** | Reuses existing flow engine; fewer new files; existing Lua API already partially exposes what's needed |
| **Cons** | `src/graph` is Tier 2; it cannot be imported by another Tier 2 module later; extending it risks violating its single-responsibility contract; typed port schemas, composites, approvals, anomalies, and monitors are all out of scope for a graph utility module |
| **Verdict** | **Ruled out.** The blast radius to `src/graph` would be large and the resulting module would be incoherent. Use it as a conceptual reference, not as base code. |

### 4.3 Alternative C — New Tier 2 Rust module (recommended)

Create `src/blocksim/` as a self-contained Tier 2 module. It imports Tier 1 (`data`, `compute`, `thread`) for building blocks but owns its own simulation kernel entirely.

| | |
|---|---|
| **Pros** | Correct tier placement; can use `data`, `compute`, `thread`; headless testable; reusable by other frontends through the `lurek.sim.*` API; Lua library can compose across it and all other Tier 2 APIs at once |
| **Cons** | Largest upfront implementation effort; cannot directly reuse `src/graph`'s existing flow logic at runtime (only conceptual reference); a separate Lua analytics layer is needed for cross-run KPIs |
| **Verdict** | **Recommended.** |

### 4.4 Alternative D — Standalone external Rust crate

Build the simulation kernel as a separate Rust crate outside Lurek2D's `src/` tree and link it as a Cargo dependency.

| | |
|---|---|
| **Pros** | Maximum backend neutrality; easier to publish independently |
| **Cons** | Requires publishing or workspace-linking; integration with `lurek.*` API becomes a secondary layer; not the natural home for a "Lurek2D library" — the user wants it inside the engine |
| **Verdict** | **Keep in mind for long-term extraction if the module proves valuable, but start inside `src/`.** |

---

## 5. Feasibility Conditions — What Must Be True

For the implementation to succeed:

1. **Kernel owned by Rust.** The deterministic tick loop, queue management, composite expansion, anomaly application, resource locks, and monitor sampling are all Rust-only.
2. **Lua stays orchestration.** Lua assembles the initial spec, drives scenario selection, controls operational inputs (approvals, anomaly injection, speed), reads snapshots, and coordinates post-run analytics.
3. **TOML for static data.** Block definitions and catalogs, thresholds, schedules, presets, and anomaly profiles live in TOML files loaded by `lurek.data.parseToml` and passed into `lurek.sim.create(spec)`.
4. **Monitor stream is export-only.** The monitor system writes samples at end-of-tick into a buffer that Lua can drain after each step or batch. It never calls into Lua during the tick.
5. **Analytics are post-run.** KPI computation, comparison across runs, detection correlation, and reporting are done after the run using `lurek.dataframe` or an external consumer tool. Nothing analytical runs inside the tick loop.
6. **Headless core.** The Rust kernel has zero dependency on graphics, audio, window, or OS-native GPU features. It must be fully testable by `cargo test --test blocksim_tests` without a display.
7. **Feature flag gated.** The module is behind `modules.blocksim = true` in the engine config just like all other optional Tier 2 subsystems.

---

## 6. Non-Requirements

The following are explicitly out of scope for this library:

- A built-in web server or REST API endpoint (an external wrapper can add that above `lurek.sim`)
- A graph layout engine (visualization is a separate UI layer)
- A DuckDB or SQL driver (use `lurek.dataframe` for in-engine analytics)
- Real-time network-distributed simulation
- YAML parsing (YAML is not part of Lurek2D's design — migrate to TOML/Lua)
- WASM or browser runtime (Lurek2D is desktop-only per constraint A-02)
- Any Python interop

---

## 7. Confidence Assessment

| Question | Confidence |
|---|---|
| Can a deterministic block sim kernel live in Rust at Tier 2? | High — matches existing Tier 2 module pattern exactly |
| Can TOML and Lua replace YAML for authored graphs? | High — `lurek.data.parseToml` exists; Lua DSL is well-suited for wiring composites |
| Can `lurek.dataframe` replace DuckDB for post-run analytics? | Medium — it can do grouping, joins, stats, export; may hit limits for very large monitor logs |
| Can the monitor stream stay outside the hot tick loop? | High — the pattern (end-of-tick callback into a side buffer) is standard |
| Can nested composites be flattened to a deterministic execution order? | Medium-High — the algorithm is known; impl is non-trivial but well-scoped |
| Can approval workflows and DLQ/replay be modelled without service-layer assumptions? | Medium — requires some design work on the Lurek2D-specific interop model |
| Can the library be truly backend-neutral for other frontends? | High **if** the kernel has no `SharedState` or wgpu coupling, which the tier rules encourage |
