# Lurek2D — Philosophy and Design Assumptions

> **Source of truth** for first principles, binding architectural decisions, and project identity.
> Companion documents: [engine-architecture.md](engine-architecture.md) (runtime module structure) · [test-framework.md](test-framework.md) (test architecture).

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
9. [Quality Gate Constraints](#quality-gate-constraints)
10. [Constraint Status Model](#constraint-status-model)
11. [Retired Decisions](#retired-decisions)

---

## The Zen of Lurek 2.0

These fifteen principles are the soul of the project. They are not aspirational guidelines — they are **binding constraints**. Every feature proposal, API design, and architectural decision must be checked against this list. If a choice violates a principle, the choice changes or the principle is formally amended — never silently overridden.

### 1. No Cycles, Ever

The module graph is a DAG. A circular import is a hard build error and a build error is a gate — it stops the branch. There are no exceptions, no `unsafe` workarounds, no "temporary" cycles that get cleaned up later. If two modules appear to need each other, one of them is in the wrong group or the shared logic belongs in a third module they both depend on.

→ See [engine-architecture.md](engine-architecture.md) § Module Group Dependency Graph.

### 2. Composition Root Is One-Way

`app` and `scripting` can know everything — they sit at the top and wire everything together. Nothing below them imports `app` or `scripting`. `lua_api` (`scripting`) is an integration endpoint, not a library. Domain modules never import it.

→ See [engine-architecture.md](engine-architecture.md) § Edge and Integration Layer.

### 3. Depend on Contracts, Not Backends

Modules that have a platform-specific backend (audio, physics, render, filesystem) expose a pure-Rust contract type. Other modules import the contract, not the backend. When the backend swaps, nothing outside it recompiles. The contract lives in the module's `mod.rs` or a `contract.rs` file — never in the backend implementation.

### 4. Core Stays Boring

`core` is errors, config, typed handles (resource keys), shared traits, and nothing else. It has no runtime state, no allocations at startup, no game logic. If you find yourself adding a non-trivial algorithm or a data structure that grows at runtime to `core`, that code belongs somewhere else.

→ See [engine-architecture.md](engine-architecture.md) § Core Runtime Group.

### 5. World Is a Registry, Not a God Brain

`world` holds `SharedState` — the typed `SlotMap` resource pools, the frame counter, the current `RunState`. It does not make decisions, does not call into domain modules, and does not own the game loop. `app` orchestrates; `world` stores. If `world` is growing methods that coordinate between modules, those methods belong in `app`.

→ See [engine-architecture.md](engine-architecture.md) § Core Runtime Group.

### 6. Same-Layer Imports Are Allowed When Stable and Acyclic

The old rule — no cross-imports within a tier — was a proxy for the real rule, which is **no cycles**. Two modules in the same responsibility group may import each other if the import direction is stable, acyclic, and well-motivated. If `tilemap` needs `scene`'s transition state, that is allowed. If `scene` also needs `tilemap`, that is a cycle and is forbidden by Principle 1.

The key question is not "are they in the same group?" but "does adding this import create a cycle?"

### 7. Split by Reason to Change, Not by File Length

A 500-line file with one cohesive responsibility is better than five 100-line files that all change together. Split a module when its parts have genuinely different reasons to change — different owners, different stability, different abstraction level. Never split because the file "feels big."

### 8. Draw Is a Projection Layer

Every module that produces visual output has at most one file dedicated to projecting its internal state into `RenderCommand` values. That file is `draw.rs`. Business logic, state mutation, and data structures are in other files. `draw.rs` is a pure read-only projection: it calls no non-render APIs and mutates no state.

→ See [engine-architecture.md](engine-architecture.md) § Rendering Pipeline.

### 9. Pure Logic Stays Pure

`math`, `procgen`, `graph`, `nav`, `serial`, and similar analytical modules must never import render, audio, input, or Lua APIs. If you need to visualise a graph for debugging, the visualisation lives in a `draw.rs` in the debug module — not in `graph` itself. These modules are the most reusable and the most stable. Protect that stability.

### 10. CPU State and Runtime Resources Must Stay Separate

A `Body` is CPU state — a plain Rust struct you can create in a test without a physics world. A `BodyHandle` is a runtime resource index into a `SlotMap`. These are different types and must never be merged. Every module that manages long-lived resources uses typed handle types (`TextureKey`, `FontKey`, `BodyHandle`, etc.), never raw indices or `usize`.

→ See `src/engine/resource_keys.rs` for the canonical key type definitions.

### 11. Tooling Lives at the Edge

`devtools`, `debugbridge`, `automation`, and the VS Code extension are edge modules. They import everything. Nothing imports them. They are never compiled into production builds unless explicitly enabled. Debug features that ship to end users are a security and performance risk.

→ See [engine-architecture.md](engine-architecture.md) § Edge and Integration Layer.

### 12. Bindings Are Thin and One-Directional

`src/lua_api/` owns all Lua-facing registration. This includes `pub fn register()`, Lua wrapper structs, `impl LuaUserData` blocks, and all `add_method` calls. Domain modules contain only pure-Rust business logic — never `impl LuaUserData` or any `mlua` import. This is not a style preference. Putting binding code in a domain module is a **blocking code review defect**.

→ See the system prompt § Lua API Conventions for the complete canonical rule.

### 13. Tests Follow Responsibility

A test lives as close to the code it tests as possible. Private logic gets a `#[cfg(test)]` module in the same file. Public contracts get `tests/rust/unit/<module>_tests.rs`. Cross-module behaviour gets `tests/rust/ext/` or `tests/lua/integration/`. Do not put a unit test in an integration file just because an integration harness already exists.

→ See [test-framework.md](test-framework.md) for the complete test architecture.

### 14. Merge Weak Modules Fast

A module with fewer than three files that has been stable for more than one release cycle should be absorbed into its natural parent unless there is a specific versioning, ownership, or stability reason to keep it separate. Dead modules, stub modules, and "future work" modules accumulate entropy. If a module has no active owner and no active users, delete or merge it.

### 15. Optimise for Human and AI Readability

Code is read far more often than it is written. The primary audience includes AI agents. Every public function, struct, and module must have a `///` doc comment that answers: "what does this do and when do I use it?" If a Copilot agent cannot use an API correctly from the docs alone, the docs and possibly the API design are wrong.

One executable. One scripting language. One afternoon to learn. Keep it that way.

→ Applies to all modules. Verified by `python tools/docs/collect_docs.py --report-missing`.

## Core Idea

Lurek2D is the engine for people who think game engines have become too complicated.

A game is a `main.lua` file. The engine runs it. You write Lua; the engine owns the GPU, the physics solver, the audio mixer, and the threading model. You never see a `.dll`, a `.framework`, or a build system. You see `lurek.process(dt)` and `lurek.render()`.

The competitive landscape is dominated by multi-gigabyte engines with visual editors, plugin marketplaces, and months-long learning curves. Lurek2D is the opposite: one binary, one scripting language, one afternoon to learn.

**The AI angle**: Lurek2D is the first game engine designed with AI copilots as first-class users. Every API is shaped so an AI agent can use it correctly from the docs alone. The CAG layer, the VS Code extension, and the documentation pipeline are all optimized for AI-assisted workflow. When an AI writes `lurek.gfx.draw(img, x, y)`, it should work on the first try, every time.

---

## Project Identity

Lurek2D's visual identity is built on a set of symbols that tell the David vs. Goliath story:

| Symbol | Meaning | Where It Appears |
|---|---|---|
| 🌙 Crescent Moon | Lua (Portuguese for "moon") — the scripting surface | Logo, splash screen |
| ⚙️ Gear / Pacman shape | Rust engine core — industrial-strength, consuming scripts | Logo (primary shape) |
| 🧊 Small Cube | The industry giants (Engine G, Engine H, Engine C) — orbiting Lurek2D | Logo (accent) |
| Deep blue + orange palette | Night sky + warm engine glow | All branding materials |

**Naming convention**: "Luna" (engine) + "2D" (scope constraint). Short form: `lurek2d`. Binary name: `lurek2d` (Unix), `lurek2d.exe` (Windows). Lua API prefix: `lurek.*`.

---

## Decision Heuristics

When two paths are available and neither violates a principle above, use these heuristics to choose:

| Heuristic | Meaning |
|---|---|
| **Simpler is better** | Fewer moving parts. Fewer concepts. Fewer files. |
| **Explicit over implicit** | Name things directly. Avoid magic. If a Copilot agent can't infer it from the signature, it's too implicit. |
| **Defaults over configuration** | Ship the 80% case. Make the other 20% possible but optional. |
| **Rust performance, Lua ergonomics** | If the user touches it, it should feel Lua-native. If the engine owns it, optimize in Rust. |
| **Test the contract, not the implementation** | Tests should break when behavior changes, not when code is refactored. |
| **One canonical place** | Every rule, every pattern, every convention has exactly one source of truth. Reference it, don't duplicate it. |
| **AI-verifiable** | Could a Copilot agent use this API correctly without a clarifying question? If no, redesign. |

---

## Platform and Runtime Constraints

These are **active, binding decisions**. All code must comply. Do not propose changes without first opening a design-assumption update discussion.

| ID | Status | Constraint |
|---|---|---|
| **A-01** | Active | Lurek2D is a **runtime only** — no embedded visual editor or IDE. The VS Code extension is an opt-in developer experience layer, not part of the engine binary. |
| **A-02** | Active | **Desktop only** — Windows / Linux / macOS, x86_64 + ARM. Mobile (iOS / Android) and WASM are out of scope. |
| **A-03** | Active | **2D graphics only** — no 3D scene graph, no perspective projection pipeline. Raycasting columns and isometric rendering are acceptable because they use 2D draw calls. |
| **A-04** | Active | No distribution platform SDK integration (Steam, Epic, itch.io store APIs) in the core engine binary. Platform wrappers live outside the five-group module stack entirely — constraint T-08. |

---

## Technology Stack Constraints

| ID | Status | Constraint |
|---|---|---|
| **B-01** | Active | **LuaJIT** is the primary scripting runtime, vendored through mlua 0.9. Lua 5.4 (`lua54` Cargo feature) is a non-shipping development fallback — it exists for fallback testing and CI environments where LuaJIT is unavailable. |
| **B-02** | Active | **wgpu 22** is the only renderer backend (Vulkan / DX12 / Metal via the wgpu abstraction). No raw OpenGL path, no software fallback. |
| **B-03** | Active | Games must run acceptably on **integrated GPUs** (Intel UHD 620, AMD Vega 8 class). No feature requirements beyond wgpu baseline capabilities. Performance target: 60 FPS at 1080p with a reasonable draw call count. |
| **B-04** | Active | Concurrency lives in **Rust threads**. LuaJIT VMs are single-threaded and cannot share state. Inter-VM communication uses typed MPMC `Channel` objects. |
| **B-05** | Active | **TOML** is the human-authored configuration format. JSON is accepted for external interop (e.g., exported save files, API data). YAML is not used anywhere in the project. |

---

## Active Module Group Constraints

These constraints formalize the [module group model](engine-architecture.md#module-group-model) as enforceable rules. The old Baseline / Tier 1 / Tier 2 / Tier 3 naming is retired — see [Retired Decisions](#retired-decisions).

| ID | Status | Constraint |
|---|---|---|
| **T-01** | Active | The active module structure uses **five responsibility groups**: Foundations, Core Runtime, Platform Services, Feature Systems, and Edge/Integration. See [engine-architecture.md](engine-architecture.md) § Module Group Model. |
| **T-02** | Active | `lua_api` (`scripting`) is the **binding layer** that registers `lurek.*`. It sits in the Edge/Integration group. It may import all Rust groups. No domain module may import `lua_api`. |
| **T-03** | Active | **No cycles, ever.** The module import graph must remain a DAG. Same-group imports are allowed provided they are acyclic and stable. See Principle 1 and Principle 6 above. |
| **T-04** | Active | **Composition root is one-way.** `app` and `scripting` may depend on any module below them. No module below them may import `app` or any `lua_api` binding module. |
| **T-05** | Active | **Lunasome** (`content/library/`) is the pure-Lua standard library. It consumes public `lurek.*` APIs only — no Rust engine internals, no `require` of engine source files. |
| **T-06** | Active | **Foundations group modules** (`math`, `log`, `data`, `serial`, `compute`, `dataframe`, `graph`, `procgen`, `patterns`) must never import render, audio, input, physics, or Lua APIs. See Principle 9. |
| **T-07** | Active | **Edge/Integration group modules** (`devtools`, `debugbridge`, `automation`) are never imported by domain modules. They are optional components compiled only for development builds. |
| **T-08** | Active | Platform SDK integrations (Steam, Epic, itch.io store APIs) must not be imported by any module in Foundations, Core Runtime, Platform Services, or Feature Systems groups. They belong to external wrapping binaries only. |

---

## API Design Constraints

| ID | Status | Constraint |
|---|---|---|
| **C-01** | Active | All Lua-facing APIs live under the `lurek.*` namespace. No bare globals, no engine-prefixed names, no alternative top-level tables. |
| **C-02** | Active | Every `lua_api` sub-module exposes exactly one `pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`. |
| **C-03** | Active | API functions must have **sensible defaults** — never require parameters a beginner would always pass as the same value. Overloaded param counts are preferred over config tables for simple APIs. |
| **C-04** | Active | Every callback (`lurek.init`, `lurek.ready`, `lurek.process`, `lurek.process_physics`, `lurek.process_late`, `lurek.render`, `lurek.render_ui`, `lurek.keypressed`, etc.) is **optional**. An empty `main.lua` is a valid game. |
| **C-05** | Active | Lua API is **synchronous from the script's perspective**. Any asynchronous work happens in Rust threads and communicates results via `Channel`. The Lua VM never blocks on I/O or network. |

---

## Quality Gate Constraints

| ID | Status | Constraint |
|---|---|---|
| **Q-01** | Active | `cargo test` must exit 0 before any merge. All Rust and Lua tests must pass. |
| **Q-02** | Active | `cargo clippy -- -D warnings` must exit 0 before any merge. No suppressed warnings, no `#[allow(clippy::...)]` without a comment explaining why. |
| **Q-03** | Active | Every new public Rust API item (`pub fn`, `pub struct`, `pub enum`, `pub trait`) requires at least **one integration test** before merge. |
| **Q-04** | Active | Every new `lurek.*` Lua API function requires at least **one Lua BDD test** before merge. |
| **Q-05** | Active | `python tools/collect_docs.py --report-missing` must exit 0 — no undocumented public items. Every `pub fn`, `pub struct`, `pub enum`, `pub trait`, and `pub type` must have a `///` doc comment. |

→ See [test-framework.md](test-framework.md) § Quality Gates for the complete test gate details.

---

## Constraint Status Model

Each design constraint has one of three statuses:

| Status | Meaning |
|---|---|
| **Active** | Binding. All code must comply. Violations require a design-assumption update discussion before implementation. |
| **Proposed** | Under consideration. Not yet binding. May be promoted to Active or withdrawn. |
| **Retired** | Was Active; now superseded by a newer decision. Kept for historical context in the Retired Decisions section below. |

To change a constraint's status:
1. Open a discussion or issue describing why the change is needed.
2. Reference the specific constraint ID (e.g., "Propose retiring A-04").
3. Get agreement from the project maintainer.
4. Update this document.
5. If the change affects the system prompt (`.github/copilot-instructions.md`), update it too.

---

## Retired Decisions

These decisions were once **Active** constraints but have been superseded. They are kept for historical context.

### Retired: Strict Tier Numbering (T-03-old, T-04-old)

**Original (Zen of Luna, c. v0.4):**
- T-03: Tier 1 modules may only import `math` and `engine`. **No Tier 1 ↔ Tier 1 cross-imports.**
- T-04: Tier 2 modules may import Baseline and any Tier 1 module. **No Tier 2 ↔ Tier 2 cross-imports.**

**Why retired:** The blanket ban on same-tier imports was a proxy for the real invariant (no cycles). It was overly conservative and ruled out legitimate stable acyclic imports between modules at the same conceptual level. For example, `tilemap` importing scene transition state from `scene` is correct design — both are Feature Systems modules, and there is no cycle.

**Replaced by:** T-03 (Active): No cycles, ever. Same-group imports are allowed when stable and acyclic. See Principle 1 and Principle 6 above.

---

### Retired: Baseline → Tier 1 → Tier 2 → Tier 3 Naming (T-01-old)

**Original (Zen of Luna, c. v0.4):**
- T-01: The active module stack is **Baseline + Tier 1 + Tier 2 + Tier 3**. Baseline is `src/math/` and `src/engine/`.

**Why retired:** The Baseline/Tier nomenclature became misleading as the engine grew. `src/engine/` was a monolith that mixed config, resource keys, app state, and boot logic — not a clean substrate. The tier numbers implied a linear progression that did not match actual import topology. The new five-group model (Foundations → Core Runtime → Platform Services → Feature Systems → Edge/Integration) is more accurate and more legible for both humans and AI agents.

**Replaced by:** T-01 (Active): Five responsibility groups. See [engine-architecture.md](engine-architecture.md) § Module Group Model.

---

### Retired: Tier 4 as the Platform Integration Slot

**Original (Zen of Luna, c. v0.4):**
- Principle 6: "Platform integrations live at Tier 4 (future) or in external wrapping binaries."

**Why retired:** "Tier 4" was never defined or implemented. The concept is now captured cleanly in constraint T-08 (Active): platform SDK wrappers live entirely outside the five-group module stack.

**Replaced by:** T-08 (Active) and constraint A-04 (Active, updated).
