# Simulation Library — Idea Folder

> **Status:** Pre-implementation feasibility study
> **Date authored:** 2026-04-08
> **Source project analyzed:** `block-sim-flask` (Python/Flask/YAML declarative graph simulator)
> **Target:** Lurek2D reusable library `lurek.sim` backed by a Rust simulation kernel

---

## What This Idea Is

The goal is to port the core of a declarative, graph-based process-flow simulator into Lurek2D as an engine-level reusable library. Instead of Python + Flask + YAML, the target stack is:

| Old stack | New stack |
|---|---|
| Python engine loop | Rust simulation kernel (`src/blocksim/`) |
| YAML authored graphs | TOML authored data + Lua assembled graphs |
| Python-side anomaly injection | Rust anomaly system over typed engine state |
| Python monitor engine | Rust end-of-tick monitor stream |
| Flask REST API | `lurek.sim.*` Lua API (synchronous from script) |
| DuckDB analytics | `lurek.dataframe` post-run analytics in Lua |
| React dashboard | `lurek.gui` / `lurek.terminal` or external frontend |

The library is intended to be **reusable across projects**, not tightly coupled to one game. Any Lua frontend, wrapper, or external tool can sit above the Rust core.

---

## File Index

| File | What it covers |
|---|---|
| `README.md` | This file — overview and index |
| [FEASIBILITY-STUDY.md](FEASIBILITY-STUDY.md) | Full feasibility analysis with verdict, evidence, constraints, and trade-off comparison of alternatives |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Tier placement, module dependency graph, layer responsibility boundaries, and internal module split |
| [RUST-MODULE-DESIGN.md](RUST-MODULE-DESIGN.md) | Internal Rust kernel design: types, state machines, tick loop, registry, monitor stream |
| [LUA-API-DESIGN.md](LUA-API-DESIGN.md) | Full proposed `lurek.sim.*` API surface with function signatures and examples |
| [CONFIG-DECOMPOSITION.md](CONFIG-DECOMPOSITION.md) | How every configuration concern decomposes across TOML, Lua, and Rust defaults |
| [RISKS-AND-ASSUMPTIONS.md](RISKS-AND-ASSUMPTIONS.md) | All design assumptions, technical risks, blockers, and mitigation strategies |
| [ROADMAP.md](ROADMAP.md) | Phased implementation schedule with acceptance gates, dependencies, and effort estimates |
| [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md) | Concrete file-by-file work breakdown by phase, agent assignments, and test requirements |

---

## Core Idea in One Paragraph

A block simulation engine models a process graph where items flow left to right through typed blocks. Each block receives typed inputs, applies its mechanic (transform, gate, route, record, compose, etc.), and emits typed outputs. The graph is fully declarative: blocks, edges, port types, filters, containers, and operational mechanics are all authored as data rather than code. On top of the execution core sits a constrained anomaly system for failure simulation, a read-only monitor layer for observability, and a post-run analytics layer for KPI comparison across scenario variants. The implementation target swaps Python's runtime for a deterministic Rust kernel, swaps YAML for TOML/Lua authoring, and exposes the whole surface through a clean `lurek.sim.*` Lua API that can be driven from any Lurek2D context — full game, headless test, or embedded library backend.

---

## Quick Feasibility Call

**Verdict: Conditionally feasible.** See [FEASIBILITY-STUDY.md](FEASIBILITY-STUDY.md) for the full analysis. The shorthand:

- ✅ Deterministic Rust kernel, headless testing, Lua authoring, TOML data — all good Lurek2D fit.
- ✅ Monitor stream, post-run analytics via `lurek.dataframe`, and external visualization — all cleanly separable.
- ⚠️ Nested composites, approval workflows, DLQ/replay, anomaly injection — feasible but heavy.
- ⚠️ Tier 2 placement means the kernel cannot directly share code with `src/graph`, `src/dataframe`, or `src/gui` at the Rust level; peer composition happens through the Lua surface.
- ❌ Pure Lua library only — ruled out; per-tick overhead and performance guarantees are incompatible with the desired backend-neutral reuse goal.
