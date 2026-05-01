# Lurek2D — Philosophy and Design Assumptions

Source of truth for first principles, binding architectural decisions, and project identity. All other architecture docs reference this file.

Companion documents: [engine-architecture.md](engine-architecture.md) · [test-framework.md](test-framework.md)

---

## Table of Contents

1. [The Zen of Lurek 2.0](#the-zen-of-lurek-20)
2. [Core Idea](#core-idea)
3. [Project Identity](#project-identity)
4. [Decision Heuristics](#decision-heuristics)
5. [Platform and Runtime Constraints](#platform-and-runtime-constraints)
6. [Technology Stack Constraints](#technology-stack-constraints)
7. [Active Module Group Constraints](#active-module-group-constraints)
8. [API Design Constraints](#api-design-constraints)
9. [Testing Constraints](#testing-constraints)
10. [Quality Gate Constraints](#quality-gate-constraints)
11. [Constraint Status Model](#constraint-status-model)
12. [Retired Decisions](#retired-decisions)

---

## The Zen of Lurek 2.0

These fifteen rules are binding constraints. Every feature proposal, API design, and architectural decision must be checked against this list. If a choice violates a rule, the choice changes or the rule is formally amended — never silently overridden.

The module grouping (Foundations → Core Runtime → Platform Services → Feature Systems → Edge/Integration) is loose and practical. It does not ban same-group imports. It says: know what each module belongs to and what it should not do. The one hard invariant is **no cycles**.

| # | Rule | Summary |
|---|------|---------|
| 1 | No Cycles, Ever | The module import graph is a DAG. A cycle means the design is wrong. |
| 2 | Composition Root Is One-Way | `app` and `lua_api` can know everything. Nothing below them imports `app` or any binding module. |
| 3 | Depend on Contracts, Not Backends | Feature Systems depend on the `render` facade. Never on backend GPU details. |
| 4 | Runtime Stays Boring | `runtime` owns errors, config, IDs, commands, and traits. It does not know about the event loop, VM boot, or debug overlays. |
| 5 | World Is a Registry, Not a God Brain | `world` holds services and resources. Domain logic belongs in Feature Systems, not in `world`. |
| 6 | Same-Group Imports Are Allowed When Stable and Acyclic | A `tilemap` importing scene state from `scene` is fine — both are Feature Systems and there is no cycle. |
| 7 | Split by Reason to Change, Not by File Length | A new module is born when it has a different responsibility, not when a file hits 800 lines. |
| 8 | Draw Is a Projection Layer | If a module has a complex state → render-commands transformation, extract a `draw.rs`. Do not do it ritually. |
| 9 | Pure Logic Stays Pure | `math`, `procgen`, `graph` must never need render, audio, input, or Lua. |
| 10 | CPU State and Runtime Resources Must Stay Separate | Serialisable game state must not require a GPU handle, OS window, or VM reference. |
| 11 | Tooling Lives at the Edge | `devtools`, `debugbridge`, `docs`, `automation` observe; they never own. |
| 12 | Bindings Are Thin and One-Directional | The Lua bridge maps API calls onto domain functions. Domain modules never know the bridge exists. |
| 13 | Tests Follow Responsibility | A unit test for a private algorithm lives locally. A contract test or integration test lives in `tests/`. |
| 14 | Merge Weak Modules Fast | If a module has no clear, distinct responsibility, merge it into the module it most closely serves. |
| 15 | Optimise for Human and AI Readability | From a module's name and public API, it must be obvious whether it is core, a service, a feature, or a bridge. |

---

## Core Idea

Lurek2D is the engine for people who think game engines have become too complicated.

A game is a `main.lua` file. The engine runs it. You write Lua; the engine owns the GPU, the physics solver, the audio mixer, and the threading model. You never see a `.dll`, a `.framework`, or a build system.

The competitive landscape is dominated by multi-gigabyte engines with visual editors and months-long learning curves. Lurek2D is the opposite: one binary, one scripting language, one afternoon to learn.

**The AI angle**: Lurek2D is designed with AI copilots as first-class users. Every API is shaped so an AI agent can use it correctly from the docs alone. The CAG layer, the VS Code extension, and the documentation pipeline are all optimised for AI-assisted workflow.

---

## Project Identity

| Symbol | Meaning | Where It Appears |
|--------|---------|-----------------|
| Crescent Moon | Lua (Portuguese for "moon") — the scripting surface | Logo, splash screen |
| Gear / Pacman shape | Rust engine core — industrial-strength | Logo (primary shape) |
| Small Cube | Industry giants orbiting Lurek2D | Logo (accent) |
| Deep blue + orange palette | Night sky + warm engine glow | All branding |

**Naming**: "Lurek" + "2D". Short form: `lurek2d`. Binary: `lurek2d` (Unix), `lurek2d.exe` (Windows). Lua API prefix: `lurek.*`.

---

## Decision Heuristics

When two paths are available and neither violates a rule above, use these:

| Heuristic | Meaning |
|-----------|---------|
| Simpler is better | Fewer moving parts, fewer concepts, fewer files |
| Explicit over implicit | Name things directly. Avoid magic. |
| Defaults over configuration | Ship the 80% case. Make the 20% possible but optional. |
| Rust performance, Lua ergonomics | User-facing API must feel Lua-native. Engine internals optimise in Rust. |
| Test the contract, not the implementation | Tests break when behaviour changes, not when code is refactored. |
| One canonical place | Every rule, pattern, and convention has one source of truth. Reference it, do not duplicate it. |
| AI-verifiable | Could a Copilot agent use this API correctly without a clarifying question? If not, redesign. |

---

## Platform and Runtime Constraints

Active and binding. All code must comply. Do not propose changes without first opening a design-assumption update discussion.

| ID | Status | Constraint |
|----|--------|-----------|
| **A-01** | Active | Lurek2D is a **runtime only** — no embedded visual editor or IDE. The VS Code extension is an opt-in developer layer, not part of the engine binary. |
| **A-02** | Active | **Desktop only** — Windows / Linux / macOS, x86_64 + ARM. Mobile and WASM are out of scope. |
| **A-03** | Active | **2D graphics only** — no 3D scene graph, no perspective projection pipeline. Raycasting and isometric rendering use 2D draw calls. |
| **A-04** | Active | No platform SDK integration (Steam, Epic, itch.io) in the core binary. Wrappers live outside the five-group module stack. |
| **A-05** | Proposed | Core binary stays ≤ 10 MB stripped on desktop targets. Optional subsystems ship as plugins. Becomes Active when the plugin system (see [plugins.md](plugins.md)) is accepted and a baseline measurement is recorded. |

---

## Technology Stack Constraints

| ID | Status | Constraint |
|----|--------|-----------|
| **B-01** | Active | **LuaJIT** is the primary scripting runtime via mlua 0.9. Lua 5.4 (`lua54` Cargo feature) is a non-shipping CI fallback for environments where LuaJIT is unavailable. |
| **B-02** | Active | **wgpu 22** is the only renderer backend (Vulkan / DX12 / Metal). No raw OpenGL path, no software fallback. |
| **B-03** | Active | Games must run at **60 FPS at 1080p on integrated GPUs** (Intel UHD 620, AMD Vega 8 class). No feature requirements beyond wgpu baseline capabilities. |
| **B-04** | Active | Concurrency lives in **Rust threads**. LuaJIT VMs are single-threaded and cannot share state. Inter-VM communication uses typed MPMC `Channel` objects. |
| **B-05** | Active | **TOML** is the human-authored config format. JSON is accepted for external interop. YAML is not used anywhere in the project. |

---

## Active Module Group Constraints

These constraints formalise the [module group model](engine-architecture.md#module-group-model).

| ID | Status | Constraint |
|----|--------|-----------|
| **T-01** | Active | The active module structure uses **five responsibility groups**: Foundations, Core Runtime, Platform Services, Feature Systems, and Edge/Integration. See [engine-architecture.md](engine-architecture.md) § Module Group Model. |
| **T-02** | Active | `lua_api` (`src/lua_api/`) is the binding layer that registers `lurek.*`. It sits in Edge/Integration. No domain module may import `lua_api`. |
| **T-03** | Active | **No cycles, ever.** The module import graph must be a DAG. Same-group imports are allowed when acyclic. |
| **T-04** | Active | **Composition root is one-way.** `app` and `lua_api` may depend on any module below them. Nothing below them imports `app` or any `lua_api` binding module. |
| **T-05** | Active | **Lunasome** (`library/`) is the pure-Lua standard library. It consumes only public `lurek.*` APIs — no Rust engine internals, no `require` of engine source files. |
| **T-06** | Active | **Foundations group modules** (`math`, `log`, `data`, `serial`, `compute`, `dataframe`, `graph`, `procgen`, `patterns`) must never import render, audio, input, physics, or Lua APIs. |
| **T-07** | Active | **Edge/Integration group modules** (`devtools`, `debugbridge`, `automation`) are never imported by domain modules. They are optional components compiled only for development builds. |
| **T-08** | Active | Platform SDK integrations must not be imported by any module in Foundations, Core Runtime, Platform Services, or Feature Systems. They belong to external wrapping binaries only. |

---

## API Design Constraints

| ID | Status | Constraint |
|----|--------|-----------|
| **C-01** | Active | All Lua-facing APIs live under the `lurek.*` namespace. No bare globals, no engine-prefixed names, no alternative top-level tables. |
| **C-02** | Active | Every `lua_api` sub-module exposes exactly one `pub fn register(lua, lurek_table, state)` function. |
| **C-03** | Active | API functions must have sensible defaults. Never require parameters a beginner would always pass as the same value. |
| **C-04** | Active | Every callback (`lurek.init`, `lurek.ready`, `lurek.process`, `lurek.draw`, etc.) is **optional**. An empty `main.lua` is a valid game. |
| **C-05** | Active | The Lua API is **synchronous from the script's perspective**. Async work happens in Rust threads and communicates results via `Channel`. The Lua VM never blocks on I/O or network. |
| **C-06** | Active | **Callback names must not shadow API module keys.** If a planned callback key equals an existing API module name, the callback key must be renamed. Never work around the collision with a local alias in Lua scripts — that disguises an engine design bug. |

---

## Testing Constraints

These constraints formalise test placement and layering rules. They are binding. Existing violations are migration-scheduled under session `testing-cleanup-20260420`.

| ID | Status | Constraint |
|----|--------|-----------|
| **TST-01** | Active | **Lua-first testing.** Any behaviour reachable through the `lurek.*` API must be tested in `tests/lua/`. Rust tests must not duplicate `lurek.*`-reachable coverage. |
| **TST-02** | Active | **Centralised Rust unit tests.** Rust unit tests live in `tests/rust/unit/<module>_tests.rs`. Inline `#[cfg(test)]` blocks inside `src/**/*.rs` are banned. |
| **TST-03** | Active | **Thin Lua API wrappers.** `src/lua_api/<module>_api.rs` contains only `impl LuaUserData`, registration, and type conversions. Business logic lives in `src/<module>/` as pure Rust. |
| **TST-04** | Active | **Thin `mod.rs`.** Every `mod.rs` contains only `pub mod X`, `pub use X::*`, module-level attributes, and doc comments. Definitions live in sibling files. |
| **TST-05** | Active | Demo tests: headless Lua tests live in `tests/lua/demos/` (one file per demo, named `test_<name>.lua`). Screenshot tests live in `tests/demo_smoke_tests.rs` with `#[ignore]`. |
| **TST-06** | Active | One test file per module per layer: `test_<module>_<layer>.lua`. No split per-sub-feature files within a layer. |

See [test-framework.md](test-framework.md) for the decision tree and enforcement audit scripts.

---

## Quality Gate Constraints

| ID | Status | Constraint |
|----|--------|-----------|
| **Q-01** | Active | `cargo test` must exit 0 before any merge. All Rust and Lua tests must pass. |
| **Q-02** | Active | `cargo clippy -- -D warnings` must exit 0. No suppressed warnings without a comment explaining why. |
| **Q-03** | Active | Every new public Rust API item (`pub fn`, `pub struct`, `pub enum`, `pub trait`) requires at least one integration test before merge. |
| **Q-04** | Active | Every new `lurek.*` Lua API function requires at least one Lua BDD test before merge. |
| **Q-05** | Active | `python tools/docs/collect_docs.py --report-missing` must exit 0. Every `pub fn`, `pub struct`, `pub enum`, `pub trait`, and `pub type` must have a `///` doc comment. |

---

## Constraint Status Model

| Status | Meaning |
|--------|---------|
| **Active** | Binding. All code must comply. Violations require a design discussion before implementation. |
| **Proposed** | Under consideration. Not yet binding. May be promoted to Active or withdrawn. |
| **Retired** | Was Active; superseded by a newer decision. Kept for historical context. |

To change a constraint's status: open a discussion referencing the specific constraint ID, get agreement from the project maintainer, update this document, and update the system prompt if the change affects it.

---

## Retired Decisions

### Retired: Strict Tier Numbering

**Original (c. v0.4):** T-03 banned all same-tier imports. T-04 banned all Tier 2 ↔ Tier 2 imports.

**Why retired:** The ban was a proxy for the real invariant (no cycles). It was overly conservative and ruled out legitimate stable acyclic imports. For example, `tilemap` importing scene state from `scene` is correct design — both are Feature Systems and there is no cycle.

**Replaced by:** T-03 (Active): No cycles, ever. Same-group imports allowed when stable and acyclic.

---

### Retired: Baseline → Tier 1 → Tier 2 → Tier 3 Naming

**Original (c. v0.4):** T-01 defined the stack as Baseline + Tier 1 + Tier 2 + Tier 3. Baseline was `src/math/` and `src/engine/`.

**Why retired:** The Baseline/Tier nomenclature became misleading as the engine grew. The tier numbers implied a linear progression that did not match actual import topology.

**Replaced by:** T-01 (Active): Five responsibility groups. See [engine-architecture.md](engine-architecture.md) § Module Group Model.

---

### Retired: Tier 4 as the Platform Integration Slot

**Original (c. v0.4):** Principle 6 placed platform integrations at "Tier 4 (future)" or in external wrapping binaries.

**Why retired:** "Tier 4" was never defined or implemented.

**Replaced by:** T-08 (Active) and A-04 (Active).
